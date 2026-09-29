package net.bladewatch.app.daemon

import java.nio.ByteBuffer
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-rdtj.3: the BareKit IPC wire codec. IPC.read delivers whatever chunk the pipe had,
 * so the decoder is only correct if frame boundaries can fall anywhere -- pear-end hit exactly
 * this when five back-to-back frames arrived as one delivery.
 */
class PearIpcTest {

    private fun frames(vararg json: String) = json.map(PearIpc::encodeJson)
        .fold(ByteArray(0)) { acc, f -> acc + f }

    @Test
    fun `encodes the length prefix, JSON type byte and UTF-8 body pear-end expects`() {
        val encoded = PearIpc.encodeJson("""{"id":1}""")
        assertEquals(1 + 8, ByteBuffer.wrap(encoded, 0, 4).int) // type byte + body
        assertEquals(PearIpc.FRAME_JSON, encoded[4])
        assertEquals("""{"id":1}""", String(encoded, 5, encoded.size - 5, Charsets.UTF_8))
    }

    @Test
    fun `decodes several frames delivered in one chunk`() {
        val out = PearIpc.FrameDecoder().feed(frames("""{"a":1}""", """{"b":2}""", """{"c":3}"""))
        assertEquals(listOf("""{"a":1}""", """{"b":2}""", """{"c":3}"""), out.map { it.text() })
    }

    @Test
    fun `reassembles a frame split at every possible byte`() {
        val wire = frames("""{"ev":"swarm.lifecycle","p":{"state":"connected"}}""")
        for (cut in 1 until wire.size) {
            val decoder = PearIpc.FrameDecoder()
            val first = decoder.feed(wire.copyOfRange(0, cut))
            val second = decoder.feed(wire.copyOfRange(cut, wire.size))
            assertTrue("nothing may emit before the frame is whole (cut=$cut)", first.isEmpty())
            assertEquals("cut=$cut", 1, second.size)
        }
    }

    @Test
    fun `handles a frame that finishes mid-chunk and the next one starting there`() {
        val wire = frames("""{"a":1}""", """{"b":2}""")
        val decoder = PearIpc.FrameDecoder()
        val cut = PearIpc.encodeJson("""{"a":1}""").size + 3 // first frame whole, 3 bytes of second
        assertEquals(listOf("""{"a":1}"""), decoder.feed(wire.copyOfRange(0, cut)).map { it.text() })
        assertEquals(listOf("""{"b":2}"""), decoder.feed(wire.copyOfRange(cut, wire.size)).map { it.text() })
    }

    @Test
    fun `survives a frame larger than its initial buffer`() {
        val big = "\"" + "x".repeat(200_000) + "\""
        val decoder = PearIpc.FrameDecoder()
        val wire = PearIpc.encodeJson(big)
        // Dribbled in, as a large connection.data frame really arrives.
        val out = wire.toList().chunked(4096).flatMap { decoder.feed(it.toByteArray()) }
        assertEquals(listOf(big), out.map { it.text() })
    }

    @Test
    fun `rejects a zero-length frame instead of misreading the next one`() {
        assertThrows(IllegalArgumentException::class.java) {
            PearIpc.FrameDecoder().feed(byteArrayOf(0, 0, 0, 0))
        }
    }

    @Test
    fun `rejects an oversized length instead of buffering toward it`() {
        // connection.data carries peer-sent bytes, so this length is peer-influenced; honouring it
        // would buffer until the head unit ran out of memory.
        val huge = ByteBuffer.allocate(4).putInt(PearIpc.MAX_FRAME_BYTES + 1).array()
        assertThrows(IllegalArgumentException::class.java) { PearIpc.FrameDecoder().feed(huge) }
    }
}
