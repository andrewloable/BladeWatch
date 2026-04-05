package com.overdrive.app.auth;

import android.util.Base64;

import com.overdrive.app.daemon.CameraDaemon;

import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

/**
 * Authentication Manager for BYD Champ.
 * 
 * Simple device token authentication - no external OAuth needed.
 * Works with any tunnel (Cloudflare, Zrok, etc.) since no origin validation required.
 * 
 * Auth Flow:
 * 1. User enters device token (displayed in app)
 * 2. Token validated → JWT session created
 * 3. JWT used for subsequent requests (7 day expiry)
 * 
 * Security:
 * - Device token = deviceId + secret (e.g., byd-a1b2c3d4-x7k9m2p5)
 * - JWT signed with HMAC-SHA256 using device secret
 * - Token persists across app reinstalls (stored in /data/local/tmp/)
 */
public class AuthManager {
    
    // File paths (daemon-compatible, survives app reinstall)
    private static final String AUTH_FILE = "/data/local/tmp/.byd_auth.json";
    private static final String DEVICE_ID_FILE = "/data/local/tmp/.overdrive_device_id";
    
    // JWT settings
    private static final long JWT_EXPIRY_MS = 365 * 24 * 60 * 60 * 1000L; // 1 year (effectively indefinite)
    private static final String JWT_ALGORITHM = "HS256";
    
    // Cached auth state
    private static volatile AuthState cachedState = null;
    
    /**
     * Auth state persisted to file.
     */
    public static class AuthState {
        public String deviceId;
        public String deviceSecret;      // Random secret for token generation
        public long lastAccess;          // Last successful auth timestamp
        
        public String getDeviceToken() {
            return deviceId + "-" + deviceSecret;
        }
        
        /**
         * Get just the secret part (for display in app UI).
         * User combines with device ID shown on login page.
         */
        public String getSecret() {
            return deviceSecret;
        }
        
        public JSONObject toJson() {
            try {
                JSONObject json = new JSONObject();
                json.put("deviceId", deviceId);
                json.put("deviceSecret", deviceSecret);
                json.put("lastAccess", lastAccess);
                return json;
            } catch (Exception e) {
                return new JSONObject();
            }
        }
        
        public static AuthState fromJson(JSONObject json) {
            AuthState state = new AuthState();
            state.deviceId = json.optString("deviceId", "");
            state.deviceSecret = json.optString("deviceSecret", "");
            state.lastAccess = json.optLong("lastAccess", 0);
            return state;
        }
    }
    
    /**
     * JWT validation result.
     */
    public static class JwtValidation {
        public boolean valid;
        public String deviceId;
        public String error;
        
        public static JwtValidation success(String deviceId) {
            JwtValidation v = new JwtValidation();
            v.valid = true;
            v.deviceId = deviceId;
            return v;
        }
        
        public static JwtValidation failure(String error) {
            JwtValidation v = new JwtValidation();
            v.valid = false;
            v.error = error;
            return v;
        }
    }
    
    // ==================== INITIALIZATION ====================
    
    /**
     * Initialize auth state. Creates device secret if not exists.
     * Call this on app/daemon startup.
     */
    public static synchronized AuthState initialize() {
        AuthState state = loadState();
        
        if (state == null) {
            state = new AuthState();
        }
        
        // Ensure device ID is set
        if (state.deviceId == null || state.deviceId.isEmpty()) {
            state.deviceId = loadDeviceId();
        }
        
        // Generate secret if not exists
        if (state.deviceSecret == null || state.deviceSecret.isEmpty()) {
            state.deviceSecret = generateSecret(8);
            saveState(state);
            log("Generated new device secret");
        }
        
        cachedState = state;
        log("Auth initialized. Device: " + state.deviceId);
        return state;
    }
    
    /**
     * Get current auth state (cached).
     * Checks if device ID file has been updated and reloads if needed.
     * This handles the case where daemon starts before app writes the device ID file.
     */
    public static AuthState getState() {
        if (cachedState == null) {
            cachedState = loadState();
            if (cachedState == null) {
                initialize();
            }
        } else {
            // Check if device ID file has a different ID (app may have written it)
            // This is important when daemon starts before app and generates temp ID
            String fileDeviceId = loadDeviceIdFromFile();
            if (fileDeviceId != null && !fileDeviceId.equals(cachedState.deviceId)) {
                log("Device ID changed in file: " + cachedState.deviceId + " -> " + fileDeviceId);
                cachedState.deviceId = fileDeviceId;
                // Keep the same secret - don't regenerate
                // This allows existing sessions to continue working
                saveState(cachedState);
                log("Auth state updated with new device ID (kept existing secret)");
            } else if (fileDeviceId == null && cachedState.deviceId != null && cachedState.deviceId.startsWith("byd-")) {
                // File doesn't exist but we have a cached ID - check if it's a temp ID
                // Temp IDs are random, real IDs are hash-based and consistent
                // We can't easily distinguish, so just log for debugging
                log("Device ID file not found, using cached: " + cachedState.deviceId);
            }
        }
        return cachedState;
    }
    
    /**
     * Load device ID from file only (no fallback generation).
     */
    private static String loadDeviceIdFromFile() {
        try {
            File file = new File(DEVICE_ID_FILE);
            if (file.exists()) {
                try (BufferedReader reader = new BufferedReader(new FileReader(file))) {
                    String id = reader.readLine();
                    if (id != null && id.startsWith("byd-")) {
                        return id.trim();
                    }
                }
            }
        } catch (Exception e) {
            // Ignore
        }
        return null;
    }
    
    // ==================== TOKEN VALIDATION ====================
    
    /**
     * Validate device token.
     * Token format: {deviceId}-{secret}
     */
    public static boolean validateDeviceToken(String token) {
        if (token == null || token.isEmpty()) {
            return false;
        }
        
        AuthState state = getState();
        if (state == null) {
            return false;
        }
        
        String expectedToken = state.getDeviceToken();
        return token.equals(expectedToken);
    }
    
    /**
     * Regenerate device token (invalidates all sessions).
     */
    public static synchronized String regenerateToken() {
        AuthState state = getState();
        if (state == null) {
            state = new AuthState();
            state.deviceId = loadDeviceId();
        }
        
        // Generate new secret
        state.deviceSecret = generateSecret(8);
        
        saveState(state);
        cachedState = state;
        
        log("Token regenerated. New token: " + state.getDeviceToken());
        return state.getDeviceToken();
    }
    
    // ==================== JWT MANAGEMENT ====================
    
    /**
     * Generate a JWT session token.
     * 
     * @return JWT string
     */
    public static String generateJwt() {
        AuthState state = getState();
        if (state == null) {
            return null;
        }
        
        try {
            long now = System.currentTimeMillis() / 1000;
            long exp = now + (JWT_EXPIRY_MS / 1000);
            
            // Header
            JSONObject header = new JSONObject();
            header.put("alg", JWT_ALGORITHM);
            header.put("typ", "JWT");
            
            // Payload
            JSONObject payload = new JSONObject();
            payload.put("sub", state.deviceId);
            payload.put("iat", now);
            payload.put("exp", exp);
            
            // Encode
            String headerB64 = base64UrlEncode(header.toString().getBytes(StandardCharsets.UTF_8));
            String payloadB64 = base64UrlEncode(payload.toString().getBytes(StandardCharsets.UTF_8));
            String content = headerB64 + "." + payloadB64;
            
            // Sign
            String signature = hmacSha256(content, state.deviceSecret);
            
            // Update last access
            state.lastAccess = System.currentTimeMillis();
            saveState(state);
            
            return content + "." + signature;
            
        } catch (Exception e) {
            log("JWT generation error: " + e.getMessage());
            return null;
        }
    }
    
    /**
     * Invalidate cached auth state.
     * Called via IPC when app regenerates token.
     * Next JWT validation will reload from file.
     */
    public static synchronized void invalidateCache() {
        cachedState = null;
        log("Auth cache invalidated - will reload on next validation");
    }
    
    /**
     * Validate a JWT and extract claims.
     * Uses cached state for performance. Cache is invalidated via IPC when token changes.
     */
    public static JwtValidation validateJwt(String jwt) {
        if (jwt == null || jwt.isEmpty()) {
            return JwtValidation.failure("No token provided");
        }
        
        // Remove "Bearer " prefix if present
        if (jwt.startsWith("Bearer ")) {
            jwt = jwt.substring(7);
        }
        
        String[] parts = jwt.split("\\.");
        if (parts.length != 3) {
            return JwtValidation.failure("Invalid token format");
        }
        
        // Use cached state for performance
        // Cache is invalidated via IPC (auth_invalidate command) when app regenerates token
        AuthState state = getState();
        if (state == null) {
            return JwtValidation.failure("Auth not initialized");
        }
        
        try {
            // Verify signature with current secret
            String content = parts[0] + "." + parts[1];
            String expectedSig = hmacSha256(content, state.deviceSecret);
            
            if (!expectedSig.equals(parts[2])) {
                log("JWT signature mismatch - token may have been regenerated");
                return JwtValidation.failure("Invalid signature");
            }
            
            // Decode payload
            String payloadJson = new String(base64UrlDecode(parts[1]), StandardCharsets.UTF_8);
            JSONObject payload = new JSONObject(payloadJson);
            
            // Check expiry
            long exp = payload.getLong("exp");
            if (System.currentTimeMillis() / 1000 > exp) {
                return JwtValidation.failure("Token expired");
            }
            
            // Check device ID matches
            String tokenDeviceId = payload.getString("sub");
            if (!tokenDeviceId.equals(state.deviceId)) {
                return JwtValidation.failure("Device mismatch");
            }
            
            return JwtValidation.success(tokenDeviceId);
            
        } catch (Exception e) {
            return JwtValidation.failure("Token validation error: " + e.getMessage());
        }
    }
    
    // ==================== FILE I/O ====================
    
    private static AuthState loadState() {
        try {
            File file = new File(AUTH_FILE);
            if (!file.exists()) {
                log("Auth file does not exist: " + AUTH_FILE);
                return null;
            }
            
            if (!file.canRead()) {
                log("Cannot read auth file: " + AUTH_FILE);
                return null;
            }
            
            StringBuilder sb = new StringBuilder();
            try (BufferedReader reader = new BufferedReader(new FileReader(file))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    sb.append(line);
                }
            }
            
            String content = sb.toString();
            if (content.isEmpty()) {
                log("Auth file is empty");
                return null;
            }
            
            JSONObject json = new JSONObject(content);
            AuthState state = AuthState.fromJson(json);
            log("Loaded auth state: deviceId=" + state.deviceId + ", hasSecret=" + (state.deviceSecret != null && !state.deviceSecret.isEmpty()));
            return state;
            
        } catch (Exception e) {
            log("Failed to load auth state: " + e.getMessage());
            return null;
        }
    }
    
    private static void saveState(AuthState state) {
        try {
            File file = new File(AUTH_FILE);
            File parent = file.getParentFile();
            if (parent != null && !parent.exists()) {
                parent.mkdirs();
            }
            
            try (FileWriter writer = new FileWriter(file)) {
                writer.write(state.toJson().toString(2));
            }
            // Set permissions (readable/writable by all - needed for daemon)
            file.setReadable(true, false);
            file.setWritable(true, false);
            
            log("Saved auth state to " + AUTH_FILE);
        } catch (Exception e) {
            log("Failed to save auth state: " + e.getMessage());
        }
    }
    
    private static String loadDeviceId() {
        // Try to read from file - this should be created by the app via ADB shell
        try {
            File file = new File(DEVICE_ID_FILE);
            if (file.exists()) {
                try (BufferedReader reader = new BufferedReader(new FileReader(file))) {
                    String id = reader.readLine();
                    if (id != null && id.startsWith("byd-")) {
                        log("Loaded device ID from file: " + id.trim());
                        return id.trim();
                    }
                }
            }
        } catch (Exception e) {
            log("Error reading device ID file: " + e.getMessage());
        }
        
        // File doesn't exist or is invalid - return a temporary ID
        // The app will create the proper ID file via ADB shell
        String tempId = "byd-" + generateSecret(8);
        log("Device ID file not found, using temporary ID: " + tempId);
        // DON'T save to file - let the app do it via ADB shell
        return tempId;
    }
    
    private static void saveDeviceId(String id) {
        // This is called but will likely fail due to permissions
        // The app should use ADB shell to write the file instead
        try {
            File file = new File(DEVICE_ID_FILE);
            File parent = file.getParentFile();
            if (parent != null && !parent.exists()) {
                parent.mkdirs();
            }
            try (FileWriter writer = new FileWriter(file)) {
                writer.write(id);
            }
            file.setReadable(true, false);
            file.setWritable(true, false);
            log("Saved device ID to file: " + id);
        } catch (Exception e) {
            log("Failed to save device ID (expected if running as app): " + e.getMessage());
        }
    }
    
    // ==================== CRYPTO UTILS ====================
    
    private static String generateSecret(int length) {
        String chars = "abcdefghijklmnopqrstuvwxyz0123456789";
        SecureRandom random = new SecureRandom();
        StringBuilder sb = new StringBuilder(length);
        for (int i = 0; i < length; i++) {
            sb.append(chars.charAt(random.nextInt(chars.length())));
        }
        return sb.toString();
    }
    
    private static String hmacSha256(String data, String secret) throws Exception {
        Mac mac = Mac.getInstance("HmacSHA256");
        SecretKeySpec keySpec = new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
        mac.init(keySpec);
        byte[] hash = mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
        return base64UrlEncode(hash);
    }
    
    private static String base64UrlEncode(byte[] data) {
        return Base64.encodeToString(data, Base64.NO_WRAP | Base64.URL_SAFE | Base64.NO_PADDING);
    }
    
    private static byte[] base64UrlDecode(String data) {
        return Base64.decode(data, Base64.URL_SAFE | Base64.NO_PADDING);
    }
    
    private static void log(String message) {
        CameraDaemon.log("AUTH: " + message);
    }
}
