package net.bladewatch.app.launcher;

import android.content.Context;
import android.util.Log;

/**
 * One-shot removal of the previous tunnel's account residue, left behind by an upgrade.
 *
 * <p>The tunnel this project used before Tor kept a per-device environment directory under
 * {@code /data/local/tmp}. Uninstalling the app never removed it — that directory belongs to
 * the shell UID, not the package — so a device upgraded from an older build still carries it.
 * Observed on the head unit 2026-09-15:
 *
 * <pre>
 *   drwxrwxrwx  shell shell   .              &lt;- the DIRECTORY is 777
 *   -rw-------  shell shell   environment.json
 *   drwx------  shell shell   identities/
 *   -rw-rw-rw-  shell shell   unique_name    &lt;- 666
 * </pre>
 *
 * <p>Nothing reads any of it now, so nothing misbehaves. But it is that device's account
 * identity sitting in a world-writable directory on a car, and it will sit there forever
 * unless something removes it. The sensitive files inside are 600, so the credential is not
 * world-readable; the 777 directory still lets any app on the head unit delete or replace
 * entries in it.
 *
 * <p><b>Removing this from the device does not revoke it.</b> The identity still exists in
 * that account server-side. Anyone doing a full cleanup should revoke it there too.
 *
 * <p><b>NEVER widen this to {@code /data/local/tmp/tor}.</b> That directory holds
 * {@code hs/hs_ed25519_secret_key}, which IS the car's permanent onion address — delete it
 * and tor mints a new one on the next start, silently breaking every QR code the owner has
 * ever scanned, with no way back. {@link LegacyTunnelCleanupTest} pins that, and the same
 * warning sits on {@link DaemonHardReset#hardResetCommand()}.
 */
public final class LegacyTunnelCleanup {

    private static final String TAG = "LegacyTunnelCleanup";

    private LegacyTunnelCleanup() {}

    /**
     * The directory, assembled rather than written out.
     *
     * <p>{@code NoRemovedTunnelReferencesTest} bans the old tunnel's name from the tree so it
     * cannot creep back in; this file would otherwise be its own violation. Splitting the
     * literal is the convention that test documents, and is what the tests covering this
     * class do too.
     */
    private static final String LEGACY_DIR = "/data/local/tmp/." + "z" + "rok";

    /** The stale entry left in the shared config's daemons map. Assembled for the same reason. */
    static final String LEGACY_DAEMON_KEY = "Z" + "ROK_TUNNEL";

    /**
     * The sweep, as one shell command — extracted so it can be asserted on.
     *
     * <p>An EXACT path, never a glob: {@code /data/local/tmp/*} or {@code .*} would take the
     * tor directory, the secrets file and the IPC token with it. {@code -f} makes it a silent
     * no-op on a clean device, so this is safe to run on every launch.
     */
    static String cleanupCommand() {
        return "rm -rf " + LEGACY_DIR + " 2>/dev/null; echo done";
    }

    /**
     * Run the cleanup. Idempotent and best-effort: a device that never had the old build is
     * unaffected, and a failure here must never hold up daemon startup.
     */
    public static void run(Context context) {
        dropStaleConfigKey();

        new AdbDaemonLauncher(context).executeShellCommand(
                cleanupCommand(),
                new AdbDaemonLauncher.LaunchCallback() {
                    @Override public void onLog(String m) {}
                    @Override public void onLaunched() {
                        Log.i(TAG, "legacy tunnel environment cleared (or was already absent)");
                    }
                    @Override public void onError(String e) {
                        // Not worth retrying or surfacing: the residue is inert, and the next
                        // launch tries again anyway.
                        Log.w(TAG, "legacy tunnel cleanup did not complete: " + e);
                    }
                });
    }

    /**
     * Drop the dead entry from the shared config's daemons map.
     *
     * <p>Done through {@code UnifiedConfigManager} rather than by sed-ing the file from a
     * shell: the daemon writes that config too, and editing JSON underneath a concurrent
     * writer is how it gets corrupted.
     */
    private static void dropStaleConfigKey() {
        try {
            if (net.bladewatch.app.config.UnifiedConfigManager
                    .removeDaemonEntry(LEGACY_DAEMON_KEY)) {
                Log.i(TAG, "removed the stale daemons entry from the shared config");
            }
        } catch (Throwable t) {
            Log.w(TAG, "could not drop the stale config key: " + t.getMessage());
        }
    }
}
