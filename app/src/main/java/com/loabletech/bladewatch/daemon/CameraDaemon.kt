package net.bladewatch.app.daemon

import android.content.ContentResolver
import android.content.Context
import android.content.ContextWrapper
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.content.res.AssetManager
import android.content.res.Resources
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process

import net.bladewatch.app.BuildConfig
import net.bladewatch.app.byd.BydDataCollector
import net.bladewatch.app.byd.BydDeviceHelper
import net.bladewatch.app.camera.AvcHalWarmup
import net.bladewatch.app.camera.BydCameraCoordinator
import net.bladewatch.app.camera.PanoramicCameraGpu
import net.bladewatch.app.auth.AuthManager
import net.bladewatch.app.config.SecretConfigStore
import net.bladewatch.app.config.UnifiedConfigManager
import net.bladewatch.app.daemon.proxy.Safe
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.logging.SessionBanner
import net.bladewatch.app.media.MediaCatalogManager
import net.bladewatch.app.monitor.AccMonitor
import net.bladewatch.app.monitor.GearMonitor
import net.bladewatch.app.monitor.GpsMonitor
import net.bladewatch.app.monitor.NetworkMonitor
import net.bladewatch.app.monitor.PerformanceMonitor
import net.bladewatch.app.monitor.SocHistoryDatabase
import net.bladewatch.app.monitor.VehicleDataMonitor
import net.bladewatch.app.notifications.CategoryRegistry
import net.bladewatch.app.notifications.NotificationBus
import net.bladewatch.app.notifications.push.SubscriptionStore
import net.bladewatch.app.notifications.push.VapidKeyStore
import net.bladewatch.app.notifications.push.VapidSigner
import net.bladewatch.app.notifications.sinks.LogSink
import net.bladewatch.app.notifications.sinks.PushSink
import net.bladewatch.app.recording.RecordingModeManager
import net.bladewatch.app.server.HttpServer
import net.bladewatch.app.server.IpcTokenManager
import net.bladewatch.app.server.LanDiscoveryResponder
import net.bladewatch.app.server.LanTls
import net.bladewatch.app.server.NotificationApiHandler
import net.bladewatch.app.server.SurveillanceIpcServer
import net.bladewatch.app.server.TcpCommandServer
import net.bladewatch.app.server.connect.impl.AuthServiceImpl
import net.bladewatch.app.server.connect.impl.NotificationsServiceImpl
import net.bladewatch.app.server.connect.impl.RecordingsServiceImpl
import net.bladewatch.app.server.connect.impl.SafeLocationsServiceImpl
import net.bladewatch.app.server.connect.impl.SettingsServiceImpl
import net.bladewatch.app.server.connect.impl.StorageServiceImpl
import net.bladewatch.app.server.connect.impl.StreamServiceImpl
import net.bladewatch.app.server.connect.impl.SurveillanceServiceImpl
import net.bladewatch.app.server.connect.impl.SystemServiceImpl
import net.bladewatch.app.server.connect.impl.TripsServiceImpl
import net.bladewatch.app.server.connect.impl.VehicleServiceImpl
import net.bladewatch.app.storage.ExternalStorageCleaner
import net.bladewatch.app.storage.InternalToSdMigrator
import net.bladewatch.app.storage.StorageManager
import net.bladewatch.app.surveillance.GpuPipelineConfig
import net.bladewatch.app.surveillance.GpuSurveillancePipeline
import net.bladewatch.app.surveillance.HardwareEventRecorderGpu
import net.bladewatch.app.surveillance.SafeLocationManager
import net.bladewatch.app.surveillance.SurveillanceSchedule
import net.bladewatch.app.surveillance.isLibraryLoaded
import net.bladewatch.app.surveillance.getLoadError
import net.bladewatch.app.surveillance.tryLoadLibrary
import net.bladewatch.app.telemetry.TelemetryDataCollector
import net.bladewatch.app.trips.OdometerReader
import net.bladewatch.app.trips.TripAnalyticsManager

import java.io.BufferedReader
import java.io.File
import java.io.FileReader
import java.io.FileWriter
import java.lang.reflect.Constructor
import java.lang.reflect.Method
import java.net.InetSocketAddress
import java.net.Socket
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.Scanner
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Main Camera Daemon - orchestrates all camera operations.
 *
 * Runs as a standalone process via app_process:
 *   adb shell "CLASSPATH=/data/app/.../base.apk app_process / \
 *       net.bladewatch.app.daemon.CameraDaemon [outputDir] [nativeLibDir]"
 *
 * Components:
 * - TcpCommandServer: JSON commands on port 19876
 * - HttpServer: Web UI and H.264 streaming on port 8080
 * - PanoramicCamera: BYD panoramic camera access
 * - VirtualView: Per-camera view cropping and encoding
 * - AccMonitor: Sentry mode when ACC goes off
 */
object CameraDaemon {

    private const val TAG = "CameraDaemon"

    // ==================== ENCRYPTED CONSTANTS (SOTA Java obfuscation) ====================
    // Decrypted at runtime via Safe.s() - AES-256-CBC with stack-based key reconstruction
    /** net.bladewatch.app */
    private fun APP_PACKAGE_NAME(): String = Safe.s("b+URlanuKqV+a8w43uR6VwE1hpEbteNkkdukhTGHkdY=")
    /** /data/local/tmp/cam_stream */
    private fun PATH_CAMERA_STREAM_DIR(): String = Safe.s("ZHx6IP38aGV/Q7iMCCcxzxuq9ag7mKGoQaOvzuwMDqM=")
    /** /sdcard/DCIM/BYDCam */
    private fun PATH_CAMERA_OUTPUT_DIR(): String = Safe.s("C6E+8XkzSNnhdgOIKBfVSXGyuhqY7qDiNp4pBP/hRuY=")
    /** /data/local/tmp/stream_mode.txt */
    private fun PATH_STREAM_MODE_FILE(): String = Safe.s("ZHx6IP38aGV/Q7iMCCcxz4A79W/sQd0NkqiGs/MIZWo=")
    /** /data/local/tmp/.byd_device_id */
    private fun PATH_DEVICE_ID_FILE(): String = Safe.s("ZHx6IP38aGV/Q7iMCCcxz8mvs/gQENVv3FEZ6OVKD54=")

    // ==================== CONFIGURATION ====================
    const val TCP_PORT = 19876
    const val HTTP_PORT = 8080
    @JvmStatic
    fun STREAM_DIR(): String = PATH_CAMERA_STREAM_DIR()
    const val APP_FILES_DIR = "/storage/emulated/0/Android/data/net.bladewatch.app/files"
    const val APP_STREAM_DIR = "/storage/emulated/0/Android/data/net.bladewatch.app/files/stream"

    // Recording config (full quality)
    const val PANO_WIDTH = 5120
    const val PANO_HEIGHT = 960
    const val VIEW_WIDTH = 1280
    const val VIEW_HEIGHT = 960
    const val FRAME_RATE = 25
    const val BITRATE = 4_000_000
    const val KEYFRAME_INTERVAL = 2
    const val SEGMENT_DURATION_MS = 2 * 60 * 1000L

    // Streaming config (SIM-optimized)
    const val STREAM_WIDTH = 640
    const val STREAM_HEIGHT = 480
    const val STREAM_JPEG_QUALITY = 70  // Increased from 40 for better quality
    const val STREAM_INTERVAL_MS = 100L

    // ==================== STATE ====================
    private val running = AtomicBoolean(true)
    private var mainHandler: Handler? = null
    private var outputDir: String? = null // Initialized in main()
    private var nativeLibDir: String? = null // Initialized in parseArguments()

    // ==================== LOGGING ====================
    private val logger = DaemonLogger.getInstance(TAG)

    // ==================== STARTUP TIMING ====================
    private var _startTime: Long = 0
    private fun logT(step: String) {
        if (!UnifiedConfigManager.isTimingLogsEnabled()) return
        val now = System.currentTimeMillis()
        log("[STARTUP +" + (now - _startTime) + "ms @" + now + "] " + step)
    }

    // ==================== SERVERS ====================
    private var tcpServer: TcpCommandServer? = null
    private var httpServer: HttpServer? = null
    private var ipcServer: SurveillanceIpcServer? = null
    private var lanDiscovery: LanDiscoveryResponder? = null
    private var accMonitor: AccMonitor? = null

    // ==================== SURVEILLANCE ====================
    private var gpuPipeline: GpuSurveillancePipeline? = null
    private var surveillanceEnabled = false
    @Volatile private var safeZoneSuppressed = false
    // Pending ACC OFF state: if ACC goes off before GPU pipeline is ready,
    // queue the request and apply it once the pipeline initializes
    @Volatile private var pendingAccOff = false

    // ==================== DOOR LOCK GATE (surveillance arm/disarm) ====================
    // Surveillance is only armed after doors are locked (reduces false triggers from owner exiting).
    @Volatile private var doorLockListenerArmed = false

    // Two parallel lock-event sources, both active simultaneously while the
    // gate is open: the device-SDK typed listener and a periodic poll. They
    // run as independent backups rather than as a fallback chain.
    private var deviceLockSubscriber: BydDataCollector.DoorLockListener? = null
    private var unlockPollThread: Thread? = null
    // Reverse watchdog: periodically queries hardware ACC state and force-
    // disables surveillance if ACC went ON without an event reaching us.
    // Symmetric counterpart to the ACC-OFF DoorLockTimeout that force-arms.
    private var accOnDisarmWatchdog: Thread? = null
    private const val ACC_ON_DISARM_POLL_INTERVAL_MS = 5_000L
    private const val DOOR_LOCK_ARM_TIMEOUT_MS = 60_000L  // 60s grace period
    private const val UNLOCK_POLL_INTERVAL_MS = 5_000L
    private const val DOOR_STATE_INVALID = 0
    private const val DOOR_STATE_UNLOCK = 1
    private const val DOOR_STATE_LOCK = 2

    // ==================== RECORDING MODE MANAGER ====================
    private var recordingModeManager: RecordingModeManager? = null

    // ==================== AVC HAL KEEP-ALIVE ====================
    // Keeps com.byd.avc alive while ACC is ON and pipeline is running.
    // Prevents BYD system from killing the camera app, which destabilizes
    // the HAL and causes "no video signal" on the native DVR.
    private var avcHalWarmup: AvcHalWarmup? = null
    private val avcWarmupLock = Any()
    @Volatile private var avcWarmupCompletedThisWindow = false
    @Volatile private var avcWarmupLastSkipReason = ""

    // ==================== STREAM MODE ====================
    const val STREAM_MODE_PRIVATE = "private"  // Local H.264 only
    const val STREAM_MODE_PUBLIC = "public"    // Tunnel access
    private var streamMode = STREAM_MODE_PRIVATE

    // ==================== DEVICE ID ====================
    private var deviceId = "unknown"

    // ==================== TRIP ANALYTICS ====================
    private var tripAnalyticsManager: TripAnalyticsManager? = null
    private var mediaCatalogManager: MediaCatalogManager? = null

    // ==================== TELEMETRY DATA COLLECTOR ====================
    private var telemetryDataCollector: TelemetryDataCollector? = null

    // ==================== SHARED APP CONTEXT ====================
    private var sharedAppContext: Context? = null

    /** Get the shared app context (for use by other components in this process). */
    @JvmStatic
    fun getAppContext(): Context? = sharedAppContext

    /** Check if the shared context is a broken fallback (null base). */
    private fun isContextBroken(): Boolean {
        val ctx = sharedAppContext ?: return true
        return isContextBrokenFor(ctx)
    }

    /** Check if a given context is a broken fallback (null base). */
    private fun isContextBrokenFor(ctx: Context?): Boolean {
        if (ctx == null) return true
        if (ctx is PermissionBypassContext) {
            return try {
                ctx.mainLooper
                false
            } catch (e: NullPointerException) {
                true
            }
        }
        return false
    }

    /**
     * Re-initialize components that depend on a valid app context.
     * Called on ACC ON after successfully recreating a broken context.
     */
    private fun reinitContextDependentComponents() {
        // Re-init BydDataCollector (was 0/17 devices with broken context)
        try {
            val collector = BydDataCollector.getInstance()
            collector.init(sharedAppContext!!)
            collector.logSummary()
            log("ACC ON: BydDataCollector re-initialized (" + (collector.data?.availableDevices?.size ?: 0) + " devices)")
        } catch (e: Exception) {
            log("ACC ON: BydDataCollector re-init failed: " + e.message)
        }

        // Re-init GearMonitor with valid context
        try {
            val gearMonitor = GearMonitor.getInstance()
            gearMonitor.init(sharedAppContext)
            telemetryDataCollector?.let { gearMonitor.setTelemetrySource(it) }
            log("ACC ON: GearMonitor re-initialized with valid context")
        } catch (e: Exception) {
            log("ACC ON: GearMonitor re-init failed: " + e.message)
        }

        // Re-init TelemetryDataCollector (BYD speed/gear/light devices were unavailable)
        try {
            telemetryDataCollector?.let {
                it.init(sharedAppContext!!)
                log("ACC ON: TelemetryDataCollector re-initialized")
            }
        } catch (e: Exception) {
            log("ACC ON: TelemetryDataCollector re-init failed: " + e.message)
        }

        // Re-init RecordingModeManager if it wasn't created (sharedAppContext was null at init time)
        val pipelineForReinit = gpuPipeline
        val contextForReinit = sharedAppContext
        if (recordingModeManager == null && pipelineForReinit != null && contextForReinit != null) {
            try {
                recordingModeManager = RecordingModeManager(contextForReinit, pipelineForReinit)
                log("ACC ON: RecordingModeManager created with valid context")
            } catch (e: Exception) {
                log("ACC ON: RecordingModeManager creation failed: " + e.message)
            }
        }

        // Re-init VehicleDataMonitor
        try {
            val vehicleMonitor = VehicleDataMonitor.getInstance()
            vehicleMonitor.init(sharedAppContext!!)
            if (!vehicleMonitor.isRunning()) {
                vehicleMonitor.start()
            }
            log("ACC ON: VehicleDataMonitor re-initialized")
        } catch (e: Exception) {
            log("ACC ON: VehicleDataMonitor re-init failed: " + e.message)
        }
    }

    // Lock file for singleton enforcement
    private const val LOCK_FILE = "/data/local/tmp/camera_daemon.lock"
    // Sentinel written after TCP/HTTP servers are confirmed listening; read by app to skip ECONNREFUSED polling
    private const val READY_SENTINEL = "/data/local/tmp/camera_daemon.ready"
    private const val SURVEILLANCE_PORT = 19877
    private var singletonLock: DaemonSingletonLock? = null

    @JvmStatic
    fun main(args: Array<String>) {
        _startTime = System.currentTimeMillis()
        initFileLogging()
        logT("initFileLogging done")

        // BladeWatch-gn2y: mark this run in cam_daemon.log, which the launcher script
        // appends to across EVERY daemon restart and never rotates. Without a boundary,
        // errors from a build that no longer exists sit alongside today's and read the
        // same — an audit on the head unit found exactly that. Straight to stdout rather
        // than through DaemonLogger, because that path is deliberately ERROR-only for this
        // very file, and a run boundary is not an error.
        println(
            SessionBanner.format(
                BuildConfig.VERSION_NAME,
                BuildConfig.GIT_BRANCH,
                BuildConfig.BUILD_TYPE,
                SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS", Locale.US).format(java.util.Date()),
                "camera-daemon"
            )
        )

        // Secondary singleton check: verify our server ports are free before
        // trusting the lock file. FileChannel.tryLock() on tmpfs can spuriously
        // succeed on some firmware, allowing a duplicate instance to start even
        // though the original daemon is running and holding all ports.
        // A port that accepts a TCP connection guarantees a live daemon is bound
        // to it — ConnectionRefused means the port is unbound/available.
        // This is safe even after a crash because TIME_WAIT sockets do NOT
        // accept new connections (connect() returns ConnectionRefused).
        if (anyPortInUse()) {
            log("ERROR: Server ports already in use — another CameraDaemon instance is running. Exiting.")
            System.exit(1)
            return
        }

        // CRITICAL: Acquire singleton lock FIRST (secondary check above already passed)
        if (!acquireSingletonLock()) {
            log("ERROR: Another CameraDaemon instance is already running. Exiting.")
            System.exit(1)
            return
        }
        logT("singletonLock acquired")

        // Report-only Frida/hook detection (uy93.9). Never enforces; disable via kill-switch file.
        RaspDetector.checkAndReport()

        // Remove any stale ready sentinel left by a previous crash before we write a new one at startup completion
        File(READY_SENTINEL).delete()

        // Enable daemon logging for StorageManager (uses DaemonLogger instead of android.util.Log)
        StorageManager.enableDaemonLogging()

        // SOTA: Fix storage permissions so UI app can read recordings
        // Note: StorageManager constructor will auto-mount SD card if configured
        val storageManager = StorageManager.getInstance()
        storageManager.fixAllPermissions()
        logT("StorageManager.fixAllPermissions done")

        // Auto-select SD card → USB → internal based on hardware presence.
        // Runs unconditionally so inserting/removing a drive between boots is
        // always reflected. Must run before startSdCardWatchdog() so the watchdog
        // knows whether any type is on SD card.
        storageManager.applyAutoStoragePriority()
        logT("applyAutoStoragePriority done")

        // Start the SD-card mount watchdog at daemon boot (instead of only on
        // ACC OFF). The watchdog no-ops when no storage type is set to SD, so
        // it's safe to start unconditionally — but it must run continuously
        // because BYD/Android can unmount the SD card at any time, including
        // while ACC is ON. Stopping it on ACC ON (the previous behavior) left
        // a hole where the HTTP server returned empty recordings until the
        // user cycled ACC OFF→ON.
        storageManager.startSdCardWatchdog()
        logT("startSdCardWatchdog done")

        // Touch the OEM-dashcam cleaner singleton so its constructor runs
        // and (if enabled in saved config) auto-starts the periodic monitor.
        // Without this the cleaner is lazy-initialized on first UI/API hit,
        // meaning a fresh boot with `enabled=true` in config never actually
        // begins reserving SD space until the user opens a settings screen.
        ExternalStorageCleaner.getInstance()
        logT("ExternalStorageCleaner.getInstance done")

        // Periodic cleanup of our own recordings/surveillance dirs — runs
        // continuously instead of only while a recording is active. This
        // catches the case where the daemon crashed mid-recording leaving
        // the dir at 95%, or the user lowered the size limit while nothing
        // was recording. Cost: one directory walk every 30s; the threshold
        // check exits early if usage is below 90%.
        storageManager.startPeriodicCleanup()
        logT("startPeriodicCleanup done")

        log("=== CAMERA DAEMON STARTING ===")
        log("PID: " + Process.myPid() + ", UID: " + Process.myUid())
        log("ClassPath: " + System.getProperty("java.class.path", "unknown"))

        // Grant all manifest permissions via shell (supplements PermissionBypassContext)
        PermissionGranter.grantAllPermissions(APP_PACKAGE_NAME())
        logT("PermissionGranter.grantAllPermissions done")

        // Global exception handler - NEVER let the daemon die from uncaught exceptions
        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            if (throwable !is ThreadDeath) {
                log("FATAL: Uncaught exception in " + thread.name + ": " + throwable.message)
                throwable.cause?.let { log("  Cause: " + it.message) }
                // Log stack trace
                for (element in throwable.stackTrace) {
                    log("    at $element")
                }
                // DO NOT kill the daemon - just log and continue
                // The daemon should stay alive even if individual operations fail
            }
        }

        if (Looper.myLooper() == null) Looper.prepare()
        mainHandler = Handler(Looper.myLooper()!!)

        // Parse arguments (sets outputDir if provided)
        parseArguments(args)

        // Initialize outputDir if not set by arguments
        if (outputDir == null) {
            outputDir = PATH_CAMERA_OUTPUT_DIR()
        }

        // Load native libraries
        loadNativeLibraries()
        logT("loadNativeLibraries done")

        // Create directories
        File(outputDir!!).mkdirs()
        File(STREAM_DIR()).mkdirs()
        File(APP_STREAM_DIR).mkdirs()

        // Generate device ID
        generateDeviceId()
        logT("generateDeviceId done")

        log("Output dir: $outputDir")
        log("Device ID: $deviceId")

        // Camera scan disabled — opening/closing all camera IDs can briefly
        // disrupt the BYD dashcam. Camera ID is auto-detected in GpuSurveillancePipeline.init()
        // scanCameras();

        // BladeWatch-078u: move the secret store off the legacy sdcardfs path
        // before anything reads it. Only this process can — the app UID cannot
        // create files in /data/local/tmp — and a device that only ever READS
        // would otherwise leave the plaintext copy on sdcardfs, where any
        // process in sdcard_rw can read it. Deliberately before the servers
        // start, so the first auth read already sees the owner-only file.
        try {
            if (SecretConfigStore().migrateFromLegacyIfNeeded()) {
                logT("SecretConfigStore migrated off the legacy sdcardfs path")
            }
        } catch (e: Exception) {
            // Never fatal: a failed migration leaves the legacy file in place
            // and the read fallback still finds it. NOTE no secret value is
            // logged here, only the fact of failure.
            log("SecretConfigStore migration failed: " + e.message)
        }

        // Generate IPC shared-secret before starting servers
        IpcTokenManager.generate()
        logT("IpcTokenManager.generate done")

        // Start servers
        val tcp = TcpCommandServer(TCP_PORT)
        tcpServer = tcp
        val http = HttpServer(HTTP_PORT)
        httpServer = http
        val ipc = SurveillanceIpcServer(19877)
        ipcServer = ipc
        val acc = AccMonitor()
        accMonitor = acc

        // Register Connect protocol service implementations
        val cd = http.connectDispatcher
        AuthServiceImpl().register(cd)
        NotificationsServiceImpl().register(cd)
        SettingsServiceImpl().register(cd)
        StreamServiceImpl().register(cd)
        StorageServiceImpl().register(cd)
        VehicleServiceImpl().register(cd)
        SurveillanceServiceImpl().register(cd)
        SafeLocationsServiceImpl().register(cd)
        TripsServiceImpl().register(cd)
        RecordingsServiceImpl().register(cd)
        SystemServiceImpl(http).register(cd)
        logT("Connect service impls registered")

        // Init app context. This will break the app if run in a thread
        if (sharedAppContext == null) {
            try {
                sharedAppContext = createAppContext()
            } catch (t: Throwable) {
                log("WARN: createAppContext threw: " + t.message)
            }
        }
        logT("createAppContext done")

        // Notifications subsystem — registry, push subscriptions, sinks.
        // Lives in this process because HttpServer (where the API routes bind)
        // runs here, and every v1 emit source (surveillance, proximity, tyre)
        // lives here too. Init on a background thread because reading APK
        // assets can take a moment and we don't want to delay HTTP startup.
        Thread({
            try {
                initNotifications()
            } catch (e: Exception) {
                log("Notifications init failed: " + e.message)
            }
        }, "NotificationsInit").start()
        logT("NotificationsInit thread started (async)")

        // SOTA: Initialize unified config manager (handles migration from legacy configs)
        UnifiedConfigManager.init()
        logT("UnifiedConfigManager.init done")

        // Load persisted quality settings BEFORE initializing surveillance
        // This ensures the encoder is created with the correct settings
        HttpServer.loadPersistedSettings()
        logT("HttpServer.loadPersistedSettings done")

        // Note: there is no version file any more. The in-app updater that used
        // to write /data/local/tmp/bladewatch_version after an install has been
        // removed, and the status endpoint now reports BuildConfig.VERSION_NAME
        // directly.

        // ImageReader FPS probe sentinel: when /data/local/tmp/run_imagereader_probe
        // exists, run AvmImageReaderFpsProbe BEFORE initSurveillance so the probe
        // has exclusive HAL access. Verifies whether replacing the live pipeline's
        // SurfaceTexture consumer with an ImageReader unblocks the ~8.5 fps panoramic
        // throttle (see CAMERA_FPS_INVESTIGATION.md). Sentinel is consumed (deleted)
        // so the probe runs once per `touch` invocation.
        try {
            val irProbeSentinel = File("/data/local/tmp/run_imagereader_probe")
            if (irProbeSentinel.exists()) {
                log("=== ImageReader probe sentinel detected — running probe ===")
                val irProbeDir = File("/data/local/tmp/imagereader_probe")
                net.bladewatch.app.camera.AvmImageReaderFpsProbe(irProbeDir).run()
                if (!irProbeSentinel.delete()) {
                    log("WARN: Could not delete ImageReader probe sentinel $irProbeSentinel")
                }
                log("=== ImageReader probe finished — continuing with normal startup ===")
            }
        } catch (t: Throwable) {
            log("ImageReader probe invocation failed: " + t.message)
        }

        // Initialize surveillance module (will use loaded settings)
        logT("initSurveillance BEGIN")
        initSurveillance()
        logT("initSurveillance done")

        // Apply persisted settings to GPU pipeline (for runtime changes)
        // Note: Codec/bitrate are already applied during init, but this ensures
        // the config object is in sync and handles any settings that need runtime application
        applyPersistedSettings()
        logT("applyPersistedSettings done")

        // If ACC went OFF before pipeline was ready, apply it now
        // RACE CONDITION FIX: Also verify ACC is still OFF before applying.
        // If ACC turned ON during pipeline init, the pending state is stale.
        if (pendingAccOff && gpuPipeline != null) {
            if (!AccMonitor.isAccOn()) {
                log("Applying pending ACC OFF surveillance request...")
                pendingAccOff = false
                onAccStateChanged(true)
            } else {
                log("Pending ACC OFF discarded — ACC is now ON (race condition guard)")
                pendingAccOff = false
            }
        }

        Thread(tcp::start, "TcpServer").start()
        Thread(http::start, "HttpServer").start()
        Thread(ipc, "SurveillanceIPC").start()
        // BladeWatch-rdtj.5: answers signed LAN probes; idles unbound until LAN access is on.
        val discovery = LanDiscoveryResponder(
            probeKey = { LanDiscoveryResponder.probeKey(SecretConfigStore()) },
            replyInfo = {
                AuthManager.getState()?.deviceId?.let { id ->
                    LanDiscoveryResponder.ReplyInfo(
                        LanTls.loadOrCreate(SecretConfigStore()).fingerprintSha256, id
                    )
                }
            },
            enabled = { UnifiedConfigManager.isLanHttpEnabled() },
        )
        lanDiscovery = discovery
        Thread(discovery::run, "LanDiscovery").start()
        Thread(acc::start, "AccMonitor").start()
        logT("server threads started (TcpServer, HttpServer, SurveillanceIPC, AccMonitor)")

        // Initialize GPS monitor with app context for standard LocationManager access
        initGpsMonitor()
        logT("initGpsMonitor done")

        // Initialize Safe Location Manager (geofence zones)
        SafeLocationManager.getInstance().init()
        logT("SafeLocationManager.init done")

        // Initialize Vehicle Data Monitor + BydDataCollector
        logT("initVehicleDataMonitor BEGIN")
        initVehicleDataMonitor()
        logT("initVehicleDataMonitor done")

        // Initialize Trip Analytics
        try {
            log("Initializing Trip Analytics...")
            logT("TripAnalyticsManager.init BEGIN")
            val tam = TripAnalyticsManager()
            tripAnalyticsManager = tam
            tam.init(sharedAppContext, telemetryDataCollector)
            log("Trip Analytics initialized (enabled=" + tam.isEnabled() + ")")
            logT("TripAnalyticsManager.init done")

            // Media catalog (H2 index of recordings/surveillance/proximity).
            // No boot-time reconcile — a large initial scan would block daemon
            // start; the catalog auto-rebuilds lazily on the first empty read.
            try {
                val mcm = MediaCatalogManager()
                mediaCatalogManager = mcm
                mcm.init()
                log("Media catalog initialized (available=" + mcm.isAvailable + ")")
                logT("MediaCatalogManager.init done")
            } catch (e: Exception) {
                log("Media catalog init failed: " + e.message)
            }

            // If the SD card mounted successfully for this boot (applyAutoStoragePriority()
            // ran earlier in main(), before either manager above existed), sweep any files
            // stranded on internal storage from a prior boot's mount failure over to it now.
            // Runs in the background — a directory scan + a handful of file moves must not
            // delay daemon startup, and both managers this depends on are ready by this point.
            if (storageManager.isSdCardAvailable) {
                val migrateThread = Thread({
                    try {
                        val mcm = mediaCatalogManager
                        InternalToSdMigrator.migrate(
                            storageManager,
                            tam.getDatabase(),
                            if (mcm != null) Runnable { mcm.reconcile() } else null
                        )
                    } catch (e: Exception) {
                        log("Internal-to-SD migration failed: " + e.message)
                    }
                }, "internal-to-sd-migration")
                migrateThread.isDaemon = true
                // Internal->SD moves cross filesystems, so every file falls back to slow
                // copy-then-delete (a real device backlog of ~900 files took well over an hour).
                // Low priority so this never contends with the active recording/camera pipeline
                // for I/O or CPU.
                migrateThread.priority = Thread.MIN_PRIORITY
                migrateThread.start()
            }

            // ONE-TIME migration: Clear poisoned consumption buckets if this is a PHEV
            // and the migration hasn't been done yet. Old trips may have been recorded
            // with wrong nominal capacity (e.g., 60 kWh BEV default instead of 18.3 kWh PHEV).
            // This must only run ONCE — running it every startup wipes all accumulated
            // consumption data, which makes the personalized range estimator return null
            // until enough new trips rebuild the buckets (minimum 3 samples per bucket).
            // Capacity is sourced from BYD-local nominal capacity (VehicleDataMonitor).
            var nominalKwh = 0.0
            try {
                nominalKwh = VehicleDataMonitor.getInstance().getNominalCapacityKwh()
            } catch (ignored: Exception) {
            }
            val bucketMigrationMarker = File("/data/local/tmp/bladewatch_bucket_migration_done")
            if (nominalKwh > 0 && nominalKwh < 30.0 && tam.getDatabase() != null && !bucketMigrationMarker.exists()) {
                tam.getDatabase()!!.clearConsumptionBuckets()
                log("One-time PHEV bucket migration: cleared poisoned consumption data")
                try {
                    FileWriter(bucketMigrationMarker).close()
                } catch (e: Exception) {
                    log("WARNING: Could not write bucket migration marker: " + e.message)
                }
            }

            // AUTO-START: If gear is already in a driving position (not P), start trip
            // recording immediately. This handles the case where CameraDaemon restarts
            // mid-drive (e.g., EGL crash watchdog, manual restart) or starts after the
            // driver has already shifted out of P.
            if (tam.isEnabled()) {
                try {
                    val currentGear = GearMonitor.getInstance().currentGear
                    if (currentGear != GearMonitor.GEAR_P) {
                        log(
                            "Trip Analytics: non-P gear detected at startup (gear=" +
                                GearMonitor.gearToString(currentGear) + ") — auto-starting trip recording"
                        )
                        tam.onGearChanged(currentGear)
                    }
                } catch (e: Exception) {
                    log("Trip Analytics gear probe error: " + e.message)
                }
            }
        } catch (e: Exception) {
            log("Trip Analytics init error: " + e.message)
        }

        // Initialize OdometerReader for trip distance
        try {
            OdometerReader.getInstance().init(sharedAppContext!!)
        } catch (e: Exception) {
            log("OdometerReader init error: " + e.message)
        }
        logT("OdometerReader.init done")

        // Restore stream mode from previous session
        loadStreamMode()
        logT("loadStreamMode done")

        // RECOVERY: Probe ACC state directly from hardware.
        // If CameraDaemon was restarted (e.g., EGL crash watchdog) while ACC was off,
        // AccSentryDaemon won't re-send the ACC OFF command. Reading the hardware
        // directly has zero dependency on AccSentryDaemon.
        try {
            val accIsOff = AccMonitor.probeAccState(sharedAppContext!!)
            if (accIsOff) {
                log("RECOVERY: Hardware probe shows ACC OFF — entering sentry mode")
                onAccStateChanged(true) // true = accIsOff
            }
        } catch (e: Exception) {
            log("ACC hardware probe error: " + e.message)
        }
        logT("ACC hardware probe done")

        log("Daemon ready on TCP:$TCP_PORT HTTP:$HTTP_PORT")
        logT("=== CAMERA DAEMON READY ===")

        // Confirm TCP_PORT is actually accepting connections before writing the sentinel.
        // The TcpServer thread was started ~115 lines above but may not have completed bind() yet.
        // Poll up to 5s; proceed anyway (with a warning) if the port never confirms, to avoid
        // blocking daemon startup indefinitely.
        run {
            val portCheckDeadline = System.currentTimeMillis() + 5000
            var portConfirmed = false
            while (System.currentTimeMillis() < portCheckDeadline) {
                try {
                    Socket().use { probe ->
                        probe.connect(InetSocketAddress("127.0.0.1", TCP_PORT), 500)
                        portConfirmed = true
                    }
                    if (portConfirmed) break
                } catch (ignored: Exception) {
                }
                try {
                    Thread.sleep(200)
                } catch (ie: InterruptedException) {
                    Thread.currentThread().interrupt()
                    return@run
                }
            }
            if (!portConfirmed) {
                log("WARNING: TCP:$TCP_PORT did not confirm within 5s before writing ready sentinel")
            }
        }

        // Write ready sentinel so the Android app can detect startup completion without polling ports.
        // setReadable(true, false) makes the file world-readable (644) so the app UID can read it;
        // FileWriter creates files mode 600 by default which the app UID cannot access.
        try {
            val fw = FileWriter(READY_SENTINEL, false)
            fw.write(Process.myPid().toString())
            fw.close()
            if (!File(READY_SENTINEL).setReadable(true, false)) {
                log("WARNING: Failed to set ready sentinel world-readable; app UID may not be able to read it")
            }
        } catch (e: Exception) {
            log("Failed to write ready sentinel: " + e.message)
        }

        // RESILIENT LOOPER: BYD framework listeners (gearbox, bodywork, etc.) can throw
        // uncaught exceptions from their internal processing (e.g., learningEPB → CarSettings
        // UID mismatch). These exceptions escape through Handler.dispatchMessage and kill
        // Looper.loop(). Wrapping in a retry loop keeps the daemon alive.
        while (running.get()) {
            try {
                Looper.loop()
                // Looper.loop() only returns if someone calls quit()
                break
            } catch (t: Throwable) {
                log("LOOPER CRASH (recovered): " + t.javaClass.simpleName + ": " + t.message)
                t.cause?.let { log("  Cause: " + it.message) }
                // Log first 5 stack frames
                val stack = t.stackTrace
                for (i in 0 until Math.min(5, stack.size)) {
                    log("    at " + stack[i])
                }
                // Continue looping — the Looper is still valid, just the current message failed
            }
        }
    }

    /**
     * Applies persisted settings to the GPU pipeline after initialization.
     */
    private fun applyPersistedSettings() {
        val pipeline = gpuPipeline ?: return

        try {
            // Apply bitrate setting to config and encoder
            val bitrate = HttpServer.getRecordingBitrate()
            if (bitrate != null) {
                setRecordingBitrate(bitrate)
                log("Applied persisted bitrate: $bitrate")
            }

            // Apply codec setting to config (encoder already created with this codec)
            val codec = HttpServer.getRecordingCodec()
            if (codec != null) {
                // Just update the config, don't reinitialize encoder
                val videoCodec = when (codec.uppercase()) {
                    "H265", "HEVC" -> GpuPipelineConfig.VideoCodec.H265
                    else -> GpuPipelineConfig.VideoCodec.H264
                }
                pipeline.config.setVideoCodec(videoCodec)
                log("Applied persisted codec: $codec")
            }

            // Apply quality settings
            val recQuality = HttpServer.getRecordingQuality()
            if (recQuality != null) {
                setRecordingQuality(recQuality)
                log("Applied persisted recording quality: $recQuality")
            }

            val streamQuality = HttpServer.getStreamingQuality()
            if (streamQuality != null) {
                setStreamingQuality(streamQuality)
                log("Applied persisted streaming quality: $streamQuality")
            }
        } catch (e: Exception) {
            log("Error applying persisted settings: " + e.message)
        }
    }

    // ==================== CAMERA MANAGEMENT ====================

    @JvmStatic
    fun startCamera(viewId: Int, enableStreaming: Boolean, viewOnly: Boolean) {
        if (viewId < 1 || viewId > 4) {
            log("ERROR: Invalid view ID: $viewId")
            return
        }

        log("Starting camera $viewId (GPU mosaic recording, viewOnly=$viewOnly)")

        // GPU pipeline handles all cameras together
        val pipeline = gpuPipeline
        if (pipeline != null && !pipeline.isRunning) {
            if (AccMonitor.isAccOn()) {
                Thread({
                    ensureAvcWarmupStarted("CameraDaemon.startCamera")
                    startPipelineInternal(viewId, viewOnly)
                }, "CameraWarmup").start()
            } else {
                startPipelineInternal(viewId, viewOnly)
            }
        } else if (pipeline != null && pipeline.isRunning) {
            // Pipeline already running - start recording if requested (stops surveillance)
            if (!viewOnly) {
                log("Pipeline already running - starting normal recording (stops surveillance if active)")
                pipeline.startRecording()
            } else {
                log("Pipeline already running for camera $viewId (view-only)")
            }
        }
    }

    /**
     * Internal: starts the GPU pipeline after any warmup delay.
     */
    private fun startPipelineInternal(viewId: Int, viewOnly: Boolean) {
        val pipeline = gpuPipeline
        if (pipeline == null || pipeline.isRunning) return
        try {
            pipeline.start(!viewOnly)
            log("GPU pipeline started for camera $viewId")

            if (!viewOnly) {
                log("Auto-recording enabled (will start when recorder ready)")
            } else {
                log("View-only mode - recording NOT started")
            }

            // Start AVC keep-alive if ACC is ON
            startAvcKeepAliveIfNeeded()
        } catch (e: Exception) {
            log("ERROR: Failed to start GPU pipeline: " + e.message)
        }
    }

    @JvmStatic
    @JvmOverloads
    fun stopCamera(viewId: Int, forceStop: Boolean = false) {
        try {
            log("Stopping camera $viewId (GPU pipeline)")

            // GPU pipeline handles all cameras
            // Only stop if forcing
            if (forceStop && gpuPipeline != null) {
                gpuPipeline!!.stop()
                stopAvcKeepAlive()
                log("GPU pipeline stopped")
            }
        } catch (e: Exception) {
            log("ERROR: Exception in stopCamera($viewId): " + e.message)
        }
    }

    /**
     * Force stop a camera, even if recording.
     * Use this when user explicitly wants to stop everything.
     */
    @JvmStatic
    fun forceStopCamera(viewId: Int) {
        stopCamera(viewId, true)
    }

    @JvmStatic
    @JvmOverloads
    fun stopAllCameras(forceStop: Boolean = true) {
        log("Stopping all cameras (GPU pipeline, force=$forceStop)")
        if (forceStop && gpuPipeline != null) {
            gpuPipeline!!.stop()
            stopAvcKeepAlive()
        }
    }

    // GPU pipeline handles camera internally - no separate camera management needed

    // ==================== AVC HAL KEEP-ALIVE ====================

    /**
     * Starts the AVC keep-alive watchdog if the pipeline is running.
     *
     * Runs regardless of ACC state. When ACC is OFF and the head unit stays
     * awake (charging, sentry mode), the system can reap com.byd.avc and the
     * AVM HAL goes cold — surface stays attached, onFrameAvailable still ticks,
     * but the cameras deliver all-zero buffers. Keeping com.byd.avc warm
     * prevents that black-frame state.
     */
    @JvmStatic
    fun startAvcKeepAliveIfNeeded() {
        var warmup = avcHalWarmup
        if (warmup == null) {
            warmup = AvcHalWarmup()
            avcHalWarmup = warmup
        }
        val pipeline = gpuPipeline
        if (pipeline != null && pipeline.isRunning) {
            if (!warmup.isActive) {
                warmup.startKeepAlive()
                log("AVC keep-alive started (pipeline running, accOn=" + AccMonitor.isAccOn() + ")")
            }
        }
    }

    /**
     * Ensures the AVC warmup ran for the current cold-start window.
     * Returns true when warmup is already satisfied or completed successfully,
     * false only when the actual warmup attempt failed.
     */
    @JvmStatic
    fun ensureAvcWarmupStarted(reason: String): Boolean {
        synchronized(avcWarmupLock) {
            var warmup = avcHalWarmup
            if (warmup == null) {
                warmup = AvcHalWarmup()
                avcHalWarmup = warmup
            }

            val pipeline = gpuPipeline
            if (pipeline != null && pipeline.isRunning) {
                avcWarmupLastSkipReason = "pipeline already running"
                log("AVC warmup skipped ($reason): $avcWarmupLastSkipReason")
                return true
            }

            if (avcWarmupCompletedThisWindow && warmup.lastResult) {
                avcWarmupLastSkipReason = "already completed this cold-start window"
                log("AVC warmup skipped ($reason): $avcWarmupLastSkipReason")
                return true
            }

            val ok = warmup.warmupAndWait(reason)
            if (ok) {
                avcWarmupCompletedThisWindow = true
                avcWarmupLastSkipReason = ""
            }
            return ok
        }
    }

    private fun resetAvcWarmupWindow(reason: String) {
        synchronized(avcWarmupLock) {
            avcWarmupCompletedThisWindow = false
            avcWarmupLastSkipReason = ""
            log("AVC warmup window reset ($reason)")
        }
    }

    /**
     * Stops the AVC keep-alive watchdog.
     * Called when pipeline stops or daemon shuts down.
     */
    @JvmStatic
    fun stopAvcKeepAlive() {
        val warmup = avcHalWarmup
        if (warmup != null && warmup.isActive) {
            warmup.stopKeepAlive()
            log("AVC keep-alive stopped")
        }
        resetAvcWarmupWindow("keep-alive stopped")
    }

    @JvmStatic
    fun isAvcWarmupAvailable(): Boolean = avcHalWarmup != null

    @JvmStatic
    fun getAvcWarmupLastStartedAtMs(): Long = avcHalWarmup?.lastStartedAtMs ?: 0L

    @JvmStatic
    fun getAvcWarmupLastResult(): Boolean = avcHalWarmup?.lastResult == true

    @JvmStatic
    fun isAvcWarmupKeepAliveActive(): Boolean = avcHalWarmup?.isActive == true

    @JvmStatic
    fun getAvcWarmupLastReason(): String = avcHalWarmup?.lastReason ?: ""

    @JvmStatic
    fun getAvcWarmupLastSkippedReason(): String = avcWarmupLastSkipReason

    // ==================== GETTERS ====================

    @JvmStatic
    fun getVirtualViews(): Map<Int, Any> {
        // GPU pipeline doesn't use VirtualView - return empty map for compatibility
        return HashMap()
    }

    @JvmStatic
    fun isRunning(): Boolean = running.get()

    /**
     * Sentinel file that signals the shell watchdog wrapper to NOT restart the daemon.
     * Written by shutdown() when the daemon is intentionally disabled (UI).
     * The watchdog script checks for this file before each restart attempt.
     * To re-enable, delete this file and start the watchdog script again.
     */
    private const val DISABLE_SENTINEL = "/data/local/tmp/camera_daemon.disabled"

    @JvmStatic
    fun shutdown() {
        log("Shutdown requested — writing disable sentinel and cleaning up...")
        running.set(false)

        // Stop AVC keep-alive immediately
        stopAvcKeepAlive()

        // Write disable sentinel FIRST — this tells the shell watchdog wrapper
        // to NOT restart the daemon after we exit. Without this, the wrapper
        // sees exit code 0 and respawns us immediately.
        writeDisableSentinel()

        // Cancel PermissionGranter to stop orphaned pm grant processes
        PermissionGranter.cancel()

        // Stop cameras and GPU pipeline
        stopAllCameras()
        gpuPipeline?.let {
            try {
                it.stop()
            } catch (e: Exception) {
                log("GPU pipeline stop error: " + e.message)
            }
        }

        // Stop all monitors
        try {
            VehicleDataMonitor.getInstance().stop()
        } catch (e: Exception) {
            log("WARN: VehicleDataMonitor stop failed: " + e.message)
        }
        try {
            GpsMonitor.getInstance().stop()
        } catch (e: Exception) {
            log("WARN: GpsMonitor stop failed: " + e.message)
        }
        try {
            GearMonitor.getInstance().stop()
        } catch (e: Exception) {
            log("WARN: GearMonitor stop failed: " + e.message)
        }
        try {
            PerformanceMonitor.getInstance().stop()
        } catch (e: Exception) {
            log("WARN: PerformanceMonitor stop failed: " + e.message)
        }
        try {
            SocHistoryDatabase.getInstance().stop()
        } catch (e: Exception) {
            log("WARN: SocHistoryDatabase stop failed: " + e.message)
        }

        // Stop services
        tripAnalyticsManager?.shutdown()
        mediaCatalogManager?.shutdown()
        tcpServer?.stop()
        httpServer?.stop()
        ipcServer?.stop()
        lanDiscovery?.stop()

        // Shutdown StorageManager (schedulers, executors)
        try {
            StorageManager.getInstance().shutdown()
        } catch (e: Exception) {
            log("WARN: StorageManager shutdown failed: " + e.message)
        }

        // Release singleton lock
        releaseSingletonLock()

        log("Daemon shutdown complete — killing self (watchdog will NOT restart)")

        // Also kill the shell watchdog wrapper process directly.
        // The sentinel file prevents restart, but killing the wrapper ensures
        // it doesn't linger as an idle process.
        killWatchdogWrapper()

        Process.killProcess(Process.myPid())
    }

    /**
     * Write the disable sentinel file that tells the shell watchdog wrapper
     * to stop restarting the daemon.
     */
    private fun writeDisableSentinel() {
        try {
            val fw = FileWriter(DISABLE_SENTINEL)
            fw.write("disabled at " + SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US).format(java.util.Date()) + "\n")
            fw.write("pid=" + Process.myPid() + "\n")
            fw.close()
            log("Disable sentinel written: $DISABLE_SENTINEL")
        } catch (e: Exception) {
            log("WARNING: Failed to write disable sentinel: " + e.message)
        }
    }

    /**
     * Kill the shell watchdog wrapper process (start_cam_daemon.sh).
     * Uses the PID file if available, falls back to pkill.
     */
    private fun killWatchdogWrapper() {
        try {
            // Try PID file first
            val pidFile = File("/data/local/tmp/cam_watchdog.pid")
            if (pidFile.exists()) {
                val pid = Scanner(pidFile).useDelimiter("\\A").next().trim()
                Runtime.getRuntime().exec(arrayOf("kill", "-9", pid))
                log("Killed watchdog wrapper via PID file (pid=$pid)")
                pidFile.delete()
            }
            // Also pkill as fallback
            Runtime.getRuntime().exec(arrayOf("pkill", "-9", "-f", "start_cam_daemon"))
            // Delete the script so it can't be accidentally re-run
            File("/data/local/tmp/start_cam_daemon.sh").delete()
        } catch (e: Exception) {
            log("Watchdog wrapper kill error (non-fatal): " + e.message)
        }
    }

    /**
     * Check if the daemon has been intentionally disabled.
     * Called by the shell watchdog wrapper before restarting.
     * Also callable from Java to check state.
     */
    @JvmStatic
    fun isDisabledBySentinel(): Boolean = File(DISABLE_SENTINEL).exists()

    /**
     * Acquire a file lock to ensure only one daemon instance runs at a time.
     * Uses Java NIO FileLock which is process-safe.
     */
    private fun acquireSingletonLock(): Boolean {
        // BladeWatch-8d5u: the stale-lock handling that used to live inline here is the
        // ORIGINAL — it was learned on this hardware and was extracted verbatim into
        // DaemonSingletonLock, which is now the single copy shared with SentryDaemon and
        // AccSentryDaemon. Behaviour is unchanged: a lock naming a dead PID, junk, or our own
        // PID is reclaimed after a 200ms pause for the kernel to drop the inode lock, and a
        // live rival is named by PID in the log.
        val lock = DaemonSingletonLock(
            File(LOCK_FILE),
            Process.myPid(),
            DaemonSingletonLock.PROC_LIVENESS
        ) { msg -> log(msg) }
        singletonLock = lock
        if (!lock.acquire()) return false

        log("Acquired singleton lock (PID: " + Process.myPid() + ")")

        return try {
            // Register shutdown hook to release lock and clean up ALL resources on process termination.
            // CRITICAL: System.exit(0) from the GL watchdog skips normal cleanup.
            // Without this, the MediaCodec encoder, EGL context, camera HAL connection,
            // and TFLite GPU delegate leak across restarts. After 3-4 rapid restarts,
            // the Adreno 610 runs out of GPU contexts and the hardware encoder exhausts
            // its codec instance limit, causing system-level freezes.
            Runtime.getRuntime().addShutdownHook(Thread({
                log("Shutdown hook: cleaning up all resources...")

                // 1. Stop PermissionGranter — prevent orphaned pm grant processes
                //    from continuing to hammer PMS after we exit
                try {
                    PermissionGranter.cancel()
                } catch (e: Exception) {
                    log("Shutdown hook: PermissionGranter cancel error: " + e.message)
                }

                // 2. Stop the GPU pipeline (releases MediaCodec encoder slot, camera HAL, EGL).
                //    The encoder.release() and closeCamera() are synchronous.
                //    releaseGl() is posted to the GL thread which may be blocked — that's
                //    acceptable because EGL contexts are destroyed when the process exits.
                try {
                    gpuPipeline?.let {
                        it.stop()
                        log("Shutdown hook: GPU pipeline stopped")
                    }
                } catch (e: Exception) {
                    log("Shutdown hook: GPU pipeline cleanup error: " + e.message)
                }

                // 3. Stop all monitors (VehicleDataMonitor, GpsMonitor, GearMonitor,
                //    PerformanceMonitor) — these hold BYD device listeners and schedulers
                try {
                    VehicleDataMonitor.getInstance().stop()
                } catch (e: Exception) {
                    log("Shutdown hook: VehicleDataMonitor stop: " + e.message)
                }
                try {
                    GpsMonitor.getInstance().stop()
                } catch (e: Exception) {
                    log("Shutdown hook: GpsMonitor stop: " + e.message)
                }
                try {
                    GearMonitor.getInstance().stop()
                } catch (e: Exception) {
                    log("Shutdown hook: GearMonitor stop: " + e.message)
                }
                try {
                    PerformanceMonitor.getInstance().stop()
                } catch (e: Exception) {
                    log("Shutdown hook: PerformanceMonitor stop: " + e.message)
                }

                // 4. Close SOC History Database (H2 JDBC connection + scheduler)
                try {
                    SocHistoryDatabase.getInstance().stop()
                } catch (e: Exception) {
                    log("Shutdown hook: SocHistoryDatabase stop: " + e.message)
                }

                // 5. Stop services (Trip Analytics + Media catalog)
                try {
                    tripAnalyticsManager?.shutdown()
                } catch (e: Exception) {
                    log("Shutdown hook: tripAnalyticsManager shutdown: " + e.message)
                }
                try {
                    mediaCatalogManager?.shutdown()
                } catch (e: Exception) {
                    log("Shutdown hook: mediaCatalogManager shutdown: " + e.message)
                }

                // 6. Stop servers (TCP, HTTP, IPC)
                try {
                    tcpServer?.stop()
                } catch (e: Exception) {
                    log("Shutdown hook: tcpServer stop: " + e.message)
                }
                try {
                    httpServer?.stop()
                } catch (e: Exception) {
                    log("Shutdown hook: httpServer stop: " + e.message)
                }
                try {
                    ipcServer?.stop()
                } catch (e: Exception) {
                    log("Shutdown hook: ipcServer stop: " + e.message)
                }

                // 7. Shutdown StorageManager (schedulers, executors, SD card watchdog)
                try {
                    StorageManager.getInstance().shutdown()
                } catch (e: Exception) {
                    log("Shutdown hook: StorageManager shutdown: " + e.message)
                }

                // 8. Release singleton lock (must be last)
                releaseSingletonLock()
                log("Shutdown hook: cleanup complete")
            }, "DaemonShutdown"))

            true
        } catch (e: java.nio.channels.OverlappingFileLockException) {
            // Lock already held by this JVM (shouldn't happen but handle it)
            log("Lock already held by this process")
            false
        } catch (e: Exception) {
            // Don't fall back to port checks — TCP sockets linger in TIME_WAIT
            // long after the daemon dies and would cause spurious "already
            // running" decisions during a fast retry loop. If we can't take
            // the lock, admit defeat and let the watchdog back off.
            log("Failed to acquire singleton lock: " + e.message)
            false
        }
    }

    /**
     * Release the singleton lock on shutdown.
     */
    private fun releaseSingletonLock() {
        try {
            singletonLock?.release()
            // The lock FILE is deliberately no longer deleted — unlinking a path another
            // process may already hold a lock on is the classic double-winner race, see
            // DaemonSingletonLock.release() (BladeWatch-8d5u). The READY SENTINEL is a
            // different thing entirely and must still go: readiness probes treat its presence
            // as "this daemon is up", so leaving it behind would advertise a dead daemon.
            File(READY_SENTINEL).delete()
            log("Released singleton lock")
        } catch (e: Exception) {
            log("Error releasing singleton lock: " + e.message)
        }
    }

    /**
     * Check if any of the daemon's server ports is already bound and accepting
     * connections. Used as a secondary singleton guard alongside the lock file
     * because FileChannel.tryLock() can be unreliable on some tmpfs mounts.
     *
     * Uses TCP connect() (not ServerSocket bind) so TIME_WAIT sockets from a
     * crash are correctly reported as free — they don't accept new connections.
     */
    private fun anyPortInUse(): Boolean {
        val ports = intArrayOf(TCP_PORT, HTTP_PORT, SURVEILLANCE_PORT)
        for (port in ports) {
            try {
                Socket().use { s ->
                    s.connect(InetSocketAddress("127.0.0.1", port), 500)
                    log("Port verification: $port is in use (another daemon is listening)")
                    return true
                }
            } catch (e: java.net.ConnectException) {
                // Port is not listening — expected for free ports
            } catch (e: Exception) {
                log("Port verification: could not check port $port: " + e.message)
            }
        }
        return false
    }

    @JvmStatic
    fun getMainHandler(): Handler? = mainHandler

    @JvmStatic
    fun getOutputDir(): String? = outputDir

    @JvmStatic
    fun getDeviceId(): String = deviceId

    @JvmStatic
    fun getTripAnalyticsManager(): TripAnalyticsManager? = tripAnalyticsManager

    @JvmStatic
    fun getMediaCatalogManager(): MediaCatalogManager? = mediaCatalogManager

    // ==================== SURVEILLANCE CONTROL ====================

    /**
     * Initialize surveillance with hardware encoding.
     * CPU usage: ~20% during recording
     */
    private fun initSurveillance() {
        try {
            log("Initializing GPU Surveillance Pipeline...")

            // SOTA: Use StorageManager for surveillance output directory
            val storageManager = StorageManager.getInstance()
            val eventDir = storageManager.surveillanceDir

            // Create GPU pipeline
            val pipeline = GpuSurveillancePipeline(PANO_WIDTH, PANO_HEIGHT, eventDir)
            gpuPipeline = pipeline

            // Get AssetManager from the app's APK
            // Since we're running as app_process, load model from filesystem
            var assetManager: AssetManager? = null
            try {
                // Try to create AssetManager from APK path
                val classpath = System.getenv("CLASSPATH")
                log("CLASSPATH: $classpath")

                // Extract the app APK path (not framework jars)
                var apkPath: String? = null
                if (classpath != null) {
                    val paths = classpath.split(":")
                    for (path in paths) {
                        if (path.contains("net.bladewatch.app") && path.endsWith(".apk")) {
                            apkPath = path
                            break
                        }
                    }
                }

                if (apkPath != null) {
                    val mgr = AssetManager::class.java.getDeclaredConstructor().newInstance()
                    val addAssetPath = AssetManager::class.java.getDeclaredMethod("addAssetPath", String::class.java)
                    val cookie = addAssetPath.invoke(mgr, apkPath) as Int

                    if (cookie != 0) {
                        assetManager = mgr
                        log("AssetManager created from APK: $apkPath")

                        // Extract web assets for HTTP server
                        HttpServer.extractWebAssets(mgr)
                    } else {
                        log("Failed to add asset path (cookie=0)")
                    }
                } else {
                    log("Could not find app APK in CLASSPATH")
                }
            } catch (e: Exception) {
                log("Could not create AssetManager: " + e.message)
                e.printStackTrace()
            }

            // Apply persisted settings to config BEFORE init
            // IMPORTANT: Set codec FIRST, then bitrate (so bitrate is calculated for correct codec)
            val persistedCodec = HttpServer.getRecordingCodec()
            if (persistedCodec != null) {
                val videoCodec = when (persistedCodec.uppercase()) {
                    "H265", "HEVC" -> GpuPipelineConfig.VideoCodec.H265
                    else -> GpuPipelineConfig.VideoCodec.H264
                }
                pipeline.config.setVideoCodec(videoCodec)
                log("Pre-init: Set codec to $persistedCodec")
            }

            val persistedQuality = HttpServer.getRecordingQuality()
            if (persistedQuality != null) {
                // RecordingQuality is the canonical quality knob. It replaces
                // the old LOW/MEDIUM/HIGH BitratePreset alias and lets newer
                // tiers share one path during pre-init and runtime changes.
                val quality = GpuPipelineConfig.RecordingQuality.fromString(persistedQuality)
                pipeline.config.setRecordingQuality(quality)
                val effectiveBitrate = pipeline.config.getEffectiveBitrate()
                log(
                    "Pre-init: Set recording quality to $quality (" + effectiveBitrate / 1_000_000 +
                        " Mbps for " + pipeline.config.getVideoCodec() + ")"
                )
            }

            pipeline.init(assetManager, DaemonBootstrap.context)

            log("GPU Surveillance initialized: " + PANO_WIDTH + "x" + PANO_HEIGHT + " -> 2560x1920 (mosaic)")

            // Clean up orphaned .tmp files from previous crashed recordings, plus
            // sidecars (.jpg/.srt/.json) whose .mp4 is already gone.
            //
            // Sweep EVERY directory a category's segments can live in, not just the active
            // one: the reaper deletes across the internal/SD mirror and the legacy path too,
            // so an orphan left in the mirror after a storage switch was previously
            // unreachable forever. sweepableDirs drops the shared flat legacy base — see its
            // doc comment, pointing a sidecar sweeper at that directory deletes the legacy
            // secrets and config files.
            try {
                val sm = StorageManager.getInstance()
                val sweptTmp = HashSet<String>()
                for (category in listOf("recordings", "surveillance", "proximity")) {
                    val dirs = sm.sweepableDirs(category)
                    for (dir in dirs) {
                        if (sweptTmp.add(dir.absolutePath)) {
                            HardwareEventRecorderGpu.cleanupOrphanedTmpFiles(dir)
                        }
                    }
                    // One call per category, never per directory: the sidecar sweeper needs
                    // every directory at once or a segment split across the internal/SD
                    // mirror by a partial migration reads as an orphan.
                    HardwareEventRecorderGpu.cleanupOrphanedSidecars(dirs)
                }
            } catch (e: Exception) {
                log("Orphan cleanup error: " + e.message)
            }

            // Initialize TelemetryDataCollector for overlay (needs app context)
            // Moved after RecordingModeManager init since sharedAppContext may not exist yet

            // Initialize RecordingModeManager
            if (sharedAppContext == null) {
                sharedAppContext = createAppContext()
            }
            val ctxForRmm = sharedAppContext
            if (ctxForRmm != null) {
                recordingModeManager = RecordingModeManager(ctxForRmm, pipeline)
                log("RecordingModeManager initialized")

                // Create AVC HAL warmup instance (shared with RecordingModeManager)
                avcHalWarmup = AvcHalWarmup()
                log("AvcHalWarmup initialized")

                // Now initialize TelemetryDataCollector (context is guaranteed available)
                try {
                    val tdc = TelemetryDataCollector()
                    telemetryDataCollector = tdc
                    tdc.init(sharedAppContext!!)
                    pipeline.setTelemetryCollector(tdc)

                    // Apply persisted overlay enabled state
                    val overlayEnabled = UnifiedConfigManager.getTelemetryOverlay().optBoolean("enabled", true)
                    pipeline.setOverlayEnabled(overlayEnabled)
                    log("TelemetryDataCollector initialized, overlay=$overlayEnabled")

                    // Late-bind TelemetryDataCollector to TripAnalyticsManager
                    // (it was null when TripAnalytics was initialized before the 45s GPU delay)
                    tripAnalyticsManager?.let {
                        it.setTelemetryDataCollector(tdc)
                        log("TelemetryDataCollector bound to TripAnalyticsManager")
                    }
                } catch (e: Exception) {
                    log("WARNING: TelemetryDataCollector init failed: " + e.message)
                }
            } else {
                log("WARNING: Could not create app context for RecordingModeManager")
            }
        } catch (e: Exception) {
            log("ERROR: GPU Surveillance init failed: " + e.message)
            log("ERROR: Exception type: " + e.javaClass.name)
            e.cause?.let { log("ERROR: Caused by: " + it.message) }
            // Print stack trace to logcat
            e.printStackTrace()
            gpuPipeline = null
        }
    }

    /**
     * Enable surveillance mode.
     */
    @JvmStatic
    fun enableSurveillance() {
        // RACE CONDITION FIX: Reject surveillance enable if ACC is ON.
        // This is the primary guard against the race where AccSentryDaemon's
        // enableSurveillance() retry loop or the 45-second fallback timer fires
        // AFTER ACC has already turned ON. AccMonitor is the source of truth
        // because it's updated synchronously by onAccStateChanged() on the IPC thread.
        if (AccMonitor.isAccOn()) {
            log("enableSurveillance() REJECTED — ACC is ON (race condition guard)")
            return
        }

        val pipeline = gpuPipeline
        if (pipeline == null) {
            log("GPU pipeline not ready — queuing surveillance enable for when pipeline initializes")
            pendingAccOff = true
            return
        }

        // SOTA: Safe Location check — don't start camera if parked at safe zone
        val safeMgr = SafeLocationManager.getInstance()
        if (safeMgr.isInSafeZone) {
            log(
                "SAFE ZONE: Surveillance suppressed — " + safeMgr.currentZoneName +
                    " (dist=" + Math.round(safeMgr.distanceToNearestZone) + "m)"
            )
            surveillanceEnabled = true   // Mark intent so it auto-starts when leaving zone
            safeZoneSuppressed = true
            return  // Camera never opens. Zero resources.
        }

        log(
            "Enabling GPU surveillance (pipeline=true, running=" + pipeline.isRunning +
                ", sentry=" + (pipeline.sentry != null) + ")"
        )
        surveillanceEnabled = true
        safeZoneSuppressed = false

        try {
            if (!pipeline.isRunning) {
                log("Pipeline not running — starting...")
                pipeline.start()
            }
            // Enable surveillance mode (motion detection)
            pipeline.enableSurveillance()
            // AVC keep-alive intentionally NOT started for the surveillance flow.
            // The 60s `am start com.byd.avc/.MainActivity` poke appears to perturb
            // the camera HAL and drag panoramic FPS down over time. Recording-mode
            // and streaming flows still warm/keep-alive AVC via RecordingModeManager
            // and StreamingApiHandler; ACC-OFF sentry runs without it for now.
            log("Surveillance mode activated successfully (no AVC keep-alive)")
        } catch (e: Exception) {
            log("ERROR: Failed to enable surveillance: " + e.message)
        }
    }

    /**
     * Ensure camera is running for surveillance (called by SurveillanceEngine when it becomes active).
     * This avoids circular calls between CameraDaemon and SurveillanceEngine.
     */
    @JvmStatic
    fun ensureCameraForSurveillance() {
        log("ensureCameraForSurveillance called")
        surveillanceEnabled = true
        enableSurveillance()
    }

    /**
     * Disable surveillance mode.
     */
    @JvmStatic
    fun disableSurveillance() {
        log("Disabling surveillance mode")
        surveillanceEnabled = false

        gpuPipeline?.disableSurveillance()
        // Keep pipeline running for potential streaming
    }

    // ==================== DOOR LOCK GATE ====================
    // Surveillance is only armed after doors are locked. This prevents false motion
    // events from the owner exiting the car. Device SDK typed listener and a 5s
    // poll run in parallel; a 60s timeout is the last resort.

    /**
     * Register door lock listener and arm surveillance when doors lock.
     * Called from ACC OFF path after all other gates (user enabled, safe zone, schedule) pass.
     *
     * RACE CONDITION SAFETY: Every callback and timeout checks AccMonitor.isAccOn()
     * before arming. If ACC turns ON during the lock wait, surveillance is NOT armed.
     */
    private fun registerDoorLockListenerAndArmOnLock() {
        doorLockListenerArmed = false

        // Two parallel lock-event sources, both active simultaneously while
        // the gate is open:
        //   1. Device SDK typed listener (via BydDataCollector) — primary
        //      reliable source. Single registration at daemon startup.
        //   2. Periodic getDoorLockStatus(area=1) poll       — catches any
        //      lock event the listener didn't deliver.
        //
        // Both converge through applyLockEvent() which is idempotent —
        // multiple sources reporting the same transition cause exactly one
        // arm or disarm. There is no primary/fallback toggle: every source
        // runs in parallel, so a silent failure of one doesn't gate the
        // others.

        attachDeviceLockSource()
        startUnlockPollThread()

        // Initial state probe: if doors are already locked at gate-entry, arm
        // now without waiting for an event.
        val deviceInitial = currentDeviceLockState()
        if (deviceInitial != null) applyLockEvent(deviceInitial, "device-initial")

        // Force-arm timeout: if no source reports a lock within 60s, arm
        // anyway. Owner may have walked away without locking, or every event
        // source failed to deliver. This is the final safety net for arming.
        Thread({
            try {
                Thread.sleep(DOOR_LOCK_ARM_TIMEOUT_MS)
                if (AccMonitor.isAccOn()) {
                    log("LOCK GATE TIMEOUT: ACC is ON — not arming")
                    return@Thread
                }
                if (!doorLockListenerArmed && !surveillanceEnabled) {
                    log(
                        "LOCK GATE TIMEOUT: No lock detected within " +
                            (DOOR_LOCK_ARM_TIMEOUT_MS / 1000) + "s — force-arming surveillance"
                    )
                    applyLockEvent(true, "timeout")
                }
            } catch (ignored: InterruptedException) {
            }
        }, "DoorLockTimeout").start()

        // Reverse fallback: ACC-ON disarm watchdog. Periodically queries
        // hardware ACC state directly. If ACC turned ON without any IPC
        // event reaching us (rare but seen during AccSentryDaemon restart
        // races), this thread force-disables surveillance.
        startAccOnDisarmWatchdog()
    }

    /**
     * Single arm/disarm path. Idempotent: redundant calls in the same state
     * are no-ops. Every lock-event source flows through here.
     */
    @Synchronized
    private fun applyLockEvent(locked: Boolean, source: String) {
        if (AccMonitor.isAccOn()) {
            log("LOCK GATE [$source]: " + (if (locked) "LOCKED" else "UNLOCKED") + " but ACC is ON — ignoring")
            return
        }
        if (locked) {
            if (doorLockListenerArmed) return
            log("LOCK GATE [$source]: LOCKED — arming surveillance")
            doorLockListenerArmed = true
            enableSurveillance()
        } else {
            if (!doorLockListenerArmed) return
            log("LOCK GATE [$source]: UNLOCKED — disarming surveillance (owner returning)")
            disableSurveillance()
            doorLockListenerArmed = false
        }
    }

    /** Device-SDK lock-event source via BydDataCollector's typed listener.
     *  Always attached — runs in parallel with the poll source. */
    private fun attachDeviceLockSource() {
        if (sharedAppContext == null) {
            log("LOCK GATE: No context — device-SDK source unavailable")
            return
        }
        try {
            val doorLockDevice = BydDeviceHelper.getDevice(
                "android.hardware.bydauto.doorlock.BYDAutoDoorLockDevice", sharedAppContext
            )
            if (doorLockDevice == null) {
                log("LOCK GATE: BYDAutoDoorLockDevice unavailable — relying on poll + timeout")
                return
            }
        } catch (e: Exception) {
            log("LOCK GATE: Device probe failed: " + e.message)
            return
        }
        subscribeDeviceLockListener()
    }

    /** @return true=locked, false=unlocked, null=unknown/device unavailable. */
    private fun currentDeviceLockState(): Boolean? {
        if (sharedAppContext == null) return null
        try {
            val doorLockDevice = BydDeviceHelper.getDevice(
                "android.hardware.bydauto.doorlock.BYDAutoDoorLockDevice", sharedAppContext
            ) ?: return null
            val s = readDoorLockStatus(doorLockDevice)
            if (s == DOOR_STATE_LOCK) return true
            if (s == DOOR_STATE_UNLOCK) return false
        } catch (e: Exception) {
            log("currentDeviceLockState error: " + e.message)
        }
        return null
    }

    /**
     * ACC-ON disarm watchdog. While surveillance is active during ACC OFF,
     * polls hardware ACC state every few seconds. If hardware says ACC ON
     * but AccMonitor still says OFF (IPC missed, AccSentryDaemon restarting),
     * force-disables surveillance directly. Symmetric counterpart to the
     * ACC-OFF arm timeout.
     */
    private fun startAccOnDisarmWatchdog() {
        if (accOnDisarmWatchdog?.isAlive == true) return
        val thread = Thread({
            log("ACC-ON disarm watchdog started")
            while (true) {
                try {
                    Thread.sleep(ACC_ON_DISARM_POLL_INTERVAL_MS)
                } catch (ie: InterruptedException) {
                    return@Thread
                }
                if (AccMonitor.isAccOn()) {
                    log("ACC-ON disarm watchdog exiting (AccMonitor=ON)")
                    return@Thread
                }
                if (sharedAppContext == null) continue
                try {
                    // probeAccState: returns true if ACC is OFF, false if ON
                    // or unknown. As a side effect updates AccMonitor.
                    val hwSaysAccOff = AccMonitor.probeAccState(sharedAppContext!!)
                    if (!hwSaysAccOff && surveillanceEnabled) {
                        log(
                            "ACC-ON DISARM WATCHDOG: hardware says ACC ON but " +
                                "surveillance still active — force-disabling"
                        )
                        disableSurveillance()
                        doorLockListenerArmed = false
                        return@Thread
                    }
                } catch (e: Exception) {
                    log("ACC-ON disarm watchdog probe error: " + e.message)
                }
            }
        }, "AccOnDisarmWatchdog")
        accOnDisarmWatchdog = thread
        thread.isDaemon = true
        thread.start()
    }

    private fun stopAccOnDisarmWatchdog() {
        accOnDisarmWatchdog?.let {
            if (it.isAlive) {
                it.interrupt()
            }
            accOnDisarmWatchdog = null
        }
    }

    /**
     * Read door lock status using the correct SDK method.
     * Tries getDoorLockStatus(int area) first (correct per SDK docs),
     * falls back to getDoorLockState() for older firmware compatibility.
     *
     * @return DOOR_STATE_INVALID(0), DOOR_STATE_UNLOCK(1), or DOOR_STATE_LOCK(2)
     */
    private fun readDoorLockStatus(doorLockDevice: Any?): Int {
        if (doorLockDevice == null) return DOOR_STATE_INVALID

        // Primary: getDoorLockStatus(int area) — per SDK documentation
        // DOOR_LOCK_AREA_LEFT_FRONT = 1 (driver's door, most reliable indicator)
        try {
            val getStatus = doorLockDevice.javaClass.getMethod("getDoorLockStatus", Int::class.javaPrimitiveType)
            val result = getStatus.invoke(doorLockDevice, 1) // 1 = LEFT_FRONT
            if (result is Int) {
                if (result in 0..2) return result
            }
        } catch (e: NoSuchMethodException) {
            // Method doesn't exist on this firmware — try fallback
        } catch (e: Exception) {
            log("LOCK GATE: getDoorLockStatus(1) failed: " + e.message)
        }

        // Fallback: getDoorLockState() — older/alternative API
        try {
            val getState = doorLockDevice.javaClass.getMethod("getDoorLockState")
            val result = getState.invoke(doorLockDevice)
            if (result is Int) {
                return result
            }
        } catch (e: NoSuchMethodException) {
            log("LOCK GATE: Neither getDoorLockStatus nor getDoorLockState available")
        } catch (e: Exception) {
            log("LOCK GATE: getDoorLockState failed: " + e.message)
        }

        return DOOR_STATE_INVALID
    }

    /**
     * Subscribe to BydDataCollector's typed door-lock listener for the
     * sentry arming gate. The collector registers a single typed proxy on
     * BYDAutoDoorLockDevice at startup and fans out events; we just attach a
     * subscriber here when ACC OFF activates the gate, and detach on ACC ON.
     *
     * This replaces the old per-cycle Proxy.newProxyInstance + registerListener
     * pattern, which leaked listener references onto the device every cycle.
     */
    private fun subscribeDeviceLockListener() {
        // Already subscribed for this cycle
        if (deviceLockSubscriber != null) return

        val subscriber = BydDataCollector.DoorLockListener { area, sdkState ->
            // Ignore non-driver-door events: lock-gate has historically gated
            // on the LF (driver's) door state, matching the prior behavior.
            if (area == 1) {
                if (sdkState == DOOR_STATE_LOCK) {
                    applyLockEvent(true, "device")
                } else if (sdkState == DOOR_STATE_UNLOCK) {
                    applyLockEvent(false, "device")
                }
            }
        }
        deviceLockSubscriber = subscriber

        try {
            BydDataCollector.getInstance().addDoorLockListener(subscriber)
            log("LOCK GATE: Device-SDK lock subscriber attached to BydDataCollector")
        } catch (e: Exception) {
            log("LOCK GATE: Failed to attach device-lock subscriber: " + e.message)
            deviceLockSubscriber = null
        }
    }

    private fun unsubscribeDeviceLockListener() {
        val subscriber = deviceLockSubscriber ?: return
        try {
            BydDataCollector.getInstance().removeDoorLockListener(subscriber)
        } catch (e: Exception) {
            log("WARN: removeDoorLockListener failed: " + e.message)
        }
        deviceLockSubscriber = null
    }

    /**
     * Continuous unlock polling thread — detects door lock/unlock transitions.
     * Uses getDoorLockStatus(1) for the driver's door.
     * Polls every 5s while ACC is off.
     */
    private fun startUnlockPollThread() {
        stopUnlockPollThread()

        val thread = Thread({
            log("Unlock poll thread started (5s polling getDoorLockStatus)")

            while (!AccMonitor.isAccOn()) {
                try {
                    Thread.sleep(UNLOCK_POLL_INTERVAL_MS)
                } catch (e: InterruptedException) {
                    return@Thread
                }
                if (AccMonitor.isAccOn()) return@Thread

                // SDK device poll. Returns INVALID(0) on firmwares that don't
                // expose getDoorLockStatus(area) to user UID, but still works
                // on most cars and gives us a fast (5s) signal.
                try {
                    val doorLockDevice = BydDeviceHelper.getDevice(
                        "android.hardware.bydauto.doorlock.BYDAutoDoorLockDevice", sharedAppContext
                    )
                    if (doorLockDevice != null) {
                        val state = readDoorLockStatus(doorLockDevice)
                        if (state == DOOR_STATE_LOCK) {
                            applyLockEvent(true, "poll")
                        } else if (state == DOOR_STATE_UNLOCK) {
                            applyLockEvent(false, "poll")
                        }
                    }
                } catch (e: Exception) {
                    // Silently continue — device may be sleeping
                }
            }
            log("Unlock poll thread exiting (ACC ON)")
        }, "UnlockPoll")
        unlockPollThread = thread
        thread.isDaemon = true
        thread.start()
    }

    private fun stopUnlockPollThread() {
        unlockPollThread?.let {
            if (it.isAlive) {
                it.interrupt()
            }
            unlockPollThread = null
        }
    }

    /**
     * Clean up all door lock gate resources. Called on ACC ON.
     */
    private fun cleanupDoorLockGate() {
        doorLockListenerArmed = false

        // Detach both lock-event sources
        unsubscribeDeviceLockListener()
        stopUnlockPollThread()

        // Stop the reverse-fallback ACC-ON disarm watchdog
        stopAccOnDisarmWatchdog()
    }

    /**
     * Notify surveillance of ACC state change.
     *
     * ACC OFF (sentry mode): Start pipeline with surveillance enabled
     * ACC ON (normal mode): Stop pipeline completely to save power
     */
    @JvmStatic
    fun onAccStateChanged(accIsOff: Boolean) {
        // Update AccMonitor state for HTTP API responses
        AccMonitor.setAccState(!accIsOff)

        // CRITICAL: Capture the BydVehicleData snapshot and record the ACC
        // transition BEFORE any pipeline/teardown work. The OFF event must
        // be persisted before BydDataCollector.setAccState(false) (further
        // down) zeroes out polling — otherwise the OFF row would have stale
        // or null telemetry. For ON, the collector is being resumed, not
        // torn down; the snapshot may be a few seconds stale, which is
        // fine (a 3s skew is negligible vs a 12-hour park, and any latency
        // biases the displayed delta toward zero — conservative).
        //
        // Wrapped in try/catch — must NEVER throw out of onAccStateChanged
        // because that would break the daemon's state machine.
        try {
            var accSnapshot: net.bladewatch.app.byd.BydVehicleData? = null
            try {
                val collector = BydDataCollector.getInstance()
                if (collector.isInitialized) {
                    accSnapshot = collector.data
                }
            } catch (t: Throwable) {
                // Collector not initialized yet on cold boot, etc. — pass
                // null snapshot, the row will still be recorded with the
                // event type so future correlation is possible.
            }
            SocHistoryDatabase.getInstance().recordAccEvent(if (accIsOff) "OFF" else "ON", accSnapshot)
        } catch (t: Throwable) {
            log("recordAccEvent failed (non-fatal): " + t.message)
        }

        // ALWAYS notify TripAnalyticsManager regardless of GPU pipeline state.
        // Trip detection depends on ACC events and must not be blocked by pipeline readiness.
        tripAnalyticsManager?.let {
            try {
                if (accIsOff) {
                    it.onAccOff()
                } else {
                    it.onAccOn()
                }
            } catch (e: Exception) {
                log("Trip Analytics ACC " + (if (accIsOff) "OFF" else "ON") + " error: " + e.message)
            }
        }

        val pipeline = gpuPipeline
        if (pipeline == null) {
            if (accIsOff) {
                log("ACC OFF but GPU pipeline not ready — queuing for when pipeline initializes")
                pendingAccOff = true
            } else {
                log("ACC ON but GPU pipeline not ready — clearing pending state")
                pendingAccOff = false
            }
            return
        }

        log("ACC state changed: " + (if (accIsOff) "OFF (entering sentry)" else "ON (exiting sentry)"))

        if (accIsOff) {
            // ACC OFF - Start pipeline for sentry mode
            try {
                // CRITICAL: Notify RecordingModeManager FIRST so it can finalize any
                // active continuous/drive-mode recording segment before we transition
                // to surveillance. Without this, the last recording segment is lost
                // when surveillance is disabled or suppressed by safe zone (early returns
                // below skip enableSurveillance which was the only path that stopped recording).
                recordingModeManager?.let {
                    log("ACC OFF - notifying RecordingModeManager to finalize active recording...")
                    it.onAccStateChanged(false)
                }

                // CRITICAL: Force-stop TelemetryDataCollector when ACC goes off.
                // No consumer needs it when the car is off (no overlay, no trip recording).
                // This prevents refcount leaks from keeping the poller alive during sentry mode.
                telemetryDataCollector?.let {
                    it.setOverlayRecordingActive(false)
                    it.forceStopPolling()
                    log("TelemetryDataCollector force-stopped (ACC OFF)")
                }

                // Stop GearMonitor polling — gear is always P when ACC is off.
                // It will be restarted on ACC ON.
                GearMonitor.getInstance().stop()
                log("GearMonitor stopped (ACC OFF)")

                // Tell BydDataCollector to skip speed/engine/gearbox polling (always 0 when parked)
                BydDataCollector.getInstance().setAccState(false)

                // CRITICAL: FORCE remount SD card when ACC goes off — BEFORE any early returns.
                // Even if surveillance is disabled or suppressed by safe zone, the SD card must stay
                // mounted so the HTTP server can serve existing recordings/events/trips.
                // Android/BYD system unmounts SD card when ACC is off, so we MUST force remount.
                val storage = StorageManager.getInstance()
                val anyStorageOnSd = storage.surveillanceStorageType == StorageManager.StorageType.SD_CARD ||
                    storage.recordingsStorageType == StorageManager.StorageType.SD_CARD ||
                    storage.tripsStorageType == StorageManager.StorageType.SD_CARD
                if (anyStorageOnSd) {
                    log("FORCE mounting SD card (ACC OFF, SD card configured for storage)...")
                    if (storage.ensureSdCardMounted(true)) {
                        log("SD card force mounted")
                    } else {
                        log("WARNING: SD card mount failed - using internal storage")
                    }
                    // Watchdog already started at daemon boot in main(); calling
                    // startSdCardWatchdog() again is idempotent (it stops any
                    // existing watchdog before starting). Kept here as a
                    // defensive re-arm in case the previous instance died.
                    storage.startSdCardWatchdog()
                }

                // Check if user has enabled surveillance in config
                val userEnabled = UnifiedConfigManager.isSurveillanceEnabled()
                if (!userEnabled) {
                    log("Surveillance NOT enabled in config — skipping auto-start on ACC OFF")
                    return  // SD card is mounted + watchdog running
                }

                // Safe zone check — don't start surveillance if parked at home/work
                val safeMgr = SafeLocationManager.getInstance()
                if (safeMgr.isInSafeZone) {
                    log(
                        "SAFE ZONE: Surveillance suppressed on ACC OFF — " + safeMgr.currentZoneName +
                            " (dist=" + Math.round(safeMgr.distanceToNearestZone) + "m)"
                    )
                    surveillanceEnabled = true   // Mark intent so it auto-starts when leaving zone
                    safeZoneSuppressed = true
                    return  // SD card is mounted + watchdog running, just skip surveillance
                }

                // Schedule check — don't start surveillance outside configured time windows
                try {
                    val schedule = UnifiedConfigManager.getSurveillanceSchedule()
                    if (schedule.isEnabled && !schedule.isActiveNow) {
                        log("SCHEDULE: Surveillance suppressed on ACC OFF — outside time window (" + schedule.summary + ")")
                        surveillanceEnabled = true  // Mark intent so periodic checker can start it later
                        return  // SD card is mounted + watchdog running, just skip surveillance
                    }
                } catch (e: Exception) {
                    log("Schedule check error (proceeding with surveillance): " + e.message)
                }

                if (!pipeline.isRunning) {
                    log("Starting pipeline for sentry mode...")
                    pipeline.start()
                }
                pipeline.setRecordingMode(GpuPipelineConfig.RecordingMode.SENTRY)
                // AVC keep-alive intentionally NOT started for the sentry/ACC-OFF
                // surveillance flow — see CameraDaemon.enableSurveillance() for
                // the full reasoning. Recording-mode and streaming flows still
                // poke AVC; only this surveillance path runs without it.
                // Door lock gate: surveillance is armed only after doors are locked.
                // This prevents false motion events from the owner exiting the car.
                // Two parallel sources fire concurrently (device-SDK typed
                // listener, 5s polling); arm timeout at 60s; ACC-ON disarm
                // watchdog runs in parallel as reverse fallback.
                log("Pipeline started in sentry mode — waiting for door lock to arm surveillance")
                registerDoorLockListenerAndArmOnLock()

                // SOTA: Periodic schedule checker — monitors time window transitions
                // during active sentry. If the schedule window ends, surveillance stops.
                // If the window starts (e.g., user parked before the window), surveillance starts.
                // Runs every 5 minutes. Only active when ACC is off.
                startScheduleChecker()

                log("Pipeline started in sentry mode")
            } catch (e: Exception) {
                val errorMsg = e.message ?: e.javaClass.simpleName
                log("ERROR: Failed to start pipeline for sentry: $errorMsg")
                e.printStackTrace()
            }
        } else {
            // ACC ON. We intentionally leave the SD-card watchdog running here:
            // BYD/Android can unmount the SD even with ACC on, and stopping the
            // watchdog created a window where the HTTP server returned empty
            // recordings until the user cycled ACC OFF→ON. The watchdog is
            // started at daemon boot in main() and runs for the daemon's
            // lifetime as long as any storage type is set to SD.

            // Stop schedule checker (only runs during ACC OFF sentry mode)
            stopScheduleChecker()

            // Stop door lock gate: detach device-SDK listener, stop
            // unlock poll, stop ACC-ON disarm watchdog.
            cleanupDoorLockGate()

            // Clear safe-zone suppression flag. It was set during the prior
            // ACC OFF in a safe zone to record "would have armed surveillance,
            // but suppressed by geofence." Once the user has turned ACC back
            // ON the suppression no longer applies — recording modes
            // (CONTINUOUS / DRIVE_MODE / PROXIMITY_GUARD) handle their own
            // activation independent of surveillance state. Without this
            // clear, the daemon status JSON keeps reporting safeZoneSuppressed=true
            // until the GPS poller eventually notices the boundary crossing,
            // which can be minutes after driving away.
            if (safeZoneSuppressed) {
                log("Clearing safeZoneSuppressed flag on ACC ON (was set during last sentry suppression)")
                safeZoneSuppressed = false
            }

            // Recreate app context if it was broken (system server was dead during init).
            // ACC ON means the head unit is awake and binder services should be available.
            // Run on a background thread because createAppContext() can block up to 10s
            // (systemMain timeout) — must not freeze the ACC ON handler.
            if (isContextBroken()) {
                Thread({
                    log("ACC ON: sharedAppContext is broken — attempting recreation...")
                    val newContext = createAppContext()
                    if (newContext != null && !isContextBrokenFor(newContext)) {
                        sharedAppContext = newContext
                        log("ACC ON: App context recreated successfully")

                        // Re-init components that failed with the broken context
                        reinitContextDependentComponents()

                        // Now start GearMonitor if it still isn't running
                        val gm = GearMonitor.getInstance()
                        if (!gm.isRunning) {
                            try {
                                gm.start()
                                log("ACC ON: GearMonitor started after context recreation")
                            } catch (e: Exception) {
                                log("ACC ON: GearMonitor start failed after recreation: " + e.message)
                            }
                        }

                        // Notify RecordingModeManager of current gear now that GearMonitor works
                        if (recordingModeManager != null && gm.isRunning) {
                            recordingModeManager!!.onGearChanged(gm.currentGear)
                        }
                    } else {
                        log("ACC ON: Context recreation failed — system services may still be starting")
                    }
                }, "ContextRecreate").start()
            }

            // Restart GearMonitor (stopped on ACC OFF)
            val gearMonitor = GearMonitor.getInstance()
            if (!gearMonitor.isRunning) {
                try {
                    gearMonitor.start()
                    log("GearMonitor restarted (ACC ON)")
                } catch (e: Exception) {
                    log("GearMonitor restart failed (ACC ON): " + e.message)
                }
            }

            // Tell BydDataCollector to resume full polling (speed/engine/gearbox)
            BydDataCollector.getInstance().setAccState(true)

            // If pipeline is currently in SURVEILLANCE mode, gracefully exit it:
            // finalize any in-progress sentry recording, flush the encoder, drop
            // out of SURVEILLANCE, and reopen the camera so BYD's native AVM app
            // can grab the primary slot. Skipped when not in surveillance —
            // calling onAccOn() in steady-state NORMAL_RECORDING would stop the
            // active recording and reopen the camera, which is exactly the
            // regression we're avoiding for duplicate ACC ON IPCs.
            if (pipeline.isSurveillanceMode) {
                try {
                    pipeline.onAccOn()
                } catch (e: Exception) {
                    log("gpuPipeline.onAccOn() error: " + e.message)
                }
            }

            // Notify RecordingModeManager — it handles starting recording mode
            log("ACC ON - notifying RecordingModeManager...")
            val rmm = recordingModeManager
            if (rmm != null) {
                rmm.onAccStateChanged(true)
            } else {
                // Fallback: Stop pipeline completely to save power (legacy behavior).
                // gpuPipeline.onAccOn() already ran above; just tear down.
                log("Stopping pipeline (ACC ON - saving power)...")
                pipeline.stop()
                log("Pipeline stopped - power saving mode")
            }
        }
    }

    /**
     * Notify of gear state change.
     *
     * Used by PROXIMITY_GUARD mode to activate/deactivate based on gear position.
     * When gear != P, proximity guard starts monitoring.
     * When gear = P, proximity guard stops (ADAS sensors go to ABNORMAL which is expected).
     *
     * @param gear The new gear position (1=P, 2=R, 3=N, 4=D, 5=M, 6=S)
     */
    @Volatile private var lastNotifiedGear = Int.MIN_VALUE

    @JvmStatic
    fun onGearChanged(gear: Int) {
        val gearName = RecordingModeManager.gearToString(gear)

        // GearMonitor primes the system with one initial notification on
        // start(); subsequent rapid duplicates can also slip through during
        // ACC ON re-init. Skip logging when the gear value is unchanged from
        // the last notification — downstream listeners already short-circuit
        // duplicate gears, but the daemon log shouldn't keep restating it.
        val redundant = (gear == lastNotifiedGear)
        lastNotifiedGear = gear
        if (!redundant) {
            log("Gear changed to: $gearName")
        }

        val rmm = recordingModeManager
        if (rmm != null) {
            rmm.onGearChanged(gear)
        } else if (!redundant) {
            log("RecordingModeManager not initialized - gear change ignored")
        }

        tripAnalyticsManager?.onGearChanged(gear)
    }

    /**
     * Check if surveillance is enabled.
     */
    @JvmStatic
    fun isSurveillanceEnabled(): Boolean = surveillanceEnabled

    /** True if surveillance was requested but suppressed because car is in a safe zone. */
    @JvmStatic
    fun isSafeZoneSuppressed(): Boolean = safeZoneSuppressed

    @JvmStatic
    fun setSafeZoneSuppressed(suppressed: Boolean) {
        safeZoneSuppressed = suppressed
    }

    // ==================== SCHEDULE CHECKER ====================

    private var scheduleCheckerThread: Thread? = null

    /**
     * Starts the periodic schedule checker that monitors time window transitions.
     * Runs every 5 minutes while ACC is off. Stops when ACC turns on.
     */
    private fun startScheduleChecker() {
        stopScheduleChecker()
        val thread = Thread({
            log("Schedule checker started (5-min interval)")
            while (!Thread.currentThread().isInterrupted) {
                try {
                    Thread.sleep(5 * 60 * 1000)  // 5 minutes
                } catch (e: InterruptedException) {
                    return@Thread
                }

                // Only check when ACC is off
                if (AccMonitor.isAccOn()) continue

                try {
                    val schedule = UnifiedConfigManager.getSurveillanceSchedule()

                    // Schedule disabled = always active, nothing to check
                    if (!schedule.isEnabled) continue

                    val withinWindow = schedule.isActiveNow
                    val currentlyActive = surveillanceEnabled && gpuPipeline != null && gpuPipeline!!.isSurveillanceMode

                    if (!withinWindow && currentlyActive) {
                        // Schedule window ended — stop surveillance
                        log("SCHEDULE: Time window ended (" + schedule.summary + ") — stopping surveillance")
                        disableSurveillance()
                    } else if (withinWindow && !currentlyActive && !safeZoneSuppressed) {
                        // Schedule window started — enable surveillance if other conditions met
                        val userEnabled = UnifiedConfigManager.isSurveillanceEnabled()
                        if (userEnabled) {
                            log("SCHEDULE: Time window started (" + schedule.summary + ") — enabling surveillance")
                            enableSurveillance()
                        }
                    }
                } catch (e: Exception) {
                    log("Schedule checker error: " + e.message)
                }
            }
            log("Schedule checker stopped")
        }, "ScheduleChecker")
        scheduleCheckerThread = thread
        thread.isDaemon = true
        thread.start()
    }

    /**
     * Stops the periodic schedule checker.
     */
    private fun stopScheduleChecker() {
        scheduleCheckerThread?.let {
            it.interrupt()
            scheduleCheckerThread = null
        }
    }

    /**
     * Check if surveillance is actively processing.
     */
    @JvmStatic
    fun isSurveillanceActive(): Boolean = gpuPipeline?.isRunning == true

    /**
     * Set recording quality tier — single user-facing knob that bundles
     * bitrate + perceptual quality. Accepts the new tier names
     * (ECONOMY/STANDARD/HIGH/PREMIUM/MAX). Anything else falls back to
     * STANDARD per the migration policy.
     */
    @JvmStatic
    fun setRecordingQuality(quality: String) {
        val pipeline = gpuPipeline ?: return

        val tier = GpuPipelineConfig.RecordingQuality.fromString(quality)

        pipeline.config.setRecordingQuality(tier)
        val effectiveBitrate = pipeline.config.getEffectiveBitrate()
        pipeline.applyBitrateChange(effectiveBitrate)
        log(
            "Recording quality set to: " + tier + " (" + effectiveBitrate / 1_000_000 + " Mbps for " +
                pipeline.config.getVideoCodec() + ")"
        )
    }

    /**
     * Set streaming quality.
     */
    @JvmStatic
    fun setStreamingQuality(quality: String) {
        val pipeline = gpuPipeline ?: return

        val streamQuality = GpuPipelineConfig.StreamingQuality.fromString(quality)

        pipeline.setStreamingQuality(streamQuality)
        log("Streaming quality set to: " + streamQuality.displayName)
    }

    /**
     * @deprecated use [setRecordingQuality] with one of
     *             ECONOMY / STANDARD / HIGH / PREMIUM / MAX. Old LOW/MEDIUM/
     *             HIGH bitrate strings are mapped to the closest tier.
     */
    @Deprecated("use setRecordingQuality")
    @JvmStatic
    fun setRecordingBitrate(bitrate: String?) {
        if (bitrate == null) return
        val tier = when (bitrate.uppercase()) {
            "LOW" -> "ECONOMY"
            "MEDIUM" -> "STANDARD"
            "HIGH" -> "HIGH"
            else -> "STANDARD"
        }
        log("setRecordingBitrate($bitrate) → mapping to recordingQuality=$tier")
        setRecordingQuality(tier)
    }

    /**
     * Set recording codec (H.264 or H.265).
     * Note: Codec change requires encoder restart.
     */
    @JvmStatic
    fun setRecordingCodec(codec: String) {
        val pipeline = gpuPipeline
        if (pipeline == null) {
            log("setRecordingCodec: gpuPipeline is null, skipping")
            return
        }

        try {
            val videoCodec = when (codec.uppercase()) {
                "H265", "HEVC" -> GpuPipelineConfig.VideoCodec.H265
                else -> GpuPipelineConfig.VideoCodec.H264
            }

            pipeline.config.setVideoCodec(videoCodec)
            pipeline.applyCodecChange(videoCodec)
            log("Recording codec set to: $codec (" + videoCodec.displayName + ") - restart recording to apply")
        } catch (e: Exception) {
            log("setRecordingCodec error: " + e.message)
            e.printStackTrace()
        }
    }

    /**
     * Get current recording quality tier (ECONOMY..MAX).
     * Canonical accessor — prefer this over the deprecated bitrate alias.
     */
    @JvmStatic
    fun getRecordingQuality(): String {
        val pipeline = gpuPipeline ?: return "STANDARD"
        return pipeline.config.getRecordingQuality().name
    }

    /**
     * Get current recording bitrate setting.
     * @deprecated Use [getRecordingQuality] for the canonical tier.
     */
    @Deprecated("Use getRecordingQuality")
    @JvmStatic
    fun getRecordingBitrate(): String {
        val pipeline = gpuPipeline ?: return "MEDIUM"
        return pipeline.config.getBitratePreset().name
    }

    /**
     * Get current recording codec setting.
     */
    @JvmStatic
    fun getRecordingCodec(): String {
        val pipeline = gpuPipeline ?: return "H264"
        return if (pipeline.config.getVideoCodec() == GpuPipelineConfig.VideoCodec.H265) "H265" else "H264"
    }

    /**
     * Get GPU pipeline instance.
     */
    @JvmStatic
    fun getGpuPipeline(): GpuSurveillancePipeline? = gpuPipeline

    // ==================== RECORDING MODE CONTROL ====================

    /**
     * Set recording mode (NONE, CONTINUOUS, DRIVE_MODE, PROXIMITY_GUARD).
     */
    @JvmStatic
    fun setRecordingMode(mode: String) {
        val rmm = recordingModeManager
        if (rmm == null) {
            log("ERROR: RecordingModeManager not initialized")
            return
        }

        try {
            val modeEnum = RecordingModeManager.Mode.valueOf(mode.uppercase())
            rmm.setMode(modeEnum)
            log("Recording mode set to: $mode")
        } catch (e: IllegalArgumentException) {
            log("ERROR: Invalid recording mode: $mode")
        }
    }

    /**
     * Get current recording mode.
     */
    @JvmStatic
    fun getRecordingMode(): String = recordingModeManager?.currentMode?.name ?: "NONE"

    /**
     * Get recording mode manager instance.
     */
    @JvmStatic
    fun getRecordingModeManager(): RecordingModeManager? = recordingModeManager

    /**
     * Get surveillance status for API.
     */
    @JvmStatic
    fun getSurveillanceStatus(): Map<String, Any> {
        val status = HashMap<String, Any>()

        val pipeline = gpuPipeline
        if (pipeline != null) {
            status["initialized"] = pipeline.isInitialized
            status["enabled"] = surveillanceEnabled
            status["active"] = pipeline.isRunning
            status["recording"] = pipeline.sentry != null && pipeline.sentry!!.isRecording()
            status["frameCount"] = pipeline.camera?.getFrameCount() ?: 0
            status["encoderType"] = "gpu-zero-copy"

            // Grid motion stats (for UI display)
            pipeline.sentry?.let { sentry ->
                status["activeBlocks"] = sentry.getLastActiveBlocksCount()
                status["totalBlocks"] = sentry.totalBlocks
                status["baselineBlocks"] = sentry.getBaselineNoiseBlocks()
                status["blockSensitivity"] = sentry.getBlockSensitivity()
                status["requiredBlocks"] = sentry.getRequiredActiveBlocks()

                // SOTA: Enhanced motion detection stats
                status["temporalBlocks"] = sentry.getLastTemporalBlocksCount()
                status["estimatedDistance"] = sentry.getLastEstimatedDistance()
                val bounds = sentry.getLastMotionBounds()
                if (bounds != null) {
                    status["motionMinY"] = bounds[0]
                    status["motionMaxY"] = bounds[1]
                }
            }

            // Get today's events with details
            val events = getTodaysEvents()
            status["totalEventsToday"] = events.size
            status["events"] = events
        } else {
            status["initialized"] = false
            status["enabled"] = false
            status["active"] = false
            status["encoderType"] = "none"
            status["totalEventsToday"] = 0
            status["events"] = ArrayList<Map<String, Any>>()
        }

        // SOTA: Safe Location status
        val safeMgr = SafeLocationManager.getInstance()
        status["safeZoneSuppressed"] = safeZoneSuppressed
        status["inSafeZone"] = safeMgr.isInSafeZone
        status["safeZoneName"] = safeMgr.currentZoneName ?: ""

        // SOTA: BYD camera coordinator status
        val cam: PanoramicCameraGpu? = pipeline?.camera
        if (pipeline != null && cam != null) {
            // Keep the flat legacy keys for existing UI consumers, then add the
            // nested cameraDiagnostics payload so field testers can export one
            // complete JSON object without reading logs.
            val cameraDiagnostics = HashMap<String, Any>()
            val coordinator: BydCameraCoordinator? = cam.getCameraCoordinator()
            if (coordinator != null) {
                status["cameraServiceRegistered"] = coordinator.isRegistered()
                status["cameraServiceUserRegistered"] = coordinator.isRegisteredAsUser()
                // cameraUserRegistered intentionally omitted — registerCameraUser is
                // permanently DISABLED, the value is always false. Polling fallback
                // is the only live path. See BydCameraCoordinator.register().
                status["cameraYielded"] = coordinator.isYielded()
                status["nativeAppActive"] = coordinator.isNativeAppActive()
                status["cameraEventCallback"] = coordinator.isEventCallbackActive()
                status["cameraOwnerPackage"] = coordinator.getCurrentCameraOwnerPackage()
                status["nativeCameraOwnerPackage"] = coordinator.getCurrentCameraOwnerPackage()
                status["cameraArbitrationMode"] = coordinator.getArbitrationMode()
                cameraDiagnostics["nativeCameraOwnerPackage"] = coordinator.getCurrentCameraOwnerPackage()
                cameraDiagnostics["arbitrationMode"] = coordinator.getArbitrationMode()
                cameraDiagnostics["cameraYielded"] = coordinator.isYielded()
                cameraDiagnostics["nativeAppActive"] = coordinator.isNativeAppActive()
                cameraDiagnostics["cameraEventCallback"] = coordinator.isEventCallbackActive()
            }

            // SOTA: Camera probe status
            status["cameraId"] = cam.getCameraId()
            status["surfaceMode"] = cam.getCameraSurfaceMode()
            status["probeComplete"] = cam.isProbeComplete()
            status["activeCameraId"] = cam.getCameraId()
            status["activeSurfaceMode"] = cam.getCameraSurfaceMode()
            status["cameraLayout"] = cam.getCameraLayout()
            status["manualOverride"] = cam.isManualOverrideActive()
            status["fallbackFromProbe"] = cam.isFallbackFromProbe()
            status["sourceBmmTag"] = cam.getSourceBmmTag()
            status["discoveryMethod"] = cam.getDiscoveryMethod()
            status["vehicleCamSort"] = cam.getVehicleCamSort()
            status["firmwareFingerprint"] = cam.getFirmwareInfo()?.fingerprint ?: ""
            status["buildDisplay"] = cam.getFirmwareInfo()?.buildDisplay ?: ""
            status["buildIncremental"] = cam.getFirmwareInfo()?.buildIncremental ?: ""
            status["productDevice"] = cam.getFirmwareInfo()?.device ?: ""
            status["nativeProbeReport"] = cam.getNativeProbeReport()
            status["eglHardwareBufferProbe"] = cam.getNativeProbeReport()
            status["nativeProbeReady"] = cam.isNativeProbeReady()
            status["fpsSetCameraResult"] = cam.getFpsSetCameraResult()
            status["fpsSetMediaCodecResult"] = cam.getFpsSetMediaCodecResult()
            status["validatedAtMs"] = cam.getValidatedAtMs()
            status["validatedFrameWidth"] = cam.getValidatedFrameWidth()
            status["validatedFrameHeight"] = cam.getValidatedFrameHeight()
            status["validationFrameCount"] = cam.getValidationFrameCount()
            status["validationSignal"] = cam.getValidationSignal()
            status["stripConfidence"] = cam.getStripConfidence()
            status["layoutConfidence"] = cam.getLayoutConfidence()
            status["quadrantVariance"] = cam.getQuadrantVariance()
            status["lastValidationFailure"] = cam.getLastValidationFailure()
            status["lastCameraEvent"] = cam.getLastCameraEvent()
            status["lastFrameAgeMs"] = cam.getLastFrameAgeMs()
            status["measuredFps"] = cam.measuredFps
            status["irFireCount"] = cam.getIrFireCount()
            status["irAcquireOkCount"] = cam.getIrAcquireOkCount()
            status["irAcquireNullCount"] = cam.getIrAcquireNullCount()
            status["irBindFailCount"] = cam.getIrBindFailCount()

            cameraDiagnostics["cameraId"] = cam.getCameraId()
            cameraDiagnostics["surfaceMode"] = cam.getCameraSurfaceMode()
            cameraDiagnostics["cameraLayout"] = cam.getCameraLayout()
            cameraDiagnostics["sourceBmmTag"] = cam.getSourceBmmTag()
            cameraDiagnostics["discoveryMethod"] = cam.getDiscoveryMethod()
            cameraDiagnostics["probeComplete"] = cam.isProbeComplete()
            cameraDiagnostics["manualOverride"] = cam.isManualOverrideActive()
            cameraDiagnostics["firmwareFingerprint"] = cam.getFirmwareInfo()?.fingerprint ?: ""
            cameraDiagnostics["buildDisplay"] = cam.getFirmwareInfo()?.buildDisplay ?: ""
            cameraDiagnostics["buildIncremental"] = cam.getFirmwareInfo()?.buildIncremental ?: ""
            cameraDiagnostics["productDevice"] = cam.getFirmwareInfo()?.device ?: ""
            cameraDiagnostics["vehicleCamSort"] = cam.getVehicleCamSort()
            cameraDiagnostics["validatedAtMs"] = cam.getValidatedAtMs()
            cameraDiagnostics["validationSignal"] = cam.getValidationSignal()
            cameraDiagnostics["layoutConfidence"] = cam.getLayoutConfidence()
            cameraDiagnostics["quadrantVariance"] = cam.getQuadrantVariance()
            cameraDiagnostics["lastFrameAgeMs"] = cam.getLastFrameAgeMs()
            cameraDiagnostics["measuredFps"] = cam.measuredFps
            cameraDiagnostics["irFireCount"] = cam.getIrFireCount()
            cameraDiagnostics["irAcquireOkCount"] = cam.getIrAcquireOkCount()
            cameraDiagnostics["irAcquireNullCount"] = cam.getIrAcquireNullCount()
            cameraDiagnostics["irBindFailCount"] = cam.getIrBindFailCount()
            cameraDiagnostics["lastCameraEvent"] = cam.getLastCameraEvent()
            cameraDiagnostics["eglHardwareBufferProbe"] = cam.getNativeProbeReport()
            cameraDiagnostics["avcWarmupLastResult"] = getAvcWarmupLastResult()
            cameraDiagnostics["fpsSetCameraResult"] = cam.getFpsSetCameraResult()
            cameraDiagnostics["fpsSetMediaCodecResult"] = cam.getFpsSetMediaCodecResult()
            status["cameraDiagnostics"] = cameraDiagnostics
        }

        try {
            val camCfg = UnifiedConfigManager.loadConfig().optJSONObject("camera")
            if (camCfg != null) {
                status["cameraReprobeOnNextRestart"] = camCfg.optBoolean("reprobeOnNextRestart", false)
            }
        } catch (e: Exception) {
            log("WARN: Failed to read cameraReprobeOnNextRestart: " + e.message)
        }

        status["avcWarmupAvailable"] = isAvcWarmupAvailable()
        status["avcWarmupLastStartedAtMs"] = getAvcWarmupLastStartedAtMs()
        status["avcWarmupLastResult"] = getAvcWarmupLastResult()
        status["avcWarmupKeepAliveActive"] = isAvcWarmupKeepAliveActive()
        status["avcWarmupLastReason"] = getAvcWarmupLastReason()
        status["avcWarmupLastSkippedReason"] = getAvcWarmupLastSkippedReason()

        return status
    }

    /**
     * Get list of today's events with timestamps.
     * Returns list of event info maps with filename, time, and size.
     */
    @JvmStatic
    fun getTodaysEvents(): List<Map<String, Any>> {
        val events = ArrayList<Map<String, Any>>()

        try {
            // Get today's date prefix (e.g., "event_20260111_")
            val todayPrefix = "event_" + SimpleDateFormat("yyyyMMdd", Locale.US).format(java.util.Date()) + "_"

            // SOTA: Use StorageManager for surveillance directory
            val storageManager = StorageManager.getInstance()
            var sentryDir = storageManager.surveillanceDir
            var files: Array<File>? = null

            if (sentryDir.exists() && sentryDir.isDirectory) {
                files = sentryDir.listFiles { _, name -> name.startsWith(todayPrefix) && name.endsWith(".mp4") }
            }

            // Fallback to legacy locations for backward compatibility
            if (files == null || files.isEmpty()) {
                sentryDir = File(outputDir, "sentry_events")
                if (sentryDir.exists() && sentryDir.isDirectory) {
                    files = sentryDir.listFiles { _, name -> name.startsWith(todayPrefix) && name.endsWith(".mp4") }
                }
            }

            if (files == null || files.isEmpty()) {
                sentryDir = File("/storage/emulated/0/Android/data/net.bladewatch.app/files/sentry_events")
                if (sentryDir.exists() && sentryDir.isDirectory) {
                    files = sentryDir.listFiles { _, name -> name.startsWith(todayPrefix) && name.endsWith(".mp4") }
                }
            }

            if (files != null) {
                // Sort by filename (which includes timestamp) descending (newest first)
                files.sortWith(Comparator { a, b -> b.name.compareTo(a.name) })

                for (file in files) {
                    val event = HashMap<String, Any>()
                    event["filename"] = file.name
                    event["size"] = file.length() / 1024 // KB

                    // Extract time from filename: event_YYYYMMDD_HHMMSS.mp4
                    val name = file.name
                    if (name.length >= 22) {
                        val timeStr = name.substring(15, 21) // HHMMSS
                        val formatted = timeStr.substring(0, 2) + ":" + timeStr.substring(2, 4) + ":" + timeStr.substring(4, 6)
                        event["time"] = formatted
                    } else {
                        event["time"] = "--:--:--"
                    }

                    events.add(event)
                }
            }
        } catch (e: Exception) {
            log("Error getting today's events: " + e.message)
        }

        return events
    }

    // ==================== STREAM MODE CONTROL ====================

    /**
     * Set stream mode: "private" (local only) or "public" (tunnel access).
     * Both modes now use tunnel URLs for remote access.
     */
    @JvmStatic
    fun setStreamMode(mode: String) {
        if (STREAM_MODE_PRIVATE != mode && STREAM_MODE_PUBLIC != mode) {
            log("ERROR: Invalid stream mode: $mode")
            return
        }

        val oldMode = streamMode
        streamMode = mode

        // Persist to file
        saveStreamMode(mode)

        log("Stream mode changed: $oldMode -> $mode")
        // VPS heartbeat removed - both modes use tunnel URLs now
    }

    /**
     * Save stream mode to file for persistence.
     */
    private fun saveStreamMode(mode: String) {
        try {
            val writer = FileWriter(PATH_STREAM_MODE_FILE())
            writer.write(mode)
            writer.close()
        } catch (e: Exception) {
            log("Failed to save stream mode: " + e.message)
        }
    }

    /**
     * Load stream mode from file.
     */
    private fun loadStreamMode() {
        try {
            val file = File(PATH_STREAM_MODE_FILE())
            if (file.exists()) {
                val reader = BufferedReader(FileReader(file))
                val mode = reader.readLine()
                reader.close()

                if (STREAM_MODE_PUBLIC == mode) {
                    log("Restored stream mode: PUBLIC")
                    setStreamMode(STREAM_MODE_PUBLIC)
                } else {
                    log("Restored stream mode: PRIVATE")
                    streamMode = STREAM_MODE_PRIVATE
                }
            }
        } catch (e: Exception) {
            log("Failed to load stream mode: " + e.message)
        }
    }

    /**
     * Get current stream mode.
     */
    @JvmStatic
    fun getStreamMode(): String = streamMode

    /**
     * Check if public streaming is enabled.
     */
    @JvmStatic
    fun isPublicMode(): Boolean = STREAM_MODE_PUBLIC == streamMode

    // ==================== INITIALIZATION ====================

    private fun generateDeviceId() {
        // FIRST: Try to read from shared file (written by app with context)
        // This ensures daemon uses the same ID as the app
        val persistentId = readDeviceIdFromFile(File(APP_FILES_DIR, ".bladewatch_device_id"))
        if (persistentId != null) {
            deviceId = persistentId
            saveDeviceId(deviceId)
            log("Device ID loaded from persistent file: $deviceId")
            return
        }

        val legacyId = readDeviceIdFromFile(File(PATH_DEVICE_ID_FILE()))
        if (legacyId != null) {
            deviceId = legacyId
            saveDeviceId(deviceId)
            log("Device ID migrated from legacy file: $deviceId")
            return
        }

        // Fallback: use serial number hash. Android O+ moved this behind
        // Build.getSerial(); older BYD builds still expose Build.SERIAL.
        try {
            val serial: String? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Build.getSerial()
            } else {
                @Suppress("DEPRECATION")
                Build.SERIAL
            }
            if (serial != null && serial != "unknown") {
                deviceId = stableDeviceId(serial)
                saveDeviceId(deviceId)
                log("Device ID generated from serial: $deviceId")
                return
            }
        } catch (e: Exception) {
            log("WARN: Could not get serial: " + e.message)
        }

        // Fallback: use build fingerprint hash
        try {
            val fingerprint = Build.FINGERPRINT
            if (fingerprint != null && fingerprint.isNotEmpty()) {
                deviceId = stableDeviceId(fingerprint)
                saveDeviceId(deviceId)
                log("Device ID generated from fingerprint: $deviceId")
                return
            }
        } catch (e: Exception) {
            log("WARN: Could not get fingerprint: " + e.message)
        }

        // Last resort: generate random ID
        deviceId = "byd-" + java.lang.Long.toHexString(System.currentTimeMillis()).substring(4)
        saveDeviceId(deviceId)
        log("Device ID generated randomly: $deviceId")
    }

    private fun readDeviceIdFromFile(idFile: File): String? {
        try {
            if (idFile.exists()) {
                // Self-heal for older installs: the legacy saveDeviceId()
                // didn't chmod the file, leaving it at the shell-UID-only
                // mode 0600 default. The app UID couldn't read it, fell
                // back to the "bladewatch-default-device" sentinel, derived
                // a different AES key, and silently failed to decrypt every
                // stored credential. setReadable(true, false) is idempotent
                // — no-op if it's already world-readable from a recent
                // install. Apply on every daemon start so a re-deploy
                // repairs older devices automatically.
                try {
                    idFile.setReadable(true, false)
                    idFile.setWritable(true, false)
                } catch (e: Exception) {
                    log("WARN: Could not set device ID file permissions: " + e.message)
                }
                val reader = BufferedReader(FileReader(idFile))
                val fileId = reader.readLine()
                reader.close()
                if (fileId != null && fileId.isNotEmpty() && fileId.startsWith("byd-")) {
                    return fileId
                }
            }
        } catch (e: Exception) {
            log("WARN: Could not read device ID from file: " + e.message)
        }
        return null
    }

    private fun stableDeviceId(source: String): String = "byd-" + String.format(Locale.US, "%08x", source.hashCode())

    private fun saveDeviceId(id: String) {
        try {
            saveDeviceIdFile(File(APP_FILES_DIR, ".bladewatch_device_id"), id)
            saveDeviceIdFile(File("/data/local/tmp/.bladewatch_device_id"), id)
            saveDeviceIdFile(File(PATH_DEVICE_ID_FILE()), id)
        } catch (e: Exception) {
            log("WARN: Could not save device ID to file: " + e.message)
        }
    }

    private fun saveDeviceIdFile(idFile: File, id: String) {
        val parent = idFile.parentFile
        if (parent != null && !parent.exists()) parent.mkdirs()
        val writer = FileWriter(idFile)
        writer.write(id)
        writer.close()
        idFile.setReadable(true, false)
        idFile.setWritable(true, false)
    }

    private fun parseArguments(args: Array<String>) {
        if (args.isNotEmpty()) {
            outputDir = args[0]
            log("Arg[0] outputDir: $outputDir")
        }

        if (args.size > 1) {
            nativeLibDir = args[1] // Use class field
            log("Arg[1] nativeLibDir: $nativeLibDir")
        }
    }

    private fun loadNativeLibraries() {
        try {
            try {
                System.loadLibrary("nativehelper")
            } catch (t: Throwable) {
            }
            System.loadLibrary("cutils")
            System.loadLibrary("utils")
            System.loadLibrary("binder")
            System.loadLibrary("gui")
            System.loadLibrary("bmmcamera")
        } catch (e: Throwable) {
            // Some Android Auto builds do not expose every system library to shell-launched
            // daemons. The BYD camera HAL still loads through the app APK libraries below.
            log("Optional system library skipped for shell daemon")
        }

        // Load surveillance library - try default path first
        if (!isLibraryLoaded()) {
            // Try explicit path using nativeLibDir
            val libDir = nativeLibDir
            if (libDir != null) {
                if (tryLoadLibrary(libDir)) {
                    log("Surveillance library loaded from: $libDir")
                } else {
                    // Try alternate paths
                    loadSurveillanceFromPath(libDir)
                }
            }

            // Final check
            if (isLibraryLoaded()) {
                log("Surveillance library loaded successfully")
            } else {
                log("WARN: Surveillance library NOT available: " + getLoadError())
            }
        } else {
            log("Surveillance library already loaded")
        }
    }

    private fun loadSurveillanceFromPath(nativeLibDir: String) {
        // Load surveillance library
        val surveillancePaths = arrayOf(
            "$nativeLibDir/libsurveillance.so",
            nativeLibDir.replace("/arm64", "/arm64-v8a") + "/libsurveillance.so",
            "$nativeLibDir-v8a/libsurveillance.so"
        )

        for (libPath in surveillancePaths) {
            if (File(libPath).exists()) {
                try {
                    System.load(libPath)
                    log("SUCCESS: Surveillance library loaded from: $libPath")
                    return
                } catch (e: Throwable) {
                    log("ERROR: FAILED to load $libPath: " + e.message)
                }
            }
        }
    }

    private fun scanCameras() {
        log("--- CAMERA SCAN ---")
        try {
            val infoClass = Class.forName("android.hardware.BmmCameraInfo")
            val mGetTags = infoClass.getDeclaredMethod("getValidCameraTag")
            mGetTags.isAccessible = true
            @Suppress("UNCHECKED_CAST")
            val tags = mGetTags.invoke(null) as List<String>?

            val mGetId = infoClass.getDeclaredMethod("getCameraId", String::class.java)
            mGetId.isAccessible = true

            if (tags != null) {
                for (tag in tags) {
                    val id = mGetId.invoke(null, tag) as Int
                    log("FOUND: [" + tag.uppercase() + "] -> ID: $id")
                }
            }
        } catch (e: Exception) {
            log("WARN: BmmCamera scan failed: " + e.message)
        }

        // Probe AVMCamera IDs 0-5 to find which cameras exist on this device
        try {
            val avmClass = Class.forName("android.hardware.AVMCamera")
            val ctor: Constructor<*> = avmClass.getDeclaredConstructor(Int::class.javaPrimitiveType)
            ctor.isAccessible = true
            val mOpen = avmClass.getDeclaredMethod("open")
            mOpen.isAccessible = true
            val mClose = avmClass.getDeclaredMethod("close")
            mClose.isAccessible = true

            for (id in 0..5) {
                try {
                    val cam = ctor.newInstance(id)
                    val opened = mOpen.invoke(cam) as Boolean
                    if (opened) {
                        log("AVMCamera ID $id: AVAILABLE")
                        mClose.invoke(cam)
                    } else {
                        log("AVMCamera ID $id: open() returned false")
                    }
                } catch (e: Exception) {
                    // Camera ID doesn't exist or can't be opened
                }
            }
        } catch (e: ClassNotFoundException) {
            log("WARN: AVMCamera not available on this device")
        } catch (e: Exception) {
            log("WARN: AVMCamera probe failed: " + e.message)
        }

        log("--- END SCAN ---")
    }

    // ==================== LOGGING ====================

    private fun initFileLogging() {
        // Configure DaemonLogger for daemon context (enable stdout for app_process)
        DaemonLogger.configure(
            DaemonLogger.Config.defaults()
                .withStdoutLog(true) // Enable stdout for daemon processes
                .withFileLog(true)
                .withConsoleLog(true)
        )
        log("=== CameraDaemon Log Started ===")
    }

    @JvmStatic
    fun log(message: String) {
        logger.info(message)
    }

    // ==================== NOTIFICATIONS ====================

    /**
     * Idempotency guard. Once the registry + sinks are wired, repeat calls
     * are no-ops.
     */
    @Volatile private var notificationsInitialized = false

    /**
     * Initialize the Web Push notification subsystem. Loads the category
     * registry from APK assets, opens persistent stores under
     * `/data/local/tmp/.push/`, registers PushSink + LogSink with
     * NotificationBus, and wires NotificationApiHandler so HTTP routes can
     * resolve.
     */
    @Synchronized
    @JvmStatic
    fun initNotifications() {
        if (notificationsInitialized) return

        var registry: CategoryRegistry? = null

        // The registry JSON ships in the APK assets. Use the cached
        // sharedAppContext if already populated; Do not create one
        // as it breaks in a thread
        val appContext = getAppContext()
        if (appContext != null) {
            try {
                registry = CategoryRegistry.loadFromAssets(appContext)
            } catch (e: Exception) {
                log("Failed to load notifications-categories.json: " + e.message)
            }
        }
        if (registry == null) {
            log("Notification registry unavailable; subsystem will boot in degraded mode.")
            return
        }

        val pushDir = File("/data/local/tmp/.push")
        if (!pushDir.exists()) pushDir.mkdirs()

        val keyStore = VapidKeyStore(File(pushDir, "vapid.json"))
        // Touch the keystore so we generate / cache the keypair eagerly.
        keyStore.publicKeyB64Url()

        val subStore = SubscriptionStore(File(pushDir, "subscriptions.json"))
        subStore.load()

        val signer = VapidSigner(keyStore, "")

        NotificationBus.get().subscribe(LogSink())
        NotificationBus.get().subscribe(PushSink(subStore, registry, keyStore, signer))

        NotificationApiHandler.init(registry, subStore, keyStore)

        notificationsInitialized = true
        log("Notifications initialized: " + registry.all().size + " categories, " + subStore.size() + " subscriptions")
    }

    // ==================== GPS MONITOR ====================

    /**
     * Initialize GPS Monitor with app context for standard LocationManager access.
     * Uses PermissionBypassContext to access location services without runtime permission prompts.
     */
    private fun initGpsMonitor() {
        try {
            log("Initializing GPS Monitor with app context...")

            // Location permissions are already granted by PermissionGranter on its
            // background thread. No need to duplicate those 3 synchronous pm grant
            // calls here — they were blocking initGpsMonitor for several seconds
            // and adding redundant load to PackageManagerService.

            // Try to get or create shared app context
            if (sharedAppContext == null) {
                sharedAppContext = createAppContext()
            }

            val ctx = sharedAppContext
            if (ctx == null) {
                log("WARNING: Could not create app context for GpsMonitor, falling back to daemon mode")
                GpsMonitor.getInstance().init(null)
                return
            }

            log("Got app context: " + ctx.javaClass.name)

            // Verify LocationManager is accessible
            val locMgr = ctx.getSystemService(Context.LOCATION_SERVICE)
            if (locMgr == null) {
                log("WARNING: LocationManager not available, falling back to daemon mode")
                GpsMonitor.getInstance().init(null)
                return
            }
            log("LocationManager available: " + locMgr.javaClass.name)

            val gpsMonitor = GpsMonitor.getInstance()

            gpsMonitor.init(ctx)
            gpsMonitor.start() // Start GPS tracking immediately

            log("GPS Monitor initialized with Context mode")

            // Initialize NetworkMonitor for WiFi/Mobile Data status in sidebar
            NetworkMonitor.init(ctx)
            log("Network Monitor initialized")
        } catch (e: Exception) {
            log("Failed to initialize GPS Monitor with context: " + e.message)
            log("Falling back to daemon mode (shell commands)")
            GpsMonitor.getInstance().init(null)
        }
    }

    // ==================== VEHICLE DATA MONITOR ====================

    /**
     * Initialize Vehicle Data Monitor for EV battery and charging data.
     * Reuses shared app context with PermissionBypassContext for BYD hardware access.
     */
    private fun initVehicleDataMonitor() {
        try {
            log("Initializing Vehicle Data Monitor...")

            // Reuse shared context if available, otherwise create new
            if (sharedAppContext == null) {
                sharedAppContext = createAppContext()
            }

            val ctx = sharedAppContext
            if (ctx == null) {
                log("WARNING: Could not create app context for VehicleDataMonitor")
                return
            }

            val vehicleMonitor = VehicleDataMonitor.getInstance()

            vehicleMonitor.init(ctx)
            vehicleMonitor.start()

            log("Vehicle Data Monitor initialized successfully")

            // Initialize Universal BYD Data Collector (runs alongside existing monitors)
            try {
                val collector = BydDataCollector.getInstance()
                collector.init(ctx)
                collector.logSummary()
                log("BYD Data Collector initialized (" + (collector.data?.availableDevices?.size ?: 0) + " devices)")
            } catch (e: Exception) {
                log("BYD Data Collector init error (non-fatal): " + e.message)
            }

            // Initialize Gear Monitor for PROXIMITY_GUARD mode
            val gearMonitor = GearMonitor.getInstance()
            gearMonitor.init(ctx)
            // Wire GearMonitor to read gear from TelemetryDataCollector's cached snapshot
            // when the overlay poller is running, avoiding duplicate CAN bus reads
            telemetryDataCollector?.let { gearMonitor.setTelemetrySource(it) }
            try {
                gearMonitor.start()
            } catch (e: Exception) {
                log("GearMonitor start failed (will retry on ACC ON): " + e.message)
            }

            log("Gear Monitor initialized successfully")

            // Initialize Performance Monitor for system instrumentation
            val perfMonitor = PerformanceMonitor.getInstance()
            perfMonitor.init(ctx)
            perfMonitor.start()

            log("Performance Monitor initialized successfully")

            // Initialize SOC History Database for persistent battery tracking
            val socDb = SocHistoryDatabase.getInstance()
            socDb.init()
            socDb.start()

            // Fix stale kWh records from before PHEV capacity was correctly detected.
            // Capacity is sourced from BYD-local nominal capacity (VehicleDataMonitor).
            val socNominalKwh = vehicleMonitor.getNominalCapacityKwh()
            if (socNominalKwh > 0 && socNominalKwh < 30.0) {
                log("Fixing stale kWh records for PHEV (nominal=$socNominalKwh kWh)")
                socDb.fixStaleRemainingKwh(socNominalKwh)
            }

            log("SOC History Database initialized successfully")
        } catch (e: Exception) {
            log("Failed to initialize Vehicle Data Monitor: " + e.message)
            e.printStackTrace()
        }
    }

    /**
     * Create app context with permission bypass for BYD hardware access.
     */
    private fun createAppContext(): Context? {
        try {
            log("createAppContext: Starting...")
            val activityThreadClass = Class.forName("android.app.ActivityThread")
            var activityThread: Any?

            // Strategy 1: Get existing ActivityThread (works if app process is running)
            try {
                val currentActivityThread = activityThreadClass.getMethod("currentActivityThread")
                activityThread = currentActivityThread.invoke(null)
                log("createAppContext: currentActivityThread = $activityThread")
            } catch (e: Exception) {
                log("createAppContext: currentActivityThread failed: " + e.message)
                activityThread = null
            }

            // Strategy 2: systemMain() with timeout — this can deadlock on some firmware
            if (activityThread == null) {
                log("createAppContext: Trying systemMain with 10s timeout...")
                var result: Any? = null
                var error: Exception? = null
                val systemMainThread = Thread({
                    try {
                        val systemMain = activityThreadClass.getMethod("systemMain")
                        result = systemMain.invoke(null)
                    } catch (e: Exception) {
                        error = e
                    }
                }, "SystemMainInit")
                systemMainThread.isDaemon = true
                systemMainThread.start()
                systemMainThread.join(10_000) // 10 second timeout

                if (systemMainThread.isAlive) {
                    log("createAppContext: systemMain TIMED OUT (10s)")
                    systemMainThread.interrupt()
                    try {
                        val currentActivityThread = activityThreadClass.getMethod("currentActivityThread")
                        activityThread = currentActivityThread.invoke(null)
                        log("createAppContext: post-timeout currentActivityThread = $activityThread")
                    } catch (e2: Exception) {
                        log("createAppContext: post-timeout currentActivityThread also failed")
                    }
                } else if (error != null) {
                    // systemMain can be blocked for shell UIDs; later strategies create the
                    // PermissionBypassContext used by the car daemon.
                    log("createAppContext: systemMain unavailable (" + error!!.message + "), trying fallback")
                } else {
                    activityThread = result
                    log("createAppContext: systemMain = $activityThread")
                }
            }

            // Strategy 3: Prepare looper manually + create ActivityThread via constructor
            if (activityThread == null) {
                log("createAppContext: Trying manual ActivityThread creation...")
                try {
                    // Ensure main looper exists (idempotent if already prepared)
                    prepareMainLooperForShellDaemon()

                    // Create ActivityThread via default constructor
                    val ctor = activityThreadClass.getDeclaredConstructor()
                    ctor.isAccessible = true
                    activityThread = ctor.newInstance()

                    // Set as the current thread via sCurrentActivityThread field
                    try {
                        val sField = activityThreadClass.getDeclaredField("sCurrentActivityThread")
                        sField.isAccessible = true
                        sField.set(null, activityThread)
                    } catch (e: NoSuchFieldException) {
                        // Some Android versions use different field name
                        try {
                            activityThreadClass.getDeclaredField("sMainThreadHandler")
                            // If we got here, the field layout is different — just proceed
                        } catch (ignored: Exception) {
                        }
                    }

                    log("createAppContext: manual ActivityThread = $activityThread")
                } catch (e: Exception) {
                    log("createAppContext: manual creation failed: " + e.message)
                }
            }

            if (activityThread == null) {
                // Strategy 4: Last resort — get system context directly via ContextImpl
                log("createAppContext: All ActivityThread strategies failed, trying ContextImpl...")
                return createFallbackContext()
            }

            val getSystemContext = activityThreadClass.getMethod("getSystemContext")
            val systemContext = getSystemContext.invoke(activityThread) as Context?
            log("createAppContext: systemContext = $systemContext")

            if (systemContext == null) {
                log("createAppContext: systemContext is null, trying fallback...")
                return createFallbackContext()
            }

            val packageName = APP_PACKAGE_NAME()
            log("createAppContext: Creating package context for $packageName")
            val appContext = systemContext.createPackageContext(
                packageName, Context.CONTEXT_INCLUDE_CODE or Context.CONTEXT_IGNORE_SECURITY
            )
            log("createAppContext: appContext = $appContext")

            val wrapped = PermissionBypassContext(appContext)
            log("createAppContext: Success, returning PermissionBypassContext")
            return wrapped
        } catch (e: Exception) {
            log("createAppContext failed: " + e.message + ", trying fallback...")
            return createFallbackContext()
        }
    }

    /**
     * Fallback context creation when ActivityThread is completely unavailable.
     * Creates a minimal context via ContextImpl reflection that's enough for
     * BYD device getInstance() calls (they just need enforceCallingOrSelfPermission to not NPE).
     */
    private fun createFallbackContext(): Context {
        try {
            // Try to create ContextImpl directly
            val contextImplClass = Class.forName("android.app.ContextImpl")

            // Try createSystemContext() — available on most Android versions
            try {
                val createSystemContext = contextImplClass.getDeclaredMethod(
                    "createSystemContext", Class.forName("android.app.ActivityThread")
                )
                createSystemContext.isAccessible = true
                // Pass null ActivityThread — some versions tolerate this
                val ctx = createSystemContext.invoke(null, null as Any?) as Context?
                if (ctx != null) {
                    log("createFallbackContext: ContextImpl.createSystemContext succeeded")
                    return PermissionBypassContext(ctx)
                }
            } catch (e: Exception) {
                log("createFallbackContext: createSystemContext failed: " + e.message)
            }

            // Try createAppContext with minimal params
            try {
                val methods = contextImplClass.declaredMethods
                for (m in methods) {
                    if (m.name == "createAppContext" && m.parameterTypes.size == 2) {
                        m.isAccessible = true
                        // Can't call without valid params, skip
                        break
                    }
                }
            } catch (ignored: Exception) {
            }

            // Last resort: use a bare PermissionBypassContext with a dummy base
            // This creates a context that returns PERMISSION_GRANTED for all checks
            // and delegates everything else to the system
            log("createFallbackContext: Using null-safe PermissionBypassContext as last resort")
            return PermissionBypassContext(null)
        } catch (e: Exception) {
            log("createFallbackContext failed completely: " + e.message)
            return PermissionBypassContext(null)
        }
    }

    @Suppress("DEPRECATION")
    private fun prepareMainLooperForShellDaemon() {
        // Shell-launched daemons do not get Android's normal ActivityThread
        // bootstrap. prepareMainLooper() is deprecated for apps, but it is the
        // compatible fallback for BYD SDK callbacks in this app_process path.
        try {
            Looper.prepareMainLooper()
        } catch (ignored: Exception) {
        }
    }

    /**
     * Context wrapper that bypasses permission checks and handles null base context.
     * Required for accessing BYD hardware services without signature permissions.
     * When base is null (fallback mode), provides safe defaults for methods BYD devices call.
     */
    private class PermissionBypassContext(base: Context?) : ContextWrapper(base) {
        override fun enforceCallingOrSelfPermission(permission: String, message: String?) {}
        override fun enforcePermission(permission: String, pid: Int, uid: Int, message: String?) {}
        override fun enforceCallingPermission(permission: String, message: String?) {}
        override fun checkCallingOrSelfPermission(permission: String): Int = PackageManager.PERMISSION_GRANTED
        override fun checkPermission(permission: String, pid: Int, uid: Int): Int = PackageManager.PERMISSION_GRANTED
        override fun checkSelfPermission(permission: String): Int = PackageManager.PERMISSION_GRANTED

        // Null-safe overrides for when base context is null (fallback mode).
        // CRITICAL: getMainLooper() must be overridden — BYDAutoDeviceManager calls
        // context.getMainLooper() in its constructor, and ContextWrapper delegates
        // to the base context which is null in fallback mode, causing NPE that
        // makes all 18 BYD device monitors null.
        override fun getMainLooper(): Looper {
            return try {
                super.getMainLooper()
            } catch (e: NullPointerException) {
                // Return the process main looper — BYD devices use it to register
                // Handler callbacks for CAN bus data change listeners.
                Looper.getMainLooper() ?: Looper.myLooper()!!
            }
        }

        override fun getApplicationContext(): Context {
            return try {
                super.getApplicationContext()
            } catch (e: NullPointerException) {
                this
            }
        }

        override fun getPackageName(): String {
            return try {
                super.getPackageName()
            } catch (e: NullPointerException) {
                APP_PACKAGE_NAME()
            }
        }

        override fun getSystemService(name: String): Any? {
            return try {
                super.getSystemService(name)
            } catch (e: NullPointerException) {
                null
            }
        }

        override fun getApplicationInfo(): ApplicationInfo {
            return try {
                super.getApplicationInfo()
            } catch (e: NullPointerException) {
                ApplicationInfo()
            }
        }

        override fun getContentResolver(): ContentResolver? {
            return try {
                super.getContentResolver()
            } catch (e: NullPointerException) {
                null
            }
        }

        override fun getResources(): Resources? {
            return try {
                super.getResources()
            } catch (e: NullPointerException) {
                null
            }
        }

        override fun createPackageContext(packageName: String, flags: Int): Context {
            return try {
                super.createPackageContext(packageName, flags)
            } catch (e: Exception) {
                this
            }
        }
    }
}
