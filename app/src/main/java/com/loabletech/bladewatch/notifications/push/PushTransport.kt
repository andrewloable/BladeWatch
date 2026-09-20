package net.bladewatch.app.notifications.push

import net.bladewatch.app.logging.DaemonLogger
import java.io.ByteArrayOutputStream
import java.net.HttpURLConnection
import java.net.URL
import kotlin.math.max

/**
 * POSTs an encrypted Web Push payload to a subscription endpoint over a direct connection.
 */
object PushTransport {

    class Result @JvmOverloads constructor(
        @JvmField val status: Int,
        @JvmField val body: String,
        /** Server-suggested wait before retrying, in seconds. -1 = unspecified. */
        @JvmField val retryAfterSeconds: Int = -1
    ) {
        fun expired(): Boolean = status == 404 || status == 410

        fun ok(): Boolean = status in 200..299

        /** True for transient failures worth retrying (5xx, 408, 429). */
        fun transientFailure(): Boolean = status >= 500 || status == 408 || status == 429
    }

    private val logger: DaemonLogger = DaemonLogger.getInstance("PushTransport")

    @JvmStatic
    @Throws(Exception::class)
    fun send(
        endpoint: String,
        vapidJwt: String,
        vapidPubKeyB64Url: String,
        aes128gcmBody: ByteArray,
        ttlSeconds: Int
    ): Result {
        val conn = URL(endpoint).openConnection() as HttpURLConnection
        try {
            conn.requestMethod = "POST"
            conn.connectTimeout = 15_000
            conn.readTimeout = 15_000
            conn.doOutput = true
            conn.setRequestProperty("Content-Type", "application/octet-stream")
            conn.setRequestProperty("Content-Encoding", "aes128gcm")
            conn.setRequestProperty("TTL", ttlSeconds.toString())
            conn.setRequestProperty(
                "Authorization",
                "vapid t=$vapidJwt, k=$vapidPubKeyB64Url"
            )
            conn.setFixedLengthStreamingMode(aes128gcmBody.size)

            conn.outputStream.use { os ->
                os.write(aes128gcmBody)
            }

            val status = conn.responseCode
            var responseBody = ""
            try {
                val stream = if (status >= 400) conn.errorStream else conn.inputStream
                if (stream != null) {
                    val out = ByteArrayOutputStream()
                    val buf = ByteArray(1024)
                    while (true) {
                        val n = stream.read(buf)
                        if (n <= 0) break
                        out.write(buf, 0, n)
                        if (out.size() > 4096) break // cap log size
                    }
                    responseBody = String(out.toByteArray(), Charsets.UTF_8)
                }
            } catch (ignored: Exception) {
                logger.warn("Failed to read push response body: " + ignored.message)
            }

            var retryAfter = -1
            val hdr = conn.getHeaderField("Retry-After")
            if (hdr != null) {
                try {
                    retryAfter = max(0, hdr.trim().toInt())
                } catch (ignored: NumberFormatException) {
                    logger.warn("Failed to parse Retry-After header: " + ignored.message)
                }
            }
            return Result(status, responseBody, retryAfter)
        } finally {
            conn.disconnect()
        }
    }
}
