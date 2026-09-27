package net.bladewatch.app.recording

import java.io.ByteArrayOutputStream
import java.io.DataOutputStream
import java.io.RandomAccessFile
import java.nio.ByteBuffer

/**
 * BladeWatch-rdtj.63: serves a fragmented recording (FragmentedMp4Writer's, rdtj.29) as an ordinary
 * one -- one index with every sample in it, then the frames -- without rewriting the file.
 *
 * AVFoundation, the companion's player on iOS and macOS, reads a fragmented file by walking every
 * fragment's header before it plays: a Range request per fragment. Over Pear each costs ~0.4 s, so
 * a 5-minute clip (160 fragments) sat at 0:00 for over a minute; measured 2026-09-27 on this car. The
 * same player started a MediaMuxer clip served through [Mp4Faststart] in 0.9 s, on two requests.
 *
 * The view is `ftyp` (from the file), a rebuilt `moov` whose sample tables list every sample of
 * every fragment (one sample per chunk, as [Mp4Faststart.splitChunks] found AVFoundation wants),
 * an `mdat` header, then each fragment's sample data, straight from the file. It is built only from
 * what FragmentedMp4Writer writes -- one video track, per-sample duration/size/flags in `trun`, no
 * composition offsets, version-0 headers -- and returns null for anything else, so the file is then
 * served as it is.
 */
internal object Mp4Defragment {
    private const val NON_SYNC = 0x00010000

    private class Fragment(val dataOffset: Long, val dataSize: Long)

    fun build(raf: RandomAccessFile, boxes: List<Mp4Faststart.Box>): Mp4Faststart.View? {
        val ftyp = boxes.firstOrNull { it.type == "ftyp" } ?: return null
        val moovBox = boxes.firstOrNull { it.type == "moov" } ?: return null
        if (moovBox.size > Int.MAX_VALUE) return null
        val moov = ByteArray(moovBox.size.toInt()).also { raf.seek(moovBox.offset); raf.readFully(it) }

        val durations = ArrayList<Long>()
        val sizes = ArrayList<Long>()
        val sync = ArrayList<Boolean>()
        val fragments = ArrayList<Fragment>()
        for ((i, box) in boxes.withIndex()) {
            if (box.type != "moof") continue
            val mdat = boxes.getOrNull(i + 1)?.takeIf { it.type == "mdat" } ?: return null
            if (box.size > 1_000_000) return null
            val moof = ByteArray(box.size.toInt()).also { raf.seek(box.offset); raf.readFully(it) }
            val before = sizes.size
            val dataOffset = readMoof(moof, durations, sizes, sync) ?: return null
            val start = box.offset + dataOffset
            val size = (before until sizes.size).sumOf { sizes[it] }
            // The samples must lie inside the fragment's own mdat.
            if (start < mdat.offset + 8 || start + size > mdat.offset + mdat.size) return null
            fragments.add(Fragment(start, size))
        }
        if (sizes.isEmpty()) return null

        val payload = fragments.sumOf { it.dataSize }
        val mdatHeader = if (payload + 8 <= 0xFFFFFFFFL) {
            ByteBuffer.allocate(8).putInt((payload + 8).toInt()).put("mdat".toByteArray(Charsets.ISO_8859_1)).array()
        } else {
            ByteBuffer.allocate(16).putInt(1).put("mdat".toByteArray(Charsets.ISO_8859_1)).putLong(payload + 16).array()
        }

        // The index's size does not depend on the offsets in it: build it once to learn where the
        // frames start, then again with the real offsets.
        var wide = false
        var index = rebuild(moov, tables(durations, sizes, sync, 0, wide)) ?: return null
        var dataStart = ftyp.size + index.size + mdatHeader.size
        if (dataStart + payload > 0xFFFFFFFFL) {
            wide = true
            index = rebuild(moov, tables(durations, sizes, sync, 0, wide)) ?: return null
            dataStart = ftyp.size + index.size + mdatHeader.size
        }
        index = rebuild(moov, tables(durations, sizes, sync, dataStart, wide)) ?: return null

        val parts = ArrayList<Mp4Faststart.View.Part>()
        var at = 0L
        fun add(length: Long, fileOffset: Long, bytes: ByteArray?) {
            parts.add(Mp4Faststart.View.Part(at, length, fileOffset, bytes))
            at += length
        }
        add(ftyp.size, ftyp.offset, null)
        add(index.size.toLong(), 0, index)
        add(mdatHeader.size.toLong(), 0, mdatHeader)
        for (f in fragments) add(f.dataSize, f.dataOffset, null)
        return Mp4Faststart.View(at, parts, TAG)
    }

    /** The ETag suffix of this layout; change it whenever the bytes it serves do. */
    const val TAG = "df1"

    /**
     * Adds one fragment's samples to the lists; returns its trun data offset (from the moof's start,
     * default-base-is-moof), or null for anything FragmentedMp4Writer does not write.
     */
    private fun readMoof(moof: ByteArray, durations: MutableList<Long>, sizes: MutableList<Long>, sync: MutableList<Boolean>): Long? {
        val buf = ByteBuffer.wrap(moof)
        val traf = child(moof, 8, moof.size, "traf") ?: return null
        val tfhd = child(moof, traf.first + 8, traf.first + traf.second, "tfhd") ?: return null
        val tfhdFlags = buf.getInt(tfhd.first + 8) and 0xFFFFFF
        if (tfhd.second < 16 || tfhdFlags != 0x020000) return null // base-is-moof, and no per-fragment defaults
        val trun = child(moof, traf.first + 8, traf.first + traf.second, "trun") ?: return null
        val flags = buf.getInt(trun.first + 8) and 0xFFFFFF
        if (flags != 0x701) return null // data offset + per-sample duration, size and flags; no cto
        val count = buf.getInt(trun.first + 12)
        if (count <= 0 || trun.second < 20 + count.toLong() * 12) return null
        val dataOffset = buf.getInt(trun.first + 16).toLong()
        var p = trun.first + 20
        repeat(count) {
            durations.add(buf.getInt(p).toLong() and 0xFFFFFFFFL)
            sizes.add(buf.getInt(p + 4).toLong() and 0xFFFFFFFFL)
            sync.add((buf.getInt(p + 8) and NON_SYNC) == 0)
            p += 12
        }
        return dataOffset
    }

    /** The first child box of [type] in [from, until): (offset, size), or null. */
    private fun child(src: ByteArray, from: Int, until: Int, type: String): Pair<Int, Int>? {
        var p = from
        val buf = ByteBuffer.wrap(src)
        while (p + 8 <= until) {
            val size = buf.getInt(p)
            if (size < 8 || p + size > until) return null
            if (String(src, p + 4, 4, Charsets.ISO_8859_1) == type) return p to size
            p += size
        }
        return null
    }

    private class Tables(val boxes: ByteArray, val mediaDuration: Long)

    private fun tables(durations: List<Long>, sizes: List<Long>, sync: List<Boolean>, dataStart: Long, wide: Boolean): Tables {
        val out = ByteArrayOutputStream()
        // stts: runs of equal durations.
        val runs = ArrayList<Pair<Int, Long>>()
        for (d in durations) {
            if (runs.isNotEmpty() && runs.last().second == d) runs[runs.size - 1] = runs.last().first + 1 to d else runs.add(1 to d)
        }
        out.write(full("stts") { w ->
            w.writeInt(runs.size)
            runs.forEach { (n, d) -> w.writeInt(n); w.writeInt(d.toInt()) }
        })
        // stss, only when some sample is not a keyframe (no stss means every sample is one).
        if (sync.any { !it }) {
            val keys = sync.indices.filter { sync[it] }
            out.write(full("stss") { w -> w.writeInt(keys.size); keys.forEach { w.writeInt(it + 1) } })
        }
        // stsc: every chunk is one sample.
        out.write(full("stsc") { w -> w.writeInt(1); w.writeInt(1); w.writeInt(1); w.writeInt(1) })
        out.write(full("stsz") { w -> w.writeInt(0); w.writeInt(sizes.size); sizes.forEach { w.writeInt(it.toInt()) } })
        out.write(full(if (wide) "co64" else "stco") { w ->
            w.writeInt(sizes.size)
            var offset = dataStart
            for (s in sizes) {
                if (wide) w.writeLong(offset) else w.writeInt(offset.toInt())
                offset += s
            }
        })
        return Tables(out.toByteArray(), durations.sum())
    }

    private fun full(type: String, body: (DataOutputStream) -> Unit): ByteArray {
        val bytes = ByteArrayOutputStream()
        DataOutputStream(bytes).use { w ->
            w.writeInt(0) // version 0, flags 0
            body(w)
        }
        return box(type, bytes.toByteArray())
    }

    private fun box(type: String, body: ByteArray): ByteArray =
        ByteBuffer.allocate(8 + body.size).putInt(8 + body.size).put(type.toByteArray(Charsets.ISO_8859_1)).put(body).array()

    /**
     * The init `moov` as an ordinary one: `mvex` dropped, the sample tables of `stbl` replaced
     * (its `stsd` kept), and the durations of `mvhd`, `tkhd` and `mdhd` set. Null when a box it has
     * to patch is not version 0.
     */
    private fun rebuild(moov: ByteArray, t: Tables): ByteArray? {
        val buf = ByteBuffer.wrap(moov)
        val mvhd = child(moov, 8, moov.size, "mvhd") ?: return null
        if (moov[mvhd.first + 8].toInt() != 0) return null
        val movieScale = buf.getInt(mvhd.first + 20).toLong()
        val trak = child(moov, 8, moov.size, "trak") ?: return null
        val mdia = child(moov, trak.first + 8, trak.first + trak.second, "mdia") ?: return null
        val mdhd = child(moov, mdia.first + 8, mdia.first + mdia.second, "mdhd") ?: return null
        if (moov[mdhd.first + 8].toInt() != 0) return null
        val mediaScale = buf.getInt(mdhd.first + 20).toLong()
        if (movieScale <= 0 || mediaScale <= 0) return null
        val movieDuration = t.mediaDuration * movieScale / mediaScale

        fun walk(at: Int, size: Int): ByteArray? {
            val type = String(moov, at + 4, 4, Charsets.ISO_8859_1)
            return when (type) {
                "moov", "trak", "mdia", "minf" -> {
                    val out = ByteArrayOutputStream()
                    var p = at + 8
                    while (p < at + size) {
                        val s = buf.getInt(p)
                        if (s < 8 || p + s > at + size) return null
                        if (String(moov, p + 4, 4, Charsets.ISO_8859_1) != "mvex") out.write(walk(p, s) ?: return null)
                        p += s
                    }
                    box(type, out.toByteArray())
                }
                "stbl" -> {
                    val stsd = child(moov, at + 8, at + size, "stsd") ?: return null
                    box("stbl", moov.copyOfRange(stsd.first, stsd.first + stsd.second) + t.boxes)
                }
                "mvhd", "mdhd", "tkhd" -> {
                    if (moov[at + 8].toInt() != 0) return null
                    val copy = moov.copyOfRange(at, at + size)
                    // v0: duration after version/flags, creation, modification and the timescale
                    // (mvhd, mdhd) or the track ID and a reserved word (tkhd).
                    val field = if (type == "tkhd") 28 else 24
                    val value = if (type == "mdhd") t.mediaDuration else movieDuration
                    if (value > 0xFFFFFFFFL) return null
                    ByteBuffer.wrap(copy).putInt(field, value.toInt())
                    copy
                }
                else -> moov.copyOfRange(at, at + size)
            }
        }
        return walk(0, moov.size)
    }
}
