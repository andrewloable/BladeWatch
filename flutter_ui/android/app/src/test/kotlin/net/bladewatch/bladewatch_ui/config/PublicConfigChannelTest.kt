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

    /// getCameraProbe backs the Diagnostics Camera health tile. It shipped with
    /// no test at all, which took this module's Kover gate from its required
    /// 100% down to 96.2% -- unnoticed because `./gradlew koverVerify` at the
    /// repo root verifies the SERVICE HOST module; this one lives in the
    /// separate `flutter_ui/android` Gradle project and has to be run there.
    @Test
    fun `getCameraProbe reads the camera section and types both fields`() {
        val ipc = FakePublicConfigIpc {
            JSONObject()
                .put("status", "ok")
                .put("section", JSONObject().put("probedCameraId", 3).put("manualOverride", true))
        }

        val probe = PublicConfigChannel(ipc).getCameraProbe()

        val sent = ipc.sentCommands.single()
        assertEquals("config_get_section", sent.optString("cmd"))
        assertEquals("camera", sent.optString("section"))
        // probedCameraId is an Int; getSection would have coerced it to a Boolean,
        // which is the whole reason this typed method exists.
        assertEquals(3, probe!!.probedCameraId)
        assertTrue(probe.manualOverride)
    }

    @Test
    fun `getCameraProbe returns null when the daemon sends no section`() {
        // null means UNKNOWN. The caller must not confuse it with a probe that
        // genuinely answered -1, which means "not probed yet" -- the class doc
        // calls this out explicitly.
        val ipc = FakePublicConfigIpc { JSONObject().put("status", "error").put("message", "nope") }
        assertNull(PublicConfigChannel(ipc).getCameraProbe())
    }

    @Test
    fun `getCameraProbe defaults a missing probe id to -1, not to zero`() {
        // 0 is a VALID camera id, so defaulting to it would report camera 0 as
        // probed when nothing was.
        val ipc = FakePublicConfigIpc {
            JSONObject().put("status", "ok").put("section", JSONObject())
        }

        val probe = PublicConfigChannel(ipc).getCameraProbe()

        assertEquals(-1, probe!!.probedCameraId)
        assertFalse(probe.manualOverride)
    }

    @Test
    fun `getCameraProbe propagates an IPC failure rather than reporting unknown`() {
        // Returning null here would be indistinguishable from a daemon that
        // answered without a section, hiding that the daemon is down.
        val ipc = FakePublicConfigIpc { throw IpcException.DaemonNotListening("connect failed") }
        assertThrows(IpcException::class.java) { PublicConfigChannel(ipc).getCameraProbe() }
    }
}
