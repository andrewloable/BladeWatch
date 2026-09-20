package net.bladewatch.app.server.connect

import net.bladewatch.app.daemon.CameraDaemon
import net.bladewatch.app.server.HttpResponse
import org.json.JSONObject
import java.io.OutputStream
import java.nio.charset.StandardCharsets
import java.util.Locale

/**
 * Routes incoming HTTP requests that use the Connect protocol to registered service handlers.
 * Unary RPCs arrive as "application/json"; streaming RPCs as "application/connect+json". The
 * response Content-Type echoes the request form.
 *
 * Path format: /bladewatch.v1.{ServiceName}/{MethodName}
 *
 * Registration:
 * ```
 *   dispatcher.register("bladewatch.v1.AuthService", "Login", this::handleLogin)
 * ```
 *
 * Integration in HttpServer — before the other route checks:
 * ```
 *   if (path.startsWith("/bladewatch.v1.")) {
 *       connectDispatcher.dispatch(method, path, body, out)
 *       return
 *   }
 * ```
 *
 * Auth middleware runs before this dispatch — no JWT check is needed here.
 *
 * The header blocks below are built from CONCATENATED string literals rather than Kotlin string
 * templates on purpose: ResponseFramingTest reads them as source text and would not recognise an
 * interpolated status line.
 */
class ConnectDispatcher {

    // Key: "ServiceFqn/MethodName" e.g. "bladewatch.v1.AuthService/Login"
    private val registry = HashMap<String, ConnectServiceHandler>()

    /**
     * Register a handler for one RPC method.
     *
     * @param serviceFqn fully-qualified service name (e.g. "bladewatch.v1.AuthService").
     * @param methodName RPC method name (e.g. "Login").
     * @param handler implementation to invoke.
     */
    fun register(serviceFqn: String, methodName: String, handler: ConnectServiceHandler) {
        registry["$serviceFqn/$methodName"] = handler
    }

    /**
     * Dispatch a Connect request: validate the Connect headers, look up the handler, and write the
     * response. Always writes exactly one HTTP response — callers must not write another.
     *
     * @param method HTTP method string.
     * @param path request path, e.g. "/bladewatch.v1.AuthService/Login".
     * @param body raw request body string (may be null or empty).
     * @param contentType value of the Content-Type header (may be null).
     * @param connectVersion value of the Connect-Protocol-Version header (may be null).
     * @param out OutputStream to write the HTTP response to.
     */
    fun dispatch(
        method: String?,
        path: String,
        body: String?,
        contentType: String?,
        connectVersion: String?,
        clientIdentity: String?,
        out: OutputStream
    ) {
        // Echo a response Content-Type matching the request: unary clients send
        // "application/json" and require it back; streaming uses the +json form.
        val respCt = responseContentType(contentType)
        try {
            // Only POST is valid for unary Connect calls.
            if ("POST" != method) {
                sendConnectError(out, respCt, 405, "unimplemented", "Connect only accepts POST")
                return
            }

            // Require Connect-Protocol-Version: 1
            if (CONNECT_PROTOCOL_VERSION != connectVersion) {
                sendConnectError(
                    out, respCt, 400, "invalid_argument",
                    "Missing or wrong Connect-Protocol-Version header; expected \"1\""
                )
                return
            }

            // Require a supported JSON content-type. Unary Connect uses "application/json";
            // streaming Connect uses "application/connect+json".
            if (!isSupportedContentType(contentType)) {
                sendConnectError(
                    out, respCt, 415, "invalid_argument",
                    "Content-Type must be application/json or application/connect+json"
                )
                return
            }

            // Resolve the handler from the path, which is like /bladewatch.v1.Svc/Method.
            val key = if (path.startsWith("/")) path.substring(1) else path
            val handler = registry[key]
            if (handler == null) {
                // Extract the service name for a nicer error message.
                val slash = key.indexOf('/')
                val svcName = if (slash > 0) key.substring(0, slash) else key
                sendConnectError(
                    out, respCt, 404, "not_found", "Service not registered: $svcName"
                )
                return
            }

            val requestJson = if (body.isNullOrEmpty()) "{}" else body
            val response = handler.handle(requestJson, clientIdentity ?: "")

            sendConnectSuccess(out, respCt, response.body, response.extraHeaders)
        } catch (e: ConnectException) {
            try {
                sendConnectError(
                    out, respCt, connectCodeToHttpStatus(e.code), e.code, e.message
                )
            } catch (ex: Exception) {
                CameraDaemon.log(
                    "ConnectDispatcher: failed to send ConnectException error: " + ex.message
                )
            }
        } catch (e: Exception) {
            CameraDaemon.log("ConnectDispatcher: unexpected error: $e")
            try {
                sendConnectError(out, respCt, 500, "internal", "An internal error occurred")
            } catch (ex: Exception) {
                CameraDaemon.log(
                    "ConnectDispatcher: also failed to send internal error response: " + ex.message
                )
            }
        }
    }

    // ==================== HTTP response helpers ====================

    @Throws(Exception::class)
    private fun sendConnectSuccess(
        out: OutputStream,
        contentType: String,
        jsonBody: String,
        extraHeaders: List<String>
    ) {
        val body = jsonBody.toByteArray(StandardCharsets.UTF_8)
        val sb = StringBuilder()
        sb.append("HTTP/1.1 200 OK\r\n")
            .append("Content-Type: ").append(contentType).append("\r\n")
            .append("Content-Length: ").append(body.size).append("\r\n")
            .append(HttpResponse.connectionHeader(out))
        for (h in extraHeaders) sb.append(h).append("\r\n")
        sb.append("\r\n")
        out.write(sb.toString().toByteArray(StandardCharsets.UTF_8))
        out.write(body)
        out.flush()
    }

    @Throws(Exception::class)
    private fun sendConnectError(
        out: OutputStream,
        contentType: String,
        httpStatus: Int,
        code: String?,
        message: String?
    ) {
        val err = JSONObject()
        err.put("code", code)
        err.put("message", message ?: "")
        val body = err.toString().toByteArray(StandardCharsets.UTF_8)
        val headers = "HTTP/1.1 " + httpStatus + " " + httpStatusText(httpStatus) + "\r\n" +
            "Content-Type: " + contentType + "\r\n" +
            "Content-Length: " + body.size + "\r\n" +
            HttpResponse.connectionHeader(out) +
            "\r\n"
        out.write(headers.toByteArray(StandardCharsets.UTF_8))
        out.write(body)
        out.flush()
    }

    /** Map Connect error codes to their canonical HTTP status codes. */
    private fun connectCodeToHttpStatus(code: String?): Int = when (code) {
        "invalid_argument" -> 400
        "unauthenticated" -> 401
        "permission_denied" -> 403
        "not_found" -> 404
        "already_exists" -> 409
        "resource_exhausted" -> 429
        "unimplemented" -> 501
        "unavailable" -> 503
        else -> 500
    }

    private fun httpStatusText(status: Int): String = when (status) {
        200 -> "OK"
        400 -> "Bad Request"
        401 -> "Unauthorized"
        403 -> "Forbidden"
        404 -> "Not Found"
        405 -> "Method Not Allowed"
        409 -> "Conflict"
        415 -> "Unsupported Media Type"
        429 -> "Too Many Requests"
        500 -> "Internal Server Error"
        501 -> "Not Implemented"
        503 -> "Service Unavailable"
        else -> "Error"
    }

    companion object {
        // Unary Connect RPCs use "application/json"; streaming Connect RPCs use
        // "application/connect+json". connect-kotlin and @connectrpc/connect-web both send the
        // unary form for unary calls, which is all the UI uses today.
        private const val CONTENT_TYPE_JSON = "application/json"
        private const val CONTENT_TYPE_CONNECT = "application/connect+json"
        private const val CONNECT_PROTOCOL_VERSION = "1"

        /**
         * Negotiates the response Content-Type from the request's. A streaming request
         * ("application/connect+json") is echoed verbatim; everything else (unary
         * "application/json", or an early error before validation) gets "application/json", which
         * is what unary Connect clients require on the response.
         *
         * Public rather than module-internal so ConnectContentTypeNegotiationTest, which is Java,
         * can call it: Kotlin mangles `internal` names on the JVM.
         */
        @JvmStatic
        fun responseContentType(requestContentType: String?): String {
            if (requestContentType != null) {
                var ct = requestContentType.trim().lowercase(Locale.ROOT)
                val semi = ct.indexOf(';')
                if (semi >= 0) ct = ct.substring(0, semi).trim()
                if (ct == CONTENT_TYPE_CONNECT) return CONTENT_TYPE_CONNECT
            }
            return CONTENT_TYPE_JSON
        }

        /**
         * Accepts the JSON Connect content-types. Unary RPCs send "application/json"; streaming
         * RPCs send "application/connect+json". Tolerates an optional parameter suffix (e.g.
         * "; charset=utf-8") and case differences.
         */
        @JvmStatic
        fun isSupportedContentType(contentType: String?): Boolean {
            if (contentType == null) return false
            var ct = contentType.trim().lowercase(Locale.ROOT)
            val semi = ct.indexOf(';')
            if (semi >= 0) ct = ct.substring(0, semi).trim()
            return ct == CONTENT_TYPE_JSON || ct == CONTENT_TYPE_CONNECT
        }
    }
}
