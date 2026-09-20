package net.bladewatch.app.monitor

import net.bladewatch.app.byd.BydDataCollector
import net.bladewatch.app.byd.BydVehicleData
import net.bladewatch.app.logging.DaemonLogger

import org.json.JSONArray
import org.json.JSONObject

import java.io.File
import java.sql.Connection
import java.sql.DriverManager
import java.sql.Types
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit

/**
 * SOTA SocHistoryDatabase - Uses H2 embedded database (100% pure Java).
 *
 * H2 advantages over SQLite/SQLDroid:
 * - Zero native dependencies (no .so files, no UnsatisfiedLinkError)
 * - Zero Android framework dependency (no Context, no package verification)
 * - Full SQL support with SQLite compatibility mode
 * - Works perfectly for UID 2000 daemon processes
 */
class SocHistoryDatabase private constructor() {

    // H2 Connection (kept open for performance)
    private var connection: Connection? = null

    private var scheduler: ScheduledExecutorService? = null

    // Named `running`/`initialized` rather than `isRunning`/`isInitialized`: Kotlin cannot
    // have both a property and a function of the same name, and isRunning() is public API.
    @Volatile private var running = false
    @Volatile private var initialized = false

    // Charging session tracking
    private var wasCharging = false
    private var chargingStartTime: Long = 0
    private var chargingStartSoc = 0.0

    // Last recorded values for deduplication
    private var lastRecordTime: Long = 0
    private var lastRecordedSoc = -1.0
    private var lastRecordedKwh = -1.0

    init {
        // Load the H2 JDBC driver (pure Java - always works)
        try {
            Class.forName("org.h2.Driver")
            logger.info("H2 JDBC Driver loaded successfully")
        } catch (e: ClassNotFoundException) {
            logger.error("H2 Driver not found! Check gradle dependencies.", e)
        } catch (e: Exception) {
            logger.error("Failed to load H2 Driver: " + e.message, e)
        }
    }

    // ==================== LIFECYCLE ====================

    fun init() {
        if (initialized) return

        synchronized(lock) {
            if (initialized) return  // Double-check after acquiring lock

            logger.info("Initializing H2 database at: $DB_PATH")

            val maxRetries = 3
            val retryDelayMs = 1000

            for (attempt in 1..maxRetries) {
                try {
                    // Open H2 connection (pure Java - no native code)
                    val conn = DriverManager.getConnection(JDBC_URL, "sa", "")
                    connection = conn
                    logger.info("H2 connection established")

                    // Tune H2 for embedded daemon use
                    conn.createStatement().use { stmt ->
                        stmt.execute("SET CACHE_SIZE 8192")  // 8MB cache
                    }

                    // Create tables
                    createTables()

                    initialized = true
                    logger.info("SOC History Database initialized via H2 (Pure Java): $DB_PATH")
                    return  // Success - exit
                } catch (e: Exception) {
                    val msg = e.message
                    val isLockError = msg != null && (msg.contains("Locked by another process") ||
                        msg.contains("lock.db") || msg.contains("already in use"))

                    if (isLockError && attempt < maxRetries) {
                        logger.warn(
                            "Database locked (attempt $attempt/$maxRetries), cleaning up stale locks..."
                        )
                        cleanupStaleLocks()
                        try {
                            Thread.sleep((retryDelayMs * attempt).toLong())  // Exponential backoff
                        } catch (ie: InterruptedException) {
                            Thread.currentThread().interrupt()
                            break
                        }
                    } else {
                        logger.error(
                            "Failed to initialize SOC database: " + e.javaClass.name + " - " + msg, e
                        )
                        break
                    }
                }
            }
        }
    }

    /**
     * Clean up stale lock files that may have been left by crashed processes.
     */
    private fun cleanupStaleLocks() {
        try {
            val lockFile = File("$DB_PATH.lock.db")
            if (lockFile.exists()) {
                // Check if the lock file is stale (older than 5 minutes with no active process)
                val ageMs = System.currentTimeMillis() - lockFile.lastModified()
                if (ageMs > 5 * 60 * 1000) {  // 5 minutes
                    if (lockFile.delete()) {
                        logger.info("Deleted stale lock file (age: " + (ageMs / 1000) + "s)")
                    }
                }
            }

            // Also try to clean up trace files
            val traceFile = File("$DB_PATH.trace.db")
            if (traceFile.exists()) {
                traceFile.delete()
            }
        } catch (e: Exception) {
            logger.debug("Lock cleanup failed: " + e.message)
        }
    }

    private fun createTables() {
        connection!!.createStatement().use { stmt ->
            // SOC history table
            stmt.execute(
                "CREATE TABLE IF NOT EXISTS " + TABLE_SOC + " (" +
                    "id IDENTITY PRIMARY KEY," +
                    "timestamp BIGINT NOT NULL," +
                    "soc_percent REAL NOT NULL," +
                    "is_charging INTEGER DEFAULT 0," +
                    "charging_power_kw REAL DEFAULT 0," +
                    "voltage_v REAL DEFAULT 0," +
                    "range_km INTEGER DEFAULT 0," +
                    "remaining_kwh REAL DEFAULT 0" +
                    ");"
            )

            // Add remaining_kwh column if it doesn't exist (migration for existing DBs)
            try {
                stmt.execute(
                    "ALTER TABLE " + TABLE_SOC + " ADD COLUMN IF NOT EXISTS remaining_kwh REAL DEFAULT 0;"
                )
            } catch (ignored: Exception) {
                logger.warn(
                    "Migration: remaining_kwh column add failed (likely already exists): " +
                        ignored.message
                )
            }

            // Migration: add battery health columns
            val newColumns = arrayOf(
                "hv_temp_high REAL DEFAULT -999",
                "hv_temp_low REAL DEFAULT -999",
                "hv_temp_avg REAL DEFAULT -999",
                "cell_volt_high REAL DEFAULT -999",
                "cell_volt_low REAL DEFAULT -999",
                "soh_percent REAL DEFAULT -999"
            )
            for (col in newColumns) {
                try {
                    stmt.execute(
                        "ALTER TABLE " + TABLE_SOC + " ADD COLUMN IF NOT EXISTS " + col + ";"
                    )
                } catch (ignored: Exception) {
                    logger.warn(
                        "Migration: column add failed for " + col +
                            " (likely already exists): " + ignored.message
                    )
                }
            }

            // Index for fast time-based queries
            stmt.execute(
                "CREATE INDEX IF NOT EXISTS idx_soc_timestamp ON " + TABLE_SOC + "(timestamp);"
            )

            // Charging sessions table
            stmt.execute(
                "CREATE TABLE IF NOT EXISTS " + TABLE_CHARGING + " (" +
                    "id IDENTITY PRIMARY KEY," +
                    "start_time BIGINT NOT NULL," +
                    "end_time BIGINT," +
                    "start_soc REAL NOT NULL," +
                    "end_soc REAL," +
                    "energy_added_kwh REAL," +
                    "peak_power_kw REAL" +
                    ");"
            )

            stmt.execute(
                "CREATE INDEX IF NOT EXISTS idx_charging_start ON " + TABLE_CHARGING + "(start_time);"
            )

            // ACC events table — every ACC ON/OFF transition is logged here so
            // the dashboard "parking delta" insight can compute changes across
            // a real park-and-return cycle (not inferred from SOC sample gaps).
            // Snapshot fields are nullable: if BydDataCollector is not yet
            // initialized at the moment of the event we still record the
            // transition so future correlation is possible.
            stmt.execute(
                "CREATE TABLE IF NOT EXISTS " + TABLE_ACC_EVENTS + " (" +
                    "id IDENTITY PRIMARY KEY," +
                    "timestamp BIGINT NOT NULL," +
                    "event_type VARCHAR(8) NOT NULL," +    // 'ON' or 'OFF'
                    "soc_percent REAL," +                  // nullable if read failed
                    "remaining_kwh REAL," +                // nullable
                    "voltage_v REAL," +                    // nullable
                    "range_km INTEGER" +                   // nullable
                    ");"
            )

            stmt.execute(
                "CREATE INDEX IF NOT EXISTS idx_acc_events_ts ON " + TABLE_ACC_EVENTS + "(timestamp DESC);"
            )

            logger.info("acc_events table ready (migration idempotent)")
        }
    }

    fun start() {
        if (running) return

        if (!initialized) {
            init()
        }

        if (!initialized) {
            logger.error("Cannot start SOC history - database init failed")
            return
        }

        running = true

        val exec = Executors.newSingleThreadScheduledExecutor { r ->
            val t = Thread(r, "SocHistoryDB")
            t.priority = Thread.MIN_PRIORITY
            // Set uncaught exception handler to prevent silent death
            t.setUncaughtExceptionHandler { _, ex ->
                logger.error("Uncaught exception in SocHistoryDB thread: " + ex.message, ex)
            }
            t
        }
        scheduler = exec

        // Record SOC every minute - wrap in Runnable that catches all exceptions
        exec.scheduleAtFixedRate({
            try {
                recordCurrentSoc()
            } catch (t: Throwable) {
                // Catch everything including Errors to prevent scheduler death
                logger.error("Critical error in SOC recording task: " + t.message, t)
            }
        }, 0, SAMPLE_INTERVAL_MS, TimeUnit.MILLISECONDS)

        // Cleanup old data daily
        exec.scheduleAtFixedRate({
            try {
                cleanupOldData()
            } catch (t: Throwable) {
                logger.error("Critical error in cleanup task: " + t.message, t)
            }
        }, 1, 24, TimeUnit.HOURS)

        logger.info("SOC history recording started (interval: " + SAMPLE_INTERVAL_MS + "ms)")
    }

    fun stop() {
        running = false
        scheduler?.let { exec ->
            exec.shutdown()
            try {
                // Give an in-flight tick a moment to finish so we don't close
                // the connection out from under it. shutdownNow() interrupts
                // the worker but doesn't wait — and the H2 write isn't
                // interruptible, so the tick still hits the JDBC layer with
                // a closed connection.
                if (!exec.awaitTermination(2, TimeUnit.SECONDS)) {
                    exec.shutdownNow()
                }
            } catch (ie: InterruptedException) {
                exec.shutdownNow()
                Thread.currentThread().interrupt()
            }
            scheduler = null
        }

        connection?.let { conn ->
            try {
                conn.close()
            } catch (ignored: Exception) {
                logger.warn("Connection close failed (non-fatal): " + ignored.message)
            }
            connection = null
        }
        initialized = false

        logger.info("SOC history recording stopped")
    }

    private fun reconnect() {
        // After stop() flips running=false the connection is intentionally
        // closed. Re-opening here would re-acquire the lock file just before
        // the JVM exits, leaving an orphaned .lock.db that blocks the next
        // daemon start. Same defense in TripDatabase.reconnect.
        if (!running) return
        try {
            val conn = connection
            if (conn == null || conn.isClosed) {
                connection = DriverManager.getConnection(JDBC_URL, "sa", "")
                logger.debug("H2 connection re-established")
            }
        } catch (e: Exception) {
            logger.error("Failed to reconnect to H2", e)
        }
    }

    // ==================== DATA RECORDING ====================

    private fun recordCurrentSoc() {
        // Wrap entire method in try-catch to prevent scheduler death
        try {
            // Bail out cleanly when stop() has already begun — otherwise we
            // race connection.close() and trip H2's "already closed" path,
            // which re-opens the DB on reconnect() and orphans the lock file.
            if (!running) return
            if (!initialized || connection == null) {
                logger.debug("SOC recording skipped: not initialized or no connection")
                reconnect()
                return
            }

            val monitor = VehicleDataMonitor.getInstance()

            val socData = monitor.getBatterySoc()
            val chargingData = monitor.getChargingState()
            val rangeData = monitor.getDrivingRange()
            val powerData = monitor.getBatteryPower()

            if (socData == null) {
                logger.debug("SOC recording skipped: no SOC data available")
                return
            }

            val soc = socData.socPercent
            val isCharging = chargingData != null &&
                chargingData.status == ChargingStateData.ChargingStatus.CHARGING
            val chargingPower = chargingData?.chargingPowerKW ?: 0.0
            val voltage = powerData?.voltageVolts ?: 0.0
            val range = rangeData?.elecRangeKm ?: 0

            // SOTA: Get remaining battery power in kWh from BYDAutoPowerDevice
            var remainingKwh = 0.0
            try {
                remainingKwh = monitor.getBatteryRemainPowerKwh()
            } catch (e: Exception) {
                logger.debug("Failed to get remaining kWh: " + e.message)
            }

            // HV battery thermal data — from BydDataCollector (has real cell temps via Integer.TYPE)
            var hvTempHigh = -999.0
            var hvTempLow = -999.0
            var hvTempAvg = -999.0
            var cellVoltHigh = -999.0
            var cellVoltLow = -999.0
            try {
                val collector = BydDataCollector.getInstance()
                if (collector.isInitialized) {
                    val vd = collector.data
                    if (vd != null) {
                        if (!vd.highCellTempC.isNaN()) hvTempHigh = vd.highCellTempC
                        if (!vd.lowCellTempC.isNaN()) hvTempLow = vd.lowCellTempC
                        if (!vd.avgCellTempC.isNaN()) hvTempAvg = vd.avgCellTempC
                        if (!vd.highCellVoltage.isNaN()) cellVoltHigh = vd.highCellVoltage
                        if (!vd.lowCellVoltage.isNaN()) cellVoltLow = vd.lowCellVoltage
                    }
                }
            } catch (e: Exception) {
                logger.debug("Failed to get collector data: " + e.message)
            }
            // Fallback to VehicleDataMonitor if collector didn't have temps
            if (hvTempHigh == -999.0 && hvTempLow == -999.0 && hvTempAvg == -999.0) {
                val thermalData = monitor.getBatteryThermal()
                if (thermalData != null && thermalData.hasData()) {
                    if (!thermalData.highestTempC.isNaN()) hvTempHigh = thermalData.highestTempC
                    if (!thermalData.lowestTempC.isNaN()) hvTempLow = thermalData.lowestTempC
                    if (!thermalData.averageTempC.isNaN()) hvTempAvg = thermalData.averageTempC
                }
            }

            // SOH estimation has been removed (no BYD-local degradation source).
            // Persist the sentinel so the soh_percent column stays well-formed and
            // history queries that filter soh_percent > 0 simply skip these rows.
            val sohPercent = -999.0

            val now = System.currentTimeMillis()

            // Record at least once every 10 minutes regardless of SOC change
            // This ensures continuous data even when parked (5x the 2-min interval)
            val maxInterval = SAMPLE_INTERVAL_MS * 5 // 10 minutes
            val forceRecord = (now - lastRecordTime) >= maxInterval

            // Always record on charging-state transitions so the chart's charging
            // band and the charging_sessions table both see the start/end edges
            // even when SOC hasn't moved 0.5% yet (typical for the first minutes
            // of AC charging on a PHEV, and for any unplug while at 100%).
            val stateTransition = (isCharging != wasCharging)

            // BEV BMS reports remainKwh independently of SOC and can drift while
            // SOC stays in the same percent bucket — record those updates too.
            val kwhMoved = lastRecordedKwh >= 0 && remainingKwh > 0 &&
                Math.abs(remainingKwh - lastRecordedKwh) >= 0.5

            // Skip only if nothing meaningful changed AND we recorded recently
            if (!forceRecord && !stateTransition && !kwhMoved &&
                lastRecordedSoc >= 0 && Math.abs(soc - lastRecordedSoc) < 0.5
            ) {
                return
            }

            // Check connection is still valid
            try {
                if (connection!!.isClosed) {
                    logger.info("Connection closed, reconnecting...")
                    reconnect()
                    val reopened = connection
                    if (reopened == null || reopened.isClosed) {
                        logger.error("Failed to reconnect to database")
                        return
                    }
                }
            } catch (e: Exception) {
                logger.error("Connection check failed", e)
                reconnect()
                return
            }

            // Insert with all battery health columns
            val sql = "INSERT INTO " + TABLE_SOC +
                " (timestamp, soc_percent, is_charging, charging_power_kw, voltage_v, range_km, remaining_kwh," +
                " hv_temp_high, hv_temp_low, hv_temp_avg, cell_volt_high, cell_volt_low, soh_percent) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"

            connection!!.prepareStatement(sql).use { pstmt ->
                pstmt.setLong(1, now)
                pstmt.setDouble(2, soc)
                pstmt.setInt(3, if (isCharging) 1 else 0)
                pstmt.setDouble(4, chargingPower)
                pstmt.setDouble(5, voltage)
                pstmt.setInt(6, range)
                pstmt.setDouble(7, remainingKwh)
                pstmt.setDouble(8, hvTempHigh)
                pstmt.setDouble(9, hvTempLow)
                pstmt.setDouble(10, hvTempAvg)
                pstmt.setDouble(11, cellVoltHigh)
                pstmt.setDouble(12, cellVoltLow)
                pstmt.setDouble(13, sohPercent)
                pstmt.executeUpdate()
            }

            lastRecordTime = now
            lastRecordedSoc = soc
            if (remainingKwh > 0) lastRecordedKwh = remainingKwh

            logger.debug("Recorded SOC: " + soc + "% (charging: " + isCharging + ")")

            // Track charging sessions
            trackChargingSession(isCharging, soc, chargingPower, now)
        } catch (e: Exception) {
            // Log but don't rethrow - scheduler must continue running
            logger.error("Failed to record SOC: " + e.message, e)
            try {
                reconnect()
            } catch (re: Exception) {
                logger.error("Reconnect also failed: " + re.message)
            }
        }
    }

    private fun trackChargingSession(isCharging: Boolean, soc: Double, power: Double, now: Long) {
        val conn = connection
        if (!initialized || conn == null) return

        try {
            if (isCharging && !wasCharging) {
                // Charging started
                chargingStartTime = now
                chargingStartSoc = soc

                val sql = "INSERT INTO " + TABLE_CHARGING +
                    " (start_time, start_soc, peak_power_kw) VALUES (?, ?, ?);"

                conn.prepareStatement(sql).use { pstmt ->
                    pstmt.setLong(1, now)
                    pstmt.setDouble(2, soc)
                    pstmt.setDouble(3, power)
                    pstmt.executeUpdate()
                }

                logger.info("Charging session started at $soc%")
            } else if (!isCharging && wasCharging) {
                // Charging ended — compute energy added and update SOH
                val socDelta = soc - chargingStartSoc

                // Compute energy added using nominal capacity if available,
                // otherwise fall back to rough estimate
                var energyAdded: Double
                var isAcCharge = true // Assume AC unless peak power > 20 kW
                var packTemp = 25.0    // Default — updated below if available

                val nominalKwh = VehicleDataMonitor.getInstance().getNominalCapacityKwh()

                if (nominalKwh > 0 && socDelta > 0) {
                    // Energy added ≈ socDelta% × nominalKwh (BYD local nominal pack
                    // capacity; SOH degradation is not modelled).
                    energyAdded = (socDelta / 100.0) * nominalKwh
                } else {
                    energyAdded = socDelta * 0.6 // Rough fallback
                }

                // Get battery temperature for calibration quality check
                try {
                    val thermal = VehicleDataMonitor.getInstance().getBatteryThermal()
                    if (thermal != null && thermal.hasData() && !thermal.averageTempC.isNaN()) {
                        packTemp = thermal.averageTempC
                    }
                } catch (e: Exception) {
                    logger.warn(
                        "Failed to get battery thermal data for charging session: " + e.message
                    )
                }

                // Detect DC fast charging from peak power
                // AC charging is typically < 11 kW (single phase) or < 22 kW (three phase)
                if (power > 20) isAcCharge = false

                val sql = "UPDATE " + TABLE_CHARGING +
                    " SET end_time = ?, end_soc = ?, energy_added_kwh = ? " +
                    "WHERE start_time = ? AND end_time IS NULL;"

                conn.prepareStatement(sql).use { pstmt ->
                    pstmt.setLong(1, now)
                    pstmt.setDouble(2, soc)
                    pstmt.setDouble(3, energyAdded)
                    pstmt.setLong(4, chargingStartTime)
                    pstmt.executeUpdate()
                }

                logger.info(
                    "Charging session ended at " + soc + "% (+" +
                        String.format("%.1f", socDelta) + "%, ~" +
                        String.format("%.1f", energyAdded) + " kWh, " +
                        (if (isAcCharge) "AC" else "DC") + ", " +
                        String.format("%.0f", packTemp) + "°C)"
                )
            }

            wasCharging = isCharging
        } catch (e: Exception) {
            logger.error("Failed to track charging session", e)
        }
    }

    // ==================== DATA RETRIEVAL ====================

    /**
     * Get SOC history for charting.
     * Uses time-based bucketing for efficient downsampling - larger windows = larger buckets.
     * Returns data in ASC order (oldest first) for time-series chart rendering.
     */
    fun getSocHistory(hoursBack: Int, maxPoints: Int): JSONArray {
        val results = JSONArray()

        val conn = connection
        if (!initialized || conn == null) {
            logger.debug("Database not initialized for getSocHistory")
            return results
        }

        try {
            val now = System.currentTimeMillis()
            val hours = Math.min(hoursBack, 168)
            val startTime = now - (hours * 60 * 60 * 1000L)

            // Calculate bucket size based on time window
            // Goal: ~maxPoints buckets across the time range
            // Minimum bucket: 2 minutes (one sample), Maximum: 30 minutes for week view
            val timeRangeMs = hours * 60 * 60 * 1000L
            var bucketMs = Math.max(120_000L, timeRangeMs / maxPoints) // At least 2 min
            bucketMs = Math.min(bucketMs, 30 * 60 * 1000L) // Cap at 30 min

            // Time-bucketed query - takes first sample from each bucket
            // Much more efficient than row numbering for large datasets
            val querySql =
                "SELECT MIN(timestamp) as t, " +
                    "  AVG(soc_percent) as soc, " +
                    "  MAX(is_charging) as charging, " +
                    "  AVG(CASE WHEN charging_power_kw > 0 THEN charging_power_kw END) as power, " +
                    "  AVG(range_km) as range, " +
                    "  AVG(CASE WHEN remaining_kwh > 0 THEN remaining_kwh END) as kwh, " +
                    "  AVG(CASE WHEN voltage_v > 0 THEN voltage_v END) as volt, " +
                    "  AVG(CASE WHEN hv_temp_avg > -999 THEN hv_temp_avg END) as temp, " +
                    "  AVG(CASE WHEN soh_percent > 0 THEN soh_percent END) as soh " +
                    "FROM " + TABLE_SOC + " " +
                    "WHERE timestamp >= ? " +
                    "GROUP BY (timestamp / ?) " +
                    "ORDER BY t ASC " +
                    "LIMIT ?;"

            conn.prepareStatement(querySql).use { pstmt ->
                pstmt.setLong(1, startTime)
                pstmt.setLong(2, bucketMs)
                pstmt.setInt(3, maxPoints)

                pstmt.executeQuery().use { rs ->
                    while (rs.next()) {
                        val row = JSONObject()
                        row.put("t", rs.getLong("t"))
                        row.put("soc", Math.round(rs.getDouble("soc") * 10) / 10.0) // 1 decimal
                        row.put("charging", rs.getInt("charging") == 1)
                        val power = rs.getDouble("power")
                        row.put("power", if (rs.wasNull()) 0 else Math.round(power * 100) / 100.0)
                        row.put("range", rs.getDouble("range").toInt())
                        val kwh = rs.getDouble("kwh")
                        if (!rs.wasNull()) row.put("kwh", Math.round(kwh * 10) / 10.0)
                        val volt = rs.getDouble("volt")
                        if (!rs.wasNull() && volt > 0) row.put("volt", Math.round(volt * 100) / 100.0)
                        val temp = rs.getDouble("temp")
                        if (!rs.wasNull()) row.put("temp", Math.round(temp * 10) / 10.0)
                        val soh = rs.getDouble("soh")
                        if (!rs.wasNull() && soh > 0) row.put("soh", Math.round(soh * 10) / 10.0)
                        results.put(row)
                    }
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to get SOC history", e)
            reconnect()
        }

        return results
    }

    /**
     * Get charging sessions.
     */
    fun getChargingSessions(daysBack: Int): JSONArray {
        val results = JSONArray()

        val conn = connection
        if (!initialized || conn == null) {
            return results
        }

        try {
            val startTime = System.currentTimeMillis() - (daysBack * 24 * 60 * 60 * 1000L)

            val sql = "SELECT start_time as startTime, end_time as endTime, start_soc as startSoc, " +
                "end_soc as endSoc, energy_added_kwh as energyAdded, peak_power_kw as peakPower " +
                "FROM " + TABLE_CHARGING + " WHERE start_time >= ? ORDER BY start_time DESC;"

            conn.prepareStatement(sql).use { pstmt ->
                pstmt.setLong(1, startTime)

                pstmt.executeQuery().use { rs ->
                    while (rs.next()) {
                        val row = JSONObject()
                        row.put("startTime", rs.getLong("startTime"))
                        row.put("endTime", rs.getLong("endTime"))
                        row.put("startSoc", rs.getDouble("startSoc"))
                        row.put("endSoc", rs.getDouble("endSoc"))
                        row.put("energyAdded", rs.getDouble("energyAdded"))
                        row.put("peakPower", rs.getDouble("peakPower"))
                        results.put(row)
                    }
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to get charging sessions", e)
            reconnect()
        }

        return results
    }

    /**
     * Get SOC statistics.
     */
    fun getSocStats(hoursBack: Int): JSONObject {
        val stats = JSONObject()

        try {
            // Always get current SOC from VehicleDataMonitor
            val monitor = VehicleDataMonitor.getInstance()
            val currentSoc = monitor.getBatterySoc()
            if (currentSoc != null) {
                stats.put("currentSoc", currentSoc.socPercent)
                stats.put("isLow", currentSoc.isLow)
                stats.put("isCritical", currentSoc.isCritical)
            }

            val conn = connection
            if (!initialized || conn == null) {
                return stats
            }

            val startTime = System.currentTimeMillis() - (hoursBack * 60 * 60 * 1000L)

            // Get min/max/avg/count
            val statsSql = "SELECT MIN(soc_percent), MAX(soc_percent), AVG(soc_percent), COUNT(*) " +
                "FROM " + TABLE_SOC + " WHERE timestamp >= ?;"

            conn.prepareStatement(statsSql).use { pstmt ->
                pstmt.setLong(1, startTime)

                pstmt.executeQuery().use { rs ->
                    if (rs.next()) {
                        stats.put("minSoc", rs.getDouble(1))
                        stats.put("maxSoc", rs.getDouble(2))
                        stats.put("avgSoc", rs.getDouble(3))
                        stats.put("sampleCount", rs.getInt(4))
                    }
                }
            }

            // Get charging session count
            val chargingSql = "SELECT COUNT(*) FROM " + TABLE_CHARGING + " WHERE start_time >= ?;"

            conn.prepareStatement(chargingSql).use { pstmt ->
                pstmt.setLong(1, startTime)

                pstmt.executeQuery().use { rs ->
                    if (rs.next()) {
                        stats.put("chargingSessions", rs.getInt(1))
                    }
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to get SOC stats", e)
        }

        return stats
    }

    /**
     * Get full report for dashboard.
     * Always includes current SOC from VehicleDataMonitor even if no history exists.
     */
    fun getFullReport(hoursBack: Int, maxPoints: Int): JSONObject {
        val report = JSONObject()

        try {
            val history = getSocHistory(hoursBack, maxPoints)
            val stats = getSocStats(hoursBack)

            // Always ensure current SOC is available from live monitor
            val monitor = VehicleDataMonitor.getInstance()
            val currentSocData = monitor.getBatterySoc()
            val rangeData = monitor.getDrivingRange()
            val chargingData = monitor.getChargingState()

            // Always append a live data point at the end so the "current" kWh/SOC
            // display is fresh from the monitor, not averaged from old DB records
            if (currentSocData != null) {
                val livePoint = JSONObject()
                livePoint.put("t", System.currentTimeMillis())
                livePoint.put("soc", currentSocData.socPercent)
                livePoint.put(
                    "charging",
                    chargingData != null &&
                        chargingData.status == ChargingStateData.ChargingStatus.CHARGING
                )
                livePoint.put("power", chargingData?.chargingPowerKW ?: 0.0)
                livePoint.put("range", rangeData?.elecRangeKm ?: 0)
                val liveKwh = monitor.getBatteryRemainPowerKwh()
                if (liveKwh > 0) livePoint.put("kwh", Math.round(liveKwh * 10) / 10.0)

                history.put(livePoint)
            }

            // Ensure stats has current SOC even if DB query returned nothing
            if (!stats.has("currentSoc") && currentSocData != null) {
                stats.put("currentSoc", currentSocData.socPercent)
                stats.put("isLow", currentSocData.isLow)
                stats.put("isCritical", currentSocData.isCritical)
            }

            report.put("history", history)
            report.put("stats", stats)
            report.put("chargingSessions", getChargingSessions(hoursBack / 24))
            report.put("hoursBack", hoursBack)
            report.put("maxPoints", maxPoints)
            report.put("timestamp", System.currentTimeMillis())

            // Add live data flag so frontend knows data is fresh
            report.put("hasLiveData", currentSocData != null)
        } catch (e: Exception) {
            logger.error("Failed to create full report", e)
        }

        return report
    }

    /**
     * Clean up old remaining_kwh records that have a stuck/stale value.
     * Called after PHEV capacity is correctly detected to fix historical data.
     * Updates records where remaining_kwh doesn't match SOC x nominal within 30%.
     */
    fun fixStaleRemainingKwh(nominalCapacityKwh: Double) {
        val conn = connection
        if (!initialized || conn == null || nominalCapacityKwh <= 0) return
        try {
            // Update records where remaining_kwh deviates >30% from SOC-derived value
            val sql = "UPDATE " + TABLE_SOC +
                " SET remaining_kwh = (soc_percent / 100.0) * ? " +
                "WHERE soc_percent > 0 AND remaining_kwh > 0 " +
                "AND ABS(remaining_kwh - (soc_percent / 100.0) * ?) / ((soc_percent / 100.0) * ?) > 0.30"
            conn.prepareStatement(sql).use { pstmt ->
                pstmt.setDouble(1, nominalCapacityKwh)
                pstmt.setDouble(2, nominalCapacityKwh)
                pstmt.setDouble(3, nominalCapacityKwh)
                val updated = pstmt.executeUpdate()
                if (updated > 0) {
                    logger.info(
                        "Fixed " + updated + " stale remaining_kwh records (nominal=" +
                            String.format("%.1f", nominalCapacityKwh) + " kWh)"
                    )
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to fix stale remaining_kwh: " + e.message)
        }
    }

    // ==================== BATTERY HEALTH QUERIES ====================

    /**
     * Get 12V battery voltage history for charting.
     */
    fun getBatteryVoltageHistory(hoursBack: Int, maxPoints: Int): JSONArray {
        val results = JSONArray()
        val conn = connection
        if (!initialized || conn == null) return results

        try {
            val now = System.currentTimeMillis()
            val hours = Math.min(hoursBack, 168)
            val startTime = now - (hours * 60 * 60 * 1000L)
            val timeRangeMs = hours * 60 * 60 * 1000L
            val bucketMs = Math.max(120_000L, timeRangeMs / maxPoints)

            val sql =
                "SELECT MIN(timestamp) as t, AVG(voltage_v) as voltage, " +
                    "  MAX(is_charging) as charging " +
                    "FROM " + TABLE_SOC + " WHERE timestamp >= ? AND voltage_v > 0 " +
                    "GROUP BY (timestamp / ?) ORDER BY t ASC LIMIT ?;"

            conn.prepareStatement(sql).use { pstmt ->
                pstmt.setLong(1, startTime)
                pstmt.setLong(2, bucketMs)
                pstmt.setInt(3, maxPoints)
                pstmt.executeQuery().use { rs ->
                    while (rs.next()) {
                        val row = JSONObject()
                        row.put("t", rs.getLong("t"))
                        row.put("voltage", Math.round(rs.getDouble("voltage") * 100) / 100.0)
                        row.put("charging", rs.getInt("charging") == 1)
                        results.put(row)
                    }
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to get voltage history", e)
            reconnect()
        }
        return results
    }

    /**
     * Get HV battery thermal history for charting.
     */
    fun getThermalHistory(hoursBack: Int, maxPoints: Int): JSONArray {
        val results = JSONArray()
        val conn = connection
        if (!initialized || conn == null) return results

        try {
            val now = System.currentTimeMillis()
            val hours = Math.min(hoursBack, 168)
            val startTime = now - (hours * 60 * 60 * 1000L)
            val timeRangeMs = hours * 60 * 60 * 1000L
            val bucketMs = Math.max(120_000L, timeRangeMs / maxPoints)

            val sql =
                "SELECT MIN(timestamp) as t, " +
                    "  AVG(CASE WHEN hv_temp_high > -999 THEN hv_temp_high END) as temp_high, " +
                    "  AVG(CASE WHEN hv_temp_low > -999 THEN hv_temp_low END) as temp_low, " +
                    "  AVG(CASE WHEN hv_temp_avg > -999 THEN hv_temp_avg END) as temp_avg, " +
                    "  MAX(is_charging) as charging " +
                    "FROM " + TABLE_SOC + " WHERE timestamp >= ? " +
                    "AND (hv_temp_high > -999 OR hv_temp_low > -999 OR hv_temp_avg > -999) " +
                    "GROUP BY (timestamp / ?) ORDER BY t ASC LIMIT ?;"

            conn.prepareStatement(sql).use { pstmt ->
                pstmt.setLong(1, startTime)
                pstmt.setLong(2, bucketMs)
                pstmt.setInt(3, maxPoints)
                pstmt.executeQuery().use { rs ->
                    while (rs.next()) {
                        val row = JSONObject()
                        row.put("t", rs.getLong("t"))
                        val h = rs.getDouble("temp_high")
                        val hNull = rs.wasNull()
                        val l = rs.getDouble("temp_low")
                        val lNull = rs.wasNull()
                        val a = rs.getDouble("temp_avg")
                        val aNull = rs.wasNull()
                        if (!hNull) row.put("high", Math.round(h * 10) / 10.0)
                        if (!lNull) row.put("low", Math.round(l * 10) / 10.0)
                        if (!aNull) row.put("avg", Math.round(a * 10) / 10.0)
                        row.put("charging", rs.getInt("charging") == 1)
                        results.put(row)
                    }
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to get thermal history", e)
            reconnect()
        }
        return results
    }

    /**
     * Get battery health report — current state + historical stats.
     */
    fun getBatteryHealthReport(hoursBack: Int, maxPoints: Int): JSONObject {
        val report = JSONObject()

        try {
            val monitor = VehicleDataMonitor.getInstance()

            // Current live data
            val current = JSONObject()

            val powerData = monitor.getBatteryPower()
            if (powerData != null) {
                current.put("voltage12v", powerData.voltageVolts)
                current.put("voltageStatus", powerData.getHealthStatus())
            }

            val socData = monitor.getBatterySoc()
            if (socData != null) {
                current.put("soc", socData.socPercent)
            }

            val thermalData = monitor.getBatteryThermal()
            if (thermalData != null && thermalData.hasData()) {
                if (!thermalData.highestTempC.isNaN()) current.put("tempHigh", thermalData.highestTempC)
                if (!thermalData.lowestTempC.isNaN()) current.put("tempLow", thermalData.lowestTempC)
                if (!thermalData.averageTempC.isNaN()) current.put("tempAvg", thermalData.averageTempC)
                if (!thermalData.deltaC.isNaN()) current.put("tempDelta", thermalData.deltaC)
                current.put("thermalStatus", thermalData.getStatus())
            }

            // SOH estimation has been removed. We can still surface a nominal
            // pack-capacity baseline derived from BYD local data so the health
            // card shows usable energy without a degradation figure.
            val nominal = monitor.getNominalCapacityKwh()
            if (nominal > 0) {
                current.put("nominalCapacityKwh", Math.round(nominal * 10) / 10.0)
                current.put("sohSource", "nominal")
            }

            val remainingKwh = monitor.getBatteryRemainPowerKwh()
            if (remainingKwh > 0) current.put("remainingKwh", Math.round(remainingKwh * 10) / 10.0)

            val rangeData = monitor.getDrivingRange()
            if (rangeData != null) current.put("rangeKm", rangeData.elecRangeKm)

            report.put("current", current)

            // Historical data
            report.put("voltageHistory", getBatteryVoltageHistory(hoursBack, maxPoints))
            report.put("thermalHistory", getThermalHistory(hoursBack, maxPoints))

            // 12V voltage stats
            val conn = connection
            if (initialized && conn != null) {
                val startTime = System.currentTimeMillis() - (hoursBack * 60 * 60 * 1000L)
                val statsSql = "SELECT MIN(voltage_v), MAX(voltage_v), AVG(voltage_v) " +
                    "FROM " + TABLE_SOC + " WHERE timestamp >= ? AND voltage_v > 0;"
                conn.prepareStatement(statsSql).use { pstmt ->
                    pstmt.setLong(1, startTime)
                    pstmt.executeQuery().use { rs ->
                        if (rs.next()) {
                            val voltStats = JSONObject()
                            voltStats.put("min", Math.round(rs.getDouble(1) * 100) / 100.0)
                            voltStats.put("max", Math.round(rs.getDouble(2) * 100) / 100.0)
                            voltStats.put("avg", Math.round(rs.getDouble(3) * 100) / 100.0)
                            report.put("voltageStats", voltStats)
                        }
                    }
                }

                // SOH history (last N samples where soh > 0)
                val sohSql = "SELECT MIN(timestamp) as t, AVG(soh_percent) as soh " +
                    "FROM " + TABLE_SOC + " WHERE timestamp >= ? AND soh_percent > 0 " +
                    "GROUP BY (timestamp / ?) ORDER BY t ASC LIMIT ?;"
                val sohBucketMs = Math.max(120_000L, hoursBack.toLong() * 60 * 60 * 1000L / maxPoints)
                val sohHistory = JSONArray()
                conn.prepareStatement(sohSql).use { pstmt ->
                    pstmt.setLong(1, startTime)
                    pstmt.setLong(2, sohBucketMs)
                    pstmt.setInt(3, maxPoints)
                    pstmt.executeQuery().use { rs ->
                        while (rs.next()) {
                            val row = JSONObject()
                            row.put("t", rs.getLong("t"))
                            row.put("soh", Math.round(rs.getDouble("soh") * 10) / 10.0)
                            sohHistory.put(row)
                        }
                    }
                }
                report.put("sohHistory", sohHistory)
            }

            report.put("hoursBack", hoursBack)
            report.put("timestamp", System.currentTimeMillis())
        } catch (e: Exception) {
            logger.error("Failed to create battery health report", e)
        }

        return report
    }

    // ==================== MAINTENANCE ====================

    /**
     * Wipes every row from soc_history and charging_sessions. Used by the
     * user-initiated "Reset Data" feature to clear SOC graphs and 12V history.
     * Returns total rows deleted, or -1 on failure. Tables remain so inserts
     * continue to work.
     */
    fun resetAll(): Long {
        val conn = connection
        if (!initialized || conn == null) return -1
        try {
            conn.createStatement().use { stmt ->
                val n1 = stmt.executeUpdate("DELETE FROM $TABLE_SOC")
                val n2 = stmt.executeUpdate("DELETE FROM $TABLE_CHARGING")
                var n3 = 0
                try {
                    n3 = stmt.executeUpdate("DELETE FROM $TABLE_ACC_EVENTS")
                } catch (ignored: Exception) {
                    logger.warn(
                        "resetAll: acc_events table may not exist (safe to ignore): " +
                            ignored.message
                    )
                }
                logger.info(
                    "resetAll: cleared " + n1 + " from " + TABLE_SOC +
                        ", " + n2 + " from " + TABLE_CHARGING +
                        ", " + n3 + " from " + TABLE_ACC_EVENTS
                )
                return (n1 + n2 + n3).toLong()
            }
        } catch (e: Exception) {
            logger.error("resetAll failed", e)
            return -1
        }
    }

    private fun cleanupOldData() {
        val conn = connection
        if (!initialized || conn == null) return

        try {
            val cutoff = System.currentTimeMillis() - (RETENTION_DAYS * 24 * 60 * 60 * 1000L)

            val deleteSocSql = "DELETE FROM " + TABLE_SOC + " WHERE timestamp < ?;"
            conn.prepareStatement(deleteSocSql).use { pstmt ->
                pstmt.setLong(1, cutoff)
                val deleted = pstmt.executeUpdate()
                if (deleted > 0) {
                    logger.info("Cleaned up $deleted old SOC records")
                }
            }

            val deleteChargingSql = "DELETE FROM " + TABLE_CHARGING + " WHERE start_time < ?;"
            conn.prepareStatement(deleteChargingSql).use { pstmt ->
                pstmt.setLong(1, cutoff)
                pstmt.executeUpdate()
            }
        } catch (e: Exception) {
            logger.error("Failed to cleanup old data", e)
        }
    }

    /**
     * Get database file size.
     */
    fun getDatabaseSize(): Long {
        return try {
            val dbFile = File("$DB_PATH.mv.db")
            if (dbFile.exists()) dbFile.length() else 0
        } catch (e: Exception) {
            logger.debug("getDatabaseSize failed: " + e.message)
            0
        }
    }

    /**
     * Get record count.
     */
    fun getRecordCount(): Int {
        val conn = connection
        if (!initialized || conn == null) return 0

        try {
            val sql = "SELECT COUNT(*) FROM " + TABLE_SOC + ";"
            conn.createStatement().use { stmt ->
                stmt.executeQuery(sql).use { rs ->
                    if (rs.next()) {
                        return rs.getInt(1)
                    }
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to get record count", e)
        }
        return 0
    }

    fun isRunning(): Boolean = running

    fun isAvailable(): Boolean = initialized && connection != null

    // ==================== ACC EVENTS ====================

    /**
     * Record a single ACC transition. Called synchronously from
     * CameraDaemon.onAccStateChanged() so the snapshot is captured BEFORE
     * the daemon tears down BydDataCollector.
     *
     * @param eventType "ON" or "OFF" (case-insensitive — normalized to upper).
     * @param data the BydVehicleData snapshot at the moment of the event.
     *             Pass null if the snapshot is unavailable; nullable fields
     *             will be persisted as SQL NULL.
     *
     * Best-effort: any exception is caught and logged; never propagates.
     */
    fun recordAccEvent(eventType: String?, data: BydVehicleData?) {
        try {
            if (eventType == null) return
            val type = eventType.trim().uppercase()
            if ("ON" != type && "OFF" != type) return

            if (!isAvailable()) {
                logger.debug("recordAccEvent skipped: DB not available (type=" + type + ")")
                return
            }

            val now = System.currentTimeMillis()

            // Pull snapshot fields defensively. Use SQL NULL when the value
            // is missing or sentinel — never a fake zero.
            var socPercent: Double? = null
            var remainingKwh: Double? = null
            var voltageV: Double? = null
            var rangeKm: Int? = null
            if (data != null) {
                if (!data.socPercent.isNaN() && data.socPercent >= 0 && data.socPercent <= 100) {
                    socPercent = data.socPercent
                }
                // NOT data.remainKwh. That channel mirrors SoC percent on this car rather
                // than reporting energy (BladeWatch-x4lf/hdt7), and this column feeds
                // getLastParkingDelta's deltaKwh, which the GetParkingDelta RPC surfaces to
                // the UI. getBatteryRemainPowerKwh() validates the channel against SoC and
                // nominal capacity and computes a replacement when it is inconsistent -- it is
                // what the other three writers in this file already use. It reads the same
                // BydDataCollector snapshot that `data` came from, so this stays consistent
                // with the rest of the row. 0 means "unknown", which must stay SQL NULL.
                try {
                    val validatedKwh = VehicleDataMonitor.getInstance().getBatteryRemainPowerKwh()
                    if (!validatedKwh.isNaN() && validatedKwh > 0) {
                        remainingKwh = validatedKwh
                    }
                } catch (t: Throwable) {
                    logger.debug("recordAccEvent remaining kWh unavailable: " + t.message)
                }
                if (!data.voltage12v.isNaN() && data.voltage12v > 0) {
                    voltageV = data.voltage12v
                }
                if (data.elecRangeKm != BydVehicleData.UNAVAILABLE && data.elecRangeKm >= 0) {
                    rangeKm = data.elecRangeKm
                }
            }

            val sql = "INSERT INTO " + TABLE_ACC_EVENTS +
                " (timestamp, event_type, soc_percent, remaining_kwh, voltage_v, range_km) " +
                "VALUES (?, ?, ?, ?, ?, ?);"

            connection!!.prepareStatement(sql).use { pstmt ->
                pstmt.setLong(1, now)
                pstmt.setString(2, type)
                if (socPercent != null) pstmt.setDouble(3, socPercent) else pstmt.setNull(3, Types.REAL)
                if (remainingKwh != null) pstmt.setDouble(4, remainingKwh) else pstmt.setNull(4, Types.REAL)
                if (voltageV != null) pstmt.setDouble(5, voltageV) else pstmt.setNull(5, Types.REAL)
                if (rangeKm != null) pstmt.setInt(6, rangeKm) else pstmt.setNull(6, Types.INTEGER)
                pstmt.executeUpdate()
            }

            logger.debug(
                "ACC event recorded: " + type +
                    " soc=" + (socPercent ?: "null") +
                    " kWh=" + (remainingKwh ?: "null")
            )
        } catch (e: Exception) {
            // Never propagate — must not break the daemon's ACC state machine.
            logger.error("recordAccEvent failed: " + e.message, e)
        }
    }

    /**
     * Compute the most recent completed park-and-return cycle.
     *
     * Algorithm (NO inference, only real events):
     *   1. Find the most recent OFF event in the table.
     *   2. Find the most recent ON event whose timestamp > that OFF's timestamp.
     *      (i.e. the matching return event).
     *   3. If both exist with usable SOC values, compute delta and return it.
     *   4. Anything else → return null.
     *
     * Edge cases (ALL return null, never fake data):
     *   - DB unavailable / not initialized.
     *   - No OFF events ever recorded (just installed, never parked yet).
     *   - Most recent OFF has no subsequent ON (currently parked — delta unknown).
     *   - Either bracket has soc_percent IS NULL or NaN.
     *   - soc_percent < 0 or > 100 on either bracket.
     *   - |deltaSoc| > 100 (sanity floor for bad data).
     *   - The OFF was older than [maxAgeHours] hours ago (stale).
     *
     * Returned JSON shape on success:
     *   offTs, onTs, idleMinutes, deltaSoc, deltaKwh?, isCharging
     *   deltaKwh present only when both samples have remaining_kwh > 0.
     *   isCharging=true if deltaSoc > 0.5 (battery gained energy parked = plugged in).
     */
    fun getLastParkingDelta(maxAgeHours: Int): JSONObject? {
        // Edge case: DB unavailable / not initialized.
        if (!isAvailable()) return null
        if (maxAgeHours <= 0) return null
        val conn = connection ?: return null
        try {
            // Step 1: find the most recent OFF event.
            val offTs: Long
            val offSoc: Double?
            val offKwh: Double?
            val offSql = "SELECT timestamp, soc_percent, remaining_kwh " +
                "FROM " + TABLE_ACC_EVENTS + " WHERE event_type = 'OFF' " +
                "ORDER BY timestamp DESC LIMIT 1"
            conn.prepareStatement(offSql).use { pstmt ->
                pstmt.executeQuery().use { rs ->
                    // Edge case: no OFF events ever recorded.
                    if (!rs.next()) return null
                    offTs = rs.getLong(1)
                    val s = rs.getDouble(2)
                    offSoc = if (rs.wasNull()) null else s
                    val k = rs.getDouble(3)
                    offKwh = if (rs.wasNull()) null else k
                }
            }

            // Edge case: OFF older than maxAgeHours → stale, skip.
            val now = System.currentTimeMillis()
            val ageMs = now - offTs
            val maxAgeMs = maxAgeHours.toLong() * 60L * 60L * 1000L
            if (ageMs < 0 || ageMs > maxAgeMs) return null

            // Step 2: find the most recent ON event after that OFF.
            val onTs: Long
            val onSoc: Double?
            val onKwh: Double?
            val onSql = "SELECT timestamp, soc_percent, remaining_kwh " +
                "FROM " + TABLE_ACC_EVENTS + " WHERE event_type = 'ON' AND timestamp > ? " +
                "ORDER BY timestamp DESC LIMIT 1"
            conn.prepareStatement(onSql).use { pstmt ->
                pstmt.setLong(1, offTs)
                pstmt.executeQuery().use { rs ->
                    // Edge case: most recent OFF has no subsequent ON
                    // (currently parked — delta unknown).
                    if (!rs.next()) return null
                    onTs = rs.getLong(1)
                    val s = rs.getDouble(2)
                    onSoc = if (rs.wasNull()) null else s
                    val k = rs.getDouble(3)
                    onKwh = if (rs.wasNull()) null else k
                }
            }

            // Edge case: either bracket has soc_percent IS NULL or NaN.
            if (offSoc == null || onSoc == null) return null
            if (offSoc.isNaN() || onSoc.isNaN()) return null

            // Edge case: soc out of valid range on either bracket.
            if (offSoc < 0 || offSoc > 100) return null
            if (onSoc < 0 || onSoc > 100) return null

            val deltaSoc = onSoc - offSoc

            // Edge case: |deltaSoc| > 100 sanity floor for bad data.
            if (deltaSoc.isNaN() || Math.abs(deltaSoc) > 100) return null

            // Edge case: onTs must be after offTs (already enforced by query
            // but defend against clock skew on the host).
            if (onTs <= offTs) return null

            val out = JSONObject()
            out.put("offTs", offTs)
            out.put("onTs", onTs)
            out.put("idleMinutes", (onTs - offTs) / 60_000L)
            out.put("deltaSoc", Math.round(deltaSoc * 10) / 10.0)

            // deltaKwh present only when both samples have remaining_kwh > 0.
            if (offKwh != null && onKwh != null &&
                !offKwh.isNaN() && !onKwh.isNaN() &&
                offKwh > 0 && onKwh > 0
            ) {
                val deltaKwh = onKwh - offKwh
                if (!deltaKwh.isNaN() && Math.abs(deltaKwh) < 500) {
                    out.put("deltaKwh", Math.round(deltaKwh * 10) / 10.0)
                }
            }

            // isCharging: positive SOC delta > 0.5 means the pack gained
            // energy while parked — i.e. plugged in.
            out.put("isCharging", deltaSoc > 0.5)

            return out
        } catch (e: Exception) {
            logger.debug("getLastParkingDelta failed: " + e.message)
            return null
        }
    }

    /**
     * Get the most recent completed charging session within the last [hoursBack]
     * hours. Returns null if none, if values are garbage, or if DB is closed.
     *
     * Returned JSON shape:
     *  startTime, endTime, durationMinutes, energyAddedKwh, startSoc, endSoc
     */
    fun getMostRecentCompletedChargingSession(hoursBack: Int): JSONObject? {
        if (!isAvailable()) return null
        if (hoursBack <= 0) return null
        val conn = connection ?: return null
        try {
            val cutoff = System.currentTimeMillis() - (hoursBack * 60L * 60L * 1000L)
            val sql = "SELECT start_time, end_time, start_soc, end_soc, energy_added_kwh " +
                "FROM " + TABLE_CHARGING +
                " WHERE end_time IS NOT NULL AND start_time >= ? " +
                "ORDER BY end_time DESC LIMIT 1"
            conn.prepareStatement(sql).use { pstmt ->
                pstmt.setLong(1, cutoff)
                pstmt.executeQuery().use { rs ->
                    if (!rs.next()) return null
                    val start = rs.getLong(1)
                    val end = rs.getLong(2)
                    val startSoc = rs.getDouble(3)
                    val endSoc = rs.getDouble(4)
                    val energy = rs.getDouble(5)
                    if (end <= start) return null
                    if (energy.isNaN() || energy <= 0 || energy > 500) return null
                    val durationMin = (end - start) / 60_000L
                    if (durationMin <= 0 || durationMin > 7 * 24 * 60) return null
                    val out = JSONObject()
                    out.put("startTime", start)
                    out.put("endTime", end)
                    out.put("durationMinutes", durationMin)
                    out.put("energyAddedKwh", Math.round(energy * 10) / 10.0)
                    out.put("startSoc", Math.round(startSoc * 10) / 10.0)
                    out.put("endSoc", Math.round(endSoc * 10) / 10.0)
                    return out
                }
            }
        } catch (e: Exception) {
            logger.debug("getMostRecentCompletedChargingSession failed: " + e.message)
            return null
        }
    }

    /**
     * Compute the SOC change rate in %/hour from recent samples (last 10 minutes).
     * Returns a positive value if SOC is rising (charging), negative if falling,
     * or 0 if insufficient data, samples are too close together, or too old.
     */
    fun getSocChangeRatePerHour(): Double {
        if (!isAvailable()) return 0.0
        val conn = connection ?: return 0.0
        try {
            // Only use samples from the last 10 minutes to avoid stale cross-session data
            val cutoff = System.currentTimeMillis() - 10 * 60 * 1000
            var soc1 = Double.NaN
            var soc2 = Double.NaN
            var t1: Long = 0
            var t2: Long = 0
            conn.prepareStatement(
                "SELECT timestamp, soc_percent FROM " + TABLE_SOC +
                    " WHERE timestamp > ? ORDER BY timestamp DESC LIMIT 2"
            ).use { stmt ->
                stmt.setLong(1, cutoff)
                stmt.executeQuery().use { rs ->
                    if (rs.next()) { t1 = rs.getLong(1); soc1 = rs.getDouble(2) }
                    if (rs.next()) { t2 = rs.getLong(1); soc2 = rs.getDouble(2) }
                }
            }

            if (soc1.isNaN() || soc2.isNaN()) return 0.0
            val deltaMs = t1 - t2
            if (deltaMs < 60_000) return 0.0  // Need at least 60s between samples
            val deltaSoc = soc1 - soc2
            if (Math.abs(deltaSoc) < 0.1) return 0.0  // SOC hasn't changed meaningfully
            val deltaHours = deltaMs / 3_600_000.0
            return deltaSoc / deltaHours
        } catch (e: Exception) {
            logger.debug("getSocChangeRatePerHour failed: " + e.message)
            return 0.0
        }
    }

    companion object {
        private const val TAG = "SocHistoryDatabase"
        private val logger = DaemonLogger.getInstance(TAG)

        // H2 JDBC URL - file-based embedded database
        // FILE_LOCK=SOCKET uses socket-based locking (more reliable than file locks on Android)
        // AUTO_SERVER=TRUE allows multiple processes to connect via TCP fallback
        private const val DB_PATH = "/data/local/tmp/bladewatch_soc_h2"
        // DB_CLOSE_ON_EXIT=FALSE: we drive shutdown ourselves from CameraDaemon.shutdown().
        // Without it, H2's JVM shutdown hook runs concurrently with our explicit
        // stop() and our last in-flight 2-minute SOC tick, producing the
        // "Database is already closed" + "Could not save properties …lock.db"
        // pair that orphans the lock file across daemon restarts.
        //
        // AUTO_SERVER intentionally omitted — H2 throws
        // "AUTO_SERVER=TRUE && DB_CLOSE_ON_EXIT=FALSE is not supported" if both
        // are set. We're single-process anyway (only the camera daemon writes;
        // HTTP reads happen in the same JVM via NotificationApiHandler). The
        // FILE_LOCK=SOCKET is the actual cross-process safety net.
        private const val JDBC_URL = "jdbc:h2:file:" + DB_PATH +
            ";FILE_LOCK=SOCKET;TRACE_LEVEL_FILE=0;DB_CLOSE_ON_EXIT=FALSE"

        // Table names
        private const val TABLE_SOC = "soc_history"
        private const val TABLE_CHARGING = "charging_sessions"
        private const val TABLE_ACC_EVENTS = "acc_events"

        // Retention periods
        private const val RETENTION_DAYS = 7L
        private const val SAMPLE_INTERVAL_MS = 120_000L  // 2 minutes - SOTA interval for daemon recording

        // Singleton
        private var instance: SocHistoryDatabase? = null
        private val lock = Any()

        @JvmStatic
        fun getInstance(): SocHistoryDatabase {
            instance?.let { return it }
            synchronized(lock) {
                return instance ?: SocHistoryDatabase().also { instance = it }
            }
        }
    }
}
