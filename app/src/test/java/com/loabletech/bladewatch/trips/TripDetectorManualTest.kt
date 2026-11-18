package net.bladewatch.app.trips

import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNotSame
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-gklt.1: a trip the driver starts with the Start Trip button.
 *
 * It must ignore Park, the park debounce, ACC OFF and the minimum duration/distance, and end
 * only through [TripDetector.stopManualTrip] (or the 7-day safety net).
 */
class TripDetectorManualTest {

    private val detector = TripDetector()
    private val listener = Recorder()

    private class Recorder : TripDetector.TripListener {
        val started = mutableListOf<TripRecord>()
        val ended = mutableListOf<TripRecord>()
        val discarded = mutableListOf<TripRecord>()
        val order = mutableListOf<String>()
        override fun onTripStarted(trip: TripRecord) { started.add(trip); order.add("started") }
        override fun onTripEnded(trip: TripRecord) { ended.add(trip); order.add("ended") }
        override fun onTripDiscarded(trip: TripRecord, reason: String) {
            discarded.add(trip); order.add("discarded")
        }
    }

    init {
        detector.addListener(listener)
    }

    @After
    fun shutdown() {
        detector.shutdown()
    }

    @Test
    fun manualTrip_survivesParkGear() {
        detector.startManualTrip()
        detector.onGearChanged(GEAR_P)

        assertTrue(detector.isTripActive())
        assertTrue(detector.isManualTripActive())
        assertEquals(TripDetector.State.ACTIVE, detector.getState())
        assertTrue(listener.ended.isEmpty())
    }

    @Test
    fun manualTrip_shortIsNeverDiscarded() {
        detector.startManualTrip()
        assertTrue(detector.stopManualTrip())

        assertEquals(1, listener.ended.size)
        assertTrue(listener.ended[0].isManual)
        assertTrue(listener.discarded.isEmpty())
        assertFalse(detector.isTripActive())
    }

    @Test
    fun startManual_whileAutoActive_endsAutoThenStartsFresh() {
        detector.onGearChanged(GEAR_D)
        val auto = detector.getActiveTrip()!!
        assertFalse(auto.isManual)

        val manual = detector.startManualTrip()

        // The auto trip was finalized first (0 s / 0 km, so it is discarded by the normal rules).
        assertEquals(listOf("started", "discarded", "started"), listener.order)
        assertSame(auto, listener.discarded[0])
        assertNotSame(auto, manual)
        assertTrue(manual.isManual)
        assertTrue(detector.isManualTripActive())
    }

    @Test
    fun startManual_isIdempotent() {
        val first = detector.startManualTrip()
        val second = detector.startManualTrip()

        assertSame(first, second)
        assertEquals(1, listener.started.size)
    }

    @Test
    fun stopManual_withNoManualTrip_returnsFalse_andKeepsAutoTrip() {
        detector.onGearChanged(GEAR_D)

        assertFalse(detector.stopManualTrip())

        assertTrue(detector.isTripActive())
        assertFalse(detector.isManualTripActive())
    }

    @Test
    fun stopManual_withNoTripAtAll_returnsFalse() {
        assertFalse(detector.stopManualTrip())
        assertTrue(listener.order.isEmpty())
    }

    @Test
    fun accOff_keepsManual() {
        detector.startManualTrip()
        detector.onAccOff()

        assertTrue(detector.isManualTripActive())
        assertTrue(listener.ended.isEmpty())
    }

    @Test
    fun accOff_endsAutoTrip() {
        detector.onGearChanged(GEAR_D)
        detector.getActiveTrip()!!.apply {
            startTime = System.currentTimeMillis() - 90_000L
            distanceKm = 5.0
        }

        detector.onAccOff()

        assertFalse(detector.isTripActive())
        assertEquals(1, listener.ended.size)
    }

    @Test
    fun manualTrip_schedulesSevenDayAutoStop() {
        detector.startManualTrip()

        val delay = detector.manualAutoStopDelayMs()
        assertNotNull(delay)
        val sevenDays = 7L * 24 * 60 * 60 * 1000
        assertTrue("delay=$delay", delay!! in (sevenDays - 5_000)..sevenDays)

        detector.stopManualTrip()
        assertNull(detector.manualAutoStopDelayMs())
    }

    @Test
    fun scheduledAutoStop_endsTheManualTrip() {
        detector.startManualTrip()
        detector.scheduleManualAutoStop(50)

        val deadline = System.currentTimeMillis() + 5_000
        while (detector.isManualTripActive() && System.currentTimeMillis() < deadline) {
            Thread.sleep(20)
        }

        assertFalse(detector.isManualTripActive())
        assertEquals(1, listener.ended.size)
        assertTrue(listener.ended[0].isManual)
    }

    @Test
    fun shutdown_doesNotFinalizeManualTrip() {
        detector.startManualTrip()
        detector.shutdown()

        assertTrue(listener.ended.isEmpty())
        assertTrue(detector.isManualTripActive())
    }

    @Test
    fun autoTrip_isStillDiscardedWhenShort() {
        // Regression guard: manual handling must not leak into auto trips.
        detector.onGearChanged(GEAR_D)
        detector.finalizeActiveTrip()

        assertEquals(1, listener.discarded.size)
        assertFalse(listener.discarded[0].isManual)
    }

    private companion object {
        const val GEAR_P = 1
        const val GEAR_D = 4
    }
}
