package net.bladewatch.app.trips

import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-nmao.3: [TripDetector] must fan events out to multiple listeners without
 * evicting [net.bladewatch.app.trips.TripAnalyticsManager]'s existing subscription, and must
 * keep the distance-provider query separate from the listener list (there is no sensible
 * "which listener answers" once more than one is registered).
 */
class TripDetectorListenersTest {

    private val detector = TripDetector()

    @After
    fun shutdown() {
        // Avoid leaking the detector's debounce scheduler thread across tests.
        detector.shutdown()
    }

    private class RecordingListener : TripDetector.TripListener {
        val started = mutableListOf<TripRecord>()
        val ended = mutableListOf<TripRecord>()
        val discarded = mutableListOf<Pair<TripRecord, String>>()
        val order = mutableListOf<String>()

        override fun onTripStarted(trip: TripRecord) {
            started.add(trip)
            order.add("started")
        }

        override fun onTripEnded(trip: TripRecord) {
            ended.add(trip)
            order.add("ended")
        }

        override fun onTripDiscarded(trip: TripRecord, reason: String) {
            discarded.add(trip to reason)
            order.add("discarded")
        }
    }

    private class ThrowingListener : TripDetector.TripListener {
        override fun onTripStarted(trip: TripRecord) = throw RuntimeException("boom-started")
        override fun onTripEnded(trip: TripRecord) = throw RuntimeException("boom-ended")
        override fun onTripDiscarded(trip: TripRecord, reason: String) =
            throw RuntimeException("boom-discarded")
    }

    /** Drives a full start-then-end sequence via the real gear state machine and debounce. */
    private fun driveStartThenEnd() {
        detector.onGearChanged(GEAR_D)
        // finalizeActiveTrip() is normally reached via the 120s debounce timer; call it
        // directly (as shutdown() and the timer itself both do) rather than waiting on a
        // real 120-second sleep in a unit test.
        detector.getActiveTrip()!!.apply {
            // Meet the minimum thresholds directly -- the state machine's own gear/GPS/HAL
            // reads are exercised elsewhere; this test is about listener fan-out.
            startTime = System.currentTimeMillis() - 90_000L
            distanceKm = 5.0
        }
        detector.finalizeActiveTrip()
    }

    @Test
    fun twoListeners_bothReceiveStartedThenEnded_inOrder() {
        val a = RecordingListener()
        val b = RecordingListener()
        detector.addListener(a)
        detector.addListener(b)

        driveStartThenEnd()

        assertEquals(listOf("started", "ended"), a.order)
        assertEquals(listOf("started", "ended"), b.order)
    }

    @Test
    fun listenerThrowingFromOnTripEnded_doesNotBlockTheOtherListener() {
        val throwing = ThrowingListener()
        val recording = RecordingListener()
        detector.addListener(throwing)
        detector.addListener(recording)

        driveStartThenEnd()

        assertEquals(1, recording.ended.size)
    }

    @Test
    fun removeListener_stopsDeliveryToThatListenerOnly() {
        val a = RecordingListener()
        val b = RecordingListener()
        detector.addListener(a)
        detector.addListener(b)
        detector.removeListener(a)

        driveStartThenEnd()

        assertTrue(a.started.isEmpty())
        assertTrue(a.ended.isEmpty())
        assertEquals(1, b.started.size)
        assertEquals(1, b.ended.size)
    }

    @Test
    fun onTripDiscarded_isDeliveredToBothListeners() {
        val a = RecordingListener()
        val b = RecordingListener()
        detector.addListener(a)
        detector.addListener(b)

        detector.onGearChanged(GEAR_D)
        // Leave startTime/distanceKm at defaults (0) -- below both minimum thresholds, so
        // finalizeActiveTrip() must discard rather than end the trip.
        detector.finalizeActiveTrip()

        assertEquals(1, a.discarded.size)
        assertEquals(1, b.discarded.size)
        assertTrue(a.ended.isEmpty())
        assertFalse(a.discarded.isEmpty())
    }

    @Test
    fun distanceProvider_consultedExactlyOncePerFinalisation_regardlessOfListenerCount() {
        var calls = 0
        detector.setDistanceProvider {
            calls++
            5.0
        }
        detector.addListener(RecordingListener())
        detector.addListener(RecordingListener())
        detector.addListener(RecordingListener())

        detector.onGearChanged(GEAR_D)
        // Leave distanceKm at the default 0 so resolveDistance() must fall back to the
        // distance provider (odometer is unavailable in a JVM test -- no real HAL).
        detector.getActiveTrip()!!.startTime = System.currentTimeMillis() - 90_000L
        detector.finalizeActiveTrip()

        assertEquals(1, calls)
    }

    companion object {
        private const val GEAR_D = 4
    }
}
