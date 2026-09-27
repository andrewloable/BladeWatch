package net.bladewatch.app.recording

import java.io.ByteArrayOutputStream
import java.io.File
import java.io.RandomAccessFile
import java.nio.ByteBuffer
import java.nio.file.Files
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotSame
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-rdtj.28: MediaMuxer leaves the index (`moov`) at the end, so a remote player cannot
 * start until it reaches the end of the file. The car serves a faststart VIEW of each clip instead:
 * these pin the order, that every chunk offset still points at the same sample bytes, that any
 * byte range is a consistent slice, and that the file on disk is never touched.
 */
class Mp4FaststartTest {

    private fun box(type: String, body: ByteArray): ByteArray =
        ByteBuffer.allocate(8 + body.size).putInt(8 + body.size).put(type.toByteArray(Charsets.ISO_8859_1)).put(body).array()

    private fun concat(vararg parts: ByteArray): ByteArray = ByteArrayOutputStream().apply { parts.forEach { write(it) } }.toByteArray()

    private fun chunkTable(type: String, offsets: List<Long>): ByteArray {
        val width = if (type == "stco") 4 else 8
        val b = ByteBuffer.allocate(8 + offsets.size * width).putInt(0).putInt(offsets.size)
        offsets.forEach { if (width == 4) b.putInt(it.toInt()) else b.putLong(it) }
        return box(type, b.array())
    }

    /**
     * ftyp, free(3192), mdat(samples), moov -- MediaMuxer's layout. Two tracks, one with a 32-bit
     * and one with a 64-bit chunk table, each pointing at samples inside mdat.
     */
    private fun muxerStyleFile(tableTypes: List<String> = listOf("stco", "co64")): Pair<File, List<Long>> {
        val ftyp = box("ftyp", "isom\u0000\u0000\u0002\u0000isomiso2avc1mp41".toByteArray(Charsets.ISO_8859_1))
        val free = box("free", ByteArray(3192 - 8))
        val payload = ByteArray(50_000) { (it * 31 % 251).toByte() }
        val mdat = box("mdat", payload)
        val mdatBody = (ftyp.size + free.size + 8).toLong()
        val offsets = listOf(0L, 1_000L, 12_345L, 49_000L).map { mdatBody + it }
        val traks = tableTypes.map { type ->
            box("trak", concat(box("tkhd", ByteArray(84)), box("mdia", concat(
                box("mdhd", ByteArray(24)),
                box("minf", box("stbl", concat(box("stsd", ByteArray(16)), chunkTable(type, offsets)))),
            ))))
        }
        val moov = box("moov", concat(box("mvhd", ByteArray(100)), *traks.toTypedArray()))
        val file = Files.createTempFile("clip", ".mp4").toFile()
        file.writeBytes(concat(ftyp, free, mdat, moov))
        return file to offsets
    }

    private fun topLevel(file: File): List<String> =
        RandomAccessFile(file, "r").use { Mp4Faststart.topLevelBoxes(it, file.length())!!.map { b -> b.type } }

    /** Every chunk offset in [file]'s index, in order. */
    private fun chunkOffsets(file: File): List<Long> {
        val bytes = file.readBytes()
        val out = ArrayList<Long>()
        fun walk(start: Int, end: Int) {
            var p = start
            while (p + 8 <= end) {
                val size = ByteBuffer.wrap(bytes, p, 4).int
                val type = String(bytes, p + 4, 4, Charsets.ISO_8859_1)
                when (type) {
                    "moov", "trak", "mdia", "minf", "stbl" -> walk(p + 8, p + size)
                    "stco", "co64" -> {
                        val n = ByteBuffer.wrap(bytes, p + 12, 4).int
                        val w = if (type == "stco") 4 else 8
                        for (i in 0 until n) {
                            val b = ByteBuffer.wrap(bytes, p + 16 + i * w, w)
                            out.add(if (w == 4) b.int.toLong() and 0xFFFFFFFFL else b.long)
                        }
                    }
                }
                p += size
            }
        }
        walk(0, bytes.size)
        return out
    }

    /** The whole faststart view of [file], written out, or null when there is none. */
    private fun viewBytes(file: File): ByteArray? {
        val view = Mp4Faststart.view(file) ?: return null
        val out = ByteArrayOutputStream()
        RandomAccessFile(file, "r").use { view.write(it, 0, view.length, out) }
        return out.toByteArray()
    }

    private fun asFile(bytes: ByteArray): File = Files.createTempFile("view", ".mp4").toFile().apply { writeBytes(bytes) }

    private fun sampleAt(file: File, offset: Long): ByteArray =
        RandomAccessFile(file, "r").use { it.seek(offset); ByteArray(16).also { b -> it.readFully(b) } }

    @Test
    fun `serves the index in front of the frames and keeps every sample reachable`() {
        val (file, offsets) = muxerStyleFile()
        val before = offsets.map { sampleAt(file, it) }

        val served = asFile(viewBytes(file)!!)

        assertEquals(listOf("ftyp", "free", "moov", "mdat"), topLevel(served))
        assertEquals("the same length: Content-Length and Range math are unchanged", file.length(), served.length())
        val after = chunkOffsets(served)
        assertEquals(8, after.size)
        after.forEachIndexed { i, offset ->
            assertArrayEquals("chunk $i must still point at the same sample", before[i % 4], sampleAt(served, offset))
        }
    }

    @Test
    fun `any byte range is the same slice of the whole view, across every part boundary`() {
        val (file, _) = muxerStyleFile()
        val whole = viewBytes(file)!!
        val view = Mp4Faststart.view(file)!!
        val moovStart = topLevelOffsets(asFile(whole))[2]
        val cases = listOf(0L to 10L, 20L to 20L, 3200L to 40L, moovStart - 5 to 30L, moovStart + 100 to 500L,
            whole.size - 1L to 1L, 0L to whole.size.toLong(), 4000L to 30_000L)
        for ((start, count) in cases) {
            val out = ByteArrayOutputStream()
            RandomAccessFile(file, "r").use { view.write(it, start, count, out) }
            assertArrayEquals("range $start+$count", whole.copyOfRange(start.toInt(), (start + count).toInt()), out.toByteArray())
        }
    }

    private fun topLevelOffsets(file: File): List<Long> =
        RandomAccessFile(file, "r").use { Mp4Faststart.topLevelBoxes(it, file.length())!!.map { b -> b.offset } }

    @Test
    fun `the file on disk is never changed`() {
        val (file, _) = muxerStyleFile()
        val bytes = file.readBytes()
        val stamp = file.lastModified()
        viewBytes(file)
        assertArrayEquals(bytes, file.readBytes())
        assertEquals(stamp, file.lastModified())
    }

    @Test
    fun `a clip already in faststart order is served as it is`() {
        val (file, _) = muxerStyleFile()
        assertNull(Mp4Faststart.view(asFile(viewBytes(file)!!)))
    }

    @Test
    fun `a file that does not parse is served as it is`() {
        val (file, _) = muxerStyleFile()
        file.writeBytes(file.readBytes().copyOf(file.length().toInt() - 10))
        assertNull(Mp4Faststart.view(file))
    }

    @Test
    fun `no index or no frames is served as it is`() {
        val file = Files.createTempFile("clip", ".mp4").toFile()
        file.writeBytes(concat(box("ftyp", ByteArray(16)), box("mdat", ByteArray(100))))
        assertNull(Mp4Faststart.view(file))
    }

    @Test
    fun `the view is cached per file, and a changed file gets a fresh one`() {
        val (file, _) = muxerStyleFile()
        val first = Mp4Faststart.view(file)
        assertSame(first, Mp4Faststart.view(file))
        file.setLastModified(file.lastModified() + 60_000)
        assertNotSame(first, Mp4Faststart.view(file))
    }

    @Test
    fun `a 32-bit offset that would overflow refuses the whole view`() {
        val moov = box("moov", box("trak", box("mdia", box("minf", box("stbl", chunkTable("stco", listOf(0xFFFF_FF00L)))))))
        assertFalse(Mp4Faststart.patchChunkOffsets(moov, from = 0, until = 0x1_0000_0000L, delta = 0x200))
    }

    /**
     * A single-track clip as MediaMuxer writes it (BladeWatch-rdtj.31): ftyp, free([freeSize]),
     * mdat, moov -- and the whole track in [chunks], each (samples, gap before it). One chunk with
     * no gaps is what the head unit records.
     */
    private fun trackFile(
        sizes: List<Int>,
        chunks: List<Pair<Int, Int>> = listOf(sizes.size to 0),
        freeSize: Int = 3192,
        uniform: Boolean = false,
        table: String = "stco",
    ): File {
        val ftyp = box("ftyp", "isom\u0000\u0000\u0002\u0000isomiso2avc1mp41".toByteArray(Charsets.ISO_8859_1))
        val free = box("free", ByteArray(freeSize - 8))
        val payload = ByteArrayOutputStream()
        val offsets = ArrayList<Long>()
        val mdatBody = (ftyp.size + free.size + 8).toLong()
        val random = java.util.Random(7)
        var sample = 0
        for ((count, gap) in chunks) {
            payload.write(ByteArray(gap))
            offsets.add(mdatBody + payload.size())
            repeat(count) { payload.write(ByteArray(sizes[sample++]).also(random::nextBytes)) }
        }
        val stsz = if (uniform) ByteBuffer.allocate(12).putInt(0).putInt(sizes[0]).putInt(sizes.size).array()
        else ByteBuffer.allocate(12 + sizes.size * 4).putInt(0).putInt(0).putInt(sizes.size).apply { sizes.forEach { putInt(it) } }.array()
        // Runs of equal-sized chunks, as stsc stores them.
        val runs = ArrayList<IntArray>()
        chunks.forEachIndexed { i, (count, _) -> if (runs.lastOrNull()?.get(1) != count) runs.add(intArrayOf(i + 1, count, 1)) }
        val stsc = ByteBuffer.allocate(8 + runs.size * 12).putInt(0).putInt(runs.size).apply { runs.forEach { r -> r.forEach { putInt(it) } } }.array()
        val stbl = box("stbl", concat(box("stsd", ByteArray(16)), box("stts", ByteArray(16)), box("stsz", stsz), box("stsc", stsc), chunkTable(table, offsets)))
        val trak = box("trak", concat(box("tkhd", ByteArray(84)), box("mdia", concat(box("mdhd", ByteArray(24)), box("minf", stbl)))))
        val moov = box("moov", concat(box("mvhd", ByteArray(100)), trak))
        return Files.createTempFile("clip", ".mp4").toFile().apply { writeBytes(concat(ftyp, free, box("mdat", payload.toByteArray()), moov)) }
    }

    /** The first track's sample table boxes, by type, as (body offset, body size). */
    private fun sampleTables(bytes: ByteArray): Map<String, Pair<Int, Int>> {
        val out = HashMap<String, Pair<Int, Int>>()
        fun walk(start: Int, end: Int) {
            var p = start
            while (p + 8 <= end) {
                val size = ByteBuffer.wrap(bytes, p, 4).int
                val type = String(bytes, p + 4, 4, Charsets.ISO_8859_1)
                if (type in setOf("moov", "trak", "mdia", "minf", "stbl")) walk(p + 8, p + size)
                else if (type !in out) out[type] = (p + 8) to (size - 8)
                p += size
            }
        }
        walk(0, bytes.size)
        return out
    }

    /** Every sample's bytes, found the way a player finds them: stsc runs over the chunk table, sizes from stsz. */
    private fun samples(file: File): List<ByteArray> {
        val bytes = file.readBytes()
        val t = sampleTables(bytes)
        val b = ByteBuffer.wrap(bytes)
        val (stsz, _) = t.getValue("stsz")
        val uniform = b.getInt(stsz + 4)
        val count = b.getInt(stsz + 8)
        val sizes = List(count) { if (uniform != 0) uniform else b.getInt(stsz + 12 + it * 4) }
        val (stsc, _) = t.getValue("stsc")
        val runs = List(b.getInt(stsc + 4)) { intArrayOf(b.getInt(stsc + 8 + it * 12), b.getInt(stsc + 12 + it * 12)) }
        val wide = "co64" in t
        val (table, _) = t.getValue(if (wide) "co64" else "stco")
        val chunks = b.getInt(table + 4)
        val out = ArrayList<ByteArray>()
        for (c in 1..chunks) {
            var at = if (wide) b.getLong(table + 8 + (c - 1) * 8) else b.getInt(table + 8 + (c - 1) * 4).toLong()
            repeat(runs.last { it[0] <= c }[1]) {
                val size = sizes[out.size]
                out.add(bytes.copyOfRange(at.toInt(), at.toInt() + size))
                at += size
            }
        }
        return out
    }

    private fun chunkCount(file: File): Int {
        val bytes = file.readBytes()
        val t = sampleTables(bytes)
        return ByteBuffer.wrap(bytes).getInt((t["stco"] ?: t.getValue("co64")).first + 4)
    }

    @Test
    fun `a one-chunk clip is served in small chunks, every frame where it was, at the same length`() {
        val sizes = List(100) { 500 + it * 37 % 400 }
        val file = trackFile(sizes)
        assertEquals("MediaMuxer's single chunk", 1, chunkCount(file))

        val served = asFile(viewBytes(file)!!)

        assertEquals(listOf("ftyp", "free", "moov", "mdat"), topLevel(served))
        assertEquals(file.length(), served.length())
        assertEquals("one sample per chunk: the smallest cut the free box pays for", 100, chunkCount(served))
        assertEquals(samples(file).map { it.toList() }, samples(served).map { it.toList() })
    }

    @Test
    fun `the cut is only as fine as the free box can pay for`() {
        // One sample per chunk needs 99 more offsets (396 bytes); two per chunk needs 49 (196).
        val file = trackFile(List(100) { 800 }, freeSize = 8 + 200)
        val served = asFile(viewBytes(file)!!)
        assertEquals(50, chunkCount(served))
        assertEquals(file.length(), served.length())
        assertEquals(samples(file).map { it.toList() }, samples(served).map { it.toList() })
    }

    @Test
    fun `with no room to grow the index, the clip is still served index first in its one chunk`() {
        val file = trackFile(List(40) { 900 }, freeSize = 8)
        val served = asFile(viewBytes(file)!!)
        assertEquals(listOf("ftyp", "free", "moov", "mdat"), topLevel(served))
        assertEquals(1, chunkCount(served))
        assertEquals(samples(file).map { it.toList() }, samples(served).map { it.toList() })
    }

    @Test
    fun `uniform sample sizes, several chunk runs, gaps between chunks and 64-bit offsets all survive the cut`() {
        val sizes = List(24) { 640 }
        val file = trackFile(sizes, chunks = listOf(6 to 0, 6 to 300, 8 to 0, 4 to 1_000), uniform = true, table = "co64")
        val served = asFile(viewBytes(file)!!)
        assertEquals(24, chunkCount(served))
        assertEquals(samples(file).map { it.toList() }, samples(served).map { it.toList() })

        val mixed = trackFile(List(24) { 300 + it * 13 }, chunks = listOf(6 to 0, 6 to 300, 8 to 0, 4 to 1_000))
        assertEquals(samples(mixed).map { it.toList() }, samples(asFile(viewBytes(mixed)!!)).map { it.toList() })
    }

    @Test
    fun `nothing to cut or tables that do not add up leave the index as it is`() {
        val oneEach = trackFile(List(10) { 700 }, chunks = List(10) { 1 to 0 })
        assertNull("already one sample per chunk", Mp4Faststart.splitChunks(oneEachIndex(oneEach), room = 10_000))

        // stsz claims more samples than the chunks hold.
        val bytes = oneEach.readBytes()
        val stsz = sampleTables(bytes).getValue("stsz").first
        ByteBuffer.wrap(bytes).putInt(stsz + 8, 11)
        val broken = asFile(bytes)
        assertNull(Mp4Faststart.splitChunks(oneEachIndex(broken), room = 10_000))
        assertEquals("the view still moves the index", listOf("ftyp", "free", "moov", "mdat"), topLevel(asFile(viewBytes(broken)!!)))

        // Chunks that would be cut, but the chunks hold more samples than stsz counts: found only
        // part-way through the walk, and still nothing is cut.
        val twoChunks = trackFile(List(10) { 700 }, chunks = listOf(5 to 0, 5 to 0)).readBytes()
        ByteBuffer.wrap(twoChunks).putInt(sampleTables(twoChunks).getValue("stsz").first + 8, 8)
        assertNull(Mp4Faststart.splitChunks(oneEachIndex(asFile(twoChunks)), room = 10_000))
    }

    private fun oneEachIndex(file: File): ByteArray =
        RandomAccessFile(file, "r").use { raf ->
            val moov = Mp4Faststart.topLevelBoxes(raf, file.length())!!.first { it.type == "moov" }
            ByteArray(moov.size.toInt()).also { raf.seek(moov.offset); raf.readFully(it) }
        }

    @Test
    fun `offsets outside the moved range are not shifted`() {
        val moov = box("moov", box("trak", box("mdia", box("minf", box("stbl", chunkTable("co64", listOf(10L, 500L)))))))
        assertTrue(Mp4Faststart.patchChunkOffsets(moov, from = 100, until = 1_000, delta = 7))
        val entries = ByteBuffer.wrap(moov, moov.size - 16, 16)
        assertEquals("before the frames: unchanged", 10L, entries.long)
        assertEquals(507L, entries.long)
    }
}
