package net.bladewatch.app.trips

import android.content.Context
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt
import net.bladewatch.app.byd.BydDataCollector
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.monitor.GearMonitor
import net.bladewatch.app.monitor.GpsMonitor
import net.bladewatch.app.monitor.VehicleDataMonitor

/**
 * Detects trip boundaries using a gear-based state machine.
 *
 * State machine: IDLE -> ACTIVE -> PARK_PENDING -> IDLE
 *
 * Transitions:
 *  - IDLE + gear in {D, R, S, M, N} -> create TripRecord, notify listener -> ACTIVE
 *  - ACTIVE + gear == P + speed == 0 -> start 120s debounce timer -> PARK_PENDING
 *  - PARK_PENDING + gear in {D, R, S, M, N} (within 120s) -> cancel timer -> ACTIVE
 *  - PARK_PENDING + 120s elapsed -> finalize trip, notify listener -> IDLE
 *
 * Called from `CameraDaemon.onGearChanged()` when gear transitions occur.
 */
class TripDetector {

    internal enum class State { IDLE, ACTIVE, PARK_PENDING }

    @Volatile
    private var state = State.IDLE

    @Volatile
    private var activeTrip: TripRecord? = null

    private val listeners = CopyOnWriteArrayList<TripListener>()
    private var distanceProvider: DistanceProvider? = null

    /** Odometer reading at trip start (km), -1 if unavailable. */
    private var startOdometerKm = -1.0

    /** Time when gear first went to P, for an accurate end time excluding the debounce. */
    private var parkStartTime = 0L

    private val scheduler = Executors.newSingleThreadScheduledExecutor { r ->
        Thread(r, "TripDetector-Debounce").apply { isDaemon = true }
    }

    @Volatile
    private var parkDebounceTask: ScheduledFuture<*>? = null

    init {
        logger.info("TripDetector created")
        checkForOrphanedTrips()
    }

    // ==================== LISTENER ====================

    /** Listener interface for trip lifecycle events. Multiple listeners may be registered. */
    interface TripListener {
        fun onTripStarted(trip: TripRecord)
        fun onTripEnded(trip: TripRecord)
        fun onTripDiscarded(trip: TripRecord, reason: String)
    }

    /**
     * Supplies the GPS-tracked distance for the just-finished trip. A query, not an event —
     * with multiple [TripListener]s there is no sensible "which one answers", so this is a
     * single designated slot, separate from the listener list (BladeWatch-nmao.3).
     */
    fun interface DistanceProvider {
        fun getRecordedDistanceKm(): Double
    }

    /** Add a listener for trip lifecycle events. A no-op if already registered. */
    fun addListener(listener: TripListener) {
        listeners.addIfAbsent(listener)
    }

    /** Remove a previously-added listener. */
    fun removeListener(listener: TripListener) {
        listeners.remove(listener)
    }

    /** Set the single distance provider consulted when resolving a trip's distance. */
    fun setDistanceProvider(provider: DistanceProvider?) {
        distanceProvider = provider
    }

    /** Notify every registered listener; one throwing must not stop the others. */
    private inline fun notifyListeners(what: String, action: (TripListener) -> Unit) {
        for (l in listeners) {
            try {
                action(l)
            } catch (e: Exception) {
                logger.error("Listener.$what failed: " + e.message)
            }
        }
    }

    // ==================== GEAR MONITOR REGISTRATION ====================

    /**
     * Register with GearMonitor for gear change callbacks. Currently a no-op — CameraDaemon
     * forwards gear changes directly via [onGearChanged].
     */
    fun registerWithGearMonitor() {
        logger.info("registerWithGearMonitor (no-op: CameraDaemon forwards gear changes)")
    }

    /** Unregister from GearMonitor. Currently a no-op — CameraDaemon forwards directly. */
    fun unregisterFromGearMonitor() {
        logger.info("unregisterFromGearMonitor (no-op)")
    }

    // ==================== GEAR CHANGE HANDLER ====================

    /**
     * Called from CameraDaemon when gear changes. The main entry point for the state machine.
     *
     * @param newGear the new gear position (1=P, 2=R, 3=N, 4=D, 5=M, 6=S)
     */
    @Synchronized
    fun onGearChanged(newGear: Int) {
        logger.info("onGearChanged: gear=${GearMonitor.gearToString(newGear)} state=$state")

        when (state) {
            State.IDLE -> if (isDrivingGear(newGear)) startTrip()
            State.ACTIVE -> handleActiveGearChange(newGear)
            State.PARK_PENDING -> handleParkPendingGearChange(newGear)
        }
    }

    /** ACTIVE state: trip in progress, watching for Park gear. */
    private fun handleActiveGearChange(newGear: Int) {
        if (newGear == GearMonitor.GEAR_P) {
            // Only start the debounce if the car is actually stopped.
            val speed = GpsMonitor.getInstance().speed
            if (speed <= 0.5f) {
                logger.info("Gear P + speed=0 -> starting ${PARK_DEBOUNCE_MS / 1000}s debounce")
                state = State.PARK_PENDING
                parkStartTime = System.currentTimeMillis()
                startParkDebounceTimer()
            } else {
                logger.info("Gear P but speed=$speed m/s -> staying ACTIVE (moving)")
            }
        }
        // Other gear changes while active are normal driving (D->R, D->N, etc.)
    }

    /** PARK_PENDING: debounce running, watching for a driving gear to cancel it. */
    private fun handleParkPendingGearChange(newGear: Int) {
        if (isDrivingGear(newGear)) {
            logger.info(
                "Gear resumed to ${GearMonitor.gearToString(newGear)} -> " +
                    "cancelling debounce, back to ACTIVE"
            )
            cancelParkDebounceTimer()
            parkStartTime = 0
            state = State.ACTIVE
        }
    }

    // ==================== TRIP LIFECYCLE ====================

    /** Start a new trip. Creates a TripRecord and notifies the listener. */
    private fun startTrip() {
        val now = System.currentTimeMillis()
        val trip = TripRecord()
        activeTrip = trip
        trip.startTime = now

        // Read start SoC
        try {
            VehicleDataMonitor.getInstance().getBatterySoc()?.let {
                trip.socStart = it.socPercent
            }
        } catch (e: Exception) {
            logger.error("Failed to read start SoC: " + e.message)
        }

        // Read start kWh (remaining energy from BMS)
        try {
            val kwhRemaining = VehicleDataMonitor.getInstance().getBatteryRemainPowerKwh()
            if (kwhRemaining > 0) trip.kwhStart = kwhRemaining
        } catch (e: Exception) {
            logger.error("Failed to read start kWh: " + e.message)
        }

        // Fuel + lifetime counters (BladeWatch-fpdz.4). Best-effort: a missing HAL must never
        // abort a trip, so every reading falls back to the unavailable sentinel.
        try {
            val vdm = VehicleDataMonitor.getInstance()
            captureStart(
                trip, isFuelCapableHybrid(),
                vdm.getFuelPercent(), vdm.getTotalFuelCon(), vdm.getTotalElecCon()
            )
        } catch (e: Exception) {
            logger.error("Failed to read start fuel/counters: " + e.message)
        }

        // Read start GPS
        try {
            val gps = GpsMonitor.getInstance()
            if (gps.hasLocation()) {
                trip.startLat = gps.latitude
                trip.startLon = gps.longitude
            }
        } catch (e: Exception) {
            logger.error("Failed to read start GPS: " + e.message)
        }

        // Odometer: store 0 for now, compute distance from GPS later if needed.
        trip.distanceKm = 0.0

        // Read start odometer
        startOdometerKm = try {
            OdometerReader.getInstance().readOdometerKm().also {
                if (it > 0) logger.info("Start odometer: $it km")
            }
        } catch (e: Exception) {
            logger.warn("Failed to read start odometer: " + e.message)
            -1.0
        }

        trip.extTempC = readExternalTempC()

        state = State.ACTIVE
        logger.info(
            "Trip started at $now (SoC=${trip.socStart}%, " +
                "GPS=${trip.startLat},${trip.startLon})"
        )

        notifyListeners("onTripStarted") { it.onTripStarted(trip) }
    }

    /**
     * External temperature via the BYD instrument HAL, or 0 when unavailable.
     *
     * Reflection, per the project's BYD SDK stub pattern: the compile-time stub is never
     * instantiated and the real class comes from the boot classloader at runtime.
     */
    private fun readExternalTempC(): Int {
        try {
            val instrumentClass =
                Class.forName("android.hardware.bydauto.instrument.BYDAutoInstrumentDevice")
            val getInst = instrumentClass.getMethod("getInstance", Context::class.java)
            val instrumentDevice = getInst.invoke(null, null as Context?)
            if (instrumentDevice != null) {
                val getTemp = instrumentClass.getMethod("getOutCarTemperature")
                val rawTemp = getTemp.invoke(instrumentDevice) as Int
                if (rawTemp in -50..60) return rawTemp
            }
        } catch (e: Exception) {
            logger.warn(
                "TripDetector.startTrip: failed to read external temperature: " + e.message
            )
        }
        return 0
    }

    /**
     * Finalize the active trip. Called when the debounce timer expires or on shutdown.
     * Populates end fields, checks minimum thresholds, and notifies the listener.
     */
    @Synchronized
    fun finalizeActiveTrip() {
        val trip = activeTrip
        if (trip == null || state == State.IDLE) {
            logger.info("finalizeActiveTrip: no active trip")
            return
        }

        cancelParkDebounceTimer()

        val now = System.currentTimeMillis()
        // Use the time gear first went to P as the real end time, not the current time, which
        // would include the 120s debounce wait.
        trip.endTime = if (parkStartTime > 0) parkStartTime else now
        trip.durationSeconds = ((trip.endTime - trip.startTime) / 1000).toInt()

        // Read end SoC
        try {
            VehicleDataMonitor.getInstance().getBatterySoc()?.let { trip.socEnd = it.socPercent }
        } catch (e: Exception) {
            logger.error("Failed to read end SoC: " + e.message)
        }

        // Read end kWh (remaining energy from BMS)
        try {
            val kwhRemaining = VehicleDataMonitor.getInstance().getBatteryRemainPowerKwh()
            if (kwhRemaining > 0) trip.kwhEnd = kwhRemaining
        } catch (e: Exception) {
            logger.error("Failed to read end kWh: " + e.message)
        }

        // Fuel + lifetime counters at the far end (BladeWatch-fpdz.4). ONE drivetrain probe for
        // this boundary, reused for both fuel fields — it takes a lock and reaches the HAL.
        try {
            val vdm = VehicleDataMonitor.getInstance()
            captureEnd(
                trip, isFuelCapableHybrid(),
                vdm.getFuelPercent(), vdm.getTotalFuelCon(), vdm.getTotalElecCon()
            )
        } catch (e: Exception) {
            logger.error("Failed to read end fuel/counters: " + e.message)
        }

        // Read end GPS
        try {
            val gps = GpsMonitor.getInstance()
            if (gps.hasLocation()) {
                trip.endLat = gps.latitude
                trip.endLon = gps.longitude
            }
        } catch (e: Exception) {
            logger.error("Failed to read end GPS: " + e.message)
        }

        resolveDistance(trip)
        computeEfficiency(trip)
        logFinalized(trip)

        // Check minimum thresholds
        val durationMs = trip.endTime - trip.startTime
        if (durationMs < MIN_TRIP_DURATION_MS) {
            val reason =
                "Duration ${durationMs / 1000}s < minimum ${MIN_TRIP_DURATION_MS / 1000}s"
            logger.info("Trip discarded: $reason")
            discardTrip(reason)
            return
        }

        if (trip.distanceKm < MIN_TRIP_DISTANCE_KM) {
            val reason = "Distance ${trip.distanceKm}km < minimum ${MIN_TRIP_DISTANCE_KM}km"
            logger.info("Trip discarded: $reason")
            discardTrip(reason)
            return
        }

        // Trip is valid — notify the listener.
        activeTrip = null
        startOdometerKm = -1.0
        parkStartTime = 0
        state = State.IDLE

        notifyListeners("onTripEnded") { it.onTripEnded(trip) }
    }

    /**
     * Resolve trip distance, preferring the most accurate source available:
     * odometer delta, then the recorder's GPS track, then straight-line as a last resort.
     */
    private fun resolveDistance(trip: TripRecord) {
        val endOdometerKm = try {
            OdometerReader.getInstance().readOdometerKm()
        } catch (e: Exception) {
            logger.warn("Failed to read end odometer: " + e.message)
            -1.0
        }

        if (startOdometerKm > 0 && endOdometerKm > startOdometerKm) {
            trip.distanceKm = endOdometerKm - startOdometerKm
            logger.info("Distance from odometer: ${"%.2f".format(trip.distanceKm)} km")
        }

        // Fallback: GPS haversine distance from the recorder.
        val provider = distanceProvider
        if (trip.distanceKm <= 0 && provider != null) {
            try {
                val recordedDist = provider.getRecordedDistanceKm()
                if (recordedDist > 0) {
                    trip.distanceKm = recordedDist
                    logger.info("Distance from GPS (fallback): ${"%.2f".format(recordedDist)} km")
                }
            } catch (e: Exception) {
                logger.warn("Failed to get GPS distance: " + e.message)
            }
        }

        // Last resort: straight-line haversine from start to end. This underestimates real
        // distance, but it stops valid trips being discarded when both the odometer and the
        // recorder distance are unavailable.
        if (trip.distanceKm <= 0 &&
            trip.startLat != 0.0 && trip.startLon != 0.0 &&
            trip.endLat != 0.0 && trip.endLon != 0.0
        ) {
            val straightLine =
                haversineKm(trip.startLat, trip.startLon, trip.endLat, trip.endLon)
            if (straightLine > 0) {
                // 1.3x approximates road distance from straight-line.
                trip.distanceKm = straightLine * 1.3
                logger.info(
                    "Distance from straight-line GPS (last resort): " +
                        "${"%.2f".format(trip.distanceKm)} km " +
                        "(straight=${"%.2f".format(straightLine)} km)"
                )
            }
        }
    }

    private fun computeEfficiency(trip: TripRecord) {
        if (trip.distanceKm <= 0) return

        // Prefer kWh-based efficiency (direct BMS measurement).
        val energyUsed = trip.getEnergyUsedKwh()
        if (energyUsed > 0) {
            trip.energyPerKm = energyUsed / trip.distanceKm
        }
        // Also compute SoC-based efficiency (legacy / fallback).
        if (trip.socStart > trip.socEnd) {
            trip.efficiencySocPerKm = (trip.socStart - trip.socEnd) / trip.distanceKm
        }
        if (trip.energyPerKm <= 0 && trip.efficiencySocPerKm > 0) {
            logger.debug("kWh not available, using SoC-based energyPerKm estimate")
        }
    }

    private fun logFinalized(trip: TripRecord) {
        // Fuel figures only when there IS a fuel leg. Logging them on a BEV would be permanent
        // noise in every trip line on a car that has no fuel system.
        val fuelSuffix = if (trip.fuelConStart >= 0 && trip.fuelConEnd >= 0) {
            ", fuel=${"%.2f".format(trip.fuelConStart)}->${"%.2f".format(trip.fuelConEnd)} L" +
                " (tank=${"%.0f".format(trip.fuelPctStart)}->" +
                "${"%.0f".format(trip.fuelPctEnd)}%)"
        } else {
            ""
        }
        logger.info(
            "Trip finalized: duration=${trip.durationSeconds}s, distance=${trip.distanceKm}km," +
                " SoC=${trip.socStart}->${trip.socEnd}%" +
                ", kWh=${"%.2f".format(trip.kwhStart)}->${"%.2f".format(trip.kwhEnd)}" +
                " (used=${"%.2f".format(trip.getEnergyUsedKwh())} kWh)" +
                fuelSuffix
        )
    }

    /** Discard a trip that does not meet minimum thresholds. */
    private fun discardTrip(reason: String) {
        val discardedTrip = activeTrip
        activeTrip = null
        startOdometerKm = -1.0
        parkStartTime = 0
        state = State.IDLE

        if (discardedTrip != null) {
            notifyListeners("onTripDiscarded") { it.onTripDiscarded(discardedTrip, reason) }
        }
    }

    // ==================== DEBOUNCE TIMER ====================

    /** Start the park debounce timer. When it fires, the trip is finalized. */
    private fun startParkDebounceTimer() {
        cancelParkDebounceTimer()
        parkDebounceTask = scheduler.schedule({
            synchronized(this@TripDetector) {
                if (state == State.PARK_PENDING) {
                    logger.info("Park debounce timer expired -> finalizing trip")
                    finalizeActiveTrip()
                }
            }
        }, PARK_DEBOUNCE_MS, TimeUnit.MILLISECONDS)
    }

    /** Cancel the park debounce timer if running. */
    private fun cancelParkDebounceTimer() {
        parkDebounceTask?.let {
            if (!it.isDone) it.cancel(false)
            parkDebounceTask = null
        }
    }

    // ==================== ORPHANED TRIP CHECK ====================

    /**
     * Check for orphaned trips on init (a trip with startTime but no endTime), left behind if
     * the daemon crashed mid-trip.
     *
     * The actual DB recovery happens in `TripAnalyticsManager.initComponents()`, because
     * TripDatabase is not available at TripDetector construction time.
     */
    private fun checkForOrphanedTrips() {
        logger.info("Checking for orphaned trips...")
    }

    // ==================== GETTERS ====================

    /** Whether a trip is currently active (ACTIVE or PARK_PENDING). */
    fun isTripActive(): Boolean = state != State.IDLE && activeTrip != null

    /** The currently active trip record, or null if no trip is active. */
    fun getActiveTrip(): TripRecord? = activeTrip

    /** The current state machine state. Internal for testing. */
    internal fun getState(): State = state

    // ==================== SHUTDOWN ====================

    /** Shut down the detector: finalize any active trip and stop the scheduler. */
    fun shutdown() {
        logger.info("Shutting down TripDetector")
        finalizeActiveTrip()
        scheduler.shutdownNow()
    }

    companion object {
        private val logger = DaemonLogger.getInstance("TripDetector")

        internal const val PARK_DEBOUNCE_MS = 120_000L     // 2 minutes
        internal const val MIN_TRIP_DURATION_MS = 60_000L  // 1 minute
        internal const val MIN_TRIP_DISTANCE_KM = 0.2      // 200 metres

        /**
         * Normalise one HAL reading to the TripRecord convention: -1 means unavailable, and any
         * non-negative value — INCLUDING 0 — is a real measurement.
         *
         * The 0 case is the whole reason this exists. An empty tank reads 0 and a fresh
         * lifetime counter reads 0; folding either into "unavailable" would make a real
         * measurement indistinguishable from a missing one, and a caller would then invent
         * consumption that never happened.
         *
         * Non-finite is rejected as a whole, not just NaN: `Infinity < 0` is false, so a bare
         * NaN check would let it through, and it then propagates into a counter DELTA and out
         * to JSON, where `put` refuses it and the trip serialises only partially.
         */
        private fun sanitizeReading(v: Double): Double =
            if (!v.isFinite() || v < 0) -1.0 else v

        /**
         * Record the fuel and lifetime-counter readings at trip START.
         *
         * Internal and pure so the capture RULE can be tested without a live
         * VehicleDataMonitor or a gear signal (BladeWatch-fpdz.4).
         *
         * @param isPhev gates the FUEL pair only. A BEV has no fuel system, so recording
         *   zeroes there would later be indistinguishable from a PHEV that burned nothing.
         *   The electricity counter is deliberately NOT gated — it is meaningful on both.
         */
        @JvmStatic
        internal fun captureStart(
            t: TripRecord,
            isPhev: Boolean,
            fuelPct: Double,
            fuelCon: Double,
            elecCon: Double,
        ) {
            if (isPhev) {
                t.fuelPctStart = sanitizeReading(fuelPct)
                t.fuelConStart = sanitizeReading(fuelCon)
            }
            t.elecConStart = sanitizeReading(elecCon)
        }

        /** Record the readings at trip END. See [captureStart]. */
        @JvmStatic
        internal fun captureEnd(
            t: TripRecord,
            isPhev: Boolean,
            fuelPct: Double,
            fuelCon: Double,
            elecCon: Double,
        ) {
            if (isPhev) {
                t.fuelPctEnd = sanitizeReading(fuelPct)
                t.fuelConEnd = sanitizeReading(fuelCon)
            }
            t.elecConEnd = sanitizeReading(elecCon)
        }

        /**
         * Drivetrain, best-effort. Called at most once per trip boundary: it takes a lock and
         * reaches the HAL, so it must not be invoked per-field. A failure yields false, which
         * costs a PHEV its fuel leg for that trip but never aborts or corrupts one.
         */
        private fun isFuelCapableHybrid(): Boolean = try {
            BydDataCollector.getInstance().isPhevVehicle()
        } catch (t: Throwable) {
            logger.debug("drivetrain probe unavailable; recording no fuel leg: " + t.message)
            false
        }

        /** Whether a gear value represents a driving gear (i.e. not Park). */
        private fun isDrivingGear(gear: Int): Boolean =
            gear == GearMonitor.GEAR_D ||
                gear == GearMonitor.GEAR_R ||
                gear == GearMonitor.GEAR_N ||
                gear == GearMonitor.GEAR_M ||
                gear == GearMonitor.GEAR_S

        /**
         * Haversine distance between two GPS coordinates in km. Used as a last-resort distance
         * estimate when the odometer and the recorder both fail.
         */
        private fun haversineKm(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
            val earthRadiusKm = 6371.0
            val dLat = Math.toRadians(lat2 - lat1)
            val dLon = Math.toRadians(lon2 - lon1)
            val a = sin(dLat / 2) * sin(dLat / 2) +
                cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) *
                sin(dLon / 2) * sin(dLon / 2)
            val c = 2 * atan2(sqrt(a), sqrt(1 - a))
            return earthRadiusKm * c
        }
    }
}
