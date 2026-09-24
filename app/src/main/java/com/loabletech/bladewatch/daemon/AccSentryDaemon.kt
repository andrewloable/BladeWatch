package net.bladewatch.app.daemon

import android.app.ActivityManager
import android.content.ContentResolver
import android.content.Context
import android.content.ContextWrapper
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.content.res.Resources
import android.hardware.bydauto.bodywork.AbsBYDAutoBodyworkListener
import android.hardware.bydauto.power.BYDAutoPowerDevice
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.Process
import android.os.SystemClock

import net.bladewatch.app.byd.BacklightController
import net.bladewatch.app.config.UnifiedConfigManager
import net.bladewatch.app.daemon.proxy.Safe
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.monitor.BatteryPowerData
import net.bladewatch.app.monitor.BatteryVoltageData
import net.bladewatch.app.monitor.ChargingStateData
import net.bladewatch.app.monitor.VehicleDataListener
import net.bladewatch.app.monitor.VehicleDataMonitor
import net.bladewatch.app.server.IpcTokenManager
import net.bladewatch.app.surveillance.SafeLocationManager

import org.json.JSONObject

import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.io.PrintWriter
import java.lang.reflect.Method
import java.net.Socket

/**
 * ACC Sentry Daemon - runs as shell user (UID 2000) via ADB shell.
 *
 * RESPONSIBILITIES:
 * 1. ACC state monitoring via BYD bodywork service
 * 2. Screen control (input keyevent) - MUST run as UID 2000
 * 3. Surveillance enable/disable via IPC to CameraDaemon
 * 4. MCU wake-up to keep hardware powered during sentry mode
 * 5. Backlight control and blocker activity management
 *
 * NOTE: Whitelisting and ACC Lock acquisition is handled by SentryDaemon (UID 1000).
 * This daemon focuses on ACC state detection and sentry mode management.
 */
object AccSentryDaemon {

    private const val TAG = "AccSentryDaemon"
    private var logger: DaemonLogger? = null

    // ==================== ENCRYPTED CONSTANTS (SOTA Java obfuscation) ====================
    // Decrypted at runtime via Safe.s() - AES-256-CBC with stack-based key reconstruction
    /** net.bladewatch.app */
    private fun APP_PACKAGE_NAME(): String = Safe.s("b+URlanuKqV+a8w43uR6VwE1hpEbteNkkdukhTGHkdY=")
    /** svc wifi enable */
    private fun CMD_WIFI_ENABLE(): String = Safe.s("GzzLDvODRsKARkPOXEZeIA==")
    /** /data/local/tmp */
    private fun PATH_DATA_LOCAL_TMP(): String = Safe.s("vuaMjrmBGBFh07qqnUuL8w==")

    // Power levels from BYDAutoBodyworkDevice
    private const val POWER_LEVEL_OFF = 0
    private const val POWER_LEVEL_ACC = 1
    private const val POWER_LEVEL_ON = 2
    private const val POWER_LEVEL_OK = 3

    @Volatile private var running = true
    @Volatile private var inSentryMode = false
    private var lastPowerLevel = -1
    private var lastMcuStatus = -1
    // Thread for the 10-second loop
    private var systemKeepAliveThread: Thread? = null
    private const val SYSTEM_KEEPALIVE_INTERVAL_MS = 10000L

    // Surveillance IPC
    private const val SURVEILLANCE_IPC_PORT = 19877
    @Volatile private var surveillanceEnabled = false

    // MCU wake timestamp (for voltage-triggered wake cooldown)
    @Volatile private var lastMcuWakeTime: Long = 0

    // ==================== ACTIVE VOLTAGE RECOVERY ====================
    // Thread handle for the active charging loop
    private var mcuChargingThread: Thread? = null
    // Pulse interval during active charging (45s keeps MCU awake without flooding CAN bus)
    private const val MCU_CHARGE_PULSE_INTERVAL_MS = 45000L

    // Context for BYD device access
    private var appContext: Context? = null

    // WakeLock for guaranteed CPU cycles
    private var wakeLock: PowerManager.WakeLock? = null

    // Daemon start time for uptime tracking
    private var startTime: Long = 0

    // ==================== STARTUP TIMING ====================
    private var _startTime: Long = 0
    private fun logT(step: String) {
        if (!UnifiedConfigManager.isTimingLogsEnabled()) return
        val now = System.currentTimeMillis()
        log("[STARTUP +" + (now - _startTime) + "ms @" + now + "] " + step)
    }

    // Handler for periodic status checks
    private var statusHandler: Handler? = null

    // ==================== CENTRALIZED MCU POWER HELPER ====================
    // Cached BYDAutoPowerDevice instance to avoid repeated reflection
    private var cachedPowerDevice: BYDAutoPowerDevice? = null

    // ==================== SPECIAL HARDWARE CONFIG (USB/POWER) ====================
    // Cached BYDAutoSpecialDevice for peripheral power control
    private var cachedSpecialDevice: Any? = null

    // Magic config IDs from BYD malware analysis (C1310c class)
    // These control the BCM's peripheral power rail behavior
    private const val SPECIAL_CONFIG_REMOTE_POWER_MODE = 782237711  // Keeps 5V rails active
    private const val SPECIAL_CONFIG_DATA_MODULE_POWER = 782237728  // Keeps Modem/USB active

    /**
     * Get or create the cached BYDAutoPowerDevice instance.
     * Uses PermissionBypassContext for BYD hardware access.
     */
    private fun getPowerDevice(): BYDAutoPowerDevice? {
        cachedPowerDevice?.let { return it }
        val ctx = appContext ?: return null

        try {
            val permissiveContext = PermissionBypassContext(ctx)
            cachedPowerDevice = BYDAutoPowerDevice.getInstance(permissiveContext)
        } catch (e: Exception) {
            log("Failed to get BYDAutoPowerDevice: " + e.message)
        }
        return cachedPowerDevice
    }

    /**
     * Get the BYDAutoSpecialDevice instance via reflection.
     * This device controls hidden BCM configuration for peripheral power.
     */
    private fun getSpecialDevice(): Any? {
        cachedSpecialDevice?.let { return it }
        val ctx = appContext ?: return null

        try {
            val permissiveContext = PermissionBypassContext(ctx)
            val clazz = Class.forName("android.hardware.bydauto.special.BYDAutoSpecialDevice")
            val getInstance = clazz.getMethod("getInstance", Context::class.java)
            cachedSpecialDevice = getInstance.invoke(null, permissiveContext)
            log("BYDAutoSpecialDevice acquired")
        } catch (e: Exception) {
            log("Failed to get BYDAutoSpecialDevice: " + e.message)
        }
        return cachedSpecialDevice
    }

    /**
     * Sets a hidden BYD configuration value via BYDAutoSpecialDevice.
     * Used to keep USB/Peripherals powered during Sleep.
     *
     * @param configId The magic config ID (e.g., 782237711)
     * @param value The value to set (typically 0=OFF, 1=ON)
     */
    private fun setSpecialConfig(configId: Int, value: Int) {
        val device = getSpecialDevice()
        if (device == null) {
            log("Cannot set Special Config - device unavailable")
            return
        }

        try {
            // 1. Create the Value Object (BYDAutoEventValue)
            val valueClass = Class.forName("android.hardware.bydauto.BYDAutoEventValue")
            val valueObj = valueClass.getDeclaredConstructor().newInstance()

            // 2. Set the integer value
            val intValueField = valueClass.getField("intValue")
            intValueField.setInt(valueObj, value)

            // 3. Set the value type (1 = Integer) - may be needed on some models
            try {
                val typeField = valueClass.getField("valueType")
                typeField.setInt(valueObj, 1)
            } catch (ignored: Exception) {
                // Field might not exist on older SDKs
            }

            // 4. Call set(int[] ids, BYDAutoEventValue value)
            val deviceClass = device.javaClass
            val setMethod = deviceClass.getMethod("set", IntArray::class.java, valueClass)
            val ids = intArrayOf(configId)
            setMethod.invoke(device, ids, valueObj)

            log("Special Config [$configId] set to: $value")
        } catch (e: Exception) {
            log("Failed to set Special Config [$configId]: " + e.message)
        }
    }

    /**
     * Sets a hidden BYD configuration value via BYDAutoPowerDevice.
     * Used for power hold/release signals (e.g., -1442840502).
     *
     * @param configId The power config ID
     * @param value The value to set
     */
    private fun setPowerConfig(configId: Int, value: Int) {
        val device = getPowerDevice()
        if (device == null) {
            log("Cannot set Power Config - device unavailable")
            return
        }

        try {
            val valueClass = Class.forName("android.hardware.bydauto.BYDAutoEventValue")
            val valueObj = valueClass.getDeclaredConstructor().newInstance()

            val intValueField = valueClass.getField("intValue")
            intValueField.setInt(valueObj, value)

            try {
                val typeField = valueClass.getField("valueType")
                typeField.setInt(valueObj, 1)
            } catch (ignored: Exception) {
            }

            val setMethod = device.javaClass.getMethod("set", IntArray::class.java, valueClass)
            val ids = intArrayOf(configId)
            setMethod.invoke(device, ids, valueObj)

            log("Power Config [$configId] set to: $value")
        } catch (e: Exception) {
            log("Failed to set Power Config [$configId]: " + e.message)
        }
    }

    /**
     * Toggles the "Remote Surveillance" power flags in the Gateway/BCM.
     * Matches Diplus C1310c implementation exactly:
     *
     * DISABLE path:
     *   - SpecialDevice 782237711 = 0 (sentry keep-alive OFF)
     *   - SpecialDevice 782237728 = 2 (allow sleep — value is 2, NOT 0)
     *   - PowerDevice  -1442840502 = 0 (release power hold)
     *
     * ENABLE path (MCU status 1 or 10):
     *   - SpecialDevice 782237711 = 1 (sentry keep-alive ON)
     *   - SpecialDevice 782237728 = 1 (wake request ON)
     *   - PowerDevice  -1442840502 is NOT set (it's a release-only signal)
     *
     * ENABLE path (MCU needs wake):
     *   - wakeUpMcu() loop — signals are NOT set until MCU is ready
     *
     * @param enable true to keep peripherals powered, false to restore stock behavior
     */
    private fun configurePeripheralPower(enable: Boolean) {
        log("Configuring Peripheral Power (USB/Data): " + (if (enable) "ON" else "OFF"))

        if (!enable) {
            // DISABLE — restore stock, allow MCU to cut power
            setSpecialConfig(SPECIAL_CONFIG_REMOTE_POWER_MODE, 0)  // Sentry keep-alive OFF
            setSpecialConfig(SPECIAL_CONFIG_DATA_MODULE_POWER, 2)  // Allow sleep (value=2, NOT 0)
            setPowerConfig(-1442840502, 0)                         // Release power hold (PowerDevice, not SpecialDevice)
        } else {
            // ENABLE — check MCU state first
            val mcuStatus = getMcuStatus()
            log("MCU status for peripheral power: $mcuStatus")

            if (mcuStatus == 1 || mcuStatus == 10) {
                // MCU is in normal standby — use signal-based path
                setSpecialConfig(SPECIAL_CONFIG_REMOTE_POWER_MODE, 1)  // Sentry keep-alive ON
                setSpecialConfig(SPECIAL_CONFIG_DATA_MODULE_POWER, 1)  // Wake request ON
                // NOTE: -1442840502 is NOT set to 1 here — it's a release-only signal
            } else {
                // MCU needs active wake — use wakeUpMcu() then retry
                log("MCU not ready (status=$mcuStatus), waking up and retrying...")
                wakeUpMcu()
                // Retry after 1 second to allow MCU to stabilize
                Thread({
                    try {
                        Thread.sleep(1000)
                    } catch (e: InterruptedException) {
                        Thread.currentThread().interrupt()
                        return@Thread
                    }
                    val retryStatus = getMcuStatus()
                    log("MCU status after wake: $retryStatus")
                    if (retryStatus == 1 || retryStatus == 10) {
                        setSpecialConfig(SPECIAL_CONFIG_REMOTE_POWER_MODE, 1)
                        setSpecialConfig(SPECIAL_CONFIG_DATA_MODULE_POWER, 1)
                    } else {
                        // One more attempt
                        wakeUpMcu()
                        try {
                            Thread.sleep(1000)
                        } catch (e: InterruptedException) {
                            Thread.currentThread().interrupt()
                            return@Thread
                        }
                        setSpecialConfig(SPECIAL_CONFIG_REMOTE_POWER_MODE, 1)
                        setSpecialConfig(SPECIAL_CONFIG_DATA_MODULE_POWER, 1)
                        log("Forced peripheral power enable after second wake attempt")
                    }
                }).start()
            }
        }
    }

    /**
     * Get current MCU status.
     * @return MCU status code, or -1 if unavailable
     */
    private fun getMcuStatus(): Int {
        val device = getPowerDevice() ?: return -1

        try {
            return device.mcuStatus
        } catch (e: Exception) {
            log("getMcuStatus error: " + e.message)
            return -1
        }
    }

    /**
     * Wake up the MCU. Returns true on success.
     */
    private fun wakeUpMcu(): Boolean {
        val device = getPowerDevice()
        if (device == null) {
            log("wakeUpMcu: No power device available")
            return false
        }

        try {
            val result = device.wakeUpMcu()
            return result == 0
        } catch (e: Exception) {
            log("wakeUpMcu error: " + e.message)
            return false
        }
    }

    // Lock file for singleton enforcement
    private const val LOCK_FILE = "/data/local/tmp/acc_sentry_daemon.lock"
    private var singletonLock: DaemonSingletonLock? = null

    @JvmStatic
    fun main(args: Array<String>) {
        _startTime = System.currentTimeMillis()
        val myUid = Process.myUid()

        // Configure DaemonLogger for daemon context (enable stdout for app_process)
        DaemonLogger.configure(
            DaemonLogger.Config.defaults()
                .withStdoutLog(true)
                .withFileLog(true)
                .withConsoleLog(true)
        )

        logger = DaemonLogger.getInstance(TAG, PATH_DATA_LOCAL_TMP())
        logT("logger initialized")

        // CRITICAL: Acquire singleton lock FIRST - exit if another instance is running
        if (!acquireSingletonLock()) {
            log("ERROR: Another AccSentryDaemon instance is already running. Exiting.")
            System.exit(1)
            return
        }
        logT("singletonLock acquired")

        log("=== ACC Sentry Daemon Starting ===")
        log("UID: $myUid (expected: 2000 shell)")
        log("PID: " + Process.myPid())

        // Initialize unified config so calls into isSurveillanceEnabled() and
        // getSurveillanceSchedule() see the on-disk config (and trigger legacy
        // migration if needed) when AccSentryDaemon starts before CameraDaemon.
        // Idempotent — CameraDaemon also calls this.
        try {
            UnifiedConfigManager.init()
        } catch (e: Exception) {
            log("UnifiedConfigManager.init() failed: " + e.message)
        }
        logT("UnifiedConfigManager.init done")

        // Record start time for uptime tracking
        startTime = System.currentTimeMillis()

        if (myUid != 2000) {
            log("WARNING: Not running as shell (UID 2000)! Screen control may not work.")
        }

        if (Looper.myLooper() == null) {
            Looper.prepare()
        }

        // Create handler for periodic status checks
        statusHandler = Handler(Looper.myLooper()!!)

        try {
            logT("createAppContext BEGIN")
            var context = createAppContext()
            if (context == null) {
                log("createAppContext failed, trying getSystemContext...")
                context = getSystemContext()
            }
            logT("createAppContext done")

            if (context != null) {
                log("Got context: $context")
                appContext = context

                // Acquire WakeLock for guaranteed CPU cycles
                acquireWakeLock()
                logT("acquireWakeLock done")

                // No BYD ACC whitelist (BladeWatch-u43d). setPkg2AccWhiteList needs the signature
                // permission DEVICE_ACC, which shell lacks, so it always failed; the fallback that
                // replaced it transacted code 2, which on this head unit is rmPkg2AccWhiteList (the
                // real codes: 1 set, 2 rm, 3 getAccModeStatus, 4 requestSuspending, 5 acquireAccLock
                // -- measured 2026-09-24), and a failure there scanned codes 1-5, request-to-suspend
                // included.

                // No BYD data-cache "whitelisting" here: bg_datacache requires the signature
                // permission ACCESS_APPOPSDATA, which shell (2000) does not hold either -- every
                // call was refused (BladeWatch-mgvv). Auto-start is the owner's BYD Auto-Start
                // setting; see docs/daemons-and-processes.md "After a reboot".

                // Install shutdown hook for debugging process termination
                installShutdownHook()

                // Log initial memory status
                logMemoryStatus()

                // Start periodic status monitoring
                startStatusMonitoring()
                logT("startStatusMonitoring done")

                // Note: VehicleDataMonitor is initialized in CameraDaemon (separate process)
                // which handles the HTTP API for vehicle data
            } else {
                log("WARNING: Running without context")
            }

            // Register bodywork listener for ACC state changes
            logT("registerBodyworkListener BEGIN")
            val registered = registerBodyworkListener(context)
            logT("registerBodyworkListener done (registered=$registered)")

            if (!registered) {
                log("Bodywork listener failed - ACC monitoring unavailable")
            }

            log("Daemon running, entering persistence loop...")
            logT("=== ACC SENTRY DAEMON READY ===")

            // UNKILLABLE LOOP WRAPPER - Crash-proof main loop
            // Automatically restarts logic if a random crash occurs
            while (true) {
                try {
                    // Start the message pump. This blocks until an exception occurs.
                    Looper.loop()
                } catch (e: Throwable) {
                    // Catch ANY crash (Exception or Error)
                    log("CRASH DETECTED in Main Loop: " + e.message)
                    e.printStackTrace()

                    // Safety pause to prevent CPU spiking if crash is repetitive
                    try {
                        Thread.sleep(5000)
                    } catch (ie: InterruptedException) {
                        Thread.currentThread().interrupt()
                    }

                    log("Restarting message queue...")
                    if (Looper.myLooper() == null) {
                        Looper.prepare()
                    }
                }
            }
        } catch (e: Exception) {
            log("FATAL: " + e.message)
            e.printStackTrace()
        }
    }

    private fun log(msg: String) {
        logger?.info(msg)
        // Note: System.out.println is now handled by DaemonLogger when enableStdoutLog is true
    }

    // ==================== SINGLETON LOCK ====================

    /**
     * Acquire a file lock to ensure only one daemon instance runs at a time.
     */
    private fun acquireSingletonLock(): Boolean {
        // BladeWatch-8d5u: this used to be a third private copy of the pattern, and the
        // weakest — it had NO stale handling at all, so a lock file whose holder had died
        // could only be cleared by hand. DaemonSingletonLock is a strict superset: same
        // exclusive FileLock, plus reclaim of a lock naming a dead PID, junk, or our own PID.
        val lock = DaemonSingletonLock(
            File(LOCK_FILE),
            Process.myPid(),
            DaemonSingletonLock.PROC_LIVENESS
        ) { msg -> log(msg) }
        singletonLock = lock
        if (!lock.acquire()) return false

        log("Acquired singleton lock (PID: " + Process.myPid() + ")")

        // Unchanged: the hook runs the FULL daemon shutdown, not just a lock release.
        Runtime.getRuntime().addShutdownHook(Thread({ shutdownDaemon() }, "DaemonCleanup"))

        return true
    }

    /**
     * Release the singleton lock on shutdown.
     */
    private fun releaseSingletonLock() {
        // No longer deletes the lock file. Unlinking a path another process may already hold a
        // lock on is the classic double-winner race — see DaemonSingletonLock.release(). A
        // leftover file is harmless: the next acquire finds no OS lock, takes it, and
        // overwrites the PID.
        singletonLock?.release()
    }

    // ==================== WAKELOCK MANAGEMENT ====================

    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) return
        val ctx = appContext ?: return

        try {
            val permissiveContext = PermissionBypassContext(ctx)
            val pm = permissiveContext.getSystemService(Context.POWER_SERVICE) as PowerManager
            val lock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "AccSentry:Core")
            wakeLock = lock
            lock.setReferenceCounted(false)
            lock.acquire()
            log("WakeLock Acquired")
        } catch (e: Exception) {
            log("WakeLock Error: " + e.message)
        }
    }

    private fun releaseWakeLock() {
        val lock = wakeLock
        if (lock != null && lock.isHeld) {
            try {
                lock.release()
                log("WakeLock Released")
            } catch (e: Exception) {
                log("WARN: wakeLock.release() failed: " + e.message)
            }
        }
    }


    // ==================== ACC STATE DETECTION ====================

    private fun registerBodyworkListener(context: Context?): Boolean {
        if (context == null) return false

        try {
            log("Registering bodywork listener...")

            val deviceClass = Class.forName("android.hardware.bydauto.bodywork.BYDAutoBodyworkDevice")
            val getInstance = deviceClass.getMethod("getInstance", Context::class.java)
            val device = getInstance.invoke(null, context)

            if (device == null) {
                log("BYDAutoBodyworkDevice.getInstance returned null")
                return false
            }

            log("Got bodywork device: $device")

            val listenerClass = Class.forName("android.hardware.bydauto.bodywork.AbsBYDAutoBodyworkListener")
            val registerListener = deviceClass.getMethod("registerListener", listenerClass)

            val listener = AccListener()
            registerListener.invoke(device, listener)

            log("Bodywork listener registered!")

            // Get initial power level
            try {
                val getPowerLevel = deviceClass.getMethod("getPowerLevel")
                val level = getPowerLevel.invoke(device) as Int
                log("Initial power level: " + powerLevelToString(level))
                lastPowerLevel = level

                if (level == POWER_LEVEL_OFF) {
                    log("Started with ACC OFF - entering sentry mode")
                    enterSentryMode()
                } else {
                    // ACC is ON - notify CameraDaemon so AccMonitor has correct state
                    log("Started with ACC ON - notifying CameraDaemon")
                    notifyAccState(false)  // accOff=false means ACC is ON
                }
            } catch (e: Exception) {
                log("Could not get initial power level: " + e.message)
            }

            return true
        } catch (e: Exception) {
            log("Bodywork registration failed: " + e.message)
            return false
        }
    }

    private class AccListener : AbsBYDAutoBodyworkListener() {
        override fun onPowerLevelChanged(level: Int) {
            log(">>> POWER LEVEL: " + powerLevelToString(level) + " (was: " + powerLevelToString(lastPowerLevel) + ")")

            if (level == POWER_LEVEL_OFF && lastPowerLevel != POWER_LEVEL_OFF) {
                log("ACC OFF detected")
                enterSentryMode()
            } else if (level >= POWER_LEVEL_ON && lastPowerLevel < POWER_LEVEL_ON) {
                log("ACC ON detected")
                exitSentryMode()
            } else if (level == POWER_LEVEL_ACC && lastPowerLevel >= POWER_LEVEL_ON) {
                // BYD app scenario: car was ON (level 2+) and dropped to ACC (level 1)
                // This is a "turning off" transition — treat as ACC OFF for sentry purposes.
                // Without this, a brief BYD app wake (OFF→ON→ACC→OFF) leaves AccMonitor
                // stuck showing ACC ON because exitSentryMode fired but enterSentryMode
                // only triggers on level 0.
                log("ACC level dropped from ON to ACC — treating as ACC OFF (BYD app shutdown)")
                enterSentryMode()
            }

            lastPowerLevel = level
        }

        override fun onAutoSystemStateChanged(state: Int) {
            log("System state: $state")
        }

        override fun onBatteryVoltageLevelChanged(level: Int) {
            // Discrete level callback (0=LOW, 1=NORMAL)
            // Actual voltage monitoring is done via polling in manageMcuPowerState()
            val levelName = if (level == 0) "LOW" else if (level == 1) "NORMAL" else "INVALID"
            log("Car battery level: $levelName")

            // Emergency action on LOW level
            if (level == 0 && inSentryMode) {
                log("CRITICAL: Battery level LOW - triggering emergency wake")
                forceMcuWakeUp()

                if (surveillanceEnabled) {
                    log("LOW BATTERY - Disabling surveillance to conserve power")
                    disableSurveillance()
                }
            }
        }
    }

    // ==================== VOLTAGE HYSTERESIS STATE ====================
    // Tracks whether we're in a charging cycle (voltage-based MCU wake)
    @Volatile private var isVoltageChargingCycle = false

    // Hysteresis thresholds for MCU wake/sleep decisions
    private const val LOW_VOLTAGE_THRESHOLD = 12.1      // Wake Trigger (Volts)
    private const val HEALTHY_VOLTAGE_THRESHOLD = 12.8  // Sleep Trigger (Volts)

    // VehicleDataMonitor listener for voltage-based MCU control
    private var vehicleDataListener: VehicleDataListener? = null

    private fun powerLevelToString(level: Int): String = when (level) {
        POWER_LEVEL_OFF -> "OFF"
        POWER_LEVEL_ACC -> "ACC"
        POWER_LEVEL_ON -> "ON"
        POWER_LEVEL_OK -> "OK"
        else -> "UNKNOWN($level)"
    }

    // ==================== SENTRY MODE ====================

    /**
     * Enter Sentry Mode - The "car is off but watching" state.
     *
     * CRITICAL SEQUENCE (order matters for power stability):
     * 1. Initialize voltage monitoring FIRST
     * 2. Wake MCU immediately (triggers DC-DC converter)
     * 3. THEN wake the system (screen/CPU)
     * 4. Start the keep-alive loop (maintains the wake state)
     * 5. Enable surveillance AFTER power is stable
     */
    private fun enterSentryMode() {
        if (inSentryMode) {
            log("Already in sentry mode")
            return
        }

        inSentryMode = true
        log("=== ENTERING SENTRY MODE ===")

        // CRITICAL: Always notify CameraDaemon that ACC is OFF immediately.
        // enableSurveillance() may skip the IPC if surveillanceEnabled is already true
        // or if the user has surveillance disabled in config, which would leave
        // AccMonitor stuck showing ACC ON (e.g. when parked in a safe zone).
        // This mirrors exitSentryMode() which also calls notifyAccState() first.
        notifyAccState(true)  // accOff=true → ACC is OFF

        // Background thread for setup
        Thread({
            try {
                // 1. Initialize voltage monitoring FIRST (for battery protection)
                initVehicleDataMonitor()

                // 2. Wake MCU immediately (triggers DC-DC converter for stable power)
                immediateWakeUpMcu()

                // 3. Configure peripheral power to keep USB/data rails active
                configurePeripheralPower(true)

                // 4. Small delay to let MCU stabilize power rails
                try {
                    Thread.sleep(300)
                } catch (e: InterruptedException) {
                    Thread.currentThread().interrupt()
                    return@Thread
                }

                // 4. THEN wake the system (screen/CPU)
                performSystemWakeUp()

                // 5. Start the keep-alive loop (maintains the wake state)
                startSystemKeepAlive()

                // 6. Another small delay to let power stabilize before surveillance
                try {
                    Thread.sleep(500)
                } catch (e: InterruptedException) {
                    Thread.currentThread().interrupt()
                    return@Thread
                }

                // 7. Register door lock listener and wait for lock before arming surveillance.
                // When ACC goes OFF and you exit the car, motion detection would pick you up
                // Door lock gate is handled by CameraDaemon (it has the BydDataCollector
                // typed HAL listener). CameraDaemon arms/disarms surveillance based on
                // lock/unlock events after receiving the ACC OFF notification above.
                // AccSentryDaemon no longer needs to manage lock detection or surveillance IPC.
                log("Door lock gate delegated to CameraDaemon")

                log("Sentry mode setup complete")
            } catch (t: Throwable) {
                log("CRITICAL: Sentry setup failed: " + t.message)
                t.printStackTrace()
                // Don't exit sentry mode - keep-alive may still work
            }
        }, "SentrySetup").start()

        log("Sentry mode ACTIVE")
    }

    /**
     * Exit Sentry Mode - Restore normal operation.
     */
    private fun exitSentryMode() {
        if (!inSentryMode) {
            log("Not in sentry mode")
            return
        }

        log("=== EXITING SENTRY MODE ===")

        // CRITICAL: Set inSentryMode=false FIRST, before stopping the keep-alive thread.
        // The keep-alive loop checks `while (running && inSentryMode)` and its interrupt
        // handler also checks `if (!running || !inSentryMode)`. If we stop the thread
        // while inSentryMode is still true, the interrupt handler sees inSentryMode=true
        // and CONTINUES the loop instead of exiting — racing with the screen-wake thread
        // below and calling setBacklightState(false) after we've already turned the screen on.
        // This race caused intermittent 20-30 second screen blackouts after vehicle ON.
        inSentryMode = false
        surveillanceEnabled = false

        // CRITICAL: Always notify CameraDaemon that ACC is ON.
        // CameraDaemon handles all surveillance cleanup (door lock gate, unlock poll,
        // pipeline stop) in its ACC ON path. The cloud listener that used to be part
        // of that cleanup went with the BYD cloud removal in 61b4d7f.
        notifyAccState(false)  // accOff=false → ACC is ON

        // Clear safe zone suppression flag (clean slate for next sentry session)
        try {
            CameraDaemon.setSafeZoneSuppressed(false)
        } catch (ignored: Exception) {
        }

        // Restore stock peripheral power behavior (allow MCU to cut power)
        configurePeripheralPower(false)

        // Stop active charging maintenance if running
        stopChargingMaintenance()

        // Stop VehicleDataMonitor listener
        stopVehicleDataMonitor()

        // Stop system keep-alive (thread will exit cleanly since inSentryMode is already false)
        stopSystemKeepAlive()

        // Restore backlight — retry a few times with delay.
        // The keep-alive thread should be fully stopped by now (inSentryMode=false
        // ensures it exits on interrupt), but retry in case the BYD system overrides
        // our first attempt during its own ACC ON boot sequence.
        Thread({
            for (attempt in 1..3) {
                setBacklightState(true)
                try {
                    Thread.sleep(1000)
                } catch (ignored: InterruptedException) {
                    break
                }
            }
        }, "ScreenWake").start()

        log("Sentry mode DEACTIVATED")
    }

    /**
     * Cleanup and shutdown the daemon gracefully.
     * Called on process termination or manual shutdown.
     */
    private fun shutdownDaemon() {
        log("=== DAEMON SHUTDOWN INITIATED ===")

        running = false

        // Exit sentry mode if active
        if (inSentryMode) {
            exitSentryMode()
        }

        // Stop status monitoring
        stopStatusMonitoring()

        // Release wake lock
        releaseWakeLock()

        // Release singleton lock
        releaseSingletonLock()

        log("=== DAEMON SHUTDOWN COMPLETE ===")
    }

    // ==================== DEBUG TOOLS ====================

    /**
     * DEBUG TOOL: Dumps the values of all known Sleep Reason constants.
     * Use this to verify which magic number (9, 13, etc.) your specific car firmware uses.
     */
    private fun logAllSleepReasonFields() {
        log("=== DUMPING SLEEP REASON CONSTANTS ===")

        val possibleFieldNames = arrayOf(
            "GO_TO_SLEEP_REASON_ACCOFF",       // Primary BYD constant
            "GO_TO_SLEEP_REASON_ACC_OFF",      // Alternative naming
            "GO_TO_SLEEP_REASON_POWER_OFF",    // Generic power off
            "GO_TO_SLEEP_REASON_DEVICE_ADMIN", // Android 10+ constant (value 13)
            "GO_TO_SLEEP_REASON_TIMEOUT",      // Standard Android (usually 2)
            "GO_TO_SLEEP_REASON_POWER_BUTTON"  // Standard Android (usually 4)
        )

        for (fieldName in possibleFieldNames) {
            try {
                val field = PowerManager::class.java.getDeclaredField(fieldName)
                field.isAccessible = true
                val value = field.getInt(null) // Static field, so object is null
                log("  [FOUND] $fieldName = $value")
            } catch (e: NoSuchFieldException) {
                log("  [MISSING] $fieldName (Not present on this firmware)")
            } catch (e: Exception) {
                log("  [ERROR] $fieldName: " + e.message)
            }
        }

        // Also dump the standard SDK version for context
        log("  [INFO] Android SDK Version: " + Build.VERSION.SDK_INT)
        log("=== END DUMP ===")
    }

    // ==================== SENTRY HELPERS ====================
    //
    // The Java original carried ~300 lines of block-commented-out BYD device method-dump
    // tooling here (dumpPowerManagerMethods, dumpBydPowerDeviceMethods, ...
    // dumpAllBydDeviceMethods) — never compiled, never called; every call site in main()
    // was itself commented out. Dropped rather than translated: Kotlin block comments
    // nest, so the original /* ... */ ... */ trick that Java tolerates does not even parse
    // here, and there is no behavior to preserve from code that was already inert text.

    // ==================== POWER CONTROL (Reflection) ====================

    /**
     * Dynamically retrieves the correct sleep reason code from the PowerManager.
     * This ensures compatibility across different Android versions (SDK 28 vs 29+)
     * and different BYD car models (Atto 3, Seal, etc.).
     *
     * Tries multiple field names that BYD might use across firmware versions.
     *
     * @return The correct GO_TO_SLEEP_REASON code (9 for older, 13 for newer)
     */
    private fun getSystemSleepReasonCode(): Int {
        // List of possible field names BYD might use across different firmware versions
        val possibleFieldNames = arrayOf(
            "GO_TO_SLEEP_REASON_ACCOFF",      // Primary BYD constant
            "GO_TO_SLEEP_REASON_ACC_OFF",     // Alternative naming
            "GO_TO_SLEEP_REASON_POWER_OFF",   // Generic power off
            "GO_TO_SLEEP_REASON_DEVICE_ADMIN" // Android 10+ constant (value 13)
        )

        for (fieldName in possibleFieldNames) {
            try {
                val field = PowerManager::class.java.getDeclaredField(fieldName)
                field.isAccessible = true
                val value = field.getInt(null)
                // Only log on first successful discovery (cache this ideally)
                return value
            } catch (e: NoSuchFieldException) {
                // Field doesn't exist, try next
            } catch (e: Exception) {
                // Access error, try next
            }
        }

        // Fallback strategy: Android 10+ (SDK 29) uses 13, older uses 9
        // This matches AOSP GO_TO_SLEEP_REASON_DEVICE_ADMIN (13) vs legacy (9)
        return if (Build.VERSION.SDK_INT >= 29) 13 else 9
    }

    /**
     * Performs a validated wake-up call using the correct context ID and details string.
     * This mimics a legitimate ignition event to bypass the ACC lock.
     * Uses "Double-Key" logic (Correct ID + "ACC_ON") to pass security check.
     *
     * CRITICAL: This is the initial wake call when entering sentry mode.
     * The keep-alive thread maintains this state via userActivity().
     */
    private fun performSystemWakeUp() {
        val ctx = appContext
        if (ctx == null) {
            log("performSystemWakeUp: No context available")
            return
        }

        try {
            val permissiveContext = PermissionBypassContext(ctx)
            val pm = permissiveContext.getSystemService(Context.POWER_SERVICE) as PowerManager

            // 1. Get the correct lock key (9 or 13) dynamically
            val reasonID = getSystemSleepReasonCode()

            // 2. Try the 3-arg wakeUp method (most reliable on BYD)
            try {
                val method = PowerManager::class.java.getMethod(
                    "wakeUp", java.lang.Long.TYPE, Integer.TYPE, String::class.java
                )
                method.invoke(pm, SystemClock.uptimeMillis(), reasonID, "ACC_ON")
                log("System wake-up sent (reason: $reasonID)")
                return
            } catch (e: NoSuchMethodException) {
                // Fall through to 1-arg version
            }

            // 3. Fallback: 1-arg wakeUp (older Android)
            try {
                val method = PowerManager::class.java.getMethod("wakeUp", Long::class.javaPrimitiveType)
                method.invoke(pm, SystemClock.uptimeMillis())
                log("System wake-up sent (1-arg fallback)")
                return
            } catch (e: NoSuchMethodException) {
                // Fall through to keyevent
            }

            // 4. Last resort: keyevent
            log("wakeUp methods unavailable, using keyevent fallback")
            execShell("input keyevent 224")
        } catch (e: Exception) {
            log("Wake-up failed: " + e.message)
            // Fallback for extreme cases
            execShell("input keyevent 224")
        }
    }

    private fun setBacklightState(on: Boolean) {
        log("Setting backlight: " + (if (on) "ON" else "OFF"))

        // BladeWatch-2000.3: the PowerManager/BYD-hardware-service reflection cascade now
        // lives in BacklightController, shared with the explicit screen on/off vehicle
        // command. Behaviour is identical to the pre-extraction inline version -- pinned by
        // AccSentryDaemonBacklightDelegationTest.
        val ctx = appContext
        if (ctx != null && BacklightController.setBacklight(ctx, on)) {
            return
        }

        // Fallback: Settings brightness
        val brightness = if (on) 128 else 0
        execShell("settings put system screen_brightness $brightness")
        if (on) {
            execShell("input keyevent 224")  // KEYCODE_WAKEUP
        } else {
            execShell("input keyevent 223")  // KEYCODE_SLEEP
        }
    }

    // ==================== SYSTEM PERSISTENCE SERVICE ====================

    /**
     * Starts the System Persistence Service (10-second maintenance loop).
     * Implements the "Refresh & Enforce" pattern:
     * 1. Maintains network interface stability (WiFi)
     * 2. Refreshes CPU wake timer (fake user activity)
     * 3. Enforces stealth power state (screen off, CPU active)
     *
     * CRITICAL: Uses Throwable catch to survive OutOfMemoryError and other Errors.
     * Thread is NOT a daemon so it survives if main thread has issues.
     */
    private fun startSystemKeepAlive() {
        if (systemKeepAliveThread?.isAlive == true) {
            return
        }

        val thread = Thread({
            log("System Persistence Service started")

            while (running && inSentryMode) {  // Check BOTH flags
                try {
                    // 1. Maintain Network Interface Stability
                    ensureWifiEnabled()
                    injectFakeUserActivity()
                    setBacklightState(false)

                    // 4. Maintenance Cycle Interval (10 seconds)
                    Thread.sleep(SYSTEM_KEEPALIVE_INTERVAL_MS)
                } catch (e: InterruptedException) {
                    log("KeepAlive interrupted - checking if should continue...")
                    if (!running || !inSentryMode) {
                        break  // Exit cleanly
                    }
                    // Otherwise continue the loop
                } catch (t: Throwable) {
                    // CRITICAL: Catch EVERYTHING including Errors (OutOfMemoryError, etc.)
                    // DON'T break - keep trying!
                    log("KeepAlive error: " + t.message)
                    try {
                        Thread.sleep(1000)  // Brief pause before retry
                    } catch (ignored: InterruptedException) {
                        if (!running || !inSentryMode) break
                    }
                }
            }

            log("System Persistence Service stopped")
        }, "SystemKeepAlive")
        systemKeepAliveThread = thread

        // CRITICAL: Not a daemon thread! Survives if main thread has issues.
        thread.isDaemon = false
        thread.start()
    }

    private fun stopSystemKeepAlive() {
        systemKeepAliveThread?.let { thread ->
            log("Stopping System Persistence Service...")
            thread.interrupt()

            // Wait briefly for clean shutdown
            try {
                thread.join(2000)
            } catch (ignored: InterruptedException) {
            }

            if (thread.isAlive) {
                log("WARN: KeepAlive thread did not stop cleanly")
            }

            systemKeepAliveThread = null
        }
    }

    /**
     * Checks if Wi-Fi is enabled and forces it ON if not.
     * Equivalent to: Runtime.getRuntime().exec("svc wifi enable");
     */
    private fun ensureWifiEnabled() {
        // We use a lightweight check to avoid spamming the shell log
        // In the decompiled code, they just blindly ran "svc wifi enable"
        // running it blindly is safer for persistence.
        execShell(CMD_WIFI_ENABLE())
    }

    /**
     * Uses Reflection to call PowerManager.userActivity()
     * This mimics the "Fake Touch" to keep CPU awake.
     *
     * CRITICAL: Checks screen status FIRST to avoid exceptions on some BYD firmware
     * where calling userActivity() when screen is OFF causes issues.
     */
    private fun injectFakeUserActivity() {
        val ctx = appContext ?: return

        try {
            val permissiveContext = PermissionBypassContext(ctx)
            val pm = permissiveContext.getSystemService(Context.POWER_SERVICE) as PowerManager

            // CRITICAL: Check screen status FIRST
            // On some BYD firmware, calling userActivity() when screen is OFF fails
            try {
                val getScreenStatus = PowerManager::class.java.getMethod("getPowerScreenStatus")
                val screenStatus = getScreenStatus.invoke(pm) as Int
                if (screenStatus == 0) {
                    // Screen is OFF - userActivity may fail or be ignored
                    // Skip it - the wakeUp call in performSystemWakeUp() handles keeping CPU alive
                    log("Screen OFF - skipping userActivity")
                    return
                }
            } catch (e: NoSuchMethodException) {
                // Method doesn't exist on this firmware - proceed anyway
            } catch (e: Exception) {
                // Access error - proceed anyway
            }

            // 1-arg version
            try {
                val method = PowerManager::class.java.getMethod("userActivity", Long::class.javaPrimitiveType)
                method.invoke(pm, SystemClock.uptimeMillis())
                log("userActivity(long) called")
                return
            } catch (e: NoSuchMethodException) {
                log("userActivity: no compatible method found")
            }

            // Fallback: Try 2-arg version first (stealth mode - doesn't turn on screen)
            // noChangeLights = true means "Reset the sleep timer, but don't turn on the screen"
            try {
                val method = PowerManager::class.java.getMethod(
                    "userActivity", Long::class.javaPrimitiveType, Boolean::class.javaPrimitiveType
                )
                method.invoke(pm, SystemClock.uptimeMillis(), true)
                log("userActivity(long, boolean) called")
            } catch (e: NoSuchMethodException) {
                // Fall through to 1-arg version
            }
        } catch (e: Exception) {
            log("userActivity error: " + e.message)
        }
    }

    private fun immediateWakeUpMcu() {
        log("IMMEDIATE MCU WAKE-UP...")

        if (wakeUpMcu()) {
            log("  MCU wake: OK")
        } else {
            log("  MCU wake: FAILED")
        }
    }

    /**
     * Force MCU wake-up for voltage-triggered charging cycles.
     * Called by VehicleDataListener when battery drops below threshold.
     * Also triggers system wake to ensure full power rail activation.
     */
    private fun forceMcuWakeUp() {
        log("VOLTAGE-TRIGGERED MCU WAKE-UP...")

        // Update wake timestamp
        lastMcuWakeTime = System.currentTimeMillis()

        // Wake the system first (ensures power rails are active)
        performSystemWakeUp()

        // Then wake MCU to trigger DC-DC converter
        if (wakeUpMcu()) {
            log("  MCU wake: OK")
        }

        // Double-tap for reliability
        try {
            Thread.sleep(500)
            wakeUpMcu()
        } catch (e: InterruptedException) {
            Thread.currentThread().interrupt()
        }
    }

    // ==================== ACTIVE VOLTAGE RECOVERY ====================

    /**
     * Starts the Active Charging Maintenance routine.
     * Launches a background thread that repeatedly pulses the MCU to keep the
     * DC-DC converter active until the target voltage is reached.
     *
     * This prevents the "Limbo State" where MCU times out and sleeps before
     * the battery has fully recovered.
     */
    private fun startChargingMaintenance() {
        if (isVoltageChargingCycle && mcuChargingThread?.isAlive == true) {
            return  // Already actively charging
        }

        log("Starting Active Voltage Recovery (Target: ${HEALTHY_VOLTAGE_THRESHOLD}V)...")
        isVoltageChargingCycle = true

        val thread = Thread({
            while (isVoltageChargingCycle && running && inSentryMode) {
                try {
                    // Trigger the DC-DC Converter
                    forceMcuWakeUp()

                    // Wait before the next pulse.
                    // 45s is aggressive enough to prevent MCU sleep (usually 1-5 min timeout)
                    // but relaxed enough to avoid flooding the CAN bus.
                    Thread.sleep(MCU_CHARGE_PULSE_INTERVAL_MS)
                } catch (e: InterruptedException) {
                    log("Charging maintenance interrupted")
                    break
                } catch (e: Exception) {
                    log("Charging loop error: " + e.message)
                }
            }
            log("Active Voltage Recovery stopped.")
        }, "McuChargeLoop")
        mcuChargingThread = thread

        thread.start()
    }

    /**
     * Stops the Active Charging Maintenance routine.
     * Called when voltage has recovered to healthy levels.
     */
    private fun stopChargingMaintenance() {
        if (!isVoltageChargingCycle) return

        log("Target voltage reached. Stopping Active Recovery.")
        isVoltageChargingCycle = false

        mcuChargingThread?.let {
            it.interrupt()
            mcuChargingThread = null
        }
    }

    // ==================== VEHICLE DATA MONITOR INTEGRATION ====================

    /**
     * Initialize VehicleDataMonitor and register listener for voltage-based MCU control.
     * Only initializes the 12V battery power monitor (not all monitors) for sentry mode.
     */
    private fun initVehicleDataMonitor() {
        val ctx = appContext
        if (ctx == null) {
            log("Cannot init VehicleDataMonitor: no context")
            return
        }

        try {
            log("Initializing VehicleDataMonitor for voltage monitoring (battery power only)...")

            val monitor = VehicleDataMonitor.getInstance()

            // Initialize with our permissive context - ONLY battery power monitor
            val permissiveContext = PermissionBypassContext(ctx)
            monitor.initBatteryPowerOnly(permissiveContext)

            // Create and register our listener for voltage-based MCU control
            val listener = object : VehicleDataListener {
                override fun onBatteryVoltageChanged(data: BatteryVoltageData) {
                    // Discrete level changes (0=LOW, 1=NORMAL) - handled by AccListener
                }

                override fun onBatteryPowerChanged(data: BatteryPowerData) {
                    // This is the actual voltage from BYDAutoOtaDevice
                    if (!inSentryMode) return

                    val voltage = data.voltageVolts

                    // OUT-OF-RANGE CHECK: Wake MCU if voltage is outside valid bounds (9.0-16.0V)
                    // This catches both critically low AND abnormally high readings
                    if (!data.isValidRange()) {
                        log("VOLTAGE OUT OF RANGE (" + String.format("%.2f", voltage) + "V) - Triggering MCU wake")
                        forceMcuWakeUp()
                    }

                    // HYSTERESIS LOGIC WITH ACTIVE MAINTENANCE
                    if (isVoltageChargingCycle) {
                        // We are currently forcing the MCU to stay awake to charge.
                        // CHECK: Have we reached the healthy threshold?
                        if (voltage >= HEALTHY_VOLTAGE_THRESHOLD) {
                            log("Voltage recovered (" + String.format("%.2f", voltage) + "V).")
                            stopChargingMaintenance()
                            // Result: MCU is finally allowed to sleep.
                        }
                    } else {
                        // We are passively monitoring. The MCU is likely sleeping.
                        // CHECK: Has voltage dropped below critical?
                        if (voltage <= LOW_VOLTAGE_THRESHOLD) {
                            log("LOW VOLTAGE (" + String.format("%.2f", voltage) + "V) DETECTED!")
                            startChargingMaintenance()
                            // Result: Starts the loop that wakes MCU every 45s.
                        }
                    }

                    // Critical safety check - disable surveillance to conserve power
                    if (data.isCritical && surveillanceEnabled) {
                        log("CRITICAL VOLTAGE (" + String.format("%.2f", voltage) + "V) - Disabling surveillance")
                        disableSurveillance()
                    }
                }

                override fun onChargingStateChanged(data: ChargingStateData) {
                    // Not used in sentry mode (battery power only)
                }

                override fun onChargingPowerChanged(powerKW: Double) {
                    // Not used in sentry mode (battery power only)
                }

                override fun onDataUnavailable(monitorName: String, reason: String) {
                    log("VehicleData unavailable: $monitorName - $reason")
                }
            }
            vehicleDataListener = listener

            monitor.addListener(listener)
            monitor.startBatteryPowerOnly()

            log("VehicleDataMonitor initialized (battery power only)")
        } catch (e: Exception) {
            log("VehicleDataMonitor init failed: " + e.message)
        }
    }

    /**
     * Stop listening to VehicleDataMonitor (battery power only).
     */
    private fun stopVehicleDataMonitor() {
        try {
            log("Removing VehicleDataMonitor listener...")

            vehicleDataListener?.let { listener ->
                val monitor = VehicleDataMonitor.getInstance()
                monitor.removeListener(listener)
                monitor.stopBatteryPowerOnly()
                vehicleDataListener = null
            }

            isVoltageChargingCycle = false

            log("VehicleDataMonitor listener removed")
        } catch (e: Exception) {
            log("VehicleDataMonitor cleanup failed: " + e.message)
        }
    }

    // ==================== SURVEILLANCE ====================

    private fun enableSurveillance() {
        if (surveillanceEnabled) return

        // RACE CONDITION FIX: Check inSentryMode before attempting to enable.
        // If exitSentryMode() was called (ACC ON) while we were sleeping/retrying,
        // we must NOT enable surveillance.
        if (!inSentryMode) {
            log("enableSurveillance() aborted — no longer in sentry mode (ACC is ON)")
            return
        }

        // Check if user has enabled surveillance in config
        // If not enabled, skip — don't auto-start on ACC OFF
        try {
            val userEnabled = UnifiedConfigManager.isSurveillanceEnabled()
            if (!userEnabled) {
                log("Surveillance NOT enabled in config — skipping auto-start on ACC OFF")
                return
            }
        } catch (e: Exception) {
            log("WARN: Could not read surveillance config: " + e.message + " — skipping auto-start")
            return
        }

        log("Enabling surveillance...")

        // Check safe zone — don't start surveillance if parked in a safe zone.
        // Mark as suppressed so onLeftSafeZone() can re-arm if the car is towed out.
        try {
            val safeLocMgr = SafeLocationManager.getInstance()
            if (safeLocMgr.isFeatureEnabled && safeLocMgr.isInSafeZone) {
                log("In safe zone '" + safeLocMgr.currentZoneName + "' — skipping surveillance")
                CameraDaemon.setSafeZoneSuppressed(true)
                return
            }
        } catch (e: Exception) {
            log("Safe zone check failed: " + e.message + " — proceeding with surveillance")
        }

        // Check schedule — don't start surveillance outside configured time windows
        try {
            val schedule = UnifiedConfigManager.getSurveillanceSchedule()
            if (schedule.isEnabled && !schedule.isActiveNow) {
                log("SCHEDULE: Outside time window (" + schedule.summary + ") — skipping surveillance")
                return
            }
        } catch (e: Exception) {
            log("Schedule check failed: " + e.message + " — proceeding with surveillance")
        }

        // Retry with backoff — CameraDaemon may not be up yet after boot
        val maxRetries = 10
        var retryDelayMs = 3000L // Start with 3 seconds

        for (attempt in 1..maxRetries) {
            // RACE CONDITION FIX: Re-check inSentryMode on EVERY retry iteration.
            // exitSentryMode() sets inSentryMode=false, so if ACC turned ON during
            // our sleep between retries, we bail out immediately.
            if (!inSentryMode) {
                log("enableSurveillance() aborted at attempt $attempt — no longer in sentry mode (ACC is ON)")
                return
            }

            try {
                val cmd = JSONObject()
                cmd.put("command", "SET_CONFIG")
                val config = JSONObject()
                // NOTE: Do NOT send accOff=true here — it was already sent by
                // notifyAccState(true) in enterSentryMode(). Sending it again
                // causes CameraDaemon.onAccStateChanged to run twice, which
                // double-enables surveillance and resets the V2 pipeline.
                config.put("enabled", true)
                cmd.put("config", config)

                val response = sendSurveillanceCommandRaw(cmd)
                if (response != null && response.optBoolean("success", false)) {
                    // Final guard: verify we're still in sentry mode AFTER the IPC succeeded.
                    // There's a tiny window where exitSentryMode() could fire between the IPC
                    // send and this check — if so, immediately send a disable to undo it.
                    if (!inSentryMode) {
                        log("Surveillance enabled but ACC turned ON during IPC — immediately disabling")
                        disableSurveillance()
                        return
                    }
                    surveillanceEnabled = true
                    log("Surveillance ENABLED (attempt $attempt)")
                    return
                } else {
                    log(
                        "WARN: Surveillance enable failed (attempt $attempt/$maxRetries): " +
                            (response?.toString() ?: "null")
                    )
                }
            } catch (e: Exception) {
                log("WARN: Surveillance enable failed (attempt $attempt/$maxRetries): " + e.message)
            }

            if (attempt < maxRetries) {
                try {
                    log("Retrying surveillance enable in " + (retryDelayMs / 1000) + "s...")
                    Thread.sleep(retryDelayMs)
                    retryDelayMs = Math.min(retryDelayMs + 2000, 10000) // Increase delay, cap at 10s
                } catch (e: InterruptedException) {
                    log("Surveillance retry interrupted")
                    return
                }
            }
        }

        log("ERROR: Failed to enable surveillance after $maxRetries attempts — CameraDaemon may not be running")
    }

    private fun disableSurveillance() {
        // SOTA: Always attempt to disable when called — CameraDaemon may have enabled
        // surveillance independently (e.g., via the periodic schedule checker or the
        // 45-second fallback timer) without AccSentryDaemon knowing. Skipping based on
        // the local surveillanceEnabled flag would leave surveillance running when the
        // owner returns and unlocks the door.
        // Note: exitSentryMode() already sends notifyAccState(false) which triggers
        // CameraDaemon's full ACC ON path (pipeline.stop()), so this is a belt-and-suspenders
        // call. It's safe to send even if surveillance is already stopped.

        log("Disabling surveillance via IPC (battery protection / session stop)...")

        try {
            // Send stopSurveillance=true to stop motion detection without persisting
            // the preference change. This preserves the user's "surveillance enabled"
            // setting so it auto-starts on the next ACC OFF cycle.
            val cmd = JSONObject()
            cmd.put("command", "SET_CONFIG")
            val config = JSONObject()
            config.put("stopSurveillance", true)
            cmd.put("config", config)

            sendSurveillanceCommandRaw(cmd)
            surveillanceEnabled = false
            log("Surveillance STOPPED via IPC (user preference preserved)")
        } catch (e: Exception) {
            log("WARN: Failed to disable surveillance via IPC: " + e.message)
        }
    }

    // ==================== DOOR LOCK GATED SURVEILLANCE — DELETED ====================
    // Door-lock gating is owned by CameraDaemon (it has BydDataCollector's typed
    // HAL listener). AccSentryDaemon delegates by calling notifyAccState() — see
    // enterSentryMode() / exitSentryMode().

    /**
     * Notify CameraDaemon of ACC state change.
     * This updates AccMonitor so HTTP API returns correct acc status.
     *
     * @param accOff true if ACC is OFF, false if ACC is ON
     */
    private fun notifyAccState(accOff: Boolean) {
        try {
            val cmd = JSONObject()
            cmd.put("command", "SET_CONFIG")
            val config = JSONObject()
            config.put("accOff", accOff)
            cmd.put("config", config)

            sendSurveillanceCommandRaw(cmd)
            log("ACC state notified to CameraDaemon: accOff=$accOff")
        } catch (e: Exception) {
            log("WARN: Failed to notify ACC state: " + e.message)
        }
    }

    private fun sendSurveillanceCommandRaw(command: JSONObject): JSONObject? {
        var socket: Socket? = null
        try {
            socket = Socket("127.0.0.1", SURVEILLANCE_IPC_PORT)
            socket.soTimeout = 5000

            val writer = PrintWriter(socket.getOutputStream(), true)
            val reader = BufferedReader(InputStreamReader(socket.getInputStream()))

            // Attach shared-secret token required by SurveillanceIpcServer
            val token = IpcTokenManager.getToken()
            if (token != null) {
                try {
                    command.put("token", token)
                } catch (ignored: Exception) {
                }
            }

            writer.println(command.toString())
            val responseLine = reader.readLine()

            return if (responseLine != null) JSONObject(responseLine) else null
        } catch (e: Exception) {
            log("Surveillance IPC error: " + e.message)
            return null
        } finally {
            if (socket != null) {
                try {
                    socket.close()
                } catch (ignored: Exception) {
                }
            }
        }
    }

    // ==================== CONTEXT HELPERS ====================

    private fun getSystemContext(): Context? {
        try {
            val activityThreadClass = Class.forName("android.app.ActivityThread")
            val activityThread = resolveActivityThread(activityThreadClass) ?: return null
            val getSystemContext = activityThreadClass.getMethod("getSystemContext")
            return getSystemContext.invoke(activityThread) as Context
        } catch (e: Exception) {
            log("getSystemContext failed: " + e.message)
            return null
        }
    }

    private fun createAppContext(): Context? {
        try {
            val activityThreadClass = Class.forName("android.app.ActivityThread")
            val activityThread = resolveActivityThread(activityThreadClass)

            if (activityThread == null) {
                log("createAppContext: all strategies failed, using null-safe fallback")
                return PermissionBypassContext(null)
            }

            val getSystemContext = activityThreadClass.getMethod("getSystemContext")
            val systemContext = getSystemContext.invoke(activityThread) as Context?
                ?: return PermissionBypassContext(null)

            val packageName = APP_PACKAGE_NAME()
            val appContext = systemContext.createPackageContext(
                packageName, Context.CONTEXT_INCLUDE_CODE or Context.CONTEXT_IGNORE_SECURITY
            )

            return PermissionBypassContext(appContext)
        } catch (e: Exception) {
            log("createAppContext failed: " + e.message)
            return PermissionBypassContext(null)
        }
    }

    private fun resolveActivityThread(activityThreadClass: Class<*>): Any? {
        try {
            val cur = activityThreadClass.getMethod("currentActivityThread")
            val at = cur.invoke(null)
            if (at != null) return at
        } catch (ignored: Exception) {
        }

        val result = arrayOfNulls<Any>(1)
        try {
            val t = Thread({
                try {
                    val systemMain = activityThreadClass.getMethod("systemMain")
                    result[0] = systemMain.invoke(null)
                } catch (ignored: Exception) {
                }
            }, "SystemMainInit")
            t.isDaemon = true
            t.start()
            t.join(10_000)
            if (t.isAlive) {
                log("resolveActivityThread: systemMain timed out")
                t.interrupt()
                try {
                    val cur = activityThreadClass.getMethod("currentActivityThread")
                    val at = cur.invoke(null)
                    if (at != null) return at
                } catch (ignored: Exception) {
                }
            } else if (result[0] != null) {
                return result[0]
            }
        } catch (ignored: Exception) {
        }

        try {
            prepareMainLooperForShellDaemon()
            val ctor = activityThreadClass.getDeclaredConstructor()
            ctor.isAccessible = true
            val at = ctor.newInstance()
            try {
                val f = activityThreadClass.getDeclaredField("sCurrentActivityThread")
                f.isAccessible = true
                f.set(null, at)
            } catch (ignored: Exception) {
            }
            log("resolveActivityThread: manual creation succeeded")
            return at
        } catch (e: Exception) {
            log("resolveActivityThread: manual creation failed: " + e.message)
        }

        return null
    }

    @Suppress("DEPRECATION")
    private fun prepareMainLooperForShellDaemon() {
        // app_process daemons do not get Android's standard main looper; BYD
        // hardware callbacks need one even though app code should not call this.
        try {
            Looper.prepareMainLooper()
        } catch (ignored: Exception) {
        }
    }

    private class PermissionBypassContext(base: Context?) : ContextWrapper(base) {
        override fun enforceCallingOrSelfPermission(permission: String, message: String?) {}
        override fun enforcePermission(permission: String, pid: Int, uid: Int, message: String?) {}
        override fun enforceCallingPermission(permission: String, message: String?) {}
        override fun checkCallingOrSelfPermission(permission: String): Int = PackageManager.PERMISSION_GRANTED
        override fun checkPermission(permission: String, pid: Int, uid: Int): Int = PackageManager.PERMISSION_GRANTED
        override fun checkSelfPermission(permission: String): Int = PackageManager.PERMISSION_GRANTED

        override fun getApplicationContext(): Context {
            return try {
                super.getApplicationContext()
            } catch (e: NullPointerException) {
                this
            }
        }

        override fun getPackageName(): String {
            return try {
                super.getPackageName()
            } catch (e: NullPointerException) {
                APP_PACKAGE_NAME()
            }
        }

        override fun getSystemService(name: String): Any? {
            return try {
                super.getSystemService(name)
            } catch (e: NullPointerException) {
                null
            }
        }

        override fun getApplicationInfo(): ApplicationInfo {
            return try {
                super.getApplicationInfo()
            } catch (e: NullPointerException) {
                ApplicationInfo()
            }
        }

        override fun getContentResolver(): ContentResolver? {
            return try {
                super.getContentResolver()
            } catch (e: NullPointerException) {
                null
            }
        }

        override fun getResources(): Resources? {
            return try {
                super.getResources()
            } catch (e: NullPointerException) {
                null
            }
        }

        override fun createPackageContext(packageName: String, flags: Int): Context {
            return try {
                super.createPackageContext(packageName, flags)
            } catch (e: Exception) {
                this
            }
        }
    }

    // ==================== INSTRUMENT DEVICE TEST ====================

    /**
     * Tests BYDAutoInstrumentDevice and BYDAutoStatisticDevice for charging data.
     */
    private fun testInstrumentDevice() {
        log("=== TESTING CHARGING DATA SOURCES ===")

        val ctx = appContext
        if (ctx == null) {
            log("ERROR: No context available")
            return
        }

        try {
            val permissiveContext = PermissionBypassContext(ctx)

            // Test InstrumentDevice
            log("--- BYDAutoInstrumentDevice ---")
            val instrClazz = Class.forName("android.hardware.bydauto.instrument.BYDAutoInstrumentDevice")
            val getInstrInstance = instrClazz.getMethod("getInstance", Context::class.java)
            val instrDevice = getInstrInstance.invoke(null, permissiveContext)

            if (instrDevice != null) {
                val instrGetters = arrayOf(
                    "getExternalChargingPower",
                    "getChargePower",
                    "getChargePercent",
                    "getChargeRestTime",
                    "getOutCarTemperature"
                )

                for (methodName in instrGetters) {
                    testGetter(instrClazz, instrDevice, methodName)
                }
            }

            // Test StatisticDevice (uses this for SOC)
            log("--- BYDAutoStatisticDevice ---")
            val statClazz = Class.forName("android.hardware.bydauto.statistic.BYDAutoStatisticDevice")
            val getStatInstance = statClazz.getMethod("getInstance", Context::class.java)
            val statDevice = getStatInstance.invoke(null, permissiveContext)

            if (statDevice != null) {
                val statGetters = arrayOf(
                    "getElecPercentageValue",      // SOC % (uses this!)
                    "getFuelPercentageValue",      // Fuel %
                    "getTotalElecConValue",        // Total kWh consumed
                    "getTotalFuelConValue",        // Total fuel consumed
                    "getEVMileageValue",           // EV range
                    "getWaterTemperature"          // Coolant temp
                )

                for (methodName in statGetters) {
                    testGetter(statClazz, statDevice, methodName)
                }

                // Test getMileageNumber(int type)
                try {
                    val m = statClazz.getMethod("getMileageNumber", Int::class.javaPrimitiveType)
                    for (type in 0..3) {
                        val result = m.invoke(statDevice, type)
                        log("  getMileageNumber($type) = $result")
                    }
                } catch (e: Exception) {
                    log("  getMileageNumber(int) = [ERROR]")
                }
            }

            // Test EnergyDevice
            log("--- BYDAutoEnergyDevice ---")
            val energyClazz = Class.forName("android.hardware.bydauto.energy.BYDAutoEnergyDevice")
            val getEnergyInstance = energyClazz.getMethod("getInstance", Context::class.java)
            val energyDevice = getEnergyInstance.invoke(null, permissiveContext)

            if (energyDevice != null) {
                val energyGetters = arrayOf(
                    "getElecPercentageValue",
                    "getEnergyMode",
                    "getOperationMode",
                    "getEVMileageValue"
                )

                for (methodName in energyGetters) {
                    testGetter(energyClazz, energyDevice, methodName)
                }
            }

            log("=== END CHARGING DATA TEST ===")
        } catch (e: Exception) {
            log("ERROR testing devices: " + e.message)
        }
    }

    private fun testGetter(clazz: Class<*>, device: Any, methodName: String) {
        try {
            val method = clazz.getMethod(methodName)
            val result = method.invoke(device)

            val resultStr: String = when (result) {
                null -> "null"
                is IntArray -> result.contentToString()
                is DoubleArray -> result.contentToString()
                else -> result.toString()
            }

            log("  $methodName() = $resultStr")
        } catch (e: NoSuchMethodException) {
            log("  $methodName() = [NOT FOUND]")
        } catch (e: Exception) {
            val msg = e.cause?.message ?: e.message
            log("  $methodName() = [ERROR: $msg]")
        }
    }

    // ==================== SHELL EXECUTION ====================

    /**
     * Disable BYD's built-in traffic monitor app.
     * It runs in the background consuming mobile data and battery.
     */
    private fun disableBydTrafficMonitor() {
        try {
            val result = execShell("pm disable-user --user 0 com.byd.trafficmonitor 2>&1")
            log("Disable BYD traffic monitor: $result")
        } catch (e: Exception) {
            log("Failed to disable BYD traffic monitor: " + e.message)
        }
    }

    private fun execShell(cmd: String): String {
        try {
            val process = Runtime.getRuntime().exec(arrayOf("sh", "-c", cmd))
            process.waitFor()
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            val output = StringBuilder()
            var line: String?
            while (reader.readLine().also { line = it } != null) {
                output.append(line).append("\n")
            }
            return output.toString().trim()
        } catch (e: Exception) {
            return "ERROR: " + e.message
        }
    }

    // ==================== MONITORING & DIAGNOSTICS ====================

    /**
     * Install shutdown hook to detect process termination.
     * This helps debug why the daemon might be dying.
     */
    private fun installShutdownHook() {
        Runtime.getRuntime().addShutdownHook(Thread({
            log("=== SHUTDOWN HOOK TRIGGERED ===")
            log("Reason: Process is being terminated")
            log("Uptime: " + (System.currentTimeMillis() - startTime) / 1000 + "s")
            log("InSentryMode: $inSentryMode")
            log("Running flag: $running")

            // Try to determine why we're dying
            try {
                val ps = execShell("ps -p " + Process.myPid())
                log("Process status before death: $ps")
            } catch (e: Exception) {
                log("Could not get process status: " + e.message)
            }

            // Check wake lock status
            wakeLock?.let { lock ->
                try {
                    log("WakeLock held: " + lock.isHeld)
                } catch (e: Exception) {
                    log("Could not check WakeLock: " + e.message)
                }
            }

            // Log memory status at death
            try {
                logMemoryStatus()
            } catch (e: Exception) {
                log("Could not log memory status: " + e.message)
            }

            log("=== SHUTDOWN COMPLETE ===")
        }, "ShutdownHook"))

        log("Shutdown hook installed")
    }

    /**
     * Log current memory status.
     * Helps detect if we're being killed due to low memory.
     */
    private fun logMemoryStatus() {
        val ctx = appContext
        if (ctx == null) {
            log("Cannot log memory status: no context")
            return
        }

        try {
            val memInfo = ActivityManager.MemoryInfo()
            val am = ctx.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager?

            if (am != null) {
                am.getMemoryInfo(memInfo)
                val availMB = memInfo.availMem / 1024 / 1024
                val totalMB = memInfo.totalMem / 1024 / 1024
                val usedMB = totalMB - availMB

                log("=== MEMORY STATUS ===")
                log("  Available: $availMB MB")
                log("  Total: $totalMB MB")
                log("  Used: $usedMB MB")
                log("  Low memory: " + memInfo.lowMemory)
                log("  Threshold: " + (memInfo.threshold / 1024 / 1024) + " MB")
            } else {
                log("ActivityManager is null")
            }
        } catch (e: Exception) {
            log("Error logging memory status: " + e.message)
        }
    }

    /**
     * Start periodic status monitoring.
     * Logs daemon health every 60 seconds for debugging.
     */
    private fun startStatusMonitoring() {
        val handler = statusHandler
        if (handler == null) {
            log("Cannot start status monitoring: no handler")
            return
        }

        val statusCheck = object : Runnable {
            override fun run() {
                try {
                    val uptimeSeconds = (System.currentTimeMillis() - startTime) / 1000
                    val uptimeMinutes = uptimeSeconds / 60

                    log("=== STATUS CHECK ===")
                    log("  Uptime: " + uptimeMinutes + "m " + (uptimeSeconds % 60) + "s")
                    log("  WakeLock: " + (wakeLock?.isHeld == true))
                    log("  InSentryMode: $inSentryMode")
                    log("  Running: $running")
                    log("  KeepAlive thread: " + (systemKeepAliveThread?.isAlive == true))
                    log("  Charging thread: " + (mcuChargingThread?.isAlive == true))
                    log("  Surveillance: $surveillanceEnabled")
                    log("  Last power level: " + powerLevelToString(lastPowerLevel))
                    log("  Last MCU status: $lastMcuStatus")

                    // Check MCU status
                    val currentMcuStatus = getMcuStatus()
                    if (currentMcuStatus != -1) {
                        log("  Current MCU status: $currentMcuStatus")
                    }

                    // Log memory every 5 minutes
                    if (uptimeMinutes % 5 == 0L) {
                        logMemoryStatus()
                    }

                    log("===================")
                } catch (e: Exception) {
                    log("Status check error: " + e.message)
                }

                // Schedule next check
                if (running && statusHandler != null) {
                    statusHandler?.postDelayed(this, 60000)  // 60 seconds
                }
            }
        }

        // Start first check after 60 seconds
        handler.postDelayed(statusCheck, 60000)
        log("Status monitoring started (60s interval)")
    }

    /**
     * Stop periodic status monitoring.
     */
    private fun stopStatusMonitoring() {
        statusHandler?.let {
            it.removeCallbacksAndMessages(null)
            log("Status monitoring stopped")
        }
    }
}
