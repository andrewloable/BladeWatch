package net.bladewatch.app.telemetry

import android.content.Context
import android.content.ContextWrapper
import android.content.pm.PackageManager
import net.bladewatch.app.logging.DaemonLogger
import java.lang.reflect.Method
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

/**
 * Polls BYD device APIs at 5 Hz via reflection to collect vehicle telemetry, producing immutable
 * [TelemetrySnapshot] objects for the overlay renderer. Every field falls back to its
 * last-known-good value when a device call fails.
 */
class TelemetryDataCollector {

    // BYDAutoSpeedDevice
    private var speedDevice: Any? = null
    private var getCurrentSpeedMethod: Method? = null
    private var getAccelerateDeepnessMethod: Method? = null
    private var getBrakeDeepnessMethod: Method? = null

    // BYDAutoGearboxDevice
    private var gearboxDevice: Any? = null
    private var getGearboxAutoModeTypeMethod: Method? = null
    private var getBrakePedalStateMethod: Method? = null

    // Turn signals via getTurnLightFlashState(): 0=off, 1=left, 2=right, 3=hazard (model-dependent)
    private var lightDevice: Any? = null
    private var getTurnLightFlashStateMethod: Method? = null

    // Seatbelt via BYDAutoInstrumentDevice.getSafetyBeltStatus(int);
    // fallback BYDAutoSafetyBeltDevice.getPassengerStatus(int)
    private var safetyBeltDevice: Any? = null
    private var getPassengerStatusMethod: Method? = null
    private var instrumentDeviceForBelt: Any? = null
    private var getSafetyBeltStatusMethod: Method? = null

    // Seatbelt alarm, discovered at runtime
    private var seatbeltAlarmDevice: Any? = null
    private var seatbeltAlarmMethod: Method? = null
    private var savedContext: Context? = null

    private var executor: ScheduledExecutorService? = null

    @Volatile
    private var latestSnapshot: TelemetrySnapshot? = null

    /** True polls at 200ms (5Hz) for the overlay; false at 1000ms (1Hz) for trip telemetry. */
    @Volatile
    private var overlayRecordingActive = false

    /** Polling stays alive while any consumer needs it — pipeline overlay, trip recorder, etc. */
    private val pollingRefCount = AtomicInteger(0)

    // Last-known-good values, used when a device call fails.
    private var lastSpeedKmh = 0
    private var lastAccelPercent = 0
    private var lastBrakePercent = 0
    private var staleSpeedCount = 0
    private var prevSpeedForStaleCheck = -1
    private var lastBrakePedalPressed = false
    private var lastGearMode = 1 // P
    private var lastLeftTurn = false
    private var lastRightTurn = false
    private var lastSeatbelts = booleanArrayOf(true, true) // buckled by default
    private var pollCount = 0L
    private var leftTurnStickyCount = 0
    private var rightTurnStickyCount = 0

    /**
     * Initialise BYD device handles by reflection through [PermissionBypassContext].
     *
     * Each device initialises independently: one failure must not take the others with it, since
     * a car missing one subsystem should still show everything else.
     */
    fun init(context: Context) {
        logger.info("Initializing telemetry device access...")

        val permissiveContext: Context = PermissionBypassContext(context)
        savedContext = permissiveContext

        try {
            val cls = Class.forName("android.hardware.bydauto.speed.BYDAutoSpeedDevice")
            speedDevice = cls.getMethod("getInstance", Context::class.java)
                .invoke(null, permissiveContext)
            getCurrentSpeedMethod = cls.getMethod("getCurrentSpeed")
            getAccelerateDeepnessMethod = cls.getMethod("getAccelerateDeepness")
            getBrakeDeepnessMethod = cls.getMethod("getBrakeDeepness")
            logger.info("BYDAutoSpeedDevice initialized")
        } catch (e: Exception) {
            logger.warn("BYDAutoSpeedDevice unavailable: " + e.message)
        }

        try {
            val cls = Class.forName("android.hardware.bydauto.gearbox.BYDAutoGearboxDevice")
            gearboxDevice = cls.getMethod("getInstance", Context::class.java)
                .invoke(null, permissiveContext)
            getGearboxAutoModeTypeMethod = cls.getMethod("getGearboxAutoModeType")
            getBrakePedalStateMethod = cls.getMethod("getBrakePedalState")
            logger.info("BYDAutoGearboxDevice initialized")
        } catch (e: Exception) {
            logger.warn("BYDAutoGearboxDevice unavailable: " + e.message)
        }

        // getTurnLightFlashState is more reliable than getLightStatus on this firmware.
        try {
            val cls = Class.forName("android.hardware.bydauto.light.BYDAutoLightDevice")
            lightDevice = cls.getMethod("getInstance", Context::class.java)
                .invoke(null, permissiveContext)
            getTurnLightFlashStateMethod = cls.getMethod("getTurnLightFlashState")
            logger.info("BYDAutoLightDevice initialized (using getTurnLightFlashState)")
        } catch (e: Exception) {
            logger.warn("BYDAutoLightDevice unavailable: " + e.message)
        }

        // Seatbelt: InstrumentDevice.getSafetyBeltStatus(int) first, SafetyBeltDevice as fallback.
        try {
            val cls = Class.forName("android.hardware.bydauto.instrument.BYDAutoInstrumentDevice")
            instrumentDeviceForBelt = cls.getMethod("getInstance", Context::class.java)
                .invoke(null, permissiveContext)
            getSafetyBeltStatusMethod = cls.getMethod("getSafetyBeltStatus", Int::class.javaPrimitiveType)
            logger.info("Using InstrumentDevice for seatbelt status")
        } catch (e: Exception) {
            logger.warn("BYDAutoInstrumentDevice seatbelt unavailable, trying fallback: " + e.message)
            try {
                val cls2 = Class.forName("android.hardware.bydauto.safetybelt.BYDAutoSafetyBeltDevice")
                safetyBeltDevice = cls2.getMethod("getInstance", Context::class.java)
                    .invoke(null, permissiveContext)
                getPassengerStatusMethod = cls2.getMethod("getPassengerStatus", Int::class.javaPrimitiveType)
                logger.info("BYDAutoSafetyBeltDevice initialized (fallback)")
            } catch (e2: Exception) {
                logger.warn("No seatbelt device available: " + e2.message)
            }
        }

        latestSnapshot = TelemetrySnapshot.createDefault()
        logger.info("Telemetry device initialization complete")
    }

    /**
     * Start polling on a background thread. Reference-counted: several callers may request
     * polling, and it only stops when all of them have released it.
     */
    fun startPolling() {
        val refs = pollingRefCount.incrementAndGet()
        val current = executor
        if (current != null && !current.isShutdown) {
            logger.info("Polling already running (refCount=$refs)")
            return
        }
        val interval = if (overlayRecordingActive) POLL_INTERVAL_MS else SLOW_POLL_INTERVAL_MS
        executor = newPoller().also {
            it.scheduleAtFixedRate({ poll() }, 0, interval, TimeUnit.MILLISECONDS)
        }
        logger.info(
            "Telemetry polling started at " + (1000 / interval) + " Hz (overlay=" +
                overlayRecordingActive + ", refCount=" + refs + ")"
        )
    }

    /** Set overlay recording mode: active polls at 5Hz, inactive drops to 1Hz. */
    fun setOverlayRecordingActive(active: Boolean) {
        if (overlayRecordingActive == active) return
        overlayRecordingActive = active
        logger.info("Overlay recording " + (if (active) "ACTIVE (5Hz)" else "INACTIVE (1Hz)"))
        restartAtCurrentRate()
    }

    /** Restart the scheduler at the rate matching [overlayRecordingActive]. No-op when stopped. */
    private fun restartAtCurrentRate() {
        val current = executor ?: return
        if (current.isShutdown) return
        current.shutdown()
        val interval = if (overlayRecordingActive) POLL_INTERVAL_MS else SLOW_POLL_INTERVAL_MS
        executor = newPoller().also {
            it.scheduleAtFixedRate({ poll() }, 0, interval, TimeUnit.MILLISECONDS)
        }
        logger.info("Telemetry polling restarted at " + (1000 / interval) + " Hz")
    }

    private fun newPoller(): ScheduledExecutorService =
        Executors.newSingleThreadScheduledExecutor { r ->
            Thread(r, "TelemetryPoller").apply { isDaemon = true }
        }

    /**
     * Release one polling reference. Only actually stops once every consumer has released; if the
     * overlay stopped but another consumer remains, the rate is downgraded instead.
     */
    fun stopPolling() {
        var refs = pollingRefCount.decrementAndGet()
        if (refs < 0) {
            pollingRefCount.set(0)
            refs = 0
        }
        if (refs > 0) {
            logger.info("Polling stop requested but still needed (refCount=$refs)")
            if (!overlayRecordingActive) restartAtCurrentRate()
            return
        }
        executor?.let {
            it.shutdown()
            executor = null
            logger.info("Telemetry polling stopped (refCount=0)")
        }
    }

    /** Stop regardless of reference count. Used during daemon shutdown. */
    fun forceStopPolling() {
        pollingRefCount.set(0)
        executor?.let {
            it.shutdown()
            executor = null
            logger.info("Telemetry polling force-stopped")
        }
    }

    /** The latest snapshot. Thread-safe via the volatile reference. */
    fun getLatestSnapshot(): TelemetrySnapshot? = latestSnapshot

    private fun poll() {
        try {
            pollInner()
        } catch (t: Throwable) {
            // CRITICAL: ScheduledExecutorService silently stops scheduling if a task throws.
            // Catch everything — a dropped poller is a dead overlay with no error anywhere.
            logger.error("Poll error (keeping alive): " + t.message)
        }
    }

    private fun pollInner() {
        var speedKmh = lastSpeedKmh
        var accelPercent = lastAccelPercent
        var brakePercent = lastBrakePercent
        var brakePedalPressed = lastBrakePedalPressed
        var gearMode = lastGearMode
        var leftTurn = lastLeftTurn
        var rightTurn = lastRightTurn
        var seatbelts = lastSeatbelts

        // ── FAST PATH: speed, accel, brake, gear — every poll. These are the only fields that
        // change rapidly while driving and are needed by the 5Hz video overlay.
        val sd = speedDevice
        if (sd != null) {
            var deviceFailed = false
            try {
                speedKmh = (getCurrentSpeedMethod!!.invoke(sd) as Double).toInt()
                lastSpeedKmh = speedKmh
            } catch (e: Exception) {
                logger.warn("Failed to read speed: " + e.message)
                deviceFailed = true
            }
            try {
                accelPercent = getAccelerateDeepnessMethod!!.invoke(sd) as Int
                lastAccelPercent = accelPercent
            } catch (e: Exception) {
                logger.warn("Failed to read accel pedal: " + e.message)
                deviceFailed = true
            }
            try {
                brakePercent = getBrakeDeepnessMethod!!.invoke(sd) as Int
                lastBrakePercent = brakePercent
            } catch (e: Exception) {
                logger.warn("Failed to read brake depth: " + e.message)
                deviceFailed = true
            }
            if (deviceFailed && tryReconnectSpeedDevice()) {
                speedKmh = lastSpeedKmh
                accelPercent = lastAccelPercent
                brakePercent = lastBrakePercent
            }

            // Staleness: an identical speed for 10+ seconds means the handle went dead without
            // throwing, which is how the BYD service restarting between trips presents.
            if (speedKmh == prevSpeedForStaleCheck && !(speedKmh == 0 && lastGearMode == 1)) {
                staleSpeedCount++
                if (staleSpeedCount >= STALE_THRESHOLD) {
                    logger.warn(
                        "Speed device appears stale (same value $speedKmh for " +
                            (staleSpeedCount / 5) + "s), reconnecting"
                    )
                    if (tryReconnectSpeedDevice()) {
                        speedKmh = lastSpeedKmh
                        accelPercent = lastAccelPercent
                        brakePercent = lastBrakePercent
                    }
                    staleSpeedCount = 0
                    prevSpeedForStaleCheck = -1
                }
            } else {
                staleSpeedCount = 0
                prevSpeedForStaleCheck = speedKmh
            }
        }

        gearboxDevice?.let { gd ->
            try {
                gearMode = getGearboxAutoModeTypeMethod!!.invoke(gd) as Int
                lastGearMode = gearMode
            } catch (e: Exception) {
                logger.warn("Failed to read gear mode: " + e.message)
            }
        }

        // Turn signals every poll (5Hz). Read on the fast path so a cancelled indicator clears
        // within ~600ms instead of lingering up to 10s. The sticky counter bridges the off-phase
        // of the ~1.5Hz blink cycle.
        val ld = lightDevice
        val turnMethod = getTurnLightFlashStateMethod
        if (ld != null && turnMethod != null) {
            try {
                val flashState = turnMethod.invoke(ld) as Int

                var leftNow = flashState == 2 || flashState == 3
                var rightNow = flashState == 4 || flashState == 5
                val hazardNow = flashState == 6 || flashState == 7
                if (hazardNow) {
                    leftNow = true
                    rightNow = true
                }

                if (leftNow) leftTurnStickyCount = TURN_STICKY_TICKS
                if (rightNow) rightTurnStickyCount = TURN_STICKY_TICKS

                leftTurn = leftTurnStickyCount > 0
                rightTurn = rightTurnStickyCount > 0

                if (leftTurnStickyCount > 0) leftTurnStickyCount--
                if (rightTurnStickyCount > 0) rightTurnStickyCount--

                lastLeftTurn = leftTurn
                lastRightTurn = rightTurn
            } catch (e: Exception) {
                logger.warn("Failed to read turn signal: " + e.message)
            }
        }

        // Seatbelts every poll (5Hz): drawn on the overlay every frame, so a buckle must show
        // within one frame rather than up to a second later.
        if (pollCount == 0L) probeSeatbeltApis(savedContext)
        val ibd = instrumentDeviceForBelt
        val beltMethod = getSafetyBeltStatusMethod
        if (ibd != null && beltMethod != null) {
            try {
                val driverRaw = beltMethod.invoke(ibd, 1) as Int
                val passengerRaw = beltMethod.invoke(ibd, 2) as Int
                seatbelts = booleanArrayOf(driverRaw != 0, passengerRaw != 0)
                lastSeatbelts = seatbelts
            } catch (e: Exception) {
                logger.warn("Failed to read seatbelt status: " + e.message)
            }
        }

        // ── SLOW PATH: brake-pedal PRESSED state, every 5th poll (1Hz). Not drawn on the
        // overlay — the renderer uses brakePercent — so 1Hz is plenty.
        if (pollCount % SLOW_FIELD_DIVISOR == 0L) {
            gearboxDevice?.let { gd ->
                try {
                    brakePedalPressed = (getBrakePedalStateMethod!!.invoke(gd) as Int) == 1
                    lastBrakePedalPressed = brakePedalPressed
                } catch (e: Exception) {
                    logger.warn("Failed to read brake pedal state: " + e.message)
                }
            }
        }

        // GPS for the dashcam overlay. GpsMonitor is fed live fixes by LocationSidecarService;
        // hasLocation() stays false until the first fix, and the overlay omits the line rather
        // than burning 0,0 into the footage.
        var hasGps = false
        var gpsLat = 0.0
        var gpsLon = 0.0
        try {
            val gps = net.bladewatch.app.monitor.GpsMonitor.getInstance()
            if (gps != null && gps.hasLocation()) {
                hasGps = true
                gpsLat = gps.latitude
                gpsLon = gps.longitude
            }
        } catch (e: Exception) {
            logger.warn("Failed to read GPS location: " + e.message)
        }

        latestSnapshot = TelemetrySnapshot(
            speedKmh, accelPercent, brakePercent,
            brakePedalPressed, gearMode,
            leftTurn, rightTurn,
            seatbelts, System.currentTimeMillis(),
            hasGps, gpsLat, gpsLon
        )

        pollCount++
    }

    /**
     * Re-obtain the speed device and PROVE it works with a test read before adopting it.
     *
     * Adopting a handle that returns without throwing but yields nothing is how the staleness
     * above starts, so the verification is the point of this method.
     */
    private fun tryReconnectSpeedDevice(): Boolean {
        return try {
            val cls = Class.forName("android.hardware.bydauto.speed.BYDAutoSpeedDevice")
            val newDevice = cls.getMethod("getInstance", Context::class.java)
                .invoke(null, savedContext) ?: return false

            val testSpeed = getCurrentSpeedMethod!!.invoke(newDevice) as Double
            val testAccel = getAccelerateDeepnessMethod!!.invoke(newDevice) as Int
            val testBrake = getBrakeDeepnessMethod!!.invoke(newDevice) as Int

            speedDevice = newDevice
            lastSpeedKmh = testSpeed.toInt()
            lastAccelPercent = testAccel
            lastBrakePercent = testBrake
            logger.info("Re-obtained BYDAutoSpeedDevice — verified working (speed=$lastSpeedKmh)")
            true
        } catch (e: Exception) {
            logger.warn("Speed device reconnect failed: " + e.message)
            false
        }
    }

    /**
     * Probe several BYD devices for any seatbelt-related method: BodyworkDevice alarms,
     * InstrumentDevice malfunction indicators, SafetyBeltDevice with various seat ids.
     *
     * Method names vary across BYD models, so this logs what it finds rather than assuming.
     */
    private fun probeSeatbeltApis(ctx: Context?) {
        logger.info("Probing BYD devices for seatbelt API...")

        try {
            val cls = Class.forName("android.hardware.bydauto.bodywork.BYDAutoBodyworkDevice")
            val device = cls.getMethod("getInstance", Context::class.java).invoke(null, ctx)
            for (name in arrayOf(
                "getAlarmState", "getSafetyBeltAlarm", "getSeatBeltWarning",
                "getSafetyBeltState", "getBeltAlarmState", "getAutoSystemState"
            )) {
                try {
                    val m = cls.getMethod(name)
                    val v = m.invoke(device) as Int
                    logger.info("Bodywork.$name() = $v")
                    if (v in 0..99) {
                        seatbeltAlarmDevice = device
                        seatbeltAlarmMethod = m
                        logger.info("Using Bodywork.$name() for seatbelt alarm")
                    }
                } catch (e: NoSuchMethodException) {
                    logger.debug("Bodywork method not found, trying next: $name")
                } catch (e: Exception) {
                    logger.warn("Bodywork seatbelt probe failed for device: " + e.message)
                }
            }
        } catch (e: Exception) {
            logger.warn("BYDAutoBodyworkDevice unavailable for seatbelt probe: " + e.message)
        }

        try {
            val cls = Class.forName("android.hardware.bydauto.instrument.BYDAutoInstrumentDevice")
            val device = cls.getMethod("getInstance", Context::class.java).invoke(null, ctx)

            for (name in arrayOf(
                "getSafetyBeltStatus", "getSeatBeltAlarm", "getSafetyBeltAlarmState",
                "getMalfunctionState"
            )) {
                try {
                    val m = cls.getMethod(name)
                    val v = m.invoke(device) as Int
                    logger.info("Instrument.$name() = $v")
                    if (seatbeltAlarmDevice == null && v in 0..99) {
                        seatbeltAlarmDevice = device
                        seatbeltAlarmMethod = m
                        logger.info("Using Instrument.$name() for seatbelt alarm")
                    }
                } catch (e: NoSuchMethodException) {
                    // Try the int-arg form instead.
                    try {
                        val m = cls.getMethod(name, Int::class.javaPrimitiveType)
                        val sb = StringBuilder("Instrument.$name(int):")
                        for (i in 0..5) {
                            try {
                                sb.append(" [").append(i).append("]=").append(m.invoke(device, i) as Int)
                            } catch (ex: Exception) {
                                sb.append(" [").append(i).append("]=ERR")
                            }
                        }
                        logger.info(sb.toString())
                    } catch (e2: NoSuchMethodException) {
                        logger.debug("Instrument method neither no-arg nor int-arg version exists: $name")
                    }
                } catch (e: Exception) {
                    logger.warn("Instrument seatbelt probe failed for method: " + e.message)
                }
            }

            try {
                val m = cls.getMethod("getMalfunctionState", Int::class.javaPrimitiveType)
                val sb = StringBuilder("Instrument.getMalfunctionState(int):")
                for (i in 0..20) {
                    try {
                        val v = m.invoke(device, i) as Int
                        if (v != 0 && v != -2147482645) sb.append(" [").append(i).append("]=").append(v)
                    } catch (ex: Exception) {
                        logger.debug("Instrument.getMalfunctionState(int) [i=$i] failed: " + ex.message)
                    }
                }
                logger.info(sb.toString())
            } catch (e: Exception) {
                logger.debug("Instrument.getMalfunctionState(int) method not available: " + e.message)
            }
        } catch (e: Exception) {
            logger.warn("BYDAutoInstrumentDevice unavailable for seatbelt probe: " + e.message)
        }

        if (seatbeltAlarmDevice == null) {
            logger.warn("No working seatbelt API found — seatbelt status will show as buckled")
        }
    }

    /**
     * Context wrapper that bypasses BYD permission checks.
     *
     * Required to reach BYD hardware services from UID 2000 without the signature permissions
     * that `pm grant` can never grant. The bypass is client-side and UID-independent.
     */
    private class PermissionBypassContext(base: Context) : ContextWrapper(base) {
        override fun enforceCallingOrSelfPermission(permission: String, message: String?) {}
        override fun enforcePermission(permission: String, pid: Int, uid: Int, message: String?) {}
        override fun enforceCallingPermission(permission: String, message: String?) {}

        override fun checkCallingOrSelfPermission(permission: String): Int =
            PackageManager.PERMISSION_GRANTED

        override fun checkPermission(permission: String, pid: Int, uid: Int): Int =
            PackageManager.PERMISSION_GRANTED

        override fun checkSelfPermission(permission: String): Int =
            PackageManager.PERMISSION_GRANTED
    }

    private companion object {
        val logger: DaemonLogger = DaemonLogger.getInstance("TelemetryDataCollector")

        /** 5 Hz — only while overlay recording is active. */
        const val POLL_INTERVAL_MS = 200L

        /** 1 Hz fallback when not recording. */
        const val SLOW_POLL_INTERVAL_MS = 1000L

        /**
         * Seatbelts and brake-pedal state do not change at 5Hz; poll them every 5th fast tick to
         * save reflection calls per cycle.
         */
        const val SLOW_FIELD_DIVISOR = 5

        /**
         * How many fast ticks to hold a turn signal "on" after the last observed flash, bridging
         * the off-phase of the ~1.5Hz blink. 3 ticks is ~600ms at 5Hz: long enough to span an
         * off-frame, short enough that a cancelled indicator clears almost immediately.
         */
        const val TURN_STICKY_TICKS = 3

        /** 10 seconds at 5Hz. */
        const val STALE_THRESHOLD = 50
    }
}
