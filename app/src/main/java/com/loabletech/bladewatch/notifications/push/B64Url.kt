package net.bladewatch.app.notifications.push

import android.util.Base64

/**
 * Base64url-without-padding helpers. Web Push, JWT and RFC 8291 all require this exact
 * encoding (RFC 4648 §5).
 *
 * The flags are load-bearing and must not be swapped for Kotlin's stdlib base64: a different
 * encoding produces subscriptions the browser rejects, which presents as "push stopped working"
 * rather than as an encoding fault.
 */
internal object B64Url {

    private const val FLAGS = Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP

    @JvmStatic
    fun enc(bytes: ByteArray): String = Base64.encodeToString(bytes, FLAGS)

    @JvmStatic
    fun dec(s: String): ByteArray = Base64.decode(s, FLAGS)
}
