package net.bladewatch.app.launcher

import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Kills every known daemon + watchdog and wipes their lock/state files, so a freshly-started app
 * process always wins over zombies left behind by the previous install.
 *
 * This was previously `updater.UpdateLifecycle` and only ran after an in-app OTA install. The OTA
 * updater has been removed, but the sweep has nothing to do with updating: the shell-launched
 * daemons run as detached `app_process` processes that are NOT bound to the package manager, so
 * they survive `uninstall` and `install -r` alike (see the clean-reinstall block in CLAUDE.md).
 * Any package replacement leaves the same zombies, which is why this hangs off
 * [Intent.ACTION_MY_PACKAGE_REPLACED] generally rather than an update-specific handshake.
 *
 * The OTA-era sentinel files are gone with the updater. They lived in `/data/local/tmp`, which is
 * mode 0771 shell:shell — only the old shell-side updater could create them, and the app UID
 * cannot. The signal is a SharedPreferences flag instead: `BootReceiver`, `MainActivity` and
 * `DaemonKeepaliveService` all run in the app process, so a private preference reaches all three.
 * That matters because `DaemonKeepaliveService` has no Intent to inspect and still must not race
 * MainActivity's sweep.
 */
object DaemonHardReset {

    private const val TAG = "DaemonHardReset"

    private const val PREFS_NAME = "daemon_hard_reset"
    private const val PREF_POST_INSTALL = "post_install"

    /** Also passed as an Intent extra when BootReceiver relaunches the app. */
    @JvmField
    val EXTRA_POST_INSTALL = "post_install"

    /** Records that the package was just replaced, so the next launch sweeps first. */
    @JvmStatic
    fun markPostInstall(ctx: Context) {
        try {
            ctx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit().putBoolean(PREF_POST_INSTALL, true).apply()
        } catch (e: Exception) {
            Log.w(TAG, "could not record post-install flag: " + e.message)
        }
    }

    /**
     * Whether this launch came straight after the package was replaced.
     *
     * [intent] may be null — callers such as `DaemonKeepaliveService` have none and rely
     * entirely on the stored flag.
     */
    @JvmStatic
    fun isPostInstallLaunch(ctx: Context, intent: Intent?): Boolean {
        if (intent != null && intent.getBooleanExtra(EXTRA_POST_INSTALL, false)) return true
        return try {
            ctx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .getBoolean(PREF_POST_INSTALL, false)
        } catch (ignored: Exception) {
            false
        }
    }

    /** Clears the flag once the sweep has actually run. */
    @JvmStatic
    fun clearPostInstall(ctx: Context) {
        try {
            ctx.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit().remove(PREF_POST_INSTALL).apply()
        } catch (e: Exception) {
            Log.w(TAG, "could not clear post-install flag: " + e.message)
        }
    }

    /**
     * The sweep, as ONE shell command — extracted so `DaemonHardResetCommandTest` can assert on
     * it. A single invocation on purpose: atomic from the daemon-watchdog perspective, with no
     * window for a half-killed watchdog to re-spawn between commands.
     *
     * Process names come from launcher constants: `byd_cam_daemon`, `sentry_daemon`,
     * `acc_sentry_daemon`, `pear_daemon` -- plus `bladewatch_tor`, the onion service an older
     * build may have left running. Tor itself was removed (BladeWatch-rdtj.12), but this sweep is
     * what runs when the package is replaced, i.e. exactly when an upgraded car still has one.
     *
     * **The same goes for `/data/local/tmp/pear`** (BladeWatch-rdtj.3): pear_daemon's storage,
     * which holds the car's permanent Pear identity once a companion is paired. Only the lock file
     * `pear_daemon.lock` (matched by `*_daemon.lock`) may go; `rm -f` cannot remove a directory,
     * and no clause may ever be widened into one that can.
     *
     * **Nothing here may delete `/data/local/tmp/tor`** (an older build's onion identity). Removing
     * it is an explicit owner decision (BladeWatch-rdtj.12), never a sweep's side effect; the
     * `rm -f` clauses are deliberately narrow, and none may be widened into a glob over it.
     *
     * Two properties of this string are load-bearing and survive translation only by being left
     * exactly as they were:
     *  - The bracket trick (`start_[c]am_daemon`) is a REGEX for `grep -E`, which does not match
     *    the literal text sitting in this shell's own cmdline. It is why `grep` is safe here and
     *    `pkill -f` is not — toybox `pkill -f` takes no regex and matched this sweep's own
     *    command line, killing the shell mid-run (measured on the head unit: exit 137, and
     *    nothing after it ran).
     *  - The daemon names are spelled IN FULL. The kernel caps `/proc/<pid>/comm` at 15 chars,
     *    but toybox matches comm OR `basename(argv[0])`, and these launch with `--nice-name`, so
     *    argv[0] is the full name. `pidof acc_sentry_daem` matches nothing.
     *
     * Every `$` below is escaped: Kotlin interpolates `$` in a string literal, so an unescaped
     * `\$p` or `\$(ps ...)` would either fail to compile or, worse, silently expand to
     * something else. `DaemonHardResetCommandTest` asserts on the produced string, which is what
     * proves this translation did not change it.
     */
    /**
     * Hard-kill every known daemon + watchdog, wipe lock/sentinel files, then invoke [onComplete]
     * on whatever thread the underlying launcher uses. Safe to call when nothing is wrong — it is
     * just a sweep.
     */
    @JvmStatic
    fun hardResetDaemons(ctx: Context, onComplete: Runnable?) {
        Log.i(TAG, "hard-resetting daemons")
        val start = System.currentTimeMillis()
        val launcher = AdbDaemonLauncher(ctx)

        launcher.executeShellCommand(hardResetCommand(), object : AdbDaemonLauncher.LaunchCallback {
            override fun onLog(m: String) {}

            override fun onLaunched() {
                Log.i(TAG, "hard reset complete in " + (System.currentTimeMillis() - start) + "ms")
                finish()
            }

            override fun onError(e: String) {
                Log.w(TAG, "hard reset error (continuing): " + e)
                finish()
            }

            /** Both paths clear the flag and settle identically — a failed sweep still proceeds. */
            private fun finish() {
                clearPostInstall(ctx)
                // Brief settle so the OS reclaims PIDs before new daemons launch.
                try {
                    Thread.sleep(1000)
                } catch (ie: InterruptedException) {
                    Thread.currentThread().interrupt()
                    Log.w(TAG, "Interrupted during sleep: " + ie.message)
                }
                onComplete?.run()
            }
        })
    }

    @JvmStatic
    internal fun hardResetCommand(): String =
        "echo 'disabled by hard reset' > /data/local/tmp/camera_daemon.disabled; for p in \$(ps -A -o PID,ARGS 2>/dev/null | grep -E 'start_[c]am_daemon|start_[a]cc_sentry' | awk '{print \$1}'); do kill -9 \$p 2>/dev/null; done; killall -9 byd_cam_daemon sentry_daemon acc_sentry_daemon bladewatch_tor pear_daemon 2>/dev/null; rm -f /data/local/tmp/*_daemon.lock 2>/dev/null; rm -f /data/local/tmp/*_daemon.disabled 2>/dev/null; rm -f /data/local/tmp/cam_watchdog.pid 2>/dev/null; rm -f /data/local/tmp/start_*.sh 2>/dev/null; echo done"
}
