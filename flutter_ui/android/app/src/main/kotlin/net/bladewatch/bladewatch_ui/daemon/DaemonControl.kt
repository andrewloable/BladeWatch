package net.bladewatch.bladewatch_ui.daemon

import net.bladewatch.bladewatch_ui.ipc.IpcCommandSender
import org.json.JSONObject

/**
 * `start`/`stop`/`status` over loopback IPC (BladeWatch-ncbb.2) — for the
 * Flutter Daemons settings screen. All three thin-wrap
 * `app/src/main/java/com/loabletech/bladewatch/server/TcpCommandServer.java`'s
 * commands of the same name (see `CameraDaemonClient.java`'s
 * `startRecording`/`stopRecording`/`getStatus`) with no per-camera or
 * streaming parameters — the settings screen only needs the daemon up/down,
 * not per-camera control (that stays on ConnectRPC, e.g. `StreamService`).
 *
 * Any [net.bladewatch.bladewatch_ui.ipc.IpcException] from the underlying
 * [IpcCommandSender] propagates to the caller rather than being swallowed,
 * so the UI can show a specific message (daemon not up vs. token unreadable
 * vs. timeout) instead of a generic failure.
 */
class DaemonControl(private val ipc: IpcCommandSender) {
    fun start(): JSONObject = ipc.sendCommand(JSONObject().put("cmd", "start"))

    fun stop(): JSONObject = ipc.sendCommand(JSONObject().put("cmd", "stop"))

    fun status(): JSONObject = ipc.sendCommand(JSONObject().put("cmd", "status"))

    /**
     * BladeWatch-1xt9: real daemon-process liveness (CAMERA_DAEMON/SENTRY_DAEMON/
     * ACC_SENTRY_DAEMON/PEAR_PEER), computed locally by the daemon via `pgrep` — not
     * to be confused with [status] above, which reports camera *recording* state, not
     * process lifecycle. Response shape: `{"status":"ok","daemons":{"<DaemonType name>":
     * <bool>, ...}}`.
     */
    fun processStatus(): JSONObject = ipc.sendCommand(JSONObject().put("cmd", "daemonStatus"))

    /**
     * BladeWatch-rdtj.17: the Pear peer -- running, switched on, reachable (DHT online; null when
     * unknown), connected companions and when one last connected. Never a topic or key.
     */
    fun pearStatus(): JSONObject = ipc.sendCommand(JSONObject().put("cmd", "pearStatus"))

    /**
     * BladeWatch-abcx: enable or disable an OPTIONAL daemon. The daemon refuses any type
     * outside its own allow-list — currently PEAR_PEER alone — so passing anything else
     * comes back as an error rather than doing something partial.
     *
     * Enabling only RECORDS the intent: DaemonStartupManager's health check performs the
     * actual launch through PearLauncher within ~30s. Disabling records the
     * intent AND kills the running process, because that health check only ever relaunches.
     */
    fun setDaemonEnabled(type: String, enabled: Boolean): JSONObject = ipc.sendCommand(
        JSONObject().put("cmd", "daemon_set_enabled").put("type", type).put("enabled", enabled),
    )
}
