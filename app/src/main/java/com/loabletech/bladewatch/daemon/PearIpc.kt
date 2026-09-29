package net.bladewatch.app.daemon

import java.nio.ByteBuffer

/**
 * Wire codec for the BareKit IPC pipe between [PearDaemon] and pear-end, the stock flutter_pear
 * worklet bundle.
 *
 * Read straight out of pear-end/index.js (`writeFramed` and its `IPC.on('data')` accumulator) and
 * schema.js (`FrameType`): every frame is a 4-byte big-endian length, then a 1-byte frame type,
 * then the body. A JSON frame's body is one UTF-8 object -- `{"id","m","p"}` requests in,
 * `{"id","ok"|"err"}` responses and `{"ev","p"}` events out.
 *
 * `IPC.read` hands over whatever chunk the pipe had, so a frame can arrive split across reads and
 * several can arrive in one; [FrameDecoder] buffers until each is whole. pear-end does the same on
 * its side for the same reason: it once saw five back-to-back frames coalesce into one delivery.
 */
object PearIpc {
    const val FRAME_JSON: Byte = 0x00

    /**
     * Largest frame accepted from the worklet. `connection.data` frames carry bytes a remote peer
     * sent, so the length prefix is peer-influenced -- without a cap, one hostile length would make
     * this daemon buffer until the head unit runs out of memory. Far above any legitimate frame.
     */
    const val MAX_FRAME_BYTES = 16 * 1024 * 1024

    fun encodeJson(json: String): ByteArray {
        val body = json.toByteArray(Charsets.UTF_8)
        return ByteBuffer.allocate(4 + 1 + body.size)
            .putInt(1 + body.size)
            .put(FRAME_JSON)
            .put(body)
            .array()
    }

    class Frame(val type: Byte, val body: ByteArray) {
        fun text(): String = String(body, Charsets.UTF_8)
    }

    class FrameDecoder {
        // Growable, not copy-on-append: a large frame arriving in many small reads would otherwise
        // recopy everything buffered so far on every read.
        private var buf = ByteArray(64 * 1024)
        private var size = 0

        /**
         * Buffers [chunk] and returns every frame it completed, in order.
         *
         * @throws IllegalArgumentException on a length no valid frame can have. The stream cannot be
         *   resynchronised after that, so the caller must drop the connection, not skip the frame.
         */
        fun feed(chunk: ByteArray): List<Frame> {
            if (size + chunk.size > buf.size) {
                buf = buf.copyOf(maxOf(buf.size * 2, size + chunk.size))
            }
            System.arraycopy(chunk, 0, buf, size, chunk.size)
            size += chunk.size

            val frames = ArrayList<Frame>()
            var off = 0
            while (size - off >= 4) {
                val len = ByteBuffer.wrap(buf, off, 4).int
                // Every frame carries at least its type byte, so 0 is as invalid as a negative.
                require(len in 1..MAX_FRAME_BYTES) { "invalid frame length $len" }
                if (size - off - 4 < len) break // the rest of this frame is still in flight
                frames += Frame(buf[off + 4], buf.copyOfRange(off + 5, off + 4 + len))
                off += 4 + len
            }
            if (off > 0) {
                System.arraycopy(buf, off, buf, 0, size - off)
                size -= off
            }
            return frames
        }
    }
}
