package net.bladewatch.app.server

import java.io.File
import java.net.ServerSocket
import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.util.Base64
import net.bladewatch.app.auth.AuthManager
import net.bladewatch.app.auth.CompanionPairing
import net.bladewatch.app.config.SecretConfigStore
import net.bladewatch.app.daemon.PearTopic
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * BladeWatch-rdtj.7: the in-car pairing commands on the IPC server -- mint, list, revoke, and the
 * LAN opt-in the pairing flow switches -- and that nothing but the in-car UI can reach them.
 */
class PairingCommandTest {

    private lateinit var store: SecretConfigStore
    private lateinit var pairing: CompanionPairing
    private val server = TcpCommandServer(19876)

    @Before
    fun setUp() {
        store = SecretConfigStore(File(Files.createTempDirectory("pairing-cmd").toFile(), "secrets.json"))
        TcpCommandServer.secretStoreForTest = store
        TcpCommandServer.daemonEnabledWritesForTest = LinkedHashMap()
        TcpCommandServer.lanEnabledForTest = false
        pairing = CompanionPairing(store, { "device-secret" })
        CompanionPairing.sharedForTest = pairing
        AuthManager.setTestState(AuthManager.AuthState().apply { deviceId = "byd-test"; deviceSecret = "device-secret" })
    }

    @After
    fun tearDown() {
        TcpCommandServer.secretStoreForTest = null
        TcpCommandServer.daemonEnabledWritesForTest = null
        TcpCommandServer.lanEnabledForTest = null
        CompanionPairing.sharedForTest = null
        AuthManager.setTestState(null)
        PeerCredentials.peerUidForTest = null
        PeerCredentials.appUidOverrideForTest = null
        IpcTokenManager.cachedToken = null
    }

    private fun command(name: String, vararg extra: Pair<String, Any>): JSONObject =
        server.processCommand(JSONObject().put("cmd", name).apply { extra.forEach { (k, v) -> put(k, v) } })

    @Test
    fun `pairingMint returns this car's own identity and switches remote access on`() {
        val response = command("pairingMint")
        assertEquals("ok", response.getString("status"))
        val payload = JSONObject(String(Base64.getUrlDecoder().decode(response.getString("payload")), StandardCharsets.UTF_8))
        assertEquals(CompanionPairing.PAYLOAD_VERSION, payload.getInt("v"))
        assertEquals("byd-test", payload.getString("deviceId"))
        assertEquals("the QR must carry the topic pear_daemon announces", PearTopic.topicHex(store), payload.getString("pearTopic"))
        assertEquals(LanTls.loadOrCreate(store).fingerprintSha256, payload.getString("tlsFp"))
        assertEquals(LanTls.PORT, payload.getInt("tlsPort"))
        assertEquals(store.getString("lanDiscovery", "probeKey"), payload.getString("probeKey"))
        assertEquals(payload.getLong("exp"), response.getLong("expiresAt"))
        assertEquals(false, response.getBoolean("lanEnabled"))
        assertEquals(mapOf("PEAR_PEER" to true), TcpCommandServer.daemonEnabledWritesForTest)
    }

    @Test
    fun `list and revoke round-trip through the IPC commands`() {
        val code = JSONObject(String(Base64.getUrlDecoder().decode(command("pairingMint").getString("payload")))).getString("code")
        val credential = pairing.redeem(code, "Owner's phone")!!

        val listed = command("pairingList").getJSONArray("companions")
        assertEquals(1, listed.length())
        assertEquals(credential.companionId, listed.getJSONObject(0).getString("id"))
        assertEquals("Owner's phone", listed.getJSONObject(0).getString("name"))

        assertEquals("ok", command("pairingRevoke", "id" to credential.companionId).getString("status"))
        assertEquals(0, command("pairingList").getJSONArray("companions").length())
        assertEquals("error", command("pairingRevoke", "id" to credential.companionId).getString("status"))
    }

    @Test
    fun `the pairing flow's LAN switch writes the opt-in`() {
        assertEquals(true, command("lanAccessSet", "enabled" to true).getBoolean("enabled"))
        assertEquals(true, TcpCommandServer.lanEnabledForTest)
        command("lanAccessSet", "enabled" to false)
        assertEquals(false, TcpCommandServer.lanEnabledForTest)
    }

    @Test
    fun `a caller that is not the in-car UI cannot mint, list or revoke pairings`() {
        // The co-resident attacker of CoResidentAttackerTest: it can read the world-readable IPC
        // token, but its peer UID is not the BladeWatch app's.
        val token = "TestTokenABCDEFGHIJKLMNOPQR012345"
        IpcTokenManager.cachedToken = token
        PeerCredentials.appUidOverrideForTest = 10085
        PeerCredentials.peerUidForTest = 10500
        val port = ServerSocket(0).use { it.localPort }
        val tcp = TcpCommandServer(port)
        Thread(tcp::start).apply { isDaemon = true }.start()
        Thread.sleep(300)
        val victim = pairing.redeem(pairing.mint(CompanionPairing.Identity("byd-test", "ab".repeat(32), 8443, "cd".repeat(32), "ef".repeat(32))).code, "victim")!!
        try {
            for (cmd in listOf(
                JSONObject().put("cmd", "pairingMint"),
                JSONObject().put("cmd", "pairingList"),
                JSONObject().put("cmd", "pairingRevoke").put("id", victim.companionId),
                JSONObject().put("cmd", "lanAccessSet").put("enabled", true),
            )) {
                IpcRoundTripTest.TcpClient(port).use { client ->
                    val reply = try {
                        client.connect(token)
                        client.sendRaw(cmd)
                    } catch (e: Exception) {
                        null // the server hung up on it: the expected outcome
                    }
                    if (reply != null) assertEquals("${cmd.getString("cmd")} must be refused", "error", reply.optString("status"))
                    assertNotEquals("no payload may leak", true, reply?.has("payload"))
                }
            }
            assertTrue("the attacker must not have un-paired anyone", pairing.isPaired(victim.companionId))
            assertEquals(emptyMap<String, Boolean>(), TcpCommandServer.daemonEnabledWritesForTest)
            assertEquals(false, TcpCommandServer.lanEnabledForTest)
        } finally {
            tcp.stop()
        }
    }
}
