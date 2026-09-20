package net.bladewatch.app.camera

import android.os.Build
import net.bladewatch.app.logging.DaemonLogger
import org.json.JSONObject

/**
 * Snapshot of the current build/vehicle identity, used to decide whether a previously validated
 * BYD camera tuple is still trustworthy.
 */
class CameraFirmwareInfo(
    fingerprint: String?,
    buildDisplay: String?,
    buildIncremental: String?,
    roBuildIncremental: String?,
    device: String?,
    vehicleCamSort: String?
) {

    @JvmField val fingerprint: String = normalize(fingerprint)

    @JvmField val buildDisplay: String = normalize(buildDisplay)

    @JvmField val buildIncremental: String = normalize(buildIncremental)

    @JvmField val roBuildIncremental: String = normalize(roBuildIncremental)

    @JvmField val device: String = normalize(device)

    @JvmField val vehicleCamSort: String = normalize(vehicleCamSort)

    fun toJson(): JSONObject {
        val json = JSONObject()
        try {
            json.put("firmwareFingerprint", fingerprint)
            json.put("buildDisplay", buildDisplay)
            json.put("buildIncremental", buildIncremental)
            json.put("roBuildIncremental", roBuildIncremental)
            json.put("productDevice", device)
            json.put("vehicleCamSort", vehicleCamSort)
        } catch (ignored: Exception) {
            logger.warn("Failed to build firmware info JSON: " + ignored.message)
        }
        return json
    }

    fun matches(cameraConfig: JSONObject?): Boolean {
        if (cameraConfig == null) return false
        // Treat the tuple as the unit of trust: every firmware signal must match before a saved
        // BYD camera selection is considered current.
        return eq(cameraConfig.optString("firmwareFingerprint", ""), fingerprint) &&
            eq(cameraConfig.optString("buildDisplay", ""), buildDisplay) &&
            eq(cameraConfig.optString("buildIncremental", ""), buildIncremental) &&
            eq(cameraConfig.optString("roBuildIncremental", ""), roBuildIncremental) &&
            eq(cameraConfig.optString("productDevice", ""), device) &&
            eq(cameraConfig.optString("vehicleCamSort", ""), vehicleCamSort)
    }

    fun hasAnySignal(): Boolean =
        fingerprint.isNotEmpty() ||
            buildDisplay.isNotEmpty() ||
            buildIncremental.isNotEmpty() ||
            roBuildIncremental.isNotEmpty() ||
            device.isNotEmpty() ||
            vehicleCamSort.isNotEmpty()

    companion object {
        private val logger: DaemonLogger = DaemonLogger.getInstance("CameraFirmwareInfo")

        @JvmStatic
        fun current(): CameraFirmwareInfo {
            // A snapshot of the current runtime build identity. Read-only metadata used to judge
            // tuple trust, not a config writer.
            return CameraFirmwareInfo(
                Build.FINGERPRINT,
                Build.DISPLAY,
                Build.VERSION.INCREMENTAL,
                readSystemProperty("ro.build.version.incremental"),
                Build.DEVICE,
                readSystemProperty("vehicle.config.cam_sort")
            )
        }

        @JvmStatic
        fun readSystemProperty(key: String): String {
            // Best-effort reflection only. These properties are useful for camera tuple trust
            // decisions, but the app must still work if the hidden SystemProperties API is
            // unavailable on a given build.
            return try {
                val sp = Class.forName("android.os.SystemProperties")
                val get = sp.getMethod("get", String::class.java)
                get.invoke(null, key)?.toString() ?: ""
            } catch (ignored: Throwable) {
                logger.warn(
                    "Failed to read system property " + key + ": " + ignored.message
                )
                ""
            }
        }

        private fun normalize(value: String?): String = value?.trim() ?: ""

        private fun eq(a: String?, b: String?): Boolean = normalize(a) == normalize(b)
    }
}
