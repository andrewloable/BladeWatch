package net.bladewatch.app.camera

import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.monitor.AccMonitor

/**
 * AVC HAL Warmup — ensures the BYD camera HAL is initialized by com.byd.avc
 * BEFORE our daemon opens the camera.
 *
 * PROBLEM: When ACC turns ON, both our daemon and the native DVR (com.byd.cdr)
 * race to open the panoramic camera. If our daemon opens first, the HAL enters
 * a state where the native DVR can't attach its surface → "no video signal."
 *
 * SOLUTION:
 * 1. Launch com.byd.avc silently (the camera HAL initializer, NOT the DVR)
 * 2. Wait 4 seconds for the HAL to fully initialize in multi-consumer mode
 * 3. THEN open our camera as a secondary consumer
 *
 * Additionally, a 60-second keep-alive watchdog re-pokes com.byd.avc while
 * the pipeline is running, regardless of ACC state. BYD's system can kill
 * the camera app after inactivity, which destabilizes the HAL for all
 * consumers — including during ACC OFF sentry mode when the head unit stays
 * awake (charging, surveillance armed).
 *
 * LIFECYCLE:
 * - start() when pipeline starts (any mode, any ACC state)
 * - stop() when pipeline stops OR daemon shuts down
 */
class AvcHalWarmup {

    @Volatile
    private var keepAliveThread: Thread? = null

    /** Whether the keep-alive watchdog is currently running. */
    @Volatile
    var isActive: Boolean = false
        private set

    @Volatile
    var lastStartedAtMs: Long = 0L
        private set

    @Volatile
    var lastResult: Boolean = false
        private set

    @Volatile
    var lastReason: String = ""
        private set

    @Volatile
    var lastError: String = ""
        private set

    // ==================== One-Shot Warmup ====================

    /**
     * Launches com.byd.avc and blocks for [HAL_WARMUP_DELAY_MS].
     * Call this BEFORE opening the camera on ACC ON transitions.
     *
     * This is a blocking call — run it on a background thread.
     *
     * @param reason human-readable caller reason for logging/status
     * @return true if warmup completed, false if interrupted
     */
    @JvmOverloads
    @Synchronized
    fun warmupAndWait(reason: String? = "unspecified"): Boolean {
        lastStartedAtMs = System.currentTimeMillis()
        lastReason = reason ?: ""
        lastError = ""
        logger.info(
            "Warming up camera HAL via com.byd.avc (waiting " +
                HAL_WARMUP_DELAY_MS + "ms, reason=" + lastReason + ")..."
        )

        launchAvc()

        return try {
            Thread.sleep(HAL_WARMUP_DELAY_MS)
            logger.info("HAL warmup complete — safe to open camera")
            lastResult = true
            true
        } catch (e: InterruptedException) {
            logger.warn("HAL warmup interrupted")
            Thread.currentThread().interrupt()
            lastResult = false
            lastError = e.message ?: ""
            false
        }
    }

    // ==================== Keep-Alive Watchdog ====================

    /**
     * Starts the 60-second keep-alive watchdog.
     * Periodically re-launches com.byd.avc to prevent the system from killing it.
     *
     * Call this after the pipeline has started successfully.
     */
    @Synchronized
    fun startKeepAlive() {
        if (isActive) {
            logger.info("Keep-alive already running")
            return
        }

        isActive = true
        val thread = Thread({
            logger.info(
                "AVC keep-alive watchdog started (interval=" +
                    KEEP_ALIVE_INTERVAL_MS / 1000 + "s)"
            )

            while (isActive && !Thread.currentThread().isInterrupted) {
                try {
                    Thread.sleep(KEEP_ALIVE_INTERVAL_MS)
                } catch (e: InterruptedException) {
                    break
                }

                // Double-check conditions before poking
                if (!isActive) break

                // Re-poke com.byd.avc to keep the camera HAL alive.
                // Runs regardless of ACC state — when the head unit stays
                // awake during ACC OFF (charging, sentry mode), the system
                // still reaps com.byd.avc and the HAL goes cold. The owning
                // pipeline (CameraDaemon) calls stopKeepAlive() on shutdown.
                logger.info(
                    "Keep-alive: re-launching com.byd.avc (accOn=" +
                        AccMonitor.isAccOn() + ")"
                )
                launchAvc()
            }

            logger.info("AVC keep-alive watchdog stopped")
        }, "AvcKeepAlive")

        keepAliveThread = thread
        thread.isDaemon = true
        thread.start()
    }

    /**
     * Stops the keep-alive watchdog.
     * Call when pipeline stops, ACC goes OFF, or daemon shuts down.
     */
    @Synchronized
    fun stopKeepAlive() {
        if (!isActive) return

        isActive = false
        keepAliveThread?.interrupt()
        keepAliveThread = null
        logger.info("AVC keep-alive stopped")
    }

    // ==================== Internal ====================

    /**
     * Silently launches com.byd.avc via am start.
     * Runs as UID 2000 (shell) — has permission to launch activities.
     * Uses FLAG_ACTIVITY_NEW_TASK | FLAG_ACTIVITY_NO_ANIMATION to avoid
     * bringing it to the foreground or showing any visual disruption.
     */
    private fun launchAvc() {
        try {
            val process = Runtime.getRuntime().exec(AVC_LAUNCH_CMD)
            val exitCode = process.waitFor()
            if (exitCode != 0) {
                logger.warn("am start com.byd.avc exited with code $exitCode")
            }
        } catch (e: Exception) {
            logger.warn("Failed to launch com.byd.avc: " + e.message)
        }
    }

    companion object {
        private const val TAG = "AvcHalWarmup"
        private val logger = DaemonLogger.getInstance(TAG)

        /** Time to wait after launching com.byd.avc before opening our camera. */
        private const val HAL_WARMUP_DELAY_MS = 4000L

        /** Interval for keep-alive pokes to prevent system from killing com.byd.avc. */
        private const val KEEP_ALIVE_INTERVAL_MS = 60_000L

        /** The am start command to silently launch com.byd.avc without bringing it to foreground. */
        private val AVC_LAUNCH_CMD = arrayOf(
            "am", "start",
            "--user", "0",
            "-n", "com.byd.avc/.MainActivity",
            "-f", "0x10020000" // FLAG_ACTIVITY_NEW_TASK | FLAG_ACTIVITY_NO_ANIMATION
        )
    }
}
