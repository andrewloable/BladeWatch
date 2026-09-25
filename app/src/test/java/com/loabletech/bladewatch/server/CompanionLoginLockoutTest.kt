package net.bladewatch.app.server

import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.file.Files
import java.security.SecureRandom
import java.util.concurrent.atomic.AtomicLong
import net.bladewatch.app.auth.AuthManager
import net.bladewatch.app.auth.CompanionPairing
import net.bladewatch.app.config.SecretConfigStore
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * BladeWatch-rlgv: anyone who can reach the /auth endpoints used to be able to keep every companion locked
 * out -- 30 bad tries tripped a global 5-minute lockout, and all remote peers share one
 * 127.0.0.1 bucket. What the companion endpoints check is 128 bits or more, so a burst of bad
 * attempts must not stop a real companion from logging in or pairing.
 */
class CompanionLoginLockoutTest {

    private lateinit var pairing: CompanionPairing
    private val secret = "device-secret-for-tests"

    @Before
    fun setUp() {
        AuthApiHandler.resetRateLimitsForTest()
        val store = SecretConfigStore(File(Files.createTempDirectory("lockout").toFile(), "secrets.json"))
        pairing = CompanionPairing(store, { secret }, AtomicLong(1_700_000_000_000)::get, SecureRandom())
        CompanionPairing.sharedForTest = pairing
        AuthManager.setTestState(AuthManager.AuthState().apply { deviceId = "byd-test"; deviceSecret = secret })
    }

    @After
    fun tearDown() {
        AuthApiHandler.resetRateLimitsForTest()
        CompanionPairing.sharedForTest = null
        AuthManager.setTestState(null)
    }

    private fun post(path: String, body: JSONObject): JSONObject {
        val out = ByteArrayOutputStream()
        assertTrue(AuthApiHandler.handle("POST", path, body.toString(), out, "127.0.0.1", false))
        val raw = out.toString(Charsets.UTF_8.name())
        return JSONObject(raw.substring(raw.indexOf("\r\n\r\n") + 4))
    }

    private val identity = CompanionPairing.Identity("byd-test", "ab".repeat(32), 8443, "cd".repeat(32), "ef".repeat(32))

    @Test
    fun `a burst of bad companion logins and codes locks nobody out`() {
        val real = pairing.redeem(pairing.mint(identity).code, "Owner's phone")!!
        repeat(40) {
            assertEquals("companion_refused",
                post(AuthApiHandler.COMPANION_LOGIN_PATH, JSONObject().put("companionId", "0".repeat(32)).put("token", "x")).getString("error"))
            assertEquals("pairing_code_refused",
                post(AuthApiHandler.PAIR_PATH, JSONObject().put("code", "guess-$it").put("name", "x")).getString("error"))
        }
        val login = post(AuthApiHandler.COMPANION_LOGIN_PATH, JSONObject().put("companionId", real.companionId).put("token", real.token))
        assertTrue("the owner's companion still logs in: $login", login.optBoolean("success"))
        val paired = post(AuthApiHandler.PAIR_PATH, JSONObject().put("code", pairing.mint(identity).code).put("name", "Tablet"))
        assertTrue("and a fresh code still pairs: $paired", paired.optBoolean("success"))
    }

    @Test
    fun `a global lockout from bad access codes does not reach companions`() {
        val real = pairing.redeem(pairing.mint(identity).code, "Owner's phone")!!
        repeat(40) { post("/auth/token", JSONObject().put("token", "wrong-$it")) }
        val login = post(AuthApiHandler.COMPANION_LOGIN_PATH, JSONObject().put("companionId", real.companionId).put("token", real.token))
        assertTrue("a companion login is not the access-code login: $login", login.optBoolean("success"))
    }
}
