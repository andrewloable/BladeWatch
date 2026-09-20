package net.bladewatch.app.audio

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.abs

/**
 * BladeWatch-2000.2: [VolumePercentConverter] (pure) and [MediaVolumeController] (against a
 * hand-written [FakeMediaVolumeDevice] -- no Mockito/Robolectric in this project) covering the
 * required-tests list verbatim.
 */
class MediaVolumeControllerTest {

    // ── VolumePercentConverter: pure, no fake needed ──────────────────────

    @Test
    fun `zero percent maps to index zero for a max of 15`() {
        assertEquals(0, VolumePercentConverter.percentToIndex(0, 15))
    }

    @Test
    fun `hundred percent maps to index 15 for a max of 15`() {
        assertEquals(15, VolumePercentConverter.percentToIndex(100, 15))
    }

    @Test
    fun `fifty percent maps to a sensible midpoint, stable within one percent step`() {
        val max = 15
        val index = VolumePercentConverter.percentToIndex(50, max)
        val roundTripped = VolumePercentConverter.indexToPercent(index, max)

        val onePercentStep = 100.0 / max // ~6.67 for max=15
        assertTrue(
            "round-tripped 50% (got $roundTripped%) must land within one percent step ($onePercentStep) of 50",
            abs(roundTripped - 50) <= onePercentStep
        )
    }

    @Test
    fun `a stream max of 7 maps 100 percent to 7, not to 15`() {
        // A different device's stream range -- the max is read, never assumed.
        assertEquals(7, VolumePercentConverter.percentToIndex(100, 7))
        assertEquals(0, VolumePercentConverter.percentToIndex(0, 7))
    }

    @Test
    fun `out of range input is clamped, not thrown on and not passed through`() {
        assertEquals(0, VolumePercentConverter.percentToIndex(-5, 15))
        assertEquals(15, VolumePercentConverter.percentToIndex(150, 15))
    }

    // ── MediaVolumeController: mute/unmute state, and which device methods run ────────────

    @Test
    fun `mute then unmute restores the previous level, not a default`() {
        val device = FakeMediaVolumeDevice(max = 15, startIndex = 11)
        val controller = MediaVolumeController(device)

        controller.mute()
        assertTrue(controller.isMuted())
        assertEquals(0, device.index)

        controller.unmute()

        assertFalse(controller.isMuted())
        assertEquals("must restore 11 -- the level actually captured -- not a fixed default", 11, device.index)
    }

    /**
     * BladeWatch-60el: stepping used to round-trip through percent (index -> percent, +/-5,
     * percent -> index). One index step is worth more than 5% on any stream whose max is under
     * 20, so the adjustment could round straight back to the index it started from and the
     * volume button did nothing at all -- in both directions, at every subsequent tap.
     * Measured example: max 7, index 3 -> 43% -> 48% -> back to index 3.
     */
    @Test
    fun `step up always advances at least one index, on coarse and fine streams alike`() {
        for (max in listOf(5, 7, 8, 10, 15)) {
            for (start in 0 until max) {
                val device = FakeMediaVolumeDevice(max = max, startIndex = start)
                MediaVolumeController(device).stepUp()

                assertTrue(
                    "stepUp() on a stream of max $max from index $start left it at ${device.index}",
                    device.index > start
                )
                assertTrue("must never exceed the device's own max", device.index <= max)
            }
        }
    }

    @Test
    fun `step down always drops at least one index, on coarse and fine streams alike`() {
        for (max in listOf(5, 7, 8, 10, 15)) {
            for (start in 1..max) {
                val device = FakeMediaVolumeDevice(max = max, startIndex = start)
                MediaVolumeController(device).stepDown()

                assertTrue(
                    "stepDown() on a stream of max $max from index $start left it at ${device.index}",
                    device.index < start
                )
                assertTrue("must never go below zero", device.index >= 0)
            }
        }
    }

    @Test
    fun `stepping stays clamped at both ends`() {
        val atMax = FakeMediaVolumeDevice(max = 15, startIndex = 15)
        MediaVolumeController(atMax).stepUp()
        assertEquals("already at max -- must clamp, not overshoot", 15, atMax.index)

        val atZero = FakeMediaVolumeDevice(max = 15, startIndex = 0)
        MediaVolumeController(atZero).stepDown()
        assertEquals("already at zero -- must clamp, not go negative", 0, atZero.index)
    }

    @Test
    fun `stepping cancels a pending mute-restore, same as setting a level`() {
        val device = FakeMediaVolumeDevice(max = 15, startIndex = 11)
        val controller = MediaVolumeController(device)

        controller.mute()
        assertTrue(controller.isMuted())
        controller.stepUp()

        assertFalse("an explicit step states what the owner wants to hear next", controller.isMuted())
        controller.unmute()
        assertEquals("unmute must not resurrect the pre-mute level after a step", 1, device.index)
    }

    @Test
    fun `only volume methods are ever invoked, nothing that starts playback`() {
        val device = FakeMediaVolumeDevice(max = 15, startIndex = 8)
        val controller = MediaVolumeController(device)

        controller.setVolumePercent(60)
        controller.stepUp()
        controller.stepDown()
        controller.mute()
        controller.unmute()

        for (invoked in device.invocations) {
            assertTrue(
                "unexpected call: $invoked",
                invoked == "getStreamMaxVolume" || invoked == "getStreamVolume" || invoked == "setStreamVolume"
            )
        }
        assertTrue("expected at least one setStreamVolume call", device.invocations.contains("setStreamVolume"))
    }

    /** Records every call so [`only volume methods are ever invoked...`] can assert on the
     * stub, not just the return value. */
    private class FakeMediaVolumeDevice(val max: Int, startIndex: Int) : MediaVolumeDevice {
        var index: Int = startIndex
        val invocations = mutableListOf<String>()

        override fun getStreamMaxVolume(): Int {
            invocations.add("getStreamMaxVolume")
            return max
        }

        override fun getStreamVolume(): Int {
            invocations.add("getStreamVolume")
            return index
        }

        override fun setStreamVolume(index: Int) {
            invocations.add("setStreamVolume")
            this.index = index
        }
    }
}
