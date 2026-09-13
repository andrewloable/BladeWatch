package net.bladewatch.bladewatch_ui.liveview

import android.media.MediaCodec
import android.media.MediaFormat
import io.flutter.view.TextureRegistry

/**
 * Real [FrameDecoder] wrapping [MediaCodec] in synchronous/buffer-polling
 * mode — the exact same mode and call sequence as `LiveStreamClient.kt`'s
 * `runStream()`/`feedToDecoder()`/`drainDecoder()`, just retargeted at a
 * Flutter [TextureRegistry.SurfaceProducer]'s surface instead of a
 * `TextureView`'s. Thin by design (see this package's `FrameDecoder` doc
 * comment) — not unit-tested, excluded from the coverage gate the same way
 * `LocationServiceChannel`/`HttpConnectionsKt` are (see app/build.gradle.kts).
 */
internal class MediaCodecFrameDecoder : FrameDecoder {
    private var codec: MediaCodec? = null
    private val bufferInfo = MediaCodec.BufferInfo()

    override fun configure(width: Int, height: Int, producer: TextureRegistry.SurfaceProducer) {
        // Drop any codec this instance is already holding. Reconfiguring without this
        // strands the previous hardware decoder for the life of the process.
        release()
        producer.setSize(width, height)
        val c = MediaCodec.createDecoderByType("video/avc")
        try {
            c.configure(MediaFormat.createVideoFormat("video/avc", width, height), producer.getSurface(), null, 0)
            c.start()
        } catch (e: Exception) {
            // createDecoderByType() has already claimed a hardware decoder instance. If
            // configure() or start() throws — bad dimensions because the daemon has not
            // reported the stream size yet, a Surface whose producer was released, or the
            // decoder being busy — that instance becomes unreachable with nothing left to
            // release it. On this head unit a stranded MediaCodec does not come back
            // without restarting the process, so release it before rethrowing.
            runCatching { c.release() }
            throw e
        }
        codec = c
    }

    override fun feed(bytes: ByteArray, presentationTimeUs: Long, isCodecConfig: Boolean) {
        val c = codec ?: return
        val flags = if (isCodecConfig) MediaCodec.BUFFER_FLAG_CODEC_CONFIG else 0
        val inputIdx = c.dequeueInputBuffer(INPUT_TIMEOUT_US)
        if (inputIdx >= 0) {
            c.getInputBuffer(inputIdx)?.apply {
                clear()
                put(bytes)
            }
            c.queueInputBuffer(inputIdx, 0, bytes.size, presentationTimeUs, flags)
        }
        drain(c)
    }

    private fun drain(c: MediaCodec) {
        while (true) {
            val idx = c.dequeueOutputBuffer(bufferInfo, 0L)
            when {
                idx >= 0 -> {
                    val render = bufferInfo.size > 0 && bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG == 0
                    c.releaseOutputBuffer(idx, render)
                }
                idx == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> continue
                idx == MediaCodec.INFO_OUTPUT_BUFFERS_CHANGED -> continue
                else -> return
            }
        }
    }

    override fun release() {
        val c = codec
        codec = null
        runCatching { c?.stop() }
        runCatching { c?.release() }
    }

    companion object {
        private const val INPUT_TIMEOUT_US = 10_000L
    }
}
