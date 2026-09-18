package net.bladewatch.app.monitor;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import org.junit.After;
import org.junit.Test;

/**
 * BladeWatch-nmao.2: {@link GearMonitor#getEffectiveGear()} must report {@code GEAR_P} while
 * charging, while {@link GearMonitor#getCurrentGear()} (the safety-critical raw value read by
 * the motion interlock) must never be touched by charging state.
 */
public class GearMonitorChargingTest {

    private static final int GEAR_P = 1;
    private static final int GEAR_D = 4;

    private final GearMonitor gearMonitor = GearMonitor.getInstance();

    @After
    public void resetSharedSingletons() {
        gearMonitor.setCurrentGearForTest(GEAR_P);
        // NOT onPowerDisconnected(): it latches a 15s (UNPLUG_OVERRIDE_MS) "recent unplug"
        // override that forces isCharging()->false regardless of bmsState, which poisoned
        // the very next test's updateBmsState(CHARGING) call in an earlier version of this
        // test (charging_rawGearD_effectiveGearIsP failed at this line, ~5ms after the prior
        // test's cleanup, with the override still active). A terminal BMS state (READY) flips
        // fusedCharging with no timed side effect.
        ChargingDetector.getInstance().updateBmsState(ChargingStateData.CHARGING_BATTERY_STATE_READY);
    }

    @Test
    public void notCharging_rawGearD_effectiveGearIsD() {
        ChargingDetector.getInstance().updateBmsState(ChargingStateData.CHARGING_BATTERY_STATE_READY);
        gearMonitor.setCurrentGearForTest(GEAR_D);

        assertEquals(GEAR_D, gearMonitor.getEffectiveGear());
    }

    @Test
    public void charging_rawGearD_effectiveGearIsP() {
        gearMonitor.setCurrentGearForTest(GEAR_D);
        ChargingDetector.getInstance().updateBmsState(ChargingStateData.CHARGING_BATTERY_STATE_CHARGING);

        assertEquals(GEAR_P, gearMonitor.getEffectiveGear());
    }

    @Test
    public void charging_rawGearD_currentGearStillReportsD() {
        // The safety pin: getCurrentGear() must NOT be touched by charging state, or the
        // motion interlock (which reads getCurrentGear(), never getEffectiveGear()) could be
        // told a genuinely-moving car is parked.
        gearMonitor.setCurrentGearForTest(GEAR_D);
        ChargingDetector.getInstance().updateBmsState(ChargingStateData.CHARGING_BATTERY_STATE_CHARGING);

        assertEquals(GEAR_D, gearMonitor.getCurrentGear());
    }

    @Test
    public void charging_rawGearP_bothReportP() {
        gearMonitor.setCurrentGearForTest(GEAR_P);
        ChargingDetector.getInstance().updateBmsState(ChargingStateData.CHARGING_BATTERY_STATE_CHARGING);

        assertEquals(GEAR_P, gearMonitor.getCurrentGear());
        assertEquals(GEAR_P, gearMonitor.getEffectiveGear());
    }

    /**
     * Structural guard, modelled on {@code NoUngatedTrunkOpenTest}: the motion interlock must
     * keep reading the raw gear. Declared as a Gradle test input via
     * {@code app/build.gradle.kts}'s blanket {@code inputs.dir("src/main/java")} on all Test
     * tasks (see the comment there) -- without it this guard would go UP-TO-DATE precisely
     * when someone wires getEffectiveGear() into the interlock, and never re-run.
     */
    @Test
    public void motionInterlockNeverReferencesEffectiveGear() throws IOException {
        assertFalse("DrivingSafetyGuard must never read getEffectiveGear() -- it takes gear as "
                        + "a plain int and must not itself decide which gear source is safe",
                read("byd/routing/DrivingSafetyGuard.java").contains("getEffectiveGear"));
        assertFalse("VehicleCommandRouter's motion interlock must read the raw gear "
                        + "(GearMonitor.getCurrentGear()), not the charging-adjusted "
                        + "getEffectiveGear() -- a car genuinely in a driving gear at a "
                        + "charger must never be reported as parked to the interlock",
                read("byd/routing/VehicleCommandRouter.java").contains("getEffectiveGear"));
    }

    private static String read(String relative) throws IOException {
        Path p = sourceRoot().resolve("com/loabletech/bladewatch").resolve(relative);
        assertTrue("missing source file: " + p, Files.isRegularFile(p));
        return new String(Files.readAllBytes(p), StandardCharsets.UTF_8);
    }

    private static Path sourceRoot() {
        Path p = Path.of("src/main/java");
        if (!Files.isDirectory(p)) p = Path.of("app/src/main/java");
        assertTrue("could not locate the app sources from " + new File(".").getAbsolutePath(),
                Files.isDirectory(p));
        return p;
    }
}
