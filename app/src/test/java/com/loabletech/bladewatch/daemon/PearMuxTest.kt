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
        assertArrayEquals(byteArrayOf(1, 0, 0, 0, 7, 2), PearMux.open(7))
        assertArrayEquals(byteArrayOf(2, 0, 0, 1, 0, 'h'.code.toByte(), 'i'.code.toByte()), PearMux.data(256, "hi".toByteArray()))
        assertArrayEquals(byteArrayOf(3, 0x7f, -1, -1, -1), PearMux.close(Int.MAX_VALUE))
        assertArrayEquals(
            byteArrayOf(4, 0, 0, 0, 2, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0),
            PearMux.window(2, 65_536, 256),
        )
        val token = ByteArray(16) { it.toByte() }
        assertArrayEquals(byteArrayOf(5, 0, 0, 0, 3) + token, PearMux.opened(3, token))
        assertArrayEquals(
            byteArrayOf(6, 0, 0, 0, 3) + token + byteArrayOf(0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 4, 0, 0),
            PearMux.reattach(3, token, 9, 262_144),
        )
        assertArrayEquals(
            byteArrayOf(7, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 4, 0, 0),
            PearMux.reattached(3, 9, 262_144),
        )
    }

    @Test
    fun `every frame round-trips`() {
        val data = PearMux.decode(PearMux.data(5, byteArrayOf(9, 8, 7)))!!
        assertEquals(PearMux.DATA, data.type)
        assertEquals(5, data.stream)
        assertArrayEquals(byteArrayOf(9, 8, 7), data.payload)
        val window = PearMux.decode(PearMux.window(5, 1_234, 5_000_000_000))!!
        assertEquals(1_234, window.credit)
        assertEquals(5_000_000_000, window.received)
        val token = ByteArray(16) { (it * 3).toByte() }
        assertArrayEquals(token, PearMux.decode(PearMux.opened(5, token))!!.token)
        val reattach = PearMux.decode(PearMux.reattach(5, token, 7, 8))!!
        assertArrayEquals(token, reattach.token)
        assertEquals(7L, reattach.received)
        assertEquals(8L, reattach.limit)
        val reattached = PearMux.decode(PearMux.reattached(5, 70, 80))!!
        assertEquals(70L, reattached.received)
        assertEquals(80L, reattached.limit)
        assertEquals(PearMux.VERSION, PearMux.decode(PearMux.open(5))!!.payload[0])
        assertEquals(PearMux.CLOSE, PearMux.decode(PearMux.close(5))!!.type)
    }

    @Test
    fun `malformed frames decode to null instead of throwing`() {
        assertNull(PearMux.decode(byteArrayOf()))
        assertNull(PearMux.decode(byteArrayOf(2, 0, 0, 0, 1))) // DATA with no payload
        assertNull(PearMux.decode(byteArrayOf(4, 0, 0, 0, 1) + ByteArray(12))) // zero credit
        assertNull(PearMux.decode(byteArrayOf(4, 0, 0, 0, 1, -1, -1, -1, -1) + ByteArray(8))) // negative credit
        assertNull(PearMux.decode(byteArrayOf(4, 0, 0, 0, 1, 0, 0, 0, 1) + ByteArray(8) { -1 })) // negative received
        assertNull(PearMux.decode(byteArrayOf(4, 0, 0, 0, 1, 0, 1, 0, 0))) // a v1 WINDOW
        assertNull(PearMux.decode(byteArrayOf(5, 0, 0, 0, 1) + ByteArray(15))) // short token
        assertNull(PearMux.decode(byteArrayOf(6, 0, 0, 0, 1) + ByteArray(31))) // short REATTACH
        assertNull(PearMux.decode(byteArrayOf(6, 0, 0, 0, 1) + ByteArray(24) + ByteArray(8) { -1 })) // negative limit
        assertNull(PearMux.decode(byteArrayOf(7, 0, 0, 0, 1) + ByteArray(15))) // short REATTACHED
        assertNull(PearMux.decode(byteArrayOf(3, 0, 0, 0, 1, 0))) // CLOSE with a payload
        assertNull(PearMux.decode(byteArrayOf(9, 0, 0, 0, 1))) // unknown type
        assertNull(PearMux.decode(ByteArray(5 + PearMux.MAX_DATA + 1).also { it[0] = PearMux.DATA }))
    }

    @Test
    fun `oversized or empty DATA is refused at encode time`() {
        assertThrows(IllegalArgumentException::class.java) { PearMux.data(1, ByteArray(0)) }
        assertThrows(IllegalArgumentException::class.java) { PearMux.data(1, ByteArray(PearMux.MAX_DATA + 1)) }
        assertThrows(IllegalArgumentException::class.java) { PearMux.window(1, 0, 0) }
        assertThrows(IllegalArgumentException::class.java) { PearMux.opened(1, ByteArray(15)) }
    }
}
