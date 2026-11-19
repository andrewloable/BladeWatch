package net.bladewatch.app.trips

import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-gklt.2: pause, resume and restore on the telemetry recorder.
 *
 * Sampling itself reads the HAL singletons and is not exercised here; these tests pin the
 * bookkeeping that the manual-trip lifecycle depends on.
 */
class TripTelemetryRecorderManualTest {

    private val recorder = TripTelemetryRecorder(null)

    @After
    fun stop() {
        try { recorder.stopRecording() } catch (ignored: Throwable) { }
    }

    @Test
    fun `restore seeds the running stats`() {
        val seed = TripTelemetryRecorder.Stats(7.75, 96, 54_321L, 900L)

        recorder.restoreRecording(1_700_000_000_123L, seed, startPaused = true)

        assertEquals(seed, recorder.statsSnapshot())
        assertEquals(96, recorder.maxSpeedKmh)
        assertEquals(54_321.0 / 900.0, recorder.avgSpeedKmh, 1e-9)
    }

    @Test
    fun `restore can start paused and resume later`() {
        recorder.restoreRecording(1L, TripTelemetryRecorder.Stats(0.0, 0, 0, 0), startPaused = true)
        assertTrue(recorder.isPaused)

        recorder.resume()
        assertFalse(recorder.isPaused)

        recorder.pause()
        assertTrue(recorder.isPaused)
    }

    @Test
    fun `pause and resume are no-ops when not recording`() {
        recorder.pause()
        recorder.resume()
        assertFalse(recorder.isPaused)
    }

    @Test
    fun `stop clears the paused flag`() {
        recorder.restoreRecording(2L, TripTelemetryRecorder.Stats(0.0, 0, 0, 0), startPaused = true)
        recorder.stopRecording()
        assertFalse(recorder.isPaused)
    }
}
