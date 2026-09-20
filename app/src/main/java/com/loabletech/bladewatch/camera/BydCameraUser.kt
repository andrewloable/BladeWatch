package net.bladewatch.app.camera

import android.hardware.IBYDCameraUser
import net.bladewatch.app.logging.DaemonLogger

/**
 * IBYDCameraUser implementation for cooperative camera sharing with BYD native apps.
 *
 * DESIGN: don't proactively yield on onPreOpenCamera. The BYD camera HAL supports multiple preview
 * surfaces via addPreviewSurface, so both apps CAN share the camera. We only yield if the native
 * app actually can't get frames (detected via a frame stall plus the onOpenCamera notification).
 *
 * Registration with IBYDCameraService serves two purposes: the service knows we exist, so it can
 * coordinate camera access properly; and we get onCloseCamera callbacks, giving an instant
 * reacquire when the native app exits (which replaces blind delays and polling).
 *
 * A yield only happens when onOpenCamera fires AND our frames stall (the HAL can't serve both
 * surfaces), i.e. when the existing frame-stall watchdog detects contention. This maximises
 * recording uptime — no unnecessary gaps.
 */
class BydCameraUser(
    private val cameraId: Int,
    private val packageName: String
) : IBYDCameraUser.Stub() {

    @Volatile
    private var yielded = false

    @Volatile
    private var nativeAppHoldsCamera = false

    @Volatile
    private var listener: CameraYieldListener? = null

    /** Callback interface for camera yield/reacquire events. */
    interface CameraYieldListener {
        /** Called when we must yield the camera (frame stall + native app active). */
        fun onYieldRequired()

        /** Called when the native app released the camera. Safe to reopen if yielded. */
        fun onCameraAvailable()

        /** Called when the native app opens the camera (informational — don't yield yet). */
        fun onNativeAppOpened(packageName: String)
    }

    fun setListener(listener: CameraYieldListener?) {
        this.listener = listener
    }

    /** Whether the requester is a different app requesting our camera. */
    private fun isOtherAppOnMyCamera(requester: IBYDCameraUser, camId: Int): Boolean {
        if (camId != cameraId) return false
        return try {
            val requesterPkg = requester.packageName
            requesterPkg != null && packageName != requesterPkg
        } catch (e: Exception) {
            logger.warn("Failed to check if other app on camera: " + e.message)
            true
        }
    }

    private fun requesterPackageOf(requester: IBYDCameraUser, context: String): String = try {
        requester.packageName ?: "unknown"
    } catch (ignored: Exception) {
        logger.warn("Failed to get requester package name $context: " + ignored.message)
        "unknown"
    }

    // ==================== IBYDCameraUser callbacks ====================

    /**
     * Called BEFORE another app opens the camera.
     *
     * We return true (allow) but do NOT yield. The HAL supports multiple preview surfaces — both
     * apps can share. We only yield later if frames actually stall, which keeps our recording
     * running without unnecessary gaps.
     */
    override fun onPreOpenCamera(requester: IBYDCameraUser, camId: Int): Boolean {
        if (isOtherAppOnMyCamera(requester, camId)) {
            logger.info(
                "onPreOpenCamera: allowing " + requesterPackageOf(requester, "") +
                    " to open camera " + camId + " (NOT yielding — sharing via addPreviewSurface)"
            )
            nativeAppHoldsCamera = true
        }
        return true // Always allow — don't block the native app
    }

    /**
     * Called AFTER another app has opened the camera.
     *
     * The native app now has the camera. We note this but don't yield yet: if the HAL can serve
     * both surfaces our recording continues uninterrupted, and if it can't, the frame-stall
     * watchdog will detect it and trigger the yield.
     */
    override fun onOpenCamera(requester: IBYDCameraUser, camId: Int): Boolean {
        if (isOtherAppOnMyCamera(requester, camId)) {
            val requesterPkg = requesterPackageOf(requester, "on open")
            logger.info(
                "onOpenCamera: " + requesterPkg + " opened camera " + camId +
                    " — monitoring for frame stalls (NOT yielding proactively)"
            )
            nativeAppHoldsCamera = true
            listener?.onNativeAppOpened(requesterPkg)
        }
        return false
    }

    /**
     * Called when another app closes the camera.
     *
     * If we had yielded (due to a frame stall), this is our signal to reopen. If we never yielded
     * (sharing worked), it is just informational.
     */
    override fun onCloseCamera(requester: IBYDCameraUser, camId: Int): Boolean {
        if (isOtherAppOnMyCamera(requester, camId)) {
            logger.info(
                "onCloseCamera: " + requesterPackageOf(requester, "on close") +
                    " released camera " + camId
            )
            nativeAppHoldsCamera = false

            if (yielded) {
                logger.info("Was yielded — triggering camera reacquire")
                yielded = false
                listener?.onCameraAvailable()
            } else {
                logger.info(
                    "Was NOT yielded — sharing worked, recording continued uninterrupted"
                )
            }
        }
        return false
    }

    override fun onError(error: String, code: Int): Boolean {
        logger.warn("onError: $error code=$code")
        return false
    }

    override fun getCameraId(): Int = cameraId

    override fun getPackageName(): String = packageName

    override fun getProperty(key: String): String? = when (key) {
        "native" -> "true"
        "camera_type" -> "android"
        else -> null
    }

    // ==================== Yield control ====================

    /**
     * Called by the frame-stall watchdog when frames stop AND the native app holds the camera.
     * This is the ONLY path that triggers a yield — not onPreOpenCamera.
     */
    fun yieldDueToContention() {
        if (!yielded && nativeAppHoldsCamera) {
            yielded = true
            logger.info("Yielding due to contention (frame stall + native app active)")
            listener?.onYieldRequired()
        }
    }

    fun isYielded(): Boolean = yielded

    fun isNativeAppHoldingCamera(): Boolean = nativeAppHoldsCamera

    /** Manually clear the yielded flag (e.g. on unregister or shutdown). */
    fun clearYielded() {
        yielded = false
        nativeAppHoldsCamera = false
    }

    private companion object {
        val logger: DaemonLogger = DaemonLogger.getInstance("BydCameraUser")
    }
}
