package com.overdrive.app.telegram;

import android.util.Log;

import com.overdrive.app.telegram.event.CriticalEvent;
import com.overdrive.app.telegram.event.MotionEvent;
import com.overdrive.app.telegram.event.TelegramEventBus;
import com.overdrive.app.telegram.event.TunnelEvent;
import com.overdrive.app.telegram.event.VideoEvent;

import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Socket;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * Static helper for emitting Telegram events from anywhere in the app.
 * 
 * Sends notifications via IPC to TelegramBotDaemon (port 19877).
 * Also publishes to TelegramEventBus for in-app listeners.
 * 
 * Usage:
 *   TelegramNotifier.notifyVideoRecorded("/path/to/video.mp4", "person", 30);
 *   TelegramNotifier.notifyTunnelUrl("https://xxx.trycloudflare.com", true);
 *   TelegramNotifier.notifyMotion("person", 0.95f);
 *   TelegramNotifier.notifyCritical(CriticalEvent.CriticalType.LOW_BATTERY, "12%");
 */
public class TelegramNotifier {
    
    private static final String TAG = "TelegramNotifier";
    private static final int IPC_PORT = 19878;  // Telegram daemon IPC port
    
    // Background executor for IPC calls
    private static final ExecutorService executor = Executors.newSingleThreadExecutor(r -> {
        Thread t = new Thread(r, "TelegramNotifierIPC");
        t.setDaemon(true);
        return t;
    });
    
    /**
     * Notify that a video recording was finalized.
     * 
     * @param filePath Path to the video file
     * @param aiDetection AI detection label (e.g., "person", "car") or null
     * @param durationSeconds Duration in seconds
     */
    public static void notifyVideoRecorded(String filePath, String aiDetection, int durationSeconds) {
        // Publish to in-app event bus
        TelegramEventBus.getInstance().publish(
                new VideoEvent(filePath, aiDetection, durationSeconds)
        );
        
        // Send via IPC to daemon
        executor.execute(() -> {
            try {
                JSONObject cmd = new JSONObject();
                cmd.put("cmd", "sendVideo");
                cmd.put("path", filePath);
                String caption = "📹 Recording";
                if (aiDetection != null) caption += " (" + aiDetection + ")";
                caption += " - " + durationSeconds + "s";
                cmd.put("caption", caption);
                sendIpc(cmd);
            } catch (Exception e) {
                Log.e(TAG, "notifyVideoRecorded IPC error", e);
            }
        });
    }
    
    /**
     * Notify that tunnel URL was created or changed.
     * 
     * @param url The tunnel URL
     * @param isNew true if new tunnel, false if URL changed
     */
    public static void notifyTunnelUrl(String url, boolean isNew) {
        Log.i(TAG, "notifyTunnelUrl called: url=" + url + ", isNew=" + isNew);
        
        // Publish to in-app event bus
        TelegramEventBus.getInstance().publish(
                new TunnelEvent(url, isNew)
        );
        
        // Send via IPC to daemon
        executor.execute(() -> {
            try {
                Log.i(TAG, "Sending tunnel URL via IPC to port " + IPC_PORT);
                JSONObject cmd = new JSONObject();
                cmd.put("cmd", "notifyTunnel");
                cmd.put("url", url);
                cmd.put("isNew", isNew);
                JSONObject response = sendIpc(cmd);
                Log.i(TAG, "IPC response: " + (response != null ? response.toString() : "null"));
            } catch (Exception e) {
                Log.e(TAG, "notifyTunnelUrl IPC error", e);
            }
        });
    }
    
    /**
     * Notify motion detection.
     * 
     * @param aiDetection AI detection label or null for generic motion
     * @param confidence Detection confidence (0-1)
     */
    public static void notifyMotion(String aiDetection, float confidence) {
        notifyMotion(aiDetection, confidence, null);
    }
    
    /**
     * Notify motion detection with video filename.
     * 
     * @param aiDetection AI detection label or null for generic motion
     * @param confidence Detection confidence (0-1)
     * @param videoFilename The event video filename (e.g., "event_20260113_143022.mp4")
     */
    public static void notifyMotion(String aiDetection, float confidence, String videoFilename) {
        // Publish to in-app event bus
        TelegramEventBus.getInstance().publish(
                new MotionEvent(aiDetection, confidence)
        );
        
        // Send via IPC to daemon
        executor.execute(() -> {
            try {
                JSONObject cmd = new JSONObject();
                cmd.put("cmd", "notifyMotion");
                cmd.put("detection", aiDetection != null ? aiDetection : "motion");
                cmd.put("confidence", confidence);
                if (videoFilename != null && !videoFilename.isEmpty()) {
                    cmd.put("videoFilename", videoFilename);
                }
                sendIpc(cmd);
            } catch (Exception e) {
                Log.e(TAG, "notifyMotion IPC error", e);
            }
        });
    }
    
    /**
     * Notify critical system event.
     * 
     * @param type Critical event type
     * @param details Additional details
     */
    public static void notifyCritical(CriticalEvent.CriticalType type, String details) {
        // Publish to in-app event bus
        TelegramEventBus.getInstance().publish(
                new CriticalEvent(type, details)
        );
        
        // Send via IPC to daemon
        executor.execute(() -> {
            try {
                JSONObject cmd = new JSONObject();
                cmd.put("cmd", "notifyCritical");
                cmd.put("type", type.name());
                cmd.put("details", details);
                sendIpc(cmd);
            } catch (Exception e) {
                Log.e(TAG, "notifyCritical IPC error", e);
            }
        });
    }
    
    /**
     * Send a custom text message via the daemon.
     */
    public static void sendMessage(String text) {
        executor.execute(() -> {
            try {
                JSONObject cmd = new JSONObject();
                cmd.put("cmd", "sendMessage");
                cmd.put("text", text);
                sendIpc(cmd);
            } catch (Exception e) {
                Log.e(TAG, "sendMessage IPC error", e);
            }
        });
    }
    
    /**
     * Notify proximity alert (Proximity Guard recording started).
     * 
     * @param timestamp Event timestamp in milliseconds
     * @param triggerLevel Trigger level ("RED" or "YELLOW")
     */
    public static void sendProximityAlert(long timestamp, String triggerLevel) {
        executor.execute(() -> {
            try {
                java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat(
                    "yyyy-MM-dd HH:mm:ss", java.util.Locale.US);
                String timeStr = sdf.format(new java.util.Date(timestamp));
                
                String emoji = "🚨";
                String distance = triggerLevel.equals("RED") ? "0-0.5m" : "0-0.8m";
                
                String message = emoji + " Proximity Alert\n" +
                               "Time: " + timeStr + "\n" +
                               "Trigger: " + triggerLevel + " (" + distance + ")\n" +
                               "Recording started...";
                
                JSONObject cmd = new JSONObject();
                cmd.put("cmd", "sendMessage");
                cmd.put("text", message);
                sendIpc(cmd);
                
                Log.i(TAG, "Proximity alert sent: " + triggerLevel);
            } catch (Exception e) {
                Log.e(TAG, "sendProximityAlert IPC error", e);
            }
        });
    }
    
    /**
     * Send IPC command to TelegramBotDaemon.
     */
    private static JSONObject sendIpc(JSONObject command) {
        Socket socket = null;
        try {
            socket = new Socket("127.0.0.1", IPC_PORT);
            socket.setSoTimeout(5000);
            
            PrintWriter writer = new PrintWriter(socket.getOutputStream(), true);
            BufferedReader reader = new BufferedReader(new InputStreamReader(socket.getInputStream()));
            
            writer.println(command.toString());
            String response = reader.readLine();
            
            if (response != null) {
                JSONObject json = new JSONObject(response);
                String status = json.optString("status", "");
                if (!"ok".equals(status)) {
                    Log.w(TAG, "IPC response: " + response);
                }
                return json;
            }
            return null;
        } catch (java.net.ConnectException e) {
            // Daemon not running - this is expected if telegram is disabled
            Log.d(TAG, "Telegram daemon not running");
            return null;
        } catch (Exception e) {
            Log.e(TAG, "IPC error: " + e.getMessage());
            return null;
        } finally {
            if (socket != null) {
                try { socket.close(); } catch (Exception ignored) {}
            }
        }
    }
}
