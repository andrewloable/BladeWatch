package net.bladewatch.app.recording

import java.io.ByteArrayOutputStream
import java.io.File
import java.io.RandomAccessFile
import java.nio.ByteBuffer

/**
 * BladeWatch-rdtj.29: writes a recording as FRAGMENTED MP4, instead of MediaMuxer's index-last
 * layout.
 *
 * MediaMuxer writes the frames first and the index (`moov`) only when it is stopped. So a remote
 * player has to reach the end of the file before it can show a frame (see [Mp4Faststart], which
 * works around that when serving), and a clip cut off mid-recording -- power loss, a killed
 * daemon -- has no index at all and plays nothing, every minute already recorded included.
 *
 * Here the file is:
 *  - `ftyp`, then a `moov` that describes the track (codec configuration, `mvex`) but holds no
 *    samples: it is written first, so a player can start from the first bytes;
 *  - a reserved `free` box, where [finish] later writes a segment index (`sidx`);
 *  - the frames, one `moof` + `mdat` fragment per group of pictures (a keyframe and what follows).
 *    Each fragment is complete on its own, so a file cut off anywhere plays up to its last
 *    complete fragment;
 *  - on a clean [finish]: the durations patched into `moov`, a `sidx` in the reserved space (what
 *    ExoPlayer seeks with) and an `mfra` random-access box at the end (what QuickTime/AVFoundation
 *    and ffmpeg seek with). A file that never reached [finish] has neither; players still play it.
 *
 * Input is what MediaCodec gives MediaMuxer: Annex-B access units (start-code delimited NAL units),
 * presentation times in microseconds, in decode order, with no B-frames (BladeWatch's encoders
 * have none; [writeSample] drops a frame whose time goes backwards rather than break the file). The NAL units are rewritten
 * length-prefixed, as MP4 requires, and parameter sets are left out of the samples: they are in the
 * sample description (`avc1`/`hvc1`, which AVFoundation insists on for HEVC).
 *
 * Plain JVM code with no Android types, so it is unit-tested directly; [RecordingMuxer] adapts it
 * to the recorder.
 */
class FragmentedMp4Writer(
    private val file: File,
    private val track: Track,
    /** Room kept after `moov` for the `sidx`: 12 bytes per fragment plus 32. */
    private val indexReserve: Int = DEFAULT_INDEX_RESERVE,
) {
    /** A video track's setup: what MediaMuxer.addTrack's MediaFormat carried. */
    class Track(
        val hevc: Boolean,
        val width: Int,
        val height: Int,
        /** csd-0: the SPS for H.264; VPS + SPS + PPS for H.265. Annex-B, as MediaCodec gives it. */
        val csd0: ByteArray,
        /** csd-1: the PPS for H.264; unused for H.265. */
        val csd1: ByteArray? = null,
    )

    private class Sample(val data: ByteArray, val pts: Long, val sync: Boolean)

    internal class Fragment(val offset: Long, val size: Long, val startTime: Long, val duration: Long)

    private val out = RandomAccessFile(file, "rw").also { it.setLength(0) }
    private val pending = ArrayList<Sample>()
    private val fragments = ArrayList<Fragment>()
    private var sequence = 0
    private var firstPtsUs = -1L
    private var lastPts = -1L
    private var lastDuration = 0L
    private var closed = false

    // Where the free box that becomes mehd at finish sits.
    private var mehdAt = 0L
    private var reserveAt = 0L

    /** Samples written so far (a fragment in memory not included). */
    var writtenSamples = 0
        private set

    /** Frames refused because their time went backwards. */
    var droppedSamples = 0
        private set

    init {
        out.write(ftyp(track.hevc))
        val moov = Moov(track).bytes()
        val moovAt = out.filePointer
        out.write(moov.data)
        mehdAt = moovAt + moov.mehdAt
        reserveAt = out.filePointer
        out.write(freeBox(indexReserve))
    }

    /**
     * One access unit. A keyframe starts a new fragment, which writes the previous one out: a
     * fragment is only ever on disk whole.
     */
    fun writeSample(data: ByteBuffer, ptsUs: Long, keyFrame: Boolean) {
        check(!closed) { "writer finished" }
        if (firstPtsUs < 0) {
            // A file must open on a keyframe: nothing before one can be decoded.
            if (!keyFrame) return
            firstPtsUs = ptsUs
        }
        val pts = toTimescale(ptsUs - firstPtsUs)
        if (pts < lastPts) {
            // Not expected (no B-frames), and not worth losing the recording over: the frame goes.
            droppedSamples++
            return
        }
        if (keyFrame && pending.isNotEmpty()) flush(nextPts = pts)
        pending.add(Sample(toLengthPrefixed(data, track.hevc), pts, keyFrame))
        lastPts = pts
    }

    /**
     * Writes the last fragment, the index and the durations, and closes the file. Returns false if
     * the file holds no frame, which the caller treats as an empty recording.
     */
    fun finish(): Boolean {
        if (closed) return fragments.isNotEmpty()
        if (pending.isNotEmpty()) flush(nextPts = -1)
        closed = true
        try {
            if (fragments.isEmpty()) return false
            writeTrailer(out, mehdAt, reserveAt, indexReserve, fragments)
            return true
        } finally {
            out.close()
        }
    }

    /**
     * Closes without finishing -- no trailer, the fragment in memory dropped: the file a crash
     * leaves, and what a recording that failed to stop keeps. It still plays; [recover] finishes it.
     * Nothing happens after [finish].
     */
    fun close() {
        if (closed) return
        closed = true
        out.close()
    }

    private fun flush(nextPts: Long) {
        // Each sample lasts until the next one starts; the file's last sample repeats the one
        // before it, as MediaMuxer does.
        val durations = LongArray(pending.size) { i ->
            val next = if (i + 1 < pending.size) pending[i + 1].pts else nextPts
            if (next < 0) lastDuration else (next - pending[i].pts).also { if (it > 0) lastDuration = it }
        }
        if (durations.isNotEmpty() && durations.last() <= 0) durations[durations.size - 1] = lastDuration.coerceAtLeast(1)
        val offset = out.length()
        val moof = moof(++sequence, pending.first().pts, pending, durations)
        val mdatSize = 8L + pending.sumOf { it.data.size.toLong() }
        out.seek(offset)
        out.write(moof)
        out.write(boxHeader(mdatSize, "mdat"))
        for (s in pending) out.write(s.data)
        fragments.add(Fragment(offset, moof.size + mdatSize, pending.first().pts, durations.sum()))
        writtenSamples += pending.size
        pending.clear()
    }

    private fun moof(seq: Int, baseTime: Long, samples: List<Sample>, durations: LongArray): ByteArray {
        val mfhd = Box("mfhd", version = 0).apply { u32(seq.toLong()) }.bytes()
        // default-base-is-moof: data offsets count from this moof's first byte.
        val tfhd = Box("tfhd", version = 0, flags = 0x020000).apply { u32(1) }.bytes()
        val tfdt = Box("tfdt", version = 1).apply { u64(baseTime) }.bytes()
        // data-offset, sample-duration, -size and -flags present.
        val trun = Box("trun", version = 0, flags = 0x000701)
        trun.u32(samples.size.toLong())
        val trunSize = 12 + 4 + 4 + 12 * samples.size
        val moofSize = 8 + mfhd.size + 8 + tfhd.size + tfdt.size + trunSize
        trun.u32(moofSize + 8L) // data_offset: past the moof and the mdat header
        for ((i, s) in samples.withIndex()) {
            trun.u32(durations[i])
            trun.u32(s.data.size.toLong())
            trun.u32(if (s.sync) SYNC_SAMPLE else NON_SYNC_SAMPLE)
        }
        val traf = container("traf", tfhd, tfdt, trun.bytes())
        return container("moof", mfhd, traf)
    }

    /** moov and where its duration fields are, relative to its start. */
    private class Moov(private val track: Track) {
        class Built(val data: ByteArray, val mehdAt: Int)

        fun bytes(): Built {
            val mvhd = Box("mvhd", version = 0).apply {
                u32(0); u32(0) // creation, modification
                u32(MOVIE_TIMESCALE)
                u32(0) // duration: 0, the samples in moov itself (none); mehd has the length
                u32(0x00010000) // rate 1.0
                u16(0x0100) // volume 1.0
                zeros(10)
                matrix()
                zeros(24) // pre_defined
                u32(2) // next_track_ID
            }.bytes()
            val tkhd = Box("tkhd", version = 0, flags = 0x000003).apply {
                u32(0); u32(0)
                u32(1) // track_ID
                u32(0) // reserved
                u32(0) // duration 0, as in mvhd
                zeros(8)
                u16(0); u16(0) // layer, alternate_group
                u16(0) // volume: video
                u16(0)
                matrix()
                u32(track.width.toLong() shl 16)
                u32(track.height.toLong() shl 16)
            }.bytes()
            val mdhd = Box("mdhd", version = 0).apply {
                u32(0); u32(0)
                u32(TIMESCALE)
                u32(0) // duration 0, as in mvhd
                u16(0x55C4) // language 'und'
                u16(0)
            }.bytes()
            val hdlr = Box("hdlr", version = 0).apply {
                u32(0)
                fourcc("vide")
                zeros(12)
                bytes("VideoHandler".toByteArray() + 0)
            }.bytes()
            val vmhd = Box("vmhd", version = 0, flags = 1).apply { zeros(8) }.bytes()
            val dref = Box("dref", version = 0).apply {
                u32(1)
                bytes(Box("url ", version = 0, flags = 1).bytes())
            }.bytes()
            val dinf = container("dinf", dref)
            val stsd = Box("stsd", version = 0).apply {
                u32(1)
                bytes(sampleEntry())
            }.bytes()
            val stts = Box("stts", version = 0).apply { u32(0) }.bytes()
            val stsc = Box("stsc", version = 0).apply { u32(0) }.bytes()
            val stsz = Box("stsz", version = 0).apply { u32(0); u32(0) }.bytes()
            val stco = Box("stco", version = 0).apply { u32(0) }.bytes()
            val stbl = container("stbl", stsd, stts, stsc, stsz, stco)
            val minf = container("minf", vmhd, dinf, stbl)
            val mdia = container("mdia", mdhd, hdlr, minf)
            val trak = container("trak", tkhd, mdia)
            // mehd's 16 bytes, held as a free box until finish writes the real length.
            val mehd = freeBox(MEHD_SIZE)
            val trex = Box("trex", version = 0).apply {
                u32(1) // track_ID
                u32(1) // default_sample_description_index
                u32(0); u32(0); u32(0)
            }.bytes()
            val mvex = container("mvex", mehd, trex)
            val moov = container("moov", mvhd, trak, mvex)
            val mvexAt = 8 + mvhd.size + trak.size
            return Built(moov, mehdAt = mvexAt + 8)
        }

        private fun sampleEntry(): ByteArray {
            val config = if (track.hevc) hvcC(splitNals(track.csd0)) else avcC(splitNals(track.csd0) + splitNals(track.csd1 ?: ByteArray(0)))
            return Box(if (track.hevc) "hvc1" else "avc1").apply {
                zeros(6)
                u16(1) // data_reference_index
                zeros(16) // pre_defined, reserved
                u16(track.width)
                u16(track.height)
                u32(0x00480000) // 72 dpi
                u32(0x00480000)
                u32(0)
                u16(1) // frame_count
                zeros(32) // compressorname
                u16(0x0018) // depth
                u16(0xFFFF) // pre_defined -1
                bytes(config)
            }.bytes()
        }
    }

    companion object {
        /** 90 kHz: the usual video timescale, and what MediaMuxer writes. */
        const val TIMESCALE = 90_000L
        const val MOVIE_TIMESCALE = 1_000L
        const val DEFAULT_INDEX_RESERVE = 16 * 1024
        private const val MEHD_SIZE = 16
        // sidx v1 without references: header, version/flags, ID, timescale, time, offset, counts.
        private const val SIDX_BASE = 8 + 4 + 4 + 4 + 8 + 8 + 2 + 2

        // ISO/IEC 14496-12 sample flags: a sync sample depends on nothing; a non-sync one does.
        private const val SYNC_SAMPLE = 0x02000000L
        private const val NON_SYNC_SAMPLE = 0x01010000L

        internal fun toTimescale(us: Long): Long = (us * TIMESCALE + 500_000) / 1_000_000

        /**
         * What a clean finish adds to a file whose fragments are all written: the length (mehd, in
         * the free box held for it inside mvex), the segment index (sidx, in the reserve after moov)
         * and the random-access box (mfra, appended).
         *
         * Only mehd carries the length. mvhd/tkhd/mdhd describe the samples inside moov itself,
         * which here are none: AVFoundation adds those to the fragments, and reported a 7.6 s clip
         * as 15.3 s while they held the total too. And mehd exists only from here on: a file that
         * never got here must state NO length -- ExoPlayer took a zero mehd as "0 s long" and would
         * not play the clip at all -- so until now its bytes are a free box.
         */
        internal fun writeTrailer(out: RandomAccessFile, mehdAt: Long, reserveAt: Long, reserve: Int, fragments: List<Fragment>) {
            val total = fragments.sumOf { it.duration }
            out.seek(mehdAt)
            out.write(Box("mehd", version = 0).apply { u32(total * MOVIE_TIMESCALE / TIMESCALE) }.bytes())
            // The sidx and what is left of the reserve as a smaller free box. A remainder under a
            // box header's 8 bytes cannot be written, and too many fragments do not fit at all
            // (12 bytes each: ~1300 in the default reserve, far past a 10-minute segment's): then
            // the reserve stays free, and the file is simply less seekable in ExoPlayer.
            val sidx = sidx(fragments, reserve)
            val rest = reserve - sidx.size
            if (rest == 0 || rest >= 8) {
                out.seek(reserveAt)
                out.write(sidx)
                if (rest > 0) out.write(boxHeader(rest.toLong(), "free"))
            }
            out.seek(out.length())
            out.write(mfra(fragments))
        }

        private fun sidx(fragments: List<Fragment>, reserve: Int): ByteArray {
            val b = Box("sidx", version = 1)
            b.u32(1) // reference_ID: the track
            b.u32(TIMESCALE)
            b.u64(0) // earliest_presentation_time
            // first_offset: from the end of the sidx to the first moof -- the free box left after it.
            val rest = reserve - (SIDX_BASE + 12 * fragments.size)
            b.u64(if (rest >= 8) rest.toLong() else 0)
            b.u16(0)
            b.u16(fragments.size)
            for (f in fragments) {
                b.u32(f.size and 0x7FFFFFFF) // reference_type 0: media
                b.u32(f.duration)
                b.u32(0x90000000L) // starts_with_SAP, SAP_type 1: every fragment opens on a keyframe
            }
            return b.bytes()
        }

        private fun mfra(fragments: List<Fragment>): ByteArray {
            val tfra = Box("tfra", version = 1)
            tfra.u32(1) // track_ID
            tfra.u32(0) // lengths of traf/trun/sample numbers: 1 byte each
            tfra.u32(fragments.size.toLong())
            for (f in fragments) {
                tfra.u64(f.startTime)
                tfra.u64(f.offset)
                tfra.u8(1) // traf_number
                tfra.u8(1) // trun_number
                tfra.u8(1) // sample_number: the keyframe opening the fragment
            }
            val tfraBytes = tfra.bytes()
            val mfro = Box("mfro", version = 0)
            mfro.u32(8L + tfraBytes.size + 16) // the whole mfra, so a reader finds it from the end
            return container("mfra", tfraBytes, mfro.bytes())
        }

        /**
         * Finishes a file this writer left unfinished -- the daemon was killed, or the power went,
         * mid-recording. Whatever follows the last complete fragment (a fragment cut off part-way
         * by the crash) is cut off; the rest gets the length, index and mfra a clean [finish] would
         * have written, so it plays AND seeks everywhere. (Unrepaired, it already plays; ExoPlayer
         * just cannot seek in it.)
         *
         * Returns true when the file is a finished recording afterwards, either because it was
         * repaired or because it already was one; false when it is not a file this writer made, or
         * holds no complete fragment. A false leaves the file untouched.
         */
        fun recover(file: File): Boolean = RandomAccessFile(file, "rw").use { f ->
            val len = f.length()
            fun header(at: Long): Pair<Long, String>? {
                if (at + 8 > len) return null
                f.seek(at)
                val size = f.readInt().toLong() and 0xFFFFFFFFL
                val type = ByteArray(4).also { f.readFully(it) }.toString(Charsets.US_ASCII)
                return if (size < 8) null else size to type
            }
            val (ftypSize, ftypType) = header(0) ?: return false
            if (ftypType != "ftyp") return false
            val (moovSize, moovType) = header(ftypSize) ?: return false
            if (moovType != "moov") return false
            val moovAt = ftypSize
            // mvex: the placeholder (unfinished) or mehd (finished).
            var mehdAt = -1L
            var finished = false
            var at = moovAt + 8
            while (at < moovAt + moovSize) {
                val (size, type) = header(at) ?: return false
                if (type == "mvex") {
                    val (childSize, childType) = header(at + 8) ?: return false
                    if (childType == "mehd") finished = true
                    if (childType == "free" && childSize == MEHD_SIZE.toLong()) mehdAt = at + 8
                }
                at += size
            }
            if (finished) return true
            if (mehdAt < 0) return false
            val reserveAt = moovAt + moovSize
            val (reserveSize, reserveType) = header(reserveAt) ?: return false
            if (reserveType != "free") return false
            // The fragments, up to the first that is not whole.
            val fragments = ArrayList<Fragment>()
            at = reserveAt + reserveSize
            while (true) {
                val (moofSize, moofType) = header(at) ?: break
                if (moofType != "moof" || at + moofSize > len) break
                val (mdatSize, mdatType) = header(at + moofSize) ?: break
                if (mdatType != "mdat" || at + moofSize + mdatSize > len) break
                val timing = fragmentTiming(f, at, moofSize) ?: break
                fragments.add(Fragment(at, moofSize + mdatSize, timing.first, timing.second))
                at += moofSize + mdatSize
            }
            if (fragments.isEmpty()) return false
            f.setLength(at)
            writeTrailer(f, mehdAt, reserveAt, reserveSize.toInt(), fragments)
            true
        }

        /** A fragment's start (tfdt) and the sum of its trun sample durations. */
        private fun fragmentTiming(f: RandomAccessFile, moofAt: Long, moofSize: Long): Pair<Long, Long>? {
            fun children(from: Long, to: Long): List<Triple<Long, Long, String>> {
                val list = ArrayList<Triple<Long, Long, String>>()
                var at = from
                while (at + 8 <= to) {
                    f.seek(at)
                    val size = f.readInt().toLong() and 0xFFFFFFFFL
                    val type = ByteArray(4).also { f.readFully(it) }.toString(Charsets.US_ASCII)
                    if (size < 8 || at + size > to) break
                    list.add(Triple(at, size, type))
                    at += size
                }
                return list
            }
            val traf = children(moofAt + 8, moofAt + moofSize).firstOrNull { it.third == "traf" } ?: return null
            var start = -1L
            var duration = 0L
            for ((at, _, type) in children(traf.first + 8, traf.first + traf.second)) {
                f.seek(at + 8)
                val versionFlags = f.readInt()
                val version = versionFlags ushr 24
                val flags = versionFlags and 0xFFFFFF
                when (type) {
                    "tfdt" -> start = if (version == 1) f.readLong() else f.readInt().toLong() and 0xFFFFFFFFL
                    "trun" -> {
                        val count = f.readInt()
                        if (flags and 0x1 != 0) f.readInt() // data_offset
                        if (flags and 0x4 != 0) f.readInt() // first_sample_flags
                        repeat(count) {
                            if (flags and 0x100 != 0) duration += f.readInt().toLong() and 0xFFFFFFFFL
                            if (flags and 0x200 != 0) f.readInt()
                            if (flags and 0x400 != 0) f.readInt()
                            if (flags and 0x800 != 0) f.readInt()
                        }
                    }
                }
            }
            return if (start < 0) null else start to duration
        }

        private fun ftyp(hevc: Boolean): ByteArray = Box("ftyp").apply {
            fourcc("isom")
            u32(0x200)
            for (brand in listOf("isom", "iso6", "mp41", if (hevc) "hvc1" else "avc1")) fourcc(brand)
        }.bytes()

        private fun freeBox(size: Int): ByteArray = ByteArray(size).also {
            ByteBuffer.wrap(it).putInt(size).put("free".toByteArray())
        }

        private fun boxHeader(size: Long, type: String): ByteArray =
            ByteBuffer.allocate(8).putInt(size.toInt()).put(type.toByteArray()).array()

        private fun container(type: String, vararg children: ByteArray): ByteArray {
            val size = 8 + children.sumOf { it.size }
            val b = ByteArrayOutputStream(size)
            b.write(boxHeader(size.toLong(), type))
            for (c in children) b.write(c)
            return b.toByteArray()
        }

        /** The NAL units of an Annex-B buffer, start codes removed. */
        internal fun splitNals(annexB: ByteArray): List<ByteArray> {
            val starts = ArrayList<Pair<Int, Int>>() // (start code position, payload position)
            var i = 0
            while (i + 2 < annexB.size) {
                if (annexB[i].toInt() == 0 && annexB[i + 1].toInt() == 0) {
                    if (annexB[i + 2].toInt() == 1) {
                        starts.add(i to i + 3)
                        i += 3
                        continue
                    }
                    if (i + 3 < annexB.size && annexB[i + 2].toInt() == 0 && annexB[i + 3].toInt() == 1) {
                        starts.add(i to i + 4)
                        i += 4
                        continue
                    }
                }
                i++
            }
            if (starts.isEmpty()) return if (annexB.isEmpty()) emptyList() else listOf(annexB)
            return starts.mapIndexed { n, (_, from) ->
                val to = if (n + 1 < starts.size) starts[n + 1].first else annexB.size
                annexB.copyOfRange(from, to)
            }.filter { it.isNotEmpty() }
        }

        private fun nalType(nal: ByteArray, hevc: Boolean): Int =
            if (hevc) (nal[0].toInt() shr 1) and 0x3F else nal[0].toInt() and 0x1F

        private fun isParameterSet(nal: ByteArray, hevc: Boolean): Boolean {
            val t = nalType(nal, hevc)
            return if (hevc) t in 32..34 else t == 7 || t == 8
        }

        /**
         * An access unit as MP4 stores it: each NAL unit behind a 4-byte length. Parameter sets and
         * access unit delimiters are dropped: the sample description carries the former, and MP4 has
         * no use for the latter. A buffer that is already length-prefixed (no start code at its
         * front) is taken as it is.
         */
        internal fun toLengthPrefixed(data: ByteBuffer, hevc: Boolean): ByteArray {
            val bytes = ByteArray(data.remaining()).also { data.duplicate().get(it) }
            val annexB = bytes.size >= 4 && bytes[0].toInt() == 0 && bytes[1].toInt() == 0 &&
                (bytes[2].toInt() == 1 || (bytes[2].toInt() == 0 && bytes[3].toInt() == 1))
            if (!annexB) return bytes
            val out = ByteArrayOutputStream(bytes.size)
            for (nal in splitNals(bytes)) {
                val t = nalType(nal, hevc)
                if (isParameterSet(nal, hevc) || (if (hevc) t == 35 else t == 9)) continue
                out.write(ByteBuffer.allocate(4).putInt(nal.size).array())
                out.write(nal)
            }
            return out.toByteArray()
        }

        /** AVCDecoderConfigurationRecord (ISO/IEC 14496-15 5.3.3). */
        internal fun avcC(nals: List<ByteArray>): ByteArray {
            val sps = nals.filter { it.isNotEmpty() && it[0].toInt() and 0x1F == 7 }
            val pps = nals.filter { it.isNotEmpty() && it[0].toInt() and 0x1F == 8 }
            require(sps.isNotEmpty() && pps.isNotEmpty()) { "H.264 config needs an SPS and a PPS" }
            return Box("avcC").apply {
                u8(1)
                u8(sps[0][1].toInt() and 0xFF) // profile
                u8(sps[0][2].toInt() and 0xFF) // compatibility
                u8(sps[0][3].toInt() and 0xFF) // level
                u8(0xFF) // 4-byte NAL lengths
                u8(0xE0 or sps.size)
                for (s in sps) { u16(s.size); bytes(s) }
                u8(pps.size)
                for (p in pps) { u16(p.size); bytes(p) }
            }.bytes()
        }

        /** HEVCDecoderConfigurationRecord (ISO/IEC 14496-15 8.3.3), from the VPS/SPS/PPS. */
        internal fun hvcC(nals: List<ByteArray>): ByteArray {
            fun of(type: Int) = nals.filter { it.size > 2 && (it[0].toInt() shr 1) and 0x3F == type }
            val vps = of(32)
            val sps = of(33)
            val pps = of(34)
            require(vps.isNotEmpty() && sps.isNotEmpty() && pps.isNotEmpty()) { "H.265 config needs a VPS, an SPS and a PPS" }
            val info = HevcSps.parse(sps[0])
            return Box("hvcC").apply {
                u8(1)
                bytes(info.profileTierLevel) // 12 bytes: profile space/tier/idc, compatibility, constraints, level
                u16(0xF000) // reserved + min_spatial_segmentation_idc 0
                u8(0xFC) // reserved + parallelismType 0
                u8(0xFC or info.chromaFormat)
                u8(0xF8 or info.bitDepthLumaMinus8)
                u8(0xF8 or info.bitDepthChromaMinus8)
                u16(0) // avgFrameRate unknown
                // constantFrameRate 0, numTemporalLayers, temporalIdNested, lengthSizeMinusOne 3
                u8(((info.maxSubLayers and 0x7) shl 3) or ((if (info.temporalIdNested) 1 else 0) shl 2) or 3)
                u8(3)
                for ((type, list) in listOf(32 to vps, 33 to sps, 34 to pps)) {
                    u8(0x80 or type) // array_completeness 1: every set is in here
                    u16(list.size)
                    for (n in list) { u16(n.size); bytes(n) }
                }
            }.bytes()
        }
    }

    /** A box being built: header (and full-box version/flags) plus fields. */
    private class Box(private val type: String, version: Int = -1, flags: Int = 0) {
        private val body = ByteArrayOutputStream()

        init {
            if (version >= 0) u32(((version.toLong() and 0xFF) shl 24) or (flags.toLong() and 0xFFFFFF))
        }

        fun u8(v: Int) = body.write(v and 0xFF)
        fun u16(v: Int) { u8(v shr 8); u8(v) }
        fun u32(v: Long) { u16((v shr 16).toInt() and 0xFFFF); u16(v.toInt() and 0xFFFF) }
        fun u32(v: Int) = u32(v.toLong() and 0xFFFFFFFFL)
        fun u64(v: Long) { u32(v ushr 32); u32(v and 0xFFFFFFFFL) }
        fun fourcc(s: String) = body.write(s.toByteArray())
        fun zeros(n: Int) = body.write(ByteArray(n))
        fun bytes(b: ByteArray) = body.write(b)

        fun matrix() {
            for (v in longArrayOf(0x00010000, 0, 0, 0, 0x00010000, 0, 0, 0, 0x40000000)) u32(v)
        }

        fun bytes(): ByteArray {
            val size = 8 + body.size()
            return ByteBuffer.allocate(size).putInt(size).put(type.toByteArray()).put(body.toByteArray()).array()
        }
    }
}

/**
 * The few things an `hvcC` needs from an HEVC SPS (ITU-T H.265 7.3.2.2): the 12-byte general
 * profile/tier/level, chroma format, bit depths, sub-layer count.
 */
internal class HevcSps(
    val profileTierLevel: ByteArray,
    val chromaFormat: Int,
    val bitDepthLumaMinus8: Int,
    val bitDepthChromaMinus8: Int,
    val maxSubLayers: Int,
    val temporalIdNested: Boolean,
) {
    companion object {
        fun parse(nal: ByteArray): HevcSps {
            val rbsp = unescape(nal.copyOfRange(2, nal.size)) // past the 2-byte NAL header
            val r = Bits(rbsp)
            r.skip(4) // sps_video_parameter_set_id
            val maxSubLayersMinus1 = r.read(3)
            val nested = r.read(1) == 1
            // general profile/tier/level: 2+1+5 bits, 32 compatibility, 48 constraint, 8 level = 12 bytes
            val ptl = ByteArray(12) { r.read(8).toByte() }
            val profilePresent = BooleanArray(maxSubLayersMinus1)
            val levelPresent = BooleanArray(maxSubLayersMinus1)
            for (i in 0 until maxSubLayersMinus1) {
                profilePresent[i] = r.read(1) == 1
                levelPresent[i] = r.read(1) == 1
            }
            if (maxSubLayersMinus1 > 0) for (i in maxSubLayersMinus1 until 8) r.skip(2)
            for (i in 0 until maxSubLayersMinus1) {
                if (profilePresent[i]) r.skip(88)
                if (levelPresent[i]) r.skip(8)
            }
            r.ue() // sps_seq_parameter_set_id
            val chroma = r.ue()
            if (chroma == 3) r.skip(1) // separate_colour_plane_flag
            r.ue(); r.ue() // width, height
            if (r.read(1) == 1) repeat(4) { r.ue() } // conformance window
            val luma = r.ue()
            val chromaDepth = r.ue()
            return HevcSps(ptl, chroma and 3, luma and 7, chromaDepth and 7, maxSubLayersMinus1 + 1, nested)
        }

        /** Removes emulation-prevention bytes (00 00 03 -> 00 00). */
        private fun unescape(b: ByteArray): ByteArray {
            val out = ByteArrayOutputStream(b.size)
            var zeros = 0
            for (x in b) {
                val v = x.toInt() and 0xFF
                if (zeros >= 2 && v == 3) {
                    zeros = 0
                    continue
                }
                out.write(v)
                zeros = if (v == 0) zeros + 1 else 0
            }
            return out.toByteArray()
        }
    }

    private class Bits(private val b: ByteArray) {
        private var pos = 0

        fun read(n: Int): Int {
            var v = 0
            repeat(n) {
                val byte = b.getOrElse(pos / 8) { 0 }.toInt()
                v = (v shl 1) or ((byte shr (7 - pos % 8)) and 1)
                pos++
            }
            return v
        }

        fun skip(n: Int) {
            pos += n
        }

        fun ue(): Int {
            var zeros = 0
            while (read(1) == 0 && zeros < 32) zeros++
            return (1 shl zeros) - 1 + read(zeros)
        }
    }
}
