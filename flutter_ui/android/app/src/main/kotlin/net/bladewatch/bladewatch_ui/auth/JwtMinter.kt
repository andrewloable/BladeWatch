package net.bladewatch.bladewatch_ui.auth

import net.bladewatch.bladewatch_ui.ipc.IpcCommandSender
import org.json.JSONObject
import java.util.Base64
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

/**
 * Mints the JWT every Connect RPC call authenticates with — the Flutter
 * side of `app/src/main/java/com/loabletech/bladewatch/client/ConnectClientProvider.kt`
 * (BladeWatch-ncbb.1's `JwtSource`). Ported from
 * `app/src/main/java/com/loabletech/bladewatch/auth/AuthManager.java`'s
 * `generateJwt()`: `base64url(header) + "." + base64url(payload) + "." +
 * base64url(HMAC-SHA256(header.payload, deviceSecret))`, with claims `sub`
 * (deviceId), `iat`/`exp` (24h lifetime), and `ver` (tokenEpoch — the daemon
 * rejects a JWT whose `ver` doesn't match its current value, so a rotated
 * secret invalidates old tokens).
 *
 * The device secret is fetched fresh via `secret_get_section("auth")` on
 * every mint — **never** `secret_get` for the raw value alone, and never
 * logged (see the Security Notes in CLAUDE.md). There is deliberately no
 * caching layer in this class: the Dart-side `ConnectClient`
 * (BladeWatch-ncbb.1) already caches the minted JWT for 4 minutes keyed to
 * [stateVersion]; caching here too would only make secret rotation take
 * longer to notice, for no benefit.
 */
class JwtMinter(private val ipc: IpcCommandSender) {

    private class AuthSectionUnavailable(message: String) : Exception(message)

    companion object {
        private const val JWT_EXPIRY_SECONDS = 24 * 60 * 60L

        // Mirrors AuthManager.java's CUSTOM_SECRET_MIN_LENGTH.
        const val CUSTOM_SECRET_MIN_LENGTH = 12
    }

    // AtomicInteger, not a @Volatile Int: `version++` is a read-modify-write, so two
    // concurrent invalidate() calls can collapse into one increment. The Dart-side JWT
    // cache keys off this value, so a lost increment means it keeps serving a token
    // signed with a secret that has already been rotated.
    private val version = java.util.concurrent.atomic.AtomicInteger(0)

    /**
     * Bumps the version [stateVersion] reports. Call after the device secret
     * is known to have rotated (e.g. the app just called `auth_invalidate`),
     * mirroring `AuthManager.invalidateCache()` — this is the signal the
     * Dart-side JWT cache uses to drop a stale token immediately instead of
     * waiting out its TTL.
     */
    fun invalidate() {
        version.incrementAndGet()
    }

    fun stateVersion(): Int = version.get()

    /**
     * BladeWatch-yz1e.2 (Dashboard access-code tile): the raw device secret,
     * for **deliberate, user-initiated display** — the same secret
     * `AuthManager.java`'s own native UI already shows (with the same
     * toggle-visibility affordance this method backs). This is not the
     * `secret_get`-on-`ConfigChannel` case the class doc above warns off:
     * that warning is about *casual* reads of this section from generic
     * config code; showing the user their own access code is the section's
     * actual, intended purpose. Never logged.
     */
    fun getAccessCode(): String? = try {
        fetchAuthSection().deviceSecret
    } catch (e: Exception) {
        null
    }

    /**
     * Generates and persists a new random access code, ported from
     * `AuthManager.java`'s `regenerateToken()` (`generateSecret(20)` — same
     * charset, same length). Calls [invalidate] on success so `ConnectClient`
     * mints a fresh JWT next call instead of serving a 4-minute-stale one
     * signed with the old secret. Returns the new code, or null if the
     * daemon rejected the write.
     */
    fun regenerateAccessCode(): String? {
        val candidate = generateSecret(20)
        if (!putDeviceSecret(candidate)) return null
        invalidate()
        return candidate
    }

    /**
     * Sets a user-chosen access code, ported from `AuthManager.java`'s
     * `setCustomSecret()`. Returns false without writing anything if
     * [password] is shorter than [CUSTOM_SECRET_MIN_LENGTH] (same bound as
     * the native dialog) or if the daemon rejected the write.
     */
    fun setCustomAccessCode(password: String): Boolean {
        if (password.length < CUSTOM_SECRET_MIN_LENGTH) return false
        if (!putDeviceSecret(password)) return false
        invalidate()
        return true
    }

    /**
     * Writes the new device secret, then tells the daemon to drop its cached auth
     * state.
     *
     * The `auth_invalidate` call is NOT optional. `secret_put` only rewrites the
     * secrets file; the daemon's `AuthManager` keeps the previous secret in its
     * `cachedState` field and keeps validating against it. Without this second
     * command the user changes their access code, the Flutter side immediately
     * starts signing JWTs with the new secret, the daemon verifies them against
     * the old one, and every RPC is rejected until the daemon happens to reload —
     * i.e. changing your access code locks you out of your own car. `auth_invalidate`
     * exists for exactly this ("called when app regenerates token", see
     * `app/src/main/java/com/loabletech/bladewatch/server/TcpCommandServer.java`).
     *
     * A failed invalidate is reported as failure even though the secret did land:
     * the caller must not report success and then mint tokens the daemon will
     * reject. Retrying the whole operation is safe — `secret_put` is idempotent.
     */
    private fun putDeviceSecret(secret: String): Boolean {
        val response = ipc.sendCommand(
            JSONObject().put("cmd", "secret_put").put("section", "auth").put("key", "deviceSecret").put("value", secret),
        )
        if (response.optString("status") != "ok") return false

        val invalidated = ipc.sendCommand(JSONObject().put("cmd", "auth_invalidate"))
        return invalidated.optString("status") == "ok"
    }

    private fun generateSecret(length: Int): String {
        val chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        val random = java.security.SecureRandom()
        return buildString {
            repeat(length) { append(chars[random.nextInt(chars.length)]) }
        }
    }

    /**
     * Mints a fresh JWT, or null if the daemon's auth section can't be
     * fetched right now — mirrors `ConnectClientProvider.kt`'s `catch (e:
     * Exception) { null }`: callers proceed without a token rather than
     * throwing, since a missing Authorization header just gets a 401 from
     * the daemon like any other unauthenticated request.
     */
    fun mintJwt(): String? {
        return try {
            val section = fetchAuthSection()
            buildJwt(section.deviceId, section.deviceSecret, section.tokenEpoch)
        } catch (e: Exception) {
            null
        }
    }

    private data class AuthSection(val deviceId: String, val deviceSecret: String, val tokenEpoch: Long)

    private fun fetchAuthSection(): AuthSection {
        val response = ipc.sendCommand(JSONObject().put("cmd", "secret_get_section").put("section", "auth"))
        val section = response.optJSONObject("section")
            ?: throw AuthSectionUnavailable("no auth section in secret_get_section response")
        val deviceId = section.optString("deviceId", "")
        val deviceSecret = section.optString("deviceSecret", "")
        if (deviceId.isEmpty() || deviceSecret.isEmpty()) {
            throw AuthSectionUnavailable("auth section missing deviceId/deviceSecret")
        }
        return AuthSection(deviceId, deviceSecret, section.optLong("tokenEpoch", 0))
    }

    private fun buildJwt(deviceId: String, deviceSecret: String, tokenEpoch: Long): String {
        val now = System.currentTimeMillis() / 1000
        val header = JSONObject().put("alg", "HS256").put("typ", "JWT").toString()
        val payload = JSONObject()
            .put("sub", deviceId)
            .put("iat", now)
            .put("exp", now + JWT_EXPIRY_SECONDS)
            .put("ver", tokenEpoch)
            .toString()
        val content = base64Url(header.toByteArray(Charsets.UTF_8)) + "." +
            base64Url(payload.toByteArray(Charsets.UTF_8))
        return "$content.${hmacSha256(content, deviceSecret)}"
    }

    private fun hmacSha256(data: String, secret: String): String {
        val mac = Mac.getInstance("HmacSHA256")
        mac.init(SecretKeySpec(secret.toByteArray(Charsets.UTF_8), "HmacSHA256"))
        return base64Url(mac.doFinal(data.toByteArray(Charsets.UTF_8)))
    }

    private fun base64Url(bytes: ByteArray): String = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes)
}
