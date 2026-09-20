package net.bladewatch.app.byd

import android.content.Context

import net.bladewatch.app.logging.DaemonLogger

import java.lang.reflect.Method
import java.util.concurrent.atomic.AtomicReference

/**
 * Universal BYD Data Collector — singleton that initializes ALL BYD device types,
 * reads initial values, registers listeners for live updates, and exposes a
 * thread-safe BydVehicleData snapshot.
 *
 * Every device init and every method call is individually try/caught — one device
 * failing never affects others. Never crashes.
 */
class BydDataCollector private constructor() {

    private val snapshot = AtomicReference<BydVehicleData>()
    private var context: Context? = null
    @Volatile private var initializedValue = false

    // Device references (all nullable)
    private var bodyworkDevice: Any? = null
    private var speedDevice: Any? = null
    private var engineDevice: Any? = null
    private var statisticDevice: Any? = null
    private var energyDevice: Any? = null
    private var tyreDevice: Any? = null
    private var chargingDevice: Any? = null
    private var doorLockDevice: Any? = null
    private var instrumentDevice: Any? = null
    private var otaDevice: Any? = null
    private var sensorDevice: Any? = null
    private var gearboxDevice: Any? = null
    private var safetyBeltDevice: Any? = null
    private var acDevice: Any? = null
    private var lightDevice: Any? = null
    private var adasDeviceValue: Any? = null
    private var radarDevice: Any? = null
    private var powerDevice: Any? = null
    private var settingDevice: Any? = null
    private var multimediaDeviceValue: Any? = null

    // Unit conversion: BYD APIs return values in the user's configured unit.
    // If the user set miles on the instrument cluster, mileage/speed/range come back in miles/mph.
    // We detect this once at init and convert everything to km at the ingestion boundary.
    private var distanceToKmFactorValue = 1.0  // 1.0 = already km, 1.60934 = miles→km
    private var unitDetected = false

    private val availableDevices = ArrayList<String>()
    private val unavailableDevices = ArrayList<String>()

    // Door-lock getters can return INVALID while the typed listener still
    // emits real transitions. Cache listener values so the UI can stay accurate
    // after a lock/unlock event even when the direct poll path is blank.
    private val doorLockEventCache = intArrayOf(
        LOCK_API_UNKNOWN, LOCK_API_UNKNOWN, LOCK_API_UNKNOWN,
        LOCK_API_UNKNOWN, LOCK_API_UNKNOWN, LOCK_API_UNKNOWN,
        LOCK_API_UNKNOWN
    )
    private var lastDoorLockSnapshotLog = ""

    // ==================== EVENT LISTENERS ====================
    // Subscribers receive door/lock events from the typed BYD HAL listeners.
    // Use these instead of polling the snapshot when you need immediate
    // notification of state transitions (e.g. surveillance arming gates).

    /** Raw SDK door-open/close events from the bodywork HAL. */
    fun interface DoorStateListener {
        /** @param area BYD area constant. @param state 0=closed,1=open per SDK. */
        fun onDoorStateChanged(area: Int, state: Int)
    }

    /** Raw SDK lock events from the doorlock HAL. */
    fun interface DoorLockListener {
        /** @param area BYD area constant. @param sdkState SDK semantics: INVALID=0,UNLOCK=1,LOCK=2. */
        fun onDoorLockStatusChanged(area: Int, sdkState: Int)
    }

    /** Snapshot-level lock summary listener — called on every snapshot update
     *  whose lock data may have changed. Use this when you want a single
     *  cohesive view of all areas rather than per-area events. */
    interface LockSnapshotListener {
        fun onLockSnapshotUpdated(snapshot: BydVehicleData)
    }

    /** Raw BMS charging-state edges from the charging HAL. Fires only on
     *  transitions (current != previous), not on every poll. State values
     *  match `ChargingStateData.CHARGING_BATTERY_STATE_*`. */
    fun interface ChargingStateListener {
        fun onChargingStateChanged(previousState: Int, newState: Int)
    }

    private val doorStateListeners = java.util.concurrent.CopyOnWriteArrayList<DoorStateListener>()
    private val doorLockListeners = java.util.concurrent.CopyOnWriteArrayList<DoorLockListener>()
    private val lockSnapshotListeners = java.util.concurrent.CopyOnWriteArrayList<LockSnapshotListener>()
    private val chargingStateListeners = java.util.concurrent.CopyOnWriteArrayList<ChargingStateListener>()

    fun addDoorStateListener(l: DoorStateListener?) { if (l != null) doorStateListeners.addIfAbsent(l) }
    fun removeDoorStateListener(l: DoorStateListener?) { doorStateListeners.remove(l) }
    fun addDoorLockListener(l: DoorLockListener?) { if (l != null) doorLockListeners.addIfAbsent(l) }
    fun removeDoorLockListener(l: DoorLockListener?) { doorLockListeners.remove(l) }
    fun addLockSnapshotListener(l: LockSnapshotListener?) { if (l != null) lockSnapshotListeners.addIfAbsent(l) }
    fun removeLockSnapshotListener(l: LockSnapshotListener?) { lockSnapshotListeners.remove(l) }
    fun addChargingStateListener(l: ChargingStateListener?) { if (l != null) chargingStateListeners.addIfAbsent(l) }
    fun removeChargingStateListener(l: ChargingStateListener?) { chargingStateListeners.remove(l) }

    private fun notifyDoorStateListeners(area: Int, state: Int) {
        for (l in doorStateListeners) {
            try { l.onDoorStateChanged(area, state) }
            catch (e: Exception) { logger.debug("DoorStateListener error: " + e.message) }
        }
    }

    private fun notifyDoorLockListeners(area: Int, sdkState: Int) {
        for (l in doorLockListeners) {
            try { l.onDoorLockStatusChanged(area, sdkState) }
            catch (e: Exception) { logger.debug("DoorLockListener error: " + e.message) }
        }
    }

    private fun notifyLockSnapshotListeners(snap: BydVehicleData) {
        for (l in lockSnapshotListeners) {
            try { l.onLockSnapshotUpdated(snap) }
            catch (e: Exception) { logger.debug("LockSnapshotListener error: " + e.message) }
        }
    }

    private fun notifyChargingStateListeners(previousState: Int, newState: Int) {
        for (l in chargingStateListeners) {
            try { l.onChargingStateChanged(previousState, newState) }
            catch (e: Exception) { logger.debug("ChargingStateListener error: " + e.message) }
        }
    }

    /** Get the latest vehicle data snapshot. Thread-safe. */
    val data: BydVehicleData?
        get() = snapshot.get()

    /** Check if the collector has been initialized. */
    val isInitialized: Boolean
        get() = initializedValue

    /**
     * Public drivetrain classifier for consumers that need PHEV-specific data
     * handling. The actual detection stays centralized in computeIsPhev() so
     * SOH, range, and charging code all agree on the same fuel-signal logic.
     */
    fun isPhevVehicle(): Boolean {
        return try {
            computeIsPhev()
        } catch (t: Throwable) {
            logger.debug("PHEV detection failed: " + t.message)
            false
        }
    }

    /**
     * Directly reads the recovered legacy OEM SOH value from the BYD Statistic
     * device. Returns -1 when the firmware does not expose a sane 1..100 value.
     *
     * This remains a collector-level helper so every consumer uses the same
     * getter/feature-id fallback and validation rules.
     */
    fun readOemSohPercent(): Double {
        if (statisticDevice == null) return -1.0
        try {
            var sohValue: Int? = null
            try {
                val result = BydDeviceHelper.callGetter(statisticDevice, "getStatisticBatteryHealthyIndex")
                if (result is Number) {
                    sohValue = result.toInt()
                }
            } catch (nsme: NoSuchMethodError) {
                logger.debug("SOH getStatisticBatteryHealthyIndex not found on this firmware")
            } catch (e: Exception) {
                if (e.cause !is NoSuchMethodError) {
                    logger.debug("SOH getter failed: " + e.message)
                }
            }

            if (sohValue == null || sohValue <= 0 || sohValue > 100) {
                try {
                    val sohVal = BydDeviceHelper.callGet(statisticDevice, BydFeatureIds.STAT_BATTERY_HEALTHY_INDEX, Integer::class.java)
                    if (sohVal != null) {
                        val raw = BydDeviceHelper.getIntValue(sohVal)
                        if (raw > 0 && raw <= 100) {
                            sohValue = raw
                        }
                    }
                } catch (e: Exception) {
                    logger.debug("SOH feature ID failed: " + e.message)
                }
            }

            return if (sohValue != null && sohValue > 0 && sohValue <= 100) sohValue.toDouble() else -1.0
        } catch (e: Exception) {
            logger.debug("readOemSohPercent error: " + e.message)
            return -1.0
        }
    }

    // ==================== INITIALIZATION ====================

    /**
     * Initialize all BYD devices. Each device is independent — failures are logged and skipped.
     */
    @Synchronized
    fun init(context: Context) {
        if (initializedValue && this.context === context) {
            return
        }
        this.context = context
        logger.info("=== BYD Data Collector Initializing ===")
        val start = System.currentTimeMillis()

        // Re-init: tear down state that would otherwise accumulate.
        availableDevices.clear()
        unavailableDevices.clear()
        pollScheduler?.shutdownNow()
        pollScheduler = null

        // Initialize each device type
        bodyworkDevice = initDevice("android.hardware.bydauto.bodywork.BYDAutoBodyworkDevice", "Bodywork")
        speedDevice = initDevice("android.hardware.bydauto.speed.BYDAutoSpeedDevice", "Speed")
        engineDevice = initDevice("android.hardware.bydauto.engine.BYDAutoEngineDevice", "Engine")
        statisticDevice = initDevice("android.hardware.bydauto.statistic.BYDAutoStatisticDevice", "Statistic")
        chargingDevice = initDevice("android.hardware.bydauto.charging.BYDAutoChargingDevice", "Charging")
        instrumentDevice = initDevice("android.hardware.bydauto.instrument.BYDAutoInstrumentDevice", "Instrument")
        otaDevice = initDevice("android.hardware.bydauto.ota.BYDAutoOtaDevice", "OTA")
        gearboxDevice = initDevice("android.hardware.bydauto.gearbox.BYDAutoGearboxDevice", "Gearbox")
        acDevice = initDevice("android.hardware.bydauto.ac.BYDAutoAcDevice", "AC")
        lightDevice = initDevice("android.hardware.bydauto.light.BYDAutoLightDevice", "Light")
        adasDeviceValue = initDevice("android.hardware.bydauto.adas.BYDAutoADASDevice", "ADAS")
        powerDevice = initDevice("android.hardware.bydauto.power.BYDAutoPowerDevice", "Power")
        safetyBeltDevice = initDevice("android.hardware.bydauto.safetybelt.BYDAutoSafetyBeltDevice", "SafetyBelt")
        tyreDevice = initDevice("android.hardware.bydauto.tyre.BYDAutoTyreDevice", "Tyre")
        doorLockDevice = initDevice("android.hardware.bydauto.doorlock.BYDAutoDoorLockDevice", "DoorLock")
        sensorDevice = initDevice("android.hardware.bydauto.sensor.BYDAutoSensorDevice", "Sensor")
        energyDevice = initDevice("android.hardware.bydauto.energy.BYDAutoEnergyDevice", "Energy")
        radarDevice = initDevice("android.hardware.bydauto.radar.BYDAutoRadarDevice", "Radar")
        settingDevice = initDevice("android.hardware.bydauto.setting.BYDAutoSettingDevice", "Setting")
        multimediaDeviceValue = initMultimediaDevice()

        logger.info("Devices available: " + availableDevices.size + "/" +
            (availableDevices.size + unavailableDevices.size))
        if (unavailableDevices.isNotEmpty()) {
            logger.info("Unavailable: " + java.lang.String.join(", ", unavailableDevices))
        }

        // Detect mileage unit from instrument cluster
        detectMileageUnit()

        // If auto-detection failed, fall back to user's persisted preference
        if (!unitDetected) {
            try {
                val tripConfig = net.bladewatch.app.trips.TripConfig()
                tripConfig.load()
                val savedUnit = tripConfig.getDistanceUnit()
                if ("mi" == savedUnit) {
                    distanceToKmFactorValue = MILES_TO_KM
                    unitDetected = true
                    logger.info("Mileage unit: MILES (from user config override, factor=$MILES_TO_KM)")
                }
            } catch (e: Exception) {
                logger.info("Could not load distance unit from TripConfig: " + e.message)
            }
        }

        // Read initial values (full collection including display-only devices)
        collectAllFull()

        // Dump all battery/energy related getter methods on key devices
        // to discover the correct remaining kWh API at runtime
        // Discovery methods removed — getBatteryRemainPowerEV() confirmed as correct BEV API.
        // BYD light/setting APIs have no write access from UID 2000.

        // Register listeners
        registerAllListeners()

        // Runtime receiver for power-cable plug edges. Manifest receiver
        // BootReceiver already covers cold-boot delivery, but Android
        // delivers POWER_CONNECTED/DISCONNECTED to runtime-registered
        // receivers more reliably while the process is alive — and the
        // ChargingDetector needs these edges within milliseconds of the
        // user plugging in so the fused state doesn't lag a 5s collect
        // cycle waiting for BMS to catch up.
        registerPlugEdgeReceiver()

        // Bridge BYD door-state events to push notifications. Safe to start
        // here — the door listener is only invoked once the bodywork HAL
        // fires onDoorStateChanged, which requires registerAllListeners to
        // have run first.
        net.bladewatch.app.notifications.DoorEventNotifier.start()
        net.bladewatch.app.notifications.ChargingEventNotifier.start()

        // Start periodic polling to keep data fresh (listeners may not fire for all values)
        startPolling()

        val elapsed = System.currentTimeMillis() - start
        logger.info("=== BYD Data Collector Ready (" + elapsed + "ms) ===")
        initializedValue = true
    }

    /**
     * Detect whether the BYD instrument cluster is configured for miles or km.
     * getMileageUnit() returns 1 for km, 0 for miles.
     * If detection fails, defaults to km (factor = 1.0).
     */
    private fun detectMileageUnit() {
        if (instrumentDevice == null) {
            logger.info("Mileage unit: defaulting to km (no instrument device)")
            return
        }
        try {
            val unitVal = BydDeviceHelper.callGetter(instrumentDevice, "getMileageUnit")
            if (unitVal is Number) {
                val unit = unitVal.toInt()
                distanceToKmFactorValue = BydSignalRules.distanceFactorForMileageUnit(unit)
                unitDetected = true
                logger.info("Mileage unit: " + (if (distanceToKmFactorValue > 1.0) "MILES" else "KM")
                        + " detected (factor=" + distanceToKmFactorValue + ")")
            } else {
                logger.info("Mileage unit: defaulting to km (getMileageUnit returned null)")
            }
        } catch (e: Exception) {
            logger.info("Mileage unit: defaulting to km (detection failed: " + e.message + ")")
        }
    }

    /**
     * Get the distance-to-km conversion factor.
     * Returns 1.0 if km, 1.60934 if miles.
     * Used by OdometerReader and other components that read BYD distance values directly.
     */
    val distanceToKmFactor: Double
        get() = distanceToKmFactorValue

    /**
     * Override the distance unit from user settings. Called when the user
     * explicitly selects km or miles in the Trip Settings UI. This fixes the
     * case where auto-detection via getMileageUnit() fails (instrumentDevice
     * null, SDK returns null, etc.) and the raw miles values pass through
     * unconverted.
     *
     * @param unit "mi" for miles (factor=1.60934), "km" for km (factor=1.0)
     */
    fun setDistanceUnitOverride(unit: String?) {
        if ("mi" == unit) {
            distanceToKmFactorValue = MILES_TO_KM
            unitDetected = true
            logger.info("Distance unit OVERRIDE: MILES (factor=$MILES_TO_KM)")
        } else {
            distanceToKmFactorValue = 1.0
            unitDetected = true
            logger.info("Distance unit OVERRIDE: KM (factor=1.0)")
        }
    }

    /**
     * Returns true if the vehicle's instrument cluster is configured for miles.
     * Used by the /status API to tell the web UI which display unit to use.
     */
    val isMilesMode: Boolean
        get() = distanceToKmFactorValue > 1.0

    private var pollScheduler: java.util.concurrent.ScheduledExecutorService? = null
    private var lastSummaryHash = ""

    private fun startPolling() {
        val scheduler = java.util.concurrent.Executors.newSingleThreadScheduledExecutor { r ->
            val t = Thread(r, "BydDataPoll")
            t.isDaemon = true
            t
        }
        pollScheduler = scheduler
        scheduler.scheduleAtFixedRate({
            try {
                collectAll()
                // Log when data actually changes
                val d = snapshot.get()
                if (d != null) {
                    val hash = String.format(
                        "%.1f|%.2f|%.1f/%.1f/%.1f|%.3f/%.3f",
                        d.socPercent, d.voltage12v, d.highCellTempC, d.lowCellTempC, d.avgCellTempC,
                        d.highCellVoltage, d.lowCellVoltage
                    )
                    if (hash != lastSummaryHash) {
                        logger.info("Data changed: SOC=" + d.socPercent + "% 12V=" + d.voltage12v + "V" +
                            " Temp=" + d.highCellTempC + "/" + d.lowCellTempC + "/" + d.avgCellTempC + "°C" +
                            " CellV=" + d.highCellVoltage + "/" + d.lowCellVoltage + "V")
                        lastSummaryHash = hash
                    }
                }
            } catch (t: Throwable) {
                logger.debug("Poll error: " + t.message)
            }
        }, POLL_INTERVAL_MS, POLL_INTERVAL_MS, java.util.concurrent.TimeUnit.MILLISECONDS)
    }

    fun stop() {
        pollScheduler?.shutdownNow()
        pollScheduler = null
        unregisterPlugEdgeReceiver()
        initializedValue = false
    }

    private var plugEdgeReceiver: android.content.BroadcastReceiver? = null

    private fun registerPlugEdgeReceiver() {
        val ctx = context ?: return
        if (android.os.Process.myUid() == android.os.Process.SHELL_UID) {
            // The camera daemon runs under app_process as shell UID 2000. That
            // synthetic process has no package identity, so Android rejects
            // registerReceiver("Unable to find app for caller") on every boot.
            // ChargingDetector still receives polled BYD charging signals in
            // daemon mode; app-UID processes can register this receiver normally.
            return
        }
        // Idempotent — re-init flow tears down and re-registers.
        unregisterPlugEdgeReceiver()
        val receiver = object : android.content.BroadcastReceiver() {
            override fun onReceive(ctx: android.content.Context?, intent: android.content.Intent?) {
                if (intent == null || intent.action == null) return
                val det = net.bladewatch.app.monitor.ChargingDetector.getInstance()
                when (intent.action) {
                    android.content.Intent.ACTION_POWER_CONNECTED -> det.onPowerConnected()
                    android.content.Intent.ACTION_POWER_DISCONNECTED -> det.onPowerDisconnected()
                }
            }
        }
        plugEdgeReceiver = receiver
        try {
            val f = android.content.IntentFilter()
            f.addAction(android.content.Intent.ACTION_POWER_CONNECTED)
            f.addAction(android.content.Intent.ACTION_POWER_DISCONNECTED)
            ctx.registerReceiver(receiver, f)
            logger.info("Plug-edge receiver registered (CONNECTED/DISCONNECTED)")
        } catch (e: Exception) {
            logger.debug("registerPlugEdgeReceiver failed: " + e.message)
            plugEdgeReceiver = null
        }
    }

    private fun unregisterPlugEdgeReceiver() {
        val ctx = context
        val receiver = plugEdgeReceiver
        if (ctx == null || receiver == null) return
        try {
            ctx.unregisterReceiver(receiver)
        } catch (e: Exception) {
            logger.debug("unregisterPlugEdgeReceiver failed: " + e.message)
        }
        plugEdgeReceiver = null
    }

    private fun initDevice(className: String, shortName: String): Any? {
        val device = BydDeviceHelper.getDevice(className, context)
        if (device != null) {
            availableDevices.add(shortName)
        } else {
            unavailableDevices.add(shortName)
        }
        return device
    }

    /**
     * Initialize the multimedia device with multiple context strategies.
     * BYDAutoMultimediaDevice does NOT extend AbsBYDAutoDevice — it's a separate class
     * that connects to a binder service and may require a specific package identity.
     */
    private fun initMultimediaDevice(): Any? {
        val className = "android.hardware.bydauto.multimedia.BYDAutoMultimediaDevice"

        // Strategy 1: Use our normal context (works for all other devices)
        var device = BydDeviceHelper.getDevice(className, context)
        if (device != null) {
            availableDevices.add("Multimedia")
            return device
        }

        // Strategy 2: Try with a proper app context for net.bladewatch.app
        // The daemon runs via app_process with a synthetic context. But the actual app
        // is installed — createPackageContext gives us a real app context with proper
        // service bindings that the multimedia device might need.
        try {
            val appPkgCtx = context?.createPackageContext(
                "net.bladewatch.app",
                android.content.Context.CONTEXT_INCLUDE_CODE or android.content.Context.CONTEXT_IGNORE_SECURITY
            )
            if (appPkgCtx != null) {
                device = BydDeviceHelper.getDevice(className, appPkgCtx)
                if (device != null) {
                    logger.info("Multimedia device OK via net.bladewatch.app package context")
                    availableDevices.add("Multimedia")
                    return device
                }
            }
        } catch (e: Exception) {
            logger.debug("Multimedia strategy 2 (bladewatch package context) failed: " + e.message)
        }

        // Strategy 3: Try with system context directly (with timeout — can deadlock)
        try {
            val result = arrayOfNulls<Any>(1)
            val t = Thread({
                try {
                    val atClass = Class.forName("android.app.ActivityThread")
                    val currentAt = atClass.getMethod("currentActivityThread")
                    val at = currentAt.invoke(null)
                    if (at != null) {
                        val getSystemContext = atClass.getMethod("getSystemContext")
                        val sysCtx = getSystemContext.invoke(at) as? android.content.Context
                        if (sysCtx != null) {
                            result[0] = BydDeviceHelper.getDevice(className, sysCtx)
                        }
                    }
                } catch (e: Exception) {
                    logger.debug("Multimedia strategy 3 inner: " + e.message)
                }
            }, "MultimediaInit-SysCtx")
            t.isDaemon = true
            t.start()
            t.join(3000) // 3s timeout — abort if it hangs
            if (t.isAlive) {
                logger.warn("Multimedia strategy 3 timed out (3s) — skipping to avoid freeze")
                t.interrupt()
            } else if (result[0] != null) {
                device = result[0]
                logger.info("Multimedia device OK via system context")
                availableDevices.add("Multimedia")
                return device
            }
        } catch (e: Exception) {
            logger.debug("Multimedia strategy 3 (system context) failed: " + e.message)
        }

        // Strategy 4: Try with getApplicationContext() directly
        try {
            val appCtx = context?.applicationContext
            if (appCtx != null && appCtx !== context) {
                device = BydDeviceHelper.getDevice(className, appCtx)
                if (device != null) {
                    logger.info("Multimedia device OK via getApplicationContext()")
                    availableDevices.add("Multimedia")
                    return device
                }
            }
        } catch (e: Exception) {
            logger.debug("Multimedia strategy 4 (app context) failed: " + e.message)
        }

        unavailableDevices.add("Multimedia")
        return null
    }

    // ==================== DATA COLLECTION ====================

    // Core data polled every 5s. Display-only data updated via listeners only (no polling).
    // Core = fields consumed by trip analytics, SOC history.
    // Display = fields only shown on the web dashboard — updated by BYD HAL listener callbacks
    //           or on-demand via collectAllFull() when the HTTP API is queried.

    // Hard throttle: never poll devices more frequently than this, even if listeners fire.
    // Listener callbacks update individual values directly in the snapshot without polling.
    // This guard prevents any code path from triggering a full device sweep within the interval.
    @Volatile private var lastCoreCollectTime = 0L

    // ACC state: when off, skip polling speed/engine/gearbox (always 0 when parked)
    @Volatile private var accIsOn = true

    /** Called by CameraDaemon when ACC state changes. Adjusts poll rate accordingly. */
    fun setAccState(isOn: Boolean) {
        val wasOn = this.accIsOn
        this.accIsOn = isOn

        // Notify the fused charging detector first so it can invalidate
        // ACC-dependent signals (enginePowerKw goes stale once ACC is off
        // and must not be reused as charging evidence).
        net.bladewatch.app.monitor.ChargingDetector.getInstance().updateAccState(isOn)

        // ACC just transitioned OFF: also clear the snapshot's enginePowerKw
        // so any consumer reading the snapshot directly (not through the
        // detector) doesn't see a stale value from the last drive while the
        // car sits parked. Other ACC-gated fields (speedKmh, brake/accel, gear)
        // are refreshed by the next poll cycle which already skips collectSpeed
        // / collectGearbox when ACC is off — only enginePower needs an
        // explicit wipe because we *deliberately* keep collecting it on the
        // ACC-off "possibly charging" branch and a stale value there would
        // confuse the detector's inference layer.
        if (wasOn && !isOn) {
            val current = snapshot.get()
            if (current != null && !current.enginePowerKw.isNaN()) {
                snapshot.set(current.toBuilder().enginePowerKw(Double.NaN).build())
                logger.info("ACC OFF: invalidated stale enginePowerKw")
            }
        }

        // Restart poll scheduler at the appropriate rate
        val scheduler = pollScheduler
        if (scheduler != null && !scheduler.isShutdown) {
            scheduler.shutdownNow()
            val interval = if (isOn) POLL_INTERVAL_MS else POLL_INTERVAL_PARKED_MS
            val newScheduler = java.util.concurrent.Executors.newSingleThreadScheduledExecutor { r ->
                val t = Thread(r, "BydDataPoll")
                t.isDaemon = true
                t
            }
            pollScheduler = newScheduler
            newScheduler.scheduleAtFixedRate({
                try {
                    collectAll()
                    val d = snapshot.get()
                    if (d != null) {
                        val hash = String.format(
                            "%.1f|%.2f|%.1f/%.1f/%.1f|%.3f/%.3f",
                            d.socPercent, d.voltage12v, d.highCellTempC, d.lowCellTempC, d.avgCellTempC,
                            d.highCellVoltage, d.lowCellVoltage
                        )
                        if (hash != lastSummaryHash) {
                            logger.info("Data changed: SOC=" + d.socPercent + "% 12V=" + d.voltage12v + "V" +
                                " Temp=" + d.highCellTempC + "/" + d.lowCellTempC + "/" + d.avgCellTempC + "°C" +
                                " CellV=" + d.highCellVoltage + "/" + d.lowCellVoltage + "V")
                            lastSummaryHash = hash
                        }
                    }
                } catch (t: Throwable) {
                    logger.debug("Poll error: " + t.message)
                }
            }, 0, interval, java.util.concurrent.TimeUnit.MILLISECONDS)
            logger.info("BydDataPoll rate changed to " + (interval / 1000) + "s (ACC " + (if (isOn) "ON" else "OFF") + ")")
        }
    }

    /**
     * Collect core telemetry data from devices into the snapshot.
     * Safe to call from any thread.
     *
     * Hard-throttled: will not poll devices if called within 5 seconds of the last poll.
     *
     * Only polls CORE devices (used by trips, SOC history).
     * When ACC is off, skips speed/engine/gearbox (always 0 when parked).
     * Display-only devices are NOT polled — updated via listeners or on-demand.
     */
    fun collectAll() {
        val now = System.currentTimeMillis()

        // Hard throttle: skip if called within MIN_COLLECT_INTERVAL_MS of last poll.
        if (now - lastCoreCollectTime < MIN_COLLECT_INTERVAL_MS) {
            return
        }
        lastCoreCollectTime = now

        val b = snapshot.get()?.toBuilder() ?: BydVehicleData.Builder()
        b.availableDevices(availableDevices.toTypedArray())
        b.unavailableDevices(unavailableDevices.toTypedArray())

        // ALWAYS needed: battery, SOC, charging, temperature, 12V
        collectBodywork(b)     // SOC, 12V, remainKwh, powerLevel
        collectStatistic(b)    // SOC, mileage, range, cellTemps, cellVoltages
        collectCharging(b)     // chargingState, gunState, chargingPower
        collectInstrument(b)   // outsideTemp, externalChargingPower
        collectOta(b)          // 12V voltage (precise)
        collectTyre(b)         // pressure (kPa), pressure/leak/signal state per wheel

        // DRIVING ONLY: skip most when ACC is off (values are always 0/stale when parked).
        // EXCEPTION: enginePower remains meaningful when the car is plugged in and
        // charging — current flowing into the pack reads negative on the engine
        // bus and is the most authoritative charging signal we have on PHEVs
        // (where chargingGunState is often UNAVAILABLE and chargingState is
        // stuck at 15=IDLE due to firmware bugs). Detect "probably charging"
        // from the listener-delivered chargingPower / externalChargingPower
        // values populated from typed callbacks even while ACC is off.
        if (accIsOn) {
            collectSpeed(b)        // speed, accel, brake
            collectEngine(b)       // enginePower, motorSpeed/torque
            collectGearbox(b)      // gearMode
        } else {
            val possiblyCharging = BydSignalRules.possiblyChargingWhileParked(
                b.chargingPowerKw, b.externalChargingPowerKw,
                b.chargingState, b.chargingGunState
            )
            if (possiblyCharging) {
                collectEngine(b)   // adds enginePowerKw → confirms direction
            }
        }

        // Extended data consumed by trips, SOC history
        collectStatisticExtended(b)   // SOH, driving time, key battery
        collectInstrumentExtended(b)  // cabin temp, trip data, consumption

        // Key proximity probe — runs every poll (ACC on or off) so we keep observing
        // fob state across the parked-charging window and any "approach unlock" event.
        collectKeyProximity(b)

        val built = b.build()
        snapshot.set(built)
        pushChargingEvidence(built)
    }

    /**
     * Force a full collection of ALL data including display-only fields.
     * Bypasses the 5-second throttle. Called by the HTTP API when a client
     * explicitly requests the full vehicle data, or during init().
     */
    fun collectAllFull() {
        lastCoreCollectTime = 0  // Bypass throttle

        val b = snapshot.get()?.toBuilder() ?: BydVehicleData.Builder()
        b.availableDevices(availableDevices.toTypedArray())
        b.unavailableDevices(unavailableDevices.toTypedArray())

        // Core devices
        collectBodywork(b)
        collectSpeed(b)
        collectEngine(b)
        collectStatistic(b)
        collectCharging(b)
        collectInstrument(b)
        collectOta(b)
        collectGearbox(b)

        // Display-only devices (normally listener-driven, polled here on-demand)
        collectAc(b)
        collectLight(b)
        collectAdas(b)
        collectSettings(b)
        collectPower(b)
        collectSafetyBelt(b)
        collectTyre(b)
        collectDoorLock(b)
        collectSensor(b)
        collectEnergy(b)
        collectRadar(b)

        // Extended data — core + display-only
        collectStatisticExtended(b)   // SOH, driving time, key battery
        collectInstrumentExtended(b)  // cabin temp, trip data, consumption
        collectChargingExtended(b)    // charging rest time
        collectBodyworkExtended(b)    // steering, auto system, 12V level, sunroof, sunshade
        collectEngineExtended(b)      // coolant, oil, engine code

        val built = b.build()
        snapshot.set(built)
        pushChargingEvidence(built)
        lastCoreCollectTime = System.currentTimeMillis()
    }

    /**
     * Push the latest snapshot into the fused ChargingDetector so its
     * inference layer can reason about fresh power-flow / gun / gear data.
     * The detector's L1 (BMS edge) and L2 (Power.isCharging) inputs come
     * from listener callbacks and the explicit poll above; this method
     * supplies L3 evidence.
     */
    private fun pushChargingEvidence(built: BydVehicleData?) {
        if (built == null) return
        // Resolve gear from authoritative GearMonitor (returns last-known
        // value even when its monitor stops on ACC OFF). On a parked car
        // that's always P. The detector uses gear==P as an L3 guard.
        var gearNow: Int
        try {
            val gm = net.bladewatch.app.monitor.GearMonitor.getInstance()
            gearNow = gm.currentGear
        } catch (e: Exception) {
            gearNow = if (built.gearMode != BydVehicleData.UNAVAILABLE)
                built.gearMode
            else
                net.bladewatch.app.monitor.GearMonitor.GEAR_P
        }
        net.bladewatch.app.monitor.ChargingDetector.getInstance()
            .updatePollEvidence(built, gearNow, net.bladewatch.app.monitor.GearMonitor.GEAR_P)
    }

    private fun collectBodywork(b: BydVehicleData.Builder) {
        val device = bodyworkDevice ?: return
        try {
            // VIN
            val vin = BydDeviceHelper.callGetter(device, "getAutoVIN")
            if (vin is String) b.vin(vin)

            // 12V auxiliary battery voltage (0-255 → 0-25.5V)
            // NOTE: getBatteryPowerValue() returns 12V battery voltage, NOT traction battery SOC.
            // SOC comes from StatisticDevice.getElecPercentageValue() — see collectStatistic().
            val battPowerRaw = BydDeviceHelper.callGetter(device, "getBatteryPowerValue")
            if (battPowerRaw is Number) {
                val voltage12v = BydSignalRules.scale12vVoltage(battPowerRaw.toDouble())
                if (voltage12v != null && b.voltage12v.isNaN()) {
                    b.voltage12v(voltage12v)
                }
            }

            // Battery remaining energy — try multiple APIs in priority order.
            // Priority 1: PowerDevice.getBatteryRemainPowerEV() — most accurate for BEVs.
            // On PHEVs this may return stale values when ICE is running — validate against SOC.
            //
            // NOTE: We deliberately do NOT gate the priority-1/2 reads on
            // `Double.isNaN(b.remainKwh)`. Because `b` is built from the previous snapshot
            // via toBuilder(), gating on NaN means we only ever read these getters ONCE
            // (the very first poll after init), and the value freezes thereafter —
            // observable as "Remaining kWh stuck at last seen value when the vehicle is
            // off". The validation block below already protects the cached value from HAL
            // garbage: out-of-range readings are skipped (not written), so the last-known
            // good value is preserved when the BYD HAL goes flaky after ACC OFF.
            //
            // We track whether priority 1 or 2 wrote a fresh kWh this cycle so the
            // priority-3 capacity fallback (older SDKs only) doesn't clobber it.
            var kwhWrittenThisCycle = false
            val pDevice = powerDevice
            if (pDevice != null) {
                try {
                    val evKwh = BydDeviceHelper.callGetter(pDevice, "getBatteryRemainPowerEV")
                    if (evKwh is Number) {
                        val evVal = evKwh.toDouble()
                        if (evVal > 1 && evVal < 120) {
                            // Validate: implied capacity should be within 50-150% of any BYD pack
                            val soc = b.socPercent
                            if (!soc.isNaN() && soc > 5) {
                                val impliedCap = evVal / (soc / 100.0)
                                if (BydSignalRules.isRemainKwhConsistentWithSoc(evVal, soc)) {
                                    b.remainKwh(evVal)
                                    kwhWrittenThisCycle = true
                                    logger.debug("remainKwh from getBatteryRemainPowerEV: " +
                                        String.format("%.1f", evVal))
                                } else {
                                    logger.debug("getBatteryRemainPowerEV rejected: " +
                                        String.format("%.1f", evVal) + " kWh at " +
                                        String.format("%.0f", soc) + "% SOC → implied " +
                                        String.format("%.1f", impliedCap) + " kWh")
                                }
                            } else if (b.remainKwh.isNaN()) {
                                // No SOC to validate against. Only accept the unvalidated
                                // reading on first poll (when there is no prior cached value
                                // to risk overwriting with HAL garbage).
                                b.remainKwh(evVal)
                                kwhWrittenThisCycle = true
                            }
                        }
                    }
                } catch (e: Exception) {
                    logger.debug("getBatteryRemainPowerEV failed: " + e.message)
                }
            }

            // Priority 2: StatisticDevice.getRemainingBatteryPower() — returns int (0.1 kWh units)
            // Only consulted when Priority 1 did NOT succeed this cycle. Without this guard,
            // both sources race every cycle and last-writer-wins; on Seal we observed
            // Priority 1 reporting 16.5 kWh (correct → 82.5 kWh nominal at 20% SOC) being
            // overwritten by Priority 2 reporting 20.6 kWh (wrong → 103 kWh implied), which
            // poisoned every downstream auto-detection.
            if (!kwhWrittenThisCycle && statisticDevice != null) {
                try {
                    val rawPower = BydDeviceHelper.callGetter(statisticDevice, "getRemainingBatteryPower")
                    if (rawPower is Number) {
                        val rawVal = rawPower.toInt()
                        if (rawVal > 10 && rawVal < 1200) {  // 1-120 kWh in 0.1 units
                            val kwh = rawVal / 10.0
                            // Validate against SOC
                            val soc = b.socPercent
                            if (!soc.isNaN() && soc > 5) {
                                if (BydSignalRules.isRemainKwhConsistentWithSoc(kwh, soc)) {
                                    b.remainKwh(kwh)
                                    kwhWrittenThisCycle = true
                                    logger.debug("remainKwh from getRemainingBatteryPower: " +
                                        String.format("%.1f", kwh) + " (raw=" + rawVal + ")")
                                }
                            } else if (b.remainKwh.isNaN()) {
                                // No SOC to validate. Only accept on first poll — see Priority 1 note.
                                b.remainKwh(kwh)
                                kwhWrittenThisCycle = true
                            }
                        }
                    }
                } catch (e: Exception) {
                    logger.debug("getRemainingBatteryPower failed: " + e.message)
                }
            }

            // getBatteryCapacity() — semantics vary by model:
            // - Newer models: returns Ah rating (fixed, e.g. 150 for Atto 3)
            // - Older models: returns remaining energy in 0.1 kWh units (changes with SOC)
            // Used as remainKwh fallback when prior priorities haven't filled it.
            val cap = BydDeviceHelper.callGetter(device, "getBatteryCapacity")
            if (cap is Number) {
                val capVal = cap.toDouble()
                if (capVal > 0) b.capacityAh(capVal)

                // Fallback for older models where Priorities 1/2 are unavailable:
                // getBatteryCapacity() returns remaining energy in 0.1 kWh units (changes
                // with SOC). Skip when the value looks like a static Ah rating (50-350
                // range, handled by the SOH-feed block above) — otherwise we'd overwrite
                // a real kWh reading with an Ah number scaled by 10. Also skip if
                // priorities 1 or 2 already wrote a fresh validated kWh this cycle, so
                // this fallback truly stays a fallback.
                //
                // No `Double.isNaN(b.remainKwh)` guard here: on the older SDKs that need
                // this fallback, this is the only signal, and gating on NaN would freeze
                // it at the first poll's value (the bug this whole block was rewritten
                // to fix). The 1-120 kWh sanity window protects against junk readings.
                val looksLikeAhRating = BydSignalRules.looksLikeAhRating(capVal)
                if (!kwhWrittenThisCycle && !looksLikeAhRating && capVal > 0) {
                    val kwhFromCap = capVal / 10.0
                    if (BydSignalRules.isPlausibleRemainKwh(kwhFromCap)) {
                        b.remainKwh(kwhFromCap)
                    }
                }
            }

            // Power level
            val pl = BydDeviceHelper.callGetter(device, "getPowerLevel")
            if (pl is Number) b.powerLevel(pl.toInt())

            // getEnergyType removed — observed returning 1 on both BEV and PHEV
            // firmwares, so it cannot be trusted as a drivetrain discriminator.
            // PHEV detection now uses live fuel HAL signals (computeIsPhev).

            // Battery temp from bodywork (feature ID 300941320, Double.TYPE)
            val battTemp = BydDeviceHelper.callGet(device, BydFeatureIds.BODYWORK_BATTERY_METRIC, java.lang.Double.TYPE)
            if (battTemp != null) {
                val tempVal = BydDeviceHelper.getDoubleValue(battTemp)
                if (!tempVal.isNaN() && tempVal > -50 && tempVal < 80) b.bodyworkBattTempC(tempVal)
            }

            // Battery range from bodywork (feature ID 300941336, Double.TYPE → intValue)
            val battRange = BydDeviceHelper.callGet(device, BydFeatureIds.BODYWORK_BATTERY_RANGE, java.lang.Double.TYPE)
            if (battRange != null) {
                val rangeVal = BydDeviceHelper.getIntValue(battRange)
                if (rangeVal in 0..1016) b.bodyworkRangeKm(Math.round(rangeVal * distanceToKmFactorValue).toInt())
            }

            // Window open percent (positions 1-6)
            val windows = IntArray(6)
            for (i in 0 until 6) {
                val wp = BydDeviceHelper.callGetter(device, "getWindowOpenPercent", i + 1)
                windows[i] = if (wp is Number) wp.toInt() else -1
            }
            b.windowOpenPercent(windows)

            // Emergency alarm
            val alarm = BydDeviceHelper.callGet(device, BydFeatureIds.BODYWORK_EMERGENCY_ALARM, Integer::class.java)
            if (alarm != null) b.emergencyAlarmState(BydDeviceHelper.getIntValue(alarm))

        } catch (e: Exception) {
            logger.debug("collectBodywork error: " + e.message)
        }
    }

    private fun collectSpeed(b: BydVehicleData.Builder) {
        val device = speedDevice ?: return
        try {
            val speed = BydDeviceHelper.callGetter(device, "getCurrentSpeed")
            if (speed is Number) {
                val v = speed.toDouble()
                if (v != BydFeatureIds.SDK_NOT_AVAILABLE) b.speedKmh(v * distanceToKmFactorValue)
            }
            val accel = BydDeviceHelper.callGetter(device, "getAccelerateDeepness")
            if (accel is Number) b.accelPercent(accel.toInt())
            val brake = BydDeviceHelper.callGetter(device, "getBrakeDeepness")
            if (brake is Number) b.brakePercent(brake.toInt())
        } catch (e: Exception) {
            logger.debug("collectSpeed error: " + e.message)
        }
    }

    private fun collectEngine(b: BydVehicleData.Builder) {
        val device = engineDevice ?: return
        try {
            // ==================== ENGINE SPEED ====================
            // Feature ID path first — try ENGINE_SPEED (339738642), then ENGINE_SPEED_GB (282066952)
            try {
                val v = BydDeviceHelper.callGet(device, BydFeatureIds.ENGINE_SPEED, Integer::class.java)
                if (v != null) {
                    val raw = BydDeviceHelper.getIntValue(v)
                    if (raw != BydFeatureIds.BMS_UNAVAILABLE && raw != BydFeatureIds.INVALID_VALUE
                        && raw != BydFeatureIds.INVALID_VALUE_2 && raw in 0..8000) {
                        b.engineSpeedRpm(raw)
                    }
                }
                // Try alternate signal if primary didn't populate
                if (b.engineSpeedRpm == BydVehicleData.UNAVAILABLE) {
                    val altVal = BydDeviceHelper.callGet(device, BydFeatureIds.ENGINE_SPEED_ALT, Integer::class.java)
                    if (altVal != null) {
                        val altRaw = BydDeviceHelper.getIntValue(altVal)
                        if (altRaw != BydFeatureIds.BMS_UNAVAILABLE && altRaw != BydFeatureIds.INVALID_VALUE
                            && altRaw != BydFeatureIds.INVALID_VALUE_2 && altRaw in 0..8000) {
                            b.engineSpeedRpm(altRaw)
                        }
                    }
                }
            } catch (e: Exception) {
                logger.debug("collectEngine engineSpeed feature ID error: " + e.message)
            }
            // Fallback to typed getter if feature ID didn't populate
            if (b.engineSpeedRpm == BydVehicleData.UNAVAILABLE) {
                val rpm = BydDeviceHelper.callGetter(device, "getEngineSpeed")
                if (rpm is Number) {
                    val rpmVal = rpm.toInt()
                    if (rpmVal in 0..8000) b.engineSpeedRpm(rpmVal)
                }
            }

            // ==================== ENGINE POWER ====================
            // Net HV-bus power: positive = motor draw, negative = into battery (regen
            // when driving, plug-in charging when parked).
            //
            // Feature ID path returns a Double in mixed units across firmware:
            //   - On most models: kW (range roughly -200..400)
            //   - On some models: deciwatts × 10 (raw > 100 → scale ×0.1)
            // Range-check excludes sentinels (BMS_UNAVAILABLE etc.) and bogus values.
            try {
                val v = BydDeviceHelper.callGet(device, BydFeatureIds.ENGINE_POWER, java.lang.Double.TYPE)
                if (v != null) {
                    val kw = BydSignalRules.enginePowerKw(BydDeviceHelper.getDoubleValue(v))
                    if (kw != null) b.enginePowerKw(kw)
                }
            } catch (e: Exception) {
                logger.debug("collectEngine enginePower feature ID error: " + e.message)
            }
            // Fallback to typed getter if feature ID didn't populate
            if (b.enginePowerKw.isNaN()) {
                val power = BydDeviceHelper.callGetter(device, "getEnginePower")
                if (power is Number) {
                    val kw = power.toDouble()
                    if (kw >= -200.0 && kw <= 400.0) b.enginePowerKw(kw)
                }
            }

            // Front motor speed (negated)
            val fms = BydDeviceHelper.callGet(device, BydFeatureIds.ENGINE_FRONT_MOTOR_SPEED, Integer::class.java)
            if (fms != null) b.frontMotorSpeed(-BydDeviceHelper.getIntValue(fms))

            // Rear motor speed
            val rms = BydDeviceHelper.callGet(device, BydFeatureIds.ENGINE_REAR_MOTOR_SPEED, Integer::class.java)
            if (rms != null) b.rearMotorSpeed(BydDeviceHelper.getIntValue(rms))

            // Front motor torque (negated double)
            val fmt = BydDeviceHelper.callGet(device, BydFeatureIds.ENGINE_FRONT_MOTOR_TORQUE, java.lang.Double.TYPE)
            if (fmt != null) b.frontMotorTorque(-BydDeviceHelper.getDoubleValue(fmt))
        } catch (e: Exception) {
            logger.debug("collectEngine error: " + e.message)
        }
    }

    private fun collectStatistic(b: BydVehicleData.Builder) {
        val device = statisticDevice ?: return
        try {
            // ==================== TOTAL MILEAGE ====================
            // Named getter primary, feature ID fallback
            val mileage = BydDeviceHelper.callGetter(device, "getTotalMileageValue")
            if (mileage is Number) {
                val raw = mileage.toInt()
                if (raw > 0) b.totalMileageKm(Math.round(raw * distanceToKmFactorValue).toInt())
            }
            if (b.totalMileageKm == BydVehicleData.UNAVAILABLE) {
                try {
                    val v = BydDeviceHelper.callGet(device, BydFeatureIds.STAT_TOTAL_MILEAGE, Integer::class.java)
                    if (v != null) {
                        val raw = BydDeviceHelper.getIntValue(v)
                        if (raw != BydFeatureIds.BMS_UNAVAILABLE && raw != BydFeatureIds.INVALID_VALUE
                            && raw != BydFeatureIds.INVALID_VALUE_2 && raw > 0) {
                            b.totalMileageKm(Math.round(raw * distanceToKmFactorValue).toInt())
                        }
                    }
                } catch (e: Exception) {
                    logger.debug("collectStatistic totalMileage feature ID error: " + e.message)
                }
            }

            // ==================== EV MILEAGE ====================
            // Named getter primary, feature ID fallback
            val evMileage = BydDeviceHelper.callGetter(device, "getEVMileageValue")
            if (evMileage is Number) {
                val raw = evMileage.toInt()
                if (raw > 0) b.evMileageKm(Math.round(raw * distanceToKmFactorValue).toInt())
            }
            if (b.evMileageKm == BydVehicleData.UNAVAILABLE) {
                try {
                    val v = BydDeviceHelper.callGet(device, BydFeatureIds.STAT_MILEAGE_EV, Integer::class.java)
                    if (v != null) {
                        val raw = BydDeviceHelper.getIntValue(v)
                        if (raw != BydFeatureIds.BMS_UNAVAILABLE && raw != BydFeatureIds.INVALID_VALUE
                            && raw != BydFeatureIds.INVALID_VALUE_2 && raw > 0) {
                            b.evMileageKm(Math.round(raw * distanceToKmFactorValue).toInt())
                        }
                    }
                } catch (e: Exception) {
                    logger.debug("collectStatistic evMileage feature ID error: " + e.message)
                }
            }

            // ==================== SOC (ELEC PERCENTAGE) ====================
            // Named getter primary, then feature ID fallback
            val elecPct = BydDeviceHelper.callGetter(device, "getElecPercentageValue")
            if (elecPct is Number) {
                val soc = elecPct.toDouble()
                if (soc in 0.0..100.0) b.socPercent(soc)
            }
            if (b.socPercent.isNaN()) {
                try {
                    val v = BydDeviceHelper.callGet(device, BydFeatureIds.STAT_ELEC_PERCENTAGE, Integer::class.java)
                    if (v != null) {
                        val raw = BydDeviceHelper.getIntValue(v)
                        if (raw != BydFeatureIds.BMS_UNAVAILABLE && raw != BydFeatureIds.INVALID_VALUE
                            && raw != BydFeatureIds.INVALID_VALUE_2 && raw in 0..100) {
                            b.socPercent(raw.toDouble())
                        }
                    }
                } catch (e: Exception) {
                    logger.debug("collectStatistic socPercent feature ID error: " + e.message)
                }
            }

            // ==================== WATER TEMP ====================
            val waterTemp = BydDeviceHelper.callGetter(device, "getWaterTemperature")
            if (waterTemp is Number) b.waterTempC(waterTemp.toDouble())

            // Fallback: try Engine device if Statistic didn't provide coolant temp.
            // Some firmware only exposes coolant temperature via the Engine device.
            val eDevice = engineDevice
            if (b.waterTempC == BydVehicleData.UNAVAILABLE.toDouble() && eDevice != null) {
                try {
                    val coolantGetters = arrayOf(
                        "getWaterTemperature", "getCoolantTemperature",
                        "getEngineCoolantTemperature", "getEngineWaterTemperature",
                        "getEngineCoolantTemp", "getWaterTemp"
                    )
                    for (getter in coolantGetters) {
                        val engineCoolant = BydDeviceHelper.callGetter(eDevice, getter)
                        if (engineCoolant is Number) {
                            val tempC = engineCoolant.toInt()
                            if (tempC in -50..200) {
                                b.waterTempC(tempC.toDouble())
                                break
                            }
                        }
                    }
                } catch (e: Exception) {
                    logger.debug("collectStatistic coolant fallback error: " + e.message)
                }
            }

            // ==================== TOTAL ELEC CONSUMPTION ====================
            val totalElec = BydDeviceHelper.callGetter(device, "getTotalElecConValue")
            if (totalElec is Number) b.totalElecCon(totalElec.toDouble())

            // ==================== TOTAL FUEL CONSUMPTION ====================
            val totalFuel = BydDeviceHelper.callGetter(device, "getTotalFuelConValue")
            if (totalFuel is Number) b.totalFuelCon(totalFuel.toDouble())

            // ==================== ELECTRIC DRIVING RANGE ====================
            // Named getter primary, feature ID fallback
            val elecRange = BydDeviceHelper.callGetter(device, "getElecDrivingRangeValue")
            if (elecRange is Number) {
                val raw = elecRange.toInt()
                if (raw > 0) b.elecRangeKm(Math.round(raw * distanceToKmFactorValue).toInt())
            }
            if (b.elecRangeKm == BydVehicleData.UNAVAILABLE) {
                try {
                    val v = BydDeviceHelper.callGet(device, BydFeatureIds.STAT_ELEC_DRIVING_RANGE, Integer::class.java)
                    if (v != null) {
                        val raw = BydDeviceHelper.getIntValue(v)
                        if (raw != BydFeatureIds.BMS_UNAVAILABLE && raw != BydFeatureIds.INVALID_VALUE
                            && raw != BydFeatureIds.INVALID_VALUE_2 && raw > 0) {
                            b.elecRangeKm(Math.round(raw * distanceToKmFactorValue).toInt())
                        }
                    }
                } catch (e: Exception) {
                    logger.debug("collectStatistic elecRange feature ID error: " + e.message)
                }
            }

            // ==================== FUEL PERCENTAGE & FUEL RANGE (PHEV only) ====================
            // BEVs return bogus CAN bus values for fuel (e.g. constant 62% on a Seal).
            val isPhevFlag = isPhev(b)

            // ==================== FUEL DRIVING RANGE (PHEV only) ====================
            if (isPhevFlag) {
                // Named getter primary, feature ID fallback
                val fuelRange = BydDeviceHelper.callGetter(device, "getFuelDrivingRangeValue")
                if (fuelRange is Number) {
                    val raw = fuelRange.toInt()
                    if (raw > 0) b.fuelRangeKm(Math.round(raw * distanceToKmFactorValue).toInt())
                }
                if (b.fuelRangeKm == BydVehicleData.UNAVAILABLE) {
                    try {
                        val v = BydDeviceHelper.callGet(device, BydFeatureIds.STAT_FUEL_DRIVING_RANGE, Integer::class.java)
                        if (v != null) {
                            val raw = BydDeviceHelper.getIntValue(v)
                            if (raw != BydFeatureIds.BMS_UNAVAILABLE && raw != BydFeatureIds.INVALID_VALUE
                                && raw != BydFeatureIds.INVALID_VALUE_2 && raw > 0) {
                                b.fuelRangeKm(Math.round(raw * distanceToKmFactorValue).toInt())
                            }
                        }
                    } catch (e: Exception) {
                        logger.debug("collectStatistic fuelRange feature ID error: " + e.message)
                    }
                }
            }

            // ==================== FUEL PERCENTAGE (PHEV only) ====================
            if (isPhevFlag) {
                // Named getter primary
                val fuelPct = BydDeviceHelper.callGetter(device, "getFuelPercentageValue")
                if (fuelPct is Number) {
                    val pct = fuelPct.toInt()
                    if (pct in 1..100) {
                        b.fuelPercent(pct.toDouble())
                    }
                }
                // Feature ID fallback
                if (b.fuelPercent.isNaN()) {
                    try {
                        val v = BydDeviceHelper.callGet(device, BydFeatureIds.STAT_FUEL_PERCENTAGE, Integer::class.java)
                        if (v != null) {
                            val raw = BydDeviceHelper.getIntValue(v)
                            if (raw != BydFeatureIds.BMS_UNAVAILABLE && raw != BydFeatureIds.INVALID_VALUE
                                && raw != BydFeatureIds.INVALID_VALUE_2 && raw > 0 && raw <= 100) {
                                b.fuelPercent(raw.toDouble())
                            }
                        }
                    } catch (e: Exception) {
                        logger.debug("Fuel percentage feature ID failed: " + e.message)
                    }
                }
            }

            // Battery temps via get() — intValue - 40 = °C
            collectStatTemp(b, BydFeatureIds.STAT_HIGHEST_BATTERY_TEMP, "high")
            collectStatTemp(b, BydFeatureIds.STAT_LOWEST_BATTERY_TEMP, "low")
            collectStatTemp(b, BydFeatureIds.STAT_AVERAGE_BATTERY_TEMP, "avg")

            // Cell voltages via get() — intValue / 1000.0 = V
            collectStatVoltage(b, BydFeatureIds.STAT_HIGHEST_BATTERY_VOLTAGE, "high")
            collectStatVoltage(b, BydFeatureIds.STAT_LOWEST_BATTERY_VOLTAGE, "low")
        } catch (e: Exception) {
            logger.debug("collectStatistic error: " + e.message)
        }
    }

    private fun collectStatTemp(b: BydVehicleData.Builder, featureId: Int, which: String) {
        var v = BydDeviceHelper.callGet(statisticDevice, featureId, Integer.TYPE)
        if (v == null) v = BydDeviceHelper.callGet(statisticDevice, featureId, Integer::class.java)
        if (v == null) return
        val temp = BydSignalRules.cellTempC(BydDeviceHelper.getIntValue(v)) ?: return
        val tempC = temp
        when (which) {
            "high" -> b.highCellTempC(tempC)
            "low" -> b.lowCellTempC(tempC)
            "avg" -> b.avgCellTempC(tempC)
        }
    }

    private fun collectStatVoltage(b: BydVehicleData.Builder, featureId: Int, which: String) {
        var v = BydDeviceHelper.callGet(statisticDevice, featureId, Integer.TYPE)
        if (v == null) v = BydDeviceHelper.callGet(statisticDevice, featureId, Integer::class.java)
        if (v == null) return
        val volts = BydSignalRules.cellVoltage(BydDeviceHelper.getIntValue(v)) ?: return
        when (which) {
            "high" -> b.highCellVoltage(volts)
            "low" -> b.lowCellVoltage(volts)
        }
    }

    private fun collectCharging(b: BydVehicleData.Builder) {
        val device = chargingDevice ?: return
        try {
            // Named getters for init read
            val gunState = BydDeviceHelper.callGetter(device, "getChargingGunState")
            if (gunState is Number) b.chargingGunState(gunState.toInt())

            val charger = BydDeviceHelper.callGetter(device, "getChargerWorkState")
            if (charger is Number) b.chargerWorkState(charger.toInt())

            // BYDAutoPowerDevice.isCharging() — independent ground truth from
            // the power MCU. Used by ChargingDetector as the L2 cross-check
            // that catches the PHEV "BMS stuck at 15 IDLE while charging" bug.
            // Tri-state: null when the device is unavailable or the call fails.
            var powerIsCharging: Boolean? = null
            val pDevice = powerDevice
            if (pDevice != null) {
                try {
                    val pic = BydDeviceHelper.callGetter(pDevice, "isCharging")
                    if (pic is Boolean) {
                        powerIsCharging = pic
                    } else if (pic is Number) {
                        powerIsCharging = pic.toInt() != 0
                    }
                } catch (e: Exception) {
                    logger.debug("collectCharging Power.isCharging error: " + e.message)
                }
            }
            net.bladewatch.app.monitor.ChargingDetector.getInstance()
                .updatePowerIsCharging(powerIsCharging)

            // Feature ID for battery device state, fallback to named getter
            try {
                val v = BydDeviceHelper.callGet(device, BydFeatureIds.CHARGING_BATTERY_DEVICE_STATE, Integer::class.java)
                if (v != null) {
                    val raw = BydDeviceHelper.getIntValue(v)
                    if (raw != BydFeatureIds.BMS_UNAVAILABLE && raw != BydFeatureIds.INVALID_VALUE
                        && raw != BydFeatureIds.INVALID_VALUE_2 && raw >= 0) {
                        b.chargingState(raw)
                    }
                }
            } catch (e: Exception) {
                logger.debug("collectCharging batteryState feature ID error: " + e.message)
            }
            if (b.chargingState == BydVehicleData.UNAVAILABLE) {
                val battState = BydDeviceHelper.callGetter(device, "getBatteryManagementDeviceState")
                if (battState is Number) {
                    b.chargingState(battState.toInt())
                }
            }

            // Charging power from the BYD ChargingDevice SDK getter.
            // Sentinel filter: SDK reports up to ±500 kW; reject anything beyond.
            // Listener callbacks (onChargingPowerChanged) keep this fresh between polls.
            val power = BydDeviceHelper.callGetter(device, "getChargingPower")
            if (power is Number) {
                val kw = power.toDouble()
                if (Math.abs(kw) > 0.01 && Math.abs(kw) < 500) {
                    b.chargingPowerKw(kw)
                }
            }

            // Targeted clear: when the BMS reports an EXPLICIT non-charging
            // terminal state (READY=0, FINISHED=2, TERMINATED=4, DISCHARG_FINISH=12),
            // we know the previous charging session is over. Clear sticky listener-
            // delivered power so the inference layer in VehicleDataMonitor can't
            // false-trigger from leftover values. We do NOT clear on IDLE (15)
            // because that's the buggy reading some PHEV firmwares give while
            // actually charging — clearing there would break detection again.
            // We do NOT clear on disconnect-only signals (gunState==1) without a
            // BMS state agreeing, because PHEVs often leave gunState UNAVAILABLE.
            if (BydSignalRules.isTerminalChargingState(b.chargingState)) {
                b.chargingPowerKw(Double.NaN)
                b.externalChargingPowerKw(Double.NaN)
            }

            // Charging mode — getChargingMode() raw value (AC vs DC vs wireless, model-specific).
            // Stored on the snapshot; logged once on first sight then throttled at 5min.
            val mode = BydDeviceHelper.callGetter(device, "getChargingMode")
            if (mode is Number) {
                val rawMode = mode.toInt()
                // Filter sentinels (BMS_UNAVAILABLE=65535, INVALID values)
                if (rawMode in 0..99) {
                    b.chargingMode(rawMode)
                    val now = System.currentTimeMillis()
                    if (now - lastChargingModeLogMs > 300_000) {
                        lastChargingModeLogMs = now
                        logger.info("getChargingMode=$rawMode")
                    }
                }
            }

            // SDK getChargingState() — distinct from getBatteryManagementDeviceState() above.
            // Diagnostic only for now: log to verify the value space against our existing
            // chargingState (which may come from a different source).
            val chState = BydDeviceHelper.callGetter(device, "getChargingState")
            if (chState is Number) {
                val rawState = chState.toInt()
                if (rawState in 0..99) {
                    val now = System.currentTimeMillis()
                    if (now - lastChargingStateRawLogMs > 300_000) {
                        lastChargingStateRawLogMs = now
                        logger.debug("getChargingState=" + rawState + " (collector chargingState=" + b.chargingState + ")")
                    }
                }
            }

            // Charging type (0=DEFAULT, 3=VTOG)
            val type = BydDeviceHelper.callGetter(device, "getChargingType")
            if (type is Number) b.chargingType(type.toInt())

            // VTOL detection — gunState==5 OR chargingType==3
            b.vtolCharging(BydSignalRules.isVtolCharging(b.chargingGunState, b.chargingType))

            // Charging capacity (kWh)
            val cap = BydDeviceHelper.callGetter(device, "getChargingCapacity")
            if (cap is Number) {
                val capKwh = cap.toDouble()
                if (capKwh > 0) b.chargingCapacityKwh(capKwh)
            }

            // Charging percent from chargingDevice
            val pct = BydDeviceHelper.callGetter(device, "getChargingPercent")
            if (pct is Number) {
                val chgPct = pct.toInt()
                if (chgPct in 0..100) b.chargingPercent(chgPct)
            }

            // Charger work state via feature ID fallback
            if (b.chargerWorkState == BydVehicleData.UNAVAILABLE) {
                try {
                    val v = BydDeviceHelper.callGet(device, BydFeatureIds.CHARGING_CHARGER_WORK_STATE, Integer::class.java)
                    if (v != null) {
                        val raw = BydDeviceHelper.getIntValue(v)
                        if (raw != BydFeatureIds.BMS_UNAVAILABLE && raw != BydFeatureIds.INVALID_VALUE
                            && raw != BydFeatureIds.INVALID_VALUE_2 && raw >= 0) {
                            b.chargerWorkState(raw)
                        }
                    }
                } catch (e: Exception) {
                    logger.debug("collectCharging chargerWorkState feature ID error: " + e.message)
                }
            }

            // Wireless charging states via feature IDs
            try {
                val wlLeft = BydDeviceHelper.callGet(device, BydFeatureIds.CHARGING_WIRELESS_LEFT_STATE, Integer::class.java)
                if (wlLeft != null) {
                    val raw = BydDeviceHelper.getIntValue(wlLeft)
                    if (raw != BydFeatureIds.BMS_UNAVAILABLE && raw != BydFeatureIds.INVALID_VALUE) {
                        b.wirelessChargingLeftState(raw)
                    }
                }
            } catch (e: Exception) {
                logger.debug("collectCharging wirelessLeft error: " + e.message)
            }
            try {
                val wlRight = BydDeviceHelper.callGet(device, BydFeatureIds.CHARGING_WIRELESS_RIGHT_STATE, Integer::class.java)
                if (wlRight != null) {
                    val raw = BydDeviceHelper.getIntValue(wlRight)
                    if (raw != BydFeatureIds.BMS_UNAVAILABLE && raw != BydFeatureIds.INVALID_VALUE) {
                        b.wirelessChargingRightState(raw)
                    }
                }
            } catch (e: Exception) {
                logger.debug("collectCharging wirelessRight error: " + e.message)
            }
            try {
                val wlState = BydDeviceHelper.callGet(device, BydFeatureIds.CHARGING_WIRELESS_STATE, Integer::class.java)
                if (wlState != null) {
                    val raw = BydDeviceHelper.getIntValue(wlState)
                    if (raw != BydFeatureIds.BMS_UNAVAILABLE && raw != BydFeatureIds.INVALID_VALUE) {
                        b.wirelessChargingStatus(raw)
                    }
                }
            } catch (e: Exception) {
                logger.debug("collectCharging wirelessState error: " + e.message)
            }
        } catch (e: Exception) {
            logger.debug("collectCharging error: " + e.message)
        }
    }

    private fun collectInstrument(b: BydVehicleData.Builder) {
        val device = instrumentDevice ?: return
        try {
            // Named getter for outside temperature
            val extTemp = BydDeviceHelper.callGetter(device, "getOutCarTemperature")
            if (extTemp is Number) {
                val t = extTemp.toInt()
                if (t in -50..60) b.outsideTempC(t.toDouble())
            }

            // External charging power. Two scaling regimes seen across BYD firmware:
            //
            //   - Listener path (onExternalChargingPowerChanged) — SDK pre-scales
            //     to kW. This matches BYDCarController in autocommander, which
            //     treats the listener arg as kW directly.
            //   - Polled getter — some firmware (Seal U DM-i PHEV, build 1124xxx)
            //     returns the raw CAN value in hectowatts (centiKW). Observed:
            //     221.7 raw for a real ~1.9 kW charger (221.7/100 = 2.217 kW,
            //     which is the wall-side handshake before AC→DC conversion loss).
            //     Same firmware family is the one that has the feature ID
            //     fallback below also delivering hectowatts (189.5 raw → 1.8 kW
            //     charger, per the comment on that path).
            //
            // Heuristic: kW values are bounded by physical reality (AC charging
            // tops at ~22 kW 3-phase, PHEV onboard charger maxes at 7 kW).
            // Anything above 50 from a getter that's supposed to be kW is the
            // hectowatt scale — divide. Below 50, trust the value as-is.
            // The 104857.5 BYD sentinel falls cleanly above the 50000 cap.
            val extPower = BydDeviceHelper.callGetter(device, "getExternalChargingPower")
            if (extPower is Number) {
                val raw = extPower.toDouble()
                val kw = BydSignalRules.externalChargingPowerKw(raw)
                if (kw != null) {
                    b.externalChargingPowerKw(kw)
                    if (!loggedExtChargePowerScale) {
                        loggedExtChargePowerScale = true
                        logger.info("getExternalChargingPower: raw=" + raw + " → " + kw
                                + " kW (scale=" + (if (BydSignalRules.isHectowattScale(raw)) "hectowatts/100" else "kW")
                                + "). Cross-check against the cluster's charging readout to confirm.")
                    }
                }
            }

            // Feature ID fallback (842006552). Returns raw CAN value in hectowatts
            // (value/100 = kW); evidence: 1.8 kW charger reports 189.5 raw.
            // Used only when the typed getter above returned nothing useful.
            if (b.externalChargingPowerKw.isNaN()
                    && (b.chargingPowerKw.isNaN() || b.chargingPowerKw == 0.0)) {
                try {
                    val v = BydDeviceHelper.callGet(device,
                            BydFeatureIds.INSTRUMENT_CHARGING_CHARGE_POWER_DD, java.lang.Double.TYPE)
                    if (v != null) {
                        val raw = BydDeviceHelper.getDoubleValue(v)
                        if (!raw.isNaN() && Math.abs(raw) > 1.0 && Math.abs(raw) < 35000) {
                            // Convert from hectowatts to kW
                            val kw = raw / 100.0
                            b.chargingPowerKw(kw)
                        }
                    }
                } catch (e: Exception) {
                    logger.debug("collectInstrument chargingPower feature ID error: " + e.message)
                }
            }

            // Charging percent via instrument feature ID (842006544) — read
            // unconditionally as fallback when the chargingDevice path didn't
            // populate it. Gating on a BMS-derived "may be charging" flag here
            // creates the same circular dependency we removed from the power
            // reads above; the safe-clear in collectCharging() wipes stale
            // values when the vehicle is genuinely idle (BMS not charging AND
            // gun disconnected).
            if (b.chargingPercent == BydVehicleData.UNAVAILABLE) {
                try {
                    val v = BydDeviceHelper.callGet(device,
                            BydFeatureIds.INSTRUMENT_CHARGING_CHARGE_PERCENT_DD, Integer::class.java)
                    if (v != null) {
                        val raw = BydDeviceHelper.getIntValue(v)
                        if (raw in 0..100) {
                            b.chargingPercent(raw)
                        }
                    }
                } catch (e: Exception) {
                    logger.debug("collectInstrument chargingPercent feature ID error: " + e.message)
                }
            }

            // Charging rest time via instrument feature IDs (primary path)
            // Fallback to chargingDevice.getChargingRestTime() is in collectChargingExtended()
            // Validates: 255 = not available, hours 0-23, minutes 0-59
            try {
                val hourVal = BydDeviceHelper.callGet(device,
                        BydFeatureIds.INSTRUMENT_CHARGING_CHARGE_REST_HOUR_DD, Integer::class.java)
                val minVal = BydDeviceHelper.callGet(device,
                        BydFeatureIds.INSTRUMENT_CHARGING_CHARGE_REST_MINUTE_DD, Integer::class.java)
                if (hourVal != null && minVal != null) {
                    val hours = BydDeviceHelper.getIntValue(hourVal)
                    val minutes = BydDeviceHelper.getIntValue(minVal)
                    if (hours != 255 && minutes != 255 && hours in 0..23 && minutes in 0..59) {
                        b.chargingRestTimeHours(hours)
                        b.chargingRestTimeMinutes(minutes)
                    }
                }
            } catch (e: Exception) {
                logger.debug("collectInstrument chargingRestTime feature ID error: " + e.message)
            }
        } catch (e: Exception) {
            logger.debug("collectInstrument error: " + e.message)
        }
    }

    private fun collectOta(b: BydVehicleData.Builder) {
        val device = otaDevice ?: return
        try {
            val voltage = BydDeviceHelper.callGetter(device, "getBatteryPowerVoltage")
            if (voltage is Number) {
                val v = voltage.toDouble()
                if (v > 0 && v < 20) b.voltage12v(v)
            }
        } catch (e: Exception) {
            logger.debug("collectOta error: " + e.message)
        }
    }

    private fun collectGearbox(b: BydVehicleData.Builder) {
        val device = gearboxDevice ?: return
        try {
            val gear = BydDeviceHelper.callGetter(device, "getGearboxAutoModeType")
            if (gear is Number) b.gearMode(gear.toInt())
        } catch (e: Exception) {
            logger.debug("collectGearbox error: " + e.message)
        }
    }

    private fun collectAc(b: BydVehicleData.Builder) {
        val device = acDevice ?: return
        try {
            val acState = BydDeviceHelper.callGetter(device, "getAcStartState")
            if (acState is Number) b.acStartState(acState.toInt())
            val cycle = BydDeviceHelper.callGetter(device, "getAcCycleMode")
            if (cycle is Number) b.acCycleMode(cycle.toInt())
            val wind = BydDeviceHelper.callGetter(device, "getAcWindMode")
            if (wind is Number) b.acWindMode(wind.toInt())
            val fanLevel = BydDeviceHelper.callGetter(device, "getAcWindLevel")
            if (fanLevel is Number) {
                val level = fanLevel.toInt()
                if (level in 0..7) b.acFanLevel(level)
            }
            val unit = BydDeviceHelper.callGetter(device, "getTemperatureUnit")
            if (unit is Number) b.tempUnit(unit.toInt())
            // Cabin temperature. Position 4, NOT 1 — 1/2/3 are the per-zone setpoints, which
            // is what this used to read (BladeWatch-gkjl). See AC_TEMP_POS_CABIN.
            val insideTemp = BydDeviceHelper.callGetter(device, "getTemprature", AC_TEMP_POS_CABIN)
            if (insideTemp is Number) {
                val t = insideTemp.toInt()
                if (t in CABIN_TEMP_RANGE_C) b.insideTempC(t.toDouble())
            }
        } catch (e: Exception) {
            logger.debug("collectAc error: " + e.message)
        }
    }

    private fun collectLight(b: BydVehicleData.Builder) {
        val device = lightDevice ?: return
        try {
            val left = BydDeviceHelper.callGetter(device, "getTurnLightState", 1)
            if (left is Number) b.leftTurnState(left.toInt())
            val right = BydDeviceHelper.callGetter(device, "getTurnLightState", 2)
            if (right is Number) b.rightTurnState(right.toInt())
            // Light status: 1=low, 2=high, 3=position, 6=rearFog, 7=frontFog, 8=hazard
            b.lowBeam(getLightStatus(1) == 1)
            b.highBeam(getLightStatus(2) == 1)
            b.rearFog(getLightStatus(6) == 1)
            b.frontFog(getLightStatus(7) == 1)
            b.hazard(getLightStatus(8) == 1)
            val dayTime = BydDeviceHelper.callGetter(device, "getDayTimeLightState")
            if (dayTime is Number) b.dayTimeLight(dayTime.toInt() == 1)
        } catch (e: Exception) {
            logger.debug("collectLight error: " + e.message)
        }
    }

    private fun getLightStatus(position: Int): Int {
        val v = BydDeviceHelper.callGetter(lightDevice, "getLightStatus", position)
        return if (v is Number) v.toInt() else 0
    }

    private fun collectAdas(b: BydVehicleData.Builder) {
        val device = adasDeviceValue ?: return
        try {
            val speedLimitWarning = BydDeviceHelper.callGetSingle(device, BydFeatureIds.ADAS_SLW_FUNC_SWITCH_STATE)
            if (speedLimitWarning >= 0) {
                b.speedLimitWarning(speedLimitWarning == 2)
            }
        } catch (e: Exception) {
            logger.debug("collectAdas error: " + e.message)
        }
    }

    private fun collectSettings(b: BydVehicleData.Builder) {
        settingDevice ?: return
        try {
            val seatHeat = intArrayOf(-1, -1)
            val seatCool = intArrayOf(-1, -1)
            // SDK returns 1=off, 2=low, 3=high — normalize to 0/1/2 for the wire format.
            // On unsupported firmwares the getter returns null/throws → leave entry unknown (-1).
            for (i in 0 until 2) {
                seatHeat[i] = normalizeSeatGetterLevel(readSeatGetterRaw("getSeatHeatingState", i + 1))
                seatCool[i] = normalizeSeatGetterLevel(readSeatGetterRaw("getSeatVentilatingState", i + 1))
            }
            b.seatHeat(seatHeat).seatCool(seatCool)
        } catch (e: Exception) {
            logger.debug("collectSettings error: " + e.message)
        }
    }

    private fun collectPower(b: BydVehicleData.Builder) {
        val device = powerDevice ?: return
        try {
            // BYDAutoPowerDevice is a singleton that may have been initialized by another daemon
            // with a null/stale context. Force-update the internal context before calling methods.
            ensureDeviceContext(device)

            val mcu = BydDeviceHelper.callGetter(device, "getMcuStatus")
            if (mcu is Number) b.mcuStatus(mcu.toInt())
            // NOTE: getBatteryRemainPowerEV() intentionally NOT called here.
            // On PHEVs (Sealion 6 DM-i), the PowerDevice EV subsystem returns stale kWh
            // values when the ICE is running. We rely on Statistic/Bodywork paths for
            // remaining kWh on both BEVs and PHEVs.
        } catch (e: Exception) {
            logger.debug("collectPower error: " + e.message)
        }
    }

    /**
     * Force-update a BYD device singleton's internal context field.
     * BYD singletons store context from the first getInstance() call.
     * If another daemon initialized it first with a null/stale context, methods NPE.
     */
    private fun ensureDeviceContext(device: Any?) {
        if (device == null || context == null) return
        try {
            // Walk up to AbsBYDAutoDevice and set mContext
            var cls: Class<*>? = device.javaClass
            while (cls != null && cls != Any::class.java) {
                try {
                    val contextField = cls.getDeclaredField("mContext")
                    contextField.isAccessible = true
                    val currentCtx = contextField.get(device)
                    if (currentCtx == null) {
                        contextField.set(device, context)
                        logger.info("Fixed null context on " + device.javaClass.simpleName)
                    }
                    return
                } catch (e: NoSuchFieldException) {
                    cls = cls.superclass
                }
            }
        } catch (e: Exception) {
            logger.debug("ensureDeviceContext failed: " + e.message)
        }
    }

    /**
     * PHEV detection. getEnergyType is unreliable — observed returning 1 on
     * both BEV and PHEV firmwares, so we cannot trust it as the discriminator.
     * Primary signal: live fuel HAL values. If both getFuelPercentageValue
     * and getFuelDrivingRangeValue return BMS-unavailable sentinels, the
     * vehicle has no fuel system → BEV. Otherwise (real fuel readings, OR
     * we haven't been able to probe yet) treat as PHEV/HEV.
     *
     * Cached after first successful probe to avoid hammering reflection.
     */
    @Volatile private var cachedDrivetrain = 0  // 0=unknown, 1=BEV, 2=PHEV/HEV
    @Volatile private var lastDrivetrainProbeMs = 0L

    private fun isPhev(b: BydVehicleData.Builder): Boolean = computeIsPhev()

    private fun isPhev(snapshot: BydVehicleData): Boolean = computeIsPhev()

    private fun computeIsPhev(): Boolean {
        val now = System.currentTimeMillis()
        if (cachedDrivetrain != 0 && (now - lastDrivetrainProbeMs) < DRIVETRAIN_REPROBE_MS) {
            return cachedDrivetrain == 2
        }
        var fuelPctSentinel = false
        var fuelRangeSentinel = false
        var fuelPctReal = false
        var fuelRangeReal = false
        val device = statisticDevice
        if (device != null) {
            try {
                val fp = BydDeviceHelper.callGetter(device, "getFuelPercentageValue")
                if (fp is Number) {
                    val v = fp.toInt()
                    if (isBevFuelSentinel(v)) fuelPctSentinel = true
                    // 0 is intentionally NOT counted as "real" — a BEV that
                    // happens to return 0 instead of a sentinel would falsely
                    // classify as PHEV. PHEVs with truly empty tanks will be
                    // caught by fuelRangeReal once driven, or by the capacity
                    // fallback in the meantime.
                    else if (v in 1..100) fuelPctReal = true
                }
            } catch (e: Exception) {
                logger.debug("computeIsPhev fuelPct probe error: " + e.message)
            }
            try {
                val fr = BydDeviceHelper.callGetter(device, "getFuelDrivingRangeValue")
                if (fr is Number) {
                    val v = fr.toInt()
                    if (isBevFuelSentinel(v)) fuelRangeSentinel = true
                    else if (v in 1..1499) fuelRangeReal = true
                }
            } catch (e: Exception) {
                logger.debug("computeIsPhev fuelRange probe error: " + e.message)
            }
        }
        // The decision itself, including the capacity gate that runs ahead of the probes
        // above. See decideDrivetrain for why the order matters.
        val verdict = decideDrivetrain(knownNominalKwh(),
                fuelPctReal, fuelRangeReal, fuelPctSentinel, fuelRangeSentinel)

        return when (verdict) {
            DRIVETRAIN_PHEV -> {
                cachedDrivetrain = 2
                lastDrivetrainProbeMs = now
                true
            }
            DRIVETRAIN_BEV -> {
                cachedDrivetrain = 1
                lastDrivetrainProbeMs = now
                false
            }
            DRIVETRAIN_PHEV_PROVISIONAL -> {
                // Cache as PHEV with a SHORTER TTL so a transient HAL miss self-heals
                // quickly. Without any cache, every isPhev() call re-runs both reflection
                // probes — onFuelPercentageChanged fires at HAL rate.
                cachedDrivetrain = 2
                // 5s TTL via the lastDrivetrainProbeMs offset trick: pretend the probe
                // happened (DRIVETRAIN_REPROBE_MS - 5000) ms ago, so the next call in >5s
                // re-probes.
                lastDrivetrainProbeMs = now - (DRIVETRAIN_REPROBE_MS - 5_000)
                true
            }
            else ->
                // Unknown — do NOT cache. Default to non-BEV.
                false
        }
    }

    /**
     * Known nominal pack capacity, or 0 when unavailable. Best-effort: this reaches another
     * subsystem, and a drivetrain probe must never propagate its failure.
     */
    private fun knownNominalKwh(): Double {
        return try {
            net.bladewatch.app.monitor.VehicleDataMonitor.getInstance().getNominalCapacityKwh()
        } catch (t: Throwable) {
            logger.debug("computeIsPhev capacity probe unavailable: " + t.message)
            0.0
        }
    }

    private fun isBevFuelSentinel(v: Int): Boolean = BydSignalRules.isBevFuelSentinel(v)

    private fun collectSafetyBelt(b: BydVehicleData.Builder) {
        val device = safetyBeltDevice ?: return
        try {
            val belts = IntArray(5)
            for (i in 0 until 5) {
                val s = BydDeviceHelper.callGetter(device, "getSafetyBeltStatus", i + 1)
                belts[i] = if (s is Number) s.toInt() else -1
            }
            b.seatbeltStatus(belts)
        } catch (e: Exception) {
            logger.debug("collectSafetyBelt error: " + e.message)
        }
    }

    private fun collectTyre(b: BydVehicleData.Builder) {
        val device = tyreDevice ?: return
        try {
            // Pressure value (kPa, raw int — confirmed by BYD-DiLink commander app's
            // UnitFormatter.formatPressure(): no scaling for kPa, *0.1450377 for psi,
            // /100 for bar). Areas: 1=FL, 2=FR, 3=RL, 4=RR.
            val pressures = IntArray(4)
            val pressureStates = IntArray(4)
            val airLeakStates = IntArray(4)
            val signalStates = IntArray(4)
            for (i in 0 until 4) {
                val p = BydDeviceHelper.callGetter(device, "getTyrePressureValue", i + 1)
                pressures[i] = if (p is Number) p.toInt() else -1
                val s = BydDeviceHelper.callGetter(device, "getTyrePressureState", i + 1)
                pressureStates[i] = if (s is Number) s.toInt() else -1
                val leak = BydDeviceHelper.callGetter(device, "getTyreAirLeakState", i + 1)
                airLeakStates[i] = if (leak is Number) leak.toInt() else -1
                val sig = BydDeviceHelper.callGetter(device, "getTyreSignalState", i + 1)
                signalStates[i] = if (sig is Number) sig.toInt() else -1

                // Poll per-wheel temperature via the matching SDK getter.
                // The async onTyreBatteryValueChanged callback is dormant on
                // some firmwares (PHEV models on this fleet, confirmed by
                // log capture), but a small subset of those firmwares still
                // answer getTyreBatteryValue(area) with the same temperature
                // value the cluster reads. callGetter is null-safe so this
                // is a no-op on firmwares that don't expose the getter.
                pollPerWheelTyreTemp(i)
            }
            b.tyrePressure(pressures)
            b.tyrePressureState(pressureStates)
            b.tyreAirLeakState(airLeakStates)
            b.tyreSignalState(signalStates)
            b.tyreTemperature(snapshotTyreTemperatures())

            val sys = BydDeviceHelper.callGetter(device, "getTyreSystemState")
            if (sys is Number) b.tyreSystemState(sys.toInt())
            val temp = BydDeviceHelper.callGetter(device, "getTyreTemperatureState")
            if (temp is Number) b.tyreTemperatureState(temp.toInt())

            // Per-tyre temperature has three possible channels:
            //   1. Async listener: AbsBYDAutoTyreListener.onTyreBatteryValueChanged
            //      — fires on BEV firmware when registered via the two-arg
            //      registerListener(listener, int[]) overload. Dormant on some
            //      PHEV firmware with single-arg registration only.
            //   2. Polled getter: pollPerWheelTyreTemp() above tries
            //      getTyreBatteryValue / getTyreTemperatureValue /
            //      getTyreTemperature / getTyreTemperatureState.
            //   3. InstrumentDevice feature IDs: polled in
            //      collectInstrumentExtended() using the LF/RF/LB/RB
            //      tyre temperature feature IDs from BydFeatureIds.
            // If all three channels stay silent, tyre temperature is not
            // available on this firmware via any known SDK path.

            logTyreAlertsIfChanged(pressures, pressureStates, airLeakStates, signalStates,
                    if (sys is Number) sys.toInt() else Int.MIN_VALUE,
                    if (temp is Number) temp.toInt() else Int.MIN_VALUE)
        } catch (e: Exception) {
            logger.debug("collectTyre error: " + e.message)
        }
    }

    // Last-seen tyre alert state — change-only logging so a developing slow leak
    // surfaces at info, but a healthy car doesn't spam the log every poll.
    @Volatile private var lastTyrePressuresKpa: IntArray? = null
    @Volatile private var lastTyrePressureStates: IntArray? = null
    @Volatile private var lastTyreAirLeakStates: IntArray? = null
    @Volatile private var lastTyreSignalStates: IntArray? = null
    @Volatile private var lastTyreSystemState = Int.MIN_VALUE
    @Volatile private var lastTyreTemperatureState = Int.MIN_VALUE

    private val tyreTemperatureCache = intArrayOf(
        BydVehicleData.UNAVAILABLE, BydVehicleData.UNAVAILABLE,
        BydVehicleData.UNAVAILABLE, BydVehicleData.UNAVAILABLE
    )
    @Volatile private var loggedTyreSlot0 = false
    @Volatile private var loggedInstrumentTyreTemp = false
    // Per-wheel one-shot log. We surface the FIRST onTyreBatteryValueChanged
    // arrival for each wheel at info level so it's obvious from a single log
    // pull whether the BYD HAL is delivering temperature events at all on
    // this vehicle. Without this, a silent firmware looks identical to a
    // working firmware where we just haven't received an event yet.
    private val loggedTyreFirstEvent = booleanArrayOf(false, false, false, false)
    @Volatile private var loggedTyreOutOfRange = false

    private fun logTyreAlertsIfChanged(pressuresKpa: IntArray, pressureStates: IntArray,
                                        airLeakStates: IntArray, signalStates: IntArray,
                                        sysState: Int, tempState: Int) {
        // Pressures fluctuate constantly (heat, drive cycle). Only treat as
        // "changed" if any wheel moves more than 5 kPa; otherwise the log
        // would fire every poll on a moving car.
        val prevPressures = lastTyrePressuresKpa
        var pressureChanged = prevPressures == null
        if (!pressureChanged && prevPressures != null) {
            for (i in pressuresKpa.indices) {
                if (Math.abs(pressuresKpa[i] - prevPressures[i]) > 5) {
                    pressureChanged = true
                    break
                }
            }
        }
        val alertChanged =
                !pressureStates.contentEquals(lastTyrePressureStates)
                || !airLeakStates.contentEquals(lastTyreAirLeakStates)
                || !signalStates.contentEquals(lastTyreSignalStates)
                || sysState != lastTyreSystemState
                || tempState != lastTyreTemperatureState
        if (!pressureChanged && !alertChanged) return

        // Notification emit on TPMS state transitions. We only fire on
        // 0 (NORMAL) -> non-zero edges so a stuck-non-zero alarm doesn't
        // re-notify on every poll. The TPMS firmware itself is the source
        // of truth — we don't threshold kPa ourselves (matches the cluster's
        // own private-binder calibration).
        val prevPressureStates = lastTyrePressureStates
        val prevAirLeakStates = lastTyreAirLeakStates
        if (prevPressureStates != null && prevAirLeakStates != null) {
            val wheelLabels = arrayOf("Front-left", "Front-right", "Rear-left", "Rear-right")
            for (i in 0 until 4) {
                if (i >= pressureStates.size) break
                val prevP = prevPressureStates[i]
                val curP = pressureStates[i]
                if (prevP == 0 && curP != 0) {
                    try {
                        val data = org.json.JSONObject()
                        data.put("wheel", i)
                        data.put("kPa", pressuresKpa[i])
                        data.put("state", curP)
                        net.bladewatch.app.notifications.NotificationBus.get().publish(
                                net.bladewatch.app.notifications.NotificationEvent(
                                        "vehicle.health.tyre.pressure",
                                        net.bladewatch.app.notifications.NotificationEvent.Severity.WARN,
                                        if (curP == 1) "Underpressure" else "Overpressure",
                                        wheelLabels[i] + " — " + pressuresKpa[i] + " kPa",
                                        "tyre-pressure-$i",
                                        null,
                                        data))
                    } catch (t: Throwable) {
                        logger.debug("tyre.pressure notify failed: " + t.message)
                    }
                }

                val prevL = prevAirLeakStates[i]
                val curL = airLeakStates[i]
                if (prevL == 0 && curL != 0) {
                    try {
                        val data = org.json.JSONObject()
                        data.put("wheel", i)
                        data.put("leakState", curL)
                        data.put("kPa", pressuresKpa[i])
                        val sev = if (curL == 2)
                                net.bladewatch.app.notifications.NotificationEvent.Severity.CRITICAL
                            else
                                net.bladewatch.app.notifications.NotificationEvent.Severity.WARN
                        net.bladewatch.app.notifications.NotificationBus.get().publish(
                                net.bladewatch.app.notifications.NotificationEvent(
                                        "vehicle.health.tyre.leak",
                                        sev,
                                        if (curL == 2) "Fast leak detected" else "Slow leak detected",
                                        wheelLabels[i] + " (" + pressuresKpa[i] + " kPa)",
                                        "tyre-leak-$i",
                                        null,
                                        data))
                    } catch (t: Throwable) {
                        logger.debug("tyre.leak notify failed: " + t.message)
                    }
                }
            }
        }

        lastTyrePressuresKpa = pressuresKpa.clone()
        lastTyrePressureStates = pressureStates.clone()
        lastTyreAirLeakStates = airLeakStates.clone()
        lastTyreSignalStates = signalStates.clone()
        lastTyreSystemState = sysState
        lastTyreTemperatureState = tempState
        // Per-wheel readout: kPa, alarm-state enum (0=NORMAL/1=UNDER/2=OVER),
        // leak-state enum (0=Normal/1=Slow/2=Fast), signal-state enum (0=OK/1=Err)
        val sb = StringBuilder("Tyre:")
        val labels = arrayOf(" FL", " FR", " RL", " RR")
        for (i in 0 until 4) {
            sb.append(labels[i]).append("=").append(pressuresKpa[i]).append("kPa")
            sb.append("/alarm=").append(pressureStates[i])
            sb.append("/leak=").append(airLeakStates[i])
            sb.append("/sig=").append(signalStates[i])
        }
        sb.append(" sys=").append(if (sysState == Int.MIN_VALUE) "n/a" else sysState.toString())
        sb.append(" temp=").append(if (tempState == Int.MIN_VALUE) "n/a" else tempState.toString())
        logger.info(sb.toString())
    }

    // Per-wheel temperature poll: candidate (device, method, slot-mapping)
    // tuples, in priority order. Each candidate names a getter on either
    // tyreDevice or instrumentDevice plus a per-corner slot map, because the
    // two HALs use DIFFERENT wheel-index conventions:
    //   tyreDevice.getTyreXxx(int):       1=LF, 2=RF, 3=LR, 4=RR
    //   instrumentDevice.getWheelTemperature(int): 1=RF, 2=RR, 3=LF, 4=LR
    // Cache layout is fixed at [FL=0, FR=1, RL=2, RR=3]; each candidate's
    // slotForCacheIdx[i] gives the int to pass for cache slot i.
    //
    // On the first poll we look up each via reflection; from then on we go
    // straight to the surviving method (or short-circuit if none exist on
    // this firmware). This means a sensor that wakes up later still gets a
    // chance to report — we only lock out based on method-existence, not on
    // whether a value was in range.
    private class TyreTempCandidate(val deviceKind: Int, val methodName: String, val slotForCacheIdx: IntArray)

    private fun pollPerWheelTyreTemp(idx: Int) {
        var method = resolvedTyreTempMethod
        if (method === NO_TYRE_TEMP_GETTER) return
        if (method == null) {
            method = resolveTyreTempMethod()
            resolvedTyreTempMethod = method
            if (method === NO_TYRE_TEMP_GETTER) return
        }
        if (resolvedTyreTempCandidateIdx >= TYRE_TEMP_CANDIDATES.size) return

        val cand = TYRE_TEMP_CANDIDATES[resolvedTyreTempCandidateIdx]
        val device = if (cand.deviceKind == DEV_INSTRUMENT) instrumentDevice else tyreDevice
        if (device == null) {
            // The candidate's device was nulled out after resolution (init
            // failure, device unavailable). Advance so the next poll picks
            // a candidate whose device is still alive.
            resolvedTyreTempCandidateIdx++
            resolvedTyreTempMethod = null
            return
        }
        val wheel = cand.slotForCacheIdx[idx]

        val raw: Any?
        try {
            raw = method.invoke(device, wheel)
        } catch (t: Throwable) {
            if (!loggedTyrePollThrew) {
                loggedTyrePollThrew = true
                val cause = t.cause ?: t
                logger.info("Tyre temp poll: " + method.name + "(" + wheel
                        + ") threw " + cause.javaClass.simpleName
                        + ": " + cause.message)
            }
            return  // transient failure; method stays resolved for next cycle
        }
        if (raw == null) {
            if (!loggedTyrePollNullReturn) {
                loggedTyrePollNullReturn = true
                logger.info("Tyre temp poll: " + method.name + "(" + wheel
                        + ") returned null — getter exists but firmware has no value")
            }
            return
        }
        if (raw !is Number) {
            if (!loggedTyrePollNonNumber) {
                loggedTyrePollNonNumber = true
                logger.info("Tyre temp poll: " + method.name + "(" + wheel
                        + ") returned " + raw.javaClass.simpleName + " = " + raw)
            }
            return
        }
        val v = raw.toDouble()
        if (!(v >= -40.0 && v <= 125.0)) {
            tyreTempOutOfRangeCount++
            if (tyreTempOutOfRangeCount == 1) {
                // Log on first occurrence
                logger.info("Tyre temp poll: " + method.name + "(" + wheel
                        + ") returned " + v + " — outside temperature range, "
                        + "this firmware reports battery voltage via this getter. "
                        + "Will try next candidate after " + TYRE_TEMP_OUT_OF_RANGE_THRESHOLD + " bad reads.")
            }
            if (tyreTempOutOfRangeCount >= TYRE_TEMP_OUT_OF_RANGE_THRESHOLD) {
                // This method consistently returns garbage — advance to next candidate
                tyreTempOutOfRangeCount = 0
                resolvedTyreTempCandidateIdx++
                resolvedTyreTempMethod = null // force re-resolution from next candidate
                logger.info("Tyre temp poll: " + method.name
                        + " returned out-of-range " + TYRE_TEMP_OUT_OF_RANGE_THRESHOLD
                        + " times — advancing to next candidate (idx="
                        + resolvedTyreTempCandidateIdx + ")")
            }
            return
        }
        // Valid reading — reset the out-of-range counter
        tyreTempOutOfRangeCount = 0

        val tempC = Math.round(v).toInt()
        synchronized(tyreTemperatureCache) {
            tyreTemperatureCache[idx] = tempC
        }
        if (!loggedTyrePollHit[idx]) {
            loggedTyrePollHit[idx] = true
            logger.info("Tyre temp poll FIRST: wheel=" + wheel
                    + " (" + arrayOf("FL", "FR", "RL", "RR")[idx] + ") via "
                    + method.name + " = " + tempC + "°C")
        }
    }

    private fun resolveTyreTempMethod(): Method {
        for (i in resolvedTyreTempCandidateIdx until TYRE_TEMP_CANDIDATES.size) {
            val cand = TYRE_TEMP_CANDIDATES[i]
            val device = if (cand.deviceKind == DEV_INSTRUMENT) instrumentDevice else tyreDevice
            if (device == null) continue  // device unavailable on this firmware
            try {
                val m = device.javaClass.getMethod(cand.methodName, Int::class.javaPrimitiveType)
                resolvedTyreTempCandidateIdx = i
                logger.info("Tyre temp poll: using " + cand.methodName + "(int) on "
                        + device.javaClass.simpleName + " (candidate idx=" + i + ")")
                return m
            } catch (e: NoSuchMethodException) {
                logger.debug("Tyre temp poll: " + cand.methodName + " not found on " + device.javaClass.simpleName)
            }
        }
        val tried = StringBuilder()
        for (i in TYRE_TEMP_CANDIDATES.indices) {
            if (i > 0) tried.append(", ")
            tried.append(if (TYRE_TEMP_CANDIDATES[i].deviceKind == DEV_INSTRUMENT) "instrument." else "tyre.")
            tried.append(TYRE_TEMP_CANDIDATES[i].methodName)
        }
        logger.info("Tyre temp poll: no getter on this firmware "
                + "(tried " + tried + " starting from idx=" + resolvedTyreTempCandidateIdx + ")")
        return NO_TYRE_TEMP_GETTER
    }

    private fun snapshotTyreTemperatures(): IntArray {
        synchronized(tyreTemperatureCache) {
            return intArrayOf(
                    tyreTemperatureCache[0], tyreTemperatureCache[1],
                    tyreTemperatureCache[2], tyreTemperatureCache[3]
            )
        }
    }

    @Volatile private var resolvedTyreTempMethod: Method? = null
    // Index into TYRE_TEMP_CANDIDATES: which candidate is currently resolved.
    // When the resolved method consistently returns out-of-range values, we advance
    // to the next candidate. This ensures getTyreBatteryValue returning battery voltage
    // doesn't permanently block getTyreTemperatureState from being tried.
    @Volatile private var resolvedTyreTempCandidateIdx = 0
    @Volatile private var tyreTempOutOfRangeCount = 0
    private val loggedTyrePollHit = booleanArrayOf(false, false, false, false)
    // Diagnostics: surface the FIRST observation per failure mode so a single
    // log capture tells us which path the BYD HAL is taking.
    @Volatile private var loggedTyrePollNullReturn = false
    @Volatile private var loggedTyrePollNonNumber = false
    @Volatile private var loggedTyrePollThrew = false

    // Diagnostic: log each unknown tyre feature ID at most once, capped at 32
    // unique IDs total. The cap prevents a chatty HAL (some emit a feature ID
    // every 100ms for trip metrics) from flooding the log if an unknown one
    // happens to slip through the listener filter.
    private val loggedUnknownTyreIds = java.util.concurrent.ConcurrentHashMap<Int, Boolean>()

    private fun logUnknownTyreEventOnce(eventId: Int, rawInt: Int, rawDbl: Double) {
        if (loggedUnknownTyreIds.size >= MAX_UNKNOWN_TYRE_IDS) return
        if (loggedUnknownTyreIds.putIfAbsent(eventId, true) != null) return
        logger.info("Tyre event UNKNOWN id=" + eventId
                + " intValue=" + (if (rawInt == Int.MIN_VALUE) "n/a" else rawInt.toString())
                + " doubleValue=" + (if (rawDbl.isNaN()) "n/a" else rawDbl.toString())
                + " — if this looks like a temperature, add it to BydFeatureIds.INSTRUMENT_*_TYRE_TEMPERATURE")
    }

    // Per-wheel out-of-range counters for the known LF/RF/LB/RB feature IDs.
    // Logged once per wheel so a sleeping TPMS sensor doesn't spam.
    private val loggedTyreEventOutOfRange = booleanArrayOf(false, false, false, false)

    private fun logTyreEventOutOfRangeOnce(eventId: Int, wheelIdx: Int, rawInt: Int, rawDbl: Double) {
        if (wheelIdx < 0 || wheelIdx > 3 || loggedTyreEventOutOfRange[wheelIdx]) return
        loggedTyreEventOutOfRange[wheelIdx] = true
        logger.info("Tyre event OUT-OF-RANGE: " + arrayOf("FL", "FR", "RL", "RR")[wheelIdx]
                + " (id=" + eventId + ") intValue="
                + (if (rawInt == Int.MIN_VALUE) "n/a" else rawInt.toString())
                + " doubleValue=" + (if (rawDbl.isNaN()) "n/a" else rawDbl.toString())
                + " — sensor likely asleep; will retry silently on next event.")
    }

    private fun onTyreCallback(method: String, args: Array<Any?>?) {
        if (args == null) return
        try {
            // Generic feature-ID event from the 2-arg listener registration.
            // Per-wheel temperature on this firmware family arrives here keyed
            // on the LF/RF/LB/RB Instrument feature IDs. We accept either
            // intValue (some firmwares emit °C as an integer) or doubleValue
            // (others emit a fractional °C).
            if ("onDataEventChanged" == method && args.size >= 2) {
                val eventId = (args[0] as Number).toInt()
                val eventValue = args[1]
                var idx = -1
                if (eventId == BydFeatureIds.INSTRUMENT_LF_TYRE_TEMPERATURE) idx = 0
                else if (eventId == BydFeatureIds.INSTRUMENT_RF_TYRE_TEMPERATURE) idx = 1
                else if (eventId == BydFeatureIds.INSTRUMENT_LB_TYRE_TEMPERATURE) idx = 2
                else if (eventId == BydFeatureIds.INSTRUMENT_RB_TYRE_TEMPERATURE) idx = 3

                if (idx < 0) {
                    // Unknown feature ID — log once per ID so the next log
                    // capture surfaces real per-wheel temperature IDs we
                    // can add to BydFeatureIds.
                    if (eventValue != null) {
                        val rawInt = BydDeviceHelper.getIntValue(eventValue)
                        val rawDbl = BydDeviceHelper.getDoubleValue(eventValue)
                        logUnknownTyreEventOnce(eventId, rawInt, rawDbl)
                    }
                    return
                }

                // Known wheel — extract value, prefer the int slot.
                val rawInt = BydDeviceHelper.getIntValue(eventValue)
                val rawDbl = BydDeviceHelper.getDoubleValue(eventValue)
                var tempC: Double? = null
                if (rawInt != Int.MIN_VALUE && rawInt in -40..125) {
                    tempC = rawInt.toDouble()
                } else if (!rawDbl.isNaN() && rawDbl >= -40.0 && rawDbl <= 125.0) {
                    tempC = rawDbl
                }
                if (tempC == null) {
                    // Sentinel — TPMS hasn't reported this wheel yet, or
                    // the value lives in a slot we don't know about.
                    logTyreEventOutOfRangeOnce(eventId, idx, rawInt, rawDbl)
                    return
                }
                val tempCi = Math.round(tempC).toInt()
                synchronized(tyreTemperatureCache) {
                    tyreTemperatureCache[idx] = tempCi
                }
                if (!loggedTyreFirstEvent[idx]) {
                    loggedTyreFirstEvent[idx] = true
                    logger.info("Tyre event FIRST: " + arrayOf("FL", "FR", "RL", "RR")[idx]
                            + " (id=" + eventId + ") = " + tempCi + "°C")
                }
                val current = snapshot.get()
                if (current != null) {
                    snapshot.set(current.toBuilder().tyreTemperature(snapshotTyreTemperatures()).build())
                }
                return
            }

            if ("onTyreBatteryValueChanged" == method && args.size >= 2) {
                val wheel = (args[0] as Number).toInt()
                val value = (args[1] as Number).toDouble()
                if (wheel == 0) {
                    if (!loggedTyreSlot0) {
                        loggedTyreSlot0 = true
                        logger.info("Tyre slot 0 raw event observed (value=$value) — ignoring further slot 0")
                    }
                    return
                }
                if (wheel < 1 || wheel > 4) {
                    logger.info("Tyre battery callback: unexpected wheel=$wheel value=$value")
                    return
                }
                val idx = wheel - 1
                if (!loggedTyreFirstEvent[idx]) {
                    loggedTyreFirstEvent[idx] = true
                    logger.info("Tyre battery callback FIRST: wheel=" + wheel
                            + " (" + arrayOf("FL", "FR", "RL", "RR")[idx] + ") value=" + value)
                }
                if (!(value >= -40.0 && value <= 125.0)) {
                    if (!loggedTyreOutOfRange) {
                        loggedTyreOutOfRange = true
                        logger.info("Tyre battery callback: value " + value
                                + " outside temperature range — likely battery voltage on this firmware")
                    }
                    return
                }
                val tempC = Math.round(value).toInt()
                synchronized(tyreTemperatureCache) {
                    tyreTemperatureCache[idx] = tempC
                }
                val current = snapshot.get()
                if (current != null) {
                    snapshot.set(current.toBuilder().tyreTemperature(snapshotTyreTemperatures()).build())
                }
                return
            }

            if ("onTyrePressureValueChanged" == method
                    || "onTyrePressureStateChanged" == method
                    || "onTyreAirLeakStateChanged" == method
                    || "onTyreSignalStateChanged" == method
                    || "onTyreSystemStateChanged" == method
                    || "onTyreTemperatureStateChanged" == method
                    || "onIndirectTyreSystemStateChanged" == method) {
                val current = snapshot.get() ?: return
                val b = current.toBuilder()
                collectTyre(b)
                snapshot.set(b.build())
            }
        } catch (e: Exception) {
            logger.debug("onTyreCallback error ($method): " + e.message)
        }
    }

    private fun collectDoorLock(b: BydVehicleData.Builder) {
        val locks = IntArray(7) { LOCK_API_UNKNOWN }
        val rawStates = intArrayOf(
            LOCK_API_UNKNOWN, LOCK_API_UNKNOWN, LOCK_API_UNKNOWN,
            LOCK_API_UNKNOWN, LOCK_API_UNKNOWN, LOCK_API_UNKNOWN,
            LOCK_API_UNKNOWN
        )

        val device = doorLockDevice
        if (device != null) {
            // The recovered legacy daemon uses getDoorLockStatus(1) first and
            // falls back to getDoorLockState(). Here we poll all known lock
            // areas so the vehicle page can derive an accurate local "all
            // locked" state. This is now the ONLY source — the BYD cloud lock
            // readback was removed in 61b4d7f.
            for (area in 1..5) {
                val raw = BydDeviceHelper.callGetter(device, "getDoorLockStatus", area)
                rawStates[area - 1] = sdkLockInt(raw)
                locks[area - 1] = apiLockFromSdk(raw)
            }

            mergeCachedDoorLocks(locks)
            locks[6] = deriveOverallLock(locks)
            if (locks[6] == LOCK_API_UNKNOWN && locks[0] != LOCK_API_UNKNOWN) {
                // Legacy surveillance used SDK area 1 as the central lock
                // indicator. Keep that fallback so one valid driver/central
                // lock event can drive the top-level vehicle status.
                locks[6] = locks[0]
            }

            if (locks[6] == LOCK_API_UNKNOWN) {
                val allArea = BydDeviceHelper.callGetter(device, "getDoorLockStatus", 0)
                rawStates[5] = sdkLockInt(allArea)
                val allAreaApi = apiLockFromSdk(allArea)
                if (allAreaApi != LOCK_API_UNKNOWN) locks[6] = allAreaApi
            }

            if (locks[6] == LOCK_API_UNKNOWN) {
                val aggregateRaw = BydDeviceHelper.callGetter(device, "getDoorLockState")
                rawStates[6] = sdkLockInt(aggregateRaw)
                val aggregate = apiLockFromSdk(aggregateRaw)
                if (aggregate != LOCK_API_UNKNOWN) locks[6] = aggregate
            }
        }

        logDoorLockSnapshot(locks, rawStates)
        b.doorLockStatus(locks)
    }

    private fun sdkLockInt(raw: Any?): Int {
        if (raw !is Number) return LOCK_API_UNKNOWN
        return raw.toInt()
    }

    private fun apiLockFromSdk(raw: Any?): Int {
        if (raw !is Number) return LOCK_API_UNKNOWN
        val sdkState = raw.toInt()
        return BydSignalRules.lockSdkToApi(sdkState)
    }

    private fun deriveOverallLock(locks: IntArray): Int = BydSignalRules.deriveOverallLock(locks)

    private fun mergeCachedDoorLocks(locks: IntArray) {
        synchronized(doorLockEventCache) {
            for (i in locks.indices) {
                if (i >= doorLockEventCache.size) break
                if (locks[i] == LOCK_API_UNKNOWN && doorLockEventCache[i] != LOCK_API_UNKNOWN) {
                    locks[i] = doorLockEventCache[i]
                }
            }
        }
    }

    private fun updateDoorLockEventCache(area: Int, sdkState: Int) {
        val apiState = apiLockFromSdk(sdkState)
        if (apiState == LOCK_API_UNKNOWN) return
        val index = area - 1
        if (index < 0 || index >= 5) return
        synchronized(doorLockEventCache) {
            doorLockEventCache[index] = apiState
            doorLockEventCache[6] = deriveOverallLock(doorLockEventCache)
            if (doorLockEventCache[6] == LOCK_API_UNKNOWN && index == 0) {
                // The recovered daemon only watched area 1 for its lock gate,
                // so preserve that central-lock fallback for listener events.
                doorLockEventCache[6] = apiState
            }
        }
    }

    private fun logDoorLockSnapshot(locks: IntArray, rawStates: IntArray) {
        val state = joinInts(locks) + " raw=" + joinInts(rawStates)
        if (state != lastDoorLockSnapshotLog) {
            lastDoorLockSnapshotLog = state
            logger.info("DoorLock snapshot api=" + joinInts(locks)
                + " raw=[area1,area2,area3,area4,area5,all,state]=" + joinInts(rawStates))
        }
    }

    private fun joinInts(values: IntArray): String {
        val sb = StringBuilder("[")
        for (i in values.indices) {
            if (i > 0) sb.append(',')
            sb.append(values[i])
        }
        return sb.append(']').toString()
    }

    private fun collectSensor(b: BydVehicleData.Builder) {
        val device = sensorDevice ?: return
        try {
            val slope = BydDeviceHelper.callGetter(device, "getSlope")
            if (slope is Number) {
                val raw = slope.toInt()
                val degrees = Math.toDegrees(Math.atan(raw / 100.0))
                if (degrees in -60.0..60.0) b.slopeDegrees(degrees)
            }
        } catch (e: Exception) {
            logger.debug("collectSensor error: " + e.message)
        }
    }

    private fun collectEnergy(b: BydVehicleData.Builder) {
        val device = energyDevice ?: return
        try {
            val mode = BydDeviceHelper.callGetter(device, "getEnergyMode")
            if (mode is Number) b.energyMode(mode.toInt())
            val opMode = BydDeviceHelper.callGetter(device, "getOperationMode")
            if (opMode is Number) b.operationMode(opMode.toInt())

            // SOC fallback: EnergyDevice.getElecPercentageValue() — try if statistic didn't provide SOC
            if (b.socPercent.isNaN()) {
                val elecPct = BydDeviceHelper.callGetter(device, "getElecPercentageValue")
                if (elecPct is Number) {
                    val soc = elecPct.toDouble()
                    if (soc > 0 && soc <= 100) {
                        b.socPercent(soc)
                        logger.debug("SOC from EnergyDevice: $soc%")
                    }
                }
            }
        } catch (e: Exception) {
            logger.debug("collectEnergy error: " + e.message)
        }
    }

    private fun collectRadar(b: BydVehicleData.Builder) {
        val device = radarDevice ?: return
        try {
            val distances = BydDeviceHelper.callGetter(device, "getAllRadarDistance")
            if (distances is IntArray) b.radarDistances(distances)
        } catch (e: Exception) {
            logger.debug("collectRadar error: " + e.message)
        }
    }

    // ==================== EXTENDED GETTERS ====================

    /**
     * Extended statistic data: OEM SOH, driving time, key battery level.
     * Called from collectAll() (core telemetry consumers need SOH).
     */
    private fun collectStatisticExtended(b: BydVehicleData.Builder) {
        val device = statisticDevice ?: return

        // OEM SOH: read from the BYD statistic register for the b.sohPercent
        // display fallback only.
        try {
            val sohValue = readOemSohPercent()
            if (sohValue > 0) {
                b.sohPercent(sohValue)
            }
        } catch (e: Exception) {
            logger.debug("collectStatisticExtended SOH error: " + e.message)
        }

        // Driving time
        try {
            val drivingTime = BydDeviceHelper.callGetter(device, "getDrivingTimeValue")
            if (drivingTime is Number) {
                val hours = drivingTime.toDouble()
                if (hours >= 0) b.drivingTimeHours(hours)
            }
        } catch (e: Exception) {
            logger.debug("collectStatisticExtended drivingTime error: " + e.message)
        }

        // Key battery level
        try {
            val keyBatt = BydDeviceHelper.callGetter(device, "getKeyBatteryLevel")
            if (keyBatt is Number) {
                b.keyBatteryLevel(keyBatt.toInt())
            }
        } catch (e: Exception) {
            logger.debug("collectStatisticExtended keyBattery error: " + e.message)
        }
    }

    /**
     * Extended instrument data: cabin temp, trip data, consumption.
     * Called from collectAll() (trips, SOC history consume these).
     */
    private fun collectInstrumentExtended(b: BydVehicleData.Builder) {
        // Cabin temperature is already read via acDevice.getTemprature(AC_TEMP_POS_CABIN) in
        // collectAc(). This comment used to say position 1; that was wrong — position 1 is the
        // driver-zone setpoint, and reading it here is what made the Vehicle screen report the
        // setpoint as the cabin temperature (BladeWatch-gkjl).
        //
        // Do not poll AC_TEMP_INSIDE here: BYD firmware denies feature 0x3d800030 for this UID
        // every cycle, creating log noise while adding no data on the tested head unit.

        // Per-tyre temperature from InstrumentDevice via feature ID get() calls.
        // Slot mapping from BYDAutoFeatureIds.Instrument:
        //   LF_TYRE_TEMPERATURE, RF_TYRE_TEMPERATURE, LB_TYRE_TEMPERATURE, RB_TYRE_TEMPERATURE
        // These may return null on some firmware but are the correct channel on others.
        try {
            val device = instrumentDevice
            if (device != null) {
                val featureIds = BydFeatureIds.INSTRUMENT_TYRE_TEMP_IDS
                // Order: LF=0, RF=1, LB(RL)=2, RB(RR)=3
                val tempResults = IntArray(4)
                var anyValid = false
                for (i in featureIds.indices) {
                    val result = BydDeviceHelper.callGet(device, featureIds[i], Integer::class.java)
                    if (result != null) {
                        val raw = BydDeviceHelper.getIntValue(result)
                        if (raw in -40..125) {
                            tempResults[i] = raw
                            anyValid = true
                        } else {
                            tempResults[i] = Int.MIN_VALUE
                        }
                    } else {
                        tempResults[i] = Int.MIN_VALUE
                    }
                }
                if (anyValid) {
                    // Map: index 0=LF, 1=RF, 2=LB(RL), 3=RB(RR)
                    synchronized(tyreTemperatureCache) {
                        if (tempResults[0] != Int.MIN_VALUE) tyreTemperatureCache[0] = tempResults[0]
                        if (tempResults[1] != Int.MIN_VALUE) tyreTemperatureCache[1] = tempResults[1]
                        if (tempResults[2] != Int.MIN_VALUE) tyreTemperatureCache[2] = tempResults[2]
                        if (tempResults[3] != Int.MIN_VALUE) tyreTemperatureCache[3] = tempResults[3]
                    }
                    b.tyreTemperature(snapshotTyreTemperatures())
                    if (!loggedInstrumentTyreTemp) {
                        loggedInstrumentTyreTemp = true
                        logger.info("Tyre temp from InstrumentDevice feature IDs: LF=" + tempResults[0]
                            + " RF=" + tempResults[1] + " RL=" + tempResults[2] + " RR=" + tempResults[3] + "°C")
                    }
                }
            }
        } catch (e: Exception) {
            logger.debug("collectInstrumentExtended tyreTemp error: " + e.message)
        }

        // Current trip mileage
        try {
            val device = instrumentDevice
            if (device != null) {
                val tripMileage = BydDeviceHelper.callGet(device,
                        BydFeatureIds.INSTRUMENT_2IN1_CURRENT_JOURNEY_DRIVE_MILEAGE, java.lang.Double.TYPE)
                if (tripMileage != null) {
                    val v = BydDeviceHelper.getDoubleValue(tripMileage)
                    if (!v.isNaN() && v >= 0) b.currentTripMileageKm(v * distanceToKmFactorValue)
                }
            }
        } catch (e: Exception) {
            logger.debug("collectInstrumentExtended tripMileage error: " + e.message)
        }

        // Current trip time
        try {
            val device = instrumentDevice
            if (device != null) {
                val tripTime = BydDeviceHelper.callGet(device,
                        BydFeatureIds.INSTRUMENT_2IN1_CURRENT_JOURNEY_DRIVE_TIME, java.lang.Double.TYPE)
                if (tripTime != null) {
                    val v = BydDeviceHelper.getDoubleValue(tripTime)
                    if (!v.isNaN() && v >= 0) b.currentTripTimeHours(v)
                }
            }
        } catch (e: Exception) {
            logger.debug("collectInstrumentExtended tripTime error: " + e.message)
        }

        // This trip electricity consumption from statistic device
        try {
            val device = statisticDevice
            if (device != null) {
                val tripElec = BydDeviceHelper.callGet(device,
                        BydFeatureIds.STAT_THIS_TRIP_ELEC_CONSUMPTION, java.lang.Double.TYPE)
                if (tripElec != null) {
                    val v = BydDeviceHelper.getDoubleValue(tripElec)
                    if (!v.isNaN() && v >= 0) b.currentTripConsumptionKwh(v)
                }
            }
        } catch (e: Exception) {
            logger.debug("collectInstrumentExtended tripElecConsumption error: " + e.message)
        }

        // Last 50km power consumption
        try {
            val device = instrumentDevice
            if (device != null) {
                val last50km = BydDeviceHelper.callGetter(device, "getLast50KmPowerConsume")
                if (last50km is Number) {
                    val v = last50km.toDouble()
                    if (v >= 0) b.last50KmConsumption(v)
                }
            }
        } catch (e: Exception) {
            logger.debug("collectInstrumentExtended last50km error: " + e.message)
        }
    }

    // ==================== KEY PROXIMITY ====================
    // Discrete key/fob proximity & authentication state probed from SettingDevice and
    // InstrumentDevice. Methods are read reflectively so missing ones (model variation)
    // don't break collection. Each value is the raw int from the SDK; UNAVAILABLE means
    // the method returned a sentinel (BMS unavailable / invalid) or wasn't present.
    //
    // Logged on every state transition and at most once per 5 minutes regardless,
    // so the log captures fob behaviour during parked / charging / approach windows.

    @Volatile private var lastKeyStartState = Int.MIN_VALUE
    @Volatile private var lastKeyMissingInd = Int.MIN_VALUE
    @Volatile private var lastKeyBtLowPowerMode = Int.MIN_VALUE
    @Volatile private var lastKeyPowerLowInd = Int.MIN_VALUE
    @Volatile private var lastKeyDetectionReminder = Int.MIN_VALUE
    @Volatile private var lastSmartKeyWarnState = Int.MIN_VALUE
    @Volatile private var lastKeyProbeLogMs = 0L

    private fun collectKeyProximity(b: BydVehicleData.Builder) {
        val startState = readKeyInt(settingDevice, "getStartKeyState")
        val missingInd = readKeyInt(settingDevice, "getMissKeyInd")
        val btLowPower = readKeyInt(settingDevice, "getIKEYBTLowPowerMode")
        val powerLow = readKeyInt(settingDevice, "getKeyPowerLowInd")
        val detectionRem = readKeyInt(instrumentDevice, "getKeyDetectionReminder")
        val warnState = readKeyInt(instrumentDevice, "getSmartKeySysWarnLightState")

        if (startState != BydVehicleData.UNAVAILABLE) b.keyStartState(startState)
        if (missingInd != BydVehicleData.UNAVAILABLE) b.keyMissingInd(missingInd)
        if (btLowPower != BydVehicleData.UNAVAILABLE) b.keyBtLowPowerMode(btLowPower)
        if (powerLow != BydVehicleData.UNAVAILABLE) b.keyPowerLowInd(powerLow)
        if (detectionRem != BydVehicleData.UNAVAILABLE) b.keyDetectionReminder(detectionRem)
        if (warnState != BydVehicleData.UNAVAILABLE) b.smartKeyWarnState(warnState)

        val changed =
            startState != lastKeyStartState
            || missingInd != lastKeyMissingInd
            || btLowPower != lastKeyBtLowPowerMode
            || powerLow != lastKeyPowerLowInd
            || detectionRem != lastKeyDetectionReminder
            || warnState != lastSmartKeyWarnState

        val now = System.currentTimeMillis()
        val heartbeat = now - lastKeyProbeLogMs > 300_000

        if (changed || heartbeat) {
            lastKeyStartState = startState
            lastKeyMissingInd = missingInd
            lastKeyBtLowPowerMode = btLowPower
            lastKeyPowerLowInd = powerLow
            lastKeyDetectionReminder = detectionRem
            lastSmartKeyWarnState = warnState
            lastKeyProbeLogMs = now
            logger.info("KeyProbe: startState=" + fmtKeyVal(startState)
                + " missingInd=" + fmtKeyVal(missingInd)
                + " btLowPower=" + fmtKeyVal(btLowPower)
                + " powerLow=" + fmtKeyVal(powerLow)
                + " detectionReminder=" + fmtKeyVal(detectionRem)
                + " smartKeyWarn=" + fmtKeyVal(warnState)
                + " accIsOn=" + accIsOn
                + (if (changed) " [CHANGE]" else " [hb]"))
        }
    }

    /**
     * Reflective single-int getter that filters BYD sentinel values
     * (BMS_UNAVAILABLE=65535, INVALID_VALUE=-10011, INVALID_VALUE_2=-10013).
     * Returns BydVehicleData.UNAVAILABLE if the method is missing, the device is
     * null, or the value is a known sentinel.
     */
    private fun readKeyInt(device: Any?, methodName: String): Int {
        if (device == null) return BydVehicleData.UNAVAILABLE
        try {
            val m = device.javaClass.getMethod(methodName)
            val result = m.invoke(device)
            if (result !is Number) return BydVehicleData.UNAVAILABLE
            val v = result.toInt()
            if (v == 65535 || v == -10011 || v == -10013) return BydVehicleData.UNAVAILABLE
            return v
        } catch (e: NoSuchMethodException) {
            return BydVehicleData.UNAVAILABLE
        } catch (e: Exception) {
            return BydVehicleData.UNAVAILABLE
        }
    }

    /**
     * Extended charging data: charging rest time.
     * Called from collectAllFull() only (display-only, on-demand).
     */
    private fun collectChargingExtended(b: BydVehicleData.Builder) {
        val device = chargingDevice ?: return

        // Fallback: chargingDevice.getChargingRestTime() when instrument feature IDs
        // didn't populate in collectInstrument(). Checks gun state first — if NONE, skip.
        if (b.chargingRestTimeHours == BydVehicleData.UNAVAILABLE) {
            try {
                if (b.chargingGunState != 1) {
                    val restTime = BydDeviceHelper.callGetter(device, "getChargingRestTime")
                    if (restTime is IntArray) {
                        if (restTime.size >= 2) {
                            val hours = restTime[0]
                            val minutes = restTime[1]
                            if (hours != 255 && minutes != 255 && hours in 0..23 && minutes in 0..59) {
                                b.chargingRestTimeHours(hours)
                                b.chargingRestTimeMinutes(minutes)
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                logger.debug("collectChargingExtended restTime error: " + e.message)
            }
        }
    }

    /**
     * Extended bodywork data: steering angle, auto system state, 12V level, sunroof, sunshade.
     * Called from collectAllFull() only (display-only, on-demand).
     */
    private fun collectBodyworkExtended(b: BydVehicleData.Builder) {
        val device = bodyworkDevice ?: return

        // Steering wheel angle
        try {
            val steering = BydDeviceHelper.callGetter(device, "getSteeringWheelValue", 1)
            if (steering is Number) {
                val angle = steering.toDouble()
                b.steeringAngleDegrees(angle)
            }
        } catch (e: Exception) {
            logger.debug("collectBodyworkExtended steering error: " + e.message)
        }

        // Auto system state (0=normal, 1=set_secure, 2=start_secure)
        try {
            val autoState = BydDeviceHelper.callGetter(device, "getAutoSystemState")
            if (autoState is Number) {
                b.autoSystemState(autoState.toInt())
            }
        } catch (e: Exception) {
            logger.debug("collectBodyworkExtended autoSystemState error: " + e.message)
        }

        // 12V battery voltage level (LOW/NORMAL/INVALID)
        try {
            val battLevel = BydDeviceHelper.callGetter(device, "getBatteryVoltageLevel")
            if (battLevel is Number) {
                b.battery12vLevel(battLevel.toInt())
            }
        } catch (e: Exception) {
            logger.debug("collectBodyworkExtended battery12vLevel error: " + e.message)
        }

        // Sunroof state (if available)
        try {
            val sunroof = BydDeviceHelper.callGetter(device, "getSunroofState")
            if (sunroof is Number) {
                b.sunroofState(sunroof.toInt())
            }
        } catch (e: Exception) {
            logger.debug("collectBodyworkExtended sunroofState error: " + e.message)
        }

        // Sunroof position (if available)
        try {
            val sunroofPos = BydDeviceHelper.callGetter(device, "getSunroofPosition")
            if (sunroofPos is Number) {
                b.sunroofPosition(sunroofPos.toInt())
            }
        } catch (e: Exception) {
            logger.debug("collectBodyworkExtended sunroofPosition error: " + e.message)
        }

        // Sunshade panel percent
        try {
            val sunshade = BydDeviceHelper.callGet(device, BydFeatureIds.BODY_SUNSHADE_PANEL_PERCENT, Integer::class.java)
            if (sunshade != null) {
                val v = BydDeviceHelper.getIntValue(sunshade)
                if (v in 0..100) b.sunshadePercent(v)
            }
        } catch (e: Exception) {
            logger.debug("collectBodyworkExtended sunshade error: " + e.message)
        }
    }

    /**
     * Extended engine data: coolant level, oil level, engine code.
     * Called from collectAllFull() only (display-only, on-demand).
     */
    private fun collectEngineExtended(b: BydVehicleData.Builder) {
        val device = engineDevice ?: return

        // Engine coolant level. BYD SDK constants: 0=NORMAL, 1=LOW.
        // Some firmwares return -1 or sentinel when the value is unavailable.
        var coolantRaw: Int? = null
        try {
            val coolant = BydDeviceHelper.callGetter(device, "getEngineCoolantLevel")
            if (coolant is Number) {
                coolantRaw = coolant.toInt()
                b.engineCoolantLevel(coolantRaw)
            }
        } catch (e: Exception) {
            logger.debug("collectEngineExtended coolant error: " + e.message)
        }

        // Oil level from Engine device. SDK range 0-254 (dipstick scale).
        // 0 may be a "no value" sentinel rather than empty tank — needs
        // verification against the cluster's own oil-level UI.
        var engineOilRaw: Int? = null
        try {
            val oil = BydDeviceHelper.callGetter(device, "getOilLevel")
            if (oil is Number) {
                engineOilRaw = oil.toInt()
                b.oilLevel(engineOilRaw)
            }
        } catch (e: Exception) {
            logger.debug("collectEngineExtended oilLevel error: " + e.message)
        }

        // Parallel reading from the Setting device (different code path).
        // Setting.getEngineOilLevel exists on most BYD firmwares — pulling it
        // alongside the Engine device version lets us cross-check which one
        // is actually populated on this car. Logged for diagnostics only;
        // not surfaced on the snapshot until we know which is canonical.
        var settingOilRaw: Int? = null
        try {
            val sDevice = settingDevice
            if (sDevice != null) {
                val oil = BydDeviceHelper.callGetter(sDevice, "getEngineOilLevel")
                if (oil is Number) settingOilRaw = oil.toInt()
            }
        } catch (e: Exception) {
            logger.debug("collectEngineExtended settingOilLevel error: " + e.message)
        }

        // "Low oil indicator" lamp from Setting device — when this is set, the
        // dashboard is already showing the warning. Useful as a sanity check.
        var lowOilIndRaw: Int? = null
        try {
            val sDevice = settingDevice
            if (sDevice != null) {
                val ind = BydDeviceHelper.callGetter(sDevice, "getLowOilInd")
                if (ind is Number) lowOilIndRaw = ind.toInt()
            }
        } catch (e: Exception) {
            logger.debug("collectEngineExtended lowOilInd error: " + e.message)
        }

        logEngineFluidsIfChanged(coolantRaw, engineOilRaw, settingOilRaw, lowOilIndRaw)

        // Engine code (e.g. "BYD473QF")
        try {
            val code = BydDeviceHelper.callGetter(device, "getEngineCode")
            if (code is String) {
                b.engineCode(code)
            } else if (code != null) {
                val codeStr = BydDeviceHelper.getStringValue(code)
                if (!codeStr.isNullOrEmpty()) b.engineCode(codeStr)
            }
        } catch (e: Exception) {
            logger.debug("collectEngineExtended engineCode error: " + e.message)
        }
    }

    // Last-seen engine-fluid readings — change-only logging plus a 5-min
    // heartbeat so a healthy car doesn't spam the log but transitions
    // (e.g. coolant drops to LOW after a leak develops) surface immediately.
    @Volatile private var lastCoolantRaw: Int? = null
    @Volatile private var lastEngineOilRaw: Int? = null
    @Volatile private var lastSettingOilRaw: Int? = null
    @Volatile private var lastLowOilIndRaw: Int? = null
    @Volatile private var lastEngineFluidsLogMs = 0L
    @Volatile private var firstEngineFluidsLog = true

    private fun logEngineFluidsIfChanged(coolantRaw: Int?, engineOilRaw: Int?,
                                          settingOilRaw: Int?, lowOilIndRaw: Int?) {
        val changed = firstEngineFluidsLog
                || coolantRaw != lastCoolantRaw
                || engineOilRaw != lastEngineOilRaw
                || settingOilRaw != lastSettingOilRaw
                || lowOilIndRaw != lastLowOilIndRaw
        val now = System.currentTimeMillis()
        val heartbeat = now - lastEngineFluidsLogMs > 300_000
        if (!changed && !heartbeat) return
        firstEngineFluidsLog = false
        lastCoolantRaw = coolantRaw
        lastEngineOilRaw = engineOilRaw
        lastSettingOilRaw = settingOilRaw
        lastLowOilIndRaw = lowOilIndRaw
        lastEngineFluidsLogMs = now
        logger.info("EngineFluids: coolant=" + fmtFluid(coolantRaw)
                + " (0=NORMAL,1=LOW)"
                + " engineOil=" + fmtFluid(engineOilRaw) + " (0-254)"
                + " settingOil=" + fmtFluid(settingOilRaw)
                + " lowOilInd=" + fmtFluid(lowOilIndRaw)
                + (if (changed) " [CHANGE]" else " [hb]"))
    }

    // ==================== LISTENER REGISTRATION ====================

    private fun registerAllListeners() {
        logger.info("Registering listeners...")
        var count = 0

        // Bodywork: use the typed listener so onDoorStateChanged /
        // onWindowStateChanged / onWindowOpenPercentChanged actually dispatch.
        // The generic IBYDAutoListener registration succeeds but never fires
        // those device-specific callbacks.
        if (BydDeviceHelper.registerBodyworkListener(bodyworkDevice, this::onBodyworkCallback)) {
            logger.info("  Bodywork listener registered (typed)")
            count++
        } else if (BydDeviceHelper.registerListener(bodyworkDevice, this::onBodyworkCallback)) {
            // Fallback for stub/older firmwares that only expose the generic interface.
            logger.info("  Bodywork listener registered (generic fallback — door/window callbacks may not fire)")
            count++
        }
        if (BydDeviceHelper.registerListener(speedDevice, this::onGenericCallback)) {
            logger.info("  Speed listener registered")
            count++
        }
        // SKIP gearbox listener — BYDAutoGearboxDevice.learningEPB() crashes with
        // "Given calling package android does not match caller's uid 2000" when running
        // as shell (UID 2000). The crash kills the BYD device manager's HandlerThread,
        // which cascades into GL thread hang → watchdog kill → daemon restart loop.
        // Gear data is collected via polling (collectAll) and GearMonitor handles gear changes.
        // if (BydDeviceHelper.registerListener(gearboxDevice, this::onGenericCallback)) {
        //     logger.info("  Gearbox listener registered")
        //     count++
        // }
        // Charging: prefer typed registration. The generic IBYDAutoListener
        // proxy used to register here misses onBatteryManagementDeviceStateChanged
        // on some PHEV firmwares, which is the root of the inconsistent
        // charging-detection bug (BMS state would freeze at 15 IDLE while
        // charging). Typed listener guarantees AC-charging start is seen.
        if (BydDeviceHelper.registerChargingListener(chargingDevice, this::onChargingCallback)) {
            logger.info("  Charging listener registered (typed)")
            count++
        } else if (BydDeviceHelper.registerListener(chargingDevice, this::onChargingCallback)) {
            logger.info("  Charging listener registered (generic fallback)")
            count++
        }
        // Engine listener: typed for onEngineCoolantLevelChanged /
        // onOilLevelChanged. Without this, engine fluid status is only
        // refreshed by the one-shot collectAllFull at init.
        if (BydDeviceHelper.registerEngineListener(engineDevice, this::onEngineCallback)) {
            logger.info("  Engine listener registered (typed)")
            count++
        } else if (BydDeviceHelper.registerListener(engineDevice, this::onEngineCallback)) {
            logger.info("  Engine listener registered (generic fallback)")
            count++
        }
        if (BydDeviceHelper.registerListener(instrumentDevice, this::onInstrumentCallback)) {
            logger.info("  Instrument listener registered (external charging power)")
            count++
        }
        if (BydDeviceHelper.registerListener(statisticDevice, this::onGenericCallback)) {
            logger.info("  Statistic listener registered")
            count++
        }
        if (BydDeviceHelper.registerListener(lightDevice, this::onLightsCallback)) {
            logger.info("  Light listener registered")
            count++
        }
        if (BydDeviceHelper.registerListener(adasDeviceValue, this::onAdasCallback)) {
            logger.info("  Adas listener registered")
            count++
        }
        if (BydDeviceHelper.registerListener(settingDevice, this::onSettingsCallback)) {
            logger.info("  Settings listener registered")
            count++
        }
        if (BydDeviceHelper.registerListener(radarDevice, this::onGenericCallback)) {
            logger.info("  Radar listener registered")
            count++
        }
        if (BydDeviceHelper.registerListener(otaDevice, this::onOtaCallback)) {
            logger.info("  OTA listener registered")
            count++
        }

        // Display-only devices — no periodic polling, listener-driven only.
        // These update the snapshot when BYD HAL pushes CAN bus state changes.
        //
        // DoorLock requires the typed AbsBYDAutoDoorLockListener — the generic
        // IBYDAutoListener registration succeeds but never receives
        // onDoorLockStatusChanged. This was the root cause of stale lock data.
        if (BydDeviceHelper.registerDoorLockListener(doorLockDevice, this::onDoorLockCallback)) {
            logger.info("  DoorLock listener registered (typed)")
            count++
        } else if (BydDeviceHelper.registerListener(doorLockDevice, this::onDoorLockCallback)) {
            logger.info("  DoorLock listener registered (generic fallback — lock callbacks may not fire)")
            count++
        }
        if (BydDeviceHelper.registerTyreListener(tyreDevice, this::onTyreCallback)) {
            logger.info("  Tyre listener registered (typed)")
            count++
        } else if (BydDeviceHelper.registerListener(tyreDevice, this::onDisplayCallback)) {
            logger.info("  Tyre listener registered (generic fallback)")
            count++
        }
        if (BydDeviceHelper.registerListener(acDevice, this::onDisplayCallback)) {
            logger.info("  AC listener registered")
            count++
        }
        if (BydDeviceHelper.registerListener(sensorDevice, this::onDisplayCallback)) {
            logger.info("  Sensor listener registered")
            count++
        }
        if (BydDeviceHelper.registerListener(energyDevice, this::onDisplayCallback)) {
            logger.info("  Energy listener registered")
            count++
        }
        if (BydDeviceHelper.registerListener(powerDevice, this::onDisplayCallback)) {
            logger.info("  Power listener registered")
            count++
        }

        logger.info("Listeners registered: $count")
    }

    private fun onBodyworkCallback(method: String, args: Array<Any?>?) {
        val current = snapshot.get() ?: return
        val b = current.toBuilder()
        // Bodywork events also affect window/door-open state (separate from
        // lock state) and trunk position. Refresh both the bodywork view and
        // the lock view — door open/close on the bodywork bus is often the
        // first signal of an upcoming lock event, and refreshing locks here
        // means consumers see consistent state regardless of which side fires.
        collectBodywork(b)
        collectDoorLock(b)
        val updated = b.build()
        snapshot.set(updated)

        // If a typed onDoorStateChanged event arrived, fan it out specifically
        // so consumers that want raw door-open events (not lock state) can
        // subscribe without polling the snapshot.
        if ("onDoorStateChanged" == method && args != null && args.size >= 2) {
            val area = (args[0] as? Int) ?: -1
            val state = (args[1] as? Int) ?: -1
            notifyDoorStateListeners(area, state)
        }
        notifyLockSnapshotListeners(updated)
    }

    /**
     * Callback for DoorLock device — re-reads lock status on CAN bus state change.
     * Unlike other display-only devices, door lock state is critical for the
     * vehicle control page and must be updated immediately when the HAL reports
     * a change.
     *
     * The typed AbsBYDAutoDoorLockListener delivers onDoorLockStatusChanged(area,state)
     * with raw SDK semantics (UNLOCK=1, LOCK=2). We refresh the snapshot (which
     * uses inverted API contract for backwards compat) and forward the raw
     * SDK-semantic event to door-lock listeners.
     */
    private fun onDoorLockCallback(method: String, args: Array<Any?>?) {
        val current = snapshot.get() ?: return

        var area = -1
        var sdkState = -1
        if ("onDoorLockStatusChanged" == method && args != null && args.size >= 2) {
            area = (args[0] as? Int) ?: -1
            sdkState = (args[1] as? Int) ?: -1
            updateDoorLockEventCache(area, sdkState)
        }

        val b = current.toBuilder()
        collectDoorLock(b)
        val updated = b.build()
        snapshot.set(updated)

        if ("onDoorLockStatusChanged" == method && args != null && args.size >= 2) {
            notifyDoorLockListeners(area, sdkState)
        }
        notifyLockSnapshotListeners(updated)
    }

    /**
     * Callback for display-only devices (Tyre, AC, Sensor, Energy, Power).
     *
     * These listeners exist solely to keep the BYD device singletons' internal caches
     * fresh. We do NOT re-poll devices here — the snapshot is updated on-demand when
     * the HTTP API calls collectAllFull(), or when the bodywork listener fires.
     *
     * This avoids the 10Hz SensorDevice postEvent from triggering expensive
     * full display sweeps (tyre×4, seatbelt×5, AC×5, light×8, radar, etc.)
     */
    private fun onDisplayCallback(method: String, args: Array<Any?>?) {
        // No-op: listener registration keeps BYD HAL singletons' caches alive.
        // Actual data is read on-demand via collectAllFull().
    }

    // Throttle for generic listener callbacks (StatisticDevice fires at ~10Hz on CAN bus)
    @Volatile private var lastGenericCallbackTime = 0L

    private fun onGenericCallback(method: String, args: Array<Any?>?) {
        // Typed callbacks for real-time updates
        if ("onElecPercentageChanged" == method && args != null && args.isNotEmpty()) {
            try {
                val soc = (args[0] as Number).toDouble()
                if (soc in 0.0..100.0) {
                    val current = snapshot.get()
                    if (current != null) {
                        snapshot.set(current.toBuilder().socPercent(soc).build())
                    }
                }
            } catch (e: Exception) { logger.debug("onGenericCallback onElecPercentageChanged error: " + e.message) }
            return
        }
        if ("onFuelPercentageChanged" == method && args != null && args.isNotEmpty()) {
            try {
                val fuel = (args[0] as Number).toInt()
                if (fuel in 1..100) {
                    val current = snapshot.get()
                    if (current != null && isPhev(current)) {
                        snapshot.set(current.toBuilder().fuelPercent(fuel.toDouble()).build())
                    }
                }
            } catch (e: Exception) { logger.debug("onGenericCallback onFuelPercentageChanged error: " + e.message) }
            return
        }
        if ("onSpeedChanged" == method && args != null && args.isNotEmpty()) {
            try {
                val speed = (args[0] as Number).toDouble()
                if (speed != BydFeatureIds.SDK_NOT_AVAILABLE) {
                    val current = snapshot.get()
                    if (current != null) {
                        snapshot.set(current.toBuilder().speedKmh(speed * distanceToKmFactorValue).build())
                    }
                }
            } catch (e: Exception) { logger.debug("onGenericCallback onSpeedChanged error: " + e.message) }
            return
        }
        if ("onEngineSpeedChanged" == method && args != null && args.isNotEmpty()) {
            try {
                val rpm = (args[0] as Number).toInt()
                if (rpm in 0..8000) {
                    val current = snapshot.get()
                    if (current != null) {
                        snapshot.set(current.toBuilder().engineSpeedRpm(rpm).build())
                    }
                }
            } catch (e: Exception) { logger.debug("onGenericCallback onEngineSpeedChanged error: " + e.message) }
            return
        }
        if ("onBatteryPowerVoltageChanged" == method && args != null && args.isNotEmpty()) {
            try {
                val voltage = (args[0] as Number).toDouble()
                if (voltage > 0 && voltage < 20) {
                    val current = snapshot.get()
                    if (current != null) {
                        snapshot.set(current.toBuilder().voltage12v(voltage).build())
                    }
                }
            } catch (e: Exception) { logger.debug("onGenericCallback onBatteryPowerVoltageChanged error: " + e.message) }
            return
        }
        if ("onChargingGunStateChanged" == method && args != null && args.isNotEmpty()) {
            try {
                val gunState = (args[0] as Number).toInt()
                val current = snapshot.get()
                if (current != null) {
                    snapshot.set(current.toBuilder().chargingGunState(gunState).build())
                }
            } catch (e: Exception) { logger.debug("onGenericCallback onChargingGunStateChanged error: " + e.message) }
            return
        }

        // Capture HV pack voltage from statistic device event.
        // BYD CAN bus fires StatisticDevice events at ~10Hz — throttle to 1Hz max.
        if ("onDataEventChanged" == method && args != null && args.size >= 2) {
            val now = System.currentTimeMillis()
            if (now - lastGenericCallbackTime < 1000) return
            lastGenericCallbackTime = now

            try {
                val eventId = (args[0] as Number).toInt()
                val eventValue = args[1]
                val iVal = BydDeviceHelper.getIntValue(eventValue)

                // Event 1151336480: HV pack voltage in decivolts (e.g., 4955 = 495.5V)
                if (eventId == 1151336480 && iVal > 2000 && iVal < 9000) {
                    val current = snapshot.get()
                    if (current != null) {
                        val volts = iVal / 10.0
                        val isFirst = current.hvPackVoltage.isNaN()
                        if (isFirst || Math.abs(current.hvPackVoltage - volts) > 0.5) {
                            snapshot.set(current.toBuilder().hvPackVoltage(volts).build())

                            if (isFirst) {
                                logger.info("HV pack voltage: " + String.format("%.1f", volts) + "V")
                            }
                        }
                    }
                }
            } catch (e: Exception) { logger.debug("onGenericCallback onDataEventChanged error: " + e.message) }
        }
    }

    /**
     * Charging device callback — captures onChargingPowerChanged directly.
     * On many BYD models, getChargingPower() returns 0 but the callback delivers
     * the real value. We store it in the snapshot for VehicleDataMonitor to pick up.
     */
    // Throttle charging power log to once per 30 seconds
    @Volatile private var lastChargingPowerLogTime = 0L
    @Volatile private var lastChargingModeLogMs = 0L
    @Volatile private var lastChargingStateRawLogMs = 0L
    // One-shot: log the raw vs scaled getExternalChargingPower value the first
    // time we successfully publish a value, so the next field log capture can
    // confirm the hectowatt vs kW scaling against the cluster's own readout.
    @Volatile private var loggedExtChargePowerScale = false

    private fun onChargingCallback(method: String, args: Array<Any?>?) {
        // Typed callbacks for real-time charging updates
        if ("onChargingGunStateChanged" == method && args != null && args.isNotEmpty()) {
            try {
                val gunState = (args[0] as Number).toInt()
                val current = snapshot.get()
                if (current != null) {
                    snapshot.set(current.toBuilder().chargingGunState(gunState).build())
                }
            } catch (e: Exception) { logger.debug("onChargingCallback onChargingGunStateChanged error: " + e.message) }
            return
        }
        // Real-time BMS state change — critical for detecting AC charging start/stop promptly
        if ("onBatteryManagementDeviceStateChanged" == method && args != null && args.isNotEmpty()) {
            try {
                val state = (args[0] as Number).toInt()
                if (state in 0..15) {
                    val current = snapshot.get()
                    if (current != null && current.chargingState != state) {
                        val previous = current.chargingState
                        snapshot.set(current.toBuilder().chargingState(state).build())
                        logger.info("BMS state changed: " + state + " (" +
                                (if (state == 0) "READY" else if (state == 1) "CHARGING" else if (state == 2) "FINISHED" else
                                 if (state == 3) "DISCHARGING" else if (state == 15) "IDLE" else "OTHER") + ")")
                        notifyChargingStateListeners(previous, state)
                    }
                    // Push edge into fused detector regardless of whether the
                    // snapshot value moved (it may already match from a poll).
                    net.bladewatch.app.monitor.ChargingDetector.getInstance().updateBmsState(state)
                }
            } catch (e: Exception) { logger.debug("onChargingCallback onBatteryManagementDeviceStateChanged error: " + e.message) }
            return
        }
        // Capacity event — purely diagnostic for charging session size, but the
        // act of receiving it confirms the charging HAL is alive on this firmware.
        if ("onChargingCapacityChanged" == method && args != null && args.isNotEmpty()) {
            try {
                val cap = (args[0] as Number).toDouble()
                if (cap > 0 && cap < 200) {
                    val current = snapshot.get()
                    if (current != null) {
                        snapshot.set(current.toBuilder().chargingCapacityKwh(cap).build())
                    }
                }
            } catch (e: Exception) { logger.debug("onChargingCallback onChargingCapacityChanged error: " + e.message) }
            return
        }
        // Handle the new-style BYDAutoEvent callbacks from ChargingDevice.
        // IMPORTANT: Do NOT blindly interpret onDataEventChanged values as charging power.
        // The ChargingDevice fires events for many different metrics (voltage, current,
        // capacity, temperature, etc.) and we cannot reliably distinguish power from other
        // values without knowing the specific event ID mapping.
        // The commander app does NOT use onDataEventChanged for power — it only uses
        // onExternalChargingPowerChanged from InstrumentDevice (see onInstrumentCallback).
        // We skip this path entirely to avoid misinterpreting non-power values as kW.
        if ("onDataEventChanged" == method && args != null && args.size >= 2) {
            // Intentionally not processing — see comment above.
            // Power comes from onExternalChargingPowerChanged (InstrumentDevice) or
            // onChargingPowerChanged (typed callback below).
            return
        }
        if ("onChargingPowerChanged" == method && args != null && args.isNotEmpty()) {
            try {
                val power = (args[0] as Number).toDouble()
                // Listener callback delivers kW directly. SDK docs: range -500 to 500 kW.
                if (Math.abs(power) > 0.1 && Math.abs(power) < 500) {
                    val current = snapshot.get()
                    if (current != null) {
                        snapshot.set(current.toBuilder().chargingPowerKw(power).build())
                        val now = System.currentTimeMillis()
                        if (now - lastChargingPowerLogTime > 30_000) {
                            lastChargingPowerLogTime = now
                            logger.info("Charging power via callback: " + String.format("%.1f", power) + " kW")
                        }
                    }
                }
            } catch (e: Exception) { logger.debug("onChargingCallback onChargingPowerChanged error: " + e.message) }
        }
        // Listener-driven: the specific event value was already captured above.
        // Skip full device re-collection — the 5s polling timer handles periodic refresh.
    }

    private fun onOtaCallback(method: String, args: Array<Any?>?) {
        if ("onBatteryPowerVoltageChanged" == method && args != null && args.isNotEmpty()) {
            try {
                val voltage = (args[0] as Number).toDouble()
                if (voltage > 0 && voltage < 20) {
                    val current = snapshot.get()
                    if (current != null) {
                        snapshot.set(current.toBuilder().voltage12v(voltage).build())
                    }
                }
            } catch (e: Exception) { logger.debug("onOtaCallback onBatteryPowerVoltageChanged error: " + e.message) }
        }
    }

    private fun onInstrumentCallback(method: String, args: Array<Any?>?) {
        // Handle the new-style BYDAutoEvent callbacks
        if ("onDataEventChanged" == method && args != null && args.size >= 2) {
            // NOTE: Do NOT blindly interpret all instrument events as charging power.
            // The instrument device fires events for trip odometer, nav data,
            // and dozens of other metrics. Only the typed onExternalChargingPowerChanged
            // callback (below) reliably delivers charging power.
            // Previously, events like INSTRUMENT_2IN1_CURRENT_JOURNEY_DRIVE_MILEAGE
            // (event 1246801948, value=18.7 km) were misinterpreted as 18.7 kW charging.
        }
        if ("onExternalChargingPowerChanged" == method && args != null && args.isNotEmpty()) {
            try {
                val power = (args[0] as Number).toDouble()
                // Listener callback delivers kW directly (SDK converts from CAN bus internally).
                if (power > 0.1 && power <= 500) {
                    val current = snapshot.get()
                    if (current != null) {
                        snapshot.set(current.toBuilder().externalChargingPowerKw(power).build())
                        val now = System.currentTimeMillis()
                        if (now - lastChargingPowerLogTime > 30_000) {
                            lastChargingPowerLogTime = now
                            logger.info("External charging power: " + String.format("%.1f", power) + " kW")
                        }
                    }
                }
            } catch (e: Exception) { logger.debug("onInstrumentCallback onExternalChargingPowerChanged error: " + e.message) }
        }
        // Listener-driven: the specific event value was already captured above.
        // Skip full device re-collection — the 5s polling timer handles periodic refresh.
    }

    private fun onLightsCallback(method: String, args: Array<Any?>?) {
        if ("onDataEventChanged" == method && args != null && args.size >= 2) {
            try {
                val eventId = (args[0] as Number).toInt()
                val eventValue = args[1]
                val iVal = BydDeviceHelper.getIntValue(eventValue)

                if (eventId == BydFeatureIds.LIGHT_DAY_RUNNING_LIGHT_AUTO_STATE && iVal in 1..2) {
                    val current = snapshot.get()
                    if (current != null) {
                        snapshot.set(current.toBuilder().dayTimeLight(iVal == 1).build())
                    }
                }
            } catch (e: Exception) { logger.debug("onLightsCallback onDataEventChanged error: " + e.message) }
        }
    }

    private fun onAdasCallback(method: String, args: Array<Any?>?) {
        if ("onDataEventChanged" == method && args != null && args.size >= 2) {
            try {
                val eventId = (args[0] as Number).toInt()
                val eventValue = args[1]
                val iVal = BydDeviceHelper.getIntValue(eventValue)

                if (eventId == BydFeatureIds.ADAS_SLW_FUNC_SWITCH_STATE && iVal in 1..2) {
                    val current = snapshot.get()
                    if (current != null) {
                        snapshot.set(current.toBuilder().speedLimitWarning(iVal == 2).build())
                    }
                }
            } catch (e: Exception) { logger.debug("onAdasCallback onDataEventChanged error: " + e.message) }
        }
    }

    private fun onSettingsCallback(method: String, args: Array<Any?>?) {
        if ("onDataEventChanged" != method || args == null || args.size < 2) return
        try {
            val eventId = (args[0] as Number).toInt()
            val iVal = BydDeviceHelper.getIntValue(args[1])
            // SDK reports 1=off, 2=low, 3=high. Anything else is unknown — ignore.
            if (iVal < 1 || iVal > 3) return

            val normalized = iVal - 1
            val current = snapshot.get() ?: return
            val b = current.toBuilder()
            val heat = if (current.seatHeat == null) IntArray(2) else current.seatHeat.clone()
            val cool = if (current.seatCool == null) IntArray(2) else current.seatCool.clone()

            if (eventId == BydFeatureIds.SET_DRIVER_SEAT_HEATING_STATE) heat[0] = normalized
            else if (eventId == BydFeatureIds.SET_DRIVER_SEAT_VENTILATING_STATE) cool[0] = normalized
            else if (eventId == BydFeatureIds.SET_PASSENGER_SEAT_HEATING_STATE) heat[1] = normalized
            else if (eventId == BydFeatureIds.SET_PASSENGER_SEAT_VENTILATING_STATE) cool[1] = normalized
            else return

            snapshot.set(b.seatHeat(heat).seatCool(cool).build())
        } catch (e: Exception) { logger.debug("onSettingsCallback onDataEventChanged error: " + e.message) }
    }

    // ==================== EXTENDED LISTENER HANDLERS ====================
    // These handler methods exist for future use. To activate, add a registerListener() call
    // in registerAllListeners() or registerBodyworkExtendedListeners() etc.

    private fun handleSteeringAngleChanged(args: Array<Any?>?) {
        if (args != null && args.isNotEmpty() && snapshot.get() != null) {
            try {
                val angle = BydDeviceHelper.getDoubleValue(args[0])
                if (!angle.isNaN() && angle >= -780 && angle <= 780) {
                    snapshot.set(snapshot.get()!!.toBuilder().steeringAngleDegrees(angle).build())
                }
            } catch (e: Exception) { logger.debug("handleSteeringAngleChanged error: " + e.message) }
        }
    }

    private fun handleAutoSystemStateChanged(args: Array<Any?>?) {
        if (args != null && args.isNotEmpty() && snapshot.get() != null) {
            try {
                val state = BydDeviceHelper.getIntValue(args[0])
                if (state in 0..2) {
                    snapshot.set(snapshot.get()!!.toBuilder().autoSystemState(state).build())
                }
            } catch (e: Exception) { logger.debug("handleAutoSystemStateChanged error: " + e.message) }
        }
    }

    private fun handleSunroofStateChanged(args: Array<Any?>?) {
        if (args != null && args.isNotEmpty() && snapshot.get() != null) {
            try {
                val state = BydDeviceHelper.getIntValue(args[0])
                if (state in 0..255) {
                    snapshot.set(snapshot.get()!!.toBuilder().sunroofState(state).build())
                }
            } catch (e: Exception) { logger.debug("handleSunroofStateChanged error: " + e.message) }
        }
    }

    private fun handleSunroofPositionChanged(args: Array<Any?>?) {
        if (args != null && args.isNotEmpty() && snapshot.get() != null) {
            try {
                val position = BydDeviceHelper.getIntValue(args[0])
                if (position in 0..100) {
                    snapshot.set(snapshot.get()!!.toBuilder().sunroofPosition(position).build())
                }
            } catch (e: Exception) { logger.debug("handleSunroofPositionChanged error: " + e.message) }
        }
    }

    /**
     * BladeWatch-62tg. This used to accept anything in 0..200 and write it straight into
     * remainKwh. That window admits the whole 0-100 percentage range, and unlike the three
     * polled sources in collectBodywork it validated nothing — so an unvalidated callback
     * could clobber a validated poll, which is exactly the last-writer-wins failure the
     * priority chain was rewritten to prevent. It now uses the same rules as every other
     * remainKwh writer.
     *
     * A percentage that happens to equal the current SoC still passes: its implied capacity is
     * ~100 kWh, a real BYD pack size, so no SoC-only rule can reject it. That case is handled
     * downstream by NominalCapacityResolver.looksLikeSocMirror rather than by teaching the
     * collector a model-specific rule here.
     */
    private fun handleChargingCapacityChanged(args: Array<Any?>?) {
        if (args != null && args.isNotEmpty() && snapshot.get() != null) {
            try {
                val capacity = BydDeviceHelper.getDoubleValue(args[0])
                if (!BydSignalRules.isPlausibleRemainKwh(capacity)) return
                val current = snapshot.get() ?: return
                if (!BydSignalRules.isRemainKwhConsistentWithSoc(capacity, current.socPercent)) {
                    logger.debug("handleChargingCapacityChanged rejected: " + capacity
                            + " kWh at " + current.socPercent + "% SOC")
                    return
                }
                snapshot.set(current.toBuilder().remainKwh(capacity).build())
            } catch (e: Exception) { logger.debug("handleChargingCapacityChanged error: " + e.message) }
        }
    }

    private fun handleDrivingTimeChanged(args: Array<Any?>?) {
        if (args != null && args.isNotEmpty() && snapshot.get() != null) {
            try {
                val hours = BydDeviceHelper.getDoubleValue(args[0])
                if (!hours.isNaN() && hours >= 0 && hours <= 10000) {
                    snapshot.set(snapshot.get()!!.toBuilder().drivingTimeHours(hours).build())
                }
            } catch (e: Exception) { logger.debug("handleDrivingTimeChanged error: " + e.message) }
        }
    }

    private fun handleKeyBatteryLevelChanged(args: Array<Any?>?) {
        if (args != null && args.isNotEmpty() && snapshot.get() != null) {
            try {
                val level = BydDeviceHelper.getIntValue(args[0])
                if (level in 0..1) {
                    snapshot.set(snapshot.get()!!.toBuilder().keyBatteryLevel(level).build())
                }
            } catch (e: Exception) { logger.debug("handleKeyBatteryLevelChanged error: " + e.message) }
        }
    }

    /**
     * Dispatcher for the typed engine listener. Routes the three known
     * device-specific callbacks to existing handle* methods, and forwards
     * unrecognised feature-ID events to the discovery logger so we can
     * extend BydFeatureIds.Engine with whatever fluid temperature IDs this
     * firmware happens to publish.
     */
    private fun onEngineCallback(method: String, args: Array<Any?>?) {
        if (args == null) return
        try {
            if ("onEngineCoolantLevelChanged" == method) {
                handleEngineCoolantLevelChanged(args)
                if (!loggedEngineCoolantEvent && args.isNotEmpty()) {
                    loggedEngineCoolantEvent = true
                    val level = BydDeviceHelper.getIntValue(args[0])
                    logger.info("Engine event FIRST: coolantLevel=" + level
                            + " (0=NORMAL,1=LOW)")
                }
                return
            }
            if ("onOilLevelChanged" == method) {
                handleOilLevelChanged(args)
                if (!loggedEngineOilEvent && args.isNotEmpty()) {
                    loggedEngineOilEvent = true
                    val level = BydDeviceHelper.getIntValue(args[0])
                    logger.info("Engine event FIRST: oilLevel=$level (0-254)")
                }
                return
            }
            if ("onEngineSpeedChanged" == method && args.isNotEmpty()) {
                val rpm = (args[0] as Number).toInt()
                if (rpm in 0..8000) {
                    val current = snapshot.get()
                    if (current != null) {
                        snapshot.set(current.toBuilder().engineSpeedRpm(rpm).build())
                    }
                }
                return
            }
            if ("onDataEventChanged" == method && args.size >= 2) {
                val eventId = (args[0] as Number).toInt()
                val eventValue = args[1]
                val rawInt = BydDeviceHelper.getIntValue(eventValue)
                val rawDbl = BydDeviceHelper.getDoubleValue(eventValue)

                // Known engine feature IDs — these are declared in
                // BYDAutoFeatureIds.Engine but the typed callbacks
                // (onEngineSpeedChanged etc.) are dormant on PHEV firmware,
                // so consume them off the generic event channel instead.
                // Apply the same sentinel filters and scaling as collectEngine.
                if (eventId == BydFeatureIds.ENGINE_SPEED
                        || eventId == BydFeatureIds.ENGINE_SPEED_ALT) {
                    // 8191 (0x1FFF) is a PHEV "engine off" sentinel observed on this
                    // firmware family; the standard BMS_UNAVAILABLE family covers the rest.
                    if (rawInt != BydFeatureIds.BMS_UNAVAILABLE
                            && rawInt != BydFeatureIds.INVALID_VALUE
                            && rawInt != BydFeatureIds.INVALID_VALUE_2
                            && rawInt != 8191
                            && rawInt in 0..8000) {
                        val current = snapshot.get()
                        if (current != null) {
                            snapshot.set(current.toBuilder().engineSpeedRpm(rawInt).build())
                        }
                    }
                    return
                }
                if (eventId == BydFeatureIds.ENGINE_POWER) {
                    // The event's intValue carries the raw CAN signal; doubleValue is
                    // typically 0.0 on the listener path. Same dual-scale heuristic as
                    // collectEngine: |raw| > 100 implies deciwatts (×0.1 → kW),
                    // otherwise treat as kW directly. Range-filter excludes sentinels.
                    val raw = if (rawInt != Int.MIN_VALUE) rawInt.toDouble() else rawDbl
                    if (!raw.isNaN() && raw >= -200.0 && raw <= 400.0) {
                        val kw = if (Math.abs(raw) > 100.0) raw * 0.1 else raw
                        // After scaling, re-check the kW range so a hectowatt value
                        // like 3095 (→ 309.5) gets rejected instead of mis-stored.
                        if (kw >= -200.0 && kw <= 400.0) {
                            // ACC OFF gating: when the key is removed, the only
                            // physically plausible engine-power direction is
                            // current INTO the pack (kw < 0, plug-in charging).
                            // Positive readings while parked are stale ECU
                            // residue or sensor noise — accepting them lets the
                            // ChargingDetector's L3 inference falsely conclude
                            // "engine is running" or wash out a real charging
                            // signal. Reject them; preserve negative values so
                            // charging-while-parked detection still works.
                            if (!accIsOn && kw > -ENGINE_POWER_CHARGING_DEADBAND) {
                                return
                            }
                            val current = snapshot.get()
                            if (current != null) {
                                snapshot.set(current.toBuilder().enginePowerKw(kw).build())
                            }
                        }
                    }
                    return
                }
                if (eventId == BydFeatureIds.ENGINE_FRONT_MOTOR_SPEED) {
                    // Front motor RPM is negated to match the cluster's display
                    // convention (forward motion = positive). Filter sentinels.
                    if (rawInt != Int.MIN_VALUE
                            && rawInt != BydFeatureIds.BMS_UNAVAILABLE
                            && rawInt != BydFeatureIds.INVALID_VALUE
                            && rawInt != BydFeatureIds.INVALID_VALUE_2
                            && Math.abs(rawInt) <= 25000) {
                        val current = snapshot.get()
                        if (current != null) {
                            snapshot.set(current.toBuilder().frontMotorSpeed(-rawInt).build())
                        }
                    }
                    return
                }
                if (eventId == BydFeatureIds.ENGINE_REAR_MOTOR_SPEED) {
                    if (rawInt != Int.MIN_VALUE
                            && rawInt != BydFeatureIds.BMS_UNAVAILABLE
                            && rawInt != BydFeatureIds.INVALID_VALUE
                            && rawInt != BydFeatureIds.INVALID_VALUE_2
                            && Math.abs(rawInt) <= 25000) {
                        val current = snapshot.get()
                        if (current != null) {
                            snapshot.set(current.toBuilder().rearMotorSpeed(rawInt).build())
                        }
                    }
                    return
                }
                if (eventId == BydFeatureIds.ENGINE_FRONT_MOTOR_TORQUE) {
                    // Negated to match cluster convention (same as collectEngine).
                    if (!rawDbl.isNaN() && Math.abs(rawDbl) <= 1000.0) {
                        val current = snapshot.get()
                        if (current != null) {
                            snapshot.set(current.toBuilder().frontMotorTorque(-rawDbl).build())
                        }
                    }
                    return
                }

                // Unknown ID — log once for discovery (capped at 32 unique IDs).
                logUnknownEngineEventOnce(eventId, rawInt, rawDbl)
            }
        } catch (e: Exception) {
            logger.debug("onEngineCallback error ($method): " + e.message)
        }
    }

    // One-shot diagnostic flags for the typed engine callbacks.
    @Volatile private var loggedEngineCoolantEvent = false
    @Volatile private var loggedEngineOilEvent = false

    // Log each unknown engine feature ID once, capped at 32 unique IDs total.
    // Engine fluids on some firmware (coolant temp, oil temp on PHEVs) arrive
    // here keyed on IDs that aren't in BYDAutoFeatureIds.Engine — surface the
    // first sighting of each so we can extend the constant table empirically.
    private val loggedUnknownEngineIds = java.util.concurrent.ConcurrentHashMap<Int, Boolean>()

    private fun logUnknownEngineEventOnce(eventId: Int, rawInt: Int, rawDbl: Double) {
        if (loggedUnknownEngineIds.size >= MAX_UNKNOWN_ENGINE_IDS) return
        if (loggedUnknownEngineIds.putIfAbsent(eventId, true) != null) return
        logger.info("Engine event UNKNOWN id=" + eventId
                + " intValue=" + (if (rawInt == Int.MIN_VALUE) "n/a" else rawInt.toString())
                + " doubleValue=" + (if (rawDbl.isNaN()) "n/a" else rawDbl.toString())
                + " — if this looks like a coolant/oil temp, add it to BydFeatureIds.Engine")
    }

    private fun handleEngineCoolantLevelChanged(args: Array<Any?>?) {
        if (args != null && args.isNotEmpty() && snapshot.get() != null) {
            try {
                val level = BydDeviceHelper.getIntValue(args[0])
                if (level in 0..1) {
                    snapshot.set(snapshot.get()!!.toBuilder().engineCoolantLevel(level).build())
                }
            } catch (e: Exception) { logger.debug("handleEngineCoolantLevelChanged error: " + e.message) }
        }
    }

    private fun handleOilLevelChanged(args: Array<Any?>?) {
        if (args != null && args.isNotEmpty() && snapshot.get() != null) {
            try {
                val level = BydDeviceHelper.getIntValue(args[0])
                if (level in 0..254) {
                    snapshot.set(snapshot.get()!!.toBuilder().oilLevel(level).build())
                }
            } catch (e: Exception) { logger.debug("handleOilLevelChanged error: " + e.message) }
        }
    }

    private fun handleSafetyBeltStatusChanged(args: Array<Any?>?) {
        if (args != null && args.isNotEmpty() && snapshot.get() != null) {
            try {
                val status = BydDeviceHelper.getIntValue(args[0])
                if (status >= 0) {
                    // Safety belt status is a bitmask — store raw value
                    // Individual seat belt states are decoded by consumers
                    snapshot.set(snapshot.get()!!.toBuilder().build())
                }
            } catch (e: Exception) { logger.debug("handleSafetyBeltStatusChanged error: " + e.message) }
        }
    }

    // ==================== VEHICLE CONTROL SETTERS ====================
    // All setters call BydDeviceHelper directly from UID 2000.
    // If a setter fails due to UID permissions, it logs the error and returns false.
    // These methods are public and always callable — no config gate needed.

    // --- Climate Control ---

    fun setAcPower(on: Boolean): Boolean {
        // Use the named start()/stop() methods on BYDAutoAcDevice — these actually
        // turn the AC system on/off. The previous implementation used AC_AUTO_MODE_SET
        // which only toggles AUTO mode (automatic climate control) without stopping the
        // AC compressor/blower. This caused "turn off" to merely disable auto mode
        // while the AC kept running in manual mode.
        //
        // Reference: BYDCarController.setAcState() calls acDevice.start(0) / acDevice.stop(0)
        // Parameter 0 = default zone (all zones).
        // Return value: 0 = success, 1 = failed, 2 = timeout, 3 = busy, 4 = invalid value
        try {
            val methodName = if (on) "start" else "stop"
            var result = BydDeviceHelper.callGetter(acDevice, methodName, 0)
            var success = result is Int && result == 0

            if (!success && result is Int) {
                val code = result
                // Retry once on BUSY (3) — AC controller may be processing a previous command
                if (code == 3) {
                    logger.info("AC $methodName returned BUSY, retrying in 500ms...")
                    Thread.sleep(500)
                    result = BydDeviceHelper.callGetter(acDevice, methodName, 0)
                    success = result is Int && result == 0
                }
                if (!success) {
                    logger.warn("AC " + methodName + " failed: result=" + result +
                        " (0=ok, 1=fail, 2=timeout, 3=busy, 4=invalid)")
                }
            }

            return success
        } catch (e: Exception) {
            logger.debug("setAcPower($on) via start/stop failed: " + e.message)
            // Fallback: try the feature ID approach (less reliable but works on some older firmware)
            return try {
                // AC_AUTO_MODE_SET with value 0 doesn't truly stop AC on most models,
                // but on some older DiLink 3.0 firmware it's the only available method.
                BydDeviceHelper.sendSetCommand(acDevice, BydFeatureIds.AC_AUTO_MODE_SET, if (on) 1 else 0)
            } catch (e2: Exception) {
                logger.debug("setAcPower fallback also failed: " + e2.message)
                false
            }
        }
    }

    // --- Screen backlight (BladeWatch-2000.3) ---

    /**
     * Wakes or dims the head unit panel via [BacklightController] — the same
     * PowerManager/BYD-hardware-service reflection `AccSentryDaemon`'s stealth panel
     * uses, shared rather than duplicated. Not vehicle telemetry, but routed through
     * `VehicleCommandRouter` like every other actuation so it gets the motion interlock
     * for free (screen OFF is gated normally; screen ON opts out via
     * `VehicleCommand#allowedWhileUnsafe`).
     */
    fun setScreenBacklight(on: Boolean): Boolean = BacklightController.setBacklight(context, on)

    fun setAcTemperature(zone: Int, tempCelsius: Double): Boolean {
        try {
            // Temperature is sent as int (degrees × 1 for most BYD models)
            val tempInt = Math.round(tempCelsius).toInt()
            if (tempInt < 17 || tempInt > 33) return false
            // SDK method: acDevice.setAcTemperature(zone, temp, 0, 1)
            val result = BydDeviceHelper.callMethod(acDevice, "setAcTemperature", zone, tempInt, 0, 1)
            return result is Int && result == 0
        } catch (e: Exception) {
            logger.debug("setAcTemperature failed: " + e.message)
            return false
        }
    }

    fun setAcFanLevel(level: Int): Boolean {
        try {
            if (level < 1 || level > 7) return false
            // SDK method: acDevice.setAcWindLevel(0, level)
            val result = BydDeviceHelper.callMethod(acDevice, "setAcWindLevel", 0, level)
            return result is Int && result == 0
        } catch (e: Exception) {
            logger.debug("setAcFanLevel failed: " + e.message)
            return false
        }
    }

    fun setMaxCooling(enabled: Boolean, hasRestore: Boolean, restoreTempCelsius: Double, restoreFanLevel: Int, restorePowerOn: Boolean): Boolean {
        var ok = true
        if (enabled) {
            ok = ok and setAcPower(true)
            ok = ok and setAcMaxCoolingState(true)
            return ok
        }

        ok = ok and setAcMaxCoolingState(false)
        // BYD's native max-cooling control should restore the previous HVAC
        // profile. Keep explicit restore best-effort for firmware that only
        // exits max-cool mode without restoring the remembered profile.
        if (hasRestore && restorePowerOn) {
            val temp = Math.max(17.0, Math.min(33.0, restoreTempCelsius))
            val fan = Math.max(1, Math.min(7, restoreFanLevel))
            ok = ok and setAcPower(true)
            setAcTemperature(1, temp)
            setAcTemperature(2, temp)
            setAcFanLevel(fan)
        }
        if (hasRestore && !restorePowerOn) ok = ok and setAcPower(false)
        return ok
    }

    fun setAcMaxCoolingState(enabled: Boolean): Boolean {
        try {
            val result = BydDeviceHelper.callMethod(acDevice, "setAcMaxCoolingState", if (enabled) 1 else 0)
            val success = result is Int && result == 0
            if (!success) {
                logger.warn("setAcMaxCoolingState($enabled) returned $result")
            }
            return success
        } catch (e: Exception) {
            logger.debug("setAcMaxCoolingState failed: " + e.message)
            return false
        }
    }

    val acMaxCoolingState: Int
        get() {
            val result = BydDeviceHelper.callGetter(acDevice, "getAcMaxCoolingState")
            return if (result is Number) result.toInt() else -1
        }

    val acWindLevel: Int
        get() {
            val result = BydDeviceHelper.callGetter(acDevice, "getAcWindLevel")
            return if (result is Number) result.toInt() else -1
        }

    fun getAcTemperature(position: Int): Int {
        val result = BydDeviceHelper.callGetter(acDevice, "getTemprature", position)
        return if (result is Number) result.toInt() else Int.MIN_VALUE
    }

    fun setAcWindMode(mode: Int): Boolean {
        try {
            // SDK method: acDevice.setAcWindMode(0, mode)
            val result = BydDeviceHelper.callMethod(acDevice, "setAcWindMode", 0, mode)
            return result is Int && result == 0
        } catch (e: Exception) {
            logger.debug("setAcWindMode failed: " + e.message)
            return false
        }
    }

    fun setFrontDefrost(on: Boolean): Boolean {
        return try {
            BydDeviceHelper.sendSetCommand(acDevice, BydFeatureIds.AC_DEFROST_FRONT_SET, if (on) 1 else 0)
        } catch (e: Exception) {
            logger.debug("setFrontDefrost failed: " + e.message)
            false
        }
    }

    fun setRearDefrost(on: Boolean): Boolean {
        return try {
            BydDeviceHelper.sendSetCommand(acDevice, BydFeatureIds.AC_DEFROST_REAR_SET, if (on) 1 else 0)
        } catch (e: Exception) {
            logger.debug("setRearDefrost failed: " + e.message)
            false
        }
    }

    fun setAcCycleMode(mode: Int): Boolean {
        return try {
            BydDeviceHelper.sendSetCommand(acDevice, BydFeatureIds.AC_CYCLE_MODE_SET, mode)
        } catch (e: Exception) {
            logger.debug("setAcCycleMode failed: " + e.message)
            false
        }
    }

    fun diagnoseAc(): org.json.JSONObject {
        val out = org.json.JSONObject()
        try {
            val device = acDevice
            out.put("acDeviceClass", if (device == null) org.json.JSONObject.NULL else device.javaClass.name)
            val methodNames = org.json.JSONArray()
            if (device != null) {
                val names = java.util.TreeSet<String>()
                for (m in device.javaClass.methods) {
                    val name = m.name
                    if (name.lowercase(java.util.Locale.US).contains("ac")
                            || name.lowercase(java.util.Locale.US).contains("temp")
                            || name.lowercase(java.util.Locale.US).contains("wind")
                            || name == "start"
                            || name == "stop") {
                        val sig = StringBuilder(name).append("(")
                        val params = m.parameterTypes
                        for (i in params.indices) {
                            if (i > 0) sig.append(",")
                            sig.append(params[i].simpleName)
                        }
                        sig.append("):").append(m.returnType.simpleName)
                        names.add(sig.toString())
                    }
                }
                for (name in names) methodNames.put(name)
            }
            out.put("methods", methodNames)

            val getters = org.json.JSONObject()
            putObjectOrNull(getters, "getAcStartState", BydDeviceHelper.callGetter(acDevice, "getAcStartState"))
            putObjectOrNull(getters, "getAcCycleMode", BydDeviceHelper.callGetter(acDevice, "getAcCycleMode"))
            putObjectOrNull(getters, "getAcWindMode", BydDeviceHelper.callGetter(acDevice, "getAcWindMode"))
            putObjectOrNull(getters, "getAcWindLevel", BydDeviceHelper.callGetter(acDevice, "getAcWindLevel"))
            putObjectOrNull(getters, "getTemperatureUnit", BydDeviceHelper.callGetter(acDevice, "getTemperatureUnit"))

            val temperatures = org.json.JSONArray()
            for (i in 0..6) {
                val item = org.json.JSONObject()
                item.put("position", i)
                putObjectOrNull(item, "value", BydDeviceHelper.callGetter(acDevice, "getTemprature", i))
                temperatures.put(item)
            }
            getters.put("getTemprature", temperatures)
            out.put("getters", getters)
        } catch (e: Exception) {
            try { out.put("error", e.message) } catch (ex: Exception) { logger.debug("diagnoseAc put error failed: " + ex.message) }
        }
        return out
    }

    // --- Windows ---
    fun setSunWindowCommand(area: Int, command: Int): Boolean {
        try {
            // area: 5=Sunroof, 6=Sunshade
            if (area < 5 || area > 6) return false
            // incoming command: 1=open, 2=close, 3=stop, 4=half, (5=breath only for sunroof)
            // Remap to these values to match windows (3 and 4 are swapped)
            // SDK command: 1=open, 2=close, 3=half, 4=stop, (5=breath only for sunroof)
            var cmdValue = command
            if (cmdValue == 3) {
                cmdValue = 4
            } else if (cmdValue == 4) {
                cmdValue = 3
            }
            // SDK method: bodyworkDevice.voiceCtlMoonRoof(cmd) or bodyworkDevice.voiceCtlSunshadePanel(cmd)
            val cmd = if (area == 5) "voiceCtlMoonRoof" else "voiceCtlSunshadePanel"
            val result = BydDeviceHelper.callMethod(bodyworkDevice, cmd, cmdValue)
            return result is Int && result == 0
        } catch (e: Exception) {
            logger.debug("Set " + (if (area == 5) "Sunroof" else "Sunshade") + " failed: " + e.message)
            return false
        }
    }

    fun setWindowCommand(area: Int, command: Int): Boolean {
        try {
            // area: 1=LF, 2=RF, 3=LR, 4=RR, 5=Sunroof, 6=Sunshade
            // command: 1=open, 2=close, 3=stop, 4=half, 5=breath
            // Sunshade and Sunroof have different command for set
            if (area in 5..6) return setSunWindowCommand(area, command)
            if (area < 1 || area > 4) return false
            // SDK method: bodyworkDevice.setAllWindowState(lf, rf, lr, rr)
            // Only the target area gets the command, others get 0
            val lf = if (area == 1) command else 0
            val rf = if (area == 2) command else 0
            val lr = if (area == 3) command else 0
            val rr = if (area == 4) command else 0
            val result = BydDeviceHelper.callMethod(bodyworkDevice, "setAllWindowState", lf, rf, lr, rr)
            return result is Int && result == 0
        } catch (e: Exception) {
            logger.debug("setWindowCommand failed: " + e.message)
            return false
        }
    }

    fun setAllWindowsCommand(command: Int): Boolean {
        try {
            // command: 1=open, 2=close, 3=stop
            // SDK method: bodyworkDevice.setAllWindowState(cmd, cmd, cmd, cmd)
            val result = BydDeviceHelper.callMethod(bodyworkDevice, "setAllWindowState", command, command, command, command)
            return result is Int && result == 0
        } catch (e: Exception) {
            logger.debug("setAllWindowsCommand failed: " + e.message)
            return false
        }
    }

    // Per-area executor so a new target on one window cancels its prior
    // motion without affecting the others. Lazy-init.
    private val windowExecutors = arrayOfNulls<java.util.concurrent.ExecutorService>(6)
    private val windowMotionTasks = arrayOfNulls<java.util.concurrent.Future<*>>(6)
    private val sideWindowExecutor: java.util.concurrent.ExecutorService =
        java.util.concurrent.Executors.newSingleThreadExecutor { r ->
            val t = Thread(r, "WinMove-AllSide")
            t.isDaemon = true
            t
        }
    private var sideWindowMotionTask: java.util.concurrent.Future<*>? = null

    @Synchronized
    private fun getWindowExecutor(areaIdx: Int): java.util.concurrent.ExecutorService {
        var ex = windowExecutors[areaIdx]
        if (ex == null) {
            ex = java.util.concurrent.Executors.newSingleThreadExecutor { r ->
                val t = Thread(r, "WinMove-" + (areaIdx + 1))
                t.isDaemon = true
                t
            }
            windowExecutors[areaIdx] = ex
        }
        return ex
    }

    private fun readWindowPercent(area: Int): Int {
        try {
            if (area == 5) {
                val sunroof = BydDeviceHelper.callGetter(bodyworkDevice, "getSunroofPosition")
                if (sunroof is Number) {
                    val value = sunroof.toInt()
                    if (value in 0..100) return value
                }
            } else if (area == 6) {
                val sunshade = BydDeviceHelper.callGet(bodyworkDevice, BydFeatureIds.BODY_SUNSHADE_PANEL_PERCENT, Integer::class.java)
                if (sunshade != null) {
                    val value = BydDeviceHelper.getIntValue(sunshade)
                    if (value in 0..100) return value
                }
            }
            val wp = BydDeviceHelper.callGetter(bodyworkDevice, "getWindowOpenPercent", area)
            if (wp is Number) {
                val value = wp.toInt()
                if (value in 0..100) return value
            }
        } catch (e: Exception) { logger.debug("readWindowPercent error: " + e.message) }
        return -1
    }

    private fun setSideWindowsCommand(lf: Int, rf: Int, lr: Int, rr: Int): Boolean {
        try {
            val result = BydDeviceHelper.callMethod(bodyworkDevice, "setAllWindowState", lf, rf, lr, rr)
            return result is Int && result == 0
        } catch (e: Exception) {
            logger.debug("setSideWindowsCommand failed: " + e.message)
            return false
        }
    }

    /**
     * Closed-loop window positioning: drives the window towards [targetPercent]
     * and stops when it reaches the target (within tolerance), the motor stalls,
     * or a safety timeout elapses. Returns immediately; motion runs on a
     * per-window background thread so a fresh target cancels the previous one.
     *
     * @param area     1=LF, 2=RF, 3=LR, 4=RR
     * @param targetPercent 0 (closed) through 100 (fully open)
     * @return true if motion was scheduled, false if inputs were invalid or
     *         the window is already at the target.
     */
    fun moveWindowToPercent(area: Int, targetPercent: Int): Boolean {
        if (area < 1 || area > 6) return false
        if (targetPercent < 0 || targetPercent > 100) return false

        // Sunroof (5) and sunshade (6) have no reliable continuous position
        // feedback on this vehicle — getSunroofPosition() reports 0 throughout
        // travel, so the closed-loop controller below mistakes "no progress" for
        // a stall and sends STOP after ~1.2 s, cutting the panel off partway.
        // These panels expose hardware one-touch commands (open/close/half) that
        // auto-drive to the end stop, so issue those directly and skip the loop.
        if (area >= 5) {
            val cmd = if (targetPercent >= 75) 1       // one-touch full open
            else if (targetPercent <= 25) 2  // one-touch full close
            else 4                            // half
            return setWindowCommand(area, cmd)
        }

        val areaIdx = area - 1

        val target = targetPercent
        // Set the tolerance to 0 when fully open or closed requested to prevent windows being slightly open
        val tolerance = if (targetPercent == 100 || targetPercent == 0) 0 else 5 // ±5 % is the realistic floor (motor coast)
        val pollIntervalMs = 200L  // SDK getter is cheap; tight loop = clean stop
        val maxRunMs = 12_000L     // window full-travel ≈ 4–6 s; cap at 12 s
        val stallWindowMs = 1_200L // no progress for this long → stall / pinch

        val initial = readWindowPercent(area)
        if (initial >= 0 && Math.abs(initial - target) <= tolerance) {
            logger.debug("Window $area already near target ($initial% vs $target%)")
            return false
        }

        // Cancel any in-flight motion for this window.
        if (area <= 4) {
            val sideTask = sideWindowMotionTask
            if (sideTask != null && !sideTask.isDone) {
                sideTask.cancel(true)
            }
        }
        val prev = windowMotionTasks[areaIdx]
        if (prev != null && !prev.isDone) prev.cancel(true)

        val task = Runnable {
            try {
                var start = readWindowPercent(area)
                if (start < 0) start = 50 // unknown — assume mid; stall-detect handles oddities

                val direction = if (target > start) 1 else 2 // 1=open, 2=close
                if (!setWindowCommand(area, direction)) {
                    logger.warn("Window $area: initial command failed")
                    return@Runnable
                }

                val startMs = System.currentTimeMillis()
                var lastProgressMs = startMs
                var lastSeenPercent = start
                var stopped = false

                while (!Thread.currentThread().isInterrupted) {
                    try {
                        Thread.sleep(pollIntervalMs)
                    } catch (e: InterruptedException) {
                        Thread.currentThread().interrupt()
                        break
                    }

                    val now = readWindowPercent(area)
                    val elapsed = System.currentTimeMillis() - startMs

                    if (now >= 0) {
                        // Stop once we've crossed the target in the direction we
                        // were moving. Crossing-based comparison avoids stopping
                        // early on a noisy reading near the boundary.
                        val reached = if (direction == 1)
                            now >= target - tolerance
                        else
                            now <= target + tolerance
                        if (reached) {
                            setWindowCommand(area, 3)
                            stopped = true
                            logger.info("Window " + area + " reached target=" + target
                                    + "% (final=" + now + "%)")
                            break
                        }

                        if (Math.abs(now - lastSeenPercent) >= 1) {
                            lastSeenPercent = now
                            lastProgressMs = System.currentTimeMillis()
                        } else if (System.currentTimeMillis() - lastProgressMs > stallWindowMs) {
                            setWindowCommand(area, 3)
                            stopped = true
                            logger.warn("Window " + area + " stalled at " + now
                                    + "% (target=" + target + "%) — stopped")
                            break
                        }
                    }

                    if (elapsed > maxRunMs) {
                        setWindowCommand(area, 3)
                        stopped = true
                        logger.warn("Window " + area + " motion timed out at "
                                + (if (now >= 0) now else -1) + "% — stopped")
                        break
                    }
                }

                if (!stopped) setWindowCommand(area, 3)
            } catch (e: Exception) {
                logger.warn("Window $area motion task error: " + e.message)
                try { setWindowCommand(area, 3) } catch (ex: Exception) { logger.debug("Window $area final stop failed: " + ex.message) }
            }
        }

        windowMotionTasks[areaIdx] = getWindowExecutor(areaIdx).submit(task)
        return true
    }

    /**
     * Closed-loop positioning for the four side windows as one SDK command
     * stream. setAllWindowState(lf, rf, lr, rr) is a four-window command, so
     * running four independent per-window loops in parallel causes each loop
     * to send zeros for the other three windows and interrupts their motion.
     */
    fun moveSideWindowsToPercent(targetPercent: Int): Boolean {
        if (targetPercent < 0 || targetPercent > 100) return false

        val target = targetPercent
        val tolerance = if (targetPercent == 100 || targetPercent == 0) 0 else 5
        val pollIntervalMs = 200L
        val maxRunMs = 12_000L
        val stallWindowMs = 1_200L

        val areas = intArrayOf(1, 2, 3, 4)
        val initial = IntArray(4)
        var needsMotion = false
        for (i in areas.indices) {
            initial[i] = readWindowPercent(areas[i])
            if (initial[i] < 0 || Math.abs(initial[i] - target) > tolerance) {
                needsMotion = true
            }
        }
        if (!needsMotion) {
            logger.debug("Side windows already near target=$target%")
            return true
        }

        val sideTask = sideWindowMotionTask
        if (sideTask != null && !sideTask.isDone) {
            sideTask.cancel(true)
        }
        for (i in 0 until 4) {
            val prev = windowMotionTasks[i]
            if (prev != null && !prev.isDone) prev.cancel(true)
        }

        val task = Runnable {
            val active = BooleanArray(4)
            val stopped = BooleanArray(4)
            val direction = IntArray(4)
            val lastSeen = IntArray(4)
            val lastProgressMs = LongArray(4)

            val startMs = System.currentTimeMillis()
            for (i in areas.indices) {
                val start = if (initial[i] >= 0) initial[i] else (if (target > 0) 0 else 50)
                lastSeen[i] = start
                lastProgressMs[i] = startMs
                if (initial[i] >= 0 && Math.abs(initial[i] - target) <= tolerance) {
                    active[i] = false
                    stopped[i] = true
                    direction[i] = 0
                } else {
                    active[i] = true
                    direction[i] = if (target > start) 1 else 2
                }
            }

            try {
                while (!Thread.currentThread().isInterrupted) {
                    val command = intArrayOf(0, 0, 0, 0)
                    var anyActive = false
                    for (i in active.indices) {
                        if (active[i]) {
                            command[i] = direction[i]
                            anyActive = true
                        } else if (!stopped[i]) {
                            command[i] = 3
                            stopped[i] = true
                        }
                    }

                    if (!anyActive) {
                        setSideWindowsCommand(command[0], command[1], command[2], command[3])
                        logger.info("Side windows reached target=$target%")
                        break
                    }

                    if (!setSideWindowsCommand(command[0], command[1], command[2], command[3])) {
                        logger.warn("Side windows target=$target% command failed")
                        break
                    }

                    try {
                        Thread.sleep(pollIntervalMs)
                    } catch (e: InterruptedException) {
                        Thread.currentThread().interrupt()
                        break
                    }

                    val nowMs = System.currentTimeMillis()
                    for (i in areas.indices) {
                        if (!active[i]) continue
                        val now = readWindowPercent(areas[i])
                        if (now < 0) continue

                        val reached = if (direction[i] == 1)
                            now >= target - tolerance
                        else
                            now <= target + tolerance
                        if (reached) {
                            active[i] = false
                            logger.info("Window " + areas[i] + " reached group target="
                                    + target + "% (final=" + now + "%)")
                        } else if (Math.abs(now - lastSeen[i]) >= 1) {
                            lastSeen[i] = now
                            lastProgressMs[i] = nowMs
                        } else if (nowMs - lastProgressMs[i] > stallWindowMs) {
                            active[i] = false
                            logger.warn("Window " + areas[i] + " stalled in group move at "
                                    + now + "% (target=" + target + "%)")
                        }
                    }

                    if (nowMs - startMs > maxRunMs) {
                        logger.warn("Side windows target=$target% timed out")
                        break
                    }
                }
            } catch (e: Exception) {
                logger.warn("Side windows motion task error: " + e.message)
            } finally {
                try { setSideWindowsCommand(3, 3, 3, 3) } catch (ex: Exception) { logger.debug("Side windows final stop failed: " + ex.message) }
            }
        }

        sideWindowMotionTask = sideWindowExecutor.submit(task)
        return true
    }

    // --- Tailgate ---

    fun openTailgate(): Boolean {
        // Method 1: SettingDevice.voiceCtlBackDoor(1) — official BYD AutoCommander method
        val sDevice = settingDevice
        if (sDevice != null) {
            try {
                val result = BydDeviceHelper.callGetter(sDevice, "voiceCtlBackDoor", 1)
                logger.info("openTailgate voiceCtlBackDoor(1) result: $result")
                if (result == null || (result is Int && result == 0)) {
                    return true
                }
            } catch (e: Exception) {
                logger.debug("openTailgate voiceCtlBackDoor failed: " + e.message)
            }
        }
        // Method 2: Bodywork BACK_DOOR_TRIGGER
        return try {
            BydDeviceHelper.sendSetCommand(bodyworkDevice, BydFeatureIds.BODY_BACK_DOOR_TRIGGER, 1)
        } catch (e: Exception) {
            logger.debug("openTailgate BACK_DOOR_TRIGGER failed: " + e.message)
            false
        }
    }

    fun closeTailgate(): Boolean {
        // SOTA FIX: Commander app uses value 3 for close via SETTING_VOICE_CTRL_BACK_DOOR_SET
        // Values: 1=open, 2=stop, 3=close (confirmed from AutoCommander decompilation)

        // Method 1: SettingDevice sendSetCommand with value 3 (close)
        val sDevice = settingDevice
        if (sDevice != null) {
            try {
                val result = BydDeviceHelper.sendSetCommand(sDevice,
                    BydFeatureIds.SETTING_VOICE_CTRL_BACK_DOOR_SET, 3)
                logger.info("closeTailgate sendSetCommand(VOICE_CTRL_BACK_DOOR, 3) result: $result")
                if (result) return true
            } catch (e: Exception) {
                logger.debug("closeTailgate sendSetCommand failed: " + e.message)
            }

            // Method 1b: Try voiceCtlBackDoor(3) directly
            try {
                val result = BydDeviceHelper.callGetter(sDevice, "voiceCtlBackDoor", 3)
                logger.info("closeTailgate voiceCtlBackDoor(3) result: $result")
                if (result == null || (result is Int && result == 0)) {
                    return true
                }
            } catch (e: Exception) {
                logger.debug("closeTailgate voiceCtlBackDoor(3) failed: " + e.message)
            }
        }

        // Method 2: Bodywork BACK_DOOR_TRIGGER with value 3 (close)
        return try {
            BydDeviceHelper.sendSetCommand(bodyworkDevice, BydFeatureIds.BODY_BACK_DOOR_TRIGGER, 3)
        } catch (e: Exception) {
            logger.debug("closeTailgate BACK_DOOR_TRIGGER(3) failed: " + e.message)
            false
        }
    }

    fun stopTailgate(): Boolean {
        // SOTA FIX: Commander app uses value 2 for stop
        // Values: 1=open, 2=stop, 3=close

        // Method 1: SettingDevice sendSetCommand with value 2 (stop)
        val sDevice = settingDevice
        if (sDevice != null) {
            try {
                val result = BydDeviceHelper.sendSetCommand(sDevice,
                    BydFeatureIds.SETTING_VOICE_CTRL_BACK_DOOR_SET, 2)
                logger.info("stopTailgate sendSetCommand(VOICE_CTRL_BACK_DOOR, 2) result: $result")
                if (result) return true
            } catch (e: Exception) {
                logger.debug("stopTailgate sendSetCommand failed: " + e.message)
            }

            // Fallback: voiceCtlBackDoor(2)
            try {
                val result = BydDeviceHelper.callGetter(sDevice, "voiceCtlBackDoor", 2)
                if (result == null || (result is Int && result == 0)) {
                    return true
                }
            } catch (e: Exception) {
                logger.debug("stopTailgate voiceCtlBackDoor(2) failed: " + e.message)
            }
        }
        return try {
            BydDeviceHelper.sendSetCommand(bodyworkDevice, BydFeatureIds.BODY_BACK_DOOR_TRIGGER, 0)
        } catch (e: Exception) {
            logger.debug("stopTailgate BACK_DOOR_TRIGGER failed: " + e.message)
            false
        }
    }

    // --- AVAS / Exterior Speaker ---

    /** Get the multimedia device (for direct access by audio test handler). */
    fun getMultimediaDevice(): Any? = multimediaDeviceValue

    /** Get the ADAS device (for direct access by `AdasFieldInventory`, read-only). */
    val adasDevice: Any?
        get() = adasDeviceValue

    /** Get exterior speaker state: 1=enabled, 0=disabled, null=unavailable or unsupported. */
    val exteriorSpeakerState: Int?
        get() {
            val device = multimediaDeviceValue ?: return null
            try {
                val m = device.javaClass.getMethod("getExteriorSpeakerState")
                val result = m.invoke(device)
                return result as? Int
            } catch (e: NoSuchMethodException) {
                return null
            } catch (e: Exception) {
                logger.debug("getExteriorSpeakerState failed: " + e.message)
                return null
            }
        }

    /** Set exterior speaker state: 1=enable, 0=disable. Returns false if unsupported on this device. */
    fun setExteriorSpeakerState(state: Int): Boolean {
        val device = multimediaDeviceValue ?: return false
        try {
            val m = device.javaClass.getMethod("setExteriorSpeakerState", Int::class.javaPrimitiveType)
            m.invoke(device, state)
            return true
        } catch (e: NoSuchMethodException) {
            logger.warn("setExteriorSpeakerState: method not present on multimedia device — exterior speaker routing unsupported on this OEM build")
            return false
        } catch (e: Exception) {
            logger.warn("setExteriorSpeakerState failed: " + e.message)
            return false
        }
    }

    /** Get AVAS sound source type. Returns null if unsupported. */
    val avasSoundSource: Int?
        get() {
            val device = multimediaDeviceValue ?: return null
            try {
                val m = device.javaClass.getMethod("getAVASSoundSource")
                val result = m.invoke(device)
                return result as? Int
            } catch (e: NoSuchMethodException) {
                return null
            } catch (e: Exception) {
                logger.debug("getAVASSoundSource failed: " + e.message)
                return null
            }
        }

    /** Set AVAS sound source type. Returns false if unsupported on this device. */
    fun setAVASSoundSource(sourceType: Int): Boolean {
        val device = multimediaDeviceValue ?: return false
        try {
            val m = device.javaClass.getMethod("setAVASSoundSource", Int::class.javaPrimitiveType)
            m.invoke(device, sourceType)
            return true
        } catch (e: NoSuchMethodException) {
            logger.warn("setAVASSoundSource: method not present on multimedia device — AVAS routing unsupported on this OEM build")
            return false
        } catch (e: Exception) {
            logger.warn("setAVASSoundSource failed: " + e.message)
            return false
        }
    }

    /**
     * Probe the multimedia device for any AVAS / exterior-speaker / outside-sound related methods.
     * Returns a list of method signatures (name + param types) whose name matches the regex.
     * Used by the audio test handler to discover what the OEM build actually exposes.
     */
    fun probeMultimediaMethods(regex: String): MutableList<String> {
        val matches = ArrayList<String>()
        val device = multimediaDeviceValue ?: return matches
        val p: java.util.regex.Pattern
        try {
            p = java.util.regex.Pattern.compile(regex, java.util.regex.Pattern.CASE_INSENSITIVE)
        } catch (e: Exception) {
            return matches
        }
        var cls: Class<*>? = device.javaClass
        while (cls != null && cls != Any::class.java) {
            for (m in cls.declaredMethods) {
                if (!p.matcher(m.name).find()) continue
                val sig = StringBuilder()
                sig.append(m.returnType.simpleName).append(' ').append(m.name).append('(')
                val params = m.parameterTypes
                for (i in params.indices) {
                    if (i > 0) sig.append(", ")
                    sig.append(params[i].simpleName)
                }
                sig.append(')')
                matches.add(sig.toString())
            }
            cls = cls.superclass
        }
        java.util.Collections.sort(matches)
        return matches
    }

    /** Check if multimedia device is available. */
    val isMultimediaAvailable: Boolean
        get() = multimediaDeviceValue != null

    // --- Charging ---
    // The Seal HAL exposes setChargeStop*/getChargeStop* methods that look like
    // they should work but: getChargeStopSupportConfig=0, getters return 0xFFFF,
    // setters silently return success-but-no-op. See
    // feedback_byd_hal_unreliable_signals. Smart-charging schedule reads/writes
    // are not available locally.

    // BEV charge-cap: BYDAutoChargingDevice.setChargeStopCapacityState (target %)
    // + setChargeStopSwitchState (master on/off). On Seal trims the
    // getChargeStopSupportConfig flag has historically returned 0, in which
    // case the framework accepts the call but doesn't apply the cap. We probe
    // by writing a target and reading it back via getChargeStopCapacityState;
    // if the read-back doesn't match, mark unsupported and the UI hides.

    @Volatile private var chargeCapProbed = false
    @Volatile private var chargeCapSupported = false

    /** Last known cap %. -1 if never probed/read. */
    val chargeCapPercent: Int
        get() {
            try {
                val v = BydDeviceHelper.callGetter(chargingDevice, "getChargeStopCapacityState")
                if (v !is Number) return -1
                val percent = v.toInt()
                if (percent in 50..100) return percent
                if (isChargeCapSentinel(percent)) {
                    chargeCapProbed = true
                    chargeCapSupported = false
                }
                return -1
            } catch (e: Exception) {
                return -1
            }
        }

    /** Last known on/off state. -1 if unsupported/read failed. */
    val chargeCapEnabled: Int
        get() {
            try {
                val v = BydDeviceHelper.callGetter(chargingDevice, "getChargeStopSwitchState")
                if (v !is Number) return -1
                val enabled = v.toInt()
                if (enabled == 0 || enabled == 1) return enabled
                if (isChargeCapSentinel(enabled)) {
                    chargeCapProbed = true
                    chargeCapSupported = false
                }
                return -1
            } catch (e: Exception) {
                return -1
            }
        }

    /**
     * Has the BEV charge-cap been observed to actually take effect on this
     * trim? null = not yet probed, true/false = result of the first write.
     * UI uses this to hide the section on no-op trims.
     */
    val isChargeCapSupported: Boolean?
        get() = if (chargeCapProbed) chargeCapSupported else null

    private fun isChargeCapSentinel(value: Int): Boolean {
        return value == 255 || value == 254
                || value == 65534 || value == 65535
                || value == BydFeatureIds.BMS_UNAVAILABLE
                || value == BydFeatureIds.INVALID_VALUE
                || value == BydFeatureIds.INVALID_VALUE_2
    }

    /**
     * Set BEV charge cap (50..100%). On the first successful write we read
     * the value back: if framework didn't honor it, flip supported=false so
     * the UI can hide. Subsequent calls short-circuit if already known to no-op.
     */
    fun setChargeCapPercent(percent: Int): Boolean {
        val device = chargingDevice
        if (device == null) {
            logger.warn("setChargeStopCapacityState: chargingDevice null")
            return false
        }
        if (percent < 50 || percent > 100) {
            logger.warn("setChargeStopCapacityState: out of range: $percent")
            return false
        }
        if (chargeCapProbed && !chargeCapSupported) {
            logger.debug("setChargeStopCapacityState: known unsupported on this trim")
            return false
        }
        try {
            val m: Method
            try {
                m = device.javaClass.getMethod("setChargeStopCapacityState", Int::class.javaPrimitiveType)
            } catch (nsme: NoSuchMethodException) {
                logger.warn("setChargeStopCapacityState not present on this firmware")
                chargeCapProbed = true; chargeCapSupported = false
                return false
            }
            val result = m.invoke(device, percent)
            val accepted = result is Int && result == 0
            if (!accepted) {
                logger.debug("setChargeStopCapacityState($percent) returned $result")
                return false
            }
            // Probe: if not yet probed, read back to confirm the value stuck.
            if (!chargeCapProbed) {
                try { Thread.sleep(150L) } catch (ie: InterruptedException) { Thread.currentThread().interrupt() }
                val readBack = chargeCapPercent
                chargeCapProbed = true
                chargeCapSupported = (readBack == percent)
                logger.info("setChargeStopCapacityState probe: wrote=" + percent
                        + " readBack=" + readBack + " supported=" + chargeCapSupported)
            }
            return chargeCapSupported
        } catch (e: Exception) {
            logger.debug("setChargeStopCapacityState failed: " + e.message)
            return false
        }
    }

    /** Set BEV charge-cap master switch (0=off, 1=on). */
    fun setChargeCapEnabled(enabled: Boolean): Boolean {
        val device = chargingDevice
        if (device == null) {
            logger.warn("setChargeStopSwitchState: chargingDevice null")
            return false
        }
        if (chargeCapProbed && !chargeCapSupported) {
            return false
        }
        try {
            val m: Method
            try {
                m = device.javaClass.getMethod("setChargeStopSwitchState", Int::class.javaPrimitiveType)
            } catch (nsme: NoSuchMethodException) {
                logger.warn("setChargeStopSwitchState not present on this firmware")
                return false
            }
            val v = if (enabled) 1 else 0
            val result = m.invoke(device, v)
            val accepted = result is Int && result == 0
            if (!accepted) {
                logger.debug("setChargeStopSwitchState($v) returned $result")
            }
            return accepted
        } catch (e: Exception) {
            logger.debug("setChargeStopSwitchState failed: " + e.message)
            return false
        }
    }

    // --- Ambient Lighting ---

    fun setAmbientLightEnabled(on: Boolean): Boolean {
        return try {
            BydDeviceHelper.sendSetCommand(lightDevice, BydFeatureIds.LIGHT_ATMOSPHERE_MAIN_SWITCH_SET, if (on) 1 else 0)
        } catch (e: Exception) {
            logger.debug("setAmbientLightEnabled failed: " + e.message)
            false
        }
    }

    fun setAmbientBrightness(level: Int): Boolean {
        return try {
            if (level < 0 || level > 100) return false
            BydDeviceHelper.sendSetCommand(lightDevice, BydFeatureIds.LIGHT_ATMOSPHERE_CUSTOM_BRIGHTNESS_SET, level)
        } catch (e: Exception) {
            logger.debug("setAmbientBrightness failed: " + e.message)
            false
        }
    }

    fun setAmbientColor(colorValue: Int): Boolean {
        return try {
            BydDeviceHelper.sendSetCommand(lightDevice, BydFeatureIds.LIGHT_ATMOSPHERE_CUSTOM_COLOR_SET, colorValue)
        } catch (e: Exception) {
            logger.debug("setAmbientColor failed: " + e.message)
            false
        }
    }

    // --- Seats ---

    fun setSeatHeating(position: Int, level: Int): Boolean {
        try {
            if (position < 1 || position > 4) return false
            if (level < 0 || level > 3) return false
            // SDK method: settingDevice.setSeatHeatingState(position, normalizedLevel)
            // Level normalization: coerceIn(level, 0, 2) + 1 → 0→1(off), 1→2(low), 2→3(high)
            val normalizedLevel = Math.min(level, 2) + 1
            val result = BydDeviceHelper.callMethod(settingDevice, "setSeatHeatingState", position, normalizedLevel)
            return result is Int && result == 0
        } catch (e: Exception) {
            logger.debug("setSeatHeating failed: " + e.message)
            return false
        }
    }

    fun setSeatVentilation(position: Int, level: Int): Boolean {
        try {
            if (position < 1 || position > 4) return false
            if (level < 0 || level > 3) return false
            // Level normalization: coerceIn(level, 0, 2) + 1 → 0→1(off), 1→2(low), 2→3(high).
            // Matches Commander's BYDCarController.normalizeSeatLevel().
            val normalizedLevel = Math.min(level, 2) + 1

            // Capability gate via BYDAutoSettingDevice.hasFeature(). The
            // canonical SDK exposes this for hardware detection — if it
            // returns DEVICE_NOT_HAS_THE_FEATURE we know the vehicle (e.g.
            // Atto 3 base trim) doesn't have ventilated seats wired and we
            // shouldn't pretend the SDK accepting the call means anything.
            // Probed once per session and cached.
            if (!seatVentFeatureProbed) {
                seatVentFeatureProbed = true
                seatVentFeatureSupported = probeHasFeature(settingDevice, "SEAT_VENTILATING")
                if (!seatVentFeatureSupported) {
                    logger.warn("Seat ventilation: hasFeature(\"SEAT_VENTILATING\") returned 0. "
                        + "Vehicle hardware lacks ventilated seats. UI should grey out the control.")
                }
            }

            // Use the canonical SDK method directly. Commander uses the same
            // call (BYDCarController.setSeatVentilationInternal at line 3017
            // of the decompile) and the BYD stub SDK at
            // android/hardware/bydauto/setting/BYDAutoSettingDevice.java only
            // defines this name. The previous "fallback chain" of
            // setSeatBlowingState / setSeatCoolingState / etc. was guesswork
            // — none of those exist in either Commander's reference or the
            // stub SDK. Removed.
            val m: Method
            try {
                m = settingDevice!!.javaClass.getMethod("setSeatVentilatingState", Int::class.javaPrimitiveType, Int::class.javaPrimitiveType)
            } catch (nsme: NoSuchMethodException) {
                logger.warn("Seat ventilation: setSeatVentilatingState not present on this firmware "
                    + "(framework-side gap, not hardware) — cannot control ventilation.")
                return false
            }
            val result = m.invoke(settingDevice, position, normalizedLevel)
            val accepted = result is Int && result == 0
            if (!accepted) {
                logger.debug("setSeatVentilatingState(" + position + ", " + normalizedLevel
                    + ") returned " + result)
                return false
            }
            // Honest result: only return true when the hardware actually
            // exists. Otherwise the SDK accepts the call but nothing happens
            // physically and the UI would mislead the user with a green
            // toast.
            return seatVentFeatureSupported
        } catch (e: Exception) {
            logger.debug("setSeatVentilation failed: " + e.message)
            return false
        }
    }

    /**
     * Recall a stored driver-side seat memory position (1 or 2).
     * SDK feature lives on settingDevice — Adas.* IDs do not accept this set.
     */
    fun setSeatMemoryPosition(position: Int): Boolean {
        try {
            if (position < 1 || position > 2) return false
            val result = BydDeviceHelper.callSetSingle(settingDevice, BydFeatureIds.SETTING_LF_MEMORY_LOCATION_WAKE_SET, position)
            return result == 0
        } catch (e: Exception) {
            logger.debug("setSeatMemoryPosition failed: " + e.message)
        }
        return false
    }

    /** Cached BYDAutoSettingDevice.hasFeature("SEAT_VENTILATING") result; probed once. */
    @Volatile private var seatVentFeatureProbed = false
    @Volatile private var seatVentFeatureSupported = false

    /**
     * Probe (and cache) whether the trim has ventilated seats. Used by the
     * vehicle-control UI to grey out the cool buttons on cars without the
     * hardware (e.g. base-trim Atto 3, Seal without comfort package).
     */
    val isSeatVentilationSupported: Boolean
        get() {
            if (!seatVentFeatureProbed) {
                seatVentFeatureProbed = true
                seatVentFeatureSupported = probeHasFeature(settingDevice, "SEAT_VENTILATING")
            }
            return seatVentFeatureSupported
        }

    /** Read-only capability probe for seat heating. */
    fun isSeatHeatingSupported(position: Int): Boolean =
        normalizeSeatGetterLevel(readSeatGetterRaw("getSeatHeatingState", position)) >= 0

    /** Read-only best-effort probe for driver seat memory recall support. */
    val isDriverSeatMemoryRecallSupported: Boolean
        get() {
            val device = settingDevice ?: return false
            val memorySet = BydDeviceHelper.callGetSingle(device, BydFeatureIds.SETTING_LF_MEMORY_LOCATION_SET)
            val memoryWake = BydDeviceHelper.callGetSingle(device, BydFeatureIds.SETTING_LF_MEMORY_LOCATION_WAKE_SET)
            return memorySet >= 0 || memoryWake >= 0
        }

    /** Read-only diagnostics used to verify trim-specific seat hardware on the actual car. */
    fun diagnoseSeatCapabilities(): org.json.JSONObject {
        val out = org.json.JSONObject()
        try {
            val device = settingDevice
            out.put("settingDeviceClass", if (device == null) org.json.JSONObject.NULL else device.javaClass.name)

            val methods = org.json.JSONObject()
            methods.put("getSeatHeatingState", hasPublicMethod(device, "getSeatHeatingState", Int::class.javaPrimitiveType!!))
            methods.put("setSeatHeatingState", hasPublicMethod(device, "setSeatHeatingState", Int::class.javaPrimitiveType!!, Int::class.javaPrimitiveType!!))
            methods.put("getSeatVentilatingState", hasPublicMethod(device, "getSeatVentilatingState", Int::class.javaPrimitiveType!!))
            methods.put("setSeatVentilatingState", hasPublicMethod(device, "setSeatVentilatingState", Int::class.javaPrimitiveType!!, Int::class.javaPrimitiveType!!))
            methods.put("hasFeature", hasPublicMethod(device, "hasFeature", String::class.java))
            out.put("methods", methods)

            val heatRaw = org.json.JSONArray()
            val heatLevel = org.json.JSONArray()
            val heatSupported = org.json.JSONArray()
            val coolRaw = org.json.JSONArray()
            val coolLevel = org.json.JSONArray()
            val coolGetterSupported = org.json.JSONArray()
            for (pos in 1..2) {
                val hr = readSeatGetterRaw("getSeatHeatingState", pos)
                val hl = normalizeSeatGetterLevel(hr)
                putIntOrNull(heatRaw, hr)
                heatLevel.put(hl)
                heatSupported.put(hl >= 0)

                val cr = readSeatGetterRaw("getSeatVentilatingState", pos)
                val cl = normalizeSeatGetterLevel(cr)
                putIntOrNull(coolRaw, cr)
                coolLevel.put(cl)
                coolGetterSupported.put(cl >= 0)
            }
            out.put("heatRaw", heatRaw)
            out.put("heatLevel", heatLevel)
            out.put("heatSupportedByGetter", heatSupported)
            out.put("coolRaw", coolRaw)
            out.put("coolLevel", coolLevel)
            out.put("coolSupportedByGetter", coolGetterSupported)

            val hasFeature = org.json.JSONObject()
            val candidates = arrayOf(
                    "SEAT_HEATING", "SEAT_VENTILATING", "SEAT_MEMORY", "SEAT_POSITION"
            )
            for (feature in candidates) {
                val value = probeHasFeatureValue(device, feature)
                putIntOrNull(hasFeature, feature, value)
            }
            out.put("hasFeature", hasFeature)

            val featureGet = org.json.JSONObject()
            putIntOrNull(featureGet, "SETTING_LF_MEMORY_LOCATION_SET",
                    BydDeviceHelper.callGetSingle(device, BydFeatureIds.SETTING_LF_MEMORY_LOCATION_SET))
            putIntOrNull(featureGet, "SETTING_LF_MEMORY_LOCATION_WAKE_SET",
                    BydDeviceHelper.callGetSingle(device, BydFeatureIds.SETTING_LF_MEMORY_LOCATION_WAKE_SET))
            putIntOrNull(featureGet, "SET_DRIVER_SEAT_HEATING_STATE",
                    BydDeviceHelper.callGetSingle(device, BydFeatureIds.SET_DRIVER_SEAT_HEATING_STATE))
            putIntOrNull(featureGet, "SET_DRIVER_SEAT_VENTILATING_STATE",
                    BydDeviceHelper.callGetSingle(device, BydFeatureIds.SET_DRIVER_SEAT_VENTILATING_STATE))
            putIntOrNull(featureGet, "SET_PASSENGER_SEAT_HEATING_STATE",
                    BydDeviceHelper.callGetSingle(device, BydFeatureIds.SET_PASSENGER_SEAT_HEATING_STATE))
            putIntOrNull(featureGet, "SET_PASSENGER_SEAT_VENTILATING_STATE",
                    BydDeviceHelper.callGetSingle(device, BydFeatureIds.SET_PASSENGER_SEAT_VENTILATING_STATE))
            out.put("featureGet", featureGet)

            val supported = org.json.JSONObject()
            supported.put("driverHeat", isSeatHeatingSupported(1))
            supported.put("passengerHeat", isSeatHeatingSupported(2))
            supported.put("driverCool", isSeatVentilationSupported)
            supported.put("passengerCool", isSeatVentilationSupported)
            supported.put("driverMemoryRecall", isDriverSeatMemoryRecallSupported)
            out.put("supported", supported)
        } catch (e: Exception) {
            try {
                out.put("error", e.message)
            } catch (ignored: Exception) {
                // Keep diagnostics best-effort.
            }
        }
        return out
    }

    private fun readSeatGetterRaw(methodName: String, position: Int): Int {
        if (position < 1 || position > 2) return Int.MIN_VALUE
        val value = BydDeviceHelper.callGetter(settingDevice, methodName, position)
        return if (value is Number) value.toInt() else Int.MIN_VALUE
    }

    private fun normalizeSeatGetterLevel(raw: Int): Int = BydSignalRules.normalizeSeatGetterLevel(raw)

    // --- Lights ---

    fun setDayTimeLight(enable: Boolean): Boolean {
        try {
            val result = BydDeviceHelper.callMethod(lightDevice, "setDayTimeLightState", if (enable) 1 else 2)
            return result is Int && result == 0
        } catch (e: Exception) {
            logger.debug("setDayTimeLight failed: " + e.message)
        }
        return false
    }

    // --- ADAS ---

    fun setSpeedLimitWarning(enable: Boolean): Boolean {
        try {
            val result = BydDeviceHelper.callSetSingle(adasDeviceValue, BydFeatureIds.ADAS_SLW_FUNC_SWITCH_STATE_SET, if (enable) 2 else 1)
            return result == 0
        } catch (e: Exception) {
            logger.debug("setSpeedLimitWarning failed: " + e.message)
        }
        return false
    }

    fun setFcwLevel(level: Int): Boolean {
        return try {
            BydDeviceHelper.sendSetCommand(settingDevice, BydFeatureIds.ADAS_FCW_LEVEL_SET, level)
        } catch (e: Exception) {
            logger.debug("setFcwLevel failed: " + e.message)
            false
        }
    }

    fun setLaneAssistMode(mode: Int): Boolean {
        return try {
            BydDeviceHelper.sendSetCommand(settingDevice, BydFeatureIds.ADAS_ELKA_SWITCH_SET, mode)
        } catch (e: Exception) {
            logger.debug("setLaneAssistMode failed: " + e.message)
            false
        }
    }

    fun setBlindSpotDetection(enabled: Boolean): Boolean {
        return try {
            BydDeviceHelper.sendSetCommand(settingDevice, BydFeatureIds.ADAS_DOW_STATE_SET, if (enabled) 1 else 0)
        } catch (e: Exception) {
            logger.debug("setBlindSpotDetection failed: " + e.message)
            false
        }
    }

    fun setEmergencyBraking(enabled: Boolean): Boolean {
        return try {
            BydDeviceHelper.sendSetCommand(settingDevice, BydFeatureIds.ADAS_ECTB_STATE_SET, if (enabled) 1 else 0)
        } catch (e: Exception) {
            logger.debug("setEmergencyBraking failed: " + e.message)
            false
        }
    }

    fun setRearCrossTrafficAlert(enabled: Boolean): Boolean {
        return try {
            BydDeviceHelper.sendSetCommand(settingDevice, BydFeatureIds.ADAS_RCTA_STATE_SET, if (enabled) 1 else 0)
        } catch (e: Exception) {
            logger.debug("setRearCrossTrafficAlert failed: " + e.message)
            false
        }
    }

    fun setFrontCrossTrafficAlert(enabled: Boolean): Boolean {
        return try {
            BydDeviceHelper.sendSetCommand(settingDevice, BydFeatureIds.ADAS_FCTA_SWITCH_SET, if (enabled) 1 else 0)
        } catch (e: Exception) {
            logger.debug("setFrontCrossTrafficAlert failed: " + e.message)
            false
        }
    }

    fun setFrontCrossTrafficBraking(enabled: Boolean): Boolean {
        return try {
            BydDeviceHelper.sendSetCommand(settingDevice, BydFeatureIds.ADAS_FCTB_SWITCH_SET, if (enabled) 1 else 0)
        } catch (e: Exception) {
            logger.debug("setFrontCrossTrafficBraking failed: " + e.message)
            false
        }
    }

    fun setSpeedLimitRecognition(enabled: Boolean): Boolean {
        return try {
            BydDeviceHelper.sendSetCommand(settingDevice, BydFeatureIds.ADAS_SLR_STATUS_SET, if (enabled) 1 else 0)
        } catch (e: Exception) {
            logger.debug("setSpeedLimitRecognition failed: " + e.message)
            false
        }
    }

    fun setTrafficLightAttention(enabled: Boolean): Boolean {
        return try {
            BydDeviceHelper.sendSetCommand(settingDevice, BydFeatureIds.ADAS_TLA_SWITCH_SET, if (enabled) 1 else 0)
        } catch (e: Exception) {
            logger.debug("setTrafficLightAttention failed: " + e.message)
            false
        }
    }

    fun setOpenDoorWarning(enabled: Boolean): Boolean {
        return try {
            BydDeviceHelper.sendSetCommand(settingDevice, BydFeatureIds.ADAS_DOW_STATE_SET, if (enabled) 1 else 0)
        } catch (e: Exception) {
            logger.debug("setOpenDoorWarning failed: " + e.message)
            false
        }
    }

    fun setRearCollisionWarning(enabled: Boolean): Boolean {
        return try {
            BydDeviceHelper.sendSetCommand(settingDevice, BydFeatureIds.ADAS_RCW_STATE_SET, if (enabled) 1 else 0)
        } catch (e: Exception) {
            logger.debug("setRearCollisionWarning failed: " + e.message)
            false
        }
    }

    fun setEspState(enabled: Boolean): Boolean {
        return try {
            BydDeviceHelper.sendSetCommand(settingDevice, BydFeatureIds.ADAS_ESP_STATE_SET, if (enabled) 1 else 0)
        } catch (e: Exception) {
            logger.debug("setEspState failed: " + e.message)
            false
        }
    }

    fun setIslaSwitch(enabled: Boolean): Boolean {
        return try {
            BydDeviceHelper.sendSetCommand(settingDevice, BydFeatureIds.ADAS_ISLA_SWITCH_SET, if (enabled) 1 else 0)
        } catch (e: Exception) {
            logger.debug("setIslaSwitch failed: " + e.message)
            false
        }
    }

    fun setIslcSwitch(enabled: Boolean): Boolean {
        return try {
            BydDeviceHelper.sendSetCommand(settingDevice, BydFeatureIds.ADAS_ISLC_SWITCH_SET, if (enabled) 1 else 0)
        } catch (e: Exception) {
            logger.debug("setIslcSwitch failed: " + e.message)
            false
        }
    }

    // --- Media ---

    /**
     * Send media info (artist + title) to the instrument cluster display.
     * Encodes the string as UTF-16LE bytes for the BYD instrument cluster.
     */
    fun sendMediaInfo(artistAndTitle: String?): Boolean {
        try {
            if (artistAndTitle == null) return false
            val formatted = "  $artistAndTitle  "
            val bytes = formatted.toByteArray(charset("UTF-16LE"))
            val finalBytes: ByteArray
            if (bytes.size > 255) {
                // Truncate to 253 bytes + 2-byte null terminator
                finalBytes = ByteArray(255)
                System.arraycopy(bytes, 0, finalBytes, 0, 253)
                finalBytes[253] = 0
                finalBytes[254] = 0
            } else {
                finalBytes = bytes
            }
            val result = BydDeviceHelper.callSetBuffer(instrumentDevice, 1140527112, finalBytes)
            return result >= 0
        } catch (e: Exception) {
            logger.debug("sendMediaInfo failed: " + e.message)
            return false
        }
    }

    fun setMusicSource(source: Int): Boolean {
        return try {
            if (source < 0 || source > 14) return false
            BydDeviceHelper.sendSetCommand(instrumentDevice, BydFeatureIds.INSTRUMENT_MUSIC_SOURCE_SET, source)
        } catch (e: Exception) {
            logger.debug("setMusicSource failed: " + e.message)
            false
        }
    }

    fun setMusicState(state: Int): Boolean {
        return try {
            if (state < 1 || state > 2) return false
            BydDeviceHelper.sendSetCommand(instrumentDevice, BydFeatureIds.INSTRUMENT_MUSIC_STATE_SET, state)
        } catch (e: Exception) {
            logger.debug("setMusicState failed: " + e.message)
            false
        }
    }

    fun setMusicPlaybackProgress(currentSeconds: Int, totalSeconds: Int): Boolean {
        return try {
            if (currentSeconds < 0 || totalSeconds < 0) return false
            // Pack current and total into the feature ID call
            // Progress is sent as a single int: current seconds (the cluster calculates percentage)
            BydDeviceHelper.sendSetCommand(instrumentDevice, BydFeatureIds.INSTRUMENT_MUSIC_PLAYBACK_PROGRESS_SET, currentSeconds)
        } catch (e: Exception) {
            logger.debug("setMusicPlaybackProgress failed: " + e.message)
            false
        }
    }

    // --- Display ---

    fun setInfotainmentBrightness(level: Int): Boolean {
        return try {
            if (level < 0 || level > 100) return false
            BydDeviceHelper.sendSetCommand(settingDevice, BydFeatureIds.SETTING_BRIGHTNESS_GEAR_SET, level)
        } catch (e: Exception) {
            logger.debug("setInfotainmentBrightness failed: " + e.message)
            false
        }
    }

    fun setDriverDisplayBrightness(level: Int): Boolean {
        return try {
            if (level < 0 || level > 100) return false
            // Driver display brightness uses the same feature ID — the instrument cluster
            // adjusts both displays together on most BYD models
            BydDeviceHelper.sendSetCommand(settingDevice, BydFeatureIds.SETTING_BRIGHTNESS_GEAR_SET, level)
        } catch (e: Exception) {
            logger.debug("setDriverDisplayBrightness failed: " + e.message)
            false
        }
    }

    fun setHudBrightness(level: Int): Boolean {
        return try {
            if (level < 0 || level > 100) return false
            BydDeviceHelper.sendSetCommand(settingDevice, BydFeatureIds.SETTING_BRIGHTNESS_GEAR_SET, level)
        } catch (e: Exception) {
            logger.debug("setHudBrightness failed: " + e.message)
            false
        }
    }

    // --- Miscellaneous ---

    fun setMirrorsFolded(folded: Boolean): Boolean {
        return try {
            BydDeviceHelper.sendSetCommand(bodyworkDevice, BydFeatureIds.MIRROR_REARVIEW_SET, if (folded) 1 else 0)
        } catch (e: Exception) {
            logger.debug("setMirrorsFolded failed: " + e.message)
            false
        }
    }

    fun setChildLock(left: Boolean, enable: Boolean): Boolean {
        return try {
            val featureId = if (left) BydFeatureIds.DOORLOCK_CHILDLOCK_LEFT_SET else BydFeatureIds.DOORLOCK_CHILDLOCK_RIGHT_SET
            BydDeviceHelper.sendSetCommand(doorLockDevice, featureId, if (enable) 1 else 0)
        } catch (e: Exception) {
            logger.debug("setChildLock failed: " + e.message)
            false
        }
    }

    fun setWirelessCharging(enabled: Boolean): Boolean {
        return try {
            BydDeviceHelper.sendSetCommand(chargingDevice, BydFeatureIds.CHARGING_WIRELESS_SWITCH_SET, if (enabled) 1 else 0)
        } catch (e: Exception) {
            logger.debug("setWirelessCharging failed: " + e.message)
            false
        }
    }

    fun wakeUpMcu(): Boolean {
        return try {
            val result = BydDeviceHelper.callGetter(powerDevice, "wakeUpMcu")
            result is Number && result.toInt() >= 0
        } catch (e: Exception) {
            logger.debug("wakeUpMcu failed: " + e.message)
            false
        }
    }

    fun rotatePad(): Boolean {
        return try {
            BydDeviceHelper.sendSetCommand(settingDevice, BydFeatureIds.SETTING_PAD_ROTATION_SET, 1)
        } catch (e: Exception) {
            logger.debug("rotatePad failed: " + e.message)
            false
        }
    }

    fun setDriftMode(enabled: Boolean): Boolean {
        return try {
            BydDeviceHelper.sendSetCommand(engineDevice, BydFeatureIds.ENGINE_DRIFT_MODE_SWITCH_CONFIG, if (enabled) 1 else 0)
        } catch (e: Exception) {
            logger.debug("setDriftMode failed: " + e.message)
            false
        }
    }

    fun setNavigationActive(active: Boolean): Boolean {
        return try {
            BydDeviceHelper.sendSetCommand(instrumentDevice, BydFeatureIds.INSTRUMENT_NAVIGATION_ACTIVATED_SET, if (active) 1 else 0)
        } catch (e: Exception) {
            logger.debug("setNavigationActive failed: " + e.message)
            false
        }
    }

    fun setNavigationETA(minutes: Int): Boolean {
        return try {
            if (minutes < 0) return false
            BydDeviceHelper.sendSetCommand(instrumentDevice, BydFeatureIds.INSTRUMENT_NAVI_ESTIMATED_TIME_SET, minutes)
        } catch (e: Exception) {
            logger.debug("setNavigationETA failed: " + e.message)
            false
        }
    }

    fun setNavigationDistance(meters: Int): Boolean {
        return try {
            if (meters < 0) return false
            BydDeviceHelper.sendSetCommand(instrumentDevice, BydFeatureIds.INSTRUMENT_NAVI_ESTIMATED_MILEAGE_SET, meters)
        } catch (e: Exception) {
            logger.debug("setNavigationDistance failed: " + e.message)
            false
        }
    }

    /**
     * Log a summary of all current values (for debugging).
     */
    fun logSummary() {
        val d = snapshot.get()
        if (d == null) {
            logger.info("No data collected yet")
            return
        }
        logger.info("=== BYD Vehicle Data Summary ===")
        if (d.vin != null) logger.info("  VIN: " + d.vin)
        if (!d.socPercent.isNaN()) logger.info("  SOC: " + d.socPercent + "%")
        else logger.warn("  SOC: UNAVAILABLE (statistic/energy devices returned blank)")
        if (!d.voltage12v.isNaN()) logger.info("  12V: " + d.voltage12v + "V")
        if (!d.remainKwh.isNaN()) logger.info("  Remaining: " + d.remainKwh + " kWh")
        if (!d.speedKmh.isNaN()) logger.info("  Speed: " + d.speedKmh + " km/h")
        if (d.gearMode != BydVehicleData.UNAVAILABLE) logger.info("  Gear: " + d.gearMode)
        if (d.totalMileageKm != BydVehicleData.UNAVAILABLE) logger.info("  Odometer: " + d.totalMileageKm + " km")
        if (d.elecRangeKm != BydVehicleData.UNAVAILABLE) logger.info("  EV Range: " + d.elecRangeKm + " km")
        if (!d.highCellTempC.isNaN()) logger.info("  Cell Temp: " + d.highCellTempC + "/" + d.lowCellTempC + "/" + d.avgCellTempC + "°C")
        if (!d.highCellVoltage.isNaN()) logger.info("  Cell Voltage: " + d.highCellVoltage + "/" + d.lowCellVoltage + "V")
        if (!d.outsideTempC.isNaN()) logger.info("  Outside: " + d.outsideTempC + "°C")
        if (d.tyrePressure != null) logger.info("  Tyres: FL=" + d.tyrePressure[0] + " FR=" + d.tyrePressure[1] + " RL=" + d.tyrePressure[2] + " RR=" + d.tyrePressure[3])
        if (d.powerLevel != BydVehicleData.UNAVAILABLE) logger.info("  Power Level: " + d.powerLevel)
        logger.info("  Devices: " + d.availableDevices!!.size + " available")
        logger.info("================================")
    }

    companion object {
        private const val TAG = "BydDataCollector"
        private val logger = DaemonLogger.getInstance(TAG)

        // Door-lock API contract used by /api/vehicle/state.
        // BYD SDK reports 1=unlock and 2=lock; the web API historically exposes
        // 1=locked and 2=unlocked, so collection converts at the boundary.
        private const val LOCK_API_UNKNOWN = -1

        @Volatile private var instance: BydDataCollector? = null

        @JvmStatic
        @Synchronized
        fun getInstance(): BydDataCollector {
            instance?.let { return it }
            val created = BydDataCollector()
            instance = created
            return created
        }

        private const val MILES_TO_KM = 1.60934

        private const val POLL_INTERVAL_MS = 5000L // 5 seconds when ACC on
        private const val POLL_INTERVAL_PARKED_MS = 90000L // 90 seconds when ACC off — listener callbacks keep the snapshot fresh between polls

        private const val MIN_COLLECT_INTERVAL_MS = 5000L // 5 seconds

        /**
         * Threshold below which a post-ACC-OFF engine-power reading is treated
         * as plausible "current flowing into pack" (plug-in charging) rather
         * than ECU residue. Values more positive than this (above the deadband)
         * are rejected when accIsOn==false because the ICE cannot be running
         * with the key removed — those readings are stale/noisy.
         */
        private const val ENGINE_POWER_CHARGING_DEADBAND = 0.3

        private const val DEV_TYRE = 0
        private const val DEV_INSTRUMENT = 1
        private val TYRE_DEVICE_SLOTS = intArrayOf(1, 2, 3, 4) // identity
        private val INSTRUMENT_DEVICE_SLOTS = intArrayOf(3, 1, 4, 2) // FL=slot3, FR=slot1, RL=slot4, RR=slot2
        private val TYRE_TEMP_CANDIDATES = arrayOf(
                // Instrument-side first: confirmed to return real per-corner °C
                // on firmwares where every tyreDevice candidate returns null.
                TyreTempCandidate(DEV_INSTRUMENT, "getWheelTemperature", INSTRUMENT_DEVICE_SLOTS),
                // tyreDevice fallbacks — order preserves prior behaviour.
                TyreTempCandidate(DEV_TYRE, "getTyreBatteryValue", TYRE_DEVICE_SLOTS),
                TyreTempCandidate(DEV_TYRE, "getTyreTemperatureValue", TYRE_DEVICE_SLOTS),
                TyreTempCandidate(DEV_TYRE, "getTyreTemperature", TYRE_DEVICE_SLOTS),
                TyreTempCandidate(DEV_TYRE, "getTyreTemperatureState", TYRE_DEVICE_SLOTS)
        )
        // null = not resolved yet (first cycle still running),
        // != null and != NO_TYRE_TEMP_GETTER = the resolved Method,
        // == NO_TYRE_TEMP_GETTER sentinel = no candidate exists on this firmware.
        private val NO_TYRE_TEMP_GETTER: Method = Any::class.java.getDeclaredMethod("toString")
        private const val TYRE_TEMP_OUT_OF_RANGE_THRESHOLD = 5 // after 5 bad reads, try next

        private const val MAX_UNKNOWN_TYRE_IDS = 32
        private const val MAX_UNKNOWN_ENGINE_IDS = 32

        // 0=unknown, 1=BEV, 2=PHEV/HEV
        internal const val DRIVETRAIN_UNKNOWN = 0
        internal const val DRIVETRAIN_BEV = 1
        internal const val DRIVETRAIN_PHEV = 2
        /** PHEV, but held on a short TTL so a transient HAL miss re-probes in seconds. */
        internal const val DRIVETRAIN_PHEV_PROVISIONAL = 3
        private const val DRIVETRAIN_REPROBE_MS = 60_000L

        /**
         * A known nominal pack strictly below this is a PHEV pack, full stop. The smallest BYD
         * BEV is the Atto 3 at 49.9 kWh, so sub-30 kWh uniquely names a PHEV across the
         * catalogue and the inverse risk is about zero.
         *
         * Inherited from Overdrive and NOT re-derived on this car. The same rule also lives in
         * `VehicleDataMonitor.isPhevVehicle`, where it serves a different caller as a
         * startup fallback; if one moves, move both.
         */
        const val PHEV_MAX_NOMINAL_KWH = 30.0

        /**
         * Positions for `BYDAutoAcDevice.getTemprature(int)` (BYD's spelling).
         *
         * Measured on the head unit 2026-09-20 via GetAcDiagnostics, AC off, car parked, all
         * three zones set to 24 and the cabin hot:
         *
         *     0 -> -2147482645   1 -> 24   2 -> 24   3 -> 24   4 -> 36   5,6 -> -2147482645
         *
         * 1/2/3 are the per-zone SETPOINTS and 4 is the CABIN sensor. This mattered: both the
         * setpoint and "inside temperature" used to be read from position 1, so the Vehicle
         * screen reported the driver's chosen temperature as the cabin reading and it never
         * moved off the stepper value (BladeWatch-gkjl).
         *
         * -2147482645 is `Int.MIN_VALUE + 1003`, the SDK's "unavailable" sentinel; both range
         * guards below reject it.
         *
         * Position 4 is not the OUTSIDE temperature — that comes from a different device
         * entirely, `instrumentDevice.getOutCarTemperature()`, in [collectInstrument].
         */
        const val AC_TEMP_POS_SETPOINT = 1
        const val AC_TEMP_POS_CABIN = 4

        /** Plausible setpoint range. Narrow on purpose — the BYD climate UI cannot leave it. */
        val AC_SETPOINT_RANGE_C = 16..35

        /**
         * Plausible cabin range. Deliberately much wider than the setpoint range: a closed car
         * in direct sun readily passes 60C, so the old -50..60 guard would have discarded a
         * real reading on exactly the days the number matters most.
         */
        val CABIN_TEMP_RANGE_C = -50..90

        /**
         * Pure drivetrain decision, split out from [computeIsPhev] so the ORDER of the
         * rules can be tested without a HAL device (BladeWatch-fpdz.1).
         *
         * **Capacity is consulted FIRST and that is the whole point.** The fuel HAL returns
         * BMS sentinels during firmware warm-up, so on a PHEV that has not finished booting both
         * signals read as sentinel, the both-sentinel rule concludes BEV, and the caller caches
         * that for a full minute. Overdrive shipped exactly that regression in v17 and fixed it
         * by putting the capacity gate ahead of the probes. A known pack size is simply stronger
         * evidence than a signal that is allowed to lie while it warms up.
         *
         * @param nominalKwh known nominal pack capacity, or 0/NaN when unknown
         * @return one of the DRIVETRAIN_* constants
         */
        @JvmStatic
        internal fun decideDrivetrain(nominalKwh: Double, fuelPctReal: Boolean, fuelRangeReal: Boolean,
                                       fuelPctSentinel: Boolean, fuelRangeSentinel: Boolean): Int {
            // Tier 0 -- capacity. Strongest signal, and immune to the warm-up sentinel problem.
            if (!nominalKwh.isNaN() && nominalKwh > 0 && nominalKwh < PHEV_MAX_NOMINAL_KWH) {
                return DRIVETRAIN_PHEV
            }
            // Both fuel signals agree there is a fuel system.
            if (fuelPctReal && fuelRangeReal) {
                return DRIVETRAIN_PHEV
            }
            // Both at sentinel: no fuel system.
            if (fuelPctSentinel && fuelRangeSentinel) {
                return DRIVETRAIN_BEV
            }
            // One real + one sentinel: PHEV with an empty tank or zero range.
            if ((fuelPctReal && fuelRangeSentinel) || (fuelRangeReal && fuelPctSentinel)) {
                return DRIVETRAIN_PHEV_PROVISIONAL
            }
            return DRIVETRAIN_UNKNOWN
        }

        private fun hasPublicMethod(target: Any?, methodName: String, vararg parameterTypes: Class<*>): Boolean {
            if (target == null) return false
            return try {
                target.javaClass.getMethod(methodName, *parameterTypes)
                true
            } catch (e: Exception) {
                false
            }
        }

        /**
         * Capability probe via BYDAutoSettingDevice.hasFeature(String).
         * Returns DEVICE_HAS_THE_FEATURE (1) on supported vehicles per the
         * canonical SDK. Treat any result == 1 as supported.
         */
        private fun probeHasFeature(settingDevice: Any?, feature: String?): Boolean {
            if (settingDevice == null || feature == null) return false
            return try {
                val m = settingDevice.javaClass.getMethod("hasFeature", String::class.java)
                val result = m.invoke(settingDevice, feature)
                if (result is Number) {
                    result.toInt() == 1
                } else {
                    false
                }
            } catch (e: Exception) {
                false
            }
        }

        private fun probeHasFeatureValue(settingDevice: Any?, feature: String?): Int {
            if (settingDevice == null || feature == null) return Int.MIN_VALUE
            return try {
                val m = settingDevice.javaClass.getMethod("hasFeature", String::class.java)
                val result = m.invoke(settingDevice, feature)
                if (result is Number) result.toInt() else Int.MIN_VALUE
            } catch (e: Exception) {
                Int.MIN_VALUE
            }
        }

        private fun putIntOrNull(array: org.json.JSONArray, value: Int) {
            array.put(if (value == Int.MIN_VALUE || value < 0) org.json.JSONObject.NULL else value)
        }

        private fun putIntOrNull(obj: org.json.JSONObject, key: String, value: Int) {
            obj.put(key, if (value == Int.MIN_VALUE || value < 0) org.json.JSONObject.NULL else value)
        }

        private fun putObjectOrNull(obj: org.json.JSONObject, key: String, value: Any?) {
            obj.put(key, value ?: org.json.JSONObject.NULL)
        }

        private fun fmtKeyVal(v: Int): String = if (v == BydVehicleData.UNAVAILABLE) "n/a" else v.toString()

        private fun fmtFluid(v: Int?): String = v?.toString() ?: "n/a"
    }
}
