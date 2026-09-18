package net.bladewatch.app.server

import net.bladewatch.app.byd.routing.VehicleCommandRouter
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-2000.1: [VehicleControlApiHandler.buildClimateCommand] -- the pure parser
 * extracted from `handleClimate`'s action switch, exercising the four new actions. Mirrors
 * [LightsAdasParserTest]'s shape (same package, for the same package-private access reason).
 */
class ClimateCommandParserTest {

    @Test
    fun `front defrost on parses to FrontDefrostCommand true`() {
        val cmd = VehicleControlApiHandler.buildClimateCommand("front_defrost", JSONObject("{\"on\":true}"))
        assertNotNull(cmd)
        assertTrue(cmd is VehicleCommandRouter.FrontDefrostCommand)
        assertTrue((cmd as VehicleCommandRouter.FrontDefrostCommand).on)
    }

    @Test
    fun `front defrost off parses to FrontDefrostCommand false`() {
        val cmd = VehicleControlApiHandler.buildClimateCommand("front_defrost", JSONObject("{\"on\":false}"))
        assertNotNull(cmd)
        assertFalse((cmd as VehicleCommandRouter.FrontDefrostCommand).on)
    }

    @Test
    fun `rear defrost on parses to RearDefrostCommand true`() {
        val cmd = VehicleControlApiHandler.buildClimateCommand("rear_defrost", JSONObject("{\"on\":true}"))
        assertNotNull(cmd)
        assertTrue(cmd is VehicleCommandRouter.RearDefrostCommand)
        assertTrue((cmd as VehicleCommandRouter.RearDefrostCommand).on)
    }

    @Test
    fun `rear defrost off parses to RearDefrostCommand false`() {
        val cmd = VehicleControlApiHandler.buildClimateCommand("rear_defrost", JSONObject("{\"on\":false}"))
        assertNotNull(cmd)
        assertFalse((cmd as VehicleCommandRouter.RearDefrostCommand).on)
    }

    @Test
    fun `set_wind_mode parses to ClimateSetWindModeCommand with the given value`() {
        val cmd = VehicleControlApiHandler.buildClimateCommand("set_wind_mode", JSONObject("{\"windMode\":3}"))
        assertNotNull(cmd)
        assertTrue(cmd is VehicleCommandRouter.ClimateSetWindModeCommand)
        assertEquals(3, (cmd as VehicleCommandRouter.ClimateSetWindModeCommand).mode)
    }

    @Test
    fun `set_cycle_mode parses to ClimateSetCycleModeCommand with the given value`() {
        val cmd = VehicleControlApiHandler.buildClimateCommand("set_cycle_mode", JSONObject("{\"cycleMode\":2}"))
        assertNotNull(cmd)
        assertTrue(cmd is VehicleCommandRouter.ClimateSetCycleModeCommand)
        assertEquals(2, (cmd as VehicleCommandRouter.ClimateSetCycleModeCommand).mode)
    }

    @Test
    fun `pre-existing actions still parse correctly after the extraction`() {
        // BladeWatch-2000.1 extracted buildClimateCommand out of handleClimate's inline
        // switch; pin that the five pre-existing actions were carried over unchanged.
        assertTrue(
            VehicleControlApiHandler.buildClimateCommand("power_on", JSONObject("{\"setpointC\":21}"))
                is VehicleCommandRouter.ClimateOnCommand
        )
        assertTrue(
            VehicleControlApiHandler.buildClimateCommand("power_off", JSONObject("{}"))
                is VehicleCommandRouter.ClimateOffCommand
        )
        assertTrue(
            VehicleControlApiHandler.buildClimateCommand("set_temp", JSONObject("{\"setpointC\":24}"))
                is VehicleCommandRouter.ClimateSetTempCommand
        )
        assertTrue(
            VehicleControlApiHandler.buildClimateCommand("set_fan", JSONObject("{\"fanLevel\":5}"))
                is VehicleCommandRouter.ClimateSetFanCommand
        )
        assertTrue(
            VehicleControlApiHandler.buildClimateCommand("max_cooling", JSONObject("{\"maxCooling\":true}"))
                is VehicleCommandRouter.ClimateMaxCoolingCommand
        )
    }

    @Test
    fun `unknown action returns null, does not throw`() {
        val cmd = VehicleControlApiHandler.buildClimateCommand("not_a_real_action", JSONObject("{}"))
        assertNull(cmd)
    }
}
