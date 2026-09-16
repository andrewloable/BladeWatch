package net.bladewatch.app.launcher;

import android.content.Context;
import android.content.Intent;
import android.util.Log;

/**
 * Kills every known daemon + watchdog and wipes their lock/state files, so a
 * freshly-started app process always wins over zombies left behind by the
 * previous install.
 *
 * This was previously {@code updater.UpdateLifecycle} and only ran after an
 * in-app OTA install. The OTA updater has been removed, but the sweep itself
 * has nothing to do with updating: the shell-launched daemons run as detached
 * {@code app_process} processes that are NOT bound to the package manager, so
 * they survive {@code uninstall} and {@code install -r} alike (see the clean
 * reinstall block in CLAUDE.md). Any package replacement — a sideload over
 * adb, a manual install — leaves exactly the same zombies, which is why this
 * now hangs off {@link Intent#ACTION_MY_PACKAGE_REPLACED} generally rather
 * than off an update-specific handshake.
 *
 * The OTA-era sentinel files ({@code bladewatch_update_in_progress},
 * {@code bladewatch_post_update}) are gone with the updater. They lived in
 * {@code /data/local/tmp}, which is mode 0771 shell:shell — only the old
 * shell-side updater could create them, and the app UID cannot. The signal is
 * therefore a SharedPreferences flag instead: {@code BootReceiver},
 * {@code MainActivity} and {@code DaemonKeepaliveService} all run in the app
 * process, so a private preference reaches all three. That matters because
 * {@code DaemonKeepaliveService} has no Intent to inspect and still must not
 * race MainActivity's sweep.
 */
public final class DaemonHardReset {

    private static final String TAG = "DaemonHardReset";

    private static final String PREFS_NAME = "daemon_hard_reset";
    private static final String PREF_POST_INSTALL = "post_install";

    /** Also passed as an Intent extra when BootReceiver relaunches the app. */
    public static final String EXTRA_POST_INSTALL = "post_install";

    private DaemonHardReset() {}

    /** Records that the package was just replaced, so the next launch sweeps first. */
    public static void markPostInstall(Context ctx) {
        try {
            ctx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    .edit().putBoolean(PREF_POST_INSTALL, true).apply();
        } catch (Exception e) {
            Log.w(TAG, "could not record post-install flag: " + e.getMessage());
        }
    }

    /**
     * Whether this launch came straight after the package was replaced. [intent]
     * may be null — callers such as {@code DaemonKeepaliveService} have none, and
     * rely entirely on the stored flag.
     */
    public static boolean isPostInstallLaunch(Context ctx, Intent intent) {
        if (intent != null && intent.getBooleanExtra(EXTRA_POST_INSTALL, false)) return true;
        try {
            return ctx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    .getBoolean(PREF_POST_INSTALL, false);
        } catch (Exception ignored) {
            return false;
        }
    }

    /** Clears the flag once the sweep has actually run. */
    public static void clearPostInstall(Context ctx) {
        try {
            ctx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    .edit().remove(PREF_POST_INSTALL).apply();
        } catch (Exception e) {
            Log.w(TAG, "could not clear post-install flag: " + e.getMessage());
        }
    }

    /**
     * The sweep, as one shell command — extracted so {@code DaemonHardResetCommandTest} can
     * assert on it. Single invocation on purpose: atomic from the daemon-watchdog perspective,
     * with no window for a half-killed watchdog to re-spawn between commands.
     *
     * <p>Process names are sourced from launcher constants:
     * <ul>
     *   <li>{@code byd_cam_daemon} (DaemonLauncher.CAMERA_DAEMON_PROCESS)</li>
     *   <li>{@code sentry_daemon} (DaemonLauncher.SENTRY_DAEMON_PROCESS)</li>
     *   <li>{@code acc_sentry_daemon} (DaemonLauncher.ACC_SENTRY_DAEMON_PROCESS)</li>
     *   <li>{@code bladewatch_tor} (TorLauncher.TOR_PROCESS)</li>
     * </ul>
     *
     * <p><b>NEVER add anything that deletes {@code /data/local/tmp/tor/hs}.</b> That directory
     * holds {@code hs_ed25519_secret_key}, which IS the car's permanent onion address — lose it
     * and tor mints a new one on the next start, silently breaking every QR code the owner ever
     * scanned, with no way back. The {@code rm -f} clauses below are deliberately narrow for
     * that reason; do not widen one into a glob over the tor directory. Wiping
     * {@code /data/local/tmp/tor/data} would be harmless (it is only the consensus cache, worth
     * one slow bootstrap), but it buys nothing here, so this does not touch the tor tree at all.
     */
    static String hardResetCommand() {
        return
                // Sentinel first so any racing watchdog sees "disabled" and bails out
                "echo 'disabled by hard reset' > /data/local/tmp/camera_daemon.disabled; " +
                // Watchdog shell scripts first, so nothing respawns behind the sweep.
                //
                // They run as `sh /data/local/tmp/start_cam_daemon.sh`, so argv[0] and comm
                // are both "sh" — killall cannot single them out without killing every shell
                // on the head unit, this one included. They need a cmdline match, and the
                // bracket trick makes one safe: grep -E reads start_[c]am_daemon as a REGEX,
                // which does NOT match the literal text "start_[c]am_daemon" sitting in this
                // shell's own cmdline. That is exactly why the trick works for grep and fails
                // for pkill -f, which takes no regex.
                //
                // For the same reason the rm below globs start_*.sh instead of naming the two
                // scripts: spelling them out would put a literal "start_cam_daemon" back in
                // this cmdline, which the regex above WOULD match — and the loop would kill
                // its own shell.
                "for p in $(ps -A -o PID,ARGS 2>/dev/null | " +
                "grep -E 'start_[c]am_daemon|start_[a]cc_sentry' | awk '{print $1}'); " +
                "do kill -9 $p 2>/dev/null; done; " +
                // Then the daemons themselves, by name.
                //
                // NOT pkill -f, and this is verified-on-device important: toybox pkill -f
                // matches the pattern as a literal SUBSTRING of every /proc/<pid>/cmdline, and
                // this ADB shell's cmdline is the whole sweep — patterns included. The first
                // such clause killed this shell (measured 2026-09-15 with a marker matching no
                // process: exit 137, and nothing after it ran). Every kill, every rm and the
                // "echo done" this method's callback waits for were dead code.
                //
                // Spelled in FULL. CLAUDE.md said to write acc_sentry_daem because the kernel
                // caps /proc/<pid>/comm at 15 chars. The cap is real, the conclusion was not:
                // toybox matches comm OR basename(argv[0]), and these daemons are launched
                // with --nice-name, so argv[0] is the full name. Measured on the head unit:
                //   pidof acc_sentry_daemon -> 4571
                //   pidof acc_sentry_daem   -> (nothing)
                //   pidof main              -> 2851 3102 4571  (comm for all three IS "main")
                // The truncated spelling is the one that matches nothing.
                "killall -9 byd_cam_daemon sentry_daemon acc_sentry_daemon bladewatch_tor " +
                "2>/dev/null; " +
                // Lock + watchdog state. Narrow globs — see the warning above.
                "rm -f /data/local/tmp/*_daemon.lock 2>/dev/null; " +
                "rm -f /data/local/tmp/*_daemon.disabled 2>/dev/null; " +
                "rm -f /data/local/tmp/cam_watchdog.pid 2>/dev/null; " +
                "rm -f /data/local/tmp/start_*.sh 2>/dev/null; " +
                "echo done";
    }

    /**
     * Hard-kill every known daemon + watchdog, wipe lock/sentinel files, then
     * invoke onComplete on the same thread that the underlying launcher uses.
     * Safe to call when nothing is wrong — it is just a sweep.
     */
    public static void hardResetDaemons(Context ctx, Runnable onComplete) {
        Log.i(TAG, "hard-resetting daemons");
        long start = System.currentTimeMillis();
        AdbDaemonLauncher launcher = new AdbDaemonLauncher(ctx);

        String cmd = hardResetCommand();

        launcher.executeShellCommand(cmd, new AdbDaemonLauncher.LaunchCallback() {
            @Override public void onLog(String m) {}
            @Override public void onLaunched() {
                long ms = System.currentTimeMillis() - start;
                Log.i(TAG, "hard reset complete in " + ms + "ms");
                clearPostInstall(ctx);
                // Brief settle so the OS reclaims PIDs before new daemons launch
                try { Thread.sleep(1000); } catch (InterruptedException ie) { Thread.currentThread().interrupt(); Log.w(TAG, "Interrupted during sleep: " + ie.getMessage()); }
                if (onComplete != null) onComplete.run();
            }
            @Override public void onError(String e) {
                Log.w(TAG, "hard reset error (continuing): " + e);
                clearPostInstall(ctx);
                try { Thread.sleep(1000); } catch (InterruptedException ie) { Thread.currentThread().interrupt(); Log.w(TAG, "Interrupted during sleep: " + ie.getMessage()); }
                if (onComplete != null) onComplete.run();
            }
        });
    }
}
