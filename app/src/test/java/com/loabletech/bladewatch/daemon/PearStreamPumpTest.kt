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

    /** What the fake companion has received per (peer, stream), for its WINDOW frames. */
    private val received = HashMap<Pair<String, Int>, Long>()

    /** The fake companion acknowledges [n] more bytes on [stream] and grants them back as credit. */
    private fun ack(p: PearStreamPump, peer: String, stream: Int, n: Int) {
        val total = received.merge(peer to stream, n.toLong(), Long::plus)!!
        p.onMessage(peer, PearMux.window(stream, n, total))
    }

    /** Collects [count] bytes of DATA the pump sends on [stream], granting credit as it goes. */
    private fun readData(p: PearStreamPump, peer: String, stream: Int, count: Int): ByteArray {
        val out = ByteArrayOutputStream()
        while (out.size() < count) {
            val f = next(PearMux.DATA, stream, peer) ?: error("only ${out.size()} of $count bytes arrived")
            out.write(f.payload)
            ack(p, peer, stream, f.payload.size)
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
            ack(p, "peerA", f.stream, f.payload.size)
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
        assertNotNull("the pump answers the CLOSE", next(PearMux.CLOSE, 1))
        assertTrue("the server never saw EOF", echo.awaitEof(5_000))
        waitFor { p.openStreams == 0 }
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
        Thread.sleep(200)
        assertEquals("kept until the companion answers, to resend it after a reconnect", 1, p.openStreams)
        p.onMessage("peerA", PearMux.close(1))
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
        ack(p, "peerA", 1, 10_000)
        val second = ByteArrayOutputStream()
        while (second.size() < 10_000) second.write(next(PearMux.DATA, 1)!!.payload)
        assertEquals(10_000, second.size())
        assertNull(next(PearMux.DATA, 1, timeoutMs = 500))

        // Then everything, in order, with nothing dropped.
        ack(p, "peerA", 1, window)
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
        p.onMessage("peerA", PearMux.close(1))
        p.onMessage("peerA", PearMux.close(2))
        waitFor { p.openStreams == 0 }

        server = TestServer.echo().also(servers::add) // and comes back
        p.onMessage("peerA", PearMux.open(3))
        p.onMessage("peerA", PearMux.data(3, "again".toByteArray()))
        assertArrayEquals("again".toByteArray(), readData(p, "peerA", 3, 5))
    }

    @Test(timeout = 20_000)
    fun `a vanished peer's streams wait out the grace period, and only its own`() {
        val echo = TestServer.echo().also(servers::add)
        val clock = AtomicLong(1_000_000)
        val p = pump(connectTo(echo), PearStreamPump.Limits(graceMs = 60_000), clock::get)
        p.onMessage("peerA", PearMux.open(1))
        p.onMessage("peerB", PearMux.open(1))
        waitFor { echo.accepted.get() == 2 }
        p.onPeerClosed("peerA")
        clock.addAndGet(60_000)
        p.sweepIdle()
        assertEquals("detached, not closed, within the grace period", 2, p.openStreams)
        clock.addAndGet(1)
        p.sweepIdle()
        assertEquals(1, p.openStreams)
        assertTrue("the detached stream's server side is closed", echo.awaitEof(5_000))
        assertNull("nothing is sent into a dead connection", next(PearMux.CLOSE, 1, peer = "peerA", timeoutMs = 300))
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

    // --- BladeWatch-bbvx: streams survive a reconnect ---

    /** Everything the pump has sent so far and not yet taken: lost with a dying connection. */
    private fun dropInFlight() {
        Thread.sleep(200)
        sent.clear()
        pending.clear()
    }

    @Test(timeout = 30_000)
    fun `a download survives a dropped connection byte for byte, on a new connection`() {
        val total = 600_000
        val pattern = ByteArray(total) { (it % 251).toByte() }
        val firehose = TestServer.firehose(pattern).also(servers::add)
        val window = 64 * 1024
        val p = pump(connectTo(firehose), PearStreamPump.Limits(window = window))
        p.onMessage("peerA", PearMux.open(1))
        val token = next(PearMux.OPENED, 1, "peerA")!!.token
        val before = readData(p, "peerA", 1, 100_000)

        dropInFlight() // up to a window was in flight, and is lost
        p.onPeerClosed("peerA")
        val got = received.getValue("peerA" to 1)
        received["peerB" to 1] = got
        p.onMessage("peerB", PearMux.reattach(1, token, got, window + got))

        val ok = next(PearMux.REATTACHED, 1, "peerB")!!
        assertEquals("the car had nothing from the companion", 0L, ok.received)
        assertEquals(window.toLong(), ok.limit)
        val after = readData(p, "peerB", 1, total - before.size)
        assertArrayEquals(pattern, before + after)
        assertEquals(1, p.openStreams)
    }

    @Test(timeout = 20_000)
    fun `bytes the companion sent before a drop reach the server once`() {
        val sink = TestServer.sink().also(servers::add)
        val p = pump(connectTo(sink))
        p.onMessage("peerA", PearMux.open(1))
        val token = next(PearMux.OPENED, 1)!!.token
        p.onMessage("peerA", PearMux.data(1, "abc".toByteArray()))
        waitFor { sink.bytes().size == 3 }
        p.onPeerClosed("peerA")
        p.onMessage("peerA", PearMux.reattach(1, token, 0, PearMux.INITIAL_WINDOW.toLong()))
        val ok = next(PearMux.REATTACHED, 1)!!
        assertEquals("so the companion resends from byte 3, not 0", 3L, ok.received)
        p.onMessage("peerA", PearMux.data(1, "def".toByteArray()))
        waitFor { sink.bytes().size == 6 }
        assertArrayEquals("abcdef".toByteArray(), sink.bytes())
    }

    @Test(timeout = 20_000)
    fun `another peer cannot take a stream without its token`() {
        val echo = TestServer.echo().also(servers::add)
        val p = pump(connectTo(echo))
        p.onMessage("peerA", PearMux.open(1))
        val token = next(PearMux.OPENED, 1, "peerA")!!.token
        val guess = token.copyOf().also { it[15] = (it[15] + 1).toByte() }
        p.onMessage("peerB", PearMux.reattach(1, guess, 0, PearMux.INITIAL_WINDOW.toLong()))
        assertNotNull(next(PearMux.CLOSE, 1, "peerB"))
        assertNull(next(PearMux.REATTACHED, 1, timeoutMs = 300))

        // Nor, with the token, onto an id that is some other stream's.
        p.onMessage("peerB", PearMux.open(2))
        next(PearMux.OPENED, 2, "peerB")!!
        p.onMessage("peerB", PearMux.reattach(2, token, 0, PearMux.INITIAL_WINDOW.toLong()))
        assertNotNull(next(PearMux.CLOSE, 2, "peerB"))

        p.onMessage("peerA", PearMux.data(1, byteArrayOf(4)))
        assertArrayEquals("the stream is still peerA's", byteArrayOf(4), readData(p, "peerA", 1, 1))
    }

    @Test(timeout = 20_000)
    fun `a reattach with offsets the car never sent closes the stream`() {
        val echo = TestServer.echo().also(servers::add)
        val p = pump(connectTo(echo))
        p.onMessage("peerA", PearMux.open(1))
        val token = next(PearMux.OPENED, 1)!!.token
        p.onMessage("peerA", PearMux.reattach(1, token, 1_000, PearMux.INITIAL_WINDOW.toLong()))
        assertNotNull(next(PearMux.CLOSE, 1))
        waitFor { p.openStreams == 0 }
    }

    @Test(timeout = 20_000)
    fun `after the grace period a reattach is refused`() {
        val echo = TestServer.echo().also(servers::add)
        val clock = AtomicLong(1_000_000)
        val p = pump(connectTo(echo), PearStreamPump.Limits(graceMs = 1_000), clock::get)
        p.onMessage("peerA", PearMux.open(1))
        val token = next(PearMux.OPENED, 1)!!.token
        p.onPeerClosed("peerA")
        clock.addAndGet(1_001)
        p.sweepIdle()
        p.onMessage("peerA", PearMux.reattach(1, token, 0, PearMux.INITIAL_WINDOW.toLong()))
        assertNotNull(next(PearMux.CLOSE, 1))
        assertEquals(0, p.openStreams)
    }

    @Test(timeout = 30_000)
    fun `a CLOSE lost with the connection is resent after the reattach, with the bytes before it`() {
        val payload = ByteArray(50_000) { (it % 7).toByte() }
        val server = TestServer.firehose(payload, thenClose = true).also(servers::add)
        val p = pump(connectTo(server))
        p.onMessage("peerA", PearMux.open(1))
        val token = next(PearMux.OPENED, 1)!!.token
        assertNotNull("the server finished", next(PearMux.CLOSE, 1))
        sent.clear()
        pending.clear() // ...and every frame of it was lost
        p.onPeerClosed("peerA")
        p.onMessage("peerA", PearMux.reattach(1, token, 0, PearMux.INITIAL_WINDOW.toLong()))
        next(PearMux.REATTACHED, 1)!!
        received.remove("peerA" to 1)
        assertArrayEquals(payload, readData(p, "peerA", 1, payload.size))
        assertNotNull("the CLOSE comes again", next(PearMux.CLOSE, 1))
        p.onMessage("peerA", PearMux.close(1))
        waitFor { p.openStreams == 0 }
        assertEquals(0L, p.unackedBytes)
    }

    @Test(timeout = 20_000)
    fun `the companion's last bytes reach the server before its CLOSE closes it`() {
        val sink = TestServer.sink().also(servers::add)
        val slow: () -> Socket = { Thread.sleep(500); Socket(InetAddress.getLoopbackAddress(), sink.port) }
        val p = pump(slow)
        p.onMessage("peerA", PearMux.open(1))
        p.onMessage("peerA", PearMux.data(1, "last words".toByteArray()))
        p.onMessage("peerA", PearMux.close(1))
        assertNotNull("answered at once", next(PearMux.CLOSE, 1))
        assertTrue(sink.awaitEof(5_000))
        assertArrayEquals("last words".toByteArray(), sink.bytes())
        waitFor { p.openStreams == 0 }
    }

    @Test(timeout = 30_000)
    fun `bytes kept for resending are capped per stream and in total`() {
        val pattern = ByteArray(2_000_000) { it.toByte() }
        val firehose = TestServer.firehose(pattern).also(servers::add)
        val p = pump(
            connectTo(firehose),
            PearStreamPump.Limits(maxUnackedPerStream = 100_000, maxUnackedTotal = 150_000),
        )
        // A peer that grants plenty of credit and never says it received anything.
        for (id in 1..2) {
            p.onMessage("peerA", PearMux.open(id))
            p.onMessage("peerA", PearMux.window(id, 10_000_000, 0))
        }
        Thread.sleep(1_000)
        assertEquals("both streams together stop at the total", 150_000L, p.unackedBytes)

        // Saying it received them lets more through, and frees what was kept.
        var got1 = 0L
        while (true) got1 += (next(PearMux.DATA, 1, timeoutMs = 200) ?: break).payload.size
        assertTrue("one stream stops at its own cap: $got1", got1 in 1..100_000)
        p.onMessage("peerA", PearMux.window(1, 1, got1))
        waitFor { next(PearMux.DATA, 1, timeoutMs = 100) != null }
        assertTrue(p.unackedBytes <= 150_000)
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

        private val collected = ByteArrayOutputStream()

        fun bytes(): ByteArray = synchronized(collected) { collected.toByteArray() }

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

            fun firehose(payload: ByteArray, thenClose: Boolean = false) = TestServer { s ->
                runCatching { s.getOutputStream().write(payload) }
                if (thenClose) runCatching { s.close() }
            }

            /** Records everything it is sent, then signals EOF. */
            fun sink(): TestServer {
                lateinit var self: TestServer
                self = TestServer { s ->
                    try {
                        val buf = ByteArray(8_192)
                        val input = s.getInputStream()
                        while (true) {
                            val n = input.read(buf)
                            if (n < 0) break
                            synchronized(self.collected) { self.collected.write(buf, 0, n) }
                        }
                        self.eofs.put(Unit)
                    } catch (e: Exception) {
                        // dropped by the test
                    }
                }
                return self
            }
        }
    }
}
