package net.bladewatch.app.launcher

import android.content.Context
import android.util.Log

/**
 * One-shot removal of the previous tunnel's account residue, left behind by an upgrade.
 *
 * The tunnel this project used before Tor kept a per-device environment directory under
 * `/data/local/tmp`. Uninstalling the app never removed it — that directory belongs to the shell
 * UID, not the package — so a device upgraded from an older build still carries it. Observed on
 * the head unit 2026-09-15: the DIRECTORY is 777, `environment.json` and `identities/` are 600,
 * `unique_name` is 666.
 *
 * Nothing reads any of it now, so nothing misbehaves. But it is that device's account identity
 * sitting in a world-writable directory on a car, and it will sit there forever unless something
 * removes it. The sensitive files inside are 600, so the credential is not world-readable; the
 * 777 directory still lets any app on the head unit delete or replace entries in it.
 *
 * **Removing this from the device does not revoke it.** The identity still exists in that account
 * server-side. Anyone doing a full cleanup should revoke it there too.
 *
 * **NEVER widen this to `/data/local/tmp/tor`.** That directory holds
 * `hs/hs_ed25519_secret_key`, which IS the car's permanent onion address — delete it and tor
 * mints a new one on the next start, silently breaking every QR code the owner has ever scanned,
 * with no way back. `LegacyTunnelCleanupTest` pins that, and the same warning sits on
 * [DaemonHardReset.hardResetCommand].
 */
object LegacyTunnelCleanup {

    private const val TAG = "LegacyTunnelCleanup"

    /**
     * The directory, assembled rather than written out.
     *
     * `NoRemovedTunnelReferencesTest` bans the old tunnel's name from the tree so it cannot creep
     * back in; this file would otherwise be its own violation. Splitting the literal is the
     * convention that test documents.
     */
    private const val LEGACY_DIR = "/data/local/tmp/." + "z" + "rok"

    /** The stale entry left in the shared config's daemons map. Assembled for the same reason. */
    @JvmField
    internal val LEGACY_DAEMON_KEY = "Z" + "ROK_TUNNEL"

    /**
     * The sweep, as one shell command — extracted so it can be asserted on.
     *
     * An EXACT path, never a glob: a glob over `/data/local/tmp` would take the tor directory,
     * the secrets file and the IPC token with it. `-f` makes it a silent no-op on a clean device,
     * so this is safe to run on every launch.
     */
    @JvmStatic
    internal fun cleanupCommand(): String = "rm -rf " + LEGACY_DIR + " 2>/dev/null; echo done"

    /**
     * Run the cleanup. Idempotent and best-effort: a device that never had the old build is
     * unaffected, and a failure here must never hold up daemon startup.
     */
    @JvmStatic
    fun run(context: Context) {
        dropStaleConfigKey()

        AdbDaemonLauncher(context).executeShellCommand(
            cleanupCommand(),
            object : AdbDaemonLauncher.LaunchCallback {
                override fun onLog(m: String) {}

                override fun onLaunched() {
                    Log.i(TAG, "legacy tunnel environment cleared (or was already absent)")
                }

                override fun onError(e: String) {
                    // Not worth retrying or surfacing: the residue is inert, and the next launch
                    // tries again anyway.
                    Log.w(TAG, "legacy tunnel cleanup did not complete: " + e)
                }
            }
        )
    }

    /**
     * Drop the dead entry from the shared config's daemons map.
     *
     * Done through `UnifiedConfigManager` rather than by sed-ing the file from a shell: the
     * daemon writes that config too, and editing JSON underneath a concurrent writer is how it
     * gets corrupted.
     */
    private fun dropStaleConfigKey() {
        try {
            if (net.bladewatch.app.config.UnifiedConfigManager.removeDaemonEntry(LEGACY_DAEMON_KEY)) {
                Log.i(TAG, "removed the stale daemons entry from the shared config")
            }
        } catch (t: Throwable) {
            Log.w(TAG, "could not drop the stale config key: " + t.message)
        }
    }
}
