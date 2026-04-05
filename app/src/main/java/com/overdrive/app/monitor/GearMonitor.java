package com.overdrive.app.monitor;

import android.content.Context;
import android.hardware.bydauto.gearbox.AbsBYDAutoGearboxListener;

import com.overdrive.app.daemon.CameraDaemon;
import com.overdrive.app.logging.DaemonLogger;

import java.lang.reflect.Method;

/**
 * Gear Monitor
 * 
 * Monitors gear position changes from BYDAutoGearboxDevice.
 * Notifies CameraDaemon.onGearChanged() when gear changes.
 * 
 * Used by PROXIMITY_GUARD mode to activate when gear != P.
 */
public class GearMonitor {
    private static final DaemonLogger logger = DaemonLogger.getInstance("GearMonitor");
    
    // Gear constants
    public static final int GEAR_P = 1;
    public static final int GEAR_R = 2;
    public static final int GEAR_N = 3;
    public static final int GEAR_D = 4;
    public static final int GEAR_M = 5;
    public static final int GEAR_S = 6;
    
    private static GearMonitor instance;
    
    private Context context;
    private Object gearboxDevice;
    private GearListener gearListener;
    private boolean isRunning = false;
    private int currentGear = GEAR_P;
    private long lastUpdateTime = 0;
    
    private GearMonitor() {}
    
    public static synchronized GearMonitor getInstance() {
        if (instance == null) {
            instance = new GearMonitor();
        }
        return instance;
    }
    
    /**
     * Initialize with context.
     */
    public void init(Context context) {
        this.context = context;
        logger.info("GearMonitor initialized");
    }
    
    /**
     * Start monitoring gear changes.
     */
    public void start() {
        if (isRunning) {
            logger.warn("Already running");
            return;
        }
        
        try {
            logger.info("Starting gear monitor...");
            
            // Get gearbox device instance via reflection
            Class<?> gearboxClass = Class.forName("android.hardware.bydauto.gearbox.BYDAutoGearboxDevice");
            Method getInstance = gearboxClass.getMethod("getInstance", Context.class);
            gearboxDevice = getInstance.invoke(null, context);
            
            if (gearboxDevice == null) {
                logger.error("BYDAutoGearboxDevice.getInstance() returned null");
                return;
            }
            
            // Get initial gear state
            Method getGear = gearboxClass.getMethod("getGearboxAutoModeType");
            currentGear = (int) getGear.invoke(gearboxDevice);
            lastUpdateTime = System.currentTimeMillis();
            logger.info("Initial gear: " + gearToString(currentGear));
            
            // Register listener
            gearListener = new GearListener();
            Method registerListener = gearboxClass.getMethod("registerListener",
                Class.forName("android.hardware.bydauto.gearbox.AbsBYDAutoGearboxListener"));
            registerListener.invoke(gearboxDevice, gearListener);
            
            isRunning = true;
            logger.info("Gear monitor started successfully");
            
            // Notify initial state
            CameraDaemon.onGearChanged(currentGear);
            
        } catch (Exception e) {
            logger.error("Failed to start gear monitor: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    /**
     * Stop monitoring.
     */
    public void stop() {
        if (!isRunning) {
            return;
        }
        
        try {
            if (gearboxDevice != null && gearListener != null) {
                Class<?> gearboxClass = gearboxDevice.getClass();
                Method unregisterListener = gearboxClass.getMethod("unregisterListener",
                    Class.forName("android.hardware.bydauto.gearbox.AbsBYDAutoGearboxListener"));
                unregisterListener.invoke(gearboxDevice, gearListener);
                logger.info("Gear listener unregistered");
            }
        } catch (Exception e) {
            logger.error("Failed to unregister gear listener: " + e.getMessage());
        } finally {
            isRunning = false;
            gearboxDevice = null;
            gearListener = null;
        }
    }
    
    /**
     * Get current gear.
     */
    public int getCurrentGear() {
        return currentGear;
    }
    
    /**
     * Get last update time.
     */
    public long getLastUpdateTime() {
        return lastUpdateTime;
    }
    
    /**
     * Check if running.
     */
    public boolean isRunning() {
        return isRunning;
    }
    
    /**
     * Convert gear to string.
     */
    public static String gearToString(int gear) {
        switch (gear) {
            case GEAR_P: return "P";
            case GEAR_R: return "R";
            case GEAR_N: return "N";
            case GEAR_D: return "D";
            case GEAR_M: return "M";
            case GEAR_S: return "S";
            default: return "UNKNOWN(" + gear + ")";
        }
    }
    
    /**
     * Gear change listener.
     */
    private class GearListener extends AbsBYDAutoGearboxListener {
        @Override
        public void onGearboxAutoModeTypeChanged(int gear) {
            if (gear != currentGear) {
                logger.info("Gear changed: " + gearToString(currentGear) + " -> " + gearToString(gear));
                currentGear = gear;
                lastUpdateTime = System.currentTimeMillis();
                
                // Notify CameraDaemon
                CameraDaemon.onGearChanged(gear);
            }
        }
    }
}
