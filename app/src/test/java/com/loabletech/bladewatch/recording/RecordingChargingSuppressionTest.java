package net.bladewatch.app.recording;

import static net.bladewatch.app.recording.RecordingModeManager.Mode.CONTINUOUS;
import static net.bladewatch.app.recording.RecordingModeManager.Mode.DRIVE_MODE;
import static net.bladewatch.app.recording.RecordingModeManager.Mode.NONE;
import static net.bladewatch.app.recording.RecordingModeManager.Mode.PROXIMITY_GUARD;
import static net.bladewatch.app.recording.RecordingModeManager.isSuppressedByCharging;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

/**
 * BladeWatch-nmao.1: pure policy tests for {@link RecordingModeManager#isSuppressedByCharging}.
 *
 * <p>{@code RecordingModeManager} cannot be constructed under plain JUnit (no Mockito/Robolectric
 * in this project, per a repo-wide search -- it needs a real {@code Context} and
 * {@code GpuSurveillancePipeline}, and its constructor spawns background threads that probe real
 * BYD hardware via reflection). Per this issue's own fallback instruction, the suppression
 * decision is extracted into this pure static and tested in isolation; the wiring around it
 * (constructor seeding, the ChargingDetector listener, activateMode's gate, shutdown's
 * unregister) is verified by code inspection instead and recorded in the close reason.
 */
public class RecordingChargingSuppressionTest {

    @Test
    public void continuous_notCharging_notSuppressed() {
        assertFalse(isSuppressedByCharging(CONTINUOUS, false));
    }

    @Test
    public void continuous_charging_suppressed() {
        assertTrue(isSuppressedByCharging(CONTINUOUS, true));
    }

    @Test
    public void driveMode_notCharging_notSuppressed() {
        assertFalse(isSuppressedByCharging(DRIVE_MODE, false));
    }

    @Test
    public void driveMode_charging_suppressed() {
        assertTrue(isSuppressedByCharging(DRIVE_MODE, true));
    }

    /**
     * The test that must fail if someone widens the suppression later: a car at a public
     * charger is exactly when radar triggers matter most, so PROXIMITY_GUARD must stay armed.
     */
    @Test
    public void proximityGuard_charging_stillArmed() {
        assertFalse(isSuppressedByCharging(PROXIMITY_GUARD, true));
    }

    @Test
    public void none_charging_notSuppressed() {
        // NONE is already off; charging must not be able to mark it "suppressed".
        assertFalse(isSuppressedByCharging(NONE, true));
    }

    @Test
    public void chargingEndingWhileDriveMode_noLongerSuppressed() {
        // Models "charging goes true then false while in DRIVE_MODE": the same stateless
        // predicate must flip back on the second call with no reset step of its own.
        assertTrue(isSuppressedByCharging(DRIVE_MODE, true));
        assertFalse(isSuppressedByCharging(DRIVE_MODE, false));
    }
}
