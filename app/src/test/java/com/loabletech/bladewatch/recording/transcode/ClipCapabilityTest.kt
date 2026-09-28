package net.bladewatch.app.recording.transcode

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** BladeWatch-rdtj.73: the pure tier/capability logic, against the real device measurements the feature is built from. */
class ClipCapabilityTest {

    @Test
    fun `parseHint reads maxW and maxH, in any order, alongside other params`() {
        assertEquals(1920 to 1080, ClipCapability.parseHint("maxW=1920&maxH=1080"))
        assertEquals(1920 to 1080, ClipCapability.parseHint("maxH=1080&maxW=1920"))
        assertEquals(1920 to 1080, ClipCapability.parseHint("t=abc123&maxW=1920&maxH=1080"))
    }

    @Test
    fun `parseHint is null -- native, unconditionally -- for anything malformed or absent`() {
        assertNull("no query at all", ClipCapability.parseHint(null))
        assertNull("empty query", ClipCapability.parseHint(""))
        assertNull("no capability params at all", ClipCapability.parseHint("t=abc123"))
        assertNull("only one of the pair", ClipCapability.parseHint("maxW=1920"))
        assertNull("not a number", ClipCapability.parseHint("maxW=abc&maxH=1080"))
        assertNull("zero", ClipCapability.parseHint("maxW=0&maxH=1080"))
        assertNull("negative", ClipCapability.parseHint("maxW=1920&maxH=-1"))
    }

    @Test
    fun `nativeFits -- the car's actual mosaic against the actual phone that failed it`() {
        // The real, measured hardware-decoder ceiling on the phone rdtj.73 was found on.
        val phoneHint = 1920 to 1920
        assertFalse("2560x1920 does not fit a 1920-either-dimension ceiling", ClipCapability.nativeFits(phoneHint, 2560, 1920))
        assertTrue("1920x1080 does fit it", ClipCapability.nativeFits(phoneHint, 1920, 1080))
    }

    @Test
    fun `nativeFits does not care which side of the hint is which -- only the pair, long against long`() {
        assertTrue(ClipCapability.nativeFits(1080 to 1920, 1920, 1080))
        assertTrue(ClipCapability.nativeFits(1920 to 1080, 1080, 1920))
    }

    @Test
    fun `nativeFits -- an absent hint is handled by the caller as native, never reaches here`() {
        // parseHint returning null IS "serve native"; nativeFits only runs once a hint exists.
        // Documented by omission: there is no Int?-accepting overload, on purpose.
    }

    @Test
    fun `an unlimited-looking hint still only proves it against the actual clip, not assumed`() {
        assertTrue(ClipCapability.nativeFits(4096 to 4096, 2560, 1920))
    }

    @Test
    fun `fallbackFits -- whether this server's one transcode tier itself is even offerable`() {
        assertTrue("a 1920-capable device", ClipCapability.fallbackFits(1920 to 1920))
        assertFalse("the software-decoder-only ceiling found on the same real phone", ClipCapability.fallbackFits(1280 to 720))
    }
}
