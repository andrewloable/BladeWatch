package net.bladewatch.app.daemon

import android.annotation.SuppressLint
import android.content.ContentResolver
import android.content.Context
import android.content.ContextWrapper
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.content.res.Resources
import android.os.Looper
import android.os.PowerManager
import android.os.Process

import net.bladewatch.app.config.UnifiedConfigManager
import net.bladewatch.app.daemon.proxy.Safe
import net.bladewatch.app.logging.DaemonLogger

import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.io.PrintWriter
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.net.SocketTimeoutException

/**
 * Sentry Daemon - runs as system user (UID 1000) via privileged shell.
 *
 * RESPONSIBILITIES:
 * 1. ACQUIRE ACC LOCK - This is the CRITICAL one that prevents force_suspend!
 * 2. Acquire WakeLock to prevent CPU sleep
 * 3. Whitelist UIDs (1000, 2000, app UID) for network access
 * 4. Whitelist app package via accmodemanager
 * 5. Keep WiFi enabled
 *
 * UID 1000 (system) has android.permission.DEVICE_ACC which is required for ACC Lock!
 */
object SentryDaemon {

    private const val TAG = "SentryDaemon"

    /**
     * BladeWatch-f0y3: mirrors CameraDaemon's /data/local/tmp/camera_daemon.lock. The
     * daemon-stop block in CLAUDE.md already removes *sentry*.lock, so this is cleaned up.
     */
    private const val SINGLETON_LOCK_FILE = "/data/local/tmp/sentry_daemon.lock"

    private var singletonLock: DaemonSingletonLock? = null
    private var logger: DaemonLogger? = null
    private var wakeLock: PowerManager.WakeLock? = null

    // ==================== STARTUP TIMING ====================
    private var startTime: Long = 0

    private fun logT(step: String) {
        if (!UnifiedConfigManager.isTimingLogsEnabled()) return
        val now = System.currentTimeMillis()
        log("[STARTUP +" + (now - startTime) + "ms @" + now + "] " + step)
    }

    // ==================== ENCRYPTED CONSTANTS (SOTA obfuscation) ====================
    // Decrypted at runtime via Safe.s() - AES-256-CBC with stack-based key reconstruction

    /** net.bladewatch.app */
    private fun appPackageName(): String = Safe.s("b+URlanuKqV+a8w43uR6VwE1hpEbteNkkdukhTGHkdY=")

    /** accmodemanager */
    private fun serviceAccMode(): String = Safe.s("tr877WU3+MV4zFtCjanWUw==")

    /** byd_datacached */
    private fun serviceBydDataCache(): String = Safe.s("JQiIxMJxYlF8spk2fIi8Sg==")

    /** bg_datacache */
    private fun serviceBgDataCache(): String = Safe.s("m84QJmAGTQpH+XP36MaDpA==")

    /** /data/local/tmp */
    private fun pathDataLocalTmp(): String = Safe.s("vuaMjrmBGBFh07qqnUuL8w==")

    /** /data/data/com.android.providers.settings */
    private fun pathDataSystemSettings(): String =
        Safe.s("4FWGV7tPhe9614nkUCor4bnqFPfssDPoiHYPJxgenGAPG3xCP+0Cb2Hm04LZxNNJ")

    /** /data/local/tmp/sentry_daemon.pid */
    private fun pathSentryPid(): String =
        Safe.s("ZHx6IP38aGV/Q7iMCCcxzy1lsQShZtcRseW7dNE1si25na89IOT5cRwBuRuJBcXS")

    /** svc wifi enable */
    private fun cmdWifiEnable(): String = Safe.s("GzzLDvODRsKARkPOXEZeIA==")

    /** cmd wifi set-wifi-enabled enabled */
    private fun cmdWifiEnableAlt(): String =
        Safe.s("OHt1ORBfaA6jti9DhL+LSDghCI3qSNr9WYGyb82Ov2DsCnMgXaYKKKOzpoICOnGX")

    // ACC Lock - COMMENTED OUT (using whitelistAppPackageOld instead)
    // private static Object accLockObject = null;
    private var appContext: Context? = null

    @JvmStatic
    fun main(args: Array<String>) {
        startTime = System.currentTimeMillis()
        val myUid = Process.myUid()

        // Configure DaemonLogger for daemon context (enable stdout for app_process)
        DaemonLogger.configure(
            DaemonLogger.Config.defaults()
                .withStdoutLog(true)
                .withFileLog(true)
                .withConsoleLog(true)
        )

        // Initialize logger based on UID
        val logDir = if (myUid == 1000) pathDataSystemSettings() else pathDataLocalTmp()
        logger = DaemonLogger.getInstance(TAG, logDir)
        logT("logger initialized")

        // CRITICAL: Check if another instance is already running BEFORE doing anything else.
        //
        // BladeWatch-f0y3: isDaemonRunning() alone is NOT sufficient and was the bug. It PINGs
        // the control port, which only answers once an instance has already bound it — so two
        // daemons launched inside that window both probed, both found nobody home, and both
        // started (observed on the head unit: PIDs 9244 and 9351, one second apart, every
        // periodic task running twice). The file lock is the actual mutual exclusion; the port
        // ping is kept as a cheap first check and for external callers.
        if (isDaemonRunning()) {
            log("ERROR: Another SentryDaemon instance is already running. Exiting.")
            System.exit(1)
            return
        }
        val lock = DaemonSingletonLock(
            File(SINGLETON_LOCK_FILE),
            Process.myPid(),
            DaemonSingletonLock.PROC_LIVENESS
        ) { msg -> log(msg) }
        singletonLock = lock
        if (!lock.acquire()) {
            log("ERROR: Another SentryDaemon instance holds the singleton lock. Exiting.")
            System.exit(1)
            return
        }
        Runtime.getRuntime().addShutdownHook(Thread { lock.release() })
        logT("singletonCheck done")

        log("=== Sentry Daemon Starting ===")
        log("UID: " + myUid + " (" + uidToName(myUid) + ")")
        log("PID: " + Process.myPid())

        if (myUid == 1000) {
            log("*** RUNNING AS SYSTEM - CAN ACQUIRE ACC LOCK! ***")
        }

        if (Looper.myLooper() == null) {
            Looper.prepare()
        }

        try {
            logT("createAppContext BEGIN")
            var context = createAppContext()
            if (context == null) {
                log("createAppContext failed, trying getSystemContext...")
                context = getSystemContext()
            }
            logT("createAppContext done")

            if (context != null) {
                log("Got context: $context")
                appContext = context

                // Write PID file for external kill
                writePidFile()
                logT("writePidFile done")

                // Start control socket for clean shutdown
                startControlSocket()
                logT("startControlSocket done")

                // ACC whitelist and protection DISABLED - causes BYD default dashcam
                // to lose video signal when running as privileged (UID 1000).
                // The setPkg2AccWhiteList call elevates our app's camera priority
                // above the BYD dashcam, stealing its AVMCamera feed.
                // whitelistAppPackageOld();
                // protectDaemon(context);

                // Keep WiFi enabled
                enableWifi()
                logT("enableWifi done")
            } else {
                log("WARNING: Running without context - using shell fallbacks")
                writePidFile()
                startControlSocket()
                // protectDaemonViaShell(); // DISABLED - same reason as above
                enableWifi()
                logT("fallback setup done (no context)")
            }

            log("=== Setup complete, daemon running ===")
            logT("=== SENTRY DAEMON READY ===")

            // Start Location Sidecar monitor to keep GPS service alive when app is killed
            startLocationMonitor()
            logT("startLocationMonitor done")

            // Keep daemon alive
            Looper.loop()
        } catch (e: Exception) {
            log("FATAL: " + e.message)
            e.printStackTrace()
        }
    }

    private fun uidToName(uid: Int): String = when (uid) {
        0 -> "root"
        1000 -> "system"
        2000 -> "shell"
        else -> "uid=$uid"
    }

    private fun log(msg: String) {
        logger?.info(msg)
        // Note: System.out.println is now handled by DaemonLogger when enableStdoutLog is true
    }

    // ==================== DAEMON PROTECTION ====================

    private fun protectDaemon(context: Context) {
        val myUid = Process.myUid()
        val isSystem = myUid == 1000

        log("=== PROTECTING DAEMON ===")

        // 1. Acquire WakeLock
        acquireWakeLock(context)

        // 2. Whitelist UIDs for network access
        val uidsToWhitelist = if (isSystem) intArrayOf(1000, 2000) else intArrayOf(myUid)
        for (uid in uidsToWhitelist) {
            whitelistUidForNetwork(context, uid)
        }

        // 3. Whitelist app package
        whitelistAppPackage(context)

        // 4. Whitelist app UID if running as system
        if (isSystem) {
            whitelistAppUid(context)
        }

        log("=== DAEMON PROTECTION COMPLETE ===")
    }

    private fun protectDaemonViaShell() {
        log("=== PROTECTING DAEMON (shell fallback) ===")

        val pkg = appPackageName()

        // Whitelist UIDs
        for (uid in intArrayOf(1000, 2000)) {
            shellWhitelistUid(uid.toString())
        }

        // Whitelist package
        shellWhitelistPackage(pkg)

        log("=== SHELL FALLBACK COMPLETE ===")
    }

    /** `service call` fallback for the two data-cache services, codes 1..3. */
    private fun shellWhitelistUid(uidStr: String) {
        for (code in 1..3) {
            execShell(
                "service call " + serviceBydDataCache() + " " + code +
                    " s16 '" + uidStr + "' i32 0 2>/dev/null"
            )
            execShell(
                "service call " + serviceBgDataCache() + " " + code +
                    " s16 '" + uidStr + "' i32 0 2>/dev/null"
            )
        }
    }

    /** `service call` fallback for accmodemanager, codes 1..5. */
    private fun shellWhitelistPackage(pkg: String) {
        for (code in 1..5) {
            execShell(
                "service call " + serviceAccMode() + " " + code + " s16 '" + pkg + "' 2>/dev/null"
            )
        }
    }

    private fun acquireWakeLock(context: Context) {
        try {
            val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager?
            if (pm != null) {
                wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "SentryDaemon::Lock")
                    .also { it.acquire() }
                log("WakeLock acquired")
            }
        } catch (e: Exception) {
            log("WARN: Failed to acquire WakeLock: " + e.message)
        }
    }

    @SuppressLint("WrongConstant")
    private fun whitelistUidForNetwork(context: Context, uid: Int) {
        val uidStr = uid.toString()
        log("Whitelisting UID $uid...")

        // Try byd_datacached
        try {
            val service = context.getSystemService(serviceBydDataCache())
            if (service != null) {
                service.javaClass
                    .getMethod("setAppStartupData", String::class.java, Integer.TYPE)
                    .invoke(service, uidStr, 0)
                log("  byd_datacached: OK")
                return
            }
        } catch (e: Exception) {
            log("whitelistUidForNetwork byd_datacached failed: " + e.message)
        }

        // Try bg_datacache
        try {
            val service = context.getSystemService(serviceBgDataCache())
            if (service != null) {
                service.javaClass
                    .getMethod("setAppOpsData", String::class.java, Integer.TYPE)
                    .invoke(service, uidStr, 0)
                log("  bg_datacache: OK")
                return
            }
        } catch (e: Exception) {
            log("whitelistUidForNetwork bg_datacache failed: " + e.message)
        }

        // Shell fallback
        shellWhitelistUid(uidStr)
        log("  shell fallback: done")
    }

    @SuppressLint("WrongConstant")
    private fun whitelistAppPackage(context: Context) {
        val pkg = appPackageName()
        log("Whitelisting package $pkg...")

        try {
            val accManager = context.getSystemService(serviceAccMode())
            if (accManager != null) {
                val mServiceField = accManager.javaClass.getDeclaredField("mService")
                mServiceField.isAccessible = true
                val iAccService = mServiceField.get(accManager)

                if (iAccService != null) {
                    val whitelistMethod = iAccService.javaClass
                        .getDeclaredMethod("setPkg2AccWhiteList", String::class.java)
                    whitelistMethod.isAccessible = true
                    whitelistMethod.invoke(iAccService, pkg)
                    log("  accmodemanager: OK")
                    return
                }
            }
        } catch (e: Exception) {
            log("whitelistAppPackage accmodemanager failed: " + e.message)
        }

        // Shell fallback
        shellWhitelistPackage(pkg)
        log("  shell fallback: done")
    }

    private fun whitelistAppUid(context: Context) {
        val pkg = appPackageName()
        try {
            val appUid = context.packageManager.getApplicationInfo(pkg, 0).uid
            log("App UID: $appUid")
            whitelistUidForNetwork(context, appUid)
        } catch (e: Exception) {
            log("Could not get app UID: " + e.message)
        }
    }

    private fun enableWifi() {
        log("Enabling WiFi (async)...")
        Thread({
            execShell(cmdWifiEnable())
            execShell(cmdWifiEnableAlt())
            log("WiFi enable commands completed")
        }, "WifiEnable").start()
    }

    // ==================== CONTEXT HELPERS ====================

    private fun getSystemContext(): Context? {
        return try {
            val activityThreadClass = Class.forName("android.app.ActivityThread")
            val activityThread = resolveActivityThread(activityThreadClass) ?: return null
            activityThreadClass.getMethod("getSystemContext").invoke(activityThread) as Context?
        } catch (e: Exception) {
            log("getSystemContext failed: " + e.message)
            null
        }
    }

    private fun createAppContext(): Context? {
        return try {
            val activityThreadClass = Class.forName("android.app.ActivityThread")
            val activityThread = resolveActivityThread(activityThreadClass)

            if (activityThread == null) {
                log("createAppContext: all strategies failed, using null-safe fallback")
                return PermissionBypassContext(null)
            }

            val systemContext = activityThreadClass.getMethod("getSystemContext")
                .invoke(activityThread) as Context?
                ?: return PermissionBypassContext(null)

            PermissionBypassContext(
                systemContext.createPackageContext(
                    appPackageName(),
                    Context.CONTEXT_INCLUDE_CODE or Context.CONTEXT_IGNORE_SECURITY
                )
            )
        } catch (e: Exception) {
            log("createAppContext failed: " + e.message)
            PermissionBypassContext(null)
        }
    }

    /**
     * Resolve ActivityThread using 3 strategies:
     * 1. currentActivityThread() — fastest, works when app process is running
     * 2. systemMain() with timeout — works on some boot conditions, can deadlock
     * 3. Manual constructor + Looper.prepareMainLooper — reliable fallback
     */
    private fun resolveActivityThread(activityThreadClass: Class<*>): Any? {
        // Strategy 1: existing thread
        try {
            activityThreadClass.getMethod("currentActivityThread").invoke(null)?.let { return it }
        } catch (ignored: Exception) {
            // Falls through to strategy 2.
        }

        // Strategy 2: systemMain with timeout
        val result = arrayOfNulls<Any>(1)
        try {
            val t = Thread({
                try {
                    result[0] = activityThreadClass.getMethod("systemMain").invoke(null)
                } catch (ignored: Exception) {
                    // Leaves result[0] null; caller falls through to strategy 3.
                }
            }, "SystemMainInit")
            t.isDaemon = true
            t.start()
            t.join(10_000)
            if (t.isAlive) {
                log("resolveActivityThread: systemMain timed out")
                t.interrupt()
                // Check if it partially initialized
                try {
                    activityThreadClass.getMethod("currentActivityThread").invoke(null)
                        ?.let { return it }
                } catch (ignored: Exception) {
                    // Falls through to strategy 3.
                }
            } else if (result[0] != null) {
                return result[0]
            }
        } catch (ignored: Exception) {
            // Falls through to strategy 3.
        }

        // Strategy 3: manual creation
        try {
            prepareMainLooperForShellDaemon()
            val ctor = activityThreadClass.getDeclaredConstructor()
            ctor.isAccessible = true
            val at = ctor.newInstance()
            try {
                val f = activityThreadClass.getDeclaredField("sCurrentActivityThread")
                f.isAccessible = true
                f.set(null, at)
            } catch (ignored: Exception) {
                // Non-fatal: the instance is still usable for getSystemContext().
            }
            log("resolveActivityThread: manual creation succeeded")
            return at
        } catch (e: Exception) {
            log("resolveActivityThread: manual creation failed: " + e.message)
        }

        return null
    }

    @Suppress("DEPRECATION")
    private fun prepareMainLooperForShellDaemon() {
        // app_process daemons do not get Android's standard main looper; BYD
        // hardware callbacks need one even though app code should not call this.
        try {
            Looper.prepareMainLooper()
        } catch (ignored: Exception) {
            // Already prepared on this thread — harmless.
        }
    }

    private class PermissionBypassContext(base: Context?) : ContextWrapper(base) {
        override fun enforceCallingOrSelfPermission(permission: String, message: String?) {}

        override fun enforcePermission(
            permission: String,
            pid: Int,
            uid: Int,
            message: String?
        ) {
        }

        override fun enforceCallingPermission(permission: String, message: String?) {}

        override fun checkCallingOrSelfPermission(permission: String): Int =
            PackageManager.PERMISSION_GRANTED

        override fun checkPermission(permission: String, pid: Int, uid: Int): Int =
            PackageManager.PERMISSION_GRANTED

        override fun checkSelfPermission(permission: String): Int =
            PackageManager.PERMISSION_GRANTED

        // Null-safe overrides for fallback mode (base=null)
        override fun getApplicationContext(): Context = try {
            super.getApplicationContext()
        } catch (e: NullPointerException) {
            this
        }

        override fun getPackageName(): String = try {
            super.getPackageName()
        } catch (e: NullPointerException) {
            appPackageName()
        }

        override fun getSystemService(name: String): Any? = try {
            super.getSystemService(name)
        } catch (e: NullPointerException) {
            null
        }

        override fun getApplicationInfo(): ApplicationInfo = try {
            super.getApplicationInfo()
        } catch (e: NullPointerException) {
            ApplicationInfo()
        }

        override fun getContentResolver(): ContentResolver? = try {
            super.getContentResolver()
        } catch (e: NullPointerException) {
            null
        }

        override fun getResources(): Resources? = try {
            super.getResources()
        } catch (e: NullPointerException) {
            null
        }

        override fun createPackageContext(packageName: String, flags: Int): Context = try {
            super.createPackageContext(packageName, flags)
        } catch (e: Exception) {
            this
        }
    }

    // ==================== SHELL EXECUTION ====================

    private fun execShell(cmd: String): String {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("sh", "-c", cmd))
            process.waitFor()
            val output = StringBuilder()
            BufferedReader(InputStreamReader(process.inputStream)).use { reader ->
                var line = reader.readLine()
                while (line != null) {
                    output.append(line).append("\n")
                    line = reader.readLine()
                }
            }
            output.toString().trim()
        } catch (e: Exception) {
            "ERROR: " + e.message
        }
    }

    // ==================== DAEMON CONTROL (KILL HANDLING) ====================

    /** SentryDaemon control (19876=CameraDaemon, 19877=Surveillance IPC, 19878=BydEventDaemon) */
    private const val CONTROL_PORT = 19879

    private fun pidFile(): String = pathSentryPid()

    @Volatile
    private var running = true

    private var controlSocket: ServerSocket? = null

    /**
     * Start control socket for clean shutdown.
     * Listens on localhost:19879 for "STOP" command.
     */
    private fun startControlSocket() {
        Thread({
            try {
                val server = ServerSocket(CONTROL_PORT, 1, InetAddress.getByName("127.0.0.1"))
                controlSocket = server
                log("Control socket listening on port $CONTROL_PORT")

                while (running) {
                    try {
                        val client = server.accept()
                        client.soTimeout = 5000

                        val reader = BufferedReader(InputStreamReader(client.getInputStream()))
                        val writer = PrintWriter(client.getOutputStream(), true)

                        val command = reader.readLine()?.trim()?.uppercase()
                        if (command != null) {
                            log("Control command: $command")

                            when (command) {
                                "STOP", "KILL", "EXIT" -> {
                                    writer.println("OK:STOPPING")
                                    client.close()
                                    shutdown()
                                }

                                "STATUS" -> writer.println(
                                    "OK:RUNNING:PID=" + Process.myPid() +
                                        ":LOCATION_MONITOR=" +
                                        (if (locationMonitorEnabled) "ON" else "OFF")
                                )

                                "PING" -> writer.println("OK:PONG")

                                "LOCATION_MONITOR_ON" -> {
                                    startLocationMonitor()
                                    writer.println("OK:LOCATION_MONITOR_STARTED")
                                }

                                "LOCATION_MONITOR_OFF" -> {
                                    stopLocationMonitor()
                                    writer.println("OK:LOCATION_MONITOR_STOPPED")
                                }

                                "LOCATION_RESTART" -> {
                                    restartLocationService()
                                    writer.println("OK:LOCATION_RESTART_TRIGGERED")
                                }

                                else -> writer.println("ERROR:UNKNOWN_COMMAND")
                            }
                        }

                        client.close()
                    } catch (e: SocketTimeoutException) {
                        // Ignore timeout
                    } catch (e: Exception) {
                        if (running) {
                            log("Control socket error: " + e.message)
                        }
                    }
                }
            } catch (e: Exception) {
                log("Failed to start control socket: " + e.message)
            }
        }, "ControlSocket").start()
    }

    /** Write PID file for external kill scripts. */
    private fun writePidFile() {
        try {
            val pid = Process.myPid()
            File(pidFile()).writeText(pid.toString())
            log("PID file written: " + pidFile() + " (PID=" + pid + ")")
        } catch (e: Exception) {
            log("Failed to write PID file: " + e.message)
        }
    }

    /** Delete PID file on exit. */
    private fun deletePidFile() {
        try {
            File(pidFile()).delete()
        } catch (e: Exception) {
            log("WARN: deletePidFile failed: " + e.message)
        }
    }

    /** Clean shutdown - release resources and exit. */
    private fun shutdown() {
        log("=== SHUTTING DOWN ===")
        running = false

        // Release ACC Lock
        // releaseAccLock();

        // Release WakeLock
        wakeLock?.let {
            if (it.isHeld) {
                try {
                    it.release()
                    log("WakeLock released")
                } catch (e: Exception) {
                    log("WARN: wakeLock.release() failed: " + e.message)
                }
            }
        }

        // Close control socket
        controlSocket?.let {
            try {
                it.close()
            } catch (e: Exception) {
                log("controlSocket.close() failed: " + e.message)
            }
        }

        // Delete PID file
        deletePidFile()

        log("Goodbye!")
        System.exit(0)
    }

    // ==================== LOCATION SIDECAR SERVICE MONITOR ====================

    private const val LOCATION_SERVICE_NAME =
        "net.bladewatch.app/.services.LocationSidecarService"

    private fun appPkg(): String = appPackageName()

    /** 15 seconds */
    private const val LOCATION_CHECK_INTERVAL_MS = 15000L

    @Volatile
    private var locationMonitorEnabled = false

    /**
     * Start Location Sidecar monitoring thread.
     * Checks every 15 seconds if LocationSidecarService is running and restarts it if needed.
     */
    @JvmStatic
    fun startLocationMonitor() {
        if (locationMonitorEnabled) {
            log("Location Monitor already running")
            return
        }

        locationMonitorEnabled = true

        Thread({
            log("=== LOCATION MONITOR STARTED ===")
            log("Checking every " + (LOCATION_CHECK_INTERVAL_MS / 1000) + "s")

            // Setup location permissions first
            setupLocationPermissions()

            var firstCheck = true

            while (running && locationMonitorEnabled) {
                try {
                    if (!firstCheck) {
                        Thread.sleep(LOCATION_CHECK_INTERVAL_MS)
                    }
                    firstCheck = false

                    // Check if Location service is running
                    val result = execShell(
                        "dumpsys activity services $LOCATION_SERVICE_NAME 2>/dev/null"
                    )

                    val isRunning = result.contains("ServiceRecord") &&
                        result.contains("app=ProcessRecord") &&
                        !result.contains("app=null")

                    if (!isRunning) {
                        log("Location Monitor: Service not running, restarting...")
                        restartLocationService()
                    }
                } catch (e: InterruptedException) {
                    log("Location Monitor interrupted")
                    Thread.currentThread().interrupt()
                    break
                } catch (e: Exception) {
                    log("Location Monitor error: " + e.message)
                }
            }

            log("=== LOCATION MONITOR STOPPED ===")
        }, "LocationMonitor").start()
    }

    /** Stop Location monitoring. */
    @JvmStatic
    fun stopLocationMonitor() {
        locationMonitorEnabled = false
    }

    /** Setup location permissions using shell commands. */
    private fun setupLocationPermissions() {
        log("Setting up Location permissions...")

        val pkg = appPkg()

        // Grant runtime permissions via pm grant (requires shell/root)
        execShell("pm grant $pkg android.permission.ACCESS_FINE_LOCATION")
        execShell("pm grant $pkg android.permission.ACCESS_COARSE_LOCATION")
        execShell("pm grant $pkg android.permission.ACCESS_BACKGROUND_LOCATION")

        // Allow background location via appops
        execShell("appops set $pkg ACCESS_FINE_LOCATION allow")
        execShell("appops set $pkg ACCESS_COARSE_LOCATION allow")
        execShell("appops set $pkg ACCESS_BACKGROUND_LOCATION allow")

        // Allow background operation
        execShell("appops set $pkg RUN_IN_BACKGROUND allow")
        execShell("appops set $pkg RUN_ANY_IN_BACKGROUND allow")

        // Whitelist from battery optimization
        execShell("dumpsys deviceidle whitelist +$pkg")

        // Apply power settings
        execShell("settings put global wifi_sleep_policy 2")
        execShell("settings put global stay_on_while_plugged_in 7")

        log("Location permissions configured")
    }

    /** Time for the freshly-started service host process to exist before we start its service. */
    private const val SERVICE_HOST_WAKE_SETTLE_MS = 1500L

    /**
     * Whether the service host process must be woken before a service start will be honoured.
     *
     * Pure so the decision is testable: `SentryDaemon` cannot be constructed on the
     * JVM. `execShell` returns COMBINED output, so anything that is not a bare PID —
     * empty, blank, or an error message — has to mean "not running". Reading shell noise as a
     * live PID would skip the wake and let the service start be silently ignored again, which
     * is the failure this exists to prevent.
     */
    @JvmStatic
    fun needsServiceHostWake(pidofOutput: String?): Boolean {
        if (pidofOutput == null) return true
        val trimmed = pidofOutput.trim()
        if (trimmed.isEmpty()) return true
        for (c in trimmed) {
            if (c < '0' || c > '9') {
                if (c == ' ' || c == '\n' || c == '\r' || c == '\t') continue
                return true // not a bare PID list — treat as not running
            }
        }
        return false
    }

    /**
     * Restart the Location Sidecar service by starting the foreground service directly.
     */
    private fun restartLocationService() {
        log("Location Monitor: Restarting Location service via foreground service...")

        val pkg = appPkg()

        // Start the foreground service directly. This works from shell UID 2000 and is the
        // only method; there is deliberately no broadcast fallback.
        //
        // BladeWatch-boat: there used to be a "Method 2" that ran
        //   am broadcast -a android.intent.action.BOOT_COMPLETED -n <pkg>/.receiver.LocationBootReceiver
        // BOOT_COMPLETED is a PROTECTED broadcast — only the system may send it, so from uid
        // 2000 it is refused every single time, permanently. Retrying cannot help. Worse, each
        // attempt dumped a 16-line SecurityException into a 256KB logcat ring (31 denials in a
        // single buffer, doubled by the duplicate-daemon bug BladeWatch-f0y3), which rotated
        // away the logs needed to diagnose anything else. Note LocationBootReceiver is still a
        // valid receiver for the REAL system broadcast and is unchanged — and on this head unit
        // BOOT_COMPLETED never reaches this app anyway because of BYD's ssc_skip
        // (BladeWatch-5rew). Do not reintroduce it.
        // BladeWatch-op3h: BYD's ssc_skip IGNORES a shell-UID service start when the target app
        // UID is not already running, and ActivityManager surfaces that as the misleading
        // "Error: Not found; no service started." (exit 255). Measured on the head unit:
        //   ssc_skip startServiceLocked 2000 want to start 10073, package net.bladewatch.app
        //   UID 10073 is not running
        //   ssc_skip ... ignored !!!
        // Starting the exported MainActivity first brings the UID up; the identical command
        // then exits 0. This is the same explicit-component-start workaround the Flutter APK's
        // wakeServiceHost() uses for the broadcast form of ssc_skip (BladeWatch-5rew).
        // MainActivity is a bootstrap that calls moveTaskToBack(true) immediately, so waking it
        // does not put anything on screen.
        if (needsServiceHostWake(execShell("pidof $pkg 2>&1"))) {
            log(
                "Location Monitor: service host not running — waking it (ssc_skip would ignore " +
                    "the service start otherwise)"
            )
            execShell("am start -n $pkg/.ui.MainActivity 2>&1")
            try {
                Thread.sleep(SERVICE_HOST_WAKE_SETTLE_MS)
            } catch (ie: InterruptedException) {
                Thread.currentThread().interrupt()
            }
        }

        val result1 = execShell(
            "am start-foreground-service -n $pkg/.services.LocationSidecarService 2>&1"
        )
        log("Location restart (foreground service): $result1")
        if (ShellResultClassifier.isFailure(result1)) {
            log("Location Monitor: WARN - foreground service start failed")
        }

        // Wait and verify
        try {
            Thread.sleep(3000)
        } catch (e: InterruptedException) {
            Thread.currentThread().interrupt()
        }

        val verify = execShell("dumpsys activity services $LOCATION_SERVICE_NAME 2>/dev/null")
        if (verify.contains("ServiceRecord") && !verify.contains("app=null")) {
            log("Location Monitor: Location service restarted successfully!")
        } else {
            log(
                "Location Monitor: Location service restart pending (verify: " +
                    verify.substring(0, minOf(verify.length, 120)) + ")"
            )
        }
    }

    /**
     * Send stop command to running daemon.
     * Call this from app to kill the daemon cleanly.
     *
     * @return true if daemon was stopped, false if not running or error
     */
    @JvmStatic
    fun sendStopCommand(): Boolean = controlCommand("STOP") { it.startsWith("OK") }

    /**
     * Check if daemon is running.
     *
     * @return true if daemon is running
     */
    @JvmStatic
    fun isDaemonRunning(): Boolean = controlCommand("PING") { it.contains("PONG") }

    /**
     * One request/response round trip against the control socket. sendStopCommand and
     * isDaemonRunning differ only in the verb and how they read the reply; any failure to
     * connect means "not running", which is false for both.
     */
    private inline fun controlCommand(verb: String, accept: (String) -> Boolean): Boolean {
        return try {
            Socket("127.0.0.1", CONTROL_PORT).use { socket ->
                socket.soTimeout = if (verb == "PING") 2000 else 5000
                val writer = PrintWriter(socket.getOutputStream(), true)
                val reader = BufferedReader(InputStreamReader(socket.getInputStream()))
                writer.println(verb)
                val response = reader.readLine()
                response != null && accept(response)
            }
        } catch (e: Exception) {
            false
        }
    }

    /** Kill daemon by PID file (fallback if socket doesn't work). */
    @JvmStatic
    fun killByPidFile() {
        try {
            val pidStr = File(pidFile()).bufferedReader().use { it.readLine() }

            if (!pidStr.isNullOrEmpty()) {
                val pid = pidStr.trim().toInt()
                Runtime.getRuntime().exec(arrayOf("kill", "-9", pid.toString()))
            }
        } catch (e: Exception) {
            log("WARN: killByPidFile failed: " + e.message)
        }
    }
}
