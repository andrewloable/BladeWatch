package net.bladewatch.bladewatch_ui.pairing

import net.bladewatch.bladewatch_ui.ipc.IpcCommandSender
import net.bladewatch.bladewatch_ui.ipc.IpcException
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

private class FakeIpc(private val respond: (JSONObject) -> JSONObject) : IpcCommandSender {
    val sent = mutableListOf<JSONObject>()
    override fun sendCommand(command: JSONObject): JSONObject {
        sent.add(command)
        return respond(command)
    }
}

/** BladeWatch-rdtj.7: the in-car pairing flow's IPC commands, exactly as the daemon names them. */
class PairingControlTest {

    @Test
    fun `mint asks the daemon for a pairing payload and returns its answer`() {
        val ipc = FakeIpc { JSONObject().put("status", "ok").put("payload", "qr").put("expiresAt", 5L) }
        val response = PairingControl(ipc).mint()
        assertEquals("pairingMint", ipc.sent.single().getString("cmd"))
        assertEquals("qr", response.getString("payload"))
    }

    @Test
    fun `list asks for the paired companions`() {
        val ipc = FakeIpc { JSONObject().put("status", "ok").put("companions", org.json.JSONArray()) }
        PairingControl(ipc).list()
        assertEquals("pairingList", ipc.sent.single().getString("cmd"))
    }

    @Test
    fun `revoke names the companion to un-pair`() {
        val ipc = FakeIpc { JSONObject().put("status", "ok") }
        PairingControl(ipc).revoke("abc123")
        assertEquals("pairingRevoke", ipc.sent.single().getString("cmd"))
        assertEquals("abc123", ipc.sent.single().getString("id"))
    }

    @Test
    fun `setLanAccess sends the owner's choice`() {
        val ipc = FakeIpc { JSONObject().put("status", "ok").put("enabled", true) }
        PairingControl(ipc).setLanAccess(true)
        assertEquals("lanAccessSet", ipc.sent.single().getString("cmd"))
        assertEquals(true, ipc.sent.single().getBoolean("enabled"))
    }

    @Test
    fun `a refusal from the daemon reaches the caller unchanged`() {
        val ipc = FakeIpc { throw IpcException.CommandRejected("no such companion") }
        assertThrows(IpcException.CommandRejected::class.java) { PairingControl(ipc).revoke("gone") }
    }
}
