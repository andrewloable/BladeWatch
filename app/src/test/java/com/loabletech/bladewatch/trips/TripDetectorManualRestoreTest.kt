package net.bladewatch.app.trips

import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

/** BladeWatch-gklt.2: re-opening a manual trip after a daemon restart. */
class TripDetectorManualRestoreTest {

    private val detector = TripDetector()
    private val started = mutableListOf<TripRecord>()
    private val ended = mutableListOf<TripRecord>()

    init {
        detector.addListener(object : TripDetector.TripListener {
            override fun onTripStarted(trip: TripRecord) { started.add(trip) }
            override fun onTripEnded(trip: TripRecord) { ended.add(trip) }
            override fun onTripDiscarded(trip: TripRecord, reason: String) {}
        })
    }

    @After
    fun shutdown() {
        detector.shutdown()
    }

    private fun savedTrip(ageMs: Long) = TripRecord().apply {
        startTime = System.currentTimeMillis() - ageMs
    }

    @Test
    fun `restore reopens the trip silently`() {
        val trip = savedTrip(3_600_000L)

        assertTrue(detector.restoreManualTrip(trip, 12_345.6))

        assertTrue(detector.isManualTripActive())
        assertSame(trip, detector.getActiveTrip())
        assertEquals(TripDetector.State.ACTIVE, detector.getState())
        assertEquals(12_345.6, detector.getStartOdometerKm(), 1e-9)
        assertTrue("no second onTripStarted", started.isEmpty())
    }

    @Test
    fun `restore re-arms the auto stop with the remaining time`() {
        val sixDays = 6L * 24 * 60 * 60 * 1000
        detector.restoreManualTrip(savedTrip(sixDays), -1.0)

        val delay = detector.manualAutoStopDelayMs()
        assertNotNull(delay)
        val oneDay = 24L * 60 * 60 * 1000
        assertTrue("delay=$delay", delay!! in (oneDay - 10_000)..oneDay)
    }

    @Test
    fun `restore of a trip past seven days ends it at once`() {
        val eightDays = 8L * 24 * 60 * 60 * 1000
        detector.restoreManualTrip(savedTrip(eightDays), -1.0)

        assertFalse(detector.isManualTripActive())
        assertEquals(1, ended.size)
        assertTrue(ended[0].isManual)
    }

    @Test
    fun `restore does nothing while a trip is already open`() {
        val live = detector.startManualTrip()

        assertFalse(detector.restoreManualTrip(savedTrip(1_000L), -1.0))

        assertSame(live, detector.getActiveTrip())
    }

    @Test
    fun `restored trip ignores park and acc off like any manual trip`() {
        detector.restoreManualTrip(savedTrip(60_000L), -1.0)

        detector.onGearChanged(1)
        detector.onAccOff()

        assertTrue(detector.isManualTripActive())
        assertTrue(ended.isEmpty())
    }
}
