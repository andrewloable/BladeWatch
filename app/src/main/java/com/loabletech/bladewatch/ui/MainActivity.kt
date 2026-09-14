package net.bladewatch.app.ui

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import net.bladewatch.app.R
import net.bladewatch.app.launcher.AdbDaemonLauncher
import net.bladewatch.app.storage.StorageSetup
import net.bladewatch.app.ui.daemon.DaemonStartupManager
import net.bladewatch.app.util.BydDataCacheWhitelist

/**
 * The daemon APK's startup bootstrap. **This is not a UI.**
 *
 * BladeWatch-81g9.2 deleted the native in-car UI; `net.bladewatch.flutter` is the only
 * in-car UI now. What survives here is the work nothing else does, in the order it has
 * to happen:
 *
 *  1. `setupStorageDirectories()`, posted off the onCreate critical path — a failure (a
 *     ROM lacking the All-Files-Access settings activity, as on BYD SL7) must not abort
 *     launch.
 *  2. `DeviceIdGenerator.init` then `generateDeviceId`, **before any daemon starts**,
 *     because the daemon reads the synced device-id file.
 *  3. `BydDataCacheWhitelist.applyAll` on a background thread — `ActivityThread.systemMain()`
 *     can block for over a minute waiting for system services.
 *  4. `DaemonStartupManager` with its staggered timing (core ~45s, optional ~60s, health
 *     checks from ~90s every 30s).
 *  5. The one-shot cleanup of the APK the removed in-app updater used to stage.
 *
 * It has NO launcher entry (BladeWatch-81g9.1). It is started explicitly: by the Flutter
 * UI when the user opens it, by `BootReceiver`, by `DaemonKeepaliveService`, and by a
 * developer over ADB — which is the only remaining way in if the Flutter APK is broken.
 *
 * It carries no layout. `minimize_on_start` sends it straight to the back so the user
 * never sees a blank screen; without that extra it still shows nothing, because
 * `setContentView` is never called.
 *
 * **`DaemonStartupManager` is constructed with no ViewModel on purpose.** It is designed
 * for that — `startCoreDaemons()` falls back to `startCoreDaemonsViaAdb()` with
 * "ViewModel not available, using ADB launcher". That path is what the service host wants,
 * and it is what `BootReceiver.startOnBoot` has always used. Verified on the head unit:
 * all three daemons start.
 *
 * Extends `Activity`, not `AppCompatActivity` — there is no AppCompat UI left to host, and
 * this keeps the daemon APK off a dependency BladeWatch-81g9.3 can then drop.
 */
class MainActivity : Activity() {

    private lateinit var daemonStartupManager: DaemonStartupManager

    // Everything posted here is deliberately NOT cancelled in onDestroy(), for the same
    // reason the daemons are not stopped there: this activity exists only to kick off
    // work that must outlive it. It calls moveTaskToBack() immediately, so if the system
    // then reclaims it, cancelling would mean daemon startup (posted at +1s) silently
    // never happens — the one failure this activity cannot afford. The cost is holding
    // the instance until the last runnable fires, ~10s, on a device running one app.
    //
    // A previous `updateCheckRunnable` field lived here, cleared in onDestroy() under a
    // comment about cancelling "the periodic work". It was never assigned — the periodic
    // update check went with the in-app OTA updater — so it cancelled nothing while
    // reading as though pending work were handled.
    private val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Deliberately no setContentView: this activity has no UI.

        // Storage setup is posted off the onCreate critical path so a failure
        // (e.g. ROM lacking the All-Files-Access Settings activity on BYD SL7)
        // cannot abort activity launch. See setupStorageDirectories().
        window.decorView.post {
            try {
                setupStorageDirectories()
            } catch (e: Exception) {
                android.util.Log.e("MainActivity", "Deferred storage setup failed: ${e.message}", e)
            }
        }

        // Initialize DeviceIdGenerator with ADB executor for file sync
        val adbExecutor = net.bladewatch.app.launcher.AdbShellExecutor(this)
        net.bladewatch.app.util.DeviceIdGenerator.init(adbExecutor)

        // Generate device ID early - this syncs to file for daemon compatibility
        // Must happen BEFORE any daemon starts
        val deviceId = net.bladewatch.app.util.DeviceIdGenerator.generateDeviceId(this)
        android.util.Log.i("MainActivity", "Device ID initialized: $deviceId")

        // Apply BYD whitelist (ACC + data cache) to prevent background killing
        // CRITICAL: Run on background thread to avoid blocking UI on boot
        // ActivityThread.systemMain() can block for 1+ minute waiting for system services
        Thread {
            try {
                BydDataCacheWhitelist.applyAll(this)
            } catch (e: Exception) {
                android.util.Log.e("MainActivity", "BYD whitelist error: ${e.message}")
            }
        }.start()

        // Initialize daemon startup manager (no ViewModel — see the class comment)
        daemonStartupManager = DaemonStartupManager(this)

        // Setup ADB auth callback to re-initialize when auth is granted
        setupAdbAuthCallback()

        android.util.Log.i("MainActivity", "BladeWatch service host started")

        // Seed out-of-process revival watchdog so the process gets resurrected
        // if it ever gets force-stopped or OOM-killed without an external event.
        try {
            net.bladewatch.app.receiver.ProcessRevivalReceiver.schedule(applicationContext)
        } catch (e: Exception) {
            android.util.Log.w("MainActivity", "ProcessRevivalReceiver.schedule failed: ${e.message}")
        }

        // Start Location Sidecar service (establishes ADB connection)
        startLocationSidecarService()

        // Initialize daemons after a short delay to allow ADB connection.
        // If the package was just replaced, run DaemonHardReset.hardResetDaemons
        // FIRST so any zombie daemons / watchdogs from the previous install are
        // dead before the new daemon launcher starts.
        val isPostInstall = net.bladewatch.app.launcher.DaemonHardReset
            .isPostInstallLaunch(this, intent)
        mainHandler.postDelayed({
            // Sync device ID to file synchronously before daemon startup
            Thread {
                try {
                    val synced = net.bladewatch.app.util.DeviceIdGenerator.syncDeviceIdToFileSync(this)
                    android.util.Log.i("MainActivity", "Device ID sync result: $synced")
                } catch (e: Exception) {
                    android.util.Log.e("MainActivity", "Device ID sync error: ${e.message}")
                }

                val startDaemons = Runnable {
                    runOnUiThread {
                        daemonStartupManager.initializeOnAppLaunch()
                        mainHandler.postDelayed({
                            daemonStartupManager.checkAllDaemonStatuses()
                        }, 3000)
                    }
                }

                if (isPostInstall) {
                    android.util.Log.i("MainActivity", "Post-install launch — hard-resetting daemons before startup")
                    net.bladewatch.app.launcher.DaemonHardReset.hardResetDaemons(this) {
                        startDaemons.run()
                    }
                } else {
                    startDaemons.run()
                }
            }.start()
        }, 1000)

        // Handle Location start intent (from SentryDaemon restart)
        handleLocationStartIntent(intent)

        // One-time cleanup of the APK the removed in-app updater used to stage.
        // Harmless once every device has been through it; costs one shell call.
        mainHandler.postDelayed({
            val adb = AdbDaemonLauncher(this)
            adb.executeShellCommand("rm -f /data/local/tmp/bladewatch_update.apk", object : AdbDaemonLauncher.LaunchCallback {
                override fun onLog(message: String) {}
                override fun onLaunched() {}
                override fun onError(error: String) {}
            })
        }, 10000) // 10 seconds after launch

        // Status overlay: start immediately if permission granted
        startStatusOverlay()

        // There is no UI to show. Whether or not the caller asked for it, get out of the
        // way — a visible blank activity over the BYD home screen is worse than nothing.
        // The extra is kept because callers still set it and it documents the intent.
        if (intent?.getBooleanExtra("minimize_on_start", false) == true) {
            android.util.Log.i("MainActivity", "Boot launch — minimizing to background")
        }
        moveTaskToBack(true)
    }

    /** Start the status overlay service if overlay permission is granted. */
    private fun startStatusOverlay() {
        val hasPermission = net.bladewatch.app.overlay.StatusOverlayService.hasOverlayPermission(this)
        android.util.Log.i("MainActivity", "Overlay permission: $hasPermission")
        if (hasPermission) {
            net.bladewatch.app.overlay.StatusOverlayService.startIfPermitted(this)
        }
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        intent?.let { handleLocationStartIntent(it) }
    }

    override fun onResume() {
        super.onResume()
        // Try to start overlay if permission was just granted (user returned from settings)
        net.bladewatch.app.overlay.StatusOverlayService.startIfPermitted(this)
        // Re-sync the auth device secret from the daemon. After a reinstall or
        // daemon restart the app can hold a stale cached secret and sign invalid
        // JWTs ("Camera unavailable") until force-stopped; invalidating here lets
        // the next authenticated call pull the daemon's current secret over IPC.
        net.bladewatch.app.auth.AuthManager.refresh()
        try {
            val sm = net.bladewatch.app.storage.StorageManager.getInstance()
            if (!sm.isSdCardAvailable()) sm.refreshSdCard()
        } catch (_: Throwable) {}
    }

    /**
     * Re-initialize daemons when ADB auth is granted. This handles the case where the
     * user accepts the USB-debugging prompt after the initial connection attempt failed —
     * common right after a reinstall, which wipes the ADB key.
     */
    private fun setupAdbAuthCallback() {
        net.bladewatch.app.launcher.AdbShellExecutor.setAuthCallback(object : net.bladewatch.app.launcher.AdbShellExecutor.AdbAuthCallback {
            override fun onAuthPending() {
                android.util.Log.i("MainActivity", "Waiting for ADB authorization...")
            }

            override fun onAuthGranted() {
                runOnUiThread {
                    android.util.Log.i("MainActivity", "ADB authorization granted — re-initializing daemons")
                    mainHandler.postDelayed({
                        daemonStartupManager.initializeOnAppLaunch()
                        mainHandler.postDelayed({
                            daemonStartupManager.checkAllDaemonStatuses()
                        }, 3000)
                    }, 500)
                }
            }

            override fun onAuthFailed(error: String) {
                android.util.Log.e("MainActivity", "ADB connection failed: $error")
            }
        })
    }

    /**
     * Setup storage directories from the app so it becomes the owner, so both app and
     * daemon can read/write them. Android 11+ needs MANAGE_EXTERNAL_STORAGE; Android 10
     * and below needs the WRITE_EXTERNAL_STORAGE runtime permission.
     */
    private fun setupStorageDirectories() {
        android.util.Log.i("MainActivity", "========== CHECKING STORAGE PERMISSION ==========")
        val hasPermission = StorageSetup.checkStoragePermission(this)
        android.util.Log.i("MainActivity", "checkStoragePermission() = $hasPermission")

        if (hasPermission) {
            android.util.Log.i("MainActivity", "Permission OK - calling setupDirectories()")
            val success = StorageSetup.setupDirectories()
            if (success) {
                android.util.Log.i("MainActivity", "Storage directories ready (App is owner)")
            } else {
                android.util.Log.w("MainActivity", "Some storage directories could not be created")
            }
            return
        }

        // On Android 10 and below, the only path is the standard runtime
        // permission dialog for WRITE_EXTERNAL_STORAGE. No MES, no app-ops.
        // Preserve the original behaviour exactly.
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.R) {
            android.util.Log.i("MainActivity", "Pre-R: requesting runtime WRITE_EXTERNAL_STORAGE")
            fallbackToSettingsRequest()
            return
        }

        // Android 11+: best-effort directory creation in legacy mode regardless
        // of MES state, so recordings still work on this launch even if MES
        // never lands. With requestLegacyExternalStorage="true" + targetSdk 25,
        // WRITE_EXTERNAL_STORAGE is enough for our own paths under
        // /storage/emulated/0/BladeWatch.
        val legacySuccess = StorageSetup.setupDirectories()
        android.util.Log.i("MainActivity", "Legacy-mode setupDirectories success=$legacySuccess")

        // Try the silent app-ops path first (only viable route on BYD SL7 which
        // lacks the All-Files-Access Settings activity). Settings intent is only
        // opened if the app-ops grant fails to land.
        android.util.Log.i("MainActivity", "MES missing - attempting silent app-ops grant via ADB")
        try {
            val adb = net.bladewatch.app.launcher.AdbShellExecutor(this)
            StorageSetup.tryGrantViaAppOps(this, adb) { granted ->
                runOnUiThread { onAppOpsGrantResult(granted) }
            }
        } catch (e: Exception) {
            android.util.Log.w("MainActivity", "app-ops pre-grant threw, falling back to Settings: ${e.message}")
            fallbackToSettingsRequest()
        }
    }

    private fun onAppOpsGrantResult(granted: Boolean) {
        if (granted) {
            android.util.Log.i("MainActivity", "MES granted via app-ops; refreshing directories")
            val success = StorageSetup.setupDirectories()
            android.util.Log.i("MainActivity", "Post-grant setupDirectories success=$success")
            return
        }
        android.util.Log.w("MainActivity", "app-ops grant did not take; falling back to Settings UI")
        fallbackToSettingsRequest()
    }

    private fun fallbackToSettingsRequest() {
        when (StorageSetup.requestStoragePermission(this)) {
            StorageSetup.RequestOutcome.REQUESTED_RUNTIME,
            StorageSetup.RequestOutcome.OPENED_SETTINGS -> {
                // Result delivered to onRequestPermissionsResult / onActivityResult.
            }
            StorageSetup.RequestOutcome.UNAVAILABLE -> {
                android.util.Log.w(
                    "MainActivity",
                    "All-Files-Access UI unavailable; staying in legacy storage mode"
                )
            }
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == StorageSetup.REQUEST_CODE_STORAGE_PERMISSION) {
            // Android 11+ Settings result
            if (StorageSetup.checkStoragePermission(this)) {
                android.util.Log.i("MainActivity", "Storage permission granted! Creating directories...")
                StorageSetup.setupDirectories()
            } else {
                android.util.Log.e("MainActivity", "Storage permission denied by user")
                Toast.makeText(this, getString(R.string.toast_storage_permission_required), Toast.LENGTH_LONG).show()
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode == StorageSetup.REQUEST_CODE_RUNTIME_PERMISSION) {
            // Android 10 and below runtime permission result
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == android.content.pm.PackageManager.PERMISSION_GRANTED
            android.util.Log.i("MainActivity", "Runtime permission result: granted=$granted")

            if (granted) {
                android.util.Log.i("MainActivity", "Storage permission granted! Creating directories...")
                StorageSetup.setupDirectories()
            } else {
                android.util.Log.e("MainActivity", "Storage permission denied by user")
                Toast.makeText(this, getString(R.string.toast_storage_permission_required), Toast.LENGTH_LONG).show()
            }
        }
    }

    /**
     * Auto-start the Location Sidecar service for GPS tracking. Runs silently in the
     * background and is monitored by SentryDaemon.
     *
     * Calls `AdbDaemonLauncher` directly. It used to route through DaemonsViewModel,
     * which only forwarded to the same launcher — and that ViewModel went with the UI.
     */
    private fun startLocationSidecarService() {
        android.util.Log.i("MainActivity", "Auto-starting Location Sidecar service via ADB...")
        AdbDaemonLauncher(this).startLocationSidecarService(object : AdbDaemonLauncher.LaunchCallback {
            override fun onLog(message: String) {
                android.util.Log.d("MainActivity", "Location: $message")
            }

            override fun onLaunched() {
                android.util.Log.i("MainActivity", "Location Sidecar service started successfully")
            }

            override fun onError(error: String) {
                android.util.Log.e("MainActivity", "Failed to start Location Sidecar: $error")
            }
        })
    }

    /**
     * Handle the Location start intent from SentryDaemon or the boot receiver — sent when
     * the daemon detects the Location service died and launches the app to restart it.
     */
    private fun handleLocationStartIntent(intent: Intent) {
        val action = intent.action
        val startLocation = intent.getBooleanExtra("start_location", false)

        if (action == "net.bladewatch.app.START_LOCATION_ACTIVITY" || startLocation) {
            android.util.Log.i("MainActivity", "Received Location start intent from SentryDaemon")

            mainHandler.postDelayed({
                android.util.Log.i("MainActivity", "Auto-starting Location service...")
                try {
                    val serviceIntent = Intent(this, net.bladewatch.app.services.LocationSidecarService::class.java)
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        startForegroundService(serviceIntent)
                    } else {
                        startService(serviceIntent)
                    }
                    android.util.Log.i("MainActivity", "Location service start requested")
                } catch (e: Exception) {
                    android.util.Log.e("MainActivity", "Failed to start Location service: ${e.message}")
                }
            }, 1000)
        }
    }

    override fun onDestroy() {
        // Remove ADB auth callback — this one IS cleared, because it is a static field on
        // AdbShellExecutor and would otherwise hold this activity for the process's life,
        // not merely until a pending runnable fires.
        net.bladewatch.app.launcher.AdbShellExecutor.setAuthCallback(null)
        // Pending mainHandler work is deliberately left to run — see the field comment.
        // Note: We intentionally do NOT stop the daemons here.
        // Daemons must persist after the activity goes away — that is the whole point.
        super.onDestroy()
    }
}
