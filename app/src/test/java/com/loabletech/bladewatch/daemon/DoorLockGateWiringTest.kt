package net.bladewatch.app.daemon

import java.io.File
import java.nio.charset.StandardCharsets
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-l55j: source-scan guard for how CameraDaemon wires the ACC-OFF door-lock gate.
 *
 * [DoorLockArmGateTest] covers the arm/disarm decisions but not what CameraDaemon does with them.
 * Both regressions this guards are silent. A timeout that reads the stale surveillanceEnabled flag
 * skips arming with no log line. An ACC-ON branch that does not clear that flag leaves the next
 * ACC OFF reporting enabled while unarmed. CameraDaemon cannot be built in the JVM suite, so this
 * reads the source as DATA. app/build.gradle.kts declares src/main/java as an explicit test input,
 * so this re-runs when CameraDaemon.kt changes.
 */
class DoorLockGateWiringTest {

    private fun cameraDaemonSource(): String {
        var f = File("src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.kt")
        if (!f.isFile) f = File("app/src/main/java/com/loabletech/bladewatch/daemon/CameraDaemon.kt")
        assertTrue("could not locate CameraDaemon.kt from ${File(".").absolutePath}", f.isFile)
        return String(f.readBytes(), StandardCharsets.UTF_8).replace("\r\n", "\n")
    }

    /**
     * Text of one member function: from its declaration line up to the next member declaration.
     * The next member's KDoc and annotations count as its preamble, so they end this function too.
     */
    private fun memberText(src: String, declaration: String): String {
        val lines = src.split("\n")
        val start = lines.indexOfFirst { it.trim().startsWith(declaration) }
        assertTrue(
            "BladeWatch-l55j: could not find '$declaration' in CameraDaemon.kt. If it was renamed, " +
                "update DoorLockGateWiringTest.",
            start >= 0)
        val nextMember = Regex("""^    (/\*\*|@\w|(private |internal |public |protected |override )*(suspend )?fun\s)""")
        val end = (start + 1 until lines.size).firstOrNull { nextMember.containsMatchIn(lines[it]) }
            ?: lines.size
        return lines.subList(start, end).joinToString("\n")
    }

    /**
     * [body] without comments: whole-line comments (// lines, and KDoc or block-comment lines starting
     * with * or slash-star) and any trailing // after code. A "//" inside a string literal is kept.
     */
    private fun codeOnly(body: String): String = body.lines()
        .filterNot { val t = it.trimStart(); t.startsWith("//") || t.startsWith("*") || t.startsWith("/*") }
        .joinToString("\n") { stripTrailingLineComment(it) }

    private fun stripTrailingLineComment(line: String): String {
        var inString = false
        var i = 0
        while (i < line.length) {
            val c = line[i]
            when {
                inString && c == '\\' -> i++
                c == '"' -> inString = !inString
                !inString && c == '/' && line.startsWith("//", i) -> return line.substring(0, i)
            }
            i++
        }
        return line
    }

    /** The 60 s timeout decides from the gate alone. A leftover flag made it skip arming silently. */
    @Test
    fun `the lock timeout never reads surveillanceEnabled`() {
        val code = codeOnly(memberText(cameraDaemonSource(), "private fun applyLockTimeout"))
        assertTrue(
            "BladeWatch-l55j: the code extracted for applyLockTimeout does not call doorLockGate.onTimeout(). " +
                "The extraction is broken, so this guard cannot judge the function.",
            code.contains("doorLockGate.onTimeout("))
        assertFalse(
            "BladeWatch-l55j regressed: applyLockTimeout reads surveillanceEnabled. The 60 s timeout " +
                "must decide only from ACC state, the gate's armed flag and its session " +
                "(DoorLockArmGate.onTimeout). A flag left over from an earlier ACC cycle makes it skip " +
                "arming silently, with no log line.",
            Regex("(?i)surveillanceenabled").containsMatchIn(code))
    }

    /** The timeout must pass the ACC state and the session it was scheduled for, so an old timeout cannot arm a newer session. */
    @Test
    fun `the lock timeout passes its own session to the gate`() {
        val code = codeOnly(memberText(cameraDaemonSource(), "private fun applyLockTimeout"))
        assertTrue(
            "BladeWatch-l55j regressed: applyLockTimeout must call doorLockGate.onTimeout(AccMonitor.isAccOn(), session). " +
                "Without the session argument, a timeout from an earlier ACC cycle can arm a later gate session early.",
            Regex("""onTimeout\(\s*AccMonitor\.isAccOn\(\)\s*,\s*session\s*\)""").containsMatchIn(code))
    }

    /** Gate entry starts a fresh session and leaves the arm decision to DoorLockArmGate. */
    @Test
    fun `gate entry never reads surveillanceEnabled`() {
        val code = codeOnly(memberText(cameraDaemonSource(), "private fun registerDoorLockListenerAndArmOnLock"))
        assertTrue(
            "BladeWatch-l55j: the code extracted for registerDoorLockListenerAndArmOnLock does not call " +
                "doorLockGate.reset(). The extraction is broken, so this guard cannot judge the function.",
            code.contains("doorLockGate.reset()"))
        assertFalse(
            "BladeWatch-l55j regressed: registerDoorLockListenerAndArmOnLock reads surveillanceEnabled. " +
                "Gate entry must start a fresh session (doorLockGate.reset()) and leave the arm decision " +
                "to DoorLockArmGate.",
            Regex("(?i)surveillanceenabled").containsMatchIn(code))
    }

    /**
     * The ACC-ON branch must clear the flag after the gate teardown and before pipeline.onAccOn(),
     * because onAccOn() disables the sentry engine and the flag has to follow it.
     */
    @Test
    fun `the ACC-ON branch clears surveillanceEnabled between cleanup and pipeline onAccOn`() {
        val src = cameraDaemonSource()
        val fnAt = src.indexOf("fun onAccStateChanged(")
        assertTrue("BladeWatch-l55j: could not find onAccStateChanged in CameraDaemon.kt", fnAt >= 0)

        // Match CALL lines only. The BladeWatch-l55j comment in the ACC-ON branch also names
        // pipeline.onAccOn(), so a plain indexOf would anchor on the comment.
        val cleanupAt = Regex("""(?m)^\s*cleanupDoorLockGate\(\)""").find(src, fnAt)?.range?.first ?: -1
        assertTrue(
            "BladeWatch-l55j: onAccStateChanged no longer calls cleanupDoorLockGate(). The ACC-ON gate teardown is missing.",
            cleanupAt > fnAt)
        val onAccOnAt = Regex("""(?m)^\s*pipeline\.onAccOn\(\)""").find(src, cleanupAt)?.range?.first ?: -1
        assertTrue(
            "BladeWatch-l55j: the ACC-ON branch no longer calls pipeline.onAccOn() after cleanupDoorLockGate().",
            onAccOnAt > cleanupAt)

        // Comments are dropped, so a comment that mentions the flag cannot satisfy the check.
        val between = src.substring(cleanupAt, onAccOnAt).lines()
            .filterNot { it.trimStart().startsWith("//") }
            .joinToString("\n")
        assertTrue(
            "BladeWatch-l55j regressed: the ACC-ON branch of onAccStateChanged must set " +
                "surveillanceEnabled = false between cleanupDoorLockGate() and pipeline.onAccOn(). " +
                "pipeline.onAccOn() disables the sentry engine, so without this the next ACC OFF " +
                "reports enabled=true while nothing is armed.",
            between.contains("surveillanceEnabled = false"))
    }

    /**
     * Gate entry captures the session id that reset() starts and hands it to the 60 s timeout, so a
     * timeout scheduled in this session cannot arm a later one.
     */
    @Test
    fun `gate entry passes its session to the lock timeout`() {
        val code = codeOnly(memberText(cameraDaemonSource(), "private fun registerDoorLockListenerAndArmOnLock"))
        assertTrue(
            "BladeWatch-l55j: the code extracted for registerDoorLockListenerAndArmOnLock is empty. " +
                "The extraction is broken, so this guard cannot judge the function.",
            code.isNotBlank())
        assertTrue(
            "BladeWatch-l55j regressed: registerDoorLockListenerAndArmOnLock must capture the session id with " +
                "'val session = doorLockGate.reset()'. Without it there is no session to hand to the timeout.",
            Regex("""val\s+session\s*=\s*doorLockGate\.reset\(\)""").containsMatchIn(code))
        assertTrue(
            "BladeWatch-l55j regressed: registerDoorLockListenerAndArmOnLock must pass that captured session to " +
                "applyLockTimeout(session). Passing doorLockGate.session reads the current session when the " +
                "timeout fires, so a stale timeout from an earlier ACC cycle can arm a later gate session early.",
            Regex("""applyLockTimeout\(\s*session\s*\)""").containsMatchIn(code))
    }

    /**
     * The ACC-ON watchdog only clears the armed flag. It must not start a new gate session, or the open
     * session's 60 s timeout would be superseded.
     */
    @Test
    fun `the ACC-ON watchdog disarms without starting a new gate session`() {
        val code = codeOnly(memberText(cameraDaemonSource(), "private fun startAccOnDisarmWatchdog"))
        assertTrue(
            "BladeWatch-l55j: the code extracted for startAccOnDisarmWatchdog is empty. " +
                "The extraction is broken, so this guard cannot judge the function.",
            code.isNotBlank())
        assertFalse(
            "BladeWatch-l55j regressed: startAccOnDisarmWatchdog calls doorLockGate.reset(). The ACC-ON watchdog " +
                "must use doorLockGate.disarm(), which clears armed WITHOUT starting a new session. A reset " +
                "supersedes the open session, so its 60 s timeout can no longer re-arm.",
            code.contains("doorLockGate.reset()"))
        assertTrue(
            "BladeWatch-l55j regressed: startAccOnDisarmWatchdog must call doorLockGate.disarm() when it " +
                "force-disables surveillance.",
            code.contains("doorLockGate.disarm()"))
    }
}
