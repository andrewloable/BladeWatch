package net.bladewatch.app.server

import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import net.bladewatch.app.camera.CameraFirmwareInfo
import net.bladewatch.app.config.UnifiedConfigManager
import net.bladewatch.app.daemon.CameraDaemon
import net.bladewatch.app.monitor.AccMonitor
import net.bladewatch.app.server.connect.ConnectException
import net.bladewatch.app.storage.StorageManager
import net.bladewatch.app.surveillance.SafeLocationManager
import net.bladewatch.app.surveillance.SurveillanceConfig
import net.bladewatch.app.surveillance.SurveillanceConfigManager
import net.bladewatch.app.surveillance.SurveillanceEngineGpu
import net.bladewatch.app.surveillance.SurveillanceSchedule
import org.json.JSONArray
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream
import java.util.Collections
import java.util.Locale
import kotlin.math.min
import kotlin.math.roundToLong

/**
 * Surveillance configuration and status, behind `SurveillanceService`.
 *
 * The distance slider (1-5) controls minObjectSize for the AI detection range; the sensitivity
 * slider (1-5) controls requiredBlocks for motion detection. Block size is LOCKED at 32 and never
 * changes.
 *
 * BladeWatch-6mnq: this was a REST handler matching /api/surveillance/ paths and writing JSON into
 * an OutputStream that the Connect layer captured straight back out. Every operation now RETURNS
 * its JSON, and the quadrant id is an argument rather than a path segment.
 */
object SurveillanceApiHandler {

    private const val UNIFIED_CONFIG_FILE = "/data/local/tmp/bladewatch_config.json"

    private val QUADRANT_KEYS = arrayOf("Q0", "Q1", "Q2", "Q3")

    /** What the old `HttpResponse.sendJsonSuccess` wrote. */
    @Throws(Exception::class)
    private fun successJson(): JSONObject {
        val resp = JSONObject()
        resp.put("success", true)
        return resp
    }

    /**
     * Reconcile the media catalog against the files on disk.
     *
     * Shares the single media DB with recordings, so this runs the full reconcile covering normal,
     * sentry and proximity. It lives in the surveillance namespace only because the surveillance
     * settings page has its own Sync button. The logic used to sit inline in the REST dispatch,
     * which is why it had no method of its own.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun reconcile(): JSONObject {
        val mcm = CameraDaemon.getMediaCatalogManager()
        if (mcm == null || !mcm.isAvailable) {
            val response = JSONObject()
            response.put("success", false)
            response.put("error", "catalog_unavailable")
            return response
        }
        return mcm.reconcile()
    }

    @JvmStatic
    @Throws(Exception::class)
    fun getConfig(): JSONObject {
        val gpuPipeline = CameraDaemon.getGpuPipeline()

        val response = JSONObject()
        response.put("success", true)

        val config = JSONObject()

        var sentryConfig: SurveillanceConfig? = null
        var sentry: SurveillanceEngineGpu? = null

        gpuPipeline?.sentry?.let { engine ->
            sentry = engine
            sentryConfig = engine.config
        }

        if (sentryConfig == null) {
            try {
                val configManager = SurveillanceConfigManager()
                if (configManager.configExists()) {
                    sentryConfig = configManager.loadConfig()
                }
            } catch (e: Exception) {
                CameraDaemon.log("Failed to load config: " + e.message)
            }
        }

        // Read the persisted preference (not the runtime state) for the UI toggle
        config.put("enabled", UnifiedConfigManager.isSurveillanceEnabled())

        if (sentryConfig != null) {
            config.put("sadThreshold", sentry?.sadThreshold ?: 0.05f)
            config.put("preRecordSeconds", sentryConfig.preRecordSeconds)
            config.put("postRecordSeconds", sentryConfig.postRecordSeconds)
            config.put("totalBlocks", sentry?.totalBlocks ?: 300)
            config.put("flashImmunity", sentryConfig.flashImmunity)
            config.put("aiEnabled", true)
            config.put("aiConfidence", sentryConfig.aiConfidence)
            config.put("minObjectSize", sentryConfig.minObjectSize)
            config.put("detectPerson", sentryConfig.isDetectPerson)
            config.put("detectCar", sentryConfig.isDetectCar)
            config.put("detectBike", sentryConfig.isDetectBike)

            // Distance preset and block settings
            config.put("distancePreset", sentryConfig.distancePreset.name)
            config.put("blockSize", sentryConfig.blockSize)
            config.put("maxDistanceM", sentryConfig.maxDistanceM)
            config.put("nightMode", sentryConfig.isNightMode)
            config.put("shadowThreshold", sentryConfig.shadowThreshold)
            config.put("densityThreshold", sentryConfig.densityThreshold)
            config.put("alarmBlockThreshold", sentryConfig.alarmBlockThreshold)

            // Sensitivity as a slider value (1-5) derived from requiredBlocks
            val reqBlocks = sentryConfig.requiredBlocks
            val sensitivityLevel = when {
                reqBlocks >= 4 -> 1 // Strict
                reqBlocks == 3 -> 2 // Conservative
                reqBlocks == 2 -> 3 // Default
                else -> 5 // Aggressive
            }
            config.put("sensitivity", sensitivityLevel)

            // Distance as a slider value (1-5) derived from minObjectSize
            val minSize = sentryConfig.minObjectSize
            val distanceLevel = when {
                minSize >= 0.22f -> 1 // ~3m (near)
                minSize >= 0.15f -> 2 // ~5m
                minSize >= 0.10f -> 3 // ~8m
                minSize >= 0.06f -> 4 // ~10m
                else -> 5 // ~15m (far)
            }
            config.put("distance", distanceLevel)
        } else {
            config.put("sadThreshold", 0.05f)
            config.put("sensitivity", 3) // Default slider value
            config.put("distance", 3) // Default slider value
            config.put("totalBlocks", 300)
            config.put("flashImmunity", 2)
            config.put("aiEnabled", true)
            config.put("aiConfidence", 0.4f)
            config.put("minObjectSize", 0.12f)
            config.put("detectPerson", true)
            config.put("detectCar", true)
            config.put("detectBike", true)
            config.put("preRecordSeconds", 5)
            config.put("postRecordSeconds", 10)
        }

        // Load recording settings from the unified config. The tier (recordingQuality:
        // ECONOMY/STANDARD/HIGH/PREMIUM/MAX) replaces the legacy recordingBitrate string. The
        // surveillance UI consumes recordingQuality; recordingBitrate is no longer surfaced.
        try {
            val recording = UnifiedConfigManager.getRecording()
            config.put(
                "recordingQuality",
                recording.optString("recordingQuality", recording.optString("quality", "STANDARD"))
            )
            config.put("recordingCodec", recording.optString("codec", "H264"))
        } catch (e: Exception) {
            config.put("recordingQuality", "STANDARD")
            config.put("recordingCodec", "H264")
        }

        try {
            val unifiedFile = File(UNIFIED_CONFIG_FILE)
            config.put(
                "lastModified",
                if (unifiedFile.exists()) unifiedFile.lastModified() else System.currentTimeMillis()
            )
        } catch (e: Exception) {
            config.put("lastModified", System.currentTimeMillis())
        }

        // Safe Location status
        val safeMgr = SafeLocationManager.getInstance()
        config.put("safeZoneSuppressed", CameraDaemon.isSafeZoneSuppressed())
        config.put("inSafeZone", safeMgr.isInSafeZone)
        config.put("safeZoneName", safeMgr.currentZoneName)

        // Deterrent action setting
        val survConfig = UnifiedConfigManager.getSurveillance()
        config.put("deterrentAction", survConfig.optString("deterrentAction", "silent"))
        config.put("deterrentCooldownSeconds", survConfig.optInt("deterrentCooldownSeconds", 60))

        // V2 Pipeline settings
        if (sentryConfig != null) {
            config.put("environmentPreset", sentryConfig.environmentPreset)
            config.put("sensitivityLevel", sentryConfig.sensitivityLevel)
            config.put("detectionZone", sentryConfig.detectionZone)
            config.put("loiteringTime", sentryConfig.loiteringTimeSeconds)
            val cameras = sentryConfig.cameraEnabled
            config.put("cameraFront", cameras[0])
            config.put("cameraRight", cameras[1])
            config.put("cameraRear", cameras[2])
            config.put("cameraLeft", cameras[3])
            config.put("motionHeatmap", sentryConfig.isMotionHeatmapEnabled)
            config.put("filterDebugLog", sentryConfig.isFilterDebugLogEnabled)
            config.put("shadowFilter", sentryConfig.shadowFilterMode)

            // Per-quadrant overrides (sensitivity / detection zone). Each entry is omitted when no
            // override is set (= inherit global).
            val overrides = JSONObject()
            for (q in 0 until 4) {
                val sens = sentryConfig.getQuadrantSensitivityOverride(q)
                val zone = sentryConfig.getQuadrantDetectionZoneOverride(q)
                if (sens != null || zone != null) {
                    val perQ = JSONObject()
                    if (sens != null) perQ.put("sensitivityLevel", sens.toInt())
                    if (zone != null) perQ.put("detectionZone", zone)
                    overrides.put(QUADRANT_KEYS[q], perQ)
                }
            }
            config.put("quadrantOverrides", overrides)

            // Schedule — read from the persisted config file (source of truth)
            try {
                val survCfg = UnifiedConfigManager.getSurveillance()
                config.put("scheduleEnabled", survCfg.optBoolean("scheduleEnabled", false))
                config.put(
                    "scheduleRules", survCfg.optJSONArray("scheduleRules") ?: JSONArray()
                )
            } catch (e: Exception) {
                // Fall back to the in-memory copy if the file read fails
                config.put("scheduleEnabled", sentryConfig.schedule.isEnabled)
                val schedRules = JSONArray()
                for (rule in sentryConfig.schedule.rules) {
                    schedRules.put(rule.toJson())
                }
                config.put("scheduleRules", schedRules)
            }

            // Camera ID info
            try {
                val camCfg = UnifiedConfigManager.loadConfig().optJSONObject("camera")
                if (camCfg != null) {
                    config.put("cameraId", camCfg.optInt("probedCameraId", -1))
                    config.put("cameraManualOverride", camCfg.optBoolean("manualOverride", false))
                    config.put("cameraLayout", camCfg.optInt("cameraLayout", -1))
                    config.put(
                        "cameraArbitrationMode",
                        camCfg.optString("arbitrationMode", "eventCallbackOnly")
                    )
                    config.put(
                        "cameraReprobeOnNextRestart",
                        camCfg.optBoolean("reprobeOnNextRestart", false)
                    )
                    config.put("cameraSourceBmmTag", camCfg.optString("sourceBmmTag", ""))
                    config.put("cameraDiscoveryMethod", camCfg.optString("discoveryMethod", ""))
                    config.put("cameraVehicleCamSort", camCfg.optString("vehicleCamSort", ""))
                    config.put(
                        "cameraFirmwareFingerprint", camCfg.optString("firmwareFingerprint", "")
                    )
                    config.put("cameraValidationSignal", camCfg.optString("validationSignal", ""))
                    config.put("cameraLayoutConfidence", camCfg.optString("layoutConfidence", ""))
                }
            } catch (ignored: Exception) {
                CameraDaemon.log("Failed to read camera config section: " + ignored.message)
            }
        } else {
            config.put("environmentPreset", "outdoor")
            config.put("sensitivityLevel", 3)
            config.put("detectionZone", "normal")
            config.put("loiteringTime", 3)
            config.put("cameraFront", true)
            config.put("cameraRight", true)
            config.put("cameraLeft", true)
            config.put("cameraRear", true)
            config.put("motionHeatmap", false)
            config.put("filterDebugLog", false)
            config.put("shadowFilter", 2)
        }

        response.put("config", config)
        return response
    }

    @JvmStatic
    @Throws(Exception::class)
    fun getStatus(): JSONObject {
        val response = JSONObject()
        response.put("success", true)
        response.put("status", JSONObject(CameraDaemon.getSurveillanceStatus()))
        return response
    }

    @JvmStatic
    @Throws(Exception::class)
    fun setConfig(body: String?): JSONObject {
        val gpuPipeline = CameraDaemon.getGpuPipeline()

        try {
            val configJson = JSONObject(body)

            val sentry: SurveillanceEngineGpu? = gpuPipeline?.sentry

            var sentryConfig: SurveillanceConfig? = sentry?.config
            if (sentryConfig == null) {
                sentryConfig = try {
                    val configManager = SurveillanceConfigManager()
                    if (configManager.configExists()) {
                        configManager.loadConfig()
                    } else {
                        SurveillanceConfig()
                    }
                } catch (e: Exception) {
                    SurveillanceConfig()
                }
            }

            var configChanged = false

            if (configJson.has("reprobeCameraOnNextRestart") &&
                configJson.optBoolean("reprobeCameraOnNextRestart", false)
            ) {
                try {
                    // Reprobe clears the trust chain but preserves manualOverride so a user can
                    // intentionally keep a hand-picked tuple.
                    val camCfg = JSONObject()
                    camCfg.put("reprobeOnNextRestart", true)
                    camCfg.put("probedCameraId", -1)
                    camCfg.put("probedSurfaceMode", -1)
                    camCfg.put("cameraLayout", -1)
                    camCfg.put("probedAndValidated", false)
                    camCfg.put("fallbackFromProbe", false)
                    camCfg.put("sourceBmmTag", "")
                    camCfg.put("discoveryMethod", "")
                    camCfg.put("vehicleCamSort", "")
                    camCfg.put("firmwareFingerprint", "")
                    camCfg.put("buildDisplay", "")
                    camCfg.put("buildIncremental", "")
                    camCfg.put("roBuildIncremental", "")
                    camCfg.put("productDevice", "")
                    camCfg.put("validatedAtMs", 0)
                    camCfg.put("validatedFrameWidth", 0)
                    camCfg.put("validatedFrameHeight", 0)
                    camCfg.put("validationFrameCount", 0)
                    camCfg.put("validationSignal", "")
                    camCfg.put("stripConfidence", "")
                    camCfg.put("layoutConfidence", "")
                    camCfg.put("lastValidationFailure", "reprobe_requested")
                    camCfg.put("nativeProbeReport", "")
                    camCfg.put("nativeProbeReady", false)
                    camCfg.put("fpsSetCameraResult", "")
                    camCfg.put("fpsSetMediaCodecResult", "")
                    camCfg.put("lastCameraEvent", "")
                    UnifiedConfigManager.updateSection("camera", camCfg)
                    CameraDaemon.log(
                        "Camera will reprobe on next restart (manual override preserved)"
                    )
                } catch (e: Exception) {
                    CameraDaemon.log("Failed to mark camera for reprobe: " + e.message)
                }
                configChanged = true
            }

            if (sentry != null && configJson.has("sadThreshold")) {
                sentry.sadThreshold = configJson.optDouble("sadThreshold", 0.05).toFloat()
            }

            if (configJson.has("preRecordSeconds")) {
                val v = configJson.optInt("preRecordSeconds", 5)
                sentryConfig.preRecordSeconds = v
                sentry?.preRecordSeconds = v
                configChanged = true
            }

            if (configJson.has("postRecordSeconds")) {
                val v = configJson.optInt("postRecordSeconds", 10)
                sentryConfig.postRecordSeconds = v
                sentry?.postRecordSeconds = v
                configChanged = true
            }

            if (configJson.has("sensitivity")) {
                // Sensitivity slider (1-5) — controls the motion detection thresholds.
                val sensVal = configJson.opt("sensitivity")
                if (sensVal is Number) {
                    val sensitivityLevel = sensVal.toInt()
                    if (sensitivityLevel in 1..5) {
                        // 1=Strict (req=4), 2=Conservative (req=3), 3=Default (req=2),
                        // 4=Sensitive (req=2), 5=Aggressive (req=1)
                        val requiredBlocks = when (sensitivityLevel) {
                            1 -> 4
                            2 -> 3
                            3 -> 2
                            4 -> 2
                            5 -> 1
                            else -> 2
                        }

                        val sensitivityPercent = sensitivityLevel * 20
                        sentryConfig.unifiedSensitivity = sensitivityPercent
                        sentryConfig.requiredBlocks = requiredBlocks

                        if (sentry != null) {
                            sentry.unifiedSensitivity = sensitivityPercent
                            sentry.setRequiredActiveBlocks(requiredBlocks)
                        }

                        configChanged = true
                        CameraDaemon.log(
                            String.format(
                                "Motion sensitivity set to level %d (%d%%, alarm=%d blocks)",
                                sensitivityLevel, sensitivityPercent, requiredBlocks
                            )
                        )
                    }
                }
                // Legacy string sensitivity ("LOW"/"MEDIUM"/"HIGH") is no longer supported
            }

            // AI detection settings
            if (configJson.has("aiConfidence")) {
                sentryConfig.aiConfidence = configJson.optDouble("aiConfidence", 0.4).toFloat()
                configChanged = true
            }
            if (configJson.has("minObjectSize")) {
                sentryConfig.minObjectSize = configJson.optDouble("minObjectSize", 0.12).toFloat()
                configChanged = true
            }
            if (configJson.has("detectPerson")) {
                sentryConfig.isDetectPerson = configJson.optBoolean("detectPerson", true)
                configChanged = true
            }
            if (configJson.has("detectCar")) {
                sentryConfig.isDetectCar = configJson.optBoolean("detectCar", true)
                configChanged = true
            }
            if (configJson.has("detectBike")) {
                sentryConfig.isDetectBike = configJson.optBoolean("detectBike", true)
                configChanged = true
            }

            // Apply the object filters to the running engine
            if (sentry != null && configChanged) {
                sentry.setObjectFilters(
                    sentryConfig.minObjectSize,
                    sentryConfig.aiConfidence,
                    sentryConfig.isDetectPerson,
                    sentryConfig.isDetectCar,
                    sentryConfig.isDetectBike
                )
            }

            // Flash immunity setting
            if (configJson.has("flashImmunity")) {
                val v = configJson.optInt("flashImmunity", 2)
                sentryConfig.flashImmunity = v
                sentry?.flashImmunity = v
                configChanged = true
            }

            // Deterrent action setting (silent / flash_lights / find_car)
            if (configJson.has("deterrentAction")) {
                val action = configJson.optString("deterrentAction", "silent")
                if ("silent" == action || "flash_lights" == action || "find_car" == action) {
                    UnifiedConfigManager.updateValues(
                        "surveillance", Collections.singletonMap("deterrentAction", action)
                    )
                    CameraDaemon.log("Deterrent action set to: $action")
                }
            }

            if (configJson.has("deterrentCooldownSeconds")) {
                val cooldown = configJson.optInt("deterrentCooldownSeconds", 60)
                if (cooldown in 10..600) {
                    UnifiedConfigManager.updateValues(
                        "surveillance",
                        Collections.singletonMap("deterrentCooldownSeconds", cooldown)
                    )
                }
            }

            // Distance slider (1-5) — ONLY controls minObjectSize (the AI detection range).
            // Motion sensitivity (requiredBlocks, densityThreshold) is handled separately.
            if (configJson.has("distance") || configJson.has("distancePreset")) {
                val distanceStr = if (configJson.has("distance")) {
                    configJson.optString("distance", "3")
                } else {
                    configJson.optString("distancePreset", "MEDIUM")
                }

                CameraDaemon.log("Distance field received: $distanceStr")

                // Map the distance to minObjectSize for AI detection
                val minObjSize: Float
                val distanceLabel: String

                val distanceValue = distanceStr.toIntOrNull()
                if (distanceValue != null) {
                    if (distanceValue <= 5) {
                        // Slider index mapping (1-5): 1 = Close (~3m, 25%), 2 = Near (~5m, 18%),
                        // 3 = Medium (~8m, 12%), 4 = Far (~10m, 8%), 5 = Very Far (~15m, 5%)
                        when (distanceValue) {
                            1 -> { minObjSize = 0.25f; distanceLabel = "CLOSE (~3m)" }
                            2 -> { minObjSize = 0.18f; distanceLabel = "NEAR (~5m)" }
                            3 -> { minObjSize = 0.12f; distanceLabel = "MEDIUM (~8m)" }
                            4 -> { minObjSize = 0.08f; distanceLabel = "FAR (~10m)" }
                            5 -> { minObjSize = 0.05f; distanceLabel = "VERY_FAR (~15m)" }
                            else -> { minObjSize = 0.12f; distanceLabel = "MEDIUM (~8m)" }
                        }
                        CameraDaemon.log(
                            "Distance slider index " + distanceValue + " mapped to: " +
                                distanceLabel
                        )
                    } else {
                        // Treat it as an actual distance in metres (6m+)
                        when {
                            distanceValue <= 8 -> { minObjSize = 0.12f; distanceLabel = "MEDIUM (~8m)" }
                            distanceValue <= 12 -> { minObjSize = 0.08f; distanceLabel = "FAR (~10m)" }
                            else -> { minObjSize = 0.05f; distanceLabel = "VERY_FAR (~15m)" }
                        }
                        CameraDaemon.log(
                            "Distance " + distanceValue + "m mapped to: " + distanceLabel
                        )
                    }
                } else {
                    // Preset names (CLOSE, NEAR, MEDIUM, FAR, VERY_FAR)
                    when (distanceStr.uppercase(Locale.ROOT)) {
                        "CLOSE" -> { minObjSize = 0.25f; distanceLabel = "CLOSE (~3m)" }
                        "NEAR" -> { minObjSize = 0.18f; distanceLabel = "NEAR (~5m)" }
                        "FAR" -> { minObjSize = 0.08f; distanceLabel = "FAR (~10m)" }
                        "VERY_FAR" -> { minObjSize = 0.05f; distanceLabel = "VERY_FAR (~15m)" }
                        else -> { minObjSize = 0.12f; distanceLabel = "MEDIUM (~8m)" }
                    }
                    CameraDaemon.log("Distance preset name: $distanceLabel")
                }

                // Only update minObjectSize — don't touch the motion sensitivity settings
                sentryConfig.minObjectSize = minObjSize
                configChanged = true

                // Apply to the running engine if available
                sentry?.setObjectFilters(
                    minObjSize,
                    sentryConfig.aiConfidence,
                    sentryConfig.isDetectPerson,
                    sentryConfig.isDetectCar,
                    sentryConfig.isDetectBike
                )

                CameraDaemon.log(
                    String.format(
                        "Distance set: %s (minObjectSize=%.0f%%)", distanceLabel, minObjSize * 100
                    )
                )
            } else {
                CameraDaemon.log("No distance field in request - using existing config")
            }

            // Night mode toggle
            if (configJson.has("nightMode")) {
                val v = configJson.optBoolean("nightMode", false)
                sentryConfig.isNightMode = v
                sentry?.isNightMode = v
                configChanged = true
            }

            // V2 Motion Detection settings. These are persisted to SurveillanceConfig;
            // sentry.setConfig() below re-applies them to the live pipeline via
            // pipelineV2Config.applyConfig().
            if (configJson.has("environmentPreset")) {
                val preset = configJson.optString("environmentPreset", "outdoor")
                sentryConfig.environmentPreset = preset
                sentry?.applyV2EnvironmentPreset(preset)
                configChanged = true
            }
            if (configJson.has("sensitivityLevel")) {
                val level = configJson.optInt("sensitivityLevel", 3)
                sentryConfig.sensitivityLevel = level
                sentry?.applyV2Sensitivity(level)
                configChanged = true
            }
            if (configJson.has("detectionZone")) {
                sentryConfig.detectionZone = configJson.optString("detectionZone", "normal")
                configChanged = true
            }
            if (configJson.has("loiteringTime")) {
                val seconds = configJson.optInt("loiteringTime", 3)
                sentryConfig.loiteringTimeSeconds = seconds
                sentry?.setV2LoiteringTime(seconds)
                configChanged = true
            }
            if (configJson.has("shadowFilter")) {
                val mode = configJson.optInt("shadowFilter", 2)
                sentryConfig.shadowFilterMode = mode
                sentry?.setV2ShadowFilterMode(mode)
                configChanged = true
            }
            if (configJson.has("cameraFront") || configJson.has("cameraRight") ||
                configJson.has("cameraLeft") || configJson.has("cameraRear")
            ) {
                val existing = sentryConfig.cameraEnabled
                val front = configJson.optBoolean("cameraFront", existing[0])
                val right = configJson.optBoolean("cameraRight", existing[1])
                val rear = configJson.optBoolean("cameraRear", existing[2])
                val left = configJson.optBoolean("cameraLeft", existing[3])
                sentryConfig.setCameraEnabled(0, front)
                sentryConfig.setCameraEnabled(1, right)
                sentryConfig.setCameraEnabled(2, rear)
                sentryConfig.setCameraEnabled(3, left)
                if (sentry != null) {
                    sentry.setV2QuadrantEnabled(0, front)
                    sentry.setV2QuadrantEnabled(1, right)
                    sentry.setV2QuadrantEnabled(2, rear)
                    sentry.setV2QuadrantEnabled(3, left)
                }
                configChanged = true
            }
            if (configJson.has("quadrantOverrides")) {
                val overrides = configJson.optJSONObject("quadrantOverrides")
                for (q in 0 until 4) {
                    val perQ = overrides?.optJSONObject(QUADRANT_KEYS[q])
                    if (perQ == null) {
                        sentryConfig.setQuadrantSensitivityOverride(q, null)
                        sentryConfig.setQuadrantDetectionZoneOverride(q, null)
                    } else {
                        sentryConfig.setQuadrantSensitivityOverride(
                            q,
                            if (perQ.has("sensitivityLevel")) perQ.optInt("sensitivityLevel", 3)
                            else null
                        )
                        sentryConfig.setQuadrantDetectionZoneOverride(
                            q,
                            if (perQ.has("detectionZone")) perQ.optString("detectionZone", null)
                            else null
                        )
                    }
                }
                configChanged = true
            }
            if (configJson.has("motionHeatmap")) {
                sentryConfig.isMotionHeatmapEnabled =
                    configJson.optBoolean("motionHeatmap", false)
                configChanged = true
            }
            if (configJson.has("filterDebugLog")) {
                val v = configJson.optBoolean("filterDebugLog", false)
                sentryConfig.isFilterDebugLogEnabled = v
                sentry?.setFilterDebugEnabled(v)
                configChanged = true
            }
            // Surveillance schedule
            if (configJson.has("scheduleEnabled") || configJson.has("scheduleRules")) {
                try {
                    val schedule = sentryConfig.schedule
                    if (configJson.has("scheduleEnabled")) {
                        schedule.isEnabled = configJson.optBoolean("scheduleEnabled", false)
                    }
                    if (configJson.has("scheduleRules")) {
                        schedule.rules.clear()
                        val rulesArr = configJson.getJSONArray("scheduleRules")
                        for (i in 0 until rulesArr.length()) {
                            val rule = SurveillanceSchedule.Rule.fromJson(rulesArr.getJSONObject(i))
                            if (rule != null) schedule.rules.add(rule)
                        }
                    }
                    // Persist the schedule to the unified config
                    val survConfig = UnifiedConfigManager.getSurveillance()
                    val scheduleJson = schedule.toJson()
                    survConfig.put(
                        "scheduleEnabled", scheduleJson.optBoolean("scheduleEnabled", false)
                    )
                    survConfig.put("scheduleRules", scheduleJson.optJSONArray("scheduleRules"))
                    UnifiedConfigManager.setSurveillance(survConfig)
                    CameraDaemon.log("Schedule updated: " + schedule.summary)
                    configChanged = true

                    // IMMEDIATE ENFORCEMENT: if surveillance is currently active and the new
                    // schedule says we're outside the window, stop it now rather than waiting for
                    // the 5-minute periodic checker. Conversely, if surveillance is inactive and
                    // the schedule now allows it, start it (respecting the safe zone and the
                    // other gates).
                    if (schedule.isEnabled) {
                        val withinWindow = schedule.isActiveNow
                        val currentlyActive = sentry != null && sentry.isActive

                        if (!withinWindow && currentlyActive) {
                            CameraDaemon.log(
                                "SCHEDULE: Immediately stopping surveillance " +
                                    "(outside new schedule window)"
                            )
                            CameraDaemon.disableSurveillance()
                        } else if (withinWindow && !currentlyActive &&
                            !AccMonitor.isAccOn() && !CameraDaemon.isSafeZoneSuppressed()
                        ) {
                            CameraDaemon.log(
                                "SCHEDULE: Immediately enabling surveillance " +
                                    "(within new schedule window)"
                            )
                            CameraDaemon.enableSurveillance()
                        }
                    } else {
                        // Schedule just disabled — if surveillance was suppressed by the
                        // schedule, resume it now (respecting the safe zone and the ACC state).
                        val currentlyActive = sentry != null && sentry.isActive
                        if (!currentlyActive && !AccMonitor.isAccOn() &&
                            !CameraDaemon.isSafeZoneSuppressed() &&
                            UnifiedConfigManager.isSurveillanceEnabled()
                        ) {
                            CameraDaemon.log(
                                "SCHEDULE: Disabled — resuming surveillance immediately"
                            )
                            CameraDaemon.enableSurveillance()
                        }
                    }
                } catch (e: Exception) {
                    CameraDaemon.log("Schedule parse error: " + e.message)
                }
            }

            if (configJson.has("cameraArbitrationMode")) {
                val mode = configJson.optString("cameraArbitrationMode", "eventCallbackOnly")
                // Accept only the three supported arbitration modes. Anything else is ignored so
                // we do not accidentally flip the camera service into an unreviewed experiment
                // state.
                if ("polling" != mode && "eventCallbackOnly" != mode &&
                    "registeredUserExperiment" != mode
                ) {
                    CameraDaemon.log("Ignoring invalid cameraArbitrationMode: $mode")
                } else {
                    try {
                        // Update the live coordinator if it already exists, then persist the same
                        // value so the next restart reuses it.
                        val cameraPipeline = CameraDaemon.getGpuPipeline()
                        cameraPipeline?.camera?.setArbitrationMode(mode)
                        val camCfg = JSONObject()
                        camCfg.put("arbitrationMode", mode)
                        UnifiedConfigManager.updateSection("camera", camCfg)
                        CameraDaemon.log("Camera arbitration mode set to: $mode")
                    } catch (e: Exception) {
                        CameraDaemon.log("Failed to save camera arbitration mode: " + e.message)
                    }
                    configChanged = true
                }
            }

            // Manual camera ID override
            if (configJson.has("manualCameraId")) {
                val camId = configJson.optInt("manualCameraId", -1)
                if (camId in 0..5) {
                    try {
                        // A manual override stores a full tuple immediately so the next restart
                        // can reuse the selection without probing.
                        val layout = if (configJson.has("cameraLayout")) {
                            configJson.optInt("cameraLayout", 0)
                        } else {
                            CameraDaemon.log(
                                "Manual camera ID set without cameraLayout; assuming layout 0"
                            )
                            0
                        }
                        val firmware = CameraFirmwareInfo.current()
                        val camCfg = JSONObject()
                        camCfg.put("probedCameraId", camId)
                        camCfg.put("probedSurfaceMode", 0)
                        camCfg.put("cameraLayout", layout)
                        camCfg.put("probedAndValidated", true)
                        camCfg.put("manualOverride", true)
                        camCfg.put("fallbackFromProbe", false)
                        camCfg.put("reprobeOnNextRestart", false)
                        camCfg.put("sourceBmmTag", "manual")
                        camCfg.put("discoveryMethod", "manual")
                        camCfg.put("vehicleCamSort", firmware.vehicleCamSort)
                        camCfg.put("firmwareFingerprint", firmware.fingerprint)
                        camCfg.put("buildDisplay", firmware.buildDisplay)
                        camCfg.put("buildIncremental", firmware.buildIncremental)
                        camCfg.put("roBuildIncremental", firmware.roBuildIncremental)
                        camCfg.put("productDevice", firmware.device)
                        camCfg.put("validatedAtMs", 0)
                        camCfg.put("validatedFrameWidth", 0)
                        camCfg.put("validatedFrameHeight", 0)
                        camCfg.put("validationFrameCount", 0)
                        camCfg.put("validationSignal", "")
                        camCfg.put("stripConfidence", "")
                        camCfg.put("layoutConfidence", "")
                        camCfg.put("lastValidationFailure", "")
                        camCfg.put("nativeProbeReport", "")
                        camCfg.put("nativeProbeReady", false)
                        camCfg.put("fpsSetCameraResult", "")
                        camCfg.put("fpsSetMediaCodecResult", "")
                        camCfg.put("lastCameraEvent", "")
                        UnifiedConfigManager.updateSection("camera", camCfg)
                        CameraDaemon.log(
                            "Manual camera ID set: " + camId +
                                " (will take effect on next restart)"
                        )
                    } catch (e: Exception) {
                        CameraDaemon.log("Failed to save manual camera ID: " + e.message)
                    }
                    configChanged = true
                }
            }
            if (configJson.has("clearManualCameraId") &&
                configJson.optBoolean("clearManualCameraId", false)
            ) {
                try {
                    // Clear the whole selection tuple, not just the camera ID, so the next boot
                    // rediscovers from scratch instead of reusing stale camera metadata.
                    val camCfg = JSONObject()
                    camCfg.put("probedCameraId", -1)
                    camCfg.put("probedSurfaceMode", -1)
                    camCfg.put("cameraLayout", -1)
                    camCfg.put("probedAndValidated", false)
                    camCfg.put("manualOverride", false)
                    camCfg.put("fallbackFromProbe", false)
                    camCfg.put("reprobeOnNextRestart", false)
                    camCfg.put("sourceBmmTag", "")
                    camCfg.put("discoveryMethod", "")
                    camCfg.put("vehicleCamSort", "")
                    camCfg.put("firmwareFingerprint", "")
                    camCfg.put("buildDisplay", "")
                    camCfg.put("buildIncremental", "")
                    camCfg.put("roBuildIncremental", "")
                    camCfg.put("productDevice", "")
                    camCfg.put("validationSignal", "")
                    camCfg.put("stripConfidence", "")
                    camCfg.put("layoutConfidence", "")
                    camCfg.put("lastValidationFailure", "")
                    camCfg.put("validatedAtMs", 0)
                    camCfg.put("validatedFrameWidth", 0)
                    camCfg.put("validatedFrameHeight", 0)
                    camCfg.put("validationFrameCount", 0)
                    camCfg.put("nativeProbeReport", "")
                    camCfg.put("nativeProbeReady", false)
                    camCfg.put("fpsSetCameraResult", "")
                    camCfg.put("fpsSetMediaCodecResult", "")
                    camCfg.put("lastCameraEvent", "")
                    UnifiedConfigManager.updateSection("camera", camCfg)
                    CameraDaemon.log(
                        "Manual camera ID cleared — will auto-detect on next restart"
                    )
                } catch (e: Exception) {
                    CameraDaemon.log("Failed to clear manual camera ID: " + e.message)
                }
                configChanged = true
            }

            if (configChanged) {
                try {
                    // Apply the config to the running surveillance engine
                    sentry?.config = sentryConfig
                } catch (e: Exception) {
                    CameraDaemon.log("Failed to apply config: " + e.message)
                }

                // Persist to disk so settings survive ACC OFF/ON (pipeline.stop() sets
                // initialized=false, and the next start() reloads config from disk via
                // SurveillanceConfigManager.loadConfig() — without this save, every
                // detection/recording field reverts to the last persisted value on the next ACC
                // cycle).
                try {
                    SurveillanceConfigManager().saveConfig(sentryConfig)
                } catch (e: Exception) {
                    CameraDaemon.log("Failed to persist surveillance config: " + e.message)
                }
            }

            // Save the recording settings (quality tier, codec) to the unified config. Accepts
            // both the new `recordingQuality` (ECONOMY..MAX) and the legacy `recordingBitrate`
            // (LOW/MEDIUM/HIGH) for forward compat.
            if (configJson.has("recordingQuality") || configJson.has("recordingBitrate") ||
                configJson.has("recordingCodec")
            ) {
                try {
                    var recordingChanged = false
                    val recording = UnifiedConfigManager.getRecording()
                    var appliedTier: String? = null
                    if (configJson.has("recordingQuality")) {
                        appliedTier = configJson.optString("recordingQuality", "STANDARD")
                    } else if (configJson.has("recordingBitrate")) {
                        // Legacy path: translate LOW/MEDIUM/HIGH to a tier name and persist under
                        // the canonical key.
                        appliedTier = when (
                            configJson.optString("recordingBitrate", "MEDIUM")
                                .uppercase(Locale.ROOT)
                        ) {
                            "LOW" -> "ECONOMY"
                            "HIGH" -> "HIGH"
                            else -> "STANDARD"
                        }
                    }
                    if (appliedTier != null) {
                        recording.put("recordingQuality", appliedTier)
                        recording.put("quality", appliedTier) // mirror for legacy readers
                        // Drop the stale LOW/MEDIUM/HIGH so cross-channel readers don't see drift
                        recording.remove("bitrate")
                        recordingChanged = true
                        try {
                            CameraDaemon.setRecordingQuality(appliedTier)
                        } catch (e: Exception) {
                            CameraDaemon.log(
                                "Failed to apply recordingQuality to pipeline: " + e.message
                            )
                        }
                    }
                    if (configJson.has("recordingCodec")) {
                        val codec = configJson.optString("recordingCodec", "H264")
                        recording.put("codec", codec)
                        recordingChanged = true
                        // Apply to the running pipeline (takes effect on the next recording)
                        try {
                            CameraDaemon.setRecordingCodec(codec)
                        } catch (e: Exception) {
                            CameraDaemon.log("Failed to apply codec to pipeline: " + e.message)
                        }
                    }
                    if (recordingChanged) {
                        UnifiedConfigManager.setRecording(recording)
                        CameraDaemon.log(
                            "Recording settings saved: recordingQuality=" +
                                recording.optString("recordingQuality") +
                                ", codec=" + recording.optString("codec")
                        )
                    }
                } catch (e: Exception) {
                    CameraDaemon.log("Failed to save recording settings: " + e.message)
                }
            }

            return successJson()
        } catch (e: Exception) {
            CameraDaemon.log("Error applying surveillance config: " + e.message)
            throw ConnectException("internal", e.message ?: "An internal error occurred")
        }
    }

    @JvmStatic
    @Throws(Exception::class)
    fun enable(): JSONObject {
        // Only persist the preference. Surveillance should only activate on ACC OFF — starting
        // motion detection while driving wastes CPU/GPU and is meaningless.
        UnifiedConfigManager.setSurveillanceEnabled(true)

        // Only actually start surveillance if ACC is currently OFF (sentry mode)
        if (!AccMonitor.isAccOn()) {
            CameraDaemon.enableSurveillance()
        } else {
            CameraDaemon.log("Surveillance preference saved — will activate on next ACC OFF")
        }
        return successJson()
    }

    @JvmStatic
    @Throws(Exception::class)
    fun disable(): JSONObject {
        CameraDaemon.disableSurveillance()
        UnifiedConfigManager.setSurveillanceEnabled(false)
        return successJson()
    }

    /**
     * Per-quadrant block confidence data for the motion heatmap overlay.
     *
     * Response shape: `{ "quadrants": [{ "id", "name", "enabled", "suppressed", "meanLuma",
     * "activeBlocks", "confirmedBlocks", "threatLevel", "confidence": [...] }, ...],
     * "gridCols": 10, "gridRows": 7 }`.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun getHeatmap(): JSONObject {
        val gpuPipeline = CameraDaemon.getGpuPipeline()

        val response = JSONObject()
        response.put("gridCols", 10)
        response.put("gridRows", 7)

        // Include the current stream view mode so the UI knows whether to draw a 2x2 mosaic
        // heatmap or a single full-frame quadrant heatmap.
        // 0=Mosaic, 1=Front, 2=Right, 3=Rear, 4=Left, -1=No stream
        var viewMode = -1
        if (gpuPipeline != null) {
            if (gpuPipeline.isStreamingEnabled) {
                viewMode = gpuPipeline.streamViewMode
            }
            // If not streaming but surveillance is running, report the recording view.
            // Surveillance always records the mosaic, but the heatmap should show all quadrants
            // in a unified layout since there is no visible stream.
            if (viewMode < 0 && gpuPipeline.isSurveillanceMode) {
                viewMode = 0 // Mosaic (surveillance records all cameras)
            }
        }
        response.put("viewMode", viewMode)

        val quadrants = JSONArray()
        val names = arrayOf("front", "right", "left", "rear")

        val sentry = gpuPipeline?.sentry
        val results = sentry?.v2Results

        for (q in 0 until 4) {
            val qObj = JSONObject()
            qObj.put("id", q)
            qObj.put("name", names[q])

            val result = if (results != null) results[q] else null
            if (result != null) {
                qObj.put("enabled", true)
                qObj.put("suppressed", result.brightnessSuppressed)
                qObj.put("meanLuma", (result.meanLuma * 10).roundToLong() / 10.0)
                qObj.put("activeBlocks", result.activeBlocks)
                qObj.put("confirmedBlocks", result.confirmedBlocks)
                qObj.put("threatLevel", result.threatLevel)
                qObj.put("componentSize", result.componentSize)

                // Block confidence array (70 floats, rounded to 2 decimal places)
                val conf = JSONArray()
                for (c in result.blockConfidence) {
                    conf.put((c * 100).roundToLong() / 100.0)
                }
                qObj.put("confidence", conf)
            } else {
                qObj.put("enabled", false)
                qObj.put("suppressed", false)
            }

            quadrants.put(qObj)
        }

        response.put("quadrants", quadrants)
        return response
    }

    /** Recent filter debug log entries: a ring buffer of the last 100 decisions, newest first. */
    @JvmStatic
    @Throws(Exception::class)
    fun getFilterLog(): JSONObject {
        val sentry = CameraDaemon.getGpuPipeline()?.sentry

        val response = JSONObject()
        val entries = JSONArray()

        if (sentry != null) {
            for (entry in sentry.filterLogEntries) {
                if (entry != null) entries.put(entry)
            }
        }

        response.put("entries", entries)
        response.put("count", entries.length())
        return response
    }

    /**
     * The quadrant snapshot as JPEG BYTES, not JSON.
     *
     * This one is genuinely binary: `GetSnapshot` base64s it into the proto's `image_jpeg` field.
     * It used to write an `HTTP/1.1 200 OK` header with `Content-Type: image/jpeg` into the
     * stream, which the Connect layer then had to parse back apart to recover the payload.
     *
     * Strategy: try the live mosaic frame from the surveillance engine (available when sentry is
     * running), then fall back to extracting a frame from the most recent event video on disk.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun getQuadrantSnapshotJpeg(quadrant: Int): ByteArray {
        if (quadrant < 0 || quadrant > 3) {
            throw ConnectException(
                "invalid_argument",
                Messages.get("errors.surveillance_invalid_quadrant_with_id", quadrant)
            )
        }

        // Try the live mosaic frame first
        val mosaicRgb = CameraDaemon.getGpuPipeline()?.sentry?.latestMosaicFrame

        if (mosaicRgb != null) {
            // Live frame available — crop the quadrant from the 640x480 mosaic
            return cropQuadrantFromMosaic(mosaicRgb, quadrant, 640, 480)
        }

        // Fallback: extract a frame from the most recent event video on disk
        val frameBitmap = getFrameFromLatestEvent()
        if (frameBitmap != null) {
            try {
                // Event videos are mosaic (all 4 cameras) — crop the quadrant
                val qW = frameBitmap.width / 2
                val qH = frameBitmap.height / 2
                val startX = (quadrant % 2) * qW
                val startY = (quadrant / 2) * qH

                val cropped = Bitmap.createBitmap(frameBitmap, startX, startY, qW, qH)

                val jpegOut = ByteArrayOutputStream()
                cropped.compress(Bitmap.CompressFormat.JPEG, 80, jpegOut)
                if (cropped !== frameBitmap) cropped.recycle()
                frameBitmap.recycle()

                return jpegOut.toByteArray()
            } catch (e: Exception) {
                frameBitmap.recycle()
                throw ConnectException(
                    "internal",
                    Messages.get(
                        "errors.surveillance_event_frame_failed_with_detail", e.message
                    )
                )
            }
        }

        throw ConnectException("internal", Messages.get("errors.surveillance_no_frame_available"))
    }

    /** Crops a quadrant from a raw RGB mosaic byte array and encodes it as JPEG. */
    @Throws(Exception::class)
    private fun cropQuadrantFromMosaic(
        mosaicRgb: ByteArray,
        quadrant: Int,
        mosaicW: Int,
        mosaicH: Int
    ): ByteArray {
        val qW = mosaicW / 2
        val qH = mosaicH / 2
        val startX = (quadrant % 2) * qW
        val startY = (quadrant / 2) * qH

        val pixels = IntArray(qW * qH)
        for (y in 0 until qH) {
            for (x in 0 until qW) {
                val srcIdx = ((startY + y) * mosaicW + (startX + x)) * 3
                if (srcIdx + 2 < mosaicRgb.size) {
                    val r = mosaicRgb[srcIdx].toInt() and 0xFF
                    val g = mosaicRgb[srcIdx + 1].toInt() and 0xFF
                    val b = mosaicRgb[srcIdx + 2].toInt() and 0xFF
                    pixels[y * qW + x] = -0x1000000 or (r shl 16) or (g shl 8) or b
                }
            }
        }

        val bitmap = Bitmap.createBitmap(pixels, qW, qH, Bitmap.Config.ARGB_8888)

        val jpegOut = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.JPEG, 80, jpegOut)
        bitmap.recycle()

        return jpegOut.toByteArray()
    }

    /**
     * Extracts a frame from the most recent event video in the surveillance directory. Returns
     * null if no events exist.
     */
    private fun getFrameFromLatestEvent(): Bitmap? {
        try {
            val survDir = StorageManager.getInstance().surveillanceDir
            if (survDir == null || !survDir.exists()) return null

            val events = survDir.listFiles { _, name ->
                name.startsWith("event_") && name.endsWith(".mp4")
            }
            if (events == null || events.isEmpty()) return null

            // Sort by name descending (newest first — filenames contain the timestamp)
            events.sortWith { a, b -> b.name.compareTo(a.name) }

            // Try the most recent file, falling back to the next if extraction fails. Use the
            // FileDescriptor overload — setDataSource(String) NPEs on the headless daemon because
            // ActivityThread.currentApplication() is null.
            for (i in 0 until min(3, events.size)) {
                val retriever = MediaMetadataRetriever()
                try {
                    FileInputStream(events[i]).use { fis ->
                        retriever.setDataSource(fis.fd)
                        var frame = retriever.getFrameAtTime(
                            1000000, MediaMetadataRetriever.OPTION_CLOSEST_SYNC
                        )
                        if (frame == null) {
                            frame = retriever.getFrameAtTime(
                                0, MediaMetadataRetriever.OPTION_CLOSEST_SYNC
                            )
                        }
                        if (frame != null) return frame
                    }
                } catch (e: Exception) {
                    CameraDaemon.log(
                        "Failed to extract frame from " + events[i].name + ": " + e.message
                    )
                } finally {
                    try {
                        retriever.release()
                    } catch (ignored: Exception) {
                        CameraDaemon.log(
                            "Failed to release retriever in getFrameFromLatestEvent: " +
                                ignored.message
                        )
                    }
                }
            }
        } catch (e: Exception) {
            CameraDaemon.log("getFrameFromLatestEvent storage error: " + e.message)
        }
        return null
    }
}
