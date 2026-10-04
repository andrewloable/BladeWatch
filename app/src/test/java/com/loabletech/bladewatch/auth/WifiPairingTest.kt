package net.bladewatch.app.auth

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

/** BladeWatch 1.4.1.2: pairing a device with no camera over the car's Wi-Fi with a matching number. */
class WifiPairingTest {

    private var clock = 1_000L
    private val pairing = WifiPairing(now = { clock })
    private val deviceNonce = ByteArray(32) { it.toByte() }
    private val commitment = WifiPairing.sha256(deviceNonce)
    private val fp = "a".repeat(64)
    private var minted = 0
    private val payload = CompanionPairing.Payload("byd-test", "t".repeat(64), 8443, fp, "k".repeat(64), "code", 0)
    private val mint: () -> CompanionPairing.Payload = { minted++; payload }

    /** Up to the owner's decision: a started, revealed request. */
    private fun revealed(): WifiPairing.Started {
        pairing.window(true)
        val started = pairing.start("Living room TV", commitment)!!
        assertTrue(pairing.reveal(started.id, deviceNonce, fp))
        return started
    }

    // The same vector the companion's test asserts, computed outside both (Python's hashlib).
    @Test
    fun `the number is fixed by the fingerprint and both nonces`() {
        val carNonce = ByteArray(32) { (it + 32).toByte() }
        assertEquals("918234", WifiPairing.number(fp, deviceNonce, carNonce))
        assertEquals("a different certificate gives a different number", "547028", WifiPairing.number("b".repeat(64), deviceNonce, carNonce))
    }

    @Test
    fun `nothing starts while the window is shut, and shutting it forgets everything`() {
        assertNull(pairing.start("TV", commitment))
        val started = revealed()
        assertNotNull(pairing.pending())
        pairing.window(false)
        assertFalse(pairing.isOpen())
        assertNull(pairing.pending())
        assertFalse(pairing.decide(started.id, true))
        assertSame(WifiPairing.Result.Refused, pairing.result(started.id, mint))
    }

    @Test
    fun `the window lapses 15 s after its last refresh`() {
        pairing.window(true)
        clock += WifiPairing.WINDOW_MS - 1
        assertTrue(pairing.isOpen())
        pairing.window(true) // the dialog refreshes it
        clock += WifiPairing.WINDOW_MS - 1
        assertTrue(pairing.isOpen())
        clock += 1
        assertFalse(pairing.isOpen())
    }

    @Test
    fun `one request at a time, and a few attempts per window`() {
        pairing.window(true)
        assertNull("a commitment is 32 bytes", pairing.start("TV", ByteArray(31)))
        val first = pairing.start("TV", commitment)!!
        assertNull("busy with an undecided request", pairing.start("Other TV", commitment))
        clock += WifiPairing.REQUEST_TTL_MS
        pairing.window(true)
        val second = pairing.start("TV", commitment)
        assertNotNull("an undecided request stops blocking after its TTL", second)
        assertNotEquals(first.id, second!!.id)
        repeat(WifiPairing.MAX_ATTEMPTS - 2) {
            clock += WifiPairing.REQUEST_TTL_MS
            pairing.window(true)
            assertNotNull(pairing.start("TV", commitment))
        }
        clock += WifiPairing.REQUEST_TTL_MS
        pairing.window(true)
        assertNull("attempts are capped per window", pairing.start("TV", commitment))
        pairing.window(false)
        pairing.window(true)
        assertNotNull("a new window starts a new count", pairing.start("TV", commitment))
    }

    @Test
    fun `a nonce that does not match its commitment ends the request`() {
        pairing.window(true)
        val started = pairing.start("TV", commitment)!!
        assertFalse(pairing.reveal(started.id, ByteArray(32) { 7 }, fp))
        assertNull(pairing.pending())
        assertFalse("the request is gone", pairing.reveal(started.id, deviceNonce, fp))
    }

    @Test
    fun `the owner sees the name and the number, and a confirmed request is handed its payload once`() {
        val started = revealed()
        val pending = pairing.pending()!!
        assertEquals(started.id, pending.id)
        assertEquals("Living room TV", pending.name)
        assertEquals(WifiPairing.number(fp, deviceNonce, started.carNonce), pending.number)
        assertSame(WifiPairing.Result.Waiting, pairing.result(started.id, mint))
        assertEquals("nothing is minted before the owner confirms", 0, minted)

        assertFalse("an unknown id is not decided", pairing.decide("nope", true))
        assertTrue(pairing.decide(started.id, true))
        assertNull("decided: no longer waiting for the owner", pairing.pending())
        val result = pairing.result(started.id, mint)
        assertTrue(result is WifiPairing.Result.Accepted)
        assertSame(payload, (result as WifiPairing.Result.Accepted).payload)
        assertSame("handed over once", WifiPairing.Result.Refused, pairing.result(started.id, mint))
        assertEquals(1, minted)
    }

    @Test
    fun `a refused request is told so, and nothing is minted`() {
        val started = revealed()
        assertTrue(pairing.decide(started.id, false))
        assertSame(WifiPairing.Result.Refused, pairing.result(started.id, mint))
        assertEquals(0, minted)
    }

    @Test
    fun `an undecided request is refused once the window lapses`() {
        val started = revealed()
        clock += WifiPairing.WINDOW_MS
        assertNull(pairing.pending())
        assertSame(WifiPairing.Result.Refused, pairing.result(started.id, mint))
    }

    @Test
    fun `a name is trimmed, stripped of control characters and capped`() {
        pairing.window(true)
        pairing.start("  TV\u0007\n" + "x".repeat(100), commitment)!!.let { pairing.reveal(it.id, deviceNonce, fp) }
        assertEquals("TV" + "x".repeat(62), pairing.pending()!!.name)
    }
}
