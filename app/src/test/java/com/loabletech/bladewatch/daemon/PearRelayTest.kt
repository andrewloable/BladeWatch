package net.bladewatch.app.daemon

import java.io.File
import java.nio.file.Files
import net.bladewatch.app.config.SecretConfigStore
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** BladeWatch-a7mu: what the car hands pear-end for the owner's relay, read from the secret store. */
class PearRelayTest {

    private fun store(vararg values: Pair<String, Any>): SecretConfigStore =
        SecretConfigStore(File(Files.createTempDirectory("pear-relay").toFile(), "secrets.json")).apply {
            values.forEach { (key, value) ->
                when (value) {
                    is Boolean -> putBoolean(PearRelay.SECTION, key, value)
                    else -> putString(PearRelay.SECTION, key, value.toString())
                }
            }
        }

    @Test
    fun `no section means no relay`() {
        assertNull(PearRelay.desiredKey(store()))
    }

    @Test
    fun `switched off means no relay, even with a key stored`() {
        assertNull(PearRelay.desiredKey(store("enabled" to "false", "key" to "482109375562")))
    }

    @Test
    fun `switched on with a key gives the bare digits`() {
        // The in-car app writes strings ("true"); a JSON boolean is accepted too.
        assertEquals("482109375562", PearRelay.desiredKey(store("enabled" to "true", "key" to "482109375562")))
        assertEquals("482109375562", PearRelay.desiredKey(store("enabled" to true, "key" to "4821-0937-5562")))
    }

    @Test
    fun `switched on without a valid key means no relay`() {
        assertNull(PearRelay.desiredKey(store("enabled" to "true")))
        for (bad in listOf("482109", "4821093755621", "4821-0937-556x", "٤821-0937-5562")) {
            assertNull(bad, PearRelay.desiredKey(store("enabled" to "true", "key" to bad)))
        }
    }

    @Test
    fun `relay set carries the key, or an explicit null to stop`() {
        assertEquals("482109375562", PearRelay.relaySetParams("482109375562").getString("key"))
        val off = PearRelay.relaySetParams(null)
        assertTrue(off.has("key"))
        assertEquals(JSONObject.NULL, off.get("key"))
    }
}
