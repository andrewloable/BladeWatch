package net.bladewatch.app.launcher

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-6jj1: shell fragments for killing and probing daemons that cannot kill or
 * mis-answer about the ADB shell issuing them.
 *
 * ## The trap, measured on the head unit 2026-09-15
 *
 * toybox `pkill -f` / `pgrep -f` match the pattern as a literal SUBSTRING of every
 * `/proc/<pid>/cmdline`. Every one of these commands arrives as `adb shell <script>`, so the
 * issuing shell's cmdline IS the script, pattern included — it matches itself.
 *
 * ```
 * $ adb shell "echo start; pkill -9 -f 'bwprobe_marker_xyz'; echo SHOULD PRINT"
 * start
 * (exit 137 — SIGKILL; the second echo never ran)
 * ```
 *
 * A marker matching no process on the device killed the shell. So a `pkill -f` ends the
 * script at its first clause, and a `pgrep -f` answers "running" unconditionally.
 *
 * ## Why `killall`, and why names are spelled in full
 *
 * `killall` and `pidof` match `comm` OR `basename(argv[0])`. The shell's are both "sh", so
 * they cannot match themselves. Measured:
 *
 * ```
 * pidof sentry_daemon  -> 24945     killall -0 sentry_daemon     -> exit 0
 * pgrep sentry_daemon  -> (nothing) killall -0 no_such_process   -> exit 1
 * pidof main           -> 24801 24945 ...
 * ```
 *
 * `pgrep` without `-f` matches `comm` ONLY, and these daemons are launched with
 * `--nice-name`, so their comm is "main" while argv[0] carries the real name. That is also
 * why CLAUDE.md's old advice to truncate `acc_sentry_daemon` to 15 chars was wrong: the cap
 * applies to comm, and the truncated spelling matches nothing at all.
 *
 * ## When a cmdline match is unavoidable
 *
 * The watchdog SCRIPTS run as `sh /data/local/tmp/start_cam_daemon.sh`, so argv[0] and comm
 * are both "sh" and `killall` cannot single them out without killing every shell on the head
 * unit. Those need [killMatchingCmdline], which is safe because `grep -E` takes a REGEX:
 * `[s]tart_cam_daemon` matches the literal text `start_cam_daemon` but NOT the literal
 * `[s]tart_cam_daemon` sitting in the issuing shell's own cmdline. That is exactly why the
 * bracket trick works for grep and fails for `pkill -f`, which takes no regex.
 */
class DaemonKillCommandsTest {

    @Test
    fun `bracketing hides the literal from a regex match on the issuing shell`() {
        val pattern = DaemonKillCommands.bracket("start_cam_daemon")

        assertEquals("[s]tart_cam_daemon", pattern)
        // The point of the whole exercise: the pattern text is not the thing it matches.
        assertFalse("the bracketed form must not contain the literal it matches",
            pattern.contains("start_cam_daemon"))
    }

    @Test
    fun `kill by name never uses pkill`() {
        val cmd = DaemonKillCommands.killByName("byd_cam_daemon", "ffmpeg")

        assertFalse("pkill -f kills the issuing shell: $cmd", cmd.contains("pkill"))
        assertTrue("must use killall, which matches comm/argv[0]: $cmd", cmd.contains("killall -9"))
        assertTrue(cmd.contains("byd_cam_daemon"))
        assertTrue(cmd.contains("ffmpeg"))
    }

    @Test
    fun `kill by name spells names in full`() {
        val cmd = DaemonKillCommands.killByName("acc_sentry_daemon")

        assertTrue("the full name is what matches: $cmd", cmd.contains("acc_sentry_daemon"))
        // The 15-char comm cap applies to comm, and killall also consults argv[0], which
        // carries the full nice-name. pidof acc_sentry_daem matched NOTHING on the device.
        assertFalse("the truncated spelling matches nothing: $cmd",
            cmd.contains("acc_sentry_daem "))
    }

    @Test
    fun `cmdline matching uses a bracketed regex and no pkill`() {
        val cmd = DaemonKillCommands.killMatchingCmdline("start_cam_daemon", "start_acc_sentry")

        assertFalse("pkill -f cannot be made safe here: $cmd", cmd.contains("pkill"))
        assertTrue("must go through grep -E, which takes a regex: $cmd", cmd.contains("grep -E"))
        assertTrue(cmd.contains("[s]tart_cam_daemon"))
        assertTrue(cmd.contains("[s]tart_acc_sentry"))
        // If the plain literal appeared anywhere in the command, the regex would match the
        // issuing shell's own cmdline and the loop would kill it.
        assertFalse("the un-bracketed literal re-arms the self-match: $cmd",
            cmd.contains("start_cam_daemon"))
        assertFalse("the un-bracketed literal re-arms the self-match: $cmd",
            cmd.contains("start_acc_sentry."))
    }

    @Test
    fun `liveness probe uses pidof, not pgrep`() {
        val cmd = DaemonKillCommands.isRunningByName("sentry_daemon")

        assertFalse("pgrep -f answers 'running' about the probing shell: $cmd",
            cmd.contains("-f"))
        // pgrep without -f consults comm only, which is "main" for every app_process
        // daemon here. pidof also consults basename(argv[0]), which carries the nice-name.
        assertFalse("pgrep matches comm only, and comm is 'main' for these: $cmd",
            cmd.contains("pgrep"))
        assertTrue("pidof matches comm OR argv[0]: $cmd", cmd.contains("pidof sentry_daemon"))
    }
}
