package net.bladewatch.app.server

import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.Inet4Address
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.NetworkInterface
import java.net.SocketTimeoutException
import java.nio.ByteBuffer
import java.security.MessageDigest
import java.security.SecureRandom
import java.util.concurrent.TimeUnit
import javax.crypto.Mac
import javax.crypto.spec.SecretKeySpec
import net.bladewatch.app.config.SecretConfigStore
import net.bladewatch.app.logging.DaemonLogger
import org.json.JSONObject

/**
 * Answers a paired companion asking "is my car on this network?" (BladeWatch-rdtj.5).
 *
 * The companion does not try to work out whether it shares a network with the car -- reading the
 * Wi-Fi SSID needs ACCESS_FINE_LOCATION on Android 10+. It broadcasts a signed probe instead, and
 * if the car answers they are on the same segment by definition. It then connects straight to the
 * LAN TLS listener, because Hyperswarm cannot connect two peers behind one NAT.
 *
 * A plain DatagramSocket, not mDNS: NsdManager needs an Android Context, which this shell-UID
 * daemon does not properly have.
 *
 * ## Wire format -- the companion (BladeWatch-rdtj.8) must reproduce it exactly
 *
 *     probe (UDP to port [PORT], exactly [PROBE_BYTES] bytes):
 *         "BWPROBE1" | nonce(16) | timestampMs(8, big-endian) | HMAC(32) | zero padding
 *         HMAC = HMAC-SHA256(probeKey, magic | nonce | timestamp)
 *
 *     reply (UDP, unicast back to the probe's source address and port):
 *         "BWREPLY1" | nonce(16, echoed) | HMAC(32) | UTF-8 JSON {"ip","port","fp","id"}
 *         HMAC = HMAC-SHA256(probeKey, magic | nonce | json)
 *
 * The probe key is the per-car secret the pairing payload carries (BladeWatch-rdtj.7).
 *
 * ## What it refuses, and why
 *
 * - **Anything unsigned.** Answering would tell every device on the network that a BladeWatch car is
 *   parked here -- a leak about the owner's location and vehicle. Invalid probes get silence.
 * - **Any probe not exactly [PROBE_BYTES] long.** The reply is always shorter than that, so the
 *   responder can never be used to amplify traffic at a spoofed victim.
 * - **Replays.** Every accepted nonce is remembered for the full freshness window, keyed on the
 *   MONOTONIC clock. Known ceiling: the cache lives in memory, so after a daemon restart a probe
 *   captured in the last 24 h can be answered once more -- revealing only "a car is at this LAN
 *   address", and only to a device already on that LAN.
 *
 * ## Why the freshness window is a generous ±24 h
 *
 * This head unit NTP-corrects its wall clock after boot and the clock can jump backwards
 * (AuthMiddleware documents it) -- exactly when the daemon starts and an owner is most likely to be
 * probing. A tight `|now - ts|` window silently refuses every probe during that skew, which reads as
 * "LAN discovery sometimes doesn't work". The window only bounds how long the nonce cache must
 * remember; replay protection is the cache, whose expiry cannot be moved by a clock jump.
 *
 * Opt-in like the TLS listener: bound only while `network.lanHttpEnabled` is on, re-checked every
 * few seconds so switching it off frees the port.
 */
class LanDiscoveryResponder(
    private val probeKey: () -> ByteArray,
    private val replyInfo: () -> ReplyInfo?,
    private val enabled: () -> Boolean,
    private val wallClockMs: () -> Long = System::currentTimeMillis,
    private val monotonicMs: () -> Long = { System.nanoTime() / 1_000_000 },
    private val port: Int = PORT,
) {
    /** What a reply tells the companion. Only routing data and a public certificate pin. */
    class ReplyInfo(val tlsFingerprintSha256: String, val deviceId: String)

    @Volatile
    private var running = true

    @Volatile
    private var socket: DatagramSocket? = null

    // nonce (hex) -> monotonic ms it was accepted. Bounded; see MAX_REMEMBERED_NONCES.
    private val seen = LinkedHashMap<String, Long>()

    /** Blocking loop; run it on its own thread. */
    fun run() {
        while (running) {
            try {
                if (!enabled()) {
                    Thread.sleep(RECHECK_MS.toLong())
                    continue
                }
                DatagramSocket(null).use { s ->
                    s.reuseAddress = true
                    s.bind(InetSocketAddress(port)) // all interfaces: probes are broadcast
                    s.soTimeout = RECHECK_MS // so the opt-in flag is re-read
                    socket = s
                    log.info("listening on udp/$port")
                    val buf = ByteArray(PROBE_BYTES + 1) // +1 so an oversized probe is detectable
                    while (running && enabled()) {
                        val packet = DatagramPacket(buf, buf.size)
                        try {
                            s.receive(packet)
                        } catch (e: SocketTimeoutException) {
                            continue
                        }
                        val reply = answer(packet.data.copyOf(packet.length), packet.address) ?: continue
                        s.send(DatagramPacket(reply, reply.size, packet.address, packet.port))
                    }
                }
                socket = null
                log.info("stopped listening (LAN access off)")
            } catch (e: InterruptedException) {
                return
            } catch (e: Exception) {
                if (!running) return
                log.error("responder error: ${e.message}")
                try {
                    Thread.sleep(5_000)
                } catch (ie: InterruptedException) {
                    return
                }
            }
        }
    }

    fun stop() {
        running = false
        socket?.close()
    }

    /**
     * The reply to [probe], or null to stay silent. Silence is the answer to everything that is not
     * a fresh, correctly signed, never-seen probe -- the sender learns nothing either way.
     */
    internal fun answer(probe: ByteArray, from: InetAddress): ByteArray? {
        if (probe.size != PROBE_BYTES) return null
        if (!probe.copyOfRange(0, 8).contentEquals(PROBE_MAGIC)) return null
        val key = probeKey()
        val signed = probe.copyOfRange(0, SIGNED_PROBE_BYTES)
        val mac = probe.copyOfRange(SIGNED_PROBE_BYTES, SIGNED_PROBE_BYTES + 32)
        if (!MessageDigest.isEqual(hmac(key, signed), mac)) return null // constant-time compare

        val nonce = probe.copyOfRange(8, 24)
        val timestamp = ByteBuffer.wrap(probe, 24, 8).long
        if (kotlin.math.abs(wallClockMs() - timestamp) > FRESHNESS_WINDOW_MS) return null
        if (!rememberIfNew(nonce.toHex())) return null // replay

        val info = replyInfo() ?: return null // nothing to route to yet
        val json = JSONObject()
            .put("ip", localAddressFacing(from)?.hostAddress ?: JSONObject.NULL)
            .put("port", LanTls.PORT)
            .put("fp", info.tlsFingerprintSha256)
            .put("id", info.deviceId)
            .toString().toByteArray(Charsets.UTF_8)
        val reply = REPLY_MAGIC + nonce + hmac(key, REPLY_MAGIC + nonce + json) + json
        // Enforced, not assumed: a reply at least as large as the probe would make this an
        // amplifier. Normal replies are ~210 bytes; only a pathological device id could reach this.
        return reply.takeIf { it.size < PROBE_BYTES }
    }

    @Synchronized
    private fun rememberIfNew(nonce: String): Boolean {
        val now = monotonicMs()
        seen.entries.removeAll { now - it.value > FRESHNESS_WINDOW_MS }
        if (seen.containsKey(nonce)) return false
        seen[nonce] = now
        // ponytail: plain oldest-first eviction at a size cap -- only correctly signed probes get
        // here, so only paired companions can fill it; a persistent cache if that ever changes.
        while (seen.size > MAX_REMEMBERED_NONCES) seen.remove(seen.keys.first())
        return true
    }

    companion object {
        /** UDP. Distinct from every TCP port in use; UDP and TCP port spaces are separate anyway. */
        const val PORT = 18443
        const val PROBE_BYTES = 256

        val PROBE_MAGIC = "BWPROBE1".toByteArray(Charsets.US_ASCII)
        val REPLY_MAGIC = "BWREPLY1".toByteArray(Charsets.US_ASCII)

        private const val SIGNED_PROBE_BYTES = 8 + 16 + 8
        private val FRESHNESS_WINDOW_MS = TimeUnit.HOURS.toMillis(24)
        private const val MAX_REMEMBERED_NONCES = 10_000
        private const val RECHECK_MS = 5_000
        internal const val SECTION = "lanDiscovery"
        private const val PROBE_KEY = "probeKey"

        // Lazy: tests load this companion for buildProbe and never need a logger.
        private val log by lazy { DaemonLogger.getInstance("LanDiscovery") }

        /**
         * The per-car probe key, created on first use and kept in the 600 secret store. Only
         * byd_cam_daemon touches it -- this responder and the pairing command -- so the in-process
         * lock is enough to stop two first uses from minting different keys.
         */
        @JvmStatic
        @Synchronized
        fun probeKey(store: SecretConfigStore): ByteArray {
            store.getString(SECTION, PROBE_KEY)?.let { stored ->
                check(stored.length == 64 && stored.all { it in "0123456789abcdef" }) {
                    "stored LAN probe key is malformed; refusing to replace it (would unpair companions)"
                }
                return stored.chunked(2).map { it.toInt(16).toByte() }.toByteArray()
            }
            val key = ByteArray(32).also(SecureRandom()::nextBytes)
            check(store.putString(SECTION, PROBE_KEY, key.toHex())) {
                "could not persist the LAN probe key to the secret store"
            }
            return key
        }

        /** Builds a probe -- used by the tests, and the executable form of the spec above. */
        @JvmStatic
        fun buildProbe(key: ByteArray, nonce: ByteArray, timestampMs: Long): ByteArray {
            require(nonce.size == 16)
            val signed = PROBE_MAGIC + nonce + ByteBuffer.allocate(8).putLong(timestampMs).array()
            return (signed + hmac(key, signed)).copyOf(PROBE_BYTES) // zero-padded
        }

        internal fun hmac(key: ByteArray, data: ByteArray): ByteArray =
            Mac.getInstance("HmacSHA256").run { init(SecretKeySpec(key, "HmacSHA256")); doFinal(data) }

        /** This car's IPv4 address on the same subnet as [peer] -- the one the companion can reach. */
        private fun localAddressFacing(peer: InetAddress): InetAddress? {
            if (peer !is Inet4Address) return null
            val target = peer.address.fold(0L) { acc, b -> (acc shl 8) or (b.toLong() and 0xff) }
            for (nif in NetworkInterface.getNetworkInterfaces() ?: return null) {
                for (ia in nif.interfaceAddresses) {
                    val addr = ia.address as? Inet4Address ?: continue
                    val prefix = ia.networkPrefixLength.toInt().coerceIn(0, 32)
                    val mask = if (prefix == 0) 0L else (0xffffffffL shl (32 - prefix)) and 0xffffffffL
                    val mine = addr.address.fold(0L) { acc, b -> (acc shl 8) or (b.toLong() and 0xff) }
                    if (mine and mask == target and mask) return addr
                }
            }
            return null
        }

        private fun ByteArray.toHex(): String = joinToString("") { "%02x".format(it.toInt() and 0xff) }
    }
}
