package net.bladewatch.app.monitor

import android.content.Context

import net.bladewatch.app.daemon.CameraDaemon
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.telemetry.TelemetryDataCollector

import java.lang.reflect.Method

/**
 * Gear Monitor — polling-based gear position monitoring.
 *
 * Uses polling instead of AbsBYDAutoGearboxListener because the BYD framework's
 * internal learningEPB() method crashes with a UID mismatch when running as shell
 * (UID 2000). The crash kills the BYD device manager's HandlerThread and cascades
 * into daemon restart loops.
 *
 * Polls getGearboxAutoModeType() every 200ms — fast enough for gear change detection
 * while avoiding the listener crash path entirely.
 */
class GearMonitor private constructor() {

    private var context: Context? = null
    private var gearboxDevice: Any? = null
    private var getGearMethod: Method? = null
    private var pollThread: Thread? = null

    /** Check if running. */
    @Volatile
    var isRunning: Boolean = false
        private set

    /**
     * Get current gear as read off the BYD SDK, unfiltered.
     *
     * This is the RAW sensor value. Safety-critical callers (the motion interlock —
     * `DrivingSafetyGuard` / `VehicleCommandRouter`) MUST use this, not
     * [getEffectiveGear] — see that method's doc for why.
     */
    @Volatile
    var currentGear: Int = GEAR_P
        private set

    /** Get last update time. */
    var lastUpdateTime: Long = 0
        private set

    // TelemetryDataCollector reference — when set, read gear from its cached snapshot
    // instead of polling the BYD device directly (avoids duplicate CAN bus reads)
    @Volatile
    private var telemetrySource: TelemetryDataCollector? = null

    /** Initialize with context. */
    fun init(context: Context?) {
        this.context = context
        logger.info("GearMonitor initialized")
    }

    /**
     * Set the TelemetryDataCollector as the gear data source.
     * When set and its poller is running, GearMonitor reads gear from the cached
     * snapshot instead of polling the BYD device directly — eliminating duplicate
     * CAN bus reads.
     */
    fun setTelemetrySource(source: TelemetryDataCollector?) {
        telemetrySource = source
    }

    /** Start monitoring gear changes via polling. */
    fun start() {
        if (isRunning) {
            logger.warn("Already running")
            return
        }

        try {
            logger.info("Starting gear monitor...")

            // Get gearbox device instance via reflection
            val gearboxClass =
                Class.forName("android.hardware.bydauto.gearbox.BYDAutoGearboxDevice")
            val getInstance = gearboxClass.getMethod("getInstance", Context::class.java)
            val device = getInstance.invoke(null, context)
            gearboxDevice = device

            if (device == null) {
                logger.error("BYDAutoGearboxDevice.getInstance() returned null")
                return
            }

            // Cache the getter method
            val gearMethod = gearboxClass.getMethod("getGearboxAutoModeType")
            getGearMethod = gearMethod

            // Get initial gear state
            currentGear = gearMethod.invoke(device) as Int
            lastUpdateTime = System.currentTimeMillis()
            logger.info("Initial gear: " + gearToString(currentGear))

            isRunning = true

            // Start polling thread
            val thread = Thread({
                while (isRunning) {
                    try {
                        Thread.sleep(POLL_INTERVAL_MS)
                        if (!isRunning) break

                        // Prefer TelemetryDataCollector's cached snapshot to avoid
                        // duplicate CAN bus reads when the overlay poller is running
                        val snap = telemetrySource?.getLatestSnapshot()
                        val gear =
                            if (snap != null &&
                                (System.currentTimeMillis() - snap.timestampMs) < 1000
                            ) {
                                // Snapshot is fresh (< 1 second old) — use its gear value
                                snap.gearMode
                            } else {
                                // No fresh snapshot — poll device directly
                                gearMethod.invoke(device) as Int
                            }

                        if (gear != currentGear) {
                            logger.info(
                                "Gear changed: " + gearToString(currentGear) +
                                    " -> " + gearToString(gear)
                            )
                            currentGear = gear
                            lastUpdateTime = System.currentTimeMillis()
                            CameraDaemon.onGearChanged(gear)
                        }
                    } catch (e: InterruptedException) {
                        break
                    } catch (e: Exception) {
                        // Don't crash the poll thread — just log and retry
                        logger.debug("Gear poll error: " + e.message)
                        try {
                            Thread.sleep(1000)
                        } catch (ie: InterruptedException) {
                            break
                        }
                    }
                }
            }, "GearPoll")
            pollThread = thread
            thread.isDaemon = true
            thread.start()

            logger.info("Gear monitor started successfully")

            // Notify initial state
            CameraDaemon.onGearChanged(currentGear)
        } catch (e: Exception) {
            logger.error("Failed to start gear monitor: " + e.message)
            e.printStackTrace()
        }
    }

    /** Stop monitoring. */
    fun stop() {
        if (!isRunning) {
            return
        }

        isRunning = false
        pollThread?.interrupt()
        pollThread = null
        gearboxDevice = null
        getGearMethod = null
        logger.info("Gear monitor stopped")
    }

    /**
     * Get gear for MODE-DECISION purposes: reports [GEAR_P] while
     * `ChargingDetector` says the vehicle is charging, regardless of the raw sensor
     * value. While plugged in and charging, the car is by definition stationary, and a
     * non-P gear read off the SDK in that state is noise (BladeWatch-nmao.2) — this exists
     * so that noise cannot start a drive recording.
     *
     * **Do not use this for anything safety-critical.** A car that is genuinely in a
     * driving gear at a charger (should never happen, but "should never happen" is not a
     * safety argument) must never be reported as parked to the motion interlock. Use
     * [currentGear] there.
     */
    fun getEffectiveGear(): Int {
        if (ChargingDetector.getInstance().isCharging()) {
            return GEAR_P
        }
        return currentGear
    }

    /**
     * Test seam — production code never calls this.
     *
     * Public rather than package-private because `GearMonitorChargingTest` is a Java test and
     * Kotlin mangles `internal` member names, which Java cannot spell.
     */
    fun setCurrentGearForTest(gear: Int) {
        currentGear = gear
    }

    companion object {
        private val logger = DaemonLogger.getInstance("GearMonitor")

        // Gear constants
        const val GEAR_P = 1
        const val GEAR_R = 2
        const val GEAR_N = 3
        const val GEAR_D = 4
        const val GEAR_M = 5
        const val GEAR_S = 6

        /** 5 Hz polling */
        private const val POLL_INTERVAL_MS = 200L

        private var instance: GearMonitor? = null

        @JvmStatic
        @Synchronized
        fun getInstance(): GearMonitor {
            return instance ?: GearMonitor().also { instance = it }
        }

        /** Convert gear to string. */
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
    }
}
