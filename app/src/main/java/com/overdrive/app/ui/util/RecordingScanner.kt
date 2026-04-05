package com.overdrive.app.ui.util

import android.content.Context
import android.util.Log
import com.overdrive.app.ui.model.RecordingFile
import org.json.JSONObject
import java.io.BufferedReader
import java.io.File
import java.io.FileReader
import java.util.Calendar

/**
 * Simplified Scanner - Uses Direct File Access (SOTA Architecture).
 * Since App owns the directory, we trust the Disk, not the Database.
 * 
 * SOTA: Reads configured storage paths from /data/local/tmp/overdrive_config.json
 * to support both internal storage and SD card.
 */
object RecordingScanner {
    private const val TAG = "RecordingScanner"
    
    // Default paths (internal storage)
    private const val INTERNAL_BASE_DIR = "/storage/emulated/0/Overdrive"
    private const val RECORDINGS_SUBDIR = "recordings"
    private const val SURVEILLANCE_SUBDIR = "surveillance"
    private const val PROXIMITY_SUBDIR = "proximity"
    
    // Config file location (same as StorageManager)
    private const val CONFIG_FILE = "/data/local/tmp/overdrive_config.json"
    
    // Simple cache to prevent IO spam on UI refresh
    private var cachedRecordings: List<RecordingFile>? = null
    private var cacheTimestamp: Long = 0
    private const val CACHE_VALIDITY_MS = 5000L // 5 seconds
    
    // Cached storage paths
    private var cachedRecordingsDir: File? = null
    private var cachedSurveillanceDir: File? = null
    private var cachedProximityDir: File? = null
    private var configCacheTimestamp: Long = 0
    private const val CONFIG_CACHE_VALIDITY_MS = 10000L // 10 seconds
    
    /**
     * Load storage configuration and determine active directories.
     * Reads from /data/local/tmp/overdrive_config.json to get storage type settings.
     */
    private fun loadStorageConfig() {
        val now = System.currentTimeMillis()
        
        // Return cached config if still valid
        if (cachedRecordingsDir != null && now - configCacheTimestamp < CONFIG_CACHE_VALIDITY_MS) {
            return
        }
        
        var recordingsStorageType = "INTERNAL"
        var surveillanceStorageType = "INTERNAL"
        var sdCardPath: String? = null
        
        try {
            val configFile = File(CONFIG_FILE)
            if (configFile.exists()) {
                val reader = BufferedReader(FileReader(configFile))
                val sb = StringBuilder()
                var line: String?
                while (reader.readLine().also { line = it } != null) {
                    sb.append(line)
                }
                reader.close()
                
                val config = JSONObject(sb.toString())
                val storage = config.optJSONObject("storage")
                if (storage != null) {
                    recordingsStorageType = storage.optString("recordingsStorageType", "INTERNAL")
                    surveillanceStorageType = storage.optString("surveillanceStorageType", "INTERNAL")
                }
                
                Log.d(TAG, "Loaded config: recordings=$recordingsStorageType, surveillance=$surveillanceStorageType")
            }
        } catch (e: Exception) {
            Log.w(TAG, "Could not load storage config: ${e.message}")
        }
        
        // Discover SD card if needed
        if (recordingsStorageType == "SD_CARD" || surveillanceStorageType == "SD_CARD") {
            sdCardPath = discoverSdCardPath()
            Log.d(TAG, "SD card path: $sdCardPath")
        }
        
        // Set recordings directory
        cachedRecordingsDir = if (recordingsStorageType == "SD_CARD" && sdCardPath != null) {
            File(sdCardPath, "Overdrive/$RECORDINGS_SUBDIR")
        } else {
            File(INTERNAL_BASE_DIR, RECORDINGS_SUBDIR)
        }
        
        // Set surveillance directory
        cachedSurveillanceDir = if (surveillanceStorageType == "SD_CARD" && sdCardPath != null) {
            File(sdCardPath, "Overdrive/$SURVEILLANCE_SUBDIR")
        } else {
            File(INTERNAL_BASE_DIR, SURVEILLANCE_SUBDIR)
        }
        
        // Proximity follows surveillance storage type
        cachedProximityDir = if (surveillanceStorageType == "SD_CARD" && sdCardPath != null) {
            File(sdCardPath, "Overdrive/$PROXIMITY_SUBDIR")
        } else {
            File(INTERNAL_BASE_DIR, PROXIMITY_SUBDIR)
        }
        
        configCacheTimestamp = now
        
        Log.d(TAG, "Active directories: recordings=${cachedRecordingsDir?.absolutePath}, " +
            "surveillance=${cachedSurveillanceDir?.absolutePath}, proximity=${cachedProximityDir?.absolutePath}")
    }
    
    /**
     * Discover SD card mount path using multiple methods.
     */
    private fun discoverSdCardPath(): String? {
        // Method 1: Scan /storage/ for mounted volumes with UUID format (e.g., "3661-3064")
        try {
            val storageDir = File("/storage")
            if (storageDir.exists() && storageDir.isDirectory) {
                val volumes = storageDir.listFiles()
                if (volumes != null) {
                    for (vol in volumes) {
                        val name = vol.name
                        // Skip emulated and self
                        if (name == "emulated" || name == "self" || name.startsWith(".")) {
                            continue
                        }
                        // Check if it's a mounted SD card (UUID format like "3661-3064")
                        if (vol.isDirectory && vol.canRead() && name.contains("-")) {
                            Log.d(TAG, "Found SD card at: ${vol.absolutePath}")
                            return vol.absolutePath
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.d(TAG, "Could not scan /storage: ${e.message}")
        }
        
        // Method 2: Check known paths
        val knownPaths = arrayOf(
            "/storage/external_sd",
            "/storage/sdcard1",
            "/mnt/external_sd",
            "/mnt/sdcard/external_sd"
        )
        for (path in knownPaths) {
            val dir = File(path)
            if (dir.exists() && dir.isDirectory && dir.canRead()) {
                Log.d(TAG, "Found SD card at known path: $path")
                return path
            }
        }
        
        return null
    }
    
    /**
     * Scan all recordings directly from Disk.
     * SOTA: Scans both internal and SD card locations based on config.
     */
    fun scanRecordings(context: Context): List<RecordingFile> {
        val now = System.currentTimeMillis()
        
        // Return cache if still valid
        cachedRecordings?.let { cached ->
            if (now - cacheTimestamp < CACHE_VALIDITY_MS) {
                return cached
            }
        }
        
        // Load storage config to get active directories
        loadStorageConfig()
        
        // Scan configured directories
        val normal = scanDirectory(cachedRecordingsDir ?: File(INTERNAL_BASE_DIR, RECORDINGS_SUBDIR), RecordingFile.RecordingType.NORMAL)
        val sentry = scanDirectory(cachedSurveillanceDir ?: File(INTERNAL_BASE_DIR, SURVEILLANCE_SUBDIR), RecordingFile.RecordingType.SENTRY)
        val proximity = scanDirectory(cachedProximityDir ?: File(INTERNAL_BASE_DIR, PROXIMITY_SUBDIR), RecordingFile.RecordingType.PROXIMITY)
        
        val allFiles = (normal + sentry + proximity).sortedByDescending { it.timestamp }
        
        Log.d(TAG, "Direct Scan: Found ${allFiles.size} total videos (normal=${normal.size}, sentry=${sentry.size}, proximity=${proximity.size})")
        
        cachedRecordings = allFiles
        cacheTimestamp = now
        return allFiles
    }
    
    private fun scanDirectory(dir: File, type: RecordingFile.RecordingType): List<RecordingFile> {
        if (!dir.exists()) return emptyList()
        
        // DIRECT FILE ACCESS - The Source of Truth
        val files = dir.listFiles() ?: return emptyList()
        
        return files
            .filter { it.isFile && it.name.endsWith(".mp4") }
            .mapNotNull { file ->
                // Use RecordingFile.fromFile for proper filename parsing
                RecordingFile.fromFile(file, type)
            }
    }
    
    /**
     * Invalidate the cache (call after recording/deletion).
     */
    fun invalidateCache() {
        cachedRecordings = null
        cacheTimestamp = 0
        // Also invalidate config cache to pick up storage changes
        cachedRecordingsDir = null
        cachedSurveillanceDir = null
        cachedProximityDir = null
        configCacheTimestamp = 0
    }
    
    /**
     * Delete a recording file and its JSON sidecar (event timeline) if present.
     */
    fun deleteRecording(recording: RecordingFile): Boolean {
        val deleted = recording.file.delete()
        if (deleted) {
            // Also delete JSON sidecar (event timeline) if it exists
            val jsonFile = File(recording.file.absolutePath.replace(".mp4", ".json"))
            if (jsonFile.exists()) {
                jsonFile.delete()
            }
            invalidateCache()
        }
        return deleted
    }
    
    // ==================== Helper Methods ====================
    
    /**
     * Get the recordings directory (respects configured storage type).
     */
    fun getRecordingsDir(context: Context): File {
        loadStorageConfig()
        return cachedRecordingsDir ?: File(INTERNAL_BASE_DIR, RECORDINGS_SUBDIR)
    }
    
    /**
     * Get the sentry events directory (respects configured storage type).
     */
    fun getSentryEventsDir(context: Context): File {
        loadStorageConfig()
        return cachedSurveillanceDir ?: File(INTERNAL_BASE_DIR, SURVEILLANCE_SUBDIR)
    }
    
    /**
     * Get the proximity events directory (respects configured storage type).
     */
    fun getProximityEventsDir(context: Context): File {
        loadStorageConfig()
        return cachedProximityDir ?: File(INTERNAL_BASE_DIR, PROXIMITY_SUBDIR)
    }
    
    /**
     * Scan only normal recordings.
     */
    fun scanNormalRecordings(context: Context): List<RecordingFile> {
        return scanRecordings(context).filter { it.type == RecordingFile.RecordingType.NORMAL }
    }
    
    /**
     * Scan only sentry event recordings.
     */
    fun scanSentryRecordings(context: Context): List<RecordingFile> {
        return scanRecordings(context).filter { it.type == RecordingFile.RecordingType.SENTRY }
    }
    
    /**
     * Scan only proximity event recordings.
     */
    fun scanProximityRecordings(context: Context): List<RecordingFile> {
        return scanRecordings(context).filter { it.type == RecordingFile.RecordingType.PROXIMITY }
    }
    
    /**
     * Get recordings for a specific date.
     */
    fun getRecordingsForDate(context: Context, year: Int, month: Int, day: Int): List<RecordingFile> {
        val calendar = Calendar.getInstance().apply {
            set(year, month, day, 0, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val startOfDay = calendar.timeInMillis
        calendar.add(Calendar.DAY_OF_MONTH, 1)
        val endOfDay = calendar.timeInMillis
        
        return scanRecordings(context).filter { 
            it.timestamp in startOfDay until endOfDay 
        }
    }
    
    /**
     * Get dates that have recordings (for calendar highlighting).
     */
    fun getDatesWithRecordings(context: Context): Set<Long> {
        val calendar = Calendar.getInstance()
        return scanRecordings(context).map { recording ->
            calendar.timeInMillis = recording.timestamp
            calendar.set(Calendar.HOUR_OF_DAY, 0)
            calendar.set(Calendar.MINUTE, 0)
            calendar.set(Calendar.SECOND, 0)
            calendar.set(Calendar.MILLISECOND, 0)
            calendar.timeInMillis
        }.toSet()
    }
    
    /**
     * Get recording count per date for a specific month.
     */
    fun getRecordingCountsByDate(context: Context, year: Int, month: Int): Map<Int, Int> {
        val rangeCalendar = Calendar.getInstance().apply {
            set(year, month, 1, 0, 0, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val startOfMonth = rangeCalendar.timeInMillis
        rangeCalendar.add(Calendar.MONTH, 1)
        val endOfMonth = rangeCalendar.timeInMillis
        
        return scanRecordings(context)
            .filter { it.timestamp in startOfMonth until endOfMonth }
            .groupBy { recording ->
                val dayCalendar = Calendar.getInstance()
                dayCalendar.timeInMillis = recording.timestamp
                dayCalendar.get(Calendar.DAY_OF_MONTH)
            }
            .mapValues { it.value.size }
    }
    
    /**
     * Get total size of all recordings.
     */
    fun getTotalRecordingsSize(context: Context): Long {
        return scanRecordings(context).sumOf { it.sizeBytes }
    }
    
    /**
     * Get total size of normal recordings.
     */
    fun getNormalRecordingsSize(context: Context): Long {
        return scanNormalRecordings(context).sumOf { it.sizeBytes }
    }
    
    /**
     * Get total size of sentry recordings.
     */
    fun getSentryRecordingsSize(context: Context): Long {
        return scanSentryRecordings(context).sumOf { it.sizeBytes }
    }
    
    /**
     * Get total size of proximity recordings.
     */
    fun getProximityRecordingsSize(context: Context): Long {
        return scanProximityRecordings(context).sumOf { it.sizeBytes }
    }
}
