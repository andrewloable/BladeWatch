package net.bladewatch.app.launcher

import android.content.Context
import android.os.Handler
import android.os.Looper
import net.bladewatch.app.logging.DaemonLogConfig
import net.bladewatch.app.logging.LogManager

/**
 * Launches and stops `pear_daemon` ([net.bladewatch.app.daemon.PearDaemon]), the Pear peer:
 * BladeWatch's remote-access transport.
 *
 * It is an `app_process` daemon like sentry_daemon, run as shell UID over ADB. Restart-on-crash is
 * NOT here: DaemonStartupManager's 30 s health check is what relaunches a dead,
 * enabled optional daemon. This class only knows how to start, stop and probe one.
 *
 * ## The storage directory is not ours to delete
 *
 * [net.bladewatch.app.daemon.PearDaemon.STORAGE_DIR] will hold the car's permanent Pear identity.
 * [stopCommand] kills the process and nothing else, on purpose -- a stop must be reversible.
 */
class PearLauncher(
    private val context: Context,
    private val adbShellExecutor: AdbShellExecutor,
    private val logManager: LogManager
) {
    companion object {
        private const val TAG = "PearLauncher"

        /**
         * The `--nice-name`, and therefore argv[0], which is what `pidof` and `killall` match for an
         * app_process daemon -- its `comm` reads "main", like every other daemon here. 11 chars,
         * comfortably inside the kernel's 15-char cap on `/proc/<pid>/comm`.
         */
        const val PEAR_PROCESS = "pear_daemon"

        const val PEAR_LOG = "/data/local/tmp/pear_daemon.log"

        private const val MAIN_CLASS = "net.bladewatch.app.daemon.PearDaemon"

        /**
         * What an APK or native-library path may contain before it is spliced into a shell command.
         * PackageManager's paths (`/data/app/net.bladewatch.app-<base64>==/...`) always fit; anything
         * else -- a quote, a space, a `;` -- is refused rather than escaped.
         */
        private val SHELL_SAFE_PATH = Regex("[A-Za-z0-9/._=+-]+")

        /**
         * Start pear_daemon detached, unless it is already running.
         *
         * `-Djava.library.path` with the APK's native dir FIRST, exactly like CameraDaemon's launch:
         * a bare `CLASSPATH=<apk> app_process` does not put the APK's lib dir on the loader's search
         * path, so libbare-kit.so is not found at all -- and the dir must come before the system
         * ones so the APK's own libc++_shared.so wins over any copy the firmware ships
         * (BladeWatch-rdtj.2).
         *
         * The already-running check is inside the single shell invocation, not a Kotlin
         * check-then-act across two ADB round trips: two callers racing that way started a daemon
         * twice (measured 2026-09-15). PearDaemon's singleton lock backs this up.
         * `pidof`, never `pgrep`: pgrep matches `comm`, which is "main" for every app_process
         * daemon, so it could never find this one.
         */
        @JvmStatic
        fun launchCommand(apkPath: String, nativeLibDir: String): String {
            require(SHELL_SAFE_PATH.matches(apkPath)) { "unsafe APK path: $apkPath" }
            require(SHELL_SAFE_PATH.matches(nativeLibDir)) { "unsafe native lib dir: $nativeLibDir" }
            val daemon = "CLASSPATH=$apkPath app_process " +
                "-Djava.library.path=$nativeLibDir:/system/lib64:/vendor/lib64:/product/lib64:/odm/lib64 " +
                "/system/bin --nice-name=$PEAR_PROCESS $MAIN_CLASS"
            return "if pidof $PEAR_PROCESS > /dev/null 2>&1; then echo already_running; " +
                "else nohup sh -c '$daemon' > $PEAR_LOG 2>&1 & echo launched; fi"
        }

        /**
         * `killall`, NOT `pkill -f`: toybox `pkill -f` matches the pattern as a substring of every
         * process's command line, including the ADB shell running this very command, and kills it
         * mid-procedure (CLAUDE.md, measured 2026-09-15). killall matches argv[0], which is "sh"
         * for that shell. Kills only -- the storage directory stays.
         */
        @JvmStatic
        fun stopCommand(): String = "killall -9 $PEAR_PROCESS 2>/dev/null; echo done"

        /** `pidof` for the same reason as [launchCommand]; it matches argv[0], never itself. */
        @JvmStatic
        fun isRunningCommand(): String =
            "pidof $PEAR_PROCESS > /dev/null 2>&1 && echo yes || echo no"

        /** How long a fresh daemon gets before its survival is checked. */
        private const val VERIFY_DELAY_MS = 5_000L
    }

    /**
     * Launch, then confirm the process is still alive a few seconds later -- a daemon that dies on
     * boot (a missing native library, a broken bundle) exits within that window, and reporting
     * "launched" for it would be a lie.
     */
    fun launch(callback: AdbDaemonLauncher.LaunchCallback) {
        val info = context.applicationInfo
        val command = try {
            launchCommand(info.sourceDir, info.nativeLibraryDir)
        } catch (e: IllegalArgumentException) {
            callback.onError("Pear launch refused: ${e.message}")
            return
        }
        log("Launching pear_daemon")
        callback.onLog("Starting Pear peer…")
        adbShellExecutor.execute(command, object : AdbShellExecutor.ShellCallback {
            override fun onSuccess(output: String) {
                if (output.contains("already_running")) {
                    callback.onLog("Pear peer already running")
                    callback.onLaunched()
                    return
                }
                Handler(Looper.getMainLooper()).postDelayed({ verify(callback) }, VERIFY_DELAY_MS)
            }

            override fun onError(error: String) {
                log("pear_daemon launch failed: $error", error = true)
                callback.onError("Pear launch failed: $error")
            }
        })
    }

    private fun verify(callback: AdbDaemonLauncher.LaunchCallback) {
        isRunning { running ->
            if (running) {
                log("pear_daemon is up")
                callback.onLaunched()
            } else {
                val msg = "pear_daemon exited right after launch -- see $PEAR_LOG"
                log(msg, error = true)
                callback.onError(msg)
            }
        }
    }

    fun stop(callback: AdbDaemonLauncher.LaunchCallback) {
        adbShellExecutor.execute(stopCommand(), object : AdbShellExecutor.ShellCallback {
            override fun onSuccess(output: String) {
                log("pear_daemon stopped")
                callback.onLaunched()
            }

            override fun onError(error: String) {
                log("Failed to stop pear_daemon: $error", error = true)
                callback.onError("Failed to stop Pear peer: $error")
            }
        })
    }

    /**
     * Every log call in this class, gated by [DaemonLogConfig.PEAR_LAUNCHER]. Nothing is lost with
     * the flag off: failures also go to [AdbDaemonLauncher.LaunchCallback.onError], which
     * DaemonStartupManager logs.
     */
    private fun log(message: String, error: Boolean = false) {
        if (!DaemonLogConfig.PEAR_LAUNCHER && !DaemonLogConfig.ENABLE_ALL) return
        if (error) logManager.error(TAG, message) else logManager.info(TAG, message)
    }

    fun isRunning(callback: (Boolean) -> Unit) {
        adbShellExecutor.execute(isRunningCommand(), object : AdbShellExecutor.ShellCallback {
            override fun onSuccess(output: String) = callback(output.trim() == "yes")
            override fun onError(error: String) = callback(false)
        })
    }
}
