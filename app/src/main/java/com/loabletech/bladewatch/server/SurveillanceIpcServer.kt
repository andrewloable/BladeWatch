package net.bladewatch.app.server

import net.bladewatch.app.config.UnifiedConfigManager
import net.bladewatch.app.daemon.CameraDaemon
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.monitor.AccMonitor
import net.bladewatch.app.monitor.GpsMonitor
import net.bladewatch.app.monitor.VehicleDataMonitor
import net.bladewatch.app.recording.RecordingModeManager
import net.bladewatch.app.storage.StorageManager
import net.bladewatch.app.surveillance.SafeLocationManager
import net.bladewatch.app.surveillance.SurveillanceConfig
import net.bladewatch.app.surveillance.SurveillanceConfigManager
import net.bladewatch.app.surveillance.SurveillanceEngineGpu
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.PrintWriter
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.net.SocketTimeoutException
import java.util.Locale
import java.util.concurrent.Executors

/**
 * IPC server for surveillance configuration. Listens on port 19877 for surveillance config
 * commands from the app UI.
 *
 * Uses a thread pool rather than a thread per connection: IPC typically has fewer connections than
 * HTTP, so 8 threads is sufficient and prevents thread exhaustion under load.
 */
class SurveillanceIpcServer(private val port: Int) : Runnable {

    private var serverSocket: ServerSocket? = null

    @Volatile
    private var running = true

    private val threadPool = Executors.newFixedThreadPool(8)

    override fun run() {
        try {
            val socket = ServerSocket(port, 50, InetAddress.getByName("127.0.0.1"))
            serverSocket = socket
            logger.info("Surveillance IPC server listening on 127.0.0.1:$port")

            while (running) {
                try {
                    val client = socket.accept()
                    // Offload to the thread pool instead of spawning a new thread
                    threadPool.execute { handleClient(client) }
                } catch (e: Exception) {
                    if (running) {
                        logger.error("Error accepting client", e)
                    }
                }
            }
        } catch (e: Exception) {
            logger.error("Failed to start IPC server", e)
        }
    }

    private fun handleClient(client: Socket) {
        try {
            // Read timeout: a client that opens the socket and never sends a newline would
            // otherwise pin one of the worker threads forever. Eight half-open sockets (a
            // buggy/restarting daemon under load) exhaust the pool and the IPC server stops
            // accepting commands. 5s is plenty for localhost JSON traffic.
            client.soTimeout = 5000

            // Defence in depth: the IPC token is world-readable (644) by design, so verify the
            // connecting process's UID before handling any command. GET_VEHICLE_DATA (telemetry)
            // and UPDATE_GPS (GPS spoofing) are sensitive — only root/system/shell-daemon and the
            // BladeWatch app may reach them. Reject everything else.
            val peerUid = PeerCredentials.resolvePeerUid(client)
            if (!PeerCredentials.isTrusted(peerUid)) {
                logger.warn(
                    "Surveillance IPC rejected untrusted peer uid=" + peerUid +
                        " from " + client.remoteSocketAddress
                )
                closeQuietly(client)
                return
            }

            val input = BufferedReader(InputStreamReader(client.getInputStream()))
            val out = PrintWriter(client.getOutputStream(), true)

            val line = input.readLine()
            if (line != null) {
                out.println(handleCommand(JSONObject(line)).toString())
            }

            client.close()
        } catch (ste: SocketTimeoutException) {
            logger.warn("IPC client read timeout — closing socket")
            closeQuietly(client)
        } catch (e: Exception) {
            logger.error("Error handling client", e)
            closeQuietly(client)
        }
    }

    private fun closeQuietly(client: Socket) {
        try {
            client.close()
        } catch (ignored: Exception) {
            // Already closed, or the peer went away — nothing useful to do.
        }
    }

    private fun handleCommand(request: JSONObject): JSONObject {
        var response = JSONObject()

        // Require the shared-secret token on every request
        if (!IpcTokenManager.isValid(request.optString("token", ""))) {
            try {
                response.put("success", false)
                response.put("error", "Unauthorized")
            } catch (e: Exception) {
                logger.warn("Failed to build Unauthorized response: " + e.message)
            }
            return response
        }

        try {
            when (val command = request.optString("command", "")) {
                // ==================== APP UI COMMANDS ====================

                "ENABLE_SURVEILLANCE" -> {
                    // Persist the preference only — surveillance auto-starts on the next ACC OFF
                    UnifiedConfigManager.setSurveillanceEnabled(true)
                    logger.info(
                        "Surveillance preference set to ENABLED (will activate on ACC OFF)"
                    )
                    response.put("success", true)
                    response.put("enabled", true)
                }

                "DISABLE_SURVEILLANCE" -> {
                    // Persist the preference and stop if currently running
                    UnifiedConfigManager.setSurveillanceEnabled(false)
                    CameraDaemon.disableSurveillance()
                    logger.info("Surveillance preference set to DISABLED and stopped")
                    response.put("success", true)
                    response.put("enabled", false)
                }

                "GET_CONFIG" -> {
                    response.put("success", true)
                    response.put("config", getDefaultConfig())
                }

                "SET_CONFIG" -> {
                    request.optJSONObject("config")?.let { applyConfig(it) }
                    response.put("success", true)
                    response.put("message", "Config updated")
                }

                "GET_STATUS" -> {
                    response.put("success", true)
                    response.put("status", getSurveillanceStatus())
                }

                // ==================== VEHICLE DATA COMMANDS ====================

                "GET_VEHICLE_DATA" -> {
                    response.put("success", true)
                    response.put("data", VehicleDataMonitor.getInstance().getAllData())
                }

                "GET_BATTERY_VOLTAGE" -> {
                    response.put("success", true)
                    response.put("data", getBatteryVoltageData())
                }

                "GET_BATTERY_POWER" -> {
                    response.put("success", true)
                    response.put("data", getBatteryPowerData())
                }

                "GET_BATTERY_SOC" -> {
                    response.put("success", true)
                    response.put("data", getBatterySocData())
                }

                "GET_CHARGING_STATE" -> {
                    response.put("success", true)
                    response.put("data", getChargingStateData())
                }

                "GET_CHARGING_POWER" -> {
                    response.put("success", true)
                    response.put("data", getChargingPowerData())
                }

                "GET_DRIVING_RANGE" -> {
                    response.put("success", true)
                    response.put("data", getDrivingRangeData())
                }

                // ==================== SAFE LOCATION COMMANDS ====================

                "GET_SAFE_LOCATIONS" -> {
                    response = SafeLocationManager.getInstance().statusJson
                    response.put("success", true)
                }

                "ADD_SAFE_LOCATION" -> {
                    val zoneData = request.optJSONObject("zone")
                    if (zoneData != null) {
                        val zone = SafeLocationManager.getInstance().addZone(
                            zoneData.optString("name", "Unnamed"),
                            zoneData.optDouble("lat", 0.0),
                            zoneData.optDouble("lng", 0.0),
                            zoneData.optInt("radiusM", 150)
                        )
                        response.put("success", zone != null)
                        if (zone != null) {
                            response.put("zone", zone.toJson())
                        } else {
                            response.put("error", Messages.get("errors.zones_max_reached", 10))
                        }
                    } else {
                        response.put("success", false)
                        response.put("error", Messages.get("errors.zones_missing_data"))
                    }
                }

                "UPDATE_SAFE_LOCATION" -> {
                    val zoneId = request.optString("id", null)
                    val updates = request.optJSONObject("updates")
                    if (zoneId != null && updates != null) {
                        response.put(
                            "success",
                            SafeLocationManager.getInstance().updateZone(zoneId, updates)
                        )
                    } else {
                        response.put("success", false)
                        response.put("error", Messages.get("errors.missing_id_or_updates"))
                    }
                }

                "DELETE_SAFE_LOCATION" -> {
                    val zoneId = request.optString("id", null)
                    if (zoneId != null) {
                        response.put(
                            "success", SafeLocationManager.getInstance().removeZone(zoneId)
                        )
                    } else {
                        response.put("success", false)
                        response.put("error", Messages.get("errors.missing_id"))
                    }
                }

                "TOGGLE_SAFE_LOCATIONS" -> {
                    val enabled = request.optBoolean("enabled", true)
                    SafeLocationManager.getInstance().setFeatureEnabled(enabled)
                    response.put("success", true)
                    response.put("enabled", enabled)
                }

                // ==================== GPS SIDECAR COMMANDS ====================
                // GPS data from LocationSidecarService (the app writes via IPC, the daemon writes
                // to file).

                "UPDATE_GPS" -> {
                    handleGpsUpdate(request)
                    response.put("success", true)
                }

                // ==================== TELEMETRY OVERLAY COMMANDS ====================

                "SET_TELEMETRY_OVERLAY" -> {
                    val enabled = request.optBoolean("enabled", false)
                    UnifiedConfigManager.setTelemetryOverlay(
                        JSONObject().put("enabled", enabled)
                    )
                    // Notify the pipeline
                    CameraDaemon.getGpuPipeline()?.setOverlayEnabled(enabled)
                    response.put("success", true)
                    response.put("enabled", enabled)
                }

                "GET_TELEMETRY_OVERLAY" -> {
                    val overlayConfig = UnifiedConfigManager.getTelemetryOverlay()
                    response.put("success", true)
                    response.put("enabled", overlayConfig.optBoolean("enabled", true))
                }

                else -> {
                    logger.warn("Unknown IPC command: $command")
                    response.put("success", false)
                    response.put("error", Messages.get("errors.unknown_command", command))
                }
            }
        } catch (e: Exception) {
            logger.error("Error handling IPC command", e)
            try {
                response.put("success", false)
                response.put("error", e.message)
            } catch (ex: Exception) {
                logger.warn("Failed to build error response: " + ex.message)
            }
        }

        return response
    }

    /**
     * Apply configuration changes to the surveillance system. Updates both the running engine (if
     * available) AND persists to the config file — config is ALWAYS persisted even if surveillance
     * is not running.
     *
     * Serialised on [CONFIG_LOCK]: the IPC server runs an 8-thread pool; without serialisation,
     * two concurrent SET_CONFIG requests could each load, mutate and save their own snapshot,
     * losing the other's update. The lock is class-wide because the persisted file is shared
     * state, not instance state.
     */
    private fun applyConfig(config: JSONObject) {
        synchronized(CONFIG_LOCK) { applyConfigLocked(config) }
    }

    private fun applyConfigLocked(config: JSONObject) {
        try {
            val pipeline = CameraDaemon.getGpuPipeline()

            // Sentry may be null if surveillance is not running — that's OK
            val sentry: SurveillanceEngineGpu? = pipeline?.sentry

            // Get or create the SurveillanceConfig for persistence. Even if sentry is null, we
            // still want to persist the config.
            var sentryConfig: SurveillanceConfig? = sentry?.config
            if (sentryConfig == null) {
                sentryConfig = try {
                    val configManager = SurveillanceConfigManager()
                    if (configManager.configExists()) {
                        logger.info("Loaded existing config from file for update")
                        configManager.loadConfig()
                    } else {
                        logger.info("Created new config for persistence")
                        SurveillanceConfig()
                    }
                } catch (e: Exception) {
                    logger.error("Failed to load config, using defaults", e)
                    SurveillanceConfig()
                }
            }

            var configChanged = false

            // Surveillance storage type change (INTERNAL or SD_CARD)
            if (config.has("surveillanceStorageType")) {
                val typeStr =
                    config.getString("surveillanceStorageType").uppercase(Locale.ROOT)
                val storageManager = StorageManager.getInstance()
                val type = if ("SD_CARD" == typeStr) {
                    StorageManager.StorageType.SD_CARD
                } else {
                    StorageManager.StorageType.INTERNAL
                }
                if (storageManager.setSurveillanceStorageType(type)) {
                    logger.info("Surveillance storage type set to $type via IPC")
                    // Update sentry's event output directory if running
                    if (sentry != null) {
                        sentry.setEventOutputDir(storageManager.surveillanceDir)
                        logger.info(
                            "Updated sentry output dir: " +
                                storageManager.surveillanceDir.absolutePath
                        )
                    }
                } else {
                    logger.warn("Failed to set surveillance storage to SD_CARD - not available")
                }
            }

            // Surveillance storage limit change
            if (config.has("surveillanceLimitMb")) {
                val storageManager = StorageManager.getInstance()
                storageManager.surveillanceLimitMb = config.getLong("surveillanceLimitMb")
                logger.info(
                    "Surveillance limit set to " + storageManager.surveillanceLimitMb +
                        " MB via IPC"
                )
                // Trigger async cleanup
                Thread(
                    { storageManager.ensureSurveillanceSpace(0) }, "SurvLimitCleanup"
                ).start()
            }

            // Enabled state
            if (config.has("enabled")) {
                val enabled = config.getBoolean("enabled")
                // Persist to the unified config so ACC OFF respects the user preference
                UnifiedConfigManager.setSurveillanceEnabled(enabled)
                if (enabled) {
                    // RACE CONDITION FIX: only enable surveillance if ACC is actually OFF.
                    // AccSentryDaemon's retry loop may send this IPC after ACC turned ON.
                    if (!AccMonitor.isAccOn()) {
                        CameraDaemon.enableSurveillance()
                        logger.info("Surveillance enabled via IPC")
                    } else {
                        logger.info(
                            "Surveillance preference saved via IPC — but ACC is ON, not activating"
                        )
                    }
                } else {
                    CameraDaemon.disableSurveillance()
                    logger.info("Surveillance disabled via IPC")
                }
            }

            // Stop surveillance without persisting the preference (battery protection, session
            // stop)
            if (config.has("stopSurveillance") && config.getBoolean("stopSurveillance")) {
                CameraDaemon.disableSurveillance()
                logger.info("Surveillance stopped via IPC (preference preserved)")
            }

            // ACC state
            if (config.has("accOff")) {
                val accOff = config.getBoolean("accOff")
                CameraDaemon.onAccStateChanged(accOff)
                logger.info("ACC state changed via IPC: " + (if (accOff) "OFF" else "ON"))
            }

            // Gear state
            if (config.has("gear")) {
                val gear = config.getInt("gear")
                CameraDaemon.onGearChanged(gear)
                logger.info(
                    "Gear changed via IPC: " + RecordingModeManager.gearToString(gear)
                )
            }

            // Sensitivity setting (maps to minObjectSize)
            if (config.has("sensitivity")) {
                val sensitivity = config.optString("sensitivity", "MEDIUM").uppercase(Locale.ROOT)
                val minSize = when (sensitivity) {
                    "LOW" -> 0.02f // 2% - detect distant objects
                    "HIGH" -> 0.15f // 15% - only close objects
                    else -> 0.08f // 8% - balanced
                }
                val confidence =
                    config.optDouble("aiConfidence", sentryConfig.aiConfidence.toDouble())
                        .toFloat()
                val detectPerson = config.optBoolean("detectPerson", sentryConfig.isDetectPerson)
                val detectCar = config.optBoolean("detectCar", sentryConfig.isDetectCar)
                val detectBike = config.optBoolean("detectBike", sentryConfig.isDetectBike)

                // Apply to the running engine if available
                sentry?.setObjectFilters(minSize, confidence, detectPerson, detectCar, detectBike)

                // Update the config object for persistence
                sentryConfig.minObjectSize = minSize
                sentryConfig.aiConfidence = confidence
                sentryConfig.isDetectPerson = detectPerson
                sentryConfig.isDetectCar = detectCar
                sentryConfig.isDetectBike = detectBike
                configChanged = true

                logger.info(
                    "Sensitivity set to " + sensitivity + " (minObjectSize=" + minSize + ")"
                )
            }

            // Object detection filters (direct minObjectSize override)
            if (config.has("minObjectSize") || config.has("aiConfidence") ||
                config.has("detectPerson") || config.has("detectCar") ||
                config.has("detectBike")
            ) {
                val minSize =
                    config.optDouble("minObjectSize", sentryConfig.minObjectSize.toDouble())
                        .toFloat()
                val confidence =
                    config.optDouble("aiConfidence", sentryConfig.aiConfidence.toDouble())
                        .toFloat()
                val detectPerson = config.optBoolean("detectPerson", sentryConfig.isDetectPerson)
                val detectCar = config.optBoolean("detectCar", sentryConfig.isDetectCar)
                val detectBike = config.optBoolean("detectBike", sentryConfig.isDetectBike)

                // Apply to the running engine if available
                sentry?.setObjectFilters(minSize, confidence, detectPerson, detectCar, detectBike)

                // Update the config object for persistence
                sentryConfig.minObjectSize = minSize
                sentryConfig.aiConfidence = confidence
                sentryConfig.isDetectPerson = detectPerson
                sentryConfig.isDetectCar = detectCar
                sentryConfig.isDetectBike = detectBike
                configChanged = true

                logger.info(
                    "Object filters applied (sentry " +
                        (if (sentry != null) "running" else "not running") + ")"
                )
            }

            // Pre/post record seconds
            if (config.has("preRecordSeconds") || config.has("preEventBufferSeconds")) {
                val preRecordSeconds = if (config.has("preRecordSeconds")) {
                    config.optInt("preRecordSeconds", 5)
                } else {
                    config.optInt("preEventBufferSeconds", 5)
                }
                sentry?.preRecordSeconds = preRecordSeconds
                sentryConfig.preRecordSeconds = preRecordSeconds
                configChanged = true
                logger.info("Pre-record seconds set to: $preRecordSeconds")
            }

            if (config.has("postRecordSeconds") || config.has("postEventBufferSeconds")) {
                val postRecordSeconds = if (config.has("postRecordSeconds")) {
                    config.optInt("postRecordSeconds", 10)
                } else {
                    config.optInt("postEventBufferSeconds", 10)
                }
                sentry?.postRecordSeconds = postRecordSeconds
                sentryConfig.postRecordSeconds = postRecordSeconds
                configChanged = true
                logger.info("Post-record seconds set to: $postRecordSeconds")
            }

            // Recording quality / legacy bitrate setting. Prefer the canonical `recordingQuality`
            // (ECONOMY..MAX); accept the legacy `bitrate` (LOW/MEDIUM/HIGH) only as a fallback.
            var tierIn: String? = null
            if (config.has("recordingQuality")) {
                tierIn = config.optString("recordingQuality", "").uppercase(Locale.ROOT)
            } else if (config.has("bitrate")) {
                tierIn = when (config.optString("bitrate", "").uppercase(Locale.ROOT)) {
                    "LOW" -> "ECONOMY"
                    "MEDIUM" -> "STANDARD"
                    "HIGH" -> "HIGH"
                    else -> null
                }
            }
            if (!tierIn.isNullOrEmpty()) {
                CameraDaemon.setRecordingQuality(tierIn)
                // Legacy alias setter; takes any string
                HttpServer.setRecordingBitrateStatic(tierIn)
                logger.info("Recording quality set to: $tierIn")
            }

            // Codec setting
            if (config.has("codec")) {
                val codec = config.optString("codec", "H264").uppercase(Locale.ROOT)
                if (codec == "H264") {
                    CameraDaemon.setRecordingCodec(codec)
                    // Also update HttpServer's static setting for web UI sync
                    HttpServer.setRecordingCodecStatic(codec)
                    logger.info("Recording codec set to: $codec")
                }
            }

            // Persist recording settings to file so the web UI can read them
            if (config.has("recordingQuality") || config.has("bitrate") || config.has("codec")) {
                HttpServer.persistSettingsStatic()
            }

            // Flash immunity setting (0=OFF, 1=LOW, 2=MEDIUM, 3=HIGH)
            if (config.has("flashImmunity")) {
                val flashImmunity = config.optInt("flashImmunity", 2)
                sentry?.flashImmunity = flashImmunity
                sentryConfig.flashImmunity = flashImmunity
                configChanged = true
                logger.info("Flash immunity set to: $flashImmunity")
            }

            // Distance preset (1-5 slider value). Distance ONLY controls minObjectSize (the AI
            // detection range). Block size is LOCKED at 32; motion sensitivity is handled
            // separately.
            if (config.has("distance")) {
                // 1 = Close (~3m, 25%), 2 = Near (~5m, 18%), 3 = Medium (~8m, 12%),
                // 4 = Far (~10m, 8%), 5 = Very Far (~15m, 5%)
                val minObjectSize: Float
                val distanceLabel: String
                when (config.optInt("distance", 3)) {
                    1 -> { minObjectSize = 0.25f; distanceLabel = "CLOSE (~3m)" }
                    2 -> { minObjectSize = 0.18f; distanceLabel = "NEAR (~5m)" }
                    3 -> { minObjectSize = 0.12f; distanceLabel = "MEDIUM (~8m)" }
                    4 -> { minObjectSize = 0.08f; distanceLabel = "FAR (~10m)" }
                    5 -> { minObjectSize = 0.05f; distanceLabel = "VERY_FAR (~15m)" }
                    else -> { minObjectSize = 0.12f; distanceLabel = "MEDIUM (~8m)" }
                }

                // Only update minObjectSize — don't touch the motion sensitivity settings
                sentryConfig.minObjectSize = minObjectSize
                configChanged = true

                // Apply to the running engine if available
                sentry?.setObjectFilters(
                    minObjectSize,
                    sentryConfig.aiConfidence,
                    sentryConfig.isDetectPerson,
                    sentryConfig.isDetectCar,
                    sentryConfig.isDetectBike
                )

                logger.info(
                    String.format(
                        "Distance set via IPC: %s (minObjectSize=%.0f%%)",
                        distanceLabel, minObjectSize * 100
                    )
                )
            }

            // Motion sensitivity slider (1-5) — SEPARATE from distance. Controls requiredBlocks
            // and densityThreshold for motion detection. Block size is LOCKED at 32.
            if (config.has("sensitivity") && config.optInt("sensitivity", -1) in 1..5) {
                val sensitivityLevel = config.optInt("sensitivity", 3)

                // Production table with block size locked at 32:
                // 1=Strict (req=4, density=48), 2=Conservative (req=3, density=40),
                // 3=Default (req=2, density=32), 4=Sensitive (req=2, density=16),
                // 5=Aggressive (req=1, density=12)
                val requiredBlocks = when (sensitivityLevel) {
                    1 -> 4 // Strict - large objects only
                    2 -> 3 // Conservative - solid objects
                    3 -> 2 // Default - balanced
                    4 -> 2 // Sensitive - catches motion quickly
                    5 -> 1 // Aggressive - any motion
                    else -> 2
                }

                // Convert slider 1-5 to percentage 20-100 for unified sensitivity
                val sensitivityPercent = sensitivityLevel * 20

                // Update the config for persistence
                sentryConfig.requiredBlocks = requiredBlocks
                sentryConfig.unifiedSensitivity = sensitivityPercent
                configChanged = true

                // Apply to the running engine if available
                if (sentry != null) {
                    sentry.unifiedSensitivity = sensitivityPercent
                    sentry.setRequiredActiveBlocks(requiredBlocks)
                }

                logger.info(
                    String.format(
                        "Motion sensitivity set to level %d (%d%%, alarm=%d blocks)",
                        sensitivityLevel, sensitivityPercent, requiredBlocks
                    )
                )
            }

            // Block sensitivity (grid motion detection) — skipped if distance was set
            if (config.has("blockSensitivity") && !config.has("distance")) {
                val blockSens = config.optDouble("blockSensitivity", 0.04).toFloat()
                sentry?.setBlockSensitivity(blockSens)
                sentryConfig.sensitivity = blockSens
                configChanged = true
                logger.info("Block sensitivity set to: $blockSens")
            }

            // Required active blocks — skipped if distance was set
            if (config.has("requiredActiveBlocks") && !config.has("distance")) {
                val reqBlocks = config.optInt("requiredActiveBlocks", 2)
                sentry?.setRequiredActiveBlocks(reqBlocks)
                sentryConfig.requiredBlocks = reqBlocks
                configChanged = true
                logger.info("Required active blocks set to: $reqBlocks")
            }

            // Apply the updated config to the engine (if running) and ALWAYS persist to file
            if (configChanged) {
                // Apply the config to the running engine (syncs internal state like preRecordMs)
                sentry?.config = sentryConfig

                // ALWAYS persist to file — critical for config to survive restarts
                try {
                    SurveillanceConfigManager().saveConfig(sentryConfig)
                    logger.info(
                        "Surveillance config persisted to file (sentry " +
                            (if (sentry != null) "running" else "not running") + ")"
                    )
                } catch (e: Exception) {
                    logger.error("Failed to persist surveillance config", e)
                }
            }

            // Note: the minObjectHeight filter is applied in C++ (yolo_detector.cpp). The height
            // filter (10% of frame) is applied BEFORE NMS in native code for efficiency.

            // ==================== V2 Pipeline Settings ====================

            // Environment preset (outdoor/garage/street) — sets the slider defaults
            if (config.has("environmentPreset")) {
                val preset = config.optString("environmentPreset", "outdoor")
                    .lowercase(Locale.ROOT)
                sentryConfig.environmentPreset = preset
                sentry?.applyV2EnvironmentPreset(preset)
                configChanged = true
                logger.info("V2 environment preset: $preset")
            }

            // Sensitivity level (1-5)
            if (config.has("sensitivityLevel")) {
                val level = config.optInt("sensitivityLevel", 3)
                sentryConfig.sensitivityLevel = level
                sentry?.applyV2Sensitivity(level)
                configChanged = true
                logger.info("V2 sensitivity level: $level")
            }

            // Detection zone (close/normal/extended)
            if (config.has("detectionZone")) {
                val zone = config.optString("detectionZone", "normal").lowercase(Locale.ROOT)
                sentryConfig.detectionZone = zone
                configChanged = true
                logger.info("V2 detection zone: $zone")
            }

            // Loitering time (seconds)
            if (config.has("loiteringTime")) {
                val seconds = config.optInt("loiteringTime", 3)
                sentryConfig.loiteringTimeSeconds = seconds
                sentry?.setV2LoiteringTime(seconds)
                configChanged = true
                logger.info("V2 loitering time: ${seconds}s")
            }

            // Shadow filter mode (0=OFF, 1=LIGHT, 2=NORMAL, 3=AGGRESSIVE)
            if (config.has("shadowFilter")) {
                val mode = config.optInt("shadowFilter", 2)
                sentryConfig.shadowFilterMode = mode
                sentry?.setV2ShadowFilterMode(mode)
                configChanged = true
                val modeNames = arrayOf("OFF", "LIGHT", "NORMAL", "AGGRESSIVE")
                logger.info(
                    "V2 shadow filter: " + (if (mode in 0..3) modeNames[mode] else "invalid")
                )
            }

            // Per-camera enable/disable. Quadrant mapping: Q0=front, Q1=right, Q2=rear, Q3=left.
            if (config.has("cameraFront")) {
                val enabled = config.optBoolean("cameraFront", true)
                sentryConfig.setCameraEnabled(0, enabled)
                sentry?.setV2QuadrantEnabled(0, enabled)
                configChanged = true
            }
            if (config.has("cameraRight")) {
                val enabled = config.optBoolean("cameraRight", true)
                sentryConfig.setCameraEnabled(1, enabled)
                sentry?.setV2QuadrantEnabled(1, enabled)
                configChanged = true
            }
            if (config.has("cameraRear")) {
                val enabled = config.optBoolean("cameraRear", true)
                sentryConfig.setCameraEnabled(2, enabled)
                sentry?.setV2QuadrantEnabled(2, enabled)
                configChanged = true
            }
            if (config.has("cameraLeft")) {
                val enabled = config.optBoolean("cameraLeft", true)
                sentryConfig.setCameraEnabled(3, enabled)
                sentry?.setV2QuadrantEnabled(3, enabled)
                configChanged = true
            }

            // Developer toggles
            if (config.has("motionHeatmap")) {
                sentryConfig.isMotionHeatmapEnabled = config.optBoolean("motionHeatmap", false)
                configChanged = true
            }
            if (config.has("filterDebugLog")) {
                val debugEnabled = config.optBoolean("filterDebugLog", false)
                sentryConfig.isFilterDebugLogEnabled = debugEnabled
                sentry?.setFilterDebugEnabled(debugEnabled)
                configChanged = true
            }
        } catch (e: Exception) {
            logger.error("Failed to apply config", e)
        }
    }

    @Throws(Exception::class)
    private fun getDefaultConfig(): JSONObject {
        val config = JSONObject()

        // Read the persisted preference (not the runtime state) for the UI toggle
        config.put("enabled", UnifiedConfigManager.isSurveillanceEnabled())
        config.put("noiseThreshold", 0.0001)
        config.put("lightThreshold", 0.4)
        config.put("aiEnabled", true)
        config.put("scheduleEnabled", false)
        config.put("recordingQuality", CameraDaemon.getRecordingQuality())
        config.put("codec", CameraDaemon.getRecordingCodec())

        // Actual values from the sentry config if available
        var sentryConfig: SurveillanceConfig? = CameraDaemon.getGpuPipeline()?.sentry?.config

        // If sentry is not running, try to load from file
        if (sentryConfig == null) {
            try {
                val configManager = SurveillanceConfigManager()
                if (configManager.configExists()) {
                    sentryConfig = configManager.loadConfig()
                    logger.info("Loaded config from file for GET_CONFIG (sentry not running)")
                }
            } catch (e: Exception) {
                logger.error("Failed to load config from file", e)
            }
        }

        if (sentryConfig != null) {
            config.put("minObjectSize", sentryConfig.minObjectSize)
            config.put("aiConfidence", sentryConfig.aiConfidence)
            config.put("detectPerson", sentryConfig.isDetectPerson)
            config.put("detectCar", sentryConfig.isDetectCar)
            config.put("detectBike", sentryConfig.isDetectBike)
            config.put("flashImmunity", sentryConfig.flashImmunity)
            config.put("preEventBufferSeconds", sentryConfig.preRecordSeconds)
            config.put("postEventBufferSeconds", sentryConfig.postRecordSeconds)
            config.put("blockSensitivity", sentryConfig.sensitivity)
            config.put("requiredActiveBlocks", sentryConfig.requiredBlocks)

            // Sensitivity as a slider value (1-5) derived from requiredBlocks:
            // 1=Strict(req=4), 2=Conservative(req=3), 3=Default(req=2), 5=Aggressive(req=1)
            val reqBlocks = sentryConfig.requiredBlocks
            val sensitivityLevel = when {
                reqBlocks >= 4 -> 1 // Strict
                reqBlocks == 3 -> 2 // Conservative
                reqBlocks == 2 -> 3 // Default (could be 3 or 4, default to 3)
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
            // Defaults when no config is available
            config.put("sensitivity", 3) // Default (slider value 1-5)
            config.put("distance", 3) // ~8m (slider value 1-5)
            config.put("minObjectSize", 0.08)
            config.put("aiConfidence", 0.6)
            config.put("detectPerson", true)
            config.put("detectCar", true)
            config.put("detectBike", true)
            config.put("flashImmunity", 2) // Default MEDIUM
            config.put("preEventBufferSeconds", 5)
            config.put("postEventBufferSeconds", 10)
            config.put("blockSensitivity", 0.04)
            config.put("requiredActiveBlocks", 2)
        }

        // lastModified timestamp for web UI sync detection
        config.put("lastModified", UnifiedConfigManager.getLastModified())

        return config
    }

    @Throws(Exception::class)
    private fun getSurveillanceStatus(): JSONObject {
        val status = JSONObject()
        // Read from the persisted config (not an in-memory flag)
        status.put("enabled", UnifiedConfigManager.isSurveillanceEnabled())
        status.put("active", CameraDaemon.isSurveillanceActive())
        status.put("recording", false)
        return status
    }

    // ==================== VEHICLE DATA HELPERS ====================

    @Throws(Exception::class)
    private fun getBatteryVoltageData(): JSONObject {
        val data = VehicleDataMonitor.getInstance().getBatteryVoltage()
            ?: throw Exception("Battery voltage data not available")

        val json = JSONObject()
        json.put("level", data.level)
        json.put("levelName", data.levelName)
        json.put("isWarning", data.isWarning)
        json.put("timestamp", data.timestamp)
        return json
    }

    @Throws(Exception::class)
    private fun getBatteryPowerData(): JSONObject {
        val data = VehicleDataMonitor.getInstance().getBatteryPower()
            ?: throw Exception("Battery power data not available")

        val json = JSONObject()
        json.put("voltageVolts", data.voltageVolts)
        json.put("isWarning", data.isWarning)
        json.put("isCritical", data.isCritical)
        json.put("healthStatus", data.getHealthStatus())
        json.put("timestamp", data.timestamp)
        return json
    }

    @Throws(Exception::class)
    private fun getBatterySocData(): JSONObject {
        val data = VehicleDataMonitor.getInstance().getBatterySoc()
            ?: throw Exception("Battery SOC data not available")

        val json = JSONObject()
        json.put("socPercent", data.socPercent)
        json.put("isLow", data.isLow)
        json.put("isCritical", data.isCritical)
        json.put("status", data.getStatus())
        json.put("timestamp", data.timestamp)
        return json
    }

    @Throws(Exception::class)
    private fun getChargingStateData(): JSONObject {
        val data = VehicleDataMonitor.getInstance().getChargingState()
            ?: throw Exception("Charging state data not available")

        val json = JSONObject()
        json.put("stateCode", data.stateCode)
        json.put("stateName", data.stateName)
        json.put("status", data.status.name)
        json.put("isError", data.isError)
        json.put("errorType", data.errorType)
        json.put("chargingPowerKW", data.chargingPowerKW)
        json.put("isDischarging", data.isDischarging)
        json.put("timestamp", data.timestamp)
        return json
    }

    @Throws(Exception::class)
    private fun getChargingPowerData(): JSONObject {
        val data = VehicleDataMonitor.getInstance().getChargingState()
            ?: throw Exception("Charging power data not available")

        val json = JSONObject()
        json.put("chargingPowerKW", data.chargingPowerKW)
        json.put("isDischarging", data.isDischarging)
        json.put("timestamp", data.timestamp)
        return json
    }

    @Throws(Exception::class)
    private fun getDrivingRangeData(): JSONObject {
        val data = VehicleDataMonitor.getInstance().getDrivingRange()
            ?: throw Exception("Driving range data not available")

        val json = JSONObject()
        json.put("elecRangeKm", data.elecRangeKm)
        json.put("fuelRangeKm", data.fuelRangeKm)
        json.put("totalRangeKm", data.totalRangeKm)
        json.put("isLow", data.isLow)
        json.put("isCritical", data.isCritical)
        json.put("status", data.getStatus())
        json.put("isPureEV", data.isPureEV())
        if (data.hasFuelPercent()) {
            json.put("fuelPercent", data.fuelPercent)
        }
        json.put("timestamp", data.timestamp)
        return json
    }

    // ==================== GPS SIDECAR HANDLER ====================

    /**
     * Handle a GPS update from LocationSidecarService. Updates GpsMonitor's cached values
     * directly — no file needed.
     */
    private fun handleGpsUpdate(request: JSONObject) {
        try {
            GpsMonitor.getInstance().updateFromIpc(
                request.optDouble("lat", 0.0),
                request.optDouble("lng", 0.0),
                request.optDouble("speed", 0.0).toFloat(),
                request.optDouble("heading", 0.0).toFloat(),
                request.optDouble("accuracy", 0.0).toFloat(),
                request.optLong("time", System.currentTimeMillis()),
                request.optDouble("altitude", 0.0)
            )
        } catch (e: Exception) {
            logger.error("Failed to update GPS", e)
        }
    }

    fun stop() {
        running = false
        try {
            serverSocket?.close()
        } catch (e: Exception) {
            logger.error("Error stopping IPC server", e)
        }
        // Kill all active connections immediately on shutdown
        threadPool.shutdownNow()
    }

    private companion object {
        val logger: DaemonLogger = DaemonLogger.getInstance("SurveillanceIPC")

        /** Guards the load-mutate-save cycle in applyConfig; see its KDoc. */
        val CONFIG_LOCK = Any()
    }
}
