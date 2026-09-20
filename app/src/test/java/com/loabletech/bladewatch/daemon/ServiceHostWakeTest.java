package net.bladewatch.app.daemon;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

/**
 * BladeWatch-op3h: BYD's {@code ssc_skip} refuses a shell-UID service start when the target app
 * UID is not already running.
 *
 * <p>Measured on the head unit 2026-09-19. {@code am start-foreground-service} for
 * {@code LocationSidecarService} exited 255 with the misleading "Error: Not found; no service
 * started.", while logcat gave the real reason:
 *
 * <pre>
 * ActivityManager: ssc_skip startServiceLocked 2000 want to start 10073, package net.bladewatch.app
 * ActivityManager: UID 10073 is not running
 * ActivityManager: packageName 10073  NOT RUNNING
 * ActivityManager: ssc_skip startServiceLocked 2000 want to start 10073 package net.bladewatch.app ignored !!!
 * </pre>
 *
 * <p>This project already knows {@code ssc_skip} for suppressing BROADCASTS to the app package
 * (BladeWatch-5rew, and why the Flutter APK's {@code wakeServiceHost} uses an explicit component
 * start). It blocks SERVICE starts by the same rule. Starting the exported
 * {@code MainActivity} first brings UID 10073 up, after which the identical command exits 0 —
 * verified on the car, with {@code dumpsys} going from {@code app=null} to a live
 * {@code ProcessRecord}.
 *
 * <p>Without the sidecar there is no GPS push to the localhost IPC, so trips record a single
 * static point with no path.
 */
public class ServiceHostWakeTest {

    @Test
    public void aDeadServiceHostMustBeWokenFirst() {
        // pidof prints nothing and exits non-zero when the process is gone.
        assertTrue("no pid means ssc_skip will ignore the service start",
                SentryDaemon.needsServiceHostWake(null));
        assertTrue(SentryDaemon.needsServiceHostWake(""));
        assertTrue(SentryDaemon.needsServiceHostWake("   \n"));
    }

    @Test
    public void aLiveServiceHostIsNotRestarted() {
        // Verbatim from the device once the host was up.
        assertFalse("UID 10073 is already running, so the service start is permitted",
                SentryDaemon.needsServiceHostWake("8778"));
        assertFalse(SentryDaemon.needsServiceHostWake("8778\n"));
    }

    @Test
    public void shellNoiseIsNotMistakenForAPid() {
        // execShell returns combined output, so a failure message must not read as "alive" —
        // that would skip the wake and leave the service start to be silently ignored again.
        assertTrue(SentryDaemon.needsServiceHostWake("pidof: not found"));
        assertTrue(SentryDaemon.needsServiceHostWake("Permission Denial"));
    }
}
