package net.bladewatch.app.config

import java.io.File
import java.nio.file.Files
import java.nio.file.attribute.PosixFilePermissions
import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * BladeWatch-rdtj.3: two PROCESSES writing the secret store must not lose each other's writes.
 *
 * CameraDaemon and pear_daemon are separate app_process daemons writing the same file. Threads in
 * one JVM cannot show this -- the in-process monitor alone would pass -- so this spawns two real
 * JVMs, holds both at a start barrier so their writes genuinely overlap, and then checks that every
 * key both of them wrote survived.
 */
class SecretConfigStoreCrossProcessTest {

    @Test
    fun `concurrent writers in two processes keep every key`() {
        val dir = Files.createTempDirectory("secret-race").toFile()
        val store = File(dir, "secrets.json")
        val go = File(dir, "go")
        val writers = listOf("a", "b").map { prefix ->
            ProcessBuilder(
                File(System.getProperty("java.home"), "bin/java").path,
                "-cp", System.getProperty("java.class.path"),
                RaceWriter::class.java.name, store.path, prefix, WRITES.toString(), go.path
            ).redirectErrorStream(true).start()
        }
        Thread.sleep(1_500) // both JVMs up and spinning on the barrier
        check(go.createNewFile())
        for (p in writers) {
            val output = p.inputStream.bufferedReader().readText()
            assertEquals(output, 0, p.waitFor())
        }

        val section = SecretConfigStore(store).loadSection("race")
        val missing = listOf("a", "b")
            .flatMap { prefix -> (0 until WRITES).map { "$prefix$it" } }
            .filterNot { section.has(it) }
        assertEquals("lost updates across processes", emptyList<String>(), missing)
    }

    @Test
    fun `the lock file is created owner-only`() {
        // World-readable, any co-resident app could open it and take a shared lock, blocking every
        // secret write on the car.
        val dir = Files.createTempDirectory("secret-lock").toFile()
        SecretConfigStore(File(dir, "secrets.json")).putString("s", "k", "v")
        assertEquals(
            PosixFilePermissions.fromString("rw-------"),
            Files.getPosixFilePermissions(File(dir, "secrets.json.lock").toPath())
        )
    }

    private companion object {
        const val WRITES = 300
    }
}

/** Child-process entry point for the race above: waits at the barrier, then writes distinct keys. */
object RaceWriter {
    @JvmStatic
    fun main(args: Array<String>) {
        val store = SecretConfigStore(File(args[0]))
        val go = File(args[3])
        while (!go.exists()) Thread.sleep(1)
        repeat(args[2].toInt()) { i -> check(store.putString("race", "${args[1]}$i", "v")) }
    }
}
