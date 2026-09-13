package net.bladewatch.bladewatch_ui.ipc

import org.json.JSONObject

/**
 * The one method every caller of [IpcClient] actually needs — extracted so
 * callers (e.g. [net.bladewatch.bladewatch_ui.auth.JwtMinter]) depend on this
 * narrow interface and can be tested with a fake instead of a real socket.
 */
interface IpcCommandSender {
    /** @see IpcClient.sendCommand */
    fun sendCommand(command: JSONObject): JSONObject
}
