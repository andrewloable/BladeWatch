package net.bladewatch.app.byd.routing;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;
import static net.bladewatch.app.byd.routing.VehicleCommandRouterInterlockTest.fixed;

import net.bladewatch.app.byd.BydDataCollector;
import net.bladewatch.app.byd.routing.VehicleCommandRouter.CommandResult;
import net.bladewatch.app.byd.routing.VehicleCommandRouter.Outcome;
import net.bladewatch.app.byd.routing.VehicleCommandRouter.VehicleCommand;

import org.junit.After;
import org.junit.Test;

/**
 * BladeWatch-2000.3: the screen on/off commands' directional interlock behaviour. Screen OFF
 * is gated exactly like every other command (see {@link VehicleCommandRouterInterlockTest});
 * screen ON must succeed even while the motion interlock would otherwise block, because
 * giving the driver their screen back is never the unsafe direction.
 *
 * <p>Uses stand-in {@link VehicleCommand} subclasses that flag whether {@code executeViaSdk}
 * ran, mirroring {@code VehicleCommandRouterInterlockTest.FlagCommand} -- real
 * {@code ScreenOnCommand}/{@code ScreenOffCommand} call into {@code BydDataCollector}'s BYD
 * reflection, which is not constructible in a plain JVM test; the router's gating logic
 * (what this test targets) does not depend on which concrete command class is passed in.
 */
public class VehicleCommandRouterScreenTest {

    private static final int GEAR_P = 1;
    private static final int GEAR_D = 4;

    private final VehicleCommandRouter router = VehicleCommandRouter.getInstance();

    @After
    public void clearInjectedMotionState() {
        router.setMotionStateForTest(null);
    }

    @Test
    public void screenOff_whileParked_invokesTheBacklightPath() {
        router.setMotionStateForTest(fixed(GEAR_P, 0.0, true));
        FlagScreenOffCommand cmd = new FlagScreenOffCommand();

        CommandResult result = router.execute(cmd);

        assertEquals(Outcome.SUCCESS, result.outcome);
        assertTrue("backlight-off path must have run", cmd.ran);
    }

    @Test
    public void screenOff_whileMoving_blocksAndNeverTouchesTheBacklightPath() {
        router.setMotionStateForTest(fixed(GEAR_D, 40.0, true));
        FlagScreenOffCommand cmd = new FlagScreenOffCommand();

        CommandResult result = router.execute(cmd);

        assertEquals(Outcome.BLOCKED_UNSAFE, result.outcome);
        assertFalse("backlight-off path must NOT have run", cmd.ran);
    }

    @Test
    public void screenOff_whileMotionUnknown_blocksAndNeverTouchesTheBacklightPath() {
        // Gear P but speed unknown (NaN), with a data source that requires a known state --
        // DrivingSafetyGuard's BLOCK_UNKNOWN branch.
        router.setMotionStateForTest(fixed(GEAR_P, Double.NaN, true));
        FlagScreenOffCommand cmd = new FlagScreenOffCommand();

        CommandResult result = router.execute(cmd);

        assertEquals(Outcome.BLOCKED_UNSAFE, result.outcome);
        assertFalse("backlight-off path must NOT have run", cmd.ran);
    }

    /**
     * The router-level tests above use stand-in FlagScreenOn/OffCommand classes, exercising
     * the router's generic {@code allowedWhileUnsafe()} mechanism without depending on the
     * real command classes (which call into BydDataCollector's BYD reflection). This test
     * closes the gap that leaves: that the REAL VehicleCommandRouter.ScreenOffCommand /
     * ScreenOnCommand are actually wired to the correct side of that mechanism. Caught during
     * this issue's own mutation check -- flipping ScreenOffCommand.allowedWhileUnsafe() to
     * true left every FlagScreenOffCommand-based test passing, because the mutation never
     * touched the class those tests use.
     */
    @Test
    public void theRealCommandClasses_haveTheCorrectDirectionalGate() {
        assertFalse("ScreenOffCommand must stay gated normally -- turning the panel off while "
                        + "moving is the unsafe direction",
                new VehicleCommandRouter.ScreenOffCommand().allowedWhileUnsafe());
        assertTrue("ScreenOnCommand must bypass the block -- giving the driver their screen "
                        + "back is never the unsafe direction",
                new VehicleCommandRouter.ScreenOnCommand().allowedWhileUnsafe());
    }

    @Test
    public void screenOn_whileMoving_succeeds() {
        // The gate is directional and this test pins that.
        router.setMotionStateForTest(fixed(GEAR_D, 40.0, true));
        FlagScreenOnCommand cmd = new FlagScreenOnCommand();

        CommandResult result = router.execute(cmd);

        assertEquals(Outcome.SUCCESS, result.outcome);
        assertTrue("backlight-on path must have run even while moving", cmd.ran);
    }

    private static final class FlagScreenOffCommand extends VehicleCommand {
        boolean ran = false;
        public String name() { return "test-screen-off"; }
        public boolean hasSdkPath() { return true; }
        public boolean executeViaSdk(BydDataCollector c) {
            ran = true;
            return true;
        }
    }

    private static final class FlagScreenOnCommand extends VehicleCommand {
        boolean ran = false;
        public String name() { return "test-screen-on"; }
        public boolean hasSdkPath() { return true; }
        public boolean allowedWhileUnsafe() { return true; }
        public boolean executeViaSdk(BydDataCollector c) {
            ran = true;
            return true;
        }
    }
}
