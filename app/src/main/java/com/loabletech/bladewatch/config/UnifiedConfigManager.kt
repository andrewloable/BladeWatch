package net.bladewatch.app.config

import android.util.Log
import net.bladewatch.app.recording.RecordingPriority
import org.json.JSONObject
import java.io.File
import java.io.FileWriter
import java.nio.channels.FileChannel
import java.nio.channels.FileLock
import java.nio.file.StandardOpenOption
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.atomic.AtomicLong

/**
 * SOTA Unified Configuration Manager
 * 
 * Solves the UID permission problem by using a world-accessible location
 * that both the app (via IPC) and shell daemon can read/write.
 * 
 * Architecture:
 * - Single JSON file in the app external files directory, mirrored to
 *   /data/local/tmp/bladewatch_config.json for older hardcoded readers
 * - App UI writes via IPC to daemon (daemon has shell UID 2000)
 * - Web UI/daemon writes directly (already has shell UID 2000)
 * - Both read from the same file
 * - Change listeners for real-time sync
 * 
 * Config sections:
 * - surveillance: Detection settings (minObjectSize, flashImmunity, etc.)
 * - recording: Recording settings (bitrate, codec, pre/post buffer)
 * - streaming: Streaming quality settings
 * - network: Network exposure settings
 */
object UnifiedConfigManager {
    private const val TAG = "UnifiedConfig"
    
    // Single source of truth. Config lives under the user-visible BladeWatch
    // tree (NOT app-scoped external files), so it survives app uninstall /
    // reinstall and updates — a fresh install picks the existing config back
    // up instead of starting from defaults. /data/local/tmp can be recreated
    // across BYD head-unit restarts, and app-scoped files are wiped on
    // uninstall, so neither is suitable as the persistent home.
    private const val CONFIG_PATH = "/storage/emulated/0/BladeWatch/data/bladewatch_config.json"
    private const val LEGACY_CONFIG_PATH = "/data/local/tmp/bladewatch_config.json"
    // Prior persistent home (pre-BladeWatch/data). Older installs kept the
    // unified config in app-scoped external files; promote it on first run
    // so existing user settings are preserved rather than rebuilt.
    private const val LEGACY_APP_FILES_CONFIG = "/storage/emulated/0/Android/data/net.bladewatch.app/files/bladewatch_config.json"

    // Legacy paths for migration
    private const val LEGACY_SENTRY_CONFIG = "/data/local/tmp/sentry_config.json"
    private const val LEGACY_CAMERA_SETTINGS = "/data/local/tmp/camera_settings.json"
    private const val LEGACY_SYSTEM_CONFIG = "/data/data/com.android.providers.settings/sentry_config.json"

    /**
     * Cross-process write lock (BladeWatch-17l7). On the real filesystem, not next to the canonical
     * sdcardfs file, so both uids lock the same inode. See [withCrossProcessLock].
     */
    private const val CONFIG_LOCK_PATH = "/data/local/tmp/bladewatch_config.json.lock"
    private const val CROSS_PROCESS_LOCK_WAIT_MS = 2_000L

    // ponytail: test seam -- null = the device paths above; a directory puts the canonical file,
    // the mirror, the old app-files home and the lock in it, so a JVM test can run the real I/O.
    @Volatile private var baseDirForTest: File? = null
    private val canonicalPath: String
        get() = baseDirForTest?.let { File(it, "bladewatch_config.json").path } ?: CONFIG_PATH
    private val mirrorPath: String
        get() = baseDirForTest?.let { File(it, "mirror/bladewatch_config.json").path } ?: LEGACY_CONFIG_PATH
    private val appFilesPath: String
        get() = baseDirForTest?.let { File(it, "appfiles/bladewatch_config.json").path } ?: LEGACY_APP_FILES_CONFIG
    private val lockPath: String
        get() = baseDirForTest?.let { File(it, "bladewatch_config.json.lock").path } ?: CONFIG_LOCK_PATH

    /** Test seam: point every path at [dir] (null = the device paths again) and drop the cache. */
    @JvmStatic
    internal fun useDirectoryForTest(dir: File?) = synchronized(this) {
        baseDirForTest = dir
        cachedConfig = null
        lastModified.set(0)
    }
    
    // In-memory cache
    @Volatile
    private var cachedConfig: JSONObject? = null
    private val lastModified = AtomicLong(0)
    
    // Change listeners
    private val listeners = CopyOnWriteArrayList<ConfigChangeListener>()
    
    interface ConfigChangeListener {
        fun onConfigChanged(section: String, config: JSONObject)
    }
    
    /**
     * Initialize and migrate from legacy configs if needed.
     */
    @JvmStatic
    fun init() {
        val configFile = File(canonicalPath)

        if (configFile.exists()) {
            Log.i(TAG, "Unified config exists at $canonicalPath")
            loadConfig()
            return
        }

        // A prior install may already hold a complete unified config at the
        // old app-files home or the /data/local/tmp mirror. Promote it to the
        // new persistent location via loadConfig() (which re-saves to
        // CONFIG_PATH) instead of rebuilding from the much older per-feature
        // legacy configs and losing user settings.
        if (File(appFilesPath).exists() || File(mirrorPath).exists()) {
            Log.i(TAG, "Promoting prior unified config to $canonicalPath")
            loadConfig()
            return
        }

        Log.i(TAG, "Unified config not found, migrating from legacy configs...")
        migrateFromLegacy()
    }
    
    /**
     * Migrate from legacy config files to unified config.
     */
    private fun migrateFromLegacy() {
        val unified = JSONObject()
        
        // Initialize sections
        unified.put("surveillance", JSONObject())
        unified.put("recording", JSONObject())
        unified.put("streaming", JSONObject())
        unified.put("network", JSONObject())
        unified.put("proximityGuard", JSONObject())
        unified.put("telemetryOverlay", JSONObject())
        unified.put("tripAnalytics", JSONObject())
        unified.put("version", 1)
        unified.put("lastModified", System.currentTimeMillis())
        
        // Try to migrate from legacy sentry config
        try {
            val legacySentry = File(LEGACY_SENTRY_CONFIG)
            if (legacySentry.exists()) {
                val legacy = JSONObject(legacySentry.readText())
                val surveillance = unified.getJSONObject("surveillance")
                
                // Copy surveillance settings
                copyIfExists(legacy, surveillance, "blockSize")
                copyIfExists(legacy, surveillance, "requiredBlocks")
                copyIfExists(legacy, surveillance, "sensitivity")
                copyIfExists(legacy, surveillance, "flashImmunity")
                copyIfExists(legacy, surveillance, "temporalFrames")
                copyIfExists(legacy, surveillance, "useChroma")
                copyIfExists(legacy, surveillance, "minDistanceM")
                copyIfExists(legacy, surveillance, "maxDistanceM")
                copyIfExists(legacy, surveillance, "cameraHeightM")
                copyIfExists(legacy, surveillance, "cameraTiltDeg")
                copyIfExists(legacy, surveillance, "verticalFovDeg")
                copyIfExists(legacy, surveillance, "aiConfidence")
                copyIfExists(legacy, surveillance, "minObjectSize")
                copyIfExists(legacy, surveillance, "detectPerson")
                copyIfExists(legacy, surveillance, "detectCar")
                copyIfExists(legacy, surveillance, "detectBike")
                copyIfExists(legacy, surveillance, "preRecordSeconds")
                copyIfExists(legacy, surveillance, "postRecordSeconds")
                
                Log.i(TAG, "Migrated surveillance settings from $LEGACY_SENTRY_CONFIG")
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to migrate from legacy sentry config: ${e.message}")
        }
        
        // Try to migrate from legacy camera settings
        try {
            val legacyCamera = File(LEGACY_CAMERA_SETTINGS)
            if (legacyCamera.exists()) {
                val legacy = JSONObject(legacyCamera.readText())
                val recording = unified.getJSONObject("recording")
                val streaming = unified.getJSONObject("streaming")
                
                // Copy recording settings
                copyIfExists(legacy, recording, "recordingBitrate", "bitrate")
                copyIfExists(legacy, recording, "recordingCodec", "codec")
                copyIfExists(legacy, recording, "recordingQuality", "quality")
                
                // Copy streaming settings
                copyIfExists(legacy, streaming, "streamingQuality", "quality")
                
                Log.i(TAG, "Migrated recording/streaming settings from $LEGACY_CAMERA_SETTINGS")
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to migrate from legacy camera settings: ${e.message}")
        }
        
        // Try system config as fallback
        try {
            val systemConfig = File(LEGACY_SYSTEM_CONFIG)
            if (systemConfig.exists()) {
                val legacy = JSONObject(systemConfig.readText())
                val surveillance = unified.getJSONObject("surveillance")
                
                // Only copy if not already set
                if (!surveillance.has("minObjectSize")) {
                    copyIfExists(legacy, surveillance, "minObjectSize")
                }
                if (!surveillance.has("flashImmunity")) {
                    copyIfExists(legacy, surveillance, "flashImmunity")
                }
                
                Log.i(TAG, "Migrated additional settings from $LEGACY_SYSTEM_CONFIG")
            }
        } catch (e: Exception) {
            Log.w(TAG, "Failed to migrate from system config: ${e.message}")
        }
        
        // Apply defaults for missing values
        applyDefaults(unified)
        
        // Save unified config
        saveConfigInternal(unified)
        cachedConfig = unified
        
        Log.i(TAG, "Migration complete. Unified config saved to $canonicalPath")
    }
    
    private fun copyIfExists(from: JSONObject, to: JSONObject, key: String, newKey: String = key) {
        if (from.has(key)) {
            to.put(newKey, from.get(key))
        }
    }
    
    private fun applyDefaults(config: JSONObject) {
        val surveillance = config.getJSONObject("surveillance")
        val recording = config.getJSONObject("recording")
        val streaming = config.getJSONObject("streaming")
        val network = config.optJSONObject("network") ?: JSONObject().also {
            config.put("network", it)
        }
        val proximityGuard = config.optJSONObject("proximityGuard") ?: JSONObject().also { 
            config.put("proximityGuard", it) 
        }
        
        // Surveillance defaults
        if (!surveillance.has("minObjectSize")) surveillance.put("minObjectSize", 0.08)
        if (!surveillance.has("aiConfidence")) surveillance.put("aiConfidence", 0.25)
        if (!surveillance.has("flashImmunity")) surveillance.put("flashImmunity", 2)
        if (!surveillance.has("detectPerson")) surveillance.put("detectPerson", true)
        if (!surveillance.has("detectCar")) surveillance.put("detectCar", true)
        if (!surveillance.has("detectBike")) surveillance.put("detectBike", false)
        if (!surveillance.has("preRecordSeconds")) surveillance.put("preRecordSeconds", 5)
        if (!surveillance.has("postRecordSeconds")) surveillance.put("postRecordSeconds", 10)
        if (!surveillance.has("blockSize")) surveillance.put("blockSize", 32)
        if (!surveillance.has("requiredBlocks")) surveillance.put("requiredBlocks", 3)
        if (!surveillance.has("sensitivity")) surveillance.put("sensitivity", 0.04)
        if (!surveillance.has("surveillanceEnabled")) surveillance.put("surveillanceEnabled", false)
        if (!surveillance.has("deterrentAction")) surveillance.put("deterrentAction", "silent")
        if (!surveillance.has("deterrentCooldownSeconds")) surveillance.put("deterrentCooldownSeconds", 15)
        
        // Recording defaults. The canonical key is `recordingQuality` (ECONOMY..MAX).
        // `quality` is the legacy mirror; `bitrate` (LOW/MEDIUM/HIGH) is no longer
        // seeded — it would drift from the active tier and confuse cross-channel
        // readers. Keep it only if a user actually has it from a pre-migration install.
        if (!recording.has("mode")) recording.put("mode", "NONE")  // Default: no recording
        if (!recording.has("recordingQuality")) recording.put("recordingQuality", "STANDARD")
        if (!recording.has("quality")) recording.put("quality", recording.optString("recordingQuality", "STANDARD"))
        if (!recording.has("codec")) recording.put("codec", "H264")
        // Per-file recording limit in minutes (segment rotation). Options 1/5/10.
        if (!recording.has("segmentMinutes")) recording.put("segmentMinutes", 5)
        // Recording priority (PERFORMANCE/RELIABILITY): new installs get the safer default.
        // The priorityMigrated marker is set here too (mirroring telemetryOverlay above) so
        // migrateConfig()'s one-time PERFORMANCE migration below never re-touches a config
        // that was already created under this default. See BladeWatch-gyg1.3.
        if (!recording.has("priority")) recording.put("priority", RecordingPriority.RELIABILITY.name)
        if (!recording.has("priorityMigrated")) recording.put("priorityMigrated", true)

        // Streaming defaults
        if (!streaming.has("quality")) streaming.put("quality", "MEDIUM")

        // Network defaults
        if (!network.has("lanHttpEnabled")) network.put("lanHttpEnabled", false)
        
        // Proximity Guard defaults
        if (!proximityGuard.has("enabled")) proximityGuard.put("enabled", false)
        if (!proximityGuard.has("triggerLevel")) proximityGuard.put("triggerLevel", "RED")
        if (!proximityGuard.has("preRecordSeconds")) proximityGuard.put("preRecordSeconds", 5)
        if (!proximityGuard.has("postRecordSeconds")) proximityGuard.put("postRecordSeconds", 10)
        
        // Telemetry Overlay defaults — ON by default so dashcam recordings get
        // the telemetry/GPS overlay burned in without a manual opt-in. The
        // defaultOnMigrated marker is set here so existing configs (created
        // under the old false-default) are migrated exactly once by
        // migrateConfig() and never re-flipped after the user toggles it off.
        val telemetryOverlay = config.optJSONObject("telemetryOverlay") ?: JSONObject().also {
            config.put("telemetryOverlay", it)
        }
        if (!telemetryOverlay.has("enabled")) telemetryOverlay.put("enabled", true)
        if (!telemetryOverlay.has("defaultOnMigrated")) telemetryOverlay.put("defaultOnMigrated", true)
        
        // Trip Analytics defaults
        val tripAnalytics = config.optJSONObject("tripAnalytics") ?: JSONObject().also {
            config.put("tripAnalytics", it)
        }
        if (!tripAnalytics.has("enabled")) tripAnalytics.put("enabled", false)

        // Floating status pill segment visibility. Independent of whether the
        // underlying feature (recording / trip analytics) is enabled — these
        // only gate the pill segments so users can hide either without
        // surrendering SYSTEM_ALERT_WINDOW or disabling the feature itself.
        val statusOverlay = config.optJSONObject("statusOverlay") ?: JSONObject().also {
            config.put("statusOverlay", it)
        }
        if (!statusOverlay.has("cameraVisible")) statusOverlay.put("cameraVisible", true)
        if (!statusOverlay.has("tripVisible")) statusOverlay.put("tripVisible", true)

        // Vehicle appearance defaults — selected 3D model and body paint color.
        // Stored unified so AVN and remote (phone-over-tunnel) clients show the
        // same vehicle. modelId must match an entry in models/manifest.json; the
        // bundled default 'seal' is always available offline.
        val vehicle = config.optJSONObject("vehicle") ?: JSONObject().also {
            config.put("vehicle", it)
        }
        if (!vehicle.has("modelId")) vehicle.put("modelId", "seal")
        if (!vehicle.has("color")) vehicle.put("color", "#E8E8EC")  // Aurora White

        // Developer options defaults
        val developerOptions = config.optJSONObject("developerOptions") ?: JSONObject().also {
            config.put("developerOptions", it)
        }
        if (!developerOptions.has("timingLogsEnabled")) developerOptions.put("timingLogsEnabled", true)
        if (!developerOptions.has("debugLogsEnabled")) developerOptions.put("debugLogsEnabled", false)
    }

    /**
     * Applies idempotent, one-time migrations to an already-loaded config and
     * returns true if it was mutated (so the caller persists it). Unlike
     * [applyDefaults], this runs on EXISTING configs every load — each
     * migration must therefore be guarded by its own marker so it fires once
     * and never overrides a deliberate later user choice.
     */
    /**
     * Applies the one-time, marker-gated migrations. The bodies live in [ConfigMigrations], a
     * pure object with no `android.*` dependency, so they are unit-testable without a live
     * Android environment -- this class is not (BladeWatch-l5w4).
     */
    private fun migrateConfig(config: JSONObject): Boolean = ConfigMigrations.apply(config)

    /**
     * Load config from file (with caching).
     */
    @JvmStatic
    fun loadConfig(): JSONObject {
        val configFile = File(canonicalPath)
        val legacyAppFilesConfigFile = File(appFilesPath)
        val legacyConfigFile = File(mirrorPath)

        // Check if file changed since last load
        if (cachedConfig != null && configFile.exists()) {
            val fileModified = configFile.lastModified()
            if (fileModified <= lastModified.get()) {
                return cachedConfig!!
            }
        }

        return synchronized(this) {
            try {
                // Prefer the new persistent home, then the old app-files home,
                // then the /data/local/tmp mirror. When the source is not the
                // canonical file, it is re-saved to CONFIG_PATH below (one-time
                // migration), which also re-creates the /data/local/tmp mirror.
                val sourceFile = when {
                    configFile.exists() -> configFile
                    legacyAppFilesConfigFile.exists() -> legacyAppFilesConfigFile
                    legacyConfigFile.exists() -> legacyConfigFile
                    else -> null
                }
                if (sourceFile != null) {
                    val content = sourceFile.readText()
                    val config = JSONObject(content)
                    val migrated = migrateConfig(config)
                    cachedConfig = config
                    // Re-save when promoting a legacy/mirror source to the
                    // canonical path, OR when a one-time migration mutated the
                    // loaded config so the change is persisted.
                    if (sourceFile.absolutePath != configFile.absolutePath || migrated) {
                        saveConfigInternal(config)
                    }
                    // Track the canonical file's fresh mtime so the cache
                    // freshness check doesn't immediately invalidate next load.
                    lastModified.set(
                        configFile.lastModified().takeIf { it > 0 } ?: sourceFile.lastModified()
                    )
                    Log.d(TAG, "Config loaded from ${sourceFile.absolutePath}")
                    config
                } else {
                    Log.w(TAG, "Config file not found, initializing...")
                    init()
                    cachedConfig ?: createDefaultConfig()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to load config: ${e.message}")
                cachedConfig ?: createDefaultConfig()
            }
        }
    }
    
    /**
     * Save entire config to file.
     */
    @JvmStatic
    fun saveConfig(config: JSONObject): Boolean {
        config.put("lastModified", System.currentTimeMillis())
        val success = saveConfigInternal(config)
        if (success) {
            cachedConfig = config
            // Track the file's actual mtime, NOT wall-clock — the cache
            // freshness check at loadConfig() compares fs mtime against
            // this value to detect cross-process writes. If we stored
            // System.currentTimeMillis() here, the saved mtime would
            // (almost always) be greater than the file's mtime, so the
            // fileModified <= lastModified check would never trip and
            // a cross-UID write would never invalidate the cache.
            lastModified.set(File(canonicalPath).lastModified())
            notifyListeners("all", config)
        }
        return success
    }
    
    private fun saveConfigInternal(config: JSONObject): Boolean {
        val configFile = File(canonicalPath)
        configFile.parentFile?.mkdirs()
        val payload = config.toString(2)

        // Atomic write: write to a sibling .tmp file, then rename. The rename
        // is a single inode swap on the filesystem, so power loss either
        // leaves the old file intact or fully promotes the new one — never
        // a half-written corrupt config that would wipe user settings.
        //
        // The catch matters: when the app UID (10xxx) writes here, it
        // can't always create new files in /data/local/tmp/ (the dir is
        // typically owned by shell:shell with the sticky bit). The tmp
        // create throws FileNotFoundException/EACCES. Without this catch,
        // every app-side write would fail, the cache would never be
        // updated, and `loadConfig` would re-enter `init()` →
        // `migrateFromLegacy()` on every subsequent call — producing the
        // ANR storm in the Connect-and-Test flow.
        val tmpFile = File(configFile.parentFile, configFile.name + ".tmp")
        try {
            FileWriter(tmpFile).use { it.write(payload) }
            tmpFile.setReadable(true, false)
            tmpFile.setWritable(true, false)
            if (tmpFile.renameTo(configFile)) {
                Log.i(TAG, "Config saved to $canonicalPath (atomic)")
                mirrorLegacyConfig(payload)
                return true
            }
            Log.w(TAG, "Atomic rename failed; falling back to direct write")
        } catch (e: Exception) {
            Log.w(TAG, "Tmp-write path unavailable (${e.message}); falling back to direct write")
        }

        // Fallback: write directly to the existing world-RW file. The
        // daemon (UID 2000) creates it on first boot with 0666, so the
        // app UID can open it for writing even though it can't create
        // new files in /data/local/tmp/. We lose atomicity here — a
        // crash mid-write corrupts the file — but for the cross-UID
        // case it's the only path that works, and corruption is
        // recoverable on next boot via the legacy-migration fallback.
        return try {
            if (!configFile.exists()) {
                Log.e(TAG, "Config file missing and tmp-create denied; cannot save")
                false
            } else {
                FileWriter(configFile).use { it.write(payload) }
                configFile.setReadable(true, false)
                configFile.setWritable(true, false)
                try { tmpFile.delete() } catch (_: Exception) {}
                Log.i(TAG, "Config saved to $canonicalPath (direct)")
                mirrorLegacyConfig(payload)
                true
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to save config: ${e.message}")
            false
        }
    }

    private fun mirrorLegacyConfig(payload: String) {
        if (canonicalPath == mirrorPath) return
        try {
            val legacyFile = File(mirrorPath)
            legacyFile.parentFile?.mkdirs()
            FileWriter(legacyFile).use { it.write(payload) }
            legacyFile.setReadable(true, false)
            legacyFile.setWritable(true, false)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to mirror legacy config: ${e.message}")
        }
    }
    
    // ==================== SECTION GETTERS ====================
    
    /**
     * Get surveillance config section.
     */
    @JvmStatic
    fun getSurveillance(): JSONObject {
        return loadConfig().optJSONObject("surveillance") ?: JSONObject()
    }
    
    /**
     * Get the surveillance schedule from config.
     * Returns a SurveillanceSchedule loaded from the surveillance section.
     */
    @JvmStatic
    fun getSurveillanceSchedule(): net.bladewatch.app.surveillance.SurveillanceSchedule {
        val schedule = net.bladewatch.app.surveillance.SurveillanceSchedule()
        schedule.loadFromJson(getSurveillance())
        return schedule
    }
    
    /**
     * Get recording config section.
     */
    @JvmStatic
    fun getRecording(): JSONObject {
        return loadConfig().optJSONObject("recording") ?: JSONObject()
    }
    
    /**
     * Get streaming config section.
     */
    @JvmStatic
    fun getStreaming(): JSONObject {
        return loadConfig().optJSONObject("streaming") ?: JSONObject()
    }
    
    /**
     * Get proximity guard config section.
     */
    @JvmStatic
    fun getProximityGuard(): JSONObject {
        return loadConfig().optJSONObject("proximityGuard") ?: JSONObject()
    }
    
    /**
     * Get telemetry overlay config section.
     * Defaults to enabled=false if section doesn't exist.
     */
    @JvmStatic
    fun getTelemetryOverlay(): JSONObject {
        return loadConfig().optJSONObject("telemetryOverlay") ?: JSONObject().apply {
            put("enabled", false)
        }
    }
    
    // ==================== SECTION SETTERS ====================
    
    /**
     * Update surveillance config section.
     */
    @JvmStatic
    fun setSurveillance(surveillance: JSONObject): Boolean {
        return updateSection("surveillance", surveillance)
    }
    
    /**
     * Update recording config section.
     */
    @JvmStatic
    fun setRecording(recording: JSONObject): Boolean {
        return updateSection("recording", recording)
    }
    
    /**
     * Update streaming config section.
     */
    @JvmStatic
    fun setStreaming(streaming: JSONObject): Boolean {
        return updateSection("streaming", streaming)
    }
    
    /**
     * Update proximity guard config section.
     */
    @JvmStatic
    fun setProximityGuard(proximityGuard: JSONObject): Boolean {
        return updateSection("proximityGuard", proximityGuard)
    }
    
    /**
     * Update telemetry overlay config section.
     */
    @JvmStatic
    fun setTelemetryOverlay(telemetryOverlay: JSONObject): Boolean {
        return updateSection("telemetryOverlay", telemetryOverlay)
    }
    
    /**
     * Get trip analytics config section.
     * Defaults to enabled=false if section doesn't exist.
     */
    @JvmStatic
    fun getTripAnalytics(): JSONObject {
        return loadConfig().optJSONObject("tripAnalytics") ?: JSONObject().apply {
            put("enabled", false)
        }
    }
    
    /**
     * Update trip analytics config section.
     */
    @JvmStatic
    fun setTripAnalytics(tripAnalytics: JSONObject): Boolean {
        return updateSection("tripAnalytics", tripAnalytics)
    }

    /**
     * Get status-overlay (floating pill) visibility section.
     * Each segment defaults to visible=true so installs that pre-date this
     * setting see no behavior change.
     */
    @JvmStatic
    fun getStatusOverlay(): JSONObject {
        return loadConfig().optJSONObject("statusOverlay") ?: JSONObject().apply {
            put("cameraVisible", true)
            put("tripVisible", true)
        }
    }

    /**
     * Update status-overlay (floating pill) visibility section.
     */
    @JvmStatic
    fun setStatusOverlay(statusOverlay: JSONObject): Boolean {
        return updateSection("statusOverlay", statusOverlay)
    }

    /**
     * Check whether LAN HTTP binding is explicitly enabled.
     * Default is false so fresh installs only listen on loopback.
     */
    @JvmStatic
    fun isLanHttpEnabled(): Boolean {
        return loadConfig().optJSONObject("network")?.optBoolean("lanHttpEnabled", false) ?: false
    }

    /**
     * Update LAN HTTP binding mode.
     */
    @JvmStatic
    fun setLanHttpEnabled(enabled: Boolean): Boolean {
        return updateValues("network", mapOf("lanHttpEnabled" to enabled))
    }

    /**
     * Check whether daemon startup timing logs are enabled.
     * Default is false — timing logs are a dev/diagnostic tool and are off
     * in normal operation to keep logcat uncluttered.
     */
    @JvmStatic
    fun isTimingLogsEnabled(): Boolean {
        return loadConfig().optJSONObject("developerOptions")?.optBoolean("timingLogsEnabled", true) ?: true
    }

    /**
     * Update daemon startup timing logs flag.
     */
    @JvmStatic
    fun setTimingLogsEnabled(enabled: Boolean): Boolean {
        return updateValues("developerOptions", mapOf("timingLogsEnabled" to enabled))
    }

    /**
     * Check whether developer debug logs are enabled.
     * When true, the app logs Activity/Fragment lifecycle events and startup steps
     * to /storage/emulated/0/BladeWatch/data/debug_app.log.
     * Default is false — disabled in normal use.
     */
    @JvmStatic
    fun isDebugLogsEnabled(): Boolean {
        return loadConfig().optJSONObject("developerOptions")?.optBoolean("debugLogsEnabled", false) ?: false
    }

    /**
     * Update developer debug logs flag.
     */
    @JvmStatic
    fun setDebugLogsEnabled(enabled: Boolean): Boolean {
        return updateValues("developerOptions", mapOf("debugLogsEnabled" to enabled))
    }

    /**
     * Whether an OPTIONAL daemon is enabled, from the cross-process `daemons`
     * section, or null when nothing has recorded a preference yet.
     *
     * BladeWatch-abcx: [net.bladewatch.app.ui.util.PreferencesManager] is the historical
     * home for this, but it is app-private SharedPreferences — unreachable from the
     * Flutter APK even under the shared UID. This section is the value BOTH UIs and the
     * daemon agree on. Null (not false) means "unset", so an existing install keeps
     * whatever SharedPreferences already says instead of silently flipping to disabled.
     */
    @JvmStatic
    fun isDaemonEnabled(daemonType: String): Boolean? {
        // From DISK, not the cache (BladeWatch-17l7): this decides whether a health check relaunches
        // remote access, and a stale cached "true" undid an owner's switch-off on the head unit.
        val daemons = (readConfigFromDisk() ?: loadConfig()).optJSONObject("daemons") ?: return null
        if (!daemons.has(daemonType)) return null
        return daemons.optBoolean(daemonType, false)
    }

    /**
     * Record whether an OPTIONAL daemon should be running. Read by
     * `DaemonStartupManager`'s health check, which is what actually starts it.
     */
    @JvmStatic
    fun setDaemonEnabled(daemonType: String, enabled: Boolean): Boolean {
        return updateValues("daemons", mapOf(daemonType to enabled))
    }

    /**
     * Drop a daemon entry entirely — for removing an entry that outlived the daemon it
     * named (BladeWatch-fjb0). Returns true only if something was actually removed, so a
     * caller can stay quiet on the overwhelmingly common no-op.
     *
     * Deliberately NOT expressible through [updateValues], which can only write values.
     */
    @JvmStatic
    fun removeDaemonEntry(daemonType: String): Boolean = mutate { config ->
        val daemons = config.optJSONObject("daemons") ?: return@mutate false
        if (!daemons.has(daemonType)) return@mutate false
        daemons.remove(daemonType)
        config.put("daemons", daemons)
        val success = saveConfig(config)
        if (success) notifyListeners("daemons", daemons)
        success
    }

    /**
     * The owner's explicit nominal pack capacity in kWh, or 0 when unset (BladeWatch-b9vl).
     *
     * Stored in the `vehicle` section next to `modelId`, because it describes the same thing:
     * which car this is. `NominalCapacityResolver` validates the range — this only reads it.
     */
    @JvmStatic
    fun getNominalCapacityOverrideKwh(): Double = getVehicle().optDouble("nominalKwhOverride", 0.0)

    /**
     * Set or clear the owner's nominal pack capacity. Pass 0 to clear it and fall back to
     * auto-detection.
     */
    @JvmStatic
    fun setNominalCapacityOverrideKwh(kwh: Double): Boolean {
        val patch = JSONObject()
        patch.put("nominalKwhOverride", if (kwh.isNaN() || kwh <= 0) 0.0 else kwh)
        return updateSection("vehicle", patch)
    }

    /**
     * Get vehicle appearance config section (selected 3D model + body color).
     */
    @JvmStatic
    fun getVehicle(): JSONObject {
        return loadConfig().optJSONObject("vehicle") ?: JSONObject().apply {
            put("modelId", "seal")
            put("color", "#E8E8EC")
        }
    }

    /**
     * Update vehicle appearance config section.
     */
    @JvmStatic
    fun setVehicle(vehicle: JSONObject): Boolean {
        return updateSection("vehicle", vehicle)
    }

    /**
     * Web-shell appearance preference (theme picker shipped in the WebView
     * pages). Stored separately from the Android-shell theme so a remote
     * user accessing the tunnel can pick their own preference
     * without touching the Android side. Default: "dark".
     *
     * Schema:
     *   { "theme": "dark" | "light" | "auto",
     *     "locale": "en" | "de" | … | "auto" }
     *
     * `locale` is stored here (not in LocaleManager) so the web-side
     * language picker doesn't cross-pollinate the Android app's locale.
     * Survives tunnel-URL changes (a tunnel origin can change, so localStorage
     * alone is not enough). Default: "auto"
     * (the runtime falls back to navigator.language).
     */
    @JvmStatic
    fun getAppearance(): JSONObject {
        return loadConfig().optJSONObject("appearance") ?: JSONObject().apply {
            put("theme", "dark")
            put("locale", "auto")
        }
    }

    @JvmStatic
    fun setAppearance(appearance: JSONObject): Boolean {
        return updateSection("appearance", appearance)
    }
    
    /**
     * Update a specific section of the config.
     */
    @JvmStatic
    fun updateSection(section: String, data: JSONObject): Boolean = mutate { config ->
        // Merge into existing section to preserve keys not present in data
        // (e.g. surveillanceEnabled is set separately from detection params)
        val existing = config.optJSONObject(section) ?: JSONObject()
        var changed = stripSensitiveKeys(section, existing)
        val keys = data.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            if (isSensitiveKey(section, key)) {
                Log.w(TAG, "Ignoring sensitive key write to public config: $section.$key")
                continue
            }
            changed = true
            existing.put(key, data.get(key))
        }
        config.put(section, existing)
        if (!changed) return@mutate false
        val success = saveConfig(config)
        if (success) {
            notifyListeners(section, existing)
        }
        success
    }
    
    /**
     * Update individual values within a section.
     */
    @JvmStatic
    fun updateValues(section: String, values: Map<String, Any>): Boolean = mutate { config ->
        val sectionObj = config.optJSONObject(section) ?: JSONObject()
        var changed = stripSensitiveKeys(section, sectionObj)

        values.forEach { (key, value) ->
            if (isSensitiveKey(section, key)) {
                Log.w(TAG, "Ignoring sensitive key write to public config: $section.$key")
                return@forEach
            }
            changed = true
            sectionObj.put(key, value)
        }

        config.put(section, sectionObj)
        if (!changed) return@mutate false
        val success = saveConfig(config)
        if (success) {
            notifyListeners(section, sectionObj)
        }
        success
    }

    /**
     * Every read-modify-write of the config goes through here (BladeWatch-17l7).
     *
     * Several processes write this file -- the service host, CameraDaemon (including the Flutter
     * UI's IPC writes) -- and each used to start from its own in-memory cache. That cache is only
     * refreshed when the file's mtime looks newer, so a writer could save a stale whole-file copy
     * over someone else's change: on the head unit an owner's PEAR_PEER=false came back as true.
     * Now each change starts from the file AS IT IS ON DISK, under a lock every process shares.
     */
    private inline fun mutate(change: (JSONObject) -> Boolean): Boolean = synchronized(this) {
        withCrossProcessLock { change(readConfigFromDisk() ?: loadConfig()) }
    }

    /**
     * The canonical file exactly as it is now, bypassing the cache; null when it is missing or
     * does not parse, and the caller then falls back to [loadConfig], which also owns first-run
     * creation and legacy promotion.
     */
    private fun readConfigFromDisk(): JSONObject? = try {
        File(canonicalPath).takeIf { it.exists() }?.let { JSONObject(it.readText()) }
    } catch (_: Exception) {
        null
    }

    /**
     * Runs [action] holding an fcntl lock on [lockPath] when one can be had within
     * [CROSS_PROCESS_LOCK_WAIT_MS], and unlocked otherwise. The lock file must be world-writable --
     * the app uid has to open it for writing and cannot create files in /data/local/tmp itself --
     * so any app could sit on it. A config write must never hang on that: falling back to the old
     * unlocked write is the right failure for a file that holds no secrets. (The secret store's
     * lock is owner-only for exactly the opposite reason.)
     */
    private inline fun <T> withCrossProcessLock(action: () -> T): T {
        val lockFile = File(lockPath)
        val channel = try {
            FileChannel.open(lockFile.toPath(), StandardOpenOption.CREATE, StandardOpenOption.WRITE)
                .also { lockFile.setReadable(true, false); lockFile.setWritable(true, false) }
        } catch (_: Exception) {
            null // e.g. the app uid before any shell process has created the file
        }
        var lock: FileLock? = null
        try {
            val deadline = System.currentTimeMillis() + CROSS_PROCESS_LOCK_WAIT_MS
            while (channel != null && lock == null && System.currentTimeMillis() < deadline) {
                lock = try { channel.tryLock() } catch (_: Exception) { break }
                if (lock == null) Thread.sleep(2)
            }
            return action()
        } finally {
            try { lock?.release() } catch (_: Exception) {}
            try { channel?.close() } catch (_: Exception) {}
        }
    }
    
    // ==================== CONVENIENCE METHODS ====================
    
    /**
     * Get a specific surveillance value.
     */
    @JvmStatic
    fun getSurveillanceValue(key: String, default: Any): Any {
        return getSurveillance().opt(key) ?: default
    }
    
    /**
     * Get a specific recording value.
     */
    @JvmStatic
    fun getRecordingValue(key: String, default: Any): Any {
        return getRecording().opt(key) ?: default
    }
    
    /**
     * Get a specific proximity guard value.
     */
    @JvmStatic
    fun getProximityGuardValue(key: String, default: Any): Any {
        return getProximityGuard().opt(key) ?: default
    }
    
    /**
     * Check if surveillance is enabled in config (user preference for ACC OFF auto-start).
     */
    @JvmStatic
    fun isSurveillanceEnabled(): Boolean {
        return getSurveillance().optBoolean("surveillanceEnabled", false)
    }
    
    /**
     * Set surveillance enabled state in config.
     */
    @JvmStatic
    fun setSurveillanceEnabled(enabled: Boolean): Boolean {
        return updateValues("surveillance", mapOf("surveillanceEnabled" to enabled))
    }
    
    // ==================== LISTENERS ====================
    
    @JvmStatic
    fun addListener(listener: ConfigChangeListener) {
        listeners.add(listener)
    }
    
    @JvmStatic
    fun removeListener(listener: ConfigChangeListener) {
        listeners.remove(listener)
    }
    
    private fun notifyListeners(section: String, config: JSONObject) {
        listeners.forEach { listener ->
            try {
                listener.onConfigChanged(section, config)
            } catch (e: Exception) {
                Log.e(TAG, "Listener error: ${e.message}")
            }
        }
    }
    
    // ==================== UTILITY ====================
    
    private fun createDefaultConfig(): JSONObject {
        val config = JSONObject()
        config.put("surveillance", JSONObject())
        config.put("recording", JSONObject())
        config.put("streaming", JSONObject())
        config.put("proximityGuard", JSONObject())
        config.put("telemetryOverlay", JSONObject())
        config.put("tripAnalytics", JSONObject())
        config.put("version", 1)
        config.put("lastModified", System.currentTimeMillis())
        applyDefaults(config)
        return config
    }

    private fun sanitizeLoadedConfig(config: JSONObject): Boolean {
        var changed = false
        val keys = config.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            val section = config.optJSONObject(key) ?: continue
            if (stripSensitiveKeys(key, section)) {
                changed = true
            }
        }
        return changed
    }

    private fun stripSensitiveKeys(section: String, data: JSONObject): Boolean {
        var changed = false
        sensitiveKeysFor(section).forEach { sensitiveKey ->
            if (data.has(sensitiveKey)) {
                data.remove(sensitiveKey)
                changed = true
            }
        }
        return changed
    }

    private fun isSensitiveKey(section: String, key: String): Boolean {
        return sensitiveKeysFor(section).contains(key)
    }

    private fun sensitiveKeysFor(section: String): Set<String> {
        return when (section) {
            "auth" -> setOf("deviceSecret")
            // The tunnel has no secrets any more: a Tor onion service needs no account,
            // no token and no registration. Its only secret is the hidden-service key,
            // which lives in tor's own directory at mode 600 and never enters this store.
            else -> emptySet()
        }
    }
    
    /**
     * Force reload from disk (bypasses cache).
     */
    @JvmStatic
    fun forceReload(): JSONObject {
        synchronized(this) {
            cachedConfig = null
            lastModified.set(0)
            return loadConfig()
        }
    }
    
    /**
     * Get the config file path (for debugging).
     */
    @JvmStatic
    fun getConfigPath(): String = canonicalPath
    
    /**
     * Check if config file exists.
     */
    @JvmStatic
    fun configExists(): Boolean = File(canonicalPath).exists() ||
        File(appFilesPath).exists() ||
        File(mirrorPath).exists()
    
    /**
     * Get last modified timestamp.
     */
    @JvmStatic
    fun getLastModified(): Long {
        val primary = File(canonicalPath)
        if (primary.exists()) return primary.lastModified()
        val appFiles = File(appFilesPath)
        if (appFiles.exists()) return appFiles.lastModified()
        val legacy = File(mirrorPath)
        return if (legacy.exists()) legacy.lastModified() else 0L
    }
}
