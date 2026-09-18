package net.bladewatch.app.byd.routing;

/**
 * Pure motion-block decision function for vehicle-actuation commands.
 *
 * <p>No Android, no singletons, no state — callers pass gear and speed in directly so this
 * can be unit-tested without a device. See {@code BladeWatch-2pnn.2} for the caller that
 * wires this into {@link VehicleCommandRouter}.
 */
public final class DrivingSafetyGuard {

    /** Gear constants, duplicated by value from {@code GearMonitor} / {@code RecordingModeManager}. */
    private static final int GEAR_P = 1;
    private static final int GEAR_R = 2;
    private static final int GEAR_N = 3;
    private static final int GEAR_D = 4;
    private static final int GEAR_M = 5;
    private static final int GEAR_S = 6;

    private static final double SPEED_JITTER_FLOOR_KMH = 0.5;

    public enum Decision {
        ALLOW,
        BLOCK_MOVING,
        BLOCK_UNKNOWN
    }

    private DrivingSafetyGuard() {}

    public static Decision evaluate(int gear, double speedKmh, boolean requireKnownState) {
        boolean speedKnown = !Double.isNaN(speedKmh);

        if (speedKnown && speedKmh > SPEED_JITTER_FLOOR_KMH) {
            return Decision.BLOCK_MOVING;
        }
        if (isDrivingGear(gear)) {
            return Decision.BLOCK_MOVING;
        }
        if (gear == GEAR_P && speedKnown) {
            return Decision.ALLOW;
        }
        return requireKnownState ? Decision.BLOCK_UNKNOWN : Decision.ALLOW;
    }

    private static boolean isDrivingGear(int gear) {
        return gear == GEAR_R || gear == GEAR_N || gear == GEAR_D || gear == GEAR_M || gear == GEAR_S;
    }
}
