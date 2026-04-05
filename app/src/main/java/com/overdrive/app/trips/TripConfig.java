package com.overdrive.app.trips;

import com.overdrive.app.config.UnifiedConfigManager;
import com.overdrive.app.logging.DaemonLogger;
import org.json.JSONObject;

/**
 * Persistent configuration for Trip Analytics.
 *
 * Uses UnifiedConfigManager to store config in the "tripAnalytics" section
 * of /data/local/tmp/overdrive_config.json. Storage settings (storageType,
 * storageLimitMb) are delegated to StorageManager — this class only manages
 * the enabled toggle.
 */
public class TripConfig {

    private static final String TAG = "TripConfig";
    private static final DaemonLogger logger = DaemonLogger.getInstance(TAG);
    private static final String SECTION = "tripAnalytics";

    private boolean enabled = false;
    private double electricityRate = 0;  // Cost per kWh
    private String currency = "";        // Currency symbol (₹, $, €, £)

    public TripConfig() {
        this.enabled = false;
    }

    /**
     * Load configuration from UnifiedConfigManager.
     *
     * @return true if the section was read successfully, false otherwise
     */
    public boolean load() {
        try {
            JSONObject section = UnifiedConfigManager.loadConfig().optJSONObject(SECTION);
            if (section != null) {
                enabled = section.optBoolean("enabled", false);
                electricityRate = section.optDouble("electricityRate", 0);
                currency = section.optString("currency", "");
                logger.info("Config loaded: enabled=" + enabled + " rate=" + electricityRate + " " + currency);
                return true;
            } else {
                logger.info("No tripAnalytics section in UnifiedConfigManager, using defaults");
                return false;
            }
        } catch (Exception e) {
            logger.error("Config load error: " + e.getMessage());
            enabled = false;
            return false;
        }
    }

    /**
     * Save current configuration to UnifiedConfigManager.
     *
     * @return true if the config was written successfully, false otherwise
     */
    public boolean save() {
        try {
            JSONObject section = new JSONObject();
            section.put("enabled", enabled);
            section.put("electricityRate", electricityRate);
            section.put("currency", currency);
            boolean success = UnifiedConfigManager.updateSection(SECTION, section);
            if (success) {
                logger.info("Config saved to UnifiedConfigManager: enabled=" + enabled);
            }
            return success;
        } catch (Exception e) {
            logger.error("Config save error: " + e.getMessage());
            return false;
        }
    }

    // ==================== GETTERS ====================

    public boolean isEnabled() {
        return enabled;
    }

    public double getElectricityRate() {
        return electricityRate;
    }

    public String getCurrency() {
        return currency;
    }

    // ==================== SETTERS ====================

    public void setEnabled(boolean enabled) {
        this.enabled = enabled;
    }

    public void setElectricityRate(double rate) {
        this.electricityRate = rate;
    }

    public void setCurrency(String currency) {
        this.currency = currency != null ? currency : "";
    }

    // ==================== UTILITY ====================

    /**
     * Serialize configuration to a JSONObject for API responses.
     */
    public JSONObject toJson() {
        JSONObject json = new JSONObject();
        try {
            json.put("enabled", enabled);
            json.put("electricityRate", electricityRate);
            json.put("currency", currency);
        } catch (Exception e) {
            logger.error("toJson error: " + e.getMessage());
        }
        return json;
    }

    @Override
    public String toString() {
        return "TripConfig{enabled=" + enabled + '}';
    }
}
