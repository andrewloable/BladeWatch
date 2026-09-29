package net.bladewatch.app.recording

import java.io.File
import java.io.OutputStream
import java.io.RandomAccessFile
import java.nio.ByteBuffer

/**
 * BladeWatch-rdtj.28: serves a recording with its index (the `moov` box) in front of its frames,
 * so a player streaming the clip can start as soon as the first bytes arrive -- without ever
 * rewriting the file.
 *
 * MediaMuxer writes `ftyp`, a ~3 KB `free` box, `mdat` (the frames), then `moov` last: Android's
 * MPEG4Writer reserves only its minimum index space when it gets no duration or size hint, and
 * MediaMuxer cannot give it one. A player then has to reach the END of the file before it can
 * show anything. Measured on a 69.6 MB, 92 s clip over Pear: ~47 s to the first frame on the
 * car's LAN, and never from mobile data.
 *
 * A [View] is the same bytes in faststart order: `ftyp`, `free`, the index with every chunk offset
 * moved down by the index's size, then `mdat`. Same length. The file on disk never changes, so
 * there is no second write on the SD card, no temp file a power cut can strand, and no window in
 * which a resumed download could splice two layouts -- and every clip already on the card gets it.
 * Checked on a real MediaMuxer clip: identical length, and every decoded frame identical (ffmpeg
 * frame MD5).
 */
object Mp4Faststart {

    /** Bytes [start, start + count) of the faststart layout, read from the original file. */
    class View internal constructor(val length: Long, private val parts: List<Part>, val tag: String = TAG) {

        /** A stretch of the view: [bytes] when set (the patched index), else the file at [fileOffset]. */
        internal class Part(val viewStart: Long, val length: Long, val fileOffset: Long, val bytes: ByteArray?)

        fun write(raf: RandomAccessFile, start: Long, count: Long, out: OutputStream) {
            require(start >= 0 && count >= 0 && start + count <= length) { "range outside the view" }
            val end = start + count
            val buffer = ByteArray(16384)
            for (part in parts) {
                val partEnd = part.viewStart + part.length
                if (partEnd <= start || part.viewStart >= end) continue
                val from = maxOf(start, part.viewStart) - part.viewStart
                var left = minOf(end, partEnd) - part.viewStart - from
                if (part.bytes != null) {
                    // The patched index, or the free box that paid for its growth.
                    out.write(part.bytes, from.toInt(), left.toInt())
                    continue
                }
                raf.seek(part.fileOffset + from)
                while (left > 0) {
                    val n = raf.read(buffer, 0, minOf(buffer.size.toLong(), left).toInt())
                    if (n <= 0) throw java.io.EOFException("recording shrank while being served")
                    out.write(buffer, 0, n)
                    left -= n
                }
            }
        }
    }

    /** The ETag suffix of this layout ("fs2" since rdtj.31 cut the chunks): change it with the bytes. */
    const val TAG = "fs2"

    private const val CACHE_SIZE = 32

    // Keyed by path, length and mtime: a replaced or rewritten file gets a fresh view. Each entry
    // holds only the patched index (17 KB for a 92 s clip), never frames.
    private val cache = object : LinkedHashMap<String, View?>(CACHE_SIZE, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, View?>) = size > CACHE_SIZE
    }

    /**
     * The faststart view of [file] -- or for a fragmented clip, the defragmented one (rdtj.63) -- or
     * null when it is already faststart, cannot be parsed, or its 32-bit offsets would overflow:
     * serve the file as it is then. Never throws.
     */
    fun view(file: File): View? {
        val key = file.absolutePath + "|" + file.length() + "|" + file.lastModified()
        synchronized(cache) { if (cache.containsKey(key)) return cache[key] }
        val view = try {
            RandomAccessFile(file, "r").use { build(it, file.length()) }
        } catch (_: Exception) {
            null
        }
        synchronized(cache) { cache[key] = view }
        return view
    }

    internal fun build(raf: RandomAccessFile, length: Long): View? {
        val boxes = topLevelBoxes(raf, length) ?: return null
        // BladeWatch-rdtj.63: a fragmented clip is served as an ordinary one, index first.
        if (boxes.any { it.type == "moof" }) return Mp4Defragment.build(raf, boxes)
        val moovAt = boxes.indexOfFirst { it.type == "moov" }
        val mdatAt = boxes.indexOfFirst { it.type == "mdat" }
        if (moovAt < 0 || mdatAt < 0 || moovAt < mdatAt) return null
        val moov = boxes[moovAt]
        val firstMdat = boxes[mdatAt]
        if (moov.size > Int.MAX_VALUE) return null
        var index = ByteArray(moov.size.toInt())
        raf.seek(moov.offset)
        raf.readFully(index)

        // BladeWatch-rdtj.31: cut the chunks small, paying for the bigger index out of a free box in
        // front of the frames -- so the frames do not move and the length stays the same.
        val free = boxes.take(mdatAt).lastOrNull { it.type == "free" || it.type == "skip" }
        var freeBytes: ByteArray? = null
        if (free != null && free.size <= Int.MAX_VALUE) {
            val split = splitChunks(index, room = free.size - 8)
            if (split != null) {
                val size = (free.size - (split.size - index.size)).toInt()
                freeBytes = ByteBuffer.allocate(size).putInt(size).put("free".toByteArray(Charsets.ISO_8859_1)).array()
                index = split
            }
        }
        // Everything from the first mdat up to the old index moves down by the old index's size.
        if (!patchChunkOffsets(index, from = firstMdat.offset, until = moov.offset, delta = moov.size)) return null

        val order = boxes.filter { it !== moov }.toMutableList()
        order.add(order.indexOf(firstMdat), moov)
        var at = 0L
        val parts = order.map { box ->
            val bytes = when {
                box === moov -> index
                box === free -> freeBytes
                else -> null
            }
            val part = View.Part(at, bytes?.size?.toLong() ?: box.size, box.offset, bytes)
            at += part.length
            part
        }
        return if (at == length) View(length, parts) else null
    }

    /**
     * BladeWatch-rdtj.31: [moov] with every chunk cut into runs of at most K samples, for the
     * smallest K whose index grows by no more than [room] bytes; null when nothing needs cutting, it
     * cannot fit, or a table does not parse (the caller keeps the index as it is).
     *
     * MediaMuxer writes a single-track clip as ONE chunk -- MPEG4Writer only cuts chunks to
     * interleave several tracks -- and AVFoundation (the companion on iOS and macOS) uses no sample
     * of a chunk before the whole chunk has arrived. So a 69.6 MB clip played nothing until all of
     * it had downloaded, even with its index first. Cut into two-frame chunks it started after
     * ~1.5 s at 1.4 MB/s, and every decoded frame was identical (ffmpeg frame MD5).
     */
    internal fun splitChunks(moov: ByteArray, room: Long): ByteArray? {
        var k = 1L
        while (true) {
            val cut = BooleanArray(1)
            val split = rebuild(moov, 0, moov.size, k, cut) ?: return null
            if (!cut[0]) return null
            if (split.size - moov.size <= room) return split
            k *= 2
        }
    }

    /** Boxes tiling [from, until) of [src] as (offset, size), or null. Inside an index every box has a plain 32-bit size. */
    private fun children(src: ByteArray, from: Int, until: Int): List<Pair<Int, Int>>? {
        val out = ArrayList<Pair<Int, Int>>()
        var pos = from
        while (pos < until) {
            if (until - pos < 8) return null
            val size = ByteBuffer.wrap(src).getInt(pos).toLong() and 0xFFFFFFFFL
            if (size < 8 || pos + size > until) return null
            out.add(pos to size.toInt())
            pos += size.toInt()
        }
        return out
    }

    private fun box(type: String, body: ByteArray): ByteArray =
        ByteBuffer.allocate(8 + body.size).putInt(8 + body.size).put(type.toByteArray(Charsets.ISO_8859_1)).put(body).array()

    private fun type(src: ByteArray, at: Int) = String(src, at + 4, 4, Charsets.ISO_8859_1)

    /** The box at [at] rebuilt with its sample tables cut to [k] samples per chunk; [cut] records whether any chunk was. */
    private fun rebuild(src: ByteArray, at: Int, size: Int, k: Long, cut: BooleanArray): ByteArray? {
        val type = type(src, at)
        if (type !in CONTAINERS) return src.copyOfRange(at, at + size)
        val kids = children(src, at + 8, at + size) ?: return null
        if (type == "stbl") return splitTable(src, at, size, kids, k, cut)
        val body = java.io.ByteArrayOutputStream()
        for ((kidAt, kidSize) in kids) body.write(rebuild(src, kidAt, kidSize, k, cut) ?: return null)
        return box(type, body.toByteArray())
    }

    /** One track's stbl with its chunks cut; unchanged when its tables are missing or do not add up. */
    private fun splitTable(src: ByteArray, at: Int, size: Int, kids: List<Pair<Int, Int>>, k: Long, cut: BooleanArray): ByteArray {
        val unchanged = src.copyOfRange(at, at + size)
        val byType = kids.associateBy { type(src, it.first) }
        val stsz = byType["stsz"] ?: return unchanged
        val stsc = byType["stsc"] ?: return unchanged
        val offsetsBox = byType["stco"] ?: byType["co64"] ?: return unchanged
        val wide = type(src, offsetsBox.first) == "co64"
        val buf = ByteBuffer.wrap(src)

        if (stsz.second < 20) return unchanged
        val uniform = buf.getInt(stsz.first + 12).toLong() and 0xFFFFFFFFL
        val samples = buf.getInt(stsz.first + 16).toLong() and 0xFFFFFFFFL
        if (samples > Int.MAX_VALUE || uniform == 0L && 20 + samples * 4 > stsz.second) return unchanged
        fun sampleSize(i: Int) = if (uniform != 0L) uniform else buf.getInt(stsz.first + 20 + i * 4).toLong() and 0xFFFFFFFFL

        if (stsc.second < 16) return unchanged
        val runs = buf.getInt(stsc.first + 12).toLong() and 0xFFFFFFFFL
        if (16 + runs * 12 > stsc.second) return unchanged
        val firstChunk = LongArray(runs.toInt()) { buf.getInt(stsc.first + 16 + it * 12).toLong() and 0xFFFFFFFFL }
        val perChunk = LongArray(runs.toInt()) { buf.getInt(stsc.first + 20 + it * 12).toLong() and 0xFFFFFFFFL }
        val description = IntArray(runs.toInt()) { buf.getInt(stsc.first + 24 + it * 12) }

        if (offsetsBox.second < 16) return unchanged
        val width = if (wide) 8 else 4
        val chunks = buf.getInt(offsetsBox.first + 12).toLong() and 0xFFFFFFFFL
        if (16 + chunks * width > offsetsBox.second) return unchanged
        if (runs == 0L || firstChunk[0] != 1L || perChunk.any { it > samples }) return unchanged

        // Walk every chunk, cutting it into pieces of at most k samples: (offset, samples, description).
        val newOffsets = ArrayList<Long>()
        val newRuns = ArrayList<LongArray>()
        var run = 0
        var sample = 0L
        var any = false
        for (c in 1..chunks) {
            while (run + 1 < runs && firstChunk[run + 1] <= c) run++
            var offset = if (wide) buf.getLong(offsetsBox.first + 16 + ((c - 1) * 8).toInt())
            else buf.getInt(offsetsBox.first + 16 + ((c - 1) * 4).toInt()).toLong() and 0xFFFFFFFFL
            var left = perChunk[run]
            if (left > k) any = true
            while (left > 0) {
                val n = minOf(k, left)
                if (sample + n > samples) return unchanged
                newOffsets.add(offset)
                val last = newRuns.lastOrNull()
                if (last == null || last[1] != n || last[2].toInt() != description[run]) {
                    newRuns.add(longArrayOf(newOffsets.size.toLong(), n, description[run].toLong()))
                }
                for (i in 0 until n.toInt()) offset += sampleSize((sample + i).toInt())
                sample += n
                left -= n
            }
        }
        if (!any || sample != samples || newOffsets.any { !wide && it > 0xFFFFFFFFL }) return unchanged
        cut[0] = true

        val newStsc = ByteBuffer.allocate(8 + newRuns.size * 12)
            .put(src, stsc.first + 8, 4).putInt(newRuns.size)
            .apply { newRuns.forEach { putInt(it[0].toInt()).putInt(it[1].toInt()).putInt(it[2].toInt()) } }.array()
        val newTable = ByteBuffer.allocate(8 + newOffsets.size * width)
            .put(src, offsetsBox.first + 8, 4).putInt(newOffsets.size)
            .apply { newOffsets.forEach { if (wide) putLong(it) else putInt(it.toInt()) } }.array()
        val body = java.io.ByteArrayOutputStream()
        for (kid in kids) {
            body.write(
                when (kid) {
                    stsc -> box("stsc", newStsc)
                    offsetsBox -> box(if (wide) "co64" else "stco", newTable)
                    else -> src.copyOfRange(kid.first, kid.first + kid.second)
                }
            )
        }
        return box("stbl", body.toByteArray())
    }

    internal data class Box(val type: String, val offset: Long, val size: Long)

    /** The file's top-level boxes, or null if they do not tile it exactly. */
    internal fun topLevelBoxes(raf: RandomAccessFile, length: Long): List<Box>? {
        val boxes = ArrayList<Box>()
        var pos = 0L
        val header = ByteArray(16)
        while (pos < length) {
            if (length - pos < 8) return null
            raf.seek(pos)
            raf.readFully(header, 0, 8)
            val buf = ByteBuffer.wrap(header)
            var size = buf.getInt(0).toLong() and 0xFFFFFFFFL
            val type = String(header, 4, 4, Charsets.ISO_8859_1)
            var headerSize = 8L
            when (size) {
                0L -> size = length - pos
                1L -> {
                    if (length - pos < 16) return null
                    raf.readFully(header, 8, 8)
                    size = buf.getLong(8)
                    headerSize = 16L
                }
            }
            if (size < headerSize || pos + size > length) return null
            boxes.add(Box(type, pos, size))
            pos += size
        }
        return boxes
    }

    private val CONTAINERS = setOf("moov", "trak", "mdia", "minf", "stbl")

    /**
     * Adds [delta] to every `stco`/`co64` entry in [from, until). Returns false if the box tree is
     * malformed or a 32-bit `stco` entry would overflow -- the caller then serves the file as-is.
     */
    internal fun patchChunkOffsets(moov: ByteArray, from: Long, until: Long, delta: Long): Boolean {
        val buf = ByteBuffer.wrap(moov)
        fun walk(start: Int, end: Int): Boolean {
            var pos = start
            while (pos + 8 <= end) {
                var size = buf.getInt(pos).toLong() and 0xFFFFFFFFL
                val type = String(moov, pos + 4, 4, Charsets.ISO_8859_1)
                var header = 8
                if (size == 1L) {
                    if (pos + 16 > end) return false
                    size = buf.getLong(pos + 8)
                    header = 16
                } else if (size == 0L) {
                    size = (end - pos).toLong()
                }
                if (size < header || pos + size > end) return false
                val body = pos + header
                val boxEnd = (pos + size).toInt()
                when (type) {
                    in CONTAINERS -> if (!walk(body, boxEnd)) return false
                    "stco", "co64" -> {
                        if (body + 8 > boxEnd) return false
                        val count = buf.getInt(body + 4).toLong() and 0xFFFFFFFFL
                        val width = if (type == "stco") 4 else 8
                        if (body + 8 + count * width > boxEnd) return false
                        for (i in 0 until count.toInt()) {
                            val at = body + 8 + i * width
                            val offset = if (width == 4) buf.getInt(at).toLong() and 0xFFFFFFFFL else buf.getLong(at)
                            if (offset < from || offset >= until) continue
                            val moved = offset + delta
                            if (width == 4) {
                                if (moved > 0xFFFFFFFFL) return false
                                buf.putInt(at, moved.toInt())
                            } else {
                                buf.putLong(at, moved)
                            }
                        }
                    }
                }
                pos = boxEnd
            }
            return pos == end
        }
        if (moov.size < 8) return false
        val top = buf.getInt(0).toLong() and 0xFFFFFFFFL
        val header = if (top == 1L) 16 else 8
        return walk(header, moov.size)
    }
}
