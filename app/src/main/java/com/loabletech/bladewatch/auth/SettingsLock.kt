package net.bladewatch.app.auth

import net.bladewatch.app.config.SecretConfigStore
import org.json.JSONObject
import java.security.MessageDigest
import java.security.SecureRandom
import java.util.Base64
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.PBEKeySpec

/**
 * The Settings PIN lock (BladeWatch-hr6r): one 6-digit PIN, held by the car, that gates Settings
 * in both the in-car UI and every paired companion -- checked here rather than each app keeping
 * its own. Stored as a salted PBKDF2 hash in the secret store's [SECTION] (daemon-only, see
 * `TcpCommandServer.DAEMON_ONLY_SECRET_SECTIONS`); the PIN itself is never stored or logged.
 *
 * Threat model: this is a UI gate against someone with physical access to the head unit or an
 * unlocked companion, not an API ACL -- any JWT holder can still call SetSettingsLock directly,
 * exactly as every other setter on this API can be called directly today. [setPin] therefore does
 * not demand the current PIN: the forgotten-PIN recovery path is a companion unlocked by
 * biometrics calling SetSettingsLock itself.
 *
 * Lockout is in-memory, guarded by [lockLock]: 5 consecutive wrong PINs lock entry out for
 * [BASE_LOCKOUT_MS]; each further wrong PIN before a success doubles the wait, capped at
 * [MAX_LOCKOUT_MS]. A PIN entered while locked out is refused outright -- neither checked nor
 * counted as an attempt.
 */
class SettingsLock(
    private val store: SecretConfigStore,
    private val now: () -> Long = System::currentTimeMillis,
    private val random: SecureRandom = SecureRandom(),
) {
    data class Result(val ok: Boolean, val retryAfterMs: Long, val attemptsLeft: Int)

    // ponytail: in memory -- a daemon restart resets the counter; persist it if restarts become
    // attacker-triggerable.
    private val lockLock = Any()
    private var consecutiveFailures = 0
    private var lockedUntil = 0L
    private var currentLockoutMs = 0L

    fun isEnabled(): Boolean = store.getString(SECTION, KEY_HASH) != null

    /** Rejects anything not exactly 6 ASCII digits. One write, so a crash can't leave a salt without its hash. */
    fun setPin(pin: String): Boolean {
        if (!PIN_PATTERN.matches(pin)) return false
        val salt = ByteArray(SALT_BYTES).also(random::nextBytes)
        val hash = pbkdf2(pin, salt, ITERATIONS)
        val payload = JSONObject()
            .put(KEY_SALT, Base64.getEncoder().encodeToString(salt))
            .put(KEY_HASH, Base64.getEncoder().encodeToString(hash))
            .put(KEY_ITERATIONS, ITERATIONS)
        val wrote = store.replaceSection(SECTION, payload)
        if (wrote) resetLockout()
        return wrote
    }

    /** Removes the PIN and disables the lock. */
    fun clear(): Boolean {
        val wrote = store.replaceSection(SECTION, JSONObject())
        if (wrote) resetLockout()
        return wrote
    }

    /** > 0 while locked out: ms until the next [verify] is actually checked. */
    fun retryAfterMs(): Long = synchronized(lockLock) {
        (lockedUntil - now()).coerceAtLeast(0L)
    }

    fun verify(pin: String): Result {
        if (!isEnabled()) return Result(true, 0L, MAX_ATTEMPTS)

        synchronized(lockLock) {
            val remaining = lockedUntil - now()
            if (remaining > 0) return Result(false, remaining, 0)
        }

        val storedSalt = store.getString(SECTION, KEY_SALT)
        val storedHash = store.getString(SECTION, KEY_HASH)
        val iterations = store.getLong(SECTION, KEY_ITERATIONS, ITERATIONS.toLong()).toInt()
        val matches = PIN_PATTERN.matches(pin) && storedSalt != null && storedHash != null &&
            MessageDigest.isEqual(
                pbkdf2(pin, Base64.getDecoder().decode(storedSalt), iterations),
                Base64.getDecoder().decode(storedHash),
            )

        return synchronized(lockLock) {
            if (matches) {
                resetLockoutLocked()
                Result(true, 0L, MAX_ATTEMPTS)
            } else {
                consecutiveFailures++
                if (consecutiveFailures >= MAX_ATTEMPTS) {
                    currentLockoutMs = if (currentLockoutMs == 0L) BASE_LOCKOUT_MS else (currentLockoutMs * 2).coerceAtMost(MAX_LOCKOUT_MS)
                    lockedUntil = now() + currentLockoutMs
                    Result(false, currentLockoutMs, 0)
                } else {
                    Result(false, 0L, MAX_ATTEMPTS - consecutiveFailures)
                }
            }
        }
    }

    private fun resetLockout() = synchronized(lockLock) { resetLockoutLocked() }

    private fun resetLockoutLocked() {
        consecutiveFailures = 0
        lockedUntil = 0L
        currentLockoutMs = 0L
    }

    private fun pbkdf2(pin: String, salt: ByteArray, iterations: Int): ByteArray {
        val spec = PBEKeySpec(pin.toCharArray(), salt, iterations, KEY_BITS)
        return SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256").generateSecret(spec).encoded
    }

    companion object {
        const val SECTION = "settingsLock"
        private const val KEY_SALT = "salt"
        private const val KEY_HASH = "hash"
        private const val KEY_ITERATIONS = "iterations"

        // Spelled [0-9], never \d: Character.isDigit()-style checks (and \d under
        // UNICODE_CHARACTER_CLASS) accept non-ASCII digit scripts like Arabic-Indic.
        private val PIN_PATTERN = Regex("^[0-9]{6}$")

        private const val SALT_BYTES = 16
        private const val ITERATIONS = 100_000
        private const val KEY_BITS = 256

        const val MAX_ATTEMPTS = 5
        const val BASE_LOCKOUT_MS = 60_000L
        const val MAX_LOCKOUT_MS = 3_600_000L

        private val daemonInstance by lazy { SettingsLock(SecretConfigStore()) }

        // ponytail: test seam -- non-null replaces the daemon's instance everywhere it is used.
        @JvmField
        @Volatile
        var sharedForTest: SettingsLock? = null

        /** The daemon's instance: lockout counters are in memory, so there must be exactly one per process. */
        @JvmStatic
        val shared: SettingsLock
            get() = sharedForTest ?: daemonInstance
    }
}
