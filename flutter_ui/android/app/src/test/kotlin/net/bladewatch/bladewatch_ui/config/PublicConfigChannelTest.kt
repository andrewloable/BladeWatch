package net.bladewatch.bladewatch_ui.config

import net.bladewatch.bladewatch_ui.ipc.IpcCommandSender
import net.bladewatch.bladewatch_ui.ipc.IpcException
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

private class FakePublicConfigIpc(private val respond: (JSONObject) -> JSONObject) : IpcCommandSender {
    val sentCommands = mutableListOf<JSONObject>()
    override fun sendCommand(command: JSONObject): JSONObject {
        sentCommands.add(command)
        return respond(command)
    }
}

class PublicConfigChannelTest {

    @Test
    fun `getSection sends config_get_section and maps every key to a boolean`() {
        val ipc = FakePublicConfigIpc {
            JSONObject()
                .put("status", "ok")
                .put("section", JSONObject().put("cameraVisible", true).put("tripVisible", false))
        }

        val section = PublicConfigChannel(ipc).getSection("statusOverlay")

        val sent = ipc.sentCommands.single()
        assertEquals("config_get_section", sent.optString("cmd"))
        assertEquals("statusOverlay", sent.optString("section"))
        assertEquals(mapOf("cameraVisible" to true, "tripVisible" to false), section)
    }

    @Test
    fun `getSection returns an empty map when the daemon sends no section`() {
        // The caller must be able to tell "call failed" from "everything off",
        // so a refused/incomplete response must not look like a set of false flags.
        val ipc = FakePublicConfigIpc { JSONObject().put("status", "error").put("message", "nope") }
        assertTrue(PublicConfigChannel(ipc).getSection("network").isEmpty())
    }

    @Test
    fun `putBoolean sends config_put with the value and reports ok`() {
        val ipc = FakePublicConfigIpc { JSONObject().put("status", "ok") }

        assertTrue(PublicConfigChannel(ipc).putBoolean("developerOptions", "debugLogsEnabled", true))

        val sent = ipc.sentCommands.single()
        assertEquals("config_put", sent.optString("cmd"))
        assertEquals("developerOptions", sent.optString("section"))
        assertEquals("debugLogsEnabled", sent.optString("key"))
        assertTrue(sent.optBoolean("value"))
    }

    @Test
    fun `putBoolean reports failure when the daemon refuses the write`() {
        val ipc = FakePublicConfigIpc { JSONObject().put("status", "error") }
        assertFalse(PublicConfigChannel(ipc).putBoolean("network", "lanHttpEnabled", true))
    }

    @Test
    fun `an IPC failure propagates rather than being reported as a successful write`() {
        val ipc = FakePublicConfigIpc { throw IpcException.DaemonNotListening("connect failed") }
        assertThrows(IpcException::class.java) {
            PublicConfigChannel(ipc).putBoolean("statusOverlay", "tripVisible", false)
        }
    }
}
