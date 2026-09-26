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
