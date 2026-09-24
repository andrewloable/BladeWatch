package net.bladewatch.app.launcher

import org.junit.Assert
import org.junit.Test

/**
 * BladeWatch-3lbz.2: the hard-reset sweep must kill tor WITHOUT destroying the onion identity.
 *
 * `/data/local/tmp/tor/hs/hs_ed25519_secret_key` is the permanent remote-access identity of this
 * car. Delete it and tor generates a brand-new onion address on the next start: every QR code the
 * owner ever scanned, every bookmark, every saved link stops working, silently and irreversibly.
 * There is no recovery — the key IS the address.
 *
 * That makes this a guard against a plausible FUTURE edit, not against today's code. The sweep
 * already wipes locks and sentinels with an `rm -f` over the daemon lock files, so
 * widening one of those globs to "tidy up" the tor directory is an easy and fatal mistake. The
 * test asserts on the generated command string, which is why [DaemonHardReset.hardResetCommand]
 * exists as a separate method at all.
 *
 * Translated from Java with the class (BladeWatch-dmrg). Kotlin interpolates `$`, and this
 * command contains three of them — `\$p`, `\$(ps ...)`, `\$1` — so the translation could have
 * changed the string silently. [isByteIdenticalToThePreConversionString] pins it against the
 * exact 512-byte output captured from the Java version BEFORE conversion.
 */
class DaemonHardResetCommandTest {

    /**
     * The verbatim output of the Java `hardResetCommand()`, captured before it was translated.
     *
     * This is the only assertion here that would catch a `$`-interpolation slip: every other test
     * checks for the presence or absence of a substring, and an interpolated `$p` would still
     * leave every one of those substrings intact.
     */
    @Test
    fun isByteIdenticalToThePreConversionString() {
        Assert.assertEquals(
            "the Kotlin translation changed the sweep. Kotlin interpolates \$ in a string "
                + "literal; every \$ in this command must be escaped.",
            "echo 'disabled by hard reset' > /data/local/tmp/camera_daemon.disabled; for p in \$(ps -A -o PID,ARGS 2>/dev/null | grep -E 'start_[c]am_daemon|start_[a]cc_sentry' | awk '{print \$1}'); do kill -9 \$p 2>/dev/null; done; killall -9 byd_cam_daemon sentry_daemon acc_sentry_daemon bladewatch_tor pear_daemon 2>/dev/null; rm -f /data/local/tmp/*_daemon.lock 2>/dev/null; rm -f /data/local/tmp/*_daemon.disabled 2>/dev/null; rm -f /data/local/tmp/cam_watchdog.pid 2>/dev/null; rm -f /data/local/tmp/start_*.sh 2>/dev/null; echo done",
            DaemonHardReset.hardResetCommand()
        )
    }

    @Test
    fun killsTor() {
        val cmd = DaemonHardReset.hardResetCommand()
        Assert.assertTrue("hard reset must kill the tor tunnel process: " + cmd,
            cmd.contains("bladewatch_tor"))
    }

    @Test
    fun neverRemovesTheHiddenServiceDirectory() {
        val cmd = DaemonHardReset.hardResetCommand()
        for (line in cmd.split(";")) {
            val t = line.trim()
            if (!t.startsWith("rm")) continue
            Assert.assertFalse(
                "hard reset must never delete the hidden-service directory — that is the car's "
                    + "permanent onion address, and losing it breaks every QR code ever scanned. "
                    + "Offending clause: " + t,
                t.contains("/data/local/tmp/tor/hs") || t.contains("/data/local/tmp/tor "))
            // A bare glob over the tor directory would sweep hs/ up with everything else.
            Assert.assertFalse(
                "a glob over the tor directory would take hs/ with it: " + t,
                t.contains("/data/local/tmp/tor/*") || t.contains("-rf /data/local/tmp/tor"))
        }
    }

    @Test
    fun killsThePearPeer() {
        // BladeWatch-rdtj.3. Without this a "hard reset" leaves the Pear peer running.
        val cmd = DaemonHardReset.hardResetCommand()
        Assert.assertTrue("hard reset must kill pear_daemon, spelled in full: " + cmd,
            cmd.contains("killall -9 byd_cam_daemon sentry_daemon acc_sentry_daemon bladewatch_tor pear_daemon "))
    }

    @Test
    fun neverRemovesThePearStorageDirectory() {
        // /data/local/tmp/pear will hold the car's permanent Pear identity -- the same hazard as
        // tor's hs/ above. Removing pear_daemon.lock is fine; touching the directory is not.
        val cmd = DaemonHardReset.hardResetCommand()
        for (line in cmd.split(";")) {
            val t = line.trim()
            if (!t.startsWith("rm")) continue
            Assert.assertFalse("recursive rm could take the pear directory: " + t, t.contains("-r"))
            Assert.assertFalse("must not name the pear directory: " + t,
                t.contains("/data/local/tmp/pear ") || t.contains("/data/local/tmp/pear/") ||
                    t.contains("/data/local/tmp/pear*") || t.endsWith("/data/local/tmp/pear"))
        }
    }

    @Test
    fun noLongerMentionsTheReplacedTunnel() {
        val cmd = DaemonHardReset.hardResetCommand()
        // Assembled rather than written out: NoRemovedTunnelReferencesTest bans the old name
        // from the tree.
        Assert.assertFalse("the replaced tunnel is gone; killing it is dead weight: " + cmd,
            cmd.lowercase().contains("z" + "rok"))
    }

    @Test
    fun stillKillsTheCoreDaemonsAndTheirWatchdogs() {
        val cmd = DaemonHardReset.hardResetCommand()
        // Regression cover: the tor edit must not quietly drop any of the existing sweep. The
        // watchdog names are asserted in their bracket-trick spelling — see
        // killsTheWatchdogScriptsWithoutMatchingItsOwnShell for why the literal form must NOT
        // appear anywhere in this command.
        for (needle in arrayOf(
            "byd_cam_daemon", "sentry_daemon", "acc_sentry_daemon",
            "start_[c]am_daemon", "start_[a]cc_sentry", "camera_daemon.disabled")) {
            Assert.assertTrue("hard reset no longer handles " + needle, cmd.contains(needle))
        }
    }

    /**
     * The sweep must not contain a single `pkill -f`, because the FIRST one ends it.
     *
     * Verified on the head unit 2026-09-15: toybox `pkill -f` matches the pattern as a literal
     * substring of every `/proc/<pid>/cmdline`, and the ADB shell running this sweep has the whole
     * sweep as its cmdline — patterns included. So `pkill -9 -f 'start_cam_daemon'`, the first
     * clause, kills the shell. Measured with a marker matching no process at all: exit 137, and
     * the echo after it never ran.
     *
     * Which means every kill below it, every `rm -f`, and the `echo done` the callback waits for
     * were all dead code: the hard reset killed nothing and cleaned up nothing, then reported
     * failure. A recovery path that silently does not recover.
     */
    @Test
    fun neverMatchesProcessesByFullCommandLine() {
        val cmd = DaemonHardReset.hardResetCommand()
        Assert.assertFalse(
            "pkill -f matches this sweep's OWN shell and kills it on the first clause "
                + "(exit 137, verified on device), so nothing after it ever runs: " + cmd,
            cmd.contains("pkill"))
    }

    /**
     * killall/pidof names must be spelled in full.
     *
     * CLAUDE.md said to write `acc_sentry_daem`, reasoning that the kernel caps
     * `/proc/<pid>/comm` at 15 characters. The cap is real; the conclusion was not. toybox
     * matches `comm` OR `basename(argv[0])`, and these daemons launch with `--nice-name`, so
     * argv[0] is the full name. Measured on the head unit: `pidof acc_sentry_daemon` -> 4571,
     * `pidof acc_sentry_daem` -> nothing, `pidof main` -> all three. The truncated spelling the
     * doc insisted on is the one that matches nothing.
     */
    @Test
    fun spellsProcessNamesInFullForKillall() {
        val cmd = DaemonHardReset.hardResetCommand()
        Assert.assertTrue("must killall the full daemon names: " + cmd,
            cmd.contains("killall -9 byd_cam_daemon sentry_daemon acc_sentry_daemon"))
        Assert.assertFalse(
            "acc_sentry_daem is the truncated comm spelling and matches NOTHING on this device "
                + "(pidof verified) — use the full name: " + cmd,
            cmd.contains("acc_sentry_daem "))
    }

    /**
     * The watchdog scripts run as `sh /data/local/tmp/start_cam_daemon.sh`: argv[0] and comm are
     * both "sh", so killall cannot single them out without killing every shell on the head unit —
     * this one included. They need a cmdline match, and the bracket trick makes one safe:
     * `grep -E` treats `start_[c]am_daemon` as a REGEX, which does not match the literal text
     * sitting in this shell's own cmdline. That is exactly why it works for grep and fails for
     * `pkill -f`, which takes no regex.
     */
    @Test
    fun killsTheWatchdogScriptsWithoutMatchingItsOwnShell() {
        val cmd = DaemonHardReset.hardResetCommand()
        Assert.assertTrue("must still kill the cam watchdog script: " + cmd,
            cmd.contains("start_[c]am_daemon"))
        Assert.assertTrue("must still kill the acc watchdog script: " + cmd,
            cmd.contains("start_[a]cc_sentry"))
    }
}
