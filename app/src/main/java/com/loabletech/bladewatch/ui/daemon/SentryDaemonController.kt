package net.bladewatch.app.ui.daemon

import net.bladewatch.app.launcher.AdbDaemonLauncher
import net.bladewatch.app.launcher.DaemonKillCommands
import net.bladewatch.app.ui.model.DaemonStatus
import net.bladewatch.app.ui.model.DaemonType

/**
 * Controller for the Sentry Daemon (SentryDaemon.java).
 * 
 * Kill methods:
 * 1. Control socket (port 19876) - clean shutdown
 * 2. PID file (/data/local/tmp/sentry_daemon.pid)
 * 3. killall by nice-name (sentry_daemon / acc_sentry_daemon) - NOT pkill -f by
 *    Java class name, which killed the issuing ADB shell and matched the
 *    launching `sh -c` rather than the daemon. See BladeWatch-6jj1.
 */
class SentryDaemonController(
    private val adbLauncher: AdbDaemonLauncher
) : DaemonController {
    
    override val type = DaemonType.SENTRY_DAEMON
    
    private fun getKillCommand(): String {
        return "echo 'STOP' | nc -w 1 127.0.0.1 19879 2>/dev/null; " +  // Port 19879 for SentryDaemon
               "if [ -f /data/local/tmp/sentry_daemon.pid ]; then " +
               "kill -9 \$(cat /data/local/tmp/sentry_daemon.pid) 2>/dev/null; " +
               "rm -f /data/local/tmp/sentry_daemon.pid; fi; " +
               // BladeWatch-6jj1: killall by NICE-NAME, not pkill -f by class name.
               //
               // Two separate bugs were here. pkill -f matched this very ADB shell's
               // cmdline and killed it, so the "echo done" below never ran. And it was
               // matching the wrong thing anyway: app_process overwrites argv[0] with
               // --nice-name, so the daemon's cmdline reads "sentry_daemon" and the Java
               // class name only appears in the launching `sh -c`. The old pattern killed
               // that launcher shell and left the daemon running. Measured on the head
               // unit: pidof sentry_daemon -> 24945, killall -0 sentry_daemon -> exit 0.
               DaemonKillCommands.killByName("sentry_daemon", "acc_sentry_daemon") + "; " +
               "echo done"
    }
    
    private fun getCheckCommand(): String {
        // pidof, never pgrep: `pgrep -f` matched the probing shell itself and so always
        // answered "running", and plain `pgrep` consults comm only — which is "main" for
        // every app_process daemon here, so it would answer "dead" for all of them.
        return "pidof sentry_daemon acc_sentry_daemon 2>/dev/null | head -1"
    }
    
    override fun start(callback: DaemonCallback) {
        callback.onStatusChanged(DaemonStatus.STARTING, "Starting sentry daemon...")
        
        adbLauncher.launchSentryDaemon(object : AdbDaemonLauncher.LaunchCallback {
            override fun onLog(message: String) {
                callback.onStatusChanged(DaemonStatus.STARTING, message)
            }
            
            override fun onLaunched() {
                callback.onStatusChanged(DaemonStatus.RUNNING, "Sentry daemon running")
            }
            
            override fun onError(error: String) {
                callback.onError(error)
            }
        })
    }
    
    override fun stop(callback: DaemonCallback) {
        callback.onStatusChanged(DaemonStatus.STOPPING, "Stopping sentry daemon...")
        
        adbLauncher.executeShellCommand(
            getKillCommand(),
            object : AdbDaemonLauncher.LaunchCallback {
                override fun onLog(message: String) {}
                override fun onLaunched() {
                    callback.onStatusChanged(DaemonStatus.STOPPED, "Sentry daemon stopped")
                }
                override fun onError(error: String) {
                    callback.onStatusChanged(DaemonStatus.STOPPED, "Sentry daemon stopped")
                }
            }
        )
    }
    
    override fun isRunning(callback: (Boolean) -> Unit) {
        adbLauncher.executeShellCommand(
            getCheckCommand(),
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
            getKillCommand(),
            object : AdbDaemonLauncher.LaunchCallback {
                override fun onLog(message: String) {}
                override fun onLaunched() {}
                override fun onError(error: String) {}
            }
        )
    }
}
