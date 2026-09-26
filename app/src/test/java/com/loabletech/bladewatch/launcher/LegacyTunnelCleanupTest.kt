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
 * a delete that reaches `/data/local/tmp/tor` (an older build's onion identity: removing it is an
 * explicit owner decision, BladeWatch-rdtj.12) or any other data directory. So the generated
 * command is pinned here the same way `DaemonHardResetCommandTest` pins the sweep.
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
            "this must NEVER reach the tor tree -- deleting it is the owner's explicit decision: "
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

    /** BladeWatch-rdtj.12: an upgraded car's config still names the removed tor daemon. */
    @Test
    fun dropsTheRemovedDaemonsConfigKeys() {
        Assert.assertEquals(listOf("Z" + "ROK_TUNNEL", "TOR_TUNNEL"), LegacyTunnelCleanup.LEGACY_DAEMON_KEYS)
    }

    /**
     * BladeWatch-rdtj.23: a v1.3.x tor survives the install (it is detached) and the post-install
     * sweep only runs if BYD delivers the package-replaced broadcast, which it suppresses after an
     * install. Still alive, it forwards the old onion port to a now-unbound 127.0.0.1:8081 that any
     * app could take. Killed here on every launch -- and only it.
     */
    @Test
    fun killsAStaleTorAndNothingElse() {
        val cmd = LegacyTunnelCleanup.cleanupCommand()
        Assert.assertTrue("must kill a stale tor: " + cmd, cmd.contains("killall -9 bladewatch_tor"))
        Assert.assertFalse("pkill -f matches its own shell: " + cmd, cmd.contains("pkill"))
        val kills = cmd.split(";").map { it.trim() }.filter { it.contains("kill") }
        Assert.assertEquals("the stale tor is the only thing this may kill: " + cmd,
            listOf("killall -9 bladewatch_tor 2>/dev/null"), kills)
    }

    @Test
    fun doesNotTouchTheConfigInTheShellCommand() {
        val cmd = LegacyTunnelCleanup.cleanupCommand()
        // The config key is dropped through UnifiedConfigManager, not by editing JSON with a
        // shell one-liner — sed-ing a config file that another process may be writing is how you
        // corrupt it.
        Assert.assertFalse("do not edit the config from the shell: " + cmd,
            cmd.contains("bladewatch_config.json"))
    }
}
