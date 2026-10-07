package net.bladewatch.app.server.connect.impl

import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.file.Files
import java.security.SecureRandom
import java.util.concurrent.atomic.AtomicLong
import net.bladewatch.app.auth.SettingsLock
import net.bladewatch.app.config.SecretConfigStore
import net.bladewatch.app.server.connect.ConnectDispatcher
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * BladeWatch-hr6r: the three Settings-lock RPCs (GetSettingsLock, SetSettingsLock,
 * VerifySettingsPin) as served over Connect -- the JSON shape the in-car UI and the companion
 * actually see, on top of [net.bladewatch.app.auth.SettingsLockTest]'s coverage of the lock logic
 * itself.
 */
class SettingsLockHandlersTest {

    private val clock = AtomicLong(1_700_000_000_000)
    private lateinit var store: SecretConfigStore
    private val dispatcher = ConnectDispatcher()

    @Before
    fun setUp() {
        store = SecretConfigStore(File(Files.createTempDirectory("settings-lock-handlers").toFile(), "secrets.json"))
        SettingsLock.sharedForTest = SettingsLock(store, clock::get, SecureRandom())
        SettingsServiceImpl().register(dispatcher)
    }

    @After
    fun tearDown() {
        SettingsLock.sharedForTest = null
    }

    private fun call(method: String, body: String = "{}"): JSONObject {
        val out = ByteArrayOutputStream()
        dispatcher.dispatch(
            "POST", "/bladewatch.v1.SettingsService/$method", body,
            "application/json", "1", "test", out,
        )
        val http = out.toString("UTF-8")
        assertTrue(http, http.startsWith("HTTP/1.1 200"))
        return JSONObject(http.substringAfter("\r\n\r\n"))
    }

    @Test
    fun `GetSettingsLock reports disabled with no retry when no pin is set`() {
        val r = call("GetSettingsLock")
        assertFalse(r.getBoolean("enabled"))
        assertEquals(0L, r.getLong("retryAfterMs"))
    }

    @Test
    fun `SetSettingsLock with enabled true and a valid pin turns the lock on`() {
        val r = call("SetSettingsLock", """{"enabled":true,"pin":"123456"}""")
        assertTrue(r.getBoolean("success"))
        assertEquals("", r.getString("error"))
        assertTrue(call("GetSettingsLock").getBoolean("enabled"))
    }

    @Test
    fun `SetSettingsLock rejects a malformed pin without throwing`() {
        val r = call("SetSettingsLock", """{"enabled":true,"pin":"12"}""")
        assertFalse(r.getBoolean("success"))
        assertTrue(r.getString("error").isNotEmpty())
        assertFalse(call("GetSettingsLock").getBoolean("enabled"))
    }

    @Test
    fun `SetSettingsLock with enabled false clears an existing pin, no current pin required`() {
        call("SetSettingsLock", """{"enabled":true,"pin":"123456"}""")
        val r = call("SetSettingsLock", """{"enabled":false}""")
        assertTrue(r.getBoolean("success"))
        assertFalse(call("GetSettingsLock").getBoolean("enabled"))
    }

    @Test
    fun `VerifySettingsPin reports ok for the correct pin`() {
        call("SetSettingsLock", """{"enabled":true,"pin":"123456"}""")
        val r = call("VerifySettingsPin", """{"pin":"123456"}""")
        assertTrue(r.getBoolean("ok"))
        assertEquals(0L, r.getLong("retryAfterMs"))
    }

    @Test
    fun `VerifySettingsPin reports attempts left for a wrong pin`() {
        call("SetSettingsLock", """{"enabled":true,"pin":"123456"}""")
        val r = call("VerifySettingsPin", """{"pin":"000000"}""")
        assertFalse(r.getBoolean("ok"))
        assertEquals((SettingsLock.MAX_ATTEMPTS - 1).toLong(), r.getLong("attemptsLeft"))
    }

    @Test
    fun `VerifySettingsPin reports a retry-after once locked out`() {
        call("SetSettingsLock", """{"enabled":true,"pin":"123456"}""")
        repeat(SettingsLock.MAX_ATTEMPTS - 1) { call("VerifySettingsPin", """{"pin":"000000"}""") }
        val locked = call("VerifySettingsPin", """{"pin":"000000"}""")
        assertFalse(locked.getBoolean("ok"))
        assertEquals(SettingsLock.BASE_LOCKOUT_MS, locked.getLong("retryAfterMs"))
    }
}
