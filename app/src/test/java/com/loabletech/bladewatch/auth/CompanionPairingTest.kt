package net.bladewatch.app.auth

import java.io.File
import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.security.SecureRandom
import java.util.Base64
import java.util.concurrent.atomic.AtomicLong
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec
import net.bladewatch.app.config.SecretConfigStore
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * BladeWatch-rdtj.7: pairing the companion app -- single-use, short-lived codes, per-companion
 * credentials, and revocation that touches exactly one companion.
 */
class CompanionPairingTest {

    private val secret = "device-secret-for-tests"
    private val clock = AtomicLong(1_700_000_000_000)
    private lateinit var store: SecretConfigStore
    private lateinit var pairing: CompanionPairing

    private val identity = CompanionPairing.Identity(
        deviceId = "byd-test",
        pearTopic = "ab".repeat(32),
        tlsPort = 8443,
        tlsFingerprint = "cd".repeat(32),
        probeKey = "ef".repeat(32),
    )

    @Before
    fun setUp() {
        store = SecretConfigStore(File(Files.createTempDirectory("pairing").toFile(), "secrets.json"))
        pairing = CompanionPairing(store, { secret }, clock::get, SecureRandom())
        CompanionPairing.sharedForTest = pairing
        AuthManager.setTestState(AuthManager.AuthState().apply { deviceId = "byd-test"; deviceSecret = secret })
    }

    @After
    fun tearDown() {
        CompanionPairing.sharedForTest = null
        AuthManager.setTestState(null)
    }

    @Test
    fun `a code can be redeemed once and never again`() {
        val code = pairing.mint(identity).code
        val credential = pairing.redeem(code, "Pixel")
        assertNotNull(credential)
        assertNull("a second redemption must be refused", pairing.redeem(code, "Pixel"))
        assertTrue(pairing.verify(credential!!.companionId, credential.token))
    }

    @Test
    fun `an expired code is refused`() {
        val code = pairing.mint(identity).code
        clock.addAndGet(CompanionPairing.CODE_TTL_MS + 1)
        assertNull(pairing.redeem(code, "Pixel"))
        assertTrue(pairing.list().isEmpty())
    }

    @Test
    fun `a code nobody minted is refused`() {
        pairing.mint(identity)
        assertNull(pairing.redeem("not-a-real-code", "Pixel"))
    }

    @Test
    fun `revoking one companion leaves the other able to get a JWT, and kills only its own sessions`() {
        val a = pairing.redeem(pairing.mint(identity).code, "Phone A")!!
        val b = pairing.redeem(pairing.mint(identity).code, "Phone B")!!
        val jwtA = AuthManager.generateJwt(a.companionId)!!
        val jwtB = AuthManager.generateJwt(b.companionId)!!
        val webSession = AuthManager.generateJwt()!!
        assertTrue(AuthManager.validateJwt(jwtA).valid)

        assertTrue(pairing.revoke(a.companionId))

        assertFalse("A's token must stop working", pairing.verify(a.companionId, a.token))
        assertFalse("A's live session must stop working", AuthManager.validateJwt(jwtA).valid)
        assertTrue("B is untouched", pairing.verify(b.companionId, b.token))
        assertTrue(AuthManager.validateJwt(jwtB).valid)
        assertTrue("B can still mint a fresh JWT", AuthManager.validateJwt(AuthManager.generateJwt(b.companionId)).valid)
        assertTrue("a session with no companion is unaffected", AuthManager.validateJwt(webSession).valid)
        assertEquals(listOf("Phone B"), pairing.list().map { it.name })
    }

    @Test
    fun `a companion token does not verify for another companion, or once the secret rotates`() {
        val a = pairing.redeem(pairing.mint(identity).code, "A")!!
        val b = pairing.redeem(pairing.mint(identity).code, "B")!!
        assertFalse(pairing.verify(b.companionId, a.token))
        val rotated = CompanionPairing(store, { "a-new-device-secret" }, clock::get, SecureRandom())
        assertFalse(rotated.verify(a.companionId, a.token))
    }

    @Test
    fun `the token is HMAC-SHA256 of the device secret over the domain tag, a zero byte and the id`() {
        val mac = Mac.getInstance("HmacSHA256").apply { init(SecretKeySpec(secret.toByteArray(), "HmacSHA256")) }
        mac.update("bladewatch/companion/v1".toByteArray(StandardCharsets.UTF_8))
        mac.update(0)
        val expected = Base64.getUrlEncoder().withoutPadding().encodeToString(mac.doFinal("0123456789abcdef0123456789abcdef".toByteArray()))
        assertEquals(expected, CompanionPairing.token(secret, "0123456789abcdef0123456789abcdef"))
    }

    @Test
    fun `the QR payload carries no credential`() {
        val json = pairing.mint(identity).toJson()
        assertEquals(setOf("v", "deviceId", "pearTopic", "tlsPort", "tlsFp", "probeKey", "code", "exp"), json.keys().asSequence().toSet())
        assertFalse(json.toString().contains(secret))
    }

    @Test
    fun `the payload wire format is pinned -- the companion decodes exactly these fields`() {
        // GOLDEN is shared, byte for byte, with packages/bladewatch_rpc/test/pairing/
        // pairing_payload_test.dart: the companion must decode what the car encodes. JSON key order
        // is not part of the format (Android's org.json keeps insertion order, the JVM's does not),
        // so the fields are compared, not the bytes.
        val payload = CompanionPairing.Payload("byd-test", "ab".repeat(32), 8443, "cd".repeat(32), "ef".repeat(32), "c0de", 1_700_000_300_000)
        val ours = JSONObject(String(Base64.getUrlDecoder().decode(payload.encode()), StandardCharsets.UTF_8))
        val golden = JSONObject(String(Base64.getUrlDecoder().decode(GOLDEN), StandardCharsets.UTF_8))
        assertTrue("fields drifted from the companion's golden: $ours", ours.similar(golden))
        assertFalse("base64url without padding", payload.encode().any { it == '=' || it == '+' || it == '/' })
    }

    @Test
    fun `at most four codes are outstanding, and the oldest goes first`() {
        val first = pairing.mint(identity).code
        repeat(4) { pairing.mint(identity) }
        assertNull(pairing.redeem(first, "late"))
    }

    @Test
    fun `nothing is paired without a device secret`() {
        val noSecret = CompanionPairing(store, { null }, clock::get, SecureRandom())
        assertNull(noSecret.redeem(noSecret.mint(identity).code, "x"))
    }

    @Test
    fun `malformed companion ids are never paired`() {
        assertFalse(pairing.isPaired(""))
        assertFalse(pairing.isPaired("../../etc"))
        assertFalse(pairing.revoke("nope"))
    }

    private companion object {
        const val GOLDEN = "eyJ2IjoxLCJkZXZpY2VJZCI6ImJ5ZC10ZXN0IiwicGVhclRvcGljIjoiYWJhYmFiYWJhYmFiYWJhYmFiYWJhYmFiYWJhYmFiYWJhYmFiYWJhYmFiYWJhYmFiYWJhYmFiYWJhYmFiYWJhYiIsInRsc1BvcnQiOjg0NDMsInRsc0ZwIjoiY2RjZGNkY2RjZGNkY2RjZGNkY2RjZGNkY2RjZGNkY2RjZGNkY2RjZGNkY2RjZGNkY2RjZGNkY2RjZGNkY2RjZCIsInByb2JlS2V5IjoiZWZlZmVmZWZlZmVmZWZlZmVmZWZlZmVmZWZlZmVmZWZlZmVmZWZlZmVmZWZlZmVmZWZlZmVmZWZlZmVmZWZlZiIsImNvZGUiOiJjMGRlIiwiZXhwIjoxNzAwMDAwMzAwMDAwfQ"
    }
}
