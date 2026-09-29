package net.bladewatch.app.ui.daemon

import java.io.File
import net.bladewatch.app.ui.model.DaemonType
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-17l7: the health check must not bring back remote access the owner switched off.
 *
 * On the head unit an owner's PEAR_PEER=false was followed 18 s later by "Pear Peer is DEAD --
 * relaunching". The decision is now re-read at relaunch time, and automatic starts no longer save
 * "enabled" -- which is how a stale read used to get written back as if the owner had asked for it.
 */
class HealthCheckRelaunchTest {

    @Test
    fun `a dead core daemon is always relaunched`() {
        assertTrue(DaemonStartupManager.shouldRelaunch(DaemonType.CAMERA_DAEMON, isRunning = false) { false })
    }

    @Test
    fun `an optional daemon switched off since the check is not relaunched`() {
        assertFalse(DaemonStartupManager.shouldRelaunch(DaemonType.PEAR_PEER, isRunning = false) { false })
    }

    @Test
    fun `a dead optional daemon that is still switched on is relaunched`() {
        assertTrue(DaemonStartupManager.shouldRelaunch(DaemonType.PEAR_PEER, isRunning = false) { true })
    }

    @Test
    fun `a running daemon is left alone without even reading its switch`() {
        var read = false
        assertFalse(DaemonStartupManager.shouldRelaunch(DaemonType.PEAR_PEER, isRunning = true) { read = true; true })
        assertFalse(read)
    }

    @Test
    fun `automatic starts never save the enabled switch`() {
        // Source scan (src/main/java is a declared test input): DaemonStartupManager has no UI, so
        // every start it makes is automatic and must pass persistEnabled = false. A bare
        // startDaemon(type) call here would re-save "enabled" from a possibly stale read.
        val path = "src/main/java/com/loabletech/bladewatch/ui/daemon/DaemonStartupManager.kt"
        val src = listOf(File(path), File("app/$path")).first { it.isFile }.readText()
        val relaunch = src.substringAfter("private fun relaunchDaemon(").substringBefore("\n    }\n")
        assertTrue(relaunch, relaunch.contains("vm.startDaemon(type, persistEnabled = false)"))
        val pear = src.substringAfter("private fun startPearFromPreferences(").substringBefore("\n    }\n")
        assertTrue(pear, pear.contains("vm.startDaemon(DaemonType.PEAR_PEER, persistEnabled = false)"))
        assertEquals(
            "a Pear start that would save the switch",
            0,
            Regex("""startDaemon\(DaemonType\.PEAR_PEER\)""").findAll(src).count()
        )
    }
}
