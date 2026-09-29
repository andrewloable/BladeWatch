package net.bladewatch.app.config

import java.io.File
import java.nio.channels.FileChannel
import java.nio.file.Files
import java.nio.file.StandardOpenOption
import java.nio.file.attribute.PosixFilePermission
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * BladeWatch-17l7: a config write from one process must not be undone by another.
 *
 * On the head unit an owner's PEAR_PEER=false, written from outside the service host, was read back
 * as true 18 s later and re-saved over. These tests reproduce the two ingredients deterministically
 * -- a process whose mtime-keyed cache cannot see a newer file, and two processes writing at once --
 * against the real file I/O, redirected into a temp directory.
 */
class UnifiedConfigManagerTest {

    private lateinit var dir: File
    private val file get() = File(dir, "bladewatch_config.json")

    @Before
    fun setUp() {
        dir = Files.createTempDirectory("unified-config").toFile()
        file.writeText("{}")
        UnifiedConfigManager.useDirectoryForTest(dir)
    }

    @After
    fun tearDown() = UnifiedConfigManager.useDirectoryForTest(null)

    /** Another process's write this process's cache cannot see: newer content, same mtime as ours. */
    private fun writeTheCacheCannotSee(change: (JSONObject) -> Unit) {
        val mtime = file.lastModified()
        file.writeText(JSONObject(file.readText()).also(change).toString())
        check(file.setLastModified(mtime))
    }

    @Test
    fun `a write starts from the file on disk, not from a stale cache`() {
        UnifiedConfigManager.setDaemonEnabled("PEAR_PEER", true) // this process now caches true
        writeTheCacheCannotSee { it.getJSONObject("daemons").put("PEAR_PEER", false) }

        UnifiedConfigManager.setDaemonEnabled("ACC_SENTRY_DAEMON", false) // an unrelated write

        val daemons = JSONObject(file.readText()).getJSONObject("daemons")
        assertEquals("the owner's switch-off was saved over", false, daemons.getBoolean("PEAR_PEER"))
        assertEquals(false, daemons.getBoolean("ACC_SENTRY_DAEMON"))
    }

    @Test
    fun `isDaemonEnabled reads the file, not a stale cache`() {
        UnifiedConfigManager.setDaemonEnabled("PEAR_PEER", true)
        writeTheCacheCannotSee { it.getJSONObject("daemons").put("PEAR_PEER", false) }

        assertEquals(false, UnifiedConfigManager.isDaemonEnabled("PEAR_PEER"))
    }

    @Test
    fun `the lock file is world-writable so the app uid can take the same lock`() {
        UnifiedConfigManager.setDaemonEnabled("PEAR_PEER", true)
        val perms = Files.getPosixFilePermissions(File(dir, "bladewatch_config.json.lock").toPath())
        assertTrue(perms.toString(), PosixFilePermission.OTHERS_WRITE in perms)
    }

    @Test
    fun `a lock held by another process delays a write but never blocks it`() {
        // The lock file is world-writable, so any app could sit on it. A config write must give up
        // on the lock after a bounded wait, not hang the daemon.
        val holder = spawn(HoldConfigLock::class.java, File(dir, "bladewatch_config.json.lock").path)
        try {
            assertEquals("locked", holder.inputStream.bufferedReader().readLine())
            val started = System.nanoTime()
            assertTrue(UnifiedConfigManager.setDaemonEnabled("PEAR_PEER", false))
            val tookMs = (System.nanoTime() - started) / 1_000_000
            assertTrue("gave up too early (${tookMs} ms) -- did it try the lock at all?", tookMs >= 1_500)
            assertTrue("blocked for ${tookMs} ms", tookMs < 6_000)
            assertEquals(false, UnifiedConfigManager.isDaemonEnabled("PEAR_PEER"))
        } finally {
            holder.destroyForcibly()
        }
    }

    @Test
    fun `concurrent writers in two processes keep every key`() {
        val go = File(dir, "go")
        val writers = listOf("a", "b").map { spawn(ConfigRaceWriter::class.java, dir.path, it, WRITES.toString(), go.path) }
        Thread.sleep(1_500) // both JVMs up and spinning on the barrier
        check(go.createNewFile())
        for (p in writers) {
            val output = p.inputStream.bufferedReader().readText()
            assertEquals(output, 0, p.waitFor())
        }

        val daemons = JSONObject(file.readText()).getJSONObject("daemons")
        val missing = listOf("a", "b").flatMap { prefix -> (0 until WRITES).map { "$prefix$it" } }
            .filterNot { daemons.has(it) }
        assertEquals("lost updates across processes", emptyList<String>(), missing)
    }

    private fun spawn(main: Class<*>, vararg args: String): Process = ProcessBuilder(
        listOf(File(System.getProperty("java.home"), "bin/java").path, "-cp", System.getProperty("java.class.path"), main.name) + args
    ).redirectErrorStream(true).start()

    private companion object {
        const val WRITES = 150
    }
}

/** Child process: holds the config lock until killed. */
object HoldConfigLock {
    @JvmStatic
    fun main(args: Array<String>) {
        val channel = FileChannel.open(File(args[0]).toPath(), StandardOpenOption.CREATE, StandardOpenOption.WRITE)
        channel.lock()
        println("locked")
        Thread.sleep(60_000)
    }
}

/** Child process for the race: waits at the barrier, then writes distinct keys. */
object ConfigRaceWriter {
    @JvmStatic
    fun main(args: Array<String>) {
        UnifiedConfigManager.useDirectoryForTest(File(args[0]))
        val go = File(args[3])
        while (!go.exists()) Thread.sleep(1)
        repeat(args[2].toInt()) { i -> check(UnifiedConfigManager.setDaemonEnabled("${args[1]}$i", true)) }
    }
}
