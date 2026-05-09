package com.overdrive.app.monitor;

import android.content.Context;

import com.overdrive.app.byd.BydDataCollector;
import com.overdrive.app.byd.BydVehicleData;
import com.overdrive.app.logging.DaemonLogger;

import org.json.JSONObject;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;

/**
 * Singleton coordinator for BYD vehicle data.
 * 
 * Phase 3: Thin wrapper around BydDataCollector.
 * All data reads delegate to the collector. Keeps the same API surface
 * so existing consumers (HttpServer, SurveillanceIpcServer, TripDetector, etc.)
 * don't need changes.
 * 
 * The BatteryPowerMonitor is kept for AccSentryDaemon's voltage-based MCU control
 * (it needs listener callbacks for real-time voltage changes).
 */
public class VehicleDataMonitor {
    
    private static final String TAG = "VehicleDataMonitor";
    private static final DaemonLogger logger = DaemonLogger.getInstance(TAG);
    
    private static VehicleDataMonitor instance;
    private static final Object lock = new Object();
    
    // Only BatteryPowerMonitor kept — AccSentryDaemon needs its listener for voltage-based MCU control
    private final BatteryPowerMonitor batteryPowerMonitor;
    
    private final CopyOnWriteArrayList<VehicleDataListener> listeners = new CopyOnWriteArrayList<>();
    private boolean isRunning = false;
    private Context context;
    
    private VehicleDataMonitor() {
        this.batteryPowerMonitor = new BatteryPowerMonitor();
    }
    
    public static VehicleDataMonitor getInstance() {
        if (instance == null) {
            synchronized (lock) {
                if (instance == null) instance = new VehicleDataMonitor();
            }
        }
        return instance;
    }

    // ==================== LIFECYCLE ====================
    
    public void init(Context context) {
        this.context = context;
        logger.info("Initializing VehicleDataMonitor (BydDataCollector mode)");
        
        // Only init battery power monitor (for AccSentryDaemon voltage listener)
        try {
            batteryPowerMonitor.init(context);
        } catch (Exception e) {
            logger.error("Failed to init BatteryPowerMonitor", e);
        }
        
        logger.info("Initialization complete (data from BydDataCollector)");
    }
    
    public void initBatteryPowerOnly(Context context) {
        this.context = context;
        try {
            batteryPowerMonitor.init(context);
        } catch (Exception e) {
            logger.error("Failed to init BatteryPowerMonitor", e);
        }
    }
    
    public synchronized void start() {
        if (isRunning) return;
        try { batteryPowerMonitor.start(); } catch (Exception e) { logger.error("BatteryPowerMonitor start failed", e); }
        isRunning = true;
        logger.info("VehicleDataMonitor started");
    }
    
    public synchronized void startBatteryPowerOnly() {
        if (isRunning) return;
        try { batteryPowerMonitor.start(); } catch (Exception e) { logger.error("BatteryPowerMonitor start failed", e); }
        isRunning = true;
    }
    
    public synchronized void stop() {
        if (!isRunning) return;
        try { batteryPowerMonitor.stop(); } catch (Exception ignored) {}
        isRunning = false;
        logger.info("VehicleDataMonitor stopped");
    }
    
    public synchronized void stopBatteryPowerOnly() {
        if (!isRunning) return;
        try { batteryPowerMonitor.stop(); } catch (Exception ignored) {}
        isRunning = false;
    }
    
    public boolean isRunning() { return isRunning; }
    
    // ==================== DATA ACCESS (delegates to BydDataCollector) ====================
    
    public BydVehicleData getVd() {
        try {
            BydDataCollector c = BydDataCollector.getInstance();
            if (!c.isInitialized() && context != null) {
                // BydDataCollector not yet initialized — init it now
                // This handles the race where VehicleDataMonitor is queried
                // before CameraDaemon finishes BydDataCollector.init()
                logger.info("BydDataCollector not initialized — initializing from VehicleDataMonitor");
                c.init(context);
            }
            return c.isInitialized() ? c.getData() : null;
        } catch (Exception e) { return null; }
    }
    
    public BatteryVoltageData getBatteryVoltage() {
        BydVehicleData vd = getVd();
        if (vd != null && vd.voltageLevelRaw != BydVehicleData.UNAVAILABLE) {
            return new BatteryVoltageData(vd.voltageLevelRaw);
        }
        return null;
    }
    
    public BatteryPowerData getBatteryPower() {
        // Try collector first, fallback to monitor (for AccSentryDaemon compatibility)
        BydVehicleData vd = getVd();
        if (vd != null && !Double.isNaN(vd.voltage12v)) {
            return new BatteryPowerData(vd.voltage12v);
        }
        return batteryPowerMonitor.getCurrentValue();
    }
    
    public BatterySocData getBatterySoc() {
        BydVehicleData vd = getVd();
        if (vd != null && !Double.isNaN(vd.socPercent)) {
            return new BatterySocData(vd.socPercent);
        }
        return null;
    }
    
    /**
     * Charging state derivation — single source of truth.
     *
     * Approach: net HV-bus power (engine power) is the canonical charging signal.
     *   - Negative engine power = energy flowing INTO the battery
     *     (regen while driving, plug-in charging while parked)
     *   - Positive engine power = motor draw (or zero/idle)
     *
     * To distinguish plug-in charging from regen, we require the gear to be in P.
     * To exclude ICE-only generator-mode "self-charging" on PHEVs, we additionally
     * require the charging gun to be physically connected.
     *
     * This avoids the BMS-state catch-22 entirely: BMS state can lag the gun
     * connection by several seconds and report 0/15 while charging on PHEVs;
     * engine power flips negative the instant current draws.
     *
     * @return ChargingStateData with status set to CHARGING, READY, or null if no
     *         charging-related data is available at all.
     */
    public ChargingStateData getChargingState() {
        BydVehicleData vd = getVd();
        if (vd == null) return null;

        // Threshold: -0.3 kW deadband to absorb sensor noise on a still vehicle.
        // Below this magnitude, we don't trust the sign of engine power.
        final double CHARGING_POWER_THRESHOLD_KW = 0.3;

        // Source 1: gear from authoritative GearMonitor (matches RecordingModeManager).
        // Falls back to vd.gearMode if monitor isn't running.
        int gearNow;
        try {
            com.overdrive.app.monitor.GearMonitor gm =
                com.overdrive.app.monitor.GearMonitor.getInstance();
            gearNow = gm.isRunning() ? gm.getCurrentGear()
                : (vd.gearMode != BydVehicleData.UNAVAILABLE ? vd.gearMode : com.overdrive.app.monitor.GearMonitor.GEAR_P);
        } catch (Exception e) {
            gearNow = (vd.gearMode != BydVehicleData.UNAVAILABLE) ? vd.gearMode : com.overdrive.app.monitor.GearMonitor.GEAR_P;
        }
        boolean inPark = (gearNow == com.overdrive.app.monitor.GearMonitor.GEAR_P);

        // Source 2: net engine power (negative = into battery).
        double enginePowerKw = vd.enginePowerKw;
        boolean enginePowerKnown = !Double.isNaN(enginePowerKw);
        boolean engineFlowingIntoBattery = enginePowerKnown && enginePowerKw < -CHARGING_POWER_THRESHOLD_KW;

        // Source 3: gun connection (filters out ICE-only generator self-charging).
        // Tri-state: explicitly connected, explicitly disconnected, or unknown.
        // Many PHEV firmwares leave chargingGunState as UNAVAILABLE (-1) entirely;
        // we cannot treat unknown as "disconnected" or PHEVs never report charging.
        boolean gunConnected = (vd.chargingGunState == 2 || vd.chargingGunState == 3
                || vd.chargingGunState == 4 || vd.chargingGunState == 5);
        boolean gunUnknown = (vd.chargingGunState == BydVehicleData.UNAVAILABLE);
        boolean gunDisconnected = (vd.chargingGunState == 1);

        // Source 4: external charging power from the charger/instrument side.
        // This catches trickle charges below the engine-power deadband — small
        // AC chargers can deliver 0.1-0.3 kW that engine-power sensor noise
        // would mask, but the instrument cluster reports faithfully.
        double extChargingPower = !Double.isNaN(vd.externalChargingPowerKw) ? vd.externalChargingPowerKw : 0;
        boolean externalChargerActive = extChargingPower > 0.15;

        // Source 5: chargingDevice power (typed listener delivers it directly).
        // On PHEV firmwares where gunState is UNAVAILABLE, this is often the only
        // proof of charging activity until the BMS state finally flips to 1.
        double devChargingPower = !Double.isNaN(vd.chargingPowerKw) ? Math.abs(vd.chargingPowerKw) : 0;
        boolean devicePowerActive = devChargingPower > 0.15;

        // BMS may explicitly report CHARGING (state 1). Trust that even if gun
        // state and engine power haven't agreed yet — the BMS knows current is
        // flowing into the pack.
        boolean bmsSaysCharging = vd.chargingState == ChargingStateData.CHARGING_BATTERY_STATE_CHARGING;

        // Plug-in charging detection. Either:
        //   - engine power flowing into battery (works on BEV + PHEV when ACC is on), OR
        //   - any positive charger-side power signal AND gun is at least not
        //     definitely-disconnected (handles PHEVs reporting gun=UNAVAILABLE).
        boolean isPlugInCharging = engineFlowingIntoBattery
                || ((externalChargerActive || devicePowerActive) && !gunDisconnected)
                || (bmsSaysCharging && !gunDisconnected);

        // Treat "gun present" loosely when other evidence shows charging activity.
        // Required only to suppress the false "ICE generator self-charge" classification.
        boolean gunPresentEnough = gunConnected
                || (gunUnknown && (externalChargerActive || devicePowerActive || bmsSaysCharging));

        // Final verdict.
        int effectiveState;
        if (inPark && isPlugInCharging && gunPresentEnough) {
            effectiveState = ChargingStateData.CHARGING_BATTERY_STATE_CHARGING;     // 1
        } else if (inPark && gunConnected) {
            effectiveState = ChargingStateData.CHARGING_BATTERY_STATE_READY;        // 0
        } else if (inPark) {
            effectiveState = ChargingStateData.CHARGING_BATTERY_STATE_IDLE;         // 15
        } else {
            // Driving / not in park — never report charging here. Regen is not charging.
            // If the BMS or HAL has its own state for the dashboard, surface it; else
            // return null so callers don't display anything misleading.
            if (vd.chargingState != BydVehicleData.UNAVAILABLE) {
                // Map BMS "charging" while driving → READY (we don't trust it without P)
                int raw = vd.chargingState;
                effectiveState = (raw == ChargingStateData.CHARGING_BATTERY_STATE_CHARGING)
                    ? ChargingStateData.CHARGING_BATTERY_STATE_READY : raw;
            } else {
                return null;
            }
        }

        ChargingStateData data = new ChargingStateData(effectiveState);

        // Power magnitude — only meaningful when we believe we're charging.
        if (effectiveState == ChargingStateData.CHARGING_BATTERY_STATE_CHARGING) {
            // Priority order:
            //   1. Engine power magnitude (truthful, fast — flips with current).
            //   2. External charging power (instrument-side, includes OBC/wall losses).
            //   3. ChargingDevice reported power (often broken on BYD HAL — last resort).
            //   4. SoC change-rate estimate via nominal capacity (only if all else fails).
            double resolved = 0;
            if (engineFlowingIntoBattery) {
                resolved = Math.abs(enginePowerKw);
            } else if (!Double.isNaN(vd.externalChargingPowerKw) && vd.externalChargingPowerKw > 0) {
                resolved = vd.externalChargingPowerKw;
            } else if (!Double.isNaN(vd.chargingPowerKw) && vd.chargingPowerKw > 0) {
                resolved = vd.chargingPowerKw;
            }

            if (resolved > 0) {
                data.updateChargingPower(resolved);
            } else {
                // SoC-rate fallback: estimate kW from %/hour × nominal kWh.
                try {
                    com.overdrive.app.abrp.SohEstimator soh =
                        com.overdrive.app.monitor.SocHistoryDatabase.getInstance().getSohEstimator();
                    if (soh != null && soh.getNominalCapacityKwh() > 0) {
                        double nominal = soh.getNominalCapacityKwh();
                        double ratePerHour = com.overdrive.app.monitor.SocHistoryDatabase.getInstance()
                            .getSocChangeRatePerHour();
                        if (ratePerHour > 0.5) {
                            double estimated = (ratePerHour / 100.0) * nominal;
                            estimated = Math.max(0.5, Math.min(150, estimated));
                            data.updateChargingPower(estimated);
                            data.isEstimated = true;
                        }
                    }
                } catch (Exception ignored) { /* leave power at 0 */ }
            }
        }
        return data;
    }
    
    public DrivingRangeData getDrivingRange() {
        BydVehicleData vd = getVd();
        if (vd != null && vd.elecRangeKm != BydVehicleData.UNAVAILABLE) {
            return new DrivingRangeData(
                vd.elecRangeKm,
                vd.fuelRangeKm != BydVehicleData.UNAVAILABLE ? vd.fuelRangeKm : 0,
                vd.fuelPercent  // NaN on BEVs (BydDataCollector only sets it on PHEVs)
            );
        }
        return null;
    }
    
    public BatteryThermalData getBatteryThermal() {
        BydVehicleData vd = getVd();
        if (vd != null) {
            double hi = vd.highCellTempC;
            double lo = vd.lowCellTempC;
            double avg = vd.avgCellTempC;
            if (!Double.isNaN(hi) || !Double.isNaN(lo) || !Double.isNaN(avg)) {
                return new BatteryThermalData(hi, lo, avg, System.currentTimeMillis());
            }
        }
        return null;
    }
    
    public double getBatteryRemainPowerKwh() {
        BydVehicleData vd = getVd();
        if (vd == null) return 0.0;

        double soc = Double.isNaN(vd.socPercent) ? 0 : vd.socPercent;
        double rawKwh = Double.isNaN(vd.remainKwh) ? 0 : vd.remainKwh;

        try {
            com.overdrive.app.abrp.SohEstimator soh =
                com.overdrive.app.monitor.SocHistoryDatabase.getInstance().getSohEstimator();
            if (soh != null && soh.getNominalCapacityKwh() > 0 && soc > 0) {
                double nominal = soh.getNominalCapacityKwh();
                double sohPercent = soh.hasEstimate() ? soh.getCurrentSoh() : 100.0;
                double computedKwh = (soc / 100.0) * nominal * (sohPercent / 100.0);
                
                // Validate raw BMS value: if implied capacity is wildly off from nominal,
                // the BMS is returning garbage (common on Seal, Han EV when ACC is off).
                // Use computed value instead.
                if (rawKwh > 0 && soc > 5) {
                    double impliedCap = rawKwh / (soc / 100.0);
                    double ratio = impliedCap / nominal;
                    if (ratio < 0.5 || ratio > 1.5) {
                        // Raw value is garbage — use computed
                        return computedKwh;
                    }
                }
                
                boolean isPhev = nominal < 30.0;
                if (isPhev) {
                    return computedKwh;
                }
                // BEV with valid raw value: use it
                if (rawKwh > 0) return rawKwh;
                // BEV with no raw value: use computed
                return computedKwh;
            }
        } catch (Exception e) { /* fall through to raw */ }

        // SohEstimator not ready: use raw BMS value if available
        if (rawKwh > 0) return rawKwh;

        return 0.0;
    }
    
    public JSONObject getAllData() {
        JSONObject json = new JSONObject();
        BydVehicleData vd = getVd();
        
        try {
            // Battery voltage (old format for BatteryMonitor compatibility)
            if (vd != null && vd.voltageLevelRaw != BydVehicleData.UNAVAILABLE) {
                JSONObject bvJson = new JSONObject();
                bvJson.put("level", vd.voltageLevelRaw);
                bvJson.put("levelName", vd.voltageLevelRaw == 1 ? "NORMAL" : vd.voltageLevelRaw == 0 ? "LOW" : "INVALID");
                json.put("batteryVoltage", bvJson);
            }
            
            // Battery power (old format)
            if (vd != null && !Double.isNaN(vd.voltage12v)) {
                JSONObject bpJson = new JSONObject();
                bpJson.put("voltageVolts", vd.voltage12v);
                bpJson.put("isWarning", vd.voltage12v < 11.5);
                bpJson.put("isCritical", vd.voltage12v < 10.5);
                bpJson.put("healthStatus", vd.voltage12v < 10.5 ? "CRITICAL" : vd.voltage12v < 11.5 ? "WARNING" : "NORMAL");
                json.put("batteryPower", bpJson);
            }
            
            // Battery SOC (old format)
            if (vd != null && !Double.isNaN(vd.socPercent)) {
                JSONObject bsJson = new JSONObject();
                bsJson.put("socPercent", vd.socPercent);
                bsJson.put("isLow", vd.socPercent < 20);
                bsJson.put("isCritical", vd.socPercent < 10);
                json.put("batterySoc", bsJson);
            }
            
            // Charging state — single source of truth via getChargingState()
            // so this JSON dump matches what SOC graph / ABRP / MQTT see. The
            // raw BMS field (vd.chargingState) is no longer surfaced standalone
            // because it's known to lag and to misreport on PHEVs.
            ChargingStateData cs = getChargingState();
            if (cs != null) {
                JSONObject csJson = new JSONObject();
                csJson.put("stateCode", cs.stateCode);
                csJson.put("stateName", cs.stateName);
                csJson.put("status", cs.status.name());
                csJson.put("isError", cs.isError);
                csJson.put("chargingPowerKW", cs.chargingPowerKW);
                csJson.put("isDischarging", cs.isDischarging);
                csJson.put("isEstimated", cs.isEstimated);
                json.put("chargingState", csJson);
            }
            
            // Driving range (old format)
            if (vd != null && vd.elecRangeKm != BydVehicleData.UNAVAILABLE) {
                JSONObject drJson = new JSONObject();
                drJson.put("elecRangeKm", vd.elecRangeKm);
                drJson.put("fuelRangeKm", vd.fuelRangeKm != BydVehicleData.UNAVAILABLE ? vd.fuelRangeKm : 0);
                drJson.put("totalRangeKm", vd.elecRangeKm + (vd.fuelRangeKm != BydVehicleData.UNAVAILABLE ? vd.fuelRangeKm : 0));
                json.put("drivingRange", drJson);
            }
            
            // Battery thermal (old format)
            if (vd != null && (!Double.isNaN(vd.highCellTempC) || !Double.isNaN(vd.avgCellTempC))) {
                JSONObject btJson = new JSONObject();
                if (!Double.isNaN(vd.highCellTempC)) btJson.put("highestTempC", vd.highCellTempC);
                if (!Double.isNaN(vd.lowCellTempC)) btJson.put("lowestTempC", vd.lowCellTempC);
                if (!Double.isNaN(vd.avgCellTempC)) btJson.put("averageTempC", vd.avgCellTempC);
                json.put("batteryThermal", btJson);
            }
            
            json.put("timestamp", System.currentTimeMillis());
        } catch (Exception e) {
            logger.error("Failed to create JSON", e);
        }
        
        return json;
    }
    
    public Map<String, Boolean> getAvailability() {
        Map<String, Boolean> availability = new HashMap<>();
        BydDataCollector c = BydDataCollector.getInstance();
        boolean ready = c.isInitialized();
        availability.put("batteryVoltage", ready);
        availability.put("batteryPower", ready || batteryPowerMonitor.isAvailable());
        availability.put("batterySoc", ready);
        availability.put("chargingState", ready);
        availability.put("drivingRange", ready);
        availability.put("batteryThermal", ready);
        return availability;
    }
    
    // ==================== MONITOR ACCESS (kept for backward compat) ====================
    
    public BatteryPowerMonitor getBatteryPowerMonitor() { return batteryPowerMonitor; }
    
    // These return null now — consumers should use the data access methods above
    public BatteryVoltageMonitor getBatteryVoltageMonitor() { return null; }
    public DrivingRangeMonitor getDrivingRangeMonitor() { return null; }
    
    // ==================== LISTENER MANAGEMENT ====================
    
    public void addListener(VehicleDataListener listener) {
        if (listener != null && !listeners.contains(listener)) {
            listeners.add(listener);
        }
    }
    
    public void removeListener(VehicleDataListener listener) {
        if (listener != null) listeners.remove(listener);
    }
    
    public void notifyBatteryVoltageChanged(BatteryVoltageData data) {
        for (VehicleDataListener l : listeners) { try { l.onBatteryVoltageChanged(data); } catch (Exception ignored) {} }
    }
    
    public void notifyBatteryPowerChanged(BatteryPowerData data) {
        for (VehicleDataListener l : listeners) { try { l.onBatteryPowerChanged(data); } catch (Exception ignored) {} }
    }
    
    public void notifyChargingStateChanged(ChargingStateData data) {
        for (VehicleDataListener l : listeners) { try { l.onChargingStateChanged(data); } catch (Exception ignored) {} }
    }
    
    public void notifyChargingPowerChanged(double powerKW) {
        for (VehicleDataListener l : listeners) { try { l.onChargingPowerChanged(powerKW); } catch (Exception ignored) {} }
    }
    
    public void notifyDataUnavailable(String monitorName, String reason) {
        for (VehicleDataListener l : listeners) { try { l.onDataUnavailable(monitorName, reason); } catch (Exception ignored) {} }
    }
}
