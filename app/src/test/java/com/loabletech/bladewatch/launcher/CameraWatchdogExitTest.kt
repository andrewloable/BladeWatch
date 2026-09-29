package net.bladewatch.app.launcher

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.File

/**
 * BladeWatch-rdtj.65: the camera daemon's watchdog must bring the daemon back from any death.
 * At ACC OFF, vold SIGINTs (exit 130) every process holding a file on the SD card it is
 * unmounting, and the watchdog used to give up on that for good.
 *
 * Runs [DaemonLauncher.WATCHDOG_EXIT_LINES] -- the real script text -- under /bin/sh, with a fake
 * daemon that exits with the given codes and a no-op `sleep`.
 */
class CameraWatchdogExitTest {
    @get:Rule val tmp = TemporaryFolder()

    private class Run(val starts: Int, val gaveUp: Boolean, val lockRemoved: Boolean)

    /** Exits with [codes] in turn, each after running [ranSeconds]; then runs "forever". */
    private fun watch(codes: List<Int>, ranSeconds: Int = 0): Run {
        val lock = File(tmp.root, "camera_daemon.lock").apply { writeText("123") }
        val script = buildString {
            appendLine("LOG_FILE=/dev/null")
            appendLine("LOCK_FILE='${lock.absolutePath}'")
            appendLine("MAX_RETRIES=5")
            appendLine("RETRY_COUNT=0")
            appendLine("sleep() { :; }")
            appendLine("CODES='${codes.joinToString(" ")}'")
            appendLine("n=0")
            appendLine("while true; do")
            appendLine("  n=\$((n + 1))")
            appendLine("  STARTED=\$((\$(date +%s) - $ranSeconds))")
            appendLine("  EXIT_CODE=\$(echo \"\$CODES\" | awk -v n=\$n '{print \$n}')")
            appendLine("  if [ -z \"\$EXIT_CODE\" ]; then echo \"running \$n\"; exit 0; fi")
            DaemonLauncher.WATCHDOG_EXIT_LINES.forEach(::appendLine)
            appendLine("done")
            appendLine("echo \"gave-up \$n\"")
        }
        val p = ProcessBuilder("/bin/sh", "-c", script).redirectErrorStream(true).start()
        val out = p.inputStream.bufferedReader().readText().trim()
        assertEquals("script failed: $out", 0, p.waitFor())
        val (state, n) = out.lines().last().split(" ")
        return Run(n.toInt(), state == "gave-up", !lock.exists())
    }

    @Test
    fun aSigintFromVoldIsRestartedAndItsStaleLockCleared() {
        val r = watch(listOf(130))
        assertFalse(r.gaveUp)
        assertEquals("started again after the SIGINT", 2, r.starts)
        assertTrue(r.lockRemoved)
    }

    @Test
    fun anySignalDeathIsRestarted() {
        for (code in listOf(130, 134, 137, 139, 143)) {
            assertFalse("exit $code", watch(listOf(code)).gaveUp)
        }
    }

    @Test
    fun aLockConflictKeepsTheOtherInstancesLock() {
        val r = watch(listOf(1))
        assertEquals(2, r.starts)
        assertFalse("exit 1 is another instance holding the lock: never delete it", r.lockRemoved)
    }

    @Test
    fun aCrashLoopStillGivesUp() {
        val r = watch(List(5) { 139 })
        assertTrue(r.gaveUp)
        assertEquals(5, r.starts)
    }

    @Test
    fun deathsFarApartNeverAddUpToGivingUp() {
        val r = watch(List(8) { 130 }, ranSeconds = 3600)
        assertFalse("each run lasted an hour: none of them is a crash loop", r.gaveUp)
        assertEquals(9, r.starts)
    }
}
