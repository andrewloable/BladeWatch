package net.bladewatch.bladewatch_ui.pairing

import net.bladewatch.bladewatch_ui.ipc.IpcCommandSender
import org.json.JSONObject

/**
 * The in-car "Pair a device" flow over loopback IPC (BladeWatch-rdtj.7): thin wrappers over
 * TcpCommandServer's `pairingMint` / `pairingList` / `pairingRevoke` / `lanAccessSet`.
 *
 * These exist only here, on the IPC port the in-car UI alone can reach (peer UID + IPC token):
 * pairing and un-pairing need someone at the car. The minted payload is a short-lived, single-use
 * pairing code plus public routing data -- it is shown as a QR and never logged.
 */
class PairingControl(private val ipc: IpcCommandSender) {
    /** `{"status":"ok","payload":<qr text>,"expiresAt":<ms>,"lanEnabled":<bool>}` */
    fun mint(): JSONObject = ipc.sendCommand(JSONObject().put("cmd", "pairingMint"))

    /** `{"status":"ok","companions":[{"id","name","pairedAt"}, ...]}` */
    fun list(): JSONObject = ipc.sendCommand(JSONObject().put("cmd", "pairingList"))

    fun revoke(companionId: String): JSONObject =
        ipc.sendCommand(JSONObject().put("cmd", "pairingRevoke").put("id", companionId))

    /** The owner's LAN-access opt-in. `{"status":"ok","enabled":<bool>}` */
    fun setLanAccess(enabled: Boolean): JSONObject =
        ipc.sendCommand(JSONObject().put("cmd", "lanAccessSet").put("enabled", enabled))
}
