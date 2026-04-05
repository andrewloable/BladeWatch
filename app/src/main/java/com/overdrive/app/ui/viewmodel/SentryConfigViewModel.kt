package com.overdrive.app.ui.viewmodel

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.PrintWriter
import java.net.Socket

/**
 * ViewModel for Sentry surveillance configuration.
 * Communicates with CameraDaemon's surveillance IPC server on port 19877.
 */
class SentryConfigViewModel : ViewModel() {
    
    companion object {
        private const val IPC_HOST = "127.0.0.1"
        private const val IPC_PORT = 19877  // Surveillance IPC server port
        private const val TIMEOUT_MS = 5000
    }
    
    // Configuration state
    private val _config = MutableLiveData<SentryConfig>()
    val config: LiveData<SentryConfig> = _config
    
    // Status state
    private val _status = MutableLiveData<SentryStatus>()
    val status: LiveData<SentryStatus> = _status
    
    // ROI data per camera
    private val _roiByCamera = MutableLiveData<Map<Int, List<Pair<Float, Float>>>>()
    val roiByCamera: LiveData<Map<Int, List<Pair<Float, Float>>>> = _roiByCamera
    
    // Error messages
    private val _error = MutableLiveData<String?>()
    val error: LiveData<String?> = _error
    
    // Current config (for modifications)
    private var currentConfig = SentryConfig()
    
    /**
     * Load configuration from daemon.
     */
    fun loadConfig() {
        viewModelScope.launch {
            try {
                // Get config
                val configResponse = sendCommand(JSONObject().apply {
                    put("command", "GET_CONFIG")
                })
                
                if (configResponse == null) {
                    _error.postValue("Cannot connect to daemon - is Camera Daemon running?")
                    return@launch
                }
                
                if (configResponse.optBoolean("success") == true) {
                    val configJson = configResponse.optJSONObject("config")
                    if (configJson != null) {
                        currentConfig = parseConfig(configJson)
                        _config.postValue(currentConfig)
                    }
                }
                
                // Get status
                val statusResponse = sendCommand(JSONObject().apply {
                    put("command", "GET_STATUS")
                })
                
                if (statusResponse?.optBoolean("success") == true) {
                    val statusJson = statusResponse.optJSONObject("status")
                    if (statusJson != null) {
                        _status.postValue(parseStatus(statusJson))
                    }
                }
                
                // Get ROI data
                loadRoiData()
                
            } catch (e: Exception) {
                _error.postValue("Failed to load config: ${e.message}")
            }
        }
    }
    
    /**
     * Load ROI data from daemon.
     */
    fun loadRoiData() {
        viewModelScope.launch {
            try {
                val roiResponse = sendCommand(JSONObject().apply {
                    put("command", "GET_ROI")
                    put("cameraId", -1) // Get all ROIs
                })
                
                if (roiResponse?.optBoolean("success") == true) {
                    val roisJson = roiResponse.optJSONObject("rois")
                    if (roisJson != null) {
                        val roiMap = mutableMapOf<Int, List<Pair<Float, Float>>>()
                        
                        roisJson.keys().forEach { key ->
                            val cameraId = key.toIntOrNull() ?: return@forEach
                            val pointsArray = roisJson.optJSONArray(key) ?: return@forEach
                            
                            val points = mutableListOf<Pair<Float, Float>>()
                            for (i in 0 until pointsArray.length()) {
                                val p = pointsArray.optJSONObject(i) ?: continue
                                points.add(Pair(
                                    p.optDouble("x", 0.0).toFloat(),
                                    p.optDouble("y", 0.0).toFloat()
                                ))
                            }
                            
                            if (points.isNotEmpty()) {
                                roiMap[cameraId] = points
                            }
                        }
                        
                        _roiByCamera.postValue(roiMap)
                    }
                }
            } catch (e: Exception) {
                // ROI loading failed, not critical
            }
        }
    }
    
    /**
     * Enable or disable surveillance.
     */
    fun setEnabled(enabled: Boolean) {
        viewModelScope.launch {
            val command = if (enabled) "ENABLE_SURVEILLANCE" else "DISABLE_SURVEILLANCE"
            val response = sendCommand(JSONObject().apply {
                put("command", command)
            })
            
            if (response?.optBoolean("success") == true) {
                currentConfig = currentConfig.copy(enabled = enabled)
                _config.postValue(currentConfig)
                loadConfig() // Refresh status
            } else {
                _error.postValue("Failed to ${if (enabled) "enable" else "disable"} surveillance")
            }
        }
    }
    
    /**
     * Update local config only - does NOT send to daemon.
     * Call saveConfig() to persist changes.
     */
    fun setNoiseThreshold(threshold: Float) {
        updateLocalConfig { it.copy(noiseThreshold = threshold) }
    }
    
    fun setLightThreshold(threshold: Float) {
        updateLocalConfig { it.copy(lightThreshold = threshold) }
    }
    
    fun setAiEnabled(enabled: Boolean) {
        updateLocalConfig { it.copy(aiEnabled = enabled) }
    }
    
    fun setAiConfidence(confidence: Float) {
        updateLocalConfig { it.copy(aiConfidence = confidence) }
    }
    
    fun setDetectPerson(detect: Boolean) {
        updateLocalConfig { it.copy(detectPerson = detect) }
    }
    
    fun setDetectCar(detect: Boolean) {
        updateLocalConfig { it.copy(detectCar = detect) }
    }
    
    fun setDetectBike(detect: Boolean) {
        updateLocalConfig { it.copy(detectBike = detect) }
    }
    
    fun setMinObjectSize(size: Float) {
        updateLocalConfig { it.copy(minObjectSize = size) }
    }
    
    fun setDistance(distance: Int) {
        updateLocalConfig { it.copy(distance = distance) }
    }
    
    fun setPreEventBuffer(seconds: Int) {
        updateLocalConfig { it.copy(preEventBufferSeconds = seconds) }
    }
    
    fun setPostEventBuffer(seconds: Int) {
        updateLocalConfig { it.copy(postEventBufferSeconds = seconds) }
    }
    
    fun setScheduleEnabled(enabled: Boolean) {
        updateLocalConfig { it.copy(scheduleEnabled = enabled) }
    }
    
    fun setBitrate(bitrate: String) {
        updateLocalConfig { it.copy(bitrate = bitrate) }
    }
    
    fun setCodec(codec: String) {
        updateLocalConfig { it.copy(codec = codec) }
    }
    
    fun setFlashImmunity(level: Int) {
        updateLocalConfig { it.copy(flashImmunity = level.coerceIn(0, 3)) }
    }
    
    fun setSensitivity(sensitivity: Int) {
        updateLocalConfig { it.copy(sensitivity = sensitivity.coerceIn(1, 5)) }
    }
    
    /**
     * Update local config only - does NOT send to daemon.
     * This is for the Apply button pattern.
     */
    private fun updateLocalConfig(transform: (SentryConfig) -> SentryConfig) {
        currentConfig = transform(currentConfig)
        _config.postValue(currentConfig)
    }
    
    /**
     * Save current config to server (called by Apply button).
     */
    fun saveConfig() {
        viewModelScope.launch {
            val configJson = JSONObject().apply {
                put("distance", currentConfig.distance)  // Distance slider (1-5) → maps to minObjectSize on server
                put("sensitivity", currentConfig.sensitivity)  // Sensitivity slider (1-5) → maps to requiredBlocks on server
                put("flashImmunity", currentConfig.flashImmunity)
                put("aiEnabled", currentConfig.aiEnabled)
                put("aiConfidence", currentConfig.aiConfidence)
                put("detectPerson", currentConfig.detectPerson)
                put("detectCar", currentConfig.detectCar)
                put("detectBike", currentConfig.detectBike)
                put("preEventBufferSeconds", currentConfig.preEventBufferSeconds)
                put("postEventBufferSeconds", currentConfig.postEventBufferSeconds)
                put("schedulingEnabled", currentConfig.scheduleEnabled)
                put("bitrate", currentConfig.bitrate)
                put("codec", currentConfig.codec)
            }
            
            val response = sendCommand(JSONObject().apply {
                put("command", "SET_CONFIG")
                put("config", configJson)
            })
            
            if (response == null) {
                _error.postValue("Cannot connect to daemon - is Camera Daemon running?")
            } else if (response.optBoolean("success") != true) {
                val errorMsg = response.optString("error", "Unknown error")
                _error.postValue("Failed to save config: $errorMsg")
            } else {
                _error.postValue(null)
            }
        }
    }
    
    /**
     * Send surveillance storage settings to daemon via IPC.
     * This ensures the daemon's StorageManager picks up the change.
     */
    fun saveSurveillanceStorage(storageType: String, limitMb: Long) {
        viewModelScope.launch {
            val configJson = JSONObject().apply {
                put("surveillanceStorageType", storageType)
                put("surveillanceLimitMb", limitMb)
            }
            
            val response = sendCommand(JSONObject().apply {
                put("command", "SET_CONFIG")
                put("config", configJson)
            })
            
            if (response == null) {
                _error.postValue("Cannot connect to daemon - is Camera Daemon running?")
            } else if (response.optBoolean("success") != true) {
                val errorMsg = response.optString("error", "Unknown error")
                _error.postValue("Failed to update storage: $errorMsg")
            }
        }
    }
    
    /**
     * Set ROI for a specific camera.
     */
    fun setRoi(cameraId: Int, points: FloatArray) {
        viewModelScope.launch {
            val pointsArray = org.json.JSONArray()
            for (i in points.indices step 2) {
                val point = JSONObject().apply {
                    put("x", points[i])
                    put("y", points[i + 1])
                }
                pointsArray.put(point)
            }
            
            val response = sendCommand(JSONObject().apply {
                put("command", "SET_ROI")
                put("cameraId", cameraId)
                put("points", pointsArray)
            })
            
            if (response?.optBoolean("success") == true) {
                _error.postValue(null) // Clear any previous error
            } else {
                _error.postValue("Failed to save ROI for camera $cameraId")
            }
        }
    }
    
    // ==================== SAFE LOCATIONS ====================
    
    fun loadSafeLocations(callback: (JSONObject) -> Unit) {
        viewModelScope.launch {
            val response = sendCommand(JSONObject().apply {
                put("command", "GET_SAFE_LOCATIONS")
            })
            if (response != null) {
                callback(response)
            } else {
                callback(JSONObject().apply {
                    put("featureEnabled", false)
                    put("zones", org.json.JSONArray())
                    put("zoneCount", 0)
                })
            }
        }
    }
    
    fun toggleSafeLocations(enabled: Boolean) {
        viewModelScope.launch {
            sendCommand(JSONObject().apply {
                put("command", "TOGGLE_SAFE_LOCATIONS")
                put("enabled", enabled)
            })
        }
    }
    
    fun addCurrentLocationAsSafe(name: String, radiusM: Int, callback: (Boolean) -> Unit) {
        viewModelScope.launch {
            // First get current GPS
            val gpsResponse = sendCommand(JSONObject().apply {
                put("command", "GET_SAFE_LOCATIONS")
            })
            
            val lat = gpsResponse?.optDouble("lat", 0.0) ?: 0.0
            val lng = gpsResponse?.optDouble("lng", 0.0) ?: 0.0
            
            if (lat == 0.0 && lng == 0.0) {
                callback(false)
                return@launch
            }
            
            val response = sendCommand(JSONObject().apply {
                put("command", "ADD_SAFE_LOCATION")
                put("zone", JSONObject().apply {
                    put("name", name)
                    put("lat", lat)
                    put("lng", lng)
                    put("radiusM", radiusM)
                })
            })
            
            callback(response?.optBoolean("success", false) ?: false)
        }
    }
    
    fun updateSafeZone(id: String, updates: JSONObject) {
        viewModelScope.launch {
            sendCommand(JSONObject().apply {
                put("command", "UPDATE_SAFE_LOCATION")
                put("id", id)
                put("updates", updates)
            })
        }
    }
    
    fun deleteSafeZone(id: String, callback: () -> Unit) {
        viewModelScope.launch {
            sendCommand(JSONObject().apply {
                put("command", "DELETE_SAFE_LOCATION")
                put("id", id)
            })
            callback()
        }
    }
    
    /**
     * Set time windows for scheduling.
     */
    fun setTimeWindows(windows: List<com.overdrive.app.ui.dialog.TimeWindowDialogFragment.TimeWindow>) {
        viewModelScope.launch {
            val windowsArray = org.json.JSONArray()
            windows.forEach { window ->
                val windowJson = JSONObject().apply {
                    put("startHour", window.startHour)
                    put("startMinute", window.startMinute)
                    put("endHour", window.endHour)
                    put("endMinute", window.endMinute)
                    
                    val daysArray = org.json.JSONArray()
                    window.daysOfWeek.forEach { day -> daysArray.put(day) }
                    put("daysOfWeek", daysArray)
                }
                windowsArray.put(windowJson)
            }
            
            val response = sendCommand(JSONObject().apply {
                put("command", "SET_CONFIG")
                put("config", JSONObject().apply {
                    put("timeWindows", windowsArray)
                    put("schedulingEnabled", true)
                })
            })
            
            if (response?.optBoolean("success") == true) {
                currentConfig = currentConfig.copy(scheduleEnabled = true)
                _config.postValue(currentConfig)
            } else {
                _error.postValue("Failed to save schedule")
            }
        }
    }
    
    /**
     * Send command to IPC server.
     */
    private suspend fun sendCommand(command: JSONObject): JSONObject? {
        return withContext(Dispatchers.IO) {
            var socket: Socket? = null
            try {
                socket = Socket(IPC_HOST, IPC_PORT)
                socket.soTimeout = TIMEOUT_MS
                
                val writer = PrintWriter(socket.getOutputStream(), true)
                val reader = BufferedReader(InputStreamReader(socket.getInputStream()))
                
                writer.println(command.toString())
                
                val responseLine = reader.readLine()
                if (responseLine != null) {
                    JSONObject(responseLine)
                } else {
                    null
                }
            } catch (e: Exception) {
                null
            } finally {
                try {
                    socket?.close()
                } catch (e: Exception) {
                    // Ignore
                }
            }
        }
    }
    
    private fun parseConfig(json: JSONObject): SentryConfig {
        return SentryConfig(
            enabled = json.optBoolean("enabled", false),
            distance = json.optInt("distance", 3),  // Default ~8m
            sensitivity = json.optInt("sensitivity", 3),  // Default balanced
            minObjectSize = json.optDouble("minObjectSize", 0.08).toFloat(),  // Default ~8m
            flashImmunity = json.optInt("flashImmunity", 2),  // Default MEDIUM
            noiseThreshold = json.optDouble("noiseThreshold", 0.005).toFloat(),  // 0.5% default
            lightThreshold = json.optDouble("lightThreshold", 0.4).toFloat(),
            aiEnabled = json.optBoolean("aiEnabled", true),
            aiConfidence = json.optDouble("aiConfidence", 0.4).toFloat(),
            detectPerson = json.optBoolean("detectPerson", true),
            detectCar = json.optBoolean("detectCar", true),
            detectBike = json.optBoolean("detectBike", true),
            preEventBufferSeconds = json.optInt("preEventBufferSeconds", 5),
            postEventBufferSeconds = json.optInt("postEventBufferSeconds", 10),
            scheduleEnabled = json.optBoolean("schedulingEnabled", false),
            bitrate = json.optString("bitrate", "MEDIUM"),
            codec = json.optString("codec", "H264")
        )
    }
    
    private fun parseStatus(json: JSONObject): SentryStatus {
        return SentryStatus(
            enabled = json.optBoolean("enabled", false),
            active = json.optBoolean("active", false),
            recording = json.optBoolean("recording", false),
            bufferFillPercent = json.optDouble("bufferFillPercent", 0.0).toFloat(),
            yoloLoaded = json.optBoolean("yoloLoaded", false),
            totalEventsToday = json.optInt("totalEventsToday", 0)
        )
    }
    
    // Data classes
    data class SentryConfig(
        val enabled: Boolean = false,
        val distance: Int = 3,  // Distance slider: 1=~3m, 2=~5m, 3=~8m, 4=~10m, 5=~15m
        val sensitivity: Int = 3,  // Sensitivity slider: 1=Strict, 2=Conservative, 3=Default, 4=Sensitive, 5=Aggressive
        val minObjectSize: Float = 0.08f,  // Distance detection: 0.02=far(~15m), 0.20=near(~3m)
        val flashImmunity: Int = 2,  // 0=OFF, 1=LOW, 2=MEDIUM, 3=HIGH
        val noiseThreshold: Float = 0.005f,  // 0.5% - matches slider minimum
        val lightThreshold: Float = 0.4f,
        val aiEnabled: Boolean = true,
        val aiConfidence: Float = 0.4f,
        val detectPerson: Boolean = true,
        val detectCar: Boolean = true,
        val detectBike: Boolean = true,
        val preEventBufferSeconds: Int = 5,
        val postEventBufferSeconds: Int = 10,
        val scheduleEnabled: Boolean = false,
        val bitrate: String = "MEDIUM",
        val codec: String = "H264"
    )
    
    data class SentryStatus(
        val enabled: Boolean = false,
        val active: Boolean = false,
        val recording: Boolean = false,
        val bufferFillPercent: Float = 0f,
        val yoloLoaded: Boolean = false,
        val totalEventsToday: Int = 0
    )
}
