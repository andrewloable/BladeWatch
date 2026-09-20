package net.bladewatch.app.server

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.ByteArrayOutputStream
import java.nio.charset.StandardCharsets

/**
 * BladeWatch-y78o.1: the still-frame fallback route. [StreamingApiHandler.sendStillFrame] is
 * package-visible specifically so this can call it directly with fake bytes, the same way
 * ClimateCommandParserTest reaches VehicleControlApiHandler's package-private parser --
 * CameraDaemon.getGpuPipeline() (handleStillFrame's own caller) needs a running daemon, so only
 * the response-writing half is unit-testable here.
 */
class StillFrameRouteTest {

    private fun responseText(bytes: ByteArray) = String(bytes, StandardCharsets.UTF_8)

    @Test
    fun withRetainedFramePresent_returns200WithTheFrameBytesAndCorrectContentType() {
        val jpeg = byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 1, 2, 3)
        val out = ByteArrayOutputStream()

        StreamingApiHandler.sendStillFrame(out, jpeg)

        val bytes = out.toByteArray()
        val headerEnd = indexOfHeaderEnd(bytes)
        val header = String(bytes, 0, headerEnd, StandardCharsets.UTF_8)
        assertTrue("expected a 200 status line, got: $header", header.startsWith("HTTP/1.1 200"))
        assertTrue("expected an image/jpeg content type, got: $header", header.contains("Content-Type: image/jpeg"))
        val body = bytes.copyOfRange(headerEnd, bytes.size)
        assertTrue("body did not end with the frame bytes", body.contentEquals(jpeg))
    }

    @Test
    fun withNoFrameRetainedYet_null_returnsAnExplicitNon200_neverA200WithEmptyBody() {
        val out = ByteArrayOutputStream()

        StreamingApiHandler.sendStillFrame(out, null)

        val response = responseText(out.toByteArray())
        assertFalse("a null frame must never produce a 200", response.startsWith("HTTP/1.1 200"))
    }

    @Test
    fun withNoFrameRetainedYet_empty_returnsAnExplicitNon200_neverA200WithEmptyBody() {
        val out = ByteArrayOutputStream()

        StreamingApiHandler.sendStillFrame(out, ByteArray(0))

        val response = responseText(out.toByteArray())
        assertFalse("a zero-length frame must never produce a 200", response.startsWith("HTTP/1.1 200"))
    }

    @Test
    fun theStillFrameRoute_isNotOnTheUnauthenticatedWhitelist() {
        // Same as every other /api/stream/* route: HttpServer runs AuthMiddleware.checkAuth
        // before any handler dispatch, UNLESS the path is on this whitelist. Calling the real
        // method (not a text guard) is a genuine behavioural assertion.
        assertFalse(AuthMiddleware.isPublicPath("/api/stream/still"))
    }

    private fun indexOfHeaderEnd(bytes: ByteArray): Int {
        val marker = "\r\n\r\n".toByteArray(StandardCharsets.UTF_8)
        outer@ for (i in 0..bytes.size - marker.size) {
            for (j in marker.indices) {
                if (bytes[i + j] != marker[j]) continue@outer
            }
            return i + marker.size
        }
        throw AssertionError("no header/body separator found in response")
    }
}
