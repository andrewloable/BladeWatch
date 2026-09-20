package net.bladewatch.app.proximity

import android.content.Context

import net.bladewatch.app.config.UnifiedConfigManager
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.surveillance.GpuSurveillancePipeline

import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit

/**
 * Proximity Guard Controller
 *
 * Core state machine for Proximity Guard recording mode.
 *
 * State transitions:
 * - IDLE: Mode disabled or ACC OFF
 * - MONITORING: Radar listeners active, waiting for trigger
 * - RECORDING: Active recording in progress
 * - POST_RECORD: Countdown timer after radar goes safe
 *
 * Features:
 * - Smart continuation: If radar triggers during POST_RECORD, continues same recording
 * - Configurable pre/post buffers
 * - Automatic cleanup and resource management
 */
class ProximityGuardController(
    context: Context,
    pipeline: GpuSurveillancePipeline
) : ProximityRadarMonitor.TriggerCallback {

    /** Controller states. */
    enum class State {
        /** Not active */
        IDLE,

        /** Listening for radar triggers */
        MONITORING,

        /** Active recording */
        RECORDING,

        /** Countdown after radar safe */
        POST_RECORD
    }

    private var config: ProximityGuardConfig = loadConfig()

    private val radarMonitor = ProximityRadarMonitor(context, config.triggerLevel).also {
        it.setCallback(this)
    }

    private val recordingHandler = ProximityRecordingHandler(pipeline)

    @Volatile
    var currentState: State = State.IDLE
        private set

    private var postRecordTimer: ScheduledFuture<*>? = null

    /** Scheduler for the post-record timer. */
    private val scheduler: ScheduledExecutorService =
        Executors.newSingleThreadScheduledExecutor { r ->
            Thread(r, "ProximityPostRecordTimer").apply { isDaemon = true }
        }

    init {
        logger.info("ProximityGuardController initialized: $config")
    }

    /**
     * Start Proximity Guard mode.
     * Transitions from IDLE to MONITORING.
     *
     * Note: The "enabled" state is controlled by RecordingModeManager's mode selection.
     * When mode is PROXIMITY_GUARD, this controller should start regardless of config.enabled.
     */
    @Synchronized
    fun start() {
        if (currentState != State.IDLE) {
            logger.warn("Cannot start - already in state: $currentState")
            return
        }

        // Reload config in case it changed (for trigger level, pre/post record settings)
        config = loadConfig()

        // SOTA: Don't check config.isEnabled here - the mode selection in RecordingModeManager
        // is the source of truth for whether proximity guard should be active.
        // The config.enabled flag is deprecated/redundant.

        logger.info("Starting Proximity Guard mode...")
        transitionTo(State.MONITORING)
        radarMonitor.startListening()
    }

    /**
     * Stop Proximity Guard mode.
     * Transitions to IDLE.
     */
    @Synchronized
    fun stop() {
        logger.info("Stopping Proximity Guard mode (current state: $currentState)")

        // Stop radar listener
        radarMonitor.stopListening()

        // Stop recording if active
        if (currentState == State.RECORDING || currentState == State.POST_RECORD) {
            cancelPostRecordTimer()
            recordingHandler.stopRecording()
        }

        transitionTo(State.IDLE)
    }

    /** Check if active (not IDLE). */
    fun isActive(): Boolean = currentState != State.IDLE

    // ==================== TRIGGER CALLBACKS ====================

    @Synchronized
    override fun onProximityTrigger(area: Int, state: Int, level: String) {
        logger.info("onProximityTrigger: state=$currentState area=$area level=$level")

        when (currentState) {
            State.MONITORING -> {
                // Start new recording
                transitionTo(State.RECORDING)
                recordingHandler.startRecording(level)
            }

            State.POST_RECORD -> {
                // Smart continuation - cancel timer and extend recording
                logger.info("Extending recording: radar triggered during post-record countdown")
                cancelPostRecordTimer()
                transitionTo(State.RECORDING)
                // Recording continues - same file, just reset the post-record timer when safe
                recordingHandler.extendRecording(level)
            }

            State.RECORDING -> {
                // Already recording - extend by resetting any pending timers
                logger.debug("Already recording, extending duration")
                recordingHandler.extendRecording(level)
            }

            State.IDLE -> logger.warn("Received trigger while IDLE - should not happen")
        }
    }

    @Synchronized
    override fun onProximitySafe() {
        logger.info("onProximitySafe: state=$currentState")

        if (currentState == State.RECORDING) {
            // Start post-record countdown
            transitionTo(State.POST_RECORD)
            startPostRecordTimer()
        }
    }

    // ==================== STATE MACHINE ====================

    private fun transitionTo(newState: State) {
        if (currentState == newState) {
            return
        }

        logger.info("State transition: $currentState -> $newState")

        // Exit action. Only POST_RECORD has one; MONITORING and IDLE need no cleanup, and
        // RECORDING's recording is stopped by the caller, not here.
        if (currentState == State.POST_RECORD) {
            cancelPostRecordTimer()
        }

        currentState = newState

        // Entry actions for new state
        logger.info(
            when (newState) {
                State.IDLE -> "Entered IDLE state"
                State.MONITORING -> "Entered MONITORING state - waiting for radar triggers"
                State.RECORDING -> "Entered RECORDING state"
                State.POST_RECORD -> "Entered POST_RECORD state - countdown started"
            }
        )
    }

    // ==================== POST-RECORD TIMER ====================

    private fun startPostRecordTimer() {
        cancelPostRecordTimer() // Cancel any existing timer

        val postRecordSeconds = config.postRecordSeconds
        logger.info("Starting post-record timer: $postRecordSeconds seconds")

        postRecordTimer = scheduler.schedule(
            {
                synchronized(this) {
                    if (currentState == State.POST_RECORD) {
                        logger.info("Post-record timer expired - stopping recording")
                        recordingHandler.stopRecording()
                        transitionTo(State.MONITORING)
                    }
                }
            },
            postRecordSeconds.toLong(), TimeUnit.SECONDS
        )
    }

    private fun cancelPostRecordTimer() {
        postRecordTimer?.let {
            if (!it.isDone) {
                it.cancel(false)
                logger.debug("Post-record timer cancelled")
            }
        }
        postRecordTimer = null
    }

    // ==================== CONFIG ====================

    private fun loadConfig(): ProximityGuardConfig = try {
        ProximityGuardConfig.fromConfig(UnifiedConfigManager.getProximityGuard())
    } catch (e: Exception) {
        logger.error("Failed to load proximity config: " + e.message)
        ProximityGuardConfig.createDefault()
    }

    /** Reload configuration (call when config changes). */
    @Synchronized
    fun reloadConfig() {
        config = loadConfig()
        logger.info("Config reloaded: $config")
    }

    /** Shutdown and cleanup resources. */
    fun shutdown() {
        stop()
        scheduler.shutdown()
        try {
            if (!scheduler.awaitTermination(2, TimeUnit.SECONDS)) {
                scheduler.shutdownNow()
            }
        } catch (e: InterruptedException) {
            logger.warn("Interrupted while shutting down scheduler: " + e.message)
            Thread.currentThread().interrupt()
            scheduler.shutdownNow()
        }
        logger.info("ProximityGuardController shutdown complete")
    }

    companion object {
        private val logger = DaemonLogger.getInstance("ProximityGuardController")
    }
}
