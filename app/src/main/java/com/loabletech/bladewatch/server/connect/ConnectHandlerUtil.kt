package net.bladewatch.app.server.connect

import net.bladewatch.app.daemon.CameraDaemon
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.OutputStream
import java.nio.charset.StandardCharsets
import java.util.Base64

/**
 * Captures an existing REST handler's output and forwards it as a Connect response.
 *
 * The remaining HTTP-shaped handlers write a full HTTP/1.1 response (status line, headers, blank
 * line, body) to their OutputStream. This helper splits the HTTP framing from the payload.
 */
object ConnectHandlerUtil {

    /** Functional interface for lambdas that write to an OutputStream. */
    fun interface HandlerInvoker {
        @Throws(Exception::class)
        fun invoke(out: OutputStream)
    }

    /** Parsed result of a captured REST handler response. */
    private class RawCapture(
        val bodyBytes: ByteArray,
        /** Everything before the blank line. */
        private val headersSection: String,
        /** Parsed from the HTTP status line. */
        val httpStatus: Int
    ) {
        /** Extract all Set-Cookie header values from the response headers. */
        fun setCookies(): List<String> {
            val cookies = ArrayList<String>()
            for (line in headersSection.split("\r\n")) {
                if (line.lowercase().startsWith("set-cookie:")) {
                    cookies.add(line.substring("set-cookie:".length).trim())
                }
            }
            return cookies
        }
    }

    @Throws(ConnectException::class)
    private fun captureRaw(invoker: HandlerInvoker): RawCapture {
        val baos = ByteArrayOutputStream(4096)
        try {
            invoker.invoke(baos)
            val all = baos.toByteArray()
            // Find the \r\n\r\n separator between headers and body
            for (i in 0 until all.size - 3) {
                if (all[i] == '\r'.code.toByte() && all[i + 1] == '\n'.code.toByte() &&
                    all[i + 2] == '\r'.code.toByte() && all[i + 3] == '\n'.code.toByte()
                ) {
                    val headers = String(all, 0, i, StandardCharsets.UTF_8)
                    val status = parseHttpStatus(headers)
                    val body = ByteArray(all.size - i - 4)
                    System.arraycopy(all, i + 4, body, 0, body.size)
                    return RawCapture(body, headers, status)
                }
            }
            // No header separator — treat the entire output as the body
            return RawCapture(all, "", 200)
        } catch (e: ConnectException) {
            throw e
        } catch (e: Exception) {
            CameraDaemon.log("ConnectHandlerUtil: handler error: $e")
            throw ConnectException("internal", "An internal error occurred")
        }
    }

    /**
     * Capture a REST handler and return its JSON body as a [JSONObject]. Non-object JSON (arrays,
     * scalars) and empty bodies are tolerated: arrays are wrapped in `{"items":[...]}`, other
     * non-object values return an empty object.
     *
     * Throws [ConnectException] with code "internal" on parse failures.
     */
    @JvmStatic
    @Throws(ConnectException::class)
    fun capture(invoker: HandlerInvoker): JSONObject {
        val raw = captureRaw(invoker)
        return try {
            val json = String(raw.bodyBytes, StandardCharsets.UTF_8).trim()
            when {
                json.isEmpty() -> JSONObject()
                json.startsWith("{") -> JSONObject(json)
                json.startsWith("[") -> JSONObject().put("items", JSONArray(json))
                else -> JSONObject()
            }
        } catch (e: Exception) {
            CameraDaemon.log("ConnectHandlerUtil: JSON parse error: $e")
            throw ConnectException("internal", "An internal error occurred")
        }
    }

    /**
     * Capture a REST handler and return its JSON body as a String, along with any Set-Cookie
     * headers from the wrapped response (for auth flows). Throws [ConnectException] if the wrapped
     * handler returns HTTP 4xx/5xx.
     */
    @JvmStatic
    @Throws(ConnectException::class)
    fun captureWithCookies(invoker: HandlerInvoker): ConnectResponse {
        val raw = captureRaw(invoker)
        if (raw.httpStatus >= 400) {
            val failed = String(raw.bodyBytes, StandardCharsets.UTF_8).trim()
            throw ConnectException(
                httpStatusToConnectCode(raw.httpStatus), extractErrorMessage(failed)
            )
        }
        return try {
            var payload = String(raw.bodyBytes, StandardCharsets.UTF_8).trim()
            if (payload.isEmpty()) payload = "{}"
            val cookies = raw.setCookies()
            if (cookies.isEmpty()) {
                ConnectResponse.of(payload)
            } else {
                ConnectResponse.withCookies(payload, cookies)
            }
        } catch (e: Exception) {
            CameraDaemon.log("ConnectHandlerUtil: cookie capture error: $e")
            throw ConnectException("internal", "An internal error occurred")
        }
    }

    /**
     * Capture a REST handler that returns binary data (e.g. image/jpeg) and encode the bytes as a
     * Base64 string in the given JSON field name.
     *
     * @param fieldName JSON key to store the Base64 bytes under.
     */
    @JvmStatic
    @Throws(ConnectException::class)
    fun captureBytes(invoker: HandlerInvoker, fieldName: String): ConnectResponse {
        val raw = captureRaw(invoker)
        if (raw.bodyBytes.isEmpty()) {
            throw ConnectException("not_found", "No data returned")
        }
        val b64 = Base64.getEncoder().encodeToString(raw.bodyBytes)
        val json = JSONObject()
        try {
            json.put(fieldName, b64)
        } catch (e: Exception) {
            throw ConnectException("internal", "An internal error occurred")
        }
        return ConnectResponse.of(json.toString())
    }

    /**
     * Capture a REST handler and return its raw body as a ConnectResponse. Throws
     * [ConnectException] if the wrapped handler returns HTTP 4xx/5xx.
     */
    @JvmStatic
    @Throws(ConnectException::class)
    fun captureString(invoker: HandlerInvoker): ConnectResponse {
        val raw = captureRaw(invoker)
        if (raw.httpStatus >= 400) {
            val failed = String(raw.bodyBytes, StandardCharsets.UTF_8).trim()
            throw ConnectException(
                httpStatusToConnectCode(raw.httpStatus), extractErrorMessage(failed)
            )
        }
        var payload = String(raw.bodyBytes, StandardCharsets.UTF_8).trim()
        if (payload.isEmpty()) payload = "{}"
        return ConnectResponse.of(payload)
    }

    /**
     * Extract a required `long` field from a JSON request body.
     *
     * Throws [ConnectException] with code "invalid_argument" if the field is missing or
     * unparseable.
     */
    @JvmStatic
    @Throws(ConnectException::class)
    fun requireLong(requestJson: String?, field: String): Long = try {
        JSONObject(requestJson).getLong(field)
    } catch (e: Exception) {
        throw ConnectException("invalid_argument", "Missing or invalid field: $field")
    }

    /**
     * Extract a required non-empty `String` field from a JSON request body.
     *
     * Throws [ConnectException] with code "invalid_argument" if the field is missing or blank.
     */
    @JvmStatic
    @Throws(ConnectException::class)
    fun requireString(requestJson: String?, field: String): String {
        val v = try {
            JSONObject(requestJson).getString(field)
        } catch (e: Exception) {
            throw ConnectException("invalid_argument", "Missing or invalid field: $field")
        }
        if (v.isEmpty()) {
            throw ConnectException("invalid_argument", "Missing or invalid field: $field")
        }
        return v
    }

    private fun parseHttpStatus(headers: String): Int = try {
        // The status line, e.g. HTTP/1.1 404 Not Found
        headers.split("\r\n")[0].split(" ")[1].toInt()
    } catch (e: Exception) {
        200
    }

    private fun httpStatusToConnectCode(status: Int): String = when (status) {
        400 -> "invalid_argument"
        401 -> "unauthenticated"
        403 -> "permission_denied"
        404 -> "not_found"
        409 -> "already_exists"
        429 -> "resource_exhausted"
        else -> "internal"
    }

    private fun extractErrorMessage(failedBody: String?): String {
        if (failedBody.isNullOrEmpty()) return "Request failed"
        try {
            val obj = JSONObject(failedBody)
            var msg = obj.optString("error", null)
            if (msg == null) msg = obj.optString("message", null)
            if (!msg.isNullOrEmpty()) return msg
        } catch (ignored: Exception) {
            CameraDaemon.log("extractErrorMessage: failed to parse body: " + ignored.message)
        }
        return "Request failed"
    }
}
