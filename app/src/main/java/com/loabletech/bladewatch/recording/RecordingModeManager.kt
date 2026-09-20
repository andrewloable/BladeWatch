package net.bladewatch.app.recording

import android.content.Context

import net.bladewatch.app.config.UnifiedConfigManager
import net.bladewatch.app.daemon.CameraDaemon
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.monitor.AccMonitor
import net.bladewatch.app.monitor.ChargingDetector
import net.bladewatch.app.monitor.GearMonitor
import net.bladewatch.app.proximity.ProximityGuardController
import net.bladewatch.app.surveillance.GpuSurveillancePipeline
import net.bladewatch.app.surveillance.PipelineRateController

/**
 * Recording Mode Manager
 *
 * Coordinates all recording modes with mutual exclusivity.
 *
 * Modes:
 * - NONE: No recording, pipeline stopped (DEFAULT)
 * - CONTINUOUS: Always recording when ACC ON
 * - DRIVE_MODE: Recording when in driving gears (D/R/S/M), stops in P/N
 * - PROXIMITY_GUARD: Radar-triggered recording in non-P gears (D/R/S/M/N), disabled in P
 *
 * Features:
 * - Mutual exclusivity enforcement
 * - Proper cleanup when switching modes
 * - Resource management (stops pipeline when NONE)
 * - Gear state awareness for DRIVE_MODE and PROXIMITY_GUARD
 * - ACC state awareness for CONTINUOUS mode
 */
class RecordingModeManager(
    private val context: Context,
    private val pipeline: GpuSurveillancePipeline
) {

    /** Recording modes for ACC ON state. */
    enum class Mode {
        /** No recording - saves resources (DEFAULT) */
        NONE,

        /** Always recording when ACC ON */
        CONTINUOUS,

        /** Recording when driving (not in P gear) */
        DRIVE_MODE,

        /** Recording on radar triggers when gear != P */
        PROXIMITY_GUARD
    }

    private val proximityController = ProximityGuardController(context, pipeline)

    /** Default: no recording */
    @Volatile
    var currentMode = Mode.NONE
        private set

    /** Default: ACC OFF — wait for AccSentryDaemon to confirm */
    @Volatile
    var isAccOn = false
        private set

    /** Default: Park */
    @Volatile
    var currentGear = GEAR_P
        private set

    // True once we've received at least one real ACC state change IPC (vs. only
    // the constructor's hardware probe). Used to keep the "wasOn=" log field
    // honest: on the first IPC after boot, accIsOn may already be true from the
    // probe, but there was no prior IPC, so reporting "wasOn=true" is misleading.
    @Volatile
    private var accIpcSeen = false

    // True if the current mode's pipeline/recording state is actually live.
    // Used to distinguish "ACC is on AND mode is running" from "ACC was set to
    // on but activation failed silently (pipeline init threw, etc.)".
    // Without this, a duplicate-event guard keyed only on accIsOn locks us out
    // of retrying activation on the next ACC ON IPC.
    @Volatile
    private var modeActive = false

    // True while ChargingDetector's fused state says the vehicle is charging. Gates
    // activation of CONTINUOUS and DRIVE_MODE only -- PROXIMITY_GUARD must keep working
    // at a public charger, which is exactly when radar triggers matter most.
    @Volatile
    private var chargingSuppressed = false

    private val chargingListener = ChargingDetector.FusedStateListener { isCharging, source ->
        onChargingStateChanged(isCharging, source)
    }

    init {
        // Load persisted mode from config
        loadPersistedMode()

        logger.info("RecordingModeManager initialized: mode=$currentMode")

        // Sync ACC state from AccMonitor if it's already been set by AccSentryDaemon
        if (queryAccStateFromHardware()) {
            isAccOn = true
            logger.info("ACC state from hardware: ON")
        }

        // Sync gear from GearMonitor if it has already started polling. Without
        // this the field stays at the GEAR_P default, and DRIVE_MODE /
        // PROXIMITY_GUARD auto-activate below silently no-ops if the daemon
        // restarted while the car was already in a driving gear. (GearMonitor
        // is started later in CameraDaemon init, so on cold start this often
        // returns GEAR_P regardless — that's fine; onGearChanged() will
        // activate the mode when GearMonitor delivers its first real gear.)
        try {
            val gm = GearMonitor.getInstance()
            if (gm.isRunning) {
                // getEffectiveGear(), not currentGear: this drives a MODE decision
                // (whether to auto-activate on boot), so a spurious non-P read while
                // charging must not be treated as a driving gear (BladeWatch-nmao.2).
                val gearNow = gm.getEffectiveGear()
                if (gearNow != currentGear) {
                    logger.info(
                        "Constructor gear sync from GearMonitor: " +
                            gearToString(currentGear) + " -> " + gearToString(gearNow)
                    )
                    currentGear = gearNow
                }
            }
        } catch (e: Exception) {
            logger.debug("Constructor GearMonitor sync skipped: " + e.message)
        }

        // Seed from the current fused charging state BEFORE the auto-activate block
        // below, or a daemon that starts while already plugged in would record until
        // the session ends instead of starting suppressed.
        chargingSuppressed = ChargingDetector.getInstance().isCharging()
        ChargingDetector.getInstance().addFusedStateListener(chargingListener)

        // Activate the loaded mode if conditions are met.
        // CONTINUOUS: activate immediately (accIsOn defaults to true)
        // DRIVE_MODE: activate if in driving gear
        // PROXIMITY_GUARD: activate if gear != P
        // NONE: no action needed
        //
        // CRITICAL: route through activateModeWithWarmup() instead of calling
        // activateMode() directly. After a hard reboot the BYD camera HAL has
        // not been poked by com.byd.avc yet, so opening the camera before
        // warmup leaves it in a wedged state where pipeline.start() fails
        // silently. The result was that CONTINUOUS recording never started
        // until the user cycled ACC OFF → ON (the IPC path runs warmup).
        if (currentMode == Mode.CONTINUOUS && isAccOn) {
            logger.info("Auto-activating CONTINUOUS mode on startup")
            activateModeWithWarmup(currentMode, "boot-auto-activate")
        } else if (currentMode == Mode.DRIVE_MODE && isDrivingGear(currentGear) && isAccOn) {
            logger.info(
                "Auto-activating DRIVE_MODE on startup (gear=" + gearToString(currentGear) + ")"
            )
            activateModeWithWarmup(currentMode, "boot-auto-activate")
        } else if (currentMode == Mode.PROXIMITY_GUARD && currentGear != GEAR_P && isAccOn) {
            logger.info(
                "Auto-activating PROXIMITY_GUARD on startup (gear=" +
                    gearToString(currentGear) + ")"
            )
            activateModeWithWarmup(currentMode, "boot-auto-activate")
        }

        // Belt-and-suspenders re-sync. Catches all the cold-start failure
        // modes uniformly: GearMonitor not yet running, AccSentryDaemon hasn't
        // pushed initial state yet, pipeline init still in flight, IPC server
        // not yet listening when AccSentryDaemon tried to push, etc. Runs once
        // a few seconds after construction; idempotent if mode is already
        // active (modeActive guard in onAccStateChanged + onGearChanged).
        scheduleColdStartResync()
    }

    private fun scheduleColdStartResync() {
        Thread({
            try {
                Thread.sleep(COLD_START_RESYNC_DELAY_MS)
            } catch (ie: InterruptedException) {
                Thread.currentThread().interrupt()
                return@Thread
            }
            try {
                resyncFromHardware("cold-start")
            } catch (e: Exception) {
                logger.warn("Cold-start re-sync error: " + e.message)
            }
        }, "RecordingModeResync").start()
    }

    /**
     * Re-query authoritative ACC + gear from hardware/monitors and re-drive
     * mode activation if state has drifted from what we currently believe.
     * Used both for cold-start re-sync and for any later resync hook.
     */
    @Synchronized
    fun resyncFromHardware(reason: String) {
        val hwAcc = queryAccStateFromHardware()
        var hwGear = currentGear
        try {
            val gm = GearMonitor.getInstance()
            if (gm.isRunning) {
                // getEffectiveGear(): re-sync also drives mode-activation retries, so the
                // same charging noise filter applies (BladeWatch-nmao.2).
                hwGear = gm.getEffectiveGear()
            }
        } catch (ignored: Exception) {
            logger.warn("GearMonitor unavailable during resync: " + ignored.message)
        }

        val accChanged = hwAcc != isAccOn
        val gearChanged = hwGear != currentGear
        logger.info(
            "Re-sync (" + reason + "): hwAcc=" + hwAcc + " accIsOn=" + isAccOn +
                ", hwGear=" + gearToString(hwGear) + " currentGear=" + gearToString(currentGear) +
                ", mode=" + currentMode + ", modeActive=" + modeActive
        )

        if (gearChanged) {
            // Route through the public handler so existing
            // activate/deactivate logic and modeActive bookkeeping run.
            onGearChanged(hwGear)
        }
        if (accChanged) {
            onAccStateChanged(hwAcc)
            return
        }

        // ACC state unchanged but mode might have failed to start at construction.
        // Retry activation if conditions are met and modeActive is false. Use
        // the warmup path so a retried activation that follows a failed
        // cold-start (camera HAL wedged, pipeline.start() returned with
        // isRunning()==false) actually pokes com.byd.avc this time around.
        if (isAccOn && !modeActive) {
            if (currentMode == Mode.CONTINUOUS) {
                logger.info("Re-sync retry: activating CONTINUOUS")
                activateModeWithWarmup(currentMode, "resync-retry")
            } else if (currentMode == Mode.DRIVE_MODE && isDrivingGear(currentGear)) {
                logger.info(
                    "Re-sync retry: activating DRIVE_MODE (gear=" +
                        gearToString(currentGear) + ")"
                )
                activateModeWithWarmup(currentMode, "resync-retry")
            } else if (currentMode == Mode.PROXIMITY_GUARD && currentGear != GEAR_P) {
                logger.info(
                    "Re-sync retry: activating PROXIMITY_GUARD (gear=" +
                        gearToString(currentGear) + ")"
                )
                activateModeWithWarmup(currentMode, "resync-retry")
            }
        }
    }

    /**
     * Run the AVC HAL warmup on a background thread and then call
     * activateMode(mode) under the manager lock. Mirrors the warmup-then-
     * activate path used by onAccStateChanged() so cold-start auto-activation
     * doesn't race with com.byd.avc's HAL initialization.
     *
     * Skips warmup if the pipeline is already running (camera is open, no
     * need to poke com.byd.avc) — same heuristic the IPC path uses.
     */
    private fun activateModeWithWarmup(mode: Mode, reason: String) {
        if (mode == Mode.NONE) {
            return
        }
        Thread({
            // Only warmup if pipeline isn't already running.
            if (!pipeline.isRunning) {
                if (!CameraDaemon.ensureAvcWarmupStarted(
                        "RecordingModeManager.activateModeWithWarmup:$reason"
                    )
                ) {
                    logger.warn(
                        "AVC warmup interrupted ($reason) — skipping mode activation"
                    )
                    return@Thread
                }
            }
            synchronized(this@RecordingModeManager) {
                if (!isAccOn) {
                    logger.info(
                        "ACC turned OFF during warmup ($reason) — skipping mode activation"
                    )
                    return@synchronized
                }
                val gearNow = currentGear
                // Re-check gear gates against the live value, in case it changed
                // during the 4s warmup sleep.
                if (mode == Mode.DRIVE_MODE && !isDrivingGear(gearNow)) {
                    logger.info(
                        "DRIVE_MODE waiting for driving gear (current=" +
                            gearToString(gearNow) + ") — " + reason
                    )
                    return@synchronized
                }
                if (mode == Mode.PROXIMITY_GUARD && gearNow == GEAR_P) {
                    logger.info("PROXIMITY_GUARD waiting for gear != P — $reason")
                    return@synchronized
                }
                if (modeActive && pipeline.isRunning && pipeline.isNormalRecordingMode) {
                    logger.info(
                        "Mode $mode already active — skipping re-activation ($reason)"
                    )
                    return@synchronized
                }
                activateMode(mode)
            }
        }, "ModeWarmup-$reason").start()
    }

    /**
     * Set recording mode.
     * Enforces mutual exclusivity by deactivating current mode before activating new.
     */
    @Synchronized
    fun setMode(mode: Mode) {
        if (mode == currentMode) {
            logger.debug("Mode already set to: $mode")
            return
        }

        logger.info("Changing recording mode: $currentMode -> $mode")

        // Sync ACC state — query hardware directly for authoritative state
        val actualAccState = queryAccStateFromHardware()
        if (actualAccState != isAccOn) {
            logger.info("Syncing ACC state: $isAccOn -> $actualAccState")
            isAccOn = actualAccState
        }

        // Sync gear state from GearMonitor (authoritative source)
        try {
            val gearMonitor = GearMonitor.getInstance()
            if (gearMonitor.isRunning) {
                // getEffectiveGear(): setMode() uses this to decide whether to immediately
                // activate DRIVE_MODE/PROXIMITY_GUARD, so the same charging noise filter
                // applies (BladeWatch-nmao.2).
                val actualGear = gearMonitor.getEffectiveGear()
                if (actualGear != currentGear) {
                    logger.info(
                        "Syncing gear from GearMonitor: " + gearToString(currentGear) +
                            " -> " + gearToString(actualGear)
                    )
                    currentGear = actualGear
                }
            }
        } catch (e: Exception) {
            logger.warn("Could not sync gear: " + e.message)
        }

        // Deactivate current mode
        deactivateMode(currentMode)

        // Update current mode
        val oldMode = currentMode
        currentMode = mode

        // Persist mode to config EARLY — before activation which might fail
        persistMode(mode)

        // Activate new mode based on appropriate trigger
        if (mode == Mode.DRIVE_MODE) {
            // DRIVE_MODE activates when in driving gears (D/R/S/M)
            if (isDrivingGear(currentGear)) {
                activateMode(mode)
            } else {
                logger.info(
                    "Gear is " + gearToString(currentGear) +
                        " - DRIVE_MODE will activate when in D/R/S/M"
                )
            }
        } else if (mode == Mode.PROXIMITY_GUARD) {
            // PROXIMITY_GUARD activates in all gears except P
            if (currentGear != GEAR_P) {
                activateMode(mode)
            } else {
                logger.info("Gear is P - PROXIMITY_GUARD will activate when gear changes")
            }
        } else if (isAccOn) {
            // CONTINUOUS and NONE activate when ACC is ON
            activateMode(mode)
        } else {
            logger.info("ACC is OFF - mode will activate when ACC turns ON")
        }

        logger.info("Recording mode changed: $oldMode -> $mode")
    }

    /**
     * Notify of ACC state change.
     * Activates/deactivates modes that depend on ACC state.
     */
    @Synchronized
    fun onAccStateChanged(isOn: Boolean) {
        // wasOn reflects "was ACC observed ON via a *prior IPC*?" — not the
        // hardware probe value seeded in the constructor. Without this guard,
        // the very first ACC IPC after boot logs "wasOn=true" (because the
        // probe set it) and triggers the "retrying activation" path, which is
        // misleading: there was no prior activation to retry.
        val wasOn = accIpcSeen && isAccOn
        val firstIpc = !accIpcSeen
        accIpcSeen = true

        logger.info(
            "ACC state changed: " + (if (isOn) "ON" else "OFF") + " (mode=" + currentMode +
                ", wasOn=" + wasOn + (if (firstIpc) " [first IPC after boot]" else "") +
                ", modeActive=" + modeActive + ")"
        )

        isAccOn = isOn

        // BladeWatch-t1lg.3: same ACC source, no second listener -- forward the edge to the
        // detection-rate controller if it has been constructed yet (it lives on the camera
        // pipeline, which may not exist this early in daemon startup).
        PipelineRateController.getInstance()?.setAccOn(isOn)

        if (isOn) {
            // Suppress only if the mode is genuinely already running. Keying
            // the guard purely on `wasOn` was wrong: if a prior activation
            // failed silently (constructor auto-activate threw, pipeline
            // wasn't ready, etc.), accIsOn was still true and the next real
            // ACC ON IPC was discarded as a "duplicate," leaving the user
            // with no recording until the next ACC OFF/ON cycle.
            if (wasOn && modeActive) {
                logger.debug("ACC already ON and mode active, ignoring duplicate notification")
                return
            }
            if (wasOn && !modeActive) {
                logger.info("ACC was already ON but mode not active — retrying activation")
            }

            // ACC is ON — if pipeline is already running, keep it running.
            // No need to stop and restart — the camera is already open and the
            // mode will continue using it. Stopping causes a HAL teardown
            // (stopPreview + close) that disrupts the native DVR.
            // If surveillance was active, CameraDaemon.onAccStateChanged handles
            // disabling it separately.

            // Start AVC keep-alive and activate mode after warmup
            val modeToActivate = currentMode
            Thread({
                // Only warmup if pipeline isn't already running
                // (if it's running, camera is already open — no need to poke com.byd.avc)
                if (!pipeline.isRunning) {
                    if (!CameraDaemon.ensureAvcWarmupStarted(
                            "RecordingModeManager.onAccStateChanged"
                        )
                    ) {
                        logger.warn("AVC warmup interrupted — skipping mode activation")
                        return@Thread
                    }
                }

                synchronized(this@RecordingModeManager) {
                    if (!isAccOn) {
                        logger.info(
                            "ACC turned OFF during reacquire delay — skipping mode activation"
                        )
                        return@synchronized
                    }

                    // Use CURRENT gear, not the gear at ACC ON time — gear may have changed
                    // during the delay (e.g., P→D or D→P)
                    val gearNow = currentGear

                    if (modeToActivate == Mode.DRIVE_MODE && !isDrivingGear(gearNow)) {
                        logger.info(
                            "DRIVE_MODE waiting for driving gear (current=" +
                                gearToString(gearNow) + ")"
                        )
                    } else if (modeToActivate == Mode.PROXIMITY_GUARD && gearNow == GEAR_P) {
                        logger.info("PROXIMITY_GUARD waiting for gear != P")
                    } else if (modeToActivate != Mode.NONE) {
                        // Skip only if the desired mode's recording is genuinely
                        // already running. Previously this checked
                        // pipeline.isRecording alone, which returns true for
                        // SURVEILLANCE recordings still finalizing at the moment
                        // of ACC ON — causing CONTINUOUS/DRIVE_MODE to be skipped
                        // and never started until the next state transition.
                        if (modeActive && pipeline.isRunning &&
                            pipeline.isNormalRecordingMode
                        ) {
                            logger.info(
                                "Mode $modeToActivate already active — skipping re-activation"
                            )
                        } else {
                            activateMode(modeToActivate)
                        }
                    }
                }
            }, "AccOnReacquire").start()
        } else {
            // ACC turned OFF — always stop the pipeline regardless of mode.
            // Recording modes only operate when ACC is ON. Surveillance (if enabled)
            // will be started separately by CameraDaemon.onAccStateChanged.
            // pipeline.isRunning guards against duplicate OFF events doing
            // unnecessary teardown work.
            CameraDaemon.stopAvcKeepAlive()
            if (pipeline.isRunning) {
                pipeline.stopRecording()
                pipeline.stop()
            }
        }
    }

    /**
     * Notify of gear state change.
     * - DRIVE_MODE: activates on D/R/S/M, deactivates on P/N
     * - PROXIMITY_GUARD: activates on D/R/S/M/N, deactivates on P
     *
     * @param gear The new gear position (GEAR_P, GEAR_R, GEAR_N, GEAR_D, etc.)
     */
    @Synchronized
    fun onGearChanged(gear: Int) {
        // Suppress no-op notifications — GearMonitor.start() calls onGearChanged()
        // once with the initial gear so the rest of the system gets primed, but
        // for RecordingModeManager that often matches the constructor default
        // and there's nothing to do. Logging it as a "P -> P" change is just noise.
        if (gear == currentGear) {
            return
        }

        val gearName = gearToString(gear)
        logger.info(
            "Gear changed: " + gearToString(currentGear) + " -> " + gearName +
                " (mode=" + currentMode + ")"
        )

        val previousGear = currentGear
        currentGear = gear

        // Only DRIVE_MODE and PROXIMITY_GUARD respond to gear changes
        if (currentMode != Mode.DRIVE_MODE && currentMode != Mode.PROXIMITY_GUARD) {
            logger.debug("Mode $currentMode does not respond to gear changes")
            return
        }

        if (currentMode == Mode.DRIVE_MODE) {
            // DRIVE_MODE: record when driving (D/R/S/M) AND ACC is ON
            val wasDriving = isDrivingGear(previousGear)
            val nowDriving = isDrivingGear(gear)

            // Use modeActive (not just gear edge) so cold-start — where
            // GearMonitor's first real reading arrives after construction with
            // currentGear default GEAR_P — also activates DRIVE_MODE on the
            // first delivered driving gear, even though the "edge" condition
            // (wasDriving=false → nowDriving=true) only fires once.
            if (nowDriving && isAccOn && !modeActive) {
                logger.info("Driving gear with mode not yet active - activating DRIVE_MODE recording")
                // Route through warmup. If the user shifts D within the 4s
                // AVC warmup window after ACC ON, calling activateMode()
                // directly would open the camera before com.byd.avc finished
                // initializing the HAL → wedged camera, no recording. The
                // warmup helper short-circuits when the pipeline is already
                // running, so it's a no-op cost when not needed.
                activateModeWithWarmup(Mode.DRIVE_MODE, "gear-to-driving")
            } else if (!nowDriving && (wasDriving || modeActive)) {
                logger.info("Shifted to parked gear - deactivating DRIVE_MODE recording")
                deactivateMode(Mode.DRIVE_MODE)
            } else if (nowDriving && !isAccOn) {
                logger.info("Driving gear but ACC OFF - DRIVE_MODE will activate when ACC turns ON")
            }
        } else if (currentMode == Mode.PROXIMITY_GUARD) {
            // PROXIMITY_GUARD: active in all gears except P, only when ACC is ON
            val wasInP = previousGear == GEAR_P
            val nowInP = gear == GEAR_P

            if (!nowInP && isAccOn && !modeActive) {
                logger.info("Out of P with mode not yet active - activating PROXIMITY_GUARD")
                // Same rationale as DRIVE_MODE above — protect against the
                // user shifting out of P before the AVC HAL is warmed up.
                activateModeWithWarmup(Mode.PROXIMITY_GUARD, "gear-out-of-P")
            } else if (nowInP && (!wasInP || modeActive)) {
                logger.info("Shifted to P - deactivating PROXIMITY_GUARD")
                deactivateMode(Mode.PROXIMITY_GUARD)
            } else if (!nowInP && !isAccOn) {
                logger.info("Not in P but ACC OFF - PROXIMITY_GUARD will activate when ACC turns ON")
            }
        }
    }

    // ==================== MODE ACTIVATION ====================

    /**
     * Fired on genuine charging-state transitions only (see FusedStateListener contract).
     * Deactivates the running mode the instant charging starts; on the reverse edge, retries
     * activation through the same warmup path the constructor and resync use, so a still-open
     * pipeline resumes recording with no teardown/restart.
     */
    @Synchronized
    private fun onChargingStateChanged(isCharging: Boolean, source: String) {
        if (chargingSuppressed == isCharging) {
            return
        }
        chargingSuppressed = isCharging
        logger.info(
            "Charging state changed (" + source + "): chargingSuppressed=" + chargingSuppressed +
                " (mode=" + currentMode + ")"
        )

        if (currentMode != Mode.CONTINUOUS && currentMode != Mode.DRIVE_MODE) {
            return // PROXIMITY_GUARD (and NONE) are never touched by charging state
        }
        if (chargingSuppressed) {
            deactivateMode(currentMode)
        } else if (isAccOn) {
            if (currentMode == Mode.CONTINUOUS) {
                activateModeWithWarmup(currentMode, "charging-ended")
            } else if (currentMode == Mode.DRIVE_MODE && isDrivingGear(currentGear)) {
                activateModeWithWarmup(currentMode, "charging-ended")
            }
        }
    }

    private fun activateMode(mode: Mode) {
        if (isSuppressedByCharging(mode, chargingSuppressed)) {
            logger.info("Skipping activation of $mode — vehicle is charging")
            modeActive = false
            return
        }
        logger.info("Activating mode: $mode")

        // SOTA: Stop any manual recording before activating a mode
        // This ensures mode-managed recording takes precedence over manual recording
        if (pipeline.isNormalRecordingMode) {
            logger.info("Stopping manual recording before activating mode: $mode")
            pipeline.stopRecording()
        }

        // If user changed cameraFps in config since the encoder was built, force
        // a clean stop here so the per-mode start() below runs through init() and
        // picks up the new FPS via loadTargetFps(). Without this, FPS changes
        // applied while the pipeline stayed alive across ACC OFF (sentry mode)
        // wouldn't reach the encoder until the next full app restart.
        //
        // Safe at this exact moment: ACC has just turned ON, surveillance was
        // already disabled by CameraDaemon.onAccOn() before this thread runs,
        // and CONTINUOUS/DRIVE_MODE recording hasn't started yet — there is no
        // active recording state to lose.
        if (mode != Mode.NONE && pipeline.isFpsConfigStale) {
            logger.info("Camera FPS config changed — restarting pipeline to apply")
            pipeline.stop()
        }

        when (mode) {
            Mode.NONE -> {
                // Stop pipeline to save resources
                if (pipeline.isRunning) {
                    logger.info("Stopping pipeline for NONE mode (resource saving)")
                    pipeline.stop()
                    CameraDaemon.stopAvcKeepAlive()
                }
                modeActive = false
            }

            Mode.CONTINUOUS -> {
                // Start pipeline and recording
                try {
                    if (!pipeline.isRunning) {
                        logger.info("Starting pipeline for CONTINUOUS mode")
                        pipeline.start(false)
                    }
                    // Pipeline.start() blocks ~2s for GL init. Recorder should be ready.
                    if (pipeline.isRunning && !pipeline.isRecording) {
                        pipeline.startRecording()
                    }
                    // Start AVC keep-alive (pipeline is now running with ACC ON)
                    CameraDaemon.startAvcKeepAliveIfNeeded()
                    modeActive = pipeline.isRunning
                } catch (e: Exception) {
                    logger.error("Failed to start CONTINUOUS mode: " + e.message)
                    modeActive = false
                }
            }

            Mode.DRIVE_MODE -> {
                // Start recording when driving (gear is D/R/S/M)
                try {
                    if (!pipeline.isRunning) {
                        logger.info("Starting pipeline for DRIVE_MODE")
                        pipeline.start(false)
                    }
                    // Pipeline.start() blocks ~2s for GL init. Recorder should be ready.
                    if (pipeline.isRunning && !pipeline.isRecording) {
                        logger.info("Starting DRIVE_MODE recording")
                        pipeline.startRecording()
                    }
                    // Start AVC keep-alive (pipeline is now running with ACC ON)
                    CameraDaemon.startAvcKeepAliveIfNeeded()
                    modeActive = pipeline.isRunning
                } catch (e: Exception) {
                    logger.error("Failed to start DRIVE_MODE: " + e.message)
                    modeActive = false
                }
            }

            Mode.PROXIMITY_GUARD -> {
                // Start pipeline (without recording) and proximity controller
                try {
                    if (!pipeline.isRunning) {
                        logger.info("Starting pipeline for PROXIMITY_GUARD mode")
                        pipeline.start(false) // Don't auto-start recording
                    }
                    proximityController.start()
                    // Start AVC keep-alive (pipeline is now running with ACC ON)
                    CameraDaemon.startAvcKeepAliveIfNeeded()
                    modeActive = pipeline.isRunning
                } catch (e: Exception) {
                    logger.error("Failed to start PROXIMITY_GUARD mode: " + e.message)
                    modeActive = false
                }
            }
        }
    }

    private fun deactivateMode(mode: Mode) {
        logger.info("Deactivating mode: $mode")

        // Whatever was active is no longer active. Set this up front so the
        // duplicate-event guard in onAccStateChanged() will allow re-activation.
        modeActive = false

        // Check if surveillance should be preserved — don't stop pipeline during ACC OFF
        // (surveillance/sentry mode needs the pipeline running)
        val keepPipelineRunning = !isAccOn

        if (keepPipelineRunning) {
            logger.info("ACC is OFF — keeping pipeline running for surveillance")
        }

        when (mode) {
            Mode.NONE -> {
                // Already stopped
            }

            Mode.CONTINUOUS -> {
                // Stop recording but keep pipeline if ACC is OFF (surveillance running)
                pipeline.stopRecording()
                if (pipeline.isRunning && !keepPipelineRunning) {
                    pipeline.stop()
                    CameraDaemon.stopAvcKeepAlive()
                }
            }

            Mode.DRIVE_MODE -> {
                // Stop recording only — keep pipeline alive for quick resume on next gear change.
                // Full pipeline teardown (camera/EGL/encoder release) makes restart unreliable
                // and slow. Only stop the pipeline on full ACC OFF (handled by onAccStateChanged).
                pipeline.stopRecording()
            }

            Mode.PROXIMITY_GUARD -> {
                // Stop proximity controller but keep pipeline if ACC is OFF (surveillance running)
                proximityController.stop()
                if (pipeline.isRunning && !keepPipelineRunning) {
                    pipeline.stop()
                    CameraDaemon.stopAvcKeepAlive()
                }
            }
        }
    }

    // ==================== CONFIG PERSISTENCE ====================

    /**
     * Query ACC state directly from BYD hardware.
     * Falls back to AccMonitor if hardware query fails.
     */
    private fun queryAccStateFromHardware(): Boolean {
        // Try direct hardware query via BYDAutoBodyworkDevice
        try {
            val deviceClass =
                Class.forName("android.hardware.bydauto.bodywork.BYDAutoBodyworkDevice")
            val getInstance = deviceClass.getMethod("getInstance", Context::class.java)
            val device = getInstance.invoke(null, context)
            if (device != null) {
                val level = deviceClass.getMethod("getPowerLevel").invoke(device) as Int
                // Power levels: 0=OFF, 1=ACC, 2=ON, 3=START
                val isOn = level >= 2
                logger.debug(
                    "Hardware power level: " + level + " (ACC " + (if (isOn) "ON" else "OFF") + ")"
                )
                return isOn
            }
        } catch (e: Exception) {
            logger.debug("Hardware ACC query failed: " + e.message)
        }

        // Fallback to AccMonitor
        return AccMonitor.isAccOn()
    }

    private fun loadPersistedMode() {
        try {
            val modeStr = UnifiedConfigManager.getRecording().optString("mode", "NONE")

            currentMode = try {
                Mode.valueOf(modeStr.uppercase()).also {
                    logger.info("Loaded persisted mode: $it")
                }
            } catch (e: IllegalArgumentException) {
                logger.warn("Invalid persisted mode: $modeStr, using NONE")
                Mode.NONE
            }
        } catch (e: Exception) {
            logger.error("Failed to load persisted mode: " + e.message)
            currentMode = Mode.NONE
        }
    }

    private fun persistMode(mode: Mode) {
        try {
            val recording = UnifiedConfigManager.getRecording()
            recording.put("mode", mode.name)
            UnifiedConfigManager.setRecording(recording)
            logger.debug("Persisted mode: $mode")
        } catch (e: Exception) {
            logger.error("Failed to persist mode: " + e.message)
        }
    }

    /** Reload configuration (call when config changes). */
    @Synchronized
    fun reloadConfig() {
        loadPersistedMode()
        proximityController.reloadConfig()
        logger.info("Config reloaded: mode=$currentMode")
    }

    /** Shutdown and cleanup resources. */
    fun shutdown() {
        logger.info("Shutting down RecordingModeManager...")
        ChargingDetector.getInstance().removeFusedStateListener(chargingListener)
        CameraDaemon.stopAvcKeepAlive()
        deactivateMode(currentMode)
        proximityController.shutdown()
        logger.info("RecordingModeManager shutdown complete")
    }

    companion object {
        private val logger = DaemonLogger.getInstance("RecordingModeManager")

        // Gear constants (from BYDAutoGearboxDevice)
        const val GEAR_P = 1
        const val GEAR_R = 2
        const val GEAR_N = 3
        const val GEAR_D = 4
        const val GEAR_M = 5
        const val GEAR_S = 6

        /**
         * 8s gives the constructor's warmup-then-activate (≈4s warmup + ~2s pipeline
         * init) time to finish before the resync second-guesses it. With the prior
         * 5s value the resync would frequently fire while warmup was still sleeping,
         * see modeActive=false, and queue a redundant retry.
         */
        private const val COLD_START_RESYNC_DELAY_MS = 8_000L

        /**
         * Check if gear is a driving gear (D/R/S/M/N).
         * N is included because BYD Auto Hold reports N while the car is stopped at a
         * traffic light with the driver's foot off the brake. Excluding N would cause
         * DRIVE_MODE recording to stop/start on every Auto Hold engage/release cycle.
         * This matches TripDetector.isDrivingGear which also includes N.
         */
        @JvmStatic
        fun isDrivingGear(gear: Int): Boolean =
            gear == GEAR_D || gear == GEAR_R || gear == GEAR_N || gear == GEAR_S || gear == GEAR_M

        /**
         * Check if gear is a parked gear (P only).
         * N is NOT parked — see isDrivingGear comment about Auto Hold.
         */
        @JvmStatic
        fun isParkedGear(gear: Int): Boolean = gear == GEAR_P

        /** Convert gear constant to string. */
        @JvmStatic
        fun gearToString(gear: Int): String = when (gear) {
            GEAR_P -> "P"
            GEAR_R -> "R"
            GEAR_N -> "N"
            GEAR_D -> "D"
            GEAR_M -> "M"
            GEAR_S -> "S"
            else -> "UNKNOWN($gear)"
        }

        /**
         * Pure policy: does charging suppress this mode? CONTINUOUS and DRIVE_MODE only --
         * PROXIMITY_GUARD is deliberately excluded. Extracted as a pure static so it is
         * unit-testable without Context/GpuSurveillancePipeline/a real ChargingDetector,
         * and so [activateMode] has exactly one gate to consult instead of duplicating this
         * decision at every call site that can trigger activation.
         */
        @JvmStatic
        fun isSuppressedByCharging(mode: Mode, charging: Boolean): Boolean =
            charging && (mode == Mode.CONTINUOUS || mode == Mode.DRIVE_MODE)
    }
}
