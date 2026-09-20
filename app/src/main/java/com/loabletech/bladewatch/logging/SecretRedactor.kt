package net.bladewatch.app.logging

import android.util.Log
import java.nio.charset.StandardCharsets
import java.security.MessageDigest
import java.util.regex.Matcher
import java.util.regex.Pattern

/**
 * Redacts secrets before they are logged.
 *
 * A redacted value keeps its first and last four characters plus a short SHA-256 prefix, so two
 * log lines carrying the same token can still be correlated without the token itself appearing.
 * Anything shorter than eight characters is replaced outright — there is nothing left to show
 * once you take eight characters off a seven-character string.
 */
object SecretRedactor {

    private const val TAG = "SecretRedactor"

    private val BEARER_PATTERN: Pattern =
        Pattern.compile("(?i)\\bBearer\\s+([A-Za-z0-9._\\-+/=]+)")
    private val TOKEN_LABEL_PATTERN: Pattern =
        Pattern.compile("(?i)\\b(token|reserved token|enable token|bot token)\\s*[:=]\\s*([^\\s,;]+)")

    @JvmStatic
    fun redact(value: String?): String? {
        if (value.isNullOrEmpty()) return value
        if (value.length < 8) return "[REDACTED]"
        return value.substring(0, 4) + "…" + value.substring(value.length - 4) +
            "#" + sha256Prefix(value)
    }

    @JvmStatic
    fun redactToken(label: String, value: String?): String {
        if (value.isNullOrEmpty()) return "$label: [REDACTED]"
        return label + ": " + redact(value)
    }

    @JvmStatic
    fun redactMessage(message: String?): String? {
        if (message.isNullOrEmpty()) return message
        var redacted = redactPattern(message, BEARER_PATTERN, 1)
        redacted = redactPattern(redacted, TOKEN_LABEL_PATTERN, 2)
        return redacted
    }

    private fun redactPattern(input: String, pattern: Pattern, groupToRedact: Int): String {
        val matcher: Matcher = pattern.matcher(input)
        val out = StringBuffer()
        while (matcher.find()) {
            val token = matcher.group(groupToRedact)
            matcher.appendReplacement(
                out,
                Matcher.quoteReplacement(matcher.group(0).replace(token, redact(token)!!))
            )
        }
        matcher.appendTail(out)
        return out.toString()
    }

    private fun sha256Prefix(value: String): String {
        return try {
            val bytes = MessageDigest.getInstance("SHA-256")
                .digest(value.toByteArray(StandardCharsets.UTF_8))
            val sb = StringBuilder()
            var i = 0
            while (i < 4 && i < bytes.size) {
                sb.append(String.format("%02x", bytes[i]))
                i++
            }
            sb.toString()
        } catch (e: Exception) {
            Log.w(TAG, "sha256Prefix failed: " + e.message)
            "0000"
        }
    }
}
