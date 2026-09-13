package net.bladewatch.bladewatch_ui.daemon

import net.bladewatch.bladewatch_ui.ipc.IpcCommandSender
import net.bladewatch.bladewatch_ui.ipc.IpcException
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

private class FakeIpc(private val respond: (JSONObject) -> JSONObject) : IpcCommandSender {
    val sentCommands = mutableListOf<JSONObject>()
    override fun sendCommand(command: JSONObject): JSONObject {
        sentCommands.add(command)
        return respond(command)
    }
}

class DaemonControlTest {

    @Test
    fun `start sends the start command and returns the daemon's response`() {
        val ipc = FakeIpc { JSONObject().put("status", "ok") }
        val response = DaemonControl(ipc).start()

        assertEquals("start", ipc.sentCommands.single().optString("cmd"))
        assertEquals("ok", response.optString("status"))
    }

    @Test
    fun `stop sends the stop command`() {
        val ipc = FakeIpc { JSONObject().put("status", "ok") }
        DaemonControl(ipc).stop()

        assertEquals("stop", ipc.sentCommands.single().optString("cmd"))
    }

    @Test
    fun `status sends the status command and returns the daemon's response`() {
        val ipc = FakeIpc { JSONObject().put("status", "ok").put("recording", true) }
        val response = DaemonControl(ipc).status()

        assertEquals("status", ipc.sentCommands.single().optString("cmd"))
        assertEquals(true, response.optBoolean("recording"))
    }

    @Test
    fun `processStatus sends the daemonStatus command and returns the daemon's response`() {
        val ipc = FakeIpc {
            JSONObject().put("status", "ok").put(
                "daemons",
                JSONObject()
                    .put("CAMERA_DAEMON", true)
                    .put("SENTRY_DAEMON", false)
                    .put("ACC_SENTRY_DAEMON", false)
                    .put("ZROK_TUNNEL", false),
            )
        }
        val response = DaemonControl(ipc).processStatus()

        assertEquals("daemonStatus", ipc.sentCommands.single().optString("cmd"))
        assertEquals(true, response.getJSONObject("daemons").getBoolean("CAMERA_DAEMON"))
        assertEquals(false, response.getJSONObject("daemons").getBoolean("SENTRY_DAEMON"))
    }

    @Test
    fun `propagates TokenUnreadable so the UI can show a specific message`() {
        val ipc = FakeIpc { throw IpcException.TokenUnreadable("no token") }
        assertThrows(IpcException.TokenUnreadable::class.java) { DaemonControl(ipc).status() }
    }

    @Test
    fun `propagates DaemonNotListening`() {
        val ipc = FakeIpc { throw IpcException.DaemonNotListening("down") }
        assertThrows(IpcException.DaemonNotListening::class.java) { DaemonControl(ipc).start() }
    }

    @Test
    fun `propagates CommandRejected`() {
        val ipc = FakeIpc { throw IpcException.CommandRejected("no") }
        assertThrows(IpcException.CommandRejected::class.java) { DaemonControl(ipc).stop() }
    }

    @Test
    fun `propagates Timeout`() {
        val ipc = FakeIpc { throw IpcException.Timeout("slow") }
        assertThrows(IpcException.Timeout::class.java) { DaemonControl(ipc).status() }
    }
}
