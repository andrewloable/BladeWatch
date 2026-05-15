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
     * Charging state derivation — hybrid approach.
     *
     * Two layers, evaluated in order:
     *
     *   Layer 1 (primary): trust the BYD ChargingDevice SDK directly.
     *     If vd.chargingState == 1 (CHARGING), declare CHARGING. The BMS knows
     *     when current is flowing into the pack better than anything else.
     *
     *   Layer 2 (fallback): inference, only when Layer 1 is silent.
     *     Some PHEV firmwares (1) leave chargingGunState as UNAVAILABLE and
     *     (2) never fire onBatteryManagementDeviceStateChanged for AC charging,
     *     so vd.chargingState stays at 15 (IDLE) while the pack is actually
     *     charging. In that case, infer charging from:
     *         gear=P AND gun-not-definitely-disconnected
     *         AND (engine power flowing into battery OR external/device power > 0)
     *     This requires positive evidence of energy flow — it cannot trigger
     *     from BMS-state alone and cannot be confused with regen (gear=P guard).
     *
     * Power magnitude resolution (independent of which layer detected charging):
     *   1. external charging power (InstrumentDevice — real charger-reported)
     *   2. chargingDevice.chargingPower  (often 0 on BYD HAL but free to try)
     *   3. abs(engine power)             (truthful when ACC is on)
     *   4. nominal-capacity hint         (3.3 kW PHEV / 7 kW BEV, marked estimated)
     *
     * @return ChargingStateData populated from whichever layer fired, or null
     *         if the chargingDevice is silent and no inference signal is present.
     */
    public ChargingStateData getChargingState() {
        BydVehicleData vd = getVd();
        if (vd == null) return null;

        // ---- Layer 1: BMS-direct ----
        boolean bmsSaysCharging =
            (vd.chargingState == ChargingStateData.CHARGING_BATTERY_STATE_CHARGING);

        // ---- Layer 2: inference (only when BMS is silent OR stuck at the
        //                          known-buggy IDLE-while-charging PHEV reading) ----
        // If the BMS is reporting a SPECIFIC non-charging state (READY/FINISHED/
        // DISCHARGING/error) we trust it and skip inference — those states are
        // explicit signals and inference would only produce false positives from
        // sticky power readings left over after unplug.
        boolean bmsAmbiguous =
            (vd.chargingState == BydVehicleData.UNAVAILABLE)
            || (vd.chargingState == ChargingStateData.CHARGING_BATTERY_STATE_IDLE);

        // gear from authoritative GearMonitor — getCurrentGear() returns the
        // cached value even after the monitor stops on ACC OFF, which is the
        // last gear the driver was in (always P when key is removed).
        int gearNow;
        try {
            com.overdrive.app.monitor.GearMonitor gm =
                com.overdrive.app.monitor.GearMonitor.getInstance();
            gearNow = gm.getCurrentGear();
        } catch (Exception e) {
            gearNow = (vd.gearMode != BydVehicleData.UNAVAILABLE)
                ? vd.gearMode
                : com.overdrive.app.monitor.GearMonitor.GEAR_P;
        }
        boolean inPark = (gearNow == com.overdrive.app.monitor.GearMonitor.GEAR_P);
        boolean gunDefinitelyDisconnected = (vd.chargingGunState == 1);

        // -0.3 kW deadband: below this magnitude engine-power sign is sensor noise.
        // enginePowerKw is only refreshed while ACC is on (BydDataCollector gates
        // collectEngine on accIsOn) so during ACC OFF this value is stale. We
        // intentionally don't filter on staleness here because the gear-in-P
        // guard plus the gun-not-disconnected guard already prevent it from
        // false-triggering — the only way it matters is when the car is
        // actually parked and plugged in.
        boolean engineFlowingIntoBattery =
            !Double.isNaN(vd.enginePowerKw) && vd.enginePowerKw < -0.3;
        boolean externalPowerActive =
            !Double.isNaN(vd.externalChargingPowerKw) && vd.externalChargingPowerKw > 0.15;
        boolean devicePowerActive =
            !Double.isNaN(vd.chargingPowerKw) && Math.abs(vd.chargingPowerKw) > 0.15;
        boolean anyPowerEvidence =
            engineFlowingIntoBattery || externalPowerActive || devicePowerActive;

        boolean inferredCharging = !bmsSaysCharging
            && bmsAmbiguous
            && inPark
            && !gunDefinitelyDisconnected
            && anyPowerEvidence;

        boolean isCharging = bmsSaysCharging || inferredCharging;

        // Decide effective state code.
        int effectiveState;
        if (isCharging) {
            effectiveState = ChargingStateData.CHARGING_BATTERY_STATE_CHARGING;
        } else if (vd.chargingState != BydVehicleData.UNAVAILABLE) {
            // Pass through whatever the BMS reports (READY, FINISHED, IDLE, error...)
            effectiveState = vd.chargingState;
        } else {
            // No BMS state and no inference signal — caller has nothing to show.
            return null;
        }

        ChargingStateData data = new ChargingStateData(effectiveState);

        // ---- Power magnitude ----
        // Only fill when we believe we're charging. For non-charging states,
        // ChargingStateData defaults power to 0 which is correct.
        if (effectiveState == ChargingStateData.CHARGING_BATTERY_STATE_CHARGING) {
            // Priority order:
            //   1. externalChargingPowerKw — charger-reported (matches AC wall power on PHEVs)
            //   2. chargingPowerKw — BMS-reported battery-side (broken on most BYDs)
            //   3. |enginePowerKw| — fallback when ACC is on
            //   4. nominal-capacity hint (estimated)
            if (!Double.isNaN(vd.externalChargingPowerKw) && vd.externalChargingPowerKw > 0) {
                data.updateChargingPower(vd.externalChargingPowerKw);
            } else if (!Double.isNaN(vd.chargingPowerKw) && vd.chargingPowerKw > 0) {
                data.updateChargingPower(vd.chargingPowerKw);
            } else if (engineFlowingIntoBattery) {
                // Use absolute value: enginePower is negative when flowing in.
                data.updateChargingPower(Math.abs(vd.enginePowerKw));
            } else {
                // BMS or inference says CHARGING but no real kW signal arrived.
                // Common on PHEVs where the SDK delivers state but never the kW.
                // Show a nominal-based hint so the UI doesn't say "Charging at 0 kW".
                try {
                    com.overdrive.app.abrp.SohEstimator soh =
                        com.overdrive.app.monitor.SocHistoryDatabase.getInstance().getSohEstimator();
                    if (soh != null && soh.getNominalCapacityKwh() > 0) {
                        double nominal = soh.getNominalCapacityKwh();
                        if (nominal < 30) {
                            // PHEV: typical AC charge rate is 3.3 kW (single phase)
                            data.updateChargingPower(3.3);
                        } else {
                            // BEV: typical AC charge rate is 7 kW
                            data.updateChargingPower(7.0);
                        }
                        data.isEstimated = true;
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
