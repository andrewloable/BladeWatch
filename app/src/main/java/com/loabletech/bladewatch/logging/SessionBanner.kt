package net.bladewatch.app.logging

/**
 * The line that says which build wrote everything below it.
 *
 * ## Why this exists (BladeWatch-gn2y)
 *
 * A log audit on the head unit found two `[CRASH] UncaughtException` entries for the
 * StatusOverlayService null-launch-intent NPE — a real bug that used to kill the process
 * and take daemon startup with it. They were dated a day earlier and came from a build
 * whose UI no longer exists; the crash is fixed and regression-tested. Nothing in the file
 * said so. The only things distinguishing "broken now" from "broken last Tuesday" were the
 * timestamps and a passing mention of a class that has since been deleted.
 *
 * `debug_app.log` already rotates at 5 MB with 3 generations kept. That was never the
 * missing piece: a low-volume log takes weeks to reach 5 MB, so four days and several
 * builds shared one file with no marker between them. What was missing is a per-run
 * boundary that also records WHICH BUILD produced the lines after it.
 *
 * Kept deliberately small and dependency-free so both sides can use it: the app process
 * writes it to `debug_app.log`, and the shell-launched daemons write it to stdout, which
 * the launcher appends to `cam_daemon.log`.
 */
object SessionBanner {

    /**
     * Greppable marker. Isolating the current run is `grep -n BLADEWATCH-SESSION` to find
     * the boundaries, then reading from the last one — which is exactly the step that would
     * have made the audit above take seconds instead of a careful read of timestamps.
     */
    const val MARKER = "BLADEWATCH-SESSION"

    /**
     * One block, three lines: a rule, the marker line with the metadata, and a closing rule.
     *
     * The rules are there for skimming — a wall of uniform log lines is exactly where a run
     * boundary disappears. The marker is there for grep.
     */
    @JvmStatic
    fun format(
        version: String,
        branch: String,
        buildType: String,
        timestamp: String,
        process: String,
    ): String {
        val rule = "=".repeat(72)
        // Blank metadata must read as unknown rather than leaving a hole that looks like a
        // formatting bug — "version=" tells the reader nothing about whether it was missing.
        fun v(s: String) = s.ifBlank { "unknown" }
        return buildString {
            appendLine(rule)
            appendLine(
                "$MARKER [$timestamp] process=${v(process)} version=${v(version)} " +
                    "branch=${v(branch)} build=${v(buildType)}"
            )
            append(rule)
        }
    }
}
