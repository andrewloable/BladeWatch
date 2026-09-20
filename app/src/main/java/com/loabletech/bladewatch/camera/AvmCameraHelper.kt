package net.bladewatch.app.camera

import android.media.MediaCodec
import net.bladewatch.app.logging.DaemonLogger

/**
 * Utility methods for AVMCamera capabilities that aren't used elsewhere in the codebase.
 *
 * The camera lifecycle (open/close/startPreview/addPreviewSurface) is already handled inline in
 * PanoramicCameraGpu and BydCameraCoordinator via reflection. This object only adds genuinely new
 * capabilities: BmmCameraInfo discovery (instant camera tuple lookup) and setCameraFps (frame rate
 * control).
 */
object AvmCameraHelper {

    private val logger: DaemonLogger = DaemonLogger.getInstance("AvmCameraHelper")

    private const val BMM_CAMERA_INFO_CLASS = "android.hardware.BmmCameraInfo"

    /**
     * Panoramic camera tags to try, in priority order.
     *
     * Matches the cascade in BmmCameraInfo.processCamProperty:242-260 verbatim: pano_h → pano_l →
     * byd_apa → apa. The jar's cascade is if/else-if, so only one of these is ever populated per
     * device — the order here only matters if a future jar build relaxes the cascade.
     */
    private val PANO_TAGS = arrayOf("pano_h", "pano_l", "byd_apa", "apa")

    // ── Camera Discovery (REQ-1) ────────────────────────────────────────

    /**
     * Discover the panoramic camera tuple via BmmCameraInfo.getCameraId() reflection.
     * BmmCameraInfo reads the system property vehicle.config.cam_sort, which maps camera tags to
     * IDs. Tries pano_h → pano_l → byd_apa → apa.
     *
     * @return the tuple, or null if no panoramic camera is available
     */
    @JvmStatic
    fun discoverPanoCamera(): PanoCameraDiscovery? {
        return try {
            val bmmClass = Class.forName(BMM_CAMERA_INFO_CLASS)

            // Dump the raw system property for debugging
            try {
                val camSort = CameraFirmwareInfo.readSystemProperty("vehicle.config.cam_sort")
                logger.info(
                    "vehicle.config.cam_sort = " +
                        (if (camSort.isNotEmpty()) "'$camSort'" else "(empty/null)")
                )
            } catch (e: Exception) {
                logger.warn("Could not read vehicle.config.cam_sort: " + e.message)
            }

            // Enumerate all known tags and their resolved IDs
            val getCameraId = bmmClass.getDeclaredMethod("getCameraId", String::class.java)
            getCameraId.isAccessible = true

            val allTags = arrayOf(
                "front", "rear", "rvs", "rf", "dms", "face",
                "pano_h", "pano_l", "apa", "byd_apa",
                "d954_h_m", "d954_h_s", "d954_l_m", "d954_l_s"
            )
            val sb = StringBuilder("BmmCameraInfo IDs:")
            for (tag in allTags) {
                try {
                    val id = getCameraId.invoke(null, tag) as Int
                    if (id >= 0) sb.append(" ").append(tag).append("=").append(id)
                } catch (ignored: Exception) {
                    logger.warn(
                        "Failed to get camera ID for tag " + tag + ": " + ignored.message
                    )
                }
            }
            logger.info(sb.toString())

            // Try the panoramic tags in priority order
            for (tag in PANO_TAGS) {
                val result = getCameraId.invoke(null, tag)
                if (result is Int && result >= 0) {
                    logger.info("Discovered panoramic camera: $tag → ID $result")
                    // APA-family tags are intentionally flagged as a different layout class so
                    // downstream rendering and diagnostics can distinguish them from the standard
                    // pano strip.
                    val layout = if ("byd_apa" == tag || "apa" == tag) 1 else 0
                    val camSort = CameraFirmwareInfo.readSystemProperty("vehicle.config.cam_sort")
                    return PanoCameraDiscovery(result, 0, layout, tag, "bmm:$tag", camSort)
                }
            }
            logger.info("BmmCameraInfo: no panoramic camera found for any tag")
            null
        } catch (e: ClassNotFoundException) {
            logger.warn("BmmCameraInfo class not available on this device")
            null
        } catch (e: Exception) {
            logger.warn("BmmCameraInfo discovery failed: " + e.message)
            null
        }
    }

    /** Compatibility wrapper that returns only the camera ID. */
    @JvmStatic
    fun discoverPanoCameraId(): Int = discoverPanoCamera()?.cameraId ?: -1

    // ── Frame Rate Control (REQ-2) ──────────────────────────────────────

    /**
     * Set the camera frame rate via AVMCamera.setCameraFps(int). Must be called after open() and
     * before startPreview().
     *
     * @param cameraObj the AVMCamera instance (from the reflection open() call)
     * @param fps desired frames per second
     * @return true if set successfully
     */
    @JvmStatic
    fun setCameraFps(cameraObj: Any?, fps: Int): Boolean {
        if (cameraObj == null) return false
        return try {
            val m = cameraObj.javaClass.getDeclaredMethod("setCameraFps", Int::class.javaPrimitiveType)
            m.isAccessible = true
            val ok = m.invoke(cameraObj, fps) == true
            if (ok) {
                logger.info("Camera FPS set to $fps")
            } else {
                // Some BYD camera HAL builds reject explicit FPS control but continue streaming
                // normally at their default rate. Treat that as capability info, not a warning.
                logger.info("setCameraFps($fps) unsupported by HAL")
            }
            ok
        } catch (e: NoSuchMethodException) {
            logger.info("setCameraFps not available on this AVMCamera version")
            false
        } catch (e: Exception) {
            logger.warn("setCameraFps failed: " + e.message)
            false
        }
    }

    /**
     * Bind a MediaCodec encoder's frame rate to the BYD camera HAL via
     * AVMCamera.setMediaCodecFps(MediaCodec, int). This is a separate JNI path from
     * [setCameraFps] — when the HAL refuses setCameraFps, this one may still succeed, because it
     * ties the encoder's KEY_FRAME_RATE to the camera emission rate without going through the
     * sensor-rate validation.
     *
     * Pass the encoder MediaCodec instance, not its surface.
     */
    @JvmStatic
    fun setMediaCodecFps(cameraObj: Any?, codec: MediaCodec?, fps: Int): Boolean {
        if (cameraObj == null || codec == null) return false
        return try {
            val m = cameraObj.javaClass.getDeclaredMethod(
                "setMediaCodecFps", MediaCodec::class.java, Int::class.javaPrimitiveType
            )
            m.isAccessible = true
            val ok = m.invoke(cameraObj, codec, fps) == true
            if (ok) {
                logger.info("MediaCodec FPS bound to $fps")
            } else {
                logger.warn("setMediaCodecFps($fps) returned false")
            }
            ok
        } catch (e: NoSuchMethodException) {
            logger.warn("setMediaCodecFps not available on this AVMCamera version")
            false
        } catch (e: Exception) {
            logger.warn("setMediaCodecFps failed: " + e.message)
            false
        }
    }
}
