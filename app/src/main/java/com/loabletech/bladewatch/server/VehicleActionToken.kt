package net.bladewatch.app.server

import java.nio.charset.StandardCharsets
import java.security.MessageDigest
import java.util.Base64
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec

/**
 * Short-lived action tokens for the actuating VehicleService RPCs (uy93.5).
 *
 * A valid bearer JWT alone over LAN cannot actuate the car: the caller must also present a fresh
 * action token bound to the device secret.
 *
 * The loopback path is exempt: tokens are only required for non-loopback (LAN/tunnel) callers in
 * HttpServer.handleClient().
 *
 * Token format: `<unix_seconds>.<base64url_hmac_sha256>`, valid for [WINDOW_SECONDS] from
 * issuance.
 *
 * Tokens have single-second granularity (a fresh call in the same wall-clock second produces the
 * same token). That is intentional: a client can ask for a token and immediately send the
 * command — no race.
 */
object VehicleActionToken {

    const val WINDOW_SECONDS = 30
    private const val HMAC_ALG = "HmacSHA256"

    /**
     * Test seam — null means the real clock, non-null an injected epoch-seconds value.
     *
     * `@JvmField` because VehicleActionTokenTest is Java and assigns it directly; a Kotlin
     * property would only be reachable through a mangled accessor.
     */
    @JvmField
    @Volatile
    var clockOverrideForTest: Long? = null

    @JvmStatic
    fun issue(deviceSecret: String): String {
        val tsPart = nowSeconds().toString()
        return tsPart + "." + sign(tsPart, deviceSecret)
    }

    @JvmStatic
    fun validate(token: String?, deviceSecret: String?): Boolean {
        if (token.isNullOrEmpty() || deviceSecret.isNullOrEmpty()) return false
        val dot = token.indexOf('.')
        if (dot < 1 || dot == token.length - 1) return false
        val tsPart = token.substring(0, dot)
        val sigPart = token.substring(dot + 1)
        val ts = try {
            tsPart.toLong()
        } catch (e: NumberFormatException) {
            return false
        }
        val age = nowSeconds() - ts
        if (age < 0 || age > WINDOW_SECONDS) return false
        val expected = sign(tsPart, deviceSecret)
        return MessageDigest.isEqual(
            expected.toByteArray(StandardCharsets.UTF_8),
            sigPart.toByteArray(StandardCharsets.UTF_8)
        )
    }

    private fun nowSeconds(): Long = clockOverrideForTest ?: (System.currentTimeMillis() / 1000L)

    private fun sign(data: String, secret: String): String = try {
        val mac = Mac.getInstance(HMAC_ALG)
        mac.init(SecretKeySpec(secret.toByteArray(StandardCharsets.UTF_8), HMAC_ALG))
        val bytes = mac.doFinal(data.toByteArray(StandardCharsets.UTF_8))
        Base64.getEncoder().withoutPadding().encodeToString(bytes)
    } catch (e: Exception) {
        ""
    }
}
