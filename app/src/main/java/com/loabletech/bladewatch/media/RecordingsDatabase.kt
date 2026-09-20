package net.bladewatch.app.media

import net.bladewatch.app.logging.DaemonLogger
import org.json.JSONObject
import java.io.File
import java.sql.Connection
import java.sql.DriverManager

/**
 * H2 embedded database that indexes recordings / surveillance / proximity clips so the web UI can
 * list them without re-scanning the filesystem and re-parsing every JSON sidecar on each poll.
 *
 * Mirrors `TripDatabase`'s connection handling (FILE_LOCK=SOCKET, DB_CLOSE_ON_EXIT=FALSE,
 * retry/backoff, ensureConnection). One difference matters: this DB is written from several
 * threads — the event recorder's drain thread via `StorageManager.onFileSaved`, the sidecar
 * writer's executor, the normal-recording promote path, and an HTTP worker running a manual sync
 * — whereas the trip DB is daemon-thread confined. Every method is therefore `@Synchronized` on
 * this instance: the single H2 [Connection] is not safe for concurrent use.
 *
 * Each row stores the full parsed recording JSON (exactly the object `RecordingsApiHandler`
 * returns per clip) plus a few indexed columns for cheap filtering and sorting.
 */
class RecordingsDatabase {

    private var connection: Connection? = null

    @Volatile
    private var isInitialized = false

    // ==================== LIFECYCLE ====================

    @Synchronized
    fun init() {
        if (isInitialized) return

        logger.info("Initializing H2 media database at: $DB_PATH")
        ensureDbDir()

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
                val conn = DriverManager.getConnection(JDBC_URL, "sa", "")
                connection = conn
                conn.createStatement().use { it.execute("SET CACHE_SIZE 8192") }
                createTables()
                isInitialized = true
                logger.info("Media Database initialized via H2 (Pure Java): $DB_PATH")
                return
            } catch (e: Exception) {
                val msg = e.message
                val isLockError = msg != null && (
                    msg.contains("Locked by another process") ||
                        msg.contains("lock.db") ||
                        msg.contains("already in use")
                    )
                if (isLockError && attempt < maxRetries) {
                    logger.warn("Media DB locked (attempt $attempt/$maxRetries), cleaning up stale locks...")
                    cleanupStaleLocks()
                    try {
                        Thread.sleep(retryDelayMs * attempt)
                    } catch (ie: InterruptedException) {
                        Thread.currentThread().interrupt()
                        break
                    }
                } else {
                    logger.error(
                        "Failed to initialize media database: " + e.javaClass.name + " - " + msg, e
                    )
                    break
                }
            }
        }
    }

    @Synchronized
    fun close() {
        connection?.let {
            try {
                it.close()
                logger.info("Media database connection closed")
            } catch (e: Exception) {
                logger.error("Failed to close media database connection", e)
            }
        }
        connection = null
        isInitialized = false
    }

    @Synchronized
    fun isAvailable(): Boolean = isInitialized && connection != null

    @Synchronized
    private fun reconnect() {
        try {
            val conn = connection
            if (conn == null || conn.isClosed) {
                connection = DriverManager.getConnection(JDBC_URL, "sa", "")
                isInitialized = true
                logger.info("H2 media database connection re-established")
            }
        } catch (e: Exception) {
            logger.error("Failed to reconnect to H2 media database", e)
        }
    }

    private fun ensureConnection(): Boolean {
        if (!isInitialized && connection == null) return false
        return try {
            val conn = connection
            if (conn == null || conn.isClosed) {
                logger.info("Media DB connection closed, reconnecting...")
                reconnect()
                connection?.isClosed == false
            } else {
                true
            }
        } catch (e: Exception) {
            logger.error("Media DB connection check failed", e)
            reconnect()
            try {
                connection?.isClosed == false
            } catch (e2: Exception) {
                false
            }
        }
    }

    private fun ensureDbDir() {
        try {
            val parent = File(DB_PATH).parentFile
            if (parent != null && !parent.exists() && !parent.mkdirs()) {
                logger.warn("Failed to create media DB directory: " + parent.absolutePath)
            }
        } catch (e: Exception) {
            logger.warn("ensureDbDir failed: " + e.message)
        }
    }

    private fun cleanupStaleLocks() {
        try {
            val lockFile = File("$DB_PATH.lock.db")
            if (lockFile.exists()) {
                val ageMs = System.currentTimeMillis() - lockFile.lastModified()
                if (ageMs > 5 * 60 * 1000) {
                    if (lockFile.delete()) {
                        logger.info("Deleted stale media DB lock file (age: " + (ageMs / 1000) + "s)")
                    }
                }
            }
            val traceFile = File("$DB_PATH.trace.db")
            if (traceFile.exists()) traceFile.delete()
        } catch (e: Exception) {
            logger.debug("Media DB lock cleanup failed: " + e.message)
        }
    }

    private fun createTables() {
        connection!!.createStatement().use { stmt ->
            stmt.execute(
                "CREATE TABLE IF NOT EXISTS recordings (" +
                    "path VARCHAR(700) PRIMARY KEY," + // absolute mp4 path (natural key)
                    "filename VARCHAR(255) NOT NULL," +
                    "type VARCHAR(16) NOT NULL," + // normal | sentry | proximity
                    "timestamp_ms BIGINT NOT NULL," + // parsed from filename
                    "size_bytes BIGINT DEFAULT 0," + // change detection
                    "mtime BIGINT DEFAULT 0," + // change detection
                    "sidecar_mtime BIGINT DEFAULT 0," + // change detection (enrichment)
                    "json CLOB" + // full parsed recording object
                    ")"
            )
            stmt.execute("CREATE INDEX IF NOT EXISTS idx_rec_ts ON recordings(timestamp_ms)")
            stmt.execute("CREATE INDEX IF NOT EXISTS idx_rec_type ON recordings(type)")
        }
    }

    // ==================== WRITE ====================

    /** Insert or update a recording row keyed by absolute path. */
    @Synchronized
    fun upsert(
        path: String, filename: String, type: String, timestampMs: Long,
        sizeBytes: Long, mtime: Long, sidecarMtime: Long, json: String,
    ) {
        if (!ensureConnection()) return
        val sql = "MERGE INTO recordings (path, filename, type, timestamp_ms, " +
            "size_bytes, mtime, sidecar_mtime, json) KEY(path) VALUES (?, ?, ?, ?, ?, ?, ?, ?)"
        try {
            connection!!.prepareStatement(sql).use { pstmt ->
                pstmt.setString(1, path)
                pstmt.setString(2, filename)
                pstmt.setString(3, type)
                pstmt.setLong(4, timestampMs)
                pstmt.setLong(5, sizeBytes)
                pstmt.setLong(6, mtime)
                pstmt.setLong(7, sidecarMtime)
                pstmt.setString(8, json)
                pstmt.executeUpdate()
            }
        } catch (e: Exception) {
            logger.error("Failed to upsert recording: $path", e)
            reconnect()
        }
    }

    @Synchronized
    fun deleteByPath(absPath: String?): Boolean {
        if (absPath == null || !ensureConnection()) return false
        try {
            connection!!.prepareStatement("DELETE FROM recordings WHERE path=?").use { pstmt ->
                pstmt.setString(1, absPath)
                return pstmt.executeUpdate() > 0
            }
        } catch (e: Exception) {
            logger.error("Failed to delete recording: $absPath", e)
            reconnect()
        }
        return false
    }

    @Synchronized
    fun resetAll(): Long {
        if (!ensureConnection()) return -1
        return try {
            connection!!.createStatement().use { stmt ->
                val n = stmt.executeUpdate("DELETE FROM recordings")
                logger.info("resetAll: cleared $n rows from recordings")
                n.toLong()
            }
        } catch (e: Exception) {
            logger.error("media resetAll failed", e)
            -1
        }
    }

    // ==================== READ ====================

    @Synchronized
    fun getCount(): Int {
        if (!ensureConnection()) return 0
        try {
            connection!!.createStatement().use { stmt ->
                stmt.executeQuery("SELECT COUNT(*) FROM recordings").use { rs ->
                    if (rs.next()) return rs.getInt(1)
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to get recording count", e)
            reconnect()
        }
        return 0
    }

    /**
     * Full recording objects within the time window, optionally narrowed by type, newest first.
     *
     * Returns the same JSON shape the filesystem scan produces (stored verbatim), so the API
     * post-processing — dedup, filtering, pagination — is identical regardless of source.
     */
    @Synchronized
    fun getRecordings(type: String?, startMs: Long, endMs: Long): List<JSONObject> {
        val out = ArrayList<JSONObject>()
        if (!ensureConnection()) return out
        val hasType = !type.isNullOrEmpty()
        val sql = StringBuilder(
            "SELECT json FROM recordings WHERE timestamp_ms >= ? AND timestamp_ms < ?"
        )
        if (hasType) sql.append(" AND type = ?")
        sql.append(" ORDER BY timestamp_ms DESC")
        try {
            connection!!.prepareStatement(sql.toString()).use { pstmt ->
                pstmt.setLong(1, startMs)
                pstmt.setLong(2, endMs)
                if (hasType) pstmt.setString(3, type)
                pstmt.executeQuery().use { rs ->
                    while (rs.next()) {
                        val json = rs.getString(1) ?: continue
                        try {
                            out.add(JSONObject(json))
                        } catch (ignored: Exception) {
                            // Skip a corrupt row; reconcile/sync will rebuild it.
                            logger.warn(
                                "Skipping corrupt JSON row in recordings query: " + ignored.message
                            )
                        }
                    }
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to query recordings", e)
            reconnect()
        }
        return out
    }

    /**
     * One `long[2]` per row: `[timestamp_ms, isSentry]` (isSentry=1 when type='sentry', else 0)
     * for calendar/date aggregation. Avoids allocating JSONObjects; no json CLOB read.
     */
    @Synchronized
    fun getDateRows(): List<LongArray> {
        val out = ArrayList<LongArray>()
        if (!ensureConnection()) return out
        try {
            connection!!.createStatement().use { stmt ->
                stmt.executeQuery(
                    "SELECT timestamp_ms, CASE WHEN type='sentry' THEN 1 ELSE 0 END" +
                        " FROM recordings ORDER BY timestamp_ms DESC"
                ).use { rs ->
                    while (rs.next()) out.add(longArrayOf(rs.getLong(1), rs.getLong(2)))
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to query date rows", e)
            reconnect()
        }
        return out
    }

    /**
     * Aggregates per-type counts, live sizes and today-window counts into the caller's [agg]
     * without materialising JSON.
     *
     * Uses live `File.length()` per row for size accuracy — stale `size_bytes` values from
     * SD-card write errors get corrected — falling back to the stored value when the file is
     * temporarily unavailable. Deduplicates by filename per type to match the filesystem scan
     * (a clip reachable at two paths is counted once).
     *
     * [agg] layout: 0=normalSize, 1=normalCount, 2=sentrySize, 3=sentryCount, 4=proximitySize,
     * 5=proximityCount, 6=normalToday, 7=sentryToday, 8=proximityToday.
     */
    @Synchronized
    fun aggregateForStats(agg: LongArray, todayStartMs: Long, todayEndMs: Long) {
        if (!ensureConnection()) return
        val seenNormal = HashSet<String>()
        val seenSentry = HashSet<String>()
        val seenProx = HashSet<String>()
        try {
            connection!!.createStatement().use { stmt ->
                stmt.executeQuery(
                    "SELECT path, filename, type, size_bytes, timestamp_ms FROM recordings"
                ).use { rs ->
                    while (rs.next()) {
                        val path = rs.getString(1)
                        val fn = rs.getString(2)
                        val type = rs.getString(3)
                        val storedSize = rs.getLong(4)
                        val ts = rs.getLong(5)
                        // Live file length for accuracy; fall back to the stored value.
                        var size = storedSize
                        if (!path.isNullOrEmpty()) {
                            val live = File(path).length()
                            if (live > 0) size = live
                        }
                        val today = ts in todayStartMs until todayEndMs
                        when (type) {
                            "sentry" -> {
                                if (!seenSentry.add(fn)) continue
                                agg[2] += size; agg[3]++; if (today) agg[7]++
                            }
                            "proximity" -> {
                                if (!seenProx.add(fn)) continue
                                agg[4] += size; agg[5]++; if (today) agg[8]++
                            }
                            else -> {
                                if (!seenNormal.add(fn)) continue
                                agg[0] += size; agg[1]++; if (today) agg[6]++
                            }
                        }
                    }
                }
            }
        } catch (e: Exception) {
            logger.error("aggregateForStats failed", e)
            reconnect()
        }
    }

    /** Map of absolute path -> `[size, mtime, sidecarMtime]` for reconcile diffing. */
    @Synchronized
    fun getAllPathState(): Map<String, LongArray> {
        val out = HashMap<String, LongArray>()
        if (!ensureConnection()) return out
        try {
            connection!!.createStatement().use { stmt ->
                stmt.executeQuery(
                    "SELECT path, size_bytes, mtime, sidecar_mtime FROM recordings"
                ).use { rs ->
                    while (rs.next()) {
                        out[rs.getString(1)] =
                            longArrayOf(rs.getLong(2), rs.getLong(3), rs.getLong(4))
                    }
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to read recording path state", e)
            reconnect()
        }
        return out
    }

    private companion object {
        val logger: DaemonLogger = DaemonLogger.getInstance("RecordingsDatabase")

        // Persistent home under the user-visible BladeWatch tree (same rationale as
        // TripDatabase): survives app uninstall/reinstall, written by the shell daemon UID.
        const val DB_PATH = "/storage/emulated/0/BladeWatch/data/bladewatch_media_h2"
        const val JDBC_URL = "jdbc:h2:file:" + DB_PATH +
            ";FILE_LOCK=SOCKET;TRACE_LEVEL_FILE=0;DB_CLOSE_ON_EXIT=FALSE"
    }
}
