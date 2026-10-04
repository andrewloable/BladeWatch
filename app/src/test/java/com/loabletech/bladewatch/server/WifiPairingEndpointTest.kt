package net.bladewatch.app.server

import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.file.Files
import java.util.Base64
import net.bladewatch.app.auth.AuthManager
import net.bladewatch.app.auth.CompanionPairing
import net.bladewatch.app.auth.WifiPairing
import net.bladewatch.app.config.SecretConfigStore
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * BladeWatch 1.4.1.2: Wi-Fi pairing end to end on the car -- the device's three calls on the LAN
 * listener, and the in-car dialog's three IPC commands in between.
 */
class WifiPairingEndpointTest {

    private lateinit var store: SecretConfigStore
    private lateinit var pairing: CompanionPairing
    private val ipc = TcpCommandServer(19876)
    private val nonce = ByteArray(32) { (it * 3).toByte() }

    @Before
    fun setUp() {
        store = SecretConfigStore(File(Files.createTempDirectory("wifi-pair").toFile(), "secrets.json"))
        TcpCommandServer.secretStoreForTest = store
        TcpCommandServer.daemonEnabledWritesForTest = LinkedHashMap()
        TcpCommandServer.lanEnabledForTest = true
        pairing = CompanionPairing(store, { "device-secret" })
        CompanionPairing.sharedForTest = pairing
        WifiPairing.sharedForTest = WifiPairing()
        AuthManager.setTestState(AuthManager.AuthState().apply { deviceId = "byd-test"; deviceSecret = "device-secret" })
    }

    @After
    fun tearDown() {
        TcpCommandServer.secretStoreForTest = null
        TcpCommandServer.daemonEnabledWritesForTest = null
        TcpCommandServer.lanEnabledForTest = null
        CompanionPairing.sharedForTest = null
        WifiPairing.sharedForTest = null
        AuthManager.setTestState(null)
    }

    private fun post(path: String, body: JSONObject, viaLan: Boolean = true): JSONObject? {
        val out = ByteArrayOutputStream()
        if (!AuthApiHandler.handle("POST", path, body.toString(), out, viaLan)) return null
        val raw = out.toString(Charsets.UTF_8.name())
        return JSONObject(raw.substring(raw.indexOf("\r\n\r\n") + 4))
    }

    private fun command(name: String, vararg extra: Pair<String, Any>): JSONObject =
        ipc.processCommand(JSONObject().put("cmd", name).apply { extra.forEach { (k, v) -> put(k, v) } })

    private fun hex(bytes: ByteArray) = bytes.joinToString("") { "%02x".format(it.toInt() and 0xff) }

    private fun start(): JSONObject = post(
        AuthApiHandler.WIFI_PAIR_START_PATH,
        JSONObject().put("name", "Living room TV").put("commitment", hex(WifiPairing.sha256(nonce))),
    )!!

    @Test
    fun `the owner confirms the number in the car, and the device gets a payload for this car`() {
        assertTrue(command("pairingWifiWindow", "open" to true).getBoolean("lanEnabled"))
        val started = start()
        assertTrue(started.getBoolean("success"))
        val id = started.getString("id")
        assertTrue(post(AuthApiHandler.WIFI_PAIR_REVEAL_PATH, JSONObject().put("id", id).put("deviceNonce", hex(nonce)))!!.getBoolean("success"))

        val request = command("pairingWifiPending").getJSONObject("request")
        assertEquals("Living room TV", request.getString("name"))
        val carNonce = started.getString("carNonce").chunked(2).map { it.toInt(16).toByte() }.toByteArray()
        assertEquals("the number the device computes from the certificate it sees",
            WifiPairing.number(LanTls.loadOrCreate(store).fingerprintSha256, nonce, carNonce), request.getString("number"))
        assertEquals("waiting", post(AuthApiHandler.WIFI_PAIR_RESULT_PATH, JSONObject().put("id", id))!!.getString("state"))

        assertEquals("ok", command("pairingWifiDecide", "id" to request.getString("id"), "accept" to true).getString("status"))
        val result = post(AuthApiHandler.WIFI_PAIR_RESULT_PATH, JSONObject().put("id", id))!!
        assertEquals("accepted", result.getString("state"))
        val payload = JSONObject(String(Base64.getUrlDecoder().decode(result.getString("payload")), Charsets.UTF_8))
        assertEquals(LanTls.loadOrCreate(store).fingerprintSha256, payload.getString("tlsFp"))
        assertNotNull("the code redeems like a QR's", pairing.redeem(payload.getString("code"), "Living room TV"))
        assertEquals("pairing switches remote access on, as with a QR", mapOf("PEAR_PEER" to true), TcpCommandServer.daemonEnabledWritesForTest)
        assertEquals("wifi_pairing_refused", post(AuthApiHandler.WIFI_PAIR_RESULT_PATH, JSONObject().put("id", id))!!.getString("error"))
    }

    @Test
    fun `Wi-Fi pairing is not reachable over Pear or loopback`() {
        command("pairingWifiWindow", "open" to true)
        for (path in listOf(AuthApiHandler.WIFI_PAIR_START_PATH, AuthApiHandler.WIFI_PAIR_REVEAL_PATH, AuthApiHandler.WIFI_PAIR_RESULT_PATH)) {
            assertEquals("$path must 404 off the LAN listener", null, post(path, JSONObject(), viaLan = false))
        }
    }

    @Test
    fun `nothing starts unless the dialog is open, and the owner can refuse`() {
        assertEquals("wifi_pairing_closed", start().getString("error"))
        command("pairingWifiWindow", "open" to true)
        assertEquals("a malformed commitment", "wifi_pairing_closed",
            post(AuthApiHandler.WIFI_PAIR_START_PATH, JSONObject().put("commitment", "AB".repeat(32)))!!.getString("error"))

        val id = start().getString("id")
        assertEquals("wifi_pairing_refused",
            post(AuthApiHandler.WIFI_PAIR_REVEAL_PATH, JSONObject().put("id", id).put("deviceNonce", "zz"))!!.getString("error"))
        val again = start().getString("id")
        post(AuthApiHandler.WIFI_PAIR_REVEAL_PATH, JSONObject().put("id", again).put("deviceNonce", hex(nonce)))
        assertEquals("error", command("pairingWifiDecide", "id" to "nope", "accept" to true).getString("status"))
        assertEquals("ok", command("pairingWifiDecide", "id" to again, "accept" to false).getString("status"))
        assertEquals("wifi_pairing_refused", post(AuthApiHandler.WIFI_PAIR_RESULT_PATH, JSONObject().put("id", again))!!.getString("error"))
        assertTrue(command("pairingWifiPending").isNull("request"))
        assertEquals(emptyMap<String, Boolean>(), TcpCommandServer.daemonEnabledWritesForTest)

        command("pairingWifiWindow", "open" to false)
        assertFalse(WifiPairing.shared.isOpen())
    }
}
