package net.bladewatch.app.surveillance

import net.bladewatch.app.config.UnifiedConfigManager
import net.bladewatch.app.logging.DaemonLogger
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit
import java.util.function.BooleanSupplier
import kotlin.math.min

/**
 * Transitions the surveillance/detection processing rate by driving state, without touching the
 * recording pipeline (BladeWatch-t1lg.3). The bitrate-adapting sibling class owns bitrate; this
 * owns the detection frame rate — two owners for one knob is the bug that split prevents.
 *
 * Recording quality (resolution, codec, bitrate, the encoder, the EGL context) is never touched
 * here. The single hard requirement this class exists to satisfy: a rate change must never cause
 * encoder re-init or EGL teardown, and must never reset the motion pipeline's state (confidence
 * history, quadrant state, tracker continuity) — it only changes how often frames reach that
 * pipeline, via [RateTarget.setDetectionRate].
 *
 * Several members are public rather than module-internal so PipelineRateControllerTest, which is
 * Java, can reach them: Kotlin mangles `internal` names on the JVM.
 *
 * @param scheduler nullable: without one, motion never auto-clears — callers must call
 *   [clearRecentMotion] themselves (the shape every unit test uses).
 */
class PipelineRateController private constructor(
    private val target: RateTarget,
    private val configuredFps: Int,
    private val drivingFps: Int,
    private val idleFps: Int,
    private val scheduler: ScheduledExecutorService?,
    private val idleAfterMotionMs: Long
) {

    constructor(target: RateTarget, configuredFps: Int, drivingFps: Int, idleFps: Int) :
        this(target, configuredFps, drivingFps, idleFps, null, 0L)

    /**
     * Implemented by whatever actually throttles frame delivery to the detection pipeline (e.g.
     * AiLaneWorker, by adjusting how many submitted frames it accepts). Must never call anything
     * that tears down or re-initialises the encoder/EGL context.
     */
    fun interface RateTarget {
        fun setDetectionRate(fps: Int)
    }

    @Volatile
    private var accOn = false

    @Volatile
    private var motionRecently = false

    @Volatile
    private var liveViewersPresent = false

    @Volatile
    private var lastAppliedFps = -1

    @Volatile
    private var motionTimeoutTask: ScheduledFuture<*>? = null

    /** Wire from the same ACC source RecordingModeManager uses — do not add a second listener. */
    @Synchronized
    fun setAccOn(isOn: Boolean) {
        accOn = isOn
        recompute()
    }

    /** Call the instant motion is detected — returns to full rate on this call, not the next tick. */
    @Synchronized
    fun onMotionDetected() {
        motionRecently = true
        recompute()
        if (scheduler != null) {
            motionTimeoutTask?.cancel(false)
            motionTimeoutTask = scheduler.schedule(
                ::clearRecentMotion, idleAfterMotionMs, TimeUnit.MILLISECONDS
            )
        }
    }

    /** Call once the "recent motion" window has elapsed with nothing further detected. */
    @Synchronized
    fun clearRecentMotion() {
        motionRecently = false
        recompute()
    }

    @Synchronized
    fun setLiveViewersPresent(present: Boolean) {
        liveViewersPresent = present
        recompute()
    }

    private fun recompute() {
        val fps = targetFps(
            accOn, liveViewersPresent, motionRecently, configuredFps, drivingFps, idleFps
        )
        if (fps != lastAppliedFps) {
            val previousFps = lastAppliedFps
            lastAppliedFps = fps
            try {
                target.setDetectionRate(fps)
                logger.info(
                    "Detection rate " + previousFps + " -> " + fps + " fps (accOn=" + accOn +
                        ", liveViewers=" + liveViewersPresent +
                        ", motionRecently=" + motionRecently + ")"
                )
            } catch (e: Exception) {
                logger.warn("setDetectionRate($fps) failed: " + e.message)
            }
        }
    }

    companion object {

        private val logger: DaemonLogger = DaemonLogger.getInstance("PipelineRateController")

        /** Driving means the head unit has better things to do than watch for prowlers. */
        const val DEFAULT_DRIVING_FPS = 5

        /** Parked and quiet for a while — still armed, just not working hard. */
        const val DEFAULT_IDLE_FPS = 2

        /**
         * How long after the last motion event to ramp back down. Not user-configurable (yet) —
         * unlike the two rates, the issue only asked for the rates themselves to come from config.
         */
        private const val DEFAULT_IDLE_AFTER_MOTION_MS = 5 * 60_000L // 5 minutes
        private const val VIEWER_POLL_INTERVAL_MS = 15_000L

        @Volatile
        private var instance: PipelineRateController? = null

        /**
         * Pure decision, no camera/EGL/Android — see the class doc for the policy. A live viewer
         * or recent motion always wins (full configured rate); otherwise the ACC state picks the
         * driving or idle rate, using this project's sane defaults. Never exceeds [configuredFps]
         * — a "power saving" mode that raised the frame rate above what the owner configured would
         * be absurd.
         */
        @JvmStatic
        fun targetFps(
            accOn: Boolean,
            liveViewersPresent: Boolean,
            motionRecently: Boolean,
            configuredFps: Int
        ): Int = targetFps(
            accOn, liveViewersPresent, motionRecently, configuredFps,
            DEFAULT_DRIVING_FPS, DEFAULT_IDLE_FPS
        )

        /** Same policy, with the driving/idle rates as parameters. */
        @JvmStatic
        fun targetFps(
            accOn: Boolean,
            liveViewersPresent: Boolean,
            motionRecently: Boolean,
            configuredFps: Int,
            drivingFps: Int,
            idleFps: Int
        ): Int {
            if (liveViewersPresent || motionRecently) {
                return configuredFps
            }
            val reduced = if (accOn) drivingFps else idleFps
            return min(configuredFps, reduced)
        }

        /**
         * Reads `camera.detectionDrivingFps` from the unified config, mirroring
         * `GpuSurveillancePipeline.loadTargetFps`'s pattern exactly. Falls back to
         * [DEFAULT_DRIVING_FPS] if missing or unreadable.
         */
        @JvmStatic
        fun loadDrivingFps(): Int {
            try {
                val cameraConfig = UnifiedConfigManager.loadConfig().optJSONObject("camera")
                if (cameraConfig != null) {
                    return cameraConfig.optInt("detectionDrivingFps", DEFAULT_DRIVING_FPS)
                }
            } catch (ignored: Exception) {
                logger.warn(
                    "Failed to read detectionDrivingFps from config — defaulting to " +
                        DEFAULT_DRIVING_FPS + "fps: " + ignored.message
                )
            }
            return DEFAULT_DRIVING_FPS
        }

        /** Reads `camera.detectionIdleFps` from the unified config. See [loadDrivingFps]. */
        @JvmStatic
        fun loadIdleFps(): Int {
            try {
                val cameraConfig = UnifiedConfigManager.loadConfig().optJSONObject("camera")
                if (cameraConfig != null) {
                    return cameraConfig.optInt("detectionIdleFps", DEFAULT_IDLE_FPS)
                }
            } catch (ignored: Exception) {
                logger.warn(
                    "Failed to read detectionIdleFps from config — defaulting to " +
                        DEFAULT_IDLE_FPS + "fps: " + ignored.message
                )
            }
            return DEFAULT_IDLE_FPS
        }

        /**
         * Production entry point: reads the driving/idle rates from config, and starts the
         * periodic live-viewer polling and the per-event motion timeout. [liveViewerCheck] is
         * injected (rather than this class reaching for a global) because there is no standalone
         * WebSocketStreamServer singleton — GpuSurveillancePipeline owns the instance via
         * getWebSocketServer().
         */
        @JvmStatic
        @Synchronized
        fun init(
            target: RateTarget,
            configuredFps: Int,
            liveViewerCheck: BooleanSupplier
        ): PipelineRateController {
            instance?.let { return it }
            val scheduler = Executors.newSingleThreadScheduledExecutor { r ->
                Thread(r, "PipelineRateController").apply { isDaemon = true }
            }
            val c = PipelineRateController(
                target, configuredFps, loadDrivingFps(), loadIdleFps(),
                scheduler, DEFAULT_IDLE_AFTER_MOTION_MS
            )
            scheduler.scheduleAtFixedRate(
                {
                    try {
                        c.setLiveViewersPresent(liveViewerCheck.asBoolean)
                    } catch (e: Exception) {
                        logger.warn("liveViewerCheck failed: " + e.message)
                    }
                },
                VIEWER_POLL_INTERVAL_MS, VIEWER_POLL_INTERVAL_MS, TimeUnit.MILLISECONDS
            )
            instance = c
            return c
        }

        /** Null until [init] has run (e.g. in a JVM unit test, or before the pipeline starts). */
        @JvmStatic
        fun getInstance(): PipelineRateController? = instance
    }
}
