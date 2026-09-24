package net.bladewatch.app.daemon

import java.io.File
import java.nio.file.Files
import java.nio.file.attribute.PosixFilePermission
import net.bladewatch.app.server.TcpCommandServer
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-rdtj.17: the in-car UI's view of the Pear peer. "Running" and "reachable" are
 * different questions -- a live process on a head unit with no network must not read as reachable.
 */
class PearStatusTest {

    private val file = File(Files.createTempDirectory("pear-status").toFile(), "pear_status.json")
    private var now = 1_000_000L
    private val status = PearStatus(file) { now }

    @After
    fun tearDown() {
        TcpCommandServer.pearStatusFileForTest = null
    }

    private fun report(running: Boolean = true, at: Long = now) = PearStatus.report(file, running, true, at)

    private fun reachable(r: JSONObject): Boolean? = if (r.isNull("reachable")) null else r.getBoolean("reachable")

    private fun healthy() {
        status.joined = true
        status.online = true
        status.companions = 2
        status.lastCompanionAt = 999_000L
        assertTrue(status.write())
    }

    @Test
    fun `a joined peer with the DHT online is reachable, with its companions`() {
        healthy()
        val r = report()
        assertEquals(true, reachable(r))
        assertEquals(true, r.getBoolean("running"))
        assertEquals(2, r.getInt("companions"))
        assertEquals(999_000L, r.getLong("lastCompanionAt"))
    }

    @Test
    fun `alive but offline is NOT reachable`() {
        healthy()
        status.online = false // networking disabled; the process is still up
        status.write()
        assertEquals(false, reachable(report()))
        assertEquals(true, report().getBoolean("running"))
    }

    @Test
    fun `a pear-end that cannot report DHT state is unknown, not false`() {
        healthy()
        status.online = null
        status.write()
        assertEquals(null, reachable(report()))
    }

    @Test
    fun `not running, stale, not joined, or no file at all is not reachable`() {
        healthy()
        assertEquals(false, reachable(report(running = false)))
        assertEquals(0, report(running = false).getInt("companions"))

        assertEquals(false, reachable(report(at = now + PearStatus.STALE_MS + 1)))
        assertEquals(0, report(at = now + PearStatus.STALE_MS + 1).getInt("companions"))

        status.joined = false
        status.write()
        assertEquals(false, reachable(report()))

        file.delete()
        assertEquals(false, reachable(report()))
        assertTrue(report().isNull("lastCompanionAt"))

        file.writeText("not json")
        assertEquals(false, reachable(report()))
    }

    @Test
    fun `the file holds counts and times only, readable by its owner alone`() {
        healthy()
        assertEquals(
            setOf("updatedAt", "joined", "online", "companions", "lastCompanionAt"),
            JSONObject(file.readText()).keys().asSequence().toSet(),
        )
        assertEquals(
            setOf(PosixFilePermission.OWNER_READ, PosixFilePermission.OWNER_WRITE),
            Files.getPosixFilePermissions(file.toPath()),
        )
        assertFalse(File(file.path + ".tmp").exists())
    }

    @Test
    fun `the pearStatus IPC command serves the report`() {
        healthy()
        TcpCommandServer.pearStatusFileForTest = file
        val r = TcpCommandServer(19876).processCommand(JSONObject().put("cmd", "pearStatus"))
        assertEquals("ok", r.getString("status"))
        // No pear_daemon process exists in a JVM test, so this is the not-running answer.
        assertEquals(false, r.getBoolean("running"))
        assertEquals(false, reachable(r))
        assertTrue(r.has("enabled") && r.has("companions") && r.has("lastCompanionAt"))
    }
}
