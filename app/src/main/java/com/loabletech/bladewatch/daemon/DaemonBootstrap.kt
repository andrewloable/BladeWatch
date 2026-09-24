package net.bladewatch.app.daemon

import android.content.ContentResolver
import android.content.Context
import android.content.ContextWrapper
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.content.res.Resources
import android.os.Looper

import net.bladewatch.app.logging.DaemonLogger

/**
 * Bootstrap utility for standalone daemons running via app_process.
 *
 * This object provides a bootstrap sequence that:
 * 1. Creates an app context using a hardcoded package name (chicken-egg problem)
 * 2. Provides permission bypass for accessing BYD hardware services
 *
 * Note: Native library loading was removed - encryption now uses pure Kotlin (Safe.kt)
 * which is 100% stable across all Android versions when running via app_process.
 *
 * USAGE (at the start of every daemon's main()):
 *   Context ctx = DaemonBootstrap.init();
 *   // Now Safe.s() / S.d() / Enc.* works correctly
 */
object DaemonBootstrap {

    private const val TAG = "DaemonBootstrap"
    private val logger = DaemonLogger.getInstance(TAG)

    // Hardcoded - this is the ONLY place we need to hardcode the package name
    // It's required to break the chicken-egg problem (can't decrypt package name without context)
    private const val BOOTSTRAP_PACKAGE = "net.bladewatch.app"

    /** The cached app context (must call [init] first). */
    @JvmStatic
    var context: Context? = null
        private set

    /** Whether bootstrap has completed successfully. */
    @JvmStatic
    var isInitialized: Boolean = false
        private set

    /**
     * Initialize the daemon environment and return an app context.
     * Safe to call multiple times - will return cached context after first init.
     *
     * @param grantPermissions run the `pm grant` pass over the service host's manifest permissions.
     *   CameraDaemon needs it (the BYD HAL checks permissions natively). pear_daemon does not -- its
     *   network access comes from the shell uid's own groups -- and the pass cost it 17.75 s of
     *   `pm grant` calls on every start before the worklet could boot (measured on the head unit,
     *   BladeWatch-rdtj.3), so it passes false.
     * @return App context with permission bypass, or null if init failed
     */
    @JvmStatic
    @Synchronized
    fun init(grantPermissions: Boolean = true): Context? {
        if (isInitialized) {
            return context
        }

        log("=== DaemonBootstrap Starting ===")

        return try {
            // Step 1: Create app context using hardcoded package name
            val ctx = createAppContext()
            context = ctx
            if (ctx == null) {
                log("ERROR: Failed to create app context")
                return null
            }
            log("App context created: " + ctx.packageName)

            // Step 2: Grant all manifest permissions via shell
            // PermissionBypassContext fakes PERMISSION_GRANTED locally, but pm grant
            // ensures the OS-level permission state is correct for cases where the
            // BYD HAL native layer checks permissions outside our context wrapper.
            if (grantPermissions) PermissionGranter.grantAllPermissions(BOOTSTRAP_PACKAGE)

            // Step 3: Verify Safe.s() decryption works (pure Kotlin, no native libs needed)
            if (verifySafeWorking()) {
                log("Safe.s() verification PASSED")
            } else {
                log("WARNING: Safe.s() verification FAILED - strings may be encrypted")
            }

            isInitialized = true
            log("=== DaemonBootstrap Complete ===")
            ctx
        } catch (e: Exception) {
            log("FATAL: Bootstrap failed: " + e.message)
            e.printStackTrace()
            null
        }
    }

    /** Get the hardcoded package name (for use before decryption is verified). */
    @JvmStatic
    fun getPackageName(): String = BOOTSTRAP_PACKAGE

    // ==================== INTERNAL HELPERS ====================

    private fun createAppContext(): Context? {
        try {
            val activityThreadClass = Class.forName("android.app.ActivityThread")
            var activityThread: Any? = null

            // Strategy 1: existing thread
            try {
                activityThread =
                    activityThreadClass.getMethod("currentActivityThread").invoke(null)
            } catch (ignored: Exception) {
                logger.warn(
                    "DaemonBootstrap createAppContext: strategy 1 (currentActivityThread) " +
                        "failed: " + ignored.message
                )
            }

            // Strategy 2: systemMain with timeout
            if (activityThread == null) {
                val result = arrayOfNulls<Any>(1)
                val t = Thread({
                    try {
                        result[0] = activityThreadClass.getMethod("systemMain").invoke(null)
                    } catch (ignored: Exception) {
                        logger.warn(
                            "DaemonBootstrap createAppContext: strategy 2 (systemMain) " +
                                "failed: " + ignored.message
                        )
                    }
                }, "SystemMainInit")
                t.isDaemon = true
                t.start()
                t.join(10_000)
                if (t.isAlive) {
                    log("createAppContext: systemMain timed out (10s)")
                    t.interrupt()
                    try {
                        activityThread =
                            activityThreadClass.getMethod("currentActivityThread").invoke(null)
                    } catch (ignored: Exception) {
                        logger.warn(
                            "DaemonBootstrap createAppContext: strategy 2 post-timeout " +
                                "currentActivityThread failed: " + ignored.message
                        )
                    }
                } else {
                    activityThread = result[0]
                }
            }

            // Strategy 3: manual creation
            if (activityThread == null) {
                try {
                    prepareMainLooperForShellDaemon()
                    val ctor = activityThreadClass.getDeclaredConstructor()
                    ctor.isAccessible = true
                    activityThread = ctor.newInstance()
                    try {
                        val f = activityThreadClass.getDeclaredField("sCurrentActivityThread")
                        f.isAccessible = true
                        f.set(null, activityThread)
                    } catch (ignored: Exception) {
                        logger.warn(
                            "DaemonBootstrap createAppContext: strategy 3 failed to set " +
                                "sCurrentActivityThread: " + ignored.message
                        )
                    }
                    log("createAppContext: manual ActivityThread creation succeeded")
                } catch (e: Exception) {
                    log("createAppContext: manual creation failed: " + e.message)
                }
            }

            if (activityThread == null) {
                log("Failed to get ActivityThread, using null-safe fallback")
                return PermissionBypassContext(null)
            }

            val systemContext = activityThreadClass.getMethod("getSystemContext")
                .invoke(activityThread) as Context?
                ?: return PermissionBypassContext(null)

            return PermissionBypassContext(
                systemContext.createPackageContext(
                    BOOTSTRAP_PACKAGE,
                    Context.CONTEXT_INCLUDE_CODE or Context.CONTEXT_IGNORE_SECURITY
                )
            )
        } catch (e: Exception) {
            log("createAppContext failed: " + e.message)
            return PermissionBypassContext(null)
        }
    }

    /** Verify that Safe.s() decryption is working by testing a known value. */
    private fun verifySafeWorking(): Boolean = try {
        val encClass = Class.forName("net.bladewatch.app.daemon.proxy.Enc")
        val decrypted = encClass.getDeclaredField("APP_PACKAGE").get(null) as String?

        // If decryption works, it should return "net.bladewatch.app"
        // If it fails, it returns "ERR" or the encrypted base64 string
        log("Enc.APP_PACKAGE = $decrypted (expected: $BOOTSTRAP_PACKAGE)")
        BOOTSTRAP_PACKAGE == decrypted
    } catch (e: Exception) {
        log("verifySafeWorking failed: " + e.message)
        false
    }

    private fun log(msg: String) {
        println("DaemonBootstrap: $msg")
    }

    @Suppress("DEPRECATION")
    private fun prepareMainLooperForShellDaemon() {
        // This bootstrap runs outside a normal app ActivityThread, so BYD SDK
        // listener registration needs a process main looper created manually.
        try {
            Looper.prepareMainLooper()
        } catch (ignored: Exception) {
            logger.warn(
                "prepareMainLooperForShellDaemon: Looper.prepareMainLooper() failed: " +
                    ignored.message
            )
        }
    }

    /**
     * Context wrapper that bypasses permission checks.
     * Required for accessing BYD hardware services without signature permissions.
     */
    class PermissionBypassContext(base: Context?) : ContextWrapper(base) {

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

        // Null-safe overrides for fallback mode
        override fun getApplicationContext(): Context = try {
            super.getApplicationContext()
        } catch (e: NullPointerException) {
            logger.warn("PermissionBypassContext.getApplicationContext() NPE: " + e.message)
            this
        }

        override fun getPackageName(): String = try {
            super.getPackageName()
        } catch (e: NullPointerException) {
            logger.warn("PermissionBypassContext.getPackageName() NPE: " + e.message)
            BOOTSTRAP_PACKAGE
        }

        override fun getSystemService(name: String): Any? = try {
            super.getSystemService(name)
        } catch (e: NullPointerException) {
            logger.warn(
                "PermissionBypassContext.getSystemService(\"$name\") NPE: " + e.message
            )
            null
        }

        override fun getApplicationInfo(): ApplicationInfo = try {
            super.getApplicationInfo()
        } catch (e: NullPointerException) {
            logger.warn("PermissionBypassContext.getApplicationInfo() NPE: " + e.message)
            ApplicationInfo()
        }

        override fun getContentResolver(): ContentResolver? = try {
            super.getContentResolver()
        } catch (e: NullPointerException) {
            logger.warn("PermissionBypassContext.getContentResolver() NPE: " + e.message)
            null
        }

        override fun getResources(): Resources? = try {
            super.getResources()
        } catch (e: NullPointerException) {
            logger.warn("PermissionBypassContext.getResources() NPE: " + e.message)
            null
        }

        override fun createPackageContext(packageName: String, flags: Int): Context = try {
            super.createPackageContext(packageName, flags)
        } catch (e: Exception) {
            logger.warn(
                "PermissionBypassContext.createPackageContext(\"$packageName\") failed: " +
                    e.message
            )
            this
        }
    }
}
