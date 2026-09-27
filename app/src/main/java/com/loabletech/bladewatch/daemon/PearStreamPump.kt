package net.bladewatch.app.daemon

import java.io.IOException
import java.net.InetAddress
import java.net.Socket
import java.security.MessageDigest
import java.security.SecureRandom
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.atomic.AtomicLong
import net.bladewatch.app.logging.DaemonLogConfig
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.server.HttpServer

/**
 * The car side of the Pear transport (BladeWatch-rdtj.6): every stream a companion opens over its
 * Pear connection ([PearMux]) becomes a TCP connection to the HTTP server, and bytes are copied
 * both ways until either end closes. Opaque bytes -- no HTTP parsing -- so ConnectRPC, stills and
 * clip playback work over Pear exactly as they do over any socket.
 *
 * Runs in pear_daemon, where the worklet IPC is; the HTTP server lives in byd_cam_daemon, so this is
 * a real cross-process hop over loopback TCP.
 *
 * ## Where it connects, and why nowhere else
 *
 * [HttpServer.PEAR_TLS_PORT] on 127.0.0.1: a REMOTE-trust TLS listener with the pairing-pinned
 * certificate. Two separate reasons:
 *
 *  - REMOTE, because a pumped connection arrives from 127.0.0.1 exactly like an app on the head
 *    unit, and debug -- the build that runs on the car -- grants unauthenticated access to local
 *    apps under some conditions (AuthMiddleware's Tier 2). Never the in-car UI's listener.
 *  - TLS, because Pear's own encryption authenticates nothing anyone pinned. The companion runs
 *    TLS through the stream to this listener and checks the certificate against its pairing pin,
 *    so a peer that merely knows the topic can neither pose as the car nor read a relayed session
 *    (owner's decision, BladeWatch-rdtj.8). The pump stays opaque: it moves TLS records it cannot
 *    read.
 *
 * ## Surviving a reconnect (BladeWatch-bbvx)
 *
 * When a companion's Pear connection drops, its streams are DETACHED, not closed: the TCP
 * connection to the HTTP server stays open, and what was sent but not yet acknowledged is kept.
 * A companion that comes back within [Limits.graceMs] sends REATTACH with the token the car gave
 * it in OPENED -- compared in constant time, so another peer that knows the topic cannot take the
 * stream -- and both sides resend from where the other stopped receiving ([PearMux] has the
 * protocol). After the grace period a detached stream is closed as before.
 *
 * ## Limits
 *
 * Anyone who knows the car's topic can connect, so every resource is capped: streams per peer and
 * in total, a connect deadline (byd_cam_daemon may be restarting), an idle timeout, per-stream
 * credit in both directions -- a peer that overruns its credit loses the stream, and a stream never
 * reads from its socket faster than the peer grants -- and the bytes kept for resending, per stream
 * and in total ([Limits.maxUnackedPerStream], [Limits.maxUnackedTotal]), so a peer that grants
 * credit and never acknowledges cannot grow the car's memory. Two threads per stream (one blocked
 * on each side), so the thread count is bounded by the stream cap.
 *
 * Payload bytes are never logged: they carry JWTs and video.
 */
class PearStreamPump(
    /** Delivers one message to [peer] over Pear. Must be safe to call from any thread, and must not block. */
    private val send: (peer: String, message: ByteArray) -> Unit,
    private val connect: () -> Socket = ::connectToRemoteListener,
    private val limits: Limits = Limits(),
    private val now: () -> Long = System::currentTimeMillis,
) {
    class Limits(
        val maxStreamsPerPeer: Int = 16,
        val maxStreams: Int = 64,
        val idleTimeoutMs: Long = 5 * 60_000L,
        val connectDeadlineMs: Long = 15_000L,
        val window: Int = PearMux.INITIAL_WINDOW,
        /** How long a detached stream, or a CLOSE awaiting its answer, is kept. */
        val graceMs: Long = 60_000L,
        /** Bytes sent and not yet acknowledged, per stream: above the companion's 2 MiB window. */
        val maxUnackedPerStream: Int = 4 * 1024 * 1024,
        val maxUnackedTotal: Long = 32L * 1024 * 1024,
    )

    private data class Key(val peer: String, val id: Int)

    /** Takes up to [want] bytes of [Limits.maxUnackedTotal]; 0 when it is spent. */
    private fun reserveTotal(want: Long): Int {
        while (true) {
            val current = unackedTotal.get()
            val take = minOf(want, limits.maxUnackedTotal - current)
            if (take <= 0) return 0
            if (unackedTotal.compareAndSet(current, current + take)) return take.toInt()
        }
    }

    private val streams = ConcurrentHashMap<Key, Stream>()
    private val unackedTotal = AtomicLong()
    private val random = SecureRandom()

    val openStreams: Int get() = streams.size

    /** Bytes held for resending, across every stream. */
    val unackedBytes: Long get() = unackedTotal.get()

    /** One Pear message from [peer]. Called on the worklet IPC thread, never concurrently. */
    fun onMessage(peer: String, message: ByteArray) {
        val frame = PearMux.decode(message) ?: return log("discarded a malformed frame")
        val key = Key(peer, frame.stream)
        when (frame.type) {
            PearMux.OPEN -> open(key, frame)
            PearMux.DATA -> streams[key]?.receive(frame.payload)
            PearMux.WINDOW -> streams[key]?.grant(frame.credit, frame.received)
            PearMux.CLOSE -> streams[key]?.onPeerClose()
            PearMux.REATTACH -> reattach(key, frame)
        }
    }

    /**
     * The Pear connection to [peer] is gone. Its streams wait [Limits.graceMs] for a REATTACH; sending
     * to them stops, but what their server sends meanwhile is still kept, up to the credit.
     */
    fun onPeerClosed(peer: String) {
        val at = now()
        streams.values.filter { it.key.peer == peer }.forEach { it.detach(at) }
    }

    /**
     * Closes streams with no traffic either way for [Limits.idleTimeoutMs], and those detached, or
     * waiting for a CLOSE to be answered, for longer than [Limits.graceMs]. Call periodically.
     */
    fun sweepIdle() {
        val t = now()
        for (s in streams.values) {
            val detachedAt = s.detachedAt
            val closeSentAt = s.closeSentAt
            when {
                detachedAt != null -> if (t - detachedAt > limits.graceMs) s.abort(notifyPeer = false)
                closeSentAt != null -> if (t - closeSentAt > limits.graceMs) s.abort(notifyPeer = false)
                s.lastActivity < t - limits.idleTimeoutMs -> s.abort(notifyPeer = true)
            }
        }
    }

    fun shutdown() = streams.values.forEach { it.abort(notifyPeer = true) }

    private fun open(key: Key, frame: PearMux.Frame) {
        // A duplicate id is ignored, not refused: answering CLOSE would tear down the live stream.
        if (streams.containsKey(key)) return // NOT `key in streams`: on ConcurrentHashMap that is containsValue
        val refuse = frame.payload[0] != PearMux.VERSION ||
            streams.size >= limits.maxStreams ||
            streams.keys.count { it.peer == key.peer } >= limits.maxStreamsPerPeer
        if (refuse) {
            log("refused a stream (${streams.size} open)")
            send(key.peer, PearMux.close(key.id))
            return
        }
        val token = ByteArray(PearMux.TOKEN_BYTES).also(random::nextBytes)
        val stream = Stream(key, token)
        streams[key] = stream
        send(key.peer, PearMux.opened(key.id, token))
        Thread({ stream.run() }, "pear-pump-r").apply { isDaemon = true }.start()
    }

    /**
     * REATTACH on [key]: the token names the stream -- whichever connection or id it had before.
     * Unknown (never issued, or already closed): CLOSE, so the companion stops waiting for it.
     */
    private fun reattach(key: Key, frame: PearMux.Frame) {
        val token = frame.token
        val stream = streams.values.firstOrNull { MessageDigest.isEqual(it.token, token) }
        val occupied = streams[key]
        if (stream == null || (occupied != null && occupied !== stream)) {
            log("refused a reattach")
            send(key.peer, PearMux.close(key.id))
            return
        }
        stream.rebind(key, frame.received, frame.limit)
    }

    private inner class Stream(key: Key, val token: ByteArray) {
        @Volatile var key: Key = key
            private set
        @Volatile var lastActivity: Long = now()
        @Volatile var detachedAt: Long? = null
            private set
        @Volatile var closeSentAt: Long? = null
            private set
        @Volatile private var socket: Socket? = null
        private val lock = Object()

        // All guarded by lock. Offsets count bytes from the start of the stream, each direction.
        private var closed = false
        private var closeReceived = false
        private var sent = 0L                            // to the companion, in DATA frames
        private var limit = limits.window.toLong()       // how far the companion lets us send
        private val unacked = ArrayDeque<ByteArray>()    // bytes [unackedStart, sent), in frames
        private var unackedStart = 0L
        private var received = 0L                        // from the companion
        private var recvLimit = limits.window.toLong()   // how far we let the companion send
        private val toSocket = LinkedBlockingQueue<ByteArray>()

        fun run() {
            val s = connectWithRetry() ?: return abort(notifyPeer = true)
            socket = s
            if (synchronized(lock) { closed }) return closeQuietly(s) // closed while connecting
            Thread({ writeLoop(s) }, "pear-pump-w").apply { isDaemon = true }.start()
            readLoop(s)
        }

        /** byd_cam_daemon may be starting or restarting: retry, with backoff, until the deadline. */
        private fun connectWithRetry(): Socket? {
            val deadline = System.nanoTime() + limits.connectDeadlineMs * 1_000_000
            var backoffMs = 50L
            while (!synchronized(lock) { closed }) {
                try {
                    return connect()
                } catch (e: IOException) {
                    if (System.nanoTime() + backoffMs * 1_000_000 > deadline) {
                        log("gave up connecting to the HTTP server: ${e.message}")
                        return null
                    }
                    Thread.sleep(backoffMs)
                    backoffMs = (backoffMs * 2).coerceAtMost(1_000L)
                }
            }
            return null
        }

        /** Server -> peer, never faster than the peer's credit, nor past the resend caps. */
        private fun readLoop(s: Socket) {
            val buf = ByteArray(PearMux.MAX_DATA)
            var reserved = 0 // of the total cap, taken by awaitCredit before the read
            try {
                val input = s.getInputStream()
                while (true) {
                    reserved = awaitCredit()
                    if (reserved == 0) break // closed, or closing
                    val n = input.read(buf, 0, reserved)
                    if (n < 0) break // the server finished
                    val chunk = buf.copyOf(n)
                    val sentIt = synchronized(lock) {
                        // Nothing may follow our CLOSE, and a closed stream is gone.
                        if (closed || closeSentAt != null) return@synchronized false
                        unacked.addLast(chunk)
                        sent += n
                        // Under the lock, so a resend after a reattach can never interleave with it.
                        sendAttached(PearMux.data(key.id, chunk))
                        true
                    }
                    unackedTotal.addAndGet(-(reserved - if (sentIt) n else 0).toLong())
                    reserved = 0
                    if (!sentIt) break
                    lastActivity = now()
                }
            } catch (e: IOException) {
                // The socket was closed under us, or the server went away: both end the stream.
            } finally {
                if (reserved > 0) unackedTotal.addAndGet(-reserved.toLong())
            }
            finish()
        }

        /**
         * Waits for credit and room under both resend caps, and reserves what it returns from the
         * total -- atomically, or two streams could both read past it.
         */
        private fun awaitCredit(): Int {
            synchronized(lock) {
                while (true) {
                    if (closed || closeSentAt != null) return 0
                    val credit = limit - sent
                    val room = limits.maxUnackedPerStream - (sent - unackedStart)
                    if (credit <= 0 || room <= 0) {
                        lock.wait()
                        continue
                    }
                    val taken = reserveTotal(minOf(credit, room, PearMux.MAX_DATA.toLong()))
                    if (taken > 0) return taken
                    lock.wait(50) // other streams' acknowledgements free the total without waking this lock
                }
            }
        }

        /** Peer -> server. Grants credit back only once bytes have actually left for the server. */
        private fun writeLoop(s: Socket) {
            var consumed = 0
            try {
                val out = s.getOutputStream()
                while (true) {
                    val chunk = toSocket.take()
                    if (chunk === POISON) break
                    if (chunk === FIN) {
                        // Everything the companion sent before its CLOSE is written: let go.
                        closeQuietly(s)
                        release()
                        break
                    }
                    out.write(chunk)
                    lastActivity = now()
                    consumed += chunk.size
                    if (consumed >= limits.window / 4 || toSocket.isEmpty()) {
                        synchronized(lock) {
                            recvLimit += consumed
                            sendAttached(PearMux.window(key.id, consumed, received))
                        }
                        consumed = 0
                    }
                }
            } catch (e: IOException) {
                val (closing, peerDone) = synchronized(lock) { (closeSentAt != null) to closeReceived }
                when {
                    !closing -> abort(notifyPeer = true)
                    peerDone -> release() // the server is gone before the companion's last bytes
                    else -> Unit // the server ended first: the companion's answer releases
                }
            }
        }

        fun receive(bytes: ByteArray) {
            val overran = synchronized(lock) {
                if (closed || closeReceived) return
                if (received + bytes.size > recvLimit) true else {
                    received += bytes.size
                    false
                }
            }
            if (overran) {
                log("a peer overran its credit; closing the stream")
                return abort(notifyPeer = true)
            }
            lastActivity = now()
            toSocket.put(bytes) // bounded by recvLimit: at most one window queued
        }

        fun grant(credit: Int, peerReceived: Long) {
            synchronized(lock) {
                limit += credit
                trim(peerReceived)
                lock.notifyAll()
            }
            lastActivity = now()
        }

        /** Drops what the peer has received. A claim past what was sent is ignored. */
        private fun trim(peerReceived: Long) {
            val upTo = minOf(peerReceived, sent)
            while (unacked.isNotEmpty() && unackedStart + unacked.first().size <= upTo) {
                val n = unacked.removeFirst().size
                unackedStart += n
                unackedTotal.addAndGet(-n.toLong())
            }
        }

        fun detach(at: Long) {
            synchronized(lock) {
                if (closed) return
                if (detachedAt == null) detachedAt = at
            }
        }

        /** The companion is back, on [newKey]'s connection: resume where each side stopped. */
        fun rebind(newKey: Key, peerReceived: Long, peerLimit: Long) {
            val valid = synchronized(lock) {
                if (closed) return
                val ok = peerReceived >= unackedStart && peerReceived <= sent && peerLimit >= sent
                if (ok) {
                    if (newKey != key) {
                        streams.remove(key, this)
                        key = newKey
                        streams[newKey] = this
                    }
                    detachedAt = null
                    trim(peerReceived)
                    limit = peerLimit
                    send(key.peer, PearMux.reattached(key.id, received, recvLimit))
                    var offset = unackedStart
                    for (chunk in unacked) {
                        val skip = (peerReceived - offset).coerceIn(0, chunk.size.toLong()).toInt()
                        if (skip < chunk.size) send(key.peer, PearMux.data(key.id, chunk, skip, chunk.size - skip))
                        offset += chunk.size
                    }
                    if (closeSentAt != null) send(key.peer, PearMux.close(key.id))
                    lock.notifyAll()
                }
                ok
            }
            if (!valid) {
                log("a reattach claimed impossible offsets; closing the stream")
                abort(notifyPeer = false)
                send(newKey.peer, PearMux.close(newKey.id))
                return
            }
            lastActivity = now()
            log("stream reattached")
        }

        /**
         * readLoop is done. If the server ended first: CLOSE, and wait for the companion's answer
         * before letting go. If the companion closed first, writeLoop lets go once its bytes are out.
         */
        private fun finish() {
            synchronized(lock) {
                if (closed || closeReceived) return
                if (closeSentAt == null) {
                    closeSentAt = now()
                    sendAttached(PearMux.close(key.id))
                }
            }
            socket?.let(::closeQuietly)
        }

        /**
         * The companion finished: answer, deliver what it sent, then close the server side. Or it
         * answers our CLOSE, and the stream is done.
         */
        fun onPeerClose() {
            val answersOurs = synchronized(lock) {
                if (closed || closeReceived) return
                closeReceived = true
                val ours = closeSentAt != null
                if (!ours) {
                    closeSentAt = now()
                    sendAttached(PearMux.close(key.id))
                }
                ours
            }
            if (answersOurs) return release()
            // writeLoop releases once it has written everything before it -- also when the server
            // connection is still being made: it starts draining as soon as there is one.
            toSocket.put(FIN)
        }

        /** Forgets the stream: both CLOSEs have crossed. */
        private fun release() {
            synchronized(lock) {
                if (closed) return
                closed = true
                lock.notifyAll()
            }
            cleanUp()
        }

        /** Ends the stream now, with no handshake. */
        fun abort(notifyPeer: Boolean) {
            val tell = synchronized(lock) {
                if (closed) return
                closed = true
                lock.notifyAll()
                notifyPeer && detachedAt == null && closeSentAt == null
            }
            cleanUp()
            if (tell) send(key.peer, PearMux.close(key.id))
        }

        private fun cleanUp() {
            streams.remove(key, this)
            synchronized(lock) {
                unackedTotal.addAndGet(-(sent - unackedStart))
                unacked.clear()
                unackedStart = sent
            }
            toSocket.clear()
            toSocket.put(POISON)
            socket?.let(::closeQuietly)
            log("stream closed (${streams.size} open)")
        }

        /** Sends unless detached: then the frame is lost with the connection, and resent if it matters. */
        private fun sendAttached(frame: ByteArray) {
            if (detachedAt == null) send(key.peer, frame)
        }
    }

    private val logger by lazy { DaemonLogger.getInstance(TAG) }

    /** Every log call in this class, gated by [DaemonLogConfig.PEAR_PUMP]. Never payload bytes. */
    private fun log(message: String) {
        if (DaemonLogConfig.PEAR_PUMP || DaemonLogConfig.ENABLE_ALL) logger.info(message)
    }

    private companion object {
        const val TAG = "PearStreamPump"

        /** Wakes a writer blocked in take() when its stream is aborted. Compared by identity. */
        val POISON = ByteArray(0)

        /** Queued after the companion's last bytes: write them, then close. Compared by identity. */
        val FIN = ByteArray(0)

        fun closeQuietly(s: Socket) {
            try {
                s.close()
            } catch (_: IOException) {
            }
        }

        fun connectToRemoteListener(): Socket =
            Socket(InetAddress.getByName("127.0.0.1"), HttpServer.PEAR_TLS_PORT).apply { tcpNoDelay = true }
    }
}
