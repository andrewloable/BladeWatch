package net.bladewatch.app.camera

import android.hardware.IBYDCameraService
import android.hardware.IBYDCameraUser
import android.os.IBinder

import net.bladewatch.app.logging.DaemonLogger

import java.lang.reflect.Method
import java.lang.reflect.Proxy

/**
 * Cooperative camera coordinator for BYD platform.
 *
 * NOTE: registerCameraUser() / IBYDCameraUser callback registration is permanently
 * DISABLED — the daemon does not participate in IBYDCameraService arbitration.
 * The only live path is polling-based: getCurrentCameraUser() + frame-stall detection.
 * All registerUser-gated branches in this file are dead and kept commented for
 * reference only; do not re-enable without re-validating the yield/reacquire flow.
 *
 * Cleanup order (always): disablePreviewCallback → stopPreview → close
 */
class BydCameraCoordinator {

    // IBYDCameraService — typed proxy (preferred) or reflection proxy (fallback)
    private var typedServiceProxy: IBYDCameraService? = null

    /** Fallback if typed stub doesn't match runtime */
    private var reflectionServiceProxy: Any? = null

    /** For polling fallback */
    private var getCurrentCameraUserMethod: Method? = null

    private var serviceAvailable = false

    // Camera user registration — DISABLED. registerCameraUser() is no longer
    // invoked, so these fields stay at their initial values for the lifetime
    // of the process: cameraUser == null, registeredAsUser == false.
    // Kept (non-final) so the commented-out registration code still compiles.
    private var cameraUser: BydCameraUser? = null
    private var registeredAsUser = false

    /** Event callback state (AVMCamera.IEventCallback — separate from IBYDCameraUser) */
    private var eventCallbackSet = false

    // Native app activity tracking (for polling fallback)
    @Volatile
    private var nativeAppActive = false

    @Volatile
    private var lastCameraOwnerPackage = ""

    @Volatile
    private var arbitrationMode = "eventCallbackOnly"

    // Yield state
    @Volatile
    private var yielded = false

    @Volatile
    private var yieldTimestamp = 0L

    /** Callback to PanoramicCameraGpu */
    interface CameraYieldCallback {
        fun onYieldCamera()
        fun onReacquireCamera()
        fun onCameraError(eventType: Int)
    }

    private var yieldCallback: CameraYieldCallback? = null

    @Volatile
    private var activeCameraId = 1

    fun setYieldCallback(callback: CameraYieldCallback?) {
        yieldCallback = callback
    }

    fun setActiveCameraId(cameraId: Int) {
        activeCameraId = cameraId
    }

    fun setArbitrationMode(mode: String?) {
        arbitrationMode = if (mode.isNullOrEmpty()) "eventCallbackOnly" else mode
    }

    // ==================== IBYDCameraService Connection ====================

    /**
     * Connects to IBYDCameraService and registers as a camera user.
     *
     * Tries typed AIDL stubs first (for registerUser). If that fails,
     * falls back to reflection-based polling (getCurrentCameraUser).
     */
    fun register() {
        try {
            val serviceManagerClass = Class.forName("android.os.ServiceManager")
            val getService =
                serviceManagerClass.getDeclaredMethod("getService", String::class.java)
            getService.isAccessible = true
            val binder = getService.invoke(null, "bydcameramanager")

            if (binder == null) {
                logger.warn("IBYDCameraService not available (binder is null)")
                return
            }

            serviceAvailable = true

            // Try BYD-custom zero-arg asInterface() first.
            // The real implementation in bmmcamera.jar gets the binder from
            // ServiceManager internally.
            try {
                typedServiceProxy = IBYDCameraService.Stub.asInterface()
                if (typedServiceProxy != null) {
                    logger.info("IBYDCameraService connected via zero-arg asInterface")
                } else {
                    logger.info("Zero-arg asInterface returned null — trying IBinder overload")
                }
            } catch (e: Throwable) {
                logger.warn("Zero-arg asInterface failed: " + e.message)
                typedServiceProxy = null
            }

            // Fallback: standard asInterface(IBinder) if zero-arg didn't work
            if (typedServiceProxy == null) {
                try {
                    typedServiceProxy = IBYDCameraService.Stub.asInterface(binder as IBinder)
                    if (typedServiceProxy != null) {
                        logger.info("IBYDCameraService connected via asInterface(IBinder)")
                    }
                } catch (e: Throwable) {
                    logger.warn("asInterface(IBinder) failed: " + e.message)
                    typedServiceProxy = null
                }
            }

            // Also set up reflection proxy as fallback for polling
            try {
                val stubClass = Class.forName("android.hardware.IBYDCameraService\$Stub")
                val asInterface = stubClass.getDeclaredMethod(
                    "asInterface", Class.forName("android.os.IBinder")
                )
                asInterface.isAccessible = true
                val proxy = asInterface.invoke(null, binder)
                reflectionServiceProxy = proxy

                if (proxy != null) {
                    try {
                        val m = proxy.javaClass.getDeclaredMethod("getCurrentCameraUser")
                        m.isAccessible = true
                        getCurrentCameraUserMethod = m
                    } catch (e: NoSuchMethodException) {
                        logger.warn("getCurrentCameraUser not found on service")
                    }
                }
            } catch (e: Exception) {
                logger.warn("Reflection proxy setup failed: " + e.message)
            }

            // API discovery and camera user registration DISABLED.
            // We don't participate in IBYDCameraService arbitration.
            // discoverCameraServiceApi();
            // registerCameraUser();
            // Explicit experiment gate: only this mode is allowed to touch the
            // registerUser path. The default modes remain polling/event-callback only.
            if ("registeredUserExperiment" == arbitrationMode) {
                registerCameraUser()
            }
        } catch (e: ClassNotFoundException) {
            logger.info("IBYDCameraService not found — camera arbitration unavailable")
        } catch (e: Exception) {
            logger.warn("IBYDCameraService setup failed: " + e.message)
        }
    }

    // ==================== Camera User Registration ====================

    /**
     * Registers with IBYDCameraService as a camera user.
     *
     * DEAD CODE — DISABLED. Not invoked from [register] (call sites are
     * commented out). Kept for reference in case event-driven yield is revived.
     * If you uncomment the call site, also remove the `false` return in
     * [isRegisteredAsUser] and revert the polling-only short-circuits.
     */
    private fun registerCameraUser() {
        if (registeredAsUser) {
            logger.info("Already registered as camera user")
            return
        }

        // Create our camera user implementation
        val user = BydCameraUser(activeCameraId, "net.bladewatch.app")
        cameraUser = user
        user.setListener(object : BydCameraUser.CameraYieldListener {
            override fun onYieldRequired() {
                // Only called from yieldDueToContention() — frame stall + native app active
                logger.info(
                    "IBYDCameraUser: yield required (frame stall contention) — notifying pipeline"
                )
                yielded = true
                nativeAppActive = true
                yieldTimestamp = System.currentTimeMillis()
                yieldCallback?.onYieldCamera()
            }

            override fun onCameraAvailable() {
                // Native app closed camera — reacquire if we had yielded
                logger.info("IBYDCameraUser: camera available — notifying pipeline")
                yielded = false
                nativeAppActive = false
                logger.info(
                    "Camera was yielded for " +
                        (System.currentTimeMillis() - yieldTimestamp) + "ms"
                )

                scheduleReacquire()
            }

            override fun onNativeAppOpened(packageName: String) {
                // Informational — native app opened camera but we're NOT yielding.
                // If sharing works (both get frames), recording continues uninterrupted.
                // If sharing fails, frame stall watchdog will detect it and call
                // onFrameStallDetected() → yieldDueToContention().
                logger.info(
                    "Native app opened camera: " + packageName +
                        " — monitoring for frame stalls (recording continues)"
                )
                nativeAppActive = true
            }
        })

        // Try registerUser via typed proxy
        val typed = typedServiceProxy
        if (typed != null) {
            try {
                val result = typed.registerUser(user)
                registeredAsUser = true
                logger.info(
                    "Registered as camera user via typed AIDL (camera " +
                        activeCameraId + ", result=" + result + ") — event-driven yield active"
                )
                return
            } catch (e: Throwable) {
                // Catches both Exception and Error (NoSuchMethodError when runtime
                // IBYDCameraService doesn't match our compile-time stub)
                logger.warn("registerUser via typed proxy failed: " + e.message)
                typedServiceProxy = null // Don't try typed proxy again
            }
        }

        val proxy = reflectionServiceProxy
        if (proxy != null) {
            // Try registerUser via reflection
            try {
                val registerMethod = proxy.javaClass.getDeclaredMethod(
                    "registerUser", IBYDCameraUser::class.java
                )
                registerMethod.isAccessible = true
                registerMethod.invoke(proxy, user)
                registeredAsUser = true
                logger.info(
                    "Registered as camera user via reflection (camera " +
                        activeCameraId + ") — event-driven yield active"
                )
                return
            } catch (e: NoSuchMethodException) {
                logger.warn("registerUser(IBYDCameraUser) not found on service")
            } catch (e: Throwable) {
                logger.warn("registerUser via reflection failed: " + e.message)
            }

            // Try with android.os.IBinder parameter type (some firmware versions)
            try {
                val registerMethod =
                    proxy.javaClass.getDeclaredMethod("registerUser", IBinder::class.java)
                registerMethod.isAccessible = true
                registerMethod.invoke(proxy, user.asBinder())
                registeredAsUser = true
                logger.info(
                    "Registered as camera user via IBinder overload (camera " +
                        activeCameraId + ") — event-driven yield active"
                )
                return
            } catch (e: NoSuchMethodException) {
                logger.warn("registerUser IBinder overload not found: " + e.message)
            } catch (e: Throwable) {
                logger.warn("registerUser IBinder overload failed: " + e.message)
            }
        }

        logger.warn("Camera user registration failed — using polling fallback")
    }

    /**
     * Unregisters from IBYDCameraService.
     *
     * DEAD CODE — DISABLED, paired with [registerCameraUser].
     */
    private fun unregisterCameraUser() {
        val user = cameraUser
        if (!registeredAsUser || user == null) return

        var unregistered = false
        val typed = typedServiceProxy
        val proxy = reflectionServiceProxy
        if (typed != null) {
            try {
                typed.unregisterUser(user)
                unregistered = true
                logger.info("Unregistered camera user via typed AIDL")
            } catch (e: Exception) {
                logger.warn(
                    "unregisterUser failed (service may still hold reference): " + e.message
                )
            }
        } else if (proxy != null) {
            try {
                val unregisterMethod = proxy.javaClass.getDeclaredMethod(
                    "unregisterUser", IBYDCameraUser::class.java
                )
                unregisterMethod.isAccessible = true
                unregisterMethod.invoke(proxy, user)
                unregistered = true
                logger.info("Unregistered camera user via reflection")
            } catch (e: Exception) {
                logger.warn("unregisterUser via reflection failed: " + e.message)
            }
        }

        if (!unregistered) {
            logger.warn(
                "Could not confirm unregister — clearing local state to allow re-registration"
            )
        }
        registeredAsUser = false
        user.clearYielded()
    }

    // ==================== Yield State Query ====================

    /**
     * Checks if the camera is currently yielded due to contention.
     * Returns false if native app opened but sharing is working (no frame stall).
     */
    fun isCameraYielded(): Boolean {
        // registerCameraUser is DISABLED — only the polling path is live.
        // if (registeredAsUser && cameraUser != null) {
        //     return cameraUser.isYielded();
        // }
        return yielded
    }

    // ==================== Polling Fallback ====================

    /**
     * Queries the current camera user's package name.
     * Returns the package name of the app currently holding the camera,
     * or null if no other app has it (or if we are the holder).
     *
     * Used at camera open time to decide PRIMARY vs SECONDARY mode.
     */
    fun queryCurrentCameraUser(): String? {
        // registerCameraUser DISABLED — polling path only.
        // if (registeredAsUser && cameraUser != null) {
        //     return cameraUser.isNativeAppHoldingCamera() ? "native" : null;
        // }
        val m = getCurrentCameraUserMethod
        val proxy = reflectionServiceProxy
        if (m != null && proxy != null) {
            try {
                val pkg = currentUserPackage(m, proxy)
                lastCameraOwnerPackage = pkg ?: ""
                if (pkg != null && "net.bladewatch.app" != pkg) return pkg
            } catch (e: Exception) {
                logger.warn("Failed to query current camera user: " + e.message)
            }
        }
        lastCameraOwnerPackage = ""
        return null
    }

    /**
     * The package name reported by the service's current camera user, or null when no
     * user is held. Both polling entry points read it exactly this way.
     */
    private fun currentUserPackage(m: Method, proxy: Any): String? {
        val currentUser = m.invoke(proxy) ?: return null
        return currentUser.javaClass.getMethod("getPackageName").invoke(currentUser) as String?
    }

    /**
     * Checks if another app currently holds the camera via getCurrentCameraUser() polling.
     * Only used when registerUser is not available.
     *
     * @return true if another camera user is active (native AVM app)
     */
    fun checkNativeAppActive(): Boolean {
        val m = getCurrentCameraUserMethod
        val proxy = reflectionServiceProxy
        if (!serviceAvailable || m == null || proxy == null) {
            return false
        }

        // registerCameraUser DISABLED — callbacks never fire, so always poll.
        // if (registeredAsUser) {
        //     return nativeAppActive;
        // }

        try {
            val currentUser = m.invoke(proxy)
            if (currentUser != null) {
                var pkg: String? = null
                try {
                    pkg = currentUser.javaClass.getMethod("getPackageName")
                        .invoke(currentUser) as String?
                } catch (ignored: Exception) {
                    logger.warn(
                        "Failed to get package name from camera user: " + ignored.message
                    )
                }

                val isUs = "net.bladewatch.app" == pkg
                val wasActive = nativeAppActive
                lastCameraOwnerPackage = pkg ?: ""
                nativeAppActive = !isUs && pkg != null

                if (nativeAppActive && !wasActive) {
                    logger.info("Native app detected via polling: $pkg")
                } else if (!nativeAppActive && wasActive) {
                    logger.info("Native app released camera (polling)")
                    handleNativeAppClosed()
                }

                return nativeAppActive
            } else {
                if (nativeAppActive) {
                    logger.info("No current camera user (polling) — native app released")
                    nativeAppActive = false
                    lastCameraOwnerPackage = ""
                    handleNativeAppClosed()
                }
                return false
            }
        } catch (e: Exception) {
            logger.warn("Failed to check native app active: " + e.message)
            return nativeAppActive
        }
    }

    private fun handleNativeAppClosed() {
        nativeAppActive = false

        if (yielded) {
            yielded = false
            logger.info(
                "Re-acquiring camera after contention yield (yielded for " +
                    (System.currentTimeMillis() - yieldTimestamp) + "ms)"
            )

            scheduleReacquire()
        }
    }

    /**
     * Wait out [REACQUIRE_DELAY_MS] on a throwaway thread, then reacquire if nothing has
     * re-yielded meanwhile. Both the event-driven and polling release paths do exactly this.
     */
    private fun scheduleReacquire() {
        val callback = yieldCallback ?: return
        Thread({
            try {
                Thread.sleep(REACQUIRE_DELAY_MS)
            } catch (e: InterruptedException) {
                Thread.currentThread().interrupt()
                logger.warn("Reacquire delay interrupted")
                return@Thread
            }

            if (!yielded && !nativeAppActive) {
                callback.onReacquireCamera()
            }
        }, "CameraReacquire").start()
    }

    // ==================== Contention Detection (Fallback) ====================

    /**
     * Called by the frame stall detector when no frames arrive for 2+ seconds.
     *
     * registerCameraUser is DISABLED, so only the polling path runs.
     * If the native app currently holds the camera → yield. Otherwise HAL issue.
     */
    fun onFrameStallDetected(): Boolean {
        // Event-driven path (registerCameraUser) DISABLED:
        // if (registeredAsUser && cameraUser != null) {
        //     if (cameraUser.isNativeAppHoldingCamera()) {
        //         logger.warn("CONTENTION: Frame stall + native app holds camera — yielding now");
        //         cameraUser.yieldDueToContention();
        //         return true;
        //     } else {
        //         logger.warn("Frame stall but native app NOT holding camera — HAL issue");
        //         return false;
        //     }
        // }

        // Polling path (the only live path)
        checkNativeAppActive()

        return if (nativeAppActive) {
            logger.warn("CONTENTION DETECTED: Frame stall + native app active — yielding")
            yielded = true
            yieldTimestamp = System.currentTimeMillis()

            yieldCallback?.onYieldCamera()
            true
        } else {
            logger.warn("Frame stall but native app NOT active — HAL issue")
            false
        }
    }

    // ==================== AVMCamera Event Callback ====================

    fun setupEventCallback(cameraObj: Any?) {
        if (cameraObj == null) return

        try {
            val avmClass = Class.forName("android.hardware.AVMCamera")

            val eventCallbackClass = avmClass.declaredClasses
                .firstOrNull { it.simpleName == "IEventCallback" }

            if (eventCallbackClass == null) {
                logger.warn("AVMCamera.IEventCallback not found")
                return
            }

            val eventProxy = Proxy.newProxyInstance(
                eventCallbackClass.classLoader,
                arrayOf<Class<*>>(eventCallbackClass)
            ) { _, method, args ->
                if (method.name.startsWith("on")) {
                    var eventType = 0
                    if (args != null && args.size >= 2 && args[1] is Int) {
                        eventType = args[1] as Int
                    }
                    handleCameraEvent(eventType)
                }
                null
            }

            val setEventCallback =
                avmClass.getDeclaredMethod("setEventCallback", eventCallbackClass)
            setEventCallback.isAccessible = true
            setEventCallback.invoke(cameraObj, eventProxy)

            eventCallbackSet = true
            logger.info("AVMCamera event callback registered")
        } catch (e: ClassNotFoundException) {
            logger.info("AVMCamera.IEventCallback not available")
        } catch (e: NoSuchMethodException) {
            logger.warn("setEventCallback not found: " + e.message)
        } catch (e: Exception) {
            logger.warn("Event callback setup failed: " + e.message)
        }
    }

    private fun handleCameraEvent(eventType: Int) {
        when {
            eventType == 1003 -> {
                // EVT_TYPE_FIRST_FRAME — HAL confirmed first frame delivered
                logger.info("Camera HAL: first frame delivered (event 1003)")
            }

            eventType == -10086 || eventType == 8 -> {
                logger.error("CAMERA HAL ERROR: event=$eventType")
                yieldCallback?.onCameraError(eventType)
            }

            eventType == 1002 -> {
                // EVT_TYPE_SERVER_DIED — camera server process died
                logger.error("CAMERA HAL: server died (event 1002)")
                yieldCallback?.onCameraError(eventType)
            }

            eventType == 1000 -> {
                // EVT_TYPE_ERR — generic camera error
                logger.warn("Camera HAL error event: $eventType")
            }

            eventType != 0 && eventType != 1001 -> {
                logger.info("Camera event: $eventType")
            }
        }
    }

    // ==================== Proper Camera Cleanup ====================

    /**
     * Notify IBYDCameraService before opening camera.
     *
     * DISABLED — we don't register with the service, so preOpenCamera notifications
     * would trigger the yield protocol on the native DVR. We open silently.
     */
    fun notifyPreOpenCamera() {
        // Disabled — not participating in IBYDCameraService arbitration.
        // Opening camera directly without notifying the service.
    }

    /**
     * Notify IBYDCameraService after closing camera.
     *
     * DISABLED — we don't register with the service, so posCloseCamera notifications
     * are not needed. We close silently.
     */
    fun notifyPosCloseCamera() {
        // Disabled — not participating in IBYDCameraService arbitration.
        // Closing camera directly without notifying the service.
    }

    // ==================== Lifecycle ====================

    fun unregister() {
        // Camera user unregistration DISABLED — we never register, so nothing to unregister.
        // unregisterCameraUser();
        if (registeredAsUser) {
            unregisterCameraUser()
        }
        serviceAvailable = false
        typedServiceProxy = null
        reflectionServiceProxy = null
        getCurrentCameraUserMethod = null
    }

    // ==================== State Queries ====================

    fun isNativeAppActive(): Boolean = nativeAppActive

    fun getCurrentCameraOwnerPackage(): String = lastCameraOwnerPackage

    /**
     * cameraUser is permanently null (registerCameraUser DISABLED), so polling
     * 'yielded' is canonical.
     */
    fun isYielded(): Boolean = yielded

    fun isRegistered(): Boolean = serviceAvailable

    fun isRegisteredAsUser(): Boolean = registeredAsUser

    fun isEventCallbackActive(): Boolean = eventCallbackSet

    fun getArbitrationMode(): String = arbitrationMode

    fun resetEventCallbackState() {
        eventCallbackSet = false
    }

    // ==================== AIDL Discovery ====================

    /**
     * Discovers the full IBYDCameraService and IBYDCameraUser AIDL interfaces
     * by enumerating methods via reflection. Logs everything for debugging.
     */
    fun discoverCameraServiceApi() {
        logger.info("=== IBYDCameraService API Discovery ===")

        // Enumerate service methods
        val serviceProxy: Any? = typedServiceProxy ?: reflectionServiceProxy
        if (serviceProxy != null) {
            logger.info("--- Service proxy methods ---")
            try {
                for (m in serviceProxy.javaClass.declaredMethods) {
                    logger.info(describeMethod(m))
                }
            } catch (e: Exception) {
                logger.warn("Failed to enumerate service methods: " + e.message)
            }
        }

        // Check for IBYDCameraUser
        val candidates = arrayOf(
            "android.hardware.IBYDCameraUser",
            "android.hardware.IBYDCameraUser\$Stub"
        )
        for (name in candidates) {
            try {
                val cls = Class.forName(name)
                logger.info("FOUND: $name")
                for (m in cls.declaredMethods) {
                    logger.info(describeMethod(m))
                }
            } catch (e: ClassNotFoundException) {
                logger.info("NOT FOUND: $name")
            } catch (e: Exception) {
                logger.warn("Error probing $name: " + e.message)
            }
        }

        // Log transaction codes from Stub classes
        val stubs = arrayOf(
            "android.hardware.IBYDCameraService\$Stub",
            "android.hardware.IBYDCameraUser\$Stub"
        )
        for (name in stubs) {
            try {
                val cls = Class.forName(name)
                logger.info("--- $name fields ---")
                for (f in cls.declaredFields) {
                    f.isAccessible = true
                    try {
                        logger.info("  " + f.name + " = " + f.get(null))
                    } catch (e: Exception) {
                        logger.info("  " + f.name + " (type=" + f.type.simpleName + ")")
                    }
                }
            } catch (e: ClassNotFoundException) {
                // Already logged above
            } catch (e: Exception) {
                logger.warn("Stub field scan failed for $name: " + e.message)
            }
        }

        logger.info("=== Discovery complete (registeredAsUser=$registeredAsUser) ===")
    }

    /** `ReturnType name(paramType, ...)`, indented — the discovery log's one line format. */
    private fun describeMethod(m: Method): String =
        "  " + m.returnType.simpleName + " " + m.name +
            "(" + m.parameterTypes.joinToString(", ") { it.name } + ")"

    companion object {
        private const val TAG = "BydCameraCoordinator"
        private val logger = DaemonLogger.getInstance(TAG)

        /** Native app fully closed by onCloseCamera */
        private const val REACQUIRE_DELAY_MS = 200L

        @JvmStatic
        fun closeCamera(cameraObj: Any?, channelId: Int) {
            if (cameraObj == null) return

            try {
                val avmClass = Class.forName("android.hardware.AVMCamera")

                try {
                    val m = avmClass.getDeclaredMethod(
                        "disablePreviewCallback", Int::class.javaPrimitiveType
                    )
                    m.isAccessible = true
                    m.invoke(cameraObj, channelId)
                } catch (ignored: NoSuchMethodException) {
                    logger.warn("disablePreviewCallback method not found")
                } catch (e: Exception) {
                    logger.warn("disablePreviewCallback failed: " + e.message)
                }

                try {
                    val m = avmClass.getDeclaredMethod("stopPreview")
                    m.isAccessible = true
                    m.invoke(cameraObj)
                } catch (e: Exception) {
                    logger.warn("stopPreview failed: " + e.message)
                }

                try {
                    val m = avmClass.getDeclaredMethod("close")
                    m.isAccessible = true
                    m.invoke(cameraObj)
                } catch (e: Exception) {
                    logger.warn("close failed: " + e.message)
                }
            } catch (e: ClassNotFoundException) {
                logger.error("AVMCamera class not found")
            }
        }
    }
}
