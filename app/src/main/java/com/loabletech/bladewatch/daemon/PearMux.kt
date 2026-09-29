package net.bladewatch.app.daemon

import java.nio.ByteBuffer

/**
 * Stream multiplexing over ONE Pear connection (BladeWatch-rdtj.6), resumable across a reconnect
 * (BladeWatch-bbvx).
 *
 * pear-end gives each peer exactly one message channel (a Protomux `pear-connection-data`
 * channel; `connection.write` / `connection.data` over the worklet IPC), but a companion needs
 * several TCP connections to the car at once -- ConnectRPC calls, stills, clip playback. This is
 * the framing that carries them. The companion implements the same thing in Dart
 * (companion/lib/transport/pear_mux.dart); change both together.
 *
 * Protomux preserves message boundaries, so a Pear message IS a frame -- no length prefix:
 *
 *     byte 0      type:  1 OPEN, 2 DATA, 3 CLOSE, 4 WINDOW, 5 OPENED, 6 REATTACH, 7 REATTACHED
 *     bytes 1-4   stream id, u32 big-endian, chosen by the companion
 *     bytes 5..   OPEN:       one byte, the protocol version ([VERSION])
 *                 DATA:       1..[MAX_DATA] payload bytes
 *                 CLOSE:      nothing
 *                 WINDOW:     u32 credit increment (> 0), u64 bytes received on this stream so far
 *                 OPENED:     the stream's reattach token, [TOKEN_BYTES] bytes
 *                 REATTACH:   token, u64 bytes received, u64 receive limit
 *                 REATTACHED: u64 bytes received, u64 receive limit
 *
 * Only the companion opens streams; the car answers OPEN with OPENED and connects to its REMOTE
 * loopback listener. Each direction of each stream starts with [INITIAL_WINDOW] bytes of credit,
 * and the receiver sends WINDOW as it consumes: a sender never has more than a window in flight.
 * pear-end's `connection.write` ignores Protomux backpressure, so this credit is the ONLY thing
 * that stops a stream from piling up in the worklet when the peer's network is slower.
 *
 * ## Surviving a reconnect (bbvx)
 *
 * A Pear connection is reliable and ordered while it lives, so bytes are only ever lost when it
 * dies. Each side therefore keeps what it sent until WINDOW says the other side received it, and
 * when the companion finds the car again on a new connection it sends REATTACH for each stream it
 * had: the token from OPENED proves the stream is its own, and the two offsets say where to resume.
 * The car rebinds the stream to the new connection and answers REATTACHED with its own offsets;
 * both then resend from the other's received offset and set their credit from the other's limit
 * (receive limit = [INITIAL_WINDOW] plus every WINDOW credit granted so far). TLS and everything
 * above it never notice. The companion ignores DATA and WINDOW on a stream it is reattaching until
 * REATTACHED arrives: the car may still be sending into the old connection's gap.
 *
 * CLOSE is a handshake: the side that finishes first keeps its stream, and what it has not had
 * acknowledged, until the other side's CLOSE comes back, so a close lost with the connection is
 * resent after a reattach. A side receiving CLOSE delivers what it already received first.
 */
object PearMux {
    const val VERSION: Byte = 2

    const val OPEN: Byte = 1
    const val DATA: Byte = 2
    const val CLOSE: Byte = 3
    const val WINDOW: Byte = 4
    const val OPENED: Byte = 5
    const val REATTACH: Byte = 6
    const val REATTACHED: Byte = 7

    private const val HEADER = 5
    const val TOKEN_BYTES = 16

    /** Payload bytes per DATA frame: 32 KiB, ~43 KiB once pear-end's IPC base64s it. */
    const val MAX_DATA = 32 * 1024

    /** Credit each side starts with, per stream and direction. ~10 Mbit/s at a 200 ms RTT. */
    const val INITIAL_WINDOW = 256 * 1024

    class Frame(val type: Byte, val stream: Int, val payload: ByteArray) {
        private fun buf() = ByteBuffer.wrap(payload)

        /** WINDOW: the credit increment. */
        val credit: Int get() = buf().int

        /** WINDOW, REATTACH, REATTACHED: bytes the sender of this frame has received. */
        val received: Long get() = when (type) {
            WINDOW -> buf().getLong(4)
            REATTACH -> buf().getLong(TOKEN_BYTES)
            else -> buf().getLong(0)
        }

        /** REATTACH, REATTACHED: how far the sender of this frame lets the other side send. */
        val limit: Long get() = buf().getLong(if (type == REATTACH) TOKEN_BYTES + 8 else 8)

        /** OPENED, REATTACH: the stream's reattach token. */
        val token: ByteArray get() = payload.copyOfRange(0, TOKEN_BYTES)
    }

    fun open(stream: Int): ByteArray = encode(OPEN, stream, byteArrayOf(VERSION))

    fun data(stream: Int, bytes: ByteArray, offset: Int = 0, length: Int = bytes.size): ByteArray {
        require(length in 1..MAX_DATA) { "DATA payload must be 1..$MAX_DATA bytes, was $length" }
        return encode(DATA, stream, bytes.copyOfRange(offset, offset + length))
    }

    fun close(stream: Int): ByteArray = encode(CLOSE, stream, ByteArray(0))

    fun window(stream: Int, credit: Int, received: Long): ByteArray {
        require(credit > 0) { "WINDOW credit must be positive" }
        return encode(WINDOW, stream, ByteBuffer.allocate(12).putInt(credit).putLong(received).array())
    }

    fun opened(stream: Int, token: ByteArray): ByteArray {
        require(token.size == TOKEN_BYTES)
        return encode(OPENED, stream, token)
    }

    fun reattach(stream: Int, token: ByteArray, received: Long, limit: Long): ByteArray {
        require(token.size == TOKEN_BYTES)
        return encode(REATTACH, stream, ByteBuffer.allocate(TOKEN_BYTES + 16).put(token).putLong(received).putLong(limit).array())
    }

    fun reattached(stream: Int, received: Long, limit: Long): ByteArray =
        encode(REATTACHED, stream, ByteBuffer.allocate(16).putLong(received).putLong(limit).array())

    /**
     * Parses one message, or null when it is not a well-formed frame. Malformed input comes from
     * the far side of the internet, so it is a value to discard, never an exception to throw.
     */
    fun decode(message: ByteArray): Frame? {
        if (message.size < HEADER) return null
        val type = message[0]
        val stream = ByteBuffer.wrap(message, 1, 4).int
        val payload = message.copyOfRange(HEADER, message.size)
        val p = ByteBuffer.wrap(payload)
        val ok = when (type) {
            OPEN -> payload.size == 1
            DATA -> payload.size in 1..MAX_DATA
            CLOSE -> payload.isEmpty()
            WINDOW -> payload.size == 12 && p.getInt(0) > 0 && p.getLong(4) >= 0
            OPENED -> payload.size == TOKEN_BYTES
            REATTACH -> payload.size == TOKEN_BYTES + 16 && p.getLong(TOKEN_BYTES) >= 0 && p.getLong(TOKEN_BYTES + 8) >= 0
            REATTACHED -> payload.size == 16 && p.getLong(0) >= 0 && p.getLong(8) >= 0
            else -> false
        }
        return if (ok) Frame(type, stream, payload) else null
    }

    private fun encode(type: Byte, stream: Int, payload: ByteArray): ByteArray =
        ByteBuffer.allocate(HEADER + payload.size).put(type).putInt(stream).put(payload).array()
}
