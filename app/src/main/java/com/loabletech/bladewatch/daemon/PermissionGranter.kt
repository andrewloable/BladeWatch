package net.bladewatch.app.daemon

import android.os.Process

import java.io.BufferedReader
import java.io.InputStreamReader

/**
 * Shell-based permission granter for daemon processes.
 *
 * Grants all manifest-declared permissions via `pm grant` shell commands.
 * Belt-and-suspenders approach alongside PermissionBypassContext:
 * - PermissionBypassContext fakes PERMISSION_GRANTED for our own process
 * - PermissionGranter actually grants permissions at the OS level via shell
 *
 * This handles cases where BYD HAL native code checks permissions outside
 * our context wrapper (e.g., deep in the system_server or HAL layer).
 *
 * pm grant works from UID 2000 (shell) which is what our daemons run as.
 * Install-time / signature permissions will be silently skipped.
 */
object PermissionGranter {

    private const val TAG = "PermissionGranter"
    private var hasRun = false
    private var grantThread: Thread? = null

    /** Delay between individual pm grant calls to avoid flooding PackageManagerService. */
    private const val GRANT_THROTTLE_MS = 50L

    /**
     * All permissions declared in our AndroidManifest that we attempt to grant.
     * BYD HAL permissions are custom permissions defined by the BYD system image.
     * pm grant works for normal/dangerous permissions; install-time ones are skipped.
     */
    private val ALL_PERMISSIONS = arrayOf(
        // --- Android standard ---
        "android.permission.CAMERA",
        "android.permission.RECORD_AUDIO",
        "android.permission.WRITE_SECURE_SETTINGS",
        "android.permission.READ_LOGS",
        "android.permission.WRITE_SETTINGS",
        "android.permission.WRITE_EXTERNAL_STORAGE",
        "android.permission.READ_EXTERNAL_STORAGE",
        "android.permission.MANAGE_EXTERNAL_STORAGE",
        "android.permission.ACCESS_FINE_LOCATION",
        "android.permission.ACCESS_COARSE_LOCATION",
        "android.permission.ACCESS_BACKGROUND_LOCATION",
        "android.permission.SYSTEM_ALERT_WINDOW",
        "android.permission.POST_NOTIFICATIONS",
        "android.permission.DEVICE_ACC",
        "android.permission.DEVICE_POWER",
        "android.permission.VIBRATE",

        // --- BYD HAL: core vehicle subsystems ---
        "android.permission.BYDAUTO_AC_COMMON",
        "android.permission.BYDAUTO_AC_GET",
        "android.permission.BYDAUTO_AC_SET",
        "android.permission.BYDAUTO_BODYWORK_COMMON",
        "android.permission.BYDAUTO_BODYWORK_GET",
        "android.permission.BYDAUTO_BODYWORK_SET",
        "android.permission.BYDAUTO_INSTRUMENT_COMMON",
        "android.permission.BYDAUTO_INSTRUMENT_GET",
        "android.permission.BYDAUTO_INSTRUMENT_SET",
        "android.permission.BYDAUTO_ENGINE_COMMON",
        "android.permission.BYDAUTO_ENGINE_GET",
        "android.permission.BYDAUTO_ENGINE_SET",
        "android.permission.BYDAUTO_CHARGING_COMMON",
        "android.permission.BYDAUTO_CHARGING_GET",
        "android.permission.BYDAUTO_CHARGING_SET",
        "android.permission.BYDAUTO_BMS_COMMON",
        "android.permission.BYDAUTO_BMS_GET",
        "android.permission.BYDAUTO_STATISTIC_COMMON",
        "android.permission.BYDAUTO_STATISTIC_GET",
        "android.permission.BYDAUTO_STATISTIC_SET",
        "android.permission.BYDAUTO_SPEED_COMMON",
        "android.permission.BYDAUTO_SPEED_GET",
        "android.permission.BYDAUTO_SPEED_SET",
        "android.permission.BYDAUTO_GEARBOX_COMMON",
        "android.permission.BYDAUTO_GEARBOX_GET",
        "android.permission.BYDAUTO_LIGHT_COMMON",
        "android.permission.BYDAUTO_LIGHT_GET",
        "android.permission.BYDAUTO_LIGHT_SET",
        "android.permission.BYDAUTO_ENERGY_COMMON",
        "android.permission.BYDAUTO_ENERGY_GET",
        "android.permission.BYDAUTO_ENERGY_SET",
        "android.permission.BYDAUTO_TYRE_COMMON",
        "android.permission.BYDAUTO_TYRE_GET",
        "android.permission.BYDAUTO_TYRE_SET",
        "android.permission.BYDAUTO_RADAR_COMMON",
        "android.permission.BYDAUTO_RADAR_GET",
        "android.permission.BYDAUTO_RADAR_SET",
        "android.permission.BYDAUTO_SETTING_COMMON",
        "android.permission.BYDAUTO_SETTING_GET",
        "android.permission.BYDAUTO_SETTING_SET",
        "android.permission.BYDAUTO_DOOR_LOCK_COMMON",
        "android.permission.BYDAUTO_DOOR_LOCK_GET",
        "android.permission.BYDAUTO_DOOR_LOCK_SET",
        "android.permission.BYDAUTO_SAFETY_BELT_COMMON",
        "android.permission.BYDAUTO_SAFETY_BELT_GET",
        "android.permission.BYDAUTO_SAFETY_BELT_SET",
        "android.permission.BYDAUTO_SEAT_COMMON",
        "android.permission.BYDAUTO_SEAT_GET",
        "android.permission.BYDAUTO_SEAT_SET",
        "android.permission.BYDAUTO_SENSOR_GET",
        "android.permission.BYDAUTO_SENSOR_SET",
        "android.permission.BYDAUTO_PM2P5_COMMON",
        "android.permission.BYDAUTO_PM2P5_GET",
        "android.permission.BYDAUTO_PM2P5_SET",
        "android.permission.BYDAUTO_MULTIMEDIA_COMMON",
        "android.permission.BYDAUTO_MULTIMEDIA_GET",
        "android.permission.BYDAUTO_MULTIMEDIA_SET",
        "android.permission.BYDAUTO_AUDIO_COMMON",
        "android.permission.BYDAUTO_AUDIO_GET",
        "android.permission.BYDAUTO_AUDIO_SET",
        "android.permission.BYDAUTO_PANORAMA_COMMON",
        "android.permission.BYDAUTO_PANORAMA_GET",
        "android.permission.BYDAUTO_PANORAMA_SET",
        "android.permission.BYDAUTO_TIME_COMMON",
        "android.permission.BYDAUTO_TIME_GET",
        "android.permission.BYDAUTO_TIME_SET",
        "android.permission.BYDAUTO_OTA_GET",
        "android.permission.BYDAUTO_OTA_SET",
        "android.permission.BYDAUTO_POWER_GET",
        "android.permission.BYDAUTO_POWER_SET",
        "android.permission.BYDAUTO_ADAS_GET",
        "android.permission.BYDAUTO_ADAS_SET",
        "android.permission.BYDAUTO_WIPER_GET",
        "android.permission.BYDAUTO_WIPER_SET",
        "android.permission.BYDAUTO_REAR_VIEW_MIRROR_GET",
        "android.permission.BYDAUTO_REAR_VIEW_MIRROR_SET",
        "android.permission.BYDAUTO_VEHICLE_DATA_GET",
        "android.permission.BYDAUTO_VEHICLE_DATA_SET",
        "android.permission.BYDAUTO_SRS_COMMON",
        "android.permission.BYDAUTO_SRS_GET",
        "android.permission.BYDAUTO_SRS_SET",

        // --- BYD HAL: extended ---
        "android.permission.BYDAUTO_SECURITY_GET",
        "android.permission.BYDAUTO_COLLISION_GET",
        "android.permission.BYDAUTO_COLLISION_SET",
        "android.permission.BYDAUTO_LOCATION_GET",
        "android.permission.BYDAUTO_LOCATION_SET",
        "android.permission.BYDAUTO_VIDEO_GET",
        "android.permission.BYDAUTO_VIDEO_SET",
        "android.permission.BYDAUTO_AUX_GET",
        "android.permission.BYDAUTO_AUX_SET",
        "android.permission.BYDAUTO_BLUETOOTH_GET",
        "android.permission.BYDAUTO_BLUETOOTH_SET",
        "android.permission.BYDAUTO_RADIO_GET",
        "android.permission.BYDAUTO_RADIO_SET",
        "android.permission.BYDAUTO_SPECIAL_GET",
        "android.permission.BYDAUTO_SPECIAL_SET",
        "android.permission.BYDAUTO_REMINDER_GET",
        "android.permission.BYDAUTO_REMINDER_SET",
        "android.permission.BYDAUTO_VERSION_GET",
        "android.permission.BYDAUTO_VERSION_SET",
        "android.permission.BYDAUTO_FUNCNOTICE_GET",
        "android.permission.BYDAUTO_FUNCNOTICE_SET",
        "android.permission.BYDAUTO_PHONE_GET",
        "android.permission.BYDAUTO_PHONE_SET",
        "android.permission.BYDAUTO_MOTOR_GET",
        "android.permission.BYDAUTO_MOTOR_SET",
        "android.permission.BYDAUTO_CPUTEMPRATURE_SET",
        "android.permission.BYDAUTO_QCFS_GET",
        "android.permission.BYDAUTO_QCFS_SET",
        "android.permission.BYDAUTO_SIGNAL_SET",
        "android.permission.BYDAUTO_RESCUE_GET",
        "android.permission.BYDAUTO_RESCUE_SET",
        "android.permission.BYDAUTO_TEST_GET",
        "android.permission.BYDAUTO_TEST_SET",
        "android.permission.BYDAUTO_DTC_GET",
        "android.permission.BYDAUTO_DTC_SET",
        "android.permission.BYDAUTO_BIGDATA_GET",
        "android.permission.BYDAUTO_YUN_GET",
        "android.permission.BYDAUTO_GB_GET",
        "android.permission.BYDAUTO_RSE_GET",
        "android.permission.BYDAUTO_RSE_SET",
        "android.permission.BYDAUTO_MQTT_GET",
        "android.permission.BYDAUTO_MQTT_SET",

        // --- BYD non-HAL ---
        "android.permission.BYD_CAMERA",
        "android.permission.BYDACQUISITION_SEND_BUFFER",
        "android.permission.BYDACQUISITION_SEND_FILE",
        "android.permission.BYDDIAGNOSTIC_SEND_BUFFER",
    )

    /**
     * Grant all manifest permissions via shell.
     * Runs on a background thread to avoid blocking daemon startup.
     * Safe to call multiple times — only runs once.
     *
     * SOTA: Throttled to avoid flooding PackageManagerService with concurrent
     * binder calls. Each `pm grant` spawns a shell process that calls into PMS.
     * Without throttling, 141 concurrent shell processes overwhelm the system
     * server, causing binder timeouts that break createPackageContext() and
     * other PMS-dependent operations running in parallel.
     *
     * pm grant requires UID 0 (root) or UID 2000 (shell). Our daemons run
     * as UID 2000 so this works. Permissions that are install-time only
     * (signature/privileged) will fail silently and get skipped.
     *
     * @param packageName the app package name
     */
    @JvmStatic
    fun grantAllPermissions(packageName: String) {
        if (hasRun) return
        hasRun = true

        val thread = Thread({
            log(
                "Granting permissions for " + packageName +
                    " (UID " + Process.myUid() + ", " + ALL_PERMISSIONS.size + " total)"
            )
            val start = System.currentTimeMillis()
            var granted = 0
            var failed = 0
            var skipped = 0
            val failures = ArrayList<String>()

            for (permission in ALL_PERMISSIONS) {
                // Check if daemon is shutting down — stop spawning new processes
                if (Thread.currentThread().isInterrupted) {
                    log("Interrupted — aborting remaining grants")
                    break
                }

                try {
                    when (execGrant(packageName, permission)) {
                        0 -> granted++
                        -2 -> skipped++
                        else -> {
                            failed++
                            failures.add(shortName(permission))
                        }
                    }
                } catch (e: Exception) {
                    failed++
                    failures.add(shortName(permission))
                }

                // Throttle: yield between grants to avoid flooding PMS.
                // 50ms × 141 permissions = ~7s total, vs the unthrottled 199s
                // observed in logs when PMS was overloaded from rapid restarts.
                try {
                    Thread.sleep(GRANT_THROTTLE_MS)
                } catch (e: InterruptedException) {
                    log("Interrupted during throttle — aborting remaining grants")
                    break
                }
            }

            val elapsed = System.currentTimeMillis() - start
            val failureSummary = if (failed == 0) "none denied" else "$failed denied"
            log(
                "Done in " + elapsed + "ms: " + granted + " granted, " +
                    skipped + " skipped, " + failureSummary
            )
            if (failures.isNotEmpty() && failures.size <= 15) {
                log("Failed: " + failures.joinToString(", "))
            } else if (failures.isNotEmpty()) {
                log("Failed: " + failures.size + " permissions")
            }
        }, "PermissionGranter")
        grantThread = thread
        thread.isDaemon = true
        thread.start()
    }

    /**
     * Stop the permission granter thread if it's still running.
     * Called from the shutdown hook to prevent orphaned pm grant processes
     * from continuing to hammer PMS after the daemon exits.
     */
    @JvmStatic
    fun cancel() {
        val thread = grantThread
        if (thread != null && thread.isAlive) {
            thread.interrupt()
            log("Cancelled — no more pm grant processes will be spawned")
        }
    }

    /**
     * Execute a single pm grant command.
     * @return 0 = success, -1 = failed, -2 = not grantable (skip)
     */
    private fun execGrant(packageName: String, permission: String): Int {
        return try {
            val process = Runtime.getRuntime().exec(
                arrayOf("sh", "-c", "pm grant $packageName $permission 2>&1")
            )

            val output = StringBuilder()
            BufferedReader(InputStreamReader(process.inputStream)).use { reader ->
                var line = reader.readLine()
                while (line != null) {
                    output.append(line)
                    line = reader.readLine()
                }
            }

            val exitCode = process.waitFor()
            val out = output.toString().trim()

            when {
                exitCode == 0 -> 0
                // These are expected — permission is install-time only, doesn't exist, etc.
                out.contains("not a changeable permission") ||
                    out.contains("Unknown permission") ||
                    out.contains("has not requested permission") ||
                    out.contains("is not a") -> -2
                else -> -1
            }
        } catch (e: Exception) {
            log("execGrant failed for " + permission + ": " + e.message)
            -1
        }
    }

    /** Strip the android.permission. prefix for shorter log output */
    private fun shortName(permission: String): String =
        permission.removePrefix("android.permission.")

    /**
     * Generate ADB commands for manually granting all permissions.
     * Useful for debugging when shell granting fails.
     */
    @JvmStatic
    fun getAdbCommands(packageName: String): String {
        val sb = StringBuilder()
        sb.append("# Grant all permissions for ").append(packageName).append(":\n")
        for (perm in ALL_PERMISSIONS) {
            sb.append("adb shell pm grant ").append(packageName).append(" ")
                .append(perm).append("\n")
        }
        sb.append("\n# Verify:\n")
        sb.append("adb shell dumpsys package ").append(packageName)
            .append(" | grep granted=true\n")
        return sb.toString()
    }

    private fun log(msg: String) {
        println("$TAG: $msg")
    }
}
