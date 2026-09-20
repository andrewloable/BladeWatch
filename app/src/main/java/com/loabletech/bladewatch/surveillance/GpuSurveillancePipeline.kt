package net.bladewatch.app.surveillance

import android.content.Context
import android.content.res.AssetManager
import android.graphics.Bitmap

import net.bladewatch.app.camera.AvmCameraHelper
import net.bladewatch.app.camera.CameraFirmwareInfo
import net.bladewatch.app.camera.PanoCameraDiscovery
import net.bladewatch.app.camera.PanoramicCameraGpu
import net.bladewatch.app.config.UnifiedConfigManager
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.storage.StorageManager
import net.bladewatch.app.streaming.GpuStreamScaler
import net.bladewatch.app.streaming.JpegEncoder
import net.bladewatch.app.streaming.StillFrameRefresher
import net.bladewatch.app.streaming.WebSocketStreamServer
import net.bladewatch.app.telemetry.TelemetryDataCollector

import org.json.JSONObject

import java.io.ByteArrayOutputStream
import java.io.File
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.function.BooleanSupplier

/**
 * GpuSurveillancePipeline - Complete GPU Zero-Copy surveillance system.
 *
 * Orchestrates all components of the GPU pipeline:
 * - PanoramicCameraGpu: Camera → GPU texture
 * - GpuMosaicRecorder: GPU composition → Encoder
 * - GpuDownscaler: GPU thumbnail → CPU
 * - SurveillanceEngineGpu: Motion detection & AI
 * - AdaptiveBitrateController: Quality optimization
 *
 * Achieves <10% CPU usage through GPU zero-copy architecture.
 *
 * @param cameraWidth Camera width (typically 5120)
 * @param cameraHeight Camera height (typically 960)
 * @param eventOutputDir Directory for event recordings
 */
class GpuSurveillancePipeline(
    private val cameraWidth: Int,
    private val cameraHeight: Int,
    private val eventOutputDir: File
) {
    // Components. The ones callers read are `var ... private set` rather than a private
    // field plus a getXxx() function: that spelling keeps the Java ABI byte-identical
    // (getCamera(), getSentry(), ...) while letting Kotlin callers use the property syntax
    // they already used against the Java original's synthetic properties.
    var camera: PanoramicCameraGpu? = null
        private set
    private var recorder: GpuMosaicRecorder? = null  // Single recorder for both modes
    private var downscaler: GpuDownscaler? = null
    var sentry: SurveillanceEngineGpu? = null
        private set
    // The pipeline's own encoder handle. NOT the same thing as the public `encoder`
    // property below, which reports the recorder's encoder — the Java original drew the
    // same distinction between the `encoder` field and getEncoder().
    private var mainEncoder: HardwareEventRecorderGpu? = null
    var bitrateController: AdaptiveBitrateController? = null
        private set

    // Streaming components (separate encoder - always available)
    var streamScaler: GpuStreamScaler? = null
        private set
    var streamEncoder: HardwareEventRecorderGpu? = null
        private set
    var webSocketServer: WebSocketStreamServer? = null
        private set
    private var streamingEnabled = false

    // BladeWatch-y78o.1: still-frame fallback for browsers with no video decoder. Reads the
    // same mosaic RGB buffer `sentry` already produces every frame; only the periodic JPEG
    // encode (see StillFrameRefresher's own doc comment) is new work, and it is on its own
    // timer, not the camera's.
    private var stillFrameRefresher: StillFrameRefresher? = null

    // Telemetry overlay
    private var telemetryCollector: TelemetryDataCollector? = null
    @Volatile private var overlayEnabledConfig = false

    // Mode tracking
    private enum class Mode {
        IDLE,               // Nothing active
        NORMAL_RECORDING,   // User manually recording
        SURVEILLANCE        // Auto-recording on motion
    }
    private var currentMode = Mode.IDLE

    // Configuration
    private val encoderWidth = 2560
    private val encoderHeight = 1920

    /** The pipeline configuration. */
    val config = GpuPipelineConfig()

    // State
    private var initialized = false
    private var running = false
    private var recordingMode = false  // true = recording, false = viewing only

    // Serializes runtime reconfig methods (applyFpsChange, applyBitrateChange,
    // applyCodecChange). Without this, two web-UI changes arriving back-to-back
    // can interleave reinitializeEncoder() calls — one observes encoder=null
    // mid-tear-down and silently no-ops, or worse, both threads tear down
    // recorder surfaces concurrently.
    private val reconfigLock = Any()

    // Saved init params — needed for re-initialization after stop/start cycle (ACC OFF→ON)
    private var savedAssetManager: AssetManager? = null
    private var savedContext: Context? = null

    // Deferred recording: stored when startRecording() is called before encoder is ready
    @Volatile private var pendingRecordingDir: File? = null
    @Volatile private var pendingRecordingPrefix: String? = null

    private fun applyCameraLayoutToConsumers(layout: Int) {
        recorder?.setCameraLayout(layout)
        streamScaler?.setCameraLayout(layout)
    }

    private fun configureCameraFromSavedConfig(
        cameraConfig: JSONObject?,
        currentFirmware: CameraFirmwareInfo?
    ): Boolean {
        val cam = camera
        if (cam == null || cameraConfig == null) {
            return false
        }

        val savedId = cameraConfig.optInt("probedCameraId", -1)
        val savedMode = cameraConfig.optInt("probedSurfaceMode", -1)
        val validated = cameraConfig.optBoolean("probedAndValidated", false)
        val manual = cameraConfig.optBoolean("manualOverride", false)
        val fallback = cameraConfig.optBoolean("fallbackFromProbe", false)
        if (savedId < 0 || savedMode < 0 || (!validated && !manual)) {
            return false
        }

        val layout = if (cameraConfig.has("cameraLayout")) cameraConfig.optInt("cameraLayout", 0) else 0
        val reprobeOnNextRestart = cameraConfig.optBoolean("reprobeOnNextRestart", false)
        val sourceTag = cameraConfig.optString(
            "sourceBmmTag", if (manual) "manual" else if (fallback) "probe-fallback" else ""
        )
        val method = cameraConfig.optString(
            "discoveryMethod", if (manual) "manual" else if (fallback) "probe" else "saved"
        )
        val camSort = cameraConfig.optString(
            "vehicleCamSort", currentFirmware?.vehicleCamSort ?: ""
        )

        cam.setCameraId(savedId)
        cam.setCameraSurfaceMode(savedMode)
        cam.setAutoProbeCameras(false)
        cam.setManualOverrideActive(manual)
        cam.setFallbackFromProbe(fallback)
        cam.setCameraSelectionMetadata(layout, sourceTag, method, camSort)
        cam.setFirmwareInfo(currentFirmware)
        cam.setArbitrationMode(cameraConfig.optString("arbitrationMode", "eventCallbackOnly"))

        val firmwareMatches = currentFirmware != null &&
            currentFirmware.hasAnySignal() &&
            currentFirmware.matches(cameraConfig)
        if (reprobeOnNextRestart) {
            logger.info(
                "Saved camera tuple marked for reprobe on next restart; ignoring tuple trust (" +
                    "id=" + savedId + ", surfaceMode=" + savedMode + ", layout=" + layout + ")"
            )
            return false
        }
        if (manual) {
            logger.info(
                "Using MANUAL camera config: id=" + savedId + ", surfaceMode=" + savedMode +
                    ", layout=" + layout
            )
            if (!firmwareMatches) {
                logger.info("Manual override firmware mismatch is expected when the tuple was selected on a different build")
            }
            cam.setSkipFrameValidation(false)
        } else if (validated && firmwareMatches) {
            logger.info(
                "Using validated saved camera config: id=" + savedId + ", surfaceMode=" + savedMode +
                    ", layout=" + layout
            )
            cam.setSkipFrameValidation(true)
        } else {
            logger.info(
                "Using saved camera config but keeping validation enabled because firmware metadata is missing or changed: id=" +
                    savedId + ", surfaceMode=" + savedMode + ", layout=" + layout
            )
            if (!firmwareMatches) {
                logger.info("Camera firmware mismatch detected, current build will revalidate before trusting the tuple")
            }
            cam.setSkipFrameValidation(false)
        }

        applyCameraLayoutToConsumers(layout)
        cam.persistCameraConfig(validated && firmwareMatches && !manual, null)
        return true
    }

    private fun configureCameraFromDiscovery(
        discovery: PanoCameraDiscovery?,
        currentFirmware: CameraFirmwareInfo?
    ) {
        val cam = camera
        if (cam == null || discovery == null) {
            return
        }

        cam.setCameraId(discovery.cameraId)
        cam.setCameraSurfaceMode(discovery.surfaceMode)
        cam.setManualOverrideActive(false)
        cam.setFallbackFromProbe(false)
        cam.setCameraSelectionMetadata(discovery)
        cam.setFirmwareInfo(currentFirmware)
        cam.setSkipFrameValidation(false)
        cam.setArbitrationMode("eventCallbackOnly")
        // BMM tells us which AVM tuple the firmware advertises, but it does
        // not prove that addPreviewSurface/startPreview will deliver frames
        // in this process. Keep auto-probe armed so the frame-15 validator, or
        // the no-frame timeout, can promote or reject the tuple at runtime.
        cam.setAutoProbeCameras(true)
        applyCameraLayoutToConsumers(discovery.cameraLayout)
        cam.persistCameraConfig(false, null)
        logger.info("Using BMM discovered camera tuple: $discovery")
    }

    private fun configureDefaultCamera(currentFirmware: CameraFirmwareInfo?) {
        val cam = camera ?: return

        cam.setCameraId(1)
        cam.setCameraSurfaceMode(0)
        cam.setManualOverrideActive(false)
        cam.setFallbackFromProbe(false)
        cam.setCameraSelectionMetadata(0, "default", "default", currentFirmware?.vehicleCamSort ?: "")
        cam.setFirmwareInfo(currentFirmware)
        cam.setSkipFrameValidation(false)
        cam.setArbitrationMode("eventCallbackOnly")
        // ID 1/mode 0 is a good first guess on Seal, not a validated fact.
        // If the HAL opens this tuple but produces zero ImageReader callbacks,
        // auto-probe must stay enabled so PanoramicCameraGpu can advance to
        // the next camera/surface tuple instead of streaming a blank view.
        cam.setAutoProbeCameras(true)
        applyCameraLayoutToConsumers(0)
        cam.persistCameraConfig(false, null)
        logger.info("Using default camera tuple as first auto-probe candidate: id=1, surfaceMode=0, layout=0")
    }

    private fun configureAutoProbeFallback(currentFirmware: CameraFirmwareInfo?) {
        val cam = camera ?: return

        cam.setCameraSelectionMetadata(0, "probe", "auto-probe", currentFirmware?.vehicleCamSort ?: "")
        cam.setFirmwareInfo(currentFirmware)
        cam.setManualOverrideActive(false)
        cam.setFallbackFromProbe(true)
        cam.setSkipFrameValidation(false)
        cam.setArbitrationMode("eventCallbackOnly")
        cam.setAutoProbeCameras(true)
        applyCameraLayoutToConsumers(0)
        logger.warn("All camera config strategies failed — enabling auto-probe")
    }

    private fun configureCameraSelection(
        currentFirmware: CameraFirmwareInfo?,
        allowDiscovery: Boolean,
        allowDefault: Boolean,
        phase: String
    ) {
        // Selection order is intentional:
        // 1) trust a saved tuple only if firmware metadata still matches or the
        //    user explicitly forced a manual override,
        // 2) fall back to BMM discovery when available,
        // 3) use the known-good default tuple,
        // 4) finally enable auto-probe so the HAL can self-discover.
        val cameraConfig = loadCameraConfigSection()
        if (cameraConfig != null) {
            val reprobeRequested = cameraConfig.optBoolean("reprobeOnNextRestart", false)
            if (reprobeRequested) {
                logger.info("Camera reprobe requested for $phase — skipping saved tuple trust")
            } else if (configureCameraFromSavedConfig(cameraConfig, currentFirmware)) {
                return
            }
        }

        if (allowDiscovery) {
            val discovery = AvmCameraHelper.discoverPanoCamera()
            if (discovery != null) {
                logger.info("Using BMM discovered camera tuple during $phase: $discovery")
                configureCameraFromDiscovery(discovery, currentFirmware)
                return
            }
        }

        if (allowDefault) {
            configureDefaultCamera(currentFirmware)
            return
        }

        configureAutoProbeFallback(currentFirmware)
    }

    /**
     * The underlying hardware encoder, or null if the pipeline has not been initialized yet.
     * Used by callers that need the active output file path for things like
     * push-notification deep-links.
     */
    val encoder: HardwareEventRecorderGpu?
        get() = recorder?.getEncoder()

    /**
     * Sets the recording mode (Normal/Sentry).
     */
    fun setRecordingMode(mode: GpuPipelineConfig.RecordingMode) {
        config.recordingMode = mode

        // Apply to encoder - but DON'T override user's bitrate setting
        // Only change FPS (which requires encoder restart anyway)
        if (mainEncoder != null) {
            // Use the user's configured bitrate, not the mode's default
            val userBitrate = config.getEffectiveBitrate()
            bitrateController?.setImmediateBitrate(userBitrate)
            // Note: FPS is set during encoder initialization
            // Dynamic FPS change would require encoder restart
            logger.info(
                String.format(
                    "Recording mode: %s (using user bitrate=%d Mbps, mode default was %d Mbps)",
                    mode, userBitrate / 1_000_000, mode.bitrate / 1_000_000
                )
            )
        }
    }

    /**
     * Sets the streaming quality (HQ/LQ).
     */
    fun setStreamingQuality(quality: GpuPipelineConfig.StreamingQuality) {
        config.streamingQuality = quality
        // Quality is saved — it will be applied on next stream start.
        // Don't restart the active stream to avoid disrupting the live view.
        logger.info(
            String.format(
                "Streaming quality saved: %s (%dx%d @ %dfps)",
                quality, quality.width, quality.height, quality.fps
            )
        )
        // GL budget warning: if the stream encoder rate exceeds the
        // recording encoder rate, both run inside the same GL render loop
        // iteration — at 30+30 fps the GL thread may not have headroom.
        // Not a hard error (encoder backpressure / reactive AI-skip will
        // handle it), but worth flagging so the operator knows why
        // performance might dip.
        val recordingFps = mainEncoder?.getFps() ?: 0
        if (recordingFps > 0 && quality.fps > recordingFps) {
            logger.warn(
                "Stream fps " + quality.fps +
                    " > recording fps " + recordingFps +
                    " — GL thread budget may be tight on heavy frames"
            )
        }
    }

    /**
     * Applies a bitrate change to the encoder.
     *
     * Reinitializes encoder immediately to ensure new bitrate is used.
     *
     * @param bitrate New bitrate in bps
     */
    fun applyBitrateChange(bitrate: Int) {
        synchronized(reconfigLock) {
            applyBitrateChangeLocked(bitrate)
        }
    }

    private fun applyBitrateChangeLocked(bitrate: Int) {
        // Update config first
        config.setCustomBitrate(bitrate)

        val enc = mainEncoder
        if (enc == null) {
            logger.info("Bitrate setting saved (encoder not initialized yet): " + (bitrate / 1_000_000) + " Mbps")
            return
        }

        // Check if bitrate actually changed
        if (enc.getBitrate() == bitrate) {
            logger.info("Bitrate already set to: " + (bitrate / 1_000_000) + " Mbps")
            return
        }

        logger.info("Bitrate change requested: " + (bitrate / 1_000_000) + " Mbps - reinitializing encoder")

        val wasSurveillance = currentMode == Mode.SURVEILLANCE
        val wasNormalRecording = currentMode == Mode.NORMAL_RECORDING
        val wasRecording = isRecording

        try {
            // Stop current recording first if active
            if (wasRecording && recorder?.isRecording() == true) {
                logger.info("Stopping recording for bitrate change")
                recorder?.stopRecording()
                // Wait for encoder to finish writing
                Thread.sleep(500)
            }

            // Reinitialize encoder with new bitrate
            reinitializeEncoder()

            // Update bitrate controller
            bitrateController?.setImmediateBitrate(bitrate)

            // Restart recording if it was active
            if (wasRecording) {
                if (wasSurveillance) {
                    logger.info("Restarting surveillance mode with new bitrate")
                    enableSurveillance()
                } else if (wasNormalRecording) {
                    logger.info("Restarting normal recording with new bitrate")
                    startRecording()
                }
            }

            logger.info("Bitrate change applied successfully: " + (bitrate / 1_000_000) + " Mbps")
        } catch (e: Exception) {
            logger.error("Failed to apply bitrate change: " + e.message, e)
            // Try to recover
            try {
                if (wasSurveillance) {
                    enableSurveillance()
                } else if (wasNormalRecording) {
                    startRecording()
                }
            } catch (e2: Exception) {
                logger.error("Failed to recover after bitrate change error", e2)
            }
        }
    }

    /**
     * Applies a recording FPS change at runtime. Persists the new fps to
     * UnifiedConfigManager (camera.targetFps), propagates it to the camera
     * (so the HAL clamps emission to that rate), and reinitializes the
     * encoder so KEY_FRAME_RATE matches.
     *
     * Range: 10-30 fps. Values outside this range are clamped — the panoramic
     * HAL on this device tops out at ~26 fps and the V2 motion pipeline is
     * tuned for 10 fps minimum (aiFrameSkip handles the higher rates).
     *
     * If recording is active, it is stopped, the encoder reinitialized, and
     * recording resumes at the new rate. If the requested fps already matches
     * the current value, no-ops.
     */
    fun applyFpsChange(fps: Int) {
        synchronized(reconfigLock) {
            applyFpsChangeLocked(fps)
        }
    }

    private fun applyFpsChangeLocked(fps: Int) {
        val clamped = Math.max(10, Math.min(30, fps))
        if (clamped != fps) {
            logger.warn("FPS $fps out of range [10..30] — clamped to $clamped")
        }

        // Persist to config first so reinitializeEncoder picks it up via loadTargetFps().
        try {
            val cameraCfg = UnifiedConfigManager.loadConfig().optJSONObject("camera") ?: JSONObject()
            cameraCfg.put("targetFps", clamped)
            UnifiedConfigManager.updateSection("camera", cameraCfg)
        } catch (e: Exception) {
            logger.warn("Failed to persist targetFps: " + e.message)
        }

        // Propagate to camera so the HAL emission rate also tracks the new target.
        camera?.setTargetFps(clamped)

        val enc = mainEncoder
        if (enc == null) {
            logger.info("FPS setting saved (encoder not initialized yet): $clamped fps")
            return
        }
        if (enc.getFps() == clamped) {
            logger.info("FPS already set to: $clamped fps")
            return
        }

        logger.info("FPS change requested: $clamped fps - reinitializing encoder")

        val wasSurveillance = currentMode == Mode.SURVEILLANCE
        val wasNormalRecording = currentMode == Mode.NORMAL_RECORDING
        val wasRecording = isRecording

        try {
            if (wasRecording && recorder?.isRecording() == true) {
                logger.info("Stopping recording for FPS change")
                recorder?.stopRecording()
                Thread.sleep(500)
            }

            // reinitializeEncoder reads loadTargetFps() internally — picks up our persist.
            reinitializeEncoder()

            if (wasRecording) {
                if (wasSurveillance) {
                    enableSurveillance()
                } else if (wasNormalRecording) {
                    startRecording()
                }
            }
            logger.info("FPS change applied successfully: $clamped fps")
        } catch (e: Exception) {
            logger.error("Failed to apply FPS change: " + e.message, e)
            try {
                if (wasSurveillance) enableSurveillance()
                else if (wasNormalRecording) startRecording()
            } catch (e2: Exception) {
                logger.error("Failed to recover after FPS change error", e2)
            }
        }
    }

    /**
     * Applies a codec change. Requires encoder restart.
     *
     * @param codec New video codec
     */
    fun applyCodecChange(codec: GpuPipelineConfig.VideoCodec) {
        synchronized(reconfigLock) {
            applyCodecChangeLocked(codec)
        }
    }

    private fun applyCodecChangeLocked(codec: GpuPipelineConfig.VideoCodec) {
        // Store the new codec setting
        config.setVideoCodec(codec)

        // If encoder doesn't exist yet, just save the setting
        val enc = mainEncoder
        if (enc == null) {
            logger.info("Codec changed to: " + codec.displayName + " - will apply when encoder initializes")
            return
        }

        // Check if codec actually changed
        val currentCodec = enc.getCodecMimeType()
        val newCodec = config.getCodecMimeType()
        if (currentCodec == newCodec) {
            logger.info("Codec already set to: " + codec.displayName)
            return
        }

        logger.info("Codec change requested: " + codec.displayName + " - reinitializing encoder")

        val wasSurveillance = currentMode == Mode.SURVEILLANCE
        val wasNormalRecording = currentMode == Mode.NORMAL_RECORDING
        val wasRecording = isRecording

        try {
            // Stop current recording first if active
            if (wasRecording && recorder?.isRecording() == true) {
                logger.info("Stopping recording for codec change")
                recorder?.stopRecording()
                // Wait for encoder to finish writing
                Thread.sleep(500)
            }

            // Reinitialize encoder with new codec
            reinitializeEncoder()

            // Restart recording if it was active
            if (wasRecording) {
                if (wasSurveillance) {
                    logger.info("Restarting surveillance mode with new codec")
                    enableSurveillance()
                } else if (wasNormalRecording) {
                    logger.info("Restarting normal recording with new codec")
                    startRecording()
                }
            }

            logger.info("Codec change applied successfully: " + codec.displayName)
        } catch (e: Exception) {
            logger.error("Failed to apply codec change: " + e.message, e)
            // Try to recover by restarting what was running
            try {
                if (wasSurveillance) {
                    enableSurveillance()
                } else if (wasNormalRecording) {
                    startRecording()
                }
            } catch (e2: Exception) {
                logger.error("Failed to recover after codec change error", e2)
            }
        }
    }

    /**
     * Returns true if the encoder is alive and its configured FPS no longer
     * matches the user's selected FPS in unified config. Caller (typically
     * RecordingModeManager at the start of an ACC ON activation) is expected
     * to follow up with a [stop] so the next [start] re-runs
     * [init] and picks up the new FPS through `loadTargetFps()`.
     *
     * Returning false is the no-action case: encoder hasn't been built yet
     * (next start() will pick up config naturally), pipeline isn't running,
     * or FPS is already current.
     */
    val isFpsConfigStale: Boolean
        get() {
            val enc = mainEncoder
            if (!running || enc == null) return false
            return enc.getFps() != loadTargetFps()
        }

    /**
     * Reinitializes the encoder with current config settings.
     * This is a synchronous operation that waits for completion.
     *
     * SOTA: Properly synchronizes with GL thread to prevent EGL_BAD_SURFACE errors.
     */
    private fun reinitializeEncoder() {
        logger.info("Reinitializing encoder...")

        // SOTA: First, release recorder's encoder surface on GL thread
        // This prevents EGL_BAD_SURFACE errors when the encoder is released
        //
        // CountDownLatch rather than the Java original's Object.wait/notify pair guarded by a
        // boolean[]: same wait-with-timeout semantics, minus the lock object Kotlin has no
        // syntax for.
        val glHandler = camera?.getGlHandler()
        val rec = recorder
        if (glHandler != null && rec != null) {
            val released = CountDownLatch(1)

            glHandler.post {
                try {
                    // Release recorder's surface (it will be recreated after new encoder is ready)
                    rec.releaseEncoderSurface()
                    logger.info("Recorder encoder surface released on GL thread")
                } catch (e: Exception) {
                    logger.warn("Error releasing recorder surface: " + e.message)
                } finally {
                    released.countDown()
                }
            }

            // Wait for GL thread to release surface (max 1 second)
            released.await(1000, TimeUnit.MILLISECONDS)
        }

        // Now safe to release old encoder
        mainEncoder?.let { old ->
            // Wait for any pending writes to complete
            if (old.isWritingToFile()) {
                logger.info("Waiting for encoder to finish writing...")
                old.flushAndClose()
                Thread.sleep(200)
            }
            old.release()
            mainEncoder = null
        }

        // Create new encoder with current config
        val codecMimeType = config.getCodecMimeType()
        val bitrate = config.getEffectiveBitrate()
        val fps = loadTargetFps()

        logger.info(
            "Creating new encoder: " +
                (if (codecMimeType.contains("hevc")) "H.265" else "H.264") +
                " @ " + fps + "fps, " + (bitrate / 1_000_000) + " Mbps"
        )

        val newEncoder = HardwareEventRecorderGpu(encoderWidth, encoderHeight, fps, bitrate, codecMimeType)
        mainEncoder = newEncoder
        // FIX (Bug A): on encoder reinit (codec/bitrate change), keep the user's
        // configured pre-record duration so the buffer doesn't reset to 5s.
        try {
            val cfgMgr = SurveillanceConfigManager()
            if (cfgMgr.configExists()) {
                val survCfg = cfgMgr.loadConfig()
                newEncoder.setPreRecordDuration(survCfg.preRecordSeconds)
            }
        } catch (e: Exception) {
            logger.warn("Failed to apply pre-record duration on reinit: " + e.message)
        }
        newEncoder.init()

        // Reinitialize recorder with new encoder on GL thread
        val cam = camera
        val camEglCore = cam?.getEglCore()
        val camGlHandler = cam?.getGlHandler()
        if (camEglCore != null && camGlHandler != null) {
            val initialized = CountDownLatch(1)
            var initError: Exception? = null

            camGlHandler.post {
                try {
                    // Recreate recorder if needed
                    var r = recorder
                    if (r == null) {
                        r = GpuMosaicRecorder()
                        recorder = r
                    }
                    r.init(camEglCore, newEncoder)
                    logger.info("Recorder reinitialized on GL thread")
                } catch (e: Exception) {
                    initError = e
                    logger.error("Failed to reinitialize recorder on GL thread", e)
                } finally {
                    initialized.countDown()
                }
            }

            // Wait for GL thread initialization (max 3 seconds)
            val completed = initialized.await(3000, TimeUnit.MILLISECONDS)

            initError?.let { throw it }

            if (!completed) {
                throw RuntimeException("Encoder reinitialization timed out")
            }
        }

        // Update bitrate controller
        if (bitrateController != null) {
            bitrateController = AdaptiveBitrateController(newEncoder, bitrate)
        }

        logger.info(
            "Encoder reinitialized successfully: " +
                (if (codecMimeType.contains("hevc")) "H.265" else "H.264") +
                " @ " + (bitrate / 1_000_000) + " Mbps"
        )
    }

    /**
     * Initializes the complete GPU pipeline.
     *
     * @throws Exception if initialization fails
     */
    @Throws(Exception::class)
    fun init() {
        init(savedAssetManager, savedContext)
    }

    /**
     * Initializes the complete GPU pipeline with AssetManager for YOLO.
     *
     * @param assetManager Android AssetManager for loading YOLO model (null = skip YOLO)
     * @throws Exception if initialization fails
     */
    @Throws(Exception::class)
    fun init(assetManager: AssetManager?) {
        init(assetManager, null)
    }

    /**
     * Initializes the complete GPU pipeline with Context for Java TFLite.
     *
     * @param assetManager Android AssetManager (unused, kept for compatibility)
     * @param context Android Context for TFLite initialization
     * @throws Exception if initialization fails
     */
    @Throws(Exception::class)
    fun init(assetManager: AssetManager?, context: Context?) {
        if (initialized) {
            logger.warn("Already initialized")
            return
        }

        // Save for re-initialization after stop/start cycle
        if (assetManager != null) this.savedAssetManager = assetManager
        if (context != null) this.savedContext = context

        logger.info("Initializing GPU surveillance pipeline...")

        // Ensure output directory exists
        if (!eventOutputDir.exists()) {
            eventOutputDir.mkdirs()
        }

        // SOTA: Release any stuck encoder resources before creating new one
        // This helps recover from previous crashes that left encoder in bad state
        mainEncoder?.let { old ->
            logger.info("Releasing previous encoder before reinit...")
            try {
                old.release()
            } catch (e: Exception) {
                logger.warn("Error releasing previous encoder: " + e.message)
            }
            mainEncoder = null
        }

        // 1. Create hardware encoder (shared by normal recording and surveillance)
        // Use config settings for bitrate, codec, and FPS. The encoder's KEY_FRAME_RATE
        // must match the camera's setCameraFps(), otherwise the encoder's PTS pacing
        // diverges from actual frame delivery and recorded video plays back at the
        // wrong speed (faster or slower than realtime).
        val codecMimeType = config.getCodecMimeType()
        val bitrate = config.getEffectiveBitrate()
        val fps = loadTargetFps()
        logger.info(
            "Creating encoder with config: " +
                (if (codecMimeType.contains("hevc")) "H.265" else "H.264") +
                " @ " + fps + "fps, " + (bitrate / 1_000_000) + " Mbps"
        )
        val newEncoder = HardwareEventRecorderGpu(encoderWidth, encoderHeight, fps, bitrate, codecMimeType)
        mainEncoder = newEncoder

        // FIX (Bug A): pre-load saved pre-record duration BEFORE encoder.init() so the
        // shared circular buffer is allocated at the right size on first init. Without
        // this the buffer is allocated with the hardcoded 5s default and only resized
        // on the next user-initiated settings save.
        var preLoadedConfig: SurveillanceConfig? = null
        try {
            val configManager = SurveillanceConfigManager()
            if (configManager.configExists()) {
                val loaded = configManager.loadConfig()
                preLoadedConfig = loaded
                newEncoder.setPreRecordDuration(loaded.preRecordSeconds)
                logger.info(
                    "Pre-applied pre-record duration from saved config: " +
                        loaded.preRecordSeconds + "s"
                )
            }
        } catch (e: Exception) {
            logger.warn("Failed to pre-load config (will retry after init): " + e.message)
        }

        newEncoder.init()

        // 2. Create GPU mosaic recorder (shared)
        val newRecorder = GpuMosaicRecorder()
        recorder = newRecorder
        // Note: recorder.init() will be called after EGL context is created by camera

        // Wire up telemetry collector to new recorder if available
        telemetryCollector?.let { newRecorder.setTelemetryCollector(it) }
        // Apply persisted overlay enabled state to new recorder
        newRecorder.setOverlayEnabled(overlayEnabledConfig)

        // 3. Create GPU downscaler
        val newDownscaler = GpuDownscaler()
        downscaler = newDownscaler
        // Note: downscaler.init() will be called after EGL context is created by camera

        // 4. Create surveillance engine (uses shared recorder)
        val newSentry = SurveillanceEngineGpu()
        sentry = newSentry
        newSentry.init(eventOutputDir, newDownscaler, assetManager, context)  // Pass Context for Java TFLite
        newSentry.setRecorder(newRecorder)  // Share recorder with normal recording

        // BladeWatch-t1lg.3: scale detection work by ACC/parked/motion/viewer state. A
        // process-wide singleton -- init() here is a no-op on a later stop/start reinit cycle
        // (PipelineRateController.init already returns the existing instance), and the
        // RateTarget lambda reads the `camera` field fresh on every call, so it keeps working
        // across a camera re-open without re-registering anything.
        PipelineRateController.init(
            PipelineRateController.RateTarget { detectionFps ->
                camera?.setDetectionRate(detectionFps)
            },
            loadTargetFps(),
            BooleanSupplier {
                val ws = webSocketServer
                ws != null && ws.hasActiveClients()
            }
        )

        // 4b. Apply saved config (use the pre-loaded one if available so we don't
        // hit disk twice).
        try {
            if (preLoadedConfig == null) {
                val configManager = SurveillanceConfigManager()
                if (configManager.configExists()) {
                    preLoadedConfig = configManager.loadConfig()
                }
            }
            val savedConfig = preLoadedConfig
            if (savedConfig != null) {
                newSentry.config = savedConfig
                logger.info("Loaded saved surveillance config")
            }
        } catch (e: Exception) {
            logger.warn("Failed to load saved config, using defaults: " + e.message)
        }

        // 5. Create camera (this creates EGL context)
        val newCamera = PanoramicCameraGpu(cameraWidth, cameraHeight)
        camera = newCamera
        newCamera.setConsumers(newRecorder, newDownscaler, newSentry)

        // Camera FPS config — must match the encoder FPS used above (loadTargetFps())
        // so that camera frame delivery rate matches the encoder's KEY_FRAME_RATE.
        newCamera.setTargetFps(fps)
        logger.info("Camera targetFps=$fps (from config)")

        // Camera config strategy:
        // 1. Saved config from previous VALIDATED probe → use directly (highest trust)
        // 2. BmmCameraInfo discovery → asks the system for the correct panoramic camera ID
        // 3. Default camera ID 1 (correct for Seal, most common model)
        // 4. Full auto-probe only when all above fail
        logger.info("Vehicle model: " + getVehicleModel())

        val currentFirmware = CameraFirmwareInfo.current()

        try {
            configureCameraSelection(currentFirmware, true, true, "init")
        } catch (e: Exception) {
            logger.warn("Failed to resolve camera selection during init: " + e.message)
        }

        // Register probe callback — only used when manual probe is triggered via API
        newCamera.setCameraProbeCallback { cameraId, surfaceMode ->
            logger.info("Probe found working camera: id=$cameraId, surfaceMode=$surfaceMode")
            try {
                camera?.let { cam ->
                    val validated = cam.getValidatedAtMs() > 0
                    cam.persistCameraConfig(validated, if (validated) null else "probe_callback_unvalidated")
                }
                logger.info("Saved camera config for next launch")
            } catch (ex: Exception) {
                logger.warn("Failed to save camera config: " + ex.message)
            }
            Thread({
                try {
                    Thread.sleep(2000)
                } catch (e: InterruptedException) {
                    logger.warn("Pending recording check sleep interrupted: " + e.message)
                    Thread.currentThread().interrupt()
                }
                checkPendingRecording()
            }, "PendingRecCheck").start()
        }

        // Always 4-camera mosaic — both devices output the same strip format
        newRecorder.setCameraLayout(newCamera.getCameraLayout())

        // 6. Create adaptive bitrate controller
        bitrateController = AdaptiveBitrateController(newEncoder, 6_000_000)

        initialized = true
        logger.info("GPU surveillance pipeline initialized")
    }

    /**
     * Starts the GPU pipeline.
     *
     * @param autoStartRecording If true, automatically starts recording when recorder is ready
     * @throws Exception if start fails
     */
    @JvmOverloads
    @Throws(Exception::class)
    fun start(autoStartRecording: Boolean = false) {
        // CRITICAL: Set running flag FIRST to prevent race conditions
        // Multiple threads may call start() concurrently (HTTP + WebSocket)
        synchronized(this) {
            if (running) {
                logger.warn("Already running")
                return
            }
            running = true  // Set immediately to block concurrent starts
        }

        try {
            // Reinitialize if stopped (encoder/recorder were released)
            if (!initialized) {
                init()
            }

            logger.info("Starting GPU pipeline (autoRecord=$autoStartRecording)...")

            val cam = camera ?: throw IllegalStateException("Camera not initialized")

            // Re-read camera config before starting — user may have changed camera ID
            // via the app UI menu since the pipeline was initialized.
            try {
                val cameraConfig = UnifiedConfigManager.loadConfig().optJSONObject("camera")
                if (cameraConfig != null) {
                    val savedId = cameraConfig.optInt("probedCameraId", -1)
                    val savedMode = cameraConfig.optInt("probedSurfaceMode", -1)
                    val validated = cameraConfig.optBoolean("probedAndValidated", false)
                    val manual = cameraConfig.optBoolean("manualOverride", false)
                    val reprobeRequested = cameraConfig.optBoolean("reprobeOnNextRestart", false)

                    if (!reprobeRequested && savedId >= 0 && savedMode >= 0 && (validated || manual)) {
                        val currentId = cam.getCameraId()
                        if (currentId != savedId) {
                            logger.info(
                                "Camera config changed since init: " + currentId + " → " + savedId +
                                    " (" + (if (manual) "manual" else "validated") + ")"
                            )
                            cam.setCameraId(savedId)
                            cam.setCameraSurfaceMode(savedMode)
                            cam.setAutoProbeCameras(false)
                            cam.setSkipFrameValidation(true)
                        }
                    } else if (savedId < 0 && cam.getCameraId() != 1) {
                        // User cleared manual override → revert to default
                        logger.info("Camera config cleared — reverting to default ID 1")
                        cam.setCameraId(1)
                        cam.setCameraSurfaceMode(0)
                        cam.setAutoProbeCameras(false)
                        cam.setSkipFrameValidation(false)
                    }
                }
            } catch (e: Exception) {
                logger.debug("Camera config re-read failed: " + e.message)
            }

            // Start camera (this creates EGL context and initializes downscaler)
            cam.start()

            // SOTA: Register yield listener for recording finalization during camera yield.
            // When contention is detected and the camera must yield to the native AVM app,
            // this ensures any active recording is properly finalized (moov atom written)
            // before the camera closes, and recording resumes after re-acquisition.
            cam.setCameraYieldListener(object : PanoramicCameraGpu.CameraYieldListener {
                override fun onPreYield() {
                    logger.info("Pre-yield: finalizing active recording...")

                    // Stop any active recording to finalize the MP4 file
                    if (recorder?.isRecording() == true) {
                        recorder?.stopRecording()
                        logger.info("Pre-yield: recording stopped")
                    }

                    // Flush encoder to ensure all buffered frames are written
                    if (mainEncoder?.isWritingToFile() == true) {
                        mainEncoder?.flushAndClose()
                        logger.info("Pre-yield: encoder flushed")
                    }
                }

                override fun onPostReacquire() {
                    logger.info("Post-reacquire: resuming recording and streaming...")

                    // Restore streaming components if streaming was enabled.
                    // yieldCameraInternal and restartCameraAfterError call clearStreamingComponents()
                    // which nulls the camera's local refs. The pipeline still holds the actual objects.
                    val scaler = streamScaler
                    val streamEnc = streamEncoder
                    if (streamingEnabled && scaler != null && streamEnc != null) {
                        camera?.setStreamingComponents(scaler, streamEnc)
                        logger.info("Post-reacquire: streaming components restored")
                    }

                    // Resume recording in whatever mode was active before yield
                    if (currentMode == Mode.SURVEILLANCE) {
                        // Sentry mode — re-enable surveillance (it will start recording on motion)
                        sentry?.let { s ->
                            if (!s.isActive) s.enable()
                        }
                        logger.info("Post-reacquire: surveillance mode restored")
                    } else if (currentMode == Mode.NORMAL_RECORDING || recordingMode) {
                        // Normal recording mode — restart recording
                        recorder?.let { r ->
                            if (!r.isRecording()) {
                                r.startRecording()
                                logger.info("Post-reacquire: normal recording resumed")
                            }
                        }
                    }
                }
            })

            // Wait for camera to fully initialize and GL context to be ready
            // Increased timeout to ensure recorder can be initialized
            Thread.sleep(1500)  // Increased from 1000ms to 1500ms

            // Set callback to start recording when recorder is ready
            if (autoStartRecording) {
                recordingMode = true
                cam.setRecorderInitCallback {
                    logger.info("Recorder ready - starting recording automatically")
                    recorder?.startRecording()
                    currentMode = Mode.NORMAL_RECORDING

                    // Enable overlay for auto-started recording
                    recorder?.setOverlayRecordingModeAllowed(true)
                    telemetryCollector?.let { tc ->
                        tc.setOverlayRecordingActive(true)
                        tc.startPolling()
                    }
                }
            } else {
                recordingMode = false
            }

            // Initialize recorder on GL thread (CRITICAL: must be on GL thread!)
            if (cam.getEglCore() != null) {
                cam.initRecorderOnGlThread(recorder, mainEncoder)
                logger.info("Recorder initialization scheduled on GL thread")

                // Wait for recorder to initialize before continuing
                Thread.sleep(500)
            }

            // DON'T auto-enable streaming - enable on-demand when client requests
            // Streaming will be enabled via enableStreaming() when HTTP client connects
            // enableStreaming() already auto-starts the pipeline if not running.

            // DON'T auto-enable surveillance - let caller decide
            // Surveillance should only be enabled when explicitly requested

            logger.info("GPU pipeline started (streaming on-demand, surveillance NOT auto-enabled)")
        } catch (e: Exception) {
            // Reset running flag on failure so retry is possible
            synchronized(this) {
                running = false
            }
            throw e
        }
    }

    /**
     * Stops the GPU pipeline.
     */
    fun stop() {
        if (!running) {
            return
        }

        logger.info("Stopping GPU pipeline...")
        running = false

        // Clear any pending deferred recording
        pendingRecordingDir = null
        pendingRecordingPrefix = null

        // Reset mode so status API reflects that we're not in any active mode
        currentMode = Mode.IDLE

        // Stop recording first to finalize file
        if (recorder?.isRecording() == true) {
            recorder?.stopRecording()
        }

        // Disable streaming — stream encoder/scaler hold EGL surfaces that will be
        // destroyed when the camera stops. They must be released before camera.stop().
        if (streamingEnabled) {
            disableStreaming()
        }

        // Disable surveillance
        sentry?.disable()

        // Stop camera (this releases EGL context and surfaces)
        camera?.stop()

        // CRITICAL: Release recorder and encoder since EGL context is gone
        // They must be recreated on next start()
        recorder?.let {
            it.release()
            recorder = null
        }

        mainEncoder?.let {
            it.release()
            mainEncoder = null
        }

        // Mark as not initialized so init() can be called again
        initialized = false

        logger.info("GPU pipeline stopped")
    }

    /**
     * Releases all resources.
     */
    fun release() {
        stop()

        bitrateController?.let {
            it.release()
            bitrateController = null
        }

        recorder?.let {
            it.release()
            recorder = null
        }

        downscaler?.let {
            it.release()
            downscaler = null
        }

        sentry?.let {
            it.release()
            sentry = null
        }

        mainEncoder?.let {
            it.release()
            mainEncoder = null
        }

        initialized = false
        logger.info("GPU pipeline released")
    }

    /**
     * Starts recording, optionally with a custom output directory and filename prefix.
     * Stops surveillance if active (mutually exclusive).
     *
     * @param outputDir Custom output directory (null for default recordings dir)
     * @param prefix Filename prefix (e.g., "cam", "proximity", "event")
     */
    @JvmOverloads
    fun startRecording(outputDir: File? = null, prefix: String = "cam") {
        // Stop surveillance if active (mutually exclusive)
        if (currentMode == Mode.SURVEILLANCE) {
            logger.info("Stopping surveillance to start normal recording (mutually exclusive)")
            sentry?.disable()
        }

        // SOTA: Ensure storage is ready (mount SD card if needed) for recordings
        if (outputDir == null) {  // Only check for default recordings dir
            try {
                val storage = StorageManager.getInstance()
                if (!storage.ensureStorageReady(false)) {
                    logger.warn("Storage not ready for recording, but continuing with fallback")
                }
            } catch (e: Exception) {
                logger.warn("Error checking storage readiness: " + e.message)
            }
        }

        val rec = recorder ?: return

        // Check if encoder is ready (has received at least one frame from camera).
        val enc = rec.getEncoder()
        if (enc != null && enc.isFormatAvailable()) {
            rec.startRecording(outputDir, prefix)
            currentMode = Mode.NORMAL_RECORDING
            rec.setOverlayRecordingModeAllowed(true)
            telemetryCollector?.let { tc ->
                tc.setOverlayRecordingActive(true)
                tc.startPolling()
            }
            logger.info(
                "Normal recording started (dir=" + (outputDir?.name ?: "default") +
                    ", prefix=" + prefix + ")"
            )
        } else {
            // Encoder not ready yet (camera still warming up). Store the
            // request and register a one-shot listener that fires the
            // moment the encoder publishes its output format. Without
            // this, cold-start CONTINUOUS recording never began until
            // the next ACC OFF/ON cycle, because checkPendingRecording()
            // was previously only called from the camera-probe callback —
            // which is skipped when a validated camera config exists.
            logger.info("Encoder not ready yet — recording will start when camera is ready")
            pendingRecordingDir = outputDir
            pendingRecordingPrefix = prefix
            recordingMode = true
            enc?.setFormatAvailableListener {
                // Posted off the encoder thread so we don't block dequeue.
                Thread({
                    try {
                        checkPendingRecording()
                    } catch (e: Exception) {
                        logger.warn("Deferred recording start failed: " + e.message)
                    }
                }, "PendingRecKickoff").start()
            }
        }
    }

    /**
     * Called when the encoder format becomes available (probe complete, first frame encoded).
     * Starts any pending recording that was deferred because the encoder wasn't ready.
     */
    private fun checkPendingRecording() {
        if (pendingRecordingPrefix == null) return
        val rec = recorder ?: return
        val enc = rec.getEncoder() ?: return
        if (!enc.isFormatAvailable()) return

        val dir = pendingRecordingDir
        val prefix = pendingRecordingPrefix
        pendingRecordingDir = null
        pendingRecordingPrefix = null

        logger.info("Encoder now ready — starting deferred recording")
        rec.startRecording(dir, prefix ?: "cam")
        currentMode = Mode.NORMAL_RECORDING
        rec.setOverlayRecordingModeAllowed(true)
        telemetryCollector?.let { tc ->
            tc.setOverlayRecordingActive(true)
            tc.startPolling()
        }
        logger.info(
            "Deferred normal recording started (dir=" + (dir?.name ?: "default") +
                ", prefix=" + prefix + ")"
        )
    }

    /**
     * Stops recording.
     */
    fun stopRecording() {
        // CRITICAL: Clear any pending (deferred) recording request FIRST.
        // During cold start, startRecording() defers to checkPendingRecording() if the
        // encoder isn't ready yet. If a gear change (D→N/P) triggers stopRecording()
        // before the encoder is ready, the pending request survives and fires later —
        // starting recording in the wrong gear state. Clearing it here prevents that.
        pendingRecordingDir = null
        pendingRecordingPrefix = null
        recordingMode = false

        recorder?.let { rec ->
            rec.stopRecording()

            // Disable overlay compositing when recording stops
            rec.setOverlayRecordingModeAllowed(false)
            telemetryCollector?.let { tc ->
                tc.setOverlayRecordingActive(false)
                tc.stopPolling()
            }

            currentMode = Mode.IDLE
            logger.info("Normal recording stopped")
        }
    }

    /**
     * Enables surveillance mode (motion detection + event recording).
     * Stops normal recording if active (mutually exclusive).
     * SOTA: Ensures SD card is mounted if SD card storage is selected.
     */
    fun enableSurveillance() {
        // Stop normal recording if active (mutually exclusive)
        if (currentMode == Mode.NORMAL_RECORDING) {
            logger.info("Stopping normal recording to enable surveillance (mutually exclusive)")
            recorder?.stopRecording()
        }

        // SOTA: Ensure storage is ready (mount SD card if needed)
        try {
            val storage = StorageManager.getInstance()
            if (!storage.ensureStorageReady(true)) {
                logger.warn("Storage not ready for surveillance, but continuing with fallback")
            }

            // SOTA: Update sentry's event output directory to current surveillance path
            // This handles storage type changes (internal <-> SD card) at runtime
            sentry?.let { s ->
                val currentSurveillanceDir = storage.surveillanceDir
                s.setEventOutputDir(currentSurveillanceDir)
                logger.info("Surveillance output directory: " + currentSurveillanceDir.absolutePath)
            }
        } catch (e: Exception) {
            logger.warn("Error checking storage readiness: " + e.message)
        }

        val s = sentry
        if (s != null) {
            s.enable()
            currentMode = Mode.SURVEILLANCE
            logger.info("Surveillance mode enabled (sentry.active=" + s.isActive + ")")
        } else {
            logger.error("Cannot enable surveillance: sentry is null!")
        }

        // Disable overlay compositing in surveillance mode
        recorder?.setOverlayRecordingModeAllowed(false)
        telemetryCollector?.let { tc ->
            tc.setOverlayRecordingActive(false)
            tc.stopPolling()
        }
    }

    /**
     * Disables surveillance mode.
     */
    fun disableSurveillance() {
        sentry?.let {
            it.disable()
            currentMode = Mode.IDLE
            logger.info("Surveillance mode disabled")
        }
    }

    /**
     * Called when ACC turns ON - stops surveillance recording.
     * This ensures sentry recordings are properly finalized when car starts.
     *
     * CRITICAL: Must synchronously close any active recording to prevent file corruption.
     */
    fun onAccOn() {
        logger.info("ACC ON detected - stopping surveillance and finalizing recordings")

        // First, stop any active recording immediately (synchronous)
        if (recorder?.isRecording() == true) {
            logger.info("Stopping active recording before ACC transition")
            recorder?.stopRecording()
        }

        // Also flush and close the encoder to ensure file is finalized
        if (mainEncoder?.isWritingToFile() == true) {
            logger.info("Flushing encoder before ACC transition")
            mainEncoder?.flushAndClose()
        }

        // Now disable surveillance mode
        if (currentMode == Mode.SURVEILLANCE) {
            disableSurveillance()
        }

        // Also stop normal recording if active
        if (currentMode == Mode.NORMAL_RECORDING) {
            stopRecording()
        }

        // CRITICAL: Reopen camera to let BYD native app get video frames.
        // During ACC OFF the daemon holds the camera exclusively for surveillance.
        // The native camera app starts on ACC ON but can't get frames because we
        // already have the primary slot. Briefly releasing and reopening the camera
        // lets the native app grab it first, then we get added as secondary consumer.
        if (running) {
            camera?.reopenCamera()
        }

        logger.info("ACC ON transition complete - all recordings finalized, camera reopened")
    }

    /**
     * Enables H.264 streaming with separate encoder.
     *
     * @param streamWidth Stream width (e.g., 1280)
     * @param streamHeight Stream height (e.g., 960)
     * @param streamFps Stream FPS (e.g., 10)
     * @param streamBitrate Stream bitrate (e.g., 2 Mbps)
     */
    @Throws(Exception::class)
    fun enableStreaming(streamWidth: Int, streamHeight: Int, streamFps: Int, streamBitrate: Int) {
        if (streamingEnabled) {
            logger.warn("Streaming already enabled")
            return
        }

        // Auto-start pipeline if not running (e.g., DRIVE_MODE in gear P, user opens stream)
        if (!running) {
            logger.info("Pipeline not running — auto-starting for streaming (view-only)")
            start(false)  // Start without auto-recording
        }

        // Verify camera GL thread is ready after start
        val cam = camera
        val glHandler = cam?.getGlHandler()
        if (cam == null || glHandler == null) {
            logger.error("Cannot enable streaming - camera GL thread not ready")
            throw IllegalStateException("Camera GL thread not initialized")
        }

        logger.info(
            String.format(
                "Enabling H.264 streaming: %dx%d @ %dfps, %d Mbps",
                streamWidth, streamHeight, streamFps, streamBitrate / 1_000_000
            )
        )

        // Create stream encoder
        logger.info("Creating stream encoder...")
        val newStreamEncoder = HardwareEventRecorderGpu(streamWidth, streamHeight, streamFps, streamBitrate)
        streamEncoder = newStreamEncoder
        newStreamEncoder.setUsePreRecordBuffer(false)  // Stream-only, no pre-record needed
        newStreamEncoder.init()
        logger.info("Stream encoder initialized")

        // Create stream scaler
        logger.info("Creating stream scaler...")
        val newStreamScaler = GpuStreamScaler(streamWidth, streamHeight)
        streamScaler = newStreamScaler

        // Always 4-camera mosaic for streaming
        newStreamScaler.setCameraLayout(cam.getCameraLayout())

        // Initialize on GL thread and WAIT for completion
        // This ensures the scaler is ready before we set streaming components
        val scalerReady = CountDownLatch(1)
        var initError: Exception? = null

        glHandler.post {
            try {
                newStreamScaler.init(cam.getEglCore()!!, newStreamEncoder)
                logger.info("Stream scaler initialized on GL thread")
            } catch (e: Exception) {
                logger.error("Failed to initialize stream scaler on GL thread", e)
                initError = e
            } finally {
                scalerReady.countDown()
            }
        }

        // Wait for GL thread initialization (max 2 seconds)
        if (!scalerReady.await(2000, TimeUnit.MILLISECONDS)) {
            throw RuntimeException("Stream scaler initialization timed out")
        }

        initError?.let {
            throw RuntimeException("Stream scaler initialization failed: " + it.message, it)
        }

        // Now set components on camera (scaler is guaranteed initialized)
        logger.info("Setting streaming components on camera...")
        cam.setStreamingComponents(newStreamScaler, newStreamEncoder)

        // Create WebSocket stream server (port 8887)
        // WebSocket has zero buffering delay vs HTTP Chunked (64KB+ buffer)
        logger.info("Starting WebSocket stream server...")
        val server = WebSocketStreamServer()
        webSocketServer = server

        // Set idle shutdown callback - auto-stop pipeline when no clients for 15 seconds
        server.setIdleShutdownCallback {
            logger.info("WebSocket idle timeout - stopping streaming and pipeline")
            // Run on separate thread to avoid blocking timer thread
            Thread({
                try {
                    disableStreaming()
                    // Keep the pipeline alive if surveillance is active OR a
                    // dashcam/drive recording is in progress. Previously this
                    // only checked surveillance, so closing the live view
                    // while driving (ACC ON, CONTINUOUS/DRIVE_MODE) stopped
                    // the whole pipeline and silently killed the dashcam
                    // recording — the drive went unrecorded. Only stop to save
                    // resources when nothing is actually recording.
                    val dashcamRecording = isRecording || isNormalRecordingMode
                    if (currentMode != Mode.SURVEILLANCE && !dashcamRecording && running) {
                        logger.info("Surveillance not active - stopping pipeline to save resources")
                        stop()
                    } else if (currentMode != Mode.SURVEILLANCE && dashcamRecording) {
                        logger.info("Live stream idle but dashcam recording active — keeping pipeline running")
                    }
                } catch (e: Exception) {
                    logger.error("Error during idle shutdown", e)
                }
            }, "IdleShutdown").start()
        }

        server.start()
        logger.info("WebSocket server started, setting stream callback...")
        newStreamEncoder.setStreamCallback(server)

        streamingEnabled = true
        logger.info("H.264 streaming enabled (WebSocket port 8887)")

        // BladeWatch-y78o.1: start the still-frame refresher alongside the real stream so a
        // browser with no decoder has something to fall back to for as long as live view is
        // open. Bitmap.compress needs android.graphics, so the encoder is a lambda here rather
        // than living in StillFrameRefresher.kt, which stays free of android.* imports.
        val refresher = StillFrameRefresher(
            { sentry?.latestMosaicFrame },
            // Fixed 640x480 — NOT streamScaler's configurable width/height. This is
            // SurveillanceEngineGpu.getLatestMosaicFrame()'s own dimension, unrelated to the
            // live H.264 stream's resolution (see that method's doc comment). Same literal
            // SurveillanceApiHandler#sendQuadrantSnapshot already hardcodes for the same
            // buffer.
            640, 480,
            JpegEncoder { rgb, width, height -> encodeMosaicJpeg(rgb, width, height) },
            STILL_FRAME_REFRESH_INTERVAL_MS,
            Executors.newSingleThreadScheduledExecutor()
        )
        stillFrameRefresher = refresher
        refresher.start()
    }

    /**
     * Disables H.264 streaming and releases stream encoder.
     */
    fun disableStreaming() {
        if (!streamingEnabled) {
            return
        }

        logger.info("Disabling H.264 streaming...")
        streamingEnabled = false

        // BladeWatch-y78o.1: stop the still-frame refresher's timer and drop the retained
        // frame -- serving a frame from a stopped session would be honestly stale, not just
        // a few seconds old.
        stillFrameRefresher?.let {
            it.stop()
            stillFrameRefresher = null
        }

        // CRITICAL: Clear streaming components from camera FIRST
        // This prevents render loop from using released surfaces
        camera?.clearStreamingComponents()

        // Clear stream callback
        streamEncoder?.clearStreamCallback()

        // Stop WebSocket server
        webSocketServer?.let {
            it.shutdown()
            webSocketServer = null
        }

        // Release stream encoder
        streamEncoder?.let {
            it.release()
            streamEncoder = null
        }

        // Release stream scaler
        streamScaler?.let {
            it.release()
            streamScaler = null
        }

        logger.info("H.264 streaming disabled")
    }

    /** Whether streaming is enabled. */
    val isStreamingEnabled: Boolean
        get() = streamingEnabled

    /**
     * BladeWatch-y78o.1: the most recently retained still-frame JPEG, or null if streaming
     * isn't enabled or no frame has been produced yet.
     */
    val latestStillFrame: ByteArray?
        get() = stillFrameRefresher?.current()

    /**
     * The stream view mode (which camera to show): 0=Mosaic (2x2 grid), 1=Front, 2=Right,
     * 3=Rear, 4=Left. Reads -1 when streaming is not enabled.
     */
    var streamViewMode: Int
        get() = streamScaler?.getViewMode() ?: -1
        set(mode) {
            val scaler = streamScaler
            if (scaler != null) {
                scaler.setViewMode(mode)
                logger.info("Stream view mode changed to $mode")
            } else {
                logger.warn("Cannot set stream view mode - streaming not enabled")
            }
        }

    /** Whether recording is currently in progress. */
    val isRecording: Boolean
        get() = recorder?.isRecording() == true

    /** Whether the pipeline is in recording mode (vs viewing mode). */
    val isRecordingMode: Boolean
        get() = recordingMode

    /** Whether the pipeline has been initialized. */
    val isInitialized: Boolean
        get() = initialized

    /** Whether the pipeline is running. */
    val isRunning: Boolean
        get() = running

    /** Whether surveillance mode is active. */
    val isSurveillanceMode: Boolean
        get() = currentMode == Mode.SURVEILLANCE

    /** Whether normal recording mode is active. */
    val isNormalRecordingMode: Boolean
        get() = currentMode == Mode.NORMAL_RECORDING

    /**
     * Sets the telemetry collector instance for overlay data.
     */
    fun setTelemetryCollector(collector: TelemetryDataCollector?) {
        this.telemetryCollector = collector
        recorder?.setTelemetryCollector(collector)
    }

    /**
     * Enables or disables the telemetry overlay.
     * Starts/stops the telemetry collector based on current recording mode.
     */
    fun setOverlayEnabled(enabled: Boolean) {
        this.overlayEnabledConfig = enabled
        recorder?.setOverlayEnabled(enabled)
        // Start/stop telemetry collector based on overlay state
        val tc = telemetryCollector
        if (enabled && currentMode == Mode.NORMAL_RECORDING && tc != null) {
            tc.setOverlayRecordingActive(true)
            tc.startPolling()
        } else if (!enabled && tc != null) {
            tc.setOverlayRecordingActive(false)
            tc.stopPolling()
        }
    }

    companion object {
        private const val TAG = "GpuPipeline"
        private val logger = DaemonLogger.getInstance(TAG)

        private const val STILL_FRAME_REFRESH_INTERVAL_MS = 5000L

        private fun loadCameraConfigSection(): JSONObject? {
            return try {
                UnifiedConfigManager.loadConfig().optJSONObject("camera")
            } catch (e: Exception) {
                logger.warn("Unable to load camera config: " + e.message)
                null
            }
        }

        /**
         * Reads the user-selected camera FPS from unified config.
         * Falls back to 15 if missing or unreadable. Restricted to BYD-supported
         * values {8, 15, 25} via the UI; other values are clamped to 15 by the
         * settings API before being persisted.
         */
        private fun loadTargetFps(): Int {
            try {
                val cameraConfig = UnifiedConfigManager.loadConfig().optJSONObject("camera")
                if (cameraConfig != null) {
                    return cameraConfig.optInt("targetFps", 15)
                }
            } catch (ignored: Exception) {
                logger.warn("Failed to read targetFps from config — defaulting to 15fps: " + ignored.message)
            }
            return 15
        }

        private fun getVehicleModel(): String {
            return try {
                Class.forName("android.os.SystemProperties")
                    .getMethod("get", String::class.java, String::class.java)
                    .invoke(null, "ro.product.model", "unknown") as String
            } catch (e: Exception) {
                logger.warn("Failed to read vehicle model via SystemProperties: " + e.message)
                "unknown"
            }
        }

        /**
         * Encodes a 3-byte-per-pixel RGB buffer as a JPEG. The [JpegEncoder]
         * implementation used by the still-frame refresher — kept as a plain static method (not
         * a lambda capturing pipeline state) so it has no dependency on pipeline internals,
         * matching SurveillanceApiHandler#sendQuadrantFromMosaic's existing RGB→ARGB→JPEG
         * conversion.
         */
        private fun encodeMosaicJpeg(rgb: ByteArray, width: Int, height: Int): ByteArray {
            val pixels = IntArray(width * height)
            var i = 0
            var p = 0
            while (p < pixels.size && i + 2 < rgb.size) {
                val r = rgb[i].toInt() and 0xFF
                val g = rgb[i + 1].toInt() and 0xFF
                val b = rgb[i + 2].toInt() and 0xFF
                pixels[p] = (0xFF000000.toInt()) or (r shl 16) or (g shl 8) or b
                i += 3
                p++
            }
            val bitmap = Bitmap.createBitmap(pixels, width, height, Bitmap.Config.ARGB_8888)
            try {
                val jpegOut = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.JPEG, 80, jpegOut)
                return jpegOut.toByteArray()
            } finally {
                bitmap.recycle()
            }
        }
    }
}
