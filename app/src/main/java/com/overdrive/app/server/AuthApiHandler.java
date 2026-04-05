package com.overdrive.app.server;

import com.overdrive.app.auth.AuthManager;
import com.overdrive.app.daemon.CameraDaemon;

import org.json.JSONObject;

import java.io.OutputStream;

/**
 * HTTP API handler for authentication endpoints.
 * 
 * Simple device token authentication - no external OAuth needed.
 * 
 * Endpoints:
 * - GET  /auth/status     - Check auth status
 * - POST /auth/token      - Validate device token and get JWT
 * - POST /auth/logout     - Clear session
 * 
 * All endpoints return JSON responses.
 */
public class AuthApiHandler {
    
    /**
     * Handle auth API requests.
     */
    public static boolean handle(String method, String path, String body, OutputStream out) throws Exception {
        
        // GET /auth/status - Check auth status
        if (path.equals("/auth/status") && method.equals("GET")) {
            return handleStatus(out);
        }
        
        // POST /auth/token - Validate device token and get JWT
        if (path.equals("/auth/token") && method.equals("POST")) {
            return handleTokenValidation(body, out);
        }
        
        // POST /auth/logout - Logout
        if (path.equals("/auth/logout") && method.equals("POST")) {
            return handleLogout(out);
        }
        
        return false;
    }
    
    /**
     * GET /auth/status
     * Returns device info.
     */
    private static boolean handleStatus(OutputStream out) throws Exception {
        AuthManager.AuthState state = AuthManager.getState();
        
        JSONObject response = new JSONObject();
        response.put("status", "ok");
        
        if (state != null) {
            response.put("deviceId", state.deviceId);
        } else {
            response.put("deviceId", "unknown");
        }
        
        HttpResponse.sendJson(out, response.toString());
        return true;
    }
    
    /**
     * POST /auth/token
     * Validates device token and returns JWT session.
     * 
     * Request: { "token": "byd-xxxxxxxx-yyyyyyyy" }
     * Response: { "success": true, "jwt": "..." }
     */
    private static boolean handleTokenValidation(String body, OutputStream out) throws Exception {
        JSONObject response = new JSONObject();
        
        try {
            JSONObject request = new JSONObject(body);
            String token = request.optString("token", "");
            
            boolean valid = AuthManager.validateDeviceToken(token);
            
            if (valid) {
                // Generate JWT session
                String jwt = AuthManager.generateJwt();
                
                AuthManager.AuthState state = AuthManager.getState();
                response.put("success", true);
                response.put("jwt", jwt);
                response.put("deviceId", state.deviceId);
                response.put("expiresIn", 365 * 24 * 60 * 60); // 1 year in seconds (matches JWT expiry)
                
                log("Token validated for device: " + state.deviceId);
            } else {
                response.put("success", false);
                response.put("error", "Invalid device token");
                log("Invalid token attempt");
            }
            
        } catch (Exception e) {
            response.put("success", false);
            response.put("error", "Invalid request: " + e.getMessage());
        }
        
        HttpResponse.sendJson(out, response.toString());
        return true;
    }
    
    /**
     * POST /auth/logout
     * Logs out the user. Client should clear stored JWT.
     */
    private static boolean handleLogout(OutputStream out) throws Exception {
        JSONObject response = new JSONObject();
        response.put("success", true);
        response.put("message", "Logged out");
        
        HttpResponse.sendJson(out, response.toString());
        return true;
    }
    
    private static void log(String message) {
        CameraDaemon.log("AUTH: " + message);
    }
}
