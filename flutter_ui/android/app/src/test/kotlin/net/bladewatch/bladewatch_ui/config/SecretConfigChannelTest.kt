package net.bladewatch.bladewatch_ui.config

import net.bladewatch.bladewatch_ui.ipc.IpcCommandSender
import net.bladewatch.bladewatch_ui.ipc.IpcException
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

private class FakeIpc(private val respond: (JSONObject) -> JSONObject) : IpcCommandSender {
    val sentCommands = mutableListOf<JSONObject>()
    override fun sendCommand(command: JSONObject): JSONObject {
        sentCommands.add(command)
        return respond(command)
    }
}

class SecretConfigChannelTest {

    @Test
    fun `get sends secret_get with section and key, and returns the value`() {
        val ipc = FakeIpc { JSONObject().put("status", "ok").put("value", "ztok_abc123") }
        val value = SecretConfigChannel(ipc).get("tunnels", "deviceToken")

        val sent = ipc.sentCommands.single()
        assertEquals("secret_get", sent.optString("cmd"))
        assertEquals("tunnels", sent.optString("section"))
        assertEquals("deviceToken", sent.optString("key"))
        assertEquals("ztok_abc123", value)
    }

    @Test
    fun `get returns null when the value is empty (key not set) rather than throwing`() {
        val ipc = FakeIpc { JSONObject().put("status", "ok").put("value", "") }
        assertNull(SecretConfigChannel(ipc).get("tunnels", "deviceToken"))
    }

    @Test
    fun `get returns null when the value is absent entirely`() {
        val ipc = FakeIpc { JSONObject().put("status", "ok") }
        assertNull(SecretConfigChannel(ipc).get("tunnels", "deviceToken"))
    }

    @Test
    fun `put sends secret_put with section, key, and value, and returns true on ok`() {
        val ipc = FakeIpc { JSONObject().put("status", "ok") }
        val result = SecretConfigChannel(ipc).put("tunnels", "deviceToken", "ztok_new")

        val sent = ipc.sentCommands.single()
        assertEquals("secret_put", sent.optString("cmd"))
        assertEquals("tunnels", sent.optString("section"))
        assertEquals("deviceToken", sent.optString("key"))
        assertEquals("ztok_new", sent.optString("value"))
        assertTrue(result)
    }

    @Test
    fun `put returns false when the daemon does not respond ok`() {
        val ipc = FakeIpc { JSONObject().put("status", "error").put("message", "disk full") }
        assertFalse(SecretConfigChannel(ipc).put("tunnels", "deviceToken", "x"))
    }

    @Test
    fun `delete sends secret_delete with section and key, and returns true on ok`() {
        val ipc = FakeIpc { JSONObject().put("status", "ok") }
        val result = SecretConfigChannel(ipc).delete("tunnels", "deviceToken")

        val sent = ipc.sentCommands.single()
        assertEquals("secret_delete", sent.optString("cmd"))
        assertEquals("tunnels", sent.optString("section"))
        assertEquals("deviceToken", sent.optString("key"))
        assertTrue(result)
    }

    @Test
    fun `delete returns false when the daemon does not respond ok`() {
        val ipc = FakeIpc { JSONObject().put("status", "error") }
        assertFalse(SecretConfigChannel(ipc).delete("tunnels", "deviceToken"))
    }

    @Test
    fun `get propagates IPC failures rather than swallowing them`() {
        val ipc = FakeIpc { throw IpcException.DaemonNotListening("down") }
        assertThrows(IpcException.DaemonNotListening::class.java) {
            SecretConfigChannel(ipc).get("tunnels", "deviceToken")
        }
    }

    @Test
    fun `put propagates IPC failures rather than swallowing them`() {
        val ipc = FakeIpc { throw IpcException.Timeout("slow") }
        assertThrows(IpcException.Timeout::class.java) {
            SecretConfigChannel(ipc).put("tunnels", "deviceToken", "x")
        }
    }

    @Test
    fun `delete propagates IPC failures rather than swallowing them`() {
        val ipc = FakeIpc { throw IpcException.CommandRejected("no") }
        assertThrows(IpcException.CommandRejected::class.java) {
            SecretConfigChannel(ipc).delete("tunnels", "deviceToken")
        }
    }

    @Test
    fun `get refuses to hand the device secret to Dart through the generic channel`() {
        // Regression guard for the class-level rule: the generic (section, key) shape
        // means Dart could otherwise read auth/deviceSecret without any method that
        // mentions auth. JwtMinter is the only sanctioned path to that value.
        val ipc = FakeIpc { JSONObject().put("status", "ok").put("value", "the-real-secret") }
        val channel = SecretConfigChannel(ipc)

        try {
            channel.get("auth", "deviceSecret")
            throw AssertionError("expected IllegalArgumentException")
        } catch (e: IllegalArgumentException) {
            assertTrue(e.message!!.contains("JwtMinter"))
        }
        assertTrue("no IPC call must be made", ipc.sentCommands.isEmpty())
    }

    @Test
    fun `the auth secret guard is case-insensitive`() {
        val ipc = FakeIpc { JSONObject().put("status", "ok").put("value", "x") }
        try {
            SecretConfigChannel(ipc).get("AUTH", "DeviceSecret")
            throw AssertionError("expected IllegalArgumentException")
        } catch (e: IllegalArgumentException) {
            // expected
        }
        assertTrue(ipc.sentCommands.isEmpty())
    }

    @Test
    fun `other keys in the auth section are still readable`() {
        // Only deviceSecret is off limits — deviceId/tokenEpoch are not secret.
        val ipc = FakeIpc { JSONObject().put("status", "ok").put("value", "byd-abc") }
        assertEquals("byd-abc", SecretConfigChannel(ipc).get("auth", "deviceId"))
    }
}
