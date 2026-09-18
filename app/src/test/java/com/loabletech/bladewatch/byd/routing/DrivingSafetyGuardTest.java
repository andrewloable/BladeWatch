package net.bladewatch.app.byd.routing;

import static net.bladewatch.app.byd.routing.DrivingSafetyGuard.Decision.ALLOW;
import static net.bladewatch.app.byd.routing.DrivingSafetyGuard.Decision.BLOCK_MOVING;
import static net.bladewatch.app.byd.routing.DrivingSafetyGuard.Decision.BLOCK_UNKNOWN;
import static org.junit.Assert.assertEquals;

import org.junit.Test;

/**
 * BladeWatch-2pnn.1: pure decision-table tests for {@link DrivingSafetyGuard}.
 * No Android, no singletons — every case passes gear/speed in directly.
 */
public class DrivingSafetyGuardTest {

    private static final int GEAR_P = 1;
    private static final int GEAR_R = 2;
    private static final int GEAR_N = 3;
    private static final int GEAR_D = 4;
    private static final int GEAR_M = 5;
    private static final int GEAR_S = 6;

    @Test
    public void parkedAndStationary_allows() {
        assertEquals(ALLOW, DrivingSafetyGuard.evaluate(GEAR_P, 0.0, true));
    }

    @Test
    public void parkedUnderJitterFloor_allows() {
        assertEquals(ALLOW, DrivingSafetyGuard.evaluate(GEAR_P, 0.4, true));
    }

    @Test
    public void parkedAtJitterFloor_blocksMoving() {
        assertEquals(BLOCK_MOVING, DrivingSafetyGuard.evaluate(GEAR_P, 0.6, true));
    }

    @Test
    public void parkedButFast_blocksMoving() {
        assertEquals(BLOCK_MOVING, DrivingSafetyGuard.evaluate(GEAR_P, 55.0, true));
    }

    @Test
    public void gearD_blocksMoving() {
        assertEquals(BLOCK_MOVING, DrivingSafetyGuard.evaluate(GEAR_D, 0.0, true));
    }

    @Test
    public void gearR_blocksMoving() {
        assertEquals(BLOCK_MOVING, DrivingSafetyGuard.evaluate(GEAR_R, 0.0, true));
    }

    @Test
    public void gearN_blocksMoving() {
        assertEquals(BLOCK_MOVING, DrivingSafetyGuard.evaluate(GEAR_N, 0.0, true));
    }

    @Test
    public void gearM_blocksMoving() {
        assertEquals(BLOCK_MOVING, DrivingSafetyGuard.evaluate(GEAR_M, 0.0, true));
    }

    @Test
    public void gearS_blocksMoving() {
        assertEquals(BLOCK_MOVING, DrivingSafetyGuard.evaluate(GEAR_S, 0.0, true));
    }

    @Test
    public void parkedWithUnknownSpeed_requireKnown_blocksUnknown() {
        assertEquals(BLOCK_UNKNOWN, DrivingSafetyGuard.evaluate(GEAR_P, Double.NaN, true));
    }

    @Test
    public void parkedWithUnknownSpeed_notRequireKnown_allows() {
        assertEquals(ALLOW, DrivingSafetyGuard.evaluate(GEAR_P, Double.NaN, false));
    }

    @Test
    public void unknownGearZero_blocksUnknown() {
        assertEquals(BLOCK_UNKNOWN, DrivingSafetyGuard.evaluate(0, 0.0, true));
    }

    @Test
    public void garbageGear_blocksUnknown() {
        assertEquals(BLOCK_UNKNOWN, DrivingSafetyGuard.evaluate(99, 0.0, true));
    }

    @Test
    public void drivingGearWithUnknownSpeed_blocksMoving_notUnknown() {
        // Rule 2 (known driving gear) must be evaluated before the NaN fallthrough.
        assertEquals(BLOCK_MOVING, DrivingSafetyGuard.evaluate(GEAR_D, Double.NaN, true));
    }

}
