package net.bladewatch.app.recording

import android.media.MediaCodec
import android.media.MediaFormat
import android.media.MediaMuxer
import java.io.File
import java.nio.ByteBuffer

/**
 * What the recorder writes a clip through (BladeWatch-rdtj.29): Android's MediaMuxer, or
 * [FragmentedMp4Writer]. The same calls in the same order either way -- addTrack, start,
 * writeSampleData..., stop, release -- so HardwareEventRecorderGpu keeps one code path and its
 * locking rules.
 */
interface RecordingMuxer {
    fun addTrack(format: MediaFormat): Int
    fun start()
    fun writeSampleData(trackIndex: Int, data: ByteBuffer, info: MediaCodec.BufferInfo)

    /** Finalises the file. Throws when it holds no frame, as MediaMuxer does. */
    fun stop()
    fun release()

    companion object {
        /**
         * The muxer for a new clip at [path]: fragmented MP4 when `recording.fragmentedMp4` is on,
         * else MediaMuxer. The flag defaults to OFF until every player has been checked on the
         * owner's devices (BladeWatch-rdtj.29 steps 3-4).
         */
        fun open(path: String, fragmented: Boolean): RecordingMuxer =
            if (fragmented) FragmentedMp4Muxer(File(path)) else MediaMuxerRecording(path)
    }
}

/** MediaMuxer, as it always was: the index written last, by stop(). */
class MediaMuxerRecording(path: String) : RecordingMuxer {
    private val muxer = MediaMuxer(path, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)

    override fun addTrack(format: MediaFormat): Int = muxer.addTrack(format)
    override fun start() = muxer.start()
    override fun writeSampleData(trackIndex: Int, data: ByteBuffer, info: MediaCodec.BufferInfo) =
        muxer.writeSampleData(trackIndex, data, info)
    override fun stop() = muxer.stop()
    override fun release() = muxer.release()
}

/**
 * [FragmentedMp4Writer] behind MediaMuxer's calls. The track's codec configuration comes from the
 * encoder's output format (csd-0/csd-1), as MediaMuxer takes it; codec-config buffers that reach
 * writeSampleData are skipped, since the sample description already holds them.
 */
class FragmentedMp4Muxer(private val file: File) : RecordingMuxer {
    private var track: FragmentedMp4Writer.Track? = null
    private var writer: FragmentedMp4Writer? = null

    override fun addTrack(format: MediaFormat): Int {
        check(track == null) { "one video track only" }
        track = trackOf(
            mime = format.getString(MediaFormat.KEY_MIME),
            width = format.getInteger(MediaFormat.KEY_WIDTH),
            height = format.getInteger(MediaFormat.KEY_HEIGHT),
            csd0 = format.getByteBuffer("csd-0"),
            csd1 = if (format.containsKey("csd-1")) format.getByteBuffer("csd-1") else null,
        )
        return 0
    }

    override fun start() {
        writer = FragmentedMp4Writer(file, checkNotNull(track) { "addTrack first" })
    }

    override fun writeSampleData(trackIndex: Int, data: ByteBuffer, info: MediaCodec.BufferInfo) {
        if (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0 || info.size <= 0) return
        val sample = data.duplicate().apply {
            limit(info.offset + info.size)
            position(info.offset)
        }
        checkNotNull(writer) { "start first" }
            .writeSample(sample, info.presentationTimeUs, info.flags and MediaCodec.BUFFER_FLAG_KEY_FRAME != 0)
    }

    override fun stop() {
        check(checkNotNull(writer) { "not started" }.finish()) { "no frames written" }
    }

    /** After a stop, nothing is left to do; without one, the file is closed as it stands. */
    override fun release() {
        writer?.close()
    }

    companion object {
        /** The track, from the values MediaMuxer.addTrack reads out of the encoder's format. */
        fun trackOf(mime: String?, width: Int, height: Int, csd0: ByteBuffer?, csd1: ByteBuffer?): FragmentedMp4Writer.Track {
            fun bytes(b: ByteBuffer?) = b?.let { ByteArray(it.remaining()).also { out -> it.duplicate().get(out) } }
            return FragmentedMp4Writer.Track(
                hevc = mime == MediaFormat.MIMETYPE_VIDEO_HEVC,
                width = width,
                height = height,
                csd0 = checkNotNull(bytes(csd0)) { "no codec configuration (csd-0)" },
                csd1 = bytes(csd1),
            )
        }

        /**
         * Finishes the fragmented clips a crash left behind as `<name>.mp4.tmp` in [dirs]: each is
         * cut back to its last complete fragment, indexed, and renamed to `<name>.mp4` (reported to
         * [onRecovered]). MediaMuxer leftovers are not fragmented, cannot be saved this way, and
         * are left exactly as they are. Call it only while nothing is recording into [dirs].
         *
         * No age guard: CameraDaemon, the only process that records, calls this after taking its
         * singleton lock, so no leftover can still be growing. A guard hid exactly the common
         * case -- measured on the head unit, the keepalive restarts a killed daemon within 6 s.
         *
         * @return the clips recovered.
         */
        fun recoverLeftovers(dirs: List<File>, onRecovered: (File) -> Unit = {}): List<File> {
            val recovered = ArrayList<File>()
            for (dir in dirs.distinct()) {
                val leftovers = dir.listFiles { f -> f.isFile && f.name.endsWith(".mp4.tmp") } ?: continue
                for (tmp in leftovers) {
                    val target = File(dir, tmp.name.removeSuffix(".tmp"))
                    if (target.exists()) continue
                    val ok = try {
                        FragmentedMp4Writer.recover(tmp)
                    } catch (_: Exception) {
                        false
                    }
                    if (ok && tmp.renameTo(target)) {
                        recovered.add(target)
                        onRecovered(target)
                    }
                }
            }
            return recovered
        }
    }
}
