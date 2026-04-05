package com.overdrive.app.monitor;

import android.content.Context;

import com.overdrive.app.logging.DaemonLogger;

import org.json.JSONObject;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * Singleton coordinator for BYD vehicle data monitoring.
 * 
 * Manages all device monitors and provides unified access to vehicle data.
 * Supports daemon mode (null Context) and app mode (with Context).
 */
public class VehicleDataMonitor {
    
    private static final String TAG = "VehicleDataMonitor";
    private static final DaemonLogger logger = DaemonLogger.getInstance(TAG);
    
    // Singleton
    private static VehicleDataMonitor instance;
    private static final Object lock = new Object();
    
    // Monitors
    private final BatteryVoltageMonitor batteryVoltageMonitor;
    private final BatteryPowerMonitor batteryPowerMonitor;
    private final BatterySocMonitor batterySocMonitor;
    private final ChargingStateMonitor chargingStateMonitor;
    private final DrivingRangeMonitor drivingRangeMonitor;
    
    // Cache
    private final VehicleDataCache cache;
    
    // Listeners
    private final CopyOnWriteArrayList<VehicleDataListener> listeners = new CopyOnWriteArrayList<>();
    
    // State
    private boolean isRunning = false;
    private Context context;
    
    private VehicleDataMonitor() {
        this.batteryVoltageMonitor = new BatteryVoltageMonitor();
        this.batteryPowerMonitor = new BatteryPowerMonitor();
        this.batterySocMonitor = new BatterySocMonitor();
        this.chargingStateMonitor = new ChargingStateMonitor();
        this.drivingRangeMonitor = new DrivingRangeMonitor();
        this.cache = new VehicleDataCache();
    }
    
    /**
     * Get singleton instance.
     */
    public static VehicleDataMonitor getInstance() {
        if (instance == null) {
            synchronized (lock) {
                if (instance == null) {
                    instance = new VehicleDataMonitor();
                }
            }
        }
        return instance;
    }
    
    // ==================== LIFECYCLE ====================
    
    /**
     * Initialize all monitors.
     * Pass null for daemon mode.
     * 
     * @param context Android context, or null for daemon mode
     */
    public void init(Context context) {
        this.context = context;
        logger.info("Initializing VehicleDataMonitor (daemon mode: " + (context == null) + ")");
        
        // Initialize all monitors
        try {
            batteryVoltageMonitor.init(context);
        } catch (Exception e) {
            logger.error("Failed to init BatteryVoltageMonitor", e);
        }
        
        try {
            batteryPowerMonitor.init(context);
        } catch (Exception e) {
            logger.error("Failed to init BatteryPowerMonitor", e);
        }
        
        try {
            batterySocMonitor.init(context);
        } catch (Exception e) {
            logger.error("Failed to init BatterySocMonitor", e);
        }
        
        try {
            chargingStateMonitor.init(context);
            // Set reference to this monitor for kWh-based power calculation
            chargingStateMonitor.setVehicleDataMonitor(this);
        } catch (Exception e) {
            logger.error("Failed to init ChargingStateMonitor", e);
        }
        
        try {
            drivingRangeMonitor.init(context);
        } catch (Exception e) {
            logger.error("Failed to init DrivingRangeMonitor", e);
        }
        
        logger.info("Initialization complete");
    }
    
    /**
     * Initialize only the 12V battery power monitor.
     * Use this for sentry mode where only voltage monitoring is needed.
     * 
     * @param context Android context, or null for daemon mode
     */
    public void initBatteryPowerOnly(Context context) {
        this.context = context;
        logger.info("Initializing VehicleDataMonitor (battery power only)");
        
        try {
            batteryPowerMonitor.init(context);
        } catch (Exception e) {
            logger.error("Failed to init BatteryPowerMonitor", e);
        }
        
        logger.info("Battery power monitor initialized");
    }
    
    /**
     * Start only the battery power monitor.
     * Use this for sentry mode where only voltage monitoring is needed.
     */
    public synchronized void startBatteryPowerOnly() {
        if (isRunning) {
            logger.info("Already running");
            return;
        }
        
        logger.info("Starting battery power monitor only...");
        
        try {
            batteryPowerMonitor.start();
        } catch (Exception e) {
            logger.error("Failed to start BatteryPowerMonitor", e);
        }
        
        isRunning = true;
        logger.info("Battery power monitor started");
    }
    
    /**
     * Stop only the battery power monitor.
     */
    public synchronized void stopBatteryPowerOnly() {
        if (!isRunning) {
            logger.info("Already stopped");
            return;
        }
        
        logger.info("Stopping battery power monitor...");
        
        try {
            batteryPowerMonitor.stop();
        } catch (Exception e) {
            logger.error("Failed to stop BatteryPowerMonitor", e);
        }
        
        isRunning = false;
        logger.info("Battery power monitor stopped");
    }
    
    /**
     * Start all monitors.
     * Idempotent - safe to call multiple times.
     */
    public synchronized void start() {
        if (isRunning) {
            logger.info("Already running");
            return;
        }
        
        logger.info("Starting all monitors...");
        
        // Start all monitors
        try {
            batteryVoltageMonitor.start();
        } catch (Exception e) {
            logger.error("Failed to start BatteryVoltageMonitor", e);
        }
        
        try {
            batteryPowerMonitor.start();
        } catch (Exception e) {
            logger.error("Failed to start BatteryPowerMonitor", e);
        }
        
        try {
            batterySocMonitor.start();
        } catch (Exception e) {
            logger.error("Failed to start BatterySocMonitor", e);
        }
        
        try {
            chargingStateMonitor.start();
        } catch (Exception e) {
            logger.error("Failed to start ChargingStateMonitor", e);
        }
        
        try {
            drivingRangeMonitor.start();
        } catch (Exception e) {
            logger.error("Failed to start DrivingRangeMonitor", e);
        }
        
        isRunning = true;
        logger.info("All monitors started");
    }
    
    /**
     * Stop all monitors.
     * Idempotent - safe to call multiple times.
     */
    public synchronized void stop() {
        if (!isRunning) {
            logger.info("Already stopped");
            return;
        }
        
        logger.info("Stopping all monitors...");
        
        // Stop all monitors
        try {
            batteryVoltageMonitor.stop();
        } catch (Exception e) {
            logger.error("Failed to stop BatteryVoltageMonitor", e);
        }
        
        try {
            batteryPowerMonitor.stop();
        } catch (Exception e) {
            logger.error("Failed to stop BatteryPowerMonitor", e);
        }
        
        try {
            batterySocMonitor.stop();
        } catch (Exception e) {
            logger.error("Failed to stop BatterySocMonitor", e);
        }
        
        try {
            chargingStateMonitor.stop();
        } catch (Exception e) {
            logger.error("Failed to stop ChargingStateMonitor", e);
        }
        
        try {
            drivingRangeMonitor.stop();
        } catch (Exception e) {
            logger.error("Failed to stop DrivingRangeMonitor", e);
        }
        
        isRunning = false;
        logger.info("All monitors stopped");
    }
    
    /**
     * Check if monitoring is running.
     */
    public boolean isRunning() {
        return isRunning;
    }
    
    // ==================== DATA ACCESS ====================
    
    /**
     * Get battery voltage level data.
     */
    public BatteryVoltageData getBatteryVoltage() {
        BatteryVoltageData data = batteryVoltageMonitor.getCurrentValue();
        if (data != null) {
            cache.updateBatteryVoltage(data);
        }
        return cache.getBatteryVoltage();
    }
    
    /**
     * Get battery power voltage data.
     */
    public BatteryPowerData getBatteryPower() {
        BatteryPowerData data = batteryPowerMonitor.getCurrentValue();
        if (data != null) {
            cache.updateBatteryPower(data);
        }
        return cache.getBatteryPower();
    }
    
    /**
     * Get battery SOC data.
     */
    public BatterySocData getBatterySoc() {
        BatterySocData data = batterySocMonitor.getCurrentValue();
        if (data != null) {
            cache.updateBatterySoc(data);
        }
        return cache.getBatterySoc();
    }
    
    /**
     * Get charging state data.
     */
    public ChargingStateData getChargingState() {
        ChargingStateData data = chargingStateMonitor.getCurrentValue();
        if (data != null) {
            cache.updateChargingState(data);
        }
        return cache.getChargingState();
    }
    
    /**
     * Get driving range data.
     */
    public DrivingRangeData getDrivingRange() {
        return drivingRangeMonitor.getCurrentValue();
    }
    
    /**
     * Get remaining battery power in kWh from BYDAutoPowerDevice.
     * This is the actual remaining energy in the EV battery.
     */
    public double getBatteryRemainPowerKwh() {
        try {
            android.hardware.bydauto.power.BYDAutoPowerDevice powerDevice = 
                android.hardware.bydauto.power.BYDAutoPowerDevice.getInstance(context);
            if (powerDevice != null) {
                return powerDevice.getBatteryRemainPowerEV();
            }
        } catch (Exception e) {
            logger.debug("Failed to get battery remain power: " + e.getMessage());
        }
        return 0.0;
    }
    
    /**
     * Get all vehicle data as JSON.
     */
    public JSONObject getAllData() {
        JSONObject json = new JSONObject();
        
        try {
            // Battery voltage
            BatteryVoltageData bv = getBatteryVoltage();
            if (bv != null) {
                JSONObject bvJson = new JSONObject();
                bvJson.put("level", bv.level);
                bvJson.put("levelName", bv.levelName);
                bvJson.put("isWarning", bv.isWarning);
                bvJson.put("timestamp", bv.timestamp);
                json.put("batteryVoltage", bvJson);
            }
            
            // Battery power
            BatteryPowerData bp = getBatteryPower();
            if (bp != null) {
                JSONObject bpJson = new JSONObject();
                bpJson.put("voltageVolts", bp.voltageVolts);
                bpJson.put("isWarning", bp.isWarning);
                bpJson.put("isCritical", bp.isCritical);
                bpJson.put("healthStatus", bp.getHealthStatus());
                bpJson.put("timestamp", bp.timestamp);
                json.put("batteryPower", bpJson);
            }
            
            // Battery SOC
            BatterySocData bs = getBatterySoc();
            if (bs != null) {
                JSONObject bsJson = new JSONObject();
                bsJson.put("socPercent", bs.socPercent);
                bsJson.put("isLow", bs.isLow);
                bsJson.put("isCritical", bs.isCritical);
                bsJson.put("status", bs.getStatus());
                bsJson.put("timestamp", bs.timestamp);
                json.put("batterySoc", bsJson);
            }
            
            // Charging state
            ChargingStateData cs = getChargingState();
            if (cs != null) {
                JSONObject csJson = new JSONObject();
                csJson.put("stateCode", cs.stateCode);
                csJson.put("stateName", cs.stateName);
                csJson.put("status", cs.status.name());
                csJson.put("isError", cs.isError);
                csJson.put("errorType", cs.errorType);
                csJson.put("chargingPowerKW", cs.chargingPowerKW);
                csJson.put("isDischarging", cs.isDischarging);
                csJson.put("timestamp", cs.timestamp);
                json.put("chargingState", csJson);
            }
            
            // Driving range
            DrivingRangeData dr = getDrivingRange();
            if (dr != null) {
                JSONObject drJson = new JSONObject();
                drJson.put("elecRangeKm", dr.elecRangeKm);
                drJson.put("fuelRangeKm", dr.fuelRangeKm);
                drJson.put("totalRangeKm", dr.totalRangeKm);
                drJson.put("isLow", dr.isLow);
                drJson.put("isCritical", dr.isCritical);
                drJson.put("status", dr.getStatus());
                drJson.put("isPureEV", dr.isPureEV());
                drJson.put("timestamp", dr.timestamp);
                json.put("drivingRange", drJson);
            }
            
            // Metadata
            json.put("isStale", cache.isStale(60000)); // 60 seconds
            json.put("timestamp", System.currentTimeMillis());
            
        } catch (Exception e) {
            logger.error("Failed to create JSON", e);
        }
        
        return json;
    }
    
    /**
     * Get availability status for each monitor.
     */
    public Map<String, Boolean> getAvailability() {
        Map<String, Boolean> availability = new HashMap<>();
        availability.put("batteryVoltage", batteryVoltageMonitor.isAvailable());
        availability.put("batteryPower", batteryPowerMonitor.isAvailable());
        availability.put("batterySoc", batterySocMonitor.isAvailable());
        availability.put("chargingState", chargingStateMonitor.isAvailable());
        availability.put("drivingRange", drivingRangeMonitor.isAvailable());
        return availability;
    }
    
    // ==================== MONITOR ACCESS ====================
    
    /**
     * Get battery voltage monitor (for internal use).
     */
    public BatteryVoltageMonitor getBatteryVoltageMonitor() {
        return batteryVoltageMonitor;
    }
    
    /**
     * Get battery power monitor (for internal use).
     */
    public BatteryPowerMonitor getBatteryPowerMonitor() {
        return batteryPowerMonitor;
    }
    
    /**
     * Get driving range monitor (for internal use).
     */
    public DrivingRangeMonitor getDrivingRangeMonitor() {
        return drivingRangeMonitor;
    }
    
    /**
     * Get charging state monitor (for internal use).
     */
    public ChargingStateMonitor getChargingStateMonitor() {
        return chargingStateMonitor;
    }
    
    // ==================== LISTENER MANAGEMENT ====================
    
    /**
     * Add a listener for vehicle data updates.
     * Thread-safe.
     * 
     * @param listener The listener to add
     */
    public void addListener(VehicleDataListener listener) {
        if (listener != null && !listeners.contains(listener)) {
            listeners.add(listener);
            logger.info("Listener added (total: " + listeners.size() + ")");
        }
    }
    
    /**
     * Remove a listener.
     * Thread-safe.
     * 
     * @param listener The listener to remove
     */
    public void removeListener(VehicleDataListener listener) {
        if (listener != null && listeners.remove(listener)) {
            logger.info("Listener removed (remaining: " + listeners.size() + ")");
        }
    }
    
    /**
     * Notify all listeners of a battery voltage change.
     */
    public void notifyBatteryVoltageChanged(BatteryVoltageData data) {
        for (VehicleDataListener listener : listeners) {
            try {
                listener.onBatteryVoltageChanged(data);
            } catch (Exception e) {
                logger.error("Listener notification failed", e);
                // Continue with other listeners
            }
        }
    }
    
    /**
     * Notify all listeners of a battery power change.
     */
    public void notifyBatteryPowerChanged(BatteryPowerData data) {
        for (VehicleDataListener listener : listeners) {
            try {
                listener.onBatteryPowerChanged(data);
            } catch (Exception e) {
                logger.error("Listener notification failed", e);
                // Continue with other listeners
            }
        }
    }
    
    /**
     * Notify all listeners of a charging state change.
     */
    public void notifyChargingStateChanged(ChargingStateData data) {
        for (VehicleDataListener listener : listeners) {
            try {
                listener.onChargingStateChanged(data);
            } catch (Exception e) {
                logger.error("Listener notification failed", e);
                // Continue with other listeners
            }
        }
    }
    
    /**
     * Notify all listeners of a charging power change.
     */
    public void notifyChargingPowerChanged(double powerKW) {
        for (VehicleDataListener listener : listeners) {
            try {
                listener.onChargingPowerChanged(powerKW);
            } catch (Exception e) {
                logger.error("Listener notification failed", e);
                // Continue with other listeners
            }
        }
    }
    
    /**
     * Notify all listeners that a monitor is unavailable.
     */
    public void notifyDataUnavailable(String monitorName, String reason) {
        for (VehicleDataListener listener : listeners) {
            try {
                listener.onDataUnavailable(monitorName, reason);
            } catch (Exception e) {
                logger.error("Listener notification failed", e);
                // Continue with other listeners
            }
        }
    }
}
