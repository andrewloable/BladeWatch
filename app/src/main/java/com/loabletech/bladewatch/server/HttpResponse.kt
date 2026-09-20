package net.bladewatch.app.server

import org.json.JSONObject
import java.io.File
import java.io.FileInputStream
import java.io.OutputStream
import java.io.RandomAccessFile
import java.nio.charset.StandardCharsets
import kotlin.math.min

/**
 * HTTP response utilities, shared by all handlers.
 *
 * The header blocks below are built from CONCATENATED string literals on purpose: ResponseFramingTest
 * reads them as source text to check that every response frames its body, and it would not
 * recognise an interpolated status line.
 */
object HttpResponse {

    /**
     * The `Connection:` header line for this response, terminated with CRLF.
     *
     * BladeWatch-67h8: returns `keep-alive` only when the server has wrapped the stream in a
     * [KeepAliveStream] AND decided this response may be followed by another on the same socket.
     * Any other stream — a test, a handler reached by a path that predates this, a future caller —
     * gets `close`, which is what every response emitted before keep-alive existed and is never
     * wrong.
     */
    @JvmStatic
    fun connectionHeader(out: OutputStream?): String {
        val keep = out is KeepAliveStream && out.isKeepAlive
        return if (keep) "Connection: keep-alive\r\n" else "Connection: close\r\n"
    }

    @JvmStatic
    @Throws(Exception::class)
    fun sendError(out: OutputStream, code: Int, message: String) {
        // BladeWatch-67h8: the body was previously delimited only by the connection close.
        // Keep-alive cannot frame that, so the length is explicit.
        val body = message.toByteArray(StandardCharsets.UTF_8)
        val response = "HTTP/1.1 " + code + " " + message + "\r\n" +
            "Content-Type: text/plain\r\n" +
            "Content-Length: " + body.size + "\r\n" +
            connectionHeader(out) + "\r\n"
        out.write(response.toByteArray(StandardCharsets.UTF_8))
        out.write(body)
        out.flush()
    }

    @JvmStatic
    @Throws(Exception::class)
    fun sendHtml(out: OutputStream, html: String) {
        val body = html.toByteArray(StandardCharsets.UTF_8)
        val headers = "HTTP/1.1 200 OK\r\n" +
            "Content-Type: text/html; charset=utf-8\r\n" +
            "Content-Length: " + body.size + "\r\n" +
            connectionHeader(out) + "\r\n"
        out.write(headers.toByteArray())
        out.write(body)
        out.flush()
    }

    @JvmStatic
    @Throws(Exception::class)
    fun sendJson(out: OutputStream, json: String) {
        val body = json.toByteArray(StandardCharsets.UTF_8)
        val headers = "HTTP/1.1 200 OK\r\n" +
            "Content-Type: application/json\r\n" +
            "Cache-Control: no-cache, no-store\r\n" +
            "Content-Length: " + body.size + "\r\n" +
            connectionHeader(out) + "\r\n"
        out.write(headers.toByteArray())
        out.write(body)
        out.flush()
    }

    @JvmStatic
    @Throws(Exception::class)
    fun sendJsonSuccess(out: OutputStream) {
        sendJson(out, "{\"success\":true}")
    }

    /**
     * CORS preflight response for OPTIONS requests. Browsers send OPTIONS before a cross-origin
     * POST/PUT/DELETE with a JSON content-type.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun sendCorsPreflightResponse(out: OutputStream) {
        sendError(out, 403, "CORS preflight denied")
        out.flush()
    }

    @JvmStatic
    @Throws(Exception::class)
    fun sendJsonError(out: OutputStream, error: String?) {
        val response = JSONObject()
        response.put("success", false)
        response.put("error", error)
        sendJson(out, response.toString())
    }

    /** HTTP 403 Forbidden with a JSON body carrying the error field. */
    @JvmStatic
    @Throws(Exception::class)
    fun sendJsonForbidden(out: OutputStream, error: String?) {
        val response = JSONObject()
        response.put("success", false)
        response.put("error", error)
        val body = response.toString().toByteArray(StandardCharsets.UTF_8)
        val headers = "HTTP/1.1 403 Forbidden\r\n" +
            "Content-Type: application/json\r\n" +
            "Cache-Control: no-cache, no-store\r\n" +
            "Content-Length: " + body.size + "\r\n" +
            connectionHeader(out) + "\r\n"
        out.write(headers.toByteArray())
        out.write(body)
        out.flush()
    }

    /** HTTP 400 Bad Request with a JSON body carrying the error field. */
    @JvmStatic
    @Throws(Exception::class)
    fun sendJsonBadRequest(out: OutputStream, error: String?) {
        val response = JSONObject()
        response.put("success", false)
        response.put("error", error)
        val body = response.toString().toByteArray(StandardCharsets.UTF_8)
        val headers = "HTTP/1.1 400 Bad Request\r\n" +
            "Content-Type: application/json\r\n" +
            "Cache-Control: no-cache, no-store\r\n" +
            "Content-Length: " + body.size + "\r\n" +
            connectionHeader(out) + "\r\n"
        out.write(headers.toByteArray())
        out.write(body)
        out.flush()
    }

    /** 401 Unauthorized with a JSON body. */
    @JvmStatic
    @Throws(Exception::class)
    fun sendUnauthorized(out: OutputStream, json: String) {
        val body = json.toByteArray(StandardCharsets.UTF_8)
        val headers = "HTTP/1.1 401 Unauthorized\r\n" +
            "Content-Type: application/json\r\n" +
            "WWW-Authenticate: Bearer realm=\"BYD Champ\"\r\n" +
            "Content-Length: " + body.size + "\r\n" +
            connectionHeader(out) + "\r\n"
        out.write(headers.toByteArray())
        out.write(body)
        out.flush()
    }

    /** 302 redirect. */
    @JvmStatic
    @Throws(Exception::class)
    fun sendRedirect(out: OutputStream, location: String) {
        val response = "HTTP/1.1 302 Found\r\n" +
            "Location: " + location + "\r\n" +
            "Content-Length: 0\r\n" +
            connectionHeader(out) + "\r\n"
        out.write(response.toByteArray())
        out.flush()
    }

    /** JSON response with a single Set-Cookie header for the JWT. */
    @JvmStatic
    @JvmOverloads
    @Throws(Exception::class)
    fun sendJsonWithCookie(
        out: OutputStream,
        json: String,
        cookieName: String,
        cookieValue: String,
        maxAgeSeconds: Int,
        secure: Boolean = false
    ) {
        sendJsonWithCookies(
            out, json,
            arrayOf(buildCookie(cookieName, cookieValue, maxAgeSeconds, true, secure))
        )
    }

    @JvmStatic
    @Throws(Exception::class)
    fun sendJsonWithCookies(out: OutputStream, json: String, cookies: Array<String?>?) {
        val body = json.toByteArray(StandardCharsets.UTF_8)
        val headers = "HTTP/1.1 200 OK\r\n" +
            "Content-Type: application/json\r\n" +
            buildSetCookieHeaders(cookies) +
            "Content-Length: " + body.size + "\r\n" +
            connectionHeader(out) + "\r\n"
        out.write(headers.toByteArray())
        out.write(body)
        out.flush()
    }

    private fun buildCookie(
        cookieName: String,
        cookieValue: String,
        maxAgeSeconds: Int,
        httpOnly: Boolean,
        secure: Boolean
    ): String {
        val cookie = StringBuilder()
        cookie.append(cookieName).append("=").append(cookieValue)
            .append("; Path=/; Max-Age=").append(maxAgeSeconds)
            .append("; SameSite=Lax")
        if (httpOnly) cookie.append("; HttpOnly")
        if (secure) cookie.append("; Secure")
        return cookie.toString()
    }

    private fun buildSetCookieHeaders(cookies: Array<String?>?): String {
        if (cookies == null || cookies.isEmpty()) return ""
        val sb = StringBuilder()
        for (cookie in cookies) {
            if (cookie.isNullOrEmpty()) continue
            sb.append("Set-Cookie: ").append(cookie).append("\r\n")
        }
        return sb.toString()
    }

    /**
     * Cache directive used for finalized event recordings. Filenames are unique-per-event and the
     * file is immutable once renamed from .mp4.tmp, so a long max-age plus immutable lets the
     * client's HTTP cache satisfy repeat playback locally. The ETag invalidates it if the
     * underlying file is ever replaced.
     */
    private const val VIDEO_CACHE_CONTROL = "private, max-age=86400, immutable"

    /**
     * Backwards-compat overload — callers that don't compute an ETag get the old "no-cache"
     * behaviour, so a /video/ caller opting out of caching (e.g. a live stream) just calls the
     * no-ETag version.
     */
    @JvmStatic
    @JvmOverloads
    @Throws(Exception::class)
    fun sendVideo(out: OutputStream, file: File, etag: String? = null) {
        if (!file.exists()) {
            sendError(out, 404, "File not found")
            return
        }

        val headers = StringBuilder()
        headers.append("HTTP/1.1 200 OK\r\n")
            .append("Content-Type: video/mp4\r\n")
            .append("Content-Length: ").append(file.length()).append("\r\n")
            .append("Accept-Ranges: bytes\r\n")
        if (etag != null) {
            headers.append("Cache-Control: ").append(VIDEO_CACHE_CONTROL).append("\r\n")
                .append("ETag: ").append(etag).append("\r\n")
        } else {
            headers.append("Cache-Control: no-cache\r\n")
        }
        headers.append(connectionHeader(out)).append("\r\n")
        out.write(headers.toString().toByteArray())

        // Stream the file in chunks
        FileInputStream(file).use { fis ->
            val buffer = ByteArray(16384)
            while (true) {
                val count = fis.read(buffer)
                if (count == -1) break
                out.write(buffer, 0, count)
            }
        }
        out.flush()
    }

    @JvmStatic
    @JvmOverloads
    @Throws(Exception::class)
    fun sendVideoRange(
        out: OutputStream,
        file: File,
        start: Long,
        endRequested: Long,
        etag: String? = null
    ) {
        if (!file.exists()) {
            sendError(out, 404, "File not found")
            return
        }

        val fileLength = file.length()
        if (start < 0 || start >= fileLength) {
            sendError(out, 416, "Range Not Satisfiable")
            return
        }
        var end = endRequested
        if (end < 0 || end >= fileLength) {
            end = fileLength - 1
        }
        if (end < start) {
            end = start
        }
        val contentLength = end - start + 1

        val headers = StringBuilder()
        headers.append("HTTP/1.1 206 Partial Content\r\n")
            .append("Content-Type: video/mp4\r\n")
            .append("Content-Length: ").append(contentLength).append("\r\n")
            .append("Content-Range: bytes ").append(start).append("-").append(end)
            .append("/").append(fileLength).append("\r\n")
            .append("Accept-Ranges: bytes\r\n")
        if (etag != null) {
            headers.append("Cache-Control: ").append(VIDEO_CACHE_CONTROL).append("\r\n")
                .append("ETag: ").append(etag).append("\r\n")
        } else {
            headers.append("Cache-Control: no-cache\r\n")
        }
        headers.append(connectionHeader(out)).append("\r\n")
        out.write(headers.toString().toByteArray())

        RandomAccessFile(file, "r").use { raf ->
            raf.seek(start)
            val buffer = ByteArray(16384)
            var remaining = contentLength
            while (remaining > 0) {
                val toRead = min(buffer.size.toLong(), remaining).toInt()
                val read = raf.read(buffer, 0, toRead)
                if (read <= 0) break
                out.write(buffer, 0, read)
                remaining -= read.toLong()
            }
        }
        out.flush()
    }

    /**
     * 304 Not Modified — no body. Echoes the ETag so the client knows the cached entry is still
     * authoritative. Cache-Control reaffirms the caching policy in case the client previously saw
     * no-cache.
     *
     * DELIBERATELY carries no `Content-Length`, and must not be given one "for consistency" now
     * that keep-alive has landed (BladeWatch-67h8). A 304 never has a body, so there is nothing to
     * frame; `Content-Length: 0` would be a lie about the resource's size rather than about this
     * response, and RFC 7230 only permits a 304 to echo the length the 200 would have had.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun sendNotModified(out: OutputStream, etag: String) {
        val headers = StringBuilder()
        headers.append("HTTP/1.1 304 Not Modified\r\n")
            .append("ETag: ").append(etag).append("\r\n")
            .append("Cache-Control: ").append(VIDEO_CACHE_CONTROL).append("\r\n")
            .append(connectionHeader(out)).append("\r\n")
        out.write(headers.toString().toByteArray())
        out.flush()
    }

    /** Send an image file with caching headers. */
    @JvmStatic
    @Throws(Exception::class)
    fun sendImage(out: OutputStream, file: File, contentType: String) {
        if (!file.exists()) {
            sendError(out, 404, "Image not found")
            return
        }

        val headers = "HTTP/1.1 200 OK\r\n" +
            "Content-Type: " + contentType + "\r\n" +
            "Content-Length: " + file.length() + "\r\n" +
            "Cache-Control: public, max-age=86400\r\n" +
            connectionHeader(out) + "\r\n"
        out.write(headers.toByteArray())

        FileInputStream(file).use { fis ->
            val buffer = ByteArray(8192)
            while (true) {
                val count = fis.read(buffer)
                if (count == -1) break
                out.write(buffer, 0, count)
            }
        }
        out.flush()
    }

    /** Send image bytes directly with caching headers. */
    @JvmStatic
    @Throws(Exception::class)
    fun sendImageBytes(out: OutputStream, data: ByteArray, contentType: String) {
        val headers = "HTTP/1.1 200 OK\r\n" +
            "Content-Type: " + contentType + "\r\n" +
            "Content-Length: " + data.size + "\r\n" +
            "Cache-Control: public, max-age=86400\r\n" +
            connectionHeader(out) + "\r\n"
        out.write(headers.toByteArray())
        out.write(data)
        out.flush()
    }
}
