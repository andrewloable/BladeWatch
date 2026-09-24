package net.bladewatch.app.daemon

import java.security.MessageDigest
import java.security.SecureRandom
import net.bladewatch.app.config.SecretConfigStore

/**
 * The Hyperswarm topic this car announces itself on.
 *
 * A topic is a public rendezvous point: anyone who knows it can find the car on the DHT and
 * ATTEMPT a connection -- the HTTP API behind it still demands a JWT, but the topic decides who
 * can knock at all. So it must be unguessable and unique per car: never a hardcoded string, and
 * never a hash of anything public such as the device id or VIN. flutter_pear's string-to-topic
 * helper carries an "unsafe" prefix for exactly this reason -- every device hashing the same string
 * lands in the same global room. (Its name is deliberately not spelled out here: the rdtj.3
 * acceptance check greps app/src/main for it and must find nothing.)
 *
 * Derived from a random 32-byte seed generated once per car and kept in the 600 shell-only secret
 * store, so it is stable across daemon restarts and reboots. Hashed under a domain tag, so the
 * topic can never collide with anything else a future feature derives from the same seed. It is
 * deliberately NOT derived from the auth device secret: rotating that secret revokes sessions, and
 * should not also make every paired companion lose track of the car.
 */
object PearTopic {
    internal const val SECTION = "pear"
    private const val SEED_KEY = "topicSeed"
    private const val SEED_BYTES = 32
    private val DOMAIN = "bladewatch/pear/topic/v1".toByteArray(Charsets.UTF_8)

    fun derive(seed: ByteArray): ByteArray {
        require(seed.size == SEED_BYTES) { "topic seed must be $SEED_BYTES bytes" }
        return MessageDigest.getInstance("SHA-256").run {
            update(DOMAIN)
            update(0.toByte())
            update(seed)
            digest()
        }
    }

    /** The car's topic as the 64-char hex string pear-end's `swarm.join` expects. */
    fun topicHex(store: SecretConfigStore, random: SecureRandom = SecureRandom()): String =
        derive(loadOrCreateSeed(store, random)).toHex()

    /**
     * The stored seed, or a new one persisted on first use.
     *
     * A stored value that is not a valid seed is an ERROR, not a cue to regenerate: a new seed is a
     * new topic, which silently strands every companion paired with this car. Better the daemon
     * fail loudly than rotate the car's identity behind the owner's back.
     */
    fun loadOrCreateSeed(store: SecretConfigStore, random: SecureRandom): ByteArray {
        val stored = store.getString(SECTION, SEED_KEY)
            // Created atomically across processes: pear_daemon and CameraDaemon's pairing command
            // can both get here first, and the loser of a separate get-then-put would keep a seed
            // that is not the stored one -- a topic no companion is told about.
            ?: store.putStringIfAbsent(SECTION, SEED_KEY, ByteArray(SEED_BYTES).also(random::nextBytes).toHex())
            ?: error("could not persist the pear topic seed to the secret store")
        check(stored.length == SEED_BYTES * 2 && stored.all { it in HEX }) {
            "stored pear topic seed is malformed; refusing to replace it (would change the topic)"
        }
        return stored.chunked(2).map { it.toInt(16).toByte() }.toByteArray()
    }

    private const val HEX = "0123456789abcdef"

    private fun ByteArray.toHex(): String =
        joinToString("") { b -> "%02x".format(b.toInt() and 0xff) }
}
