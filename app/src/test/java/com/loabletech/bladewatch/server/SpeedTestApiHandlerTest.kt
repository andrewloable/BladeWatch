package net.bladewatch.app.server

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.charset.StandardCharsets

/**
 * BladeWatch-j6ra.1: `GET /speedtest/down?bytes=N`, the payload the companion's Diagnostics speed
 * test downloads. Called directly with a [ByteArrayOutputStream], the way [StillFrameRouteTest]
 * reaches its writer: the socket loop in HttpServer needs a running daemon.
 */
class SpeedTestApiHandlerTest {

    private class Reply(val handled: Boolean, val head: String, val body: ByteArray)

    private fun call(path: String, method: String = "GET"): Reply {
        val out = ByteArrayOutputStream()
        val handled = SpeedTestApiHandler.handle(method, path, out)
        val bytes = out.toByteArray()
        val end = indexOfHeaderEnd(bytes)
        return Reply(
            handled,
            String(bytes, 0, end, StandardCharsets.UTF_8),
            bytes.copyOfRange(end, bytes.size)
        )
    }

    /** Where the body starts; 0 for an empty reply, so a refused call reads as head "" and body "". */
    private fun indexOfHeaderEnd(bytes: ByteArray): Int {
        val marker = "\r\n\r\n".toByteArray(StandardCharsets.UTF_8)
        outer@ for (i in 0..bytes.size - marker.size) {
            for (j in marker.indices) {
                if (bytes[i + j] != marker[j]) continue@outer
            }
            return i + marker.size
        }
        return 0
    }

    @Test
    fun servesExactlyTheRequestedNumberOfBytes_acrossChunkBoundaries() {
        // 200 000 = three whole 64 KiB chunks and a partial fourth.
        val r = call("/speedtest/down?bytes=200000")

        assertTrue(r.handled)
        assertTrue("expected a 200, got: ${r.head}", r.head.startsWith("HTTP/1.1 200"))
        assertEquals(200000, r.body.size)
    }

    @Test
    fun contentLengthMatchesTheBody_soKeepAliveCanFindTheEnd() {
        val r = call("/speedtest/down?bytes=1234")

        assertTrue(r.head, r.head.contains("Content-Length: 1234\r\n"))
        assertEquals(1234, r.body.size)
    }

    @Test
    fun theHeadersMarkItAsAnUncacheableBinaryBody() {
        val r = call("/speedtest/down?bytes=10")

        assertTrue(r.head, r.head.contains("Content-Type: application/octet-stream\r\n"))
        assertTrue(r.head, r.head.contains("Cache-Control: no-store\r\n"))
        // A plain stream is not a KeepAliveStream, so it must say close (HttpResponse.connectionHeader).
        assertTrue(r.head, r.head.contains("Connection: close\r\n"))
    }

    @Test
    fun aRequestAboveTheCapIsClampedNotRefused() {
        val r = call("/speedtest/down?bytes=999999999")

        assertEquals(SpeedTestApiHandler.MAX_BYTES, r.body.size)
        assertTrue(r.head, r.head.contains("Content-Length: ${SpeedTestApiHandler.MAX_BYTES}\r\n"))
    }

    @Test
    fun zeroBytesIsAnEmptyReply_thePing() {
        val r = call("/speedtest/down?bytes=0")

        assertTrue(r.head, r.head.startsWith("HTTP/1.1 200"))
        assertTrue(r.head, r.head.contains("Content-Length: 0\r\n"))
        assertEquals(0, r.body.size)
    }

    @Test
    fun aMissingNonNumericOrNegativeSizeIsTreatedAsZero() {
        for (path in listOf(
            "/speedtest/down",
            "/speedtest/down?bytes=",
            "/speedtest/down?bytes=abc",
            "/speedtest/down?bytes=-5",
            "/speedtest/down?other=1"
        )) {
            val r = call(path)
            assertTrue("$path -> ${r.head}", r.head.startsWith("HTTP/1.1 200"))
            assertEquals(path, 0, r.body.size)
        }
    }

    @Test
    fun bytesIsFoundAmongOtherQueryParameters() {
        assertEquals(10, call("/speedtest/down?x=1&bytes=10&y=2").body.size)
    }

    @Test
    fun theBodyIsNotOneRepeatedByte_soACompressingHopCannotInflateTheNumber() {
        val body = call("/speedtest/down?bytes=65536").body

        assertTrue("body is a single repeated value", body.toSet().size > 1)
    }

    @Test
    fun anythingElseIsNotHandledAndNothingIsWritten() {
        for ((method, path) in listOf(
            "POST" to "/speedtest/down?bytes=10",
            "HEAD" to "/speedtest/down?bytes=10",
            "GET" to "/speedtest/up",
            "GET" to "/speedtest/"
        )) {
            val r = call(path, method)
            assertFalse("$method $path", r.handled)
            assertEquals("$method $path wrote a reply", "", r.head)
            assertEquals("$method $path wrote a body", 0, r.body.size)
        }
    }

    @Test
    fun theRouteIsBehindTheAuthGate() {
        // HttpServer runs AuthMiddleware.checkAuth before routeToHandlers unless the path is public.
        assertFalse(AuthMiddleware.isPublicPath("/speedtest/down?bytes=1"))
        assertFalse(AuthMiddleware.isPublicPath("/speedtest/down"))
    }

    /**
     * HttpServer's socket loop cannot run on the JVM (NoRestJsonRoutesTest reads it as text for the
     * same reason), so this is the only thing that fails if the route is never wired in. Also pins
     * that it stays off /api/, which NoRestJsonRoutesTest reserves for the JSON surface.
     */
    @Test
    fun httpServerDispatchesTheRouteToTheHandler() {
        val src = File(
            if (File("src/main/java").isDirectory) "src/main/java" else "app/src/main/java",
            "com/loabletech/bladewatch/server/HttpServer.kt"
        ).readText()

        assertTrue(src.contains("startsWith(\"/speedtest/\")"))
        assertTrue(src.contains("SpeedTestApiHandler.handle("))
    }
}
