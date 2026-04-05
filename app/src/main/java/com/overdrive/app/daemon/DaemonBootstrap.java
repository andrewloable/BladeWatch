package com.overdrive.app.daemon;

import android.content.Context;

import java.lang.reflect.Field;
import java.lang.reflect.Method;

/**
 * Bootstrap utility for standalone daemons running via app_process.
 * 
 * This class provides a bootstrap sequence that:
 * 1. Creates an app context using a hardcoded package name (chicken-egg problem)
 * 2. Provides permission bypass for accessing BYD hardware services
 * 
 * Note: Native library loading was removed - encryption now uses pure Java (Safe.java)
 * which is 100% stable across all Android versions when running via app_process.
 * 
 * USAGE (at the start of every daemon's main()):
 *   Context ctx = DaemonBootstrap.init();
 *   // Now Safe.s() / S.d() / Enc.* works correctly
 */
public final class DaemonBootstrap {
    
    private static final String TAG = "DaemonBootstrap";
    
    // Hardcoded - this is the ONLY place we need to hardcode the package name
    // It's required to break the chicken-egg problem (can't decrypt package name without context)
    private static final String BOOTSTRAP_PACKAGE = "com.overdrive.app";
    
    private static Context appContext = null;
    private static boolean initialized = false;
    
    private DaemonBootstrap() {} // No instantiation
    
    /**
     * Initialize the daemon environment and return an app context.
     * Safe to call multiple times - will return cached context after first init.
     * 
     * @return App context with permission bypass, or null if init failed
     */
    public static synchronized Context init() {
        if (initialized) {
            return appContext;
        }
        
        log("=== DaemonBootstrap Starting ===");
        
        try {
            // Step 1: Create app context using hardcoded package name
            appContext = createAppContext();
            if (appContext == null) {
                log("ERROR: Failed to create app context");
                return null;
            }
            log("App context created: " + appContext.getPackageName());
            
            // Step 2: Verify Safe.s() decryption works (pure Java, no native libs needed)
            if (verifySafeWorking()) {
                log("Safe.s() verification PASSED");
            } else {
                log("WARNING: Safe.s() verification FAILED - strings may be encrypted");
            }
            
            initialized = true;
            log("=== DaemonBootstrap Complete ===");
            return appContext;
            
        } catch (Exception e) {
            log("FATAL: Bootstrap failed: " + e.getMessage());
            e.printStackTrace();
            return null;
        }
    }
    
    /**
     * Get the cached app context (must call init() first).
     */
    public static Context getContext() {
        return appContext;
    }
    
    /**
     * Check if bootstrap has completed successfully.
     */
    public static boolean isInitialized() {
        return initialized;
    }
    
    /**
     * Get the hardcoded package name (for use before decryption is verified).
     */
    public static String getPackageName() {
        return BOOTSTRAP_PACKAGE;
    }
    
    // ==================== INTERNAL HELPERS ====================
    
    private static Context createAppContext() {
        try {
            Class<?> activityThreadClass = Class.forName("android.app.ActivityThread");
            Object activityThread = null;
            
            // Try to get existing ActivityThread
            try {
                Method currentActivityThread = activityThreadClass.getMethod("currentActivityThread");
                activityThread = currentActivityThread.invoke(null);
            } catch (Exception ignored) {}
            
            // If none exists, create one via systemMain
            if (activityThread == null) {
                Method systemMain = activityThreadClass.getMethod("systemMain");
                activityThread = systemMain.invoke(null);
            }
            
            if (activityThread == null) {
                log("Failed to get ActivityThread");
                return null;
            }
            
            // Get system context
            Method getSystemContext = activityThreadClass.getMethod("getSystemContext");
            Context systemContext = (Context) getSystemContext.invoke(activityThread);
            
            // Create package context for our app
            Context packageContext = systemContext.createPackageContext(
                BOOTSTRAP_PACKAGE,
                Context.CONTEXT_INCLUDE_CODE | Context.CONTEXT_IGNORE_SECURITY
            );
            
            // Wrap with permission bypass
            return new PermissionBypassContext(packageContext);
            
        } catch (Exception e) {
            log("createAppContext failed: " + e.getMessage());
            return null;
        }
    }
    
    /**
     * Verify that Safe.s() decryption is working by testing a known value.
     */
    private static boolean verifySafeWorking() {
        try {
            Class<?> encClass = Class.forName("com.overdrive.app.daemon.proxy.Enc");
            Field appPackageField = encClass.getDeclaredField("APP_PACKAGE");
            String decrypted = (String) appPackageField.get(null);
            
            // If decryption works, it should return "com.overdrive.app"
            // If it fails, it returns "ERR" or the encrypted base64 string
            boolean works = BOOTSTRAP_PACKAGE.equals(decrypted);
            log("Enc.APP_PACKAGE = " + decrypted + " (expected: " + BOOTSTRAP_PACKAGE + ")");
            return works;
            
        } catch (Exception e) {
            log("verifySafeWorking failed: " + e.getMessage());
            return false;
        }
    }
    
    private static void log(String msg) {
        System.out.println("DaemonBootstrap: " + msg);
    }
    
    /**
     * Context wrapper that bypasses permission checks.
     * Required for accessing BYD hardware services without signature permissions.
     */
    public static class PermissionBypassContext extends android.content.ContextWrapper {
        public PermissionBypassContext(Context base) { 
            super(base); 
        }
        
        @Override 
        public void enforceCallingOrSelfPermission(String permission, String message) {}
        
        @Override 
        public void enforcePermission(String permission, int pid, int uid, String message) {}
        
        @Override 
        public void enforceCallingPermission(String permission, String message) {}
        
        @Override 
        public int checkCallingOrSelfPermission(String permission) {
            return android.content.pm.PackageManager.PERMISSION_GRANTED;
        }
        
        @Override 
        public int checkPermission(String permission, int pid, int uid) {
            return android.content.pm.PackageManager.PERMISSION_GRANTED;
        }
        
        @Override 
        public int checkSelfPermission(String permission) {
            return android.content.pm.PackageManager.PERMISSION_GRANTED;
        }
    }
}
