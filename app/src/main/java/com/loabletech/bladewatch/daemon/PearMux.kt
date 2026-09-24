package net.bladewatch.app.daemon

import java.nio.ByteBuffer

/**
 * Stream multiplexing over ONE Pear connection (BladeWatch-rdtj.6).
 *
 * pear-end gives each peer exactly one message channel (a Protomux `pear-connection-data`
 * channel; `connection.write` / `connection.data` over the worklet IPC), but a companion needs
 * several TCP connections to the car at once -- the live-view WebSocket, ConnectRPC calls,
 * thumbnails. This is the framing that carries them. The companion implements the same thing in
 * Dart (BladeWatch-rdtj.8); change both together.
 *
 * Protomux preserves message boundaries, so a Pear message IS a frame -- no length prefix:
 *
 *     byte 0      type:  1 OPEN, 2 DATA, 3 CLOSE, 4 WINDOW
 *     bytes 1-4   stream id, u32 big-endian, chosen by whoever opens the stream
 *     bytes 5..   OPEN:   one byte, the protocol version ([VERSION])
 *                 DATA:   1..[MAX_DATA] payload bytes
 *                 CLOSE:  nothing
 *                 WINDOW: u32 big-endian credit increment, > 0
 *
 * Only the companion opens streams; the car answers OPEN by connecting to its REMOTE loopback
 * listener and never opens a stream itself. Each direction of each stream starts with
 * [INITIAL_WINDOW] bytes of credit, and the receiver sends WINDOW as it consumes: a sender never
 * has more than a window of unacknowledged data in flight. pear-end's `connection.write` ignores
 * Protomux backpressure, so this credit is the ONLY thing that stops a live video stream from
 * piling up in the worklet when the peer's network is slower than the camera.
 */
object PearMux {
    const val VERSION: Byte = 1

    const val OPEN: Byte = 1
    const val DATA: Byte = 2
    const val CLOSE: Byte = 3
    const val WINDOW: Byte = 4

    private const val HEADER = 5

    /** Payload bytes per DATA frame: 32 KiB, ~43 KiB once pear-end's IPC base64s it. */
    const val MAX_DATA = 32 * 1024

    /** Credit each side starts with, per stream and direction. ~10 Mbit/s at a 200 ms RTT. */
    const val INITIAL_WINDOW = 256 * 1024

    class Frame(val type: Byte, val stream: Int, val payload: ByteArray)

    fun open(stream: Int): ByteArray = encode(OPEN, stream, byteArrayOf(VERSION))

    fun data(stream: Int, bytes: ByteArray, offset: Int = 0, length: Int = bytes.size): ByteArray {
        require(length in 1..MAX_DATA) { "DATA payload must be 1..$MAX_DATA bytes, was $length" }
        return encode(DATA, stream, bytes.copyOfRange(offset, offset + length))
    }

    fun close(stream: Int): ByteArray = encode(CLOSE, stream, ByteArray(0))

    fun window(stream: Int, credit: Int): ByteArray {
        require(credit > 0) { "WINDOW credit must be positive" }
        return encode(WINDOW, stream, ByteBuffer.allocate(4).putInt(credit).array())
    }

    /** The credit a WINDOW frame carries. */
    fun credit(frame: Frame): Int = ByteBuffer.wrap(frame.payload).int

    /**
     * Parses one message, or null when it is not a well-formed frame. Malformed input comes from
     * the far side of the internet, so it is a value to discard, never an exception to throw.
     */
    fun decode(message: ByteArray): Frame? {
        if (message.size < HEADER) return null
        val type = message[0]
        val stream = ByteBuffer.wrap(message, 1, 4).int
        val payload = message.copyOfRange(HEADER, message.size)
        val ok = when (type) {
            OPEN -> payload.size == 1
            DATA -> payload.size in 1..MAX_DATA
            CLOSE -> payload.isEmpty()
            WINDOW -> payload.size == 4 && ByteBuffer.wrap(payload).int > 0
            else -> false
        }
        return if (ok) Frame(type, stream, payload) else null
    }

    private fun encode(type: Byte, stream: Int, payload: ByteArray): ByteArray =
        ByteBuffer.allocate(HEADER + payload.size).put(type).putInt(stream).put(payload).array()
}
