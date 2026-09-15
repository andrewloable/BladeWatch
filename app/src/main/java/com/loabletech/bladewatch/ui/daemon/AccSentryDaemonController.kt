package net.bladewatch.app.ui.daemon

import net.bladewatch.app.launcher.AdbDaemonLauncher
import net.bladewatch.app.launcher.DaemonKillCommands
import net.bladewatch.app.ui.model.DaemonStatus
import net.bladewatch.app.ui.model.DaemonType

/**
 * Controller for AccSentryDaemon - handles ACC monitoring and screen control.
 * 
 * This daemon MUST run as UID 2000 (shell) for screen control to work.
 * It's separate from SentryDaemon (UID 1000) which handles system whitelisting.
 */
class AccSentryDaemonController(
    private val adbLauncher: AdbDaemonLauncher
) : DaemonController {
    
    override val type = DaemonType.ACC_SENTRY_DAEMON
    
    companion object {
        private const val PROCESS_NAME = "acc_sentry_daemon"
    }
    
    override fun start(callback: DaemonCallback) {
        callback.onStatusChanged(DaemonStatus.STARTING, "Launching AccSentryDaemon (UID 2000)...")
        
        adbLauncher.launchAccSentryDaemon(
            onSuccess = {
                callback.onStatusChanged(DaemonStatus.RUNNING, "Running as UID 2000")
            },
            onError = { error ->
                callback.onError(error)
            }
        )
    }
    
    override fun stop(callback: DaemonCallback) {
        callback.onStatusChanged(DaemonStatus.STOPPING, "Stopping...")
        
        adbLauncher.executeShellCommand(
            // BladeWatch-6jj1: pkill -f 'acc_sentry' matched THIS shell's own cmdline
            // and killed it, so nothing below it ran. The daemon goes by nice-name
            // (killall matches comm/argv[0], both "sh" for us, so it cannot self-match);
            // the watchdog SCRIPT runs as plain "sh" and needs a cmdline match, which is
            // safe only because grep -E takes a regex and the pattern is bracketed.
            //
            // The rm globs start_acc_*.sh rather than naming the script — the plain
            // literal would re-arm that regex against our own cmdline.
            DaemonKillCommands.killByName("acc_sentry_daemon") + "; " +
            DaemonKillCommands.killMatchingCmdline("start_acc_sentry") + "; " +
            "rm -f /data/local/tmp/acc_sentry_daemon.lock 2>/dev/null; " +
            "rm -f /data/local/tmp/start_acc_*.sh 2>/dev/null; " +
            "echo done",
            object : AdbDaemonLauncher.LaunchCallback {
                override fun onLog(message: String) {}
                override fun onLaunched() {
                    callback.onStatusChanged(DaemonStatus.STOPPED, "Stopped")
                }
                override fun onError(error: String) {
                    // killall returns an error when nothing matched - that's fine
                    callback.onStatusChanged(DaemonStatus.STOPPED, "Stopped")
                }
            }
        )
    }
    
    override fun isRunning(callback: (Boolean) -> Unit) {
        adbLauncher.executeShellCommand(
            "ps -A | grep $PROCESS_NAME | grep -v grep",
            object : AdbDaemonLauncher.LaunchCallback {
                override fun onLog(message: String) {
                    callback(message.trim().isNotEmpty())
                }
                override fun onLaunched() {}
                override fun onError(error: String) {
                    callback(false)
                }
            }
        )
    }
    
    override fun cleanup() {
        adbLauncher.executeShellCommand(
            // BladeWatch-6jj1: pkill -f 'acc_sentry' matched THIS shell's own cmdline
            // and killed it, so nothing below it ran. The daemon goes by nice-name
            // (killall matches comm/argv[0], both "sh" for us, so it cannot self-match);
            // the watchdog SCRIPT runs as plain "sh" and needs a cmdline match, which is
            // safe only because grep -E takes a regex and the pattern is bracketed.
            //
            // The rm globs start_acc_*.sh rather than naming the script — the plain
            // literal would re-arm that regex against our own cmdline.
            DaemonKillCommands.killByName("acc_sentry_daemon") + "; " +
            DaemonKillCommands.killMatchingCmdline("start_acc_sentry") + "; " +
            "rm -f /data/local/tmp/acc_sentry_daemon.lock 2>/dev/null; " +
            "rm -f /data/local/tmp/start_acc_*.sh 2>/dev/null; " +
            "echo done",
            object : AdbDaemonLauncher.LaunchCallback {
                override fun onLog(message: String) {}
                override fun onLaunched() {}
                override fun onError(error: String) {}
            }
        )
    }
}
