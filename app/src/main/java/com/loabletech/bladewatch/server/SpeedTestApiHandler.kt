package net.bladewatch.app.server

import java.io.OutputStream
import java.util.Random

/**
 * `GET /speedtest/down?bytes=N`: the payload the companion's Diagnostics speed test downloads to
 * measure the link to the car (BladeWatch-j6ra).
 *
 * Plain HTTP, not Connect, and NOT under `/api/`: the body is binary (base64 inside JSON would
 * distort the number being measured), and NoRestJsonRoutesTest reserves `/api/` for the JSON
 * surface. Authenticated like every other route -- it is not on the public list.
 *
 * Download only. HttpServer buffers a request body into memory before it checks auth, so an upload
 * route would need streaming-body plumbing first.
 *
 * The header block is built from CONCATENATED string literals on purpose: ResponseFramingTest
 * reads it as source text.
 */
object SpeedTestApiHandler {

    const val DOWN_PATH = "/speedtest/down"

    /** The most one request may ask for. Larger asks are clamped, not refused. */
    const val MAX_BYTES = 32 * 1024 * 1024

    private const val CHUNK_BYTES = 64 * 1024

    // Random, written once and reused: incompressible if a hop compresses, and N bytes are never
    // allocated. Not secret, so java.util.Random rather than SecureRandom.
    private val chunk = ByteArray(CHUNK_BYTES).also { Random().nextBytes(it) }

    @JvmStatic
    @Throws(Exception::class)
    fun handle(method: String, path: String, out: OutputStream): Boolean {
        if (method != "GET" || path.substringBefore('?') != DOWN_PATH) return false
        val bytes = requestedBytes(path)
        val headers = "HTTP/1.1 200 OK\r\n" +
            "Content-Type: application/octet-stream\r\n" +
            "Content-Length: " + bytes + "\r\n" +
            "Cache-Control: no-store\r\n" +
            HttpResponse.connectionHeader(out) + "\r\n"
        out.write(headers.toByteArray())
        var left = bytes
        while (left > 0) {
            val n = minOf(left, CHUNK_BYTES)
            out.write(chunk, 0, n)
            left -= n
        }
        out.flush()
        return true
    }

    /** `bytes=N` from the query, clamped to 0..[MAX_BYTES]; missing, non-numeric or negative is 0 (a ping). */
    private fun requestedBytes(path: String): Int =
        path.substringAfter('?', "").split('&')
            .firstOrNull { it.startsWith("bytes=") }
            ?.substringAfter('=')?.toLongOrNull()
            ?.coerceIn(0, MAX_BYTES.toLong())?.toInt() ?: 0
}
