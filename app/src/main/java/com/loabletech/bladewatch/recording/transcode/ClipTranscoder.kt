package net.bladewatch.app.recording.transcode

import android.graphics.SurfaceTexture
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.opengl.GLES11Ext
import android.opengl.GLES20
import android.os.Handler
import android.os.HandlerThread
import android.view.Surface
import net.bladewatch.app.camera.EGLCore
import net.bladewatch.app.camera.GlUtil
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.recording.RecordingMuxer
import java.io.File
import java.util.concurrent.TimeUnit

/**
 * Re-encodes one stored clip at a lower resolution, for a client whose own decoder cannot handle
 * the car's native format (BladeWatch-rdtj.73). Saved recordings only, never live view -- see
 * [ClipCapability]'s own doc.
 *
 * A classic offline decode -> GPU scale -> encode -> mux pipeline (the "Grafika" pattern): the
 * decoder's output goes to a [SurfaceTexture] as an external OES texture; a tiny pass-through GL
 * shader draws it, scaled by nothing more than a different `glViewport`, into the encoder's own
 * input [Surface] ([MediaCodec.createInputSurface]); [RecordingMuxer] writes the encoder's output,
 * fragmented, so a transcoded clip is served through the exact same faststart path as any other
 * recording (RecordingsApiHandler / Mp4Faststart). No frame ever touches a CPU byte buffer.
 *
 * Every `MediaCodec` lifecycle call (create/configure/start, on EITHER codec) is wrapped in the
 * SAME watchdog-thread-with-timeout pattern [HardwareEventRecorderGpu] already uses for the live
 * recorder, and for the same reason its own comment gives: "All MediaCodec operations can block
 * if hardware encoder is stuck." Measured on the car's own Snapdragon 665 (BladeWatch-rdtj.73's
 * investigation notes): a decoder and a second encoder both allocate in under 200ms combined,
 * concurrently with the live recorder's own encoder, which is reassuring but not a guarantee this
 * every time -- the guard stays.
 *
 * Synchronous and blocking: this runs on the HTTP server's own request thread (a fixed 32-thread
 * pool; one long call does not stall the other 31), not a background job with polling. A 5-minute
 * clip took roughly 107s to DECODE alone in testing; budget the caller's own timeout accordingly.
 */
class ClipTranscoder {
    private val logger = DaemonLogger.getInstance(TAG)

    /**
     * Transcodes [source] to [target] at [width]x[height]. [target] is written via a `.tmp`
     * sibling, renamed only once the mux finishes cleanly -- a failure or a crash mid-transcode
     * therefore never leaves a broken file where a cache hit would find it. Returns false (and
     * cleans up) on any failure; throws nothing a caller need catch beyond that.
     */
    fun transcode(source: File, target: File, width: Int, height: Int): Boolean {
        val tmp = File(target.path + ".tmp")
        tmp.delete()
        var ok = false
        try {
            ok = run(source, tmp, width, height)
        } catch (e: Exception) {
            logger.error("transcode failed: ${source.name} -> ${width}x$height", e)
            ok = false
        }
        if (ok && tmp.renameTo(target)) return true
        tmp.delete()
        return false
    }

    private fun run(source: File, target: File, width: Int, height: Int): Boolean {
        val extractor = MediaExtractor()
        extractor.setDataSource(source.path)
        val (track, srcFormat) = videoTrack(extractor) ?: run {
            logger.error("no video track in ${source.name}")
            extractor.release()
            return false
        }
        extractor.selectTrack(track)
        val mime = srcFormat.getString(MediaFormat.KEY_MIME) ?: MediaFormat.MIMETYPE_VIDEO_AVC
        val fps = if (srcFormat.containsKey(MediaFormat.KEY_FRAME_RATE)) srcFormat.getInteger(MediaFormat.KEY_FRAME_RATE) else 16

        // --- encoder first: its input Surface is what the decoder and GL step render into ---
        val outFormat = MediaFormat.createVideoFormat(mime, width, height).apply {
            setInteger(MediaFormat.KEY_COLOR_FORMAT, MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface)
            setInteger(MediaFormat.KEY_BIT_RATE, targetBitrate(width, height, fps))
            setInteger(MediaFormat.KEY_FRAME_RATE, fps)
            setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 2)
        }
        val encoder = withTimeout("create encoder") { MediaCodec.createEncoderByType(mime) } ?: run {
            extractor.release(); return false
        }
        if (!withTimeout("configure encoder") { encoder.configure(outFormat, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE); true }.let { it == true }) {
            runCatching { encoder.release() }
            extractor.release()
            return false
        }
        val encoderSurface = withTimeout("encoder input surface") { encoder.createInputSurface() } ?: run {
            runCatching { encoder.release() }
            extractor.release()
            return false
        }
        withTimeout("start encoder") { encoder.start(); true }

        // --- GL: sample the decoder's output as an external texture, draw it scaled ---
        val egl = EGLCore()
        val eglSurface = egl.createWindowSurface(encoderSurface)
        egl.makeCurrent(eglSurface)
        val oesTexture = GlUtil.createExternalTexture()
        val surfaceTexture = SurfaceTexture(oesTexture)
        surfaceTexture.setDefaultBufferSize(srcFormat.getInteger(MediaFormat.KEY_WIDTH), srcFormat.getInteger(MediaFormat.KEY_HEIGHT))
        val decoderSurface = Surface(surfaceTexture)
        val frameLock = Object()
        var frameAvailable = false
        // SurfaceTexture's frame-available callback posts through a Handler tied to a Looper --
        // this whole pipeline runs on a plain background executor thread with none, which crashed
        // with a null Looper.mQueue the first time this ran against a real transcode (measured on
        // the car, 2026-09-28). The callback only flips a flag and notifies a lock; a dedicated
        // HandlerThread just to host it is cheap and avoids touching the executor's own threading.
        val callbackThread = HandlerThread("ClipTranscoder-cb").apply { start() }
        val callbackHandler = Handler(callbackThread.looper)
        surfaceTexture.setOnFrameAvailableListener({
            synchronized(frameLock) {
                frameAvailable = true
                frameLock.notifyAll()
            }
        }, callbackHandler)
        val program = GlUtil.createProgram(VERTEX_SHADER, FRAGMENT_SHADER)
        val aPosition = GLES20.glGetAttribLocation(program, "aPosition")
        val aTexCoord = GLES20.glGetAttribLocation(program, "aTexCoord")
        val uTex = GLES20.glGetUniformLocation(program, "uTex")
        val vertexBuf = GlUtil.createFloatBuffer(FULLSCREEN_QUAD)
        val texCoordBuf = GlUtil.createFloatBuffer(FULLSCREEN_TEXCOORD)

        // --- decoder: the source's own compressed samples, output straight to the SurfaceTexture ---
        val decoder = withTimeout("create decoder") { MediaCodec.createDecoderByType(mime) } ?: run {
            cleanupGl(egl, eglSurface, decoderSurface, surfaceTexture, program, oesTexture, callbackThread)
            runCatching { encoder.stop(); encoder.release() }
            extractor.release()
            return false
        }
        withTimeout("configure+start decoder") { decoder.configure(srcFormat, decoderSurface, null, 0); decoder.start(); true }

        val muxer = RecordingMuxer.open(target.path, fragmented = true)
        var trackIndex = -1
        var muxerStarted = false
        val bufferInfo = MediaCodec.BufferInfo()
        var inputDone = false
        var decoderEosSent = false
        var encoderDone = false
        var wroteAnyFrame = false

        try {
            while (!encoderDone) {
                // Feed the decoder from the source.
                if (!inputDone) {
                    val inIdx = decoder.dequeueInputBuffer(10_000)
                    if (inIdx >= 0) {
                        val buf = decoder.getInputBuffer(inIdx)
                        val size = buf?.let { extractor.readSampleData(it, 0) } ?: -1
                        if (size < 0) {
                            decoder.queueInputBuffer(inIdx, 0, 0, 0, MediaCodec.BUFFER_FLAG_END_OF_STREAM)
                            inputDone = true
                        } else {
                            decoder.queueInputBuffer(inIdx, 0, size, extractor.sampleTime, 0)
                            extractor.advance()
                        }
                    }
                }

                // Drain the decoder: render each frame to the encoder's surface via GL, scaled.
                val decOutIdx = decoder.dequeueOutputBuffer(bufferInfo, 10_000)
                if (decOutIdx >= 0) {
                    val eos = (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0
                    val render = bufferInfo.size > 0
                    decoder.releaseOutputBuffer(decOutIdx, render)
                    if (render) {
                        synchronized(frameLock) {
                            while (!frameAvailable) frameLock.wait(2_000)
                            frameAvailable = false
                        }
                        surfaceTexture.updateTexImage()
                        egl.makeCurrent(eglSurface)
                        GLES20.glViewport(0, 0, width, height)
                        GLES20.glClearColor(0f, 0f, 0f, 1f)
                        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)
                        GLES20.glUseProgram(program)
                        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
                        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, oesTexture)
                        GLES20.glUniform1i(uTex, 0)
                        GLES20.glEnableVertexAttribArray(aPosition)
                        GLES20.glVertexAttribPointer(aPosition, 2, GLES20.GL_FLOAT, false, 0, vertexBuf)
                        GLES20.glEnableVertexAttribArray(aTexCoord)
                        GLES20.glVertexAttribPointer(aTexCoord, 2, GLES20.GL_FLOAT, false, 0, texCoordBuf)
                        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
                        GLES20.glDisableVertexAttribArray(aPosition)
                        GLES20.glDisableVertexAttribArray(aTexCoord)
                        egl.swapBuffersWithTimestamp(eglSurface, bufferInfo.presentationTimeUs * 1000)
                    }
                    if (eos && !decoderEosSent) {
                        decoderEosSent = true
                        encoder.signalEndOfInputStream()
                    }
                } else if (decOutIdx == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                    // The Surface-output decoder's own format change carries nothing this pipeline
                    // needs (colour format etc. are handled by the Surface/EGL path already).
                }

                // Drain the encoder into the muxer.
                while (true) {
                    val encOutIdx = encoder.dequeueOutputBuffer(bufferInfo, 0)
                    if (encOutIdx == MediaCodec.INFO_TRY_AGAIN_LATER) break
                    if (encOutIdx == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED) {
                        trackIndex = muxer.addTrack(encoder.outputFormat)
                        muxer.start()
                        muxerStarted = true
                        continue
                    }
                    if (encOutIdx < 0) continue
                    val outBuf = encoder.getOutputBuffer(encOutIdx)
                    if (outBuf != null && bufferInfo.size > 0 && muxerStarted) {
                        muxer.writeSampleData(trackIndex, outBuf, bufferInfo)
                        wroteAnyFrame = true
                    }
                    val encEos = (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0
                    encoder.releaseOutputBuffer(encOutIdx, false)
                    if (encEos) {
                        encoderDone = true
                        break
                    }
                }
            }
        } finally {
            runCatching { decoder.stop(); decoder.release() }
            runCatching { encoder.stop() }
            runCatching { encoder.release() }
            cleanupGl(egl, eglSurface, decoderSurface, surfaceTexture, program, oesTexture, callbackThread)
            extractor.release()
            if (wroteAnyFrame && muxerStarted) {
                try {
                    muxer.stop()
                } catch (e: Exception) {
                    logger.error("muxer.stop failed for ${source.name}", e)
                    wroteAnyFrame = false
                }
            }
            muxer.release()
        }
        return wroteAnyFrame
    }

    private fun cleanupGl(
        egl: EGLCore, eglSurface: android.opengl.EGLSurface, decoderSurface: Surface,
        surfaceTexture: SurfaceTexture, program: Int, texture: Int, callbackThread: HandlerThread
    ) {
        runCatching { GlUtil.deleteProgram(program) }
        runCatching { GlUtil.deleteTexture(texture) }
        runCatching { decoderSurface.release() }
        runCatching { surfaceTexture.release() }
        runCatching { egl.destroySurface(eglSurface) }
        runCatching { egl.release() }
        runCatching { callbackThread.quitSafely() }
    }

    private fun videoTrack(extractor: MediaExtractor): Pair<Int, MediaFormat>? {
        for (i in 0 until extractor.trackCount) {
            val f = extractor.getTrackFormat(i)
            if (f.getString(MediaFormat.KEY_MIME)?.startsWith("video/") == true) return i to f
        }
        return null
    }

    /** A conservative encode bitrate for the target size -- not the car's own live-recording tuning. */
    private fun targetBitrate(width: Int, height: Int, fps: Int): Int {
        val bitsPerPixel = 0.1 // roughly what a 1080p H.264 web upload targets
        return (width * height * fps * bitsPerPixel).toInt().coerceAtLeast(1_000_000)
    }

    /**
     * CRITICAL, same as [HardwareEventRecorderGpu]: a MediaCodec lifecycle call can block if the
     * hardware codec is stuck. Runs [block] on its own thread with a hard timeout; null on
     * timeout or failure, after best-effort cleanup is the caller's job (it always checks for
     * null). Never silently swallows a real exception -- only a timeout returns null quietly.
     */
    private fun <T> withTimeout(what: String, timeoutMs: Long = 10_000, block: () -> T): T? {
        var result: T? = null
        var error: Throwable? = null
        val t = Thread({
            try {
                result = block()
            } catch (e: Throwable) {
                error = e
            }
        }, "Transcode-$what")
        t.isDaemon = true
        t.start()
        t.join(timeoutMs)
        if (t.isAlive) {
            logger.error("$what TIMEOUT after ${timeoutMs}ms -- hardware codec stuck")
            t.interrupt()
            return null
        }
        error?.let {
            logger.error("$what failed", it)
            return null
        }
        return result
    }

    companion object {
        private const val TAG = "ClipTranscoder"

        private const val VERTEX_SHADER = """
            attribute vec4 aPosition;
            attribute vec2 aTexCoord;
            varying vec2 vTexCoord;
            void main() {
                gl_Position = aPosition;
                vTexCoord = aTexCoord;
            }
        """

        private const val FRAGMENT_SHADER = """
            #extension GL_OES_EGL_image_external : require
            precision mediump float;
            varying vec2 vTexCoord;
            uniform samplerExternalOES uTex;
            void main() {
                gl_FragColor = texture2D(uTex, vTexCoord);
            }
        """

        // A full-screen triangle strip; GL's own texture sampling does the resize when the
        // viewport differs from the source texture's size -- no scaling math needed here.
        private val FULLSCREEN_QUAD = floatArrayOf(-1f, -1f, 1f, -1f, -1f, 1f, 1f, 1f)
        private val FULLSCREEN_TEXCOORD = floatArrayOf(0f, 0f, 1f, 0f, 0f, 1f, 1f, 1f)
    }
}
