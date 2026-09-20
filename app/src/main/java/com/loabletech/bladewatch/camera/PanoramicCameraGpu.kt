package net.bladewatch.app.camera

import android.graphics.ImageFormat
import android.hardware.HardwareBuffer
import android.media.Image
import android.media.ImageReader
import android.opengl.EGLSurface
import android.os.Handler
import android.os.HandlerThread
import android.view.Surface

import net.bladewatch.app.camera.bindHardwareBufferToTextureNative
import net.bladewatch.app.camera.probeExtensionsNative
import net.bladewatch.app.config.UnifiedConfigManager
import net.bladewatch.app.logging.DaemonLogConfig
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.streaming.GpuStreamScaler
import net.bladewatch.app.surveillance.FoveatedCropper
import net.bladewatch.app.surveillance.GpuDownscaler
import net.bladewatch.app.surveillance.GpuMosaicRecorder
import net.bladewatch.app.surveillance.HardwareEventRecorderGpu
import net.bladewatch.app.surveillance.SurveillanceEngineGpu
import net.bladewatch.app.surveillance.isLibraryLoaded

import org.json.JSONObject

import java.lang.reflect.Constructor
import java.lang.reflect.Method
import java.util.Arrays
import java.util.LinkedHashSet
import java.util.concurrent.atomic.AtomicBoolean

/**
 * PanoramicCameraGpu - GPU Edition with Zero-Copy Pipeline.
 *
 * This is the GPU-native version of PanoramicCamera that uses an
 * ImageReader-backed HardwareBuffer path. Camera frames flow directly to a
 * GPU external OES texture, enabling:
 * - Zero-copy recording (camera → GPU → encoder)
 * - Minimal AI readback (GPU downscales to 320x240)
 * - <10% total CPU usage
 *
 * Architecture:
 * - Camera writes to GL_TEXTURE_EXTERNAL_OES via ImageReader + HardwareBuffer
 * - Render loop on dedicated GL thread distributes frames to:
 *   - Recording Lane: GpuMosaicRecorder (zero-copy to encoder)
 *   - AI Lane: GpuDownscaler (2 FPS readback for motion detection)
 *
 * @param width Camera width (typically 5120)
 * @param height Camera height (typically 960)
 */
class PanoramicCameraGpu(val width: Int, val height: Int) {

    // AVMCamera surface mode — 0 works on Seal, Atto 1 may need different value
    // Set via setCameraSurfaceMode() before start() for per-model override
    private var cameraSurfaceMode = 0

    // Camera ID override — set via setCameraId() before start()
    private var cameraIdOverride = -1  // -1 = use default PHYSICAL_CAMERA_ID
    @Volatile private var manualOverrideActive = false
    @Volatile private var fallbackFromProbe = false

    // SOTA: Full-matrix auto-probe — sweeps camera IDs 0-5 × surface modes 0-5
    // to find the first combination that produces panoramic image data.
    private var autoProbeCameras = false
    // When true, skip frame-15/50 validation entirely (user manually set camera ID)
    private var skipFrameValidation = false
    private var probeStartId = -1  // Tracks where probe started for wrap-around detection
    private var probeNextCameraId = 0    // Next camera ID to try
    private var probeNextSurfaceMode = 0 // Next surface mode to try
    private var probeSurfaceModeMatrixActive = false
    private var probeMatrixCameraIds = IntArray(0)
    private var probeMatrixCameraIndex = 0

    // SOTA: Probe gate — blocks recording/streaming/AI until probe finds a working camera.
    // Without this, the encoder records BLACK frames and the stream shows garbage during probe.
    // Defaults to true (no gate) — only set to false when setAutoProbeCameras(true) is called.
    @Volatile private var probeComplete = true

    // Track the last camera ID that delivered non-black data during probe.
    // If the probe exhausts all IDs without finding a verified strip, fall back
    // to this camera — it's better to record from a real camera than nothing.
    private var lastDataCameraId = -1
    @Volatile private var cameraLayout = 0
    @Volatile private var sourceBmmTag = ""
    @Volatile private var discoveryMethod = ""
    @Volatile private var vehicleCamSort = ""
    @Volatile private var firmwareInfo: CameraFirmwareInfo = CameraFirmwareInfo.current()
    @Volatile private var nativeProbeReport = ""
    @Volatile private var nativeProbeReady = false
    @Volatile private var fpsSetCameraResult = "unknown"
    @Volatile private var fpsSetMediaCodecResult = "not_wired"
    @Volatile private var validatedAtMs = 0L
    @Volatile private var validatedFrameWidth = 0
    @Volatile private var validatedFrameHeight = 0
    @Volatile private var validationFrameCount = 0
    @Volatile private var validationSignal = ""
    @Volatile private var stripConfidence = ""
    @Volatile private var layoutConfidence = ""
    @Volatile private var quadrantVariance = ""
    @Volatile private var lastValidationFailure = ""
    @Volatile private var lastCameraEvent = ""
    @Volatile private var arbitrationMode = "eventCallbackOnly"

    // Callback when auto-probe discovers a working camera config
    fun interface CameraProbeCallback {
        fun onCameraFound(cameraId: Int, surfaceMode: Int)
    }
    private var probeCallback: CameraProbeCallback? = null

    // EGL and OpenGL
    private var eglCore: EGLCore? = null
    private var dummySurface: EGLSurface? = null  // Pbuffer for headless context
    private var cameraTextureId = 0
    // Camera consumer: ImageReader → AHardwareBuffer → EGLImage →
    // cameraTextureId. Bypasses SurfaceFlinger throttling that clamps the
    // Legacy SurfaceTexture consumer path drops to ~8.5 fps on DiLink50 5.0UI builds (verified by
    // AvmImageReaderFpsProbe → 26 fps panoramic). cameraSurface is what we
    // hand to AVMCamera.addPreviewSurface — sourced from ImageReader.getSurface().
    // minSdk=28 enforces Image.getHardwareBuffer availability.
    private var cameraImageReader: ImageReader? = null
    private var cameraSurface: Surface? = null
    // Dedicated handler for ImageReader.OnImageAvailableListener. MUST be
    // separate from glHandler — renderLoop blocks the GL thread on
    // frameSync.wait(), which would starve the listener if it ran on the
    // same looper. The callback hops to glHandler.post for the actual GL
    // bind work via onHalImageAvailable.
    private var imageReaderThread: HandlerThread? = null
    private var imageReaderHandler: Handler? = null

    // Camera object (via reflection).
    // volatile because reopenCamera() runs on the daemon thread and writes
    // cameraObj while the GL render thread reads it in renderLoop(). Without
    // volatile, the GL thread could observe a stale non-null cameraObj after
    // we've torn down the BYD HAL and block in updateTexImage() against a
    // dead BufferQueue (which is what was tripping the GL watchdog on
    // ACC OFF→ON transitions).
    @Volatile private var cameraObj: Any? = null

    // Render loop
    private var glThread: HandlerThread? = null
    private var glHandler: Handler? = null
    @Volatile private var running = false
    private val frameSync = Object()
    // State-backed signal between the HAL callback (onHalImageAvailable) and
    // the GL render loop. Plain notify()/wait() races: if the HAL fires while
    // the GL thread is mid-processing (not yet in wait()), the notification
    // is dropped and the GL thread blocks for up to 100 ms before the NEXT
    // HAL fire wakes it — capping effective FPS well below the HAL emission
    // rate. The pending flag closes the race: HAL sets it, GL skips wait()
    // when it's already set, and clears it before processing.
    @Volatile private var imagePending = false

    // Consumers
    private var recorder: GpuMosaicRecorder? = null
    private var encoder: HardwareEventRecorderGpu? = null  // Direct encoder reference for draining
    private var streamScaler: GpuStreamScaler? = null  // Stream scaler (optional)
    private var streamEncoder: HardwareEventRecorderGpu? = null  // Stream encoder (optional)
    private var downscaler: GpuDownscaler? = null
    private var sentry: SurveillanceEngineGpu? = null
    private var foveatedCropper: FoveatedCropper? = null  // High-res AI crop from raw strip

    // Frame timing
    private var frameCounter = 0
    // AI lane is fully decoupled from the GL thread (AiLaneWorker). GL thread
    // produces downscaled frames at camera rate; worker consumes at its own
    // pace and drops frames when busy. V2 motion's internal 100ms throttle
    // (MOTION_PROCESS_INTERVAL_MS) keeps actual processing at ~10 fps so
    // there's no need for a separate frame-skip counter on the GL side.
    private var aiLaneWorker: AiLaneWorker? = null
    // Last measured camera FPS, computed in the 2-min Stats log. Surfaced
    // as a property so the UI can show actualFps when it falls below
    // requested (HAL clamp; e.g. user requests 30, HAL emits ~26).
    @Volatile var measuredFps: Float = 0f
        private set
    private var lastFrameTime: Long = 0
    @Volatile private var lastCameraStartTime: Long = 0
    private var startTime: Long = 0

    // Watchdog for GL thread hang detection
    @Volatile private var lastGlThreadHeartbeat: Long = 0
    private var watchdogThread: Thread? = null

    // SOTA: BYD camera coordinator for cooperative sharing and error recovery
    private var cameraCoordinator: BydCameraCoordinator? = null
    @Volatile private var cameraYielded = false

    // Auto-probe normally advances at frame 15. If a camera/mode opens but
    // produces no frames at all, frameCounter never reaches 15, so use this
    // wall-clock guard to move to the next candidate instead of staying in
    // probeComplete=false forever.
    @Volatile private var consecutiveContentionStalls = 0

    // Flag to indicate camera restart is in progress — watchdog uses extended timeout.
    // P1 #11: AtomicBoolean so concurrent restartCameraAfterError + reopenCamera
    // calls can't both enter the restart path. Loser observes
    // compareAndSet(false,true)==false and returns; only the winner runs the
    // close/open sequence and is responsible for clearing the flag.
    private val restartInProgress = AtomicBoolean(false)

    // SOTA: Pre-yield listener — pipeline registers this to finalize recordings before yield
    interface CameraYieldListener {
        /** Called BEFORE camera is yielded. Finalize any active recording to prevent corruption. */
        fun onPreYield()
        /** Called AFTER camera is re-acquired. Resume recording if needed. */
        fun onPostReacquire()
    }
    private var yieldListener: CameraYieldListener? = null

    // Stats logging (time-based, not frame-based)
    private var lastStatsTime: Long = 0
    private var lastStatsFrameCount = 0

    // Per-stage timing: rolling p50/p95 window across STAGE_TIMING_WINDOW frames.
    // All collection and log emission are gated on DaemonLogConfig.GPU_PIPELINE_TIMING
    // (compile-time) + UnifiedConfigManager.isTimingLogsEnabled() (runtime).
    // When the compile-time flag is false, R8 eliminates every branch that touches
    // these arrays so the hot path pays zero overhead in production builds.
    private val timingTotalNs = LongArray(STAGE_TIMING_WINDOW)
    private val timingAcquireNs = LongArray(STAGE_TIMING_WINDOW)
    private val timingEncodeNs = LongArray(STAGE_TIMING_WINDOW)
    private val timingReadbackNs = LongArray(STAGE_TIMING_WINDOW)
    private val timingSubmitNs = LongArray(STAGE_TIMING_WINDOW)
    private var timingPos = 0
    private var timingFilled = 0
    private var stageWindowAiReadbackSkips = 0

    private var targetFps = 15  // Desired frame rate for camera

    /**
     * Sets the consumers for the camera frames.
     *
     * @param recorder GPU mosaic recorder for zero-copy recording
     * @param downscaler GPU downscaler for AI lane
     * @param sentry Surveillance engine for motion detection
     */
    fun setConsumers(recorder: GpuMosaicRecorder?, downscaler: GpuDownscaler?, sentry: SurveillanceEngineGpu?) {
        this.recorder = recorder
        this.downscaler = downscaler
        this.sentry = sentry

        // Build the AI lane worker once consumers are wired. Recycler points
        // back to the downscaler's buffer pool so dropped frames are returned
        // immediately (no leak under sustained submit-while-busy).
        if (this.aiLaneWorker == null) {
            this.aiLaneWorker = AiLaneWorker(AiLaneWorker.FrameRecycler { frame ->
                val ds = this.downscaler
                if (ds != null && frame != null) {
                    try {
                        ds.recycleBuffer(frame)
                    } catch (t: Throwable) {
                        logger.debug("downscaler.recycleBuffer failed: " + t.message)
                    }
                }
            })
        }
        this.aiLaneWorker?.setSentry(sentry)
        // Sentry needs the GL handler so its foveated crops (which touch GL
        // state) can hop back to GL thread when called from AiLaneWorker.
        val gh = glHandler
        if (sentry != null && gh != null) {
            sentry.setGlHandler(gh)
        }
        sentry?.setCameraTargetFps(targetFps)
    }

    /**
     * Starts the GPU camera pipeline.
     *
     * @throws Exception if initialization fails
     */
    @Throws(Exception::class)
    fun start() {
        logger.info("Starting GPU camera pipeline...")
        startTime = System.currentTimeMillis()

        // SOTA: Initialize BYD camera coordinator for cooperative sharing
        if (cameraCoordinator == null) {
            val coordinator = BydCameraCoordinator()
            cameraCoordinator = coordinator
            coordinator.setArbitrationMode(arbitrationMode)
            coordinator.setYieldCallback(object : BydCameraCoordinator.CameraYieldCallback {
                override fun onYieldCamera() {
                    // Contention detected — yield on GL thread
                    logger.info("YIELD: Contention detected — releasing camera for native app")
                    cameraYielded = true
                    glHandler?.post { yieldCameraInternal() }
                }

                override fun onReacquireCamera() {
                    // Native app released camera after contention yield — re-acquire
                    logger.info("REACQUIRE: Native app released camera — reopening")
                    cameraYielded = false
                    glHandler?.post {
                        try {
                            startCamera()
                            val coord = cameraCoordinator
                            if (coord != null && cameraObj != null) {
                                coord.resetEventCallbackState()
                                coord.setupEventCallback(cameraObj)
                            }

                            // Restart encoder drainer thread — it was stopped during
                            // onPreYield → stopRecording → closeEventRecording.
                            // Without this, triggerEventRecording creates a muxer but
                            // no thread dequeues frames from the encoder to write them.
                            encoder?.restartDrainerAfterCameraClose()

                            // SOTA: Notify pipeline to resume recording
                            yieldListener?.let { listener ->
                                try {
                                    listener.onPostReacquire()
                                    logger.info("Post-reacquire: recording resumed")
                                } catch (e: Exception) {
                                    logger.warn("Post-reacquire callback error: " + e.message)
                                }
                            }

                            logger.info("Camera re-acquired after contention yield")
                        } catch (e: Exception) {
                            logger.error("Failed to re-acquire camera: " + e.message)
                        }
                    }
                }

                override fun onCameraError(eventType: Int) {
                    // Camera HAL error — but only restart if frames have actually stopped.
                    // On DiLink5.0, event 8 fires immediately after camera open (after event 1004)
                    // as a benign HAL lifecycle notification. Restarting on it causes an infinite loop.
                    // Guard: ignore error events within 3 seconds of camera start — the HAL is still
                    // settling. If it's a real error, the frame stall watchdog will catch it.
                    val timeSinceStart = System.currentTimeMillis() - lastCameraStartTime
                    if (timeSinceStart < 3000) {
                        logger.warn(
                            "CAMERA ERROR: event=" + eventType + " — IGNORED (camera started " +
                                timeSinceStart + "ms ago, waiting for frame stall watchdog)"
                        )
                        return
                    }
                    logger.error("CAMERA ERROR: event=$eventType — restarting camera")
                    glHandler?.post { restartCameraAfterError() }
                }
            })
            coordinator.register()
        }

        // Start GL thread
        val newGlThread = HandlerThread("GL-RenderLoop")
        glThread = newGlThread
        newGlThread.start()
        val newGlHandler = Handler(newGlThread.looper)
        glHandler = newGlHandler

        // Now that the GL handler exists, give it to the sentry so its
        // foveated crops can hop back to GL when called from AiLaneWorker.
        sentry?.let {
            it.setGlHandler(newGlHandler)
            it.setCameraTargetFps(targetFps)
        }

        // Initialize on GL thread
        newGlHandler.post {
            try {
                initializeGl()
                startCamera()

                // SOTA: Setup event callback for HAL error detection (-10086, 8)
                val coord = cameraCoordinator
                if (coord != null && cameraObj != null) {
                    coord.setupEventCallback(cameraObj)
                }

                running = true

                // Start render loop
                newGlHandler.post(this::renderLoop)

                // Start watchdog
                startWatchdog()

                logger.info("GPU camera pipeline started")
            } catch (e: Exception) {
                logger.error("Failed to start GPU pipeline", e)
                throw RuntimeException(e)
            }
        }
    }

    /**
     * Initializes OpenGL context and textures.
     */
    private fun initializeGl() {
        // Create EGL context
        val core = EGLCore()
        eglCore = core

        // Create a dummy pbuffer surface and make it current
        // This is required before any OpenGL calls can be made
        val dummy = core.createPbufferSurface(1, 1)
        dummySurface = dummy
        core.makeCurrent(dummy)

        // Log GL info (now that context is current)
        GlUtil.logGlInfo()

        probeHardwareBufferBridge()

        // Create camera texture (OES type for external camera)
        cameraTextureId = GlUtil.createExternalTexture()

        // Create the ImageReader-backed camera consumer. Bypasses
        // SurfaceFlinger throttling that clamps the SurfaceTexture consumer
        // to ~8.5 fps on this device (verified by AvmImageReaderFpsProbe).
        createCameraImageReader()

        // Initialize GPU components now that EGL context exists
        if (recorder != null) {
            // Recorder needs to be initialized with EGLCore and encoder
            // This should be done by the caller after encoder is created
            logger.debug("Recorder initialization deferred to caller")
        }

        downscaler?.let {
            it.init()  // Default RGB mode
            logger.debug("Downscaler initialized")
        }

        // Initialize foveated cropper for high-res AI crops
        val cropper = FoveatedCropper()
        foveatedCropper = cropper
        cropper.init()

        logger.info("OpenGL initialized (texture=$cameraTextureId)")
    }

    /**
     * Initializes the recorder on the GL thread.
     *
     * This must be called after the GL context is created and made current.
     *
     * @param recorder GPU mosaic recorder to initialize
     * @param encoder Hardware encoder providing the input surface
     */
    fun initRecorderOnGlThread(recorder: GpuMosaicRecorder?, encoder: HardwareEventRecorderGpu?) {
        val gh = glHandler
        if (gh == null) {
            logger.error("GL thread not started")
            return
        }

        // Store encoder reference for draining in render loop
        this.encoder = encoder

        gh.post {
            try {
                val enc = encoder
                val core = eglCore
                // The Java original called recorder.init(...) unconditionally, so a missing
                // dependency threw and the catch below skipped BOTH the success log and the
                // callback. Guarding without returning would instead report success and tell
                // the pipeline to start recording against an uninitialised recorder.
                if (recorder == null || enc == null || core == null) {
                    logger.error(
                        "Recorder init skipped (recorder=" + (recorder != null) +
                            ", encoder=" + (enc != null) + ", eglCore=" + (core != null) + ")"
                    )
                    return@post
                }
                recorder.init(core, enc)
                logger.info("Recorder initialized on GL thread")

                // Notify pipeline that recorder is ready
                recorderInitCallback?.run()
            } catch (e: Exception) {
                logger.error("Failed to initialize recorder on GL thread", e)
            }
        }
    }

    // Callback for when recorder is initialized
    private var recorderInitCallback: Runnable? = null

    /**
     * Sets a callback to be invoked when the recorder is initialized.
     *
     * @param callback Callback to run on GL thread after recorder init
     */
    fun setRecorderInitCallback(callback: Runnable?) {
        this.recorderInitCallback = callback
    }

    /**
     * Initializes the stream scaler on the GL thread.
     *
     * @param streamScaler GPU stream scaler to initialize
     * @param streamEncoder Hardware encoder for streaming
     */
    fun initStreamScalerOnGlThread(streamScaler: GpuStreamScaler, streamEncoder: HardwareEventRecorderGpu) {
        val gh = glHandler
        if (gh == null) {
            logger.error("GL thread not started")
            return
        }

        gh.post {
            try {
                streamScaler.init(eglCore!!, streamEncoder)
                logger.info("Stream scaler initialized on GL thread")
            } catch (e: Exception) {
                logger.error("Failed to initialize stream scaler on GL thread", e)
            }
        }
    }

    /**
     * Gets the EGL core for initializing GPU components.
     *
     * @return EGLCore instance (only valid after start() is called)
     */
    fun getEglCore(): EGLCore? = eglCore

    /**
     * Recreates the ImageReader consumer for camera switching.
     *
     * The BYD AVMCamera HAL doesn't properly deliver frames to a Surface
     * that was previously connected to a different camera ID. After the first
     * frame, subsequent frames are never delivered, causing a frozen image.
     * Recreating the ImageReader consumer forces a clean connection to the new camera.
     */
    private fun recreateCameraSurface() {
        logger.info("Recreating ImageReader consumer for camera switch...")
        releaseCameraConsumer()
        createCameraImageReader()
        logger.info("Camera consumer recreated for camera switch")
    }

    /** Build an ImageReader-backed consumer (zero-copy path).
     *  Frame handling:
     *    HAL → ImageReader producer (gralloc)
     *      → OnImageAvailableListener fires on imageReaderThread
     *        → acquireLatestImage / getHardwareBuffer
     *          → glHandler.post(bindHardwareBufferToTexture + notify frameSync)
     *  The listener MUST run on a thread separate from glHandler because
     *  renderLoop parks the GL thread on frameSync.wait(); a same-thread
     *  listener would starve and the HAL queue would back up, dropping
     *  frames the way we observed at boot (Stats: 0 frames). */
    private fun createCameraImageReader() {
        if (imageReaderThread == null) {
            val thread = HandlerThread("CamImageReaderCb")
            imageReaderThread = thread
            thread.start()
            imageReaderHandler = Handler(thread.looper)
        }
        // Pool size 6 (vs the typical 3) absorbs GL-thread stalls during
        // surveillance heavy work (YOLO inference, foveated readback) without
        // throttling the HAL producer rate. At 5120×960 NV12 = 7.4 MB/buf,
        // pool=6 holds ~44 MB gralloc — well within Adreno 610 budget.
        // Pool=3 was throttling HAL emission to ~5.7 fps in surveillance mode
        // because GL frames occasionally hit 261ms (logged backpressure).
        // 6 buffers × 67ms (15 fps cycle) = 400ms slack vs 200ms.
        // PRIVATE = opaque gralloc, optimal for zero-copy GPU sampling.
        // USAGE_GPU_SAMPLED_IMAGE tells the gralloc allocator we want a
        // GPU-friendly memory layout.
        val poolSize = 6
        val reader = try {
            val usage = HardwareBuffer.USAGE_GPU_SAMPLED_IMAGE
            ImageReader.newInstance(width, height, ImageFormat.PRIVATE, poolSize, usage)
        } catch (t: Throwable) {
            // Some BYD HAL builds may reject PRIVATE — fall back to YUV_420_888.
            logger.warn("ImageReader PRIVATE init failed: " + t.message + " — falling back to YUV_420_888")
            ImageReader.newInstance(width, height, ImageFormat.YUV_420_888, poolSize)
        }
        cameraImageReader = reader
        reader.setOnImageAvailableListener({ r -> onHalImageAvailable(r) }, imageReaderHandler)
        cameraSurface = reader.surface
    }

    private fun probeHardwareBufferBridge() {
        if (!isLibraryLoaded()) {
            throw IllegalStateException("libsurveillance not loaded before camera startup")
        }

        val report = probeExtensionsNative()
        nativeProbeReport = report ?: ""
        nativeProbeReady = isHardwareBufferBridgeReady(nativeProbeReport)
        logger.info("HardwareBuffer bridge probe: $nativeProbeReport")

        if (!nativeProbeReady) {
            throw IllegalStateException("HardwareBuffer bridge missing required extensions: $nativeProbeReport")
        }
    }

    private fun persistCameraConfigSnapshot(validated: Boolean, failureReason: String?) {
        try {
            val existingCam = UnifiedConfigManager.loadConfig().optJSONObject("camera")
            val currentId = getCameraId()
            val existingManual = existingCam != null && existingCam.optBoolean("manualOverride", false)
            val existingId = existingCam?.optInt("probedCameraId", -1) ?: -1

            if (existingManual && existingId >= 0 && existingId != currentId && !manualOverrideActive) {
                logger.info(
                    "Skipping config write — manual override exists (saved=" + existingId +
                        ", running=" + currentId + ")"
                )
                return
            }

            val camCfg = JSONObject()
            camCfg.put("probedCameraId", currentId)
            camCfg.put("probedSurfaceMode", cameraSurfaceMode)
            camCfg.put("cameraLayout", cameraLayout)
            camCfg.put("probedAndValidated", validated)
            camCfg.put("manualOverride", manualOverrideActive || existingManual)
            camCfg.put("fallbackFromProbe", fallbackFromProbe)
            camCfg.put("reprobeOnNextRestart", false)
            camCfg.put("sourceBmmTag", sourceBmmTag)
            camCfg.put("discoveryMethod", discoveryMethod)
            camCfg.put("vehicleCamSort", vehicleCamSort)
            camCfg.put("validatedAtMs", validatedAtMs)
            camCfg.put("validatedFrameWidth", validatedFrameWidth)
            camCfg.put("validatedFrameHeight", validatedFrameHeight)
            camCfg.put("validationSignal", validationSignal)
            camCfg.put("validationFrameCount", validationFrameCount)
            camCfg.put("stripConfidence", stripConfidence)
            camCfg.put("layoutConfidence", layoutConfidence)
            camCfg.put("quadrantVariance", quadrantVariance)
            camCfg.put("lastValidationFailure", failureReason ?: lastValidationFailure)
            camCfg.put("nativeProbeReport", nativeProbeReport)
            camCfg.put("nativeProbeReady", nativeProbeReady)
            camCfg.put("arbitrationMode", arbitrationMode)
            camCfg.put("fpsSetCameraResult", fpsSetCameraResult)
            camCfg.put("fpsSetMediaCodecResult", fpsSetMediaCodecResult)
            camCfg.put("lastCameraEvent", lastCameraEvent)
            firmwareInfo.let { fw ->
                camCfg.put("firmwareFingerprint", fw.fingerprint)
                camCfg.put("buildDisplay", fw.buildDisplay)
                camCfg.put("buildIncremental", fw.buildIncremental)
                camCfg.put("roBuildIncremental", fw.roBuildIncremental)
                camCfg.put("productDevice", fw.device)
                camCfg.put("vehicleCamSort", fw.vehicleCamSort)
            }
            UnifiedConfigManager.updateSection("camera", camCfg)
        } catch (ex: Exception) {
            logger.warn("Failed to save camera config: " + ex.message)
        }
    }

    fun persistCameraConfig(validated: Boolean, failureReason: String?) {
        persistCameraConfigSnapshot(validated, failureReason)
    }

    /** Idempotent teardown of whichever consumer is active. */
    private fun releaseCameraConsumer() {
        // Release the held Image + HardwareBuffer FIRST so the gralloc slots
        // go back to the ImageReader pool before we close the reader.
        releasePreviousBoundImage()
        cameraSurface?.let {
            try {
                it.release()
            } catch (t: Throwable) {
                logger.debug("cameraSurface.release() failed: " + t.message)
            }
            cameraSurface = null
        }
        cameraImageReader?.let {
            try {
                it.close()
            } catch (t: Throwable) {
                logger.debug("cameraImageReader.close() failed: " + t.message)
            }
            cameraImageReader = null
        }
    }

    /**
     * Starts the BYD camera via AVMCamera reflection with multi-strategy fallback.
     * Tries constructor path first, then static factory for firmware compatibility.
     */
    @Throws(Exception::class)
    private fun startCamera() {
        // GATE: Don't open camera if yielded to native app via IBYDCameraUser callback
        val coord = cameraCoordinator
        if (coord != null && coord.isCameraYielded()) {
            logger.info("Camera yielded to native app — skipping open")
            cameraYielded = true
            return
        }

        val cameraId = if (cameraIdOverride >= 0) cameraIdOverride else PHYSICAL_CAMERA_ID

        startCameraViaAvmReflection(cameraId)

        cameraYielded = false
        lastCameraStartTime = System.currentTimeMillis()
        logger.info(
            "Camera started (" + width + "x" + height +
                ", id=" + cameraId + ", surfaceMode=" + cameraSurfaceMode + ")"
        )

        // Update coordinator with actual camera ID
        cameraCoordinator?.setActiveCameraId(cameraId)
    }

    /**
     * Opens camera via AVMCamera reflection.
     *
     * Strategy (mirrors DiPlus C4051a.m4446d() approach):
     *   1. Constructor: new AVMCamera(int) + .open() — required on this device.
     *      The static factory AVMCamera.open(int) returns null because
     *      BmmCameraInfo.isValidCamera() is empty (vehicle.config.cam_sort
     *      is unset on DiLink 5.0). The constructor bypasses that gate and
     *      is the only path that opens the camera at all.
     *   2. Static factory AVMCamera.open(int) — only if constructor is
     *      missing entirely (DiLink 6.0+ may remove it).
     *
     * See CAMERA_FPS_INVESTIGATION.md for the full rationale.
     *
     * After either path succeeds, addPreviewSurface + startPreview are called.
     *
     * Notifies IBYDCameraService before opening so the service can arbitrate
     * with native apps (reverse camera, dashcam, AVM parking view).
     */
    @Throws(Exception::class)
    private fun startCameraViaAvmReflection(cameraId: Int) {
        // Notify camera service we're about to open
        cameraCoordinator?.notifyPreOpenCamera()

        val avmClass = Class.forName("android.hardware.AVMCamera")

        // === ATTEMPT 1: Constructor new AVMCamera(int) + .open() ===
        // Required on this firmware. The static factory would return null.
        try {
            val constructor: Constructor<*> = avmClass.getDeclaredConstructor(Int::class.javaPrimitiveType)
            constructor.isAccessible = true
            val obj = constructor.newInstance(cameraId)
            cameraObj = obj

            val mOpen = avmClass.getDeclaredMethod("open")
            mOpen.isAccessible = true
            if (mOpen.invoke(obj) as Boolean != true) {
                throw RuntimeException("AVMCamera.open() returned false (id=$cameraId)")
            }
            logger.info("Camera opened via constructor path (id=$cameraId)")
        } catch (e: NoSuchMethodException) {
            // Constructor with int param doesn't exist — fall back to static factory
            logger.info("AVMCamera(int) constructor not found — trying static factory")
            cameraObj = null

            // === ATTEMPT 2: Static factory AVMCamera.open(cameraId) ===
            try {
                val mStaticOpen = avmClass.getDeclaredMethod("open", Int::class.javaPrimitiveType)
                mStaticOpen.isAccessible = true
                var obj = mStaticOpen.invoke(null, cameraId)
                cameraObj = obj
                if (obj != null) {
                    logger.info("Camera opened via static factory (id=$cameraId)")
                } else {
                    logger.info("AVMCamera.open($cameraId) returned null — trying IDs 0-5")
                    for (tryId in 0..5) {
                        if (tryId == cameraId) continue
                        obj = mStaticOpen.invoke(null, tryId)
                        cameraObj = obj
                        if (obj != null) {
                            logger.info("Camera opened via static factory probe (id=$tryId)")
                            cameraIdOverride = tryId
                            break
                        }
                    }
                }
                if (cameraObj == null) {
                    throw RuntimeException("AVMCamera.open() returned null for all IDs 0-5")
                }
            } catch (e2: NoSuchMethodException) {
                throw RuntimeException(
                    "AVMCamera API not compatible: no constructor(int) and no static open(int). " +
                        "Available constructors: " + Arrays.toString(avmClass.declaredConstructors) +
                        ", methods: " + Arrays.toString(avmClass.declaredMethods),
                    e2
                )
            }
        }

        // Snapshot the opened handle once. cameraObj is @Volatile and other threads null it
        // (the release path, and the coordinator yielding the camera to the native BYD app).
        // Re-reading the field at each reflective call site below turned that race into
        // Method.invoke's "null receiver" NPE, which propagated out of the GL post lambda and
        // killed the render thread — observed on the head unit 2026-09-20 (BladeWatch-ydl3).
        val cam = cameraObj
            ?: throw RuntimeException("AVMCamera handle was released during open (id=$cameraId)")

        // Set FPS BEFORE addPreviewSurface. On DiLink 3.x firmware the HAL
        // rejects setCameraFps once a preview surface is attached — even before
        // startPreview. Order must be open → setCameraFps → addPreviewSurface →
        // startPreview to match the BYD HAL state machine.
        val fpsOk = AvmCameraHelper.setCameraFps(cam, targetFps)
        fpsSetCameraResult = if (fpsOk)
            "startup:setCameraFps($targetFps)=ok"
        else
            "startup:setCameraFps($targetFps)=failed"
        // We intentionally stop at setCameraFps here. The encoder-owned
        // MediaCodec path is surfaced only as diagnostics until a real owner
        // passes the codec across the boundary.

        // Connect surface — mode 0 works on Seal, other models may need different mode
        val mAddSurface = avmClass.getDeclaredMethod("addPreviewSurface", Surface::class.java, Int::class.javaPrimitiveType)
        mAddSurface.isAccessible = true
        mAddSurface.invoke(cam, cameraSurface, cameraSurfaceMode)

        // Start preview — required for real frame data on BYD Seal HAL.
        // The HAL supports multiple consumers calling startPreview simultaneously.
        // The AVC warmup (com.byd.avc launch + 4s delay) ensures the native DVR
        // has already initialized before we reach here, preventing race conditions.
        val mStart = avmClass.getDeclaredMethod("startPreview")
        mStart.isAccessible = true
        mStart.invoke(cam)
        logger.info("Camera started (id=$cameraId, targetFps=$targetFps)")
    }

    // Diagnostic counters for the ImageReader frame flow. Kept in place as
    // permanent instrumentation since the path crosses two threads + a
    // gralloc lifetime boundary; surfacing health via 2-min Stats line is
    // cheap and useful in field debugging.
    @Volatile private var irFireCount: Long = 0       // onHalImageAvailable invocations
    @Volatile private var irAcquireOkCount: Long = 0
    @Volatile private var irAcquireNullCount: Long = 0
    @Volatile private var irBindFailCount: Long = 0
    @Volatile private var lastIrDiagLogMs: Long = 0

    /**
     * Called when a new gralloc buffer is available from the HAL
     * (ImageReader path, API 28+). Runs on imageReaderThread (NOT glThread)
     * — we cannot do the EGLImage bind here because the EGL context lives
     * on the GL thread.
     *
     * Strategy: notify frameSync so renderLoop wakes up. renderLoop will
     * do acquireLatestImage + getHardwareBuffer + bind on the GL thread
     * where the EGL context is current. This mirrors the SurfaceTexture
     * path where the producer notifies and the consumer thread does
     * updateTexImage.
     */
    private fun onHalImageAvailable(r: ImageReader) {
        irFireCount++
        synchronized(frameSync) {
            imagePending = true
            frameSync.notify()
        }
    }

    // The Image and HardwareBuffer currently bound to cameraTextureId.
    // Held alive across GL render cycles — closing them returns the gralloc
    // slot to the ImageReader pool, which invalidates the EGLImage we bound
    // and causes the producer side to stall. Released only when the NEXT
    // bind succeeds (releasePreviousImage call inside consumeLatestImageAndBind),
    // so the texture always references a live gralloc buffer.
    //
    // THREAD-CONFINED to the GL thread (renderLoop). All reads and writes
    // happen inside consumeLatestImageAndBind / releasePreviousBoundImage,
    // which are only invoked from renderLoop. Do NOT access from the
    // ImageReader callback thread, watchdog, or any daemon thread — touching
    // these from another thread will leak the gralloc slot and stall the HAL.
    private var currentBoundImage: Image? = null             // @GuardedBy(GL thread)
    private var currentBoundHwBuffer: HardwareBuffer? = null // @GuardedBy(GL thread)

    /**
     * Acquires the latest gralloc buffer from cameraImageReader and binds it
     * to cameraTextureId. MUST be called from the GL thread (current EGL
     * context required for glEGLImageTargetTexture2DOES).
     *
     * Returns true if a frame was bound; false if no frame was ready or
     * the bind failed. acquireLatestImage drops older buffered frames if
     * the GL loop falls behind, matching SurfaceTexture's "always sample
     * latest" semantics.
     */
    private fun consumeLatestImageAndBind(): Boolean {
        val reader = cameraImageReader ?: return false
        var image: Image? = null
        var hwBuffer: HardwareBuffer? = null
        var transferredOwnership = false
        try {
            image = reader.acquireLatestImage()
            if (image == null) {
                irAcquireNullCount++
                return false
            }
            irAcquireOkCount++
            hwBuffer = image.hardwareBuffer
            if (hwBuffer == null) {
                logger.warn("Image.getHardwareBuffer() returned null — dropping frame")
                irBindFailCount++
                return false
            }
            val bound = bindHardwareBufferToTextureNative(hwBuffer, cameraTextureId)
            if (!bound) {
                logger.warn("bindHardwareBufferToTexture failed — dropping frame")
                irBindFailCount++
                return false
            }
            // Bind succeeded. NOW it's safe to release the previous image —
            // the texture is no longer pointing at it.
            releasePreviousBoundImage()
            // Transfer ownership of this image+hwBuffer into the held slots.
            currentBoundImage = image
            currentBoundHwBuffer = hwBuffer
            transferredOwnership = true
            return true
        } catch (t: Throwable) {
            logger.warn("consumeLatestImageAndBind error: " + t.message)
            irBindFailCount++
            return false
        } finally {
            // Only close locally if we did NOT transfer ownership to the
            // held slots. On the success path the held slots own the refs;
            // on failure paths we close immediately to release the slot.
            if (!transferredOwnership) {
                if (hwBuffer != null) {
                    try {
                        hwBuffer.close()
                    } catch (t: Throwable) {
                        logger.debug("hwBuffer.close() failed: " + t.message)
                    }
                }
                if (image != null) {
                    try {
                        image.close()
                    } catch (t: Throwable) {
                        logger.debug("image.close() failed: " + t.message)
                    }
                }
            }
        }
    }

    private fun releasePreviousBoundImage() {
        currentBoundHwBuffer?.let {
            try {
                it.close()
            } catch (t: Throwable) {
                logger.debug("currentBoundHwBuffer.close() failed: " + t.message)
            }
            currentBoundHwBuffer = null
        }
        currentBoundImage?.let {
            try {
                it.close()
            } catch (t: Throwable) {
                logger.debug("currentBoundImage.close() failed: " + t.message)
            }
            currentBoundImage = null
        }
    }

    /** Periodic diagnostic for the ImageReader path. Throttled to align with
     *  the 2-minute Stats log so it rides along instead of spamming. */
    private fun maybeLogImageReaderDiag() {
        val now = System.currentTimeMillis()
        if (now - lastIrDiagLogMs < STATS_INTERVAL_MS) return
        lastIrDiagLogMs = now
        logger.info(
            String.format(
                "IR-diag: fire=%d acqOk=%d acqNull=%d bindFail=%d",
                irFireCount, irAcquireOkCount, irAcquireNullCount, irBindFailCount
            )
        )
    }

    /**
     * Main render loop - distributes frames to recording and AI lanes.
     */
    private fun renderLoop() {
        if (!running) {
            return
        }

        try {
            // Wait for new frame (hardware sync). Skip the wait if the HAL
            // already signaled while we were processing the previous frame —
            // otherwise the unconditional wait() would miss that notify and
            // park us until the NEXT HAL fire, capping effective FPS.
            synchronized(frameSync) {
                if (!imagePending) {
                    try {
                        (frameSync as Object).wait(100)  // Timeout to check running flag
                    } catch (e: InterruptedException) {
                        Thread.currentThread().interrupt()
                    }
                }
                imagePending = false
            }

            if (!running) {
                return
            }

            // Update watchdog heartbeat
            lastGlThreadHeartbeat = System.currentTimeMillis()
            maybeLogImageReaderDiag()

            // Auto-probe must advance even when a candidate camera/mode opens
            // successfully but never produces enough frames to reach the
            // frame-15 validation branch.
            if (maybeAdvanceProbeAfterNoFrames()) {
                return
            }

            // SOTA: Skip frame processing if camera is yielded to native app,
            // not yet open, or being torn down/reopened by the daemon thread
            // (reopenCamera/restartCameraAfterError). The restartInProgress
            // gate is essential — without it the GL thread can race the
            // daemon thread's close and block in updateTexImage() against a
            // dead BufferQueue, freezing the GL thread until the watchdog
            // kills the process.
            if (cameraYielded || cameraObj == null || restartInProgress.get()) {
                // GL thread stays alive but doesn't touch camera — waiting for re-acquire
                return
            }

            // ImageReader path: acquireLatestImage + getHardwareBuffer +
            // glEGLImageTargetTexture2DOES binds the freshest gralloc buffer
            // to cameraTextureId. Runs on the GL thread (current EGL
            // context). If no new frame is ready (spurious wakeup or notify
            // race), return — the finally re-posts the loop and we wait again.
            if (cameraImageReader == null) {
                return
            }
            // Per-stage timing — compile-time flag gates all nanoTime calls and
            // accumulation so the hot path has zero overhead in release builds.
            val collectTiming = DaemonLogConfig.GPU_PIPELINE_TIMING || DaemonLogConfig.ENABLE_ALL
            val stageT0 = if (collectTiming) System.nanoTime() else 0L
            if (!consumeLatestImageAndBind()) {
                return
            }
            val stageAfterAcquireNs = if (collectTiming) System.nanoTime() else 0L
            frameCounter++
            lastFrameTime = System.currentTimeMillis()
            firstFrameReceived = true
            consecutiveContentionStalls = 0  // Frames flowing — clear stall counter

            // Camera setup burst is complete now that frames are flowing — kick off
            // deferred YOLO/TFLite init so its GPU-delegate kernel compilation runs
            // during steady-state rendering, not concurrently with the camera's heavy
            // EGL/GL setup. Idempotent: only the first call actually starts the thread.
            sentry?.startDeferredYoloInit()

            // SOTA: Full-matrix auto-probe at frame 15 (~2 sec).
            // Sweeps camera IDs 0-5 × surface modes 0-5 to find the first
            // combination that produces panoramic image data. Each combo gets
            // 15 frames to warm up before pixel readback.
            if (frameCounter == 15 && downscaler != null && !skipFrameValidation) {
                try {
                    val probe = downscaler!!.readPixels(cameraTextureId, 8, 8)
                    var hasData = false
                    if (probe != null) {
                        for (i in 0 until Math.min(probe.size, 192)) {
                            if ((probe[i].toInt() and 0xFF) > 10) {
                                hasData = true
                                break
                            }
                        }
                    }
                    val currentId = if (cameraIdOverride >= 0) cameraIdOverride else PHYSICAL_CAMERA_ID
                    val isPanoramic = width >= 5000
                    val stripVerified = verifyPanoramicStrip(probe)
                    val stripConfidenceValue = if (stripVerified) "high" else "low"
                    val layoutConfidenceValue = if (stripVerified)
                        (if (cameraLayout == 1) "apa_candidate" else "high")
                    else
                        (if (cameraLayout == 1) "unknown" else "low")
                    val quadrantVarianceValue = summarizeQuadrantVariance(probe)
                    setQuadrantVariance(quadrantVarianceValue)
                    logger.info(
                        "Camera ID " + currentId + " probe: " +
                            (if (hasData) "HAS DATA" else "BLACK") +
                            " | resolution=" + width + "x" + height +
                            " | type=" + (if (isPanoramic) "PANORAMIC" else "SINGLE") +
                            " | surfaceMode=" + cameraSurfaceMode
                    )

                    if (hasData && isPanoramic) {
                        // Track this camera as having real data (for fallback if strip check fails)
                        lastDataCameraId = currentId
                        recordValidationSnapshot(
                            stripVerified,
                            if (stripVerified) "frame15_non_black_5120x960" else "frame15_non_black_low_layout_confidence",
                            stripConfidenceValue,
                            layoutConfidenceValue,
                            if (stripVerified) "" else "frame15_low_layout_confidence",
                            width,
                            height,
                            frameCounter
                        )

                        // During auto-probe: accept the first camera with non-black panoramic data.
                        // The 5120x960 resolution IS the panoramic strip identifier on BYD — no other
                        // camera output uses this resolution with real image data. The luma-based
                        // strip check was producing false negatives in low-light/uniform scenes.
                        if (autoProbeCameras) {
                            logger.info(
                                "Auto-probe: SELECTED camera ID " + currentId +
                                    " (panoramic data confirmed, surfaceMode=" + cameraSurfaceMode +
                                    ", stripVerified=" + stripVerified + ")"
                            )
                            autoProbeCameras = false
                            probeStartId = -1
                            probeComplete = true
                            lastDataCameraId = -1
                            persistCameraConfigSnapshot(stripVerified, if (stripVerified) null else "frame15_low_layout_confidence")
                            logger.info("Probe complete — recording/streaming/AI lanes now active")
                            probeCallback?.onCameraFound(currentId, cameraSurfaceMode)
                        } else {
                            // Not in auto-probe mode — this is the frame-15 check for a saved config.
                            // Camera has data at panoramic resolution — it's working correctly.
                            // No further validation needed (skipFrameValidation handles saved configs,
                            // but this path covers the default camera ID 1 on first boot).
                            probeComplete = true
                            persistCameraConfigSnapshot(stripVerified, if (stripVerified) null else "frame15_low_layout_confidence")
                        }
                    } else if (autoProbeCameras) {
                        // Advance to next combination in the matrix
                        advanceProbeToNext(currentId)
                    } else if (!hasData) {
                        // Saved config gave black frames at frame 15. This could be:
                        // 1. HAL warmup (normal — wait longer)
                        // 2. OEM dashcam contention (transient)
                        // 3. Genuinely wrong camera ID (BmmCameraInfo returned wrong value)
                        //
                        // Don't re-probe immediately (causes OEM dashcam "no signal").
                        // Instead, schedule a second check at frame 50 (~5s). If still black
                        // at that point, the saved config is genuinely wrong and we re-probe.
                        recordValidationSnapshot(
                            false,
                            "frame15_black",
                            "low",
                            if (cameraLayout == 1) "unknown" else "low",
                            "frame15_black",
                            width,
                            height,
                            frameCounter
                        )
                        logger.warn(
                            "Frame 15 readback BLACK for cam=" + currentId +
                                ", surfaceMode=" + cameraSurfaceMode +
                                " — will recheck at frame 50 before deciding"
                        )
                    }
                } catch (e: Exception) {
                    logger.warn("Camera probe failed: " + e.message)
                }
            }

            // Frame 50 recheck (~5s): if frame 15 was black, verify again.
            // By frame 50 the HAL has definitely warmed up. If still black, the saved
            // config is genuinely wrong (BmmCameraInfo returned incorrect ID).
            // Only then trigger a re-probe — this is rare and justified.
            if (frameCounter == 50 && !autoProbeCameras && !skipFrameValidation && downscaler != null) {
                try {
                    val probe = downscaler!!.readPixels(cameraTextureId, 8, 8)
                    var hasData = false
                    if (probe != null) {
                        for (i in 0 until Math.min(probe.size, 192)) {
                            if ((probe[i].toInt() and 0xFF) > 10) {
                                hasData = true
                                break
                            }
                        }
                    }
                    if (!hasData) {
                        val currentId = if (cameraIdOverride >= 0) cameraIdOverride else PHYSICAL_CAMERA_ID
                        val stripVerified = verifyPanoramicStrip(probe)
                        val quadrantVarianceValue = summarizeQuadrantVariance(probe)
                        setQuadrantVariance(quadrantVarianceValue)
                        recordValidationSnapshot(
                            stripVerified,
                            if (stripVerified) "frame50_non_black_5120x960" else "frame50_non_black_low_layout_confidence",
                            if (stripVerified) "high" else "low",
                            if (stripVerified) (if (cameraLayout == 1) "apa_candidate" else "high")
                            else (if (cameraLayout == 1) "unknown" else "low"),
                            if (stripVerified) "" else "frame50_low_layout_confidence",
                            width,
                            height,
                            frameCounter
                        )
                        logger.warn("Frame 50 STILL BLACK for cam=$currentId — saved config is wrong, starting re-probe")
                        persistCameraConfigSnapshot(false, "frame50_black")
                        setAutoProbeCameras(true)
                        probeComplete = false
                        lastDataCameraId = -1
                        advanceProbeToNext(currentId)
                    } else {
                        // Camera has non-black data at frame 50 — it's working.
                        // Persist as validated so next restart skips all frame checks.
                        // BUT: don't overwrite if user has a manual override set — they may have
                        // changed the camera ID in the UI and it hasn't taken effect yet.
                        val currentId = if (cameraIdOverride >= 0) cameraIdOverride else PHYSICAL_CAMERA_ID
                        val stripVerified = verifyPanoramicStrip(probe)
                        val quadrantVarianceValue = summarizeQuadrantVariance(probe)
                        setQuadrantVariance(quadrantVarianceValue)
                        val stripConfidenceValue = if (stripVerified) "high" else "low"
                        val layoutConfidenceValue = if (stripVerified)
                            (if (cameraLayout == 1) "apa_candidate" else "high")
                        else
                            (if (cameraLayout == 1) "unknown" else "low")
                        logger.info("Frame 50 recheck: camera ID $currentId confirmed working")
                        probeComplete = true
                        recordValidationSnapshot(
                            stripVerified,
                            if (stripVerified) "frame50_non_black_5120x960" else "frame50_non_black_low_layout_confidence",
                            stripConfidenceValue,
                            layoutConfidenceValue,
                            if (stripVerified) "" else "frame50_low_layout_confidence",
                            width,
                            height,
                            frameCounter
                        )
                        persistCameraConfigSnapshot(stripVerified, if (stripVerified) null else "frame50_low_layout_confidence")
                    }
                } catch (e: Exception) {
                    logger.warn("Frame 50 recheck failed: " + e.message)
                }
            }

            // SOTA: Gate all consumer passes until probe finds a working camera.
            // Without this, the encoder records BLACK frames, the stream shows garbage,
            // and the AI lane processes empty images during the probe sweep.
            if (!probeComplete) {
                // Still probing — don't feed consumers. Heartbeat already
                // updated above. Re-post handled by the finally block.
                return
            }

            // PASS 1: Recording (Zero-Copy GPU Path)
            // SOTA: Always render to encoder (for pre-record circular buffer)
            val localRecorder = recorder
            val localEncoder = encoder
            val stageBeforeMosaicNs = if (collectTiming) System.nanoTime() else 0L
            var stageAfterEncodeNs = stageBeforeMosaicNs
            if (localRecorder != null) {
                localRecorder.drawFrame(cameraTextureId)

                // CRITICAL: Drain encoder immediately after frame submission
                // This prevents eglSwapBuffers from blocking when encoder buffers fill up
                localEncoder?.drainEncoder()
                stageAfterEncodeNs = if (collectTiming) System.nanoTime() else 0L

                // RECOVERY: If encoder surface died (EGL_BAD_SURFACE after prolonged use),
                // reinitialize the encoder and reconnect the recorder.
                // P1 #9: keep using localRecorder/localEncoder captured above.
                // pipeline.stop() runs on the daemon thread and can null
                // this.recorder/this.encoder concurrently; re-reading the fields
                // here would NPE.
                if (localRecorder.needsReinit() && localEncoder != null) {
                    logger.warn("Encoder surface lost - reinitializing encoder...")
                    // Extend the GL watchdog window: encoder.release() joins
                    // the drainer (up to 2s) plus MediaCodec stop/release —
                    // the bare 3s GL timeout is not enough headroom.
                    // P1 #11: CAS so a concurrent reopenCamera (daemon thread)
                    // can't race; if another restart is already in flight,
                    // skip — it'll re-fire on the next frame.
                    if (!restartInProgress.compareAndSet(false, true)) {
                        return
                    }
                    try {
                        // Full teardown of recorder GL resources. Without this,
                        // shader programs (programId, overlayProgramId) and the
                        // overlay texture (overlayTextureId) leak on every
                        // reinit, since recorder.init() only frees the encoder
                        // surface, not the programs/textures it then re-creates.
                        localRecorder.release()
                        localEncoder.release()
                        localEncoder.init()
                        localRecorder.init(eglCore!!, localEncoder)
                        localRecorder.clearReinitFlag()
                        logger.info("Encoder reinitialized successfully after surface loss")
                    } catch (reinitEx: Exception) {
                        logger.error("Encoder reinit failed: " + reinitEx.message)
                        // If reinit fails, force process restart — EGL context is likely corrupt
                        logger.error("CRITICAL: Encoder reinit failed, forcing process restart")
                        try {
                            Thread.sleep(100)
                        } catch (ie: InterruptedException) {
                            Thread.currentThread().interrupt()
                        }
                        System.exit(0)
                    } finally {
                        restartInProgress.set(false)
                    }
                }
            }

            // PASS 1B: Streaming (Parallel Zero-Copy GPU Path)
            // Only runs if streaming is enabled - uses separate encoder at lower resolution
            // Capture local refs to avoid NPE from concurrent pipeline shutdown
            val localStreamScaler = streamScaler
            val localStreamEncoder = streamEncoder
            if (localStreamScaler != null && localStreamEncoder != null) {
                localStreamScaler.drawFrame(cameraTextureId)
                localStreamEncoder.drainEncoder()
            }

            // PASS 2: AI Lane (decoupled, async).
            //
            // GL thread: read pixels (~5-15ms) and post the byte[] to the AI
            // worker. Worker runs sentry.processFrame on its own thread —
            // V2 motion native (~30-100ms) and YOLO (which already dispatches
            // to its own aiExecutor inside SurveillanceEngineGpu) no longer
            // block the GL render loop.
            //
            // Drop-not-queue: if the worker is still processing the previous
            // frame, the new frame is recycled and dropped. V2 motion is
            // throttled to 10 fps internally so backlog has zero benefit.
            //
            // FRAME-COUNTER THROTTLE: AI readback runs once per
            // AI_READBACK_FRAME_MODULO frames the GL thread processes.
            // Wall-clock throttling collapses when readback duration approaches
            // the interval — the GL thread always finds the timer expired and
            // every frame triggers readback, capping the loop at ~8 fps.
            // Frame-modulo is immune: AI rate scales with HAL emission rate.
            //
            // Foveated cropper still runs on GL thread (inside processFrame's
            // call chain via setFoveatedCropper), but only when sentry
            // schedules it after motion detection — not every frame.
            val stageBeforeAiReadbackNs = if (collectTiming) System.nanoTime() else 0L
            var stageAfterAiReadbackNs = stageBeforeAiReadbackNs
            var stageAfterAiSubmitNs = stageBeforeAiReadbackNs
            val sentryLocal = sentry
            val aiWorker = aiLaneWorker
            if (sentryLocal != null && sentryLocal.isActive && downscaler != null && aiWorker != null) {
                val aiFrameTurn = (frameCounter % AI_READBACK_FRAME_MODULO == 0)
                if (!aiFrameTurn || aiWorker.isBusy()) {
                    // Not this frame's turn, or the worker is still processing
                    // the previous frame. Skip readback — let GL thread fly
                    // through mosaic+swap to drain the ImageReader pool.
                    if (collectTiming) stageWindowAiReadbackSkips++
                } else {
                    try {
                        val smallFrame = downscaler!!.readPixelsDirect(cameraTextureId)
                        stageAfterAiReadbackNs = if (collectTiming) System.nanoTime() else 0L
                        if (smallFrame != null) {
                            // Lazy-wire foveated cropper once. GL thread safe.
                            val cropper = foveatedCropper
                            if (cropper != null && cropper.isInitialized() && sentryLocal.foveatedCropper == null) {
                                sentryLocal.setFoveatedCropper(cropper, cameraTextureId)
                            }
                            // submitFrame is non-blocking: queues if worker idle,
                            // recycles+drops if busy. Either way, GL thread
                            // continues to next camera frame immediately.
                            aiWorker.submitFrame(smallFrame)
                        }
                        stageAfterAiSubmitNs = if (collectTiming) System.nanoTime() else 0L
                    } catch (e: Exception) {
                        logger.warn("AI lane error: " + (e.message ?: e.javaClass.simpleName))
                    }
                }
            }

            // Per-stage timing roll-up: accumulate into rolling window, emit
            // p50/p95/max every STAGE_TIMING_WINDOW frames when the runtime
            // toggle is on. The collectTiming gate makes all of this dead code
            // in production (R8 eliminates it when GPU_PIPELINE_TIMING=false).
            if (collectTiming) {
                val stageEndNs = System.nanoTime()
                timingTotalNs[timingPos] = stageEndNs - stageT0
                timingAcquireNs[timingPos] = stageAfterAcquireNs - stageT0
                timingEncodeNs[timingPos] = stageAfterEncodeNs - stageBeforeMosaicNs
                timingReadbackNs[timingPos] = stageAfterAiReadbackNs - stageBeforeAiReadbackNs
                timingSubmitNs[timingPos] = stageAfterAiSubmitNs - stageAfterAiReadbackNs
                timingPos = (timingPos + 1) % STAGE_TIMING_WINDOW
                if (timingFilled < STAGE_TIMING_WINDOW) timingFilled++

                if (timingFilled >= STAGE_TIMING_WINDOW && timingPos == 0 && UnifiedConfigManager.isTimingLogsEnabled()) {
                    val timing = DaemonLogger.getInstance("GpuPipelineTiming")
                    timing.info(
                        String.format(
                            "[PipelineTiming p50/p95/max ms] total:%d/%d/%d" +
                                " acquire:%d/%d/%d encode:%d/%d/%d" +
                                " gpuReadback:%d/%d/%d aiSubmit:%d/%d/%d" +
                                " (frames=%d aiSkips=%d)",
                            p50ms(timingTotalNs, timingFilled),
                            p95ms(timingTotalNs, timingFilled),
                            maxMs(timingTotalNs, timingFilled),
                            p50ms(timingAcquireNs, timingFilled),
                            p95ms(timingAcquireNs, timingFilled),
                            maxMs(timingAcquireNs, timingFilled),
                            p50ms(timingEncodeNs, timingFilled),
                            p95ms(timingEncodeNs, timingFilled),
                            maxMs(timingEncodeNs, timingFilled),
                            p50ms(timingReadbackNs, timingFilled),
                            p95ms(timingReadbackNs, timingFilled),
                            maxMs(timingReadbackNs, timingFilled),
                            p50ms(timingSubmitNs, timingFilled),
                            p95ms(timingSubmitNs, timingFilled),
                            maxMs(timingSubmitNs, timingFilled),
                            STAGE_TIMING_WINDOW, stageWindowAiReadbackSkips
                        )
                    )
                    stageWindowAiReadbackSkips = 0
                    timingFilled = 0
                }
            }

            // Log stats periodically (every 2 minutes, time-based).
            // Reports the *windowed* FPS (frames since the last stats log) instead
            // of the lifetime average — otherwise a stall during one window drags
            // the running mean down forever and masks recovery in later windows.
            val now = System.currentTimeMillis()
            if (now - lastStatsTime >= STATS_INTERVAL_MS) {
                val windowMs = if (lastStatsTime == 0L) (now - startTime) else (now - lastStatsTime)
                val windowFrames = frameCounter - lastStatsFrameCount
                val fps = if (windowMs > 0) (windowFrames * 1000.0f) / windowMs else 0f
                measuredFps = fps

                val aiProc = aiWorker?.processedFrames ?: 0
                val aiDrop = aiWorker?.droppedFrames ?: 0
                val uptimeS = (now - startTime) / 1000
                logger.info(
                    String.format(
                        "Stats: %d frames (window), %.1f FPS (target=%d), uptime=%ds, aiProcessed=%d, aiDropped=%d",
                        windowFrames, fps, targetFps, uptimeS, aiProc, aiDrop
                    )
                )
                aiWorker?.resetCounters()

                lastStatsTime = now
                lastStatsFrameCount = frameCounter
            }
        } catch (e: Exception) {
            val msg = e.message ?: e.javaClass.simpleName
            logger.error("Render loop error: $msg", e)
        } finally {
            // Schedule next frame in finally so any `return` inside the try
            // (e.g., consumeLatestImageAndBind() returning false on a frame
            // where no new image is ready) still re-posts the loop. Without
            // this, the GL thread stops iterating and the watchdog kills us.
            if (running) {
                glHandler?.post(this::renderLoop)
            }
        }
    }

    private fun maybeAdvanceProbeAfterNoFrames(): Boolean {
        if (!autoProbeCameras || probeComplete || skipFrameValidation || frameCounter >= 15) {
            return false
        }
        val startedAt = lastCameraStartTime
        if (startedAt <= 0) {
            return false
        }
        val elapsedMs = System.currentTimeMillis() - startedAt
        if (elapsedMs < PROBE_NO_FRAME_TIMEOUT_MS) {
            return false
        }

        val currentId = if (cameraIdOverride >= 0) cameraIdOverride else PHYSICAL_CAMERA_ID
        logger.warn(
            "Auto-probe: camera ID " + currentId +
                " surfaceMode=" + cameraSurfaceMode +
                " produced only " + frameCounter + " frames in " + elapsedMs +
                "ms; advancing probe"
        )
        recordValidationSnapshot(
            false,
            "probe_timeout_no_frames",
            "low",
            if (cameraLayout == 1) "unknown" else "low",
            "probe_timeout_no_frames",
            width,
            height,
            frameCounter
        )
        advanceProbeToNext(currentId)
        return true
    }

    private fun summarizeQuadrantVariance(probe8x8: ByteArray?): String {
        // This is diagnostics only. It turns the 8x8 probe into a compact
        // summary so logs and persisted config can explain *why* a frame was
        // classified as low-confidence without storing the raw pixels.
        if (probe8x8 == null || probe8x8.size < 192) {
            return ""
        }
        val qLuma = IntArray(4)
        val qCnt = IntArray(4)
        val qMin = intArrayOf(255, 255, 255, 255)
        val qMax = intArrayOf(0, 0, 0, 0)
        var totalNonBlack = 0
        for (y in 0 until 8) {
            for (x in 0 until 8) {
                val idx = (y * 8 + x) * 3
                val r = probe8x8[idx].toInt() and 0xFF
                val g = probe8x8[idx + 1].toInt() and 0xFF
                val b = probe8x8[idx + 2].toInt() and 0xFF
                val luma = (r + g * 2 + b) / 4
                val q = x / 2
                qLuma[q] += luma
                qCnt[q]++
                if (luma < qMin[q]) qMin[q] = luma
                if (luma > qMax[q]) qMax[q] = luma
                if (luma > 10) totalNonBlack++
            }
        }
        for (q in 0 until 4) {
            if (qCnt[q] > 0) qLuma[q] /= qCnt[q]
        }
        return "Q0=" + qLuma[0] + "/" + (qMax[0] - qMin[0]) +
            " Q1=" + qLuma[1] + "/" + (qMax[1] - qMin[1]) +
            " Q2=" + qLuma[2] + "/" + (qMax[2] - qMin[2]) +
            " Q3=" + qLuma[3] + "/" + (qMax[3] - qMin[3]) +
            " nonBlack=" + totalNonBlack + "/64"
    }

    /**
     * Verifies that the camera is producing a real panoramic strip (4 distinct views)
     * rather than a single camera stretched or AVM bird's-eye view.
     *
     * A real panoramic strip has 4 cameras stitched side by side. Each quadrant shows
     * a different scene. We verify by reading pixel samples from each quadrant and
     * checking that they have significantly different luma values.
     *
     * Uses the downscaler's 8x8 readback. Columns 0-1=Q0, 2-3=Q1, 4-5=Q2, 6-7=Q3.
     */
    private fun verifyPanoramicStrip(probe8x8: ByteArray?): Boolean {
        if (probe8x8 == null || probe8x8.size < 192) return false
        val qLuma = IntArray(4)
        val qCnt = IntArray(4)
        val qMin = intArrayOf(255, 255, 255, 255)
        val qMax = intArrayOf(0, 0, 0, 0)
        var totalNonBlack = 0
        for (y in 0 until 8) {
            for (x in 0 until 8) {
                val idx = (y * 8 + x) * 3
                val r = probe8x8[idx].toInt() and 0xFF
                val g = probe8x8[idx + 1].toInt() and 0xFF
                val b = probe8x8[idx + 2].toInt() and 0xFF
                val luma = (r + g * 2 + b) / 4
                val q = x / 2
                qLuma[q] += luma
                qCnt[q]++
                if (luma < qMin[q]) qMin[q] = luma
                if (luma > qMax[q]) qMax[q] = luma
                if (luma > 10) totalNonBlack++
            }
        }
        for (q in 0 until 4) {
            if (qCnt[q] > 0) qLuma[q] /= qCnt[q]
        }

        // Primary check: luma difference between quadrant pairs.
        // A real panoramic strip has 4 cameras showing different scenes.
        var diffPairs = 0
        for (i in 0 until 4) for (j in i + 1 until 4) if (Math.abs(qLuma[i] - qLuma[j]) > 15) diffPairs++
        var isStrip = diffPairs >= 2

        // Secondary check: if all quadrants have real (non-black) data with internal
        // variance, this is a real camera feed even if the scenes look similar.
        // This handles the common case of a parked car in a garage/at night where
        // all 4 cameras see similar dark scenes (low inter-quadrant difference)
        // but each quadrant still has texture/detail (intra-quadrant variance).
        if (!isStrip && totalNonBlack >= 48) {  // At least 75% of pixels are non-black
            var quadrantsWithVariance = 0
            for (q in 0 until 4) {
                // Each quadrant has internal texture (not a flat solid color)
                if (qMax[q] - qMin[q] >= 3) quadrantsWithVariance++
            }
            // Accept if all quadrants have real data (non-black) and at least 3 have
            // internal variance. This distinguishes a real 4-camera feed from a
            // synthetic AVM bird's-eye view (which would have large inter-quadrant
            // differences) or a single stretched camera (which would have identical
            // min/max patterns across all quadrants).
            if (quadrantsWithVariance >= 3) {
                isStrip = true
                logger.info(
                    "Strip accepted via secondary check: $quadrantsWithVariance quadrants with variance, " +
                        "$totalNonBlack/64 non-black pixels"
                )
            }
        }

        logger.info(
            "Strip check: Q0=" + qLuma[0] + " Q1=" + qLuma[1] + " Q2=" + qLuma[2] + " Q3=" + qLuma[3] +
                " diffPairs=" + diffPairs + " → " + (if (isStrip) "STRIP" else "NOT_STRIP")
        )
        return isStrip
    }

    /**
     * Builds the camera ID order for the surface-mode matrix fallback.
     * The list starts with the best evidence we have, then fills in 0-5.
     */
    private fun buildSurfaceModeProbeCameraIds(): IntArray {
        val ids = LinkedHashSet<Int>()
        if (lastDataCameraId >= 0) {
            ids.add(lastDataCameraId)
        }
        if (probeStartId >= 0) {
            ids.add(probeStartId)
        }
        ids.add(if (cameraIdOverride >= 0) cameraIdOverride else PHYSICAL_CAMERA_ID)
        for (i in 0..MAX_CAMERA_ID) {
            ids.add(i)
        }
        return ids.toIntArray()
    }

    private fun advanceProbeSurfaceModeMatrix(skipId: Int): Boolean {
        if (probeMatrixCameraIds.isEmpty()) {
            probeMatrixCameraIds = buildSurfaceModeProbeCameraIds()
            probeMatrixCameraIndex = 0
        }

        // Sweep one surface mode at a time so we can preserve the same
        // cleanup/settle order across every candidate camera ID.
        while (probeNextSurfaceMode <= 5) {
            while (probeMatrixCameraIndex < probeMatrixCameraIds.size) {
                val tryId = probeMatrixCameraIds[probeMatrixCameraIndex++]
                if (tryId == skipId) {
                    continue
                }

                logger.info("Auto-probe: trying camera ID $tryId [surfaceMode=$probeNextSurfaceMode]")

                cameraIdOverride = tryId
                cameraSurfaceMode = probeNextSurfaceMode
                frameCounter = 0
                lastStatsFrameCount = 0
                lastGlThreadHeartbeat = System.currentTimeMillis()

                recreateCameraSurface()
                lastGlThreadHeartbeat = System.currentTimeMillis()

                try {
                    try {
                        Thread.sleep(500)
                    } catch (ie: InterruptedException) {
                        Thread.currentThread().interrupt()
                    }
                    startCamera()
                    val coord = cameraCoordinator
                    if (coord != null && cameraObj != null) {
                        coord.setupEventCallback(cameraObj)
                    }
                    return true
                } catch (e: Exception) {
                    logger.info("Auto-probe: camera ID $tryId surfaceMode=$probeNextSurfaceMode failed to open: " + e.message)
                    cameraObj = null
                    try {
                        Thread.sleep(500)
                    } catch (ie: InterruptedException) {
                        Thread.currentThread().interrupt()
                    }
                }
            }

            probeMatrixCameraIndex = 0
            probeNextSurfaceMode++
        }

        return false
    }

    private fun advanceProbeToNext(skipId: Int) {
        // Close current camera cleanly
        if (cameraObj != null) {
            try {
                BydCameraCoordinator.closeCamera(cameraObj, cameraSurfaceMode)
            } catch (closeEx: Exception) {
                logger.warn("Error closing camera for probe: " + closeEx.message)
            }
            cameraObj = null
            cameraCoordinator?.resetEventCallbackState()
        }

        // CRITICAL: Let the BYD camera HAL settle between close and next open.
        // Without this delay, rapid camera cycling overwhelms the HAL service
        // and triggers a system watchdog reboot.
        try {
            Thread.sleep(1500)
        } catch (ignored: InterruptedException) {
        }

        var found = false
        if (!probeSurfaceModeMatrixActive) {
            // Probe camera IDs 0-5 with surface mode 0 first.
            while (probeNextCameraId <= MAX_CAMERA_ID) {
                val tryId = probeNextCameraId
                probeNextCameraId++

                // Skip the ID we just tested
                if (tryId == skipId) {
                    continue
                }

                logger.info("Auto-probe: trying camera ID $tryId [${tryId + 1}/${MAX_CAMERA_ID + 1}]")

                cameraIdOverride = tryId
                cameraSurfaceMode = 0  // Surface mode 0 confirmed working
                frameCounter = 0
                lastStatsFrameCount = 0
                lastGlThreadHeartbeat = System.currentTimeMillis()

                // Recreate the ImageReader consumer — HAL won't deliver continuous
                // frames to a surface previously connected to a different camera/mode.
                recreateCameraSurface()
                lastGlThreadHeartbeat = System.currentTimeMillis()

                try {
                    // Brief pause before opening next camera — HAL needs time to release resources
                    try {
                        Thread.sleep(500)
                    } catch (ie: InterruptedException) {
                        Thread.currentThread().interrupt()
                    }

                    startCamera()
                    // Setup event callback (only for AVMCamera path — binder service handles its own events)
                    val coord = cameraCoordinator
                    if (coord != null && cameraObj != null) {
                        coord.setupEventCallback(cameraObj)
                    }
                    found = true
                    break
                } catch (e: Exception) {
                    // Camera ID doesn't exist or can't open — skip to next
                    logger.info("Auto-probe: camera ID $tryId failed to open: " + e.message)
                    cameraObj = null
                    // Delay before trying next combo to avoid HAL overload
                    try {
                        Thread.sleep(500)
                    } catch (ie: InterruptedException) {
                        Thread.currentThread().interrupt()
                    }
                    continue
                }
            }

            if (!found) {
                probeSurfaceModeMatrixActive = true
                probeMatrixCameraIds = buildSurfaceModeProbeCameraIds()
                probeMatrixCameraIndex = 0
                probeNextSurfaceMode = 0
                logger.warn("Auto-probe: ID-only probing exhausted; switching to surface-mode matrix")
                found = advanceProbeSurfaceModeMatrix(skipId)
            }
        } else {
            found = advanceProbeSurfaceModeMatrix(skipId)
        }

        if (!found) {
            // If we found at least one camera with data during probe, switch back to it.
            // This prevents the "probe failed" state from leaving us on a black camera.
            if (lastDataCameraId >= 0 && lastDataCameraId != cameraIdOverride) {
                logger.info("Auto-probe: no verified strip found, falling back to camera ID $lastDataCameraId (last known data source)")
                cameraIdOverride = lastDataCameraId
                cameraSurfaceMode = 0
                frameCounter = 0
                lastStatsFrameCount = 0
                lastGlThreadHeartbeat = System.currentTimeMillis()
                recreateCameraSurface()
                lastGlThreadHeartbeat = System.currentTimeMillis()
                try {
                    Thread.sleep(500)
                    startCamera()
                    val coord = cameraCoordinator
                    if (coord != null && cameraObj != null) {
                        coord.setupEventCallback(cameraObj)
                    }
                } catch (e: Exception) {
                    logger.error("Fallback camera open failed: " + e.message)
                }
                // Persist this as a fallback so next restart doesn't re-probe
                try {
                    val camCfg = JSONObject()
                    camCfg.put("probedCameraId", lastDataCameraId)
                    camCfg.put("probedSurfaceMode", 0)
                    camCfg.put("probedAndValidated", true)
                    camCfg.put("fallbackFromProbe", true)
                    UnifiedConfigManager.updateSection("camera", camCfg)
                    logger.info("Persisted fallback camera ID $lastDataCameraId for next launch")
                } catch (ex: Exception) {
                    logger.warn("Failed to persist fallback camera config: " + ex.message)
                }
            } else {
                logger.error("Auto-probe: exhausted all " + (MAX_CAMERA_ID + 1) + " camera IDs — no working panoramic camera found")
            }
            autoProbeCameras = false
            probeStartId = -1
            lastDataCameraId = -1
            probeSurfaceModeMatrixActive = false
            probeMatrixCameraIds = IntArray(0)
            probeMatrixCameraIndex = 0
            // Ungate consumers even on failure — better to record whatever we have
            // than to stay permanently blocked
            probeComplete = true
            logger.warn("Probe complete (fallback mode) — unblocking consumers")
        }
    }

    /**
     * Starts the watchdog thread that monitors GL thread health.
     *
     * If the GL thread hangs (e.g., eglSwapBuffers blocks), the watchdog
     * will call System.exit(0) to force a process restart, since EGL
     * contexts cannot be recovered from a blocked thread.
     */
    private fun startWatchdog() {
        lastGlThreadHeartbeat = System.currentTimeMillis()
        firstFrameReceived = false

        val thread = Thread({
            while (running) {
                try {
                    Thread.sleep(1000)  // Check every second

                    val now = System.currentTimeMillis()
                    val timeSinceHeartbeat = now - lastGlThreadHeartbeat

                    // Use extended timeout until the first camera frame arrives.
                    // The BYD panoramic camera HAL can take 5-8 seconds to deliver
                    // the first frame after open. During this period the GL thread
                    // is blocked on frameSync.wait(100) which still updates the
                    // heartbeat, but if the HAL is slow to even accept the surface
                    // (e.g., I/O contention from MediaScanner broadcasts), the
                    // heartbeat can stall. Killing the process here just causes a
                    // restart loop that makes things worse.
                    // Also use extended timeout during camera restart — the GL thread
                    // is busy with close/reopen operations and heartbeat updates are
                    // interleaved but may not be frequent enough for the normal timeout.
                    val effectiveTimeout = if (firstFrameReceived && !restartInProgress.get())
                        GL_THREAD_TIMEOUT_MS
                    else
                        GL_THREAD_WARMUP_TIMEOUT_MS

                    if (timeSinceHeartbeat > effectiveTimeout) {
                        logger.error(
                            "CRITICAL: GL thread blocked for " + timeSinceHeartbeat +
                                "ms - forcing process restart" +
                                (if (firstFrameReceived) "" else " (during camera warmup)")
                        )

                        // Try to flush logs before exit
                        try {
                            Thread.sleep(100)
                        } catch (ignored: InterruptedException) {
                        }

                        // Exit code 0 triggers restart loop in DaemonLauncher wrapper.
                        // EGL contexts cannot be recovered from a blocked thread.
                        System.exit(0)
                    }

                    // SOTA: Frame health monitor — detect stalled camera feed
                    // If GL thread is alive but no new frames for FRAME_STALL_THRESHOLD_MS,
                    // the camera HAL may be starved or dead.
                    // Decision is contention-aware: if native app is active, use longer
                    // threshold and require consecutive stalls before yielding.
                    if (!cameraYielded && lastFrameTime > 0 && timeSinceHeartbeat < GL_THREAD_TIMEOUT_MS) {
                        val timeSinceFrame = now - lastFrameTime

                        // Use longer threshold when native app is active — transient
                        // CPU/IO stalls shouldn't trigger a yield that interrupts recording
                        val coord = cameraCoordinator
                        val nativeActive = coord != null && coord.isNativeAppActive()
                        val stallThreshold = if (nativeActive) FRAME_STALL_CONTENTION_THRESHOLD_MS else FRAME_STALL_THRESHOLD_MS

                        if (timeSinceFrame > stallThreshold) {
                            logger.warn("FRAME STALL: No frames for " + timeSinceFrame + "ms" + (if (nativeActive) " (native app active)" else ""))
                            // Reset lastFrameTime to prevent repeated triggers
                            lastFrameTime = now

                            if (coord != null) {
                                if (nativeActive) {
                                    // Contention path: require consecutive stalls before yielding
                                    consecutiveContentionStalls++
                                    if (consecutiveContentionStalls >= CONTENTION_STALL_COUNT_TO_YIELD) {
                                        logger.warn("Consecutive contention stalls: $consecutiveContentionStalls — yielding camera")
                                        consecutiveContentionStalls = 0
                                        coord.onFrameStallDetected()
                                    } else {
                                        logger.info(
                                            "Contention stall $consecutiveContentionStalls/$CONTENTION_STALL_COUNT_TO_YIELD" +
                                                " — waiting for more evidence before yielding"
                                        )
                                    }
                                } else {
                                    // No native app — this is a HAL issue, restart camera
                                    consecutiveContentionStalls = 0
                                    logger.info("Frame stall is HAL issue — restarting camera")
                                    glHandler?.post { restartCameraAfterError() }
                                }
                            } else {
                                // No coordinator — just restart
                                glHandler?.post { restartCameraAfterError() }
                            }
                        } else if (nativeActive && timeSinceFrame < 500) {
                            // Frames are flowing despite native app — reset stall counter
                            consecutiveContentionStalls = 0
                        }
                    }
                } catch (e: InterruptedException) {
                    break
                }
            }
        }, "GL-Watchdog")
        watchdogThread = thread

        thread.isDaemon = true
        thread.start()

        logger.info(
            "GL thread watchdog started (timeout=" + GL_THREAD_TIMEOUT_MS + "ms, " +
                "warmupTimeout=" + GL_THREAD_WARMUP_TIMEOUT_MS + "ms, " +
                "frameStall=" + FRAME_STALL_THRESHOLD_MS + "ms, " +
                "cameraId=" + (if (cameraIdOverride >= 0) cameraIdOverride else PHYSICAL_CAMERA_ID) + ", " +
                "probe=" + (if (autoProbeCameras) "ACTIVE" else "OFF") + ")"
        )
    }
    // Written on the camera frame callback / GL thread, read by the watchdog thread to pick the
    // GL-hang timeout that can force a process restart. Must stay @Volatile (it was `volatile`
    // in the Java original) or the watchdog can read a stale value indefinitely.
    @Volatile private var firstFrameReceived = false

    /**
     * SOTA: Yields the camera to the native BYD AVM app.
     *
     * Called on GL thread when contention is detected (frame stall while native
     * app is active). Finalizes any active recording FIRST to prevent MP4 corruption,
     * then does a clean camera close.
     *
     * The GL render loop continues running but skips frame processing while yielded.
     * Camera is re-acquired when onCloseCamera fires from IBYDCameraService.
     */
    private fun yieldCameraInternal() {
        logger.info("Yielding camera to native AVM app...")

        // CRITICAL: Finalize active recording BEFORE closing camera.
        yieldListener?.let { listener ->
            try {
                listener.onPreYield()
                logger.info("Pre-yield: recording finalized")
            } catch (e: Exception) {
                logger.warn("Pre-yield callback error: " + e.message)
            }
        }

        // Detach streaming components to stop drainer threads
        if (streamScaler != null || streamEncoder != null) {
            clearStreamingComponents()
        }

        // FORTIFY FIX: Stop encoder drainer threads BEFORE closing camera.
        // The drainer thread calls MediaCodec.dequeueOutputBuffer() which internally
        // accesses the camera's ImageReader / HardwareBuffer-backed EGL chain. If we destroy
        // the camera (and its native mutex) while the drainer is mid-dequeue,
        // we get: FORTIFY: pthread_mutex_lock called on a destroyed mutex
        encoder?.stopDrainerForCameraClose()
        streamEncoder?.stopDrainerForCameraClose()

        if (cameraObj != null) {
            BydCameraCoordinator.closeCamera(cameraObj, cameraSurfaceMode)
            cameraObj = null
            cameraCoordinator?.let {
                it.resetEventCallbackState()
                it.notifyPosCloseCamera()
            }
            logger.info("Camera yielded — GL pipeline idle, waiting for onCloseCamera")
        }

        // Restart drainer threads after camera is closed (for pre-record buffer)
        encoder?.restartDrainerAfterCameraClose()
    }

    /**
     * SOTA: Restarts the camera after a HAL error event or frame stall.
     *
     * Called on GL thread. Does a full close→reopen cycle with proper cleanup.
     * This is faster than the watchdog kill+restart because it doesn't require
     * a full process restart — just a camera reopen.
     */
    private fun restartCameraAfterError() {
        // P1 #11: CAS — only one restart can be in flight. If reopenCamera
        // (daemon thread) is already restarting, return without touching the
        // flag so its finally{set(false)} doesn't get clobbered.
        if (!restartInProgress.compareAndSet(false, true)) {
            logger.info("Restart already in progress — skipping restartCameraAfterError")
            return
        }
        logger.info("Restarting camera after error/stall...")

        try {
            // CRITICAL: Finalize active recording BEFORE closing camera.
            yieldListener?.let { listener ->
                try {
                    listener.onPreYield()
                    logger.info("Pre-restart: recording finalized")
                } catch (e: Exception) {
                    logger.warn("Pre-restart callback error: " + e.message)
                }
            }

            // Detach streaming components
            if (streamScaler != null || streamEncoder != null) {
                clearStreamingComponents()
                logger.info("Pre-restart: streaming components detached")
            }

            // FORTIFY FIX: Stop encoder drainer threads BEFORE closing camera.
            encoder?.stopDrainerForCameraClose()
            streamEncoder?.stopDrainerForCameraClose()

            // Close with proper cleanup + notify service
            if (cameraObj != null) {
                BydCameraCoordinator.closeCamera(cameraObj, cameraSurfaceMode)
                cameraObj = null
                cameraCoordinator?.let {
                    it.resetEventCallbackState()
                    it.notifyPosCloseCamera()
                }
            }

            // Brief pause to let HAL settle
            Thread.sleep(500)

            // Update heartbeat so watchdog doesn't kill us during restart
            lastGlThreadHeartbeat = System.currentTimeMillis()

            // CRITICAL: Recreate the ImageReader consumer before reopening camera.
            // The BYD HAL won't deliver continuous frames to a surface that was
            // previously connected to a different camera instance — only the first
            // frame arrives, then the stream freezes. This matches the fix already
            // present in the auto-probe path in renderLoop().
            recreateCameraSurface()

            // Update heartbeat again after surface recreation
            lastGlThreadHeartbeat = System.currentTimeMillis()

            // CRITICAL FIX: Open camera on a separate thread with a timeout.
            // startCamera() calls into the BYD HAL which can block indefinitely
            // if the HAL is in a bad state. Running it on the GL thread causes
            // the watchdog to kill the process (GL heartbeat stops updating).
            // By opening on a worker thread, the GL thread stays alive and the
            // watchdog heartbeat keeps ticking. If the open times out, we let
            // the watchdog handle it on the next stall cycle instead of crash-looping.
            var openSuccess = false
            var openError: Exception? = null
            val cameraOpenThread = Thread({
                try {
                    startCamera()
                    openSuccess = true
                } catch (e: Exception) {
                    openError = e
                }
            }, "CameraReopen")
            cameraOpenThread.start()

            // Wait up to 2 seconds for camera to open, updating heartbeat periodically
            val openStart = System.currentTimeMillis()
            val openTimeout = 2000L
            while (cameraOpenThread.isAlive && (System.currentTimeMillis() - openStart) < openTimeout) {
                Thread.sleep(200)
                lastGlThreadHeartbeat = System.currentTimeMillis()
            }

            if (!openSuccess) {
                if (cameraOpenThread.isAlive) {
                    logger.warn("Camera open timed out after " + openTimeout + "ms — will retry on next stall cycle")
                    // Don't interrupt — let it finish in background, watchdog won't kill us
                    // because heartbeat is still updating
                    return
                }
                openError?.let { throw it }
            }

            // Update heartbeat after successful open
            lastGlThreadHeartbeat = System.currentTimeMillis()

            // Restart encoder drainer now that camera is open again
            encoder?.restartDrainerAfterCameraClose()

            // Re-register event callback
            val coord = cameraCoordinator
            if (coord != null && cameraObj != null) {
                coord.setupEventCallback(cameraObj)
            }

            // Resume recording/surveillance after camera restart
            yieldListener?.let { listener ->
                try {
                    listener.onPostReacquire()
                    logger.info("Post-restart: recording/surveillance resumed")
                } catch (e: Exception) {
                    logger.warn("Post-restart callback error: " + e.message)
                }
            }

            logger.info("Camera restarted successfully after error")
        } catch (e: Exception) {
            logger.error("Camera restart failed: " + e.message)
            // If restart fails, the watchdog will eventually kill the process
            // but at least we won't crash-loop immediately
        } finally {
            restartInProgress.set(false)
        }
    }

    /**
     * Stops the GPU camera pipeline.
     */
    fun stop() {
        logger.info("Stopping GPU camera pipeline...")
        running = false

        // Stop watchdog
        watchdogThread?.let {
            it.interrupt()
            watchdogThread = null
        }

        // FORTIFY FIX: Stop encoder drainer threads BEFORE closing camera
        encoder?.stopDrainerForCameraClose()
        streamEncoder?.stopDrainerForCameraClose()

        // Close camera with proper cleanup + notify service
        if (cameraObj != null) {
            BydCameraCoordinator.closeCamera(cameraObj, cameraSurfaceMode)
            cameraObj = null
            cameraCoordinator?.notifyPosCloseCamera()
        }

        // Unregister from IBYDCameraService AFTER notifying posCloseCamera.
        // Must keep the service proxy alive until the close notification is sent,
        // otherwise the native camera app never receives the "camera released" signal
        // and hangs waiting for it.
        cameraCoordinator?.unregister()

        // Cleanup on GL thread
        glHandler?.post(this::releaseGl)

        // Stop GL thread
        glThread?.let { thread ->
            thread.quitSafely()
            try {
                thread.join(1000)
            } catch (e: InterruptedException) {
                logger.warn("GL thread join interrupted")
            }
            glThread = null
        }

        logger.info("GPU camera pipeline stopped")
    }

    /**
     * Releases and reopens the AVMCamera without tearing down the GL pipeline.
     *
     * During ACC OFF→ON, the daemon holds the camera from surveillance mode.
     * The BYD native camera app starts on ACC ON but can't get frames.
     * Releasing briefly lets the native app grab the primary slot, then we
     * get added as secondary consumer via addPreviewSurface.
     */
    @JvmOverloads
    fun reopenCamera(maxWaitMs: Long = 15000) {
        if (!running) {
            logger.warn("Cannot reopen camera - not running")
            return
        }

        // P1 #11: CAS — only one restart can be in flight. If
        // restartCameraAfterError (GL thread) already owns the flag, return
        // without clobbering its finally{set(false)}.
        if (!restartInProgress.compareAndSet(false, true)) {
            logger.warn("Restart already in progress — skipping reopenCamera")
            return
        }

        logger.info("Reopening AVMCamera...")

        // CRITICAL: Mark restart-in-progress BEFORE touching the camera so the
        // GL watchdog uses GL_THREAD_WARMUP_TIMEOUT_MS (10s) instead of the
        // normal 3s. Without this, the daemon thread's polling sleep + the
        // GL thread briefly blocking on updateTexImage() against a dying HAL
        // is enough to trip the watchdog and force a full process restart on
        // every ACC OFF→ON transition. See log: "GL thread blocked for 3492ms".

        try {
            // Proper cleanup order via BydCameraCoordinator.
            // Null cameraObj BEFORE closeCamera() so the GL renderLoop's
            // `cameraObj == null` short-circuit kicks in immediately
            // and stops calling updateTexImage() on a HAL that's being torn down.
            if (cameraObj != null) {
                val toClose = cameraObj
                cameraObj = null
                BydCameraCoordinator.closeCamera(toClose, cameraSurfaceMode)
                cameraCoordinator?.resetEventCallbackState()
                logger.info("Camera closed (proper cleanup)")
            }

            // Kick the GL heartbeat so the watchdog timer resets at the start of
            // the wait — close+log above can already have spent >1s.
            lastGlThreadHeartbeat = System.currentTimeMillis()

            // registerCameraUser is DISABLED — the event-driven branch below is
            // dead. Kept for reference; do NOT re-enable without re-validating
            // the IBYDCameraUser yield/reacquire path end-to-end.

            // Polling path — the only live path. Wait long enough for the BYD
            // native AVM app to claim the primary camera slot, then reopen as
            // secondary consumer. Sleeps in 500ms chunks so we can refresh the
            // GL watchdog heartbeat — otherwise a long single sleep on this
            // (daemon) thread can race the GL thread mid-updateTexImage and
            // make timeSinceHeartbeat exceed the threshold.
            logger.info("Polling fallback (maxWait=" + maxWaitMs + "ms)")
            val minWaitMs = 3000L
            sleepWithHeartbeat(minWaitMs)

            val coord = cameraCoordinator
            if (coord != null && coord.isRegistered()) {
                val deadline = System.currentTimeMillis() + (maxWaitMs - minWaitMs)
                var nativeAppDetected = false

                while (System.currentTimeMillis() < deadline) {
                    if (coord.checkNativeAppActive()) {
                        nativeAppDetected = true
                        logger.info("Native app claimed camera (polling) — waiting for release")
                        sleepWithHeartbeat(500)
                        break
                    }
                    sleepWithHeartbeat(500)
                }

                if (!nativeAppDetected) {
                    logger.info("Native app not detected after polling — reopening")
                }
            } else {
                val remainingWait = maxWaitMs - minWaitMs
                logger.info("No service available — fixed delay (" + remainingWait + "ms)")
                sleepWithHeartbeat(remainingWait)
            }

            startCamera()

            val coord2 = cameraCoordinator
            if (coord2 != null && cameraObj != null) {
                coord2.setupEventCallback(cameraObj)
            }

            // Reset heartbeat after a successful reopen so the next watchdog
            // tick measures from a known-good baseline.
            lastGlThreadHeartbeat = System.currentTimeMillis()
            logger.info("Camera reopened successfully")
        } catch (e: Exception) {
            logger.error("Failed to reopen camera: " + e.message, e)
            try {
                if (cameraObj == null) {
                    logger.warn("Retry camera open...")
                    startCamera()
                    val coord3 = cameraCoordinator
                    if (coord3 != null && cameraObj != null) {
                        coord3.setupEventCallback(cameraObj)
                    }
                    lastGlThreadHeartbeat = System.currentTimeMillis()
                }
            } catch (e2: Exception) {
                logger.error("Camera retry failed: " + e2.message)
            }
        } finally {
            restartInProgress.set(false)
        }
    }

    /**
     * Sleeps for [totalMs] milliseconds in 250ms chunks, refreshing
     * the GL watchdog heartbeat each chunk. Used while the daemon thread is
     * waiting for the BYD HAL to settle so the watchdog doesn't kill the
     * process during the wait.
     */
    @Throws(InterruptedException::class)
    private fun sleepWithHeartbeat(totalMs: Long) {
        val step = 250L
        var remaining = totalMs
        while (remaining > 0 && running) {
            val chunk = Math.min(step, remaining)
            Thread.sleep(chunk)
            lastGlThreadHeartbeat = System.currentTimeMillis()
            remaining -= chunk
        }
    }

    /**
     * Releases OpenGL resources.
     */
    private fun releaseGl() {
        // Shut down the AI worker FIRST so any in-flight processFrame
        // completes before we tear down the consumers it might still
        // reference. The worker's drain timeout caps this at ~2s.
        aiLaneWorker?.let {
            try {
                it.shutdown()
            } catch (ignored: Throwable) {
            }
            aiLaneWorker = null
        }

        // Release foveated cropper before GL context is destroyed
        foveatedCropper?.let {
            it.release()
            foveatedCropper = null
        }

        // Releases whichever consumer is active.
        releaseCameraConsumer()

        // Tear down the ImageReader callback thread (full shutdown only —
        // recreateCameraSurface keeps it alive across camera re-attach).
        imageReaderThread?.let {
            try {
                it.quitSafely()
            } catch (ignored: Throwable) {
            }
            imageReaderThread = null
            imageReaderHandler = null
        }

        if (cameraTextureId != 0) {
            GlUtil.deleteTexture(cameraTextureId)
            cameraTextureId = 0
        }

        dummySurface?.let {
            eglCore?.destroySurface(it)
            dummySurface = null
        }

        eglCore?.let {
            it.release()
            eglCore = null
        }

        logger.info("OpenGL resources released")
    }

    /**
     * Sets streaming components for parallel GPU path.
     *
     * @param streamScaler GPU stream scaler
     * @param streamEncoder Stream encoder
     */
    fun setStreamingComponents(streamScaler: GpuStreamScaler?, streamEncoder: HardwareEventRecorderGpu?) {
        this.streamScaler = streamScaler
        this.streamEncoder = streamEncoder
    }

    /**
     * Clears streaming components (called when streaming is disabled).
     * This prevents the render loop from trying to use released surfaces.
     */
    fun clearStreamingComponents() {
        this.streamScaler = null
        this.streamEncoder = null
    }

    /**
     * Gets the GL thread handler for posting operations.
     *
     * @return Handler for GL thread
     */
    fun getGlHandler(): Handler? = glHandler

    /**
     * Checks if the camera is running.
     */
    fun isRunning(): Boolean = running

    /**
     * Sets the AVMCamera surface mode for addPreviewSurface().
     * Must be called before start(). Default is 0 (works on Seal).
     * Atto 1 may need mode 1 for processed panoramic output.
     */
    fun setCameraSurfaceMode(mode: Int) {
        this.cameraSurfaceMode = mode
        logger.info("Camera surface mode set to: $mode")
    }

    /**
     * Gets the current camera surface mode.
     */
    fun getCameraSurfaceMode(): Int = cameraSurfaceMode

    /**
     * Gets the active camera ID (the one currently open or selected by probe).
     */
    fun getCameraId(): Int = if (cameraIdOverride >= 0) cameraIdOverride else PHYSICAL_CAMERA_ID

    /**
     * Sets the AVMCamera ID to use.
     * Must be called before start(). Default is 1 (works on Seal).
     * Dolphin/Atto 1 may need ID 0.
     */
    fun setCameraId(id: Int) {
        this.cameraIdOverride = id
        logger.info("Camera ID override set to: $id")
    }

    /**
     * Sets the target frame rate for the binder camera backend.
     * Only effective when binder backend is enabled.
     * Updates the target frame rate. If the camera is already open, also
     * pushes the new rate to the HAL via AvmCameraHelper.setCameraFps so
     * emission rate matches the encoder's KEY_FRAME_RATE without a full
     * camera reopen.
     *
     * @param fps Desired frames per second (range enforced by callers; this
     *            method just stores and applies)
     */
    fun setTargetFps(fps: Int) {
        this.targetFps = fps
        logger.info("Target FPS set to: $fps")
        // Keep the AI-lane GL-hop budget in sync with the new rate.
        sentry?.setCameraTargetFps(fps)
        // If the camera is currently open, push the new rate to the HAL.
        // Returns false on devices where setCameraFps is rejected (e.g., the
        // BYD HAL when isValidCamera gate fails) — we log and continue; the
        // encoder reconfig will still produce the right KEY_FRAME_RATE.
        val cam = cameraObj
        if (cam != null) {
            try {
                val ok = AvmCameraHelper.setCameraFps(cam, fps)
                fpsSetCameraResult = if (ok) "live:setCameraFps($fps)=ok" else "live:setCameraFps($fps)=failed"
            } catch (t: Throwable) {
                fpsSetCameraResult = "live:setCameraFps($fps)=error:" + t.javaClass.simpleName
                logger.warn("Live setCameraFps failed: " + t.message)
            }
        }
    }

    /**
     * Gets the target FPS setting.
     */
    fun getTargetFps(): Int = targetFps

    /**
     * BladeWatch-t1lg.3: `PipelineRateController.RateTarget`. Deliberately NOT
     * [setTargetFps] -- that one reaches the camera HAL and the encoder's
     * KEY_FRAME_RATE; this only throttles how often [AiLaneWorker] accepts a frame for
     * detection. Camera capture rate, the encoder, and the EGL context are untouched. A no-op
     * before `aiLaneWorker` exists (camera not yet open) -- the next rate change after
     * open reapplies it, so this is a missed interval at worst, never a crash.
     */
    fun setDetectionRate(fps: Int) {
        aiLaneWorker?.setDetectionRate(fps)
    }

    /**
     * Enables auto-probe mode: tries camera IDs 0-5 at startup to find
     * the one that produces actual image data. Logs resolution and pixel
     * content for each ID. Auto-selects the first panoramic (5120-wide) camera
     * with non-black frames.
     */
    fun setAutoProbeCameras(enabled: Boolean) {
        this.autoProbeCameras = enabled
        if (enabled) {
            probeComplete = false
            probeStartId = getCameraId()
            probeNextCameraId = 0
            probeNextSurfaceMode = 0
            probeSurfaceModeMatrixActive = false
            probeMatrixCameraIds = IntArray(0)
            probeMatrixCameraIndex = 0
        } else {
            probeSurfaceModeMatrixActive = false
        }
        logger.info("Camera auto-probe: " + (if (enabled) "ENABLED" else "DISABLED"))
    }

    /**
     * When true, skip frame-15/50 validation. Used when user manually set camera ID.
     */
    fun setSkipFrameValidation(skip: Boolean) {
        this.skipFrameValidation = skip
        if (skip) logger.info("Frame validation SKIPPED (manual camera override)")
    }

    fun setManualOverrideActive(manualOverride: Boolean) {
        this.manualOverrideActive = manualOverride
    }

    fun setFallbackFromProbe(fallbackFromProbe: Boolean) {
        this.fallbackFromProbe = fallbackFromProbe
    }

    fun setCameraLayout(layout: Int) {
        this.cameraLayout = layout
    }

    fun setCameraSelectionMetadata(discovery: PanoCameraDiscovery?) {
        if (discovery == null) return
        setCameraLayout(discovery.cameraLayout)
        this.sourceBmmTag = discovery.sourceTag
        this.discoveryMethod = discovery.method
        this.vehicleCamSort = discovery.vehicleCamSort
        logger.info("Camera discovery metadata set: $discovery")
    }

    fun setCameraSelectionMetadata(layout: Int, sourceTag: String?, method: String?, camSort: String?) {
        this.cameraLayout = layout
        this.sourceBmmTag = sourceTag ?: ""
        this.discoveryMethod = method ?: ""
        this.vehicleCamSort = camSort ?: ""
    }

    fun setFirmwareInfo(info: CameraFirmwareInfo?) {
        this.firmwareInfo = info ?: CameraFirmwareInfo.current()
    }

    fun setNativeProbeReport(report: String?, ready: Boolean) {
        this.nativeProbeReport = report ?: ""
        this.nativeProbeReady = ready
    }

    fun setArbitrationMode(arbitrationMode: String?) {
        this.arbitrationMode = if (arbitrationMode.isNullOrEmpty()) "eventCallbackOnly" else arbitrationMode
        cameraCoordinator?.setArbitrationMode(this.arbitrationMode)
    }

    fun setFpsSetMediaCodecResult(result: String?) {
        // Honest boundary: the pipeline does not currently own the encoder
        // MediaCodec, so the diagnostic default is "not_wired" unless a
        // future owner explicitly threads a real codec reference through.
        this.fpsSetMediaCodecResult = if (result.isNullOrEmpty()) "not_wired" else result
    }

    fun setLastCameraEvent(event: String?) {
        this.lastCameraEvent = event ?: ""
    }

    fun setQuadrantVariance(variance: String?) {
        this.quadrantVariance = variance ?: ""
    }

    fun getCameraLayout(): Int = cameraLayout

    fun isManualOverrideActive(): Boolean = manualOverrideActive

    fun isFallbackFromProbe(): Boolean = fallbackFromProbe

    fun getSourceBmmTag(): String = sourceBmmTag

    fun getDiscoveryMethod(): String = discoveryMethod

    fun getVehicleCamSort(): String = vehicleCamSort

    fun getFirmwareInfo(): CameraFirmwareInfo = firmwareInfo

    fun getNativeProbeReport(): String = nativeProbeReport

    fun isNativeProbeReady(): Boolean = nativeProbeReady

    fun getFpsSetCameraResult(): String = fpsSetCameraResult

    fun getFpsSetMediaCodecResult(): String = fpsSetMediaCodecResult

    fun getValidatedAtMs(): Long = validatedAtMs

    fun getValidatedFrameWidth(): Int = validatedFrameWidth

    fun getValidatedFrameHeight(): Int = validatedFrameHeight

    fun getValidationFrameCount(): Int = validationFrameCount

    fun getValidationSignal(): String = validationSignal

    fun getStripConfidence(): String = stripConfidence

    fun getLayoutConfidence(): String = layoutConfidence

    fun getQuadrantVariance(): String = quadrantVariance

    fun getLastValidationFailure(): String = lastValidationFailure

    fun getLastCameraEvent(): String = lastCameraEvent

    fun getArbitrationMode(): String = arbitrationMode

    fun getLastFrameAgeMs(): Long {
        val last = lastFrameTime
        if (last <= 0L) {
            return 0L
        }
        return Math.max(0L, System.currentTimeMillis() - last)
    }

    fun getIrFireCount(): Long = irFireCount

    fun getIrAcquireOkCount(): Long = irAcquireOkCount

    fun getIrAcquireNullCount(): Long = irAcquireNullCount

    fun getIrBindFailCount(): Long = irBindFailCount

    fun recordValidationSnapshot(
        validated: Boolean,
        signal: String?,
        stripConfidence: String?,
        layoutConfidence: String?,
        failureReason: String?,
        frameWidth: Int,
        frameHeight: Int,
        frameCount: Int
    ) {
        if (validated) {
            this.validatedAtMs = System.currentTimeMillis()
            this.validatedFrameWidth = frameWidth
            this.validatedFrameHeight = frameHeight
            this.validationFrameCount = frameCount
        } else {
            this.validatedAtMs = 0L
            this.validatedFrameWidth = 0
            this.validatedFrameHeight = 0
            this.validationFrameCount = 0
        }
        this.validationSignal = signal ?: ""
        this.stripConfidence = stripConfidence ?: ""
        this.layoutConfidence = layoutConfidence ?: ""
        this.lastValidationFailure = failureReason ?: ""
    }

    /**
     * Sets a callback to be notified when auto-probe discovers a working camera.
     * The pipeline can use this to persist the result for faster restarts.
     */
    fun setCameraProbeCallback(callback: CameraProbeCallback?) {
        this.probeCallback = callback
    }

    /**
     * Gets the timestamp of the last frame.
     */
    fun getLastFrameTime(): Long = lastFrameTime

    /**
     * SOTA: Gets the BYD camera coordinator for status queries.
     */
    fun getCameraCoordinator(): BydCameraCoordinator? = cameraCoordinator

    /**
     * SOTA: Sets the yield listener for recording finalization during camera yield.
     * The pipeline registers this to ensure recordings are properly closed before
     * the camera is released, and resumed after re-acquisition.
     */
    fun setCameraYieldListener(listener: CameraYieldListener?) {
        this.yieldListener = listener
    }

    /**
     * SOTA: Returns true if camera is currently yielded to native BYD app.
     */
    fun isCameraYielded(): Boolean = cameraYielded

    /**
     * Gets the total frame count.
     */
    fun getFrameCount(): Int = frameCounter

    /**
     * Returns true when camera probe is complete and frames are valid for consumption.
     * During probe, recording/streaming/AI are gated to prevent encoding BLACK frames.
     */
    fun isProbeComplete(): Boolean = probeComplete

    companion object {
        private const val TAG = "PanoramicCameraGpu"
        private val logger = DaemonLogger.getInstance(TAG)
        private const val PHYSICAL_CAMERA_ID = 1
        private const val MAX_CAMERA_ID = 5     // Probe camera IDs 0-5

        // Camera health monitor — detects stalled frames and triggers recovery
        private const val FRAME_STALL_THRESHOLD_MS = 4000L  // 4 seconds without frames (HAL issue)
        // When native app is active, use a longer threshold to avoid false yields
        // from transient CPU/IO load. The HAL needs time to settle into sharing mode.
        private const val FRAME_STALL_CONTENTION_THRESHOLD_MS = 3000L
        private const val PROBE_NO_FRAME_TIMEOUT_MS = 6000L
        // Require consecutive stalls before yielding — a single stall could be transient
        private const val CONTENTION_STALL_COUNT_TO_YIELD = 2

        private const val GL_THREAD_TIMEOUT_MS = 3000L
        // Extended timeout for initial camera warmup — the BYD panoramic camera HAL
        // can take several seconds to deliver the first frame. During this period the
        // GL thread is legitimately blocked on frameSync.wait(), not deadlocked.
        private const val GL_THREAD_WARMUP_TIMEOUT_MS = 10000L

        // Stats logging (time-based, not frame-based)
        private const val STATS_INTERVAL_MS = 120000L  // Every 2 minutes

        // Per-stage timing window: rolling p50/p95 window across STAGE_TIMING_WINDOW frames.
        private const val STAGE_TIMING_WINDOW = 150 // ~10 s at 15 fps

        // AI readback throttle — frame-counter modulo, NOT wall-clock.
        // Wall-clock throttling is fragile when readback duration approaches the
        // interval: the GL thread spends ~117ms per frame (mosaic+swap+readback),
        // which guarantees `now - lastReadback >= 95ms` on every loop, so 100% of
        // frames trigger readback and the pipeline collapses to ~8 fps.
        // Frame-modulo couples AI rate directly to HAL emission rate. With HAL
        // emitting at ~26 fps (ImageReader path), every 3rd frame is ~8.6 AI fps,
        // matching V2 motion's 10 fps internal cadence. If HAL rate changes, AI
        // rate scales proportionally and the GL thread budget stays balanced.
        private const val AI_READBACK_FRAME_MODULO = 3

        private fun isHardwareBufferBridgeReady(report: String?): Boolean {
            if (report.isNullOrEmpty()) {
                return false
            }
            val requiredTokens = arrayOf(
                "fnsResolved=true",
                "ahbFromHwb=y",
                "EGL_KHR_image_base=y",
                "EGL_ANDROID_get_native_client_buffer=y",
                "EGL_ANDROID_image_native_buffer=y",
                "GL_OES_EGL_image_external=y",
                "currentDisplay=yes"
            )
            for (token in requiredTokens) {
                if (!report.contains(token)) {
                    return false
                }
            }
            return true
        }

        // ── Timing helpers (only called at emission, never per-frame) ──────────

        private fun p50ms(ns: LongArray, filled: Int): Long {
            val copy = ns.copyOf(filled)
            copy.sort()
            return copy[copy.size / 2] / 1_000_000L
        }

        private fun p95ms(ns: LongArray, filled: Int): Long {
            val copy = ns.copyOf(filled)
            copy.sort()
            return copy[(copy.size * 0.95).toInt()] / 1_000_000L
        }

        private fun maxMs(ns: LongArray, filled: Int): Long {
            var max = 0L
            for (i in 0 until filled) if (ns[i] > max) max = ns[i]
            return max / 1_000_000L
        }
    }
}
