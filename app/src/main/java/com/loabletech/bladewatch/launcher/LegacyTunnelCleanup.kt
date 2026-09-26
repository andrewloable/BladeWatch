package net.bladewatch.app.launcher

import android.content.Context
import android.util.Log

/**
 * One-shot removal of removed tunnels' residue, left behind by an upgrade: the pre-tor tunnel's
 * account directory and config key, and tor's config key and running process (tor was removed in
 * BladeWatch-rdtj.12).
 *
 * **The stale tor process is killed here, on every launch (BladeWatch-rdtj.23).** It is detached,
 * so an install does not stop it, and [DaemonHardReset] only runs when the package-replaced
 * broadcast arrives -- which BYD's ssc_skip suppresses after every install until the owner
 * re-allows Auto-Start. A surviving tor keeps forwarding its onion port to 127.0.0.1:8081, which
 * nothing listens on any more: any app on the head unit could bind it and receive what the owner
 * sends to their saved onion bookmark, the web password included. Nothing launches tor now, so a
 * process by that name is always stale.
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
 * **NEVER widen this to `/data/local/tmp/tor`.** That directory holds an older build's onion
 * identity; removing it is an explicit owner decision (BladeWatch-rdtj.12), never an upgrade's side
 * effect. `LegacyTunnelCleanupTest` pins that, and the same rule sits on
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

    /**
     * The stale entries left in the shared config's daemons map: the pre-tor tunnel's (assembled
     * for the same reason as [LEGACY_DIR]) and tor's (BladeWatch-rdtj.12).
     */
    @JvmField
    internal val LEGACY_DAEMON_KEYS = listOf("Z" + "ROK_TUNNEL", "TOR_TUNNEL")

    /**
     * The sweep, as one shell command — extracted so it can be asserted on.
     *
     * An EXACT path, never a glob: a glob over `/data/local/tmp` would take the tor directory,
     * the secrets file and the IPC token with it. `-f` makes it a silent no-op on a clean device,
     * so this is safe to run on every launch.
     *
     * `killall`, never `pkill -f`: toybox matches `-f` as a substring of every cmdline, this
     * command's own shell included, so it would kill the shell running it. killall matches
     * comm / basename(argv[0]), which is "sh" for the shell.
     */
    @JvmStatic
    internal fun cleanupCommand(): String =
        "killall -9 bladewatch_tor 2>/dev/null; rm -rf " + LEGACY_DIR + " 2>/dev/null; echo done"

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
     * Drop the dead entries from the shared config's daemons map.
     *
     * Done through `UnifiedConfigManager` rather than by sed-ing the file from a shell: the
     * daemon writes that config too, and editing JSON underneath a concurrent writer is how it
     * gets corrupted.
     */
    private fun dropStaleConfigKey() {
        try {
            for (key in LEGACY_DAEMON_KEYS) {
                if (net.bladewatch.app.config.UnifiedConfigManager.removeDaemonEntry(key)) {
                    Log.i(TAG, "removed the stale daemons entry $key from the shared config")
                }
            }
        } catch (t: Throwable) {
            Log.w(TAG, "could not drop the stale config key: " + t.message)
        }
    }
}
