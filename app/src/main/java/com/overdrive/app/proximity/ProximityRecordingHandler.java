package com.overdrive.app.proximity;

import com.overdrive.app.logging.DaemonLogger;
import com.overdrive.app.storage.StorageManager;
import com.overdrive.app.surveillance.GpuSurveillancePipeline;
import com.overdrive.app.telegram.TelegramNotifier;

import java.io.File;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

/**
 * Proximity Recording Handler
 * 
 * Manages the recording lifecycle for Proximity Guard events:
 * - Pre-buffer capture
 * - Recording start/stop
 * - File naming with proximity_ prefix
 * - Storage management
 * - Telegram notifications
 */
public class ProximityRecordingHandler {
    private static final DaemonLogger logger = DaemonLogger.getInstance("ProximityRecordingHandler");
    
    private final GpuSurveillancePipeline pipeline;
    private final StorageManager storageManager;
    
    private File outputDir;
    private String currentTriggerLevel;
    private boolean isRecording = false;
    
    public ProximityRecordingHandler(GpuSurveillancePipeline pipeline) {
        this.pipeline = pipeline;
        this.storageManager = StorageManager.getInstance();
        this.outputDir = storageManager.getProximityDir();
    }
    
    /**
     * Start proximity recording.
     * 
     * @param triggerLevel The trigger level that caused recording ("YELLOW" or "RED")
     */
    public void startRecording(String triggerLevel) {
        if (isRecording) {
            logger.warn("Already recording, ignoring start request");
            return;
        }
        
        currentTriggerLevel = triggerLevel;
        
        try {
            // Ensure space available (reserve 50MB)
            boolean spaceAvailable = storageManager.ensureProximitySpace(50 * 1024 * 1024);
            if (!spaceAvailable) {
                logger.error("Insufficient space for proximity recording");
                return;
            }
            
            // Get proximity output directory
            outputDir = storageManager.getProximityDir();
            
            // Start recording with proximity directory and prefix
            pipeline.startRecording(outputDir, "proximity");
            isRecording = true;
            
            logger.info("Proximity recording started: trigger=" + triggerLevel + " dir=" + outputDir.getAbsolutePath());
            
            // Send Telegram notification
            sendTelegramNotification(triggerLevel);

            // Publish to NotificationBus → push notifications
            publishProximityNotification(triggerLevel);

        } catch (Exception e) {
            logger.error("Failed to start proximity recording: " + e.getMessage());
            e.printStackTrace();
        }
    }

    /**
     * Publish a proximity notification onto the cross-cutting NotificationBus.
     *
     * <p>RED trigger ({@code <0.5m}) is treated as critical so it overrides
     * the user's quiet hours. YELLOW ({@code 0.5–0.8m}) is warn.
     */
    private void publishProximityNotification(String triggerLevel) {
        try {
            boolean red = "RED".equals(triggerLevel);
            org.json.JSONObject data = new org.json.JSONObject();
            data.put("triggerLevel", triggerLevel);

            // The pipeline's encoder was started above with the proximity_
            // prefix. Pull the active output path so the push deep-links to
            // the exact clip being recorded and renders its thumbnail.
            String filename = activeRecordingFilename();
            String url;
            if (filename != null) {
                String enc = java.net.URLEncoder.encode(filename, "UTF-8");
                data.put("filename", filename);
                data.put("snapshot", "/thumb/" + enc);
                url = "/events.html?filter=proximity&file=" + enc;
            } else {
                url = "/events.html?filter=proximity";
            }

            com.overdrive.app.notifications.NotificationBus.get().publish(
                    new com.overdrive.app.notifications.NotificationEvent(
                            "surveillance.proximity",
                            red
                                    ? com.overdrive.app.notifications.NotificationEvent.Severity.CRITICAL
                                    : com.overdrive.app.notifications.NotificationEvent.Severity.WARN,
                            red ? "Object very close" : "Object nearby",
                            red ? "Within 0.5 m" : "Within 0.8 m",
                            "proximity-" + triggerLevel,
                            url,
                            data));
        } catch (Throwable t) {
            logger.debug("publishProximityNotification failed: " + t.getMessage());
        }
    }

    private String activeRecordingFilename() {
        try {
            if (pipeline == null) return null;
            com.overdrive.app.surveillance.HardwareEventRecorderGpu enc = pipeline.getEncoder();
            if (enc == null) return null;
            String path = enc.getCurrentOutputPath();
            if (path == null || path.isEmpty()) return null;
            int slash = path.lastIndexOf('/');
            return slash >= 0 ? path.substring(slash + 1) : path;
        } catch (Throwable t) {
            return null;
        }
    }
    
    /**
     * Stop proximity recording.
     */
    public void stopRecording() {
        if (!isRecording) {
            return;
        }
        
        try {
            // Stop recording
            pipeline.stopRecording();
            isRecording = false;
            
            logger.info("Proximity recording stopped");
            
            // Trigger cleanup
            storageManager.onProximityFileSaved();
            
        } catch (Exception e) {
            logger.error("Failed to stop proximity recording: " + e.getMessage());
            e.printStackTrace();
        }
    }
    
    /**
     * Extend current recording (new trigger while already recording).
     * Does not create a new file - just logs the extension.
     * The 2-minute segment handling is done by the encoder.
     * 
     * @param triggerLevel The new trigger level
     */
    public void extendRecording(String triggerLevel) {
        if (!isRecording) {
            logger.warn("Cannot extend - not recording");
            return;
        }
        
        logger.info("Extending proximity recording: new trigger=" + triggerLevel + 
                   " (previous=" + currentTriggerLevel + ")");
        
        // Update trigger level if higher priority
        if (triggerLevel.equals("RED") && !currentTriggerLevel.equals("RED")) {
            currentTriggerLevel = triggerLevel;
            logger.info("Upgraded trigger level to RED");
        }
    }
    
    /**
     * Check if currently recording.
     */
    public boolean isRecording() {
        return isRecording;
    }
    
    /**
     * Get current trigger level.
     */
    public String getCurrentTriggerLevel() {
        return currentTriggerLevel;
    }
    
    // ==================== PRIVATE METHODS ====================
    
    /**
     * Send Telegram notification for proximity alert.
     */
    private void sendTelegramNotification(String triggerLevel) {
        try {
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US);
            String timestamp = sdf.format(new Date());
            
            String emoji = "🚨";
            String distance = triggerLevel.equals("RED") ? "0-0.5m" : "0-0.8m";
            
            String message = emoji + " Proximity Alert\n" +
                           "Time: " + timestamp + "\n" +
                           "Trigger: " + triggerLevel + " (" + distance + ")\n" +
                           "Recording started...";
            
            TelegramNotifier.sendMessage(message);
            logger.info("Telegram notification sent: " + triggerLevel);
            
        } catch (Exception e) {
            logger.error("Failed to send Telegram notification: " + e.getMessage());
        }
    }
}
