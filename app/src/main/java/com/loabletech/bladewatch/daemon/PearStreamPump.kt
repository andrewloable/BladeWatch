package net.bladewatch.app.daemon

import java.io.IOException
import java.net.InetAddress
import java.net.Socket
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.LinkedBlockingQueue
import net.bladewatch.app.logging.DaemonLogConfig
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.server.HttpServer

/**
 * The car side of the Pear transport (BladeWatch-rdtj.6): every stream a companion opens over its
 * Pear connection ([PearMux]) becomes a TCP connection to the HTTP server, and bytes are copied
 * both ways until either end closes. Opaque bytes -- no HTTP parsing -- so ConnectRPC, the
 * WebSocket live view and everything else work over Pear exactly as they do over any socket.
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
 *  - TLS, because Pear's own encryption authenticates nothing anyone pinned: pear-end's key pair is
 *    random per start. The companion runs TLS through the stream to this listener and checks the
 *    certificate against its pairing pin, so a peer that merely knows the topic can neither pose as
 *    the car nor read a relayed session (owner's decision, BladeWatch-rdtj.8). The pump stays
 *    opaque: it moves TLS records it cannot read.
 *
 * ## Limits
 *
 * Anyone who knows the car's topic can connect, so every resource is capped: streams per peer and
 * in total, a connect deadline (byd_cam_daemon may be restarting), an idle timeout, and per-stream
 * credit ([PearMux.INITIAL_WINDOW]) in both directions -- a peer that overruns its credit loses the
 * stream, and a stream never reads from its socket faster than the peer grants. Two threads per
 * stream (one blocked on each side), so the thread count is bounded by the stream cap.
 *
 * Payload bytes are never logged: they carry JWTs and video.
 */
class PearStreamPump(
    /** Delivers one message to [peer] over Pear. Must be safe to call from any thread. */
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
    )

    private data class Key(val peer: String, val id: Int)

    private val streams = ConcurrentHashMap<Key, Stream>()

    val openStreams: Int get() = streams.size

    /** One Pear message from [peer]. Called on the worklet IPC thread, never concurrently. */
    fun onMessage(peer: String, message: ByteArray) {
        val frame = PearMux.decode(message) ?: return log("discarded a malformed frame")
        val key = Key(peer, frame.stream)
        when (frame.type) {
            PearMux.OPEN -> open(key, frame)
            PearMux.DATA -> streams[key]?.receive(frame.payload)
            PearMux.WINDOW -> streams[key]?.grant(PearMux.credit(frame))
            PearMux.CLOSE -> streams[key]?.close(notifyPeer = false)
        }
    }

    /** The Pear connection itself is gone: nothing can be sent to [peer] any more. */
    fun onPeerClosed(peer: String) {
        streams.values.filter { it.key.peer == peer }.forEach { it.close(notifyPeer = false) }
    }

    /** Closes streams with no traffic either way for [Limits.idleTimeoutMs]. Call periodically. */
    fun sweepIdle() {
        val cutoff = now() - limits.idleTimeoutMs
        streams.values.filter { it.lastActivity < cutoff }.forEach { it.close(notifyPeer = true) }
    }

    fun shutdown() = streams.values.forEach { it.close(notifyPeer = true) }

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
        val stream = Stream(key)
        streams[key] = stream
        Thread({ stream.run() }, "pear-pump-r").apply { isDaemon = true }.start()
    }

    private inner class Stream(val key: Key) {
        @Volatile var lastActivity: Long = now()
        @Volatile private var closed = false
        @Volatile private var socket: Socket? = null
        private val lock = Object()
        private var sendCredit = limits.window     // guarded by lock: bytes we may still send
        private var recvAllowance = limits.window  // guarded by lock: bytes the peer may still send
        private val toSocket = LinkedBlockingQueue<ByteArray>()

        fun run() {
            val s = connectWithRetry() ?: return close(notifyPeer = true)
            socket = s
            if (closed) return closeQuietly(s) // closed while connecting; close() may have missed it
            Thread({ writeLoop(s) }, "pear-pump-w").apply { isDaemon = true }.start()
            readLoop(s)
        }

        /** byd_cam_daemon may be starting or restarting: retry, with backoff, until the deadline. */
        private fun connectWithRetry(): Socket? {
            val deadline = System.nanoTime() + limits.connectDeadlineMs * 1_000_000
            var backoffMs = 50L
            while (!closed) {
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

        /** Server -> peer, never faster than the peer's credit allows. */
        private fun readLoop(s: Socket) {
            val buf = ByteArray(PearMux.MAX_DATA)
            try {
                val input = s.getInputStream()
                while (true) {
                    val allowed = awaitCredit()
                    if (allowed == 0) break // closed
                    val n = input.read(buf, 0, allowed)
                    if (n < 0) break // the server finished
                    synchronized(lock) { sendCredit -= n }
                    lastActivity = now()
                    send(key.peer, PearMux.data(key.id, buf, 0, n))
                }
            } catch (e: IOException) {
                // The socket was closed under us, or the server went away: both end the stream.
            }
            close(notifyPeer = true)
        }

        private fun awaitCredit(): Int = synchronized(lock) {
            while (sendCredit <= 0 && !closed) lock.wait()
            if (closed) 0 else minOf(sendCredit, PearMux.MAX_DATA)
        }

        /** Peer -> server. Grants credit back only once bytes have actually left for the server. */
        private fun writeLoop(s: Socket) {
            var consumed = 0
            try {
                val out = s.getOutputStream()
                while (true) {
                    val chunk = toSocket.take()
                    if (chunk === POISON) break
                    out.write(chunk)
                    lastActivity = now()
                    consumed += chunk.size
                    if (consumed >= limits.window / 4 || toSocket.isEmpty()) {
                        synchronized(lock) { recvAllowance += consumed }
                        send(key.peer, PearMux.window(key.id, consumed))
                        consumed = 0
                    }
                }
            } catch (e: IOException) {
                close(notifyPeer = true)
            }
        }

        fun receive(bytes: ByteArray) {
            val overran = synchronized(lock) {
                if (bytes.size > recvAllowance) true else {
                    recvAllowance -= bytes.size
                    false
                }
            }
            if (overran) {
                log("a peer overran its credit; closing the stream")
                return close(notifyPeer = true)
            }
            lastActivity = now()
            toSocket.put(bytes) // bounded by recvAllowance: at most one window queued
        }

        fun grant(credit: Int) {
            synchronized(lock) {
                sendCredit = (sendCredit.toLong() + credit).coerceAtMost(Int.MAX_VALUE.toLong()).toInt()
                lock.notifyAll()
            }
            lastActivity = now()
        }

        fun close(notifyPeer: Boolean) {
            synchronized(lock) {
                if (closed) return
                closed = true
                lock.notifyAll()
            }
            streams.remove(key, this)
            toSocket.clear()
            toSocket.put(POISON)
            socket?.let(::closeQuietly)
            if (notifyPeer) send(key.peer, PearMux.close(key.id))
            log("stream closed (${streams.size} open)")
        }
    }

    private val logger by lazy { DaemonLogger.getInstance(TAG) }

    /** Every log call in this class, gated by [DaemonLogConfig.PEAR_PUMP]. Never payload bytes. */
    private fun log(message: String) {
        if (DaemonLogConfig.PEAR_PUMP || DaemonLogConfig.ENABLE_ALL) logger.info(message)
    }

    private companion object {
        const val TAG = "PearStreamPump"

        /** Wakes a writer blocked in take() when its stream closes. Compared by identity. */
        val POISON = ByteArray(0)

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
