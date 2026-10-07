package net.bladewatch.app.auth

import java.io.File
import java.nio.file.Files
import java.security.SecureRandom
import java.util.concurrent.atomic.AtomicLong
import net.bladewatch.app.config.SecretConfigStore
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * BladeWatch-hr6r: the Settings PIN lock -- a salted PBKDF2 hash in the secret store, plus an
 * in-memory lockout that doubles on each further wrong PIN and never un-counts an attempt made
 * while already locked out.
 */
class SettingsLockTest {

    private val clock = AtomicLong(1_700_000_000_000)
    private lateinit var storeFile: File
    private lateinit var store: SecretConfigStore
    private lateinit var lock: SettingsLock

    @Before
    fun setUp() {
        storeFile = File(Files.createTempDirectory("settings-lock").toFile(), "secrets.json")
        store = SecretConfigStore(storeFile)
        lock = SettingsLock(store, clock::get, SecureRandom())
    }

    private fun advance(ms: Long) = clock.addAndGet(ms)

    @Test
    fun `disabled by default, verify is ok with no pin set`() {
        assertFalse(lock.isEnabled())
        val r = lock.verify("000000")
        assertTrue(r.ok)
        assertEquals(0L, r.retryAfterMs)
    }

    @Test
    fun `setPin enables the lock and the correct pin verifies`() {
        assertTrue(lock.setPin("123456"))
        assertTrue(lock.isEnabled())
        val r = lock.verify("123456")
        assertTrue(r.ok)
        assertEquals(0L, r.retryAfterMs)
    }

    @Test
    fun `a wrong pin is refused and counts against the attempt budget`() {
        lock.setPin("123456")
        val r = lock.verify("000000")
        assertFalse(r.ok)
        assertEquals(0L, r.retryAfterMs)
        assertEquals(SettingsLock.MAX_ATTEMPTS - 1, r.attemptsLeft)
    }

    @Test
    fun `setPin rejects anything that is not exactly 6 ASCII digits`() {
        for (bad in listOf("12345", "1234567", "12345a", "123 456", "", "١٢٣٤٥٦")) {
            assertFalse("expected rejection of \"$bad\"", lock.setPin(bad))
        }
        assertFalse(lock.isEnabled())
    }

    @Test
    fun `verify treats malformed input as a wrong attempt, not a free pass`() {
        lock.setPin("123456")
        val r = lock.verify("12345") // 5 digits -- malformed, must still count
        assertFalse(r.ok)
        assertEquals(SettingsLock.MAX_ATTEMPTS - 1, r.attemptsLeft)
    }

    @Test
    fun `two setPin calls use different salts`() {
        lock.setPin("123456")
        val salt1 = store.getString(SettingsLock.SECTION, "salt")
        lock.setPin("654321")
        val salt2 = store.getString(SettingsLock.SECTION, "salt")
        assertNotEquals(salt1, salt2)
        // The old PIN no longer verifies; the new one does.
        assertFalse(lock.verify("123456").ok)
        assertTrue(lock.verify("654321").ok)
    }

    @Test
    fun `the fifth consecutive wrong pin locks out for the base duration`() {
        lock.setPin("123456")
        for (expectedLeft in (SettingsLock.MAX_ATTEMPTS - 1) downTo 1) {
            val r = lock.verify("000000")
            assertFalse(r.ok)
            assertEquals(0L, r.retryAfterMs)
            assertEquals(expectedLeft, r.attemptsLeft)
        }
        val fifth = lock.verify("000000")
        assertFalse(fifth.ok)
        assertEquals(SettingsLock.BASE_LOCKOUT_MS, fifth.retryAfterMs)
        assertEquals(0, fifth.attemptsLeft)
    }

    private fun lockOutOnce() {
        lock.setPin("123456")
        repeat(SettingsLock.MAX_ATTEMPTS) { lock.verify("000000") }
    }

    @Test
    fun `an attempt made while locked out is refused without being checked or counted`() {
        lockOutOnce()

        // Even the CORRECT pin is refused while locked out -- it must not be checked at all. The
        // reported wait only ever counts DOWN from the original lockout; it is never reset or
        // extended by an attempt made during it.
        advance(SettingsLock.BASE_LOCKOUT_MS / 3)
        val first = lock.verify("123456")
        assertFalse(first.ok)
        assertEquals(SettingsLock.BASE_LOCKOUT_MS - SettingsLock.BASE_LOCKOUT_MS / 3, first.retryAfterMs)

        advance(SettingsLock.BASE_LOCKOUT_MS / 3)
        val second = lock.verify("000000") // a second, different, still-wrong attempt during lockout
        assertFalse(second.ok)
        assertTrue("expected a smaller remaining wait, got ${second.retryAfterMs}", second.retryAfterMs < first.retryAfterMs)

        // Advance past the lockout and fail exactly once: if either attempt made during the
        // lockout had been silently counted as a strike, this would double more than once.
        advance(SettingsLock.BASE_LOCKOUT_MS)
        val afterExpiry = lock.verify("000000")
        assertFalse(afterExpiry.ok)
        assertEquals(SettingsLock.BASE_LOCKOUT_MS * 2, afterExpiry.retryAfterMs)
    }

    @Test
    fun `each further wrong pin before a success doubles the lockout, capped at the maximum`() {
        lockOutOnce()
        var expected = SettingsLock.BASE_LOCKOUT_MS
        repeat(8) {
            advance(expected) // let the current lockout expire
            val r = lock.verify("000000")
            assertFalse(r.ok)
            expected = (expected * 2).coerceAtMost(SettingsLock.MAX_LOCKOUT_MS)
            assertEquals(expected, r.retryAfterMs)
        }
        assertEquals(SettingsLock.MAX_LOCKOUT_MS, expected)
    }

    @Test
    fun `a correct pin resets the attempt counter and the lockout`() {
        lock.setPin("123456")
        repeat(3) { lock.verify("000000") } // 3 strikes, well under the lockout threshold
        assertTrue(lock.verify("123456").ok)

        // A fresh cycle: the next wrong attempt reports the full budget minus one, not minus four.
        val r = lock.verify("000000")
        assertEquals(SettingsLock.MAX_ATTEMPTS - 1, r.attemptsLeft)
    }

    @Test
    fun `setPin while locked out clears the lockout`() {
        lockOutOnce()
        assertTrue(lock.retryAfterMs() > 0)
        lock.setPin("999999")
        assertEquals(0L, lock.retryAfterMs())
        val r = lock.verify("000000")
        assertFalse(r.ok)
        assertEquals(SettingsLock.MAX_ATTEMPTS - 1, r.attemptsLeft) // fresh budget, not still locked
    }

    @Test
    fun `clear disables the lock and resets the lockout`() {
        lockOutOnce()
        assertTrue(lock.clear())
        assertFalse(lock.isEnabled())
        assertEquals(0L, lock.retryAfterMs())
        assertTrue(lock.verify("anything").ok)
    }

    @Test
    fun `retryAfterMs counts down and reaches zero once the lockout expires`() {
        lockOutOnce()
        val remaining = lock.retryAfterMs()
        assertTrue(remaining > 0)
        advance(remaining / 2)
        assertTrue(lock.retryAfterMs() in 1..remaining)
        advance(remaining)
        assertEquals(0L, lock.retryAfterMs())
    }

    @Test
    fun `the stored section never contains the pin itself`() {
        lock.setPin("123456")
        val section = store.loadSection(SettingsLock.SECTION)
        val raw = section.toString()
        assertFalse(raw.contains("123456"))
        assertTrue(section.has("salt"))
        assertTrue(section.has("hash"))
        assertTrue(section.has("iterations"))
    }
}
