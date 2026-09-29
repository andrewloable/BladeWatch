package net.bladewatch.app.surveillance

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotSame
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * BladeWatch-rdtj.61: the cached mosaic frame behind the live view's still and the quadrant
 * snapshots. With sentry off it is fed only by [SurveillanceEngineGpu.storeMosaicFrame].
 */
class MosaicFrameCacheTest {
    private val size = 640 * 480 * 3

    private fun frame(fill: Int) = ByteArray(size) { fill.toByte() }

    @Test
    fun storesFramesWhileSentryIsOff() {
        val engine = SurveillanceEngineGpu()
        assertNull(engine.latestMosaicFrame)
        engine.storeMosaicFrame(frame(1))
        assertArrayEquals(frame(1), engine.latestMosaicFrame)
        engine.storeMosaicFrame(frame(2))
        assertArrayEquals("a newer frame replaces the old one", frame(2), engine.latestMosaicFrame)
    }

    @Test
    fun aReaderKeepsAWholeFrameWhileTheNextOneIsStored() {
        val engine = SurveillanceEngineGpu()
        engine.storeMosaicFrame(frame(1))
        val reading = engine.latestMosaicFrame!!
        engine.storeMosaicFrame(frame(2))
        assertNotSame(reading, engine.latestMosaicFrame)
        assertArrayEquals("the array a reader holds is not overwritten by the next frame", frame(1), reading)
    }

    @Test
    fun ignoresAFrameOfTheWrongSize() {
        val engine = SurveillanceEngineGpu()
        engine.storeMosaicFrame(frame(1))
        val version = engine.mosaicVersion
        engine.storeMosaicFrame(ByteArray(10))
        assertEquals(size, engine.latestMosaicFrame!!.size)
        assertArrayEquals(frame(1), engine.latestMosaicFrame)
        assertEquals("a rejected frame is not a new one", version, engine.mosaicVersion)
    }

    @Test
    fun everyStoredFrameIsANewVersion() {
        val engine = SurveillanceEngineGpu()
        val v0 = engine.mosaicVersion
        engine.storeMosaicFrame(frame(1))
        engine.storeMosaicFrame(frame(1))
        assertEquals("the still re-encodes only when this moves", v0 + 2, engine.mosaicVersion)
    }
}
