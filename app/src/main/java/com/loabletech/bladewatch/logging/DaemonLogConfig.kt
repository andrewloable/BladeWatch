package net.bladewatch.app.logging


/**
 * Compile-time logging configuration for release builds.
 * 
 * By default, all file logging is OFF in release builds.
 * To debug a specific daemon/component on a device:
 *   1. Set ENABLE_ALL = true (logs everything), OR
 *   2. Set individual flags below to true for targeted logging
 *   3. Build and deploy to the device
 *   4. Logs will appear in /data/local/tmp/<tag>.log
 * 
 * IMPORTANT: The proguard rules in proguard-rules.pro must also be updated.
 *   When LogConfig flags are enabled, the corresponding -assumenosideeffects
 *   rules are conditionally excluded so R8 doesn't strip the log calls.
 *   See the "Log Stripping" section in proguard-rules.pro.
 * 
 * After debugging, set everything back to false before shipping to production.
 */
object DaemonLogConfig {

    // ==================== MASTER SWITCH ====================
    
    /**
     * Set true to enable file+stdout logging for ALL daemons/components.
     * Overrides all individual flags below.
     * 
     * When true, proguard log stripping is FULLY DISABLED (see proguard-rules.pro).
     */
    const val ENABLE_ALL = false

    // ==================== DAEMON PROCESSES ====================
    
    /** CameraDaemon - main camera pipeline, GPU init, surveillance orchestration */
    const val CAMERA_DAEMON = false
    
    /** AccSentryDaemon - ACC state detection, sentry mode transitions */
    const val ACC_SENTRY_DAEMON = false
    
    /** SentryDaemon - legacy sentry process */
    const val SENTRY_DAEMON = false

    /** BydEventDaemon - BYD vehicle event listener */
    const val BYD_EVENT_DAEMON = false

    // ==================== GPU PIPELINE ====================
    
    /** GpuPipeline - GPU surveillance pipeline orchestration */
    const val GPU_PIPELINE = false
    
    /** PanoramicCameraGpu - AVMCamera init, GL thread, frame delivery */
    const val PANORAMIC_CAMERA = false
    
    /** EGLCore - EGL context creation, surface management */
    const val EGL_CORE = false
    
    /** GlUtil - shader compilation, texture creation */
    const val GL_UTIL = false
    
    /** GpuMosaicRecorder - mosaic rendering, encoder surface */
    const val GPU_MOSAIC_RECORDER = false
    
    /** GpuDownscaler - GPU frame downscaling for AI lane */
    const val GPU_DOWNSCALER = false
    
    /** GpuStreamScaler - GPU stream scaling */
    const val GPU_STREAM_SCALER = false
    
    /** HWEncoderGpu - MediaCodec hardware encoder */
    const val HW_ENCODER = false
    
    /** AdaptiveBitrate - bitrate controller */
    const val ADAPTIVE_BITRATE = false
    
    /** H264CircularBuffer - pre-record circular buffer */
    const val H264_CIRCULAR_BUFFER = false
    
    /** GpuPipelineTiming - per-stage frame timing with p50/p95, see PanoramicCameraGpu */
    const val GPU_PIPELINE_TIMING = false

    // ==================== SURVEILLANCE & MOTION ====================
    
    /** SurveillanceEngineGpu - motion detection, event recording triggers */
    const val SURVEILLANCE_ENGINE = false
    
    /** EventTimeline - event timeline collector */
    const val EVENT_TIMELINE = false
    
    /** ModeTransition - mode transition manager */
    const val MODE_TRANSITION = false
    
    /** SafeLocationManager - geofence/safe zone logic (logs via CameraDaemon.log) */
    const val SAFE_LOCATION = false
    
    /** SurveillanceConfigManager - surveillance config persistence */
    const val SURVEILLANCE_CONFIG = false

    // ==================== RECORDING ====================
    
    /** RecordingModeManager - recording mode state machine */
    const val RECORDING_MODE_MANAGER = false

    // ==================== PROXIMITY GUARD ====================
    
    /** ProximityGuardController - proximity guard orchestration */
    const val PROXIMITY_GUARD_CONTROLLER = false
    
    /** ProximityRadarMonitor - radar data monitoring */
    const val PROXIMITY_RADAR_MONITOR = false
    
    /** ProximityRecordingHandler - proximity-triggered recording */
    const val PROXIMITY_RECORDING_HANDLER = false
    
    /** ProximityGuardConfig - proximity guard configuration */
    const val PROXIMITY_GUARD_CONFIG = false

    // ==================== MONITORS ====================
    
    /** GearMonitor - gear state detection */
    const val GEAR_MONITOR = false
    
    /** VehicleDataMonitor - BYD vehicle CAN bus data */
    const val VEHICLE_DATA_MONITOR = false
    
    
    /** PerformanceMonitor - CPU/memory/thermal monitoring */
    const val PERFORMANCE_MONITOR = false
    
    
    /** SocHistoryDatabase - SOC history H2 database */
    const val SOC_HISTORY_DATABASE = false

    // ==================== STREAMING ====================
    
    /** WSStreamServer - WebSocket stream server */
    const val WS_STREAM_SERVER = false

    // ==================== TELEMETRY ====================

    /** TelemetryDataCollector - telemetry data collection */
    const val TELEMETRY_DATA_COLLECTOR = false

    /** OverlayRenderer - telemetry overlay rendering */
    const val OVERLAY_RENDERER = false

    // ==================== TRIP ANALYTICS ====================
    
    /** Trip analytics — trip detection, telemetry recording, scoring, range estimation */
    const val TRIP_ANALYTICS = false

    // ==================== STORAGE ====================
    
    /** StorageManager - storage management, SD card mounting */
    const val STORAGE_MANAGER = false
    
    /** ExternalStorageCleaner - external storage cleanup */
    const val EXTERNAL_STORAGE_CLEANER = false

    // ==================== SERVERS ====================
    
    /** HttpServer - HTTP API server (logs via CameraDaemon.log) */
    const val HTTP_SERVER = false
    
    /** SurveillanceIPC - surveillance IPC server */
    const val SURVEILLANCE_IPC = false

    /** PerformanceApiHandler - performance API handler */
    const val PERFORMANCE_API_HANDLER = false

    // ==================== TAG LOOKUP ====================
    
    private val ENABLED_TAGS: MutableSet<String> = HashSet()
    
    /**
     * Returns true if ANY logging is enabled (for proguard-safe fast check).
     * When this is false and proguard strips log calls, this class is a no-op.
     */
    const val ANY_LOGGING_ENABLED = ENABLE_ALL
        || CAMERA_DAEMON || ACC_SENTRY_DAEMON || SENTRY_DAEMON
        || BYD_EVENT_DAEMON
        || GPU_PIPELINE || PANORAMIC_CAMERA || EGL_CORE || GL_UTIL
        || GPU_MOSAIC_RECORDER || GPU_DOWNSCALER || GPU_STREAM_SCALER
        || HW_ENCODER || ADAPTIVE_BITRATE || H264_CIRCULAR_BUFFER
        || GPU_PIPELINE_TIMING || SURVEILLANCE_ENGINE || EVENT_TIMELINE
        || MODE_TRANSITION || SAFE_LOCATION || SURVEILLANCE_CONFIG
        || RECORDING_MODE_MANAGER || PROXIMITY_GUARD_CONTROLLER
        || PROXIMITY_RADAR_MONITOR || PROXIMITY_RECORDING_HANDLER
        || PROXIMITY_GUARD_CONFIG || GEAR_MONITOR || VEHICLE_DATA_MONITOR
        || PERFORMANCE_MONITOR
        || SOC_HISTORY_DATABASE || WS_STREAM_SERVER
        || TELEMETRY_DATA_COLLECTOR
        || OVERLAY_RENDERER || TRIP_ANALYTICS || STORAGE_MANAGER
        || EXTERNAL_STORAGE_CLEANER || HTTP_SERVER || SURVEILLANCE_IPC
        || PERFORMANCE_API_HANDLER
    
    init {
        if (!ENABLE_ALL) {
            if (CAMERA_DAEMON)              ENABLED_TAGS.add("CameraDaemon")
            if (ACC_SENTRY_DAEMON)          ENABLED_TAGS.add("AccSentryDaemon")
            if (SENTRY_DAEMON)              ENABLED_TAGS.add("SentryDaemon")
            if (BYD_EVENT_DAEMON)           ENABLED_TAGS.add("BydEventDaemon")
            if (GPU_PIPELINE)               ENABLED_TAGS.add("GpuPipeline")
            if (PANORAMIC_CAMERA)           ENABLED_TAGS.add("PanoramicCameraGpu")
            if (EGL_CORE)                   ENABLED_TAGS.add("EGLCore")
            if (GL_UTIL)                    ENABLED_TAGS.add("GlUtil")
            if (GPU_MOSAIC_RECORDER)        ENABLED_TAGS.add("GpuMosaicRecorder")
            if (GPU_DOWNSCALER)             ENABLED_TAGS.add("GpuDownscaler")
            if (GPU_STREAM_SCALER)          ENABLED_TAGS.add("GpuStreamScaler")
            if (HW_ENCODER)                 ENABLED_TAGS.add("HWEncoderGpu")
            if (ADAPTIVE_BITRATE)           ENABLED_TAGS.add("AdaptiveBitrate")
            if (H264_CIRCULAR_BUFFER)       ENABLED_TAGS.add("H264CircularBuffer")
            if (GPU_PIPELINE_TIMING)        ENABLED_TAGS.add("GpuPipelineTiming")
            if (SURVEILLANCE_ENGINE)        ENABLED_TAGS.add("SurveillanceEngineGpu")
            if (EVENT_TIMELINE)             ENABLED_TAGS.add("EventTimeline")
            if (MODE_TRANSITION)            ENABLED_TAGS.add("ModeTransition")
            if (SAFE_LOCATION)              ENABLED_TAGS.add("SafeLocation")
            if (RECORDING_MODE_MANAGER)     ENABLED_TAGS.add("RecordingModeManager")
            if (PROXIMITY_GUARD_CONTROLLER) ENABLED_TAGS.add("ProximityGuardController")
            if (PROXIMITY_RADAR_MONITOR)    ENABLED_TAGS.add("ProximityRadarMonitor")
            if (PROXIMITY_RECORDING_HANDLER) ENABLED_TAGS.add("ProximityRecordingHandler")
            if (PROXIMITY_GUARD_CONFIG)     ENABLED_TAGS.add("ProximityGuardConfig")
            if (GEAR_MONITOR)               ENABLED_TAGS.add("GearMonitor")
            if (VEHICLE_DATA_MONITOR)       ENABLED_TAGS.add("VehicleDataMonitor")
            if (PERFORMANCE_MONITOR)        ENABLED_TAGS.add("PerformanceMonitor")
            if (SOC_HISTORY_DATABASE)       ENABLED_TAGS.add("SocHistoryDatabase")
            if (WS_STREAM_SERVER)           ENABLED_TAGS.add("WSStreamServer")
            if (TELEMETRY_DATA_COLLECTOR)   ENABLED_TAGS.add("TelemetryDataCollector")
            if (OVERLAY_RENDERER)           ENABLED_TAGS.add("OverlayRenderer")
            if (TRIP_ANALYTICS) {
                ENABLED_TAGS.add("TripAnalyticsManager")
                ENABLED_TAGS.add("TripDetector")
                ENABLED_TAGS.add("TripTelemetryRecorder")
                ENABLED_TAGS.add("TripScoreEngine")
                ENABLED_TAGS.add("TripDatabase")
                ENABLED_TAGS.add("RangeEstimator")
                ENABLED_TAGS.add("TripConfig")
                ENABLED_TAGS.add("TelemetryStore")
            }
            if (STORAGE_MANAGER)            ENABLED_TAGS.add("StorageManager")
            if (EXTERNAL_STORAGE_CLEANER)   ENABLED_TAGS.add("ExternalStorageCleaner")
            if (HTTP_SERVER)                ENABLED_TAGS.add("HttpServer")
            if (SURVEILLANCE_IPC)           ENABLED_TAGS.add("SurveillanceIPC")
            if (PERFORMANCE_API_HANDLER)    ENABLED_TAGS.add("PerformanceApiHandler")
        }
    }

    /**
     * Check if file logging is enabled for a given tag.
     * Called by DaemonLogger on every log write.
     */
    @JvmStatic
    fun isFileLoggingEnabled(tag: String): Boolean {
        if (ENABLE_ALL) return true
        return ENABLED_TAGS.contains(tag)
    }
}
