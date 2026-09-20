package net.bladewatch.app.daemon

import java.util.Locale

/**
 * Decides whether the output of an `am` / shell invocation represents a failure.
 *
 * BladeWatch-boat. Call sites used to test `result.contains("Error")`, which misses the shape the
 * platform actually produces when it refuses a command:
 *
 * ```
 * Broadcasting: Intent { act=android.intent.action.BOOT_COMPLETED ... }
 * Security exception: Permission Denial: not allowed to send broadcast ... from uid=2000
 * java.lang.SecurityException: Permission Denial: ...
 * ```
 *
 * No "Error" substring, not empty — so a hard refusal was logged as though it might have worked.
 * Pure, so the real device output can be asserted on directly in a JVM test rather than a
 * synthesised approximation of it.
 */
object ShellResultClassifier {

    /** Markers that mean the command did not do what was asked, pre-lower-cased for matching. */
    private val FAILURE_MARKERS_LOWER = arrayOf(
        "error",
        "exception", // covers "Security exception:" and any java.lang.* trace
        "permission denial",
        "failure",
        "denied"
    )

    /**
     * @param result raw combined stdout/stderr, or null
     * @return true when the output indicates failure. Null or blank counts as failure: a command
     *   that produced nothing at all did not demonstrably succeed.
     */
    @JvmStatic
    fun isFailure(result: String?): Boolean {
        if (result == null || result.trim().isEmpty()) return true
        // Case-insensitive: the platform writes both "Security exception" and
        // "java.lang.SecurityException" for the same refusal. Lower-cased once, not once per
        // marker -- this runs on every location-service restart.
        val lower = result.lowercase(Locale.US)
        for (marker in FAILURE_MARKERS_LOWER) {
            if (lower.contains(marker)) return true
        }
        return false
    }
}
