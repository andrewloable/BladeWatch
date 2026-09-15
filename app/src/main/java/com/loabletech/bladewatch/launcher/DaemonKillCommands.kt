package net.bladewatch.app.launcher

/**
 * Shell fragments for killing and probing daemons that cannot kill — or mis-answer about —
 * the ADB shell issuing them.
 *
 * ## The trap this exists to close (BladeWatch-6jj1)
 *
 * toybox `pkill -f` / `pgrep -f` match the pattern as a literal SUBSTRING of every
 * `/proc/<pid>/cmdline`. Every command here arrives as `adb shell <script>`, so the issuing
 * shell's cmdline IS the script, pattern included — it matches itself. Measured on the head
 * unit on 2026-09-15 with a marker matching no process at all:
 *
 * ```
 * $ adb shell "echo start; pkill -9 -f 'bwprobe_marker_xyz'; echo SHOULD PRINT"
 * start
 * (exit 137 — SIGKILL; the second echo never ran)
 * ```
 *
 * So a `pkill -f` ENDS THE SCRIPT at its first clause — every kill, every `rm` and the
 * `echo done` a callback waits for become dead code — and a `pgrep -f` answers "running"
 * unconditionally, which silently wedges anything that skips work when a daemon is already
 * up.
 *
 * ## What works instead, and why
 *
 * `killall` and `pidof` match `comm` OR `basename(argv[0])`. The issuing shell's are both
 * "sh", so they cannot match themselves. Measured on the same device:
 *
 * ```
 * pidof sentry_daemon -> 24945       killall -0 sentry_daemon    -> exit 0
 * pgrep sentry_daemon -> (nothing)   killall -0 no_such_process  -> exit 1
 * pidof main          -> 24801 24945 4571
 * ```
 *
 * Note `pgrep` WITHOUT `-f` consults `comm` only, and every app_process daemon here is
 * launched with `--nice-name`, so its comm is "main" while argv[0] carries the real name.
 * That also corrects CLAUDE.md's old advice to truncate `acc_sentry_daemon` to 15
 * characters: the cap applies to comm, and the truncated spelling matches nothing at all.
 *
 * ## The one case that still needs a cmdline match
 *
 * The watchdog SCRIPTS run as `sh /data/local/tmp/start_cam_daemon.sh`, so argv[0] and comm
 * are both "sh" — `killall` cannot single them out without killing every shell on the head
 * unit, this one included. [killMatchingCmdline] handles those, and is safe precisely
 * because `grep -E` takes a REGEX: `[s]tart_cam_daemon` matches the literal text
 * `start_cam_daemon` but NOT the literal `[s]tart_cam_daemon` in the issuing shell's own
 * cmdline. That is why the bracket trick works for grep and fails for `pkill -f`.
 *
 * **If you add a clause mentioning one of these names in plain text — an `rm` naming the
 * script, say — you re-arm the self-match and the loop kills its own shell.** Keep such
 * paths globbed (`start_cam_*.sh`), as the callers here do.
 */
object DaemonKillCommands {

    /**
     * Turn a literal into a regex that matches it without containing it.
     *
     * Brackets the first character: `start_cam_daemon` -> `[s]tart_cam_daemon`.
     */
    @JvmStatic
    fun bracket(literal: String): String {
        if (literal.isEmpty()) return literal
        return "[${literal.first()}]${literal.substring(1)}"
    }

    /**
     * Kill processes by name. Names must be spelled IN FULL — see the class docs.
     *
     * Safe against self-kill: matches comm/argv[0], which are "sh" for the issuing shell.
     */
    @JvmStatic
    fun killByName(vararg names: String): String =
        "killall -9 ${names.joinToString(" ")} 2>/dev/null"

    /**
     * Kill processes whose CMDLINE contains one of [literals] — for the watchdog scripts,
     * which all run as "sh" and so cannot be told apart by name.
     *
     * Each literal is bracketed, so the regex cannot match this command's own shell.
     */
    @JvmStatic
    fun killMatchingCmdline(vararg literals: String): String {
        val pattern = literals.joinToString("|") { bracket(it) }
        return "for p in \$(ps -A -o PID,ARGS 2>/dev/null | grep -E '$pattern' | " +
            "awk '{print \$1}'); do kill -9 \$p 2>/dev/null; done"
    }

    /**
     * Probe whether a named process is alive, answering `yes` or `no`.
     *
     * `pidof`, never `pgrep`: pgrep consults comm only, which is "main" for every
     * app_process daemon here, so it would report every one of them as dead.
     */
    @JvmStatic
    fun isRunningByName(name: String): String =
        "pidof $name > /dev/null && echo yes || echo no"
}
