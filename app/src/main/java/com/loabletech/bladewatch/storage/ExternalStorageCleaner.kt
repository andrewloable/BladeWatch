package net.bladewatch.app.storage

import android.os.StatFs
import android.util.Log

import net.bladewatch.app.logging.DaemonLogger

import org.json.JSONObject

import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.util.Locale
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/**
 * ExternalStorageCleaner - Aggressive cleanup of external app recordings (BYD CDR/Dashcam)
 *
 * SOTA: Ensures BladeWatch always has reserved space on SD card by
 * cleaning up oldest files from BYD CDR (built-in dashcam) when needed.
 *
 * Features:
 * - Auto-discovery of SD card and CDR recording directories
 * - Configurable reserved space (default 2GB)
 * - Oldest-first deletion strategy
 * - Protected files (last N hours) option
 * - Minimum file retention (always keep N newest files)
 * - Detailed logging of all deletions
 * - Periodic monitoring (every 60 seconds when active)
 * - Thread-safe operations
 */
class ExternalStorageCleaner private constructor() {

    // ==================== State ====================

    // These four persist on every write: the setter clamps, then saves. Callers
    // (the Connect/REST handler, the IPC server) just assign.
    private var enabledField = false
    private var reservedSpaceMbField = DEFAULT_RESERVED_SPACE_MB
    private var protectedHoursField = DEFAULT_PROTECTED_HOURS
    private var minFilesKeepField = DEFAULT_MIN_FILES_KEEP

    var isEnabled: Boolean
        get() = enabledField
        set(value) {
            enabledField = value
            saveConfig()
            if (value) startMonitoring() else stopMonitoring()
        }

    var reservedSpaceMb: Long
        get() = reservedSpaceMbField
        set(value) {
            reservedSpaceMbField = value.coerceIn(100, 20000)
            saveConfig()
        }

    var protectedHours: Int
        get() = protectedHoursField
        set(value) {
            protectedHoursField = value.coerceIn(0, 168) // 0-7 days
            saveConfig()
        }

    var minFilesKeep: Int
        get() = minFilesKeepField
        set(value) {
            minFilesKeepField = value.coerceIn(0, 100)
            saveConfig()
        }

    var sdCardPath: String? = null
        private set

    var cdrPath: String? = null
        private set

    var isSdCardAvailable = false
        private set

    // Background monitor
    private var monitorScheduler: ScheduledExecutorService? = null
    private val monitoringActive = AtomicBoolean(false)
    private val cleanupLock = Any()

    // Statistics
    var totalBytesFreed = 0L
        private set

    var totalFilesDeleted = 0
        private set

    var lastCleanupTime = 0L
        private set

    init {
        discoverPaths()
        loadConfig()

        // Restore monitoring across daemon restarts. Without this, the user has
        // to re-toggle the UI switch after every reboot to resume background
        // OEM-dashcam cleanup, even though `enabled=true` is persisted to disk.
        if (isEnabled && isSdCardAvailable) {
            startMonitoring()
        }
    }

    // ==================== Path Discovery ====================

    /**
     * Discover SD card path and CDR recording directory.
     * SOTA: Uses sm list-volumes to find mounted SD cards.
     */
    fun discoverPaths() {
        sdCardPath = null
        cdrPath = null
        isSdCardAvailable = false

        // Method 1: Check BYD system property for SD card UUID
        val sdUuid = getSystemProperty("sys.byd.mSdcardUuid")
        val sdExists = getSystemProperty("sys.byd.isSDExist")

        if ("true".equals(sdExists, ignoreCase = true) && sdUuid.isNotEmpty()) {
            val uuidPath = "/storage/$sdUuid"
            val uuidDir = File(uuidPath)
            if (uuidDir.exists() && uuidDir.isDirectory) {
                sdCardPath = uuidPath
                logInfo("Found SD card via UUID: $sdCardPath")
            }
        }

        // Method 2: Check mounted public volumes via 'sm list-volumes'
        if (sdCardPath == null) {
            try {
                val listProcess = Runtime.getRuntime().exec(arrayOf("sm", "list-volumes", "all"))
                BufferedReader(InputStreamReader(listProcess.inputStream)).use { reader ->
                    var line = reader.readLine()
                    while (line != null) {
                        // Parse lines like: "public:8,97 mounted 3661-3064"
                        val trimmed = line.trim()
                        if (trimmed.startsWith("public:") && trimmed.contains("mounted")) {
                            val parts = trimmed.split(Regex("\\s+"))
                            if (parts.size >= 3) {
                                val mountPath = "/storage/" + parts[2] // e.g., "3661-3064"
                                val mountDir = File(mountPath)

                                if (mountDir.exists() && mountDir.isDirectory) {
                                    sdCardPath = mountPath
                                    logInfo("Found SD card via sm list-volumes: $sdCardPath")
                                    break
                                }
                            }
                        }
                        line = reader.readLine()
                    }
                }
                listProcess.waitFor()
            } catch (e: Exception) {
                logDebug("Could not check sm list-volumes: " + e.message)
            }
        }

        // Method 3: Check known paths
        if (sdCardPath == null) {
            for (path in SD_CARD_PATHS) {
                val dir = File(path)
                if (dir.exists() && dir.isDirectory && dir.canRead()) {
                    sdCardPath = path
                    logInfo("Found SD card at: $sdCardPath")
                    break
                }
            }
        }

        val sdPath = sdCardPath
        if (sdPath == null) {
            logWarn("No SD card found")
            return
        }

        isSdCardAvailable = true

        // Find CDR directory
        for (subdir in CDR_SUBDIRS) {
            val fullPath = "$sdPath/$subdir"
            val cdrDir = File(fullPath)
            if (cdrDir.exists() && cdrDir.isDirectory && containsVideoFiles(cdrDir)) {
                cdrPath = fullPath
                logInfo("Found CDR directory: $cdrPath")
                break
            }
        }

        if (cdrPath == null) {
            logInfo("No CDR directory found on SD card")
            // Try to find any directory with video files
            cdrPath = findLargestVideoDirectory(File(sdPath))
            if (cdrPath != null) {
                logInfo("Found video directory via scan: $cdrPath")
            }
        }
    }

    /**
     * Scan SD card root to find the directory with the most video files.
     * Fallback when known CDR paths don't exist.
     */
    private fun findLargestVideoDirectory(root: File?): String? {
        if (root == null || !root.exists()) return null

        val dirs = root.listFiles { f: File -> f.isDirectory } ?: return null

        var bestPath: String? = null
        var maxFiles = 0

        for (dir in dirs) {
            // Skip Android system directories
            val name = dir.name
            if (name == "Android" || name == "." || name == ".." ||
                name.startsWith(".") || name == "BladeWatch"
            ) {
                continue
            }

            val videoCount = countVideoFiles(dir)
            if (videoCount > maxFiles) {
                maxFiles = videoCount
                bestPath = dir.absolutePath
            }
        }

        // Only return if we found at least 5 video files
        return if (maxFiles >= 5) bestPath else null
    }

    /** Count video files in a directory (non-recursive, just top level). */
    private fun countVideoFiles(dir: File?): Int {
        if (dir == null || !dir.exists()) return 0
        return dir.listFiles { f: File -> f.isFile && isVideoFile(f) }?.size ?: 0
    }

    /** Get Android system property via reflection or shell. */
    private fun getSystemProperty(key: String): String {
        return try {
            // Try reflection first
            val systemProperties = Class.forName("android.os.SystemProperties")
            val get = systemProperties.getMethod("get", String::class.java, String::class.java)
            get.invoke(null, key, "") as String
        } catch (e: Exception) {
            // Fall back to shell
            try {
                val p = Runtime.getRuntime().exec(arrayOf("getprop", key))
                val line = BufferedReader(InputStreamReader(p.inputStream)).use { it.readLine() }
                p.waitFor()
                line?.trim() ?: ""
            } catch (e2: Exception) {
                ""
            }
        }
    }

    /** Check if directory contains video files. */
    private fun containsVideoFiles(dir: File?): Boolean {
        if (dir == null || !dir.exists()) return false
        val files = dir.listFiles { f: File -> f.isFile && isVideoFile(f) }
        return files != null && files.isNotEmpty()
    }

    // ==================== Configuration ====================

    /** Load configuration from config file. */
    fun loadConfig() {
        try {
            val configFile = File(CONFIG_FILE)
            if (!configFile.exists()) return

            val config = JSONObject(configFile.readText())
            val extCleanup = config.optJSONObject("externalCleanup")

            if (extCleanup != null) {
                // Assign the backing fields directly: going through the public setters here
                // would write the file straight back out (and start monitoring) while we are
                // still reading it.
                enabledField = extCleanup.optBoolean("enabled", false)
                reservedSpaceMbField =
                    extCleanup.optLong("reservedSpaceMb", DEFAULT_RESERVED_SPACE_MB)
                protectedHoursField = extCleanup.optInt("protectedHours", DEFAULT_PROTECTED_HOURS)
                minFilesKeepField = extCleanup.optInt("minFilesKeep", DEFAULT_MIN_FILES_KEEP)

                // Override discovered CDR path if configured
                val configuredCdrPath = extCleanup.optString("cdrPath", "")
                if (configuredCdrPath.isNotEmpty()) {
                    val cdrDir = File(configuredCdrPath)
                    if (cdrDir.exists() && cdrDir.isDirectory) {
                        cdrPath = configuredCdrPath
                    }
                }

                logInfo(
                    "Loaded external cleanup config: enabled=" + isEnabled +
                        ", reserved=" + reservedSpaceMb + "MB, protected=" + protectedHours + "h"
                )
            }
        } catch (e: Exception) {
            logWarn("Could not load external cleanup config: " + e.message)
        }
    }

    /** Save configuration to config file. */
    fun saveConfig() {
        try {
            val configFile = File(CONFIG_FILE)
            val config = if (configFile.exists()) {
                JSONObject(configFile.readText())
            } else {
                JSONObject().apply { put("version", 1) }
            }

            val extCleanup = config.optJSONObject("externalCleanup") ?: JSONObject()

            extCleanup.put("enabled", isEnabled)
            extCleanup.put("reservedSpaceMb", reservedSpaceMb)
            extCleanup.put("protectedHours", protectedHours)
            extCleanup.put("minFilesKeep", minFilesKeep)
            cdrPath?.let { extCleanup.put("cdrPath", it) }

            config.put("externalCleanup", extCleanup)
            config.put("lastModified", System.currentTimeMillis())

            configFile.writeText(config.toString(2))

            configFile.setReadable(true, false)
            configFile.setWritable(true, false)

            logInfo("Saved external cleanup config")
        } catch (e: Exception) {
            logError("Could not save external cleanup config: " + e.message)
        }
    }

    // ==================== Storage Stats ====================

    /** Get available space on SD card in bytes. */
    val sdCardFreeSpace: Long get() = statFs()?.availableBytes ?: 0

    /** Get total space on SD card in bytes. */
    val sdCardTotalSpace: Long get() = statFs()?.totalBytes ?: 0

    /** A StatFs on the SD card, or null when the path is unset/missing/unreadable. */
    private fun statFs(): StatFs? {
        val path = sdCardPath ?: return null
        return try {
            // Verify path exists before using StatFs
            val sdDir = File(path)
            if (!sdDir.exists() || !sdDir.isDirectory) return null
            StatFs(path)
        } catch (e: Exception) {
            logWarn("Could not stat SD card: " + e.message)
            null
        }
    }

    /** Get total size of CDR recordings in bytes. */
    val cdrUsage: Long get() {
        val path = cdrPath ?: return 0
        return getDirectorySize(File(path))
    }

    /** Get count of CDR video files. */
    val cdrFileCount: Int get() {
        if (cdrPath == null) return 0
        return getCdrVideoFiles().size
    }

    /** Get size of protected files (within protection window). */
    val protectedSize: Long get() {
        if (cdrPath == null) return 0

        val protectionCutoff = protectionCutoff()
        return getCdrVideoFiles()
            .filter { it.lastModified() > protectionCutoff }
            .sumOf { it.length() }
    }

    /** Get size of deletable files (outside protection window, excluding min keep). */
    val deletableSize: Long get() {
        if (cdrPath == null) return 0

        val files = getCdrVideoFiles()
        if (files.size <= minFilesKeep) return 0

        // Sort newest first
        val newestFirst = files.sortedByDescending { it.lastModified() }

        val protectionCutoff = protectionCutoff()

        // Skip the newest minFilesKeep files
        return newestFirst.drop(minFilesKeep)
            .filter { it.lastModified() < protectionCutoff }
            .sumOf { it.length() }
    }

    private fun protectionCutoff(): Long =
        System.currentTimeMillis() - (protectedHours * 3600L * 1000L)

    private fun getDirectorySize(dir: File?): Long {
        if (dir == null || !dir.exists()) return 0

        var size = 0L
        dir.listFiles()?.forEach { file ->
            size += if (file.isFile) file.length() else getDirectorySize(file)
        }
        return size
    }

    /** Get all CDR video files, including subdirectories. */
    private fun getCdrVideoFiles(): List<File> {
        val videoFiles = ArrayList<File>()
        val path = cdrPath ?: return videoFiles

        collectVideoFiles(File(path), videoFiles)
        return videoFiles
    }

    private fun collectVideoFiles(dir: File?, result: MutableList<File>) {
        if (dir == null || !dir.exists()) return

        // Try shell fallback for permission issues
        val files = dir.listFiles() ?: listFilesViaShell(dir)

        for (file in files) {
            if (file.isDirectory) {
                collectVideoFiles(file, result)
            } else if (isVideoFile(file)) {
                result.add(file)
            }
        }
    }

    private fun isVideoFile(file: File): Boolean {
        val name = file.name.lowercase()
        return VIDEO_EXTENSIONS.any { name.endsWith(it.lowercase()) }
    }

    private fun listFilesViaShell(dir: File): Array<File> {
        return try {
            val p = Runtime.getRuntime().exec(arrayOf("ls", "-1", dir.absolutePath))
            val files = ArrayList<File>()
            BufferedReader(InputStreamReader(p.inputStream)).use { reader ->
                var line = reader.readLine()
                while (line != null) {
                    files.add(File(dir, line.trim()))
                    line = reader.readLine()
                }
            }
            p.waitFor()
            files.toTypedArray()
        } catch (e: Exception) {
            logWarn("listFilesViaShell failed for " + dir.absolutePath + ": " + e.message)
            emptyArray()
        }
    }

    // ==================== Cleanup Logic ====================

    /** Result of a cleanup operation. */
    class CleanupResult {
        @JvmField val bytesFreed: Long
        @JvmField val filesDeleted: Int
        @JvmField val deletedFiles: List<String>
        @JvmField val error: String?

        constructor(bytesFreed: Long, filesDeleted: Int, deletedFiles: List<String>) {
            this.bytesFreed = bytesFreed
            this.filesDeleted = filesDeleted
            this.deletedFiles = deletedFiles
            this.error = null
        }

        constructor(error: String) {
            this.bytesFreed = 0
            this.filesDeleted = 0
            this.deletedFiles = ArrayList()
            this.error = error
        }

        val isSuccess: Boolean get() = error == null
    }

    /**
     * Ensure reserved space is available on SD card.
     * Deletes oldest CDR files if needed.
     *
     * @return CleanupResult with details of what was deleted
     */
    fun ensureReservedSpace(): CleanupResult {
        synchronized(cleanupLock) {
            if (!isEnabled) {
                return CleanupResult("Cleanup not enabled")
            }

            if (sdCardPath == null || cdrPath == null) {
                discoverPaths()
                if (sdCardPath == null) {
                    return CleanupResult("No SD card found")
                }
                if (cdrPath == null) {
                    return CleanupResult("No CDR directory found")
                }
            }

            val freeSpace = sdCardFreeSpace
            val reservedBytes = reservedSpaceMb * 1024L * 1024L

            if (freeSpace >= reservedBytes) {
                logDebug(
                    "SD card has sufficient space: " + formatSize(freeSpace) +
                        " free, " + formatSize(reservedBytes) + " reserved"
                )
                return CleanupResult(0, 0, ArrayList())
            }

            val toFree = reservedBytes - freeSpace
            logInfo("Need to free " + formatSize(toFree) + " on SD card")

            return performCleanup(toFree)
        }
    }

    /**
     * Force cleanup to free specified amount of space.
     *
     * Gated on the `enabled` flag. This was previously documented as
     * "ignores the enabled flag" — that turned the manual-cleanup path into a
     * footgun where any caller (UI tap, HTTP POST) could delete
     * OEM dashcam files even when the user had explicitly disabled the
     * feature in config. Honoring the flag here is the single source of
     * truth; callers should surface the rejection to the user.
     *
     * @param bytesToFree Minimum bytes to free
     * @return CleanupResult with details, or an error result if disabled
     */
    fun forceCleanup(bytesToFree: Long): CleanupResult {
        synchronized(cleanupLock) {
            if (!isEnabled) {
                return CleanupResult("External storage cleanup is disabled")
            }

            if (sdCardPath == null || cdrPath == null) {
                discoverPaths()
                if (cdrPath == null) {
                    return CleanupResult("No CDR directory found")
                }
            }

            return performCleanup(bytesToFree)
        }
    }

    /** Perform the actual cleanup operation. */
    private fun performCleanup(bytesToFree: Long): CleanupResult {
        val files = getCdrVideoFiles()

        if (files.isEmpty()) {
            return CleanupResult("No CDR files found")
        }

        // Sort oldest first
        val oldestFirst = files.sortedBy { it.lastModified() }

        // Calculate protection cutoff
        val protectionCutoff = protectionCutoff()

        // Determine how many files we must keep (newest N)
        val deletableCount = maxOf(0, oldestFirst.size - minFilesKeep)

        var freed = 0L
        var deleted = 0
        val deletedFiles = ArrayList<String>()

        var i = 0
        while (i < deletableCount && freed < bytesToFree) {
            val file = oldestFirst[i]
            i++

            // Skip protected files
            if (file.lastModified() > protectionCutoff) {
                logDebug(
                    "Skipping protected file: " + file.name + " (age: " + getFileAge(file) + ")"
                )
                continue
            }

            val fileSize = file.length()
            val fileName = file.name

            if (deleteFile(file)) {
                freed += fileSize
                deleted++
                deletedFiles.add(fileName)
                logInfo("Deleted CDR file: " + fileName + " (" + formatSize(fileSize) + ")")
            } else {
                logWarn("Failed to delete: $fileName")
            }
        }

        // Update statistics
        totalBytesFreed += freed
        totalFilesDeleted += deleted
        lastCleanupTime = System.currentTimeMillis()

        logInfo(
            "CDR cleanup complete: freed " + formatSize(freed) + " (" + deleted + " files)"
        )

        return CleanupResult(freed, deleted, deletedFiles)
    }

    /** Delete a file, trying Java API first then shell fallback. */
    private fun deleteFile(file: File): Boolean {
        // Try Java delete
        if (file.delete()) {
            return true
        }

        // Try shell rm
        return try {
            val p = Runtime.getRuntime().exec(arrayOf("rm", "-f", file.absolutePath))
            p.waitFor() == 0 && !file.exists()
        } catch (e: Exception) {
            logWarn("Shell delete failed: " + e.message)
            false
        }
    }

    private fun getFileAge(file: File): String {
        val ageMs = System.currentTimeMillis() - file.lastModified()
        val hours = ageMs / (3600 * 1000)
        return if (hours < 24) "${hours}h" else "${hours / 24}d"
    }

    // ==================== Background Monitoring ====================

    /**
     * Start periodic monitoring of SD card space.
     * Automatically triggers cleanup when space runs low.
     */
    fun startMonitoring() {
        if (!isEnabled || !isSdCardAvailable) return

        val existing = monitorScheduler
        if (existing != null && !existing.isShutdown) {
            return // Already running
        }

        monitoringActive.set(true)

        val scheduler = Executors.newSingleThreadScheduledExecutor { r ->
            Thread(r, "ExternalStorageMonitor").apply {
                isDaemon = true
                priority = Thread.MIN_PRIORITY
            }
        }
        monitorScheduler = scheduler

        scheduler.scheduleAtFixedRate(
            {
                try {
                    if (isEnabled && isSdCardAvailable) {
                        val freeSpace = sdCardFreeSpace
                        val reservedBytes = reservedSpaceMb * 1024L * 1024L

                        // Trigger cleanup at 90% of reserved threshold
                        if (freeSpace < reservedBytes * 0.9) {
                            logInfo(
                                "SD card space low (" + formatSize(freeSpace) +
                                    "), triggering cleanup"
                            )
                            ensureReservedSpace()
                        }
                    }
                } catch (e: Exception) {
                    logWarn("Monitor error: " + e.message)
                }
            },
            MONITOR_INTERVAL_SECONDS, MONITOR_INTERVAL_SECONDS, TimeUnit.SECONDS
        )

        logInfo("Started external storage monitoring (interval=${MONITOR_INTERVAL_SECONDS}s)")
    }

    /** Stop periodic monitoring. */
    fun stopMonitoring() {
        monitoringActive.set(false)

        monitorScheduler?.let { scheduler ->
            scheduler.shutdown()
            try {
                if (!scheduler.awaitTermination(5, TimeUnit.SECONDS)) {
                    scheduler.shutdownNow()
                }
            } catch (e: InterruptedException) {
                scheduler.shutdownNow()
            }
            monitorScheduler = null
            logInfo("Stopped external storage monitoring")
        }
    }

    /** Check if monitoring is active. */
    val isMonitoringActive: Boolean get() = monitoringActive.get()

    // ==================== Preview/Dry Run ====================

    /**
     * Preview what would be deleted without actually deleting.
     * Useful for UI to show user what will happen.
     *
     * @param bytesToFree Target bytes to free
     * @return List of files that would be deleted with their sizes
     */
    fun previewCleanup(bytesToFree: Long): List<FileInfo> {
        val preview = ArrayList<FileInfo>()

        if (cdrPath == null) {
            discoverPaths()
            if (cdrPath == null) return preview
        }

        val files = getCdrVideoFiles().sortedBy { it.lastModified() }

        val protectionCutoff = protectionCutoff()
        val deletableCount = maxOf(0, files.size - minFilesKeep)

        var wouldFree = 0L

        var i = 0
        while (i < deletableCount && wouldFree < bytesToFree) {
            val file = files[i]
            i++

            if (file.lastModified() > protectionCutoff) {
                continue // Would be skipped
            }

            preview.add(
                FileInfo(file.name, file.length(), file.lastModified(), file.absolutePath)
            )
            wouldFree += file.length()
        }

        return preview
    }

    /** File info for preview. */
    class FileInfo(
        @JvmField val name: String,
        @JvmField val size: Long,
        @JvmField val lastModified: Long,
        @JvmField val path: String
    )

    // ==================== Utility ====================

    /** Refresh paths (call when SD card is mounted/unmounted). */
    fun refresh() {
        discoverPaths()
        if (isEnabled && isSdCardAvailable && !monitoringActive.get()) {
            startMonitoring()
        }
    }

    /** Shutdown cleaner and release resources. */
    fun shutdown() {
        stopMonitoring()
        logInfo("ExternalStorageCleaner shutdown complete")
    }

    companion object {
        private const val TAG = "ExternalStorageCleaner"

        // Hybrid logger
        private var useDaemonLogger = false
        private var daemonLogger: DaemonLogger? = null

        @JvmStatic
        fun enableDaemonLogging() {
            useDaemonLogger = true
            daemonLogger = DaemonLogger.getInstance(TAG)
        }

        private fun logInfo(msg: String) {
            val dl = daemonLogger
            if (useDaemonLogger && dl != null) dl.info(msg) else Log.i(TAG, msg)
        }

        private fun logWarn(msg: String) {
            val dl = daemonLogger
            if (useDaemonLogger && dl != null) dl.warn(msg) else Log.w(TAG, msg)
        }

        private fun logError(msg: String) {
            val dl = daemonLogger
            if (useDaemonLogger && dl != null) dl.error(msg) else Log.e(TAG, msg)
        }

        private fun logDebug(msg: String) {
            val dl = daemonLogger
            if (useDaemonLogger && dl != null) dl.debug(msg) else Log.d(TAG, msg)
        }

        // ==================== Constants ====================

        /** Known SD card mount paths */
        private val SD_CARD_PATHS = arrayOf(
            "/storage/external_sd",
            "/storage/sdcard1",
            "/mnt/external_sd",
            "/mnt/sdcard/external_sd"
        )

        /** Known BYD CDR (dashcam) recording directories */
        private val CDR_SUBDIRS = arrayOf(
            "Recorder/Normal", // BYD built-in dashcam - normal recordings
            "Recorder", // BYD built-in dashcam - root
            "Recorder/Video",
            "DCIM",
            "DCIM/Camera",
            "DCIM/100MEDIA",
            "DVR",
            "CDR",
            "行车记录仪",
            "Video",
            "Video/DVR",
            "Movies",
            "Movies/DVR",
            "Record",
            "CarRecord",
            "DashCam",
            "Camera"
        )

        /** Video file extensions to clean */
        private val VIDEO_EXTENSIONS = arrayOf(
            ".mp4", ".MP4", ".avi", ".AVI", ".ts", ".TS", ".mov", ".MOV"
        )

        /** Config file location (shared with StorageManager) */
        private const val CONFIG_FILE = "/data/local/tmp/bladewatch_config.json"

        // Default configuration
        /** 2GB */
        private const val DEFAULT_RESERVED_SPACE_MB = 2048L

        /** 24 hours */
        private const val DEFAULT_PROTECTED_HOURS = 24

        /** Always keep 10 newest */
        private const val DEFAULT_MIN_FILES_KEEP = 10

        /** Check every minute */
        private const val MONITOR_INTERVAL_SECONDS = 60L

        // Singleton
        private var instance: ExternalStorageCleaner? = null

        @JvmStatic
        @Synchronized
        fun getInstance(): ExternalStorageCleaner =
            instance ?: ExternalStorageCleaner().also { instance = it }

        @JvmStatic
        fun formatSize(bytes: Long): String = when {
            bytes >= 1_000_000_000 ->
                String.format(Locale.US, "%.1f GB", bytes / 1_000_000_000.0)
            bytes >= 1_000_000 -> String.format(Locale.US, "%.1f MB", bytes / 1_000_000.0)
            bytes >= 1_000 -> String.format(Locale.US, "%.1f KB", bytes / 1_000.0)
            else -> "$bytes B"
        }
    }
}
