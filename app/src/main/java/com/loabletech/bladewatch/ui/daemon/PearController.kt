package net.bladewatch.app.ui.daemon

import android.content.Context
import net.bladewatch.app.launcher.AdbDaemonLauncher
import net.bladewatch.app.launcher.AdbShellExecutor
import net.bladewatch.app.launcher.PearLauncher
import net.bladewatch.app.logging.LogManager
import net.bladewatch.app.ui.model.DaemonStatus
import net.bladewatch.app.ui.model.DaemonType

/**
 * Controller for pear_daemon, the Pear peer.
 *
 * Unlike TorController.start, this does NOT kill a running instance first. Tor needed that because
 * two tor processes fight over one DataDirectory lock; here the launch command's `pidof` guard and
 * PearDaemon's singleton lock already refuse a second copy, and killing a healthy peer on every
 * start would drop every companion connected to it.
 */
class PearController(
    context: Context,
    private val adbLauncher: AdbDaemonLauncher
) : DaemonController {

    override val type = DaemonType.PEAR_PEER

    private val pearLauncher by lazy {
        PearLauncher(context, AdbShellExecutor(context), LogManager.getInstance())
    }

    override fun start(callback: DaemonCallback) {
        callback.onStatusChanged(DaemonStatus.STARTING, "Starting Pear peer…")
        pearLauncher.launch(object : AdbDaemonLauncher.LaunchCallback {
            override fun onLog(message: String) =
                callback.onStatusChanged(DaemonStatus.STARTING, message)

            override fun onLaunched() = callback.onStatusChanged(DaemonStatus.RUNNING, "Running")
            override fun onError(error: String) = callback.onError(error)
        })
    }

    override fun stop(callback: DaemonCallback) {
        callback.onStatusChanged(DaemonStatus.STOPPING, "Stopping Pear peer…")
        pearLauncher.stop(object : AdbDaemonLauncher.LaunchCallback {
            override fun onLog(message: String) {}
            override fun onLaunched() =
                callback.onStatusChanged(DaemonStatus.STOPPED, "Pear peer stopped")

            override fun onError(error: String) = callback.onError(error)
        })
    }

    override fun isRunning(callback: (Boolean) -> Unit) = pearLauncher.isRunning(callback)

    override fun cleanup() {
        adbLauncher.executeShellCommand(
            PearLauncher.stopCommand(),
            object : AdbDaemonLauncher.LaunchCallback {
                override fun onLog(message: String) {}
                override fun onLaunched() {}
                override fun onError(error: String) {}
            }
        )
    }
}
