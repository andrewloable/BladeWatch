package net.bladewatch.app.daemon;

import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

/**
 * BladeWatch-boat: {@code restartLocationService} decided whether an {@code am} call had failed
 * with {@code result.contains("Error")}. The real failure output on this head unit contains no
 * such substring, so a permission refusal read as a success and the WARN never fired.
 *
 * <p>The inputs below are verbatim from the device (2026-09-19), not synthesised — the entire
 * defect was that the real shape did not match the expected one. Compare BladeWatch-t87k, the
 * same mistake in {@code BydDeviceHelper.statusForFailure}, where a test fed a bare
 * {@code SecurityException} that reflection never actually produces.
 */
public class ShellResultClassifierTest {

    /** Verbatim device output, trimmed to the lines that matter. */
    private static final String PERMISSION_DENIAL =
            "Broadcasting: Intent { act=android.intent.action.BOOT_COMPLETED flg=0x400000 "
            + "cmp=net.bladewatch.app/.receiver.LocationBootReceiver }\n"
            + "Security exception: Permission Denial: not allowed to send broadcast "
            + "android.intent.action.BOOT_COMPLETED from pid=22631, uid=2000\n"
            + "java.lang.SecurityException: Permission Denial: not allowed to send broadcast "
            + "android.intent.action.BOOT_COMPLETED from pid=22631, uid=2000\n"
            + "\tat com.android.server.am.ActivityManagerService.broadcastIntentLocked"
            + "(ActivityManagerService.java:15827)";

    @Test
    public void theRealPermissionDenialIsRecognisedAsFailure() {
        assertTrue("this exact output was being read as a success",
                ShellResultClassifier.isFailure(PERMISSION_DENIAL));
    }

    @Test
    public void theOldSubstringCheckWouldHaveMissedIt() {
        // Documents precisely why the bug survived review: the word is simply not there.
        assertFalse("'Error' does not appear in the real denial output",
                PERMISSION_DENIAL.contains("Error"));
        assertFalse(PERMISSION_DENIAL.isEmpty());
    }

    @Test
    public void ordinaryFailureShapesAreStillCaught() {
        assertTrue(ShellResultClassifier.isFailure("Error: Not found; no service started"));
        assertTrue(ShellResultClassifier.isFailure("java.lang.IllegalStateException: boom"));
        assertTrue(ShellResultClassifier.isFailure("Exception occurred while executing"));
        assertTrue(ShellResultClassifier.isFailure(""));
        assertTrue(ShellResultClassifier.isFailure(null));
    }

    @Test
    public void aGenuineSuccessIsNotFlaggedAsFailure() {
        assertFalse(ShellResultClassifier.isFailure(
                "Starting service: Intent { cmp=net.bladewatch.app/.services.LocationSidecarService }"));
        assertFalse(ShellResultClassifier.isFailure("Broadcast completed: result=0"));
    }
}
