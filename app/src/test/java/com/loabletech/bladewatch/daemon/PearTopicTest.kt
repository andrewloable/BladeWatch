package net.bladewatch.app.daemon

import java.io.File
import java.nio.file.Files
import java.security.MessageDigest
import java.security.SecureRandom
import net.bladewatch.app.config.SecretConfigStore
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-rdtj.3: the car's Hyperswarm topic. A topic is who can find the car on the DHT at
 * all, so what matters is that it is unique per car, unguessable, and stable -- and that nothing
 * ever rotates it silently, since that strands every paired companion.
 */
class PearTopicTest {

    private val dir = Files.createTempDirectory("pear-topic-test").toFile()
    private val storeFile = File(dir, "secrets.json")

    @After
    fun tearDown() {
        dir.deleteRecursively()
    }

    /** Deterministic stand-in for SecureRandom, so a test can name the seed it expects. */
    private fun fixedRandom(byte: Int) = object : SecureRandom() {
        override fun nextBytes(bytes: ByteArray) = bytes.fill(byte.toByte())
    }

    private fun seed(byte: Int) = ByteArray(32) { byte.toByte() }

    @Test
    fun `two cars with different seeds get different topics`() {
        // Each car's seed comes from its own SecureRandom draw, so this is the production path:
        // two independent seeds through the real derivation.
        val carA = PearTopic.topicHex(SecretConfigStore(File(dir, "a.json")))
        val carB = PearTopic.topicHex(SecretConfigStore(File(dir, "b.json")))
        assertNotEquals(carA, carB)
    }

    @Test
    fun `a topic is a 32-byte value, hex-encoded for swarm join`() {
        val hex = PearTopic.topicHex(SecretConfigStore(storeFile))
        assertEquals(64, hex.length)
        assertTrue(hex, hex.all { it in "0123456789abcdef" })
    }

    @Test
    fun `derivation is deterministic`() {
        assertArrayEquals(PearTopic.derive(seed(1)), PearTopic.derive(seed(1)))
    }

    @Test
    fun `derivation is exactly SHA-256 of the domain tag, a zero byte, then the seed`() {
        // A known-answer test, not "differs from a bare hash": dropping the domain tag still leaves
        // the zero byte, so that weaker check passed with the tag deleted (caught by mutation). And
        // pinning the exact bytes is the point: ANY change to this derivation changes every car's
        // topic, silently stranding every companion already paired with it.
        val expected = MessageDigest.getInstance("SHA-256").run {
            update("bladewatch/pear/topic/v1".toByteArray(Charsets.UTF_8))
            update(0.toByte())
            update(seed(1))
            digest()
        }
        assertArrayEquals(expected, PearTopic.derive(seed(1)))
        assertFalse(PearTopic.derive(seed(1)).contentEquals(MessageDigest.getInstance("SHA-256").digest(seed(1))))
    }

    @Test
    fun `the seed is created once and the topic survives a daemon restart`() {
        val first = PearTopic.topicHex(SecretConfigStore(storeFile), fixedRandom(7))
        // A new store object on the same file is what a restarted pear_daemon sees. A different
        // random source proves the seed was READ, not regenerated.
        val afterRestart = PearTopic.topicHex(SecretConfigStore(storeFile), fixedRandom(9))
        assertEquals(first, afterRestart)
        assertEquals(PearTopic.derive(seed(7)).joinToString("") { "%02x".format(it) }, first)
    }

    @Test
    fun `the topic itself is never what gets stored`() {
        val topic = PearTopic.topicHex(SecretConfigStore(storeFile), fixedRandom(7))
        assertFalse("the secret store must hold the seed, not the derived topic",
            storeFile.readText().contains(topic))
    }

    @Test
    fun `a malformed stored seed fails loudly and is not replaced`() {
        val store = SecretConfigStore(storeFile)
        store.putString("pear", "topicSeed", "not-a-seed")
        val before = storeFile.readText()

        assertThrows(IllegalStateException::class.java) { PearTopic.topicHex(store) }
        // Regenerating would mint a new topic and strand every paired companion without a word.
        assertEquals(before, storeFile.readText())
    }

    @Test
    fun `derive rejects a seed of the wrong size`() {
        assertThrows(IllegalArgumentException::class.java) { PearTopic.derive(ByteArray(16)) }
    }

    @Test
    fun `two processes creating the seed at once end up with the same topic`() {
        // pear_daemon and CameraDaemon's pairing command can both be first to need the seed. Two
        // real JVMs, held at a barrier, each derive the topic from the same empty store; with a
        // separate get-then-put each could keep its own seed and one topic would silently be wrong.
        val store = File(dir, "race.json")
        val go = File(dir, "go")
        val children = listOf(1, 2).map {
            ProcessBuilder(
                File(System.getProperty("java.home"), "bin/java").path, "-cp", System.getProperty("java.class.path"),
                TopicRaceChild::class.java.name, store.path, go.path
            ).redirectErrorStream(true).start()
        }
        Thread.sleep(1_500)
        check(go.createNewFile())
        val topics = children.map { p -> p.inputStream.bufferedReader().readText().trim().also { assertEquals(it, 0, p.waitFor()) } }
        assertEquals("both processes must derive the same topic", topics[0], topics[1])
        assertEquals("and it must be the stored one", PearTopic.topicHex(SecretConfigStore(store)), topics[0])
    }
}

/** Child process for the seed race: waits at the barrier, then prints the topic it derives. */
object TopicRaceChild {
    @JvmStatic
    fun main(args: Array<String>) {
        val store = SecretConfigStore(File(args[0]))
        val go = File(args[1])
        while (!go.exists()) Thread.sleep(1)
        print(PearTopic.topicHex(store))
    }
}
