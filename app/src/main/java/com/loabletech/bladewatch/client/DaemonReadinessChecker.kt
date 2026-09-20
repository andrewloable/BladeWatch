package net.bladewatch.app.client

import android.util.Log
import java.io.File
import java.net.InetSocketAddress
import java.net.Socket

object DaemonReadinessChecker {

    private const val SENTINEL_PATH = "/data/local/tmp/camera_daemon.ready"
    private const val TAG = "DaemonReadiness"

    // The daemon's TCP command server. A successful connect is a UID-independent liveness signal:
    // it proves the daemon process is alive AND accepting commands.
    private const val DAEMON_HOST = "127.0.0.1"
    private const val DAEMON_PORT = 19876
    private const val PROBE_TIMEOUT_MS = 1000

    /**
     * True if the daemon has finished startup: the ready sentinel exists and is non-empty, AND the
     * daemon's TCP command port accepts a connection.
     *
     * The TCP probe is the authoritative liveness check. We deliberately do NOT stat `/proc/<pid>`:
     * on the head unit /proc is mounted `hidepid=2,gid=3009`, so the app UID cannot see the
     * daemon's /proc entry (the daemon runs as the shell UID and the app is not in gid 3009). A
     * /proc check therefore always fails from the app process, leaving the camera permanently
     * "connecting". A TCP connect works regardless of UID and also covers the stale-sentinel case:
     * a daemon killed with `kill -9` leaves the sentinel behind but is no longer listening, so the
     * connect is refused.
     */
    @JvmStatic
    fun isReady(): Boolean {
        val f = File(SENTINEL_PATH)
        if (!f.exists() || f.length() == 0L) return false
        return daemonPortAccepting()
    }

    /**
     * Attempt a short-lived TCP connect to the daemon command port.
     *
     * @return true if the connection is accepted, false on refusal, timeout or any error
     */
    private fun daemonPortAccepting(): Boolean = try {
        Socket().use { s ->
            s.connect(InetSocketAddress(DAEMON_HOST, DAEMON_PORT), PROBE_TIMEOUT_MS)
            true
        }
    } catch (e: Exception) {
        false
    }

    /**
     * Block until [isReady] returns true or [timeoutMs] elapses. Polls every 500ms and logs
     * progress at INFO level every 5 seconds.
     *
     * @return true if the daemon became ready within the timeout
     */
    @JvmStatic
    fun waitUntilReady(timeoutMs: Long): Boolean {
        val deadline = System.currentTimeMillis() + timeoutMs
        var lastLogMs = System.currentTimeMillis()
        while (System.currentTimeMillis() < deadline) {
            if (isReady()) {
                Log.i(TAG, "Daemon is ready")
                return true
            }
            val now = System.currentTimeMillis()
            if (now - lastLogMs >= 5000) {
                Log.i(
                    TAG,
                    "Waiting for daemon ready sentinel... " + ((deadline - now) / 1000) +
                        "s remaining"
                )
                lastLogMs = now
            }
            try {
                Thread.sleep(500)
            } catch (e: InterruptedException) {
                Thread.currentThread().interrupt()
                return false
            }
        }
        Log.i(TAG, "Timed out waiting for daemon ready sentinel")
        return false
    }
}
