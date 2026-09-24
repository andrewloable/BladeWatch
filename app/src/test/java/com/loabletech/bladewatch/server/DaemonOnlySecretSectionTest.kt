package net.bladewatch.app.server

import java.io.File
import java.nio.file.Files
import net.bladewatch.app.auth.CompanionPairing
import net.bladewatch.app.config.SecretConfigStore
import net.bladewatch.app.daemon.PearTopic
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test

/**
 * BladeWatch-rdtj.16: the secret-store sections only byd_cam_daemon uses -- the LAN TLS identity,
 * the Pear topic seed, the discovery probe key and the paired companions -- are out of reach of
 * every secret_* IPC command, in both directions. The app UID is trusted, but it must not be able
 * to read those keys or plant a companion.
 */
class DaemonOnlySecretSectionTest {

    private lateinit var store: SecretConfigStore
    private val server = TcpCommandServer(19876)
    private val sections = listOf(LanTls.SECTION, PearTopic.SECTION, LanDiscoveryResponder.SECTION, CompanionPairing.SECTION)

    @Before
    fun setUp() {
        store = SecretConfigStore(File(Files.createTempDirectory("daemon-only").toFile(), "secrets.json"))
        TcpCommandServer.secretStoreForTest = store
        sections.forEach { store.putString(it, "k", "secret-$it") }
    }

    @After
    fun tearDown() {
        TcpCommandServer.secretStoreForTest = null
    }

    private fun command(name: String, section: String, vararg extra: Pair<String, Any>): JSONObject =
        server.processCommand(
            JSONObject().put("cmd", name).put("section", section).put("key", "k").apply { extra.forEach { (k, v) -> put(k, v) } },
        )

    @Test
    fun `every secret command is refused on every daemon-only section, whatever the case`() {
        for (section in sections + sections.map { it.uppercase() }) {
            for (response in listOf(
                command("secret_get", section),
                command("secret_get_section", section),
                command("secret_put", section, "value" to "planted"),
                command("secret_delete", section),
            )) {
                assertEquals("$section: $response", "error", response.getString("status"))
                assertEquals("", response.optString("value", ""))
                assertEquals(false, response.has("section"))
            }
        }
        // Nothing was read out, written or deleted.
        sections.forEach { assertEquals("secret-$it", store.getString(it, "k")) }
    }

    @Test
    fun `other sections still work over IPC`() {
        assertEquals("ok", command("secret_put", "tunnels", "value" to "v").getString("status"))
        assertEquals("v", command("secret_get", "tunnels").getString("value"))
        assertEquals("ok", command("secret_delete", "tunnels").getString("status"))
    }
}
