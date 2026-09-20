package net.bladewatch.app.storage

import android.os.StatFs
import android.util.Log

import net.bladewatch.app.logging.DaemonLogger

import org.json.JSONObject

import java.io.BufferedReader
import java.io.File
import java.io.FileWriter
import java.io.InputStreamReader
import java.util.Locale
import java.util.Scanner
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean
import java.util.function.BooleanSupplier
import java.util.function.Function

/**
 * StorageManager - SOTA Storage Management for BladeWatch
 *
 * Manages recording and surveillance storage with:
 * - Dedicated directories under /storage/emulated/0/BladeWatch/ (internal) or SD card
 * - Storage type selection: INTERNAL or SD_CARD for both recordings and surveillance
 * - Configurable size limits (100MB - 10000MB for SD card)
 * - Automatic cleanup of oldest files when limit is reached
 * - Event-driven cleanup (after each file save)
 * - Periodic background cleanup during long recordings
 * - Thread-safe operations
 * - SD card detection and availability monitoring
 *
 * SOTA Cleanup Strategy:
 * 1. Pre-recording check - Reserve space before starting
 * 2. Post-file cleanup - Run after each file is closed/saved
 * 3. Periodic cleanup - Background task every 30 seconds during active recording
 *
 * Storage Selection:
 * - Each storage type (recordings, surveillance) can independently use internal or SD card
 * - SD card paths are auto-discovered via BYD system properties or known mount points
 * - Graceful fallback to internal storage if SD card becomes unavailable
 */
class StorageManager private constructor() {

    // Storage type enum
    enum class StorageType {
        INTERNAL,
        SD_CARD
    }

    // Current limits. Custom setters (not plain field assignment) because setting a limit
    // clamps to the physical-disk ceiling and persists — exactly what the Java setXxxLimitMb
    // methods did; Kotlin callers use assignment syntax (`storage.recordingsLimitMb = x`) so
    // the clamp+save behavior has to live in the setter itself, not a separate function (which
    // would collide with the property's own generated setXxxLimitMb JVM method). Backed by a
    // private field so loadConfig() can assign the already-clamped-there value directly,
    // without re-triggering a clamp + saveConfig() during construction.
    private var recordingsLimitMbValue: Long = DEFAULT_RECORDINGS_LIMIT_MB
    var recordingsLimitMb: Long
        get() = recordingsLimitMbValue
        set(value) {
            recordingsLimitMbValue = clampLimitMb(value, physicalDiskMaxMb(recordingsStorageType))
            saveConfig()
        }

    private var surveillanceLimitMbValue: Long = DEFAULT_SURVEILLANCE_LIMIT_MB
    var surveillanceLimitMb: Long
        get() = surveillanceLimitMbValue
        set(value) {
            surveillanceLimitMbValue = clampLimitMb(value, physicalDiskMaxMb(surveillanceStorageType))
            saveConfig()
        }

    private var proximityLimitMbValue: Long = DEFAULT_PROXIMITY_LIMIT_MB
    var proximityLimitMb: Long
        get() = proximityLimitMbValue
        set(value) {
            proximityLimitMbValue = Math.max(MIN_LIMIT_MB, Math.min(physicalDiskMaxMb(surveillanceStorageType), value))
            saveConfig()
        }

    private var tripsLimitMbValue: Long = DEFAULT_TRIPS_LIMIT_MB
    var tripsLimitMb: Long
        get() = tripsLimitMbValue
        set(value) {
            tripsLimitMbValue = Math.max(MIN_LIMIT_MB, Math.min(physicalDiskMaxMb(tripsStorageType), value))
            saveConfig()
        }

    // Storage type selection (SOTA: independent selection for recordings and surveillance)
    var recordingsStorageType: StorageType = StorageType.INTERNAL
        private set
    var surveillanceStorageType: StorageType = StorageType.INTERNAL
        private set
    var tripsStorageType: StorageType = StorageType.INTERNAL
        private set

    // SD card state
    var sdCardPath: String? = null
        private set
    private var sdCardAvailable = false

    /** Whether an SD (or USB, reusing the SD machinery) card is currently mounted and in use. */
    val isSdCardAvailable: Boolean
        get() = sdCardAvailable

    // Internal storage directories (always available)
    var internalRecordingsDir: File? = null
        private set
    var internalSurveillanceDir: File? = null
        private set
    var internalProximityDir: File? = null
        private set
    var internalTripsDir: File? = null
        private set

    // SD card directories (may be null if SD card not available)
    var sdCardRecordingsDir: File? = null
        private set
    var sdCardSurveillanceDir: File? = null
        private set
    var sdCardProximityDir: File? = null
        private set
    var sdCardTripsDir: File? = null
        private set

    // Active directories (based on storage type selection)
    lateinit var recordingsDir: File
        private set
    lateinit var surveillanceDir: File
        private set
    lateinit var proximityDir: File
        private set
    lateinit var tripsDir: File
        private set

    // Background cleanup scheduler
    private var cleanupScheduler: ScheduledExecutorService? = null
    private val recordingActive = AtomicBoolean(false)
    private val surveillanceActive = AtomicBoolean(false)

    /**
     * Whether recording is active. Periodic cleanup runs continuously regardless (started at
     * daemon boot via [startPeriodicCleanup]); this flag is kept for callers that consult it.
     */
    val isRecordingActive: Boolean
        get() = recordingActive.get()

    /** Whether surveillance is active. See [isRecordingActive] for periodic-cleanup lifetime semantics. */
    val isSurveillanceActive: Boolean
        get() = surveillanceActive.get()

    // Async cleanup executor (single thread to avoid concurrent cleanup)
    private val asyncCleanupExecutor = Executors.newSingleThreadExecutor { r ->
        val t = Thread(r, "StorageCleanupAsync")
        t.isDaemon = true
        t.priority = Thread.MIN_PRIORITY  // Low priority to not interfere with recording
        t
    }

    // Cleanup lock to prevent concurrent cleanup operations
    private val cleanupLock = Any()

    // SD card mount watchdog (keeps SD card mounted during sentry mode)
    private var sdCardWatchdog: ScheduledExecutorService? = null
    private var sdWatchdogConsecutiveFailures = 0

    /** True when [applyAutoStoragePriority] could not mount an already-configured SD card
     * after [SD_CARD_BOOT_MOUNT_ATTEMPTS] tries at boot. Cleared once the SD watchdog remounts
     * the card, or on the next successful boot-time mount. */
    @Volatile
    var isSdCardMountFailedAtBoot: Boolean = false
        private set

    /** User-facing explanation for [isSdCardMountFailedAtBoot], or null if there is no active
     * failure. */
    @Volatile
    var sdCardMountErrorMessage: String? = null
        private set

    init {
        if (!tryLoadSdCardFromCache()) {
            discoverSdCard()
        }
        initDirectories()
        loadConfig()

        // SOTA: If config says SD card but it's not available, try to mount it
        // This happens when daemon starts and SD card is unmounted
        if (!sdCardAvailable &&
            (surveillanceStorageType == StorageType.SD_CARD ||
                recordingsStorageType == StorageType.SD_CARD ||
                tripsStorageType == StorageType.SD_CARD)
        ) {
            logInfo("SD card configured but not available - attempting mount...")
            ensureSdCardMounted(true)
        }

        updateActiveDirectories()

        // One-shot startup reap. If the user lowered the limit, switched
        // storage type, or upgraded from a legacy build, the inactive +
        // legacy locations may be holding orphan files that count toward
        // the limit. Reap them once at boot so the UI total agrees with
        // the configured limit before any new event fires the per-save
        // cleanup. Async — don't block daemon startup.
        asyncCleanupExecutor.execute {
            synchronized(cleanupLock) {
                try {
                    ensureRecordingsSpace(0)
                    ensureSurveillanceSpace(0)
                    ensureProximitySpace(0)
                    ensureTripsSpace(0)
                } catch (e: Exception) {
                    logWarn("Startup reap failed: " + e.message)
                }
            }
        }
    }

    // ==================== SD Card Discovery ====================

    /**
     * SOTA: Mount SD card, optionally forcing a remount.
     * Uses Android's StorageManager (sm) command to mount public volumes.
     *
     * @param force If true, always attempt to mount even if already mounted
     * @return true if SD card is now mounted, false otherwise
     */
    @JvmOverloads
    fun ensureSdCardMounted(force: Boolean = false): Boolean {
        // Quick check: if path is already accessible, no work needed
        if (sdCardAvailable && sdCardPath != null) {
            val sdDir = File(sdCardPath!!)
            if (sdDir.exists() && sdDir.canWrite()) {
                logDebug("SD card already mounted at: $sdCardPath")
                return true
            }
        }

        logDebug("Mounting SD card...")

        try {
            // Step 1: Find the Volume ID using 'sm list-volumes all'
            val listProcess = Runtime.getRuntime().exec(arrayOf("sm", "list-volumes", "all"))
            val reader = BufferedReader(InputStreamReader(listProcess.inputStream))
            var line: String?
            var volumeId: String? = null      // e.g., "public:8,97"
            var volumeUuid: String? = null    // e.g., "3661-3064"

            while (reader.readLine().also { line = it } != null) {
                // Parse lines like: "public:8,97 unmounted 3661-3064" or "public:8,97 mounted 3661-3064"
                val trimmed = line!!.trim()
                logDebug("sm list-volumes: $trimmed")

                if (trimmed.startsWith("public:")) {
                    val parts = trimmed.split(Regex("\\s+"))
                    if (parts.size >= 3) {
                        volumeId = parts[0]           // e.g., "public:8,97"
                        val state = parts[1]          // e.g., "unmounted" or "mounted"
                        volumeUuid = parts[2]          // e.g., "3661-3064"

                        // If already mounted, verify with a shell write probe.
                        // File.canWrite() is unreliable on sdcardfs: returns false even
                        // when the shell UID has write access via the sdcard_rw group.
                        if ("mounted" == state) {
                            val mountPath = "/storage/$volumeUuid"
                            if (shellCanWrite(mountPath)) {
                                sdCardPath = mountPath
                                sdCardAvailable = true
                                logInfo("SD card already mounted at: $sdCardPath")
                                reader.close()
                                listProcess.waitFor()
                                initSdCardDirectories()
                                updateActiveDirectories()
                                return true
                            }
                            // Probe failed — stale mount, will force remount below.
                            logWarn("SD card volume $volumeId probe failed at $mountPath — will force remount")
                        }

                        break  // Found the public volume
                    }
                }
            }
            reader.close()
            listProcess.waitFor()

            // Step 2: Always attempt mount if we found a volume
            // sm mount is safe to call even if already mounted (no-op if healthy)
            // For stale mounts, this forces the system to re-establish the FUSE path
            if (volumeId != null) {
                val mountProcess = Runtime.getRuntime().exec(arrayOf("sm", "mount", volumeId))

                // Capture output for debugging
                val outReader = BufferedReader(InputStreamReader(mountProcess.inputStream))
                val errReader = BufferedReader(InputStreamReader(mountProcess.errorStream))
                val output = StringBuilder()
                var outLine: String?
                while (outReader.readLine().also { outLine = it } != null) {
                    output.append(outLine).append("\n")
                }
                while (errReader.readLine().also { outLine = it } != null) {
                    output.append("ERR: ").append(outLine).append("\n")
                }
                outReader.close()
                errReader.close()

                val exitCode = mountProcess.waitFor()
                logInfo(
                    "sm mount exit code: " + exitCode +
                        (if (output.isNotEmpty()) ", output: " + output.toString().trim() else "")
                )

                if (exitCode == 0 && volumeUuid != null) {
                    val mountPath = "/storage/$volumeUuid"
                    // Wait up to 3 s for the sdcardfs layer to become writable (1 s steps).
                    for (i in 0 until 3) {
                        Thread.sleep(1000)
                        if (shellCanWrite(mountPath)) {
                            sdCardPath = mountPath
                            sdCardAvailable = true
                            logInfo("SD card mounted successfully at: $sdCardPath")
                            initSdCardDirectories()
                            updateActiveDirectories()
                            return true
                        }
                        logDebug("Waiting for mount probe... attempt " + (i + 1) + "/3")
                    }
                    logWarn("SD card mount path not accessible after mount: $mountPath")
                } else {
                    logWarn("sm mount command failed with exit code: $exitCode")
                }
            } else {
                logDebug("No public SD card volume found")
            }
        } catch (e: Exception) {
            logError("Error mounting SD card: " + e.message)
        }

        // Re-run discovery in case mount succeeded but we missed it
        discoverSdCard()
        return sdCardAvailable
    }

    /**
     * Check if SD card is currently mounted (without attempting to mount).
     * Simply checks if the path exists and is writable.
     *
     * @return true if SD card is mounted
     */
    fun isSdCardMounted(): Boolean {
        val path = sdCardPath ?: return false
        return shellCanWrite(path)
    }

    /**
     * Ensure SD card is ready for use.
     * If SD card storage is selected but not mounted, attempts to mount it.
     * If mount fails, falls back to internal storage.
     *
     * @param forSurveillance true if checking for surveillance, false for recordings
     * @return true if storage is ready (either SD card mounted or fallback to internal)
     */
    fun ensureStorageReady(forSurveillance: Boolean): Boolean {
        val selectedType = if (forSurveillance) surveillanceStorageType else recordingsStorageType

        if (selectedType == StorageType.INTERNAL) {
            // Internal storage is always ready
            return true
        }

        // CRITICAL: Don't switch storage location while recording is active
        // This prevents files from being split across SD card and internal storage
        if (!forSurveillance && recordingActive.get()) {
            logDebug("Recording active - not switching storage location")
            return true
        }
        if (forSurveillance && surveillanceActive.get()) {
            logDebug("Surveillance active - not switching storage location")
            return true
        }

        // SD card selected - ensure it's mounted
        if (!isSdCardMounted()) {
            logInfo("SD card not mounted, attempting to mount for " + (if (forSurveillance) "surveillance" else "recordings"))

            if (!ensureSdCardMounted()) {
                logWarn("Failed to mount SD card, falling back to internal storage")

                // Temporary fallback: point active directory to internal storage
                // but do NOT change the storage type preference — user still wants SD card.
                // When SD card comes back (watchdog remount or next ensureStorageReady call),
                // updateActiveDirectories() will restore the SD card path.
                if (forSurveillance) {
                    surveillanceDir = internalSurveillanceDir!!
                    proximityDir = internalProximityDir!!
                } else {
                    recordingsDir = internalRecordingsDir!!
                }

                return true  // Internal storage is ready
            }
        }

        // SD card is mounted, ensure directories exist
        initSdCardDirectories()
        updateActiveDirectories()

        // Pre-reserve space on SD card by cleaning BYD dashcam files if needed
        try {
            val cleaner = ExternalStorageCleaner.getInstance()
            if (cleaner.isEnabled && cleaner.isSdCardAvailable) {
                cleaner.ensureReservedSpace()
            }
        } catch (e: Exception) {
            logWarn("Pre-recording CDR cleanup failed: " + e.message)
        }

        return true
    }

    /**
     * Discover SD card path. Only considers /storage/<uuid> paths (the canonical
     * vold mount points). Never falls back to /mnt/sdcard or similar symlinks,
     * which may resolve to internal storage and return wrong StatFs sizes.
     *
     * Java's `File.canWrite()` is unreliable on sdcardfs mounts (returns
     * false even when the shell UID has group write access via sdcard_rw). We use
     * a shell `touch` probe instead, with up to 3 attempts separated by 1 s
     * each before giving up.
     */
    fun discoverSdCard() {
        sdCardPath = null
        sdCardAvailable = false

        // Collect candidate /storage/<uuid> paths from sm list-volumes and /storage scan.
        val candidates = ArrayList<String>()

        // Source 1: sm list-volumes all — most reliable, gives us the exact UUID.
        try {
            val p = Runtime.getRuntime().exec(arrayOf("sm", "list-volumes", "all"))
            val r = BufferedReader(InputStreamReader(p.inputStream))
            var line: String?
            while (r.readLine().also { line = it } != null) {
                val trimmed = line!!.trim()
                if (trimmed.startsWith("public:") && trimmed.contains("mounted")) {
                    val parts = trimmed.split(Regex("\\s+"))
                    if (parts.size >= 3) {
                        val uuid = parts[2]
                        if (uuid != "null" && uuid.isNotEmpty()) {
                            candidates.add("/storage/$uuid")
                        }
                    }
                }
            }
            r.close()
            p.waitFor()
        } catch (e: Exception) {
            logDebug("sm list-volumes failed: " + e.message)
        }

        // Source 2: scan /storage/ for UUID-style directories, skipping symlinks and known non-SD names.
        try {
            val entries = File("/storage").listFiles()
            if (entries != null) {
                for (f in entries) {
                    val name = f.name
                    if (name == "emulated" || name == "self" || name == "sdcard" || name.startsWith(".")) {
                        continue
                    }
                    // Only plain directories (not symlinks) to avoid /storage/sdcard -> E3B7-10F2 duplicates.
                    val absPath = f.absolutePath
                    if (f.isDirectory && !candidates.contains(absPath)) {
                        candidates.add(absPath)
                    }
                }
            }
        } catch (e: Exception) {
            logDebug("Could not scan /storage: " + e.message)
        }

        // Probe each candidate with a shell write test (3 attempts, 1 s apart).
        for (candidate in candidates) {
            for (attempt in 1..3) {
                try {
                    val dir = File(candidate)
                    if (!dir.exists() || !dir.isDirectory) {
                        break // path doesn't exist yet — no point retrying
                    }
                    val p = Runtime.getRuntime().exec(
                        arrayOf(
                            "sh", "-c",
                            "touch $candidate/.bladewatch_probe && rm $candidate/.bladewatch_probe"
                        )
                    )
                    val exit = p.waitFor()
                    if (exit == 0) {
                        sdCardPath = candidate
                        sdCardAvailable = true
                        writeSdCardCache(candidate)
                        logInfo("Found SD card (attempt $attempt): $sdCardPath")
                        return
                    }
                    logDebug("SD probe failed on $candidate (attempt $attempt/3, exit=$exit)")
                    if (attempt < 3) Thread.sleep(1000)
                } catch (e: Exception) {
                    logDebug("SD probe error on $candidate attempt $attempt: " + e.message)
                    try {
                        if (attempt < 3) Thread.sleep(1000)
                    } catch (ie: InterruptedException) {
                        Thread.currentThread().interrupt()
                        return
                    }
                }
            }
        }

        logDebug("No writable SD card found under /storage/")
    }

    /**
     * Reads the SD card path cache and validates it with a write probe.
     * Returns true and sets sdCardPath/sdCardAvailable if the cached path is still valid.
     * Deletes the cache file and returns false if validation fails.
     */
    private fun tryLoadSdCardFromCache(): Boolean {
        try {
            val cacheFile = File(SD_CARD_CACHE_PATH)
            if (!cacheFile.exists()) return false
            val cachedPath = Scanner(cacheFile).useDelimiter("\\A").next().trim()
            if (cachedPath.isEmpty()) return false
            if (!shellCanWrite(cachedPath)) {
                logDebug("Cached SD path not writable, falling back to full discovery: $cachedPath")
                cacheFile.delete()
                return false
            }
            sdCardPath = cachedPath
            sdCardAvailable = true
            logInfo("SD card path loaded from cache: $cachedPath")
            return true
        } catch (e: Exception) {
            logDebug("SD card cache read failed: " + e.message)
            return false
        }
    }

    /**
     * Writes the discovered SD card path to the cache file using an atomic temp+rename.
     */
    private fun writeSdCardCache(path: String) {
        try {
            val tmpFile = File("$SD_CARD_CACHE_PATH.tmp")
            val fw = FileWriter(tmpFile, false)
            fw.write(path)
            fw.close()
            tmpFile.renameTo(File(SD_CARD_CACHE_PATH))
        } catch (e: Exception) {
            logDebug("SD card cache write failed: " + e.message)
        }
    }

    /**
     * Returns true if the shell UID can write to `dirPath`.
     * Uses a `touch`/`rm` probe via sh because `File.canWrite()`
     * is unreliable on sdcardfs mounts (may return false despite sdcard_rw group access).
     */
    private fun shellCanWrite(dirPath: String): Boolean {
        try {
            val dir = File(dirPath)
            if (!dir.exists() || !dir.isDirectory) return false
            val p = Runtime.getRuntime().exec(
                arrayOf("sh", "-c", "touch $dirPath/.bladewatch_probe && rm $dirPath/.bladewatch_probe")
            )
            return p.waitFor() == 0
        } catch (e: Exception) {
            return false
        }
    }

    /**
     * Initialize storage directories.
     * IMPORTANT: Sets world-readable permissions so the UI app can access recordings.
     */
    private fun initDirectories() {
        // Initialize internal storage directories (always available)
        val internalBaseDir = File(INTERNAL_BASE_DIR)
        if (!internalBaseDir.exists()) {
            val created = internalBaseDir.mkdirs()
            logInfo("Created internal base directory: $INTERNAL_BASE_DIR (success=$created)")
        }
        internalBaseDir.setReadable(true, false)
        internalBaseDir.setExecutable(true, false)

        val recDir = File(internalBaseDir, RECORDINGS_SUBDIR)
        internalRecordingsDir = recDir
        if (!recDir.exists()) {
            val created = recDir.mkdirs()
            logInfo("Created internal recordings directory: " + recDir.absolutePath + " (success=" + created + ")")
        }
        recDir.setReadable(true, false)
        recDir.setExecutable(true, false)

        val survDir = File(internalBaseDir, SURVEILLANCE_SUBDIR)
        internalSurveillanceDir = survDir
        if (!survDir.exists()) {
            val created = survDir.mkdirs()
            logInfo("Created internal surveillance directory: " + survDir.absolutePath + " (success=" + created + ")")
        }
        survDir.setReadable(true, false)
        survDir.setExecutable(true, false)

        val proxDir = File(internalBaseDir, PROXIMITY_SUBDIR)
        internalProximityDir = proxDir
        if (!proxDir.exists()) {
            val created = proxDir.mkdirs()
            logInfo("Created internal proximity directory: " + proxDir.absolutePath + " (success=" + created + ")")
        }
        proxDir.setReadable(true, false)
        proxDir.setExecutable(true, false)

        val tripsD = File(internalBaseDir, TRIPS_SUBDIR)
        internalTripsDir = tripsD
        if (!tripsD.exists()) {
            val created = tripsD.mkdirs()
            logInfo("Created internal trips directory: " + tripsD.absolutePath + " (success=" + created + ")")
        }
        tripsD.setReadable(true, false)
        tripsD.setExecutable(true, false)

        // Initialize SD card directories if available
        initSdCardDirectories()
    }

    /**
     * Initialize SD card directories if SD card is available.
     */
    private fun initSdCardDirectories() {
        if (!sdCardAvailable || sdCardPath == null) {
            sdCardRecordingsDir = null
            sdCardSurveillanceDir = null
            sdCardProximityDir = null
            sdCardTripsDir = null
            return
        }

        val sdBaseDir = File(sdCardPath, "BladeWatch")

        // Always try to create directories (mkdirs is idempotent)
        // This handles the case where SD card was remounted
        val baseCreated = sdBaseDir.mkdirs()
        if (!sdBaseDir.exists()) {
            logError("Failed to create SD card base directory: " + sdBaseDir.absolutePath)
            return
        }
        if (baseCreated) {
            logInfo("Created SD card base directory: " + sdBaseDir.absolutePath)
        }
        sdBaseDir.setReadable(true, false)
        sdBaseDir.setWritable(true, false)
        sdBaseDir.setExecutable(true, false)

        val recDir = File(sdBaseDir, RECORDINGS_SUBDIR)
        sdCardRecordingsDir = recDir
        val recCreated = recDir.mkdirs()
        if (!recDir.exists()) {
            logError("Failed to create SD card recordings directory: " + recDir.absolutePath)
        } else {
            if (recCreated) {
                logInfo("Created SD card recordings directory: " + recDir.absolutePath)
            }
            recDir.setReadable(true, false)
            recDir.setWritable(true, false)
            recDir.setExecutable(true, false)
        }

        val survDir = File(sdBaseDir, SURVEILLANCE_SUBDIR)
        sdCardSurveillanceDir = survDir
        val survCreated = survDir.mkdirs()
        if (!survDir.exists()) {
            logError("Failed to create SD card surveillance directory: " + survDir.absolutePath)
        } else {
            if (survCreated) {
                logInfo("Created SD card surveillance directory: " + survDir.absolutePath)
            }
            survDir.setReadable(true, false)
            survDir.setWritable(true, false)
            survDir.setExecutable(true, false)
        }

        val proxDir = File(sdBaseDir, PROXIMITY_SUBDIR)
        sdCardProximityDir = proxDir
        val proxCreated = proxDir.mkdirs()
        if (!proxDir.exists()) {
            logError("Failed to create SD card proximity directory: " + proxDir.absolutePath)
        } else {
            if (proxCreated) {
                logInfo("Created SD card proximity directory: " + proxDir.absolutePath)
            }
            proxDir.setReadable(true, false)
            proxDir.setWritable(true, false)
            proxDir.setExecutable(true, false)
        }

        val tripsD = File(sdBaseDir, TRIPS_SUBDIR)
        sdCardTripsDir = tripsD
        val tripsCreated = tripsD.mkdirs()
        if (!tripsD.exists()) {
            logError("Failed to create SD card trips directory: " + tripsD.absolutePath)
        } else {
            if (tripsCreated) {
                logInfo("Created SD card trips directory: " + tripsD.absolutePath)
            }
            tripsD.setReadable(true, false)
            tripsD.setWritable(true, false)
            tripsD.setExecutable(true, false)
        }

        // Verify directories are actually writable
        val sd = sdCardSurveillanceDir
        if (sd != null && sd.exists()) {
            if (!sd.canWrite()) {
                logError("SD card surveillance directory exists but is not writable: " + sd.absolutePath)
            } else {
                logInfo("SD card surveillance directory verified writable: " + sd.absolutePath)
            }
        }
    }

    /**
     * Update active directories based on storage type selection.
     * Falls back to internal storage if SD card is not available.
     */
    private fun updateActiveDirectories() {
        // Recordings directory
        // CRITICAL: Don't switch while recording is active to prevent split files
        if (recordingActive.get()) {
            logDebug("Recording active - skipping recordings directory update")
        } else if (recordingsStorageType == StorageType.SD_CARD && sdCardAvailable && sdCardRecordingsDir != null) {
            recordingsDir = sdCardRecordingsDir!!
            logInfo("Recordings using SD card: " + recordingsDir.absolutePath)
        } else {
            recordingsDir = internalRecordingsDir!!
            if (recordingsStorageType == StorageType.SD_CARD) {
                logWarn("SD card not available for recordings, falling back to internal storage")
            }
        }

        // Surveillance directory
        // CRITICAL: Don't switch while surveillance is active to prevent split files
        if (surveillanceActive.get()) {
            logDebug("Surveillance active - skipping surveillance directory update")
        } else if (surveillanceStorageType == StorageType.SD_CARD && sdCardAvailable && sdCardSurveillanceDir != null) {
            surveillanceDir = sdCardSurveillanceDir!!
            logInfo("Surveillance using SD card: " + surveillanceDir.absolutePath)
        } else {
            surveillanceDir = internalSurveillanceDir!!
            if (surveillanceStorageType == StorageType.SD_CARD) {
                logWarn("SD card not available for surveillance, falling back to internal storage")
            }
        }

        // Proximity always uses same storage as surveillance
        if (!surveillanceActive.get()) {
            proximityDir = if (surveillanceStorageType == StorageType.SD_CARD && sdCardAvailable && sdCardProximityDir != null) {
                sdCardProximityDir!!
            } else {
                internalProximityDir!!
            }
        }

        // Trips directory
        // Trip telemetry files are small — no recording-active check needed
        if (tripsStorageType == StorageType.SD_CARD && sdCardAvailable && sdCardTripsDir != null) {
            tripsDir = sdCardTripsDir!!
            logInfo("Trips using SD card: " + tripsDir.absolutePath)
        } else {
            tripsDir = internalTripsDir!!
            if (tripsStorageType == StorageType.SD_CARD) {
                logWarn("SD card not available for trips, falling back to internal storage")
            }
        }
    }

    /**
     * Load storage limits and storage type from config.
     *
     * Reads via UnifiedConfigManager so the storage section lives in its
     * cachedConfig and is preserved on every subsequent UnifiedConfigManager
     * save. Previously this read /data/local/tmp/bladewatch_config.json
     * directly, but UnifiedConfigManager.mirrorLegacyConfig() was silently
     * overwriting that file (from its own storage-section-free cachedConfig)
     * on any unrelated settings change, causing the SD card preference to
     * revert to INTERNAL after each daemon restart.
     */
    private fun loadConfig() {
        try {
            val storage = net.bladewatch.app.config.UnifiedConfigManager.loadConfig().optJSONObject("storage")
            if (storage != null) {
                recordingsLimitMbValue = storage.optLong("recordingsLimitMb", DEFAULT_RECORDINGS_LIMIT_MB)
                surveillanceLimitMbValue = storage.optLong("surveillanceLimitMb", DEFAULT_SURVEILLANCE_LIMIT_MB)
                proximityLimitMbValue = storage.optLong("proximityLimitMb", DEFAULT_PROXIMITY_LIMIT_MB)
                tripsLimitMbValue = storage.optLong("tripsLimitMb", DEFAULT_TRIPS_LIMIT_MB)

                val recStorageType = storage.optString("recordingsStorageType", "INTERNAL")
                val survStorageType = storage.optString("surveillanceStorageType", "INTERNAL")
                val tripsStorageTypeStr = storage.optString("tripsStorageType", "INTERNAL")

                recordingsStorageType = if ("SD_CARD" == recStorageType) StorageType.SD_CARD else StorageType.INTERNAL
                surveillanceStorageType = if ("SD_CARD" == survStorageType) StorageType.SD_CARD else StorageType.INTERNAL
                tripsStorageType = if ("SD_CARD" == tripsStorageTypeStr) StorageType.SD_CARD else StorageType.INTERNAL

                // Clamp to valid range — use physical disk size where known, fall back to hard ceiling
                val sdDiskMb = sdCardTotalSpace / (1024L * 1024L)
                val intDiskMb = internalTotalSpace / (1024L * 1024L)
                val sdMax = if (sdDiskMb > MIN_LIMIT_MB) sdDiskMb else MAX_LIMIT_MB_SD_CARD
                val intMax = if (intDiskMb > MIN_LIMIT_MB) intDiskMb else MAX_LIMIT_MB_INTERNAL
                val maxRecLimit = if (recordingsStorageType == StorageType.SD_CARD) sdMax else intMax
                val maxSurvLimit = if (surveillanceStorageType == StorageType.SD_CARD) sdMax else intMax
                val maxTripsLimit = if (tripsStorageType == StorageType.SD_CARD) sdMax else intMax

                recordingsLimitMbValue = Math.max(MIN_LIMIT_MB, Math.min(maxRecLimit, recordingsLimitMbValue))
                surveillanceLimitMbValue = Math.max(MIN_LIMIT_MB, Math.min(maxSurvLimit, surveillanceLimitMbValue))
                proximityLimitMbValue = Math.max(MIN_LIMIT_MB, Math.min(maxSurvLimit, proximityLimitMbValue))
                tripsLimitMbValue = Math.max(MIN_LIMIT_MB, Math.min(maxTripsLimit, tripsLimitMbValue))

                logInfo(
                    "Loaded storage config: recordings=" + recordingsLimitMb + "MB (" + recordingsStorageType +
                        "), surveillance=" + surveillanceLimitMb + "MB (" + surveillanceStorageType +
                        "), trips=" + tripsLimitMb + "MB (" + tripsStorageType + ")"
                )
            }
        } catch (e: Exception) {
            logWarn("Could not load storage config: " + e.message)
        }
    }

    /**
     * Save storage limits and storage type via UnifiedConfigManager.
     *
     * Writing through UnifiedConfigManager ensures the storage section is
     * part of its cachedConfig, so subsequent mirror writes (triggered by
     * any other settings change) carry the storage section instead of
     * silently overwriting it with a storage-section-free snapshot.
     */
    fun saveConfig() {
        try {
            val storage = JSONObject()
            storage.put("recordingsLimitMb", recordingsLimitMb)
            storage.put("surveillanceLimitMb", surveillanceLimitMb)
            storage.put("proximityLimitMb", proximityLimitMb)
            storage.put("tripsLimitMb", tripsLimitMb)
            storage.put("recordingsStorageType", recordingsStorageType.name)
            storage.put("surveillanceStorageType", surveillanceStorageType.name)
            storage.put("tripsStorageType", tripsStorageType.name)

            net.bladewatch.app.config.UnifiedConfigManager.updateSection("storage", storage)

            logInfo(
                "Saved storage config: recordings=" + recordingsLimitMb + "MB (" + recordingsStorageType +
                    "), surveillance=" + surveillanceLimitMb + "MB (" + surveillanceStorageType +
                    "), trips=" + tripsLimitMb + "MB (" + tripsStorageType + ")"
            )
        } catch (e: Exception) {
            logError("Could not save storage config: " + e.message)
        }
    }

    // ==================== Auto Storage Priority ====================

    /**
     * Applies the storage priority on daemon startup: SD card → USB → internal.
     *
     * Runs unconditionally so that inserting or removing a drive between boots is
     * always reflected correctly. The decision is persisted to config so
     * mid-session reads remain consistent. Existing SD_CARD config values are
     * overridden — hardware presence is the authoritative signal, not stored prefs.
     *
     * Safe to call after getInstance() completes: updateActiveDirectories() guards
     * against switching while recording/surveillance is active.
     */
    fun applyAutoStoragePriority() {
        // 1. SD card (discovered in constructor via tryLoadSdCardFromCache / discoverSdCard).
        // Those two only ever detect a volume already in "mounted" state — neither
        // calls `sm mount`. A card that's physically present but sitting unmounted
        // at this point in boot (e.g. vold didn't auto-mount it) would otherwise be
        // invisible here forever. ensureSdCardMounted() is the method that actually
        // issues `sm mount`; call it repeatedly (with waits) so presence, not prior mount
        // state OR a single unlucky boot-timing race, decides.
        if (!sdCardAvailable) {
            val previouslyOnSdCard = recordingsStorageType == StorageType.SD_CARD ||
                surveillanceStorageType == StorageType.SD_CARD ||
                tripsStorageType == StorageType.SD_CARD
            val result = resolveSdCardAutoPriority(
                SD_CARD_BOOT_MOUNT_ATTEMPTS, SD_CARD_BOOT_MOUNT_RETRY_MS, previouslyOnSdCard,
                BooleanSupplier { ensureSdCardMounted(true) }, REAL_SLEEPER
            )
            if (result == AutoPriorityResult.KEEP_SD_CARD_AND_FLAG_ERROR) {
                isSdCardMountFailedAtBoot = true
                sdCardMountErrorMessage = "SD card is configured for storage but did not mount " +
                    "after " + SD_CARD_BOOT_MOUNT_ATTEMPTS + " attempts at startup. " +
                    "Restart the device with the SD card seated to restore SD card storage."
                logError(
                    sdCardMountErrorMessage +
                        " Keeping the existing SD_CARD preference rather than silently" +
                        " switching to internal storage."
                )
                // Active directories temporarily point at internal (existing
                // ensureStorageReady fallback) until the card mounts; the persisted
                // preference is untouched so the watchdog can restore it with no config
                // rewrite, and no files silently start accumulating under a preference
                // switch nobody asked for.
                updateActiveDirectories()
                return
            }
            // FALL_BACK_TO_INTERNAL falls through to step 3 below (no prior SD_CARD
            // preference to protect — this is the normal "no SD card ever configured"
            // auto-detect outcome). MOUNTED means ensureSdCardMounted() already set
            // sdCardAvailable/sdCardPath as a side effect.
        }

        isSdCardMountFailedAtBoot = false
        sdCardMountErrorMessage = null

        if (sdCardAvailable && sdCardPath != null) {
            val bladeWatchDir = File(sdCardPath, "BladeWatch")
            if (bladeWatchDir.exists()) {
                logInfo("Auto-priority: SD card with existing BladeWatch/ at $sdCardPath")
            } else {
                logInfo("Auto-priority: SD card found, creating BladeWatch/ at $sdCardPath")
            }
            // initSdCardDirectories() already ran — either in the constructor's
            // discovery, or just above inside ensureSdCardMounted() — dirs exist.
            recordingsStorageType = StorageType.SD_CARD
            surveillanceStorageType = StorageType.SD_CARD
            tripsStorageType = StorageType.SD_CARD
            updateActiveDirectories()
            saveConfig()
            return
        }

        // 2. USB drive (scans /mnt/usb* and /storage/usb*)
        val usbPath = discoverUsbDrive()
        if (usbPath != null) {
            logInfo("Auto-priority: USB drive found at $usbPath")
            // Reuse StorageType.SD_CARD machinery — USB is treated identically
            // once sdCardPath is set to the USB mount point.
            sdCardPath = usbPath
            sdCardAvailable = true
            writeSdCardCache(usbPath)
            initSdCardDirectories()
            recordingsStorageType = StorageType.SD_CARD
            surveillanceStorageType = StorageType.SD_CARD
            tripsStorageType = StorageType.SD_CARD
            updateActiveDirectories()
            saveConfig()
            return
        }

        // 3. Internal (default) — no external storage found
        logInfo("Auto-priority: no external storage found, using internal")
        recordingsStorageType = StorageType.INTERNAL
        surveillanceStorageType = StorageType.INTERNAL
        tripsStorageType = StorageType.INTERNAL
        updateActiveDirectories()
        saveConfig()
    }

    /**
     * Scans known USB mount paths (/mnt/usb* and /storage/usb*) and returns
     * the first directory that is writable by the shell UID, or null if none found.
     */
    private fun discoverUsbDrive(): String? {
        val candidates = ArrayList<String>()

        try {
            val mntEntries = File("/mnt").listFiles()
            if (mntEntries != null) {
                for (f in mntEntries) {
                    if (f.isDirectory && f.name.lowercase(Locale.ROOT).startsWith("usb")) {
                        candidates.add(f.absolutePath)
                    }
                }
            }
        } catch (e: Exception) {
            logDebug("USB scan /mnt failed: " + e.message)
        }

        try {
            val storageEntries = File("/storage").listFiles()
            if (storageEntries != null) {
                for (f in storageEntries) {
                    val name = f.name.lowercase(Locale.ROOT)
                    if (f.isDirectory && name.startsWith("usb") && !candidates.contains(f.absolutePath)) {
                        candidates.add(f.absolutePath)
                    }
                }
            }
        } catch (e: Exception) {
            logDebug("USB scan /storage failed: " + e.message)
        }

        for (path in candidates) {
            if (shellCanWrite(path)) {
                return path
            }
        }
        return null
    }

    // ==================== Directory Getters ====================

    val recordingsPath: String
        get() = recordingsDir.absolutePath

    val surveillancePath: String
        get() = surveillanceDir.absolutePath

    val proximityPath: String
        get() = proximityDir.absolutePath

    val tripsPath: String
        get() = tripsDir.absolutePath

    /**
     * Fix permissions on all storage directories and files.
     * Call this from daemon startup to ensure UI app can read recordings.
     * Note: chmod doesn't work on FUSE - rely on MediaScanner broadcast for cross-UID visibility.
     */
    fun fixAllPermissions() {
        // Fix directory permissions synchronously (fast, no I/O contention)
        val baseDir = File(INTERNAL_BASE_DIR)
        if (baseDir.exists()) {
            baseDir.setReadable(true, false)
            baseDir.setExecutable(true, false)
        }
        fixDirectoryPermissions(recordingsDir)
        fixDirectoryPermissions(surveillanceDir)
        fixDirectoryPermissions(proximityDir)
        fixDirectoryPermissions(tripsDir)

        // Make all existing files world-readable (chmod 666).
        // Required for: (1) UI app (different UID) to read files directly,
        // (2) FUSE layer on BYD Android to allow File.listFiles() to see them.
        // This is fast (no shell processes) — just Java File.setReadable() calls.
        makeFilesReadable(recordingsDir)
        makeFilesReadable(surveillanceDir)
        makeFilesReadable(proximityDir)
        makeFilesReadable(tripsDir)

        // SOTA: Incremental MediaScanner broadcast — only broadcast files created
        // since the last successful broadcast. Uses a marker file to track the
        // timestamp of the last full scan. On first run (no marker), broadcasts
        // everything once, then subsequent startups only broadcast new files.
        //
        // Additionally, broadcasts are throttled (50ms between each shell exec)
        // to avoid saturating the I/O bus during camera pipeline startup.
        // The old approach spawned 2 shell processes per file × hundreds of files
        // = hundreds of concurrent process forks competing with the GPU pipeline.
        Thread({
            val lastScanTimestamp = loadLastBroadcastTimestamp()
            val scanStartTime = System.currentTimeMillis()

            var count = 0
            count += broadcastFilesSince(recordingsDir, lastScanTimestamp)
            count += broadcastFilesSince(surveillanceDir, lastScanTimestamp)
            count += broadcastFilesSince(proximityDir, lastScanTimestamp)

            saveLastBroadcastTimestamp(scanStartTime)

            if (count > 0) {
                logInfo("MediaScanner broadcast complete: $count new files indexed")
            } else {
                logDebug("MediaScanner: no new files to broadcast since last scan")
            }
        }, "MediaScannerBroadcast").start()
    }

    /**
     * Load the timestamp of the last successful MediaScanner broadcast.
     * Returns 0 if no marker exists (first run — will broadcast everything).
     */
    private fun loadLastBroadcastTimestamp(): Long {
        try {
            val marker = File(BROADCAST_MARKER_FILE)
            if (marker.exists()) {
                val content = Scanner(marker).useDelimiter("\\A").next().trim()
                return content.toLong()
            }
        } catch (e: Exception) {
            logDebug("No broadcast marker found, will do full scan")
        }
        return 0
    }

    /**
     * Save the timestamp of the current broadcast scan.
     */
    private fun saveLastBroadcastTimestamp(timestamp: Long) {
        try {
            val fw = FileWriter(BROADCAST_MARKER_FILE)
            fw.write(timestamp.toString())
            fw.close()
        } catch (e: Exception) {
            logWarn("Failed to save broadcast marker: " + e.message)
        }
    }

    /**
     * Broadcast only files modified after the given timestamp.
     * Throttled to avoid I/O contention with the GPU pipeline.
     * @return number of files broadcast
     */
    private fun broadcastFilesSince(dir: File?, sinceTimestamp: Long): Int {
        if (dir == null || !dir.exists()) return 0

        val files = dir.listFiles { _, name -> name.endsWith(".mp4") }
        if (files == null || files.isEmpty()) return 0

        var count = 0
        for (f in files) {
            if (f.lastModified() > sinceTimestamp) {
                broadcastFile(f)
                count++

                // Throttle: yield between broadcasts to avoid saturating I/O
                if (count % 5 == 0) {
                    try {
                        Thread.sleep(BROADCAST_THROTTLE_MS)
                    } catch (e: InterruptedException) {
                        break
                    }
                }
            }
        }
        return count
    }

    // ==================== Limit Setters ====================

    private fun physicalDiskMaxMb(type: StorageType): Long {
        val diskBytes = if (type == StorageType.SD_CARD) sdCardTotalSpace else internalTotalSpace
        val diskMb = diskBytes / (1024L * 1024L)
        return if (diskMb > MIN_LIMIT_MB) diskMb else (if (type == StorageType.SD_CARD) MAX_LIMIT_MB_SD_CARD else MAX_LIMIT_MB_INTERNAL)
    }

    // ==================== Storage Type Setters ====================

    /**
     * Set recordings storage type (INTERNAL or SD_CARD).
     * @param type The storage type to use
     * @return true if successfully changed, false if SD card not available
     */
    fun setRecordingsStorageType(type: StorageType): Boolean {
        if (type == StorageType.SD_CARD) {
            // Try to mount SD card if not available (same as surveillance)
            if (!sdCardAvailable) {
                logInfo("SD card not available, attempting to mount...")
                if (!ensureSdCardMounted(true)) {  // Force mount
                    logWarn("Cannot set recordings to SD card - SD card mount failed")
                    return false
                }
            }
        }

        recordingsStorageType = type
        updateActiveDirectories()
        saveConfig()
        logInfo("Recordings storage type set to: $type")

        // SOTA: Auto-enable CDR cleanup when using SD card
        if (type == StorageType.SD_CARD) {
            autoEnableCdrCleanup()
        }

        return true
    }

    /**
     * Set surveillance storage type (INTERNAL or SD_CARD).
     * @param type The storage type to use
     * @return true if successfully changed, false if SD card not available
     */
    fun setSurveillanceStorageType(type: StorageType): Boolean {
        if (type == StorageType.SD_CARD) {
            // Try to mount SD card if not available
            if (!sdCardAvailable) {
                logInfo("SD card not available, attempting to mount...")
                if (!ensureSdCardMounted(true)) {  // Force mount
                    logWarn("Cannot set surveillance to SD card - SD card mount failed")
                    return false
                }
            }
        }

        surveillanceStorageType = type
        updateActiveDirectories()
        saveConfig()
        logInfo("Surveillance storage type set to: $type")

        // SOTA: Auto-enable CDR cleanup when using SD card
        if (type == StorageType.SD_CARD) {
            autoEnableCdrCleanup()
        }

        return true
    }

    /**
     * Set trips storage type (INTERNAL or SD_CARD).
     * Does NOT call autoEnableCdrCleanup() — trip files are small and don't compete with BYD dashcam space.
     * @param type The storage type to use
     * @return true if successfully changed, false if SD card not available
     */
    fun setTripsStorageType(type: StorageType): Boolean {
        if (type == StorageType.SD_CARD) {
            // Try to mount SD card if not available
            if (!sdCardAvailable) {
                logInfo("SD card not available, attempting to mount...")
                if (!ensureSdCardMounted(true)) {  // Force mount
                    logWarn("Cannot set trips to SD card - SD card mount failed")
                    return false
                }
            }
        }

        tripsStorageType = type
        updateActiveDirectories()
        saveConfig()
        logInfo("Trips storage type set to: $type")

        return true
    }

    /**
     * SOTA: Auto-enable CDR (BYD dashcam) cleanup when BladeWatch uses SD card.
     * This ensures BladeWatch always has space by cleaning up old dashcam files.
     */
    private fun autoEnableCdrCleanup() {
        try {
            val cleaner = ExternalStorageCleaner.getInstance()
            if (!cleaner.isEnabled && cleaner.isSdCardAvailable) {
                // Calculate recommended reserved space based on our limits
                var totalNeeded = 0L
                if (recordingsStorageType == StorageType.SD_CARD) {
                    totalNeeded += recordingsLimitMb
                }
                if (surveillanceStorageType == StorageType.SD_CARD) {
                    totalNeeded += surveillanceLimitMb
                }
                // Add 20% buffer
                val reservedMb = Math.max(2048L, (totalNeeded * 1.2).toLong())

                cleaner.reservedSpaceMb = reservedMb
                cleaner.isEnabled = true
                logInfo("Auto-enabled CDR cleanup with ${reservedMb}MB reserved for BladeWatch")
            }
        } catch (e: Exception) {
            logWarn("Could not auto-enable CDR cleanup: " + e.message)
        }
    }

    // ==================== All Storage Locations (for scanning) ====================

    /**
     * ALL directories that may contain recordings of a given type.
     * Returns the active (configured) directory first, then any alternate locations
     * where files may exist (e.g., internal when SD card is active, or vice versa).
     *
     * This is the single source of truth for multi-location scanning.
     * Callers should iterate all returned directories to find all files.
     */
    val allRecordingsDirs: List<File>
        get() = getAllDirsForType(recordingsDir, internalRecordingsDir, sdCardRecordingsDir)

    val allSurveillanceDirs: List<File>
        get() = getAllDirsForType(surveillanceDir, internalSurveillanceDir, sdCardSurveillanceDir)

    val allProximityDirs: List<File>
        get() = getAllDirsForType(proximityDir, internalProximityDir, sdCardProximityDir)

    val allTripsDirs: List<File>
        get() = getAllDirsForType(tripsDir, internalTripsDir, sdCardTripsDir)

    /**
     * Same as [allSurveillanceDirs] et al, but additionally
     * includes legacy app-files locations from older app versions where
     * stale media may still be living and counting toward the limit.
     *
     * Used by both the size accounting and the cleanup reaper so the two
     * agree about what "the surveillance pool" actually is — otherwise
     * the UI can show 800 MB used against a 500 MB limit while cleanup
     * (which only saw the active dir) thinks everything is fine.
     *
     * Includes the flat legacy base ([LEGACY_APP_FILES_DIR]) when a
     * non-null filename prefix is supplied via [namePrefixForCategory],
     * because the flat base is shared across categories and only files
     * matching the category's prefix should be touched.
     */
    private fun getReapableDirs(category: String): List<File> {
        val dirs: MutableList<File>
        var legacyPath: String? = null
        var includeFlatBase = false
        when (category) {
            "recordings" -> {
                dirs = ArrayList(allRecordingsDirs)
                legacyPath = "$LEGACY_APP_FILES_DIR/recordings"
                includeFlatBase = true  // some old installs wrote cam_* into <base>
            }
            "surveillance" -> {
                dirs = ArrayList(allSurveillanceDirs)
                legacyPath = LEGACY_SURVEILLANCE_DIR
            }
            "proximity" -> {
                dirs = ArrayList(allProximityDirs)
                legacyPath = "$LEGACY_APP_FILES_DIR/proximity_events"
            }
            "trips" -> {
                dirs = ArrayList(allTripsDirs)
            }
            else -> return ArrayList()
        }
        if (legacyPath != null) {
            addDirIfMissing(dirs, File(legacyPath))
        }
        if (includeFlatBase) {
            addDirIfMissing(dirs, File(LEGACY_APP_FILES_DIR))
        }
        return dirs
    }

    /**
     * Every directory a media category's segments can live in — active, the internal/SD
     * mirror, and the dedicated legacy path — MINUS the shared flat legacy base.
     *
     * For orphan sweepers, which delete by "this file's `.mp4` is missing" rather than by
     * an explicit selection. [getReapableDirs] is not safe for them as-is.
     *
     * The exclusion is load-bearing, not tidiness. `getReapableDirs("recordings")` adds
     * [LEGACY_APP_FILES_DIR] itself, which is not a media directory: it also holds
     * `bladewatch_secrets.json` (`SecretConfigStore.LEGACY_PATH`) and
     * `bladewatch_config.json` (`UnifiedConfigManager.LEGACY_APP_FILES_CONFIG`), plus
     * `.bladewatch_device_id`. A sidecar sweeper pointed at it sees two `.json` files with
     * no matching `.mp4` and deletes the device's legacy secrets and config.
     *
     * [ensureSpace] survives that directory only because it passes a category `namePrefix`.
     * A sweeper cannot use the same guard: per-actor thumbnails are named
     * `thumb_<base>_a*.jpg` and do not carry the category prefix, so prefix-filtering would
     * skip exactly the files the sweep exists for.
     *
     * "trips" is deliberately not a sweepable category. Trip telemetry is `<tripId>.jsonl.gz`
     * with no `.mp4` anywhere — nothing there is a sidecar.
     */
    fun sweepableDirs(category: String): List<File> =
        sweepableDirsFrom(category, getReapableDirs(category))

    /**
     * Sum .mp4 files across the given dirs, deduplicating by filename
     * (so a clip mirrored on internal + SD-card isn't counted twice).
     *
     * @param namePrefix If non-null, only files whose name starts with
     *                   this prefix are summed. Used when the dir set
     *                   includes the flat legacy base shared across
     *                   categories.
     */
    private fun getDirectoriesTotalSize(dirs: List<File>, namePrefix: String?): Long {
        var size = 0L
        val seen = HashSet<String>()
        for (dir in dirs) {
            if (dir == null || !dir.exists() || !dir.isDirectory) continue
            var files = dir.listFiles()
            if (files == null) {
                files = listFilesViaShell(dir)
            }
            if (files == null) continue
            for (f in files) {
                if (!f.isFile) continue
                val name = f.name
                if (namePrefix != null && !name.startsWith(namePrefix)) continue
                // Only the per-category extension counts (.mp4 + sidecar .json)
                // for limit accounting; filenames in the flat base that don't
                // match the prefix would already have been skipped above.
                if (!name.endsWith(".mp4") && !name.endsWith(".json")) continue
                if (!seen.add(name)) continue
                size += f.length()
            }
        }
        return size
    }

    /**
     * Build a deduplicated list of directories: active first, then alternates.
     * Skips null entries and directories that match the active one.
     */
    private fun getAllDirsForType(activeDir: File?, internalDir: File?, sdCardDir: File?): List<File> {
        val dirs = ArrayList<File>()
        val seen = HashSet<String>()

        // Active directory first (always included)
        if (activeDir != null) {
            dirs.add(activeDir)
            seen.add(activeDir.absolutePath)
        }

        // Internal directory (if different from active)
        if (internalDir != null && !seen.contains(internalDir.absolutePath)) {
            dirs.add(internalDir)
            seen.add(internalDir.absolutePath)
        }

        // SD card directory (if different from active)
        if (sdCardDir != null && !seen.contains(sdCardDir.absolutePath)) {
            dirs.add(sdCardDir)
            seen.add(sdCardDir.absolutePath)
        }

        return dirs
    }

    /**
     * Available space on SD card in bytes.
     */
    val sdCardFreeSpace: Long get() {
        val path = sdCardPath ?: return 0
        try {
            // Verify path exists before using StatFs
            val sdDir = File(path)
            if (!sdDir.exists() || !sdDir.isDirectory) {
                logDebug("SD card path not accessible: $path")
                return 0
            }
            val stat = StatFs(path)
            return stat.availableBytes
        } catch (e: Exception) {
            logWarn("Could not get SD card free space: " + e.message)
            return 0
        }
    }

    /**
     * Total space on SD card in bytes.
     */
    val sdCardTotalSpace: Long get() {
        val path = sdCardPath ?: return 0
        try {
            // Verify path exists before using StatFs
            val sdDir = File(path)
            if (!sdDir.exists() || !sdDir.isDirectory) {
                return 0
            }
            val stat = StatFs(path)
            return stat.totalBytes
        } catch (e: Exception) {
            logWarn("Could not get SD card total space: " + e.message)
            return 0
        }
    }

    /**
     * Available space on internal storage in bytes.
     */
    val internalFreeSpace: Long get() {
        try {
            val stat = StatFs(INTERNAL_BASE_DIR)
            return stat.availableBytes
        } catch (e: Exception) {
            logWarn("Could not get internal free space: " + e.message)
            return 0
        }
    }

    /**
     * Total space on internal storage in bytes.
     */
    val internalTotalSpace: Long get() {
        try {
            val stat = StatFs(INTERNAL_BASE_DIR)
            return stat.totalBytes
        } catch (e: Exception) {
            logWarn("Could not get internal total space: " + e.message)
            return 0
        }
    }

    /**
     * Refresh SD card detection and update directories.
     * Call this when SD card may have been inserted/removed.
     */
    fun refreshSdCard() {
        discoverSdCard()
        initSdCardDirectories()
        updateActiveDirectories()
        logInfo("SD card refresh complete. Available: $sdCardAvailable")
    }

    /**
     * Max limit based on storage type.
     */
    fun getMaxLimitMb(type: StorageType): Long =
        if (type == StorageType.SD_CARD) MAX_LIMIT_MB_SD_CARD else MAX_LIMIT_MB_INTERNAL

    // ==================== Storage Stats ====================

    /**
     * Current size of recordings across all locations (active dir, the
     * inactive internal/SD-card mirror, and legacy app-files paths).
     *
     * Must match the dirs the cleanup actually reaps — otherwise the UI can
     * report 800 MB used while the limit is 500 MB and cleanup never fires.
     */
    val recordingsSize: Long get() = getDirectoriesTotalSize(getReapableDirs("recordings"), namePrefixForCategory("recordings"))

    /**
     * Current size of surveillance across all locations (active dir, the
     * inactive internal/SD-card mirror, and the legacy sentry_events path).
     */
    val surveillanceSize: Long get() = getDirectoriesTotalSize(getReapableDirs("surveillance"), namePrefixForCategory("surveillance"))

    /**
     * Current size of proximity across all locations (active dir, the
     * inactive internal/SD-card mirror, and the legacy proximity_events path).
     */
    val proximitySize: Long get() = getDirectoriesTotalSize(getReapableDirs("proximity"), namePrefixForCategory("proximity"))

    /**
     * Recordings file count across all locations (active + inactive
     * mirror + legacy). Matches the size accounting so per-file averages
     * line up with reported totals.
     */
    val recordingsCount: Int get() = getFileCountAcross(getReapableDirs("recordings"), namePrefixForCategory("recordings"))

    /**
     * Surveillance events file count across all locations.
     */
    val surveillanceCount: Int get() = getFileCountAcross(getReapableDirs("surveillance"), namePrefixForCategory("surveillance"))

    /**
     * Proximity events file count across all locations.
     */
    val proximityCount: Int get() = getFileCountAcross(getReapableDirs("proximity"), namePrefixForCategory("proximity"))

    private fun getFileCountAcross(dirs: List<File>, namePrefix: String?): Int {
        var total = 0
        val seen = HashSet<String>()
        for (dir in dirs) {
            if (dir == null || !dir.exists() || !dir.isDirectory) continue
            var files = dir.listFiles { _, name -> name.endsWith(".mp4") }
            if (files == null) {
                files = listFilesViaShell(dir)
            }
            if (files == null) continue
            for (f in files) {
                if (!f.isFile) continue
                val name = f.name
                if (namePrefix != null && !name.startsWith(namePrefix)) continue
                if (seen.add(name)) {
                    total++
                }
            }
        }
        return total
    }

    /**
     * Current size of trips directory in bytes.
     */
    val tripsSize: Long get() = getDirectorySize(tripsDir)

    /**
     * Trips file count.
     */
    val tripsCount: Int get() = getFileCount(tripsDir)

    private fun getDirectorySize(dir: File): Long {
        if (!dir.exists() || !dir.isDirectory) return 0

        var size = 0L
        // Count ALL files in the directory (mp4, json sidecars, tmp, etc.)
        var files = dir.listFiles()

        if (files == null) {
            // Directory might be owned by UI app - use shell to list
            files = listFilesViaShell(dir)
        }

        if (files != null) {
            for (f in files) {
                if (f.isFile) {
                    size += f.length()
                }
            }
        }
        return size
    }

    private fun getFileCount(dir: File): Int {
        if (!dir.exists() || !dir.isDirectory) return 0

        // SOTA: Try direct listFiles first, fall back to shell if null
        var files = dir.listFiles { _, name -> name.endsWith(".mp4") }

        if (files == null) {
            // Directory might be owned by UI app - use shell to list
            files = listFilesViaShell(dir)
        }

        return files?.size ?: 0
    }

    /**
     * SOTA: List files via shell command when direct access fails.
     * This handles the case where UI app owns the directory but daemon needs to list files.
     */
    private fun listFilesViaShell(dir: File): Array<File>? {
        try {
            val p = Runtime.getRuntime().exec(arrayOf("ls", dir.absolutePath))
            val reader = BufferedReader(InputStreamReader(p.inputStream))

            val files = ArrayList<File>()
            var line: String?
            while (reader.readLine().also { line = it } != null) {
                if (line!!.endsWith(".mp4")) {
                    files.add(File(dir, line))
                }
            }
            reader.close()
            p.waitFor()

            logDebug("listFilesViaShell: found " + files.size + " files in " + dir.name)
            return files.toTypedArray()
        } catch (e: Exception) {
            logWarn("listFilesViaShell failed: " + e.message)
            return arrayOf()
        }
    }

    // ==================== Cleanup Logic ====================

    /**
     * Ensure recordings storage is within size limit.
     * Deletes oldest files (across active + inactive + legacy locations)
     * until the total falls under the limit.
     *
     * @param reserveBytes Additional bytes to reserve for new file
     * @return true if cleanup was successful and space is available
     */
    fun ensureRecordingsSpace(reserveBytes: Long): Boolean = ensureSpace(
        getReapableDirs("recordings"), recordingsDir,
        namePrefixForCategory("recordings"),
        recordingsLimitMb * 1024 * 1024, reserveBytes
    )

    /**
     * Ensure surveillance storage is within size limit.
     * Deletes oldest files (across active + inactive + legacy locations)
     * until the total falls under the limit.
     *
     * @param reserveBytes Additional bytes to reserve for new file
     * @return true if cleanup was successful and space is available
     */
    fun ensureSurveillanceSpace(reserveBytes: Long): Boolean = ensureSpace(
        getReapableDirs("surveillance"), surveillanceDir,
        namePrefixForCategory("surveillance"),
        surveillanceLimitMb * 1024 * 1024, reserveBytes
    )

    /**
     * Ensure proximity storage is within size limit.
     * Deletes oldest files (across active + inactive + legacy locations)
     * until the total falls under the limit.
     *
     * @param reserveBytes Additional bytes to reserve for new file
     * @return true if cleanup was successful and space is available
     */
    fun ensureProximitySpace(reserveBytes: Long): Boolean = ensureSpace(
        getReapableDirs("proximity"), proximityDir,
        namePrefixForCategory("proximity"),
        proximityLimitMb * 1024 * 1024, reserveBytes
    )

    /**
     * Ensure trips storage is within size limit.
     * Deletes oldest files until the total falls under the limit.
     *
     * @param reserveBytes Additional bytes to reserve for new file
     * @return true if cleanup was successful and space is available
     */
    fun ensureTripsSpace(reserveBytes: Long): Boolean = ensureSpace(
        getReapableDirs("trips"), tripsDir,
        namePrefixForCategory("trips"),
        tripsLimitMb * 1024 * 1024, reserveBytes
    )

    /**
     * Generic cleanup method that operates across a set of directories.
     *
     * Pools all .mp4 files from every dir (active, inactive mirror, legacy),
     * sorts globally by mtime, and deletes oldest-first until the combined
     * total is under the limit. This guarantees the user-configured limit
     * is honored across orphan locations after a storage-type switch or
     * after a legacy install left behind clips.
     *
     * SOTA: Uses shell fallback for listing/deleting when directory is owned
     * by a different UID than the daemon.
     *
     * @param dirs        Every directory whose files count toward this limit.
     *                    May contain a mix of active, inactive, and legacy
     *                    paths. Nulls/missing dirs are skipped.
     * @param activeDir   The dir new files will land in. Created if missing
     *                    so the next write doesn't fail.
     * @param limitBytes  Total bytes allowed across all dirs.
     * @param reserveBytes Additional bytes to keep free (subtracted from limit).
     * @return true if cleanup was successful and space is available
     */
    private fun ensureSpace(dirs: List<File>, activeDir: File?, namePrefix: String?, limitBytes: Long, reserveBytes: Long): Boolean {
        if (activeDir != null && (!activeDir.exists() || !activeDir.isDirectory)) {
            activeDir.mkdirs()
        }

        var targetSize = limitBytes - reserveBytes
        if (targetSize < 0) targetSize = 0

        val selection = selectFilesToDelete(
            dirs, namePrefix, targetSize,
            MarkedRecordingsStore.getInstance(), Function { d -> listMp4FilesWithShellFallback(d) }
        )

        // Key this on the POOL size, not on the selection being empty: selectFilesToDelete
        // also returns an empty selection when the pool is over target but every candidate
        // was skipped for being marked. Returning true there would claim space is available
        // while still over the limit, and would skip the CDR fallback below.
        if (selection.poolSizeAtStart <= targetSize) {
            return true  // Already within limit
        }

        var currentSize = selection.poolSizeAtStart
        var deletedCount = 0
        var deletedSize = 0L
        var reapedFromInactive = false

        for (file in selection.files) {
            val fileSize = file.length()
            var deleted = file.delete()
            if (!deleted) {
                deleted = deleteFileViaShell(file)
            }

            if (deleted) {
                currentSize -= fileSize
                deletedCount++
                deletedSize += fileSize
                if (activeDir == null || file.parentFile?.absolutePath != activeDir.absolutePath) {
                    reapedFromInactive = true
                }
                logInfo("Deleted old file: " + file.absolutePath + " (" + formatSize(fileSize) + ")")

                // Also delete every sidecar sitting next to the mp4 — they are all keyed off
                // the mp4 filename, so when the mp4 goes they are dead weight
                // (BladeWatch-k3b0 — 823 orphaned .jpg/.srt found on the head unit, 111 MB).
                //
                // Note what this does and does not cost, because an earlier version of this
                // comment got it wrong: getDirectoriesTotalSize counts only .mp4 and .json,
                // so orphaned .jpg/.srt waste disk on a shared SD card but never inflate a
                // category limit. An orphaned .json does inflate it, and would make this very
                // loop delete more real footage to reach its target.
                val parentDir = file.parentFile
                if (parentDir != null && file.name.endsWith(".mp4")) {
                    val base = file.name.substring(0, file.name.length - 4)

                    // Event timeline JSON, hero JPEG, and SRT subtitle track.
                    for (sidecarName in listOf("$base.json", "$base.jpg", "$base.srt")) {
                        val sidecar = File(parentDir, sidecarName)
                        if (sidecar.exists() && !sidecar.delete()) {
                            deleteFileViaShell(sidecar)
                        }
                    }

                    // Per-actor thumbnails. Anchor with "_a" so a sibling segment's thumbs
                    // (e.g. "thumb_<base>_2_a*.jpg") aren't swept when <base> is reaped.
                    val perActorPrefix = "thumb_${base}_a"
                    parentDir.listFiles { _, name ->
                        name.startsWith(perActorPrefix) && name.endsWith(".jpg")
                    }?.forEach { thumb ->
                        if (!thumb.delete()) deleteFileViaShell(thumb)
                    }
                }

                // Drop any cached entry the recordings API might still hold.
                try {
                    net.bladewatch.app.server.RecordingsApiHandler.invalidateRecordingCache(file.absolutePath)
                } catch (e: Throwable) {
                    logWarn("Failed to invalidate recording cache: " + e.message)
                }
            } else {
                logWarn("Failed to delete: " + file.absolutePath)
            }
        }

        if (deletedCount > 0) {
            logInfo(
                "Cleanup complete: deleted " + deletedCount + " files (" + formatSize(deletedSize) + ")" +
                    (if (reapedFromInactive) " — including orphan/legacy locations" else "")
            )
        }

        // If still over limit and the active dir lives on the SD card, fall
        // back to CDR cleanup to free up underlying SD-card space.
        val sdPath = sdCardPath
        if (currentSize > targetSize &&
            sdCardAvailable &&
            activeDir != null &&
            sdPath != null &&
            activeDir.absolutePath.startsWith(sdPath)
        ) {
            try {
                val cleaner = ExternalStorageCleaner.getInstance()
                if (cleaner.isEnabled) {
                    logInfo("BladeWatch cleanup insufficient on SD card — triggering CDR cleanup")
                    cleaner.ensureReservedSpace()
                }
            } catch (e: Exception) {
                logWarn("CDR fallback cleanup failed: " + e.message)
            }
        }

        return currentSize <= targetSize
    }

    /** One directory's .mp4 listing, falling back to a shell `ls` when the directory is
     * owned by a different UID and [File.listFiles] returns null. Extracted from
     * ensureSpace's own pre-existing inline logic so [selectFilesToDelete] can share
     * it via a lambda while staying a static, independently testable method. */
    private fun listMp4FilesWithShellFallback(dir: File): Array<File>? {
        val files = dir.listFiles { _, name -> name.endsWith(".mp4") }
        return files ?: listFilesViaShell(dir)
    }

    /** What would be deleted if the recordings limit were changed to `hypotheticalLimitMb`,
     * given today's files -- performs no deletion. BladeWatch-gyg1.4. Clamped through
     * [clampLimitMb] exactly as [setRecordingsLimitMb] would, so the preview
     * describes the limit that would actually be applied (BladeWatch-xa3s). */
    fun previewRecordingsLimitChange(hypotheticalLimitMb: Long): CleanupImpact =
        previewLimitChange(
            getReapableDirs("recordings"), namePrefixForCategory("recordings"),
            clampLimitMb(hypotheticalLimitMb, physicalDiskMaxMb(recordingsStorageType))
        )

    /** What would be deleted if the surveillance limit were changed to `hypotheticalLimitMb`,
     * given today's files -- performs no deletion. BladeWatch-gyg1.4. Clamped as
     * [setSurveillanceLimitMb] would; see [previewRecordingsLimitChange]. */
    fun previewSurveillanceLimitChange(hypotheticalLimitMb: Long): CleanupImpact =
        previewLimitChange(
            getReapableDirs("surveillance"), namePrefixForCategory("surveillance"),
            clampLimitMb(hypotheticalLimitMb, physicalDiskMaxMb(surveillanceStorageType))
        )

    private fun previewLimitChange(dirs: List<File>, namePrefix: String?, hypotheticalLimitMb: Long): CleanupImpact {
        val selection = selectFilesToDelete(
            dirs, namePrefix, hypotheticalLimitMb * 1024 * 1024,
            MarkedRecordingsStore.getInstance(), Function { d -> listMp4FilesWithShellFallback(d) }
        )
        var totalBytes = 0L
        for (f in selection.files) totalBytes += f.length()
        return CleanupImpact(selection.files.size, totalBytes)
    }

    /**
     * SOTA: Delete file via shell command when Java delete fails.
     */
    private fun deleteFileViaShell(file: File): Boolean {
        try {
            val p = Runtime.getRuntime().exec(arrayOf("rm", file.absolutePath))
            val exitCode = p.waitFor()
            return exitCode == 0
        } catch (e: Exception) {
            logWarn("deleteFileViaShell failed: " + e.message)
            return false
        }
    }

    /**
     * Run cleanup on both directories.
     */
    fun runCleanup() {
        ensureRecordingsSpace(0)
        ensureSurveillanceSpace(0)
        ensureProximitySpace(0)
        ensureTripsSpace(0)
    }

    // ==================== Event-Driven Cleanup (SOTA) ====================

    /**
     * Called after a recording file is saved/closed.
     * Triggers async cleanup to ensure we stay within limits.
     * Also sets file permissions so UI app can read it.
     *
     * This is the SOTA approach - cleanup after each file save rather than
     * only at recording start, preventing storage overflow during long sessions.
     *
     * IMPORTANT: Runs async to avoid blocking the video encoding thread.
     */
    fun onRecordingFileSaved() {
        // Fix directory permissions in case they were reset
        fixDirectoryPermissions(recordingsDir)

        // FIX: Removed broadcastRecentFiles() — specific file already broadcast by onFileSaved()

        asyncCleanupExecutor.execute {
            synchronized(cleanupLock) {
                try {
                    // Make all files in directory readable
                    makeFilesReadable(recordingsDir)

                    val currentSize = recordingsSize
                    val limitBytes = recordingsLimitMb * 1024 * 1024

                    if (currentSize > limitBytes) {
                        logInfo("Recording file saved - triggering cleanup (current=" + formatSize(currentSize) + ", limit=" + formatSize(limitBytes) + ")")
                        ensureRecordingsSpace(0)
                    } else {
                        logDebug("Recording file saved - within limits (" + formatSize(currentSize) + "/" + formatSize(limitBytes) + ")")
                    }
                } catch (e: Exception) {
                    logWarn("Async recording cleanup error: " + e.message)
                }
            }
        }
    }

    /**
     * Called after a surveillance event file is saved/closed.
     * Triggers async cleanup to ensure we stay within limits.
     * Also sets file permissions so UI app can read it.
     *
     * IMPORTANT: Runs async to avoid blocking the video encoding thread.
     */
    fun onSurveillanceFileSaved() {
        // Fix directory permissions in case they were reset
        fixDirectoryPermissions(surveillanceDir)

        // FIX: Removed broadcastRecentFiles() call that re-scanned ALL files modified
        // in the last 60 seconds. This caused duplicate MediaScanner broadcasts —
        // if two events saved 20 seconds apart, the second save re-broadcast the first.
        // Over days of parking, this list grows to hundreds of files, causing massive
        // CPU spikes on every new event. The specific file is already broadcast by
        // onFileSaved() → broadcastFile(file) before this method is called.

        asyncCleanupExecutor.execute {
            synchronized(cleanupLock) {
                try {
                    // Make all files in directory readable
                    makeFilesReadable(surveillanceDir)

                    val currentSize = surveillanceSize
                    val limitBytes = surveillanceLimitMb * 1024 * 1024

                    if (currentSize > limitBytes) {
                        logInfo("Surveillance file saved - triggering cleanup (current=" + formatSize(currentSize) + ", limit=" + formatSize(limitBytes) + ")")
                        ensureSurveillanceSpace(0)
                    } else {
                        logDebug("Surveillance file saved - within limits (" + formatSize(currentSize) + "/" + formatSize(limitBytes) + ")")
                    }
                } catch (e: Exception) {
                    logWarn("Async surveillance cleanup error: " + e.message)
                }
            }
        }
    }

    /**
     * Called after a proximity event file is saved/closed.
     * Triggers async cleanup to ensure we stay within limits.
     * Also sets file permissions so UI app can read it.
     *
     * IMPORTANT: Runs async to avoid blocking the video encoding thread.
     */
    fun onProximityFileSaved() {
        // Fix directory permissions in case they were reset
        fixDirectoryPermissions(proximityDir)

        // FIX: Removed broadcastRecentFiles() — specific file already broadcast by onFileSaved()

        asyncCleanupExecutor.execute {
            synchronized(cleanupLock) {
                try {
                    // Make all files in directory readable
                    makeFilesReadable(proximityDir)

                    val currentSize = proximitySize
                    val limitBytes = proximityLimitMb * 1024 * 1024

                    if (currentSize > limitBytes) {
                        logInfo("Proximity file saved - triggering cleanup (current=" + formatSize(currentSize) + ", limit=" + formatSize(limitBytes) + ")")
                        ensureProximitySpace(0)
                    } else {
                        logDebug("Proximity file saved - within limits (" + formatSize(currentSize) + "/" + formatSize(limitBytes) + ")")
                    }
                } catch (e: Exception) {
                    logWarn("Async proximity cleanup error: " + e.message)
                }
            }
        }
    }

    /**
     * Called after a trip telemetry file is saved/closed.
     * Triggers async cleanup to ensure we stay within limits.
     * Also sets file permissions so UI app can read it.
     *
     * IMPORTANT: Runs async to avoid blocking the telemetry recording thread.
     */
    fun onTripFileSaved() {
        // Fix directory permissions in case they were reset
        fixDirectoryPermissions(tripsDir)

        asyncCleanupExecutor.execute {
            synchronized(cleanupLock) {
                try {
                    // Make all files in directory readable
                    makeFilesReadable(tripsDir)

                    val currentSize = tripsSize
                    val limitBytes = tripsLimitMb * 1024 * 1024

                    if (currentSize > limitBytes) {
                        logInfo("Trip file saved - triggering cleanup (current=" + formatSize(currentSize) + ", limit=" + formatSize(limitBytes) + ")")
                        ensureTripsSpace(0)
                    } else {
                        logDebug("Trip file saved - within limits (" + formatSize(currentSize) + "/" + formatSize(limitBytes) + ")")
                    }
                } catch (e: Exception) {
                    logWarn("Async trips cleanup error: " + e.message)
                }
            }
        }
    }

    /**
     * Fix directory permissions so UI app can read files.
     * Note: chmod doesn't work on Android FUSE filesystem, but we keep Java API calls.
     */
    private fun fixDirectoryPermissions(dir: File?) {
        if (dir != null && dir.exists()) {
            dir.setReadable(true, false)
            dir.setExecutable(true, false)
        }
    }

    /**
     * Make all .mp4 files in directory readable by all.
     * Note: chmod doesn't work on Android FUSE filesystem - rely on MediaStore instead.
     */
    private fun makeFilesReadable(dir: File?) {
        if (dir == null || !dir.exists()) return

        var files = dir.listFiles { _, name -> name.endsWith(".mp4") }
        if (files == null) {
            files = listFilesViaShell(dir)
        }

        if (files != null) {
            for (f in files) {
                f.setReadable(true, false)
            }
        }
    }

    /**
     * Make a single file readable by all users.
     * Note: chmod doesn't work on Android FUSE - rely on MediaStore for cross-UID access.
     */
    fun makeFileReadable(file: File?) {
        if (file == null || !file.exists()) return
        file.setReadable(true, false)
    }

    /**
     * Force Android MediaScanner to index a file so it appears in MediaStore
     * and becomes visible to standard apps with READ_EXTERNAL_STORAGE.
     *
     * CRITICAL: Both methods are required on BYD's Android 10:
     * - `am broadcast MEDIA_SCANNER_SCAN_FILE` refreshes the FUSE permission cache
     *   so that File.listFiles() on SD card paths can see the file. Without this,
     *   the RecordingsApiHandler's scanDirectory() gets incomplete file listings.
     * - `content insert` directly inserts into MediaStore for cross-UID visibility
     *   (needed for the UI app running as a different UID).
     */
    private fun broadcastFile(file: File?) {
        if (file == null || !file.exists()) return

        val path = file.absolutePath

        try {
            // Method 1: FUSE cache refresh via MediaScanner intent
            // Required for File.listFiles() to work on SD card FUSE paths
            Runtime.getRuntime().exec(
                arrayOf(
                    "am", "broadcast",
                    "-a", "android.intent.action.MEDIA_SCANNER_SCAN_FILE",
                    "-d", "file://$path"
                )
            )

            // Method 2: Direct MediaStore insert for cross-UID visibility
            Runtime.getRuntime().exec(
                arrayOf(
                    "content", "insert",
                    "--uri", "content://media/external/video/media",
                    "--bind", "_data:s:$path"
                )
            )

            logDebug("Broadcast file to MediaScanner: " + file.name)
        } catch (e: Exception) {
            logWarn("Failed to broadcast file: " + e.message)
        }
    }

    /**
     * SOTA: Fix permissions and broadcast a single file after it's saved.
     * Call this immediately after closing a video file.
     * @param file The video file that was just saved
     */
    fun onFileSaved(file: File?) {
        if (file == null || !file.exists()) {
            logWarn("onFileSaved: file is null or doesn't exist")
            return
        }

        logInfo("Processing saved file: " + file.name + " (" + formatSize(file.length()) + ")")

        // 1. Make file readable by all (chmod 666)
        makeFileReadable(file)

        // 2. Broadcast to MediaScanner
        broadcastFile(file)

        // 3. Trigger appropriate cleanup based on directory
        val path = file.absolutePath
        if (path.contains(RECORDINGS_SUBDIR)) {
            onRecordingFileSaved()
        } else if (path.contains(SURVEILLANCE_SUBDIR)) {
            onSurveillanceFileSaved()
        } else if (path.contains(PROXIMITY_SUBDIR)) {
            onProximityFileSaved()
        } else if (path.contains(TRIPS_SUBDIR)) {
            onTripFileSaved()
        }

        // 4. Live-index into the media catalog (best-effort). Covers event +
        // proximity recordings, which finalize through this path. Non-.mp4 and
        // unrecognised filenames are ignored by the manager.
        if (file.name.endsWith(".mp4")) {
            try {
                val mcm = net.bladewatch.app.daemon.CameraDaemon.getMediaCatalogManager()
                mcm?.indexRecording(file)
            } catch (t: Throwable) {
                logWarn("media index (onFileSaved) failed: " + t.message)
            }
        }
    }

    // ==================== Periodic Background Cleanup ====================

    /**
     * Start periodic cleanup for long recording sessions.
     * Runs every 30 seconds while recording is active.
     */
    fun startPeriodicCleanup() {
        val existing = cleanupScheduler
        if (existing != null && !existing.isShutdown) {
            return  // Already running
        }

        val scheduler = Executors.newSingleThreadScheduledExecutor { r ->
            val t = Thread(r, "StorageCleanup")
            t.isDaemon = true
            t
        }
        cleanupScheduler = scheduler

        scheduler.scheduleAtFixedRate({
            try {
                // Run unconditionally — not gated on active recording. This catches
                // dirs that grew past the limit while the daemon was offline (crash
                // mid-recording, or user lowering the limit) and keeps the user's
                // configured limit honored even when nothing is currently writing.
                synchronized(cleanupLock) {
                    val currentSize = recordingsSize
                    val limitBytes = recordingsLimitMb * 1024 * 1024
                    if (currentSize > limitBytes * 0.9) {  // 90% threshold
                        logInfo("Periodic cleanup: recordings at " + formatSize(currentSize) + "/" + formatSize(limitBytes))
                        ensureRecordingsSpace(50 * 1024 * 1024)  // Reserve 50MB
                    }
                }

                synchronized(cleanupLock) {
                    val currentSize = surveillanceSize
                    val limitBytes = surveillanceLimitMb * 1024 * 1024
                    if (currentSize > limitBytes * 0.9) {  // 90% threshold
                        logInfo("Periodic cleanup: surveillance at " + formatSize(currentSize) + "/" + formatSize(limitBytes))
                        ensureSurveillanceSpace(50 * 1024 * 1024)  // Reserve 50MB
                    }
                }

                synchronized(cleanupLock) {
                    val currentSize = tripsSize
                    val limitBytes = tripsLimitMb * 1024 * 1024
                    if (currentSize > limitBytes * 0.9) {  // 90% threshold
                        logInfo("Periodic cleanup: trips at " + formatSize(currentSize) + "/" + formatSize(limitBytes))
                        ensureTripsSpace(50 * 1024 * 1024)  // Reserve 50MB
                    }
                }
            } catch (e: Exception) {
                logWarn("Periodic cleanup error: " + e.message)
            }
        }, CLEANUP_INTERVAL_SECONDS, CLEANUP_INTERVAL_SECONDS, TimeUnit.SECONDS)

        logInfo("Started periodic storage cleanup (interval=${CLEANUP_INTERVAL_SECONDS}s)")
    }

    /**
     * Stop periodic cleanup.
     */
    fun stopPeriodicCleanup() {
        cleanupScheduler?.let { scheduler ->
            scheduler.shutdown()
            try {
                if (!scheduler.awaitTermination(5, TimeUnit.SECONDS)) {
                    scheduler.shutdownNow()
                }
            } catch (e: InterruptedException) {
                scheduler.shutdownNow()
            }
            cleanupScheduler = null
            logInfo("Stopped periodic storage cleanup")
        }
    }

    /**
     * Start SD card mount watchdog for sentry mode.
     * Periodically checks if the SD card is still mounted and re-mounts it if the
     * system unmounted it (BYD/Android tends to unmount SD when ACC is off).
     *
     * Call this when entering sentry mode with SD card storage selected.
     */
    fun startSdCardWatchdog() {
        // Start watchdog if ANY storage type uses SD card (not just surveillance).
        // The watchdog keeps the SD card mounted so recordings, events, and trips
        // remain accessible via the HTTP server even when surveillance is suppressed.
        val anyOnSd = surveillanceStorageType == StorageType.SD_CARD ||
            recordingsStorageType == StorageType.SD_CARD ||
            tripsStorageType == StorageType.SD_CARD
        if (!anyOnSd) {
            logDebug("SD watchdog not needed - no storage type uses SD card")
            return
        }

        stopSdCardWatchdog()  // Stop any existing watchdog first

        val watchdog = Executors.newSingleThreadScheduledExecutor { r ->
            val t = Thread(r, "SdCardWatchdog")
            t.isDaemon = true
            t.priority = Thread.NORM_PRIORITY  // Normal priority - mount is critical
            t
        }
        sdCardWatchdog = watchdog

        watchdog.scheduleAtFixedRate({
            try {
                if (!isSdCardMounted()) {
                    sdWatchdogConsecutiveFailures++

                    // Only log verbosely for the first few failures, then quiet down
                    val shouldLog = sdWatchdogConsecutiveFailures <= SD_WATCHDOG_MAX_VERBOSE_FAILURES ||
                        sdWatchdogConsecutiveFailures % SD_WATCHDOG_QUIET_LOG_INTERVAL == 0

                    if (shouldLog) {
                        logWarn("SD card watchdog: card unmounted, attempting remount... (attempt #$sdWatchdogConsecutiveFailures)")
                    }

                    if (ensureSdCardMounted(true)) {
                        logInfo("SD card watchdog: remounted successfully after $sdWatchdogConsecutiveFailures attempts")
                        sdWatchdogConsecutiveFailures = 0
                        val clearingBootFailure = isSdCardMountFailedAtBoot
                        isSdCardMountFailedAtBoot = false
                        sdCardMountErrorMessage = null

                        // Restore SD card directories now that card is back
                        initSdCardDirectories()
                        updateActiveDirectories()

                        // Update running sentry engine's output directory
                        try {
                            val pipeline = net.bladewatch.app.daemon.CameraDaemon.getGpuPipeline()
                            if (pipeline != null && pipeline.sentry != null) {
                                pipeline.sentry?.setEventOutputDir(surveillanceDir)
                                logInfo("SD card watchdog: updated sentry output dir to " + surveillanceDir.absolutePath)
                            }
                        } catch (e: Exception) {
                            logWarn("SD card watchdog: could not update sentry dir: " + e.message)
                        }

                        // The card just came back after being unavailable (at boot or mid-
                        // session) — sweep anything that was written to internal storage in
                        // the meantime over to it. Background thread so a directory scan
                        // never delays the watchdog's own 15s cadence.
                        val migrateThread = Thread({
                            try {
                                val tam = net.bladewatch.app.daemon.CameraDaemon.getTripAnalyticsManager()
                                val mcm = net.bladewatch.app.daemon.CameraDaemon.getMediaCatalogManager()
                                InternalToSdMigrator.migrate(
                                    this,
                                    tam?.getDatabase(),
                                    if (mcm != null && mcm.isAvailable) Runnable { mcm.reconcile() } else null
                                )
                            } catch (e: Exception) {
                                logWarn("Internal-to-SD migration after watchdog remount failed: " + e.message)
                            }
                        }, "internal-to-sd-migration-watchdog")
                        migrateThread.isDaemon = true
                        // See CameraDaemon's boot-time migration trigger for why this must be
                        // low priority: internal->SD moves cross filesystems, so every file falls
                        // back to slow copy-then-delete.
                        migrateThread.priority = Thread.MIN_PRIORITY
                        migrateThread.start()
                        if (clearingBootFailure) {
                            logInfo("SD card watchdog: cleared boot-time mount failure flag")
                        }
                    } else if (shouldLog) {
                        logError("SD card watchdog: remount FAILED - surveillance may use internal fallback")
                    }
                } else {
                    // Card is mounted — reset failure counter
                    if (sdWatchdogConsecutiveFailures > 0) {
                        logInfo("SD card watchdog: card is mounted again")
                        sdWatchdogConsecutiveFailures = 0
                    }
                    isSdCardMountFailedAtBoot = false
                    sdCardMountErrorMessage = null
                }
            } catch (e: Exception) {
                logWarn("SD card watchdog error: " + e.message)
            }
        }, SD_WATCHDOG_INTERVAL_SECONDS, SD_WATCHDOG_INTERVAL_SECONDS, TimeUnit.SECONDS)

        logInfo("Started SD card mount watchdog (interval=${SD_WATCHDOG_INTERVAL_SECONDS}s)")
    }

    /**
     * Stop SD card mount watchdog (call when exiting sentry mode or ACC comes back on).
     */
    fun stopSdCardWatchdog() {
        sdCardWatchdog?.let { watchdog ->
            watchdog.shutdown()
            try {
                if (!watchdog.awaitTermination(3, TimeUnit.SECONDS)) {
                    watchdog.shutdownNow()
                }
            } catch (e: InterruptedException) {
                watchdog.shutdownNow()
            }
            sdCardWatchdog = null
            logInfo("Stopped SD card mount watchdog")
        }
    }

    /**
     * Set recording active state. Periodic cleanup runs continuously regardless
     * (started at daemon boot via [startPeriodicCleanup]); this flag
     * is kept for callers that may consult [isRecordingActive].
     */
    fun setRecordingActive(active: Boolean) {
        recordingActive.set(active)
    }

    /**
     * Set surveillance active state. See [setRecordingActive]
     * for periodic-cleanup lifetime semantics.
     */
    fun setSurveillanceActive(active: Boolean) {
        surveillanceActive.set(active)
    }

    /**
     * Wipes every media file (and JSON sidecars) for the given category from
     * all known storage locations — active dir, internal fallback, and SD-card
     * mirror — plus thumbnails for that category.
     *
     * Used by the user-initiated "Reset Data" feature. Holds [cleanupLock]
     * so it cannot race with periodic cleanup or any in-flight delete.
     *
     * @param category one of "recordings", "surveillance", "proximity", "trips"
     * @return number of files deleted, or -1 on unknown category
     */
    fun wipeMediaCategory(category: String?): Long {
        if (category == null) return -1
        val dirs: List<File> = when (category) {
            "recordings" -> allRecordingsDirs
            "surveillance" -> allSurveillanceDirs
            "proximity" -> allProximityDirs
            "trips" -> allTripsDirs
            else -> return -1
        }

        var deleted = 0L
        synchronized(cleanupLock) {
            for (dir in dirs) {
                if (dir == null || !dir.exists() || !dir.isDirectory) continue
                val files = dir.listFiles() ?: continue
                for (f in files) {
                    if (f.isFile && f.delete()) deleted++
                }
            }

            // Best-effort thumbnail cleanup. Thumbnails live alongside the
            // active dir's parent in a "thumbs" subfolder; nuking the whole
            // dir would also kill any other category's thumbs, so we limit
            // to those derived from the just-wiped filenames. Cheaper to
            // just blow away the whole thumbs dir on a media wipe.
            try {
                val baseDir = if (dirs.isEmpty() || dirs[0].parentFile == null) null else dirs[0].parentFile
                if (baseDir != null) {
                    val thumbs = File(baseDir, "thumbs")
                    if (thumbs.exists() && thumbs.isDirectory) {
                        val thumbFiles = thumbs.listFiles()
                        if (thumbFiles != null) {
                            for (t in thumbFiles) if (t.isFile) t.delete()
                        }
                    }
                }
            } catch (e: Exception) {
                logWarn("Thumbnail cleanup failed during wipeMediaCategory: " + e.message)
            }
        }

        logInfo("wipeMediaCategory($category) deleted $deleted files")
        return deleted
    }

    /**
     * Shutdown all background threads.
     * Call this when the app is terminating.
     */
    fun shutdown() {
        stopPeriodicCleanup()
        stopSdCardWatchdog()

        asyncCleanupExecutor.shutdown()
        try {
            if (!asyncCleanupExecutor.awaitTermination(2, TimeUnit.SECONDS)) {
                asyncCleanupExecutor.shutdownNow()
            }
        } catch (e: InterruptedException) {
            asyncCleanupExecutor.shutdownNow()
        }

        logInfo("StorageManager shutdown complete")
    }

    /** Outcome of [resolveSdCardAutoPriority]. */
    enum class AutoPriorityResult { MOUNTED, KEEP_SD_CARD_AND_FLAG_ERROR, FALL_BACK_TO_INTERNAL }

    /** Sleep abstraction so [resolveSdCardAutoPriority] is unit-testable without a
     * real `Thread.sleep` in the test process. */
    fun interface Sleeper {
        fun sleep(ms: Long)
    }

    /** Result of [selectFilesToDelete]: the files it selected (oldest first, already
     * excluding marked recordings) and the pooled size of every reapable file before any
     * selection, for the caller to track as deletions proceed. */
    class CleanupSelection(@JvmField val files: List<File>, @JvmField val poolSizeAtStart: Long)

    /** The exact impact (BladeWatch-gyg1.4) of changing a limit: how many files and how many
     * bytes the identical algorithm [ensureSpace] uses would remove. Never an
     * estimate -- computed from real per-file sizes via [selectFilesToDelete]. */
    class CleanupImpact(@JvmField val fileCount: Int, @JvmField val totalBytes: Long)

    companion object {
        private const val TAG = "StorageManager"

        // Hybrid logger - uses DaemonLogger when running as daemon, android.util.Log otherwise
        private var useDaemonLogger = false
        private var daemonLogger: DaemonLogger? = null

        /**
         * Enable daemon logging mode (call from daemon process).
         */
        @JvmStatic
        fun enableDaemonLogging() {
            useDaemonLogger = true
            daemonLogger = DaemonLogger.getInstance(TAG)
        }

        private fun logInfo(msg: String) {
            if (useDaemonLogger && daemonLogger != null) {
                daemonLogger!!.info(msg)
            } else {
                Log.i(TAG, msg)
            }
        }

        private fun logWarn(msg: String) {
            if (useDaemonLogger && daemonLogger != null) {
                daemonLogger!!.warn(msg)
            } else {
                Log.w(TAG, msg)
            }
        }

        private fun logError(msg: String) {
            if (useDaemonLogger && daemonLogger != null) {
                daemonLogger!!.error(msg)
            } else {
                Log.e(TAG, msg)
            }
        }

        private fun logDebug(msg: String) {
            if (useDaemonLogger && daemonLogger != null) {
                daemonLogger!!.debug(msg)
            } else {
                Log.d(TAG, msg)
            }
        }

        // Base directories for BladeWatch files
        private const val INTERNAL_BASE_DIR = "/storage/emulated/0/BladeWatch"

        // Legacy paths from older app versions. Files here aren't written anymore
        // but they still count toward the user's configured limit and must be
        // reaped — otherwise a 500 MB limit can show 800 MB used in the UI.
        private const val LEGACY_APP_FILES_DIR = "/storage/emulated/0/Android/data/net.bladewatch.app/files"
        private const val LEGACY_SURVEILLANCE_DIR = "$LEGACY_APP_FILES_DIR/sentry_events"

        // Known SD card mount paths (BYD and common Android paths)
        // SD card paths are discovered dynamically via discoverSdCard() — always /storage/<uuid>.
        // Do NOT add /mnt/sdcard or similar symlinks here; they may resolve to internal storage.

        // Subdirectories
        const val RECORDINGS_SUBDIR = "recordings"
        const val SURVEILLANCE_SUBDIR = "surveillance"
        const val PROXIMITY_SUBDIR = "proximity"
        const val TRIPS_SUBDIR = "trips"

        // SD card path cache — persists across restarts to avoid running sm list-volumes on every boot
        private const val SD_CARD_CACHE_PATH = "/data/local/tmp/bladewatch_sdcard_path"

        // Default limits (in bytes)
        private const val DEFAULT_RECORDINGS_LIMIT_MB = 500L
        private const val DEFAULT_SURVEILLANCE_LIMIT_MB = 500L
        private const val DEFAULT_PROXIMITY_LIMIT_MB = 500L
        private const val DEFAULT_TRIPS_LIMIT_MB = 500L
        private const val MIN_LIMIT_MB = 100L
        private const val MAX_LIMIT_MB_INTERNAL = 2_000_000L  // 2TB hard ceiling (physical disk is the real limit)
        private const val MAX_LIMIT_MB_SD_CARD = 2_000_000L  // 2TB hard ceiling (physical disk is the real limit)

        // Periodic cleanup interval (30 seconds)
        private const val CLEANUP_INTERVAL_SECONDS = 30L

        // Singleton instance
        @Volatile private var instance: StorageManager? = null

        @JvmStatic
        @Synchronized
        fun getInstance(): StorageManager {
            instance?.let { return it }
            val created = StorageManager()
            instance = created
            return created
        }

        // Marker file that stores the epoch millis of the last successful broadcast scan.
        private const val BROADCAST_MARKER_FILE = "/data/local/tmp/bladewatch_last_mediascan"

        // Throttle delay between individual file broadcasts (ms).
        private const val BROADCAST_THROTTLE_MS = 50L

        // SD card mount watchdog constants
        private const val SD_WATCHDOG_INTERVAL_SECONDS = 15L
        private const val SD_WATCHDOG_MAX_VERBOSE_FAILURES = 5  // Log verbosely for first 5 failures
        private const val SD_WATCHDOG_QUIET_LOG_INTERVAL = 20   // Then log every 20th attempt (~5 min)

        /** Mount attempts at boot before [applyAutoStoragePriority] gives up on a
         * previously-configured SD card. Spaced [SD_CARD_BOOT_MOUNT_RETRY_MS] apart;
         * each [ensureSdCardMounted] call has its own internal up-to-3s wait for the
         * sdcardfs layer, so worst case this budgets roughly
         * (attempts-1)*retryMs + attempts*3s before giving up on a truly absent card. */
        private const val SD_CARD_BOOT_MOUNT_ATTEMPTS = 5
        private const val SD_CARD_BOOT_MOUNT_RETRY_MS = 2000L

        private val REAL_SLEEPER = Sleeper { ms ->
            try {
                Thread.sleep(ms)
            } catch (e: InterruptedException) {
                Thread.currentThread().interrupt()
            }
        }

        /**
         * Pure retry-then-decide logic for SD card auto-priority at boot, extracted static +
         * dependency-injected so it is unit-testable without a live Android environment — the
         * same constraint that motivated extracting [selectFilesToDelete] (see
         * `StorageManagerCleanupSelectionTest`'s doc comment).
         *
         * Calls `mountAttempt` up to `maxAttempts` times, sleeping `sleepMs`
         * between attempts (never after the last one), stopping as soon as one attempt reports
         * mounted.
         *
         * The decision on exhaustion is the actual fix for a real incident: a boot-time race
         * where the SD card isn't mounted yet by the time this runs used to silently downgrade an
         * already-configured SD_CARD preference to INTERNAL and persist that change — recovering
         * required a full device restart, sometimes more than one, to win the race. Retrying first,
         * and refusing to downgrade an existing SD_CARD preference even once retries are exhausted,
         * fixes that: [applyAutoStoragePriority] flags the failure instead (surfaced to the
         * UI so the user knows to restart) and leaves the preference alone so the SD watchdog keeps
         * retrying in the background and can still self-heal without a restart.
         *
         * @param previouslyOnSdCard whether the persisted config already had at least one category
         *        on SD_CARD before this pass began
         */
        @JvmStatic
        fun resolveSdCardAutoPriority(
            maxAttempts: Int,
            sleepMs: Long,
            previouslyOnSdCard: Boolean,
            mountAttempt: BooleanSupplier,
            sleeper: Sleeper
        ): AutoPriorityResult {
            for (attempt in 1..maxAttempts) {
                if (mountAttempt.asBoolean) {
                    return AutoPriorityResult.MOUNTED
                }
                if (attempt < maxAttempts) {
                    sleeper.sleep(sleepMs)
                }
            }
            return if (previouslyOnSdCard) AutoPriorityResult.KEEP_SD_CARD_AND_FLAG_ERROR else AutoPriorityResult.FALL_BACK_TO_INTERNAL
        }

        /**
         * The limit that would actually be persisted for `limitMb`: clamped to
         * `[MIN_LIMIT_MB, maxLimitMb]`.
         *
         * Static with the maximum injected so it is testable without a live
         * `StorageManager` — the same constraint that shaped [selectFilesToDelete].
         * Every path that reasons about a proposed limit must go through this (BladeWatch-xa3s):
         * a preview computed from the raw request describes a limit that can never be applied, and
         * for a negative or overflowing value it describes deleting everything, because a negative
         * byte target makes [selectFilesToDelete]'s stop condition unreachable.
         */
        @JvmStatic
        fun clampLimitMb(limitMb: Long, maxLimitMb: Long): Long = Math.max(MIN_LIMIT_MB, Math.min(maxLimitMb, limitMb))

        /**
         * Filename prefix that identifies media belonging to `category`.
         * When non-null, callers that scan multi-category directories (the
         * flat legacy base) should restrict to filenames starting with this
         * prefix so they don't reap a sibling category's files. Returns null
         * for categories whose dirs are all category-dedicated.
         */
        /**
         * The decision behind [sweepableDirs], as a static taking its input rather than
         * reading it — a StorageManager cannot be constructed in a JVM test (it needs real
         * `/storage/emulated/0` paths and `StatFs`), which is the same reason
         * [selectFilesToDelete] was extracted this way. The guard this encodes is
         * security-relevant, so it needs to be reachable by a test.
         */
        @JvmStatic
        internal fun sweepableDirsFrom(category: String, reapableDirs: List<File>): List<File> =
            when (category) {
                "recordings", "surveillance", "proximity" ->
                    reapableDirs.filter { it.absolutePath != LEGACY_APP_FILES_DIR }
                else -> emptyList()
            }

        private fun namePrefixForCategory(category: String): String? = when (category) {
            "recordings" -> "cam"        // cam_*, cam2_*, …
            "surveillance" -> "event_"
            "proximity" -> "proximity_"
            else -> null
        }

        /**
         * Selects, oldest-first, exactly the files [ensureSpace] would delete to bring
         * `dirs`' pooled total at or under `targetSizeBytes` -- skipping files
         * `markedStore` reports as marked (BladeWatch-nmao.4) -- but performs no deletion.
         * Returns an empty selection when the pool is already within the target or has nothing
         * reapable. BladeWatch-gyg1.4: shared, unmodified, by both the real cleanup in
         * [ensureSpace] (which deletes the returned files) and
         * `previewRecordingsLimitChange`/`previewSurveillanceLimitChange` (which
         * only sum them) -- the two paths can never disagree about which files a given limit
         * would remove, because they run the identical selection code.
         *
         * Static and dependency-injected (`markedStore`, `lister`) specifically so
         * it is testable without constructing a `StorageManager`, which needs a live
         * Android environment (see `MarkedRecordingsExcludedFromCleanupTest`'s doc comment).
         */
        @JvmStatic
        fun selectFilesToDelete(
            dirs: List<File>,
            namePrefix: String?,
            targetSizeBytes: Long,
            markedStore: MarkedRecordingsStore,
            lister: Function<File, Array<File>?>
        ): CleanupSelection {
            // Collect every reapable file, deduplicated by filename so a clip
            // that exists on both internal and SD card isn't accounted twice.
            // When namePrefix is non-null, restrict to files matching the
            // category (some dirs in the list are shared with other categories
            // — typically the flat legacy base).
            val allFiles = ArrayList<File>()
            val seenNames = HashSet<String>()
            var currentSize = 0L
            for (dir in dirs) {
                if (dir == null || !dir.exists() || !dir.isDirectory) continue
                val files = lister.apply(dir) ?: continue
                for (f in files) {
                    if (!f.isFile) continue
                    val name = f.name
                    if (namePrefix != null && !name.startsWith(namePrefix)) continue
                    if (!seenNames.add(name)) continue
                    allFiles.add(f)
                    currentSize += f.length()
                }
            }

            if (currentSize <= targetSizeBytes || allFiles.isEmpty()) {
                return CleanupSelection(emptyList(), currentSize)
            }

            // Oldest first (global ordering across all dirs).
            allFiles.sortBy { it.lastModified() }

            val toDelete = ArrayList<File>()
            var remaining = currentSize
            for (file in allFiles) {
                if (remaining <= targetSizeBytes) break

                // BladeWatch-nmao.4: a bookmarked clip must never be swept -- having it
                // deleted out from under a mark is worse than having no bookmark at all.
                if (markedStore.isMarked(file.name)) {
                    continue
                }

                toDelete.add(file)
                remaining -= file.length()
            }

            return CleanupSelection(toDelete, currentSize)
        }

        // ==================== Utility ====================

        @JvmStatic
        fun formatSize(bytes: Long): String {
            if (bytes >= 1_000_000_000) {
                return String.format("%.1f GB", bytes / 1_000_000_000.0)
            } else if (bytes >= 1_000_000) {
                return String.format("%.1f MB", bytes / 1_000_000.0)
            } else if (bytes >= 1_000) {
                return String.format("%.1f KB", bytes / 1_000.0)
            }
            return "$bytes B"
        }

        @JvmStatic
        fun getMinLimitMb(): Long = MIN_LIMIT_MB

        @JvmStatic
        fun getMaxLimitMb(): Long = getMaxLimitMbInternal()

        @JvmStatic
        fun getMaxLimitMbInternal(): Long {
            val sm = getInstance()
            val diskMb = sm.internalTotalSpace / (1024L * 1024L)
            if (diskMb > MIN_LIMIT_MB) return diskMb
            return MAX_LIMIT_MB_INTERNAL
        }

        @JvmStatic
        fun getMaxLimitMbSdCard(): Long {
            val sm = getInstance()
            val diskMb = sm.sdCardTotalSpace / (1024L * 1024L)
            if (diskMb > MIN_LIMIT_MB) return diskMb
            return MAX_LIMIT_MB_SD_CARD
        }
    }
}

/** Add [candidate] to [dirs] if it's a real, not-already-present directory. */
private fun addDirIfMissing(dirs: MutableList<File>, candidate: File?) {
    if (candidate == null || !candidate.exists() || !candidate.isDirectory) return
    val path = candidate.absolutePath
    for (d in dirs) {
        if (d != null && d.absolutePath == path) return
    }
    dirs.add(candidate)
}
