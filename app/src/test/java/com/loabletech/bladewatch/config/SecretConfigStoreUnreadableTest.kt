package net.bladewatch.app.config

import java.io.File
import java.nio.file.Files
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-w7by: a secret store that exists but cannot be parsed is not an empty one. A write
 * used to read it as empty and save "empty + this change", dropping the auth secret, every paired
 * companion, the TLS identity, the probe key and the Pear topic seed in one go.
 */
class SecretConfigStoreUnreadableTest {

    @Test
    fun `a write never replaces a store it could not read`() {
        // A store path that exists but cannot be read (a directory here, which fails the read for
        // any user, root included): refuse the write rather than start over.
        val dir = Files.createTempDirectory("secret-unreadable").toFile()
        val file = File(dir, "secrets.json").apply { mkdirs() }
        val store = SecretConfigStore(file)

        assertFalse("the write must be refused", store.putString("lanTls", "certificateDer", "new"))
        assertTrue("left exactly as it was", file.isDirectory)
        assertFalse(store.isReadable())
    }

    @Test
    fun `a damaged store is started over, but kept beside it first`() {
        val dir = Files.createTempDirectory("secret-damaged").toFile()
        val file = File(dir, "secrets.json")
        val damaged = "{\"auth\": {\"deviceSecret\": \"keep-me\"}, \"companion\": {"
        file.writeText(damaged)
        val store = SecretConfigStore(file)
        assertFalse("a pairing check must not take it for empty", store.isReadable())

        assertTrue(store.putString("s", "k", "v"))
        assertEquals("v", store.getString("s", "k"))
        val kept = dir.listFiles()!!.single { it.name.startsWith("secrets.json.damaged-") }
        assertEquals("what it held can still be recovered", damaged, kept.readText())
    }

    @Test
    fun `an empty or missing store is still written normally`() {
        val dir = Files.createTempDirectory("secret-empty").toFile()
        val blank = File(dir, "blank.json").apply { writeText("  ") }
        assert(SecretConfigStore(blank).putString("s", "k", "v"))
        assertEquals("v", SecretConfigStore(blank).getString("s", "k"))
        val missing = File(dir, "missing.json")
        assert(SecretConfigStore(missing).putString("s", "k", "v"))
        assertEquals("v", SecretConfigStore(missing).getString("s", "k"))
    }

    // BladeWatch-w7by: an install restarted the app before the daemons; its IPC read of the device
    // secret failed, it minted a NEW one and persisted it once the daemon answered, and every
    // companion token died. Only the daemon, with a store it can read, may mint.
    @Test
    fun `only the daemon, reading its store, may mint secrets`() {
        try {
            SecretConfigBridge.directStoreForTest = null
            assertFalse("a process that is not the daemon (the app, this JVM) never mints", SecretConfigBridge.canMintSecrets())

            val dir = Files.createTempDirectory("secret-mint").toFile()
            SecretConfigBridge.directStoreForTest = SecretConfigStore(File(dir, "secrets.json"))
            assertTrue("the daemon with a readable store may", SecretConfigBridge.canMintSecrets())

            SecretConfigBridge.directStoreForTest = SecretConfigStore(File(dir, "unreadable").apply { mkdirs() })
            assertFalse("not while it cannot read the store", SecretConfigBridge.canMintSecrets())
        } finally {
            SecretConfigBridge.directStoreForTest = null
        }
    }
}
