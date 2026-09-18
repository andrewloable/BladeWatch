package net.bladewatch.app.byd.routing;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotEquals;
import static org.junit.Assert.assertTrue;

import net.bladewatch.app.byd.BydDataCollector;
import net.bladewatch.app.byd.routing.VehicleCommandRouter.CommandResult;
import net.bladewatch.app.byd.routing.VehicleCommandRouter.MotionState;
import net.bladewatch.app.byd.routing.VehicleCommandRouter.Outcome;
import net.bladewatch.app.byd.routing.VehicleCommandRouter.VehicleCommand;

import org.junit.After;
import org.junit.Test;

/**
 * BladeWatch-2pnn.2: {@link VehicleCommandRouter#execute} must refuse to touch the SDK
 * while {@link DrivingSafetyGuard} says the vehicle is moving (or its state is unknown).
 */
public class VehicleCommandRouterInterlockTest {

    private static final int GEAR_P = 1;
    private static final int GEAR_N = 3;
    private static final int GEAR_D = 4;

    private final VehicleCommandRouter router = VehicleCommandRouter.getInstance();

    @After
    public void clearInjectedMotionState() {
        router.setMotionStateForTest(null);
    }

    @Test
    public void parked_runsCommandAndReturnsSuccess() {
        router.setMotionStateForTest(fixed(GEAR_P, 0.0, true));
        FlagCommand cmd = new FlagCommand();

        CommandResult result = router.execute(cmd);

        assertEquals(Outcome.SUCCESS, result.outcome);
        assertTrue("executeViaSdk must have run", cmd.ran);
    }

    @Test
    public void moving_blocksAndNeverTouchesSdk() {
        router.setMotionStateForTest(fixed(GEAR_D, 40.0, true));
        FlagCommand cmd = new FlagCommand();

        CommandResult result = router.execute(cmd);

        assertEquals(Outcome.BLOCKED_UNSAFE, result.outcome);
        assertFalse("executeViaSdk must NOT have run", cmd.ran);
    }

    @Test
    public void parkedButRolling_blocks() {
        // Gear P but 3.0 km/h -- e.g. rolling on a slope.
        router.setMotionStateForTest(fixed(GEAR_P, 3.0, true));
        FlagCommand cmd = new FlagCommand();

        CommandResult result = router.execute(cmd);

        assertEquals(Outcome.BLOCKED_UNSAFE, result.outcome);
        assertFalse(cmd.ran);
    }

    @Test
    public void gearNeutral_blocks() {
        router.setMotionStateForTest(fixed(GEAR_N, 0.0, true));
        FlagCommand cmd = new FlagCommand();

        CommandResult result = router.execute(cmd);

        assertEquals(Outcome.BLOCKED_UNSAFE, result.outcome);
        assertFalse(cmd.ran);
    }

    @Test
    public void noSdkPath_whileParked_remainsNotSupported() {
        router.setMotionStateForTest(fixed(GEAR_P, 0.0, true));

        CommandResult result = router.execute(new NoSdkCommand());

        assertEquals(Outcome.NOT_SUPPORTED, result.outcome);
    }

    @Test
    public void blockedMessage_isNotTheNotSupportedMessage() {
        router.setMotionStateForTest(fixed(GEAR_D, 40.0, true));

        CommandResult result = router.execute(new FlagCommand());

        assertEquals(Outcome.BLOCKED_UNSAFE, result.outcome);
        assertNotEquals(VehicleCommandRouter.notSupportedMessage(), result.displayMessage);
        assertFalse(result.displayMessage.isEmpty());
    }

    static MotionState fixed(int gear, double speedKmh, boolean requireKnownState) {
        return new MotionState() {
            public int gear() { return gear; }
            public double speedKmh() { return speedKmh; }
            public boolean requireKnownState() { return requireKnownState; }
        };
    }

    private static final class FlagCommand extends VehicleCommand {
        boolean ran = false;
        public String name() { return "test-flag-command"; }
        public boolean hasSdkPath() { return true; }
        public boolean executeViaSdk(BydDataCollector c) {
            ran = true;
            return true;
        }
    }

    private static final class NoSdkCommand extends VehicleCommand {
        public String name() { return "test-no-sdk-command"; }
    }
}
