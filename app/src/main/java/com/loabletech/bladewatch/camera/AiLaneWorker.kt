package net.bladewatch.app.camera

import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.surveillance.SurveillanceEngineGpu

import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/**
 * AiLaneWorker — runs sentry.processFrame() on a dedicated thread so the
 * GL render loop doesn't block on V2 motion native + downstream AI work.
 *
 * Flow:
 *   GL thread: downscaler.readPixelsDirect(textureId) → byte[]
 *   GL thread: aiWorker.submitFrame(byte[]) — non-blocking, drops frame if busy
 *   Worker thread: sentry.processFrame(byte[]) — V2 motion native +
 *                  any further async dispatch (YOLO already runs on its
 *                  own aiExecutor inside SurveillanceEngineGpu)
 *
 * Drop-not-queue policy: at fixed AI cadence (V2 motion is throttled to
 * 10 fps internally via MOTION_PROCESS_INTERVAL_MS) we never want to build
 * up a backlog. If the worker is mid-processing when GL submits a new
 * frame, we recycle the new frame back to the downscaler pool and skip.
 * The next render loop iteration will get a fresh frame anyway.
 *
 * The recycle-on-drop is essential: downscaler.readPixelsDirect borrows
 * from a fixed pool; failing to recycle leaks the buffer.
 */
class AiLaneWorker(private val recycler: FrameRecycler) {

    fun interface FrameRecycler {
        /** Called from worker when a submitted frame can't be processed (busy/shutdown). */
        fun recycle(frame: ByteArray)
    }

    private val executor: ExecutorService = Executors.newSingleThreadExecutor { r ->
        Thread(r, "AiLaneWorker").apply {
            isDaemon = true
            priority = Thread.NORM_PRIORITY
        }
    }

    private val busy = AtomicBoolean(false)

    // Named `shutdownRequested`, not `shutdown`: Kotlin cannot have a property and a function
    // of the same name, and shutdown() below owns that name.
    private val shutdownRequested = AtomicBoolean(false)

    @Volatile
    private var sentry: SurveillanceEngineGpu? = null

    /** Diagnostic counters for the periodic Stats log. */
    @Volatile
    var droppedFrames: Long = 0
        private set

    @Volatile
    var processedFrames: Long = 0
        private set

    // BladeWatch-t1lg.3: PipelineRateController's actuator. Wall-clock throttle, not a
    // frame-count ratio -- this worker never learns the camera's actual capture fps, and a
    // time-based gate needs no such knowledge. 0 (the default) means "no throttle beyond the
    // existing busy-drop policy", i.e. today's behavior, unchanged until something calls
    // setDetectionRate. This never touches the encoder, EGL, or sentry's internal state --
    // it only decides, before any of that, whether THIS frame is accepted at all.
    @Volatile
    private var minIntervalMs: Long = 0

    @Volatile
    private var lastAcceptedAtMs: Long = 0

    // Track frames that have been queued to the executor but not yet run, so
    // we can recycle them on forced shutdown. Without this, a shutdownNow()
    // path discards the Runnable (and its captured byte[] frame) and leaks
    // one downscaler-pool buffer per shutdown.
    private val inFlightFrames = ConcurrentHashMap<Runnable, ByteArray>()

    /** Bind/unbind the sentry. Null detaches; safe to call from GL thread. */
    fun setSentry(sentry: SurveillanceEngineGpu?) {
        this.sentry = sentry
    }

    /**
     * Submit an RGB frame for AI processing. Non-blocking. If the worker is
     * still processing the previous frame, the new frame is recycled and
     * dropped. Returns true if the frame was queued, false if dropped.
     */
    fun submitFrame(rgbFrame: ByteArray?): Boolean {
        if (rgbFrame == null) return false
        if (shutdownRequested.get()) {
            recycler.recycle(rgbFrame)
            return false
        }
        val s = sentry
        if (s == null || !s.isActive) {
            recycler.recycle(rgbFrame)
            return false
        }
        val minInterval = minIntervalMs
        if (minInterval > 0) {
            val now = System.currentTimeMillis()
            if (now - lastAcceptedAtMs < minInterval) {
                // Throttled by PipelineRateController's current rate, not busy -- same
                // recycle-on-drop policy either way.
                recycler.recycle(rgbFrame)
                return false
            }
            lastAcceptedAtMs = now
        }
        if (!busy.compareAndSet(false, true)) {
            // Worker still processing previous frame; drop this one and let
            // GL thread continue.
            droppedFrames++
            recycler.recycle(rgbFrame)
            return false
        }
        // Stage the Runnable so we can deregister it from inFlightFrames
        // when it actually runs OR recycle the captured frame on forced
        // shutdown via shutdownNow.
        var self: Runnable? = null
        val task = Runnable {
            // Mark as started — shutdownNow's "not yet run" list will not
            // contain us once we're past this point.
            self?.let { inFlightFrames.remove(it) }
            try {
                val sNow = sentry
                if (sNow != null && sNow.isActive) {
                    // sentry.processFrame recycles the buffer in its own
                    // finally block. We do NOT recycle here on success.
                    sNow.processFrame(rgbFrame)
                    processedFrames++
                } else {
                    recycler.recycle(rgbFrame)
                }
            } catch (t: Throwable) {
                logger.warn("AI lane processing error: " + t.message)
                // sentry.processFrame normally recycles in finally; if it
                // threw before reaching the recycle, we recycle here as
                // a safety net (double-recycle is bounded by the pool's
                // ArrayBlockingQueue offer policy).
                try {
                    recycler.recycle(rgbFrame)
                } catch (ignored: Throwable) {
                    logger.warn(
                        "Failed to recycle frame after AI lane processing error: " +
                            ignored.message
                    )
                }
            } finally {
                busy.set(false)
            }
        }
        self = task
        return try {
            inFlightFrames[task] = rgbFrame
            executor.execute(task)
            true
        } catch (t: Throwable) {
            // Executor rejected (post-shutdown). Recycle and clear tracking + busy.
            inFlightFrames.remove(task)
            busy.set(false)
            recycler.recycle(rgbFrame)
            false
        }
    }

    /**
     * Sets the detection processing rate. `fps <= 0` disables the throttle entirely
     * (every submitted frame is a candidate again, subject only to the existing busy-drop
     * policy). Implements `PipelineRateController.RateTarget`; never touches the
     * encoder, EGL, or sentry.
     */
    fun setDetectionRate(fps: Int) {
        minIntervalMs = if (fps > 0) 1000L / fps else 0
    }

    /**
     * Returns true when the worker is mid-processFrame and a new submit
     * would be dropped. The GL render loop uses this to skip the expensive
     * readPixelsDirect path entirely on frames that would be dropped anyway,
     * avoiding 1.2 MB readback + Java RGBA→RGB Y-flip + the GPU pipeline
     * flush that glReadPixels forces. V2 motion is throttled to ~10 fps
     * internally (MOTION_PROCESS_INTERVAL_MS=100), so at 30 fps camera the
     * worker is busy ~67% of frames — skipping readback on those frames
     * cuts GL-thread load by ~2/3 without losing any motion detection.
     *
     * Cheap atomic read; safe to call from the GL thread every iteration.
     */
    fun isBusy(): Boolean = busy.get()

    fun resetCounters() {
        droppedFrames = 0
        processedFrames = 0
    }

    /**
     * Shutdown — drains in-flight work, then refuses new submissions.
     * Any unrun Runnables (frames queued but not yet processed) have their
     * byte[] payloads returned to the recycler so the downscaler buffer
     * pool isn't leaked.
     */
    fun shutdown() {
        if (!shutdownRequested.compareAndSet(false, true)) return
        executor.shutdown()
        var notRun: List<Runnable> = emptyList()
        try {
            if (!executor.awaitTermination(2, TimeUnit.SECONDS)) {
                notRun = executor.shutdownNow()
            }
        } catch (ie: InterruptedException) {
            Thread.currentThread().interrupt()
            notRun = executor.shutdownNow()
        }
        // Recycle byte[] frames captured by any Runnable that was queued
        // but never started. inFlightFrames is keyed by the Runnable itself.
        for (r in notRun) {
            val f = inFlightFrames.remove(r)
            if (f != null) {
                try {
                    recycler.recycle(f)
                } catch (ignored: Throwable) {
                    logger.warn("Failed to recycle frame on shutdown: " + ignored.message)
                }
            }
        }
        // Anything else in the map represents Runnables that started but
        // didn't finish (e.g., interrupted). Their try/finally already calls
        // recycle on exception paths, so just clear the tracking map.
        inFlightFrames.clear()
    }

    companion object {
        private val logger = DaemonLogger.getInstance("AiLaneWorker")
    }
}
