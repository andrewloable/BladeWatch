package net.bladewatch.app.launcher;

import org.junit.Assert;
import org.junit.Test;

/**
 * BladeWatch-3lbz.2: the hard-reset sweep must kill tor WITHOUT destroying the onion identity.
 *
 * <p>{@code /data/local/tmp/tor/hs/hs_ed25519_secret_key} is the permanent remote-access identity
 * of this car. Delete it and tor generates a brand-new onion address on the next start: every QR
 * code the owner ever scanned, every bookmark, every saved link stops working, silently and
 * irreversibly. There is no recovery — the key is the address.
 *
 * <p>That makes this a guard against a plausible FUTURE edit, not against today's code. The sweep
 * already wipes locks and sentinels with {@code rm -f /data/local/tmp/*_daemon.lock} and friends,
 * so widening one of those globs to "tidy up" the tor directory is an easy and fatal mistake. The
 * test asserts on the generated command string, which is why {@link DaemonHardReset#hardResetCommand()}
 * exists as a separate method at all.
 */
public class DaemonHardResetCommandTest {

    @Test
    public void killsTor() {
        String cmd = DaemonHardReset.hardResetCommand();

        Assert.assertTrue("hard reset must kill the tor tunnel process: " + cmd,
                cmd.contains("bladewatch_tor"));
    }

    @Test
    public void neverRemovesTheHiddenServiceDirectory() {
        String cmd = DaemonHardReset.hardResetCommand();

        for (String line : cmd.split(";")) {
            String t = line.trim();
            if (!t.startsWith("rm")) continue;
            Assert.assertFalse(
                    "hard reset must never delete the hidden-service directory — that is the "
                            + "car's permanent onion address, and losing it breaks every QR code "
                            + "ever scanned. Offending clause: " + t,
                    t.contains("/data/local/tmp/tor/hs") || t.contains("/data/local/tmp/tor "));
            // A bare glob over the tor directory would sweep hs/ up with everything else.
            Assert.assertFalse(
                    "a glob over the tor directory would take hs/ with it: " + t,
                    t.contains("/data/local/tmp/tor/*") || t.contains("-rf /data/local/tmp/tor"));
        }
    }

    @Test
    public void noLongerMentionsTheReplacedTunnel() {
        String cmd = DaemonHardReset.hardResetCommand();

        // Assembled rather than written out: NoRemovedTunnelReferencesTest bans the old
        // name from the tree.
        Assert.assertFalse("the replaced tunnel is gone; killing it is dead weight: " + cmd,
                cmd.toLowerCase().contains("z" + "rok"));
    }

    @Test
    public void stillKillsTheCoreDaemonsAndTheirWatchdogs() {
        String cmd = DaemonHardReset.hardResetCommand();

        // Regression cover: the tor edit must not quietly drop any of the existing sweep.
        // The watchdog names are asserted in their bracket-trick spelling — see
        // killsTheWatchdogScriptsWithoutMatchingItsOwnShell for why the literal form
        // must NOT appear anywhere in this command.
        for (String needle : new String[] {
                "byd_cam_daemon", "sentry_daemon", "acc_sentry_daemon",
                "start_[c]am_daemon", "start_[a]cc_sentry", "camera_daemon.disabled"}) {
            Assert.assertTrue("hard reset no longer handles " + needle, cmd.contains(needle));
        }
    }

    /**
     * The sweep must not contain a single {@code pkill -f}, because the FIRST one ends it.
     *
     * <p>Verified on the head unit 2026-09-15: toybox {@code pkill -f} matches the pattern as
     * a literal substring of every {@code /proc/<pid>/cmdline}, and the ADB shell running this
     * sweep has the whole sweep as its cmdline — patterns included. So
     * {@code pkill -9 -f 'start_cam_daemon'}, the first clause, kills the shell. Measured with
     * a marker matching no process at all:
     *
     * <pre>
     *   $ adb shell "echo start; pkill -9 -f 'bwprobe_marker_xyz'; echo SHOULD PRINT"
     *   start
     *   (exit 137 — SIGKILL; the second echo never ran)
     * </pre>
     *
     * <p>Which means every kill below it, every {@code rm -f}, and the {@code echo done} the
     * callback waits for were all dead code: the hard reset killed nothing and cleaned up
     * nothing, then reported failure. A recovery path that silently does not recover.
     */
    @Test
    public void neverMatchesProcessesByFullCommandLine() {
        String cmd = DaemonHardReset.hardResetCommand();

        Assert.assertFalse(
                "pkill -f matches this sweep's OWN shell and kills it on the first clause "
                        + "(exit 137, verified on device), so nothing after it ever runs: " + cmd,
                cmd.contains("pkill"));
    }

    /**
     * killall/pidof names must be spelled in full.
     *
     * <p>CLAUDE.md said to write {@code acc_sentry_daem}, reasoning that the kernel caps
     * {@code /proc/<pid>/comm} at 15 characters. The cap is real; the conclusion was not.
     * toybox matches {@code comm} OR {@code basename(argv[0])}, and these daemons are launched
     * with {@code --nice-name}, so argv[0] is the full name. Measured on the head unit
     * 2026-09-15:
     *
     * <pre>
     *   pidof acc_sentry_daemon -> 4571
     *   pidof acc_sentry_daem   -> (nothing)
     *   pidof main              -> 2851 3102 4571   (comm for all three is "main")
     * </pre>
     *
     * <p>So the truncated spelling the doc insisted on is the one that matches nothing.
     */
    @Test
    public void spellsProcessNamesInFullForKillall() {
        String cmd = DaemonHardReset.hardResetCommand();

        Assert.assertTrue("must killall the full daemon names: " + cmd,
                cmd.contains("killall -9 byd_cam_daemon sentry_daemon acc_sentry_daemon"));
        Assert.assertFalse(
                "acc_sentry_daem is the truncated comm spelling and matches NOTHING on this "
                        + "device (pidof verified) — use the full name: " + cmd,
                cmd.contains("acc_sentry_daem "));
    }

    /**
     * The watchdog scripts run as {@code sh /data/local/tmp/start_cam_daemon.sh}: argv[0] and
     * comm are both "sh", so killall cannot single them out without killing every shell on the
     * head unit — this one included. They need a cmdline match, and the bracket trick makes one
     * safe: {@code grep -E} treats {@code start_[c]am_daemon} as a REGEX, which does not match
     * the literal text {@code start_[c]am_daemon} sitting in this shell's own cmdline. (That is
     * exactly why it works for grep and fails for pkill -f, which does not take a regex.)
     * Verified on the head unit 2026-09-15 — it listed the two watchdogs and not the shell.
     */
    @Test
    public void killsTheWatchdogScriptsWithoutMatchingItsOwnShell() {
        String cmd = DaemonHardReset.hardResetCommand();

        Assert.assertTrue("must still kill the cam watchdog script: " + cmd,
                cmd.contains("start_[c]am_daemon"));
        Assert.assertTrue("must still kill the acc watchdog script: " + cmd,
                cmd.contains("start_[a]cc_sentry"));
    }
}
