package net.bladewatch.app.server

import java.io.File
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.SocketTimeoutException
import java.nio.file.Files
import java.util.concurrent.TimeUnit
import net.bladewatch.app.config.SecretConfigStore
import org.json.JSONObject
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-rdtj.5: the LAN discovery responder. It must answer a paired companion, and give
 * everyone else -- the unsigned, the replayed, the stale -- nothing at all, because even a refusal
 * would tell them a BladeWatch car is parked on this network.
 */
class LanDiscoveryResponderTest {

    private val key = ByteArray(32) { 7 }
    private val otherKey = ByteArray(32) { 9 }
    private val lan: InetAddress = InetAddress.getByName("127.0.0.1")
    private val fp = "ab".repeat(32)

    private var wall = 1_790_000_000_000L // an arbitrary, fixed "now"
    private var mono = 5_000L

    private fun responder(info: LanDiscoveryResponder.ReplyInfo? = LanDiscoveryResponder.ReplyInfo(fp, "byd-a1b2c3d4")) =
        LanDiscoveryResponder(
            probeKey = { key }, replyInfo = { info }, enabled = { true },
            wallClockMs = { wall }, monotonicMs = { mono },
        )

    private var nonceSeq = 0
    private fun nonce() = ByteArray(16) { (it + 16 * nonceSeq).toByte() }.also { nonceSeq++ }
    private fun probe(ts: Long = wall, k: ByteArray = key, n: ByteArray = nonce()) =
        LanDiscoveryResponder.buildProbe(k, n, ts)

    /** Verifies a reply the way the companion will, and returns its JSON. */
    private fun verify(reply: ByteArray, sentNonce: ByteArray): JSONObject {
        assertArrayEquals(LanDiscoveryResponder.REPLY_MAGIC, reply.copyOfRange(0, 8))
        assertArrayEquals("the reply must echo OUR nonce", sentNonce, reply.copyOfRange(8, 24))
        val mac = reply.copyOfRange(24, 56)
        val json = reply.copyOfRange(56, reply.size)
        assertArrayEquals(
            "the reply must be signed with the same key",
            LanDiscoveryResponder.hmac(key, LanDiscoveryResponder.REPLY_MAGIC + sentNonce + json), mac
        )
        return JSONObject(String(json, Charsets.UTF_8))
    }

    @Test
    fun `a correctly signed probe is answered with routing data and the TLS pin`() {
        val n = nonce()
        val reply = responder().answer(probe(n = n), lan)
        assertNotNull(reply)
        val json = verify(reply!!, n)
        assertEquals(LanTls.PORT, json.getInt("port"))
        assertEquals(fp, json.getString("fp"))
        assertEquals("byd-a1b2c3d4", json.getString("id"))
        assertEquals("127.0.0.1", json.getString("ip"))
        assertEquals(setOf("ip", "port", "fp", "id"), json.keys().asSequence().toSet())
    }

    @Test
    fun `a probe signed with the wrong key gets silence`() {
        assertNull(responder().answer(probe(k = otherKey), lan))
    }

    @Test
    fun `a corrupted HMAC gets silence`() {
        val p = probe()
        p[40] = (p[40].toInt() xor 1).toByte()
        assertNull(responder().answer(p, lan))
    }

    @Test
    fun `a probe that is not exactly 256 bytes gets silence`() {
        val p = probe()
        assertNull(responder().answer(p.copyOf(255), lan))
        assertNull(responder().answer(p.copyOf(257), lan))
    }

    @Test
    fun `a probe with the wrong magic gets silence`() {
        val p = probe()
        p[0] = 'X'.code.toByte()
        assertNull(responder().answer(p, lan))
    }

    @Test
    fun `a replayed probe gets silence`() {
        val r = responder()
        val p = probe()
        assertNotNull(r.answer(p, lan))
        assertNull("a captured probe must not work twice", r.answer(p, lan))
    }

    @Test
    fun `probes more than 24 hours old or ahead get silence`() {
        val r = responder()
        val day = TimeUnit.HOURS.toMillis(24)
        assertNull(r.answer(probe(ts = wall - day - 1), lan))
        assertNull(r.answer(probe(ts = wall + day + 1), lan))
        assertNotNull(r.answer(probe(ts = wall - day + 60_000), lan))
    }

    @Test
    fun `the clock jumping backwards mid-session does not break discovery or reopen replays`() {
        val r = responder()
        val before = probe()
        assertNotNull(r.answer(before, lan))

        // The head unit NTP-corrects after boot and its wall clock jumps BACK two hours. The
        // companion's clock is right, so its probes now look two hours in the car's future.
        wall -= TimeUnit.HOURS.toMillis(2)
        mono += 1_000 // the monotonic clock only ever moves forward

        val companionNow = wall + TimeUnit.HOURS.toMillis(2)
        assertNotNull("a fresh probe must still be answered", r.answer(probe(ts = companionNow), lan))
        assertNull("the jump must not let the earlier probe be replayed", r.answer(before, lan))
    }

    @Test
    fun `remembered nonces expire on the monotonic clock, not the wall clock`() {
        val r = responder()
        val n = nonce()
        assertNotNull(r.answer(probe(n = n), lan))
        // A huge wall-clock jump alone must not flush the cache...
        wall += TimeUnit.DAYS.toMillis(365)
        assertNull(r.answer(probe(n = n, ts = wall), lan))
        // ...but 24 h of real elapsed time does, so the cache cannot grow without bound.
        mono += TimeUnit.HOURS.toMillis(24) + 1
        assertNotNull(r.answer(probe(n = n, ts = wall), lan))
    }

    @Test
    fun `a reply is always smaller than the probe -- no amplification`() {
        val reply = responder().answer(probe(), lan)!!
        assertTrue("reply ${reply.size} bytes", reply.size < LanDiscoveryResponder.PROBE_BYTES)
        // And the guard holds even for an absurd device id: silence rather than a large reply.
        val huge = LanDiscoveryResponder.ReplyInfo(fp, "x".repeat(500))
        assertNull(responder(huge).answer(probe(), lan))
    }

    @Test
    fun `no reply before the car knows who it is`() {
        assertNull(responder(info = null).answer(probe(), lan))
    }

    @Test
    fun `end to end over a real UDP socket`() {
        val port = DatagramSocket(0).use { it.localPort }
        val responder = LanDiscoveryResponder(
            probeKey = { key },
            replyInfo = { LanDiscoveryResponder.ReplyInfo(fp, "byd-a1b2c3d4") },
            enabled = { true },
            port = port,
        )
        val thread = Thread(responder::run).apply { isDaemon = true; start() }
        try {
            DatagramSocket().use { client ->
                client.soTimeout = 2_000
                val target = InetSocketAddress(InetAddress.getLoopbackAddress(), port)
                val n = ByteArray(16) { 42 }
                var reply: ByteArray? = null
                // The responder binds on its own thread; retry briefly until it is listening.
                for (attempt in 0 until 20) {
                    val p = LanDiscoveryResponder.buildProbe(key, ByteArray(16) { (42 + attempt).toByte() }, System.currentTimeMillis())
                    client.send(DatagramPacket(p, p.size, target))
                    try {
                        val buf = ByteArray(512)
                        val packet = DatagramPacket(buf, buf.size)
                        client.receive(packet)
                        reply = buf.copyOf(packet.length)
                        assertArrayEquals(ByteArray(16) { (42 + attempt).toByte() }, reply.copyOfRange(8, 24))
                        break
                    } catch (e: SocketTimeoutException) {
                        continue
                    }
                }
                assertNotNull("a signed probe must be answered over the wire", reply)

                // And a forged one gets nothing back at all.
                val forged = LanDiscoveryResponder.buildProbe(otherKey, n, System.currentTimeMillis())
                client.send(DatagramPacket(forged, forged.size, target))
                client.soTimeout = 750
                assertThrows(SocketTimeoutException::class.java) {
                    client.receive(DatagramPacket(ByteArray(512), 512))
                }
            }
        } finally {
            responder.stop()
            thread.join(10_000)
        }
    }

    @Test
    fun `nothing is bound while LAN access is off`() {
        val port = DatagramSocket(0).use { it.localPort }
        val responder = LanDiscoveryResponder(
            probeKey = { key }, replyInfo = { null }, enabled = { false }, port = port,
        )
        val thread = Thread(responder::run).apply { isDaemon = true; start() }
        try {
            Thread.sleep(300)
            // If the responder had bound the port, this would throw.
            DatagramSocket(InetSocketAddress(port)).close()
        } finally {
            responder.stop()
            thread.interrupt()
            thread.join(10_000)
        }
    }

    @Test
    fun `the probe key is created once and never silently replaced`() {
        val dir = Files.createTempDirectory("lan-probe-key").toFile()
        try {
            val file = File(dir, "secrets.json")
            val first = LanDiscoveryResponder.probeKey(SecretConfigStore(file))
            assertEquals(32, first.size)
            assertArrayEquals(first, LanDiscoveryResponder.probeKey(SecretConfigStore(file)))

            val corrupt = SecretConfigStore(File(dir, "bad.json"))
            corrupt.putString("lanDiscovery", "probeKey", "zz")
            assertThrows(IllegalStateException::class.java) { LanDiscoveryResponder.probeKey(corrupt) }
            assertEquals("zz", corrupt.getString("lanDiscovery", "probeKey"))
        } finally {
            dir.deleteRecursively()
        }
    }

    @After
    fun reset() {
        nonceSeq = 0
    }
}
