package net.bladewatch.app.daemon

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** BladeWatch-lw0o: the car accepts companions it cannot find announced. */
class PearDaemonJoinTest {

    @Test
    fun `the car joins its topic accepting unannounced companions`() {
        val params = PearDaemon.joinParams("ab".repeat(32))
        assertEquals("ab".repeat(32), params.getString("topic"))
        assertTrue(params.getBoolean("acceptUnannounced"))
        // The car must keep announcing: it is what every companion looks up.
        assertTrue(!params.has("server") || params.getBoolean("server"))
    }

    /**
     * BladeWatch-rdtj.24: one identity across restarts. pear-end reads its storage root from argv[0]
     * under BareKit, so the order matters as much as the flag.
     */
    @Test
    fun `the worklet keeps its identity across restarts, storage root first`() {
        val args = PearDaemon.workletArgs.toList()
        assertEquals(PearDaemon.STORAGE_DIR, args.first())
        assertEquals(listOf(PearDaemon.STORAGE_DIR, "--persistent-identity"), args)
    }

    /**
     * BladeWatch-a7mu: pear-end hears about the owner's relay only when the setting changes, and a
     * car that never had one sends nothing, so its worklet runs exactly as before.
     */
    @Test
    fun `relay set is sent only when the owner's relay setting changes`() {
        val key = "482109375562"
        assertNull(PearDaemon.relayRequest(null, null))
        assertEquals(key, PearDaemon.relayRequest(null, key)!!.getString("key"))
        assertNull(PearDaemon.relayRequest(key, key))
        assertEquals("111122223333", PearDaemon.relayRequest(key, "111122223333")!!.getString("key"))
        assertEquals(JSONObject.NULL, PearDaemon.relayRequest(key, null)!!.get("key"))
    }
}
