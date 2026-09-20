package net.bladewatch.app.server

import net.bladewatch.app.config.UnifiedConfigManager
import net.bladewatch.app.daemon.CameraDaemon
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.recording.RecordingPriority
import net.bladewatch.app.server.connect.ConnectException
import net.bladewatch.app.storage.StorageManager
import net.bladewatch.app.surveillance.GpuPipelineConfig
import net.bladewatch.app.telemetry.OverlayField
import net.bladewatch.app.telemetry.OverlayFieldSelectionResolver
import net.bladewatch.app.telemetry.RecordingOverlayType
import org.json.JSONArray
import org.json.JSONObject
import java.io.BufferedReader
import java.io.File
import java.io.FileReader
import java.util.Locale
import kotlin.math.abs
import kotlin.math.roundToLong

/**
 * Recording and streaming quality settings, plus the storage limits, behind `SettingsService` and
 * `StorageService`.
 *
 * BladeWatch-6mnq: this was a REST handler matching /api/settings/ paths and writing JSON into an
 * OutputStream that the Connect layer captured straight back out. Every operation an RPC still
 * reaches now RETURNS its JSON.
 *
 * Deleted with the dispatch: the /api/settings/unified pair and the telemetry-overlay settings
 * pair had no RPC at all, and the status-overlay pair plus the telemetry-overlay FIELDS reader
 * were SUPERSEDED in BladeWatch-qwqq, which implemented them directly in SettingsServiceImpl.
 * Keeping those would have left two implementations of the same setting, which is how
 * GetSohNominal came to contradict GetSohStatus.
 */
object QualitySettingsApiHandler {

    private val logger: DaemonLogger = DaemonLogger.getInstance("QualitySettingsApiHandler")

    // Single user-facing recording quality tier (ECONOMY/STANDARD/HIGH/PREMIUM/MAX). Persisted in
    // UnifiedConfigManager under recording.recordingQuality. Default STANDARD on first load —
    // legacy values reset per the migration policy.
    private var recordingQuality = "STANDARD"

    /** Mirrors [recordingQuality]; kept until the persistence migration completes. */
    @Deprecated("mirrors recordingQuality")
    private var recordingBitrate = "STANDARD"

    // H264 only — HEVC playback isn't supported by the video player.
    private var recordingCodec = "H264"

    private const val UNIFIED_CONFIG_FILE = "/data/local/tmp/bladewatch_config.json"
    private const val LEGACY_SETTINGS_FILE = "/data/local/tmp/camera_settings.json"

    /**
     * The saved theme + locale preferences for the WEB UI (not the Android app). Defaults to
     * theme=dark / locale=auto so first-load matches the design system.
     *
     * `locale` here is the web-only language pick. The Android app's locale lives in
     * [LocaleManager] and is round-tripped through SettingsService.Get/SetLocale. Keeping these
     * separate is what stops picking Hindi on the tunnel from also flipping the in-car app.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun getAppearance(): JSONObject {
        val app = UnifiedConfigManager.getAppearance()
        val response = JSONObject()
        response.put("success", true)
        response.put("theme", app.optString("theme", "dark"))
        response.put("locale", app.optString("locale", "auto"))
        return response
    }

    /**
     * Body: `{ "theme": "dark"|"light"|"auto", "locale": "<bcp47>"|"auto" }`. Either field may be
     * omitted (partial update). theme is validated to one of three strings; locale is validated
     * against [LocaleManager]'s supported set (with the "auto" sentinel allowed). Persists into
     * the appearance section of the unified config, NOT into LocaleManager.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun setAppearance(body: String?): JSONObject {
        val response = JSONObject()
        try {
            val req = JSONObject(body ?: "{}")
            val app = JSONObject()
            val theme = req.optString("theme", null)
            if (theme != null) {
                if ("dark" != theme && "light" != theme && "auto" != theme) {
                    response.put("success", false)
                    response.put("error", "theme must be one of: dark, light, auto")
                    return response
                }
                app.put("theme", theme)
            }
            val locale = req.optString("locale", null)
            if (locale != null) {
                if ("auto" != locale && !LocaleManager.isSupported(locale)) {
                    response.put("success", false)
                    response.put("error", "locale must be 'auto' or one of the supported tags")
                    return response
                }
                app.put("locale", locale)
            }
            response.put("success", UnifiedConfigManager.setAppearance(app))
            if (theme != null) response.put("theme", theme)
            if (locale != null) response.put("locale", locale)
        } catch (e: Exception) {
            response.put("success", false)
            response.put("error", e.message)
        }
        return response
    }

    /** Storage limit settings. */
    @JvmStatic
    @Throws(Exception::class)
    fun getStorageSettings(): JSONObject {
        val storage = StorageManager.getInstance()

        // Refresh SD card detection if it is not currently available: this handles the case where
        // the card was inserted after app start.
        if (!storage.isSdCardAvailable) {
            storage.refreshSdCard()
        }

        val response = JSONObject()
        response.put("success", true)
        response.put("recordingsLimitMb", storage.recordingsLimitMb)
        response.put("surveillanceLimitMb", storage.surveillanceLimitMb)
        response.put("minLimitMb", StorageManager.getMinLimitMb())
        response.put("maxLimitMb", StorageManager.getMaxLimitMb())
        response.put("maxLimitMbSdCard", StorageManager.getMaxLimitMbSdCard())
        response.put("recordingsPath", storage.recordingsPath)
        response.put("surveillancePath", storage.surveillancePath)
        response.put("recordingsSize", storage.recordingsSize)
        response.put("surveillanceSize", storage.surveillanceSize)
        response.put("recordingsCount", storage.recordingsCount)
        response.put("surveillanceCount", storage.surveillanceCount)

        // Storage type selection
        response.put("recordingsStorageType", storage.recordingsStorageType.name)
        response.put("surveillanceStorageType", storage.surveillanceStorageType.name)

        // SD card info
        response.put("sdCardAvailable", storage.isSdCardAvailable)
        response.put("sdCardPath", storage.sdCardPath)
        if (storage.isSdCardAvailable) {
            response.put("sdCardFreeSpace", storage.sdCardFreeSpace)
            response.put("sdCardTotalSpace", storage.sdCardTotalSpace)
            response.put(
                "sdCardFreeFormatted", StorageManager.formatSize(storage.sdCardFreeSpace)
            )
            response.put(
                "sdCardTotalFormatted", StorageManager.formatSize(storage.sdCardTotalSpace)
            )
        }

        // Internal storage info
        response.put("internalFreeSpace", storage.internalFreeSpace)
        response.put("internalTotalSpace", storage.internalTotalSpace)
        response.put(
            "internalFreeFormatted", StorageManager.formatSize(storage.internalFreeSpace)
        )
        response.put(
            "internalTotalFormatted", StorageManager.formatSize(storage.internalTotalSpace)
        )

        // Boot-time SD card mount failure (see StorageManager.resolveSdCardAutoPriority)
        response.put("sdCardMountFailed", storage.isSdCardMountFailedAtBoot)
        response.put("sdCardMountError", storage.sdCardMountErrorMessage)

        return response
    }

    /** Apply storage limit and storage-type changes. */
    @JvmStatic
    @Throws(Exception::class)
    fun setStorageSettings(body: String?): JSONObject {
        try {
            val settings = JSONObject(body)
            val storage = StorageManager.getInstance()

            // Handle storage type changes first (before limit changes)
            var storageTypeChanged = false

            if (settings.has("recordingsStorageType")) {
                val typeStr = settings.getString("recordingsStorageType").uppercase(Locale.ROOT)
                val type = if ("SD_CARD" == typeStr) {
                    StorageManager.StorageType.SD_CARD
                } else {
                    StorageManager.StorageType.INTERNAL
                }
                if (storage.setRecordingsStorageType(type)) {
                    storageTypeChanged = true
                    CameraDaemon.log("Recordings storage type set to: $type")
                } else {
                    CameraDaemon.log(
                        "Failed to set recordings storage type to SD_CARD - not available"
                    )
                }
            }

            if (settings.has("surveillanceStorageType")) {
                val typeStr = settings.getString("surveillanceStorageType").uppercase(Locale.ROOT)
                val type = if ("SD_CARD" == typeStr) {
                    StorageManager.StorageType.SD_CARD
                } else {
                    StorageManager.StorageType.INTERNAL
                }
                if (storage.setSurveillanceStorageType(type)) {
                    storageTypeChanged = true
                    CameraDaemon.log("Surveillance storage type set to: $type")

                    // Update the running sentry engine's output directory to match the new storage
                    try {
                        val sentry = CameraDaemon.getGpuPipeline()?.sentry
                        if (sentry != null) {
                            sentry.setEventOutputDir(storage.surveillanceDir)
                            CameraDaemon.log(
                                "Updated sentry output dir: " +
                                    storage.surveillanceDir.absolutePath
                            )
                        }
                    } catch (e: Exception) {
                        CameraDaemon.log(
                            "Warning: could not update sentry output dir: " + e.message
                        )
                    }
                } else {
                    CameraDaemon.log(
                        "Failed to set surveillance storage type to SD_CARD - not available"
                    )
                }
            }

            // Calculate exactly what will be deleted before applying the changes
            // (BladeWatch-gyg1.4: the real selection algorithm via
            // StorageManager.previewXLimitChange, not an average-file-size estimate — computed
            // against today's files, before the limit write below, matching this method's
            // pre-existing "impact, then apply" order).
            var recordingsImpact: StorageManager.CleanupImpact? = null
            var surveillanceImpact: StorageManager.CleanupImpact? = null

            if (settings.has("recordingsLimitMb")) {
                val newLimit = settings.getLong("recordingsLimitMb")
                val impact = storage.previewRecordingsLimitChange(newLimit)
                if (impact.fileCount > 0) recordingsImpact = impact
                storage.recordingsLimitMb = newLimit
                CameraDaemon.log("Recordings limit set to: " + newLimit + " MB")
            }

            if (settings.has("surveillanceLimitMb")) {
                val newLimit = settings.getLong("surveillanceLimitMb")
                val impact = storage.previewSurveillanceLimitChange(newLimit)
                if (impact.fileCount > 0) surveillanceImpact = impact
                storage.surveillanceLimitMb = newLimit
                CameraDaemon.log("Surveillance limit set to: " + newLimit + " MB")
            }

            // Run cleanup async so the response isn't blocked
            Thread({
                storage.runCleanup()
                CameraDaemon.log("Storage cleanup completed after limit change")
            }, "StorageLimitCleanup").start()

            val response = JSONObject()
            response.put("success", true)
            response.put("recordingsLimitMb", storage.recordingsLimitMb)
            response.put("surveillanceLimitMb", storage.surveillanceLimitMb)
            response.put("recordingsStorageType", storage.recordingsStorageType.name)
            response.put("surveillanceStorageType", storage.surveillanceStorageType.name)
            response.put("recordingsPath", storage.recordingsPath)
            response.put("surveillancePath", storage.surveillancePath)

            // Include the real (not estimated) impact in the response — BladeWatch-gyg1.4.
            if (recordingsImpact != null) {
                response.put("recordingsImpact", impactJson(recordingsImpact))
            }
            if (surveillanceImpact != null) {
                response.put("surveillanceImpact", impactJson(surveillanceImpact))
            }
            if (recordingsImpact != null || surveillanceImpact != null) {
                response.put(
                    "message",
                    Messages.get("messages.quality_storage_settings_updated_cleanup")
                )
            } else if (storageTypeChanged) {
                response.put("message", Messages.get("messages.quality_storage_location_changed"))
            } else {
                response.put("message", Messages.get("messages.quality_storage_settings_updated"))
            }

            return response
        } catch (e: Exception) {
            CameraDaemon.log("Error setting storage limits: " + e.message)
            throw ConnectException("internal", e.message ?: "An internal error occurred")
        }
    }

    /**
     * BladeWatch-gyg1.4: computes and returns exactly what a proposed recordings/surveillance
     * limit would delete, using [StorageManager]'s real selection algorithm against today's files.
     * A separate, read-only operation from [setStorageSettings] — deliberately not a flag on it —
     * so a caller previewing a change can be certain nothing was written and no cleanup ran,
     * without having to trust that a flag was honoured.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun previewStorageLimitChange(body: String?): JSONObject {
        try {
            val settings = JSONObject(body)
            val storage = StorageManager.getInstance()

            val response = JSONObject()
            response.put("success", true)

            if (settings.has("recordingsLimitMb")) {
                response.put(
                    "recordingsImpact",
                    impactJson(
                        storage.previewRecordingsLimitChange(
                            settings.getLong("recordingsLimitMb")
                        )
                    )
                )
            }
            if (settings.has("surveillanceLimitMb")) {
                response.put(
                    "surveillanceImpact",
                    impactJson(
                        storage.previewSurveillanceLimitChange(
                            settings.getLong("surveillanceLimitMb")
                        )
                    )
                )
            }

            return response
        } catch (e: Exception) {
            CameraDaemon.log("Error previewing storage limit change: " + e.message)
            throw ConnectException("internal", e.message ?: "An internal error occurred")
        }
    }

    @Throws(Exception::class)
    private fun impactJson(impact: StorageManager.CleanupImpact): JSONObject {
        val json = JSONObject()
        json.put("fileCount", impact.fileCount)
        json.put("totalBytes", impact.totalBytes)
        return json
    }

    @JvmStatic
    @Throws(Exception::class)
    fun getQuality(): JSONObject {
        val response = JSONObject()
        response.put("success", true)

        // Read from the unified config for cross-UID sync
        @Suppress("DEPRECATION")
        var currentBitrate = recordingBitrate
        var currentCodec = recordingCodec
        var currentRecQuality = recordingQuality
        var currentStreamQuality = StreamingApiHandler.getStreamingQuality()
        var lastModified = System.currentTimeMillis()

        try {
            val unifiedFile = File(UNIFIED_CONFIG_FILE)
            if (unifiedFile.exists()) {
                lastModified = unifiedFile.lastModified()

                val unified = JSONObject(readAllText(unifiedFile))

                val recording = unified.optJSONObject("recording")
                if (recording != null) {
                    val fileCodec = recording.optString("codec", "")
                    if (fileCodec == "H264" || fileCodec == "H265") {
                        currentCodec = fileCodec
                        recordingCodec = fileCodec
                    }

                    // Canonical tier first (recordingQuality → quality), then migrate legacy
                    // `bitrate` LOW/MEDIUM/HIGH as a final fallback. Old `quality` values
                    // (LOW/REDUCED/NORMAL) collapse to STANDARD.
                    val fileTier = recording.optString(
                        "recordingQuality", recording.optString("quality", "")
                    )
                    if (isKnownTier(fileTier)) {
                        currentRecQuality = fileTier
                        recordingQuality = fileTier
                        @Suppress("DEPRECATION")
                        recordingBitrate = fileTier
                    } else if (recording.has("bitrate")) {
                        val tier = legacyBitrateToTier(
                            recording.optString("bitrate", "").uppercase(Locale.ROOT)
                        )
                        if (tier.isNotEmpty()) {
                            currentRecQuality = tier
                            recordingQuality = tier
                            @Suppress("DEPRECATION")
                            recordingBitrate = tier
                        }
                    } else if (fileTier.isNotEmpty()) {
                        currentRecQuality = "STANDARD"
                        recordingQuality = "STANDARD"
                        @Suppress("DEPRECATION")
                        recordingBitrate = "STANDARD"
                    }
                    @Suppress("DEPRECATION")
                    currentBitrate = recordingBitrate
                }

                val streaming = unified.optJSONObject("streaming")
                if (streaming != null) {
                    val fileStreamQuality = streaming.optString("quality", "")
                    if (fileStreamQuality.isNotEmpty()) {
                        currentStreamQuality = fileStreamQuality
                        StreamingApiHandler.setStreamingQuality(fileStreamQuality)
                    }
                }
            }
        } catch (e: Exception) {
            CameraDaemon.log("sendQualitySettings: Could not read unified config: " + e.message)
        }

        // Single user-facing recording quality tier. Bundles bitrate + perceptual expectation.
        // FPS and codec stay independent. Any legacy LOW/REDUCED/NORMAL value migrates silently
        // to STANDARD.
        val tierFromConfig = try {
            UnifiedConfigManager.loadConfig().optJSONObject("recording")
                ?.optString("recordingQuality", null)
        } catch (e: Exception) {
            null
        }
        val activeTier = GpuPipelineConfig.RecordingQuality.fromString(tierFromConfig)

        response.put("recordingQuality", activeTier.name)
        response.put("streamingQuality", currentStreamQuality)
        response.put("recordingCodec", currentCodec)
        response.put("lastModified", lastModified)

        // Camera FPS setting
        var currentFps = 15
        try {
            val cameraConfig = UnifiedConfigManager.loadConfig().optJSONObject("camera")
            if (cameraConfig != null) {
                currentFps = cameraConfig.optInt("targetFps", 15)
            }
        } catch (e: Exception) {
            logger.warn("Failed to read camera targetFps, using default: " + e.message)
        }
        response.put("cameraFps", currentFps)

        // Per-file recording limit (minutes). Drives segment rotation in HardwareEventRecorderGpu
        // — recordings are split into files of this length. Options: 1, 5, 10. Default 5.
        var segMinutes = 5
        try {
            segMinutes = UnifiedConfigManager.getRecording().optInt("segmentMinutes", 5)
        } catch (e: Exception) {
            logger.warn("Failed to read recordingSegmentMinutes: " + e.message)
        }
        response.put("recordingSegmentMinutes", segMinutes)

        // PERFORMANCE/RELIABILITY (BladeWatch-gyg1.3) — caps the segment length above when
        // RELIABILITY, so an abrupt power loss loses at most one minute instead of up to
        // recordingSegmentMinutes. See RecordingPriority.
        var recPriority = RecordingPriority.RELIABILITY.name
        try {
            // The same read as HardwareEventRecorderGpu.loadSegmentDurationMs, so the reported
            // value and the enforced one cannot disagree.
            recPriority = RecordingPriority.fromConfigValue(
                UnifiedConfigManager.getRecording().optString("priority", null)
            ).name
        } catch (e: Exception) {
            logger.warn("Failed to read recordingPriority: " + e.message)
        }
        response.put("recordingPriority", recPriority)

        // Surface the measured FPS so the UI can show actualFps when the HAL clamps below the
        // request (e.g. the user picks 30, the HAL emits ~26 panoramic on this device). 0 means
        // "not measured yet" — the render loop only updates this every 2 minutes.
        try {
            val camera = CameraDaemon.getGpuPipeline()?.camera
            val measured = camera?.measuredFps ?: 0f
            if (measured > 0f) {
                response.put("cameraFpsActual", (measured * 10).roundToLong() / 10.0)
                if (abs(measured - currentFps) > 1.5f) {
                    response.put(
                        "cameraFpsClampNote",
                        "HAL emitting at ~" + measured.roundToLong() +
                            " fps (requested " + currentFps + ")"
                    )
                }
            }
        } catch (ignored: Exception) {
            logger.warn("Failed to query measured FPS: " + ignored.message)
        }

        // Recording quality tiers — the single user-facing knob. Includes per-tier bitrate
        // (resolved against the current codec) and a size estimate so the UI can show "X MB/min,
        // ~Y GB/hour". Note that bitrate is bandwidth-per-second: FPS does not change file size at
        // a fixed bitrate (higher fps just spreads bits over more frames, reducing per-frame
        // detail).
        val codecForEstimate = if ("H265".equals(currentCodec, ignoreCase = true)) {
            GpuPipelineConfig.VideoCodec.H265
        } else {
            GpuPipelineConfig.VideoCodec.H264
        }

        val qualityInfo = JSONObject()
        for (q in GpuPipelineConfig.RecordingQuality.values()) {
            val entry = JSONObject()
            val br = q.getBitrateForCodec(codecForEstimate)
            entry.put("displayName", q.displayName)
            entry.put("bitrateBps", br)
            entry.put("bitrateMbps", (br / 100_000.0).roundToLong() / 10.0)
            entry.put(
                "mbPerMinute", (q.estimateMbPerMinute(codecForEstimate) * 10).roundToLong() / 10.0
            )
            entry.put(
                "gbPerHour", (q.estimateMbPerHour(codecForEstimate) / 102.4).roundToLong() / 10.0
            )
            // Perceptual equivalent at the user's current fps. Drops one tier at 30 fps vs 15 fps
            // because the encoder spreads bits over more frames. The UI labels this as
            // approximate — native resolution is fixed at 2560x1920 regardless of tier.
            entry.put("qualityEquivalent", q.getQualityEquivalent(codecForEstimate, currentFps))
            qualityInfo.put(q.name, entry)
        }
        response.put("recordingQualityOptions", qualityInfo)
        response.put("nativeResolution", "2560×1920 mosaic · 4 × 1280×960 cameras")

        // Currently-active size estimate so the UI can render "uses ~X GB/hour at your current
        // settings" without iterating the options dict. Recomputed from active tier + active codec
        // on each call.
        val activeEstimate = JSONObject()
        val mbPerMin = activeTier.estimateMbPerMinute(codecForEstimate)
        activeEstimate.put(
            "bitrateMbps",
            (activeTier.getBitrateForCodec(codecForEstimate) / 100_000.0).roundToLong() / 10.0
        )
        activeEstimate.put("mbPerMinute", (mbPerMin * 10).roundToLong() / 10.0)
        activeEstimate.put("mbPer2Min", (mbPerMin * 2 * 10).roundToLong() / 10.0)
        activeEstimate.put("gbPerHour", (mbPerMin * 60 / 102.4).roundToLong() / 10.0)
        // Minutes of recording per 1 GB of storage — easier to reason about for a parked
        // surveillance session than fractional GB/hr numbers.
        if (mbPerMin > 0) {
            activeEstimate.put("minutesPerGb", (1024.0 / mbPerMin).roundToLong())
        }
        activeEstimate.put(
            "qualityEquivalent", activeTier.getQualityEquivalent(codecForEstimate, currentFps)
        )
        response.put("activeRecordingEstimate", activeEstimate)

        // Codec info for the UI
        val codecInfo = JSONObject()
        codecInfo.put("H264", "H.264/AVC (Compatible)")
        response.put("codecOptions", codecInfo)

        // FPS options for the UI. Range 10..30 — clamped server-side by
        // GpuSurveillancePipeline.applyFpsChange. The HAL on this device tops out around 26 fps
        // panoramic, so 30 clamps gracefully.
        val fpsInfo = JSONObject()
        fpsInfo.put("10", "10 FPS (Low power)")
        fpsInfo.put("15", "15 FPS (Balanced)")
        fpsInfo.put("20", "20 FPS (Smooth)")
        fpsInfo.put("25", "25 FPS (High motion)")
        fpsInfo.put("30", "30 FPS (Max — HAL ceiling ~26)")
        response.put("fpsOptions", fpsInfo)

        return response
    }

    @JvmStatic
    @Throws(Exception::class)
    fun setQuality(body: String?): JSONObject {
        try {
            val settings = JSONObject(body)

            if (settings.has("recordingQuality")) {
                val tier = settings.getString("recordingQuality").uppercase(Locale.ROOT)
                if (isKnownTier(tier)) {
                    recordingQuality = tier
                    CameraDaemon.log("Recording quality set to: $tier")
                    CameraDaemon.setRecordingQuality(tier)
                } else {
                    CameraDaemon.log(
                        "Rejecting recordingQuality=" + tier +
                            " — must be one of ECONOMY/STANDARD/HIGH/PREMIUM/MAX"
                    )
                }
            }

            if (settings.has("streamingQuality")) {
                val streamQuality = settings.getString("streamingQuality").uppercase(Locale.ROOT)
                if (streamQuality in STREAM_TIERS) {
                    StreamingApiHandler.setStreamingQuality(streamQuality)
                    CameraDaemon.log("Streaming quality set to: $streamQuality")
                    CameraDaemon.setStreamingQuality(streamQuality)
                }
            }

            // Legacy `recordingBitrate` key (LOW/MEDIUM/HIGH) — translated to the new tier
            // system. Clients should send `recordingQuality` directly going forward; this branch
            // only catches old ones.
            if (settings.has("recordingBitrate") && !settings.has("recordingQuality")) {
                val legacy = settings.getString("recordingBitrate").uppercase(Locale.ROOT)
                val tier = legacyBitrateToTier(legacy).ifEmpty { "STANDARD" }
                CameraDaemon.log(
                    "Legacy recordingBitrate=" + legacy + " → recordingQuality=" + tier
                )
                recordingQuality = tier
                CameraDaemon.setRecordingQuality(tier)
            }

            // Connect/proto clients send the proto json-name "codec"; the legacy web UI sends
            // "recordingCodec". Read whichever is present.
            if (settings.has("codec") || settings.has("recordingCodec")) {
                val codecKey = if (settings.has("codec")) "codec" else "recordingCodec"
                val codec = settings.getString(codecKey).uppercase(Locale.ROOT)
                if (codec == "H264") {
                    recordingCodec = codec
                    CameraDaemon.log("Recording codec set to: $codec")
                    CameraDaemon.setRecordingCodec(codec)
                }
            }

            if (settings.has("recordingPriority")) {
                val rawPriority = settings.getString("recordingPriority")
                if (rawPriority.isNotEmpty()) {
                    try {
                        // fromConfigValue never throws — an unrecognised name still saves a valid
                        // enum name (RELIABILITY) rather than rejecting the request.
                        val normalized = RecordingPriority.fromConfigValue(rawPriority).name
                        val rec = UnifiedConfigManager.loadConfig().optJSONObject("recording")
                            ?: JSONObject()
                        rec.put("priority", normalized)
                        UnifiedConfigManager.updateSection("recording", rec)
                        CameraDaemon.log(
                            "Recording priority set to: " + normalized +
                                " (applies to the next segment rotation)"
                        )
                    } catch (e: Exception) {
                        CameraDaemon.log("Failed to save recordingPriority: " + e.message)
                    }
                }
            }

            if (settings.has("recordingSegmentMinutes")) {
                val mins = settings.getInt("recordingSegmentMinutes")
                if (mins == 1 || mins == 5 || mins == 10) {
                    try {
                        val rec = UnifiedConfigManager.loadConfig().optJSONObject("recording")
                            ?: JSONObject()
                        rec.put("segmentMinutes", mins)
                        UnifiedConfigManager.updateSection("recording", rec)
                        CameraDaemon.log(
                            "Recording segment limit set to: " + mins +
                                " min (applies to the next recording)"
                        )
                    } catch (e: Exception) {
                        CameraDaemon.log("Failed to save recordingSegmentMinutes: " + e.message)
                    }
                } else {
                    CameraDaemon.log(
                        "Rejecting recordingSegmentMinutes=" + mins + " — must be 1, 5, or 10"
                    )
                }
            }

            // Connect/proto clients send the proto json-name "fps"; the legacy web UI sends
            // "cameraFps". Read whichever is present.
            if (settings.has("fps") || settings.has("cameraFps")) {
                val fps = settings.getInt(if (settings.has("fps")) "fps" else "cameraFps")
                if (fps < 10 || fps > 30) {
                    CameraDaemon.log("Rejecting cameraFps=" + fps + " — out of range [10..30]")
                } else {
                    // applyFpsChange persists to UnifiedConfig, propagates to the camera, and
                    // reinitialises the encoder so KEY_FRAME_RATE matches. No restart required —
                    // the change is live.
                    val pipeline = CameraDaemon.getGpuPipeline()
                    if (pipeline != null) {
                        pipeline.applyFpsChange(fps)
                        CameraDaemon.log("Camera FPS applied: $fps")
                    } else {
                        // Pipeline not yet created — persist so init() picks it up.
                        try {
                            val camCfg = UnifiedConfigManager.loadConfig()
                                .optJSONObject("camera") ?: JSONObject()
                            camCfg.put("targetFps", fps)
                            UnifiedConfigManager.updateSection("camera", camCfg)
                            CameraDaemon.log("Camera FPS saved (pipeline not ready): $fps")
                        } catch (e: Exception) {
                            CameraDaemon.log("Failed to save camera FPS: " + e.message)
                        }
                    }
                }
            }

            val response = JSONObject()
            response.put("success", true)
            @Suppress("DEPRECATION")
            response.put("recordingBitrate", recordingBitrate)
            response.put("recordingCodec", recordingCodec)
            response.put(
                "note",
                if (recordingCodec == "H265") Messages.get("messages.quality_h265_note") else null
            )

            persistSettings()

            return response
        } catch (e: Exception) {
            CameraDaemon.log("Error setting quality: " + e.message)
            throw ConnectException("internal", e.message ?: "An internal error occurred")
        }
    }

    /** Loads persisted settings from the unified config file. Called during HttpServer init. */
    @JvmStatic
    fun loadPersistedSettings() {
        // Try the unified config first
        try {
            val unifiedFile = File(UNIFIED_CONFIG_FILE)
            if (unifiedFile.exists()) {
                val unified = JSONObject(readAllText(unifiedFile))

                val recording = unified.optJSONObject("recording")
                if (recording != null) {
                    // Canonical tier: recordingQuality (ECONOMY..MAX). Fall back to legacy
                    // `quality` and finally legacy `bitrate` (LOW/MEDIUM/HIGH).
                    val tier = recording.optString(
                        "recordingQuality", recording.optString("quality", "")
                    )
                    if (isKnownTier(tier)) {
                        recordingQuality = tier
                        @Suppress("DEPRECATION")
                        recordingBitrate = tier // mirror — keep in sync
                        CameraDaemon.log("Restored recording tier from unified: $tier")
                    } else if (recording.has("bitrate")) {
                        val legacyBitrate = recording.getString("bitrate").uppercase(Locale.ROOT)
                        val migrated = legacyBitrateToTier(legacyBitrate)
                        if (migrated.isNotEmpty()) {
                            recordingQuality = migrated
                            @Suppress("DEPRECATION")
                            recordingBitrate = migrated
                            CameraDaemon.log(
                                "Migrated legacy bitrate=" + legacyBitrate +
                                    " → recordingQuality=" + migrated
                            )
                        }
                    }
                    if (recording.has("codec")) {
                        val codec = recording.getString("codec")
                        if (codec == "H264") {
                            recordingCodec = codec
                            CameraDaemon.log("Restored recording codec from unified: $codec")
                        }
                    }
                }

                val streaming = unified.optJSONObject("streaming")
                if (streaming != null && streaming.has("quality")) {
                    val quality = streaming.getString("quality")
                    StreamingApiHandler.setStreamingQuality(quality)
                    CameraDaemon.log("Restored streaming quality from unified: $quality")
                }

                CameraDaemon.log("Settings loaded from unified config: $UNIFIED_CONFIG_FILE")
                return
            }
        } catch (e: Exception) {
            CameraDaemon.log("Could not load from unified config: " + e.message)
        }

        // Fallback to the legacy settings file
        loadLegacySettings()
    }

    private fun loadLegacySettings() {
        try {
            val file = File(LEGACY_SETTINGS_FILE)
            CameraDaemon.log(
                "Loading settings from legacy: " + LEGACY_SETTINGS_FILE +
                    " (exists=" + file.exists() + ")"
            )
            if (file.exists()) {
                val settings = JSONObject(readAllText(file))

                // Canonical recordingQuality first; fall back to legacy bitrate.
                if (settings.has("recordingQuality")) {
                    val tier = settings.getString("recordingQuality").uppercase(Locale.ROOT)
                    if (isKnownTier(tier)) {
                        recordingQuality = tier
                        @Suppress("DEPRECATION")
                        recordingBitrate = tier
                    }
                } else if (settings.has("recordingBitrate")) {
                    val bitrate = settings.getString("recordingBitrate").uppercase(Locale.ROOT)
                    val tier = legacyBitrateToTier(bitrate)
                    if (tier.isNotEmpty()) {
                        recordingQuality = tier
                        @Suppress("DEPRECATION")
                        recordingBitrate = tier
                    }
                }
                if (settings.has("recordingCodec")) {
                    val codec = settings.getString("recordingCodec")
                    if (codec == "H264") {
                        recordingCodec = codec
                    }
                }
                if (settings.has("streamingQuality")) {
                    StreamingApiHandler.setStreamingQuality(
                        settings.getString("streamingQuality")
                    )
                }

                CameraDaemon.log("Settings loaded from legacy $LEGACY_SETTINGS_FILE")
                // Migrate to the unified config
                persistSettings()
            }
        } catch (e: Exception) {
            CameraDaemon.log("Could not load legacy settings: " + e.message)
        }
    }

    /**
     * Persists the current settings to the unified config file via UnifiedConfigManager.
     *
     * Routing through UCM (instead of doing direct file I/O) acquires the UCM lock, gets the
     * atomic-rename write semantics, and prevents this write from racing with concurrent
     * updateSection calls (e.g. a camera probe persisting its findings at the same time the user
     * clicks Save).
     */
    @JvmStatic
    fun persistSettings() {
        try {
            val recording = JSONObject()
            // Canonical tier; `quality` is the legacy mirror. We deliberately do NOT write
            // `bitrate` (LOW/MEDIUM/HIGH) — that is the field that historically drifted out of
            // sync with the active tier.
            recording.put("recordingQuality", recordingQuality)
            recording.put("quality", recordingQuality)
            recording.put("codec", recordingCodec)
            UnifiedConfigManager.updateSection("recording", recording)

            val streaming = JSONObject()
            streaming.put("quality", StreamingApiHandler.getStreamingQuality())
            UnifiedConfigManager.updateSection("streaming", streaming)

            CameraDaemon.log("Settings persisted via UnifiedConfigManager")
        } catch (e: Exception) {
            CameraDaemon.log("Could not persist settings: " + e.message)
        }
    }

    // Static getters for cross-component access
    @JvmStatic
    fun getRecordingQuality(): String = recordingQuality

    @Suppress("DEPRECATION")
    @JvmStatic
    fun getRecordingBitrate(): String = recordingBitrate

    @JvmStatic
    fun getRecordingCodec(): String = recordingCodec

    /**
     * Static setter for the app UI and IPC. Accepts the tier names (ECONOMY..MAX); legacy names
     * migrate to STANDARD per the migration policy, so old IPC clients are not silently swallowed.
     */
    @JvmStatic
    fun setRecordingQuality(quality: String?) {
        if (quality == null) return
        // Legacy LOW/REDUCED/NORMAL → STANDARD.
        val tier = if (isKnownTier(quality)) quality.uppercase(Locale.ROOT) else "STANDARD"
        recordingQuality = tier
        CameraDaemon.setRecordingQuality(tier)
        persistSettings()
    }

    @Deprecated("use setRecordingQuality with ECONOMY..MAX")
    @JvmStatic
    fun setRecordingBitrate(bitrate: String?) {
        if (bitrate == null) return
        val tier = legacyBitrateToTier(bitrate.uppercase(Locale.ROOT)).ifEmpty { "STANDARD" }
        setRecordingQuality(tier)
    }

    @JvmStatic
    fun setRecordingCodec(codec: String) {
        if (codec == "H264") {
            recordingCodec = codec
            CameraDaemon.setRecordingCodec(codec)
            persistSettings()
        }
    }

    /**
     * Static setter for the IPC server: updates the variable only, with no CameraDaemon call.
     * Accepts both the canonical tier names (ECONOMY..MAX) and legacy LOW/MEDIUM/HIGH.
     */
    @JvmStatic
    fun setRecordingBitrateStatic(value: String?) {
        if (value == null) return
        val v = value.uppercase(Locale.ROOT)
        val tier = when (v) {
            "LOW" -> "ECONOMY"
            "MEDIUM" -> "STANDARD"
            "HIGH", "ECONOMY", "STANDARD", "PREMIUM", "MAX" -> v
            else -> return
        }
        @Suppress("DEPRECATION")
        recordingBitrate = tier
        recordingQuality = tier
    }

    @JvmStatic
    fun setRecordingCodecStatic(codec: String) {
        if (codec == "H264") {
            recordingCodec = codec
        }
    }

    /**
     * Body: `{"type": "continuous"|"surveillance"|"proximity", "fields": ["SPEED", ...]}`.
     *
     * An unknown type is a bad request (there is a small, fixed set of recording types); an
     * unknown field NAME inside "fields" is silently dropped by
     * [OverlayFieldSelectionResolver.resolve], not here — mirroring how a persisted config file is
     * already treated by the reader.
     *
     * Note that the outer catch flattens the typed invalid_argument into internal. That is
     * pre-existing behaviour, kept rather than changed in passing.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun setTelemetryOverlayFields(body: String?): JSONObject {
        try {
            val req = JSONObject(body)
            val typeKey = req.optString("type", "")
            val type = RecordingOverlayType.values().firstOrNull { it.configKey == typeKey }
                ?: throw ConnectException(
                    "invalid_argument",
                    Messages.get("errors.telemetry_overlay_unknown_type_with_id", typeKey)
                )

            val fieldsArray = req.optJSONArray("fields")
                ?: throw ConnectException(
                    "invalid_argument", Messages.get("errors.telemetry_overlay_fields_missing")
                )
            // Reuse OverlayFieldSelectionResolver's own case-insensitive, unknown-name-dropping
            // match (the same logic a persisted config file is read with) instead of
            // re-implementing it here: wrap the incoming array in the same
            // {"fields": {type: [...]}} shape resolve() already parses, and read it straight back
            // out.
            val incomingShape = JSONObject()
                .put("fields", JSONObject().put(type.configKey, fieldsArray))
            val selection = OverlayFieldSelectionResolver.resolve(incomingShape, type)

            var overlayConfig = UnifiedConfigManager.getTelemetryOverlay()
            overlayConfig =
                OverlayFieldSelectionResolver.withSelection(overlayConfig, type, selection)
            UnifiedConfigManager.setTelemetryOverlay(overlayConfig)

            val response = JSONObject()
            response.put("success", true)
            val savedArray = JSONArray()
            for (field in selection) savedArray.put(field.name)
            response.put("fields", savedArray)
            return response
        } catch (e: Exception) {
            CameraDaemon.log("Error setting telemetry overlay fields: " + e.message)
            throw ConnectException("internal", e.message ?: "An internal error occurred")
        }
    }

    // ==================== HELPERS ====================

    private val STREAM_TIERS = setOf(
        "ULTRA_LOW", "LOW", "MEDIUM", "HIGH", "ULTRA_HIGH", "SMOOTH", "MAX", "LQ", "HQ"
    )

    private fun readAllText(f: File): String {
        val sb = StringBuilder()
        BufferedReader(FileReader(f)).use { reader ->
            while (true) {
                val line = reader.readLine() ?: break
                sb.append(line)
            }
        }
        return sb.toString()
    }

    /** "" when the value is not one of the three legacy bitrate names. */
    private fun legacyBitrateToTier(legacy: String): String = when (legacy) {
        "LOW" -> "ECONOMY"
        "MEDIUM" -> "STANDARD"
        "HIGH" -> "HIGH"
        else -> ""
    }

    /**
     * Validates a tier name without depending on the enum class: this handler runs in the daemon
     * process before the surveillance pipeline is built, so the check stays string-based and
     * cheap.
     */
    private fun isKnownTier(s: String?): Boolean = when (s?.uppercase(Locale.ROOT)) {
        "ECONOMY", "STANDARD", "HIGH", "PREMIUM", "MAX" -> true
        else -> false
    }
}
