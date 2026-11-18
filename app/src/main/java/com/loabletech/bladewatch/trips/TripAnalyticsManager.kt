package net.bladewatch.app.trips

import android.content.Context
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.max
import kotlin.math.sin
import kotlin.math.sqrt
import net.bladewatch.app.byd.BydDataCollector
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.monitor.GearMonitor
import net.bladewatch.app.monitor.VehicleDataMonitor
import net.bladewatch.app.storage.StorageManager
import net.bladewatch.app.telemetry.TelemetryDataCollector
import org.json.JSONObject

/**
 * Top-level coordinator for Trip Analytics and Driving DNA. The single entry point for
 * CameraDaemon integration.
 *
 * Lifecycle:
 *  - `CameraDaemon.main()` -> [init]
 *  - `CameraDaemon.shutdown()` -> [shutdown]
 *  - GearMonitor callback -> [onGearChanged]
 */
class TripAnalyticsManager {

    private var config: TripConfig? = null
    private var database: TripDatabase? = null
    private var detector: TripDetector? = null
    private var recorder: TripTelemetryRecorder? = null
    private var scoreEngine: TripScoreEngine? = null
    private var rangeEstimator: RangeEstimator? = null

    private var telemetryDataCollector: TelemetryDataCollector? = null

    /** Durable copy of the open manual trip (BladeWatch-gklt.2); null until components are up. */
    private var manualStore: ManualTripStore? = null

    /** One thread for the minute tick that saves the open manual trip. */
    private var manualScheduler: ScheduledExecutorService? = null

    /**
     * Other features' state for the open manual trip; saved and restored with it.
     *
     * A [JSONObject] is not thread-safe, and the minute tick, the ACC callbacks and the RPC
     * threads all touch it, so EVERY read or write of it (and every save that serialises it)
     * holds [manualLock].
     */
    @Volatile
    private var manualExtras = JSONObject()
    private val manualLock = Any()

    /** EV/HEV split of the trip in progress (BladeWatch-reml.1). Fed every [ENERGY_SAMPLE_SECONDS]. */
    private val segments = EnergyModeSegments()

    /** When to remind the driver to stop an open manual trip. See [ManualTripReminder]. */
    private val reminder = ManualTripReminder(
        clock = System::currentTimeMillis,
        fire = ::onReminderFired,
    )

    @Volatile
    private var enabled = false

    @Volatile
    private var initialized = false

    // ==================== LIFECYCLE ====================

    /**
     * Initialize trip analytics. Called from `CameraDaemon.main()`.
     *
     *  1. Load [TripConfig]
     *  2. If enabled, initialize the database, detector, recorder, score engine and range
     *     estimator
     *  3. Wire the detector listener to handle trip start/end events
     *  4. Ensure the trips directory exists
     */
    fun init(context: Context?, telemetryDataCollector: TelemetryDataCollector?) {
        this.telemetryDataCollector = telemetryDataCollector

        // 1. Load config
        val cfg = TripConfig()
        cfg.load()
        config = cfg

        // 4. Ensure the trips directory exists
        val tripsDir = StorageManager.getInstance().tripsDir
        if (!tripsDir.exists()) {
            val created = tripsDir.mkdirs()
            logger.info(
                "Trips directory created: ${tripsDir.absolutePath} (success=$created)"
            )
        }

        // 2. If enabled, initialize all components
        if (cfg.isEnabled()) {
            initComponents()
        }

        initialized = true
        logger.info("TripAnalyticsManager initialized — enabled=${cfg.isEnabled()}")
    }

    /** Shut down trip analytics. Called from `CameraDaemon.shutdown()`. */
    fun shutdown() {
        logger.info("Shutting down TripAnalyticsManager")

        // An open manual trip must survive a daemon restart, so only an auto trip is finalized.
        // The manual one is flushed and saved instead.
        manualScheduler?.shutdownNow()
        manualScheduler = null
        detector?.let {
            if (it.isManualTripActive()) {
                recorder?.flushNow()
                saveManualState()
            } else {
                it.finalizeActiveTrip()
            }
        }
        database?.close()

        enabled = false
        initialized = false

        logger.info("TripAnalyticsManager shut down")
    }

    // ==================== GEAR FORWARDING ====================

    /** Forward a gear change to the detector if enabled. */
    fun onGearChanged(newGear: Int) {
        if (!enabled) return
        detector?.onGearChanged(newGear)
        if (detector?.isManualTripActive() == true) {
            reminder.onGear(newGear)
            persistReminder()
        }
    }

    // ==================== ACC LIFECYCLE ====================

    /**
     * Called when ACC goes OFF (car powering down / entering sentry mode). Finalizes an active
     * AUTO trip immediately — the gear change to P may not fire reliably during power-down, so
     * this is a safety net. A manual trip (BladeWatch-gklt) stays open.
     */
    fun onAccOff() {
        if (!enabled) return
        // The detector decides: an auto trip ends now, a manual trip stays open.
        val d = detector ?: return
        d.onAccOff()
        if (d.isManualTripActive()) {
            // Nobody is driving: stop sampling (GPS drift, flat-zero rows) but keep the trip.
            recorder?.pause()
            reminder.onAcc(false)
            persistReminder()
        }
    }

    /**
     * Called when ACC comes ON (car powering up). Probes the current gear and auto-starts a
     * trip if already in a driving gear. This covers the case where the gear changed to D
     * before the GearMonitor listener was re-registered, or the gear event was lost during the
     * ACC transition.
     */
    fun onAccOn() {
        if (!enabled) return
        logger.info("ACC ON — trip detection ready (waiting for gear D/R)")

        if (detector?.isManualTripActive() == true) {
            recorder?.resume()
            reminder.onAcc(true)
            persistReminder()
        }

        try {
            val currentGear = GearMonitor.getInstance().currentGear
            val d = detector
            if (currentGear != GearMonitor.GEAR_P && d != null && !d.isTripActive()) {
                logger.info(
                    "ACC ON + gear already ${GearMonitor.gearToString(currentGear)} " +
                        "— auto-starting trip"
                )
                d.onGearChanged(currentGear)
            }
        } catch (e: Exception) {
            logger.warn("ACC ON gear probe failed: " + e.message)
        }
    }

    // ==================== RUNTIME CONFIG ====================

    /**
     * Enable or disable trip analytics at runtime.
     *
     * Trip analytics is always on — there is no off switch. A request to disable is ignored,
     * and if the components somehow are not up yet they are brought up rather than torn down.
     */
    fun onConfigChanged(newEnabled: Boolean) {
        logger.info("onConfigChanged: $enabled -> $newEnabled")

        if (!newEnabled) {
            logger.info("Ignoring disable request — trip analytics is always on")
            if (!enabled) initComponents()
            return
        }

        if (newEnabled == enabled) return // No change

        config?.let {
            it.setEnabled(true)
            it.save()
        }

        if (!enabled) initComponents()

        // If gear is not P, trigger trip detection.
        val currentGear = GearMonitor.getInstance().currentGear
        val d = detector
        if (currentGear != GearMonitor.GEAR_P && d != null) {
            logger.info(
                "Enabling while gear=${GearMonitor.gearToString(currentGear)} " +
                    "— forwarding gear to detector"
            )
            d.onGearChanged(currentGear)
        }

        logger.info("Trip analytics enabled")
    }

    // ==================== ACCESSORS ====================

    fun getDatabase(): TripDatabase? = database

    fun getRangeEstimator(): RangeEstimator? = rangeEstimator

    fun getConfig(): TripConfig? = config

    fun isEnabled(): Boolean = enabled

    /** Whether a trip is currently being tracked (ACTIVE or PARK_PENDING). */
    fun isTripActive(): Boolean = enabled && detector?.isTripActive() == true

    /** Start a manual trip (Start Trip button), or null when trip analytics is not running. */
    fun startManualTrip(): TripRecord? {
        if (!enabled) return null
        val d = detector ?: return null
        val alreadyOpen = d.isManualTripActive()
        val trip = d.startManualTrip()
        // A NEW manual trip starts with a clean slate; an idempotent repeat keeps its state.
        if (!alreadyOpen) {
            synchronized(manualLock) { manualExtras = JSONObject() }
            val gear = try { GearMonitor.getInstance().currentGear } catch (e: Exception) { null }
            // The driver just pressed the button, so the car is on.
            reminder.onManualTripStarted(gear, accOn = true)
            persistReminder()
        } else {
            saveManualState()
        }
        return trip
    }

    /**
     * End the open manual trip. False when none is open or trip analytics is not running. The
     * saved state is removed when the trip is persisted (see [handleTripEnded]).
     */
    fun stopManualTrip(): Boolean = enabled && detector?.stopManualTrip() == true

    /** Whether a manual trip is open. */
    fun isManualTripActive(): Boolean = enabled && detector?.isManualTripActive() == true

    /**
     * The trip in progress as the wire message ActiveTripStatus (camelCase proto3 JSON). Safe to
     * call when no trip is open: everything is then zero/false/empty.
     */
    fun activeTripStatus(): JSONObject {
        val json = JSONObject()
        val trip = if (enabled) detector?.getActiveTrip() else null
        val open = trip != null && detector?.isTripActive() == true
        val manual = open && trip!!.isManual
        val (reminder, ackedSeq) = synchronized(manualLock) {
            // Copy out under the lock: the objects are mutated by other threads.
            val r = manualExtras.optJSONObject("reminder")
            Pair(r?.let { JSONObject(it.toString()) }, manualExtras.optLong("reminderAckedSeq", 0L))
        }
        json.put("active", open)
        json.put("manual", manual)
        json.put("startTimeMs", if (open) trip!!.startTime else 0L)
        json.put("distanceKm", if (open) (recorder?.totalDistanceKm ?: 0.0) else 0.0)
        json.put(
            "autoStopAtMs",
            if (manual) trip!!.startTime + TripDetector.MANUAL_MAX_DURATION_MS else 0L
        )
        json.put("reminderSeq", if (manual) reminder?.optLong("seq", 0L) ?: 0L else 0L)
        json.put("reminderReason", if (manual) reminder?.optString("lastReason", "") ?: "" else "")
        json.put("reminderAckedSeq", if (manual) ackedSeq else 0L)
        json.put("telemetryPaused", manual && recorder?.isPaused == true)
        putLiveCost(json, open)
        return json
    }

    /**
     * What the open trip has cost so far, from the tracker's latest reading (no extra HAL read per
     * poll). EV driving so far x the electricity rate, HEV driving so far x the fuel price; "not
     * available" with no trip or with neither rate configured, never a made-up zero.
     */
    private fun putLiveCost(json: JSONObject, open: Boolean) {
        val cfg = config
        val live = if (open) segments.live() else null
        val rate = cfg?.getElectricityRate() ?: 0.0
        val price = cfg?.getFuelPricePerL() ?: 0.0
        val available = live != null && (rate > 0 || price > 0)
        json.put("liveCostAvailable", available)
        json.put("liveElectricCost", if (available && rate > 0) live!!.evKwh * rate else 0.0)
        json.put("liveFuelCost", if (available && price > 0) live!!.hevLitres * price else 0.0)
        json.put("liveCurrency", if (available) cfg?.getCurrency() ?: "" else "")
        json.put("liveHasFuel", available && price > 0)
    }

    /**
     * Record that the in-car dialog for reminder [seq] has been shown, so it is never shown again.
     * Keeps the highest value: a late or repeated acknowledgement can never re-arm an older one.
     */
    fun acknowledgeReminder(seq: Long) {
        if (!isManualTripActive()) return
        synchronized(manualLock) {
            if (seq > manualExtras.optLong("reminderAckedSeq", 0L)) {
                manualExtras.put("reminderAckedSeq", seq)
                saveManualState()
            }
        }
    }

    /** The active trip record, or null if no trip is active. */
    fun getActiveTrip(): TripRecord? = detector?.getActiveTrip()

    /**
     * Update the TelemetryDataCollector reference after late initialization. Called by
     * CameraDaemon once the collector is ready (after the GPU init delay).
     */
    /** Test seam: run with a prebuilt detector/recorder, skipping the database and HAL wiring. */
    internal fun attachForTest(
        detector: TripDetector,
        recorder: TripTelemetryRecorder?,
        store: ManualTripStore? = null,
        config: TripConfig? = null,
    ) {
        this.detector = detector
        this.recorder = recorder
        this.manualStore = store
        this.config = config
        enabled = true
    }

    /** Test seam: the EV/HEV tracker, so a test can drive what the live cost reads. */
    internal fun energySegments(): EnergyModeSegments = segments

    fun setTelemetryDataCollector(collector: TelemetryDataCollector?) {
        val first = telemetryDataCollector == null && collector != null
        telemetryDataCollector = collector
        recorder?.telemetryDataCollector = collector
        // A trip restored (or started) before the collector existed has not asked it to poll,
        // so its samples would all read zero. handleTripEnded releases the reference.
        if (first && detector?.isTripActive() == true) {
            try {
                collector?.startPolling()
            } catch (e: Exception) {
                logger.warn("Failed to start polling for the open trip: " + e.message)
            }
        }
    }

    // ==================== SYNC / RECONCILE ====================

    /**
     * Manual trips sync: prune trips whose telemetry file is gone, then re-index any orphan
     * telemetry files into basic trip rows (start/end, duration, distance and GPS endpoints
     * derived from the samples).
     *
     * Per the agreed scope this does NOT recompute DNA/efficiency scores or SoC — the
     * telemetry samples do not carry SoC, so those stay 0 for reconstructed trips.
     *
     * Synchronized for single-flight. The trip DB connection is otherwise daemon-thread
     * confined; this runs on an HTTP worker, the same concurrency posture as the existing read
     * endpoints.
     *
     * @return `{success, added, removed, total}` or `{success:false, error:...}`
     */
    @Synchronized
    fun reconcileTrips(): JSONObject {
        val m = HashMap<String, Any?>()
        val db = database
        if (db == null || !db.isAvailable()) {
            m["success"] = false
            m["error"] = "trips_unavailable"
            return JSONObject(m as Map<*, *>)
        }
        try {
            val removed = db.deleteTripsWithMissingTelemetry()

            val known = HashSet(db.getAllTelemetryPaths())
            // The telemetry file of a trip that is still open has no row yet: indexing it now
            // would store a half-trip and the real one would then be saved a second time. A
            // manual trip can stay open for days, so this is no longer a theoretical race.
            val openTripFile = detector?.getActiveTrip()?.let { "${it.startTime}.jsonl.gz" }
            var added = 0
            for (dir in StorageManager.getInstance().allTripsDirs) {
                if (!dir.exists() || !dir.canRead()) continue
                val files = dir.listFiles { _, name -> name.endsWith(".jsonl.gz") } ?: continue
                for (f in files) {
                    if (!f.canRead() || f.length() <= 0) continue
                    if (known.contains(f.absolutePath)) continue
                    if (f.name == openTripFile) continue
                    val samples = TelemetryStore.readFromFile(f)
                    if (samples.isNullOrEmpty()) continue
                    if (samples.size == 1) {
                        // A single-sample file cannot produce a valid trip (no distance, no
                        // duration). Skip the DB insert; leave the file on disk.
                        logger.warn("Skipping single-sample telemetry file: ${f.name}")
                        continue
                    }
                    val t = buildBasicTrip(samples, f.absolutePath)
                    if (db.insertTrip(t) > 0) {
                        added++
                        known.add(f.absolutePath)
                    }
                }
            }

            val total = db.getTripCount()
            m["success"] = true
            m["added"] = added
            m["removed"] = removed
            m["total"] = total
            logger.info("Trips sync: +$added -$removed (total=$total)")
        } catch (e: Exception) {
            logger.error("Trips reconcile failed", e)
            m["success"] = false
            m["error"] = e.message
        }
        return JSONObject(m as Map<*, *>)
    }

    /**
     * Reconstruct a minimal TripRecord from telemetry samples — start/end, duration,
     * GPS-derived distance and endpoints, speed stats. No scores or SoC (not derivable from
     * telemetry samples).
     */
    private fun buildBasicTrip(samples: List<TelemetrySample>, telemetryPath: String): TripRecord {
        val t = TripRecord()
        val first = samples.first()
        val last = samples.last()
        t.startTime = first.timestampMs
        t.endTime = last.timestampMs
        t.durationSeconds = max(0L, (t.endTime - t.startTime) / 1000).toInt()

        var distanceKm = 0.0
        var lastLat = 0.0
        var lastLon = 0.0
        var hasLast = false
        var maxSpeed = 0
        var speedSum = 0L
        var speedCount = 0L
        var startLat = 0.0
        var startLon = 0.0
        var endLat = 0.0
        var endLon = 0.0
        var haveStart = false

        for (s in samples) {
            if (s.speedKmh > maxSpeed) maxSpeed = s.speedKmh
            speedSum += s.speedKmh
            speedCount++
            if (s.lat != 0.0 && s.lon != 0.0) {
                if (!haveStart) {
                    startLat = s.lat
                    startLon = s.lon
                    haveStart = true
                }
                endLat = s.lat
                endLon = s.lon
                if (hasLast) {
                    val d = haversineKm(lastLat, lastLon, s.lat, s.lon)
                    if (d < 0.5) distanceKm += d // filter GPS jumps (matches the recorder)
                }
                lastLat = s.lat
                lastLon = s.lon
                hasLast = true
            }
        }

        t.distanceKm = distanceKm
        t.maxSpeedKmh = maxSpeed
        t.avgSpeedKmh = if (speedCount > 0) speedSum.toDouble() / speedCount else 0.0
        t.startLat = startLat
        t.startLon = startLon
        t.endLat = endLat
        t.endLon = endLon
        t.telemetryFilePath = telemetryPath
        return t
    }

    // ==================== PRIVATE ====================

    /** Initialize all trip analytics components and wire up the detector listener. */
    private fun initComponents() {
        // Database
        val db = TripDatabase()
        db.init()
        database = db

        // BladeWatch-reml.3: wipe the pre-EV/HEV trip history once. FIRST, before anything reads
        // trips, and sparing only the telemetry file of a manual trip that is still open.
        val store = ManualTripStore(File(MANUAL_STATE_PATH))
        val openTripFile = store.load()?.let { "${it.startTime}.jsonl.gz" }
        db.wipeTripHistoryOnce(
            StorageManager.getInstance().allTripsDirs,
            if (openTripFile != null) setOf(openTripFile) else emptySet(),
        )

        // Clean up orphaned trips from previous daemon crashes (no end_time, older than 24h).
        try {
            val cutoff = System.currentTimeMillis() - 24 * 60 * 60 * 1000L
            db.deleteOrphanedTrips(cutoff)
        } catch (e: Exception) {
            logger.warn("Orphaned trip cleanup failed: " + e.message)
        }

        // Backfill route_id for existing trips (idempotent — skips already-assigned trips).
        db.backfillRouteIds()

        // Detector
        val d = TripDetector()
        d.addListener(object : TripDetector.TripListener {
            override fun onTripStarted(trip: TripRecord) = handleTripStarted(trip)
            override fun onTripEnded(trip: TripRecord) {
                try {
                    handleTripEnded(trip)
                } finally {
                    // Saved state describes an OPEN trip; once it is persisted it must go, or the
                    // next daemon start would resurrect a trip that already ended.
                    if (trip.isManual) {
                        manualStore?.clear()
                        reminder.onManualTripEnded()
                        synchronized(manualLock) { manualExtras = JSONObject() }
                    }
                }
            }
            override fun onTripDiscarded(trip: TripRecord, reason: String) =
                handleTripDiscarded(trip, reason)
        })
        d.setDistanceProvider { recorder?.totalDistanceKm ?: 0.0 }
        // BladeWatch-nmao.3: trip lifecycle push notifications. TripDetector has no static
        // singleton for a notifier to reach into (unlike ChargingDetector), so it is
        // registered here, at the one place the detector instance is actually created.
        d.addListener(net.bladewatch.app.notifications.TripEventNotifier.getInstance())
        detector = d

        recorder = TripTelemetryRecorder(telemetryDataCollector)
        scoreEngine = TripScoreEngine()
        rangeEstimator = RangeEstimator(db, config)

        manualStore = store
        enabled = true
        restoreManualTrip()
        startManualTick()
        logger.info("Trip analytics components initialized")
    }

    // ==================== MANUAL TRIP STATE (BladeWatch-gklt.2) ====================

    /** Build the persisted state of the open manual trip from the live detector and recorder. */
    private fun currentManualState(): ManualTripStore.State? {
        val d = detector ?: return null
        val r = recorder ?: return null
        val t = d.getActiveTrip() ?: return null
        if (!t.isManual) return null
        return ManualTripStore.State(
            startTime = t.startTime,
            socStart = t.socStart,
            kwhStart = t.kwhStart,
            fuelPctStart = t.fuelPctStart,
            fuelConStart = t.fuelConStart,
            elecConStart = t.elecConStart,
            startLat = t.startLat,
            startLon = t.startLon,
            extTempC = t.extTempC,
            startOdometerKm = d.getStartOdometerKm(),
            stats = r.statsSnapshot(),
            telemetryPaused = r.isPaused,
            extras = manualExtras,
        )
    }

    /**
     * Change the extras of the open manual trip under the lock, then save. This is the ONLY way
     * other features (reminder state, per-mode energy segments) may modify the extras.
     */
    internal fun updateExtras(block: (JSONObject) -> Unit) {
        synchronized(manualLock) {
            block(manualExtras)
            saveManualState()
        }
    }

    /** Save the reminder's state with the open manual trip. */
    private fun persistReminder() {
        updateExtras {
            it.put("reminder", reminder.toJson())
            it.put("energySegments", segments.toJson())
        }
    }

    /** One reading of the car for the EV/HEV split. Every field falls back to unavailable (-1). */
    private fun readEnergySnapshot(): EnergyModeSegments.Snapshot {
        fun counter(v: Double) = if (v.isFinite() && v >= 0) v else -1.0
        val vdm = try { VehicleDataMonitor.getInstance() } catch (t: Throwable) { null }
        val mode = try {
            val c = BydDataCollector.getInstance()
            if (c.isInitialized) c.data?.energyMode ?: -1 else -1
        } catch (t: Throwable) {
            -1
        }
        val odometer = try { OdometerReader.getInstance().readOdometerKm() } catch (t: Throwable) { -1.0 }
        return EnergyModeSegments.Snapshot(
            timeMs = System.currentTimeMillis(),
            modeRaw = mode,
            odometerKm = if (odometer > 0) odometer else -1.0,
            elecConKwh = counter(try { vdm?.getTotalElecCon() ?: Double.NaN } catch (t: Throwable) { Double.NaN }),
            kwhRemaining = counter(try { vdm?.getBatteryRemainPowerKwh() ?: Double.NaN } catch (t: Throwable) { Double.NaN }),
            fuelConL = counter(try { vdm?.getTotalFuelCon() ?: Double.NaN } catch (t: Throwable) { Double.NaN }),
            gpsDistanceKm = recorder?.totalDistanceKm ?: -1.0,
        )
    }

    /** Feed the open trip's EV/HEV tracker (the sampler thread, every few seconds). */
    private fun sampleEnergy() {
        if (detector?.isTripActive() == true && segments.isTracking()) {
            segments.onSnapshot(readEnergySnapshot())
        }
    }

    /** Close the split and copy the per-mode figures onto [trip]. */
    private fun applyEnergySegments(trip: TripRecord) {
        if (!segments.isTracking()) return
        val isPhev = try { BydDataCollector.getInstance().isPhevVehicle() } catch (t: Throwable) { false }
        val r = segments.finish(readEnergySnapshot(), isPhev)
        trip.evKm = r.evKm
        trip.evKwh = r.evKwh
        trip.hevKm = r.hevKm
        trip.hevLitres = r.hevLitres
        trip.energySegmentsJson = r.segmentsJson
        logger.info(
            "Energy split: EV ${"%.2f".format(r.evKm)} km / ${"%.2f".format(r.evKwh)} kWh, " +
                "HEV ${"%.2f".format(r.hevKm)} km / ${"%.2f".format(r.hevLitres)} L"
        )
    }

    /** The reminder rules decided to remind: tell the companion (the in-car dialog polls). */
    private fun onReminderFired(reason: String) {
        val start = detector?.getActiveTrip()?.startTime ?: 0L
        logger.info("Manual trip reminder: $reason")
        try {
            net.bladewatch.app.notifications.TripEventNotifier.getInstance()
                .onManualTripReminder(reason, start)
        } catch (t: Throwable) {
            logger.warn("Manual trip reminder notification failed: " + t.message)
        }
    }

    /**
     * Write the open manual trip to disk. A no-op (true) when there is none; false when the
     * write failed. Holds [manualLock] so the extras are not mutated while being serialised.
     */
    internal fun saveManualState(): Boolean = synchronized(manualLock) {
        val state = currentManualState() ?: return true
        manualStore?.save(state) ?: true
    }

    /**
     * Re-open a manual trip that was open when the daemon last stopped. The recorder is restored
     * FIRST so that a trip already past its 7-day limit (which the detector then ends at once)
     * finds a running recorder to stop.
     */
    private fun restoreManualTrip() {
        val state = manualStore?.load() ?: return
        val d = detector ?: return
        val r = recorder ?: return
        logger.info("Restoring open manual trip started at ${state.startTime}")
        synchronized(manualLock) { manualExtras = state.extras }
        reminder.restore(state.extras.optJSONObject("reminder"))
        segments.restore(state.extras.optJSONObject("energySegments"))
        // A state saved before the split existed: track from now rather than not at all.
        if (!segments.isTracking()) segments.start(readEnergySnapshot())
        telemetryDataCollector?.let {
            try {
                it.startPolling()
            } catch (e: Exception) {
                logger.warn("Failed to start TelemetryDataCollector polling: " + e.message)
            }
        }
        r.restoreRecording(state.startTime, state.stats, state.telemetryPaused)
        d.restoreManualTrip(state.toTripRecord(), state.startOdometerKm)
    }

    /** Save the open manual trip every minute, so a crash loses at most a minute of stats. */
    private fun startManualTick() {
        val exec = Executors.newSingleThreadScheduledExecutor { r ->
            Thread(r, "ManualTrip-Tick").apply { isDaemon = true }
        }
        manualScheduler = exec
        exec.scheduleWithFixedDelay({
            try {
                if (detector?.isManualTripActive() == true) {
                    reminder.tick()
                    persistReminder()
                }
            } catch (t: Throwable) {
                // Never let one failed tick cancel the schedule.
                logger.warn("Manual trip tick failed: " + t.message)
            }
        }, TICK_SECONDS, TICK_SECONDS, TimeUnit.SECONDS)
        exec.scheduleWithFixedDelay({
            try {
                sampleEnergy()
            } catch (t: Throwable) {
                logger.warn("Energy sample failed: " + t.message)
            }
        }, ENERGY_SAMPLE_SECONDS, ENERGY_SAMPLE_SECONDS, TimeUnit.SECONDS)
    }

    /**
     * Handle a trip-started event. Starts the telemetry recorder using startTime as the trip
     * id (the DB auto-increment id does not exist yet).
     */
    private fun handleTripStarted(trip: TripRecord) {
        logger.info("Trip started at ${trip.startTime}")

        // Ensure the collector is polling so we get fresh data — it may not be if no recording
        // or overlay is active.
        telemetryDataCollector?.let {
            try {
                it.startPolling()
                logger.info("TelemetryDataCollector polling ensured for trip recording")
            } catch (e: Exception) {
                logger.warn("Failed to start TelemetryDataCollector polling: " + e.message)
            }
        }

        recorder?.startRecording(trip.startTime)
        segments.start(readEnergySnapshot())
    }

    /**
     * Handle a trip-ended event: stop the recorder, score the trip, cost it, persist it,
     * update rollups and routes, and feed the range estimator.
     */
    private fun handleTripEnded(trip: TripRecord) {
        logger.info(
            "Trip ended — duration=${trip.durationSeconds}s, distance=${trip.distanceKm}km"
        )

        // Release the telemetry polling ref acquired in handleTripStarted.
        telemetryDataCollector?.stopPolling()

        var telemetryPath: String? = null

        // 1. Stop the recorder and collect samples
        val samples = recorder?.let { rec ->
            telemetryPath = rec.stopRecording()
            rec.samplesForScoring
        }

        // 1b. Close the EV/HEV split with a last reading, now the recorder's GPS distance is final.
        applyEnergySegments(trip)

        // 2. Resolve trip energy (kWh) BEFORE scoring, and assign energyPerKm from it.
        //
        // ORDER IS THE FIX, not an optimisation. energyPerKm is what the UI shows as
        // efficiency, and its only SoC fallback used to live inside computeCosts, which ran
        // AFTER scoring. So on any trip where the kWh channel could not answer — a short hop
        // where integer-resolution SoC never moved, or a BMS that goes flaky with ACC off —
        // scoring saw 0 and 0 was stored. Consistency then measured that 0 against the fleet
        // average as a full 100% deviation and clamped itself to 0 as well.
        val nominalKwh = try {
            VehicleDataMonitor.getInstance().getNominalCapacityKwh()
        } catch (e: Exception) {
            logger.warn("Nominal capacity not available for energy estimation: " + e.message)
            0.0
        }
        // The ELECTRIC leg: kWh over the km driven in EV mode. A trip with no HEV driving (every BEV
        // trip) is its whole trip, resolved exactly as before; HEV driving is not part of it.
        val leg = electricLeg(trip, nominalKwh)
        val energyUsed = leg.kwh
        // Assigned UNCONDITIONALLY, including 0. This resolution is authoritative and supersedes the
        // provisional rate the detector computed at finalize time; leaving a stale value in place when
        // this resolves to 0 would let a reading that the plausibility gate rejected survive into the
        // rollups and the efficiency score. A trip with no electric leg (all HEV) has no kWh/km.
        trip.energyPerKm = if (leg.km > 0) energyUsed / leg.km else 0.0

        // 3. Compute scores, now that energyPerKm is on a single, settled unit axis.
        val engine = scoreEngine
        if (engine != null && !samples.isNullOrEmpty()) {
            engine.computeSummary(trip, samples)

            // Consistency uses recent trips from the DB. It is fed the resolved kWh/km and
            // ONLY that: the old code fell back to efficiencySocPerKm when energyPerKm was 0,
            // silently comparing SoC%/km (order 3.5) against a kWh/km history (order 0.15).
            // When there is no resolved figure, skip rather than compare across units.
            database?.let { db ->
                if (trip.energyPerKm > 0) {
                    val recentTrips = db.getTrips(30, 10)
                    trip.consistencyScore =
                        engine.computeConsistency(trip.energyPerKm, recentTrips)
                }
            }
        }

        // 4. Recorder stats (the recorder is authoritative for avg/max speed).
        recorder?.let { rec ->
            trip.maxSpeedKmh = rec.maxSpeedKmh
            trip.avgSpeedKmh = rec.avgSpeedKmh
        }

        // 5. Snapshot the rates and cost both legs, using the SAME resolved energy figure so
        // the cost and the efficiency can never disagree about how much was consumed.
        config?.let { cfg ->
            computeCosts(
                trip, cfg.getElectricityRate(), cfg.getCurrency(),
                cfg.getFuelPricePerL(), energyUsed
            )
        }

        trip.telemetryFilePath = telemetryPath

        // 4. Persist
        val db = database
        if (db == null || !db.isAvailable()) {
            logger.error(
                "CRITICAL: Trip database unavailable — trip NOT saved! " +
                    "distance=${trip.distanceKm}km"
            )
        } else {
            val dbId = db.insertTrip(trip)
            if (dbId <= 0) {
                logger.error("CRITICAL: database.insertTrip returned $dbId — trip NOT saved!")
            } else {
                renameTelemetryToDbId(trip, db, dbId, telemetryPath)

                // 5. Rollups
                db.updateWeeklyRollup(trip)
                db.updateMonthlyRollup(trip)

                // 6. Route id, for O(1) similar-trip lookups
                if (trip.startLat != 0.0 && trip.startLon != 0.0) {
                    val routeId = db.findOrCreateRoute(
                        trip.startLat, trip.startLon, trip.endLat, trip.endLon, trip.distanceKm
                    )
                    if (routeId > 0) {
                        trip.routeId = routeId
                        db.updateTrip(trip)
                        logger.info("Trip assigned to route $routeId")
                    }
                }

                logger.info(
                    "Trip saved — id=$dbId scores=[A=${trip.anticipationScore}" +
                        " S=${trip.smoothnessScore}" +
                        " SD=${trip.speedDisciplineScore}" +
                        " E=${trip.efficiencyScore}" +
                        " C=${trip.consistencyScore}]"
                )
            }
        }

        // 7. Feed the range estimator
        rangeEstimator?.onTripCompleted(trip)
    }

    /**
     * Rename the telemetry file from its startTime-based name to the DB id, once the insert
     * has given us one, and point the record at the new path.
     */
    private fun renameTelemetryToDbId(
        trip: TripRecord,
        db: TripDatabase,
        dbId: Long,
        telemetryPath: String?,
    ) {
        val newPath = recorder?.getTelemetryFilePath(dbId) ?: return
        if (telemetryPath == null) return

        val oldFile = File(telemetryPath)
        val newFile = File(newPath)
        if (!oldFile.exists() || oldFile.absolutePath == newFile.absolutePath) return

        if (oldFile.renameTo(newFile)) {
            trip.telemetryFilePath = newPath
            db.updateTrip(trip)
            logger.info("Telemetry file renamed: ${oldFile.name} -> ${newFile.name}")
        } else {
            logger.warn("Failed to rename telemetry file to ${newFile.name}")
        }
    }

    /** Handle a discarded trip: stop the recorder and clean up its telemetry file. */
    private fun handleTripDiscarded(trip: TripRecord, reason: String) {
        logger.info("Trip discarded: $reason")

        // Nothing to record for a discarded trip: drop the EV/HEV tracker.
        if (segments.isTracking()) segments.finish(readEnergySnapshot(), false)

        // Release the telemetry polling ref acquired in handleTripStarted.
        telemetryDataCollector?.stopPolling()

        recorder?.let { rec ->
            val telemetryPath = rec.stopRecording()
            if (telemetryPath != null) {
                val telemetryFile = File(telemetryPath)
                if (telemetryFile.exists()) {
                    if (telemetryFile.delete()) {
                        logger.info("Discarded telemetry file: ${telemetryFile.name}")
                    } else {
                        logger.warn(
                            "Failed to delete discarded telemetry file: ${telemetryFile.name}"
                        )
                    }
                }
            }
        }
    }

    companion object {
        private val logger = DaemonLogger.getInstance("TripAnalyticsManager")

        /**
         * Where the open manual trip is saved: next to the trip database, which already lives on
         * shared storage (never under /data/local/tmp, which the app UID cannot create files in).
         */
        private const val MANUAL_STATE_PATH =
            "/storage/emulated/0/BladeWatch/data/active_manual_trip.json"

        private const val TICK_SECONDS = 60L

        /** How often the EV/HEV tracker is fed. Slower than the 5 Hz telemetry on purpose: it only
         * needs to notice a mode change, and each reading takes the HAL lock. */
        private const val ENERGY_SAMPLE_SECONDS = 5L

        private fun haversineKm(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
            val earthRadiusKm = 6371.0
            val dLat = Math.toRadians(lat2 - lat1)
            val dLon = Math.toRadians(lon2 - lon1)
            val a = sin(dLat / 2) * sin(dLat / 2) +
                cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) *
                sin(dLon / 2) * sin(dLon / 2)
            return earthRadiusKm * 2 * atan2(sqrt(a), sqrt(1 - a))
        }

        /**
         * Resolve both cost legs onto [trip]: the electric leg, the PHEV fuel leg, and the
         * combined `tripCost`.
         *
         * Pure and internal on purpose. `tripCost` is the user's stored cost history, so "a
         * BEV still costs exactly what it used to" has to be a test, not a claim.
         *
         * **Litres come from the lifetime COUNTER delta, never from tank percent.** Percent has
         * no litre scale without a tank capacity, and BYD local data does not expose one.
         *
         * @param nominalKwh pack capacity for the SoC fallback, or 0 when unknown
         */
        /**
         * Resolve the trip's electrical energy use in kWh, in three tiers, most to least
         * accurate:
         *
         *  1. **Metered** — delta of the HAL's cumulative electricity counter. The only tier
         *     with the resolution to measure a short trip.
         *  2. **Remaining-energy delta** — derived from an integer-resolution SoC, so it reads
         *     a flat 0 below roughly 4 km.
         *  3. **SoC estimate** — SoC delta x nominal pack capacity.
         *
         * The first two live in [TripRecord.getEnergyUsedKwh]. Returns 0 when no source is
         * usable (SoC flat or rising, no capacity estimate) — an honest 0, not an invention.
         *
         * Called BEFORE scoring so the efficiency axis and the cost math see the same kWh
         * figure on a single unit axis.
         *
         * @param nominalKwh pack capacity for the SoC tier, or 0 when unknown. BladeWatch has
         *   no SoH source, so the pack is used at face value.
         */
        /** The electric leg a trip is costed and scored on: kWh over the km driven in EV mode. */
        internal data class ElectricLeg(val kwh: Double, val km: Double)

        /**
         * The electric leg of [trip] (BladeWatch-reml.2).
         *
         *  - **No HEV driving** (a BEV, or an all-EV trip): the whole trip, with the energy resolved
         *    by [resolveTripEnergyKwh] exactly as before. This is the BEV parity guarantee.
         *  - **HEV driving present**: only the EV segments' kWh and km. HEV driving contributes no
         *    electricity at all (owner decision), and a trip with no EV driving has no electric leg.
         */
        @JvmStatic
        internal fun electricLeg(trip: TripRecord, nominalKwh: Double): ElectricLeg =
            if (trip.hasHevLeg()) {
                ElectricLeg(trip.evKwh, trip.evKm)
            } else {
                ElectricLeg(resolveTripEnergyKwh(trip, nominalKwh), trip.distanceKm)
            }

        @JvmStatic
        internal fun resolveTripEnergyKwh(trip: TripRecord, nominalKwh: Double): Double {
            // Reject a metered delta no battery could have supplied over this distance
            // (a generous 100 kWh/100 km ceiling, plus 1 kWh of slack for very short trips).
            // A counter reset or a unit change between the two reads would otherwise be booked
            // as a huge, confidently-wrong measurement. Clearing the snapshots makes every
            // downstream tier fall through consistently instead of disagreeing.
            if (trip.hasMeteredEnergy() && trip.distanceKm > 0) {
                val maxPlausibleKwh = 1.0 + trip.distanceKm
                if (trip.getMeteredEnergyKwh() > maxPlausibleKwh) {
                    logger.warn(
                        "Metered energy implausible (${"%.2f".format(trip.getMeteredEnergyKwh())}" +
                            " kWh over ${"%.2f".format(trip.distanceKm)} km) —" +
                            " discarding accumulator, using SoC path"
                    )
                    trip.elecConStart = -1.0
                    trip.elecConEnd = -1.0
                }
            }

            val measured = trip.getEnergyUsedKwh()
            if (measured > 0) return measured

            // The meter reported a true zero AND the remaining-energy delta agreed, so 0 is a
            // measurement rather than a missing value — estimating from SoC would manufacture
            // consumption the vehicle says did not happen. That is the normal reading for a
            // PHEV leg driven entirely on the engine.
            //
            // Unless SoC disagrees CLEARLY. SoC is integer-resolution here, so a single 1%
            // step is indistinguishable from quantisation noise or from parasitic/HVAC draw,
            // and treating it as propulsion energy would invent roughly 0.6 kWh of cost the
            // meter says was never drawn. Requiring a margin ABOVE one step means only an
            // unmistakable drop overrides the meter, while a genuinely stuck counter over a
            // real drive still does.
            val socDrop =
                if (trip.socStart > 0 && trip.socEnd > 0) trip.socStart - trip.socEnd else 0.0
            val socFellClearly = socDrop > SOC_OVERRIDE_MIN_DROP_PCT
            if (trip.hasMeteredEnergy() && !socFellClearly) return 0.0

            // Estimate from the SoC delta. No SoH source exists, so nominal is used at face
            // value and the pack is treated as healthy.
            if (trip.socStart > 0 && trip.socEnd > 0 && trip.socStart > trip.socEnd &&
                nominalKwh > 0
            ) {
                val estimated = ((trip.socStart - trip.socEnd) / 100.0) * nominalKwh
                logger.info(
                    "Energy estimated from SoC: ${"%.1f".format(trip.socStart)}%" +
                        " -> ${"%.1f".format(trip.socEnd)}%" +
                        " = ${"%.2f".format(estimated)} kWh" +
                        " (nominal=${"%.1f".format(nominalKwh)})"
                )
                return estimated
            }
            return 0.0
        }

        /**
         * Minimum SoC drop, in percent, that lets the SoC tier override a metered zero.
         *
         * SoC is integer-resolution on this HAL, so anything at or below one step is noise;
         * this sits above it.
         */
        internal const val SOC_OVERRIDE_MIN_DROP_PCT = 1.0

        /**
         * A double safe to store on a [TripRecord], or 0.
         *
         * Record fields are serialised, and JSON has no representation for Infinity or NaN —
         * `JSONObject.put` rejects them outright. Since `toJson` catches, a non-finite field
         * does not surface as an error but as a trip object silently truncated at that key.
         */
        private fun finiteOrZero(v: Double): Double = if (v.isFinite()) v else 0.0

        @JvmStatic
        internal fun computeCosts(
            trip: TripRecord,
            electricityRate: Double,
            currency: String?,
            fuelPricePerL: Double,
            energyUsed: Double,
        ) {
            // Sanitised on the way ONTO the record, not merely on the way into config.
            //
            // A record field is what gets serialised, and JSON cannot carry a non-finite
            // number: `JSONObject.put` throws and `toJson` — which catches — then emits a
            // trip TRUNCATED at that key rather than a clean error. Infinity slips past the
            // obvious checks (`Infinity > 0` is true), so the guard has to be isFinite.
            trip.electricityRate = finiteOrZero(electricityRate)
            trip.currency = currency
            trip.fuelPricePerL = finiteOrZero(fuelPricePerL)

            // energyPerKm stays kWh/km and ELECTRIC-ONLY, and is set by the caller from the
            // same resolved figure passed in here. Folding litres in would silently change
            // what every stored efficiency figure means and break historical comparison.
            if (energyUsed > 0 && trip.electricityRate > 0) {
                trip.electricCost = energyUsed * trip.electricityRate
            }

            // ---- fuel leg ----
            // A trip with the EV/HEV split (every trip recorded since BladeWatch-reml.1) burned fuel
            // ONLY while in HEV mode, so its litres are the HEV segments' and nothing else: EV
            // driving is costed by kWh alone, even if the engine's lifetime counter moved. A trip
            // without the split (a legacy record) keeps the whole-trip counter delta below.
            if (trip.hasEnergySplit()) {
                trip.litresUsed = trip.hevLitres
                if (trip.fuelPricePerL > 0) {
                    trip.fuelCost = trip.litresUsed * trip.fuelPricePerL
                }
            } else if (trip.fuelConStart >= 0 && trip.fuelConEnd >= 0 &&
                trip.fuelConEnd >= trip.fuelConStart
            ) {
                // Both ends must be real readings (-1 means never read). A counter that went
                // BACKWARDS is a HAL reset or an overflow, not negative consumption, so it yields 0
                // rather than a negative that would subtract from the trip cost.
                trip.litresUsed = trip.fuelConEnd - trip.fuelConStart
                // A litresUsed of 0 is a VALID result — a PHEV leg driven entirely on
                // electricity — and is stored as such. The litres were burned whether or not
                // the owner configured a price, so they are recorded even when the leg cannot
                // be costed.
                if (trip.fuelPricePerL > 0) {
                    trip.fuelCost = trip.litresUsed * trip.fuelPricePerL
                }
            }

            // On a BEV fuelCost is 0, so this is byte-identical to the electric-only figure
            // tripCost has always carried.
            trip.tripCost = trip.electricCost + trip.fuelCost

            if (trip.tripCost > 0) {
                logger.info(
                    "Trip cost: electric=$currency${"%.2f".format(trip.electricCost)}" +
                        " + fuel=$currency${"%.2f".format(trip.fuelCost)}" +
                        " (${"%.2f".format(trip.litresUsed)} L)" +
                        " = $currency${"%.2f".format(trip.tripCost)}"
                )
            }
        }
    }
}
