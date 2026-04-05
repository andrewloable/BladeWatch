package com.overdrive.app.abrp;

import com.overdrive.app.logging.DaemonLogger;
import com.overdrive.app.monitor.BatterySocData;
import com.overdrive.app.monitor.VehicleDataMonitor;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.lang.reflect.Method;
import java.util.LinkedList;
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

    private double nominalCapacityKwh = 60.48;
    private static final String SOH_FILE = "/data/local/tmp/abrp_soh_estimate.properties";
    private static final int WINDOW_SIZE = 10;

    private static final String PROP_SOH_PERCENT = "soh_percent";
    private static final String PROP_ESTIMATION_METHOD = "estimation_method";
    private static final String PROP_LAST_UPDATED = "last_updated";
    private static final String PROP_SAMPLE_COUNT = "sample_count";

    private static final String METHOD_INSTANTANEOUS = "instantaneous";
    private static final String METHOD_CALIBRATION = "calibration";

    private double currentSoh = -1;
    private String estimationMethod = METHOD_INSTANTANEOUS;
    private int sampleCount = 0;
    private final LinkedList<Double> rollingWindow = new LinkedList<>();

    public void setNominalCapacityKwh(double capacityKwh) {
        if (capacityKwh > 10 && capacityKwh < 200) {
            this.nominalCapacityKwh = capacityKwh;
            logger.info("Nominal capacity set to " + capacityKwh + " KWh");
        }
    }

    public double getNominalCapacityKwh() {
        return nominalCapacityKwh;
    }

    // ==================== AUTO-DETECT ====================

    public void autoDetectCarModel(android.content.Context context) {
        // Method 1: BMS direct — getBatteryCapacity() returns Ah
        if (context != null) {
            try {
                Class<?> cls = Class.forName("android.hardware.bydauto.bodywork.BYDAutoBodyworkDevice");
                Object device = cls.getMethod("getInstance", android.content.Context.class).invoke(null, context);
                if (device != null) {
                    Method getBatteryCapacity = cls.getMethod("getBatteryCapacity");
                    Number capNum = (Number) getBatteryCapacity.invoke(device);
                    int capacityRaw = capNum != null ? capNum.intValue() : 0;
                    if (capacityRaw > 0) {
                        double capacityKwh = 0;
                        if (capacityRaw > 1000) {
                            capacityKwh = capacityRaw / 1000.0;  // Wh
                        } else if (capacityRaw >= 100 && capacityRaw <= 300) {
                            capacityKwh = mapAhToKwh(capacityRaw);  // Ah
                        } else {
                            capacityKwh = capacityRaw;  // KWh direct
                        }
                        if (capacityKwh > 10 && capacityKwh < 200) {
                            setNominalCapacityKwh(capacityKwh);
                            logger.info("BMS Capacity: " + capacityKwh + " KWh (Raw: " + capacityRaw + " Ah)");
                            return;
                        }
                    }
                }
            } catch (Exception e) {
                logger.debug("BMS capacity lookup failed: " + e.getMessage());
            }
        }

        // Method 2: SOC heuristic — remainingKwh / SOC → match nearest
        try {
            VehicleDataMonitor vdm = VehicleDataMonitor.getInstance();
            double remainingKwh = vdm.getBatteryRemainPowerKwh();
            BatterySocData socData = vdm.getBatterySoc();
            if (remainingKwh > 10 && socData != null && socData.socPercent > 30) {
                double estimatedCapacity = remainingKwh / (socData.socPercent / 100.0);
                double matched = matchNearestCapacity(estimatedCapacity);
                if (matched > 0) {
                    setNominalCapacityKwh(matched);
                    logger.info("SOC-Estimated Capacity: " + String.format("%.1f", estimatedCapacity) +
                        " KWh -> Matched to " + matched + " KWh");
                    return;
                }
            }
        } catch (Exception e) {
            logger.debug("SOC estimation failed: " + e.getMessage());
        }

        // Method 3: System property model string
        try {
            String carType = (String) Class.forName("android.os.SystemProperties")
                .getMethod("get", String.class, String.class)
                .invoke(null, "ro.product.model", "");
            if (carType != null && !carType.isEmpty()) {
                double mapped = mapCarTypeToCapacity(carType);
                if (mapped > 0) {
                    setNominalCapacityKwh(mapped);
                    logger.info("Model-Mapped Capacity (" + carType + "): " + mapped + " KWh");
                    return;
                }
            }
        } catch (Exception e) { /* ignore */ }

        logger.warn("Capacity detection failed. Using default: " + nominalCapacityKwh + " KWh");
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
            if (sohStr != null) currentSoh = Double.parseDouble(sohStr);

            String method = props.getProperty(PROP_ESTIMATION_METHOD);
            if (method != null) estimationMethod = method;

            String countStr = props.getProperty(PROP_SAMPLE_COUNT);
            if (countStr != null) sampleCount = Integer.parseInt(countStr);

            // Sanity check
            if (currentSoh > 110.0 || currentSoh < 50.0) {
                logger.info("Clearing invalid SOH: " + currentSoh + "%");
                currentSoh = -1;
                sampleCount = 0;
            } else {
                // Prime the rolling window with saved value to prevent jumps on reboot
                rollingWindow.clear();
                int primeCount = Math.min(Math.max(1, sampleCount), WINDOW_SIZE);
                for (int i = 0; i < primeCount; i++) {
                    rollingWindow.add(currentSoh);
                }
                logger.info("Restored SOH: " + currentSoh + "% (window primed: " + primeCount + " samples)");
            }
        } catch (Exception e) {
            logger.error("Failed to load SOH: " + e.getMessage());
        }
    }

    // ==================== SOH UPDATES ====================

    public void updateFromInstantaneous(double remainingKwh, double socPercent) {
        if (socPercent <= 0 || socPercent > 100.0) return;

        double currentTotalCap = remainingKwh / (socPercent / 100.0);
        double instantaneousSoh = (currentTotalCap / nominalCapacityKwh) * 100.0;

        if (instantaneousSoh < 50.0 || instantaneousSoh > 110.0) return;

        rollingWindow.addLast(instantaneousSoh);
        if (rollingWindow.size() > WINDOW_SIZE) {
            rollingWindow.removeFirst();
        }

        double sum = 0;
        for (double val : rollingWindow) sum += val;
        currentSoh = sum / rollingWindow.size();
        estimationMethod = METHOD_INSTANTANEOUS;
        sampleCount = rollingWindow.size();

        persistEstimate();
    }

    public void updateFromCalibration(double energyChargedKwh, double socDelta) {
        if (socDelta < 10.0) return;

        double actualCapacity = energyChargedKwh / (socDelta / 100.0);
        double soh = (actualCapacity / nominalCapacityKwh) * 100.0;

        currentSoh = soh;
        estimationMethod = METHOD_CALIBRATION;
        rollingWindow.clear();
        for (int i = 0; i < WINDOW_SIZE; i++) rollingWindow.add(soh);
        sampleCount = WINDOW_SIZE;

        logger.info("Calibration SOH: " + String.format("%.1f", soh) + "% (" +
            String.format("%.1f", energyChargedKwh) + " kWh / " + String.format("%.1f", socDelta) + "% delta)");
        persistEstimate();
    }

    // ==================== GETTERS ====================

    public double getCurrentSoh() { return currentSoh; }
    public boolean hasEstimate() { return currentSoh > 0; }

    public double getEstimatedCapacityKwh() {
        if (!hasEstimate()) return -1;
        return (currentSoh / 100.0) * nominalCapacityKwh;
    }

    // ==================== PERSISTENCE ====================

    private void persistEstimate() {
        try {
            Properties props = new Properties();
            props.setProperty(PROP_SOH_PERCENT, String.valueOf(currentSoh));
            props.setProperty(PROP_ESTIMATION_METHOD, estimationMethod);
            props.setProperty(PROP_LAST_UPDATED, String.valueOf(System.currentTimeMillis()));
            props.setProperty(PROP_SAMPLE_COUNT, String.valueOf(sampleCount));

            try (FileOutputStream fos = new FileOutputStream(SOH_FILE)) {
                props.store(fos, "ABRP SOH Estimate");
            }
        } catch (Exception e) {
            logger.error("Failed to persist SOH: " + e.getMessage());
        }
    }

    // ==================== MAPPINGS ====================

    private static double mapAhToKwh(int ah) {
        switch (ah) {
            case 150: return 60.48;   // Atto 3
            case 153: return 82.56;   // Seal
            case 140: return 71.8;    // Seal U
            case 166: return 85.44;   // Han
            case 120: return 44.9;    // Dolphin Standard
            case 100: return 38.0;    // Seagull
            case 200: return 108.8;   // Tang
            case 176: return 56.4;    // Qin
            default:  return 0;       // Unknown — don't guess
        }
    }

    private static double matchNearestCapacity(double estimated) {
        double[] known = { 38.0, 44.9, 56.4, 60.48, 71.8, 82.56, 85.44, 108.8 };
        double bestMatch = 0;
        double bestDiff = Double.MAX_VALUE;
        for (double k : known) {
            double diff = Math.abs(estimated - k);
            if (diff / k < 0.10 && diff < bestDiff) {
                bestDiff = diff;
                bestMatch = k;
            }
        }
        return bestMatch;
    }

    private static double mapCarTypeToCapacity(String carType) {
        String ct = carType.toUpperCase();
        if (ct.contains("SEAL") && !ct.contains("SEAL U") && !ct.contains("SEALU") && !ct.contains("SEAL-U")) return 82.56;
        if (ct.contains("SEAL U") || ct.contains("SEALU") || ct.contains("SEAL-U") || ct.contains("S7")) return 71.8;
        if (ct.contains("HAN") || ct.contains("DM-P")) return 85.44;
        if (ct.contains("TANG")) return 108.8;
        if (ct.contains("ATTO") || ct.contains("YUAN") || ct.contains("S1")) return 60.48;
        if (ct.contains("DOLPHIN") || ct.contains("EA1")) return 60.48;
        if (ct.contains("SEAGULL") || ct.contains("DOLPHIN MINI")) return 38.0;
        if (ct.contains("E6")) return 71.7;
        if (ct.contains("SONG")) return 71.8;
        return 0;
    }
}
