package net.bladewatch.app.surveillance

import net.bladewatch.app.BuildConfig
import net.bladewatch.app.ai.AssetContext
import net.bladewatch.app.ai.Detection
import net.bladewatch.app.ai.YoloDetector
import net.bladewatch.app.auth.AuthManager
import net.bladewatch.app.byd.BydDataCollector
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.monitor.AccMonitor
import net.bladewatch.app.notifications.NotificationBus
import net.bladewatch.app.notifications.NotificationEvent
import net.bladewatch.app.notifications.NotificationGate
import net.bladewatch.app.storage.StorageManager

import android.content.Context
import android.content.res.AssetManager
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.os.Handler
import android.os.Process

import org.json.JSONObject

import java.io.File
import java.io.FileOutputStream
import java.net.URLEncoder
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.text.SimpleDateFormat
import java.util.ArrayDeque
import java.util.Collections
import java.util.Date
import java.util.Locale
import java.util.concurrent.CountDownLatch
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReferenceArray

/**
 * SurveillanceEngineGpu - V2 Per-Quadrant Motion Detection Pipeline
 *
 * Uses the V2 native pipeline for per-quadrant 6-stage motion detection
 * with staggered YOLO AI inference on active quadrants.
 */
class SurveillanceEngineGpu {

    // Motion detection buffers
    private var currentFrame: ByteBuffer? = null
    private var lastMotionTime: Long = 0
    private var firstMotionTime: Long = 0  // When sustained motion started (for duration check)

    // Loitering time in ms — derived from user setting (1-10 seconds).
    // THREAT_MEDIUM must persist for this duration before triggering recording.
    // THREAT_HIGH triggers after SUSTAINED_MOTION_BASE_MS (loitering already confirmed by native pipeline).
    private var loiteringTimeMs: Long = 3000  // Default 3 seconds

    private var lastMotionProcessTime: Long = 0

    // Reference to downscaler for buffer recycling
    private var downscaler: GpuDownscaler? = null

    // Reference to mosaic recorder for triggering recording
    private var recorder: GpuMosaicRecorder? = null

    // SIMPLIFIED: Frame-to-frame motion detection
    private var requiredActiveBlocks = 3    // Need 3+ blocks changed to trigger

    // SOTA: Flash Immunity Level (0=OFF, 1=LOW, 2=MEDIUM, 3=HIGH). Backed by [flashImmunityValue]
    // so the public property below can carry the config-sync + log side effect the Java setter had.
    private var flashImmunityValue = 2  // Default: MEDIUM

    /**
     * SOTA: Flash Immunity Level (0=OFF, 1=LOW, 2=MEDIUM, 3=HIGH).
     *
     * Uses edge-based detection to ignore light flashes (headlights, lightning, etc.)
     * while still detecting real object motion.
     *
     * Levels:
     * - 0 = OFF: Legacy pixel differencing, sensitive to flashes
     * - 1 = LOW: Edge-based, some flash filtering
     * - 2 = MEDIUM: Edge-based + brightness normalization (default)
     * - 3 = HIGH: Edge-based + aggressive flash rejection
     */
    var flashImmunity: Int
        get() = flashImmunityValue
        set(level) {
            flashImmunityValue = Math.max(0, Math.min(3, level))
            // Sync with SOTA config
            config.flashImmunity = flashImmunityValue
            val levelNames = arrayOf("OFF", "LOW", "MEDIUM", "HIGH")
            logger.info("Flash immunity set to: " + levelNames[flashImmunityValue] + " (" + flashImmunityValue + ")")
        }

    // SOTA: Unified configuration for motion detection, flash filtering, and distance estimation
    /**
     * The SOTA surveillance configuration (distance preset, flash mode, camera calibration).
     * Assigning re-runs every side effect the Java `setConfig` had: syncing legacy fields,
     * propagating pre-record duration to the encoder, rebuilding the YOLO class filter, and
     * reapplying the V2 pipeline config.
     */
    var config: SurveillanceConfig = createDefaultConfig()
        set(newConfig) {
            field = newConfig

            // Sync legacy fields for backward compatibility
            flashImmunityValue = newConfig.flashImmunity
            requiredActiveBlocks = newConfig.requiredBlocks
            minObjectSize = newConfig.minObjectSize
            aiConfidence = newConfig.aiConfidence
            preRecordMsValue = newConfig.preRecordSeconds * 1000L
            postRecordMsValue = newConfig.postRecordSeconds * 1000L

            // FIX (Bug A): propagate the loaded pre-record duration to the encoder's
            // circular buffer. Without this the encoder retains its hardcoded 5s
            // allocation from init() until the user re-saves the setting, which makes
            // the persisted value look like it was reset.
            val enc = recorder?.getEncoder()
            if (enc != null) {
                try {
                    enc.setPreRecordDuration(newConfig.preRecordSeconds)
                } catch (e: Exception) {
                    logger.warn("Failed to propagate pre-record duration to encoder: " + e.message)
                }
            }

            // Sync loitering time for Java-side sustained motion enforcement
            loiteringTimeMs = newConfig.loiteringTimeSeconds * 1000L

            // Update frame dimensions in config for distance estimation
            newConfig.setResolution(THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT)
            newConfig.isMosaic = true  // We use 2x2 mosaic layout

            // Apply object detection filters from saved config.
            // This rebuilds the classFilter array so YOLO respects detectPerson/detectCar/detectBike.
            setObjectFilters(
                newConfig.minObjectSize, newConfig.aiConfidence,
                newConfig.isDetectPerson, newConfig.isDetectCar, newConfig.isDetectBike
            )

            // Apply V2 pipeline settings from loaded config.
            // Order matters: environment preset sets all defaults, then sensitivity and
            // detection zone override their specific parameters, then loitering and cameras.
            val pv2Config = pipelineV2Config
            val pv2 = pipelineV2
            if (pv2Config != null && pv2 != null) {
                pv2Config.applyEnvironmentPreset(newConfig.environmentPreset)

                // The native pipeline runs once with a single config. To honor
                // per-quadrant overrides we feed the *most-permissive* aggregate
                // (highest sensitivity, widest detection zone) to native, then
                // demote per-quadrant in Java via applyQuadrantOverrides().
                var aggSens = newConfig.sensitivityLevel
                var aggZone = newConfig.detectionZone
                for (q in 0 until 4) {
                    aggSens = Math.max(aggSens, newConfig.getEffectiveSensitivityLevel(q))
                    if ("extended" == newConfig.getEffectiveDetectionZone(q)) {
                        aggZone = "extended"
                    } else if ("normal" == newConfig.getEffectiveDetectionZone(q) && "close" == aggZone) {
                        aggZone = "normal"
                    }
                }
                pv2Config.applySensitivity(aggSens)
                pv2Config.applyDetectionZone(aggZone)
                pv2Config.loiteringFrames = newConfig.loiteringTimeSeconds * 10
                // Apply saved shadow filter mode (after preset, so user override takes precedence)
                pv2Config.shadowFilterMode = newConfig.shadowFilterMode
                val cameras = newConfig.cameraEnabled
                for (i in 0 until 4) {
                    pv2Config.quadrantEnabled[i] = cameras[i]
                }
                pv2.applyConfig(pv2Config)
                logger.info(
                    String.format(
                        "V2 pipeline config applied: env=%s, sens=%d (agg=%d), zone=%s (agg=%s), loiter=%ds, cameras=[%b,%b,%b,%b]",
                        newConfig.environmentPreset, newConfig.sensitivityLevel, aggSens,
                        newConfig.detectionZone, aggZone,
                        newConfig.loiteringTimeSeconds, cameras[0], cameras[1], cameras[2], cameras[3]
                    )
                )
            }

            // Apply filter debug setting
            filterDebugEnabled = newConfig.isFilterDebugLogEnabled

            logger.info("Config applied: $newConfig")
        }

    /**
     * Creates default config with proper resolution for mosaic mode.
     * SOTA: Enables chroma filtering by default to ignore lighting changes.
     */
    private fun createDefaultConfig(): SurveillanceConfig {
        val cfg = SurveillanceConfig(SurveillanceConfig.DistancePreset.MEDIUM, SurveillanceConfig.FlashMode.ADAPTIVE)
        // CRITICAL: Set resolution to match THUMBNAIL dimensions
        cfg.setResolution(THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT)
        cfg.isMosaic = true  // We use 2x2 mosaic layout
        cfg.isUseChroma = true // SOTA: Enable chroma filtering to ignore lighting changes
        return cfg
    }

    // Track active blocks for UI display
    private var lastActiveBlocksCount = 0
    private var lastTemporalBlocksCount = 0  // SOTA: Temporally consistent blocks
    private var lastMotionMinY = 0           // SOTA: Top of motion bounding box
    private var lastMotionMaxY = 0           // SOTA: Bottom of motion bounding box
    private var lastEstimatedDistance = 0f   // SOTA: Estimated distance in meters

    // Pre-record and post-record configuration (configurable via API). Backed fields so
    // the public var properties below can carry the config-sync + encoder-notify side
    // effects the Java setters had.
    private var preRecordMsValue: Long = 5000    // 5 seconds before motion (default)
    private var postRecordMsValue: Long = 10000  // 10 seconds after motion (default)
    private var recordingStopTime: Long = 0  // When to stop recording (motion time + post-record)
    private var lastRecordingStopTime: Long = 0  // When last recording stopped (for cooldown)

    // DETERRENT FLASH SUPPRESSION: After the deterrent fires, suppress new motion triggers
    // for a window that covers the flash sequence + ring buffer flush.
    private var deterrentFiredTime: Long = 0  // Timestamp when deterrent was last dispatched

    // YOLO CONFIRMATION GATE: Track when YOLO last confirmed a real threat object.
    @Volatile private var lastAiConfirmationTimeMs: Long = 0  // When YOLO last found a real object

    // Detection mode
    @Volatile private var useObjectDetection = false
    // FIX (A8/B3): volatile so the AI executor sees writes from the UI thread
    // without a torn read. The lambda still snapshots into a local before use.
    @Volatile private var yoloDetector: YoloDetector? = null
    // FIX (Bug B): retain context references so we can lazily re-init the YOLO detector
    // when the user re-enables object detection after disabling all classes.
    private var yoloContext: Context? = null
    private var yoloAssetManager: AssetManager? = null
    // Guards the one-time deferred YOLO init kicked off at camera first-frame.
    private val yoloInitStarted = AtomicBoolean(false)

    // Object detection filters (SOTA: Quadrant-relative height filter in YoloDetector)
    private var minObjectSize = 0.12f  // 12% of QUADRANT height (~8m for person in 2x2 grid)
    private var aiConfidence = 0.25f  // 25% confidence (lowered for debugging)
    // FIX (Bug B): tri-state semantics for classFilter:
    //   null            -> uninitialised, fall back to "all classes" defaults
    //   length == 0     -> user explicitly disabled all classes; YOLO must be skipped
    //   length >  0     -> only those COCO class IDs are kept
    private var classFilter: IntArray? = null
    // Mirror of "should AI run at all" derived from classFilter; cheaper to read on hot path.
    @Volatile private var aiEnabled = true

    // AI throttling - only run YOLO every 500ms to save CPU
    private var lastAiTimeMs: Long = 0

    // --- SOTA FIX: Persistent Resources (Eliminates GC Stutter) ---
    // Per-thread scratch buffer for cropFromMosaic. Previously a single
    // shared byte[] was racy: the main render thread (processFrame, tracker
    // update) and the aiExecutor thread (baseline seed / lighting refresh /
    // post-suppression refresh) both call cropFromMosaic, and concurrent
    // System.arraycopy into the same buffer can produce torn rows. All
    // call sites that retain the result already defensive-copy, but the
    // arraycopy ITSELF is racy — torn rows feed YOLO garbage. ThreadLocal
    // gives each thread its own scratch with no synchronization overhead.
    private val aiBufferTL = ThreadLocal<ByteArray>()
    // Single Thread Executor: Prevents OS thread creation overhead.
    //    Runs at THREAD_PRIORITY_BACKGROUND so a 200-300ms CPU YOLO inference
    //    can't preempt the camera-frame producer or encoder-feed thread. On
    //    this device's NNAPI-SL stack, ~538 of ~546 model ops fall through to
    //    XNNPACK on CPU even when "NNAPI" is enabled, so YOLO is in practice
    //    a CPU-heavy task and must yield to higher-priority threads.
    private val aiExecutor: ExecutorService = Executors.newSingleThreadExecutor { r ->
        val t = Thread({
            // Drop to Linux nice +10 so a 200-300ms CPU YOLO pass can't
            // preempt the camera/encoder feed. setThreadPriority works
            // regardless of how Java's Thread.priority maps internally.
            try {
                Process.setThreadPriority(Process.THREAD_PRIORITY_BACKGROUND)
            } catch (thr: Throwable) {
                logger.debug("setThreadPriority failed: " + thr.message)
            }
            r.run()
        }, "SentryAiExecutor")
        t.isDaemon = true
        t.priority = Thread.MIN_PRIORITY
        t
    }
    // Atomic Flag for thread safety
    private val isAiRunning = AtomicBoolean(false)
    // --- END SOTA FIX ---

    // State
    @Volatile private var active = false
    private var inActiveMode = false
    private var recording = false

    // V2 Pipeline: Per-quadrant 6-stage motion detection
    private var pipelineV2: MotionPipelineV2? = null
    private var pipelineV2Config: MotionPipelineV2.Config? = null
    // Staggered YOLO: queue of quadrants to run AI on.
    // Bounded + de-duplicating: there are only 4 quadrants, so a bitset-backed
    // ArrayDeque guarantees the queue can never grow past 4 entries no matter
    // how many motion events fire. Without this bound, sustained 4-quadrant
    // motion would pile up dozens of pending inferences (the executor processes
    // at AI_COOLDOWN_MS = 500ms; bursts at 10 FPS add 4 per frame), every one
    // of which holds GPU/DSP cycles when it eventually runs and contributes to
    // the recording stutter. add() is idempotent for already-queued quadrants.
    private val aiQuadrantQueue = ArrayDeque<Int>(4)
    private var aiQuadrantQueueMask = 0  // bit q = quadrant q is in queue
    // P1 #12: lock guards the deque + mask as one unit. Callers come from
    // AiLaneWorker (processFrameV2) and the aiExecutor lambda (heartbeat /
    // post-suppression refresh paths); without this the deque could throw
    // ConcurrentModificationException and mask/deque could decohere.
    private val aiQuadrantQueueLock = Any()

    private fun aiQuadrantQueueAdd(q: Int) {
        if (q < 0 || q >= MotionPipelineV2.NUM_QUADRANTS) return
        val bit = 1 shl q
        synchronized(aiQuadrantQueueLock) {
            if ((aiQuadrantQueueMask and bit) != 0) return  // already queued
            aiQuadrantQueueMask = aiQuadrantQueueMask or bit
            aiQuadrantQueue.addLast(q)
        }
    }

    private fun aiQuadrantQueuePoll(): Int? {
        synchronized(aiQuadrantQueueLock) {
            val q = aiQuadrantQueue.pollFirst()
            if (q != null) aiQuadrantQueueMask = aiQuadrantQueueMask and (1 shl q).inv()
            return q
        }
    }

    private fun aiQuadrantQueueClear() {
        synchronized(aiQuadrantQueueLock) {
            aiQuadrantQueue.clear()
            aiQuadrantQueueMask = 0
        }
    }

    private fun aiQuadrantQueueIsEmpty(): Boolean {
        synchronized(aiQuadrantQueueLock) {
            return aiQuadrantQueue.isEmpty()
        }
    }

    // Foveated AI cropping: high-res 640×640 crop from raw camera strip
    var foveatedCropper: FoveatedCropper? = null
        private set
    private var cameraTextureId = -1  // OES texture for foveated crop
    // GL thread handler — used to dispatch foveated crops back to GL thread
    // because crop() touches GL state (FBO bind, glReadPixels). With the
    // AI lane decoupled to AiLaneWorker, processFrame now runs off the GL
    // thread and cannot directly call cropper.crop() — we must hop to GL.
    private var glHandler: Handler? = null
    // Camera FPS used to size the GL-hop wait budget (one frame + slack).
    // Wired by PanoramicCameraGpu.setCameraTargetFps() at startup and on FPS
    // changes; the cropOnGlThread budget tracks it. 0 until wired — the
    // crop path falls back to a safe minimum so we never time out on cold start.
    @Volatile private var cameraTargetFps = 0
    // Throttle for foveated GL-hop timeout warnings — log at most once per 5s
    // and aggregate the count so a busy GL thread doesn't spam.
    private var lastFoveatedTimeoutLogMs: Long = 0
    private var foveatedTimeoutCount: Long = 0

    // Cross-quadrant object tracker
    private val crossQuadrantTracker = CrossQuadrantTracker()

    // Actor-layer tracker — sits ON TOP of the existing YOLO + cross-quadrant
    // pipeline and emits Actor records carrying proximity / trend / severity for
    // the timeline + thumbnail + notification + UI layers. Does not affect motion
    // detection or recording trigger logic.
    private val actorTracker = ActorTracker()
    // Snapshot of the most recent Actor list, for callers that read state.
    // CopyOnWrite to keep reads lock-free for UI / API threads.
    @Volatile private var lastActors: List<Actor> = emptyList()

    // Thumbnail capture buffer (Block C). Field declared here so the wiring point
    // in runAiOnQuadrant compiles even before Block C lands. Constructed/reset by
    // recording lifecycle handlers.
    private var thumbnailBuffer: ThumbnailBuffer? = null

    // FIX (B1/H-a): recording-generation counter. Bumped whenever a recording
    // ends and Actor/Thumbnail state is reset. The aiExecutor lambda captures
    // the value at scheduling time; on completion, it compares against the
    // current value and drops its writes (lastActors update, ThumbnailBuffer
    // observe, baseline promotion) if the generation has advanced. Without
    // this, a slow YOLO inference scheduled before stopRecording can repopulate
    // state for a recording that has already finished, polluting the next
    // recording's first frames.
    private val recordingGeneration = AtomicLong(0)

    // Heartbeat cooldown: prevent NCC tracker from spamming YOLO on every frame
    // when the template match is failing. Without this, a bad template causes
    // needsYoloHeartbeat=true on every frame, turning YOLO into a continuous
    // 10 FPS detector and destroying the battery savings of decoupled tracking.
    private val lastHeartbeatTimeMs = LongArray(MotionPipelineV2.NUM_QUADRANTS)

    // Filter debug log: ring buffer of recent filter decisions (max 100 entries)
    private val filterLog = arrayOfNulls<String>(FILTER_LOG_CAPACITY)
    private var filterLogIndex = 0
    private var filterLogCount = 0
    private var filterDebugEnabled = false

    // SOTA: Event timeline collector for JSON sidecar files
    private val timelineCollector = EventTimelineCollector()

    // SOTA: Detection baseline for filtering static objects from YOLO output.
    // Maintains a per-quadrant "living memory" of known scene objects so that
    // motion-triggered YOLO detections of parked cars, trash cans, etc. are
    // suppressed — only NEW or MOVED objects trigger recording.
    private val detectionBaseline = DetectionBaseline()
    // Track whether baseline has been seeded (one-time on sentry enable)
    @Volatile private var baselineSeeded = false
    // Track last YOLO detections per quadrant for event-end baseline update.
    // P1 #13: AtomicReferenceArray — written from aiExecutor lambda, read by
    // stopRecording() (recorder drainer thread) and reset by enable() / disable().
    // Plain array slot publication wasn't safe-published across threads. Readers
    // must tolerate null (they already do — null check before deref).
    private val lastYoloDetections = AtomicReferenceArray<List<Detection>?>(MotionPipelineV2.NUM_QUADRANTS)
    // Track which quadrant had the last event (for event-end baseline update)
    private var lastEventQuadrant = -1

    // POST-SUPPRESSION BASELINE REFRESH: When brightness suppression fires (lighting change),
    // queue a baseline refresh for after the scene stabilizes.
    private val framesSinceSuppressionEnded = IntArray(MotionPipelineV2.NUM_QUADRANTS)
    private val suppressionWasActive = BooleanArray(MotionPipelineV2.NUM_QUADRANTS)
    private val baselineRefreshQueued = BooleanArray(MotionPipelineV2.NUM_QUADRANTS)

    // Output directory
    private var eventOutputDir: File? = null
    // volatile: read by main render thread and written by the encoder drainer
    // thread (segment listener at rotation time). Without this, the main
    // thread could observe a stale File reference.
    @Volatile private var currentEventFile: File? = null

    // Stats
    private var frameCount = 0
    private var motionDetections = 0

    // Cached latest mosaic frame for snapshot API (640×480 RGB)
    @Volatile private var latestMosaicFrameValue: ByteArray? = null

    /** The latest cached mosaic frame (640×480 RGB) for the snapshot API, or null if none cached yet. */
    val latestMosaicFrame: ByteArray?
        get() = latestMosaicFrameValue

    /**
     * Initializes the surveillance engine with Context for Java TFLite.
     *
     * @param eventDir Directory for saving event recordings
     * @param downscaler GPU downscaler reference for buffer recycling
     * @param assetManager Android AssetManager (unused, kept for compatibility)
     * @param context Android Context for TFLite initialization
     */
    @JvmOverloads
    fun init(eventDir: File, downscaler: GpuDownscaler?, assetManager: AssetManager? = null, context: Context? = null) {
        this.eventOutputDir = eventDir
        this.downscaler = downscaler
        // Retain for lazy YOLO re-init (Bug B fix path)
        this.yoloContext = context
        this.yoloAssetManager = assetManager
        // Construct thumbnail buffer once; it is reused across recordings (it
        // clears its slots itself at recording-stop).
        if (this.thumbnailBuffer == null) {
            this.thumbnailBuffer = ThumbnailBuffer()
        }

        if (!eventDir.exists()) {
            eventDir.mkdirs()
        }

        // Allocate direct buffer for V2 pipeline JNI
        val frame = ByteBuffer.allocateDirect(FRAME_SIZE)
        frame.order(ByteOrder.nativeOrder())
        currentFrame = frame

        // YOLO/TFLite init is DEFERRED until the camera signals its first frame
        // (see startDeferredYoloInit(), called from PanoramicCameraGpu). TFLite's
        // GPU-delegate kernel compilation (~2-4s) would otherwise contend with the
        // camera's heavy one-time EGL/GL setup running concurrently on the same GPU,
        // serializing in the driver and slowing BOTH. The Context / AssetManager are
        // retained above (yoloContext / yoloAssetManager) for the deferred thread.
        if (context == null && assetManager == null) {
            logger.info("No Context or AssetManager provided - object detection disabled")
        } else {
            logger.info("YOLO init deferred until camera first-frame (avoids GPU setup contention)")
        }

        logger.info("Initialized surveillance engine (buffer=$FRAME_SIZE bytes)")

        // Initialize V2 per-quadrant pipeline
        try {
            val pv2 = MotionPipelineV2()
            if (pv2.init()) {
                pipelineV2 = pv2
                val pv2Cfg = MotionPipelineV2.Config()
                pv2Cfg.applyEnvironmentPreset("outdoor")  // Default preset
                pipelineV2Config = pv2Cfg
                pv2.applyConfig(pv2Cfg)
                logger.info("V2 per-quadrant pipeline initialized")
            } else {
                logger.error("V2 pipeline init failed")
                pipelineV2 = null
            }
        } catch (e: Exception) {
            logger.error("V2 pipeline not available: " + e.message)
            pipelineV2 = null
        }
    }

    /**
     * Sets the mosaic recorder for event recording.
     */
    fun setRecorder(recorder: GpuMosaicRecorder?) {
        this.recorder = recorder
    }

    /**
     * Set the foveated cropper for high-res AI inference.
     * When set, YOLO runs on a 640×640 crop from the raw 5120×960 strip
     * instead of the 320×240 mosaic quadrant. Must be called from GL thread.
     */
    fun setFoveatedCropper(cropper: FoveatedCropper?, textureId: Int) {
        this.foveatedCropper = cropper
        this.cameraTextureId = textureId
        if (cropper != null && cropper.isInitialized()) {
            logger.info("Foveated AI cropping enabled (640×640 from raw strip)")
        }
    }

    /** GL handler for posting foveated crops back to the GL thread.
     *  Required when processFrame runs on AiLaneWorker. */
    fun setGlHandler(glHandler: Handler?) {
        this.glHandler = glHandler
    }

    /** Camera target FPS — sizes the foveated GL-hop wait budget so the
     *  AI lane never times out on a normal-load render frame. */
    fun setCameraTargetFps(fps: Int) {
        if (fps > 0) this.cameraTargetFps = fps
    }

    /**
     * Run foveatedCropper.crop on the GL thread and wait for result. Caller
     * may be on AiLaneWorker — this method bridges back to GL where
     * FBO/glReadPixels calls are valid.
     *
     * Returns null if the crop fails, the GL handler isn't set, or the call
     * times out. Timeout is sized to one full camera frame (1000/targetFps + 50ms
     * slack) so we tolerate the GL thread being mid-render without flooding logs.
     * Caller falls back to the mosaic crop on null.
     */
    private fun cropOnGlThread(quadrant: Int, centroidX: Float, centroidY: Float): ByteArray? {
        val cropper = this.foveatedCropper
        val texId = this.cameraTextureId
        val h = this.glHandler
        if (cropper == null || texId < 0) return null
        // Fast path: if we're already on GL thread (handler == null OR handler's
        // looper == current looper), just call directly.
        if (h == null || h.looper.thread == Thread.currentThread()) {
            return try {
                cropper.crop(texId, quadrant, centroidX, centroidY)
            } catch (t: Throwable) {
                logger.warn("Foveated crop (inline) failed: " + t.message)
                null
            }
        }
        // Slow path: post to GL handler and wait. Budget = one camera frame at
        // the configured target FPS, plus a small slack for the readback itself.
        // At 15 fps that's ~115ms; at 30 fps ~85ms. The previous 50ms cap was
        // smaller than a single frame's render budget which guaranteed timeouts.
        // Floor at 80ms so we don't go shorter than a normal readback even if
        // FPS hasn't been wired yet (cold start before setCameraTargetFps).
        val fps = this.cameraTargetFps
        val timeoutMs = if (fps > 0) Math.max(80L, (1000L / fps) + 50) else 150L
        val result = arrayOfNulls<ByteArray>(1)
        val latch = CountDownLatch(1)
        val posted = h.post {
            try {
                result[0] = cropper.crop(texId, quadrant, centroidX, centroidY)
            } catch (t: Throwable) {
                logger.warn("Foveated crop (GL hop) failed: " + t.message)
            } finally {
                latch.countDown()
            }
        }
        if (!posted) {
            // GL thread shutting down or handler invalid — fall back to mosaic.
            return null
        }
        try {
            if (!latch.await(timeoutMs, TimeUnit.MILLISECONDS)) {
                // Throttle the warn so a busy GL thread doesn't spam logs.
                val now = System.currentTimeMillis()
                if (now - lastFoveatedTimeoutLogMs > 5_000) {
                    lastFoveatedTimeoutLogMs = now
                    foveatedTimeoutCount++
                    logger.info("Foveated crop GL hop timed out (mosaic fallback active; $foveatedTimeoutCount timeouts since start)")
                }
                return null
            }
        } catch (ie: InterruptedException) {
            Thread.currentThread().interrupt()
            return null
        }
        return result[0]
    }

    /**
     * SOTA: Updates the event output directory.
     * Called when storage type changes (internal <-> SD card) to ensure
     * events are saved to the correct location.
     */
    fun setEventOutputDir(eventDir: File?) {
        this.eventOutputDir = eventDir
        if (eventDir != null && !eventDir.exists()) {
            val created = eventDir.mkdirs()
            logger.info("Updated event output directory: " + eventDir.absolutePath + " (created=" + created + ")")
            if (created) {
                eventDir.setReadable(true, false)
                eventDir.setExecutable(true, false)
            }
        } else {
            logger.info("Updated event output directory: " + (eventDir?.absolutePath ?: "null"))
        }
    }

    /**
     * Starts deferred YOLO/TFLite initialization on a background thread.
     *
     * Called by [net.bladewatch.app.camera.PanoramicCameraGpu] once the camera
     * has delivered its first frame — i.e. after the camera's heavy one-time EGL/GL
     * setup (context creation, shader compilation, first-frame warmup) is complete.
     * Deferring to this point means TFLite's GPU-delegate kernel compilation runs
     * during light steady-state rendering instead of contending with the camera setup
     * burst on the same GPU (which serialized in the driver and slowed both).
     *
     * Idempotent: only the first invocation spawns the thread, so it is safe for the
     * camera to call this on every frame.
     */
    fun startDeferredYoloInit() {
        if (!yoloInitStarted.compareAndSet(false, true)) {
            return  // already started
        }
        if (yoloContext == null && yoloAssetManager == null) {
            logger.info("Deferred YOLO init skipped - no Context or AssetManager retained")
            return
        }
        val yoloInitThread = Thread({
            try {
                val ctx: Context = yoloContext ?: run {
                    logger.info("Creating AssetContext for TFLite (daemon mode, deferred)...")
                    AssetContext(yoloAssetManager!!)
                }
                logger.info("Initializing Java TFLite YOLO detector (deferred, post camera first-frame)...")
                val detector = YoloDetector(ctx)
                val yoloLoaded = detector.init()
                if (yoloLoaded) {
                    useObjectDetection = true   // written before volatile publish
                    yoloDetector = detector     // volatile write publishes both fields
                    logger.info("YOLO model loaded successfully - object detection enabled")
                    logger.info("GPU acceleration: " + (if (detector.isGpuEnabled()) "ENABLED" else "disabled (CPU fallback)"))
                } else {
                    logger.warn("YOLO model load failed (deferred) - object detection disabled")
                }
            } catch (e: Throwable) {
                logger.warn("Deferred YOLO init error: " + e.message)
            }
        }, "YoloInit")
        yoloInitThread.isDaemon = true
        yoloInitThread.start()
    }

    /**
     * Processes a frame from the GPU downscaler.
     *
     * This is called at 2 FPS during idle mode. When motion is detected,
     * it can be called at 5 FPS for more responsive AI.
     *
     * CRITICAL: This method receives a BORROWED buffer from the pool.
     * The buffer MUST be recycled in a finally block to prevent pool exhaustion.
     * If async AI is needed, the data must be copied before recycling.
     *
     * @param smallRgbFrame 320x240 RGB frame from GPU (borrowed from pool)
     */
    fun processFrame(smallRgbFrame: ByteArray?) {
        if (!active) {
            // Still need to recycle even if not active
            if (smallRgbFrame != null) downscaler?.recycleBuffer(smallRgbFrame)
            return
        }

        // RACE CONDITION FIX (belt-and-suspenders): If somehow active=true but ACC is ON,
        // auto-disable. This catches the case where enable() raced with ACC ON and the
        // disable path hasn't run yet.
        if (AccMonitor.isAccOn()) {
            logger.warn("processFrame: ACC is ON but surveillance is active — auto-disabling")
            disable()
            if (smallRgbFrame != null) downscaler?.recycleBuffer(smallRgbFrame)
            return
        }

        if (smallRgbFrame == null || smallRgbFrame.size != FRAME_SIZE) {
            logger.warn("Invalid frame size: " + (smallRgbFrame?.size ?: 0))
            if (smallRgbFrame != null) downscaler?.recycleBuffer(smallRgbFrame)
            return
        }

        try {
            frameCount++
            val now = System.currentTimeMillis()

            // Cache latest frame for snapshot API (every 10th frame to reduce copies)
            if (frameCount % 10 == 0) {
                var cache = latestMosaicFrameValue
                if (cache == null || cache.size != smallRgbFrame.size) {
                    cache = ByteArray(smallRgbFrame.size)
                    latestMosaicFrameValue = cache
                }
                System.arraycopy(smallRgbFrame, 0, cache, 0, smallRgbFrame.size)
            }

            // Log frame count every 100 frames to confirm frames are arriving
            if (frameCount % 100 == 0) {
                logger.info("Surveillance frame #$frameCount received")
            }

            // MOTION THROTTLING: Skip frames to achieve 10 FPS (saves 66% CPU)
            if (now - lastMotionProcessTime < MOTION_PROCESS_INTERVAL_MS) {
                return
            }
            lastMotionProcessTime = now

            if (pipelineV2 == null) {
                logger.warn("V2 pipeline not initialized — skipping frame")
                return
            }

            processFrameV2(smallRgbFrame, now)
        } finally {
            // CRITICAL: Always recycle buffer back to pool
            // This MUST happen in finally block to prevent pool exhaustion
            downscaler?.recycleBuffer(smallRgbFrame)
        }
    }

    // Track peak threat level during a motion sequence (reset when sequence ends)
    private var peakThreatDuringSequence = 0

    // Previous frame sample for Java-side motion diff check (independent of native pipeline)
    private var prevFrameSamples: IntArray? = null
    private var prevDenseHash: IntArray? = null

    /**
     * V2 Pipeline: Per-quadrant 6-stage motion detection.
     */
    private fun processFrameV2(smallRgbFrame: ByteArray, now: Long) {
        val frame = currentFrame!!
        // Copy frame data into a direct ByteBuffer for JNI
        frame.clear()
        frame.put(smallRgbFrame)
        frame.flip()

        // DIAGNOSTIC: Every 100 frames, check frame validity and inter-frame diff.
        // Only in debug builds — this is pure development tooling.
        if (BuildConfig.DEBUG && frameCount % 100 == 0) {
            runFrameDiagnostic(smallRgbFrame)
        }

        val pv2 = pipelineV2!!
        // Run V2 pipeline (includes C++ Global Illumination Sync)
        val results = pv2.processFrame(frame, THUMBNAIL_WIDTH, THUMBNAIL_HEIGHT)

        // SOTA: Seed detection baseline once after camera warmup (frame 30 = ~3s at 10 FPS).
        // Runs YOLO on each quadrant to catalog what's already in the scene (parked cars,
        // trash cans, etc.) so future motion-triggered detections can filter them out.
        // Cost: 4 inferences, one-time. Runs on AI executor thread to avoid blocking motion pipeline.
        if (!baselineSeeded && frameCount >= 30 && useObjectDetection && yoloDetector != null) {
            baselineSeeded = true  // Set immediately to prevent re-entry
            val seedFrame = ByteArray(smallRgbFrame.size)
            System.arraycopy(smallRgbFrame, 0, seedFrame, 0, smallRgbFrame.size)
            aiExecutor.execute {
                // FIX (A8/B3): snapshot detector at lambda entry — see runAiOnQuadrant
                // for rationale. Toggling AI off via setObjectFilters between
                // submission and execution would otherwise NPE or crash native TFLite.
                val detectorSnap = yoloDetector
                if (detectorSnap == null || !aiEnabled) {
                    logger.info("Baseline seed skipped (detector closed)")
                    return@execute
                }
                logger.info("Seeding detection baseline (frame 30)...")
                val qW = THUMBNAIL_WIDTH / 2
                val qH = THUMBNAIL_HEIGHT / 2
                for (q in 0 until MotionPipelineV2.NUM_QUADRANTS) {
                    try {
                        val quadCrop = cropFromMosaic(seedFrame, q, qW, qH)
                        val dets = detectorSnap.detect(quadCrop, qW, qH, aiConfidence, true, true, false, true, minObjectSize)
                        detectionBaseline.seedFromDetections(q, dets, qW, qH)
                    } catch (e: Exception) {
                        logger.warn("Baseline seed failed for Q$q: " + e.message)
                    }
                }
                logger.info("Detection baseline seeded for all quadrants")
            }
        }

        // Per-quadrant override post-filter. The native pipeline ran with the
        // aggregate (most-permissive) sensitivity/zone, so each quadrant's
        // result currently reflects the loosest gates. Walk the quadrants and
        // demote any result that wouldn't pass its own effective gates.
        applyQuadrantOverrides(results)

        // Check if any quadrant detected motion at MEDIUM or higher threat.
        var maxThreat = pv2.getMaxThreatLevel()
        var anyMotion = maxThreat >= MotionPipelineV2.THREAT_MEDIUM

        // SOTA: Tracker immunity from brightness suppression (Headlight Sweep Fix).
        // When a car's headlights sweep across the camera, the brightness suppression
        // stage kills ALL motion blocks in that quadrant. If a person is being tracked
        // in that quadrant, the motion sequence timer loses them and the recording
        // stops prematurely. Fix: if any quadrant is brightness-suppressed but the
        // NCC tracker has an active lock on it, keep anyMotion=true so the sequence
        // timer continues. The tracker's pixel-level lock is immune to global
        // brightness changes — it tracks texture, not absolute luminance.
        // FIX: Only person tracks (classId==0) get immunity. Vehicle tracks
        // (motorcycles, cars) should not override brightness suppression.
        if (!anyMotion) {
            for (q in 0 until MotionPipelineV2.NUM_QUADRANTS) {
                if (results[q].brightnessSuppressed) {
                    try {
                        if (trackerHasActiveTrack(q)) {
                            val trackBox = trackerGetTrackBox(q)
                            if (trackBox != null && trackBox[5].toInt() == 0) { // person only
                                anyMotion = true
                                if (maxThreat < MotionPipelineV2.THREAT_MEDIUM) {
                                    maxThreat = MotionPipelineV2.THREAT_MEDIUM
                                }
                                if (frameCount % 50 == 0) {
                                    logger.info(
                                        "Headlight sweep immunity: Q$q [" + MotionPipelineV2.QUADRANT_NAMES[q] +
                                            "] suppressed but tracker holds person lock"
                                    )
                                }
                                break
                            }
                        }
                    } catch (e: Exception) {
                        logger.debug("trackerHasActiveTrack/trackerGetTrackBox Q$q error: " + e.message)
                    }
                }
            }
        }

        // --- Diagnostic: Log per-quadrant pipeline results every time motion is detected ---
        if (anyMotion || filterDebugEnabled) {
            logQuadrantDiagnostics(results, maxThreat)
        }

        // Update legacy tracking variables for compatibility
        if (anyMotion) {
            val bestQ = pv2.getHighestThreatQuadrant()
            if (bestQ >= 0) {
                lastActiveBlocksCount = results[bestQ].activeBlocks
                lastTemporalBlocksCount = results[bestQ].confirmedBlocks
            }
        }

        if (anyMotion) {
            processMotionDetected(smallRgbFrame, now, results, maxThreat)
        } else {
            processNoMotion(now, results)
        }

        // Post-record check: stop recording when no motion for postRecordMs.
        // SOTA: Also check ANY quadrant for activity (not just MEDIUM+ threat).
        // A person standing still near the car produces minimal block changes but
        // is still a valid reason to keep recording. Use a lower threshold:
        // any quadrant with confirmedBlocks > 0 counts as "activity" for post-record.
        if (recording && now >= recordingStopTime && recordingStopTime > 0) {
            handlePostRecordCheck(now, results)
        }

        // SOTA: Update texture tracker on every frame (runs NCC template matching).
        // This is the core of the decoupled tracking — YOLO sleeps, NCC tracks.
        // Also handles YOLO heartbeat: when NCC confidence drops below 0.60 or
        // 3 seconds have elapsed, the tracker requests YOLO re-verification.
        if (recording) {
            updateTexturetrackers(smallRgbFrame, now)
        }

        // Process staggered YOLO queue (one per frame)
        // FIX: Check cooldown BEFORE polling the queue. Previously, poll() consumed
        // the quadrant, then runAiOnQuadrant's internal cooldown check rejected it —
        // permanently vaporizing that quadrant's AI pass.
        if (useObjectDetection && !isAiRunning.get() && !aiQuadrantQueueIsEmpty()) {
            if ((System.currentTimeMillis() - lastAiTimeMs) >= AI_COOLDOWN_MS) {
                val q = aiQuadrantQueuePoll()
                if (q != null) runAiOnQuadrant(smallRgbFrame, q)
            }
        }

        // Periodic stats
        if (frameCount % 500 == 0) {
            logPeriodicStats(smallRgbFrame, results)
        }
    }

    private fun runFrameDiagnostic(smallRgbFrame: ByteArray) {
        // Sample 16 pixels spread across the frame
        val currentSamples = IntArray(16)
        val sampleCoords = arrayOf(
            intArrayOf(60, 80), intArrayOf(60, 240), intArrayOf(60, 400), intArrayOf(60, 560),    // Row 1
            intArrayOf(180, 80), intArrayOf(180, 240), intArrayOf(180, 400), intArrayOf(180, 560), // Row 2
            intArrayOf(300, 80), intArrayOf(300, 240), intArrayOf(300, 400), intArrayOf(300, 560), // Row 3
            intArrayOf(420, 80), intArrayOf(420, 240), intArrayOf(420, 400), intArrayOf(420, 560)  // Row 4
        )
        var allBlack = true
        for (i in 0 until 16) {
            val off = (sampleCoords[i][0] * THUMBNAIL_WIDTH + sampleCoords[i][1]) * 3
            if (off + 2 < smallRgbFrame.size) {
                val r = smallRgbFrame[off].toInt() and 0xFF
                val g = smallRgbFrame[off + 1].toInt() and 0xFF
                val b = smallRgbFrame[off + 2].toInt() and 0xFF
                currentSamples[i] = (r shl 16) or (g shl 8) or b
                if (r > 5 || g > 5 || b > 5) allBlack = false
            }
        }

        // Compare with previous frame samples
        var maxDiff = 0
        var changedSamples = 0
        val prevSamples = prevFrameSamples
        if (prevSamples != null) {
            for (i in 0 until 16) {
                val r1 = (currentSamples[i] shr 16) and 0xFF
                val g1 = (currentSamples[i] shr 8) and 0xFF
                val b1 = currentSamples[i] and 0xFF
                val r2 = (prevSamples[i] shr 16) and 0xFF
                val g2 = (prevSamples[i] shr 8) and 0xFF
                val b2 = prevSamples[i] and 0xFF
                val diff = Math.abs(r1 - r2) + Math.abs(g1 - g2) + Math.abs(b1 - b2)
                if (diff > maxDiff) maxDiff = diff
                if (diff > 10) changedSamples++
            }
        }
        prevFrameSamples = currentSamples

        // Also compute a dense diff: scan every 20th pixel across the full frame
        var denseMaxDiff = 0
        var denseChanged = 0
        var denseSamples = 0
        val prevDense = prevDenseHash
        if (prevDense != null) {
            var y = 0
            while (y < THUMBNAIL_HEIGHT) {
                var x = 0
                while (x < THUMBNAIL_WIDTH) {
                    val off = (y * THUMBNAIL_WIDTH + x) * 3
                    if (off + 2 < smallRgbFrame.size) {
                        val r = smallRgbFrame[off].toInt() and 0xFF
                        val g = smallRgbFrame[off + 1].toInt() and 0xFF
                        val b = smallRgbFrame[off + 2].toInt() and 0xFF
                        val idx = denseSamples
                        if (idx < prevDense.size) {
                            val pr = (prevDense[idx] shr 16) and 0xFF
                            val pg = (prevDense[idx] shr 8) and 0xFF
                            val pb = prevDense[idx] and 0xFF
                            val diff = Math.abs(r - pr) + Math.abs(g - pg) + Math.abs(b - pb)
                            if (diff > denseMaxDiff) denseMaxDiff = diff
                            if (diff > 30) denseChanged++
                        }
                        denseSamples++
                    }
                    x += 20
                }
                y += 20
            }
        }
        // Store dense samples for next comparison
        val totalDense = (THUMBNAIL_HEIGHT / 20) * (THUMBNAIL_WIDTH / 20)
        var denseArr = prevDenseHash
        if (denseArr == null || denseArr.size != totalDense) {
            denseArr = IntArray(totalDense)
            prevDenseHash = denseArr
        }
        var di = 0
        var y = 0
        while (y < THUMBNAIL_HEIGHT) {
            var x = 0
            while (x < THUMBNAIL_WIDTH) {
                val off = (y * THUMBNAIL_WIDTH + x) * 3
                if (off + 2 < smallRgbFrame.size && di < denseArr.size) {
                    val r = smallRgbFrame[off].toInt() and 0xFF
                    val g = smallRgbFrame[off + 1].toInt() and 0xFF
                    val b = smallRgbFrame[off + 2].toInt() and 0xFF
                    denseArr[di++] = (r shl 16) or (g shl 8) or b
                }
                x += 20
            }
            y += 20
        }

        // Log sample pixels from each quadrant center
        val q0 = currentSamples[5]
        val q1 = currentSamples[6]
        val q2 = currentSamples[9]
        val q3 = currentSamples[10]

        logger.info(
            String.format(
                "FRAME_DIAG #%d: %s | sparse: max=%d changed=%d/16 | dense: max=%d changed=%d/%d | Q0=(%d,%d,%d) Q1=(%d,%d,%d) Q2=(%d,%d,%d) Q3=(%d,%d,%d)",
                frameCount,
                if (allBlack) "ALL_BLACK!" else "ok",
                maxDiff, changedSamples,
                denseMaxDiff, denseChanged, denseSamples,
                (q0 shr 16) and 0xFF, (q0 shr 8) and 0xFF, q0 and 0xFF,
                (q1 shr 16) and 0xFF, (q1 shr 8) and 0xFF, q1 and 0xFF,
                (q2 shr 16) and 0xFF, (q2 shr 8) and 0xFF, q2 and 0xFF,
                (q3 shr 16) and 0xFF, (q3 shr 8) and 0xFF, q3 and 0xFF
            )
        )
    }

    private fun logQuadrantDiagnostics(results: Array<MotionPipelineV2.QuadrantResult>, maxThreat: Int) {
        val threatNames = arrayOf("NONE", "LOW(pass)", "MEDIUM(approach)", "HIGH(loiter)")
        for (q in 0 until MotionPipelineV2.NUM_QUADRANTS) {
            val r = results[q]
            if (r.activeBlocks == 0 && !r.brightnessSuppressed) continue

            val qName = MotionPipelineV2.QUADRANT_NAMES[q]

            // Convert centroid block coords to estimated distance in meters
            val estDistM = estimateDistanceFromCentroid(q, r.centroidY)
            val distStr = if (r.componentSize > 0) String.format("~%.1fm", estDistM) else "n/a"

            // Zone cutoff in human terms
            val maxRow = pipelineV2Config?.maxDistanceRow ?: 0
            val zoneCutoffDist = estimateDistanceFromCentroid(q, maxRow.toFloat())
            val zoneStr = config.detectionZone
            val zoneLimitStr = if (maxRow > 0) {
                String.format(
                    "%s(<%s ~%.1fm)", zoneStr,
                    if (maxRow == 4) "close" else if (maxRow == 2) "normal" else "extended", zoneCutoffDist
                )
            } else {
                "$zoneStr(no limit)"
            }

            if (r.brightnessSuppressed) {
                logger.debug(String.format("  [%s] BRIGHTNESS_SUPPRESSED luma=%.0f (light change detected)", qName, r.meanLuma))
            } else if (r.shadowFiltered && !r.motionDetected) {
                logger.debug(String.format("  [%s] SHADOW_FILTERED active=%d (shadow discrimination removed blocks)", qName, r.activeBlocks))
            } else if (r.motionDetected) {
                logger.info(
                    String.format(
                        "  [%s] %s | dist=%s | blocks: active=%d confirmed=%d component=%d | zone=%s",
                        qName, threatNames[r.threatLevel], distStr,
                        r.activeBlocks, r.confirmedBlocks, r.componentSize, zoneLimitStr
                    )
                )
            } else if (r.activeBlocks > 0) {
                // Motion was detected at block level but rejected by later stages
                val minComponentSize = pipelineV2Config?.minComponentSize ?: 1
                val alarmBlockThreshold = pipelineV2Config?.alarmBlockThreshold ?: 2
                val reason = if (r.confirmedBlocks == 0) {
                    "not yet confirmed (need more frames)"
                } else if (r.componentSize < minComponentSize) {
                    String.format("component too small (%d blocks, need %d)", r.componentSize, minComponentSize)
                } else if (maxRow > 0 && r.centroidY < maxRow) {
                    String.format("too far away (%s, zone limit ~%.1fm)", distStr, zoneCutoffDist)
                } else if (r.confirmedBlocks < alarmBlockThreshold) {
                    String.format("below alarm threshold (%d blocks, need %d)", r.confirmedBlocks, alarmBlockThreshold)
                } else {
                    "passing motion (" + threatNames[r.threatLevel] + ", ignored)"
                }
                logger.debug(String.format("  [%s] REJECTED: %s | dist=%s active=%d confirmed=%d", qName, reason, distStr, r.activeBlocks, r.confirmedBlocks))
            }
        }
    }

    private fun processMotionDetected(smallRgbFrame: ByteArray, now: Long, results: Array<MotionPipelineV2.QuadrantResult>, maxThreatIn: Int) {
        var maxThreat = maxThreatIn
        val pv2 = pipelineV2!!
        lastMotionTime = now

        // BladeWatch-t1lg.3: return to full detection rate on this exact call, not the
        // next scheduled tick -- see PipelineRateController's class doc for why that
        // matters (a blind window at the moment something moved is the one failure mode
        // this whole feature must not introduce).
        PipelineRateController.getInstance()?.onMotionDetected()

        // Track peak threat across the entire motion sequence
        if (maxThreat > peakThreatDuringSequence) {
            peakThreatDuringSequence = maxThreat
        }

        // Log motion to timeline — ALWAYS, even before recording starts.
        timelineCollector.onMotionDetected(lastActiveBlocksCount, pv2.getActiveQuadrantMask())

        if (firstMotionTime == 0L) {
            firstMotionTime = now
            peakThreatDuringSequence = maxThreat
            val bestQ = pv2.getHighestThreatQuadrant()
            val bestR = if (bestQ >= 0) results[bestQ] else null
            val estDist = if (bestQ >= 0 && bestR != null) estimateDistanceFromCentroid(bestQ, bestR.centroidY) else -1f
            val threatStr = if (maxThreat >= MotionPipelineV2.THREAT_HIGH) "HIGH(loiter)" else "MEDIUM(approach)"
            val needed = if (maxThreat >= MotionPipelineV2.THREAT_HIGH) SUSTAINED_MOTION_BASE_MS else loiteringTimeMs
            logger.info(
                String.format(
                    "Motion started: %s camera, threat=%s, dist=~%.1fm, need %.1fs sustained...",
                    if (bestQ >= 0) MotionPipelineV2.QUADRANT_NAMES[bestQ] else "?",
                    threatStr, estDist, needed / 1000.0
                )
            )
        }

        val motionDuration = now - firstMotionTime

        // Use peak threat for duration requirement (not just current frame).
        // This prevents a brief MEDIUM→NONE→MEDIUM flicker from resetting the clock.
        val effectiveThreat = peakThreatDuringSequence

        // Determine required sustained motion based on threat level:
        val requiredDuration = if (effectiveThreat >= MotionPipelineV2.THREAT_HIGH) SUSTAINED_MOTION_BASE_MS else loiteringTimeMs

        // --- Diagnostic: Log sustained motion progress ---
        if (motionDuration > 0 && motionDuration < requiredDuration) {
            // Log every second while waiting
            if (motionDuration % 1000 < MOTION_PROCESS_INTERVAL_MS) {
                val threatNames = arrayOf("NONE", "LOW(pass)", "MEDIUM(approach)", "HIGH(loiter)")
                val bestQ = pv2.getHighestThreatQuadrant()
                val bestR = if (bestQ >= 0) results[bestQ] else null
                val estDist = if (bestQ >= 0 && bestR != null) estimateDistanceFromCentroid(bestQ, bestR.centroidY) else -1f
                logger.info(
                    String.format(
                        "Motion building: %.1fs / %.1fs | threat=%s | dist=~%.1fm | loiterSetting=%ds",
                        motionDuration / 1000.0, requiredDuration / 1000.0,
                        threatNames[maxThreat], estDist, (loiteringTimeMs / 1000).toInt()
                    )
                )
            }
        }

        // FIX: Early AI initialization — queue YOLO on active quadrants as soon as
        // motion is detected, not after the loitering timer expires.
        if (useObjectDetection && !isAiRunning.get() && aiQuadrantQueueIsEmpty()) {
            val bestQ = pv2.getHighestThreatQuadrant()
            if (bestQ >= 0) aiQuadrantQueueAdd(bestQ)
            for (q in 0 until MotionPipelineV2.NUM_QUADRANTS) {
                if (q != bestQ && results[q].motionDetected) {
                    aiQuadrantQueueAdd(q)
                }
            }
            // Kick off AI immediately if cooldown allows
            if (!aiQuadrantQueueIsEmpty() && (System.currentTimeMillis() - lastAiTimeMs) >= AI_COOLDOWN_MS) {
                val q = aiQuadrantQueuePoll()
                if (q != null) runAiOnQuadrant(smallRgbFrame, q)
            }
        }

        if (motionDuration >= requiredDuration) {
            inActiveMode = true

            // Filter debug log
            if (filterDebugEnabled) {
                val bestQ = pv2.getHighestThreatQuadrant()
                val qName = if (bestQ >= 0) MotionPipelineV2.QUADRANT_NAMES[bestQ] else "?"
                val threatNames = arrayOf("NONE", "LOW", "MEDIUM", "HIGH")
                val r = if (bestQ >= 0) results[bestQ] else null
                val estDist = if (bestQ >= 0 && r != null) estimateDistanceFromCentroid(bestQ, r.centroidY) else -1f
                addFilterLogEntry(
                    String.format(
                        "[%s] TRIGGER: %s threat=%s dist=~%.1fm active=%d confirmed=%d component=%d sustained=%.1fs",
                        SimpleDateFormat("HH:mm:ss", Locale.US).format(Date(now)),
                        qName, threatNames[maxThreat], estDist,
                        r?.activeBlocks ?: 0, r?.confirmedBlocks ?: 0,
                        r?.componentSize ?: 0, motionDuration / 1000.0
                    )
                )
            }

            if (!recording) {
                triggerRecordingIfConfirmed(smallRgbFrame, now, results, maxThreat, motionDuration, requiredDuration)
            } else {
                // Already recording — extend recording timer on continued motion.
                val newStopTime = now + postRecordMsValue
                if (newStopTime > recordingStopTime) {
                    recordingStopTime = newStopTime
                }

                // Also run YOLO on new quadrants that have motion (even if different from original)
                if (useObjectDetection && !isAiRunning.get()) {
                    for (q in 0 until MotionPipelineV2.NUM_QUADRANTS) {
                        if (results[q].motionDetected && results[q].threatLevel >= MotionPipelineV2.THREAT_MEDIUM) {
                            aiQuadrantQueueAdd(q)  // dedups internally
                        }
                    }
                    // FIX: Check cooldown before consuming queue item
                    if (!aiQuadrantQueueIsEmpty() && (System.currentTimeMillis() - lastAiTimeMs) >= AI_COOLDOWN_MS) {
                        val q = aiQuadrantQueuePoll()
                        if (q != null) runAiOnQuadrant(smallRgbFrame, q)
                    }
                }
            }

            // Staggered YOLO: queue active quadrants for AI detection
            if (useObjectDetection && !isAiRunning.get()) {
                aiQuadrantQueueClear()
                // Add quadrants sorted by threat level (highest first)
                val bestQ = pv2.getHighestThreatQuadrant()
                if (bestQ >= 0) aiQuadrantQueueAdd(bestQ)
                for (q in 0 until MotionPipelineV2.NUM_QUADRANTS) {
                    if (q != bestQ && results[q].motionDetected) {
                        aiQuadrantQueueAdd(q)
                    }
                }
                // FIX: Check cooldown before consuming queue item
                if (!aiQuadrantQueueIsEmpty() && (System.currentTimeMillis() - lastAiTimeMs) >= AI_COOLDOWN_MS) {
                    val q = aiQuadrantQueuePoll()
                    if (q != null) runAiOnQuadrant(smallRgbFrame, q)
                }
            }
        }
    }

    private fun triggerRecordingIfConfirmed(
        smallRgbFrame: ByteArray, now: Long, results: Array<MotionPipelineV2.QuadrantResult>,
        maxThreat: Int, motionDuration: Long, requiredDuration: Long
    ) {
        val pv2 = pipelineV2!!
        val effectiveThreat = peakThreatDuringSequence
        // AI CONFIRMATION GATE: For THREAT_MEDIUM, require YOLO to have confirmed
        // a real object during this motion sequence before committing a recording.
        val deterrentActive = deterrentFiredTime > 0 && (now - deterrentFiredTime) < DETERRENT_SUPPRESSION_MS
        val aiRecentlyConfirmed = lastAiConfirmationTimeMs >= firstMotionTime  // Confirmed during THIS sequence
        val aiAvailable = useObjectDetection && yoloDetector != null
        val timePastRequired = motionDuration - requiredDuration  // How long past the trigger threshold

        // TIMEOUT FALLBACK: Let motion through if YOLO hasn't confirmed in time.
        var brightnessEventDuringSequence = false
        for (q in 0 until MotionPipelineV2.NUM_QUADRANTS) {
            if (suppressionWasActive[q] || results[q].brightnessSuppressed) {
                brightnessEventDuringSequence = true
                break
            }
        }
        val timeoutMs = if (brightnessEventDuringSequence) DETERRENT_SUPPRESSION_MS else 2000L
        val timeoutExpired = timePastRequired > timeoutMs

        var shouldSuppress = false
        if (aiAvailable && !aiRecentlyConfirmed && !timeoutExpired) {
            if (effectiveThreat <= MotionPipelineV2.THREAT_MEDIUM) {
                // MEDIUM: always require AI confirmation (with timeout fallback)
                shouldSuppress = true
            } else if (deterrentActive) {
                // HIGH during deterrent: require AI confirmation (deterrent mimics loitering)
                shouldSuppress = true
            }
        }
        // NO-YOLO DETERRENT FALLBACK
        if (!aiAvailable && deterrentActive && !recording) {
            shouldSuppress = true
            if (frameCount % 50 == 0) {
                logger.debug(
                    String.format(
                        "No-YOLO deterrent guard: suppressing (deterrent %.1fs ago, no AI available)",
                        (now - deterrentFiredTime) / 1000.0
                    )
                )
            }
            firstMotionTime = 0
            peakThreatDuringSequence = 0
        }

        if (shouldSuppress) {
            if (frameCount % 50 == 0) {
                val tNames = arrayOf("NONE", "LOW", "MEDIUM", "HIGH")
                logger.debug(
                    String.format(
                        "AI gate holding: threat=%s, motion=%.1fs, grace=%.1fs remaining, deterrent=%s, brightnessEvent=%s",
                        tNames[effectiveThreat], motionDuration / 1000.0,
                        Math.max(0.0, (timeoutMs - timePastRequired).toDouble()) / 1000.0,
                        if (deterrentActive) "active" else "inactive",
                        if (brightnessEventDuringSequence) "yes" else "no"
                    )
                )
            }
            // Don't reset firstMotionTime — let the timer keep running.
        } else {
            // SOTA: Event stitching — start a new recording immediately.
            motionDetections++
            var bestQ = pv2.getHighestThreatQuadrant()
            // If no quadrant has motion (e.g., tracker held through flash),
            // fall back to the quadrant with an active tracker lock
            if (bestQ < 0) {
                for (tq in 0 until MotionPipelineV2.NUM_QUADRANTS) {
                    try {
                        if (trackerHasActiveTrack(tq)) {
                            bestQ = tq
                            break
                        }
                    } catch (e: Exception) {
                        logger.debug("trackerHasActiveTrack tq=$tq error: " + e.message)
                    }
                }
            }
            val qName = if (bestQ >= 0) MotionPipelineV2.QUADRANT_NAMES[bestQ] else "?"
            val triggerSource = if (pv2.getMaxThreatLevel() >= MotionPipelineV2.THREAT_MEDIUM) "motion" else "tracker"
            val threatNames = arrayOf("NONE", "LOW(pass)", "MEDIUM(approach)", "HIGH(loiter)")
            val bestResult = if (bestQ >= 0) results[bestQ] else null

            // Estimate distance from centroid position
            val estDist = if (bestQ >= 0 && bestResult != null) estimateDistanceFromCentroid(bestQ, bestResult.centroidY) else -1f
            val distStr = if (estDist > 0) String.format("~%.1fm", estDist) else "unknown"

            val detectionZone = config.detectionZone
            val sensitivityLevel = config.sensitivityLevel
            val loiteringSec = config.loiteringTimeSeconds
            val maxRow = pipelineV2Config?.maxDistanceRow ?: 0
            val zoneLimitDist = if (bestQ >= 0) estimateDistanceFromCentroid(bestQ, maxRow.toFloat()) else -1f

            logger.info(
                String.format(
                    ">>> RECORDING TRIGGERED <<<\n" +
                        "  Camera: %s | Threat: %s | Distance: %s | Sustained: %.1fs | Source: %s\n" +
                        "  Blocks: active=%d, confirmed=%d, component=%d\n" +
                        "  Settings: sensitivity=%d, zone=%s (limit %s), loiterTime=%ds\n" +
                        "  Why: threat %s >= MEDIUM ✓, duration %.1fs >= %.1fs ✓, distance %s within zone ✓",
                    qName, threatNames[maxThreat], distStr, motionDuration / 1000.0, triggerSource,
                    bestResult?.activeBlocks ?: 0,
                    bestResult?.confirmedBlocks ?: 0,
                    bestResult?.componentSize ?: 0,
                    sensitivityLevel, detectionZone,
                    if (maxRow > 0) String.format("~%.1fm", zoneLimitDist) else "none",
                    loiteringSec,
                    threatNames[maxThreat], motionDuration / 1000.0, requiredDuration / 1000.0,
                    distStr
                )
            )

            recordingStopTime = now + postRecordMsValue
            startRecording()

            try {
                val videoFilename = currentEventFile?.name
                publishMotionNotification(videoFilename)
            } catch (e: Exception) {
                logger.warn("Failed to send motion notification: " + e.message)
            }
        }
    }

    private fun processNoMotion(now: Long, results: Array<MotionPipelineV2.QuadrantResult>) {
        // No motion detected on this frame (all quadrants below MEDIUM threat).
        // Don't immediately end the sequence — allow gaps up to 2 seconds.
        if (!recording) {
            val timeSinceLastMotion = now - lastMotionTime

            var trackerActive = false
            var anyLowActivity = false
            val aiPending = isAiRunning.get() || !aiQuadrantQueueIsEmpty()
            val aiConfirmedDuringSequence = (firstMotionTime > 0) && (lastAiConfirmationTimeMs >= firstMotionTime)
            for (q in 0 until MotionPipelineV2.NUM_QUADRANTS) {
                try {
                    if (trackerHasActiveTrack(q)) {
                        val trackBox = trackerGetTrackBox(q)
                        if (trackBox != null && trackBox[5].toInt() == 0) { // person only
                            trackerActive = true
                        }
                    }
                } catch (e: Exception) {
                    logger.debug("trackerHasActiveTrack/GetTrackBox Q$q error: " + e.message)
                }
                if (results[q].activeBlocks > 0) anyLowActivity = true
            }
            val gapTolerance = if (trackerActive || anyLowActivity || aiPending || aiConfirmedDuringSequence) 4000L else 2000L

            // DEFERRED TRIGGER
            if (firstMotionTime != 0L && !recording && aiConfirmedDuringSequence) {
                val motionDuration = lastMotionTime - firstMotionTime
                val requiredMs = if (peakThreatDuringSequence >= MotionPipelineV2.THREAT_HIGH) SUSTAINED_MOTION_BASE_MS else loiteringTimeMs
                if (motionDuration >= requiredMs && peakThreatDuringSequence >= MotionPipelineV2.THREAT_MEDIUM) {
                    logger.info(
                        String.format(
                            "DEFERRED TRIGGER: motion=%.1fs >= %.1fs, AI confirmed, triggering from gap phase",
                            motionDuration / 1000.0, requiredMs / 1000.0
                        )
                    )
                    inActiveMode = true
                    motionDetections++
                    recordingStopTime = now + postRecordMsValue
                    startRecording()
                    try {
                        val videoFilename = currentEventFile?.name
                        publishMotionNotification(videoFilename)
                    } catch (e: Exception) {
                        logger.warn("Failed to send motion notification: " + e.message)
                    }
                }
            }

            if (firstMotionTime != 0L && timeSinceLastMotion > gapTolerance) {
                // Motion sequence ended without triggering
                val motionDuration = lastMotionTime - firstMotionTime
                if (motionDuration > 200) {
                    val threatNames = arrayOf("NONE", "LOW(pass)", "MEDIUM(approach)", "HIGH(loiter)")
                    val requiredMs = if (peakThreatDuringSequence >= MotionPipelineV2.THREAT_HIGH) SUSTAINED_MOTION_BASE_MS else loiteringTimeMs
                    logger.info(
                        String.format(
                            "Motion ended WITHOUT trigger: lasted=%.1fs, peakThreat=%s, required=%.1fs, gapTolerance=%.1fs%s",
                            motionDuration / 1000.0, threatNames[peakThreatDuringSequence],
                            requiredMs / 1000.0, gapTolerance / 1000.0,
                            if (trackerActive) " (tracker was active)" else ""
                        )
                    )
                }
                firstMotionTime = 0
                peakThreatDuringSequence = 0
            }
        }
    }

    private fun handlePostRecordCheck(now: Long, results: Array<MotionPipelineV2.QuadrantResult>) {
        // Check if any quadrant has residual activity (even below MEDIUM threat)
        var anyActivity = false
        for (q in 0 until MotionPipelineV2.NUM_QUADRANTS) {
            if (results[q].confirmedBlocks > 0 || results[q].activeBlocks > 0) {
                anyActivity = true
                break
            }
        }

        // SOTA: Also check texture tracker — "Static Foreground Victory".
        var trackerHolding = false
        for (q in 0 until MotionPipelineV2.NUM_QUADRANTS) {
            try {
                if (trackerHasActiveTrack(q)) {
                    val trackBox = trackerGetTrackBox(q)
                    if (trackBox != null && trackBox[5].toInt() == 0) { // class 0 = person only
                        trackerHolding = true
                        break
                    }
                }
            } catch (e: Exception) {
                logger.debug("trackerHasActiveTrack/GetTrackBox Q$q error: " + e.message)
            }
        }

        if (anyActivity || trackerHolding) {
            // Still some activity or tracker holding — extend recording
            recordingStopTime = now + postRecordMsValue
            if (trackerHolding && !anyActivity && frameCount % 100 == 0) {
                logger.info("Post-record extended by texture tracker (no motion, object still present)")
            }
        } else {
            val timeSinceLastMotion = now - lastMotionTime
            if (timeSinceLastMotion >= postRecordMsValue) {
                logger.info(String.format("V2 post-record complete — stopping (no motion for %.1fs)", timeSinceLastMotion / 1000.0))
                stopRecording()
                recordingStopTime = 0
                firstMotionTime = 0
                peakThreatDuringSequence = 0
            }
        }
    }

    private fun updateTexturetrackers(smallRgbFrame: ByteArray, now: Long) {
        for (q in 0 until MotionPipelineV2.NUM_QUADRANTS) {
            try {
                if (trackerHasActiveTrack(q)) {
                    // Feed the quadrant crop to the tracker
                    val qW = THUMBNAIL_WIDTH / 2
                    val qH = THUMBNAIL_HEIGHT / 2
                    val quadCrop = cropFromMosaic(smallRgbFrame, q, qW, qH)
                    trackerUpdate(quadCrop, qW, qH, q, now)

                    // Check if tracker wants YOLO heartbeat (NCC score dropped or timer expired).
                    if (trackerNeedsYoloHeartbeat(q)) {
                        val timeSinceLastHeartbeat = now - lastHeartbeatTimeMs[q]
                        if (timeSinceLastHeartbeat >= HEARTBEAT_COOLDOWN_MS && useObjectDetection && !isAiRunning.get()) {
                            aiQuadrantQueueAdd(q)  // dedups internally
                            lastHeartbeatTimeMs[q] = now
                            logger.info("Tracker heartbeat: waking YOLO for Q$q [" + MotionPipelineV2.QUADRANT_NAMES[q] + "]")
                        }
                    }
                }
            } catch (e: Exception) {
                // Tracker not available — continue without it
            }
        }
    }

    private fun logPeriodicStats(smallRgbFrame: ByteArray, results: Array<MotionPipelineV2.QuadrantResult>) {
        val pv2Config = pipelineV2Config
        val pv2 = pipelineV2
        logger.info(String.format("V2 stats: frames=%d, motions=%d, recording=%b", frameCount, motionDetections, recording))
        // Log per-quadrant status for debugging
        for (q in 0 until MotionPipelineV2.NUM_QUADRANTS) {
            val r = results[q]
            val status = if (r.brightnessSuppressed) "SUPPRESSED" else if (r.motionDetected) "MOTION(t=" + r.threatLevel + ")" else "quiet"
            logger.info(
                String.format(
                    "  Q%d[%s]: %s active=%d confirmed=%d component=%d luma=%.0f",
                    q, MotionPipelineV2.QUADRANT_NAMES[q], status,
                    r.activeBlocks, r.confirmedBlocks, r.componentSize, r.meanLuma
                )
            )
        }

        // SOTA: Auto day/night mode switch based on ambient light.
        var avgLuma = 0f
        var lumaCount = 0
        for (q in 0 until MotionPipelineV2.NUM_QUADRANTS) {
            if (results[q].meanLuma > 0) {
                avgLuma += results[q].meanLuma
                lumaCount++
            }
        }
        if (lumaCount > 0) {
            avgLuma /= lumaCount

            val shouldBeNight = avgLuma < 90.0f
            val currentlyNight = isNightMode

            if (shouldBeNight != currentlyNight && pv2Config != null) {
                // Restore base global params from user's preset
                val preset = config.environmentPreset
                val tempCfg = MotionPipelineV2.Config()
                tempCfg.applyEnvironmentPreset(preset)

                pv2Config.brightnessShiftThreshold = tempCfg.brightnessShiftThreshold
                pv2Config.brightnessSuppressionFrames = tempCfg.brightnessSuppressionFrames
                pv2Config.shadowFilterMode = tempCfg.shadowFilterMode
                pv2Config.chromaRatioTolerance = tempCfg.chromaRatioTolerance
                pv2Config.shadowPixelFraction = tempCfg.shadowPixelFraction
                pv2Config.oscillationThreshold = tempCfg.oscillationThreshold

                if (shouldBeNight) {
                    pv2Config.brightnessShiftThreshold = 0.35f
                    pv2Config.brightnessSuppressionFrames = 8
                    pv2Config.shadowFilterMode = 1  // LIGHT
                    pv2Config.chromaRatioTolerance = 0.25f
                    pv2Config.shadowPixelFraction = 0.7f
                    pv2Config.oscillationThreshold = 4
                    isNightMode = true
                    logger.info(String.format("Auto NIGHT mode (avgLuma=%.0f < 95)", avgLuma))
                } else {
                    isNightMode = false
                    logger.info(String.format("Auto NORMAL mode (avgLuma=%.0f >= 95)", avgLuma))
                }
                pv2?.applyConfig(pv2Config)

                // SOTA: Refresh detection baseline on lighting transition.
                if (baselineSeeded && useObjectDetection && yoloDetector != null) {
                    logger.info("Queuing detection baseline refresh (lighting transition)...")
                    val frameSnapshot = ByteArray(smallRgbFrame.size)
                    System.arraycopy(smallRgbFrame, 0, frameSnapshot, 0, smallRgbFrame.size)
                    aiExecutor.execute {
                        val detectorSnap = yoloDetector
                        if (detectorSnap == null || !aiEnabled) {
                            logger.info("Lighting-transition baseline refresh skipped (detector closed)")
                            return@execute
                        }
                        logger.info("Refreshing detection baseline (lighting transition)...")
                        val qW = THUMBNAIL_WIDTH / 2
                        val qH = THUMBNAIL_HEIGHT / 2
                        for (qr in 0 until MotionPipelineV2.NUM_QUADRANTS) {
                            try {
                                val quadCrop = cropFromMosaic(frameSnapshot, qr, qW, qH)
                                val dets = detectorSnap.detect(quadCrop, qW, qH, aiConfidence, true, true, false, true, minObjectSize)
                                detectionBaseline.refreshQuadrant(qr, dets, qW, qH)
                            } catch (e: Exception) {
                                logger.warn("Baseline refresh failed for Q$qr: " + e.message)
                            }
                        }
                    }
                }
            }
        }

        // Log suppressed quadrants for debug
        if (filterDebugEnabled) {
            for (q in 0 until MotionPipelineV2.NUM_QUADRANTS) {
                if (results[q].brightnessSuppressed) {
                    addFilterLogEntry(
                        String.format(
                            "[%s] SUPPRESSED: %s (brightness shift, luma=%.0f)",
                            SimpleDateFormat("HH:mm:ss", Locale.US).format(Date(System.currentTimeMillis())),
                            MotionPipelineV2.QUADRANT_NAMES[q], results[q].meanLuma
                        )
                    )
                }
            }
        }

        // POST-SUPPRESSION BASELINE REFRESH
        if (baselineSeeded && useObjectDetection && yoloDetector != null) {
            for (q in 0 until MotionPipelineV2.NUM_QUADRANTS) {
                if (results[q].brightnessSuppressed) {
                    // Suppression is active — mark it and reset the stabilization counter
                    suppressionWasActive[q] = true
                    framesSinceSuppressionEnded[q] = 0
                    baselineRefreshQueued[q] = false
                } else if (suppressionWasActive[q]) {
                    // Suppression just ended — start counting stabilization frames
                    framesSinceSuppressionEnded[q]++

                    if (framesSinceSuppressionEnded[q] >= BASELINE_STABILIZATION_FRAMES) {
                        // Scene has stabilized — always clear the flag
                        suppressionWasActive[q] = false

                        if (!baselineRefreshQueued[q] && !recording) {
                            baselineRefreshQueued[q] = true

                            val qToRefresh = q
                            val frameSnapshot = ByteArray(smallRgbFrame.size)
                            System.arraycopy(smallRgbFrame, 0, frameSnapshot, 0, smallRgbFrame.size)

                            aiExecutor.execute {
                                val detectorSnap = yoloDetector
                                if (detectorSnap == null || !aiEnabled) {
                                    logger.debug("Post-suppression baseline refresh skipped (detector closed)")
                                    return@execute
                                }
                                try {
                                    val qW = THUMBNAIL_WIDTH / 2
                                    val qH = THUMBNAIL_HEIGHT / 2
                                    val quadCrop = cropFromMosaic(frameSnapshot, qToRefresh, qW, qH)
                                    val dets = detectorSnap.detect(quadCrop, qW, qH, aiConfidence, true, true, false, true, minObjectSize)
                                    detectionBaseline.refreshQuadrant(qToRefresh, dets, qW, qH)
                                    logger.debug(
                                        "Post-suppression baseline refresh Q" + qToRefresh +
                                            " [" + MotionPipelineV2.QUADRANT_NAMES[qToRefresh] + "]: " + dets.size + " detections"
                                    )
                                } catch (e: Exception) {
                                    logger.warn("Post-suppression baseline refresh failed Q$qToRefresh: " + e.message)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /**
     * Run YOLO on a single quadrant (cropped from the mosaic).
     */
    private fun runAiOnQuadrant(mosaicRgb: ByteArray, quadrant: Int) {
        // FIX (Bug B): respect user's class toggles. Empty classFilter = sentinel for
        // "all classes disabled" — skip YOLO entirely.
        if (!useObjectDetection) return
        val cf = classFilter
        if (!aiEnabled || (cf != null && cf.isEmpty())) return
        if (yoloDetector == null) return
        if (isAiRunning.get()) return

        val now = System.currentTimeMillis()
        if ((now - lastAiTimeMs) < AI_COOLDOWN_MS) return
        lastAiTimeMs = now

        // Determine crop dimensions and data source.
        val qW: Int
        val qH: Int
        val cropData: ByteArray?
        // BladeWatch-4pic: true only for a full mosaic TILE.
        val fromMosaicTile: Boolean

        val motionResult = pipelineV2?.getResults()?.get(quadrant)

        // For heartbeat runs, the person may be stationary (zero motion blocks).
        var heartbeatHasTrackerPos = false
        var trackerCentroidX = 0f
        var trackerCentroidY = 0f
        try {
            val trackBox = trackerGetTrackBox(quadrant)
            if (trackBox != null && trackBox[6] > 0) {  // trackBox[6] = active flag
                trackerCentroidX = (trackBox[0] + trackBox[2] / 2.0f) / 32.0f
                trackerCentroidY = (trackBox[1] + trackBox[3] / 2.0f) / 32.0f
                heartbeatHasTrackerPos = true
            }
        } catch (e: Exception) {
            logger.debug("trackerGetTrackBox Q$quadrant error: " + e.message)
        }

        val cropper = foveatedCropper
        if (cropper != null && cropper.isInitialized() && cameraTextureId >= 0 &&
            ((motionResult != null && motionResult.componentSize > 0) || heartbeatHasTrackerPos)
        ) {
            // Foveated path: 640×640 from raw strip.
            val centroidX = if (motionResult != null && motionResult.componentSize > 0) motionResult.centroidX else trackerCentroidX
            val centroidY = if (motionResult != null && motionResult.componentSize > 0) motionResult.centroidY else trackerCentroidY
            val foveatedRgb = cropOnGlThread(quadrant, centroidX, centroidY)
            if (foveatedRgb != null) {
                qW = FoveatedCropper.CROP_SIZE
                qH = FoveatedCropper.CROP_SIZE
                fromMosaicTile = false   // re-centred sub-window — never dewarped
                cropData = ByteArray(foveatedRgb.size)
                System.arraycopy(foveatedRgb, 0, cropData, 0, foveatedRgb.size)
            } else {
                qW = THUMBNAIL_WIDTH / 2
                qH = THUMBNAIL_HEIGHT / 2
                fromMosaicTile = true    // the fallback IS a tile, so it is dewarpable
                val mosaicShared = cropFromMosaic(mosaicRgb, quadrant, qW, qH)
                cropData = ByteArray(mosaicShared.size)
                System.arraycopy(mosaicShared, 0, cropData, 0, mosaicShared.size)
            }
        } else {
            // Legacy path: 320×240 from mosaic.
            qW = THUMBNAIL_WIDTH / 2
            qH = THUMBNAIL_HEIGHT / 2
            fromMosaicTile = true
            val mosaicShared = cropFromMosaic(mosaicRgb, quadrant, qW, qH)
            cropData = ByteArray(mosaicShared.size)
            System.arraycopy(mosaicShared, 0, cropData, 0, mosaicShared.size)
        }

        isAiRunning.set(true)
        val qIdx = quadrant

        // FIX: Snapshot block confidences on the main thread BEFORE dispatching to aiExecutor.
        val blockConfSnapshot = FloatArray(MotionPipelineV2.TOTAL_BLOCKS)
        val snapshotConfirmedBlocks: Int
        val pv2 = pipelineV2
        if (pv2 != null) {
            val snapResult = pv2.getResults()[qIdx]
            System.arraycopy(snapResult.blockConfidence, 0, blockConfSnapshot, 0, MotionPipelineV2.TOTAL_BLOCKS)
            snapshotConfirmedBlocks = snapResult.confirmedBlocks
        } else {
            snapshotConfirmedBlocks = 0
        }

        val usedFoveated = (qW == FoveatedCropper.CROP_SIZE)

        // Capture whether this YOLO run is a heartbeat verification BEFORE the lambda.
        var heartbeatCheck = false
        try {
            heartbeatCheck = trackerNeedsYoloHeartbeat(quadrant) && trackerHasActiveTrack(quadrant)
        } catch (e: Exception) {
            // Tracker not available
        }
        val isHeartbeatRun = heartbeatCheck

        // FIX (B1/H-a): capture the recording generation NOW.
        val generationAtSchedule = recordingGeneration.get()

        // Capture mosaic quadrant crop for the texture tracker (always 320×240).
        val mosaicQuadCrop: ByteArray?
        run {
            val mqW = THUMBNAIL_WIDTH / 2
            val mqH = THUMBNAIL_HEIGHT / 2
            val tmp = cropFromMosaic(mosaicRgb, quadrant, mqW, mqH)
            mosaicQuadCrop = ByteArray(tmp.size).also { System.arraycopy(tmp, 0, it, 0, tmp.size) }
        }

        aiExecutor.execute {
            runAiInference(
                qIdx, cropData!!, qW, qH, fromMosaicTile, usedFoveated, isHeartbeatRun,
                blockConfSnapshot, snapshotConfirmedBlocks, generationAtSchedule, mosaicQuadCrop
            )
        }
    }

    private fun runAiInference(
        qIdx: Int, cropData: ByteArray, qW: Int, qH: Int, fromMosaicTile: Boolean, usedFoveated: Boolean,
        isHeartbeatRun: Boolean, blockConfSnapshot: FloatArray, snapshotConfirmedBlocks: Int,
        generationAtSchedule: Long, mosaicQuadCrop: ByteArray?
    ) {
        try {
            // FIX (A8/B3): Snapshot the detector reference at lambda entry.
            val detectorSnap = yoloDetector
            if (detectorSnap == null || !aiEnabled) {
                isAiRunning.set(false)
                return
            }

            var detectPerson = true
            var detectCar = true
            var detectBike = true
            val cf = classFilter
            if (cf != null && cf.isNotEmpty()) {
                detectPerson = false; detectCar = false; detectBike = false
                for (cls in cf) {
                    if (cls == 0) detectPerson = true
                    if (cls == 2 || cls == 5 || cls == 7) detectCar = true
                    if (cls == 1 || cls == 3) detectBike = true
                }
            }

            // BladeWatch-4pic: straighten the fisheye ONLY for the detector, and only
            // for a full mosaic tile.
            val dewarped: ByteArray? = if (fromMosaicTile) FisheyeDewarp.dewarpForDetector(cropData, qW, qH, qIdx) else null
            val detectorInput = dewarped ?: cropData

            var detections: List<Detection>? = detectorSnap.detect(
                detectorInput, qW, qH, aiConfidence, detectPerson, detectCar, false, detectBike, minObjectSize
            )

            // Back to ORIGINAL crop space before anything downstream sees the list.
            if (dewarped != null) {
                detections = FisheyeDewarp.mapDetectionsToSource(detections, qW, qH, qIdx)
            }

            // Track how many motion-filtered detections we found
            var motionFilteredCount = 0

            if (detections != null && detections.isNotEmpty()) {
                var motionFiltered = ArrayList<Detection>()
                for (det in detections) {
                    val classId = det.classId

                    // Respect user's class filter settings.
                    if (cf != null && cf.isNotEmpty()) {
                        var classAllowed = false
                        for (allowedCls in cf) {
                            if (classId == allowedCls) {
                                classAllowed = true
                                break
                            }
                        }
                        if (!classAllowed) continue
                    } else {
                        // No filter set — only allow known relevant classes
                        if (classId != 0 && classId != 1 && classId != 2 && classId != 3 && classId != 5 && classId != 7) continue
                    }

                    var passesFilter = false

                    if (isHeartbeatRun && classId == 0) {
                        // Heartbeat + person: bypass spatial filter
                        passesFilter = true
                    } else if (snapshotConfirmedBlocks > 0) {
                        // Normal path: require overlap with active motion blocks
                        val scaleX = if (usedFoveated) (320.0f / FoveatedCropper.CROP_SIZE) else 1.0f
                        val scaleY = if (usedFoveated) (240.0f / FoveatedCropper.CROP_SIZE) else 1.0f
                        val detLeft = (det.x * scaleX).toInt()
                        val detTop = (det.y * scaleY).toInt()
                        val detRight = ((det.x + det.w) * scaleX).toInt()
                        val detBottom = ((det.y + det.h) * scaleY).toInt()

                        for (bi in 0 until MotionPipelineV2.TOTAL_BLOCKS) {
                            if (blockConfSnapshot[bi] < 0.5f) continue

                            val bx = (bi % MotionPipelineV2.GRID_COLS) * 32
                            val by = (bi / MotionPipelineV2.GRID_COLS) * 32
                            val bRight = bx + 32
                            val bBottom = by + 32

                            if (detLeft < bRight && detRight > bx && detTop < bBottom && detBottom > by) {
                                passesFilter = true
                                break
                            }
                        }
                    } else {
                        // No motion data available — keep all detections (fallback)
                        passesFilter = true
                    }

                    if (passesFilter) {
                        motionFiltered.add(det)
                    }
                }

                var relevantCount = motionFiltered.size
                motionFilteredCount = relevantCount

                if (relevantCount > 0) {
                    // SOTA: Record person detections for spatial veto baseline tracking.
                    val qWNorm = if (usedFoveated) FoveatedCropper.CROP_SIZE else (THUMBNAIL_WIDTH / 2)
                    val qHNorm = if (usedFoveated) FoveatedCropper.CROP_SIZE else (THUMBNAIL_HEIGHT / 2)
                    for (det in motionFiltered) {
                        if (det.classId == 0) {  // person
                            detectionBaseline.recordPersonDetection(qIdx, det, qWNorm, qHNorm)
                        }
                    }

                    // SOTA: Filter detections against baseline
                    val baselineFiltered = ArrayList<Detection>()
                    var baselineSuppressed = 0
                    for (det in motionFiltered) {
                        if (det.classId == 0) {
                            // Person — always pass through, never check baseline
                            baselineFiltered.add(det)
                        } else if (detectionBaseline.isInBaseline(det, qIdx, qWNorm, qHNorm)) {
                            // Known static object — suppress
                            baselineSuppressed++
                        } else {
                            // New or moved non-person object — pass through
                            baselineFiltered.add(det)
                        }
                    }

                    if (baselineSuppressed > 0) {
                        logger.info("Baseline filter Q$qIdx: $baselineSuppressed static objects suppressed, " + baselineFiltered.size + " new/moved pass")
                    }

                    // Store last detections for event-end baseline update
                    lastYoloDetections.set(qIdx, ArrayList(motionFiltered))
                    lastEventQuadrant = qIdx

                    // THREAT-LEVEL DECISION MATRIX (AI background subtraction gate)
                    val currentThreat = pipelineV2?.getMaxThreatLevel() ?: MotionPipelineV2.THREAT_MEDIUM
                    if (currentThreat <= MotionPipelineV2.THREAT_MEDIUM && baselineFiltered.isEmpty()) {
                        // THREAT_LOW or MEDIUM + all detections are known static objects → suppress
                        val tNames = arrayOf("NONE", "LOW", "MEDIUM", "HIGH")
                        logger.info("AI gate: " + tNames[currentThreat] + " + no new objects → suppressing for Q" + qIdx)
                        relevantCount = 0
                        motionFilteredCount = 0
                    } else {
                        // Use baseline-filtered detections for downstream processing
                        motionFiltered = baselineFiltered
                        relevantCount = motionFiltered.size
                        motionFilteredCount = relevantCount
                    }
                }

                if (relevantCount > 0) {
                    handleConfirmedDetections(
                        qIdx, motionFiltered, qW, qH, usedFoveated, isHeartbeatRun, generationAtSchedule,
                        mosaicQuadCrop, cropData, detections
                    )
                }
            }

            // TEARDOWN GATE: When YOLO returns 0 objects during a heartbeat,
            // the object has left the scene. Kill the zombie track immediately.
            if (isHeartbeatRun && (detections == null || detections.isEmpty() || motionFilteredCount == 0)) {
                try {
                    if (trackerHasActiveTrack(qIdx)) {
                        trackerDropTrack(qIdx)
                        trackerConfirmHeartbeat(qIdx, System.currentTimeMillis())
                        logger.info("Tracker teardown: YOLO heartbeat found nothing, killed track Q$qIdx [" + MotionPipelineV2.QUADRANT_NAMES[qIdx] + "]")
                    }
                } catch (e: Exception) {
                    logger.debug("trackerDropTrack/ConfirmHeartbeat Q$qIdx error: " + e.message)
                }
            }
        } catch (e: Exception) {
            logger.error("V2 AI detection error (Q$qIdx)", e)
        } finally {
            isAiRunning.set(false)
        }
    }

    private fun handleConfirmedDetections(
        qIdx: Int, motionFiltered: List<Detection>, qW: Int, qH: Int, usedFoveated: Boolean,
        isHeartbeatRun: Boolean, generationAtSchedule: Long, mosaicQuadCrop: ByteArray?,
        cropData: ByteArray?, allDetections: List<Detection>
    ) {
        // YOLO confirmed a real object — update AI confirmation timestamp.
        lastAiConfirmationTimeMs = System.currentTimeMillis()

        var timeSinceMotion = System.currentTimeMillis() - lastMotionTime
        if (timeSinceMotion < 2000) {
            lastMotionTime = System.currentTimeMillis()
            timeSinceMotion = System.currentTimeMillis() - lastMotionTime
        }

        val hasActiveMotion = timeSinceMotion < 2000
        // Always send to timeline
        timelineCollector.onAiDetection(motionFiltered, hasActiveMotion, 1 shl qIdx)

        // Cross-quadrant tracking REQUIRES bboxes in 320×240 quadrant pixel space.
        val cqtDetections: List<Detection>
        if (usedFoveated) {
            val scaleToQuad = 320.0f / FoveatedCropper.CROP_SIZE  // 0.5
            val scaled = ArrayList<Detection>(motionFiltered.size)
            for (det in motionFiltered) {
                scaled.add(
                    Detection(
                        det.classId, det.confidence,
                        (det.x * scaleToQuad).toInt(), (det.y * scaleToQuad).toInt(),
                        (det.w * scaleToQuad).toInt(), (det.h * scaleToQuad).toInt()
                    )
                )
            }
            cqtDetections = scaled
        } else {
            cqtDetections = motionFiltered
        }

        val tracked = crossQuadrantTracker.processDetections(cqtDetections, qIdx)

        // ActorTracker + ThumbnailBuffer want bboxes in cropData's NATIVE coord space.
        val trackableDetections = motionFiltered

        // Build a parallel array of cross-quadrant track IDs.
        val xqTrackIds = IntArray(trackableDetections.size)
        var ti = 0
        while (ti < tracked.size && ti < xqTrackIds.size) {
            xqTrackIds[ti] = tracked[ti].trackId
            ti++
        }

        // Actor layer: convert YOLO detections into persistent Actor records.
        try {
            // FIX (B1/H-a): if stopRecording bumped the generation while we were running,
            // our writes belong to a recording that's already finalised. Skip them.
            if (recordingGeneration.get() != generationAtSchedule) {
                logger.debug("AI lambda completed after recording stop (gen $generationAtSchedule vs " + recordingGeneration.get() + ") — skipping Actor/Thumbnail writes")
            } else {
                val recordingStartWall = if (timelineCollector.isCollecting) timelineCollector.recordingStartTimeMs else 0L
                val actorSnapshot = actorTracker.update(trackableDetections, xqTrackIds, qIdx, qW, qH, recordingStartWall, System.currentTimeMillis())
                lastActors = actorSnapshot
                // Forward to thumbnail buffer so it can capture the peak-severity frame.
                thumbnailBuffer?.let { tb ->
                    if (cropData != null) tb.observe(actorSnapshot, cropData, qW, qH, qIdx)
                }
                // Mid-event baseline promotion
                for (a in actorSnapshot) {
                    if (!a.isStatic) continue
                    if (a.classGroup == Actor.ClassGroup.PERSON || a.classGroup == Actor.ClassGroup.ANIMAL || a.classGroup == Actor.ClassGroup.UNKNOWN) continue
                    val cocoCls = when (a.classGroup) {
                        Actor.ClassGroup.VEHICLE -> 2  // car
                        Actor.ClassGroup.BIKE -> 1     // bicycle
                        else -> continue
                    }
                    // Baseline promotion only on mosaic frames.
                    if (usedFoveated) continue
                    detectionBaseline.promoteStaticActor(qIdx, cocoCls, a.lastBboxX, a.lastBboxY, a.lastBboxW, a.lastBboxH, qW, qH)
                }
            }
        } catch (aEx: Exception) {
            logger.warn("ActorTracker.update failed: " + aEx.message)
        }

        // SOTA: Start/refresh texture tracker on the highest-confidence detection.
        if (trackableDetections.isNotEmpty() && mosaicQuadCrop != null) {
            var best = trackableDetections[0]
            for (d in trackableDetections) {
                if (d.confidence > best.confidence) best = d
            }
            try {
                if (isHeartbeatRun) {
                    // SEMANTIC LOCK
                    val trackBox = trackerGetTrackBox(qIdx)
                    val trackClassId = trackBox?.get(5)?.toInt() ?: -1

                    if (trackClassId >= 0 && best.classId != trackClassId && best.confidence > 0.70f) {
                        logger.info(
                            "Semantic mismatch: track Q" + qIdx + " born as class " + trackClassId +
                                " but YOLO sees class " + best.classId +
                                " @" + String.format("%.0f%%", best.confidence * 100) + " — killing track"
                        )
                        trackerDropTrack(qIdx)
                        trackerConfirmHeartbeat(qIdx, System.currentTimeMillis())
                    } else {
                        // Class matches — refresh the template
                        trackerRefreshTemplate(
                            mosaicQuadCrop, THUMBNAIL_WIDTH / 2, THUMBNAIL_HEIGHT / 2, qIdx,
                            best.x, best.y, best.w, best.h, System.currentTimeMillis()
                        )
                        trackerConfirmHeartbeat(qIdx, System.currentTimeMillis())
                        logger.info("Tracker heartbeat confirmed: refreshed template for Q$qIdx [" + MotionPipelineV2.QUADRANT_NAMES[qIdx] + "]")
                    }
                } else {
                    // First detection: start a new track
                    trackerStartTrack(
                        mosaicQuadCrop, THUMBNAIL_WIDTH / 2, THUMBNAIL_HEIGHT / 2, qIdx, best.classId,
                        best.x, best.y, best.w, best.h, System.currentTimeMillis()
                    )
                }
            } catch (e: Exception) {
                logger.warn("Tracker start/refresh failed: " + e.message)
            }
        }

        val qName = MotionPipelineV2.QUADRANT_NAMES[qIdx]
        val cropMode = if (usedFoveated) "foveated 640×640" else "mosaic 320×240"
        logger.info(
            String.format(
                "V2 AI [%s] (%s): %d objects (motion-filtered from %d), %d tracks",
                qName, cropMode, motionFiltered.size, allDetections.size, crossQuadrantTracker.getActiveTrackCount()
            )
        )
    }

    /**
     * Crop a quadrant from the 640×480 mosaic into the reusable aiBuffer.
     * Legacy path used when foveated cropper is not available.
     */
    private fun cropFromMosaic(mosaicRgb: ByteArray, quadrant: Int, qW: Int, qH: Int): ByteArray {
        val startX = (quadrant % 2) * qW
        val startY = (quadrant / 2) * qH

        val cropSize = qW * qH * BYTES_PER_PIXEL
        var aiBuffer = aiBufferTL.get()
        if (aiBuffer == null || aiBuffer.size != cropSize) {
            aiBuffer = ByteArray(cropSize)
            aiBufferTL.set(aiBuffer)
        }

        for (y in 0 until qH) {
            val srcOffset = ((startY + y) * THUMBNAIL_WIDTH + startX) * BYTES_PER_PIXEL
            val dstOffset = y * qW * BYTES_PER_PIXEL
            System.arraycopy(mosaicRgb, srcOffset, aiBuffer, dstOffset, qW * BYTES_PER_PIXEL)
        }
        return aiBuffer
    }

    /**
     * Gets the last estimated distance to motion.
     */
    fun getLastEstimatedDistance(): Float = lastEstimatedDistance

    /**
     * Snapshot of currently-active Actors. Lock-free read suitable for UI / API
     * threads. May be empty if no detections have been observed yet.
     */
    fun getLastActors(): List<Actor> = lastActors

    /**
     * Re-evaluate each quadrant's result against its effective (possibly
     * overridden) sensitivity / zone gates. The native pipeline already ran
     * with the most-permissive aggregate config, so we only ever demote — we
     * never falsely promote, so this can't synthesize motion that the native
     * stage didn't see.
     */
    private fun applyQuadrantOverrides(results: Array<MotionPipelineV2.QuadrantResult>?) {
        if (results == null) return

        // Fast path: nothing overridden → skip entirely.
        var anyOverride = false
        for (q in 0 until MotionPipelineV2.NUM_QUADRANTS) {
            if (config.getQuadrantSensitivityOverride(q) != null || config.getQuadrantDetectionZoneOverride(q) != null) {
                anyOverride = true
                break
            }
        }
        if (!anyOverride) return

        for (q in 0 until MotionPipelineV2.NUM_QUADRANTS) {
            val r = results[q]
            if (!r.motionDetected) continue

            val effSens = config.getEffectiveSensitivityLevel(q)
            val effZone = config.getEffectiveDetectionZone(q)
            val gates = MotionPipelineV2.Config.gatesForSensitivity(effSens)
            val maxRow = MotionPipelineV2.Config.maxDistanceRowForZone(effZone)

            // Recount confirmed blocks at this quadrant's stricter confidence threshold.
            var confirmedAtThreshold = if (r.blockConfidence != null) {
                var count = 0
                for (i in r.blockConfidence.indices) {
                    if (r.blockConfidence[i] >= gates.confidenceThreshold) count++
                }
                count
            } else {
                r.confirmedBlocks
            }

            val failsAlarm = confirmedAtThreshold < gates.alarmBlockThreshold
            val failsComponent = r.componentSize < gates.minComponentSize
            val failsZone = (maxRow > 0) && (r.centroidY < maxRow)

            if (failsAlarm || failsComponent || failsZone) {
                r.motionDetected = false
                r.threatLevel = MotionPipelineV2.THREAT_NONE
                r.confirmedBlocks = confirmedAtThreshold
                if (filterDebugEnabled) {
                    val reason = if (failsAlarm) "alarm" else if (failsComponent) "component" else "zone"
                    logger.debug(
                        String.format(
                            "  [%s] OVERRIDE_DEMOTED reason=%s sens=%d zone=%s confirmed@%.2f=%d/%d component=%d/%d centroidRow=%.1f/cutoff=%d",
                            MotionPipelineV2.QUADRANT_NAMES[q], reason, effSens, effZone,
                            gates.confidenceThreshold, confirmedAtThreshold, gates.alarmBlockThreshold,
                            r.componentSize, gates.minComponentSize, r.centroidY, maxRow
                        )
                    )
                }
            } else {
                // Pass: update confirmedBlocks to reflect the stricter count
                r.confirmedBlocks = confirmedAtThreshold
            }
        }
    }

    /**
     * Estimate real-world distance from a centroid Y position in block coordinates.
     */
    private fun estimateDistanceFromCentroid(quadrant: Int, centroidBlockY: Float): Float {
        // Convert block Y to pixel Y within the quadrant
        val pixelY = centroidBlockY * GRID_BLOCK_SIZE + (GRID_BLOCK_SIZE / 2.0f)

        // Convert quadrant-local pixel Y to global mosaic Y
        val quadrantOffsetY = if (quadrant >= 2) (THUMBNAIL_HEIGHT / 2) else 0
        val globalY = quadrantOffsetY + pixelY.toInt()

        return config.estimateDistanceForQuadrant(quadrant, globalY)
    }

    /**
     * Gets the last temporal blocks count (blocks with temporal consistency).
     */
    fun getLastTemporalBlocksCount(): Int = lastTemporalBlocksCount

    /**
     * Gets the last motion bounding box Y coordinates.
     * @return int array [minY, maxY] or null if no motion
     */
    fun getLastMotionBounds(): IntArray? {
        if (lastMotionMaxY > lastMotionMinY) {
            return intArrayOf(lastMotionMinY, lastMotionMaxY)
        }
        return null
    }

    /**
     * Sets object detection filters.
     *
     * Also adjusts motion detection sensitivity based on minSize:
     * - Lower minSize (for distant objects) = lower motion sensitivity
     * - Higher minSize (for close objects) = higher motion sensitivity
     */
    fun setObjectFilters(minSize: Float, confidence: Float, detectPerson: Boolean, detectCar: Boolean, detectBike: Boolean) {
        this.minObjectSize = minSize
        this.aiConfidence = confidence

        // Build class filter for YOLO
        val classes = ArrayList<Int>()
        if (detectPerson) classes.add(0)  // COCO: person
        if (detectCar) {
            classes.add(2)  // COCO: car
            classes.add(5)  // COCO: bus
            classes.add(7)  // COCO: truck
        }
        if (detectBike) {
            classes.add(1)  // COCO: bicycle
            classes.add(3)  // COCO: motorcycle
        }

        // FIX (Bug B): empty list now means "user disabled all classes"
        val hadAi = this.aiEnabled
        if (classes.isEmpty()) {
            classFilter = IntArray(0)
            this.aiEnabled = false
        } else {
            classFilter = classes.toIntArray()
            this.aiEnabled = true
        }

        // Unload YOLO when AI is now off; load lazily again on next call when re-enabled.
        if (!aiEnabled && yoloDetector != null) {
            try {
                yoloDetector?.close()
            } catch (e: Exception) {
                logger.warn("YoloDetector close failed: " + e.message)
            }
            yoloDetector = null
            logger.info("YOLO detector closed: all object classes disabled by user")
        } else if (aiEnabled && !hadAi) {
            logger.info("Object detection re-enabled; YOLO will be reloaded on next inference")
        }

        logger.info(
            String.format(
                "Object filters: minSize=%.1f%%, confidence=%.0f%%, aiEnabled=%s, classes=%s",
                minSize * 100, confidence * 100, aiEnabled, classes
            )
        )

        // Lazily reload YOLO if it was previously closed and we now need it again
        if (aiEnabled && yoloDetector == null) {
            reloadYoloDetectorIfPossible()
        }
    }

    /**
     * (Bug B helper) Lazily re-initialise the YOLO detector after a previous unload.
     */
    private fun reloadYoloDetectorIfPossible() {
        if (yoloDetector != null) return
        // Defer during the pre-camera startup window.
        if (!yoloInitStarted.get()) {
            logger.info("YOLO reload requested before camera-ready — deferring to first-frame hook")
            return
        }
        try {
            val ctx = yoloContext
            val am = yoloAssetManager
            val detector = if (ctx != null) {
                YoloDetector(ctx)
            } else if (am != null) {
                YoloDetector(AssetContext(am))
            } else {
                logger.warn("Cannot reload YOLO: no context/assetManager retained")
                return
            }
            val ok = detector.init()
            if (ok) {
                yoloDetector = detector
                useObjectDetection = true
                logger.info("YOLO detector reloaded (object detection re-enabled)")
            } else {
                logger.warn("YOLO reload failed")
                yoloDetector = null
            }
        } catch (e: Exception) {
            logger.warn("YOLO reload threw: " + e.message)
            yoloDetector = null
        }
    }

    /**
     * Fallback hero JPEG: extract a keyframe from the MP4 itself when
     * ThumbnailBuffer didn't capture one.
     */
    private fun writeFallbackHeroFromMp4(mp4File: File?, outFile: File?) {
        if (mp4File == null || outFile == null) return
        if (outFile.exists()) return          // ThumbnailBuffer already wrote one
        if (!mp4File.exists() || mp4File.length() == 0L) return

        var mmr: MediaMetadataRetriever? = null
        try {
            val retriever = MediaMetadataRetriever()
            mmr = retriever
            retriever.setDataSource(mp4File.absolutePath)
            // Sample at ~1s in (or 0 if the clip is shorter) to skip the black frame.
            val dur = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
            var durMs = 0L
            try {
                if (dur != null) durMs = dur.toLong()
            } catch (ignored: Exception) {
            }
            val sampleUs = if (durMs >= 1500) 1_000_000L else Math.max(0L, durMs * 500L)
            var frame = retriever.getFrameAtTime(sampleUs, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
            if (frame == null) {
                frame = retriever.getFrameAtTime(0, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
            }
            if (frame == null) {
                logger.debug("Fallback hero: getFrameAtTime returned null for " + mp4File.name)
                return
            }
            val tmpFile = File(outFile.absolutePath + ".tmp")
            try {
                FileOutputStream(tmpFile).use { fos ->
                    frame.compress(Bitmap.CompressFormat.JPEG, 85, fos)
                    try {
                        fos.fd.sync()
                    } catch (ignored: Throwable) {
                    }
                }
            } finally {
                frame.recycle()
            }
            try {
                tmpFile.setReadable(true, /* ownerOnly= */ false)
            } catch (ignored: Throwable) {
            }
            if (!tmpFile.renameTo(outFile)) {
                outFile.delete()
                if (!tmpFile.renameTo(outFile)) {
                    tmpFile.delete()
                    logger.warn("Fallback hero rename failed for " + outFile.name)
                    return
                }
            }
            logger.info("Fallback hero (from mp4 keyframe): " + outFile.name)
        } catch (t: Throwable) {
            logger.debug("Fallback hero extraction failed for " + mp4File.name + ": " + t.message)
        } finally {
            if (mmr != null) {
                try {
                    mmr.release()
                } catch (ignored: Throwable) {
                }
            }
        }
    }

    /**
     * Initial low-priority notification at the moment recording starts.
     */
    private fun publishMotionNotification(videoFilename: String?) {
        try {
            // Honour the user's per-tier toggle.
            if (!config.isPushNotices) {
                return
            }
            val data = JSONObject()
            val url: String
            if (videoFilename != null && videoFilename.isNotEmpty()) {
                val enc = URLEncoder.encode(videoFilename, "UTF-8")
                data.put("filename", videoFilename)
                data.put("stage", "start")
                url = "/events?filter=sentry&file=$enc"
            } else {
                url = "/events?filter=sentry"
            }

            var camHint: String? = null
            for (a in lastActors) {
                if (a.peakCamera >= 0 && a.peakCamera < MotionPipelineV2.QUADRANT_NAMES.size) {
                    camHint = MotionPipelineV2.QUADRANT_NAMES[a.peakCamera]
                    break
                }
            }
            val title = if (camHint != null) "Motion at $camHint" else "Motion detected"
            val body = "Recording in progress"

            NotificationBus.get().publish(
                NotificationEvent(
                    "surveillance.motion.notice",
                    NotificationEvent.Severity.INFO,
                    title,
                    body,
                    notificationTagFor(videoFilename),
                    url,
                    data
                )
            )
        } catch (t: Throwable) {
            logger.debug("publishMotionNotification (start) failed: " + t.message)
        }
    }

    /**
     * Finalized rich notification fired from stopRecording AFTER the hero JPEG
     * has been written by ThumbnailBuffer.
     */
    private fun publishMotionFinal(videoFilename: String?, heroJpegName: String?) {
        try {
            // Snapshot the current Actor view
            val snap = lastActors
            val peakSev = NotificationGate.maxSeverity(snap)
            if (!NotificationGate.shouldPush(peakSev, config)) {
                logger.debug("publishMotionFinal suppressed by per-tier toggle (sev=$peakSev)")
                return
            }

            var persons = 0
            var vehicles = 0
            var bikes = 0
            var animals = 0
            var closest: Actor.Proximity? = null
            var threat: Actor? = null
            for (a in snap) {
                if (a.isStatic) continue
                when (a.classGroup) {
                    Actor.ClassGroup.PERSON -> persons++
                    Actor.ClassGroup.VEHICLE -> vehicles++
                    Actor.ClassGroup.BIKE -> bikes++
                    Actor.ClassGroup.ANIMAL -> animals++
                    else -> {}
                }
                if (closest == null || a.peakProximity.ordinal < closest.ordinal) {
                    closest = a.peakProximity
                }
                if (threat == null ||
                    a.peakSeverity.ordinal > threat.peakSeverity.ordinal ||
                    (a.peakSeverity == threat.peakSeverity && classRank(a.classGroup) > classRank(threat.classGroup))
                ) {
                    threat = a
                }
            }
            val camHint = cameraNameFor(threat)

            // ---- Title (severity tier + threat class + camera) ----
            val title: String
            if (threat == null) {
                title = if (camHint != null) "Motion at $camHint" else "Motion detected"
            } else {
                val sb = StringBuilder()
                if (peakSev == Actor.Severity.CRITICAL) sb.append("CRITICAL · ")
                else if (peakSev == Actor.Severity.ALERT) sb.append("Alert · ")
                var label = Actor.groupLabel(threat.classGroup)
                if (label.isNotEmpty()) {
                    label = label[0].uppercaseChar() + label.substring(1)
                }
                sb.append(label)
                if (camHint != null) sb.append(" at ").append(camHint)
                title = sb.toString()
            }

            // ---- Body (proximity phrase + counts when relevant) ----
            val body: String
            val totalActors = persons + vehicles + bikes + animals
            val hasHero = !heroJpegName.isNullOrEmpty()
            if (threat == null) {
                body = "Recording in progress"
            } else {
                val sb = StringBuilder()
                if (closest != null && closest != Actor.Proximity.UNKNOWN) {
                    sb.append(proximityPhrase(closest))
                }
                if (totalActors > 1) {
                    if (sb.isNotEmpty()) sb.append(" · ")
                    sb.append(formatActorCounts(persons, vehicles, bikes, animals))
                }
                if (sb.isEmpty()) sb.append("Motion detected")
                if (hasHero) sb.append(" · close-up view")
                body = sb.toString()
            }

            val data = JSONObject()
            val url: String
            if (videoFilename != null) {
                val enc = URLEncoder.encode(videoFilename, "UTF-8")
                data.put("filename", videoFilename)
                val snapshotName = if (!heroJpegName.isNullOrEmpty()) heroJpegName else videoFilename
                val encSnap = URLEncoder.encode(snapshotName, "UTF-8")
                val thumbTok = AuthManager.signThumbToken(snapshotName, 600L)
                var snapUrl = "/thumb/$encSnap"
                if (thumbTok != null) snapUrl += "?t=$thumbTok"
                data.put("snapshot", snapUrl)
                data.put("stage", "final")
                url = "/events?filter=sentry&file=$enc"
            } else {
                url = "/events?filter=sentry"
            }
            // Surface the new metadata so the notification UI / SW can render it
            data.put("severity", peakSev.name)
            data.put("personCount", persons)
            data.put("vehicleCount", vehicles)
            data.put("bikeCount", bikes)
            data.put("animalCount", animals)
            if (closest != null && closest != Actor.Proximity.UNKNOWN) {
                data.put("closestProximity", closest.name)
            }
            if (camHint != null) data.put("camera", camHint)

            val nsev = if (peakSev == Actor.Severity.CRITICAL) {
                NotificationEvent.Severity.CRITICAL
            } else if (peakSev == Actor.Severity.ALERT) {
                NotificationEvent.Severity.WARN
            } else {
                NotificationEvent.Severity.INFO
            }

            // Route to severity-specific subcategory so per-tier muting works.
            val subCategory = if (peakSev == Actor.Severity.CRITICAL) "surveillance.motion.critical"
            else if (peakSev == Actor.Severity.ALERT) "surveillance.motion.alert"
            else "surveillance.motion.notice"

            NotificationBus.get().publish(NotificationEvent(subCategory, nsev, title, body, notificationTagFor(videoFilename), url, data))
        } catch (t: Throwable) {
            logger.debug("publishMotionFinal failed: " + t.message)
        }
    }

    /**
     * Starts recording an event with pre-record support.
     */
    private fun startRecording() {
        val rec = recorder
        if (rec == null) {
            logger.error("Cannot start recording - recorder is null")
            return
        }

        if (recording) {
            logger.debug("Already recording")
            return
        }

        // SOTA: Storage cleanup happens off the trigger thread.
        var storageManager: StorageManager?
        try {
            val sm = StorageManager.getInstance()
            storageManager = sm
            if (sm.surveillanceStorageType == StorageManager.StorageType.SD_CARD && !sm.isSdCardMounted()) {
                logger.warn("SD card unmounted before recording - attempting remount")
                if (!sm.ensureSdCardMounted(true)) {
                    logger.error("SD card remount failed - event may write to stale path")
                }
            }
        } catch (e: Exception) {
            logger.warn("Storage mount check failed: " + e.message)
            storageManager = null
        }
        val smRef = storageManager
        if (smRef != null) {
            aiExecutor.execute {
                try {
                    smRef.ensureSurveillanceSpace(50 * 1024 * 1024)
                } catch (e: Exception) {
                    logger.warn("Async storage cleanup failed: " + e.message)
                }
            }
        }

        val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())
        val fileName = "event_$timestamp.mp4"
        val eventFile = File(eventOutputDir, fileName)
        currentEventFile = eventFile

        logger.info("Triggering event recording: " + eventFile.absolutePath)
        logger.info(String.format("Pre-record: %d sec, Post-record: %d sec", preRecordMsValue / 1000, postRecordMsValue / 1000))

        // Trigger event recording (flushes pre-record buffer)
        rec.triggerEventRecording(eventFile.absolutePath, postRecordMsValue)
        recording = true

        // Per-segment hero / sidecar plumbing.
        try {
            val enc = rec.getEncoder()
            if (enc != null) {
                enc.setSegmentListener(HardwareEventRecorderGpu.SegmentListener { closedSegment, newSegment ->
                    try {
                        if (closedSegment != null) {
                            flushSegmentMetadata(closedSegment)
                        }
                        // Update currentEventFile so stopRecording's flush attaches to the LAST segment.
                        currentEventFile = newSegment
                        // Restart the timeline collector for the new segment.
                        timelineCollector.startCollectingNoPreRing()
                    } catch (ex: Exception) {
                        logger.warn("Per-segment flush failed: " + ex.message)
                    }
                })
            }
        } catch (e: Exception) {
            logger.warn("Could not register segment listener: " + e.message)
        }

        // SOTA: Start timeline event collection for this recording.
        var actualPreRecordMs = preRecordMsValue
        try {
            val encoder = rec.getEncoder()
            if (encoder != null) {
                val actual = encoder.getActualPreRecordDurationMs()
                if (actual > 0) {
                    actualPreRecordMs = actual
                    logger.info("Timeline using actual pre-record duration: " + actual + "ms (configured: " + preRecordMsValue + "ms)")
                }
            }
        } catch (e: Exception) {
            logger.warn("Could not get actual pre-record duration: " + e.message)
        }
        timelineCollector.startCollecting(actualPreRecordMs)

        logger.info("Event recording triggered successfully")
    }

    /**
     * Stops recording an event with post-record support.
     */
    private fun stopRecording() {
        val rec = recorder
        if (rec == null || !recording) {
            return
        }

        // SOTA: Update detection baseline from the last YOLO detections of this event.
        if (lastEventQuadrant >= 0) {
            val snap = lastYoloDetections.getAndSet(lastEventQuadrant, null)
            if (snap != null) {
                val qW = THUMBNAIL_WIDTH / 2
                val qH = THUMBNAIL_HEIGHT / 2
                detectionBaseline.updateFromEventEnd(lastEventQuadrant, snap, qW, qH)
            }
            lastEventQuadrant = -1
        }

        // Stop immediately (post-record already handled by timeout).
        rec.stopEventRecording(true, 0)
        recording = false
        lastRecordingStopTime = System.currentTimeMillis()  // Track when we stopped

        // FIX (B1/H-a): bump the generation counter NOW.
        recordingGeneration.incrementAndGet()

        val eventFile = currentEventFile
        if (eventFile != null && eventFile.exists()) {
            logger.info(String.format("Saved: %s (%d KB)", eventFile.name, eventFile.length() / 1024))

            // Flush metadata for the FINAL segment.
            flushSegmentMetadata(eventFile)

            // Two-stage notification.
            val videoName = eventFile.name
            val heroSibling = videoName.replace(".mp4", ".jpg")
            val heroSiblingFile = File(eventFile.parentFile, heroSibling)

            // Fallback hero if ThumbnailBuffer didn't write one.
            if (!heroSiblingFile.exists()) {
                writeFallbackHeroFromMp4(eventFile, heroSiblingFile)
            }

            val heroName = if (heroSiblingFile.exists()) heroSibling else null
            try {
                publishMotionFinal(videoName, heroName)
            } catch (t: Throwable) {
                logger.debug("publishMotionFinal threw: " + t.message)
            }
        }

        // Detach the segment listener so a stale lambda from a previous event can't reset state.
        try {
            rec.getEncoder()?.setSegmentListener(null)
        } catch (ignored: Exception) {
        }

        currentEventFile = null
        // Reset Actor state for the next event
        actorTracker.reset()
        lastActors = emptyList()
        thumbnailBuffer?.clear()
        logger.info("Recording stopped, motion detection continues")
    }

    /**
     * Write hero JPEG + per-actor thumbnails + JSON timeline sidecar
     * alongside the given .mp4 segment.
     */
    private fun flushSegmentMetadata(segmentMp4: File?) {
        if (segmentMp4 == null) return

        // Renormalize per-actor peak timestamps against THIS segment's timeline origin.
        val segmentStartMs = timelineCollector.recordingStartTimeMs
        val rawActors = lastActors
        val segmentActors: List<Actor>
        if (rawActors.isEmpty() || segmentStartMs <= 0) {
            segmentActors = rawActors
        } else {
            val list = ArrayList<Actor>(rawActors.size)
            for (a in rawActors) {
                val renormalizedRelMs = if (a.peakSeverityWallMs > 0 && a.peakSeverityWallMs >= segmentStartMs) {
                    a.peakSeverityWallMs - segmentStartMs
                } else {
                    -1L  // peak fell outside this segment
                }
                if (renormalizedRelMs == a.peakSeverityRelMs) {
                    list.add(a)
                } else {
                    list.add(
                        Actor(
                            a.actorId, a.classGroup,
                            a.firstSeenWallMs, a.lastSeenWallMs,
                            a.firstSeenRelMs, a.lastSeenRelMs,
                            a.cameraMask,
                            a.peakProximity, a.lastProximity,
                            a.trend, a.isStatic,
                            a.peakSeverity, a.peakSeverityWallMs, renormalizedRelMs,
                            a.peakConfidence,
                            a.peakBboxX, a.peakBboxY, a.peakBboxW, a.peakBboxH,
                            a.peakBboxQuadW, a.peakBboxQuadH, a.peakCamera,
                            a.lastBboxX, a.lastBboxY, a.lastBboxW, a.lastBboxH
                        )
                    )
                }
            }
            segmentActors = list
        }

        var heroFile: File? = null
        val tb = thumbnailBuffer
        if (tb != null) {
            try {
                val relMap = HashMap<Long, Long>()
                for (a in segmentActors) {
                    if (a.peakSeverityRelMs >= 0) {
                        relMap[a.actorId] = a.peakSeverityRelMs
                    }
                }
                heroFile = tb.flushToDisk(segmentMp4, relMap)
                if (heroFile != null) {
                    logger.info("Hero thumbnail (" + segmentMp4.name + "): " + heroFile.name)
                }
            } catch (e: Exception) {
                logger.warn("Thumbnail flush failed for " + segmentMp4.name + ": " + e.message)
            }
        }

        // Write timeline JSON sidecar alongside this segment.
        try {
            timelineCollector.stopAndWrite(segmentMp4, segmentActors, heroFile?.name)
        } catch (e: Exception) {
            logger.warn("Timeline write failed for " + segmentMp4.name + ": " + e.message)
        }

        // Reset the metadata buffers for the next segment. ThumbnailBuffer
        // already self-clears in flushToDisk; timelineCollector needs an
        // explicit reset before the rotation listener calls startCollecting
        // for the new segment. Don't clear lastActors — the next segment's
        // first frame should have continuity with actors that crossed the
        // rotation boundary.
    }

    /**
     * Enables surveillance (starts monitoring).
     */
    fun enable() {
        // RACE CONDITION FIX (defense in depth): Final guard at the engine level.
        if (AccMonitor.isAccOn()) {
            logger.warn(">>> Surveillance enable REJECTED at engine level — ACC is ON")
            return
        }

        // Check if native library is loaded
        if (!isLibraryLoaded()) {
            logger.error(">>> Cannot enable surveillance: NativeMotion library not loaded! Error: " + getLoadError())
            return
        }

        logger.info("Enabling surveillance engine (pipelineV2=" + (pipelineV2 != null) + ", pipelineV2init=" + (pipelineV2?.isInitialized() == true) + ")")

        active = true
        frameCount = 0
        motionDetections = 0
        firstMotionTime = 0  // Reset sustained motion timer
        deterrentFiredTime = 0  // Reset deterrent suppression
        lastAiConfirmationTimeMs = 0  // Reset AI confirmation gate
        peakThreatDuringSequence = 0

        // Reset post-suppression baseline refresh tracking
        for (q in 0 until MotionPipelineV2.NUM_QUADRANTS) {
            framesSinceSuppressionEnded[q] = 0
            suppressionWasActive[q] = false
            baselineRefreshQueued[q] = false
        }

        // Reset SOTA tracking variables
        lastTemporalBlocksCount = 0
        lastMotionMinY = 0
        lastMotionMaxY = 0
        lastEstimatedDistance = 0f

        // SOTA: Notify StorageManager that surveillance is active (for periodic cleanup)
        try {
            StorageManager.getInstance().setSurveillanceActive(true)
        } catch (e: Exception) {
            logger.warn("Could not set surveillance active state: " + e.message)
        }

        // V2: Re-initialize pipeline for clean start
        if (pipelineV2 != null) {
            try {
                initPipelineV2()
                logger.info("V2 pipeline reset for new surveillance session")
            } catch (e: Exception) {
                logger.warn("V2 pipeline reset failed: " + e.message)
            }
        }

        // Reset cross-quadrant tracker for clean session
        crossQuadrantTracker.reset()

        // Reset Actor layer too — fresh ID space for each session
        actorTracker.reset()
        lastActors = emptyList()

        // Reset detection baseline for clean session
        detectionBaseline.reset()
        baselineSeeded = false
        for (q in 0 until MotionPipelineV2.NUM_QUADRANTS) {
            lastYoloDetections.set(q, null)
        }
        lastEventQuadrant = -1

        // Initialize native texture tracker (YOLO + NCC hybrid VOT)
        try {
            initTracker()
            logger.info("Texture tracker initialized (YOLO + NCC hybrid)")
        } catch (e: Exception) {
            logger.warn("Texture tracker init failed: " + e.message)
        }

        logger.info("Surveillance enabled (V2 per-quadrant pipeline)")
    }

    /**
     * Disables surveillance (stops monitoring).
     */
    fun disable() {
        if (recording) {
            stopRecording()
        }
        active = false
        inActiveMode = false

        // P1 #15: cancel pending YOLO work and clear shared state BEFORE resetting the baseline.
        aiQuadrantQueueClear()
        for (q in 0 until MotionPipelineV2.NUM_QUADRANTS) {
            lastYoloDetections.set(q, null)
        }
        // Brief drain so any inference already running observes active=false and skips its writes.
        try {
            val drainDeadline = System.currentTimeMillis() + 50
            while (isAiRunning.get() && System.currentTimeMillis() < drainDeadline) {
                Thread.sleep(5)
            }
        } catch (ignored: InterruptedException) {
            Thread.currentThread().interrupt()
        }

        // SOTA: Notify StorageManager that surveillance is inactive
        try {
            StorageManager.getInstance().setSurveillanceActive(false)
        } catch (e: Exception) {
            logger.warn("Could not set surveillance inactive state: " + e.message)
        }

        // Reset detection baseline for clean session
        detectionBaseline.reset()
        baselineSeeded = false

        logger.info("Surveillance disabled")
    }

    /** Whether surveillance is active. */
    val isActive: Boolean
        get() = active

    /**
     * Checks if currently recording.
     */
    fun isRecording(): Boolean = recording

    /**
     * Checks if in active mode (heavy AI).
     */
    fun isInActiveMode(): Boolean = inActiveMode

    /**
     * Gets the current SAD threshold.
     */
    var sadThreshold: Float
        get() = config.sensitivity
        set(threshold) {
            config.sensitivity = threshold
            logger.info("SAD threshold set to: $threshold")
        }

    /**
     * Gets the grid motion block sensitivity.
     */
    fun getBlockSensitivity(): Float = config.sensitivity

    /**
     * Sets the grid motion block sensitivity.
     * Lower values detect more distant/subtle motion.
     */
    fun setBlockSensitivity(sensitivity: Float) {
        val clamped = Math.max(0.01f, Math.min(0.20f, sensitivity))
        config.sensitivity = clamped
        logger.info("Block sensitivity set to: $clamped")
    }

    /**
     * The unified motion sensitivity (0-100%).
     *
     * This is the recommended API for controlling motion detection.
     * A single slider that intelligently adjusts:
     * - Density Threshold: How many pixels must change per block
     * - Alarm Threshold: How many blocks must trigger to start recording
     *
     * Mapping:
     * - 0-30%:   LOW (large/close objects only)
     * - 31-60%:  MEDIUM (balanced, default)
     * - 61-80%:  HIGH (detects distant objects)
     * - 81-100%: VERY HIGH (any motion)
     */
    var unifiedSensitivity: Int
        get() = config.unifiedSensitivity
        set(sensitivity) {
            config.unifiedSensitivity = sensitivity

            // Sync legacy fields for backward compatibility
            this.requiredActiveBlocks = config.alarmBlockThreshold

            logger.info(
                String.format(
                    "Unified sensitivity set to: %d%% (alarm=%d blocks, density=%d pixels, shadow=%d)",
                    sensitivity, config.alarmBlockThreshold, config.densityThreshold, config.shadowThreshold
                )
            )
        }

    /**
     * Night mode (affects shadow threshold).
     *
     * Night mode uses a higher shadow threshold (40 vs 25) to filter
     * out headlight reflections and other light artifacts.
     */
    var isNightMode: Boolean
        get() = config.isNightMode
        set(enabled) {
            config.isNightMode = enabled
            // Log the V2 pipeline's actual shadow threshold (not the legacy config's)
            val v2Shadow = pipelineV2Config?.shadowThreshold ?: -1
            val v2Filter = pipelineV2Config?.shadowFilterMode ?: -1
            logger.info("Night mode set to: $enabled (V2 shadow threshold=$v2Shadow, filter=$v2Filter)")
        }

    /**
     * Gets the required active blocks threshold.
     */
    fun getRequiredActiveBlocks(): Int = requiredActiveBlocks

    /**
     * Sets the required active blocks threshold.
     * Lower values are more sensitive to small/distant motion.
     */
    fun setRequiredActiveBlocks(blocks: Int) {
        this.requiredActiveBlocks = Math.max(1, Math.min(10, blocks))
        // Sync with SOTA config
        config.requiredBlocks = this.requiredActiveBlocks
        logger.info("Required active blocks set to: " + this.requiredActiveBlocks)
    }

    /**
     * Gets the minimum object size for detection.
     */
    fun getMinObjectSize(): Float = minObjectSize

    /**
     * Gets the total number of grid blocks.
     */
    val totalBlocks: Int
        get() = TOTAL_BLOCKS

    /**
     * Gets the last active blocks count (for UI display).
     */
    fun getLastActiveBlocksCount(): Int = lastActiveBlocksCount

    /**
     * Gets the baseline noise blocks count (deprecated - always returns 0).
     */
    fun getBaselineNoiseBlocks(): Int = 0  // Baseline logic removed for simplicity

    /**
     * The pre-record duration in seconds. Assigning also propagates to the
     * encoder's circular buffer size, matching the Java `setPreRecordSeconds`.
     */
    var preRecordSeconds: Int
        get() = (preRecordMsValue / 1000).toInt()
        set(seconds) {
            preRecordMsValue = seconds * 1000L
            // Sync with SOTA config
            config.preRecordSeconds = seconds
            logger.info("Pre-record duration set to: $seconds seconds")

            // Update the circular buffer size in the recorder's encoder
            recorder?.getEncoder()?.setPreRecordDuration(seconds)
        }

    /**
     * The post-record duration in seconds.
     */
    var postRecordSeconds: Int
        get() = (postRecordMsValue / 1000).toInt()
        set(seconds) {
            postRecordMsValue = seconds * 1000L
            // Sync with SOTA config
            config.postRecordSeconds = seconds
            logger.info("Post-record duration set to: $seconds seconds")
        }

    /**
     * Gets the frame count.
     */
    fun getFrameCount(): Int = frameCount

    /**
     * Gets the motion detection count.
     */
    fun getMotionDetections(): Int = motionDetections

    /**
     * Updates the V2 pipeline configuration.
     * Call this when user changes settings via IPC.
     */
    fun updateV2Config(newConfig: MotionPipelineV2.Config?) {
        val pv2 = pipelineV2
        if (pv2 != null) {
            if (newConfig != null) {
                pipelineV2Config = newConfig
            }
            pipelineV2Config?.let {
                pv2.applyConfig(it)
                logger.info("V2 pipeline config updated")
            }
        }
    }

    /**
     * Apply a V2 environment preset (outdoor/garage/street).
     */
    fun applyV2EnvironmentPreset(preset: String) {
        pipelineV2Config?.let { cfg ->
            cfg.applyEnvironmentPreset(preset)
            pipelineV2?.applyConfig(cfg)
            logger.info("V2 environment preset applied: $preset")
        }
    }

    /**
     * Apply V2 sensitivity level (1-5).
     */
    fun applyV2Sensitivity(level: Int) {
        pipelineV2Config?.let { cfg ->
            cfg.applySensitivity(level)
            pipelineV2?.applyConfig(cfg)
            logger.info("V2 sensitivity set to $level")
        }
    }

    /**
     * Set V2 loitering time in seconds.
     */
    fun setV2LoiteringTime(seconds: Int) {
        pipelineV2Config?.let { cfg ->
            cfg.loiteringFrames = seconds * 10  // 10 FPS
            pipelineV2?.applyConfig(cfg)
        }
        // Also update Java-side sustained motion threshold.
        this.loiteringTimeMs = seconds * 1000L
        logger.info("V2 loitering time set to " + seconds + "s (native=" + (seconds * 10) + " frames, java=" + loiteringTimeMs + "ms)")
    }

    /**
     * Enable/disable a specific camera quadrant for V2 detection.
     * @param quadrant 0=front, 1=right, 2=left, 3=rear
     */
    fun setV2QuadrantEnabled(quadrant: Int, enabled: Boolean) {
        val cfg = pipelineV2Config
        if (cfg != null && quadrant in 0..3) {
            cfg.quadrantEnabled[quadrant] = enabled
            pipelineV2?.applyConfig(cfg)
            logger.info("V2 quadrant " + MotionPipelineV2.QUADRANT_NAMES[quadrant] + " " + (if (enabled) "enabled" else "disabled"))
        }
    }

    /**
     * Get V2 pipeline results (for heatmap overlay / debug).
     */
    val v2Results: Array<MotionPipelineV2.QuadrantResult>?
        get() = pipelineV2?.getResults()

    /**
     * Set shadow filter mode for V2 pipeline.
     * @param mode 0=OFF, 1=LIGHT, 2=NORMAL, 3=AGGRESSIVE
     */
    fun setV2ShadowFilterMode(mode: Int) {
        val cfg = pipelineV2Config
        if (cfg != null && mode in 0..3) {
            cfg.shadowFilterMode = mode
            pipelineV2?.applyConfig(cfg)
            val modeNames = arrayOf("OFF", "LIGHT", "NORMAL", "AGGRESSIVE")
            logger.info("V2 shadow filter mode set to " + modeNames[mode])
        }
    }

    /**
     * Get current shadow filter mode.
     * @return 0=OFF, 1=LIGHT, 2=NORMAL, 3=AGGRESSIVE
     */
    fun getV2ShadowFilterMode(): Int = pipelineV2Config?.shadowFilterMode ?: 0

    /**
     * Enable/disable filter debug logging.
     */
    fun setFilterDebugEnabled(enabled: Boolean) {
        this.filterDebugEnabled = enabled
        if (!enabled) {
            synchronized(filterLog) {
                filterLogCount = 0
                filterLogIndex = 0
            }
        }
        logger.info("Filter debug log " + (if (enabled) "enabled" else "disabled"))
    }

    /**
     * Add an entry to the filter debug log ring buffer.
     */
    private fun addFilterLogEntry(entry: String) {
        if (!filterDebugEnabled) return
        synchronized(filterLog) {
            filterLog[filterLogIndex] = entry
            filterLogIndex = (filterLogIndex + 1) % FILTER_LOG_CAPACITY
            if (filterLogCount < FILTER_LOG_CAPACITY) filterLogCount++
        }
    }

    /**
     * Recent filter log entries (newest first).
     */
    val filterLogEntries: Array<String>
        get() = synchronized(filterLog) {
            Array(filterLogCount) { i ->
                val idx = (filterLogIndex - 1 - i + FILTER_LOG_CAPACITY) % FILTER_LOG_CAPACITY
                filterLog[idx] ?: ""
            }
        }

    fun release() {
        disable()

        // SOTA FIX: Shutdown the executor
        aiExecutor.shutdownNow()

        // Clean up YOLO detector
        yoloDetector?.close()
        yoloDetector = null

        currentFrame = null
        // ThreadLocal: clear this thread's scratch. Other threads' entries
        // (aiExecutor, drainer) will be reclaimed when those threads exit
        // or the next allocation replaces them.
        aiBufferTL.remove()

        logger.info("Released")
    }

    companion object {
        private const val TAG = "SurveillanceEngineGpu"
        private val logger = DaemonLogger.getInstance(TAG)

        // SUSTAINED MOTION: Base minimum before any trigger (prevents single-frame noise).
        // For THREAT_HIGH (loitering confirmed), this is the only delay needed.
        // For THREAT_MEDIUM (approaching), the loitering time setting adds additional delay.
        private const val SUSTAINED_MOTION_BASE_MS = 500L

        // MOTION THROTTLING: Process motion at 10 FPS max (saves 66% CPU vs 30 FPS)
        private const val MOTION_PROCESS_INTERVAL_MS = 100L  // 10 FPS

        // SOTA: Grid Motion Configuration
        // 640x480 / 32 = 20x15 grid. 32px blocks are ideal for human detection at distance.
        private const val GRID_BLOCK_SIZE = 32
        private const val GRID_COLS = 640 / GRID_BLOCK_SIZE  // 20
        private const val GRID_ROWS = 480 / GRID_BLOCK_SIZE  // 15
        private const val TOTAL_BLOCKS = GRID_COLS * GRID_ROWS  // 300

        // DETERRENT FLASH SUPPRESSION
        private const val DETERRENT_SUPPRESSION_MS = 20000L

        // AI throttling
        private const val AI_COOLDOWN_MS = 500L

        // Heartbeat cooldown
        private const val HEARTBEAT_COOLDOWN_MS = 5000L  // Min 5s between heartbeats per quadrant

        // Filter debug log
        private const val FILTER_LOG_CAPACITY = 100

        // POST-SUPPRESSION BASELINE REFRESH
        private const val BASELINE_STABILIZATION_FRAMES = 15  // 1.5s at 10 FPS

        // Frame dimensions - SOTA: Increased to 640x480 for better AI detection
        private const val THUMBNAIL_WIDTH = 640
        private const val THUMBNAIL_HEIGHT = 480
        private const val BYTES_PER_PIXEL = 3  // RGB
        private const val FRAME_SIZE = THUMBNAIL_WIDTH * THUMBNAIL_HEIGHT * BYTES_PER_PIXEL

        /**
         * Rank a class group for "which actor is the threat in this scene". Higher
         * = more important to surface. Mirrors [ThumbnailBuffer]'s scoring so
         * the notification title agrees with the thumbnail.
         */
        private fun classRank(g: Actor.ClassGroup?): Int {
            if (g == null) return 0
            return when (g) {
                Actor.ClassGroup.PERSON -> 4
                Actor.ClassGroup.BIKE -> 3
                Actor.ClassGroup.VEHICLE -> 2
                Actor.ClassGroup.ANIMAL -> 1
                else -> 0
            }
        }

        private fun cameraNameFor(a: Actor?): String? {
            if (a == null) return null
            if (a.peakCamera < 0 || a.peakCamera >= MotionPipelineV2.QUADRANT_NAMES.size) return null
            return MotionPipelineV2.QUADRANT_NAMES[a.peakCamera]
        }

        /**
         * Stable per-event tag used by both the initial quick notification and the
         * finalized rich one. Same tag → OS replaces the first banner with the
         * second instead of stacking.
         */
        private fun notificationTagFor(videoFilename: String?): String {
            if (videoFilename != null && videoFilename.isNotEmpty()) {
                return "motion:$videoFilename"
            }
            // Fallback when we don't yet have a filename — minute-bucket dedupe
            // (matches legacy behaviour).
            return "motion-" + (System.currentTimeMillis() / 60000L)
        }

        /**
         * Capitalised, human-readable proximity phrase used as the lead clause
         * in notification bodies. "VERY_CLOSE" → "Very close", etc.
         */
        private fun proximityPhrase(p: Actor.Proximity?): String {
            if (p == null) return ""
            return when (p) {
                Actor.Proximity.VERY_CLOSE -> "Very close"
                Actor.Proximity.CLOSE -> "Close"
                Actor.Proximity.MID -> "Mid range"
                Actor.Proximity.FAR -> "Far"
                else -> ""
            }
        }

        /**
         * Pluralised count list for notification bodies.
         * (1, 0, 0, 0) → "1 person"
         * (2, 1, 0, 0) → "2 people, 1 vehicle"
         * (0, 2, 0, 1) → "2 vehicles, 1 animal"
         * Skips zero counts; uses proper plurals.
         */
        private fun formatActorCounts(persons: Int, vehicles: Int, bikes: Int, animals: Int): String {
            val parts = ArrayList<String>(4)
            if (persons > 0) parts.add(persons.toString() + " " + (if (persons == 1) "person" else "people"))
            if (vehicles > 0) parts.add(vehicles.toString() + " " + (if (vehicles == 1) "vehicle" else "vehicles"))
            if (bikes > 0) parts.add(bikes.toString() + " " + (if (bikes == 1) "bike" else "bikes"))
            if (animals > 0) parts.add(animals.toString() + " " + (if (animals == 1) "animal" else "animals"))
            return parts.joinToString(", ")
        }
    }
}
