package net.bladewatch.app.streaming

import android.media.MediaCodec

import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.surveillance.HardwareEventRecorderGpu

import org.java_websocket.WebSocket
import org.java_websocket.handshake.ClientHandshake
import org.java_websocket.server.WebSocketServer

import java.net.InetAddress
import java.net.InetSocketAddress
import java.nio.ByteBuffer
import java.util.Collections
import java.util.Timer
import java.util.TimerTask
import java.util.concurrent.ConcurrentHashMap

class WebSocketStreamServer @JvmOverloads constructor(
    private val port: Int = PORT
) : WebSocketServer(loopbackAddress(port)), HardwareEventRecorderGpu.StreamCallback {

    /** Cached SPS/PPS for late-joining clients. */
    @Volatile
    var cachedSpsPps: ByteArray? = null
        private set

    private val clients: MutableSet<WebSocket> =
        Collections.newSetFromMap(ConcurrentHashMap<WebSocket, Boolean>())

    private var idleTimer: Timer? = null

    @Volatile
    private var lastClientDisconnectTime: Long = 0

    @Volatile
    private var idleShutdownTriggered = false

    private var idleShutdownCallback: Runnable? = null
    private var frameCount: Long = 0
    private var lastLogTime: Long = 0

    /** Track external clients (e.g., from HttpServer /ws path) */
    @Volatile
    private var externalClientCount = 0

    // SOTA FIX: Reusable frame buffer to eliminate GC pressure
    // H.264 frames are typically 50-200KB, allocate 512KB to handle spikes
    private var reusableFrameBuffer = ByteArray(512 * 1024)

    init {
        isReuseAddr = true
        connectionLostTimeout = 30
        logger.info("WebSocketStreamServer created on 127.0.0.1:$port")
    }

    fun setIdleShutdownCallback(callback: Runnable?) {
        idleShutdownCallback = callback
    }

    /**
     * Register an external client (e.g., from HttpServer /ws path).
     * This prevents idle timeout while external clients are connected.
     */
    @Synchronized
    fun registerExternalClient() {
        externalClientCount++
        cancelIdleTimer()
        logger.info("External client registered (total: $externalClientCount)")
    }

    /** Unregister an external client. */
    @Synchronized
    fun unregisterExternalClient() {
        externalClientCount = maxOf(0, externalClientCount - 1)
        logger.info("External client unregistered (remaining: $externalClientCount)")
        if (clients.isEmpty() && externalClientCount == 0) {
            lastClientDisconnectTime = System.currentTimeMillis()
            startIdleTimer()
        }
    }

    /**
     * A still-frame viewer is watching (`GET /api/stream/still`): the companion's live view
     * (BladeWatch-rdtj.11) and the web's still tier. It holds no WebSocket, so without this it
     * would count as nobody watching and streaming would idle out under it after
     * [IDLE_TIMEOUT_MS] -- the still would go 503 every half minute. Each request pushes the idle
     * deadline forward instead, so streaming lasts exactly as long as someone keeps looking.
     */
    fun noteStillViewer() {
        lastClientDisconnectTime = System.currentTimeMillis()
    }

    /** Check if there are any active clients (internal or external). */
    fun hasActiveClients(): Boolean = clients.isNotEmpty() || externalClientCount > 0

    override fun onOpen(conn: WebSocket, handshake: ClientHandshake) {
        clients.add(conn)
        logger.info(
            "WS Client connected: " + conn.remoteSocketAddress +
                " (total: " + clients.size + ")"
        )
        cancelIdleTimer()
        idleShutdownTriggered = false
        val spsPps = cachedSpsPps
        if (spsPps != null) {
            try {
                conn.send(spsPps)
                logger.info("Sent cached SPS/PPS (" + spsPps.size + " bytes)")
            } catch (e: Exception) {
                logger.error("Failed to send SPS/PPS", e)
            }
        }
    }

    override fun onClose(conn: WebSocket, code: Int, reason: String?, remote: Boolean) {
        clients.remove(conn)
        logger.info("WS Client disconnected (remaining: " + clients.size + ")")
        if (clients.isEmpty()) {
            lastClientDisconnectTime = System.currentTimeMillis()
            startIdleTimer()
        }
    }

    override fun onMessage(conn: WebSocket, message: String) {
        if ("keyframe" == message) {
            logger.info("Client requested keyframe")
        }
    }

    override fun onMessage(conn: WebSocket, message: ByteBuffer) {}

    override fun onError(conn: WebSocket?, ex: Exception) {
        if (conn != null) {
            clients.remove(conn)
            logger.error("WS Error: " + ex.message)
            if (clients.isEmpty()) {
                lastClientDisconnectTime = System.currentTimeMillis()
                startIdleTimer()
            }
        } else {
            logger.error("WS Server error: " + ex.message)
        }
    }

    override fun onStart() {
        logger.info("WebSocket Stream Server started on port $port")
        lastClientDisconnectTime = System.currentTimeMillis()
        startIdleTimer()
    }

    @Synchronized
    private fun startIdleTimer() {
        cancelIdleTimer()
        val timer = Timer("WS-IdleTimer", true)
        idleTimer = timer
        timer.schedule(
            object : TimerTask() {
                override fun run() {
                    checkIdleTimeout()
                }
            },
            IDLE_TIMEOUT_MS, 5000
        )
        logger.info("Idle timer started - shutdown after " + (IDLE_TIMEOUT_MS / 1000) + "s")
    }

    @Synchronized
    private fun cancelIdleTimer() {
        idleTimer?.cancel()
        idleTimer = null
    }

    @Synchronized
    private fun checkIdleTimeout() {
        if (clients.isNotEmpty() || externalClientCount > 0) {
            cancelIdleTimer()
            return
        }
        val idleTime = System.currentTimeMillis() - lastClientDisconnectTime
        if (idleTime >= IDLE_TIMEOUT_MS && !idleShutdownTriggered) {
            idleShutdownTriggered = true
            logger.info("Idle timeout (" + (idleTime / 1000) + "s) - triggering shutdown")
            cancelIdleTimer()
            idleShutdownCallback?.let {
                try {
                    it.run()
                } catch (e: Exception) {
                    logger.error("Idle shutdown callback error", e)
                }
            }
        }
    }

    override fun onSpsPps(sps: ByteBuffer, pps: ByteBuffer) {
        val spsSize = sps.remaining()
        val ppsSize = pps.remaining()
        val buf = ByteArray(spsSize + ppsSize)
        sps.get(buf, 0, spsSize)
        pps.get(buf, spsSize, ppsSize)
        cachedSpsPps = buf
        logger.info("Cached SPS/PPS: $spsSize + $ppsSize bytes")
        sendToAll(buf)
    }

    override fun onH264Packet(data: ByteBuffer, info: MediaCodec.BufferInfo) {
        if (clients.isEmpty()) return

        // SOTA FIX: Reuse buffer instead of allocating new byte[] per frame
        // This eliminates ~1.5MB/sec of GC pressure at 15 FPS
        val frameSize = info.size
        if (frameSize > reusableFrameBuffer.size) {
            // Rare case: frame larger than buffer, resize once
            reusableFrameBuffer = ByteArray(frameSize * 2)
            logger.warn("Resized frame buffer to " + reusableFrameBuffer.size + " bytes")
        }

        data.position(info.offset)
        data.get(reusableFrameBuffer, 0, frameSize)

        // Send to all clients (they copy internally)
        sendToAll(reusableFrameBuffer, frameSize)

        frameCount++
        val now = System.currentTimeMillis()
        if (now - lastLogTime > 10000) {
            logger.info("Stats: " + frameCount + " frames, " + clients.size + " clients")
            lastLogTime = now
        }
    }

    private fun sendToAll(data: ByteArray, length: Int = data.size) {
        for (conn in clients) {
            try {
                if (conn.isOpen) {
                    // WebSocket library copies data internally, safe to reuse buffer
                    conn.send(ByteBuffer.wrap(data, 0, length))
                } else {
                    clients.remove(conn)
                }
            } catch (e: Exception) {
                logger.warn(
                    "Failed to send frame to client " + conn.remoteSocketAddress +
                        ": " + e.message
                )
                clients.remove(conn)
            }
        }
    }

    fun getClientCount(): Int = clients.size

    fun hasClients(): Boolean = clients.isNotEmpty()

    fun shutdown() {
        try {
            cancelIdleTimer()
            for (conn in clients) {
                try {
                    conn.close()
                } catch (e: Exception) {
                    logger.warn("Failed to close WebSocket: " + e.message)
                }
            }
            clients.clear()
            cachedSpsPps = null
            frameCount = 0
            stop(1000)
            logger.info("WebSocket Stream Server stopped")
        } catch (e: Exception) {
            logger.error("Error stopping server", e)
        }
    }

    companion object {
        private const val TAG = "WSStreamServer"
        private val logger = DaemonLogger.getInstance(TAG)
        private const val PORT = 8887
        private const val IDLE_TIMEOUT_MS = 30_000L

        private fun loopbackAddress(port: Int): InetSocketAddress = try {
            InetSocketAddress(InetAddress.getByName("127.0.0.1"), port)
        } catch (e: Exception) {
            // Unreachable — "127.0.0.1" is always resolvable
            InetSocketAddress(port)
        }
    }
}
