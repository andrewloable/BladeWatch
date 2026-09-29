package net.bladewatch.app.server

import net.bladewatch.app.byd.BydDataCollector
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * The Vehicle screen's two climate temperatures, and the two ways they were wrong.
 *
 * BladeWatch-gkjl: the "inside temperature" was read from getTemprature(1), the driver's setpoint.
 * BladeWatch-eh3u: its replacement, getTemprature(4), is the SDK's AC_TEMPERATURE_OUT -- measured
 * 2026-09-25 at 33 while the owner's thermometer in the cabin read 28 and the instrument's outside
 * temperature read 32. The car exposes no cabin temperature, so the screen shows the outside air
 * and says so.
 */
class ClimateTempSelectionTest {

    /** `Int.MIN_VALUE + 1003` -- what the SDK returns for a position it cannot serve. */
    private val unavailable = -2147482645

    @Test
    fun reportsTheSetpointAndTheOutsideAir() {
        val t = VehicleControlApiHandler.selectClimateTemps(setpointRaw = 24, outsideC = 32.0)
        assertEquals(24, t.setpointC)
        assertEquals(32.0, t.outsideTempC!!, 0.001)
    }

    @Test
    fun omitsWhatTheCarCannotServe() {
        val t = VehicleControlApiHandler.selectClimateTemps(setpointRaw = unavailable, outsideC = Double.NaN)
        assertNull("a wrong number is worse than no number -- the UI hides the row", t.setpointC)
        assertNull(t.outsideTempC)
    }

    @Test
    fun theSetpointIsPositionOne() {
        assertEquals(1, BydDataCollector.AC_TEMP_POS_SETPOINT)
    }
}
