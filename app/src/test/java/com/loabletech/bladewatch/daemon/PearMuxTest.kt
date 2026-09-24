package net.bladewatch.app.daemon

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
import org.junit.Test

/**
 * BladeWatch-rdtj.6: the wire format the companion (BladeWatch-rdtj.8) must speak byte for byte.
 * The exact bytes are pinned, not just the round trip, so a change here fails loudly instead of
 * silently breaking every paired companion.
 */
class PearMuxTest {

    @Test
    fun `frames have the documented layout`() {
        assertArrayEquals(byteArrayOf(1, 0, 0, 0, 7, 1), PearMux.open(7))
        assertArrayEquals(byteArrayOf(2, 0, 0, 1, 0, 'h'.code.toByte(), 'i'.code.toByte()), PearMux.data(256, "hi".toByteArray()))
        assertArrayEquals(byteArrayOf(3, 0x7f, -1, -1, -1), PearMux.close(Int.MAX_VALUE))
        assertArrayEquals(byteArrayOf(4, 0, 0, 0, 2, 0, 1, 0, 0), PearMux.window(2, 65_536))
    }

    @Test
    fun `every frame round-trips`() {
        val data = PearMux.decode(PearMux.data(5, byteArrayOf(9, 8, 7)))!!
        assertEquals(PearMux.DATA, data.type)
        assertEquals(5, data.stream)
        assertArrayEquals(byteArrayOf(9, 8, 7), data.payload)
        assertEquals(1_234, PearMux.credit(PearMux.decode(PearMux.window(5, 1_234))!!))
        assertEquals(PearMux.VERSION, PearMux.decode(PearMux.open(5))!!.payload[0])
        assertEquals(PearMux.CLOSE, PearMux.decode(PearMux.close(5))!!.type)
    }

    @Test
    fun `malformed frames decode to null instead of throwing`() {
        assertNull(PearMux.decode(byteArrayOf()))
        assertNull(PearMux.decode(byteArrayOf(2, 0, 0, 0, 1))) // DATA with no payload
        assertNull(PearMux.decode(byteArrayOf(4, 0, 0, 0, 1, 0, 0, 0, 0))) // zero credit
        assertNull(PearMux.decode(byteArrayOf(4, 0, 0, 0, 1, -1, -1, -1, -1))) // negative credit
        assertNull(PearMux.decode(byteArrayOf(3, 0, 0, 0, 1, 0))) // CLOSE with a payload
        assertNull(PearMux.decode(byteArrayOf(9, 0, 0, 0, 1))) // unknown type
        assertNull(PearMux.decode(ByteArray(5 + PearMux.MAX_DATA + 1).also { it[0] = PearMux.DATA }))
    }

    @Test
    fun `oversized or empty DATA is refused at encode time`() {
        assertThrows(IllegalArgumentException::class.java) { PearMux.data(1, ByteArray(0)) }
        assertThrows(IllegalArgumentException::class.java) { PearMux.data(1, ByteArray(PearMux.MAX_DATA + 1)) }
        assertThrows(IllegalArgumentException::class.java) { PearMux.window(1, 0) }
    }
}
