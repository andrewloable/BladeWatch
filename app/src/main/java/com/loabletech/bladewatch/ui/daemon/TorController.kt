package net.bladewatch.app.ui.daemon

import android.content.Context
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import net.bladewatch.app.launcher.AdbDaemonLauncher
import net.bladewatch.app.launcher.TorLauncher
import net.bladewatch.app.ui.model.DaemonStatus
import net.bladewatch.app.ui.model.DaemonType
import net.bladewatch.app.ui.util.PreferencesManager

/**
 * Controller for the Tor onion service, the only remote-access tunnel.
 *
 * Replaces the previous tunnel's controller. Most of what that class did is gone with its
 * account model: there is no enable token, no reserved-share token, no unique name to keep in sync with
 * the server, and therefore no "split-brain" repair when the two drifted apart. There is also no
 * public-versus-reserved mode, because a Tor address is permanent by construction — it is derived
 * from a key file in the hidden-service directory, so it survives restarts and reboots without
 * anything being reserved anywhere.
 */
class TorController(
    private val context: Context,
    private val adbLauncher: AdbDaemonLauncher
) : DaemonController {

    override val type = DaemonType.TOR_TUNNEL

    private val _tunnelUrl = MutableLiveData<String?>()
    val tunnelUrl: LiveData<String?> = _tunnelUrl

    private val torLauncher by lazy {
        TorLauncher(
            context,
            net.bladewatch.app.launcher.AdbShellExecutor(context),
            net.bladewatch.app.logging.LogManager.getInstance()
        )
    }

    override fun start(callback: DaemonCallback) {
        callback.onStatusChanged(DaemonStatus.STARTING, "Starting Tor…")

        // Kill any zombie first. Unlike the previous tunnel — where a stale process meant
        // the share was still reserved server-side and the new one failed outright — this is
        // only about two processes fighting over the same DataDirectory lock.
        adbLauncher.executeShellCommand(
            TorLauncher.stopCommand(),
            object : AdbDaemonLauncher.LaunchCallback {
                override fun onLaunched() = startInternal(callback)
                override fun onLog(m: String) {}
                override fun onError(e: String) = startInternal(callback)
            }
        )
    }

    private fun startInternal(callback: DaemonCallback) {
        torLauncher.launchTor(object : TorLauncher.TorCallback {
            override fun onLog(message: String) {
                callback.onStatusChanged(DaemonStatus.STARTING, message)
            }

            override fun onTunnelUrl(url: String) {
                _tunnelUrl.postValue(url)
                PreferencesManager.setLastTunnelUrl(url)
                callback.onStatusChanged(DaemonStatus.RUNNING, url)
            }

            override fun onError(error: String) = callback.onError(error)
        })
    }

    override fun stop(callback: DaemonCallback) {
        callback.onStatusChanged(DaemonStatus.STOPPING, "Stopping Tor…")
        torLauncher.stopTor(object : TorLauncher.TorCallback {
            override fun onLog(message: String) {
                _tunnelUrl.postValue(null)
                callback.onStatusChanged(DaemonStatus.STOPPED, message)
            }

            override fun onTunnelUrl(url: String) {
                // Not reachable for a stop; kept because the callback is shared.
            }

            override fun onError(error: String) {
                _tunnelUrl.postValue(null)
                callback.onError(error)
            }
        })
    }

    override fun isRunning(callback: (Boolean) -> Unit) = torLauncher.isTunnelRunning(callback)

    /**
     * Re-read the address for a tunnel that is already up — e.g. after a UI process restart,
     * where the LiveData is empty but tor has been running for hours.
     *
     * Falls back to the last address seen. That fallback is sound here in a way it never was for
     * the previous tunnel: the onion address is permanent, so a remembered one is still correct. It is shown
     * only when tor is actually running, so a stale value cannot be presented as a live tunnel.
     */
    fun refreshTunnelUrl(callback: ((String?) -> Unit)? = null) {
        isRunning { running ->
            if (!running) {
                _tunnelUrl.postValue(null)
                callback?.invoke(null)
                return@isRunning
            }
            val remembered = PreferencesManager.getLastTunnelUrl()
            if (!remembered.isNullOrEmpty()) _tunnelUrl.postValue(remembered)
            callback?.invoke(remembered)
        }
    }

    override fun cleanup() {
        adbLauncher.executeShellCommand(
            TorLauncher.stopCommand(),
            object : AdbDaemonLauncher.LaunchCallback {
                override fun onLog(message: String) {}
                override fun onLaunched() {}
                override fun onError(error: String) {}
            }
        )
        _tunnelUrl.postValue(null)
    }

    /** The current tunnel URL, if one is known. */
    fun getTunnelUrl(): String? = _tunnelUrl.value
}
