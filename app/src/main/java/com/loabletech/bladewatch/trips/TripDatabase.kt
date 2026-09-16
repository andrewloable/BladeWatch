package net.bladewatch.app.trips

import java.io.File
import java.nio.file.Files
import java.nio.file.StandardCopyOption
import java.sql.Connection
import java.sql.DriverManager
import java.sql.PreparedStatement
import java.sql.ResultSet
import java.sql.Statement
import java.util.Calendar
import java.util.Locale
import kotlin.math.roundToInt
import net.bladewatch.app.logging.DaemonLogger

/**
 * H2 embedded database for the trip catalog, rollups, and consumption buckets. Follows the
 * same pattern as SocHistoryDatabase but uses a separate DB file.
 */
class TripDatabase {

    private var connection: Connection? = null

    @Volatile
    private var isInitialized = false

    /**
     * JDBC URL actually used by [init]. Defaults to the on-disk database; a test points it at
     * an in-memory H2 so the schema, the bindings and the row mapping can be exercised for
     * real rather than asserted against SQL strings.
     *
     * Internal and deliberately not a public setter: nothing in the daemon should ever
     * redirect the trip history.
     */
    private var jdbcUrl = JDBC_URL

    /** Test seam — see [jdbcUrl]. Must be called before [init]. */
    internal fun setJdbcUrlForTest(url: String) {
        jdbcUrl = url
    }

    // ==================== LIFECYCLE ====================

    fun init() {
        if (isInitialized) return

        logger.info("Initializing H2 trip database at: $DB_PATH")

        // Ensure the persistent directory exists and pull forward any existing trip history
        // from the old /data/local/tmp location.
        ensureDbDir()
        migrateLegacyDbIfNeeded()

        try {
            Class.forName("org.h2.Driver")
        } catch (e: ClassNotFoundException) {
            logger.error("H2 Driver not found! Check gradle dependencies.", e)
            return
        }

        val maxRetries = 3
        val retryDelayMs = 1000L

        for (attempt in 1..maxRetries) {
            try {
                val conn = DriverManager.getConnection(jdbcUrl, "sa", "")
                connection = conn
                logger.info("H2 connection established")

                // Tune H2 for embedded daemon use.
                conn.createStatement().use { it.execute("SET CACHE_SIZE 8192") }

                createTables()
                isInitialized = true
                logger.info("Trip Database initialized via H2 (Pure Java): $DB_PATH")
                return
            } catch (e: Exception) {
                val msg = e.message
                val isLockError = msg != null && (
                    msg.contains("Locked by another process") ||
                        msg.contains("lock.db") ||
                        msg.contains("already in use")
                    )

                if (isLockError && attempt < maxRetries) {
                    logger.warn(
                        "Database locked (attempt $attempt/$maxRetries), cleaning up stale locks..."
                    )
                    cleanupStaleLocks()
                    try {
                        Thread.sleep(retryDelayMs * attempt) // Exponential backoff
                    } catch (ie: InterruptedException) {
                        Thread.currentThread().interrupt()
                        break
                    }
                } else {
                    logger.error(
                        "Failed to initialize trip database: ${e.javaClass.name} - $msg", e
                    )
                    logger.error(
                        "CRITICAL: Trip database failed to initialize after $maxRetries " +
                            "attempts — no trips will be saved"
                    )
                    break
                }
            }
        }
    }

    fun close() {
        connection?.let {
            try {
                it.close()
                logger.info("Trip database connection closed")
            } catch (e: Exception) {
                logger.error("Failed to close trip database connection", e)
            }
            connection = null
        }
        isInitialized = false
    }

    private fun reconnect() {
        try {
            val conn = connection
            if (conn == null || conn.isClosed) {
                connection = DriverManager.getConnection(jdbcUrl, "sa", "")
                isInitialized = true
                logger.info("H2 trip database connection re-established")
            }
        } catch (e: Exception) {
            logger.error("Failed to reconnect to H2 trip database", e)
        }
    }

    /**
     * Ensure the database connection is alive, reconnecting if it has closed.
     *
     * @return true when a usable connection is available
     */
    private fun ensureConnection(): Boolean {
        if (!isInitialized && connection == null) return false
        return try {
            val conn = connection
            if (conn == null || conn.isClosed) {
                logger.info("Database connection closed, reconnecting...")
                reconnect()
                connection?.isClosed == false
            } else {
                true
            }
        } catch (e: Exception) {
            logger.error("Connection check failed", e)
            reconnect()
            try {
                connection?.isClosed == false
            } catch (e2: Exception) {
                false
            }
        }
    }

    /** The live connection, for use after [ensureConnection] has returned true. */
    private fun conn(): Connection = connection!!

    /**
     * Ensure the parent directory of the H2 database exists. H2 creates the DB files but not
     * intermediate directories, so the first init on a clean device would otherwise fail to
     * open the connection.
     */
    private fun ensureDbDir() {
        try {
            val parent = File(DB_PATH).parentFile
            if (parent != null && !parent.exists() && !parent.mkdirs()) {
                logger.warn("Failed to create trip DB directory: ${parent.absolutePath}")
            }
        } catch (e: Exception) {
            logger.warn("ensureDbDir failed: " + e.message)
        }
    }

    /**
     * One-time migration of the H2 trip database from the old /data/local/tmp home to the
     * persistent BladeWatch/data home. Runs only when the new database file does not yet exist
     * and the old one does, so existing trip history is preserved across the relocation. The
     * old file is removed after a successful copy to keep a single source of truth.
     *
     * H2's default MVStore engine keeps all data in a single "{path}.mv.db" file, and
     * FILE_LOCK=SOCKET means there is no on-disk lock file to carry over. The .trace.db
     * (diagnostics) file is intentionally not migrated.
     */
    private fun migrateLegacyDbIfNeeded() {
        try {
            val newDb = File("$DB_PATH.mv.db")
            if (newDb.exists()) return // already migrated, or fresh install
            val oldDb = File("$LEGACY_DB_PATH.mv.db")
            if (!oldDb.exists()) return // nothing to migrate

            Files.copy(oldDb.toPath(), newDb.toPath(), StandardCopyOption.REPLACE_EXISTING)
            logger.info("Migrated trip DB from ${oldDb.absolutePath} to ${newDb.absolutePath}")

            // Single source of truth: drop the old data file once the copy succeeds.
            // Best-effort — a leftover old file is harmless because init() never points at it
            // again.
            if (!oldDb.delete()) {
                logger.debug(
                    "Could not delete old trip DB after migration: ${oldDb.absolutePath}"
                )
            }
        } catch (e: Exception) {
            // Non-fatal: fall through to opening a (possibly empty) new DB.
            logger.warn("Trip DB migration skipped: " + e.message)
        }
    }

    private fun cleanupStaleLocks() {
        try {
            val lockFile = File("$DB_PATH.lock.db")
            if (lockFile.exists()) {
                val ageMs = System.currentTimeMillis() - lockFile.lastModified()
                if (ageMs > 5 * 60 * 1000) {
                    if (lockFile.delete()) {
                        logger.info("Deleted stale lock file (age: ${ageMs / 1000}s)")
                    }
                }
            }
            val traceFile = File("$DB_PATH.trace.db")
            if (traceFile.exists()) traceFile.delete()
        } catch (e: Exception) {
            logger.debug("Lock cleanup failed: " + e.message)
        }
    }

    private fun createTables() {
        conn().createStatement().use { stmt ->
            // Trip catalog
            stmt.execute(
                "CREATE TABLE IF NOT EXISTS trips (" +
                    "id IDENTITY PRIMARY KEY," +
                    "start_time BIGINT NOT NULL," +
                    "end_time BIGINT NOT NULL," +
                    "distance_km REAL NOT NULL," +
                    "duration_seconds INTEGER NOT NULL," +
                    "avg_speed_kmh REAL," +
                    "max_speed_kmh INTEGER," +
                    "soc_start REAL," +
                    "soc_end REAL," +
                    "kwh_start REAL DEFAULT 0," +
                    "kwh_end REAL DEFAULT 0," +
                    "energy_per_km REAL DEFAULT 0," +
                    "electricity_rate REAL DEFAULT 0," +
                    "currency VARCHAR(8) DEFAULT ''," +
                    "trip_cost REAL DEFAULT 0," +
                    "kinematic_state VARCHAR(32) DEFAULT ''," +
                    "efficiency_soc_per_km REAL," +
                    "start_lat REAL," +
                    "start_lon REAL," +
                    "end_lat REAL," +
                    "end_lon REAL," +
                    "ext_temp_c INTEGER," +
                    "anticipation_score INTEGER," +
                    "smoothness_score INTEGER," +
                    "speed_discipline_score INTEGER," +
                    "efficiency_score INTEGER," +
                    "consistency_score INTEGER," +
                    "micro_moments_json CLOB," +
                    "telemetry_file_path VARCHAR(512)" +
                    ")"
            )

            stmt.execute("CREATE INDEX IF NOT EXISTS idx_trips_start ON trips(start_time)")
            stmt.execute("CREATE INDEX IF NOT EXISTS idx_trips_end ON trips(end_time)")

            // Migration: add columns that post-date the original schema.
            try {
                stmt.execute("ALTER TABLE trips ADD COLUMN IF NOT EXISTS kwh_start REAL DEFAULT 0")
                stmt.execute("ALTER TABLE trips ADD COLUMN IF NOT EXISTS kwh_end REAL DEFAULT 0")
                stmt.execute("ALTER TABLE trips ADD COLUMN IF NOT EXISTS energy_per_km REAL DEFAULT 0")
                stmt.execute("ALTER TABLE trips ADD COLUMN IF NOT EXISTS electricity_rate REAL DEFAULT 0")
                stmt.execute("ALTER TABLE trips ADD COLUMN IF NOT EXISTS currency VARCHAR(8) DEFAULT ''")
                stmt.execute("ALTER TABLE trips ADD COLUMN IF NOT EXISTS trip_cost REAL DEFAULT 0")
                stmt.execute("ALTER TABLE trips ADD COLUMN IF NOT EXISTS kinematic_state VARCHAR(32) DEFAULT ''")
                stmt.execute("ALTER TABLE trips ADD COLUMN IF NOT EXISTS gradient_profile VARCHAR(16) DEFAULT ''")
                stmt.execute("ALTER TABLE trips ADD COLUMN IF NOT EXISTS elevation_gain_m REAL DEFAULT 0")
                stmt.execute("ALTER TABLE trips ADD COLUMN IF NOT EXISTS elevation_loss_m REAL DEFAULT 0")
                stmt.execute("ALTER TABLE trips ADD COLUMN IF NOT EXISTS avg_gradient_pct REAL DEFAULT 0")

                // PHEV fuel leg + metered energy (BladeWatch-fpdz.3).
                //
                // THE DEFAULTS ARE NOT UNIFORM AND THAT IS DELIBERATE. The six observed
                // counters default to -1 because -1 means "never read"; 0 is a legitimate
                // measurement (an empty tank, a PHEV leg driven entirely on electricity, a
                // fresh lifetime counter). Defaulting them to 0 would make every historical
                // BEV trip claim a full set of real fuel readings that all happen to be zero.
                // The four computed columns DO default to 0, because they are sums: nothing
                // measured is nothing spent.
                //
                // DOUBLE PRECISION, not REAL like the older columns beside them. That is not
                // an inconsistency for its own sake: H2's REAL is 32-bit, and these are
                // LIFETIME counters whose value is only ever used as a small difference of
                // two large numbers. At a 100,000 kWh odometer, float32 resolution is about
                // 0.008 kWh, which would quantise a 0.4 kWh short trip by roughly 2% -- and
                // the short trip is precisely the case the metered tier exists to measure.
                // The older REAL columns hold instantaneous values where that cancellation
                // does not arise, so they are left alone.
                stmt.execute("ALTER TABLE trips ADD COLUMN IF NOT EXISTS fuel_pct_start DOUBLE PRECISION DEFAULT -1")
                stmt.execute("ALTER TABLE trips ADD COLUMN IF NOT EXISTS fuel_pct_end DOUBLE PRECISION DEFAULT -1")
                stmt.execute("ALTER TABLE trips ADD COLUMN IF NOT EXISTS fuel_con_start DOUBLE PRECISION DEFAULT -1")
                stmt.execute("ALTER TABLE trips ADD COLUMN IF NOT EXISTS fuel_con_end DOUBLE PRECISION DEFAULT -1")
                stmt.execute("ALTER TABLE trips ADD COLUMN IF NOT EXISTS elec_con_start DOUBLE PRECISION DEFAULT -1")
                stmt.execute("ALTER TABLE trips ADD COLUMN IF NOT EXISTS elec_con_end DOUBLE PRECISION DEFAULT -1")
                stmt.execute("ALTER TABLE trips ADD COLUMN IF NOT EXISTS litres_used DOUBLE PRECISION DEFAULT 0")
                stmt.execute("ALTER TABLE trips ADD COLUMN IF NOT EXISTS fuel_price_per_l DOUBLE PRECISION DEFAULT 0")
                stmt.execute("ALTER TABLE trips ADD COLUMN IF NOT EXISTS fuel_cost DOUBLE PRECISION DEFAULT 0")
                stmt.execute("ALTER TABLE trips ADD COLUMN IF NOT EXISTS electric_cost DOUBLE PRECISION DEFAULT 0")
            } catch (e: Exception) {
                // Columns already exist, or the H2 version does not support IF NOT EXISTS.
                logger.debug("trips column migration: " + e.message)
            }

            // Routes table for O(1) similar-trip lookups
            stmt.execute(
                "CREATE TABLE IF NOT EXISTS routes (" +
                    "id IDENTITY PRIMARY KEY," +
                    "start_lat REAL NOT NULL," +
                    "start_lon REAL NOT NULL," +
                    "end_lat REAL NOT NULL," +
                    "end_lon REAL NOT NULL," +
                    "avg_distance_km REAL DEFAULT 0," +
                    "trip_count INTEGER DEFAULT 0" +
                    ")"
            )

            try {
                stmt.execute("ALTER TABLE trips ADD COLUMN IF NOT EXISTS route_id BIGINT DEFAULT NULL")
                stmt.execute("CREATE INDEX IF NOT EXISTS idx_trips_route ON trips(route_id)")
                // Clean up any sentinel rows from previous migrations.
                stmt.execute("DELETE FROM routes WHERE trip_count < 0")
            } catch (e: Exception) {
                logger.debug("route_id migration: " + e.message)
            }

            // Weekly rollups
            stmt.execute(
                "CREATE TABLE IF NOT EXISTS weekly_rollups (" +
                    "\"year\" INTEGER NOT NULL," +
                    "week_number INTEGER NOT NULL," +
                    "trip_count INTEGER DEFAULT 0," +
                    "total_distance_km REAL DEFAULT 0," +
                    "total_duration_seconds INTEGER DEFAULT 0," +
                    "avg_efficiency REAL DEFAULT 0," +
                    "total_energy_kwh REAL DEFAULT 0," +
                    "total_cost REAL DEFAULT 0," +
                    "avg_energy_per_km REAL DEFAULT 0," +
                    "avg_anticipation INTEGER DEFAULT 0," +
                    "avg_smoothness INTEGER DEFAULT 0," +
                    "avg_speed_discipline INTEGER DEFAULT 0," +
                    "avg_efficiency_score INTEGER DEFAULT 0," +
                    "avg_consistency INTEGER DEFAULT 0," +
                    "PRIMARY KEY (\"year\", week_number)" +
                    ")"
            )

            try {
                stmt.execute("ALTER TABLE weekly_rollups ADD COLUMN IF NOT EXISTS total_energy_kwh REAL DEFAULT 0")
                stmt.execute("ALTER TABLE weekly_rollups ADD COLUMN IF NOT EXISTS total_cost REAL DEFAULT 0")
                stmt.execute("ALTER TABLE weekly_rollups ADD COLUMN IF NOT EXISTS avg_energy_per_km REAL DEFAULT 0")
            } catch (e: Exception) {
                logger.debug("weekly_rollups energy migration: " + e.message)
            }

            // Monthly rollups
            stmt.execute(
                "CREATE TABLE IF NOT EXISTS monthly_rollups (" +
                    "\"year\" INTEGER NOT NULL," +
                    "month_number INTEGER NOT NULL," +
                    "trip_count INTEGER DEFAULT 0," +
                    "total_distance_km REAL DEFAULT 0," +
                    "total_duration_seconds INTEGER DEFAULT 0," +
                    "avg_efficiency REAL DEFAULT 0," +
                    "total_energy_kwh REAL DEFAULT 0," +
                    "total_cost REAL DEFAULT 0," +
                    "avg_energy_per_km REAL DEFAULT 0," +
                    "avg_anticipation INTEGER DEFAULT 0," +
                    "avg_smoothness INTEGER DEFAULT 0," +
                    "avg_speed_discipline INTEGER DEFAULT 0," +
                    "avg_efficiency_score INTEGER DEFAULT 0," +
                    "avg_consistency INTEGER DEFAULT 0," +
                    "PRIMARY KEY (\"year\", month_number)" +
                    ")"
            )

            try {
                stmt.execute("ALTER TABLE monthly_rollups ADD COLUMN IF NOT EXISTS total_energy_kwh REAL DEFAULT 0")
                stmt.execute("ALTER TABLE monthly_rollups ADD COLUMN IF NOT EXISTS total_cost REAL DEFAULT 0")
                stmt.execute("ALTER TABLE monthly_rollups ADD COLUMN IF NOT EXISTS avg_energy_per_km REAL DEFAULT 0")
            } catch (e: Exception) {
                logger.debug("monthly_rollups energy migration: " + e.message)
            }

            // Consumption buckets
            stmt.execute(
                "CREATE TABLE IF NOT EXISTS consumption_buckets (" +
                    "bucket_key VARCHAR(64) PRIMARY KEY," +
                    "sample_count INTEGER DEFAULT 0," +
                    "sum_kwh_per_km REAL DEFAULT 0," +
                    "sum_squared_kwh_per_km REAL DEFAULT 0" +
                    ")"
            )
        }
    }

    // ==================== TRIP CRUD ====================

    /** Insert a new trip record and return the auto-generated id, or -1 on failure. */
    fun insertTrip(trip: TripRecord): Long {
        if (!ensureConnection()) return -1

        val sql = "INSERT INTO trips (start_time, end_time, distance_km, duration_seconds, " +
            "avg_speed_kmh, max_speed_kmh, soc_start, soc_end, kwh_start, kwh_end, energy_per_km, " +
            "electricity_rate, currency, trip_cost, kinematic_state, " +
            "gradient_profile, elevation_gain_m, elevation_loss_m, avg_gradient_pct, " +
            "efficiency_soc_per_km, " +
            "start_lat, start_lon, end_lat, end_lon, ext_temp_c, " +
            "anticipation_score, smoothness_score, speed_discipline_score, " +
            "efficiency_score, consistency_score, micro_moments_json, telemetry_file_path, route_id, " +
            // Appended AFTER route_id on purpose: every pre-existing parameter keeps its
            // position, so this change cannot silently shift an old binding.
            FUEL_COLUMNS + ") " +
            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, " +
            "?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"

        try {
            conn().prepareStatement(sql, Statement.RETURN_GENERATED_KEYS).use { pstmt ->
                setTripParams(pstmt, trip)
                pstmt.setObject(33, if (trip.routeId > 0) trip.routeId else null)
                setFuelParams(pstmt, trip, 34)
                pstmt.executeUpdate()

                pstmt.generatedKeys.use { keys ->
                    if (keys.next()) {
                        val id = keys.getLong(1)
                        trip.id = id
                        logger.info("Inserted trip id=$id")
                        return id
                    }
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to insert trip", e)
            reconnect()
        }
        return -1
    }

    /** Update all fields of an existing trip by id. */
    fun updateTrip(trip: TripRecord) {
        if (!ensureConnection()) return

        val sql = "UPDATE trips SET start_time=?, end_time=?, distance_km=?, duration_seconds=?, " +
            "avg_speed_kmh=?, max_speed_kmh=?, soc_start=?, soc_end=?, kwh_start=?, kwh_end=?, energy_per_km=?, " +
            "electricity_rate=?, currency=?, trip_cost=?, kinematic_state=?, " +
            "gradient_profile=?, elevation_gain_m=?, elevation_loss_m=?, avg_gradient_pct=?, " +
            "efficiency_soc_per_km=?, " +
            "start_lat=?, start_lon=?, end_lat=?, end_lon=?, ext_temp_c=?, " +
            "anticipation_score=?, smoothness_score=?, speed_discipline_score=?, " +
            "efficiency_score=?, consistency_score=?, micro_moments_json=?, telemetry_file_path=?, " +
            "route_id=?, " +
            "fuel_pct_start=?, fuel_pct_end=?, fuel_con_start=?, fuel_con_end=?, " +
            "elec_con_start=?, elec_con_end=?, litres_used=?, fuel_price_per_l=?, " +
            "fuel_cost=?, electric_cost=? " +
            "WHERE id=?"

        try {
            conn().prepareStatement(sql).use { pstmt ->
                setTripParams(pstmt, trip)
                pstmt.setObject(33, if (trip.routeId > 0) trip.routeId else null)
                setFuelParams(pstmt, trip, 34)
                pstmt.setLong(44, trip.id)
                pstmt.executeUpdate()
                logger.debug("Updated trip id=${trip.id}")
            }
        } catch (e: Exception) {
            logger.error("Failed to update trip id=${trip.id}", e)
            reconnect()
        }
    }

    /** A single trip by id, or null if not found. */
    fun getTrip(id: Long): TripRecord? {
        if (!ensureConnection()) return null

        try {
            conn().prepareStatement("SELECT * FROM trips WHERE id=?").use { pstmt ->
                pstmt.setLong(1, id)
                pstmt.executeQuery().use { rs ->
                    if (rs.next()) return readTripFromResultSet(rs)
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to get trip id=$id", e)
            reconnect()
        }
        return null
    }

    /**
     * Recent trips within the given number of days, newest first.
     *
     * Backwards-compatible overload — equivalent to the paginated form with offset 0. Kept so
     * callers that do not paginate (rollups, route detection) work without changes.
     */
    @JvmOverloads
    fun getTrips(days: Int, limit: Int, offset: Int = 0): List<TripRecord> {
        val trips = ArrayList<TripRecord>()
        if (!ensureConnection()) return trips
        val safeOffset = if (offset < 0) 0 else offset

        val cutoff = System.currentTimeMillis() - (days.toLong() * 86400000L)
        val sql = "SELECT * FROM trips WHERE start_time >= ? ORDER BY start_time DESC LIMIT ? OFFSET ?"

        try {
            conn().prepareStatement(sql).use { pstmt ->
                pstmt.setLong(1, cutoff)
                pstmt.setInt(2, limit)
                pstmt.setInt(3, safeOffset)
                pstmt.executeQuery().use { rs ->
                    while (rs.next()) trips.add(readTripFromResultSet(rs))
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to get trips", e)
            reconnect()
        }
        return trips
    }

    /** Delete a trip by id. Returns true if a row was deleted. */
    fun deleteTrip(id: Long): Boolean {
        if (!ensureConnection()) return false

        try {
            conn().prepareStatement("DELETE FROM trips WHERE id=?").use { pstmt ->
                pstmt.setLong(1, id)
                if (pstmt.executeUpdate() > 0) {
                    logger.info("Deleted trip id=$id")
                    return true
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to delete trip id=$id", e)
            reconnect()
        }
        return false
    }

    /** Total number of trips in the database. */
    fun getTripCount(): Int {
        if (!ensureConnection()) return 0

        try {
            conn().prepareStatement("SELECT COUNT(*) FROM trips").use { pstmt ->
                pstmt.executeQuery().use { rs ->
                    if (rs.next()) return rs.getInt(1)
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to get trip count", e)
            reconnect()
        }
        return 0
    }

    // ==================== ROUTE MATCHING ====================

    /**
     * Find or create a route for the given trip coordinates. Scans the routes table (small —
     * typically 10-30 routes) for a match within a 0.01 degree geofence, about 1.1 km.
     *
     * @return the route id, or -1 on failure
     */
    fun findOrCreateRoute(
        startLat: Double,
        startLon: Double,
        endLat: Double,
        endLon: Double,
        distanceKm: Double,
    ): Long {
        if (!ensureConnection()) return -1

        try {
            val sql = "SELECT id, avg_distance_km, trip_count FROM routes " +
                "WHERE ABS(start_lat - ?) < 0.01 AND ABS(start_lon - ?) < 0.01 " +
                "AND ABS(end_lat - ?) < 0.01 AND ABS(end_lon - ?) < 0.01"
            conn().prepareStatement(sql).use { pstmt ->
                pstmt.setDouble(1, startLat)
                pstmt.setDouble(2, startLon)
                pstmt.setDouble(3, endLat)
                pstmt.setDouble(4, endLon)
                pstmt.executeQuery().use { rs ->
                    if (rs.next()) {
                        // Match found — update stats with a running average for coordinates
                        // and distance.
                        val avgDist = rs.getDouble("avg_distance_km")
                        val routeId = rs.getLong("id")
                        val count = rs.getInt("trip_count")
                        val newAvgDist = (avgDist * count + distanceKm) / (count + 1)
                        val update = "UPDATE routes SET trip_count = trip_count + 1, " +
                            "avg_distance_km = ?, " +
                            "start_lat = (start_lat * trip_count + ?) / (trip_count + 1), " +
                            "start_lon = (start_lon * trip_count + ?) / (trip_count + 1), " +
                            "end_lat = (end_lat * trip_count + ?) / (trip_count + 1), " +
                            "end_lon = (end_lon * trip_count + ?) / (trip_count + 1) " +
                            "WHERE id = ?"
                        conn().prepareStatement(update).use { upd ->
                            upd.setDouble(1, newAvgDist)
                            upd.setDouble(2, startLat)
                            upd.setDouble(3, startLon)
                            upd.setDouble(4, endLat)
                            upd.setDouble(5, endLon)
                            upd.setLong(6, routeId)
                            upd.executeUpdate()
                        }
                        return routeId
                    }
                }
            }

            // No match — create a new route.
            val insert = "INSERT INTO routes " +
                "(start_lat, start_lon, end_lat, end_lon, avg_distance_km, trip_count) " +
                "VALUES (?, ?, ?, ?, ?, 1)"
            conn().prepareStatement(insert, Statement.RETURN_GENERATED_KEYS).use { pstmt ->
                pstmt.setDouble(1, startLat)
                pstmt.setDouble(2, startLon)
                pstmt.setDouble(3, endLat)
                pstmt.setDouble(4, endLon)
                pstmt.setDouble(5, distanceKm)
                pstmt.executeUpdate()
                pstmt.generatedKeys.use { keys ->
                    if (keys.next()) return keys.getLong(1)
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to find/create route", e)
        }
        return -1
    }

    /** Trips by route id — an O(1) indexed lookup. */
    fun getTripsByRoute(routeId: Long, limit: Int): List<TripRecord> {
        val trips = ArrayList<TripRecord>()
        if (!ensureConnection()) return trips

        val sql = "SELECT * FROM trips WHERE route_id = ? ORDER BY start_time DESC LIMIT ?"
        try {
            conn().prepareStatement(sql).use { pstmt ->
                pstmt.setLong(1, routeId)
                pstmt.setInt(2, limit)
                pstmt.executeQuery().use { rs ->
                    while (rs.next()) trips.add(readTripFromResultSet(rs))
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to get trips by route", e)
        }
        return trips
    }

    /**
     * Backfill route_id for existing trips that do not have one. Called once after migration;
     * idempotent, since it only scans trips whose route_id is still null.
     */
    fun backfillRouteIds() {
        if (!ensureConnection()) return

        val sql = "SELECT id, start_lat, start_lon, end_lat, end_lon, distance_km FROM trips " +
            "WHERE route_id IS NULL AND start_lat != 0 ORDER BY start_time ASC"
        var assigned = 0
        try {
            conn().prepareStatement(sql).use { pstmt ->
                pstmt.executeQuery().use { rs ->
                    while (rs.next()) {
                        val id = rs.getLong("id")
                        val routeId = findOrCreateRoute(
                            rs.getDouble("start_lat"),
                            rs.getDouble("start_lon"),
                            rs.getDouble("end_lat"),
                            rs.getDouble("end_lon"),
                            rs.getDouble("distance_km")
                        )
                        if (routeId > 0) {
                            conn().prepareStatement(
                                "UPDATE trips SET route_id = ? WHERE id = ?"
                            ).use { upd ->
                                upd.setLong(1, routeId)
                                upd.setLong(2, id)
                                upd.executeUpdate()
                                assigned++
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to backfill route IDs", e)
        }
        if (assigned > 0) {
            logger.info("Backfilled route_id for $assigned existing trips")
        }
    }

    // ==================== ROLLUPS ====================

    /**
     * Update the weekly rollup for the ISO week of the given trip, keeping running averages:
     * `new_avg = (old_avg * old_count + new_value) / (old_count + 1)`.
     */
    fun updateWeeklyRollup(trip: TripRecord) {
        if (!ensureConnection()) return

        val cal = Calendar.getInstance(Locale.US)
        cal.timeInMillis = trip.startTime
        cal.minimalDaysInFirstWeek = 4 // ISO week
        cal.firstDayOfWeek = Calendar.MONDAY
        val year = cal.get(Calendar.YEAR)
        val week = cal.get(Calendar.WEEK_OF_YEAR)

        try {
            val existing = getWeeklyRollup(year, week)

            if (existing == null) {
                val sql = "INSERT INTO weekly_rollups (\"year\", week_number, trip_count, " +
                    "total_distance_km, total_duration_seconds, avg_efficiency, " +
                    "total_energy_kwh, total_cost, avg_energy_per_km, " +
                    "avg_anticipation, avg_smoothness, avg_speed_discipline, " +
                    "avg_efficiency_score, avg_consistency) " +
                    "VALUES (?, ?, 1, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
                conn().prepareStatement(sql).use { pstmt ->
                    pstmt.setInt(1, year)
                    pstmt.setInt(2, week)
                    bindNewRollupBody(pstmt, trip)
                    pstmt.executeUpdate()
                }
            } else {
                val oldCount = existing.tripCount
                val sql = "UPDATE weekly_rollups SET trip_count=?, " +
                    "total_distance_km=?, total_duration_seconds=?, avg_efficiency=?, " +
                    "total_energy_kwh=?, total_cost=?, avg_energy_per_km=?, " +
                    "avg_anticipation=?, avg_smoothness=?, avg_speed_discipline=?, " +
                    "avg_efficiency_score=?, avg_consistency=? " +
                    "WHERE \"year\"=? AND week_number=?"
                conn().prepareStatement(sql).use { pstmt ->
                    pstmt.setInt(1, oldCount + 1)
                    pstmt.setDouble(2, existing.totalDistanceKm + trip.distanceKm)
                    pstmt.setInt(3, existing.totalDurationSeconds + trip.durationSeconds)
                    pstmt.setDouble(4, runningAvg(existing.avgEfficiency, oldCount, trip.efficiencySocPerKm))
                    pstmt.setDouble(5, existing.totalEnergyKwh + trip.getEnergyUsedKwh())
                    pstmt.setDouble(6, existing.totalCost + trip.tripCost)
                    pstmt.setDouble(7, runningAvg(existing.avgEnergyPerKm, oldCount, trip.energyPerKm))
                    pstmt.setInt(8, runningAvg(existing.avgAnticipation.toDouble(), oldCount, trip.anticipationScore.toDouble()).toInt())
                    pstmt.setInt(9, runningAvg(existing.avgSmoothness.toDouble(), oldCount, trip.smoothnessScore.toDouble()).toInt())
                    pstmt.setInt(10, runningAvg(existing.avgSpeedDiscipline.toDouble(), oldCount, trip.speedDisciplineScore.toDouble()).toInt())
                    pstmt.setInt(11, runningAvg(existing.avgEfficiencyScore.toDouble(), oldCount, trip.efficiencyScore.toDouble()).toInt())
                    pstmt.setInt(12, runningAvg(existing.avgConsistency.toDouble(), oldCount, trip.consistencyScore.toDouble()).toInt())
                    pstmt.setInt(13, year)
                    pstmt.setInt(14, week)
                    pstmt.executeUpdate()
                }
            }
            logger.debug("Updated weekly rollup year=$year week=$week")
        } catch (e: Exception) {
            logger.error("Failed to update weekly rollup", e)
            reconnect()
        }
    }

    /** Update the monthly rollup for the month of the given trip. See [updateWeeklyRollup]. */
    fun updateMonthlyRollup(trip: TripRecord) {
        if (!ensureConnection()) return

        val cal = Calendar.getInstance(Locale.US)
        cal.timeInMillis = trip.startTime
        val year = cal.get(Calendar.YEAR)
        val month = cal.get(Calendar.MONTH) + 1 // Calendar.MONTH is 0-based

        try {
            val existing = getMonthlyRollup(year, month)

            if (existing == null) {
                val sql = "INSERT INTO monthly_rollups (\"year\", month_number, trip_count, " +
                    "total_distance_km, total_duration_seconds, avg_efficiency, " +
                    "total_energy_kwh, total_cost, avg_energy_per_km, " +
                    "avg_anticipation, avg_smoothness, avg_speed_discipline, " +
                    "avg_efficiency_score, avg_consistency) " +
                    "VALUES (?, ?, 1, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
                conn().prepareStatement(sql).use { pstmt ->
                    pstmt.setInt(1, year)
                    pstmt.setInt(2, month)
                    bindNewRollupBody(pstmt, trip)
                    pstmt.executeUpdate()
                }
            } else {
                val oldCount = existing.tripCount
                val sql = "UPDATE monthly_rollups SET trip_count=?, " +
                    "total_distance_km=?, total_duration_seconds=?, avg_efficiency=?, " +
                    "total_energy_kwh=?, total_cost=?, avg_energy_per_km=?, " +
                    "avg_anticipation=?, avg_smoothness=?, avg_speed_discipline=?, " +
                    "avg_efficiency_score=?, avg_consistency=? " +
                    "WHERE \"year\"=? AND month_number=?"
                conn().prepareStatement(sql).use { pstmt ->
                    pstmt.setInt(1, oldCount + 1)
                    pstmt.setDouble(2, existing.totalDistanceKm + trip.distanceKm)
                    pstmt.setInt(3, existing.totalDurationSeconds + trip.durationSeconds)
                    pstmt.setDouble(4, runningAvg(existing.avgEfficiency, oldCount, trip.efficiencySocPerKm))
                    pstmt.setDouble(5, existing.totalEnergyKwh + trip.getEnergyUsedKwh())
                    pstmt.setDouble(6, existing.totalCost + trip.tripCost)
                    pstmt.setDouble(7, runningAvg(existing.avgEnergyPerKm, oldCount, trip.energyPerKm))
                    pstmt.setInt(8, runningAvg(existing.avgAnticipation.toDouble(), oldCount, trip.anticipationScore.toDouble()).toInt())
                    pstmt.setInt(9, runningAvg(existing.avgSmoothness.toDouble(), oldCount, trip.smoothnessScore.toDouble()).toInt())
                    pstmt.setInt(10, runningAvg(existing.avgSpeedDiscipline.toDouble(), oldCount, trip.speedDisciplineScore.toDouble()).toInt())
                    pstmt.setInt(11, runningAvg(existing.avgEfficiencyScore.toDouble(), oldCount, trip.efficiencyScore.toDouble()).toInt())
                    pstmt.setInt(12, runningAvg(existing.avgConsistency.toDouble(), oldCount, trip.consistencyScore.toDouble()).toInt())
                    pstmt.setInt(13, year)
                    pstmt.setInt(14, month)
                    pstmt.executeUpdate()
                }
            }
            logger.debug("Updated monthly rollup year=$year month=$month")
        } catch (e: Exception) {
            logger.error("Failed to update monthly rollup", e)
            reconnect()
        }
    }

    /**
     * Bind parameters 3-13 of a new weekly/monthly rollup INSERT. The two statements share an
     * identical body after their period key, so binding it once keeps them from drifting.
     */
    private fun bindNewRollupBody(pstmt: PreparedStatement, trip: TripRecord) {
        pstmt.setDouble(3, trip.distanceKm)
        pstmt.setInt(4, trip.durationSeconds)
        pstmt.setDouble(5, trip.efficiencySocPerKm)
        pstmt.setDouble(6, trip.getEnergyUsedKwh())
        pstmt.setDouble(7, trip.tripCost)
        pstmt.setDouble(8, trip.energyPerKm)
        pstmt.setInt(9, trip.anticipationScore)
        pstmt.setInt(10, trip.smoothnessScore)
        pstmt.setInt(11, trip.speedDisciplineScore)
        pstmt.setInt(12, trip.efficiencyScore)
        pstmt.setInt(13, trip.consistencyScore)
    }

    /** A weekly rollup by year and ISO week number. */
    fun getWeeklyRollup(year: Int, week: Int): WeeklyRollup? {
        if (!ensureConnection()) return null

        val sql = "SELECT * FROM weekly_rollups WHERE \"year\"=? AND week_number=?"
        try {
            conn().prepareStatement(sql).use { pstmt ->
                pstmt.setInt(1, year)
                pstmt.setInt(2, week)
                pstmt.executeQuery().use { rs ->
                    if (rs.next()) return readWeeklyRollupFromResultSet(rs)
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to get weekly rollup year=$year week=$week", e)
            reconnect()
        }
        return null
    }

    /** The most recent N weekly rollups, newest first. */
    fun getRecentWeeklyRollups(weeks: Int): List<WeeklyRollup> {
        val rollups = ArrayList<WeeklyRollup>()
        if (!ensureConnection()) return rollups

        val sql = "SELECT * FROM weekly_rollups ORDER BY \"year\" DESC, week_number DESC LIMIT ?"
        try {
            conn().prepareStatement(sql).use { pstmt ->
                pstmt.setInt(1, weeks)
                pstmt.executeQuery().use { rs ->
                    while (rs.next()) rollups.add(readWeeklyRollupFromResultSet(rs))
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to get recent weekly rollups", e)
            reconnect()
        }
        return rollups
    }

    /** The most recent N monthly rollups, newest first. */
    fun getRecentMonthlyRollups(months: Int): List<MonthlyRollup> {
        val rollups = ArrayList<MonthlyRollup>()
        if (!ensureConnection()) return rollups

        val sql = "SELECT * FROM monthly_rollups ORDER BY \"year\" DESC, month_number DESC LIMIT ?"
        try {
            conn().prepareStatement(sql).use { pstmt ->
                pstmt.setInt(1, months)
                pstmt.executeQuery().use { rs ->
                    while (rs.next()) rollups.add(readMonthlyRollupFromResultSet(rs))
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to get recent monthly rollups", e)
            reconnect()
        }
        return rollups
    }

    /** Average DNA scores over the given number of days, or null when there are no trips. */
    fun getAverageDna(days: Int): DnaScores? {
        if (!ensureConnection()) return null

        val cutoff = System.currentTimeMillis() - (days.toLong() * 86400000L)
        val sql = "SELECT AVG(anticipation_score) as avg_ant, AVG(smoothness_score) as avg_smo, " +
            "AVG(speed_discipline_score) as avg_spd, AVG(efficiency_score) as avg_eff, " +
            "AVG(consistency_score) as avg_con, COUNT(*) as cnt " +
            "FROM trips WHERE start_time >= ?"

        try {
            conn().prepareStatement(sql).use { pstmt ->
                pstmt.setLong(1, cutoff)
                pstmt.executeQuery().use { rs ->
                    if (rs.next() && rs.getInt("cnt") > 0) {
                        val scores = DnaScores()
                        scores.anticipation = rs.getDouble("avg_ant").roundToInt()
                        scores.smoothness = rs.getDouble("avg_smo").roundToInt()
                        scores.speedDiscipline = rs.getDouble("avg_spd").roundToInt()
                        scores.efficiency = rs.getDouble("avg_eff").roundToInt()
                        scores.consistency = rs.getDouble("avg_con").roundToInt()
                        return scores
                    }
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to get average DNA scores", e)
            reconnect()
        }
        return null
    }

    // ==================== CONSUMPTION BUCKETS ====================

    /**
     * Update a consumption bucket: increment the sample count, add to the sum, and add the
     * square to the sum of squares. Insert if the bucket does not exist yet.
     */
    fun updateConsumptionBucket(bucketKey: String, consumptionKwhPerKm: Double) {
        if (!ensureConnection()) return

        try {
            val existing = getBucket(bucketKey)

            if (existing == null) {
                val sql = "INSERT INTO consumption_buckets " +
                    "(bucket_key, sample_count, sum_kwh_per_km, sum_squared_kwh_per_km) " +
                    "VALUES (?, 1, ?, ?)"
                conn().prepareStatement(sql).use { pstmt ->
                    pstmt.setString(1, bucketKey)
                    pstmt.setDouble(2, consumptionKwhPerKm)
                    pstmt.setDouble(3, consumptionKwhPerKm * consumptionKwhPerKm)
                    pstmt.executeUpdate()
                }
            } else {
                val sql = "UPDATE consumption_buckets SET sample_count = sample_count + 1, " +
                    "sum_kwh_per_km = sum_kwh_per_km + ?, " +
                    "sum_squared_kwh_per_km = sum_squared_kwh_per_km + ? " +
                    "WHERE bucket_key = ?"
                conn().prepareStatement(sql).use { pstmt ->
                    pstmt.setDouble(1, consumptionKwhPerKm)
                    pstmt.setDouble(2, consumptionKwhPerKm * consumptionKwhPerKm)
                    pstmt.setString(3, bucketKey)
                    pstmt.executeUpdate()
                }
            }
            logger.debug("Updated consumption bucket: $bucketKey")
        } catch (e: Exception) {
            logger.error("Failed to update consumption bucket: $bucketKey", e)
            reconnect()
        }
    }

    /** A consumption bucket by key, or null if not found. */
    fun getBucket(bucketKey: String): ConsumptionBucket? {
        if (!ensureConnection()) return null

        try {
            conn().prepareStatement(
                "SELECT * FROM consumption_buckets WHERE bucket_key = ?"
            ).use { pstmt ->
                pstmt.setString(1, bucketKey)
                pstmt.executeQuery().use { rs ->
                    if (rs.next()) return readBucketFromResultSet(rs)
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to get consumption bucket: $bucketKey", e)
            reconnect()
        }
        return null
    }

    /**
     * Wipe every row from every trips table, for the user-initiated "Reset Data" feature. The
     * schema is left intact, so inserts continue to work without a reconnect.
     *
     * @return total rows deleted across all tables, or -1 on failure
     */
    fun resetAll(): Long {
        if (!ensureConnection()) return -1
        var total = 0L
        // Order matters only weakly here (no FK constraints in the schema), but child-like
        // tables before parent feels right and matches the create-order idiom used elsewhere.
        val tables = arrayOf(
            "consumption_buckets", "monthly_rollups", "weekly_rollups", "routes", "trips"
        )
        return try {
            conn().createStatement().use { stmt ->
                for (t in tables) {
                    val n = stmt.executeUpdate("DELETE FROM $t")
                    total += n
                    logger.info("resetAll: cleared $n rows from $t")
                }
            }
            total
        } catch (e: Exception) {
            logger.error("resetAll failed", e)
            -1
        }
    }

    /**
     * Clear the ELECTRIC consumption buckets. Called when nominal capacity changes
     * significantly (e.g. a wrong capacity was detected previously) to stop poisoned
     * consumption rates corrupting range estimates.
     *
     * **Fuel buckets survive, deliberately.** The only caller is the one-time PHEV migration
     * in `CameraDaemon`, which fires when the pack turns out to be PHEV-sized and purges kWh/km
     * rates that were computed against a wrong, BEV-sized capacity. A fuel rate is
     * `litresUsed / distanceKm` — no capacity appears in it, so it cannot be poisoned that way.
     * Deleting it would throw away the fuel learning of the exact vehicle the migration just
     * identified as a PHEV, and blank its fuel range until enough trips had been re-driven.
     */
    fun clearConsumptionBuckets() {
        if (!ensureConnection()) return
        try {
            conn().prepareStatement(
                "DELETE FROM consumption_buckets WHERE bucket_key NOT LIKE ? ESCAPE '\\'"
            ).use { stmt ->
                stmt.setString(1, FUEL_KEY_PATTERN)
                val deleted = stmt.executeUpdate()
                logger.info("Cleared $deleted consumption buckets (capacity changed)")
            }
        } catch (e: Exception) {
            logger.error("Failed to clear consumption buckets", e)
        }
    }

    /**
     * The overall average across the ELECTRIC consumption buckets: all sums over all counts.
     *
     * **Fuel buckets are excluded and that exclusion is load-bearing.** `FuelConsumption`
     * stores litres/km in this same table, namespaced by a `fuel_` key prefix, to avoid a
     * schema change. An unfiltered SUM would therefore average litres/km into kWh/km — and the
     * two bands overlap numerically (roughly 0.02-0.20 L/km against 0.10-0.30 kWh/km), so the
     * result stays plausible-looking while being wrong.
     *
     * Two callers would be affected on a PHEV, both in `RangeEstimator`: the final tier of the
     * electric cascade would return a contaminated mean, and `backfillBucketsIfNeeded` would
     * see fuel rows, conclude the buckets were already populated, and skip the electric
     * backfill entirely.
     *
     * The `_` in the prefix is a LIKE wildcard, hence the explicit ESCAPE — without it the
     * pattern would also exclude any key spelled `fuel` plus any single character.
     */
    fun getOverallAverage(): ConsumptionBucket? {
        if (!ensureConnection()) return null

        val sql = "SELECT SUM(sample_count) as total_count, " +
            "SUM(sum_kwh_per_km) as total_sum, " +
            "SUM(sum_squared_kwh_per_km) as total_sum_sq " +
            "FROM consumption_buckets " +
            "WHERE bucket_key NOT LIKE ? ESCAPE '\\'"

        try {
            conn().prepareStatement(sql).use { pstmt ->
                pstmt.setString(1, FUEL_KEY_PATTERN)
                pstmt.executeQuery().use { rs ->
                    if (rs.next()) {
                        val totalCount = rs.getInt("total_count")
                        if (totalCount == 0) return null

                        val overall = ConsumptionBucket()
                        overall.bucketKey = "overall"
                        overall.sampleCount = totalCount
                        overall.sumKwhPerKm = rs.getDouble("total_sum")
                        overall.sumSquaredKwhPerKm = rs.getDouble("total_sum_sq")
                        return overall
                    }
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to get overall consumption average", e)
            reconnect()
        }
        return null
    }

    // ==================== HELPERS ====================

    /** Read a [TripRecord] from a ResultSet row. */
    private fun readTripFromResultSet(rs: ResultSet): TripRecord {
        val trip = TripRecord()
        trip.id = rs.getLong("id")
        trip.startTime = rs.getLong("start_time")
        trip.endTime = rs.getLong("end_time")
        trip.distanceKm = rs.getDouble("distance_km")
        trip.durationSeconds = rs.getInt("duration_seconds")
        trip.avgSpeedKmh = rs.getDouble("avg_speed_kmh")
        trip.maxSpeedKmh = rs.getInt("max_speed_kmh")
        trip.socStart = rs.getDouble("soc_start")
        trip.socEnd = rs.getDouble("soc_end")
        trip.kwhStart = rs.getDouble("kwh_start")
        trip.kwhEnd = rs.getDouble("kwh_end")
        trip.energyPerKm = rs.getDouble("energy_per_km")
        trip.electricityRate = rs.getDouble("electricity_rate")
        trip.currency = rs.getString("currency")
        trip.tripCost = rs.getDouble("trip_cost")
        trip.kinematicState = rs.getString("kinematic_state")
        trip.gradientProfile = readOptionalString(rs, "gradient_profile", "")
        trip.elevationGainM = readOptionalDouble(rs, "elevation_gain_m", 0.0)
        trip.elevationLossM = readOptionalDouble(rs, "elevation_loss_m", 0.0)
        trip.avgGradientPercent = readOptionalDouble(rs, "avg_gradient_pct", 0.0)
        trip.efficiencySocPerKm = rs.getDouble("efficiency_soc_per_km")
        trip.startLat = rs.getDouble("start_lat")
        trip.startLon = rs.getDouble("start_lon")
        trip.endLat = rs.getDouble("end_lat")
        trip.endLon = rs.getDouble("end_lon")
        trip.extTempC = rs.getInt("ext_temp_c")
        trip.anticipationScore = rs.getInt("anticipation_score")
        trip.smoothnessScore = rs.getInt("smoothness_score")
        trip.speedDisciplineScore = rs.getInt("speed_discipline_score")
        trip.efficiencyScore = rs.getInt("efficiency_score")
        trip.consistencyScore = rs.getInt("consistency_score")
        trip.microMomentsJson = rs.getString("micro_moments_json")
        trip.telemetryFilePath = rs.getString("telemetry_file_path")
        trip.routeId = try {
            rs.getLong("route_id")
        } catch (e: Exception) {
            logger.debug("readTripFromResultSet route_id: " + e.message)
            -1
        }

        // PHEV fuel leg + metered energy. Each read is optional so a database written before
        // these columns existed still opens; see readOptionalDouble for why the fallbacks
        // differ between the observed counters (-1) and the computed sums (0).
        trip.fuelPctStart = readOptionalDouble(rs, "fuel_pct_start", -1.0)
        trip.fuelPctEnd = readOptionalDouble(rs, "fuel_pct_end", -1.0)
        trip.fuelConStart = readOptionalDouble(rs, "fuel_con_start", -1.0)
        trip.fuelConEnd = readOptionalDouble(rs, "fuel_con_end", -1.0)
        trip.elecConStart = readOptionalDouble(rs, "elec_con_start", -1.0)
        trip.elecConEnd = readOptionalDouble(rs, "elec_con_end", -1.0)
        trip.litresUsed = readOptionalDouble(rs, "litres_used", 0.0)
        trip.fuelPricePerL = readOptionalDouble(rs, "fuel_price_per_l", 0.0)
        trip.fuelCost = readOptionalDouble(rs, "fuel_cost", 0.0)
        trip.electricCost = readOptionalDouble(rs, "electric_cost", 0.0)
        return trip
    }

    /** Bind PreparedStatement parameters 1-32 for a [TripRecord]. */
    private fun setTripParams(pstmt: PreparedStatement, trip: TripRecord) {
        pstmt.setLong(1, trip.startTime)
        pstmt.setLong(2, trip.endTime)
        pstmt.setDouble(3, trip.distanceKm)
        pstmt.setInt(4, trip.durationSeconds)
        pstmt.setDouble(5, trip.avgSpeedKmh)
        pstmt.setInt(6, trip.maxSpeedKmh)
        pstmt.setDouble(7, trip.socStart)
        pstmt.setDouble(8, trip.socEnd)
        pstmt.setDouble(9, trip.kwhStart)
        pstmt.setDouble(10, trip.kwhEnd)
        pstmt.setDouble(11, trip.energyPerKm)
        pstmt.setDouble(12, trip.electricityRate)
        pstmt.setString(13, trip.currency ?: "")
        pstmt.setDouble(14, trip.tripCost)
        pstmt.setString(15, trip.kinematicState ?: "")
        pstmt.setString(16, trip.gradientProfile ?: "")
        pstmt.setDouble(17, trip.elevationGainM)
        pstmt.setDouble(18, trip.elevationLossM)
        pstmt.setDouble(19, trip.avgGradientPercent)
        pstmt.setDouble(20, trip.efficiencySocPerKm)
        pstmt.setDouble(21, trip.startLat)
        pstmt.setDouble(22, trip.startLon)
        pstmt.setDouble(23, trip.endLat)
        pstmt.setDouble(24, trip.endLon)
        pstmt.setInt(25, trip.extTempC)
        pstmt.setInt(26, trip.anticipationScore)
        pstmt.setInt(27, trip.smoothnessScore)
        pstmt.setInt(28, trip.speedDisciplineScore)
        pstmt.setInt(29, trip.efficiencyScore)
        pstmt.setInt(30, trip.consistencyScore)
        pstmt.setString(31, trip.microMomentsJson)
        pstmt.setString(32, trip.telemetryFilePath)
    }

    /**
     * Bind the ten fuel / metered-energy parameters starting at [i].
     *
     * Order must match [FUEL_COLUMNS] and the UPDATE SET list exactly.
     */
    private fun setFuelParams(pstmt: PreparedStatement, trip: TripRecord, i: Int) {
        pstmt.setDouble(i, trip.fuelPctStart)
        pstmt.setDouble(i + 1, trip.fuelPctEnd)
        pstmt.setDouble(i + 2, trip.fuelConStart)
        pstmt.setDouble(i + 3, trip.fuelConEnd)
        pstmt.setDouble(i + 4, trip.elecConStart)
        pstmt.setDouble(i + 5, trip.elecConEnd)
        pstmt.setDouble(i + 6, trip.litresUsed)
        pstmt.setDouble(i + 7, trip.fuelPricePerL)
        pstmt.setDouble(i + 8, trip.fuelCost)
        pstmt.setDouble(i + 9, trip.electricCost)
    }

    /**
     * Read one optional REAL column, falling back to [fallback] when it is absent.
     *
     * The fallback is per-column, not a blanket 0: the observed counters fall back to -1
     * ("never read") and the computed sums to 0. An older database simply has none of these
     * columns, and that must read as "no data", never as a set of zeroes that look measured.
     */
    private fun readOptionalDouble(rs: ResultSet, column: String, fallback: Double): Double =
        try {
            rs.getDouble(column)
        } catch (e: Exception) {
            logger.debug("readTripFromResultSet $column: " + e.message)
            fallback
        }

    /** Read one optional string column, falling back when it is absent. */
    private fun readOptionalString(rs: ResultSet, column: String, fallback: String): String? =
        try {
            rs.getString(column)
        } catch (e: Exception) {
            logger.debug("readTripFromResultSet $column: " + e.message)
            fallback
        }

    /** Read a [WeeklyRollup] from a ResultSet row. */
    private fun readWeeklyRollupFromResultSet(rs: ResultSet): WeeklyRollup {
        val rollup = WeeklyRollup()
        rollup.year = rs.getInt("year")
        rollup.weekNumber = rs.getInt("week_number")
        rollup.tripCount = rs.getInt("trip_count")
        rollup.totalDistanceKm = rs.getDouble("total_distance_km")
        rollup.totalDurationSeconds = rs.getInt("total_duration_seconds")
        rollup.avgEfficiency = rs.getDouble("avg_efficiency")
        rollup.totalEnergyKwh = rs.getDouble("total_energy_kwh")
        rollup.totalCost = rs.getDouble("total_cost")
        rollup.avgEnergyPerKm = rs.getDouble("avg_energy_per_km")
        rollup.avgAnticipation = rs.getInt("avg_anticipation")
        rollup.avgSmoothness = rs.getInt("avg_smoothness")
        rollup.avgSpeedDiscipline = rs.getInt("avg_speed_discipline")
        rollup.avgEfficiencyScore = rs.getInt("avg_efficiency_score")
        rollup.avgConsistency = rs.getInt("avg_consistency")
        return rollup
    }

    /** Read a [MonthlyRollup] from a ResultSet row. */
    private fun readMonthlyRollupFromResultSet(rs: ResultSet): MonthlyRollup {
        val rollup = MonthlyRollup()
        rollup.year = rs.getInt("year")
        rollup.month = rs.getInt("month_number")
        rollup.tripCount = rs.getInt("trip_count")
        rollup.totalDistanceKm = rs.getDouble("total_distance_km")
        rollup.totalDurationSeconds = rs.getInt("total_duration_seconds")
        rollup.avgEfficiency = rs.getDouble("avg_efficiency")
        rollup.totalEnergyKwh = rs.getDouble("total_energy_kwh")
        rollup.totalCost = rs.getDouble("total_cost")
        rollup.avgEnergyPerKm = rs.getDouble("avg_energy_per_km")
        rollup.avgAnticipation = rs.getInt("avg_anticipation")
        rollup.avgSmoothness = rs.getInt("avg_smoothness")
        rollup.avgSpeedDiscipline = rs.getInt("avg_speed_discipline")
        rollup.avgEfficiencyScore = rs.getInt("avg_efficiency_score")
        rollup.avgConsistency = rs.getInt("avg_consistency")
        return rollup
    }

    /** Read a [ConsumptionBucket] from a ResultSet row. */
    private fun readBucketFromResultSet(rs: ResultSet): ConsumptionBucket {
        val bucket = ConsumptionBucket()
        bucket.bucketKey = rs.getString("bucket_key")
        bucket.sampleCount = rs.getInt("sample_count")
        bucket.sumKwhPerKm = rs.getDouble("sum_kwh_per_km")
        bucket.sumSquaredKwhPerKm = rs.getDouble("sum_squared_kwh_per_km")
        return bucket
    }

    /** A monthly rollup by year and month (internal helper for [updateMonthlyRollup]). */
    private fun getMonthlyRollup(year: Int, month: Int): MonthlyRollup? {
        val sql = "SELECT * FROM monthly_rollups WHERE \"year\"=? AND month_number=?"
        try {
            conn().prepareStatement(sql).use { pstmt ->
                pstmt.setInt(1, year)
                pstmt.setInt(2, month)
                pstmt.executeQuery().use { rs ->
                    if (rs.next()) return readMonthlyRollupFromResultSet(rs)
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to get monthly rollup year=$year month=$month", e)
        }
        return null
    }

    /** Running average: `(oldAvg * oldCount + newValue) / (oldCount + 1)`. */
    private fun runningAvg(oldAvg: Double, oldCount: Int, newValue: Double): Double =
        (oldAvg * oldCount + newValue) / (oldCount + 1)

    /**
     * Delete orphaned trips — those with `end_time == 0` or `duration_seconds == 0` older than
     * the given cutoff, left behind by daemon crashes mid-trip.
     *
     * @return the number of deleted rows
     */
    fun deleteOrphanedTrips(olderThanMs: Long): Int {
        if (!ensureConnection()) return 0
        try {
            conn().prepareStatement(
                "DELETE FROM trips WHERE (end_time = 0 OR duration_seconds = 0) AND start_time < ?"
            ).use { pstmt ->
                pstmt.setLong(1, olderThanMs)
                val deleted = pstmt.executeUpdate()
                if (deleted > 0) logger.info("Cleaned up $deleted orphaned trip(s)")
                return deleted
            }
        } catch (e: Exception) {
            logger.error("Failed to delete orphaned trips: " + e.message)
            return 0
        }
    }

    /** Whether the database is initialized and available. */
    fun isAvailable(): Boolean = isInitialized && connection != null

    // ==================== SYNC / RECONCILE ====================

    /**
     * All non-empty telemetry file paths currently referenced by trip rows. Used by the manual
     * trips sync to detect orphan telemetry files on disk.
     */
    fun getAllTelemetryPaths(): List<String> {
        val paths = ArrayList<String>()
        if (!ensureConnection()) return paths
        val sql = "SELECT telemetry_file_path FROM trips " +
            "WHERE telemetry_file_path IS NOT NULL AND telemetry_file_path <> ''"
        try {
            conn().createStatement().use { stmt ->
                stmt.executeQuery(sql).use { rs ->
                    while (rs.next()) {
                        val p = rs.getString(1)
                        if (!p.isNullOrEmpty()) paths.add(p)
                    }
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to read telemetry paths", e)
            reconnect()
        }
        return paths
    }

    /**
     * Delete trips whose referenced telemetry file no longer exists on disk.
     *
     * Trips with a null or empty telemetry path are left alone — legacy history predating
     * telemetry-path storage must NOT be pruned.
     *
     * @return the number of rows removed
     */
    fun deleteTripsWithMissingTelemetry(): Int {
        if (!ensureConnection()) return 0
        val toDelete = ArrayList<Long>()
        val sql = "SELECT id, telemetry_file_path FROM trips " +
            "WHERE telemetry_file_path IS NOT NULL AND telemetry_file_path <> ''"
        try {
            conn().createStatement().use { stmt ->
                stmt.executeQuery(sql).use { rs ->
                    while (rs.next()) {
                        val id = rs.getLong(1)
                        val p = rs.getString(2)
                        if (!p.isNullOrEmpty() && !File(p).exists()) toDelete.add(id)
                    }
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to scan trips for missing telemetry", e)
            reconnect()
            return 0
        }
        var removed = 0
        for (id in toDelete) {
            if (deleteTrip(id)) removed++
        }
        if (removed > 0) {
            logger.info("Trips sync: pruned $removed trip(s) with missing telemetry")
        }
        return removed
    }

    private companion object {
        private const val TAG = "TripDatabase"
        private val logger = DaemonLogger.getInstance(TAG)

        // Persistent home under the user-visible BladeWatch tree so the trip history survives
        // app uninstall/reinstall and updates (the old /data/local/tmp location can be
        // recreated across head-unit resets). Both writers run as the shell daemon UID; the
        // app reads via the daemon API, so external-storage POSIX-permission limits do not
        // apply here. H2-on-external is already proven by SocHistoryDatabase.
        private const val DB_PATH =
            "/storage/emulated/0/BladeWatch/data/bladewatch_trips_h2"

        /** Old DB home, migrated once on first init (see migrateLegacyDbIfNeeded). */
        private const val LEGACY_DB_PATH = "/data/local/tmp/bladewatch_trips_h2"

        // DB_CLOSE_ON_EXIT=FALSE: avoid H2's JVM shutdown hook racing the daemon's explicit
        // close path. Without this we hit the same orphaned-lock-file pattern as
        // SocHistoryDatabase, which blocks the next CameraDaemon start with "Locked by another
        // process".
        //
        // AUTO_SERVER omitted — incompatible with DB_CLOSE_ON_EXIT=FALSE (H2 throws
        // JdbcSQLFeatureNotSupportedException at init). Single-process architecture: only
        // CameraDaemon writes, TripApiHandler reads from the same JVM. FILE_LOCK=SOCKET
        // handles cross-process safety.
        private const val JDBC_URL =
            "jdbc:h2:file:$DB_PATH;FILE_LOCK=SOCKET;TRACE_LEVEL_FILE=0;DB_CLOSE_ON_EXIT=FALSE"

        /**
         * Column list for the PHEV fuel leg and the metered-energy counters, in the SAME order
         * as [setFuelParams]. Shared between the INSERT column list and the binding so the two
         * cannot drift — a silent column/parameter mismatch writes every value into the wrong
         * field and still executes cleanly.
         */
        /**
         * LIKE pattern matching every fuel bucket key, for the statements that must operate on
         * the ELECTRIC buckets only.
         *
         * `_` is a single-character wildcard in SQL LIKE, so the prefix's own underscore is
         * escaped — without it the pattern would also match a key spelled `fuel` plus any one
         * character. Derived from [FuelConsumption.FUEL_PREFIX] so it cannot drift from the
         * prefix the writer actually uses.
         */
        private val FUEL_KEY_PATTERN = FuelConsumption.FUEL_PREFIX.replace("_", "\\_") + "%"

        private const val FUEL_COLUMNS =
            "fuel_pct_start, fuel_pct_end, fuel_con_start, fuel_con_end, " +
                "elec_con_start, elec_con_end, litres_used, fuel_price_per_l, " +
                "fuel_cost, electric_cost"
    }
}
