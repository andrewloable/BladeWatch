package net.bladewatch.app.trips

import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * BladeWatch-fpdz.4: capturing the fuel and lifetime counters at both ends of a trip.
 *
 * `TripDetector` needs a live `VehicleDataMonitor` and a gear signal, so the capture rule is
 * extracted as a pure function and tested here. The two properties worth pinning are both
 * about not inventing data:
 *
 *  - **The fuel pair is gated on drivetrain.** A BEV has no fuel system, so its fuel readings
 *    are meaningless and must stay at the unavailable sentinel rather than being recorded as
 *    zeroes that later look like a measurement.
 *  - **The electricity counter is NOT gated.** It is meaningful on both drivetrains and it is
 *    what lets a trip shorter than SoC resolution report a real figure.
 *
 * Kotlin reaching `TripDetector`'s package-private statics works because this file declares
 * the same package and compiles into the same module — Kotlin cannot DECLARE package-private,
 * but it can read Java's.
 */
class TripDetectorFuelCaptureTest {

    private companion object {
        const val EPS = 1e-9
        const val UNAVAILABLE = -1.0
    }

    @Test
    fun `phev captures all three readings at both ends`() {
        val t = TripRecord()
        TripDetector.captureStart(t, true, 80.0, 1200.25, 5000.0)
        assertEquals(80.0, t.fuelPctStart, EPS)
        assertEquals(1200.25, t.fuelConStart, EPS)
        assertEquals(5000.0, t.elecConStart, EPS)

        TripDetector.captureEnd(t, true, 74.5, 1203.75, 5008.4)
        assertEquals(74.5, t.fuelPctEnd, EPS)
        assertEquals(1203.75, t.fuelConEnd, EPS)
        assertEquals(5008.4, t.elecConEnd, EPS)
    }

    /**
     * A BEV must record no fuel at all, but MUST still record electricity. Writing 0s into the
     * fuel fields here would make a BEV look like a PHEV that burned nothing.
     */
    @Test
    fun `bev records electricity but no fuel`() {
        val t = TripRecord()
        TripDetector.captureStart(t, false, 0.0, 0.0, 5000.0)
        TripDetector.captureEnd(t, false, 0.0, 0.0, 5008.4)

        assertEquals("BEV fuel percent must stay unavailable", UNAVAILABLE, t.fuelPctStart, EPS)
        assertEquals("BEV fuel counter must stay unavailable", UNAVAILABLE, t.fuelConStart, EPS)
        assertEquals("BEV fuel percent must stay unavailable", UNAVAILABLE, t.fuelPctEnd, EPS)
        assertEquals("BEV fuel counter must stay unavailable", UNAVAILABLE, t.fuelConEnd, EPS)

        assertEquals("electricity is meaningful on a BEV", 5000.0, t.elecConStart, EPS)
        assertEquals("electricity is meaningful on a BEV", 5008.4, t.elecConEnd, EPS)
    }

    /** A HAL that returns NaN has told us nothing; that is the unavailable sentinel. */
    @Test
    fun `NaN becomes the unavailable sentinel`() {
        val t = TripRecord()
        TripDetector.captureStart(t, true, Double.NaN, Double.NaN, Double.NaN)
        assertEquals(UNAVAILABLE, t.fuelPctStart, EPS)
        assertEquals(UNAVAILABLE, t.fuelConStart, EPS)
        assertEquals(UNAVAILABLE, t.elecConStart, EPS)
    }

    /**
     * THE case the sentinel convention exists for. An empty tank reads 0, and 0 is a real
     * measurement — it must not be folded into "unavailable".
     */
    @Test
    fun `a real zero is kept as zero not as unavailable`() {
        val emptyTank = TripRecord()
        TripDetector.captureStart(emptyTank, true, 0.0, 1200.0, 5000.0)
        assertEquals("an empty tank is a reading, not a missing value",
            0.0, emptyTank.fuelPctStart, EPS)

        val freshCounters = TripRecord()
        TripDetector.captureStart(freshCounters, true, 40.0, 0.0, 0.0)
        assertEquals("a fresh lifetime counter reads 0", 0.0, freshCounters.fuelConStart, EPS)
        assertEquals("a fresh lifetime counter reads 0", 0.0, freshCounters.elecConStart, EPS)
    }

    /** A negative reading is not physical; treat it as unavailable rather than storing it. */
    @Test
    fun `negative readings are treated as unavailable`() {
        val t = TripRecord()
        TripDetector.captureStart(t, true, -5.0, -2.0, -3.0)
        assertEquals(UNAVAILABLE, t.fuelPctStart, EPS)
        assertEquals(UNAVAILABLE, t.fuelConStart, EPS)
        assertEquals(UNAVAILABLE, t.elecConStart, EPS)
    }

    /** Capturing one end must never disturb the other. */
    @Test
    fun `capturing the end does not disturb the start readings`() {
        val t = TripRecord()
        TripDetector.captureStart(t, true, 80.0, 1200.25, 5000.0)
        TripDetector.captureEnd(t, true, 74.5, 1203.75, 5008.4)
        assertEquals(80.0, t.fuelPctStart, EPS)
        assertEquals(1200.25, t.fuelConStart, EPS)
        assertEquals(5000.0, t.elecConStart, EPS)
    }
}
