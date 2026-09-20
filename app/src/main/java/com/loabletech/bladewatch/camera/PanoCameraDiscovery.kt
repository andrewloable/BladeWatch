package net.bladewatch.app.camera

import net.bladewatch.app.logging.DaemonLogger
import org.json.JSONObject

/**
 * Structured result of panoramic BYD camera discovery.
 *
 * Deliberately richer than the legacy integer-only API so field debugging can tell which BMM tag
 * and layout actually selected the tuple.
 */
class PanoCameraDiscovery(
    @JvmField val cameraId: Int,
    @JvmField val surfaceMode: Int,
    @JvmField val cameraLayout: Int,
    sourceTag: String?,
    method: String?,
    vehicleCamSort: String?
) {

    @JvmField val sourceTag: String = sourceTag ?: ""

    @JvmField val method: String = method ?: ""

    @JvmField val vehicleCamSort: String = vehicleCamSort ?: ""

    fun toJson(): JSONObject {
        val json = JSONObject()
        try {
            // Persist the same field names used by the camera config/status payloads so a single
            // discovery object can be written through without extra translation.
            json.put("probedCameraId", cameraId)
            json.put("probedSurfaceMode", surfaceMode)
            json.put("cameraLayout", cameraLayout)
            json.put("sourceBmmTag", sourceTag)
            json.put("discoveryMethod", method)
            json.put("vehicleCamSort", vehicleCamSort)
        } catch (ignored: Exception) {
            logger.warn("Failed to build discovery JSON: " + ignored.message)
        }
        return json
    }

    override fun toString(): String =
        "PanoCameraDiscovery{id=" + cameraId +
            ", surfaceMode=" + surfaceMode +
            ", layout=" + cameraLayout +
            ", sourceTag='" + sourceTag + '\'' +
            ", method='" + method + '\'' +
            ", vehicleCamSort='" + vehicleCamSort + '\'' + '}'

    private companion object {
        val logger: DaemonLogger = DaemonLogger.getInstance("PanoCameraDiscovery")
    }
}
