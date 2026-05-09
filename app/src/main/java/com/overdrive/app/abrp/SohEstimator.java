package com.overdrive.app.abrp;

import com.overdrive.app.byd.BydVehicleData;
import com.overdrive.app.logging.DaemonLogger;
import com.overdrive.app.monitor.BatterySocData;
import com.overdrive.app.monitor.VehicleDataMonitor;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.lang.reflect.Method;
import java.util.Properties;

/**
 * Estimates battery State of Health (SOH) for ABRP telemetry.
 *
 * Three detection methods for nominal capacity (priority order):
 * 1. BMS direct: BYDAutoBodyworkDevice.getBatteryCapacity() (Ah → KWh mapping)
 * 2. SOC heuristic: remainingKwh / SOC → match to nearest known BYD pack
 * 3. Model string: ro.product.model → mapCarTypeToCapacity()
 *
 * Rolling window primed on init to prevent jumps after reboot.
 */
public class SohEstimator {

    private static final String TAG = "SohEstimator";
    private static final DaemonLogger logger = DaemonLogger.getInstance(TAG);

    // Nominal capacity — 0 means "not detected yet". SOH estimation is blocked until
    // autoDetectCarModel() successfully identifies the pack size from the BYD SDK.
    // No hardcoded default — wrong nominal capacity produces wrong SOH.
    private double nominalCapacityKwh = 0;
    private static final String SOH_FILE = "/data/local/tmp/abrp_soh_estimate.properties";

    private static final String PROP_SOH_PERCENT = "soh_percent";
    private static final String PROP_ESTIMATION_METHOD = "estimation_method";
    private static final String PROP_LAST_UPDATED = "last_updated";
    private static final String PROP_SAMPLE_COUNT = "sample_count";
    private static final String PROP_NOMINAL_CAPACITY = "nominal_capacity_kwh";

    private static final String METHOD_INSTANTANEOUS = "instantaneous";
    private static final String METHOD_CALIBRATION = "calibration";

    private double currentSoh = -1;
    private String estimationMethod = METHOD_INSTANTANEOUS;
    private String sohSource = "instantaneous"; // "oem", "calibration", "capacity_ah", or "instantaneous"
    private int sampleCount = 0;

    // ==================== RAW SOURCE VALUES ====================
    // Track the latest raw reading from each source independently.
    // These are displayed on the UI so the user can see what each method reports.
    private double rawOemSoh = -1;
    private double rawCapacityAhSoh = -1;
    private double rawCalibrationSoh = -1;
    private double rawEnergySoh = -1;  // instantaneous / remaining-energy based

    // ==================== SOURCE SELECTION MODE ====================
    // "auto" = EMA blend (default), or user can pin to a specific source
    private String preferredSource = "auto";  // "auto", "oem", "capacity_ah", "calibration", "energy"
    private static final String PROP_PREFERRED_SOURCE = "preferred_source";

    public void setNominalCapacityKwh(double capacityKwh) {
        if (capacityKwh > 10 && capacityKwh < 200) {
            this.nominalCapacityKwh = capacityKwh;
            logger.info("Nominal capacity set to " + capacityKwh + " KWh");
            persistEstimate();  // Save immediately so it survives restarts
            
            // Trigger seed now that we have capacity — autoDetect may have
            // set this after the initial seedInitialEstimate call returned early
            if (!hasEstimate()) {
                seedInitialEstimate();
            }
        }
    }

    public double getNominalCapacityKwh() {
        return nominalCapacityKwh;
    }

    /**
     * Detect capacity from pack voltage (called by BydDataCollector on first HV voltage event).
     * 
     * IMPORTANT: This method only sets capacity if no capacity has been detected yet.
     * It does NOT override a previously detected capacity because pack voltage is unreliable
     * on some BYD models (e.g., Atto 3 reports 500V instead of expected 384V).
     * The SOC heuristic (remainKwh / SOC%) is more reliable and runs first in autoDetectCarModel().
     */
    public void autoDetectFromPackVoltage(double packVoltage, BydVehicleData vd) {
        if (packVoltage < 200 || packVoltage > 900) return;
        
        // Only use pack voltage if we haven't detected capacity yet via a more reliable method
        if (nominalCapacityKwh > 0) {
            logger.debug("Pack voltage " + String.format("%.1f", packVoltage) + 
                "V ignored — capacity already detected: " + nominalCapacityKwh + " kWh");
            return;
        }
        
        double cellVoltage = 3.2;
        int cellCount = (int) Math.round(packVoltage / cellVoltage);
        double capacity = mapCellCountToCapacity(cellCount);
        
        if (capacity > 0) {
            setNominalCapacityKwh(capacity);
            logger.info("Pack Voltage Capacity: " + capacity + " kWh (voltage=" +
                String.format("%.1f", packVoltage) + "V, nominal cellV=3.2V" +
                ", cells≈" + cellCount + "s)");
        } else {
            logger.debug("Pack voltage " + String.format("%.1f", packVoltage) + "V → " + 
                cellCount + " cells — no matching BYD pack");
        }
    }

    // ==================== AUTO-DETECT ====================

    /**
     * Detect nominal battery capacity from BYD SDK data.
     *
     * Priority order:
     * 1. SOC heuristic: remainKwh / SOC → snap to nearest known pack.
     *    Works on every vehicle that reports both values. At high SOC (>95%),
     *    remainKwh ≈ nominal capacity directly.
     * 2. Model string: ro.product.model → table lookup.
     * 3. BMS direct: getBatteryCapacity() Ah → mapAhToKwh() lookup.
     *    Fallback for vehicles where remainKwh isn't available.
     * 4. Pack voltage: derive cell count (least reliable).
     */

    /** True if v looks like a CAN/HAL "value unavailable" sentinel for an int field. */
    private static boolean isSentinelInt(int v) {
        return v == 255 || v == 254
            || v == 511 || v == 1023
            || v == 2046 || v == 2047
            || v == 4095
            || v == 65534 || v == 65535;
    }
    private static boolean isSentinelInt(Object o) {
        return (o instanceof Number) && isSentinelInt(((Number) o).intValue());
    }

    /** Render an exception for log: prefer message, fall back to class name so we never log "[]". */
    private static String describeException(Throwable e) {
        if (e == null) return "null";
        String msg = e.getMessage();
        if (msg != null && !msg.trim().isEmpty()) {
            return e.getClass().getSimpleName() + ": " + msg;
        }
        Throwable cause = e.getCause();
        if (cause != null && cause.getMessage() != null && !cause.getMessage().trim().isEmpty()) {
            return e.getClass().getSimpleName() + " (cause: "
                + cause.getClass().getSimpleName() + ": " + cause.getMessage() + ")";
        }
        return e.getClass().getSimpleName() + " (no message)";
    }

    private void dumpPhevDiagnostics(android.content.Context context) {
        try {
            logger.info("=== POWERTRAIN DIAGNOSTICS ===");

            // ro.product.model — head-unit model string
            try {
                String model = (String) Class.forName("android.os.SystemProperties")
                    .getMethod("get", String.class, String.class)
                    .invoke(null, "ro.product.model", "");
                logger.info("[diag] ro.product.model = \"" + model + "\"");
            } catch (Exception e) {
                logger.info("[diag] ro.product.model: failed (" + describeException(e) + ")");
            }

            if (context == null) {
                logger.info("[diag] context==null — skipping HAL probes");
                logger.info("=== POWERTRAIN DIAGNOSTICS END ===");
                return;
            }

            // BYDAutoEnergyDevice — getEnergyMode + getOperationMode.
            // NOTE: codes vary across firmware. 1==EV, 3==HEV is the common mapping
            // but NOT universal — observed BEV (Atto 3) returning 3 and PHEV
            // (Sealion 6 DM-i) returning 0. This signal alone is unreliable for
            // PHEV detection; we use it only as a hint.
            try {
                Class<?> energyCls = Class.forName("android.hardware.bydauto.energy.BYDAutoEnergyDevice");
                Object energyDev = energyCls.getMethod("getInstance", android.content.Context.class)
                    .invoke(null, context);
                if (energyDev != null) {
                    try {
                        Object em = energyCls.getMethod("getEnergyMode").invoke(energyDev);
                        String hint;
                        if (Integer.valueOf(1).equals(em)) hint = " (commonly EV — not authoritative)";
                        else if (Integer.valueOf(3).equals(em)) hint = " (commonly HEV — not authoritative; observed on BEV too)";
                        else hint = " (unknown code)";
                        logger.info("[diag] BYDAutoEnergyDevice.getEnergyMode = " + em + hint);
                    } catch (Exception e) {
                        logger.info("[diag] getEnergyMode failed: " + describeException(e));
                    }
                    try {
                        Object om = energyCls.getMethod("getOperationMode").invoke(energyDev);
                        logger.info("[diag] BYDAutoEnergyDevice.getOperationMode = " + om);
                    } catch (Exception e) {
                        logger.info("[diag] getOperationMode failed: " + describeException(e));
                    }
                } else {
                    logger.info("[diag] BYDAutoEnergyDevice getInstance returned null");
                }
            } catch (ClassNotFoundException e) {
                logger.info("[diag] BYDAutoEnergyDevice not on this firmware");
            } catch (Exception e) {
                logger.info("[diag] BYDAutoEnergyDevice probe failed: " + describeException(e));
            }

            // BYDAutoChargingDevice — Commander uses getChargingCapacity, we don't.
            // Probed values across different vehicles all read 0.0; treat as not useful.
            try {
                Class<?> chargingCls = Class.forName("android.hardware.bydauto.charging.BYDAutoChargingDevice");
                Object chargingDev = chargingCls.getMethod("getInstance", android.content.Context.class)
                    .invoke(null, context);
                if (chargingDev != null) {
                    try {
                        Object cc = chargingCls.getMethod("getChargingCapacity").invoke(chargingDev);
                        logger.info("[diag] BYDAutoChargingDevice.getChargingCapacity = " + cc
                            + " (not used — observed 0.0 on every probed vehicle)");
                    } catch (Exception e) {
                        logger.info("[diag] getChargingCapacity failed: " + describeException(e));
                    }
                    try {
                        Object ct = chargingCls.getMethod("getChargingType").invoke(chargingDev);
                        logger.info("[diag] BYDAutoChargingDevice.getChargingType = " + ct);
                    } catch (Exception e) {
                        logger.info("[diag] getChargingType failed: " + describeException(e));
                    }
                } else {
                    logger.info("[diag] BYDAutoChargingDevice getInstance returned null");
                }
            } catch (ClassNotFoundException e) {
                logger.info("[diag] BYDAutoChargingDevice not on this firmware");
            } catch (Exception e) {
                logger.info("[diag] BYDAutoChargingDevice probe failed: " + describeException(e));
            }

            // BYDAutoStatisticDevice — getFuelPercentageValue is the most reliable
            // PHEV signal IF you filter sentinels. BEVs return 255 (unavailable);
            // PHEVs return 0..100 actual fuel level. Same for getFuelDrivingRangeValue
            // (BEVs return 2046/2047, PHEVs return real km).
            try {
                Class<?> statCls = Class.forName("android.hardware.bydauto.statistic.BYDAutoStatisticDevice");
                Object statDev = statCls.getMethod("getInstance", android.content.Context.class)
                    .invoke(null, context);
                if (statDev != null) {
                    try {
                        Object fp = statCls.getMethod("getFuelPercentageValue").invoke(statDev);
                        String hint;
                        if (isSentinelInt(fp)) hint = " (sentinel — BEV / fuel unavailable)";
                        else if (fp instanceof Number) {
                            int v = ((Number) fp).intValue();
                            if (v >= 0 && v <= 100) hint = " (in 0..100 range — PHEV fuel level)";
                            else hint = " (out of expected 0..100 range — ignore)";
                        } else hint = "";
                        logger.info("[diag] BYDAutoStatisticDevice.getFuelPercentageValue = " + fp + hint);
                    } catch (Exception e) {
                        logger.info("[diag] getFuelPercentageValue failed: " + describeException(e));
                    }
                    try {
                        Object fr = statCls.getMethod("getFuelDrivingRangeValue").invoke(statDev);
                        String hint;
                        if (isSentinelInt(fr)) hint = " (sentinel — BEV / range unavailable)";
                        else if (fr instanceof Number) {
                            int v = ((Number) fr).intValue();
                            if (v > 0 && v < 1500) hint = " km (real PHEV fuel range)";
                            else hint = " (out of expected 0..1500 km range)";
                        } else hint = "";
                        logger.info("[diag] BYDAutoStatisticDevice.getFuelDrivingRangeValue = " + fr + hint);
                    } catch (Exception e) {
                        logger.info("[diag] getFuelDrivingRangeValue failed: " + describeException(e));
                    }
                    try {
                        Object sohi = statCls.getMethod("getStatisticBatteryHealthyIndex").invoke(statDev);
                        logger.info("[diag] BYDAutoStatisticDevice.getStatisticBatteryHealthyIndex = " + sohi);
                    } catch (Exception e) {
                        logger.info("[diag] getStatisticBatteryHealthyIndex failed: " + describeException(e));
                    }
                    try {
                        Object remPwr = statCls.getMethod("getRemainingBatteryPower").invoke(statDev);
                        logger.info("[diag] BYDAutoStatisticDevice.getRemainingBatteryPower = " + remPwr
                            + " (raw — divide by 10 if reported in 0.1 kWh units)");
                    } catch (Exception e) {
                        logger.info("[diag] getRemainingBatteryPower failed: " + describeException(e));
                    }
                } else {
                    logger.info("[diag] BYDAutoStatisticDevice getInstance returned null");
                }
            } catch (ClassNotFoundException e) {
                logger.info("[diag] BYDAutoStatisticDevice not on this firmware");
            } catch (Exception e) {
                logger.info("[diag] BYDAutoStatisticDevice probe failed: " + describeException(e));
            }

            // BYDAutoBodyworkDevice — getBatteryCapacity (we use this) + getBatteryPowerHEV
            try {
                Class<?> bodyCls = Class.forName("android.hardware.bydauto.bodywork.BYDAutoBodyworkDevice");
                Object bodyDev = bodyCls.getMethod("getInstance", android.content.Context.class)
                    .invoke(null, context);
                if (bodyDev != null) {
                    try {
                        Object cap = bodyCls.getMethod("getBatteryCapacity").invoke(bodyDev);
                        int rawCap = (cap instanceof Number) ? ((Number) cap).intValue() : -1;
                        String semHint;
                        if (isSentinelInt(rawCap)) semHint = " (sentinel — unavailable)";
                        else if (rawCap >= 50 && rawCap <= 350) semHint = " (likely Ah rating)";
                        else if (rawCap > 350 && rawCap < 60000) semHint = " (likely 0.1 kWh units → " + (rawCap / 10.0) + " kWh)";
                        else semHint = " (unknown semantics)";
                        logger.info("[diag] BYDAutoBodyworkDevice.getBatteryCapacity = " + cap + semHint);
                    } catch (Exception e) {
                        logger.info("[diag] getBatteryCapacity failed: " + describeException(e));
                    }
                    try {
                        Object hev = bodyCls.getMethod("getBatteryPowerHEV").invoke(bodyDev);
                        String hevHint;
                        if (hev instanceof Number) {
                            double v = ((Number) hev).doubleValue();
                            if (v == 65535.0 || v == 65534.0 || v == 255.0) hevHint = " (sentinel — unavailable)";
                            else hevHint = " (BEVs: kWh remaining; PHEVs: typically SOC%)";
                        } else hevHint = "";
                        logger.info("[diag] BYDAutoBodyworkDevice.getBatteryPowerHEV = " + hev + hevHint);
                    } catch (Exception e) {
                        logger.info("[diag] getBatteryPowerHEV failed: " + describeException(e));
                    }
                }
            } catch (ClassNotFoundException e) {
                logger.info("[diag] BYDAutoBodyworkDevice not on this firmware");
            } catch (Exception e) {
                logger.info("[diag] BYDAutoBodyworkDevice probe failed: " + describeException(e));
            }

            // BYDAutoPowerDevice — getBatteryRemainPowerEV (we use this)
            try {
                Class<?> pwrCls = Class.forName("android.hardware.bydauto.power.BYDAutoPowerDevice");
                Object pwrDev = pwrCls.getMethod("getInstance", android.content.Context.class)
                    .invoke(null, context);
                if (pwrDev != null) {
                    try {
                        Object rp = pwrCls.getMethod("getBatteryRemainPowerEV").invoke(pwrDev);
                        logger.info("[diag] BYDAutoPowerDevice.getBatteryRemainPowerEV = " + rp);
                    } catch (Exception e) {
                        logger.info("[diag] getBatteryRemainPowerEV failed: " + describeException(e));
                    }
                }
            } catch (ClassNotFoundException e) {
                logger.info("[diag] BYDAutoPowerDevice not on this firmware");
            } catch (Exception e) {
                logger.info("[diag] BYDAutoPowerDevice probe failed: " + describeException(e));
            }

            // Current snapshot context — what our internal pipeline already has
            try {
                VehicleDataMonitor vdm = VehicleDataMonitor.getInstance();
                BydVehicleData vd = vdm != null ? vdm.getVd() : null;
                BatterySocData socData = vdm != null ? vdm.getBatterySoc() : null;
                double remKwh = vdm != null ? vdm.getBatteryRemainPowerKwh() : 0;
                logger.info("[diag] internal: socPercent="
                    + (socData != null ? socData.socPercent : "null")
                    + ", getBatteryRemainPowerKwh=" + remKwh
                    + ", vd.remainKwh=" + (vd != null ? vd.remainKwh : "null")
                    + ", vd.hvPackVoltage=" + (vd != null ? vd.hvPackVoltage : "null")
                    + ", vd.fuelPercent=" + (vd != null ? vd.fuelPercent : "null")
                    + ", currentNominalKwh=" + nominalCapacityKwh);
            } catch (Exception e) {
                logger.info("[diag] internal snapshot probe failed: " + describeException(e));
            }

            logger.info("=== POWERTRAIN DIAGNOSTICS END ===");
        } catch (Throwable t) {
            // Diagnostic must never throw into the caller's flow
            logger.warn("dumpPhevDiagnostics: unexpected error: " + describeException(t));
        }
    }

    public void autoDetectCarModel(android.content.Context context) {
        // Diagnostic dump — read-only, no behaviour change. Logs HAL values that
        // are useful for diagnosing PHEV capacity-detection failures, including
        // sources we currently ignore (getChargingCapacity, getEnergyMode,
        // getFuelPercentage). Safe to leave on; runs once per autoDetect call.
        dumpPhevDiagnostics(context);

        // Priority order:
        // 1. SOC heuristic: remainKwh / SOC → snap to nearest known pack (most reliable auto-detect)
        // 2. Model string: ro.product.model → table lookup
        // 3. BMS direct: getBatteryCapacity() Ah → mapAhToKwh() (often returns 0xFFFF sentinel)
        // 4. Pack voltage: derive cell count (unreliable — some models report wrong voltage)
        // 5. Persisted capacity from previous successful detection

        // Method 1: SOC heuristic — most reliable auto-detection method.
        // Uses actual energy readings (remainKwh / SOC%) which are proven accurate.
        try {
            VehicleDataMonitor vdm = VehicleDataMonitor.getInstance();
            double remainingKwh = vdm.getBatteryRemainPowerKwh();
            BatterySocData socData = vdm.getBatterySoc();
            if (remainingKwh > 5 && socData != null && socData.socPercent > 20) {
                double estimatedCapacity = remainingKwh / (socData.socPercent / 100.0);
                // Detect BYD PHEV firmware bug: BMS returns SOC% value as kWh.
                // Widened threshold from 3.0 to 5.0 — on PHEVs the values can drift
                // slightly apart (e.g., SOC=53%, remainKwh=56) but still indicate the bug.
                // Also detect when remainKwh is impossibly large for a PHEV pack
                // (e.g., remainKwh=56 on an 18 kWh pack means it's clearly SOC-as-kWh).
                boolean likelyPhevKwhBug = Math.abs(remainingKwh - socData.socPercent) < 5.0;
                // Additional heuristic: if remainKwh > 40 but estimated capacity snaps to
                // a known small PHEV pack (<30 kWh), the BMS is lying about remainKwh.
                //
                // CAUTION: a 1:1 ratio also occurs naturally on ~100 kWh BEVs at any SOC
                // (e.g. Tang at 70% SOC: remain≈70 kWh, ratio=1.0). To avoid false-flagging
                // those as the PHEV firmware bug, only run the ratio check before any
                // nominal capacity has been detected — once we know the pack is, say,
                // 108.8 kWh nominal, we already have the answer.
                if (!likelyPhevKwhBug && remainingKwh > 40 && estimatedCapacity > 40
                        && nominalCapacityKwh <= 0) {
                    double socKwhRatio = remainingKwh / socData.socPercent;
                    if (socKwhRatio > 0.85 && socKwhRatio < 1.15) {
                        likelyPhevKwhBug = true;
                    }
                }
                if (likelyPhevKwhBug) {
                    logger.info("SOC heuristic skipped: remainKwh (" +
                        String.format("%.1f", remainingKwh) + ") ≈ socPercent (" +
                        String.format("%.1f", socData.socPercent) + ") — likely SOC-as-kWh firmware bug");
                } else if (nominalCapacityKwh > 0 && nominalCapacityKwh < 30 && estimatedCapacity > 40) {
                    // Already detected as a small PHEV pack via another method (BMS Ah, config, etc.)
                    // but SOC heuristic is computing a wildly different capacity — BMS remainKwh is lying
                    logger.info("SOC heuristic skipped: estimated " + String.format("%.1f", estimatedCapacity) +
                        " kWh but nominal already detected as " + String.format("%.1f", nominalCapacityKwh) +
                        " kWh — PHEV remainKwh unreliable");
                } else {
                    double matched = matchNearestCapacity(estimatedCapacity);
                    if (matched > 0) {
                        setNominalCapacityKwh(matched);
                        // Only show "matched to X" when the snap actually moved
                        // the value. SOC granularity is whole percent, so an
                        // estimate of 60.0 matching nominal 60.48 is *expected*
                        // rounding, not a discrepancy worth flagging.
                        double snapDelta = Math.abs(estimatedCapacity - matched);
                        boolean snapped = snapDelta > 0.5;
                        logger.info("SOC-derived nominal capacity: " + matched + " kWh"
                            + (snapped
                                ? " (estimated " + String.format("%.1f", estimatedCapacity)
                                  + " kWh, snapped to nearest known pack)"
                                : "")
                            + " [SOC=" + String.format("%.1f", socData.socPercent) + "%, remain="
                            + String.format("%.1f", remainingKwh) + " kWh]");
                        return;
                    }
                }
            }
        } catch (Exception e) {
            logger.debug("SOC heuristic failed: " + e.getMessage());
        }

        // Method 2: System property model string
        try {
            String carType = (String) Class.forName("android.os.SystemProperties")
                .getMethod("get", String.class, String.class)
                .invoke(null, "ro.product.model", "");
            if (carType != null && !carType.isEmpty()) {
                double mapped = mapCarTypeToCapacity(carType);
                if (mapped > 0) {
                    setNominalCapacityKwh(mapped);
                    logger.info("Model-Mapped Capacity (" + carType + "): " + mapped + " kWh");
                    return;
                }
            }
        } catch (Exception e) { /* ignore */ }

        // Method 3: BMS direct — getBatteryCapacity() Ah
        // WARNING: Often returns 0xFFFF (65535) sentinel on many BYD models.
        if (context != null) {
            try {
                Class<?> cls = Class.forName("android.hardware.bydauto.bodywork.BYDAutoBodyworkDevice");
                Object device = cls.getMethod("getInstance", android.content.Context.class).invoke(null, context);
                if (device != null) {
                    Method getBatteryCapacity = cls.getMethod("getBatteryCapacity");
                    Number capNum = (Number) getBatteryCapacity.invoke(device);
                    int capacityRaw = capNum != null ? capNum.intValue() : 0;
                    // Filter CAN bus sentinel values
                    if (capacityRaw > 0 && capacityRaw != 255 && capacityRaw != 65534 && capacityRaw != 65535) {
                        double capacityKwh = 0;
                        if (capacityRaw > 1000 && capacityRaw < 60000) {
                            capacityKwh = capacityRaw / 1000.0;
                        } else if (capacityRaw <= 1000) {
                            double fromAh = mapAhToKwh(capacityRaw);
                            if (fromAh > 0) {
                                capacityKwh = fromAh;
                            } else if (capacityRaw >= 10 && capacityRaw <= 350) {
                                capacityKwh = capacityRaw;
                            }
                        }
                        if (capacityKwh > 10 && capacityKwh < 150) {
                            setNominalCapacityKwh(capacityKwh);
                            logger.info("BMS Capacity: " + capacityKwh + " kWh (raw=" + capacityRaw + ")");
                            return;
                        }
                    }
                    if (capacityRaw == 65535 || capacityRaw == 65534 || capacityRaw == 255) {
                        logger.debug("BMS capacity returned sentinel value " + capacityRaw + " — skipping");
                    }
                }
            } catch (Exception e) {
                logger.debug("BMS capacity lookup failed: " + e.getMessage());
            }
        }

        // Method 4: Pack voltage → cell count (least reliable — some models report wrong voltage)
        try {
            VehicleDataMonitor vdm = VehicleDataMonitor.getInstance();
            BydVehicleData vd = vdm != null ? vdm.getVd() : null;
            if (vd != null && !Double.isNaN(vd.hvPackVoltage) && vd.hvPackVoltage > 200) {
                double voltage = vd.hvPackVoltage;
                double cellVoltage = 3.2;
                int cellCount = (int) Math.round(voltage / cellVoltage);
                double capacity = mapCellCountToCapacity(cellCount);
                if (capacity > 0) {
                    setNominalCapacityKwh(capacity);
                    logger.info("Pack Voltage Capacity: " + capacity + " kWh (voltage=" + 
                        String.format("%.1f", voltage) + "V, nominal cellV=3.2V" + 
                        ", cells≈" + cellCount + "s)");
                    return;
                }
            }
        } catch (Exception e) {
            logger.debug("Pack voltage capacity lookup failed: " + e.getMessage());
        }

        logger.warn("Capacity detection failed" + 
            (nominalCapacityKwh > 0 ? " — using previously saved capacity: " + nominalCapacityKwh + " kWh" 
                                    : " — SOH estimation disabled until capacity is identified"));
    }

    /**
     * Seed the initial SOH estimate immediately after capacity detection.
     * Called once after autoDetectCarModel() so the web UI has a value
     * before the first SocHistoryDatabase tick (2 min) or ABRP upload (5 sec).
     */
    public void seedInitialEstimate() {
        if (hasEstimate()) return;  // Already have an estimate from persisted file
        if (nominalCapacityKwh <= 0) return;  // Need capacity first

        try {
            VehicleDataMonitor vdm = VehicleDataMonitor.getInstance();
            double remainingKwh = vdm.getBatteryRemainPowerKwh();
            BatterySocData socData = vdm.getBatterySoc();
            if (socData == null || socData.socPercent <= 20 || socData.socPercent > 100) {
                // SOC too low/high or unavailable — fall through to 100% baseline below.
            } else {
                // PHEV firmware bug: BMS reports SOC% in the kWh field. Catch
                // the easy case (numerically equal) first.
                boolean isPhevKwhBug = Math.abs(remainingKwh - socData.socPercent) < 5.0;
                // Ratio sanity check is only useful BEFORE we know the pack
                // size — once nominalCapacityKwh is set, a pack near 100 kWh
                // legitimately produces a 1:1 SOC%/kWh ratio at any SOC.
                if (!isPhevKwhBug && remainingKwh > 0 && socData.socPercent > 0
                        && nominalCapacityKwh <= 0) {
                    double socKwhRatio = remainingKwh / socData.socPercent;
                    if (socKwhRatio > 0.85 && socKwhRatio < 1.15) {
                        isPhevKwhBug = true;
                    }
                }

                // Read the highest cell voltage so the chemistry-aware scale
                // can decide LFP vs NMC.
                double highCellV = Double.NaN;
                BydVehicleData vd = vdm.getVd();
                if (vd != null && !Double.isNaN(vd.highCellVoltage)) {
                    highCellV = vd.highCellVoltage;
                }

                // Boot-time seed is treated as "at rest" — the daemon usually
                // boots either while parked or right after ACC ON, before any
                // significant accessory load has stabilized. The data we use
                // here was sampled within seconds of construction and hasn't
                // had time to drift. updateFromEnergy still validates the
                // implied capacity is within 50–150% of nominal, so a stale
                // PHEV kWh field can't seed a wrong value.
                if (!isPhevKwhBug && remainingKwh > 0 && socData.socPercent <= 85) {
                    updateFromEnergy(remainingKwh, socData.socPercent, highCellV, /*atRest=*/true);
                }
            }

            // If energy seed didn't fire (PHEV bug, SOC out of range, etc.),
            // start at 100% — calibration / capacity-Ah will refine it.
            if (!hasEstimate()) {
                String why;
                if (socData == null) {
                    why = "no SOC data";
                } else if (socData.socPercent <= 20) {
                    why = "SOC " + String.format("%.0f", socData.socPercent) + "% below seed threshold";
                } else if (socData.socPercent > 85) {
                    why = "SOC " + String.format("%.0f", socData.socPercent) + "% above seed threshold";
                } else {
                    why = "energy reading unreliable";
                }
                logger.info("Seeding SOH at 100% baseline (" + why + ") — nominal="
                    + String.format("%.2f", nominalCapacityKwh) + " kWh");
                currentSoh = 100.0;
                sampleCount = 1;
                estimationMethod = METHOD_INSTANTANEOUS;
                persistEstimate();
            }
        } catch (Exception e) {
            logger.debug("Initial SOH seed failed: " + e.getMessage());
        }
    }

    // ==================== LIFECYCLE ====================

    public void init() {
        try {
            File sohFile = new File(SOH_FILE);
            if (!sohFile.exists()) return;

            Properties props = new Properties();
            try (FileInputStream fis = new FileInputStream(sohFile)) {
                props.load(fis);
            }

            String sohStr = props.getProperty(PROP_SOH_PERCENT);
            if (sohStr != null) {
                double persistedSoh = Double.parseDouble(sohStr);
                // Valid SOH is 60-110% (allow up to 110% for factory over-provisioned new packs).
                // Reject everything else to force re-estimation.
                if (persistedSoh >= 60 && persistedSoh <= 110) {
                    currentSoh = persistedSoh;
                    logger.info("Restored SOH: " + currentSoh + "%");
                } else {
                    logger.info("Discarding persisted SOH " + persistedSoh + " — out of valid range 60-110");
                    // Delete the file to prevent this warning on every restart
                    sohFile.delete();
                }
            }

            String method = props.getProperty(PROP_ESTIMATION_METHOD);
            if (method != null) estimationMethod = method;

            String countStr = props.getProperty(PROP_SAMPLE_COUNT);
            if (countStr != null) sampleCount = Integer.parseInt(countStr);

            // Restore preferred source selection
            String savedSource = props.getProperty(PROP_PREFERRED_SOURCE);
            if (savedSource != null && !savedSource.isEmpty()) {
                preferredSource = savedSource;
            }

            // Restore nominal capacity — this survives bad remainKwh readings
            // that would otherwise cause autoDetectCarModel to fail.
            String capStr = props.getProperty(PROP_NOMINAL_CAPACITY);
            if (capStr != null) {
                double savedCap = Double.parseDouble(capStr);
                if (savedCap > 10 && savedCap < 200 && nominalCapacityKwh <= 0) {
                    nominalCapacityKwh = savedCap;
                    logger.info("Restored nominal capacity: " + savedCap + " kWh");
                }
            }

            if (currentSoh > 0) {
                logger.info("SOH init complete: " + currentSoh + "% (samples: " + sampleCount + ")");
            }
        } catch (Exception e) {
            logger.error("Failed to load SOH: " + e.getMessage());
        }
    }

    // ==================== SOTA SOH UPDATES ====================

    /**
     * Chemistry-aware display→absolute SOC scale.
     *
     * The previous implementation hard-coded `displaySoc * 0.95 + 2.5`, which
     * is the NMC convention (hide ~2.5% at top and bottom for cycling
     * protection). BYD Blade is LFP, which has a flat voltage curve and
     * minimal hidden reserve — the displayed range is essentially the usable
     * range. Empirically, on Atto 3 with SOC=28% and remainKwh=16.8 kWh, the
     * implied capacity is exactly 60.0 kWh against a 60.48 kWh nameplate,
     * meaning display 0..100% ≈ usable 0..100%. Applying *0.95+2.5 here was
     * causing a ~4% phantom SOH degradation on a brand-new pack.
     *
     * The chemistry of every pack we know about (Atto 3, Seal, Han, Tang,
     * Dolphin, Sealion 6/7) is BYD Blade LFP, so we default to 1:1. The hook
     * is left in place so an NMC-equipped variant can be detected later (e.g.
     * by checking if cell.maxV > 3.7V, which LFP cells never reach).
     */
    private static double displayToAbsoluteSocScale(double highCellVoltage) {
        // LFP fully-charged cell V ≈ 3.40V, hot at 3.55V. NMC fully-charged
        // cell V ≈ 4.10–4.20V. If we see a high cell ≥ 3.75V, it's NMC.
        if (!Double.isNaN(highCellVoltage) && highCellVoltage >= 3.75) {
            return 0.95;  // NMC convention
        }
        return 1.0;       // LFP: display range == usable range
    }

    /** Apply scale to display SOC. Offset is intentionally 0 for LFP. */
    private static double scaleDisplaySoc(double displaySoc, double scale) {
        if (scale >= 0.999) return displaySoc;       // LFP: identity
        return displaySoc * scale + (1.0 - scale) / 2.0 * 100.0;  // NMC: hide reserve symmetrically
    }

    /**
     * Confidence-Weighted Exponential Moving Average (EMA).
     * Replaces the naive rolling window. Prevents volatile swings from noisy readings
     * while allowing high-confidence calibration data to shift the estimate quickly.
     *
     * @param newSohEstimate The new SOH value to incorporate
     * @param confidenceWeight How much this reading should influence the average (0.0 - 1.0)
     */
    private void applyWeightedSoh(double newSohEstimate, double confidenceWeight) {
        // Allow 60-110% to track factory over-provisioning degradation curve.
        // A brand-new BYD pack is typically 102-104% of rated nominal capacity.
        // Clamping to 100% would hide the first 2+ years of degradation.
        if (newSohEstimate < 60.0 || newSohEstimate > 110.0) return;

        if (currentSoh < 0) {
            // First estimate — accept directly
            currentSoh = newSohEstimate;
        } else {
            // EMA: current = (new * weight) + (current * (1 - weight))
            currentSoh = (newSohEstimate * confidenceWeight) + (currentSoh * (1.0 - confidenceWeight));
        }

        sampleCount++;
        persistEstimate();
    }

    /**
     * Compute and record an "energy-based" SOH from current SOC + remaining
     * kWh, BUT distinguish two cases via the rest-state hints:
     *
     *  - If atRest is true (parked, AC off, not charging, low cell spread)
     *    the reading is trustworthy enough to seed (when no estimate exists)
     *    and to update rawEnergySoh for display.
     *  - If atRest is false the reading is still computed for rawEnergySoh
     *    so the UI can show "live energy-based estimate," but is NEVER used
     *    to seed currentSoh and is NEVER fed into the EMA. Instantaneous
     *    discharge readings drift up to 5% with HVAC / accessory load and
     *    would otherwise pollute the active SOH.
     *
     * The chemistry-aware SOC scale fixes the long-standing ~4% phantom
     * degradation: BYD Blade is LFP and the displayed range is the usable
     * range, so display 0..100% maps to absolute 0..100% (not 2.5..97.5%).
     *
     * @param remainingKwh      Battery remaining energy from BMS (kWh)
     * @param displaySocPercent Display SOC from dashboard (0-100)
     * @param highCellVoltage   Highest cell voltage in V, or NaN. Used only
     *                          to detect chemistry (LFP vs NMC).
     * @param atRest            True if rest-state gates are satisfied. False
     *                          forces this reading into UI-only display
     *                          (rawEnergySoh) without affecting currentSoh.
     */
    public void updateFromEnergy(double remainingKwh, double displaySocPercent,
                                 double highCellVoltage, boolean atRest) {
        // Need nominal capacity to compute SOH — skip if not yet detected
        if (nominalCapacityKwh <= 0) return;

        if (displaySocPercent <= 5 || displaySocPercent > 100.0) return;
        if (remainingKwh <= 1.0) return;

        // Prefer mid-range SOC (20-85%) where BMS readings are most stable.
        if (displaySocPercent < 20 || displaySocPercent > 85) {
            return;
        }

        // Sanity check: implied capacity must be in a plausible range
        double impliedCapacity = remainingKwh / (displaySocPercent / 100.0);
        if (impliedCapacity < 10.0 || impliedCapacity > 120.0) {
            logger.debug("Energy SOH rejected: implied capacity "
                + String.format("%.1f", impliedCapacity) + " kWh outside BYD range (10-120)");
            return;
        }
        double ratio = impliedCapacity / nominalCapacityKwh;
        if (ratio < 0.5 || ratio > 1.5) {
            logger.debug("Energy SOH rejected: implied capacity "
                + String.format("%.1f", impliedCapacity) + " kWh is "
                + String.format("%.0f", ratio * 100) + "% of nominal "
                + String.format("%.2f", nominalCapacityKwh)
                + " kWh — likely bad remainKwh reading");
            return;
        }

        double scale = displayToAbsoluteSocScale(highCellVoltage);
        double absSoc = scaleDisplaySoc(displaySocPercent, scale);
        double currentTotalCap = remainingKwh / (absSoc / 100.0);
        double instantaneousSoh = (currentTotalCap / nominalCapacityKwh) * 100.0;

        if (instantaneousSoh < 60.0 || instantaneousSoh > 110.0) return;

        // Always track raw value for UI display
        rawEnergySoh = instantaneousSoh;

        // Driving / HVAC-on readings are noisy. Track them for display only.
        if (!atRest) {
            return;
        }

        // Rest-state reading is trustworthy. Seed if we don't have an estimate
        // yet; otherwise let calibration / capacity-Ah continue to dominate.
        if (hasEstimate()) return;

        currentSoh = instantaneousSoh;
        sampleCount = 1;
        estimationMethod = METHOD_INSTANTANEOUS;
        sohSource = "energy";
        persistEstimate();
        logger.info("SOH seeded from rest-state energy: "
            + String.format("%.1f", currentSoh) + "% (remain="
            + String.format("%.1f", remainingKwh) + " kWh, SOC="
            + String.format("%.1f", displaySocPercent) + "%, implied cap="
            + String.format("%.1f", impliedCapacity) + " kWh, scale="
            + String.format("%.2f", scale) + ")");
    }

    /**
     * Backward-compatible wrapper. Treats the reading as not-at-rest, so it
     * only updates the UI-facing rawEnergySoh and never seeds currentSoh.
     * Existing schedulers (AbrpTelemetryService, SocHistoryDatabase) call this
     * on every periodic tick — most of those ticks are mid-discharge and
     * shouldn't pollute the active estimate. Callers that have rest-state
     * info should call updateFromEnergy(...) directly.
     */
    public void updateFromInstantaneous(double remainingKwh, double displaySocPercent) {
        updateFromEnergy(remainingKwh, displaySocPercent, Double.NaN, /*atRest=*/false);
    }

    /**
     * SOTA: Update SOH from a charge calibration session.
     *
     * Only accepts slow AC charging at optimal battery temperatures.
     * DC Fast Charging introduces thermal loss and early voltage tapering,
     * making Coulomb-counting unreliable. Cold temperatures temporarily
     * reduce available chemical capacity, skewing SOH low.
     *
     * @param energyEnteredBatteryKwh Energy that entered the battery (after charging losses)
     * @param socDelta SOC change during charge session (Display SOC delta)
     * @param packTempCelsius Average battery temperature during the charge
     * @param isAcCharge True if using slow AC charging, False if DC Fast Charging
     */
    public void updateFromCalibration(double energyEnteredBatteryKwh, double socDelta,
                                      double packTempCelsius, boolean isAcCharge) {
        updateFromCalibration(energyEnteredBatteryKwh, socDelta, packTempCelsius, isAcCharge, Double.NaN);
    }

    /**
     * Same as the 4-arg form, plus the highest cell voltage observed during
     * the charge window. Used to pick the chemistry-aware display→absolute
     * scale (LFP = identity, NMC = 0.95).
     */
    public void updateFromCalibration(double energyEnteredBatteryKwh, double socDelta,
                                      double packTempCelsius, boolean isAcCharge,
                                      double highCellVoltage) {
        // Need nominal capacity to compute SOH
        if (nominalCapacityKwh <= 0) {
            logger.debug("Calibration rejected: nominal capacity not yet detected");
            return;
        }

        // 1. DC Fast Charging introduces thermal loss and early voltage tapering.
        //    It is not reliable for Coulomb-counting SOH.
        if (!isAcCharge) {
            logger.debug("Calibration rejected: DC Fast Charging is too volatile for accurate SOH math.");
            return;
        }

        // 2. Cold temperatures temporarily reduce available chemical capacity.
        //    Only accept calibration at optimal chemical temperatures (15°C to 35°C).
        if (packTempCelsius < 15.0 || packTempCelsius > 35.0) {
            logger.debug("Calibration rejected: Pack temperature (" +
                String.format("%.1f", packTempCelsius) + "°C) outside optimal SOH window (15-35°C).");
            return;
        }

        // 3. Reject shallow charges — LFP flat voltage curve makes them unreliable
        if (socDelta < 25.0) {
            logger.debug("Calibration rejected: SOC delta " + String.format("%.1f", socDelta) +
                "% < 25% minimum for LFP accuracy");
            return;
        }

        // Chemistry-aware scale. LFP (every BYD Blade pack we know about) =
        // 1.0 → display delta == absolute delta. NMC variants would use 0.95.
        // The previous unconditional 0.95 made every calibration ~5% optimistic,
        // pushing SOH > 100% on healthy packs and into the 110% rejection band.
        double scale = displayToAbsoluteSocScale(highCellVoltage);
        double absSocDelta = socDelta * scale;

        double actualCapacity = energyEnteredBatteryKwh / (absSocDelta / 100.0);
        double calibratedSoh = (actualCapacity / nominalCapacityKwh) * 100.0;

        if (calibratedSoh < 60.0 || calibratedSoh > 110.0) {
            logger.warn("Calibration SOH out of range: " + String.format("%.1f", calibratedSoh) + "% — rejected");
            return;
        }

        // Dynamic confidence weight based on charge delta size:
        // 25% delta → 0.15 weight (moderate confidence)
        // 50% delta → 0.30 weight (good confidence)
        // 75%+ delta → 0.50 weight (high confidence)
        double confidenceWeight = 0.15 + (((Math.min(socDelta, 75.0) - 25.0) / 50.0) * 0.35);

        applyWeightedSoh(calibratedSoh, confidenceWeight);
        rawCalibrationSoh = calibratedSoh;
        estimationMethod = METHOD_CALIBRATION;
        sohSource = "calibration";

        logger.info("Calibration SOH: " + String.format("%.1f", calibratedSoh) + "% " +
            "(weight=" + String.format("%.2f", confidenceWeight) + ", temp=" +
            String.format("%.1f", packTempCelsius) + "°C, scale=" +
            String.format("%.2f", scale) + ") " +
            "[" + String.format("%.1f", energyEnteredBatteryKwh) + " kWh / " +
            String.format("%.1f", socDelta) + "% display delta → " +
            String.format("%.1f", absSocDelta) + "% absolute]");
    }

    /**
     * Legacy overload for callers that don't have temperature/charge type info.
     * Assumes AC charging at optimal temperature (backward compatible).
     */
    public void updateFromCalibration(double energyEnteredBatteryKwh, double socDelta) {
        updateFromCalibration(energyEnteredBatteryKwh, socDelta, 25.0, true);
    }

    // ==================== CAPACITY-AH BASED SOH ====================

    /**
     * SOTA Method 3: Capacity-Based SOH from BMS-reported Ah vs nominal Ah.
     *
     * Formula:
     *   nominalCapacityAh = (batteryKwh × 1000) ÷ (cellCount × BYD_BLADE_REFERENCE_CELL_VOLTAGE)
     *   soh% = (bodyworkBatteryCapacityAh ÷ nominalCapacityAh) × 100
     *
     * This compares the BMS's current full-charge capacity (Ah) against the factory
     * nameplate capacity derived from the known pack kWh and cell configuration.
     * High confidence — the BMS tracks this via coulomb counting over the pack's lifetime.
     *
     * @param bodyworkBatteryCapacityAh Current full-charge capacity reported by BMS (Ah)
     * @param cellCount Number of series cells in the pack (derived from pack voltage)
     */
    private static final double BYD_BLADE_REFERENCE_CELL_VOLTAGE = 3.2; // LFP nominal voltage
    private double lastCapacityAhReading = -1; // Dedup: skip if same reading

    // "Stuck-at-nameplate" detector. Some firmwares return the static factory
    // Ah rating instead of a live coulomb-counted value, which would make the
    // capacity-Ah path always read 100% SOH. If we see the reported Ah within
    // ±0.5 of the derived nominal Ah for STUCK_AT_NAMEPLATE_TRIPS consecutive
    // readings, mark this BMS as not coulomb-counting and stop using the source.
    private int nameplateMatchCount = 0;
    private boolean capacityAhDisabled = false;
    private static final int STUCK_AT_NAMEPLATE_TRIPS = 5;
    private static final double STUCK_AT_NAMEPLATE_TOLERANCE_AH = 0.5;

    public void updateFromCapacityAh(double bodyworkBatteryCapacityAh, int cellCount) {
        if (nominalCapacityKwh <= 0) {
            logger.debug("Capacity-Ah SOH rejected: nominal capacity not yet detected");
            return;
        }
        if (capacityAhDisabled) {
            // Source already disqualified for this session — would always read 100%.
            return;
        }
        if (bodyworkBatteryCapacityAh <= 0 || cellCount <= 0) return;

        // Skip if same reading as last time (avoid log spam + redundant EMA updates)
        if (bodyworkBatteryCapacityAh == lastCapacityAhReading) return;
        lastCapacityAhReading = bodyworkBatteryCapacityAh;

        // Derive what the factory Ah should be from the known kWh pack size
        double nominalCapacityAh = (nominalCapacityKwh * 1000.0)
            / (cellCount * BYD_BLADE_REFERENCE_CELL_VOLTAGE);

        // Sanity: nominal Ah should be in a reasonable range for BYD packs (50-350 Ah)
        if (nominalCapacityAh < 50 || nominalCapacityAh > 350) {
            logger.debug("Capacity-Ah SOH rejected: derived nominal " +
                String.format("%.1f", nominalCapacityAh) + " Ah outside expected range");
            return;
        }

        // Stuck-at-nameplate detector
        if (Math.abs(bodyworkBatteryCapacityAh - nominalCapacityAh) <= STUCK_AT_NAMEPLATE_TOLERANCE_AH) {
            nameplateMatchCount++;
            if (nameplateMatchCount >= STUCK_AT_NAMEPLATE_TRIPS) {
                capacityAhDisabled = true;
                logger.warn("Capacity-Ah source disabled: BMS-reported Ah ("
                    + String.format("%.1f", bodyworkBatteryCapacityAh)
                    + ") matches nameplate (" + String.format("%.1f", nominalCapacityAh)
                    + ") for " + nameplateMatchCount
                    + " consecutive readings — likely returning static rating, not live capacity");
            }
            // Don't feed nameplate-match readings into the EMA — they would
            // bias SOH toward 100% and mask real degradation.
            return;
        } else {
            nameplateMatchCount = 0;  // Reset on any non-matching reading
        }

        double sohFromAh = (bodyworkBatteryCapacityAh / nominalCapacityAh) * 100.0;

        if (sohFromAh < 60.0 || sohFromAh > 110.0) {
            logger.debug("Capacity-Ah SOH rejected: " + String.format("%.1f", sohFromAh) +
                "% outside valid range 60-110");
            return;
        }

        // High confidence weight — BMS-reported capacity is reliable
        applyWeightedSoh(sohFromAh, 0.40);
        rawCapacityAhSoh = sohFromAh;
        sohSource = "capacity_ah";
        estimationMethod = "capacity_ah";

        logger.info("Capacity-Ah SOH: " + String.format("%.1f", sohFromAh) + "% " +
            "(reported=" + String.format("%.1f", bodyworkBatteryCapacityAh) + " Ah, " +
            "nominal=" + String.format("%.1f", nominalCapacityAh) + " Ah, " +
            cellCount + "s cells)");
    }

    // ==================== OEM SOH ====================

    // Latched once the OEM SOH method/feature has been confirmed missing on
    // this firmware. Polling it on every cycle was wasting reflection calls
    // and emitting "[diag] getStatisticBatteryHealthyIndex failed: ..." spam.
    // Set by markOemSohUnavailable() from the data-collection path.
    private volatile boolean oemSohUnavailable = false;

    /** True if the OEM SOH index is known to be unsupported on this firmware. */
    public boolean isOemSohUnavailable() {
        return oemSohUnavailable;
    }

    /** Latch OEM SOH as unavailable. Idempotent. */
    public void markOemSohUnavailable() {
        if (!oemSohUnavailable) {
            oemSohUnavailable = true;
            logger.info("OEM SOH (StatisticBatteryHealthyIndex) marked unavailable on this firmware "
                + "— will rely on capacity_ah / calibration / energy sources");
        }
    }

    /**
     * Update SOH directly from the OEM battery health index (STATISTIC_BATTERY_HEALTHY_INDEX).
     * When available, the OEM value is the most accurate SOH source — it comes directly
     * from the BMS and supersedes both instantaneous and calibration estimates.
     *
     * @param oemSohPercent OEM SOH value from BYD BMS (expected range 60-110%)
     */
    public void updateFromOem(double oemSohPercent) {
        if (Double.isNaN(oemSohPercent)) return;
        // Accept only realistic SOH values (60-100%).
        if (oemSohPercent < 60 || oemSohPercent > 100) {
            logger.debug("Rejecting OEM SOH " + oemSohPercent + " — outside valid range 60-100");
            return;
        }

        // Always track raw value for UI display
        rawOemSoh = oemSohPercent;

        // Apply via EMA (weight 0.70) instead of direct set — protects against
        // models that return garbage in the valid range
        if (!"oem".equals(sohSource)) {
            logger.info("SOH source transitioning from " + sohSource + " to OEM: " +
                String.format("%.1f", oemSohPercent) + "%");
        }
        applyWeightedSoh(oemSohPercent, 0.70);
        sohSource = "oem";
        persistEstimate();
    }

    /**
     * Returns the current SOH data source: "oem", "calibration", or "instantaneous".
     */
    public String getSohSource() { return sohSource; }

    // ==================== GETTERS ====================

    /**
     * Returns the active SOH value based on preferred source mode.
     * - "auto": returns the EMA-blended value (default)
     * - "oem"/"capacity_ah"/"calibration"/"energy": returns that source's raw value
     */
    public double getCurrentSoh() {
        if ("auto".equals(preferredSource)) {
            return currentSoh;
        }
        // User pinned to a specific source — return its raw value
        double raw = getRawForSource(preferredSource);
        return raw > 0 ? raw : currentSoh;  // fallback to EMA if pinned source has no data
    }

    private double getRawForSource(String source) {
        switch (source) {
            case "oem": return rawOemSoh;
            case "capacity_ah": return rawCapacityAhSoh;
            case "calibration": return rawCalibrationSoh;
            case "energy": return rawEnergySoh;
            default: return -1;
        }
    }

    public double getEmaSoh() { return currentSoh; }  // Always returns the blended EMA value
    public boolean hasEstimate() { return currentSoh > 0; }

    public double getEstimatedCapacityKwh() {
        if (!hasEstimate()) return -1;
        return (currentSoh / 100.0) * nominalCapacityKwh;
    }

    public int getSampleCount() { return sampleCount; }
    public String getEstimationMethod() { return estimationMethod; }
    public String getPreferredSource() { return preferredSource; }

    /**
     * Set the preferred SOH source mode.
     * @param source "auto", "oem", "capacity_ah", "calibration", or "energy"
     */
    public void setPreferredSource(String source) {
        if (source == null) source = "auto";
        switch (source) {
            case "auto":
            case "oem":
            case "capacity_ah":
            case "calibration":
            case "energy":
                this.preferredSource = source;
                persistEstimate();
                logger.info("SOH preferred source set to: " + source);
                break;
            default:
                logger.warn("Invalid SOH source: " + source + " — keeping " + preferredSource);
        }
    }

    // ==================== RESET ====================

    /**
     * Reset all SOH estimation state. Clears persisted data and forces re-estimation
     * from scratch on next available data source. Use when:
     * - Battery was replaced
     * - User suspects incorrect SOH reading
     * - Debugging estimation issues
     */
    public void reset() {
        currentSoh = -1;
        sampleCount = 0;
        nominalCapacityKwh = 0;  // Clear capacity — forces re-detection on next autoDetect cycle
        sohSource = "instantaneous";
        estimationMethod = METHOD_INSTANTANEOUS;
        rawOemSoh = -1;
        rawCapacityAhSoh = -1;
        rawCalibrationSoh = -1;
        rawEnergySoh = -1;
        lastCapacityAhReading = -1;
        nameplateMatchCount = 0;
        capacityAhDisabled = false;
        oemSohUnavailable = false;
        // Keep preferredSource — user's choice survives reset

        // Delete persisted file
        File sohFile = new File(SOH_FILE);
        if (sohFile.exists()) {
            sohFile.delete();
        }

        logger.info("SOH estimation RESET — all data cleared. Will re-seed from next available source.");
    }

    /**
     * Get full SOH status as JSON for API/UI consumption.
     * Includes raw values from all sources + the active computed value + mode.
     */
    public org.json.JSONObject getStatus() {
        org.json.JSONObject status = new org.json.JSONObject();
        try {
            // Active/computed value
            double activeSoh = getCurrentSoh();
            status.put("soh", activeSoh > 0 ? Math.round(activeSoh * 10) / 10.0 : -1);
            status.put("emaSoh", currentSoh > 0 ? Math.round(currentSoh * 10) / 10.0 : -1);
            status.put("source", sohSource);
            status.put("method", estimationMethod);
            status.put("sampleCount", sampleCount);
            status.put("nominalCapacityKwh", nominalCapacityKwh);
            status.put("estimatedCapacityKwh", getEstimatedCapacityKwh() > 0
                ? Math.round(getEstimatedCapacityKwh() * 10) / 10.0 : -1);
            status.put("hasEstimate", hasEstimate());
            status.put("preferredSource", preferredSource);

            // Raw values from each source
            org.json.JSONObject raw = new org.json.JSONObject();
            raw.put("oem", rawOemSoh > 0 ? Math.round(rawOemSoh * 10) / 10.0 : org.json.JSONObject.NULL);
            raw.put("capacity_ah", rawCapacityAhSoh > 0 ? Math.round(rawCapacityAhSoh * 10) / 10.0 : org.json.JSONObject.NULL);
            raw.put("calibration", rawCalibrationSoh > 0 ? Math.round(rawCalibrationSoh * 10) / 10.0 : org.json.JSONObject.NULL);
            raw.put("energy", rawEnergySoh > 0 ? Math.round(rawEnergySoh * 10) / 10.0 : org.json.JSONObject.NULL);
            status.put("rawValues", raw);

            // Last updated from file
            File sohFile = new File(SOH_FILE);
            if (sohFile.exists()) {
                Properties props = new Properties();
                try (FileInputStream fis = new FileInputStream(sohFile)) {
                    props.load(fis);
                }
                String lastUpdated = props.getProperty(PROP_LAST_UPDATED);
                if (lastUpdated != null) {
                    status.put("lastUpdated", Long.parseLong(lastUpdated));
                }
            }
        } catch (Exception e) {
            logger.error("Failed to build SOH status: " + e.getMessage());
        }
        return status;
    }

    // ==================== PERSISTENCE ====================

    private void persistEstimate() {
        // Don't persist invalid/sentinel values — this prevents the -1.0 SOH bug
        // where reset() sets currentSoh=-1, then a subsequent call to persistEstimate()
        // (e.g., from setNominalCapacityKwh) writes -1 to disk, causing "Discarding
        // persisted SOH -1.0" warnings on every startup.
        if (currentSoh <= 0 && nominalCapacityKwh <= 0) {
            // Nothing useful to persist — skip
            return;
        }
        
        try {
            Properties props = new Properties();
            // Only write SOH if it's a valid estimate
            if (currentSoh > 0 && currentSoh <= 110) {
                props.setProperty(PROP_SOH_PERCENT, String.valueOf(currentSoh));
            }
            props.setProperty(PROP_ESTIMATION_METHOD, estimationMethod);
            props.setProperty(PROP_LAST_UPDATED, String.valueOf(System.currentTimeMillis()));
            props.setProperty(PROP_SAMPLE_COUNT, String.valueOf(sampleCount));
            props.setProperty(PROP_PREFERRED_SOURCE, preferredSource);
            if (nominalCapacityKwh > 0) {
                props.setProperty(PROP_NOMINAL_CAPACITY, String.valueOf(nominalCapacityKwh));
            }

            try (FileOutputStream fos = new FileOutputStream(SOH_FILE)) {
                props.store(fos, "ABRP SOH Estimate");
            }
            // Make world-readable so the app process (UID 10xxx) can read it
            new File(SOH_FILE).setReadable(true, false);
        } catch (Exception e) {
            logger.error("Failed to persist SOH: " + e.getMessage());
        }
    }

    // ==================== MAPPINGS ====================

    private static double mapAhToKwh(int ah) {
        switch (ah) {
            case 150: return 60.48;   // Atto 3 / Yuan Plus
            case 153: return 82.56;   // Seal Premium/Performance
            case 157: return 61.44;   // Seal Dynamic RWD
            case 140: return 71.8;    // Seal U (71.8 kWh variant)
            case 170: return 87.0;    // Seal U (87 kWh variant)
            case 166: return 85.44;   // Han EV
            case 120: return 44.9;    // Dolphin Standard
            case 135: return 60.48;   // Dolphin Extended
            case 100: return 38.0;    // Seagull (38 kWh variant)
            case 80:  return 30.08;   // Seagull (30 kWh) / Atto 1 Essential
            case 200: return 108.8;   // Tang
            case 176: return 56.4;    // Qin Plus EV
            case 180: return 91.3;    // Sealion 7
            case 110: return 43.2;    // Atto 1 Premium / Atto 2
            case 50:  return 18.3;    // Sealion 6 DM-i (PHEV) small battery
            case 56:  return 18.3;    // Sealion 6 DM-i (PHEV) — confirmed BMS returns 56 Ah
            case 72:  return 26.6;    // Sealion 6 DM-i (PHEV) large battery
            case 75:  return 26.6;    // Sealion 6 DM-i (PHEV) large battery — alternate
            case 79:  return 26.6;    // Sealion 6 DM-i (PHEV) large battery — confirmed from BMS
            default:  return 0;       // Unknown — don't guess
        }
    }

    private static double matchNearestCapacity(double estimated) {
        double[] known = {
            18.3,   // Sealion 6 DM-i (PHEV) small battery
            26.6,   // Sealion 6 DM-i (PHEV) large battery
            30.08,  // Seagull 30 / Atto 1 Essential
            38.0,   // Seagull 38
            43.2,   // Atto 1 Premium
            44.9,   // Dolphin Standard / Atto 2
            56.4,   // Qin Plus EV
            60.48,  // Atto 3 / Dolphin Extended
            61.44,  // Seal Dynamic RWD
            71.7,   // E6
            71.8,   // Seal U / Song Plus EV
            82.56,  // Seal
            85.44,  // Han EV
            87.0,   // Seal U (87 kWh)
            91.3,   // Sealion 7
            108.8   // Tang
        };
        double bestMatch = 0;
        double bestDiff = Double.MAX_VALUE;
        for (double k : known) {
            double diff = Math.abs(estimated - k);
            // Use 20% tolerance for small packs (<40 kWh) because BMS readings
            // on PHEVs have higher relative error at low SOC. Standard 10% for larger packs.
            double tolerance = k < 40 ? 0.20 : 0.10;
            if (diff / k < tolerance && diff < bestDiff) {
                bestDiff = diff;
                bestMatch = k;
            }
        }
        return bestMatch;
    }

    /**
     * Map HV pack cell count (series) to known BYD battery capacity.
     * BYD Blade cells are LFP (3.2V nominal). Cell count is derived from
     * pack voltage / 3.2V and uniquely identifies the pack across all models.
     *
     * Known BYD Blade pack configurations:
     * - 96s:  ~307V nominal → Seagull 30 kWh / Sealion 6 DM-i 18.3 kWh
     * - 104s: ~333V nominal → Dolphin Standard 44.9 kWh
     * - 120s: ~384V nominal → Atto 3 60.48 kWh / Dolphin Extended
     * - 126s: ~403V nominal → Seal Dynamic 61.44 kWh
     * - 138s: ~442V nominal → Seal U 71.8 kWh / Song Plus EV
     * - 150s: ~480V nominal → Seal 82.5 kWh
     * - 156s: ~499V nominal → Han EV 85.44 kWh
     * - 166s: ~531V nominal → Seal U 87 kWh
     * - 170s: ~544V nominal → Sealion 7 91.3 kWh
     * - 192s: ~614V nominal → Tang 108.8 kWh
     */
    private static double mapCellCountToCapacity(int cellCount) {
        // Allow ±3 cells tolerance (voltage measurement noise at 3.2V nominal)
        // Ranges must NOT overlap — each cell count maps to exactly one pack.
        if (cellCount >= 80 && cellCount <= 86) return 26.6;     // Sealion 6 DM-i large (83s ~266V)
        if (cellCount >= 93 && cellCount <= 99) return 30.08;    // Seagull 30 / Atto 1
        if (cellCount >= 101 && cellCount <= 107) return 44.9;   // Dolphin Standard
        if (cellCount >= 117 && cellCount <= 122) return 60.48;  // Atto 3 / Dolphin Extended (120s)
        if (cellCount >= 123 && cellCount <= 129) return 61.44;  // Seal Dynamic RWD (126s)
        if (cellCount >= 135 && cellCount <= 141) return 71.8;   // Seal U / Song Plus EV (138s)
        if (cellCount >= 147 && cellCount <= 152) return 82.56;  // Seal (150s)
        if (cellCount >= 153 && cellCount <= 159) return 85.44;  // Han EV (156s)
        if (cellCount >= 163 && cellCount <= 166) return 87.0;   // Seal U 87 kWh (166s)
        if (cellCount >= 167 && cellCount <= 173) return 91.3;   // Sealion 7 (170s)
        if (cellCount >= 189 && cellCount <= 195) return 108.8;  // Tang (192s)
        return 0;
    }

    private static double mapCarTypeToCapacity(String carType) {
        String ct = carType.toUpperCase();
        // Order matters: check more specific patterns first
        if (ct.contains("SEALION 6") || ct.contains("SEALION6") || ct.contains("SEA LION 6")) return 26.6;
        if (ct.contains("SEALION") || ct.contains("SEA LION")) return 91.3;  // Sealion 7
        if (ct.contains("SEAL U") || ct.contains("SEALU") || ct.contains("SEAL-U") || ct.contains("S7")) return 71.8;
        if (ct.contains("SEAL")) return 82.56;
        if (ct.contains("HAN") || ct.contains("DM-P")) return 85.44;
        if (ct.contains("TANG")) return 108.8;
        if (ct.contains("ATTO 3") || ct.contains("ATTO3") || ct.contains("YUAN PLUS")) return 60.48;
        if (ct.contains("ATTO 2") || ct.contains("ATTO2")) return 44.9;
        if (ct.contains("ATTO 1") || ct.contains("ATTO1")) return 30.08;  // Essential (safer default)
        if (ct.contains("YUAN PRO")) return 38.0;
        if (ct.contains("YUAN")) return 60.48;  // Yuan Plus fallback
        if (ct.contains("DOLPHIN MINI") || ct.contains("SEAGULL")) return 38.0;
        if (ct.contains("DOLPHIN")) return 44.9;  // Standard range default
        if (ct.contains("E6")) return 71.7;
        if (ct.contains("SONG")) return 71.8;
        if (ct.contains("QIN")) return 56.4;
        return 0;
    }
}
