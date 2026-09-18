package net.bladewatch.app.byd.routing

import net.bladewatch.app.byd.BydDataCollector
import net.bladewatch.app.byd.routing.VehicleCommandRouter.Outcome
import net.bladewatch.app.byd.routing.VehicleCommandRouter.VehicleCommand
import net.bladewatch.app.byd.routing.VehicleCommandRouterInterlockTest.fixed
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-2000.1: router-level behaviour for the four newly-exposed climate primitives
 * (front/rear defrost, wind mode, cycle mode). The action-string parsing itself is tested
 * separately in `net.bladewatch.app.server.ClimateCommandParserTest` -- package-private for
 * the same reason `parseLightsRequest`/`parseAdasRequest` are, so its own test lives alongside
 * it in the server package, mirroring `LightsAdasParserTest`.
 *
 * "Reaches the right collector method, and no other" (this issue's own required-tests
 * wording) cannot be verified behaviourally: `BydDataCollector` has a private constructor
 * (singleton, no Mockito/Robolectric in this project) and none of the existing VehicleCommand
 * subclasses -- not one, checked -- are tested this way either, for the same reason. Verified
 * instead as a source-text structural guard in
 * `net.bladewatch.app.manifest.ClimateCommandCollectorWiringTest`, matching
 * NoUngatedActuationTest/StealthPanelBacklightStillWiredTest's identical shape.
 */
class ClimateCommandRoutingTest {

    private val router = VehicleCommandRouter.getInstance()

    @After
    fun clearInjectedMotionState() {
        router.setMotionStateForTest(null)
    }

    @Test
    fun `all four new commands have sdk path`() {
        assertTrue(VehicleCommandRouter.FrontDefrostCommand(true).hasSdkPath())
        assertTrue(VehicleCommandRouter.RearDefrostCommand(true).hasSdkPath())
        assertTrue(VehicleCommandRouter.ClimateSetWindModeCommand(1).hasSdkPath())
        assertTrue(VehicleCommandRouter.ClimateSetCycleModeCommand(1).hasSdkPath())
    }

    @Test
    fun `executeViaSdk returning false produces FAILED, not SUCCESS`() {
        router.setMotionStateForTest(fixed(GEAR_P, 0.0, true))
        val refusing = object : VehicleCommand() {
            override fun name() = "test-refusing-command"
            override fun hasSdkPath() = true
            override fun executeViaSdk(collector: BydDataCollector) = false
        }

        val result = router.execute(refusing)

        assertEquals(Outcome.FAILED, result.outcome)
    }

    companion object {
        private const val GEAR_P = 1
    }
}
