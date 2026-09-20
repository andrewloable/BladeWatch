package net.bladewatch.app.surveillance

import android.opengl.EGLSurface
import android.opengl.GLES11Ext
import android.opengl.GLES20
import android.opengl.GLUtils
import android.view.Surface

import net.bladewatch.app.camera.EGLCore
import net.bladewatch.app.camera.GlUtil
import net.bladewatch.app.config.UnifiedConfigManager
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.storage.StorageManager
import net.bladewatch.app.telemetry.OverlayBitmapRenderer
import net.bladewatch.app.telemetry.OverlayFieldSelectionResolver
import net.bladewatch.app.telemetry.RecordingOverlayType
import net.bladewatch.app.telemetry.TelemetryDataCollector

import java.io.File
import java.nio.FloatBuffer
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

import kotlin.math.abs

/**
 * GpuMosaicRecorder - GPU-based 2x2 grid compositor for zero-copy recording.
 *
 * This class renders a 5120x960 camera strip into a 2560x1920 2x2 grid layout
 * directly to the MediaCodec encoder's input surface. All composition happens
 * on the GPU, achieving 0% CPU usage and 0 GB/s memory bandwidth.
 *
 * Key features:
 * - Zero-copy GPU path (camera texture → encoder surface)
 * - Branchless fragment shader for optimal GPU performance
 * - Direct rendering to encoder (no intermediate buffers)
 * - 0% CPU usage for video composition
 */
class GpuMosaicRecorder {

    // EGL and OpenGL state
    private var eglCore: EGLCore? = null
    private var encoderSurface: EGLSurface? = null
    private var encoderInputSurface: Surface? = null

    // SOTA: Dynamic Time-Base Corrector (TBC) state.
    // Uses an Exponential Moving Average to learn the actual hardware frame rate
    // in real-time, then feeds mathematically perfect, evenly spaced timestamps
    // to the encoder. This eliminates both the fast-forward bug (from hardcoded FPS)
    // and the rubber-banding jitter (from raw System.nanoTime()).
    private var lastRealTimeNs = -1L
    private var smoothedPtsNs = -1L

    /** Initial assumption: ~5.5 FPS */
    private var averageDeltaNs = 181_000_000L

    // OpenGL program and locations
    private var programId = 0
    private var uCameraTexLocation = 0
    private var uApaModeLocation = 0
    private var aPositionLocation = 0
    private var aTexCoordLocation = 0

    // Vertex data
    private var vertexBuffer: FloatBuffer? = null
    private var texCoordBuffer: FloatBuffer? = null

    /** Encoder reference */
    private var encoder: HardwareEventRecorderGpu? = null

    // State
    // volatile + accessed under recordingLock for read-modify-write safety.
    // The double-check around encoder.triggerEventRecording closes the racing
    // start-paths (RecordingModeManager, deferred-listener thread, direct
    // CameraDaemon.startPipeline calls) that previously could land two muxers
    // on disk with timestamps milliseconds apart. The encoder side has its
    // own startStopLock as defense in depth.
    @Volatile
    private var recording = false

    private val recordingLock = Any()

    /** APA mode: passthrough instead of mosaic split */
    @Volatile
    private var apaMode = false

    /** 0=4-cam, 1=APA passthrough, 2=3-cam */
    @Volatile
    private var cameraLayout = 0

    private var lastFrameTime = 0L
    private var frameCount = 0L

    // Overlay GL resources
    private var overlayTextureId = 0
    private var overlayProgramId = 0
    private var overlayAPositionLoc = 0
    private var overlayATexCoordLoc = 0
    private var overlayUTextureLoc = 0
    private var overlayVertexBuffer: FloatBuffer? = null
    private var overlayTexCoordBuffer: FloatBuffer? = null

    // Overlay state
    @Volatile
    private var overlayEnabled = false

    private var overlayRenderer: OverlayBitmapRenderer? = null
    private var telemetryCollector: TelemetryDataCollector? = null
    private var overlayFrameCounter = 0

    @Volatile
    private var overlayRecordingModeAllowed = false

    private var overlayTextureReady = false
    private var overlayTextureInitialized = false

    // Frame skip tracking - prevents eglSwapBuffers from blocking GL thread
    // When encoder is backed up (SD card I/O), skip rendering to keep camera HAL flowing
    private var lastDrawDurationNs = 0L
    private var consecutiveSlowFrames = 0
    private var skippedFrames = 0

    // EGL_BAD_SURFACE recovery: track consecutive surface errors to trigger reinit
    private var consecutiveSurfaceErrors = 0

    @Volatile
    private var needsReinit = false

    /**
     * Initializes the GPU mosaic recorder.
     *
     * @param eglCore EGL context manager
     * @param encoder Hardware encoder that provides the input surface
     */
    fun init(eglCore: EGLCore, encoder: HardwareEventRecorderGpu) {
        // Release old resources if reinitializing
        val oldSurface = encoderSurface
        if (oldSurface != null) {
            this.eglCore?.destroySurface(oldSurface)
            encoderSurface = null
            logger.info("Released old encoder surface for reinitialization")
        }

        this.eglCore = eglCore
        this.encoder = encoder

        // Seed TBC EMA from the encoder's configured fps so the first ~10
        // frames have correct PTS pacing. Without this, averageDeltaNs starts
        // at the static default (~5.5 fps) and the EMA needs ~22 frames to
        // converge — at 30 fps that's 700ms of fast-forward at the start of
        // each recording, plus a "snap to wall clock" jump from the 1s drift
        // failsafe. Reset smoothedPtsNs too so on reinit (FPS change) the
        // first frame uses real wall-clock time as the new origin.
        val encoderFps = encoder.getFps()
        averageDeltaNs = 1_000_000_000L / maxOf(1, encoderFps)
        smoothedPtsNs = -1
        lastRealTimeNs = -1
        logger.info(
            "TBC seeded: averageDeltaNs=" + (averageDeltaNs / 1_000_000) +
                "ms (from encoder fps=" + encoderFps + ")"
        )

        // Register callback to sync recording flag when encoder closes file
        encoder.setFileClosedCallback {
            if (recording) {
                recording = false
                logger.info("Recording flag reset (encoder closed file)")
            }

            // SOTA: Trigger storage cleanup after each file is saved
            try {
                val storageManager = StorageManager.getInstance()

                // Determine if this was a surveillance or manual recording based on output path
                // Surveillance files go to surveillance dir, manual recordings to recordings dir
                val lastPath = encoder.getCurrentOutputPath()
                if (lastPath != null) {
                    if (lastPath.contains("/surveillance/") || lastPath.contains("event_")) {
                        storageManager.onSurveillanceFileSaved()
                    } else {
                        storageManager.onRecordingFileSaved()
                    }
                }
            } catch (e: Exception) {
                logger.warn("Storage cleanup after file close failed: " + e.message)
            }
        }

        // Get encoder's input surface
        val inputSurface = encoder.getInputSurface()
            ?: throw RuntimeException("Encoder input surface is null")
        encoderInputSurface = inputSurface

        // Create EGL surface from encoder surface (with RECORDABLE flag)
        encoderSurface = eglCore.createWindowSurface(inputSurface)

        // Compile shaders and create program
        programId = GlUtil.createProgram(VERTEX_SHADER, FRAGMENT_SHADER)
        if (programId == 0) {
            throw RuntimeException("Failed to create shader program")
        }

        // Get attribute and uniform locations
        aPositionLocation = GLES20.glGetAttribLocation(programId, "aPosition")
        aTexCoordLocation = GLES20.glGetAttribLocation(programId, "aTexCoord")
        uCameraTexLocation = GLES20.glGetUniformLocation(programId, "uCameraTex")
        uApaModeLocation = GLES20.glGetUniformLocation(programId, "uApaMode")

        GlUtil.checkGlError("glGetLocation")

        // Create vertex buffers
        vertexBuffer = GlUtil.createFloatBuffer(VERTEX_COORDS)
        texCoordBuffer = GlUtil.createFloatBuffer(TEX_COORDS)

        // --- Overlay GL resource initialization ---
        overlayProgramId = GlUtil.createProgram(OVERLAY_VERTEX_SHADER, OVERLAY_FRAGMENT_SHADER)
        if (overlayProgramId == 0) {
            logger.error("Failed to create overlay shader program - overlay disabled")
            overlayEnabled = false
        } else {
            overlayAPositionLoc = GLES20.glGetAttribLocation(overlayProgramId, "aPosition")
            overlayATexCoordLoc = GLES20.glGetAttribLocation(overlayProgramId, "aTexCoord")
            overlayUTextureLoc = GLES20.glGetUniformLocation(overlayProgramId, "uTexture")

            // Generate overlay texture
            val texIds = IntArray(1)
            GLES20.glGenTextures(1, texIds, 0)
            overlayTextureId = texIds[0]

            overlayVertexBuffer = GlUtil.createFloatBuffer(OVERLAY_VERTEX_COORDS)
            overlayTexCoordBuffer = GlUtil.createFloatBuffer(OVERLAY_TEX_COORDS)

            // Create bitmap renderer
            overlayRenderer = OverlayBitmapRenderer()
            overlayTextureInitialized = false
        }

        logger.info(
            "GpuMosaicRecorder initialized (encoder codec=" +
                (if (encoder.isHevcCodec()) "H.265" else "H.264") + ")"
        )
    }

    /**
     * Draws a frame from the camera texture to the encoder surface.
     *
     * This performs the GPU-based 2x2 grid composition and submits the
     * result directly to the encoder. All processing happens in VRAM.
     *
     * NOTE: In SOTA mode, this ALWAYS renders (encoder is always running).
     * The recording flag only controls whether frames are saved to file.
     *
     * IMPORTANT: If the encoder is backed up (eglSwapBuffers blocking due to
     * full encoder input buffer), we skip rendering to prevent blocking the GL thread.
     * This keeps the camera HAL's BufferQueue flowing, which prevents the BYD native
     * parking camera app from losing video signal during prolonged recording.
     *
     * @param cameraTextureId OpenGL texture ID containing camera frame
     */
    fun drawFrame(cameraTextureId: Int) {
        // Check if initialized
        val egl = eglCore
        val surface = encoderSurface
        if (egl == null || surface == null) {
            // Not initialized yet - skip silently
            return
        }

        // ENCODER BACKPRESSURE GUARD: If previous frames took too long (encoder backed up),
        // skip this frame to prevent blocking the GL thread. The camera HAL's BufferQueue
        // must keep flowing or the BYD native camera app loses video signal.
        if (consecutiveSlowFrames >= SLOW_FRAME_SKIP_THRESHOLD) {
            skippedFrames++
            // Reset after skipping one frame to retry
            consecutiveSlowFrames = 0
            if (skippedFrames % 10 == 1) {
                logger.warn(
                    "Encoder backpressure: skipped " + skippedFrames +
                        " frames to keep camera HAL flowing (last draw=" +
                        (lastDrawDurationNs / 1_000_000) + "ms)"
                )
            }
            return
        }

        // SOTA: Always render to encoder (for pre-record buffer)
        // The encoder decides whether to write to file or just buffer

        val startTime = System.nanoTime()

        // Make encoder surface current
        egl.makeCurrent(surface)

        // Set viewport to encoder resolution (2560x1920)
        GLES20.glViewport(0, 0, 2560, 1920)

        // Clear
        GLES20.glClearColor(0.0f, 0.0f, 0.0f, 1.0f)
        GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)

        // Use our shader program
        GLES20.glUseProgram(programId)

        // Bind camera texture
        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, cameraTextureId)
        GLES20.glUniform1i(uCameraTexLocation, 0)
        GLES20.glUniform1f(uApaModeLocation, cameraLayout.toFloat())

        // Set up vertex attributes
        GLES20.glEnableVertexAttribArray(aPositionLocation)
        GLES20.glVertexAttribPointer(
            aPositionLocation, 2, GLES20.GL_FLOAT, false, 0, vertexBuffer
        )

        GLES20.glEnableVertexAttribArray(aTexCoordLocation)
        GLES20.glVertexAttribPointer(
            aTexCoordLocation, 2, GLES20.GL_FLOAT, false, 0, texCoordBuffer
        )

        // Draw fullscreen quad (shader does the 2x2 grid mapping)
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

        // Disable vertex arrays
        GLES20.glDisableVertexAttribArray(aPositionLocation)
        GLES20.glDisableVertexAttribArray(aTexCoordLocation)

        // OVERLAY PASS: Composite telemetry overlay if enabled
        drawOverlayPass()

        // --- SOTA: Dynamic Time-Base Corrector (TBC) ---
        // Learns the actual hardware frame rate via EMA and produces perfectly
        // paced timestamps that eliminate both fast-forward and rubber-banding.
        val nowNs = System.nanoTime()
        if (smoothedPtsNs < 0) {
            // First frame initialization
            smoothedPtsNs = nowNs
            lastRealTimeNs = nowNs
        } else {
            // 1. Calculate the raw, jittery delta
            val rawDeltaNs = nowNs - lastRealTimeNs
            lastRealTimeNs = nowNs

            // 2. Clamp outliers (ignore massive CPU freezes or dropped frames)
            //    Min 30ms (33 FPS cap), Max 500ms (2 FPS floor)
            val clampedDeltaNs = rawDeltaNs.coerceIn(30_000_000L, 500_000_000L)

            // 3. Update the moving average (Alpha=0.1 for smooth adaptation)
            //    This learns the car's actual framerate without jitter
            averageDeltaNs = (averageDeltaNs * 0.9 + clampedDeltaNs * 0.1).toLong()

            // 4. Advance the perfectly smooth timeline
            smoothedPtsNs += averageDeltaNs

            // 5. Failsafe: prevent smoothed clock from drifting >1s from real time
            if (abs(nowNs - smoothedPtsNs) > 1_000_000_000L) {
                smoothedPtsNs = nowNs
            }
        }

        // Push the mathematically perfect timestamp to the hardware encoder
        try {
            egl.swapBuffersWithTimestamp(surface, smoothedPtsNs)
            consecutiveSurfaceErrors = 0 // Reset on success
        } catch (e: RuntimeException) {
            consecutiveSurfaceErrors++
            if (consecutiveSurfaceErrors >= SURFACE_ERROR_REINIT_THRESHOLD) {
                logger.error(
                    "Encoder surface dead after " + consecutiveSurfaceErrors +
                        " consecutive errors, requesting reinit"
                )
                needsReinit = true
                encoderSurface = null // Prevent further attempts
                return
            }
            if (consecutiveSurfaceErrors <= 3) {
                logger.warn(
                    "swapBuffers failed (" + consecutiveSurfaceErrors + "): " + e.message
                )
            }
            return
        }

        // Track draw duration to detect encoder backpressure
        val elapsedNs = System.nanoTime() - startTime
        lastDrawDurationNs = elapsedNs

        if (elapsedNs > MAX_DRAW_DURATION_NS) {
            consecutiveSlowFrames++
        } else {
            consecutiveSlowFrames = 0
        }

        // Update stats (only count if actually recording to file)
        if (recording) {
            lastFrameTime = System.currentTimeMillis()
            frameCount++
        }
    }

    /** The telemetry-overlay compositing pass, run after the mosaic quad. */
    private fun drawOverlayPass() {
        val renderer = overlayRenderer
        if (!overlayEnabled || !overlayRecordingModeAllowed || renderer == null) return

        overlayFrameCounter++
        try {
            // Update bitmap every 3rd frame (~5 FPS at 15 FPS recording)
            val collector = telemetryCollector
            if ((overlayFrameCounter == 1 || overlayFrameCounter % 3 == 0) && collector != null) {
                // getLatestSnapshot() is null until the collector's first poll lands; the
                // renderer's field selection needs a real snapshot, so skip the update
                // rather than pass a placeholder that would draw zeroes.
                val snapshot = collector.getLatestSnapshot()
                // BladeWatch-y78o.5: every overlay-enabled recording that reaches this call
                // site today (continuous/drive-mode dashcam AND proximity-triggered clips --
                // both route through GpuSurveillancePipeline's same Mode.NORMAL_RECORDING
                // path; surveillance/sentry recording calls setOverlayRecordingModeAllowed
                // (false) and never reaches here at all) uses the CONTINUOUS type's field
                // selection. Re-reading config here (not cached) is cheap at ~5 fps.
                if (snapshot != null) {
                    val enabledFields = OverlayFieldSelectionResolver.resolve(
                        UnifiedConfigManager.getTelemetryOverlay(),
                        RecordingOverlayType.CONTINUOUS
                    )
                    renderer.renderFrame(snapshot, overlayFrameCounter / 3, enabledFields)
                }
            }

            // Upload new bitmap to texture ONLY when the double buffer actually swapped.
            // swapAndGetFront() returns null when no new content is available,
            // avoiding the expensive texImage2D/texSubImage2D call on unchanged frames.
            val overlayBitmap = renderer.swapAndGetFront()
            if (overlayBitmap != null && !overlayBitmap.isRecycled) {
                GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, overlayTextureId)
                if (!overlayTextureInitialized) {
                    // First upload: allocate GPU texture storage with texImage2D
                    GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, overlayBitmap, 0)
                    GLES20.glTexParameteri(
                        GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MIN_FILTER, GLES20.GL_LINEAR
                    )
                    GLES20.glTexParameteri(
                        GLES20.GL_TEXTURE_2D, GLES20.GL_TEXTURE_MAG_FILTER, GLES20.GL_LINEAR
                    )
                    overlayTextureInitialized = true
                } else {
                    // Subsequent uploads: reuse existing texture storage with texSubImage2D
                    // This avoids GPU texture reallocation on every update
                    GLUtils.texSubImage2D(GLES20.GL_TEXTURE_2D, 0, 0, 0, overlayBitmap)
                }
                overlayTextureReady = true

                if (overlayFrameCounter <= 3) {
                    logger.info(
                        "Overlay: uploaded frame " + overlayFrameCounter +
                            " bitmap=" + overlayBitmap.width + "x" + overlayBitmap.height
                    )
                }
            }

            // Draw overlay quad EVERY frame (reuses last uploaded texture)
            if (overlayTextureReady) {
                GLES20.glEnable(GLES20.GL_BLEND)
                GLES20.glBlendFunc(GLES20.GL_SRC_ALPHA, GLES20.GL_ONE_MINUS_SRC_ALPHA)

                GLES20.glUseProgram(overlayProgramId)

                GLES20.glActiveTexture(GLES20.GL_TEXTURE1)
                GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, overlayTextureId)
                GLES20.glUniform1i(overlayUTextureLoc, 1)

                GLES20.glEnableVertexAttribArray(overlayAPositionLoc)
                GLES20.glVertexAttribPointer(
                    overlayAPositionLoc, 2, GLES20.GL_FLOAT, false, 0, overlayVertexBuffer
                )
                GLES20.glEnableVertexAttribArray(overlayATexCoordLoc)
                GLES20.glVertexAttribPointer(
                    overlayATexCoordLoc, 2, GLES20.GL_FLOAT, false, 0, overlayTexCoordBuffer
                )

                GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)

                GLES20.glDisableVertexAttribArray(overlayAPositionLoc)
                GLES20.glDisableVertexAttribArray(overlayATexCoordLoc)
                GLES20.glDisable(GLES20.GL_BLEND)
            }
        } catch (e: Exception) {
            // Skip overlay on error, never drop frame
            if (overlayFrameCounter <= 5) {
                logger.error("Overlay draw error: " + e.message, e)
            }
        }
    }

    /**
     * Starts recording to a file.
     *
     * @param outputPath Path for the output MP4 file
     */
    fun startRecording(outputPath: String) {
        // Default 5 sec post-record
        startEncoderRecording(outputPath, 5000, setStorageActive = true)
    }

    /**
     * Triggers event recording with pre-record buffer flush.
     * Alias for startRecording for API compatibility.
     */
    fun triggerEventRecording(outputPath: String, postRecordDurationMs: Long) {
        startEncoderRecording(outputPath, postRecordDurationMs, setStorageActive = false)
    }

    /**
     * The one start path. Both public entry points differ only in the post-record window and
     * whether they flag StorageManager as recording-active.
     */
    private fun startEncoderRecording(
        outputPath: String,
        postRecordDurationMs: Long,
        setStorageActive: Boolean
    ) {
        synchronized(recordingLock) {
            if (recording) {
                logger.warn("Already recording")
                return
            }

            // Start encoder recording (with pre-record buffer flush)
            val enc = encoder
            if (enc != null && enc.triggerEventRecording(outputPath, postRecordDurationMs)) {
                recording = true
                frameCount = 0

                if (setStorageActive) {
                    // SOTA: Notify StorageManager that recording is active
                    // (for periodic cleanup)
                    try {
                        StorageManager.getInstance().setRecordingActive(true)
                    } catch (e: Exception) {
                        logger.warn("Could not set recording active state: " + e.message)
                    }

                    logger.info(
                        "Recording started: " + outputPath + " (codec=" +
                            (if (enc.isHevcCodec()) "H.265" else "H.264") + ")"
                    )
                } else {
                    logger.info("Recording started: $outputPath")
                }
            } else {
                logger.error("Failed to start encoder recording")
            }
        }
    }

    /**
     * Starts recording, optionally into a custom output directory with a custom filename
     * prefix (e.g. "cam", "proximity", "event"). Defaults to the recordings dir and "cam".
     *
     * @param outputDir Custom output directory (null for default recordings dir)
     * @param prefix Filename prefix
     */
    @JvmOverloads
    fun startRecording(outputDir: File? = null, prefix: String = "cam") {
        // Two-phase guard for the directory+prefix overload:
        //
        // Phase 1 (this check, intentionally unlocked): cheap volatile read.
        //   If recording is already true, skip mkdirs/ensureSpace/timestamp
        //   generation — work that's irrelevant once another caller has
        //   started. This is a performance optimization, NOT the correctness
        //   guarantee.
        //
        // Phase 2 (inside the inner startRecording(outputPath) call): the
        //   recordingLock-protected re-check is the authoritative one. If two
        //   callers both pass Phase 1, both will compute their own timestamps,
        //   but only the first to acquire recordingLock will start the encoder
        //   and create a file. The second caller is rejected at the inner
        //   guard and discards its timestamp harmlessly — the wasted work is
        //   bounded to a few mkdirs and a SimpleDateFormat call, which is
        //   acceptable to keep this method lock-free during normal operation.
        //
        // The duplicate-files-on-disk symptom this whole structure prevents
        // came from an earlier version where neither phase used a lock; the
        // encoder's startStopLock alone was insufficient because the wrapper's
        // recording flag had its own race window.
        if (recording) {
            logger.warn(
                "Already recording — ignoring redundant start (dir=" +
                    (outputDir?.name ?: "default") + ", prefix=" + prefix + ")"
            )
            return
        }
        // SOTA: Use StorageManager for recordings directory and auto-cleanup
        try {
            val storageManager = StorageManager.getInstance()

            // Use provided directory or default to recordings dir
            val targetDir = outputDir ?: storageManager.recordingsDir

            // Ensure directory exists
            if (!targetDir.exists()) {
                targetDir.mkdirs()
            }

            // Reserve ~100MB for new recording
            storageManager.ensureRecordingsSpace(100L * 1024 * 1024)

            // Generate filename with timestamp
            startRecording(File(targetDir, prefix + "_" + timestamp() + ".mp4").absolutePath)
        } catch (e: Exception) {
            logger.error("Failed to start recording: " + e.message)
            // Fallback to legacy path
            startRecording(
                "/storage/emulated/0/Android/data/net.bladewatch.app/files/" +
                    prefix + "_" + timestamp() + ".mp4"
            )
        }
    }

    private fun timestamp(): String =
        SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())

    /** Stops recording. */
    fun stopRecording() {
        if (!recording) {
            return
        }

        recording = false
        markStorageInactive()

        // Stop encoder recording
        encoder?.stopRecording()
    }

    /**
     * Stops recording with post-record support.
     *
     * @param immediate If true, stops immediately. If false, uses post-record.
     */
    fun stopEventRecording(immediate: Boolean, postRecordDurationMs: Long) {
        if (!recording) {
            return
        }

        recording = false
        markStorageInactive()

        // Stop encoder recording
        encoder?.stopEventRecording(immediate, postRecordDurationMs)

        logger.info(String.format(Locale.US, "Recording stopped. Total frames: %d", frameCount))
    }

    /** SOTA: Notify StorageManager that recording is inactive. */
    private fun markStorageInactive() {
        try {
            StorageManager.getInstance().setRecordingActive(false)
        } catch (e: Exception) {
            logger.warn("Could not set recording inactive state: " + e.message)
        }
    }

    /**
     * Checks if currently recording.
     *
     * @return true if recording, false otherwise
     */
    fun isRecording(): Boolean = recording

    /**
     * Gets the timestamp of the last rendered frame.
     *
     * @return Timestamp in milliseconds
     */
    fun getLastFrameTime(): Long = lastFrameTime

    /**
     * Gets the total number of frames rendered.
     *
     * @return Frame count
     */
    fun getFrameCount(): Long = frameCount

    /**
     * Gets the encoder instance.
     *
     * @return Hardware encoder
     */
    fun getEncoder(): HardwareEventRecorderGpu? = encoder

    fun setOverlayEnabled(enabled: Boolean) {
        overlayEnabled = enabled
    }

    /**
     * Sets the camera layout mode for the mosaic shader.
     * 0 = 4-camera mosaic (Seal: pano_h/pano_l, surfaceMode=0)
     * 1 = APA passthrough (single pre-composited image, surfaceMode=1 with apa/byd_apa tag)
     * 2 = 3-camera mosaic (Atto 3 default: Rear, Side, Front)
     */
    fun setCameraLayout(layout: Int) {
        apaMode = layout == 1
        cameraLayout = layout
        val names = arrayOf("4-camera mosaic", "APA passthrough", "3-camera mosaic")
        logger.info(
            "Camera layout: " +
                (if (layout < names.size) names[layout] else "unknown($layout)")
        )
    }

    fun setApaMode(apa: Boolean) {
        setCameraLayout(if (apa) 1 else 0)
    }

    // (TBC timestamp is computed inline in drawFrame)

    fun isOverlayEnabled(): Boolean = overlayEnabled

    fun setOverlayRecordingModeAllowed(allowed: Boolean) {
        overlayRecordingModeAllowed = allowed
    }

    fun setTelemetryCollector(collector: TelemetryDataCollector?) {
        telemetryCollector = collector
    }

    /**
     * Returns true if the encoder surface has died and needs reinitialization.
     * Called by PanoramicCameraGpu to trigger encoder recovery.
     */
    fun needsReinit(): Boolean = needsReinit

    /** Clears the reinit flag after recovery is complete. */
    fun clearReinitFlag() {
        needsReinit = false
        consecutiveSurfaceErrors = 0
    }

    /**
     * SOTA: Releases only the encoder surface without releasing other resources.
     * Called before encoder reinitialization to prevent EGL_BAD_SURFACE errors.
     * The surface will be recreated when init() is called with the new encoder.
     */
    fun releaseEncoderSurface() {
        val surface = encoderSurface
        val egl = eglCore
        if (surface != null && egl != null) {
            egl.destroySurface(surface)
            encoderSurface = null
            encoderInputSurface = null
            logger.info("Released encoder surface for reinitialization")
        }
    }

    /** Releases all resources. */
    fun release() {
        recording = false

        if (programId != 0) {
            GlUtil.deleteProgram(programId)
            programId = 0
        }

        // Release overlay resources
        if (overlayProgramId != 0) {
            GLES20.glDeleteProgram(overlayProgramId)
            overlayProgramId = 0
        }
        if (overlayTextureId != 0) {
            GLES20.glDeleteTextures(1, intArrayOf(overlayTextureId), 0)
            overlayTextureId = 0
        }
        overlayRenderer?.release()
        overlayRenderer = null
        overlayTextureReady = false
        overlayTextureInitialized = false

        val surface = encoderSurface
        if (surface != null) {
            eglCore?.destroySurface(surface)
            encoderSurface = null
        }

        logger.info("GpuMosaicRecorder released")
    }

    companion object {
        private const val TAG = "GpuMosaicRecorder"
        private val logger = DaemonLogger.getInstance(TAG)

        /** 30ms threshold */
        private const val MAX_DRAW_DURATION_NS = 30_000_000L

        /** Skip after 3 slow frames */
        private const val SLOW_FRAME_SKIP_THRESHOLD = 3

        private const val SURFACE_ERROR_REINIT_THRESHOLD = 3

        /** Fullscreen quad vertices (NDC coordinates) */
        private val VERTEX_COORDS = floatArrayOf(
            -1.0f, -1.0f, // Bottom-left
            1.0f, -1.0f, // Bottom-right
            -1.0f, 1.0f, // Top-left
            1.0f, 1.0f // Top-right
        )

        /** Texture coordinates (flipped vertically for correct orientation) */
        private val TEX_COORDS = floatArrayOf(
            0.0f, 1.0f, // Bottom-left (flipped to top-left)
            1.0f, 1.0f, // Bottom-right (flipped to top-right)
            0.0f, 0.0f, // Top-left (flipped to bottom-left)
            1.0f, 0.0f // Top-right (flipped to bottom-right)
        )

        /**
         * Overlay quad: top 160px of 1920px frame.
         * NDC Y: +1.0 (top) down to +1.0 - 0.1667 = +0.8333
         */
        private val OVERLAY_VERTEX_COORDS = floatArrayOf(
            -1.0f, 0.8333f,
            1.0f, 0.8333f,
            -1.0f, 1.0f,
            1.0f, 1.0f
        )

        /** Tex coords flipped Y for correct orientation */
        private val OVERLAY_TEX_COORDS = floatArrayOf(
            0.0f, 1.0f,
            1.0f, 1.0f,
            0.0f, 0.0f,
            1.0f, 0.0f
        )

        /** Vertex shader - simple passthrough */
        private val VERTEX_SHADER =
            "attribute vec4 aPosition;\n" +
            "attribute vec2 aTexCoord;\n" +
            "varying vec2 vTexCoord;\n" +
            "void main() {\n" +
            "    gl_Position = aPosition;\n" +
            "    vTexCoord = aTexCoord;\n" +
            "}\n"

        // Fragment shader - supports 4-camera mosaic, 3-camera mosaic, and APA passthrough.
        // uApaMode: 0.0 = 4-camera mosaic (Seal: pano_h/pano_l with surfaceMode=0)
        //           1.0 = APA passthrough (single pre-composited image)
        //           2.0 = 3-camera mosaic (Atto 3: Rear=0-25%, Side=25-75%, Front=75-100%)
        // 4-cam strip: cam1(Rear)=0.00, cam2(Left)=0.25, cam3(Right)=0.50, cam4(Front)=0.75
        // 3-cam strip: Rear=0.00-0.25, Left+Right=0.25-0.75, Front=0.75-1.00
        private val FRAGMENT_SHADER =
            "#extension GL_OES_EGL_image_external : require\n" +
            "precision mediump float;\n" +
            "uniform samplerExternalOES uCameraTex;\n" +
            "uniform float uApaMode;\n" +
            "varying vec2 vTexCoord;\n" +
            "void main() {\n" +
            "    vec2 samplePos;\n" +
            "    if (uApaMode > 1.5) {\n" +
            "        // 3-camera mosaic: TL=Front, BL=Rear, Right=Side(Left+Right)\n" +
            "        if (vTexCoord.x < 0.5) {\n" +
            "            // Left column: top=Front(0.75-1.0), bottom=Rear(0.0-0.25)\n" +
            // 0-0.5 -> 0-0.25
            "            float localX = vTexCoord.x * 0.5;\n" +
            "            float localY = mod(vTexCoord.y, 0.5) * 2.0;\n" +
            "            if (vTexCoord.y < 0.5) {\n" +
            // Front
            "                samplePos = vec2(localX + 0.75, localY);\n" +
            "            } else {\n" +
            // Rear
            "                samplePos = vec2(localX, localY);\n" +
            "            }\n" +
            "        } else {\n" +
            "            // Right column: Side view (0.25-0.75, full height)\n" +
            // 0.5-1.0 -> 0-0.5
            "            float localX = (vTexCoord.x - 0.5) * 1.0;\n" +
            "            samplePos = vec2(0.25 + localX * 0.5, vTexCoord.y);\n" +
            "        }\n" +
            "    } else if (uApaMode > 0.5) {\n" +
            "        // APA passthrough\n" +
            "        samplePos = vTexCoord;\n" +
            "    } else {\n" +
            "        // 4-camera mosaic (Seal default)\n" +
            "        vec2 gridPos = step(0.5, vTexCoord);\n" +
            "        float stripOffsetX = 0.75 - (gridPos.x * 0.25) - (gridPos.y * 0.75) + (gridPos.x * gridPos.y * 0.50);\n" +
            "        float localX = mod(vTexCoord.x, 0.5) * 0.5;\n" +
            "        float localY = mod(vTexCoord.y, 0.5) * 2.0;\n" +
            "        samplePos = vec2(localX + stripOffsetX, localY);\n" +
            "    }\n" +
            "    gl_FragColor = texture2D(uCameraTex, samplePos);\n" +
            "}\n"

        /** Overlay vertex shader - simple 2D passthrough */
        private val OVERLAY_VERTEX_SHADER =
            "attribute vec4 aPosition;\n" +
            "attribute vec2 aTexCoord;\n" +
            "varying vec2 vTexCoord;\n" +
            "void main() {\n" +
            "    gl_Position = aPosition;\n" +
            "    vTexCoord = aTexCoord;\n" +
            "}\n"

        /** Overlay fragment shader - standard sampler2D with alpha (NOT OES) */
        private val OVERLAY_FRAGMENT_SHADER =
            "precision mediump float;\n" +
            "varying vec2 vTexCoord;\n" +
            "uniform sampler2D uTexture;\n" +
            "void main() {\n" +
            "    gl_FragColor = texture2D(uTexture, vTexCoord);\n" +
            "}\n"
    }
}
