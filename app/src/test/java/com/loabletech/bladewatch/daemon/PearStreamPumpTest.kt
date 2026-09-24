package net.bladewatch.app.daemon

import java.io.ByteArrayOutputStream
import java.io.File
import java.net.ConnectException
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong
import net.bladewatch.app.logging.DaemonLogConfig
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-rdtj.6: the car-side Pear pump, against real loopback sockets standing in for the
 * HTTP server and a fake peer standing in for the companion.
 */
class PearStreamPumpTest {

    /** What the pump sent to the companion, decoded. */
    private val sent = LinkedBlockingQueue<Pair<String, PearMux.Frame>>()
    private val servers = CopyOnWriteArrayList<TestServer>()
    private var pump: PearStreamPump? = null

    @After
    fun tearDown() {
        pump?.shutdown()
        servers.forEach { it.stop() }
    }

    private fun pump(
        connect: () -> Socket,
        limits: PearStreamPump.Limits = PearStreamPump.Limits(),
        now: () -> Long = System::currentTimeMillis,
    ) = PearStreamPump({ peer, msg -> sent.put(peer to PearMux.decode(msg)!!) }, connect, limits, now).also { pump = it }

    private fun connectTo(server: TestServer): () -> Socket = { Socket(InetAddress.getLoopbackAddress(), server.port) }

    /** Frames already taken off [sent] while waiting for a different one. Streams race. */
    private val pending = ArrayList<Pair<String, PearMux.Frame>>()

    /** The next frame of [type] the pump sent on [stream] (to [peer], if given); others are kept. */
    private fun next(type: Byte, stream: Int, peer: String? = null, timeoutMs: Long = 5_000): PearMux.Frame? {
        fun matches(e: Pair<String, PearMux.Frame>) =
            e.second.type == type && e.second.stream == stream && (peer == null || e.first == peer)
        pending.firstOrNull(::matches)?.let { pending.remove(it); return it.second }
        val deadline = System.currentTimeMillis() + timeoutMs
        while (true) {
            val left = deadline - System.currentTimeMillis()
            if (left <= 0) return null
            val e = sent.poll(left, TimeUnit.MILLISECONDS) ?: return null
            if (matches(e)) return e.second
            pending += e
        }
    }

    /** Collects [count] bytes of DATA the pump sends on [stream], granting credit as it goes. */
    private fun readData(p: PearStreamPump, peer: String, stream: Int, count: Int): ByteArray {
        val out = ByteArrayOutputStream()
        while (out.size() < count) {
            val f = next(PearMux.DATA, stream, peer) ?: error("only ${out.size()} of $count bytes arrived")
            out.write(f.payload)
            p.onMessage(peer, PearMux.window(stream, f.payload.size))
        }
        return out.toByteArray()
    }

    @Test(timeout = 20_000)
    fun `bytes are copied both ways`() {
        val echo = TestServer.echo().also(servers::add)
        val p = pump(connectTo(echo))
        p.onMessage("peerA", PearMux.open(1))
        p.onMessage("peerA", PearMux.data(1, "GET /status".toByteArray()))
        assertArrayEquals("GET /status".toByteArray(), readData(p, "peerA", 1, 11))
    }

    @Test(timeout = 20_000)
    fun `two concurrent streams never cross`() {
        val echo = TestServer.echo().also(servers::add)
        val p = pump(connectTo(echo))
        p.onMessage("peerA", PearMux.open(1))
        p.onMessage("peerA", PearMux.open(2))
        repeat(40) {
            p.onMessage("peerA", PearMux.data(1, ByteArray(1_000) { 'A'.code.toByte() }))
            p.onMessage("peerA", PearMux.data(2, ByteArray(1_000) { 'B'.code.toByte() }))
        }
        val one = ByteArrayOutputStream()
        val two = ByteArrayOutputStream()
        while (one.size() < 40_000 || two.size() < 40_000) {
            val (_, f) = sent.poll(5, TimeUnit.SECONDS) ?: error("stalled at ${one.size()} / ${two.size()}")
            if (f.type != PearMux.DATA) continue
            (if (f.stream == 1) one else two).write(f.payload)
            p.onMessage("peerA", PearMux.window(f.stream, f.payload.size))
        }
        assertTrue(one.toByteArray().all { it == 'A'.code.toByte() })
        assertTrue(two.toByteArray().all { it == 'B'.code.toByte() })
        assertEquals(40_000, one.size())
        assertEquals(40_000, two.size())
    }

    @Test(timeout = 20_000)
    fun `a close from the companion closes the server side`() {
        val echo = TestServer.echo().also(servers::add)
        val p = pump(connectTo(echo))
        p.onMessage("peerA", PearMux.open(1))
        p.onMessage("peerA", PearMux.data(1, byteArrayOf(1)))
        readData(p, "peerA", 1, 1)
        p.onMessage("peerA", PearMux.close(1))
        assertTrue("the server never saw EOF", echo.awaitEof(5_000))
        assertEquals(0, p.openStreams)
    }

    @Test(timeout = 20_000)
    fun `a close from the server is sent to the companion`() {
        val echo = TestServer.echo().also(servers::add)
        val p = pump(connectTo(echo))
        p.onMessage("peerA", PearMux.open(1))
        p.onMessage("peerA", PearMux.data(1, byteArrayOf(1)))
        readData(p, "peerA", 1, 1)
        echo.dropAll()
        assertNotNull(next(PearMux.CLOSE, 1))
        waitFor { p.openStreams == 0 }
    }

    @Test(timeout = 20_000)
    fun `the stream caps are enforced per peer and in total`() {
        val echo = TestServer.echo().also(servers::add)
        val p = pump(connectTo(echo), PearStreamPump.Limits(maxStreamsPerPeer = 2, maxStreams = 3))
        p.onMessage("peerA", PearMux.open(1))
        p.onMessage("peerA", PearMux.open(2))
        p.onMessage("peerA", PearMux.open(3)) // over the per-peer cap
        assertNotNull("the third stream of one peer must be refused", next(PearMux.CLOSE, 3))
        p.onMessage("peerB", PearMux.open(1))
        p.onMessage("peerB", PearMux.open(2)) // over the total cap
        assertNotNull("the stream over the total cap must be refused", next(PearMux.CLOSE, 2, peer = "peerB"))
        assertEquals(3, p.openStreams)
    }

    @Test(timeout = 20_000)
    fun `an idle stream is closed by the sweep`() {
        val echo = TestServer.echo().also(servers::add)
        val clock = AtomicLong(1_000_000)
        val p = pump(connectTo(echo), PearStreamPump.Limits(idleTimeoutMs = 60_000), clock::get)
        p.onMessage("peerA", PearMux.open(1))
        p.onMessage("peerA", PearMux.data(1, byteArrayOf(1)))
        readData(p, "peerA", 1, 1)
        p.sweepIdle()
        assertEquals("a fresh stream must survive the sweep", 1, p.openStreams)
        clock.addAndGet(60_001)
        p.sweepIdle()
        assertNotNull(next(PearMux.CLOSE, 1))
        assertTrue("the server side must be closed too", echo.awaitEof(5_000))
        assertEquals(0, p.openStreams)
    }

    @Test(timeout = 30_000)
    fun `a slow companion gets backpressure, not an unbounded buffer, and no bytes are lost`() {
        val total = 1_000_000
        val pattern = ByteArray(total) { (it % 251).toByte() }
        val firehose = TestServer.firehose(pattern).also(servers::add)
        val window = 64 * 1024
        val p = pump(connectTo(firehose), PearStreamPump.Limits(window = window))
        p.onMessage("peerA", PearMux.open(1))

        // Without any credit back, the pump must stop at exactly one window.
        val first = ByteArrayOutputStream()
        while (first.size() < window) first.write(next(PearMux.DATA, 1)!!.payload)
        assertEquals(window, first.size())
        assertNull("sent past the window with no credit", next(PearMux.DATA, 1, timeoutMs = 700))

        // Each grant releases exactly that much.
        p.onMessage("peerA", PearMux.window(1, 10_000))
        val second = ByteArrayOutputStream()
        while (second.size() < 10_000) second.write(next(PearMux.DATA, 1)!!.payload)
        assertEquals(10_000, second.size())
        assertNull(next(PearMux.DATA, 1, timeoutMs = 500))

        // Then everything, in order, with nothing dropped.
        p.onMessage("peerA", PearMux.window(1, window))
        val rest = readData(p, "peerA", 1, total - window - 10_000)
        assertArrayEquals(pattern, first.toByteArray() + second.toByteArray() + rest)
    }

    @Test(timeout = 20_000)
    fun `a companion that overruns its credit loses the stream`() {
        // The server is slow to accept, so nothing is written and no credit comes back yet.
        val echo = TestServer.echo().also(servers::add)
        val connects = AtomicInteger()
        val slowConnect: () -> Socket = { connects.incrementAndGet(); Thread.sleep(1_500); Socket(InetAddress.getLoopbackAddress(), echo.port) }
        val p = pump(slowConnect, PearStreamPump.Limits(window = 4_096))
        p.onMessage("peerA", PearMux.open(1))
        p.onMessage("peerA", PearMux.data(1, ByteArray(4_096)))
        assertEquals("a full window is allowed", 1, p.openStreams)
        p.onMessage("peerA", PearMux.data(1, ByteArray(1)))
        assertNotNull("one byte past the window must close the stream", next(PearMux.CLOSE, 1))
        assertEquals(0, p.openStreams)
    }

    @Test(timeout = 20_000)
    fun `the pump retries while the HTTP server is not listening yet`() {
        val echo = TestServer.echo().also(servers::add)
        val attempts = AtomicInteger()
        val flaky: () -> Socket = {
            if (attempts.incrementAndGet() <= 3) throw ConnectException("byd_cam_daemon still starting")
            Socket(InetAddress.getLoopbackAddress(), echo.port)
        }
        val p = pump(flaky)
        p.onMessage("peerA", PearMux.open(1))
        p.onMessage("peerA", PearMux.data(1, "ping".toByteArray()))
        assertArrayEquals("ping".toByteArray(), readData(p, "peerA", 1, 4))
        assertEquals(4, attempts.get())
    }

    @Test(timeout = 20_000)
    fun `the pump gives up at the connect deadline and says so`() {
        val never: () -> Socket = { throw ConnectException("nothing listening") }
        val p = pump(never, PearStreamPump.Limits(connectDeadlineMs = 400))
        p.onMessage("peerA", PearMux.open(1))
        assertNotNull(next(PearMux.CLOSE, 1))
        assertEquals(0, p.openStreams)
    }

    @Test(timeout = 30_000)
    fun `a restarting HTTP server closes pumped streams cleanly and the pump keeps working`() {
        var server = TestServer.echo().also(servers::add)
        val p = pump({ Socket(InetAddress.getLoopbackAddress(), server.port) })
        p.onMessage("peerA", PearMux.open(1))
        p.onMessage("peerA", PearMux.open(2))
        p.onMessage("peerA", PearMux.data(1, byteArrayOf(1)))
        p.onMessage("peerA", PearMux.data(2, byteArrayOf(2)))
        readData(p, "peerA", 1, 1)
        readData(p, "peerA", 2, 1)

        server.stop() // byd_cam_daemon dies
        assertNotNull(next(PearMux.CLOSE, 1))
        assertNotNull(next(PearMux.CLOSE, 2))
        waitFor { p.openStreams == 0 }

        server = TestServer.echo().also(servers::add) // and comes back
        p.onMessage("peerA", PearMux.open(3))
        p.onMessage("peerA", PearMux.data(3, "again".toByteArray()))
        assertArrayEquals("again".toByteArray(), readData(p, "peerA", 3, 5))
    }

    @Test(timeout = 20_000)
    fun `a vanished peer takes only its own streams with it`() {
        val echo = TestServer.echo().also(servers::add)
        val p = pump(connectTo(echo))
        p.onMessage("peerA", PearMux.open(1))
        p.onMessage("peerB", PearMux.open(1))
        waitFor { echo.accepted.get() == 2 }
        p.onPeerClosed("peerA")
        assertEquals(1, p.openStreams)
        p.onMessage("peerB", PearMux.data(1, byteArrayOf(9)))
        assertArrayEquals(byteArrayOf(9), readData(p, "peerB", 1, 1))
    }

    @Test(timeout = 20_000)
    fun `junk from the far side is ignored without opening anything`() {
        val echo = TestServer.echo().also(servers::add)
        val p = pump(connectTo(echo))
        p.onMessage("peerA", byteArrayOf())
        p.onMessage("peerA", byteArrayOf(9, 0, 0, 0, 1, 1))
        p.onMessage("peerA", PearMux.data(7, byteArrayOf(1))) // unknown stream
        p.onMessage("peerA", byteArrayOf(PearMux.OPEN, 0, 0, 0, 1, 99)) // unknown version
        assertEquals(0, p.openStreams)
        assertEquals(0, echo.accepted.get())
    }

    @Test
    fun `the pump only ever targets the Pear TLS listener and its logging is gated`() {
        val path = "src/main/java/com/loabletech/bladewatch/daemon/PearStreamPump.kt"
        val src = listOf(File(path), File("app/$path")).first { it.isFile }.readText()
        assertFalse("the in-car UI's port must not appear in the pump at all", "8080" in src)
        val connect = src.substringAfter("fun connectToRemoteListener()")
        assertTrue(connect, connect.contains("HttpServer.PEAR_TLS_PORT"))
        assertEquals(8444, net.bladewatch.app.server.HttpServer.PEAR_TLS_PORT)
        val helper = src.substringAfter("private fun log(").substringBefore("\n    }\n")
        assertTrue(helper.contains("DaemonLogConfig.PEAR_PUMP"))
        assertEquals("a logger call outside the gated helper", helper.split("logger.").size, src.split("logger.").size)
        assertFalse("must ship false", DaemonLogConfig.PEAR_PUMP)
    }

    private fun waitFor(timeoutMs: Long = 5_000, condition: () -> Boolean) {
        val deadline = System.currentTimeMillis() + timeoutMs
        while (!condition()) {
            check(System.currentTimeMillis() < deadline) { "condition not met in $timeoutMs ms" }
            Thread.sleep(10)
        }
    }

    /** A loopback server that either echoes or writes a fixed payload to every connection. */
    private class TestServer private constructor(private val onConnection: (Socket) -> Unit) {
        private val server = ServerSocket(0, 50, InetAddress.getLoopbackAddress())
        private val clients = CopyOnWriteArrayList<Socket>()
        private val eofs = LinkedBlockingQueue<Unit>()
        val accepted = AtomicInteger()
        val port: Int get() = server.localPort

        init {
            Thread {
                while (!server.isClosed) {
                    val s = try { server.accept() } catch (e: Exception) { break }
                    clients += s
                    accepted.incrementAndGet()
                    Thread { onConnection(s) }.apply { isDaemon = true }.start()
                }
            }.apply { isDaemon = true }.start()
        }

        fun awaitEof(timeoutMs: Long) = eofs.poll(timeoutMs, TimeUnit.MILLISECONDS) != null

        fun dropAll() = clients.forEach { runCatching { it.close() } }

        fun stop() {
            runCatching { server.close() }
            dropAll()
        }

        companion object {
            fun echo(): TestServer {
                lateinit var self: TestServer
                self = TestServer { s ->
                    try {
                        val buf = ByteArray(8_192)
                        val input = s.getInputStream()
                        val out = s.getOutputStream()
                        while (true) {
                            val n = input.read(buf)
                            if (n < 0) break
                            out.write(buf, 0, n)
                        }
                        self.eofs.put(Unit)
                    } catch (e: Exception) {
                        // dropped by the test
                    }
                }
                return self
            }

            fun firehose(payload: ByteArray) = TestServer { s ->
                runCatching { s.getOutputStream().write(payload) }
            }
        }
    }
}
