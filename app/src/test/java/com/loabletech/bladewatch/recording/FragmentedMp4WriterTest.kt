package net.bladewatch.app.recording

import java.io.File
import java.nio.ByteBuffer
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

/**
 * BladeWatch-rdtj.29. The writer's output was checked against real players (ffmpeg frame by frame,
 * AVPlayer, ExoPlayer and MediaMetadataRetriever on Android 10, Chrome) in the spike; these tests
 * pin the layout that made it work, so a change that would break a player fails here first.
 */
class FragmentedMp4WriterTest {
    @get:Rule val tmp = TemporaryFolder()

    private val sc = byteArrayOf(0, 0, 0, 1)
    private val sps = byteArrayOf(0x67, 0x42, 0x00, 0x33, 0x11, 0x22)
    private val pps = byteArrayOf(0x68, 0x33, 0x44)
    private val h264 = FragmentedMp4Writer.Track(false, 2560, 1920, sc + sps, sc + pps)

    // A real HEVC VPS/SPS/PPS (libx265, 2560x1920 Main): codec parameters only.
    private fun hex(s: String) = ByteArray(s.length / 2) { s.substring(2 * it, 2 * it + 2).toInt(16).toByte() }
    private val vps = hex("40010c01ffff016000000300900000030000030096928090")
    private val hevcSps = hex("420101016000000300900000030000030096a001402007816592a4932bc05a8283037080000006000003005d84")
    private val hevcPps = hex("4401c172b46240")

    /** An access unit as MediaCodec gives it: an optional AUD and parameter sets, then a slice. */
    private fun frame(n: Int, key: Boolean, size: Int = 100): ByteBuffer {
        val slice = ByteArray(size) { (n + it).toByte() }.also { it[0] = if (key) 0x65 else 0x41 }
        val aud = byteArrayOf(0x09, 0x10)
        return ByteBuffer.wrap(sc + aud + (if (key) sc + sps + sc + pps else ByteArray(0)) + sc + slice)
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

    /** [gops] groups of 30 frames at a steady 15 fps, written and finished. */
    private fun write(gops: Int, file: File = tmp.newFile(), finish: Boolean = true, reserve: Int = FragmentedMp4Writer.DEFAULT_INDEX_RESERVE): FragmentedMp4Writer {
        val w = FragmentedMp4Writer(file, h264, reserve)
        for (i in 0 until gops * 30) w.writeSample(frame(i, i % 30 == 0), i * 66_667L, i % 30 == 0)
        if (finish) assertTrue(w.finish())
        return w
    }

    @Test
    fun layoutIsHeaderFirstThenOneFragmentPerGroupThenTheRandomAccessBox() {
        val file = tmp.newFile()
        write(3, file)
        val b = file.readBytes()
        assertEquals(listOf("ftyp", "moov", "sidx", "free", "moof", "mdat", "moof", "mdat", "moof", "mdat", "mfra"), boxes(b).map { it.type })
        val moov = boxes(b).first { it.type == "moov" }
        // The length lives in mehd only: 90 frames of 1/15 s = 6000 ms. mvhd's stays 0 (AVFoundation
        // added the two up and reported double).
        val mehd = child(b, moov, "mvex", "mehd")
        assertEquals(6000L, u32(b, mehd.at + 12))
        assertEquals(0L, u32(b, child(b, moov, "mvhd").at + 24))
        // avc1 carrying the SPS/PPS as avcC.
        val avcC = b.copyOfRange(boxes(b).first { it.type == "moov" }.at, b.size).let { m -> String(m, Charsets.ISO_8859_1).indexOf("avcC") }
        assertTrue(avcC > 0)
        val cfg = moov.at + avcC + 4
        assertArrayEquals(byteArrayOf(1, 0x42, 0x00, 0x33, 0xFF.toByte(), 0xE1.toByte()), b.copyOfRange(cfg, cfg + 6))
    }

    @Test
    fun samplesAreLengthPrefixedWithoutParameterSetsOrDelimiters() {
        val file = tmp.newFile()
        write(1, file)
        val b = file.readBytes()
        val moof = boxes(b).first { it.type == "moof" }
        val trun = child(b, moof, "traf", "trun")
        assertEquals(0x000701L, u32(b, trun.at + 8) and 0xFFFFFF)
        assertEquals(30L, u32(b, trun.at + 12))
        val dataOffset = u32(b, trun.at + 16).toInt()
        // First sample: duration, size 4 + 100, sync flags; its data starts at moof + data_offset.
        assertEquals(6000L, u32(b, trun.at + 20)) // 66_667 us in 90 kHz
        assertEquals(104L, u32(b, trun.at + 24))
        assertEquals(0x02000000L, u32(b, trun.at + 28))
        assertEquals(0x01010000L, u32(b, trun.at + 40), "the second is not a sync sample")
        val first = moof.at + dataOffset
        assertEquals(100, ByteBuffer.wrap(b, first, 4).int)
        assertEquals(0x65.toByte(), b[first + 4])
        assertEquals("mdat", String(b, moof.at + moof.size + 4, 4, Charsets.US_ASCII))
        assertEquals(moof.size + 8, dataOffset)
    }

    private fun assertEquals(expected: Long, actual: Long, message: String) = org.junit.Assert.assertEquals(message, expected, actual)

    @Test
    fun theIndexPointsAtEachFragmentAndLeavesTheRestOfTheReserveFree() {
        val file = tmp.newFile()
        write(3, file)
        val b = file.readBytes()
        val top = boxes(b)
        val sidx = top.first { it.type == "sidx" }
        val free = top[top.indexOf(sidx) + 1]
        assertEquals(FragmentedMp4Writer.DEFAULT_INDEX_RESERVE, sidx.size + free.size)
        assertEquals(free.size.toLong(), ByteBuffer.wrap(b, sidx.at + 28, 8).long) // first_offset
        assertEquals(3, ByteBuffer.wrap(b, sidx.at + 38, 2).short.toInt())
        val moofs = top.withIndex().filter { it.value.type == "moof" }
        for ((i, indexed) in moofs.withIndex()) {
            val (at, moof) = indexed
            val ref = sidx.at + 40 + 12 * i
            assertEquals((moof.size + top[at + 1].size).toLong(), u32(b, ref)) // moof + mdat
            // The fragment's duration is its samples' durations added up.
            val trun = child(b, moof, "traf", "trun")
            val samples = (0 until u32(b, trun.at + 12).toInt()).sumOf { u32(b, trun.at + 20 + 12 * it) }
            assertEquals(samples, u32(b, ref + 4))
            assertEquals(0x90000000L, u32(b, ref + 8))
        }
        // mfra: one entry per fragment, and mfro gives mfra's size from the end of the file.
        val mfra = top.last()
        assertEquals(mfra.size.toLong(), u32(b, b.size - 4))
    }

    @Test
    fun aFileMustOpenOnAKeyframeAndTimeNeverRunsBackwards() {
        val file = tmp.newFile()
        val w = FragmentedMp4Writer(file, h264)
        w.writeSample(frame(0, false), 0, false) // before any keyframe: undecodable, dropped
        w.writeSample(frame(1, true), 1_000_000, true)
        w.writeSample(frame(2, false), 1_066_667, false)
        w.writeSample(frame(3, false), 1_000_000, false) // backwards
        w.writeSample(frame(4, false), 1_133_333, false)
        assertTrue(w.finish())
        assertEquals(3, w.writtenSamples)
        assertEquals(1, w.droppedSamples)
        val b = file.readBytes()
        val trun = child(b, boxes(b).first { it.type == "moof" }, "traf", "trun")
        // The last sample repeats the duration before it, as MediaMuxer does.
        assertEquals(listOf(6000L, 6000L, 6000L), (0 until 3).map { u32(b, trun.at + 20 + 12 * it) })
        assertEquals(0L, ByteBuffer.wrap(b, child(b, boxes(b).first { it.type == "moof" }, "traf", "tfdt").at + 12, 8).long)
    }

    @Test
    fun nothingWrittenIsAnEmptyRecording() {
        assertFalse(FragmentedMp4Writer(tmp.newFile(), h264).finish())
        val w = FragmentedMp4Writer(tmp.newFile(), h264)
        w.writeSample(frame(0, false), 0, false)
        assertFalse(w.finish())
        assertFalse(w.finish(), "a second finish changes nothing")
    }

    private fun assertFalse(value: Boolean, message: String) = org.junit.Assert.assertFalse(message, value)

    @Test
    fun aCrashLeavesWholeFragmentsNoLengthAndNoIndex() {
        val file = tmp.newFile()
        val w = write(3, file, finish = false)
        w.writeSample(frame(90, true), 90 * 66_667L, true) // flushes the third group
        w.close()
        w.close()
        val b = file.readBytes()
        assertEquals(listOf("ftyp", "moov", "free", "moof", "mdat", "moof", "mdat", "moof", "mdat"), boxes(b).map { it.type })
        // mvex holds a free box where mehd goes: a zero mehd made ExoPlayer take the clip as 0 s.
        assertEquals(listOf("free", "trex"), boxes(b, child(b, boxes(b)[1], "mvex").at + 8, child(b, boxes(b)[1], "mvex").let { it.at + it.size }).map { it.type })
    }

    @Test
    fun recoveryCutsBackToTheLastWholeFragmentAndMatchesACleanFinish() {
        // A crash after three groups, with part of a fourth on disk as a power cut would leave it.
        val crashed = tmp.newFile()
        write(3, crashed, finish = false).apply {
            writeSample(frame(90, true), 90 * 66_667L, true)
            close()
        }
        val partial = tmp.newFile()
        write(4, partial)
        crashed.appendBytes(partial.readBytes().copyOfRange(crashed.length().toInt(), crashed.length().toInt() + 500))
        assertTrue(FragmentedMp4Writer.recover(crashed))
        // Byte for byte what a clean finish after the same three groups writes.
        val clean = tmp.newFile()
        write(3, clean)
        assertArrayEquals(clean.readBytes(), crashed.readBytes())
        // Finished files are left alone.
        assertTrue(FragmentedMp4Writer.recover(crashed))
        assertArrayEquals(clean.readBytes(), crashed.readBytes())
    }

    @Test
    fun recoveryRefusesWhatItDidNotWrite() {
        val junk = tmp.newFile().apply { writeBytes(ByteArray(100) { it.toByte() }) }
        assertFalse(FragmentedMp4Writer.recover(junk))
        assertEquals(100L, junk.length())
        // An index-last MP4 (MediaMuxer's layout): ftyp, free, mdat.
        val muxer = tmp.newFile().apply {
            writeBytes(byteArrayOf(0, 0, 0, 16) + "ftyp".toByteArray() + "isom".toByteArray() + ByteArray(4) +
                byteArrayOf(0, 0, 0, 8) + "free".toByteArray() + byteArrayOf(0, 0, 0, 8) + "mdat".toByteArray())
        }
        assertFalse(FragmentedMp4Writer.recover(muxer))
        // Ours, but not one fragment complete: nothing worth keeping.
        val header = tmp.newFile()
        FragmentedMp4Writer(header, h264).close()
        val before = header.readBytes()
        assertFalse(FragmentedMp4Writer.recover(header))
        assertArrayEquals(before, header.readBytes())
    }

    @Test
    fun anIndexTooBigForTheReserveIsLeftOutNotForced() {
        val file = tmp.newFile()
        write(3, file, reserve = 64) // room for the sidx header but not three references
        val b = file.readBytes()
        assertEquals(listOf("ftyp", "moov", "free", "moof", "mdat", "moof", "mdat", "moof", "mdat", "mfra"), boxes(b).map { it.type })
        assertEquals(6000L, u32(b, child(b, boxes(b)[1], "mvex", "mehd").at + 12), "the length is still there")
    }

    @Test
    fun annexBBecomesLengthPrefixed() {
        // 3- and 4-byte start codes; parameter sets and delimiters out.
        val au = byteArrayOf(0, 0, 1, 0x09, 0x10) + byteArrayOf(0, 0, 0, 1) + sps + byteArrayOf(0, 0, 1, 0x65, 1, 2, 3)
        assertArrayEquals(byteArrayOf(0, 0, 0, 4, 0x65, 1, 2, 3), FragmentedMp4Writer.toLengthPrefixed(ByteBuffer.wrap(au), hevc = false))
        // Already length-prefixed: kept as it is.
        val avcc = byteArrayOf(0, 0, 0, 2, 0x41, 9)
        assertArrayEquals(avcc, FragmentedMp4Writer.toLengthPrefixed(ByteBuffer.wrap(avcc), hevc = false))
        // HEVC: VPS/SPS/PPS (32-34) and AUD (35) out; a slice (type 1) kept.
        val hau = sc + byteArrayOf(0x46, 1, 0x50) + sc + vps + sc + hevcSps + sc + hevcPps + sc + byteArrayOf(0x02, 1, 7, 7)
        assertArrayEquals(byteArrayOf(0, 0, 0, 4, 0x02, 1, 7, 7), FragmentedMp4Writer.toLengthPrefixed(ByteBuffer.wrap(hau), hevc = true))
        assertEquals(emptyList<ByteArray>(), FragmentedMp4Writer.splitNals(ByteArray(0)))
    }

    @Test
    fun hevcConfigurationComesFromTheSps() {
        val hvcC = FragmentedMp4Writer.hvcC(listOf(vps, hevcSps, hevcPps))
        assertEquals("hvcC", String(hvcC, 4, 4, Charsets.US_ASCII))
        val body = hvcC.copyOfRange(8, hvcC.size)
        assertEquals(1, body[0].toInt())
        // general profile/tier/level from the SPS, its emulation-prevention bytes (00 00 03) removed.
        assertArrayEquals(hex("016000000090000000000096"), body.copyOfRange(1, 13))
        assertEquals(0xFD, body[16].toInt() and 0xFF) // 4:2:0
        assertEquals(0xF8, body[17].toInt() and 0xFF) // 8-bit luma
        assertEquals(0xF8, body[18].toInt() and 0xFF) // 8-bit chroma
        assertEquals(0x0F, body[21].toInt() and 0xFF) // 1 temporal layer, nested, 4-byte lengths
        assertEquals(3, body[22].toInt())
        assertEquals(0xA0, body[23].toInt() and 0xFF) // complete array of VPS (type 32)

        val file = tmp.newFile()
        val w = FragmentedMp4Writer(file, FragmentedMp4Writer.Track(true, 2560, 1920, sc + vps + sc + hevcSps + sc + hevcPps))
        w.writeSample(ByteBuffer.wrap(sc + byteArrayOf(0x26, 1, 5)), 0, true)
        assertTrue(w.finish())
        val text = String(file.readBytes(), Charsets.ISO_8859_1)
        assertTrue(text.contains("hvc1") && text.contains("hvcC"))
    }

    @Test
    fun theConfigurationsRefuseMissingParameterSets() {
        assertTrue(runCatching { FragmentedMp4Writer.avcC(listOf(sps)) }.isFailure)
        assertTrue(runCatching { FragmentedMp4Writer.hvcC(listOf(vps, hevcSps)) }.isFailure)
    }

    @Test
    fun microsecondsTo90kHzRound() {
        assertEquals(6000L, FragmentedMp4Writer.toTimescale(66_667))
        assertEquals(0L, FragmentedMp4Writer.toTimescale(5))
        assertEquals(1L, FragmentedMp4Writer.toTimescale(6))
    }

    @Test
    fun leftoversAreFinishedAndNamedOnlyWhenTheyAreOurs() {
        val dir = tmp.newFolder()
        fun crashed(name: String): File = File(dir, name).also { f ->
            write(2, f, finish = false).apply {
                writeSample(frame(60, true), 60 * 66_667L, true)
                close()
            }
        }
        // Written a moment ago, as it is when the keepalive restarts a killed daemon within
        // seconds: recovered all the same (no age guard -- see recoverLeftovers).
        val ours = crashed("event_1.mp4.tmp")
        val taken = crashed("event_3.mp4.tmp").also { File(dir, "event_3.mp4").writeText("x") }
        val muxer = File(dir, "event_4.mp4.tmp").apply { writeBytes(ByteArray(64)) }
        val seen = ArrayList<String>()
        val saved = FragmentedMp4Muxer.recoverLeftovers(listOf(dir, dir)) { seen.add(it.name) }
        assertEquals(listOf("event_1.mp4"), saved.map { it.name })
        assertEquals(listOf("event_1.mp4"), seen)
        assertFalse(ours.exists())
        assertTrue(File(dir, "event_1.mp4").exists() && taken.exists() && muxer.exists())
        assertTrue(FragmentedMp4Writer.recover(File(dir, "event_1.mp4")), "the recovered clip is a finished one")
        assertEquals(emptyList<File>(), FragmentedMp4Muxer.recoverLeftovers(listOf(File(dir, "missing"))))
    }

    private fun assertTrue(value: Boolean, message: String) = org.junit.Assert.assertTrue(message, value)

    @Test
    fun trackComesFromTheEncodersFormat() {
        val t = FragmentedMp4Muxer.trackOf("video/hevc", 2560, 1920, ByteBuffer.wrap(sc + vps), null)
        assertTrue(t.hevc)
        assertArrayEquals(sc + vps, t.csd0)
        assertNull(t.csd1)
        val a = FragmentedMp4Muxer.trackOf("video/avc", 640, 480, ByteBuffer.wrap(sc + sps), ByteBuffer.wrap(sc + pps))
        assertFalse(a.hevc)
        assertArrayEquals(sc + pps, a.csd1)
        assertTrue(runCatching { FragmentedMp4Muxer.trackOf("video/avc", 1, 1, null, null) }.isFailure)
    }
}
