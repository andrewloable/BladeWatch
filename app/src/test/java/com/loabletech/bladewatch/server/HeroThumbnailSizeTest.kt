package net.bladewatch.app.server

import org.junit.Assert.assertEquals
import org.junit.Test

/** BladeWatch-820b: a hero served as a grid thumbnail is brought down to the thumbnail size. */
class HeroThumbnailSizeTest {

    private val edge = RecordingsApiHandler.HERO_THUMB_EDGE

    @Test
    fun `a 2560x1920 hero becomes a 480x360 thumbnail`() {
        assertEquals(480 to 360, RecordingsApiHandler.scaledTo(2560, 1920, edge))
        // Decoded at 1/4 (640x480) -- still at least the target, so no quality lost to sampling.
        assertEquals(4, RecordingsApiHandler.sampleSizeFor(2560, 1920, edge))
    }

    @Test
    fun `a square 640 hero becomes 480, and portrait keeps its aspect`() {
        assertEquals(480 to 480, RecordingsApiHandler.scaledTo(640, 640, edge))
        assertEquals(240 to 480, RecordingsApiHandler.scaledTo(960, 1920, edge))
        assertEquals(1, RecordingsApiHandler.sampleSizeFor(640, 640, edge))
    }

    @Test
    fun `nothing is ever enlarged`() {
        assertEquals(320 to 180, RecordingsApiHandler.scaledTo(320, 180, edge))
        assertEquals(1, RecordingsApiHandler.sampleSizeFor(320, 180, edge))
    }
}
