package net.bladewatch.app.recording

import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.RandomAccessFile
import java.nio.ByteBuffer

/**
 * BladeWatch-rdtj.63: a fragmented clip served as an ordinary one (index first, then every sample),
 * because AVFoundation walks every fragment of a fragmented file before it plays -- over a minute
 * for a 5-minute clip over Pear.
 */
class Mp4DefragmentTest {
    @get:Rule val tmp = TemporaryFolder()

    private val sc = byteArrayOf(0, 0, 0, 1)
    private val sps = byteArrayOf(0x67, 0x42, 0x00, 0x33, 0x11, 0x22)
    private val pps = byteArrayOf(0x68, 0x33, 0x44)
    private val h264 = FragmentedMp4Writer.Track(false, 2560, 1920, sc + sps, sc + pps)

    /** A frame whose slice bytes say which frame it is, so each sample can be found again. */
    private fun frame(n: Int, key: Boolean): ByteBuffer {
        val slice = ByteArray(50 + n % 7) { (n * 31 + it).toByte() }.also { it[0] = if (key) 0x65 else 0x41 }
        return ByteBuffer.wrap(sc + (if (key) sc + sps + sc + pps else ByteArray(0)) + sc + slice)
    }

    /** [gops] groups of 30 frames at 15 fps; returns the file and each sample as stored (length-prefixed). */
    private fun clip(gops: Int, finish: Boolean = true): Pair<File, List<ByteArray>> {
        val file = tmp.newFile()
        val w = FragmentedMp4Writer(file, h264)
        val stored = ArrayList<ByteArray>()
        for (i in 0 until gops * 30) {
            val key = i % 30 == 0
            val f = frame(i, key)
            w.writeSample(f.duplicate(), i * 66_667L, key)
            stored.add(FragmentedMp4Writer.toLengthPrefixed(f.duplicate(), false))
        }
        if (finish) assertTrue(w.finish()) else w.close()
        return file to stored
    }

    private fun served(file: File): ByteArray {
        val view = Mp4Faststart.view(file)
        assertNotNull("a fragmented clip gets a view", view)
        view!!
        val out = ByteArrayOutputStream()
        RandomAccessFile(file, "r").use { view.write(it, 0, view.length, out) }
        assertEquals(view.length, out.size().toLong())
        return out.toByteArray()
    }

    private class Box(val type: String, val at: Int, val size: Int)

    private fun boxes(b: ByteArray, from: Int = 0, to: Int = b.size): List<Box> {
        val out = ArrayList<Box>()
        var at = from
        while (at + 8 <= to) {
            val size = ByteBuffer.wrap(b, at, 4).int
            out.add(Box(String(b, at + 4, 4, Charsets.US_ASCII), at, size))
            if (size < 8) break
            at += size
        }
        return out
    }

    private fun child(b: ByteArray, parent: Box, vararg path: String): Box {
        var box = parent
        for (p in path) box = boxes(b, box.at + 8, box.at + box.size).first { it.type == p }
        return box
    }

    private fun u32(b: ByteArray, at: Int) = ByteBuffer.wrap(b, at, 4).int.toLong() and 0xFFFFFFFFL

    @Test
    fun anOrdinaryClipIndexFirstWithEverySampleWhereItsIndexSays() {
        val (file, stored) = clip(3)
        val b = served(file)
        assertEquals(listOf("ftyp", "moov", "mdat"), boxes(b).map { it.type })
        val moov = boxes(b).first { it.type == "moov" }
        assertTrue("no fragment extension left", boxes(b, moov.at + 8, moov.at + moov.size).none { it.type == "mvex" })
        val stbl = child(b, moov, "trak", "mdia", "minf", "stbl")
        assertEquals(listOf("stsd", "stts", "stss", "stsc", "stsz", "stco"), boxes(b, stbl.at + 8, stbl.at + stbl.size).map { it.type })

        val stsz = child(b, stbl, "stsz")
        val stco = child(b, stbl, "stco")
        val count = u32(b, stsz.at + 16).toInt()
        assertEquals(90, count)
        assertEquals(count.toLong(), u32(b, stco.at + 12))
        for (i in 0 until count) {
            val size = u32(b, stsz.at + 20 + 4 * i).toInt()
            val offset = u32(b, stco.at + 16 + 4 * i).toInt()
            assertArrayEquals("sample $i", stored[i], b.copyOfRange(offset, offset + size))
        }
        // One sample per chunk, which AVFoundation needs to start before the whole clip arrives.
        val stsc = child(b, stbl, "stsc")
        assertEquals(listOf(1L, 1L, 1L, 1L), (0 until 4).map { u32(b, stsc.at + 12 + 4 * it) })
    }

    @Test
    fun durationsAndKeyframesMatchTheFragments() {
        val (file, _) = clip(2)
        val b = served(file)
        val moov = boxes(b).first { it.type == "moov" }
        val stbl = child(b, moov, "trak", "mdia", "minf", "stbl")
        val stts = child(b, stbl, "stts")
        var samples = 0L
        var total = 0L
        for (e in 0 until u32(b, stts.at + 12).toInt()) {
            val n = u32(b, stts.at + 16 + 8 * e)
            samples += n
            total += n * u32(b, stts.at + 20 + 8 * e)
        }
        assertEquals(60L, samples)
        val mdhd = child(b, moov, "trak", "mdia", "mdhd")
        assertEquals("mdhd holds the length now", total, u32(b, mdhd.at + 24))
        val mvhd = child(b, moov, "mvhd")
        assertEquals(total * u32(b, mvhd.at + 20) / u32(b, mdhd.at + 20), u32(b, mvhd.at + 24))
        val tkhd = child(b, moov, "trak", "tkhd")
        assertEquals(u32(b, mvhd.at + 24), u32(b, tkhd.at + 28))
        val stss = child(b, stbl, "stss")
        assertEquals(listOf(1L, 31L), (0 until u32(b, stss.at + 12).toInt()).map { u32(b, stss.at + 16 + 4 * it) })
    }

    @Test
    fun aRecoveredCrashClipIsServedTheSameWay() {
        val (file, stored) = clip(2, finish = false)
        assertTrue(FragmentedMp4Writer.recover(file))
        val b = served(file)
        val stbl = child(b, boxes(b).first { it.type == "moov" }, "trak", "mdia", "minf", "stbl")
        assertEquals("whole fragments only: the one in flight was lost", 30L, u32(b, child(b, stbl, "stsz").at + 16))
        val off = u32(b, child(b, stbl, "stco").at + 16).toInt()
        assertArrayEquals(stored[0], b.copyOfRange(off, off + stored[0].size))
    }

    @Test
    fun itsOwnEtagSoNoCachedRangeOfAnotherLayoutMixesIn() {
        val (file, _) = clip(1)
        assertEquals(Mp4Defragment.TAG, Mp4Faststart.view(file)!!.tag)
        assertTrue(Mp4Defragment.TAG != Mp4Faststart.TAG)
    }

    @Test
    fun anythingButThisWritersLayoutIsServedAsItIs() {
        val (file, _) = clip(1)
        val b = file.readBytes()
        // A trun with composition offsets (flag 0x800), which this writer never writes.
        val moof = boxes(b).first { it.type == "moof" }
        val trun = child(b, moof, "traf", "trun")
        val patched = b.copyOf().also { ByteBuffer.wrap(it).putInt(trun.at + 8, 0x000F01) }
        val other = tmp.newFile().apply { writeBytes(patched) }
        assertNull(Mp4Faststart.view(other))
    }
}
