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

    // True when fuel signals (getFuelPercentageValue / getFuelDrivingRangeValue)
    // are at BEV sentinels. Set by autoDetectCarModel before the SOC heuristic
    // runs so we can suppress the PHEV-kWh-bug detector on real BEVs whose
    // remainKwh happens to be numerically close to SOC% by coincidence
    // (e.g. Seal at SOC=21%, remainKwh=17.1 → diff=3.9 → false positive).
    // getEnergyType is unreliable: observed returning 1 on both BEV and PHEV.
    private boolean fuelSignalsLookBev = false;

    // ==================== SOURCE SELECTION MODE ====================
    // "auto" = EMA blend (default), or user can pin to a specific source
    private String preferredSource = "auto";  // "auto", "oem", "capacity_ah", "calibration", "energy"
    private static final String PROP_PREFERRED_SOURCE = "preferred_source";

    // Plausible BYD pack range. Smallest is Sealion 6 DM-i PHEV at 18.3 kWh;
    // largest is Tang at 108.8 kWh. The 200 kWh upper bound that used to live
    // here let bugs like "149 Ah misread as 149 kWh" persist as nominal.
    private static final double MIN_PLAUSIBLE_KWH = 15.0;
    private static final double MAX_PLAUSIBLE_KWH = 120.0;

    public void setNominalCapacityKwh(double capacityKwh) {
        if (capacityKwh >= MIN_PLAUSIBLE_KWH && capacityKwh <= MAX_PLAUSIBLE_KWH) {
            this.nominalCapacityKwh = capacityKwh;
            logger.info("Nominal capacity set to " + capacityKwh + " KWh");
            persistEstimate();  // Save immediately so it survives restarts

            // Trigger seed now that we have capacity — autoDetect may have
            // set this after the initial seedInitialEstimate call returned early
            if (!hasEstimate()) {
                seedInitialEstimate();
            }
        } else {
            logger.warn("Rejecting implausible nominal capacity: " + capacityKwh
                + " kWh (valid range: " + MIN_PLAUSIBLE_KWH + "-" + MAX_PLAUSIBLE_KWH + ")");
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
        // Reset each call — re-detect on every autoDetect cycle
        fuelSignalsLookBev = false;
        boolean fuelPctSentinel = false;
        boolean fuelRangeSentinel = false;
        boolean fuelPctProbed = false;
        boolean fuelRangeProbed = false;
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
                        fuelPctProbed = true;
                        String hint;
                        if (isSentinelInt(fp)) {
                            hint = " (sentinel — BEV / fuel unavailable)";
                            fuelPctSentinel = true;
                        } else if (fp instanceof Number) {
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
                        fuelRangeProbed = true;
                        String hint;
                        if (isSentinelInt(fr)) {
                            hint = " (sentinel — BEV / range unavailable)";
                            fuelRangeSentinel = true;
                        } else if (fr instanceof Number) {
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

            // BYDAutoBodyworkDevice — getBatteryCapacity (we use this)
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

            // Both fuel signals at sentinels → vehicle is a BEV regardless of
            // what getEnergyType claims. We've observed energyType=1 on both
            // BEV and PHEV, so it cannot be the discriminator on its own.
            // Requiring BOTH sentinels avoids a single-signal false positive.
            if (fuelPctProbed && fuelRangeProbed && fuelPctSentinel && fuelRangeSentinel) {
                fuelSignalsLookBev = true;
                logger.info("[diag] Inferred drivetrain: BEV (both fuel signals at sentinel — getEnergyType ignored)");
            }

            logger.info("=== POWERTRAIN DIAGNOSTICS END ===");
        } catch (Throwable t) {
            // Diagnostic must never throw into the caller's flow
            logger.warn("dumpPhevDiagnostics: unexpected error: " + describeException(t));
        }
    }

    // Synchronizes the entire detection pipeline so two threads can't
    // interleave dumpPhevDiagnostics output and race on fuelSignalsLookBev.
    // Observed in field log: CameraDaemon init and SocHistoryDatabase
    // periodic tick both ran autoDetectCarModel concurrently, producing
    // interleaved log lines and a stale fuelSignalsLookBev read.
    private final Object autoDetectLock = new Object();

    public void autoDetectCarModel(android.content.Context context) {
        synchronized (autoDetectLock) {
            autoDetectCarModelInternal(context);
        }
    }

    private void autoDetectCarModelInternal(android.content.Context context) {
        // Defensive: callers (e.g. PerformanceApiHandler.handleSohReset) used
        // to pass null, which silently disabled HAL probes — no fuel signal
        // could be read, so dumpPhevDiagnostics couldn't set fuelSignalsLookBev
        // and the BMS-Ah exact lookup couldn't run, leaving SOC-heuristic-only
        // detection. Recover by reaching for the daemon's app context.
        if (context == null) {
            try {
                context = com.overdrive.app.daemon.CameraDaemon.getAppContext();
                if (context != null) {
                    logger.warn("autoDetectCarModel called with null context — recovered via CameraDaemon.getAppContext()");
                } else {
                    logger.warn("autoDetectCarModel: null context AND no app context available — HAL probes will be skipped");
                }
            } catch (Exception e) {
                logger.warn("autoDetectCarModel: failed to recover null context: " + describeException(e));
            }
        }

        // Diagnostic dump — read-only, no behaviour change. Logs HAL values that
        // are useful for diagnosing PHEV capacity-detection failures, including
        // sources we currently ignore (getChargingCapacity, getEnergyMode,
        // getFuelPercentage). Safe to leave on; runs once per autoDetect call.
        dumpPhevDiagnostics(context);

        // Priority order:
        // 1. BMS direct EXACT — getBatteryCapacity() returns a value present in
        //    mapAhToKwh's table. Most precise: 157 → 61.44 (Seal Dynamic) is
        //    unambiguous, whereas the SOC heuristic can confuse it with Seal U.
        // 2. SOC heuristic — remainKwh / SOC → snap to nearest known pack.
        //    Used when BMS returns a sentinel or unmapped value.
        // 3. Model string — ro.product.model → table lookup.
        // 4. BMS direct FUZZY — fuzzy Ah snap (±N) for BMSes that report
        //    slightly off the canonical rating (Atto 3 reports 149, nameplate 150).
        // 5. Pack voltage — derive cell count (unreliable on some models).

        // Method 1: BMS direct exact lookup — only fires when raw Ah is
        // an exact key in mapAhToKwh. This bypasses the SOC heuristic's
        // worst case (Seal Dynamic 67 kWh estimate snapping to Seal U 71.8).
        //
        // Cross-check: if remainKwh + SOC are both available and produce
        // an implied capacity that disagrees with the BMS Ah lookup by
        // more than one pack class (~25%), trust the SOC math. The BMS Ah
        // value can be off-by-a-cell-count between similar packs (Seal
        // Premium 153 Ah ↔ Atto 3 150 Ah is the dangerous neighbor) and
        // the SOC ratio is the more reliable disambiguator.
        if (context != null) {
            double exactKwh = tryBmsExactCapacity(context);
            if (exactKwh > 0 && !contradictedBySocRatio(exactKwh)) {
                setNominalCapacityKwh(exactKwh);
                return;
            }
        }

        // Method 2: SOC heuristic — most reliable auto-detection method
        // when BMS Ah is a sentinel or unmapped. Uses actual energy readings
        // (remainKwh / SOC%) which are proven accurate.
        //
        // Floor lowered from 20% → 10% SOC. The 20% floor was originally
        // there to guard against BMS noise at deep discharge, but a Seal
        // Premium powered on at SOC=19% (15.7 kWh) would skip this method
        // entirely and fall through to the fuzzy Ah snap, which guesses
        // 60.48 (Atto 3) from raw=149 instead of the obvious 82.6 kWh ratio.
        // The PHEV-kWh-bug guard already covers the failure mode this floor
        // was meant to prevent on PHEVs; on BEVs (fuelSignalsLookBev=true),
        // the energy-vs-SOC ratio at 10-20% SOC is just as accurate as at 50%.
        try {
            VehicleDataMonitor vdm = VehicleDataMonitor.getInstance();
            double remainingKwh = vdm.getBatteryRemainPowerKwh();
            BatterySocData socData = vdm.getBatterySoc();
            if (remainingKwh > 1.5 && socData != null && socData.socPercent >= 10) {
                double estimatedCapacity = remainingKwh / (socData.socPercent / 100.0);
                // Detect BYD PHEV firmware bug: BMS returns SOC% value as kWh.
                // Widened threshold from 3.0 to 5.0 — on PHEVs the values can drift
                // slightly apart (e.g., SOC=53%, remainKwh=56) but still indicate the bug.
                // Also detect when remainKwh is impossibly large for a PHEV pack
                // (e.g., remainKwh=56 on an 18 kWh pack means it's clearly SOC-as-kWh).
                //
                // Suppress the bug check entirely if fuel signals confirm this is a BEV.
                // Real BEVs near 20% SOC can land within 5 kWh of SOC% by coincidence
                // (Seal: SOC=21%, remainKwh=17.1 → diff=3.9), and they snap cleanly to
                // an 80+ kWh pack. The PHEV bug only appears on vehicles that have
                // a fuel tank, so absence of fuel data rules it out definitively.
                boolean likelyPhevKwhBug = !fuelSignalsLookBev
                        && Math.abs(remainingKwh - socData.socPercent) < 5.0;
                // Additional heuristic: if remainKwh > 40 but estimated capacity snaps to
                // a known small PHEV pack (<30 kWh), the BMS is lying about remainKwh.
                //
                // CAUTION: a 1:1 ratio also occurs naturally on ~100 kWh BEVs at any SOC
                // (e.g. Tang at 70% SOC: remain≈70 kWh, ratio=1.0), so this check is
                // suppressed when fuel signals already confirm BEV. Without that guard
                // a Tang BEV would be falsely flagged as a PHEV with the kWh field bug.
                if (!fuelSignalsLookBev && !likelyPhevKwhBug
                        && remainingKwh > 40 && estimatedCapacity > 40
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
                    // Pass live pack voltage + SOC so close-neighbor packs
                    // (82.56 vs 85.44, 60.48 vs 61.44) can be disambiguated
                    // by checking which one's cell count produces a plausible
                    // per-cell voltage at the current SOC.
                    double packV = Double.NaN;
                    BydVehicleData vd = vdm.getVd();
                    if (vd != null && !Double.isNaN(vd.hvPackVoltage)
                            && vd.hvPackVoltage > 200) {
                        packV = vd.hvPackVoltage;
                    }
                    double matched = matchNearestCapacity(
                        estimatedCapacity, packV, socData.socPercent);
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

        // Method 4: BMS direct FUZZY — runs when SOC heuristic and model
        // string both fail. Snaps unmapped raw Ah readings (e.g. 149) to
        // their nearest canonical pack Ah using nearestKnownAh's gap-aware
        // tolerance. Also handles the rare BMS that reports kWh × 1000.
        // Cross-check with SOC ratio: if the snapped Ah implies a kWh that
        // the SOC ratio contradicts by >25%, the snap was probably wrong
        // (e.g. Seal Premium reads 149 Ah → snaps to 150 → 60.48 kWh,
        // but SOC ratio implies ~82 kWh). Skip the fuzzy result in that
        // case and fall through to pack voltage.
        if (context != null) {
            double fuzzyKwh = tryBmsFuzzyCapacity(context);
            if (fuzzyKwh > 0 && !contradictedBySocRatio(fuzzyKwh)) {
                setNominalCapacityKwh(fuzzyKwh);
                return;
            }
        }

        // Method 5: Pack voltage → cell count (least reliable — some models report wrong voltage)
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

        // All detection methods failed. Validate the previously saved
        // capacity (from init()) against the live SOC ratio if possible —
        // a stale persisted value from a buggy older build (e.g. 60.48
        // restored from a prior fuzzy-snap mistake) shouldn't be kept
        // when current readings contradict it.
        if (nominalCapacityKwh > 0 && contradictedBySocRatio(nominalCapacityKwh)) {
            logger.warn("Persisted nominal " + nominalCapacityKwh
                + " kWh contradicted by current SOC ratio — clearing for re-detection on next cycle");
            nominalCapacityKwh = 0;
            currentSoh = -1;
            sampleCount = 0;
            rawEnergySoh = -1;
            rawCapacityAhSoh = -1;
            rawCalibrationSoh = -1;
            persistEstimate();
        }

        logger.warn("Capacity detection failed" +
            (nominalCapacityKwh > 0 ? " — using previously saved capacity: " + nominalCapacityKwh + " kWh"
                                    : " — SOH estimation disabled until capacity is identified"));
    }

    /**
     * Returns true if the SOC heuristic (remainKwh / SOC%) implies a
     * nominal capacity that differs from `bmsKwh` by more than 25%.
     * Used to veto BMS-Ah results when they're plausibly the wrong pack
     * class — e.g. a Seal Premium whose BMS reports raw Ah=150 (Atto 3
     * key) but whose 15.7 kWh @ 19% SOC implies an 80+ kWh pack.
     *
     * Returns false if SOC data is unavailable / unreliable / would mark
     * a fresh pack at SOH < 75% as a different pack class.
     */
    private boolean contradictedBySocRatio(double bmsKwh) {
        try {
            VehicleDataMonitor vdm = VehicleDataMonitor.getInstance();
            if (vdm == null) return false;
            double remainKwh = vdm.getBatteryRemainPowerKwh();
            BatterySocData socData = vdm.getBatterySoc();
            if (socData == null) return false;
            double soc = socData.socPercent;
            // Need real values, low-SOC math is dominated by BMS noise.
            if (remainKwh < 1.5 || soc < 10 || soc > 100) return false;
            double impliedKwh = remainKwh / (soc / 100.0);
            // PHEV-kWh-bug case: ignore SOC ratio if it equals SOC% literally
            // (BMS quirk that reports SOC value in the kWh field). The
            // fuelSignalsLookBev guard handles confirmed BEVs; anything
            // else suspicious enough to be the bug should not veto BMS Ah.
            if (!fuelSignalsLookBev && Math.abs(remainKwh - soc) < 5.0) return false;
            double relativeDelta = Math.abs(impliedKwh - bmsKwh) / bmsKwh;
            if (relativeDelta > 0.25) {
                logger.warn("BMS exact-Ah result " + bmsKwh + " kWh contradicted by SOC ratio: "
                    + String.format("%.1f", impliedKwh) + " kWh (remain="
                    + String.format("%.1f", remainKwh) + ", SOC="
                    + String.format("%.0f", soc) + "%) — falling through to SOC heuristic");
                return true;
            }
        } catch (Exception ignored) {}
        return false;
    }

    /**
     * Read getBatteryCapacity and return kWh ONLY when the raw Ah value is
     * an exact key in mapAhToKwh (or in 0.001 kWh units). Returns 0 if
     * sentinel, unmapped, or out of plausible range — caller falls through
     * to the SOC heuristic. Splitting "exact" from "fuzzy" lets us prefer
     * exact BMS Ah (e.g. 157 → 61.44 Seal Dynamic) over the SOC heuristic
     * which can confuse Seal Dynamic with Seal U at low SOC.
     */
    private double tryBmsExactCapacity(android.content.Context context) {
        Integer rawOrNull = readBatteryCapacityRaw(context);
        if (rawOrNull == null) return 0;
        int raw = rawOrNull;
        // BMS-as-kWh-thousandths variant
        if (raw > 1000 && raw < 60000) {
            double kwh = raw / 1000.0;
            if (kwh >= MIN_PLAUSIBLE_KWH && kwh <= MAX_PLAUSIBLE_KWH) {
                logger.info("BMS Capacity (exact, 0.001 kWh): " + kwh + " kWh (raw=" + raw + ")");
                return kwh;
            }
            return 0;
        }
        // BMS-as-Ah variant — only accept exact mapAhToKwh hits here
        if (raw > 0 && raw <= 1000) {
            double kwh = mapAhToKwh(raw);
            if (kwh >= MIN_PLAUSIBLE_KWH && kwh <= MAX_PLAUSIBLE_KWH) {
                logger.info("BMS Capacity (exact, Ah=" + raw + "): " + kwh + " kWh");
                return kwh;
            }
        }
        return 0;
    }

    /**
     * Fuzzy fallback: snap an unmapped raw Ah to the nearest canonical pack
     * Ah (within nearestKnownAh's gap-aware window). Used after SOC and
     * model-string detection have both failed. Required for BMSes that
     * report ±1-2 Ah off nameplate (Atto 3 reports 149, nameplate 150).
     */
    private double tryBmsFuzzyCapacity(android.content.Context context) {
        Integer rawOrNull = readBatteryCapacityRaw(context);
        if (rawOrNull == null) return 0;
        int raw = rawOrNull;
        if (raw <= 0 || raw > 1000) return 0;
        // Skip values that already mapped exactly — tryBmsExactCapacity
        // would have used them. Fuzzy is only for unmapped raws.
        if (mapAhToKwh(raw) > 0) return 0;

        int snappedAh = nearestKnownAh(raw, 3);
        if (snappedAh <= 0) return 0;
        double kwh = mapAhToKwh(snappedAh);
        if (kwh < MIN_PLAUSIBLE_KWH || kwh > MAX_PLAUSIBLE_KWH) return 0;

        logger.info("BMS Capacity (fuzzy): " + kwh + " kWh (raw Ah=" + raw
            + " → snapped to " + snappedAh + " Ah)");
        return kwh;
    }

    /**
     * Read getBatteryCapacity raw int. Returns null on sentinel, error, or
     * device-not-ready so callers can fall through cleanly.
     */
    private Integer readBatteryCapacityRaw(android.content.Context context) {
        try {
            Class<?> cls = Class.forName("android.hardware.bydauto.bodywork.BYDAutoBodyworkDevice");
            Object device = cls.getMethod("getInstance", android.content.Context.class).invoke(null, context);
            if (device == null) return null;
            Method getBatteryCapacity = cls.getMethod("getBatteryCapacity");
            Number capNum = (Number) getBatteryCapacity.invoke(device);
            if (capNum == null) return null;
            int raw = capNum.intValue();
            if (raw <= 0 || raw == 255 || raw == 254 || raw == 65534 || raw == 65535) {
                return null;
            }
            return raw;
        } catch (Exception e) {
            logger.debug("readBatteryCapacityRaw failed: " + e.getMessage());
            return null;
        }
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
            // 10% floor matches autoDetectCarModel — energy / SOC ratio is
            // accurate at low SOC for confirmed BEVs (fuelSignalsLookBev),
            // and the PHEV-kWh-bug guard handles the suspect-firmware case.
            if (socData == null || socData.socPercent < 10 || socData.socPercent > 100) {
                // SOC too low/high or unavailable — fall through to 100% baseline below.
            } else {
                // PHEV firmware bug: BMS reports SOC% in the kWh field. Catch
                // the easy case (numerically equal) first. Skip on confirmed BEVs.
                boolean isPhevKwhBug = !fuelSignalsLookBev
                        && Math.abs(remainingKwh - socData.socPercent) < 5.0;
                // Ratio sanity check is only useful BEFORE we know the pack
                // size — once nominalCapacityKwh is set, a pack near 100 kWh
                // legitimately produces a 1:1 SOC%/kWh ratio at any SOC.
                // Also skip when fuel signals already confirmed this is a BEV.
                if (!fuelSignalsLookBev && !isPhevKwhBug
                        && remainingKwh > 0 && socData.socPercent > 0
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
                } else if (socData.socPercent < 10) {
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
            // Apply the same plausibility window as setNominalCapacityKwh so we
            // discard values from older builds that wrote bad nominals (e.g.
            // 149 from the now-fixed "treat raw Ah as kWh" bug).
            String capStr = props.getProperty(PROP_NOMINAL_CAPACITY);
            if (capStr != null) {
                double savedCap = Double.parseDouble(capStr);
                if (savedCap >= MIN_PLAUSIBLE_KWH && savedCap <= MAX_PLAUSIBLE_KWH
                        && nominalCapacityKwh <= 0) {
                    nominalCapacityKwh = savedCap;
                    logger.info("Restored nominal capacity: " + savedCap + " kWh");
                } else if (savedCap > 0) {
                    logger.warn("Discarding persisted nominal " + savedCap
                        + " kWh — outside plausible range ("
                        + MIN_PLAUSIBLE_KWH + "-" + MAX_PLAUSIBLE_KWH
                        + "), will re-detect");
                    // The currentSoh restored above was computed against this
                    // bad nominal (e.g. 100% baseline against 149 kWh).
                    // getEstimatedCapacityKwh = currentSoh × newNominal / 100
                    // would mix the new correct nominal with a SOH derived
                    // against a wrong one. Force a clean re-seed.
                    if (currentSoh > 0) {
                        logger.warn("Also clearing currentSoh " + currentSoh
                            + "% — was seeded against discarded nominal");
                        currentSoh = -1;
                        sampleCount = 0;
                        rawEnergySoh = -1;
                        rawCapacityAhSoh = -1;
                        rawCalibrationSoh = -1;
                    }
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

        // Prefer mid-range SOC (15-85%) where BMS readings are most stable.
        // Floor lowered from 20% → 15% because LFP cells have a flat
        // discharge curve down to ~10% SOC; below 15% the curve steepens
        // and the BMS Coulomb counter can drift, so anything under 15%
        // is still gated to avoid biasing SOH estimates.
        if (displaySocPercent < 15 || displaySocPercent > 85) {
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
    // BYD Blade LFP reference cell voltage. 3.22 V derived from BYD's
    // published kWh / Ah / cellCount specs:
    //   Atto 3:        60.4 kWh / (126s × 150 Ah) = 3.196 V
    //   Seal Premium:  82.5 kWh / (172s × 150 Ah) = 3.197 V
    // Rounded to 3.22 to match BMS reporting tolerance. Using 3.2 V
    // produced systematic SOH errors of ~0.6% on first probe.
    private static final double BYD_BLADE_REFERENCE_CELL_VOLTAGE = 3.22;
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

    /**
     * Snap a raw BMS Ah reading to the nearest entry in mapAhToKwh.
     * Tolerance is `min(toleranceAh, halfGapToNeighbor)` so close-paired
     * canonical Ah values (e.g. 150 Atto 3 ↔ 153 Seal Premium, which map
     * to 60.48 vs 82.56 kWh) cannot have one's snap window swallow the
     * other's BMS reading. Returns 0 if nothing within the safe window.
     */
    private static int nearestKnownAh(int rawAh, int toleranceAh) {
        // Sorted ascending — required for the gap calculation.
        int[] knownAh = {50, 56, 72, 75, 79, 80, 100, 110, 120, 135, 140,
                         150, 153, 157, 166, 170, 176, 180, 200};
        int best = 0;
        int bestDiff = Integer.MAX_VALUE;
        for (int i = 0; i < knownAh.length; i++) {
            int k = knownAh[i];
            int d = Math.abs(rawAh - k);

            int leftGap = (i == 0) ? Integer.MAX_VALUE : (k - knownAh[i - 1]);
            int rightGap = (i == knownAh.length - 1)
                ? Integer.MAX_VALUE
                : (knownAh[i + 1] - k);
            // Integer half (rounded down) keeps the windows non-overlapping.
            int halfGap = Math.min(leftGap, rightGap) / 2;
            int safeTolerance = Math.min(toleranceAh, halfGap);

            if (d <= safeTolerance && d < bestDiff) {
                bestDiff = d;
                best = k;
            }
        }
        return best;
    }

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

    // Sorted ascending — required by matchNearestCapacity for the
    // half-the-gap tolerance computation. E6 (71.7 kWh) intentionally
    // omitted: legacy taxi model, virtually indistinguishable from Seal U
    // (71.8 kWh). Add via mapCarTypeToCapacity model-string lookup if needed.
    private static final double[] KNOWN_PACK_KWH = {
        18.3,   // Sealion 6 DM-i (PHEV) small battery
        26.6,   // Sealion 6 DM-i (PHEV) large battery
        30.08,  // Seagull 30 / Atto 1 Essential
        38.0,   // Seagull 38
        43.2,   // Atto 1 Premium
        44.9,   // Dolphin Standard / Atto 2
        56.4,   // Qin Plus EV
        60.48,  // Atto 3 / Dolphin Extended
        61.44,  // Seal Dynamic RWD
        71.8,   // Seal U / Song Plus EV
        82.56,  // Seal
        85.44,  // Han EV
        87.0,   // Seal U (87 kWh)
        91.3,   // Sealion 7
        108.8   // Tang
    };

    private static double matchNearestCapacity(double estimated) {
        return matchNearestCapacity(estimated, Double.NaN, Double.NaN);
    }

    /**
     * Snap an estimated capacity to the nearest known BYD pack.
     *
     * 10% relative tolerance for ≥40 kWh packs, 20% for smaller PHEV packs.
     * "Closest within tolerance" wins, with ONE refinement: when two
     * candidate packs are within 5 kWh of the estimate, use pack voltage
     * to break the tie. Each pack has a known cell count; combining that
     * with SOC and live pack voltage tells us the implied per-cell voltage.
     * Reject candidates whose implied per-cell voltage is outside the LFP
     * SOC voltage curve.
     *
     * Real-world example: Seal Premium @ 17% SOC, packV=500V, estimate=84.1
     * - 82.56 (172s): 500/172 = 2.91 V → plausible LFP @ 17% (≥2.85 V) ✓
     * - 85.44 (156s): 500/156 = 3.21 V → implies ~50% SOC, NOT 17% ✗
     */
    private static double matchNearestCapacity(double estimated,
                                               double packVoltage,
                                               double socPercent) {
        double bestMatch = 0;
        double bestDiff = Double.MAX_VALUE;
        for (double k : KNOWN_PACK_KWH) {
            double diff = Math.abs(estimated - k);
            double tolerance = (k < 40 ? 0.20 : 0.10) * k;
            if (diff > tolerance) continue;
            if (!packVoltagePlausibleForPack(k, packVoltage, socPercent)) continue;
            if (diff < bestDiff) {
                bestDiff = diff;
                bestMatch = k;
            }
        }
        return bestMatch;
    }

    /**
     * Returns true if `packVoltage` is consistent with a pack of the given
     * kWh size at `socPercent`. Looks up the pack's cell count, computes
     * implied per-cell voltage, and checks against an LFP SOC voltage band.
     *
     * Returns true (no filter) when packVoltage / socPercent / cell count
     * for `kwh` is unavailable — caller falls back to closest-diff alone.
     */
    private static boolean packVoltagePlausibleForPack(double kwh,
                                                       double packVoltage,
                                                       double socPercent) {
        if (Double.isNaN(packVoltage) || packVoltage < 200) return true;
        if (Double.isNaN(socPercent) || socPercent < 5 || socPercent > 100) return true;
        int cellCount = cellCountForCapacity(kwh);
        if (cellCount <= 0) return true;
        double impliedCellV = packVoltage / cellCount;
        // LFP SOC voltage band — wide enough to absorb load/temp variation
        // but narrow enough to reject neighboring packs that imply a wrong
        // SOC. Boundaries empirical from BYD Blade datasheet rest curves
        // plus ~0.15 V tolerance for under-load operation.
        double minV = lfpMinCellVoltageAt(socPercent);
        double maxV = lfpMaxCellVoltageAt(socPercent);
        return impliedCellV >= minV && impliedCellV <= maxV;
    }

    // LFP SOC voltage curve (BYD Blade rest readings + ±0.10 V band for
    // under-load / temperature variation). At 17% SOC a real LFP cell is
    // resting around 3.15-3.20 V, so a packV/cellCount division giving
    // 3.21 V at SOC=17% means the cell count is wrong (too few cells).
    // Bands here are tight enough to reject 156s when 172s is correct,
    // but loose enough to absorb realistic measurement noise.
    private static double lfpMinCellVoltageAt(double socPercent) {
        if (socPercent >= 95) return 3.28;
        if (socPercent >= 80) return 3.18;
        if (socPercent >= 50) return 3.10;
        if (socPercent >= 30) return 3.00;
        if (socPercent >= 15) return 2.85;
        if (socPercent >= 5)  return 2.70;
        return 2.50;
    }

    private static double lfpMaxCellVoltageAt(double socPercent) {
        if (socPercent >= 95) return 3.55;
        if (socPercent >= 80) return 3.40;
        if (socPercent >= 50) return 3.30;
        if (socPercent >= 30) return 3.22;
        if (socPercent >= 15) return 3.18;
        if (socPercent >= 5)  return 3.10;
        return 3.00;
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
    /**
     * Look up the canonical cell count for a BYD pack of the given kWh
     * capacity. Cell count is configuration data (model-specific), not a
     * voltage-derivable signal — pack voltage drops below nominal at low
     * SOC, so dividing by a fixed cell voltage undercounts cells.
     *
     * Returns 0 if the kWh value isn't in the catalog — caller should skip
     * any computation that needs cellCount in that case.
     */
    public static int cellCountForCapacity(double nominalKwh) {
        // Tolerance of ±0.5 kWh handles minor catalog vs detected mismatches
        // (e.g. detected 60.48 maps to 60.4 catalog entry).
        if (matches(nominalKwh, 60.48) || matches(nominalKwh, 60.4))  return 126;  // Atto 3 / Yuan Plus
        if (matches(nominalKwh, 61.44))                                return 128;  // Seal Dynamic RWD
        if (matches(nominalKwh, 82.56) || matches(nominalKwh, 82.5))   return 172;  // Seal Premium / Excellence
        if (matches(nominalKwh, 71.8))                                 return 138;  // Seal U / Song Plus EV
        if (matches(nominalKwh, 87.0))                                 return 166;  // Seal U 87 kWh
        if (matches(nominalKwh, 85.44))                                return 156;  // Han EV
        if (matches(nominalKwh, 91.3))                                 return 170;  // Sealion 7
        if (matches(nominalKwh, 108.8))                                return 192;  // Tang
        if (matches(nominalKwh, 44.9))                                 return 104;  // Dolphin Standard / Atto 2
        if (matches(nominalKwh, 30.08))                                return 96;   // Seagull 30 / Atto 1 Essential
        if (matches(nominalKwh, 38.0))                                 return 100;  // Seagull 38
        if (matches(nominalKwh, 43.2))                                 return 96;   // Atto 1 Premium
        if (matches(nominalKwh, 56.4))                                 return 116;  // Qin Plus EV
        if (matches(nominalKwh, 18.3))                                 return 80;   // Sealion 6 DM-i small
        if (matches(nominalKwh, 26.6))                                 return 84;   // Sealion 6 DM-i large
        return 0;
    }

    private static boolean matches(double a, double b) {
        return Math.abs(a - b) < 0.5;
    }

    private static double mapCellCountToCapacity(int cellCount) {
        // Cell counts from BYD published specs. ±2 cell tolerance handles
        // minor BMS measurement noise. Ambiguous cases (126s Atto 3 vs
        // 128s Seal Dynamic; 170s Sealion 7 vs 172s Seal Premium) return
        // 0 so higher-priority detection methods (BMS Ah exact, SOC
        // heuristic) can disambiguate. This method is the lowest-priority
        // fallback — use it only when nothing better worked.
        if (cellCount >= 82 && cellCount <= 86)   return 26.6;   // Sealion 6 DM-i large (84s)
        if (cellCount >= 94 && cellCount <= 98)   return 30.08;  // Seagull 30 / Atto 1 (96s)
        if (cellCount >= 102 && cellCount <= 106) return 44.9;   // Dolphin Standard (104s)
        if (cellCount >= 114 && cellCount <= 118) return 56.4;   // Qin Plus EV (116s)
        // 126/128 ambiguous — skip
        if (cellCount >= 136 && cellCount <= 140) return 71.8;   // Seal U / Song Plus EV (138s)
        if (cellCount >= 154 && cellCount <= 158) return 85.44;  // Han EV (156s)
        if (cellCount >= 164 && cellCount <= 168) return 87.0;   // Seal U 87 kWh (166s)
        // 170/172 ambiguous — skip
        if (cellCount >= 190 && cellCount <= 194) return 108.8;  // Tang (192s)
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
