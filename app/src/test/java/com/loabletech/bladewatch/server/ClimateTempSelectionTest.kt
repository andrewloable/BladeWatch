package net.bladewatch.app.server

import net.bladewatch.app.byd.BydDataCollector
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * BladeWatch-gkjl: the climate setpoint and the cabin temperature must come from DIFFERENT
 * positions of `BYDAutoAcDevice.getTemprature(int)`.
 *
 * Both used to be read from position 1, so the Vehicle screen reported the driver's chosen
 * setpoint as the cabin reading — it tracked the temperature stepper exactly and never rose on
 * a hot day. The owner spotted it: the screen said 24.0C while the car was above 30C.
 *
 * Measured on the head unit 2026-09-20 (AC off, parked, all zones set to 24, cabin hot):
 *
 *     position 0 -> -2147482645   1 -> 24   2 -> 24   3 -> 24   4 -> 36   5,6 -> -2147482645
 *
 * so the numbers below are the real ones, not invented.
 */
class ClimateTempSelectionTest {

    /** `Int.MIN_VALUE + 1003` — what the SDK returns for a position it cannot serve. */
    private val unavailable = -2147482645

    @Test
    fun readsTheSetpointAndTheCabinFromTheirOwnPositions() {
        val t = VehicleControlApiHandler.selectClimateTemps(
            setpointRaw = 24, cabinRaw = 36, cachedInsideC = Double.NaN,
        )
        assertEquals(24, t.setpointC)
        assertEquals(36.0, t.insideTempC!!, 0.001)
    }

    /**
     * The regression itself. If the cabin were ever read from the setpoint position again the
     * two would be equal for any real vehicle state, which is the signature of this bug.
     */
    @Test
    fun theCabinReadingIsNotTheSetpoint() {
        val t = VehicleControlApiHandler.selectClimateTemps(
            setpointRaw = 24, cabinRaw = 36, cachedInsideC = Double.NaN,
        )
        assertEquals(
            "cabin temperature came back equal to the setpoint — position 1 is being read for both again",
            false,
            t.setpointC!!.toDouble() == t.insideTempC,
        )
    }

    @Test
    fun omitsTheCabinReadingWhenTheSensorIsUnavailable() {
        val t = VehicleControlApiHandler.selectClimateTemps(
            setpointRaw = 24, cabinRaw = unavailable, cachedInsideC = Double.NaN,
        )
        assertEquals(24, t.setpointC)
        assertNull("a wrong number is worse than no number — the UI hides the row", t.insideTempC)
    }

    @Test
    fun fallsBackToTheCollectorsCachedCabinValue() {
        val t = VehicleControlApiHandler.selectClimateTemps(
            setpointRaw = 24, cabinRaw = unavailable, cachedInsideC = 31.5,
        )
        assertEquals(31.5, t.insideTempC!!, 0.001)
    }

    @Test
    fun omitsTheSetpointWhenItIsOutOfRange() {
        val t = VehicleControlApiHandler.selectClimateTemps(
            setpointRaw = unavailable, cabinRaw = 36, cachedInsideC = Double.NaN,
        )
        assertNull(t.setpointC)
        assertEquals(36.0, t.insideTempC!!, 0.001)
    }

    /**
     * A closed car in direct sun passes 60C easily, and the old guard was -50..60 — it would
     * have discarded a real reading on exactly the days the number matters most.
     */
    @Test
    fun acceptsACabinHotterThanTheOldSixtyDegreeCeiling() {
        val t = VehicleControlApiHandler.selectClimateTemps(
            setpointRaw = 24, cabinRaw = 72, cachedInsideC = Double.NaN,
        )
        assertEquals(72.0, t.insideTempC!!, 0.001)
    }

    @Test
    fun theTwoPositionsAreDistinctAndTheRangesDiffer() {
        assertEquals(1, BydDataCollector.AC_TEMP_POS_SETPOINT)
        assertEquals(4, BydDataCollector.AC_TEMP_POS_CABIN)
        assertEquals(
            "setpoint and cabin must never read the same position",
            false,
            BydDataCollector.AC_TEMP_POS_SETPOINT == BydDataCollector.AC_TEMP_POS_CABIN,
        )
    }
}
