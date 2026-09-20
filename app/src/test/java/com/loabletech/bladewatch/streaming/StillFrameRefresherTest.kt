package net.bladewatch.app.streaming

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.util.concurrent.Executors

/**
 * BladeWatch-y78o.1: a still-frame fallback for browsers with no video decoder. The mechanism
 * is "retain a reference to the most recent already-encoded frame" -- HTTP requests only ever
 * read [StillFrameRefresher.current], which never encodes; encoding happens exclusively inside
 * [StillFrameRefresher.tick], driven by a scheduled timer decoupled from camera FPS. These tests
 * exercise [tick] directly (the same `internal` test-visibility pattern as
 * ScreenAutoRecoveryTest's onSample) rather than waiting on a real scheduler.
 */
class StillFrameRefresherTest {

    private fun refresher(mosaicSource: () -> ByteArray?, encoder: JpegEncoder) =
        StillFrameRefresher(mosaicSource, 640, 480, encoder, 5000L, Executors.newSingleThreadScheduledExecutor())

    @Test
    fun tick_withMosaicFramePresent_encodesAndRetainsIt() {
        var encodeCalls = 0
        val r = refresher(
            mosaicSource = { byteArrayOf(1, 2, 3) },
            encoder = JpegEncoder { rgb, w, h ->
                encodeCalls++
                assertEquals(640, w)
                assertEquals(480, h)
                byteArrayOf(0xFF.toByte(), 0xD8.toByte(), rgb[0])
            },
        )

        r.tick()

        assertEquals(1, encodeCalls)
        assertArrayEquals(byteArrayOf(0xFF.toByte(), 0xD8.toByte(), 1), r.current())
    }

    @Test
    fun tick_withNoMosaicFrameYet_skipsEncodeAndLeavesNoFrameRetained() {
        var encodeCalls = 0
        val r = refresher(
            mosaicSource = { null },
            encoder = JpegEncoder { _, _, _ -> encodeCalls++; byteArrayOf(1) },
        )

        r.tick()

        assertEquals(0, encodeCalls)
        assertNull(r.current())
    }

    @Test
    fun current_calledRepeatedlyBetweenTicks_neverInvokesTheEncoder() {
        var encodeCalls = 0
        val r = refresher(
            mosaicSource = { byteArrayOf(9) },
            encoder = JpegEncoder { _, _, _ -> encodeCalls++; byteArrayOf(9) },
        )

        r.tick()
        assertEquals(1, encodeCalls)

        // Repeated reads -- simulating repeated HTTP requests with no new tick between them --
        // must never call the encoder again.
        r.current()
        r.current()
        r.current()
        assertEquals(1, encodeCalls)
    }

    @Test
    fun oneHundredTicks_theRetainedFrameIsReplacedNotAccumulated() {
        var lastEncoded = 0
        val r = refresher(
            mosaicSource = { byteArrayOf(1) },
            encoder = JpegEncoder { _, _, _ -> lastEncoded++; byteArrayOf(lastEncoded.toByte()) },
        )

        repeat(100) { r.tick() }

        // Exactly the 100th frame is held -- not a growing list of all 100.
        assertArrayEquals(byteArrayOf(100), r.current())
        assertEquals(100, lastEncoded)
    }

    @Test
    fun stop_clearsTheRetainedFrame() {
        val r = refresher(
            mosaicSource = { byteArrayOf(1) },
            encoder = JpegEncoder { _, _, _ -> byteArrayOf(1) },
        )
        r.tick()
        assertArrayEquals(byteArrayOf(1), r.current())

        r.stop()

        assertNull(r.current())
    }

    @Test
    fun tick_whenEncoderReturnsNull_leavesThePreviouslyRetainedFrameInPlace() {
        var shouldFail = false
        val r = refresher(
            mosaicSource = { byteArrayOf(1) },
            encoder = JpegEncoder { _, _, _ -> if (shouldFail) null else byteArrayOf(7) },
        )
        r.tick()
        assertArrayEquals(byteArrayOf(7), r.current())

        shouldFail = true
        r.tick()

        // A transient encode failure must not blank out a still-good previous frame.
        assertArrayEquals(byteArrayOf(7), r.current())
    }
}
