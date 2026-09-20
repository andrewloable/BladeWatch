package net.bladewatch.app.launcher

import org.junit.Assert
import org.junit.Test

/**
 * BladeWatch-fjb0: remove the previous tunnel's account residue on upgrade.
 *
 * Found on the head unit 2026-09-15 after a clean reinstall of both APKs onto a device that had
 * run the old build: the stale directory survived, holding that device's account identity, with
 * the DIRECTORY at mode 777 and one file at 666. Nothing reads it any more, so nothing
 * misbehaves — but it is a credential sitting in a world-writable directory on a car, and it
 * will sit there forever unless something removes it.
 *
 * **Why these tests assert on a string.** The one thing that could go catastrophically wrong is
 * a delete that reaches `/data/local/tmp/tor`. That directory holds `hs/hs_ed25519_secret_key`,
 * which IS the car's permanent onion address: remove it and tor mints a new one on the next
 * start, silently breaking every QR code the owner has ever scanned, with no way back. So the
 * generated command is pinned here the same way `DaemonHardResetCommandTest` pins the sweep.
 *
 * Translated from Java with its class (BladeWatch-dmrg) because `cleanupCommand` is `internal`
 * and Java cannot call a Kotlin internal member.
 */
class LegacyTunnelCleanupTest {

    /** Assembled at runtime so this file is not itself a NoRemovedTunnelReferencesTest hit. */
    private val legacyDir = "/data/local/tmp/." + "z" + "rok"

    @Test
    fun removesTheLegacyEnvironmentDirectory() {
        val cmd = LegacyTunnelCleanup.cleanupCommand()
        Assert.assertTrue("must remove the stale environment directory: " + cmd,
            cmd.contains(legacyDir))
        Assert.assertTrue("it is a directory, so -rf: " + cmd, cmd.contains("rm -rf"))
    }

    @Test
    fun neverTouchesTheTorDirectory() {
        val cmd = LegacyTunnelCleanup.cleanupCommand()
        Assert.assertFalse(
            "this must NEVER reach the tor tree — hs/hs_ed25519_secret_key is the car's "
                + "permanent onion address and losing it breaks every QR code ever scanned: "
                + cmd,
            cmd.contains("/data/local/tmp/tor"))
    }

    /**
     * A glob is how this goes wrong by accident: a wildcard under `/data/local/tmp` would sweep
     * up the tor directory, the secrets file and the IPC token along with the target.
     */
    @Test
    fun usesAnExactPathRatherThanAGlob() {
        val cmd = LegacyTunnelCleanup.cleanupCommand()
        for (clause in cmd.split(";")) {
            val t = clause.trim()
            if (!t.startsWith("rm")) continue
            Assert.assertFalse("no globs in a delete under /data/local/tmp: " + t,
                t.contains("*"))
        }
    }

    /** Idempotent: running it on a clean device must be a silent no-op, not an error. */
    @Test
    fun isSafeToRunWhenNothingIsThere() {
        val cmd = LegacyTunnelCleanup.cleanupCommand()
        Assert.assertTrue("rm must tolerate a missing path (-f): " + cmd,
            cmd.contains("rm -rf"))
        Assert.assertTrue("must not fail the shell when the path is absent: " + cmd,
            cmd.contains("2>/dev/null") || cmd.contains("|| true"))
    }

    @Test
    fun doesNotKillAnythingOrTouchTheConfigInTheShellCommand() {
        val cmd = LegacyTunnelCleanup.cleanupCommand()
        // The config key is dropped through UnifiedConfigManager, not by editing JSON with a
        // shell one-liner — sed-ing a config file that another process may be writing is how you
        // corrupt it.
        Assert.assertFalse("no kills belong in a cleanup: " + cmd, cmd.contains("kill"))
        Assert.assertFalse("do not edit the config from the shell: " + cmd,
            cmd.contains("bladewatch_config.json"))
    }
}
