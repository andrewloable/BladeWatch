package net.bladewatch.app.util

import android.content.Context
import android.widget.Toast
import org.json.JSONObject

/**
 * Kotlin extension functions for common operations.
 */

/**
 * Show a toast message.
 */
fun Context.toast(message: String, duration: Int = Toast.LENGTH_SHORT) {
    Toast.makeText(this, message, duration).show()
}

/**
 * Safe string to int conversion.
 */
fun String.toIntOrDefault(default: Int): Int {
    return this.toIntOrNull() ?: default
}

/**
 * Safe string to long conversion.
 */
fun String.toLongOrDefault(default: Long): Long {
    return this.toLongOrNull() ?: default
}


/**
 * `optString(name, null)` without passing null where the Android SDK declares the fallback
 * non-null. Same result as Android's own: the value's string form, or null when [name] is
 * absent. An explicit JSON null reads as "null", exactly as `optString(name, null)` did.
 */
fun JSONObject.optStringOrNull(name: String): String? = opt(name)?.toString()
