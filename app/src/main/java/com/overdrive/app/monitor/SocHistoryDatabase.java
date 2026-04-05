package com.overdrive.app.monitor;

import com.overdrive.app.logging.DaemonLogger;

import org.json.JSONArray;
import org.json.JSONObject;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * SOTA SocHistoryDatabase - Uses H2 embedded database (100% pure Java).
 * 
 * H2 advantages over SQLite/SQLDroid:
 * - Zero native dependencies (no .so files, no UnsatisfiedLinkError)
 * - Zero Android framework dependency (no Context, no package verification)
 * - Full SQL support with SQLite compatibility mode
 * - Works perfectly for UID 2000 daemon processes
 */
public class SocHistoryDatabase {
    
    private static final String TAG = "SocHistoryDatabase";
    private static final DaemonLogger logger = DaemonLogger.getInstance(TAG);
    
    // H2 JDBC URL - file-based embedded database
    // FILE_LOCK=SOCKET uses socket-based locking (more reliable than file locks on Android)
    // AUTO_SERVER=TRUE allows multiple processes to connect via TCP fallback
    private static final String DB_PATH = "/data/local/tmp/overdrive_soc_h2";
    private static final String JDBC_URL = "jdbc:h2:file:" + DB_PATH + 
        ";AUTO_SERVER=TRUE;FILE_LOCK=SOCKET;TRACE_LEVEL_FILE=0";
    
    // Table names
    private static final String TABLE_SOC = "soc_history";
    private static final String TABLE_CHARGING = "charging_sessions";
    
    // Retention periods
    private static final long RETENTION_DAYS = 7;
    private static final long SAMPLE_INTERVAL_MS = 120_000;  // 2 minutes - SOTA interval for daemon recording
    
    // Singleton
    private static SocHistoryDatabase instance;
    private static final Object lock = new Object();
    
    // H2 Connection (kept open for performance)
    private Connection connection;
    
    private ScheduledExecutorService scheduler;
    private volatile boolean isRunning = false;
    private volatile boolean isInitialized = false;
    
    // Charging session tracking
    private boolean wasCharging = false;
    private long chargingStartTime = 0;
    private double chargingStartSoc = 0;
    
    // Last recorded values for deduplication
    private long lastRecordTime = 0;
    private double lastRecordedSoc = -1;
    
    private SocHistoryDatabase() {
        // Load the H2 JDBC driver (pure Java - always works)
        try {
            Class.forName("org.h2.Driver");
            logger.info("H2 JDBC Driver loaded successfully");
        } catch (ClassNotFoundException e) {
            logger.error("H2 Driver not found! Check gradle dependencies.", e);
        } catch (Exception e) {
            logger.error("Failed to load H2 Driver: " + e.getMessage(), e);
        }
    }
    
    public static SocHistoryDatabase getInstance() {
        if (instance == null) {
            synchronized (lock) {
                if (instance == null) {
                    instance = new SocHistoryDatabase();
                }
            }
        }
        return instance;
    }
    
    // ==================== LIFECYCLE ====================
    
    public void init() {
        if (isInitialized) return;
        
        synchronized (lock) {
            if (isInitialized) return;  // Double-check after acquiring lock
            
            logger.info("Initializing H2 database at: " + DB_PATH);
            
            int maxRetries = 3;
            int retryDelayMs = 1000;
            
            for (int attempt = 1; attempt <= maxRetries; attempt++) {
                try {
                    // Open H2 connection (pure Java - no native code)
                    connection = DriverManager.getConnection(JDBC_URL, "sa", "");
                    logger.info("H2 connection established");
                    
                    // Tune H2 for embedded daemon use
                    try (Statement stmt = connection.createStatement()) {
                        stmt.execute("SET CACHE_SIZE 8192");  // 8MB cache
                    }
                    
                    // Create tables
                    createTables();
                    
                    isInitialized = true;
                    logger.info("SOC History Database initialized via H2 (Pure Java): " + DB_PATH);
                    return;  // Success - exit
                    
                } catch (Exception e) {
                    String msg = e.getMessage();
                    boolean isLockError = msg != null && (msg.contains("Locked by another process") || 
                        msg.contains("lock.db") || msg.contains("already in use"));
                    
                    if (isLockError && attempt < maxRetries) {
                        logger.warn("Database locked (attempt " + attempt + "/" + maxRetries + "), cleaning up stale locks...");
                        cleanupStaleLocks();
                        try {
                            Thread.sleep(retryDelayMs * attempt);  // Exponential backoff
                        } catch (InterruptedException ie) {
                            Thread.currentThread().interrupt();
                            break;
                        }
                    } else {
                        logger.error("Failed to initialize SOC database: " + e.getClass().getName() + " - " + msg, e);
                        break;
                    }
                }
            }
        }
    }
    
    /**
     * Clean up stale lock files that may have been left by crashed processes.
     */
    private void cleanupStaleLocks() {
        try {
            java.io.File lockFile = new java.io.File(DB_PATH + ".lock.db");
            if (lockFile.exists()) {
                // Check if the lock file is stale (older than 5 minutes with no active process)
                long ageMs = System.currentTimeMillis() - lockFile.lastModified();
                if (ageMs > 5 * 60 * 1000) {  // 5 minutes
                    if (lockFile.delete()) {
                        logger.info("Deleted stale lock file (age: " + (ageMs / 1000) + "s)");
                    }
                }
            }
            
            // Also try to clean up trace files
            java.io.File traceFile = new java.io.File(DB_PATH + ".trace.db");
            if (traceFile.exists()) {
                traceFile.delete();
            }
        } catch (Exception e) {
            logger.debug("Lock cleanup failed: " + e.getMessage());
        }
    }
    
    private void createTables() throws Exception {
        try (Statement stmt = connection.createStatement()) {
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
            );
            
            // Add remaining_kwh column if it doesn't exist (migration for existing DBs)
            try {
                stmt.execute("ALTER TABLE " + TABLE_SOC + " ADD COLUMN IF NOT EXISTS remaining_kwh REAL DEFAULT 0;");
            } catch (Exception ignored) {
                // Column may already exist
            }
            
            // Index for fast time-based queries
            stmt.execute(
                "CREATE INDEX IF NOT EXISTS idx_soc_timestamp ON " + TABLE_SOC + "(timestamp);"
            );
            
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
            );
            
            stmt.execute(
                "CREATE INDEX IF NOT EXISTS idx_charging_start ON " + TABLE_CHARGING + "(start_time);"
            );
        }
    }

    public void start() {
        if (isRunning) return;
        
        if (!isInitialized) {
            init();
        }
        
        if (!isInitialized) {
            logger.error("Cannot start SOC history - database init failed");
            return;
        }
        
        isRunning = true;
        
        scheduler = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "SocHistoryDB");
            t.setPriority(Thread.MIN_PRIORITY);
            // Set uncaught exception handler to prevent silent death
            t.setUncaughtExceptionHandler((thread, ex) -> {
                logger.error("Uncaught exception in SocHistoryDB thread: " + ex.getMessage(), ex);
            });
            return t;
        });
        
        // Record SOC every minute - wrap in Runnable that catches all exceptions
        scheduler.scheduleAtFixedRate(() -> {
            try {
                recordCurrentSoc();
            } catch (Throwable t) {
                // Catch everything including Errors to prevent scheduler death
                logger.error("Critical error in SOC recording task: " + t.getMessage(), 
                    t instanceof Exception ? (Exception) t : new Exception(t));
            }
        }, 0, SAMPLE_INTERVAL_MS, TimeUnit.MILLISECONDS);
        
        // Cleanup old data daily
        scheduler.scheduleAtFixedRate(() -> {
            try {
                cleanupOldData();
            } catch (Throwable t) {
                logger.error("Critical error in cleanup task: " + t.getMessage(),
                    t instanceof Exception ? (Exception) t : new Exception(t));
            }
        }, 1, 24, TimeUnit.HOURS);
        
        logger.info("SOC history recording started (interval: " + SAMPLE_INTERVAL_MS + "ms)");
    }
    
    public void stop() {
        isRunning = false;
        if (scheduler != null) {
            scheduler.shutdownNow();
            scheduler = null;
        }
        
        // Close connection
        if (connection != null) {
            try {
                connection.close();
            } catch (Exception ignored) {}
            connection = null;
        }
        
        logger.info("SOC history recording stopped");
    }
    
    private void reconnect() {
        try {
            if (connection == null || connection.isClosed()) {
                connection = DriverManager.getConnection(JDBC_URL, "sa", "");
                logger.debug("H2 connection re-established");
            }
        } catch (Exception e) {
            logger.error("Failed to reconnect to H2", e);
        }
    }
    
    // ==================== DATA RECORDING ====================
    
    private void recordCurrentSoc() {
        // Wrap entire method in try-catch to prevent scheduler death
        try {
            if (!isInitialized || connection == null) {
                logger.debug("SOC recording skipped: not initialized or no connection");
                reconnect();
                return;
            }
            
            VehicleDataMonitor monitor = VehicleDataMonitor.getInstance();
            if (monitor == null) {
                logger.debug("SOC recording skipped: VehicleDataMonitor not available");
                return;
            }
            
            BatterySocData socData = monitor.getBatterySoc();
            ChargingStateData chargingData = monitor.getChargingState();
            DrivingRangeData rangeData = monitor.getDrivingRange();
            BatteryPowerData powerData = monitor.getBatteryPower();
            
            if (socData == null) {
                logger.debug("SOC recording skipped: no SOC data available");
                return;
            }
            
            double soc = socData.socPercent;
            boolean isCharging = chargingData != null && 
                chargingData.status == ChargingStateData.ChargingStatus.CHARGING;
            double chargingPower = chargingData != null ? chargingData.chargingPowerKW : 0;
            double voltage = powerData != null ? powerData.voltageVolts : 0;
            int range = rangeData != null ? rangeData.elecRangeKm : 0;
            
            // SOTA: Get remaining battery power in kWh from BYDAutoPowerDevice
            double remainingKwh = 0;
            try {
                remainingKwh = monitor.getBatteryRemainPowerKwh();
            } catch (Exception e) {
                logger.debug("Failed to get remaining kWh: " + e.getMessage());
            }
            
            long now = System.currentTimeMillis();
            
            // Record at least once every 10 minutes regardless of SOC change
            // This ensures continuous data even when parked (5x the 2-min interval)
            long maxInterval = SAMPLE_INTERVAL_MS * 5; // 10 minutes
            boolean forceRecord = (now - lastRecordTime) >= maxInterval;
            
            // Skip only if SOC hasn't changed AND we recorded recently (within 10 min)
            if (!forceRecord && lastRecordedSoc >= 0 && Math.abs(soc - lastRecordedSoc) < 0.5) {
                return;
            }
            
            // Check connection is still valid
            try {
                if (connection.isClosed()) {
                    logger.info("Connection closed, reconnecting...");
                    reconnect();
                    if (connection == null || connection.isClosed()) {
                        logger.error("Failed to reconnect to database");
                        return;
                    }
                }
            } catch (Exception e) {
                logger.error("Connection check failed", e);
                reconnect();
                return;
            }
            
            // Insert with remaining_kwh
            String sql = "INSERT INTO " + TABLE_SOC + 
                " (timestamp, soc_percent, is_charging, charging_power_kw, voltage_v, range_km, remaining_kwh) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?);";
            
            try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
                pstmt.setLong(1, now);
                pstmt.setDouble(2, soc);
                pstmt.setInt(3, isCharging ? 1 : 0);
                pstmt.setDouble(4, chargingPower);
                pstmt.setDouble(5, voltage);
                pstmt.setInt(6, range);
                pstmt.setDouble(7, remainingKwh);
                pstmt.executeUpdate();
            }
            
            lastRecordTime = now;
            lastRecordedSoc = soc;
            
            logger.debug("Recorded SOC: " + soc + "% (charging: " + isCharging + ")");
            
            // Track charging sessions
            trackChargingSession(isCharging, soc, chargingPower, now);
            
        } catch (Exception e) {
            // Log but don't rethrow - scheduler must continue running
            logger.error("Failed to record SOC: " + e.getMessage(), e);
            try {
                reconnect();
            } catch (Exception re) {
                logger.error("Reconnect also failed: " + re.getMessage());
            }
        }
    }
    
    private void trackChargingSession(boolean isCharging, double soc, double power, long now) {
        if (!isInitialized || connection == null) return;
        
        try {
            if (isCharging && !wasCharging) {
                // Charging started
                chargingStartTime = now;
                chargingStartSoc = soc;
                
                String sql = "INSERT INTO " + TABLE_CHARGING + 
                    " (start_time, start_soc, peak_power_kw) VALUES (?, ?, ?);";
                
                try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
                    pstmt.setLong(1, now);
                    pstmt.setDouble(2, soc);
                    pstmt.setDouble(3, power);
                    pstmt.executeUpdate();
                }
                
                logger.info("Charging session started at " + soc + "%");
                
            } else if (!isCharging && wasCharging) {
                // Charging ended
                double energyAdded = (soc - chargingStartSoc) * 0.6; // Rough estimate
                
                String sql = "UPDATE " + TABLE_CHARGING + 
                    " SET end_time = ?, end_soc = ?, energy_added_kwh = ? " +
                    "WHERE start_time = ? AND end_time IS NULL;";
                
                try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
                    pstmt.setLong(1, now);
                    pstmt.setDouble(2, soc);
                    pstmt.setDouble(3, energyAdded);
                    pstmt.setLong(4, chargingStartTime);
                    pstmt.executeUpdate();
                }
                
                logger.info("Charging session ended at " + soc + "% (+" + 
                    String.format("%.1f", soc - chargingStartSoc) + "%)");
            }
            
            wasCharging = isCharging;
            
        } catch (Exception e) {
            logger.error("Failed to track charging session", e);
        }
    }


    // ==================== DATA RETRIEVAL ====================
    
    /**
     * Get SOC history for charting.
     * Uses time-based bucketing for efficient downsampling - larger windows = larger buckets.
     * Returns data in ASC order (oldest first) for time-series chart rendering.
     */
    public JSONArray getSocHistory(int hoursBack, int maxPoints) {
        JSONArray results = new JSONArray();
        
        if (!isInitialized || connection == null) {
            logger.debug("Database not initialized for getSocHistory");
            return results;
        }
        
        try {
            long now = System.currentTimeMillis();
            int hours = Math.min(hoursBack, 168);
            long startTime = now - (hours * 60 * 60 * 1000L);
            
            // Calculate bucket size based on time window
            // Goal: ~maxPoints buckets across the time range
            // Minimum bucket: 2 minutes (one sample), Maximum: 30 minutes for week view
            long timeRangeMs = hours * 60 * 60 * 1000L;
            long bucketMs = Math.max(120_000L, timeRangeMs / maxPoints); // At least 2 min
            bucketMs = Math.min(bucketMs, 30 * 60 * 1000L); // Cap at 30 min
            
            // Time-bucketed query - takes first sample from each bucket
            // Much more efficient than row numbering for large datasets
            String querySql = 
                "SELECT MIN(timestamp) as t, " +
                "  AVG(soc_percent) as soc, " +
                "  MAX(is_charging) as charging, " +
                "  AVG(charging_power_kw) as power, " +
                "  AVG(range_km) as range, " +
                "  AVG(remaining_kwh) as kwh " +
                "FROM " + TABLE_SOC + " " +
                "WHERE timestamp >= ? " +
                "GROUP BY (timestamp / ?) " +
                "ORDER BY t ASC " +
                "LIMIT ?;";
            
            try (PreparedStatement pstmt = connection.prepareStatement(querySql)) {
                pstmt.setLong(1, startTime);
                pstmt.setLong(2, bucketMs);
                pstmt.setInt(3, maxPoints);
                
                try (ResultSet rs = pstmt.executeQuery()) {
                    while (rs.next()) {
                        JSONObject row = new JSONObject();
                        row.put("t", rs.getLong("t"));
                        row.put("soc", Math.round(rs.getDouble("soc") * 10) / 10.0); // 1 decimal
                        row.put("charging", rs.getInt("charging") == 1);
                        row.put("power", Math.round(rs.getDouble("power") * 100) / 100.0);
                        row.put("range", (int) rs.getDouble("range"));
                        row.put("kwh", Math.round(rs.getDouble("kwh") * 10) / 10.0);
                        results.put(row);
                    }
                }
            }
            
        } catch (Exception e) {
            logger.error("Failed to get SOC history", e);
            reconnect();
        }
        
        return results;
    }
    
    /**
     * Get charging sessions.
     */
    public JSONArray getChargingSessions(int daysBack) {
        JSONArray results = new JSONArray();
        
        if (!isInitialized || connection == null) {
            return results;
        }
        
        try {
            long startTime = System.currentTimeMillis() - (daysBack * 24 * 60 * 60 * 1000L);
            
            String sql = "SELECT start_time as startTime, end_time as endTime, start_soc as startSoc, " +
                "end_soc as endSoc, energy_added_kwh as energyAdded, peak_power_kw as peakPower " +
                "FROM " + TABLE_CHARGING + " WHERE start_time >= ? ORDER BY start_time DESC;";
            
            try (PreparedStatement pstmt = connection.prepareStatement(sql)) {
                pstmt.setLong(1, startTime);
                
                try (ResultSet rs = pstmt.executeQuery()) {
                    while (rs.next()) {
                        JSONObject row = new JSONObject();
                        row.put("startTime", rs.getLong("startTime"));
                        row.put("endTime", rs.getLong("endTime"));
                        row.put("startSoc", rs.getDouble("startSoc"));
                        row.put("endSoc", rs.getDouble("endSoc"));
                        row.put("energyAdded", rs.getDouble("energyAdded"));
                        row.put("peakPower", rs.getDouble("peakPower"));
                        results.put(row);
                    }
                }
            }
            
        } catch (Exception e) {
            logger.error("Failed to get charging sessions", e);
            reconnect();
        }
        
        return results;
    }
    
    /**
     * Get SOC statistics.
     */
    public JSONObject getSocStats(int hoursBack) {
        JSONObject stats = new JSONObject();
        
        try {
            // Always get current SOC from VehicleDataMonitor
            VehicleDataMonitor monitor = VehicleDataMonitor.getInstance();
            BatterySocData currentSoc = monitor.getBatterySoc();
            if (currentSoc != null) {
                stats.put("currentSoc", currentSoc.socPercent);
                stats.put("isLow", currentSoc.isLow);
                stats.put("isCritical", currentSoc.isCritical);
            }
            
            if (!isInitialized || connection == null) {
                return stats;
            }
            
            long startTime = System.currentTimeMillis() - (hoursBack * 60 * 60 * 1000L);
            
            // Get min/max/avg/count
            String statsSql = "SELECT MIN(soc_percent), MAX(soc_percent), AVG(soc_percent), COUNT(*) " +
                "FROM " + TABLE_SOC + " WHERE timestamp >= ?;";
            
            try (PreparedStatement pstmt = connection.prepareStatement(statsSql)) {
                pstmt.setLong(1, startTime);
                
                try (ResultSet rs = pstmt.executeQuery()) {
                    if (rs.next()) {
                        stats.put("minSoc", rs.getDouble(1));
                        stats.put("maxSoc", rs.getDouble(2));
                        stats.put("avgSoc", rs.getDouble(3));
                        stats.put("sampleCount", rs.getInt(4));
                    }
                }
            }
            
            // Get charging session count
            String chargingSql = "SELECT COUNT(*) FROM " + TABLE_CHARGING + " WHERE start_time >= ?;";
            
            try (PreparedStatement pstmt = connection.prepareStatement(chargingSql)) {
                pstmt.setLong(1, startTime);
                
                try (ResultSet rs = pstmt.executeQuery()) {
                    if (rs.next()) {
                        stats.put("chargingSessions", rs.getInt(1));
                    }
                }
            }
            
        } catch (Exception e) {
            logger.error("Failed to get SOC stats", e);
        }
        
        return stats;
    }
    
    /**
     * Get full report for dashboard.
     * Always includes current SOC from VehicleDataMonitor even if no history exists.
     */
    public JSONObject getFullReport(int hoursBack, int maxPoints) {
        JSONObject report = new JSONObject();
        
        try {
            JSONArray history = getSocHistory(hoursBack, maxPoints);
            JSONObject stats = getSocStats(hoursBack);
            
            // Always ensure current SOC is available from live monitor
            VehicleDataMonitor monitor = VehicleDataMonitor.getInstance();
            BatterySocData currentSocData = monitor.getBatterySoc();
            DrivingRangeData rangeData = monitor.getDrivingRange();
            ChargingStateData chargingData = monitor.getChargingState();
            
            // If we have live SOC data but no history, create a synthetic history point
            if (history.length() == 0 && currentSocData != null) {
                JSONObject livePoint = new JSONObject();
                livePoint.put("t", System.currentTimeMillis());
                livePoint.put("soc", currentSocData.socPercent);
                livePoint.put("charging", chargingData != null && 
                    chargingData.status == ChargingStateData.ChargingStatus.CHARGING);
                livePoint.put("power", chargingData != null ? chargingData.chargingPowerKW : 0);
                livePoint.put("range", rangeData != null ? rangeData.elecRangeKm : 0);
                livePoint.put("kwh", monitor.getBatteryRemainPowerKwh());
                history.put(livePoint);
            }
            
            // Ensure stats has current SOC even if DB query returned nothing
            if (!stats.has("currentSoc") && currentSocData != null) {
                stats.put("currentSoc", currentSocData.socPercent);
                stats.put("isLow", currentSocData.isLow);
                stats.put("isCritical", currentSocData.isCritical);
            }
            
            report.put("history", history);
            report.put("stats", stats);
            report.put("chargingSessions", getChargingSessions(hoursBack / 24));
            report.put("hoursBack", hoursBack);
            report.put("maxPoints", maxPoints);
            report.put("timestamp", System.currentTimeMillis());
            
            // Add live data flag so frontend knows data is fresh
            report.put("hasLiveData", currentSocData != null);
            
        } catch (Exception e) {
            logger.error("Failed to create full report", e);
        }
        
        return report;
    }
    
    // ==================== MAINTENANCE ====================
    
    private void cleanupOldData() {
        if (!isInitialized || connection == null) return;
        
        try {
            long cutoff = System.currentTimeMillis() - (RETENTION_DAYS * 24 * 60 * 60 * 1000L);
            
            String deleteSocSql = "DELETE FROM " + TABLE_SOC + " WHERE timestamp < ?;";
            try (PreparedStatement pstmt = connection.prepareStatement(deleteSocSql)) {
                pstmt.setLong(1, cutoff);
                int deleted = pstmt.executeUpdate();
                if (deleted > 0) {
                    logger.info("Cleaned up " + deleted + " old SOC records");
                }
            }
            
            String deleteChargingSql = "DELETE FROM " + TABLE_CHARGING + " WHERE start_time < ?;";
            try (PreparedStatement pstmt = connection.prepareStatement(deleteChargingSql)) {
                pstmt.setLong(1, cutoff);
                pstmt.executeUpdate();
            }
            
        } catch (Exception e) {
            logger.error("Failed to cleanup old data", e);
        }
    }
    
    /**
     * Get database file size.
     */
    public long getDatabaseSize() {
        try {
            java.io.File dbFile = new java.io.File(DB_PATH + ".mv.db");
            return dbFile.exists() ? dbFile.length() : 0;
        } catch (Exception e) {
            return 0;
        }
    }
    
    /**
     * Get record count.
     */
    public int getRecordCount() {
        if (!isInitialized || connection == null) return 0;
        
        try {
            String sql = "SELECT COUNT(*) FROM " + TABLE_SOC + ";";
            try (Statement stmt = connection.createStatement();
                 ResultSet rs = stmt.executeQuery(sql)) {
                if (rs.next()) {
                    return rs.getInt(1);
                }
            }
        } catch (Exception e) {
            logger.error("Failed to get record count", e);
        }
        return 0;
    }
    
    public boolean isRunning() {
        return isRunning;
    }
    
    public boolean isAvailable() {
        return isInitialized && connection != null;
    }
}
