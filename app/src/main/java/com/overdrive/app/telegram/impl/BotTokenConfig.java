package com.overdrive.app.telegram.impl;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;

import androidx.annotation.Nullable;
import androidx.security.crypto.EncryptedSharedPreferences;
import androidx.security.crypto.MasterKey;

import com.overdrive.app.telegram.IBotTokenConfig;
import com.overdrive.app.telegram.model.BotInfo;
import com.overdrive.app.telegram.model.ValidationResult;

import org.json.JSONObject;

import java.io.IOException;
import java.security.GeneralSecurityException;
import java.util.concurrent.TimeUnit;

import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

/**
 * Bot token configuration with encrypted storage and Telegram API validation.
 * 
 * Note: Daemon config file (/data/local/tmp/telegram_config.properties) is written
 * via ADB shell from TelegramSettingsFragment because app process can't write to
 * /data/local/tmp directly.
 */
public class BotTokenConfig implements IBotTokenConfig {
    
    private static final String TAG = "BotTokenConfig";
    
    private static final String PREFS_NAME = "telegram_bot_prefs";
    private static final String KEY_TOKEN = "bot_token";
    private static final String KEY_BOT_ID = "bot_id";
    private static final String KEY_BOT_USERNAME = "bot_username";
    private static final String KEY_BOT_FIRST_NAME = "bot_first_name";
    
    private static final String TELEGRAM_API_BASE = "https://api.telegram.org/bot";
    
    private final SharedPreferences prefs;
    private final OkHttpClient httpClient;
    
    public BotTokenConfig(Context context) {
        this.prefs = createEncryptedPrefs(context);
        this.httpClient = new OkHttpClient.Builder()
                .connectTimeout(10, TimeUnit.SECONDS)
                .readTimeout(10, TimeUnit.SECONDS)
                .build();
    }
    
    /**
     * Constructor with custom OkHttpClient (for proxy support).
     */
    public BotTokenConfig(Context context, OkHttpClient httpClient) {
        this.prefs = createEncryptedPrefs(context);
        this.httpClient = httpClient;
    }
    
    private SharedPreferences createEncryptedPrefs(Context context) {
        try {
            MasterKey masterKey = new MasterKey.Builder(context)
                    .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                    .build();
            
            return EncryptedSharedPreferences.create(
                    context,
                    PREFS_NAME,
                    masterKey,
                    EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                    EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            );
        } catch (GeneralSecurityException | IOException e) {
            return context.getSharedPreferences(PREFS_NAME + "_fallback", Context.MODE_PRIVATE);
        }
    }
    
    @Override
    public void saveToken(String token) {
        prefs.edit().putString(KEY_TOKEN, token).apply();
        // Note: Daemon config file is written via ADB shell from TelegramSettingsFragment
        // because app process can't write to /data/local/tmp directly
    }
    
    /**
     * Note: Direct file write to /data/local/tmp doesn't work from app process.
     * Config writing is handled via ADB shell in TelegramSettingsFragment.
     * This method is kept for reference but is effectively a no-op.
     */
    @SuppressWarnings("unused")
    private void writeToDaemonConfig(String key, String value) {
        // App process (UID 10xxx) cannot write to /data/local/tmp
        // Config is written via ADB shell from TelegramSettingsFragment
        Log.d(TAG, "writeToDaemonConfig called - delegated to TelegramSettingsFragment via ADB shell");
    }
    
    /**
     * Note: Direct file write to /data/local/tmp doesn't work from app process.
     * Owner info is written by the daemon itself when /pair command is received.
     * This method is kept for reference but is effectively a no-op.
     */
    @SuppressWarnings("unused")
    public void writeOwnerToDaemonConfig(long chatId, String username, String firstName) {
        // App process (UID 10xxx) cannot write to /data/local/tmp
        // Owner is saved by daemon when /pair command is received
        Log.d(TAG, "writeOwnerToDaemonConfig called - owner is saved by daemon via /pair command");
    }
    
    @Override
    @Nullable
    public String getToken() {
        return prefs.getString(KEY_TOKEN, null);
    }
    
    @Override
    public boolean hasToken() {
        String token = getToken();
        return token != null && !token.isEmpty();
    }
    
    @Override
    public void clearToken() {
        prefs.edit()
                .remove(KEY_TOKEN)
                .remove(KEY_BOT_ID)
                .remove(KEY_BOT_USERNAME)
                .remove(KEY_BOT_FIRST_NAME)
                .apply();
        
        // Also clear from daemon config
        clearTokenFromDaemonConfig();
    }
    
    /**
     * Note: Direct file write to /data/local/tmp doesn't work from app process.
     * Token clearing from daemon config should be handled via ADB shell if needed.
     */
    @SuppressWarnings("unused")
    private void clearTokenFromDaemonConfig() {
        // App process (UID 10xxx) cannot write to /data/local/tmp
        Log.d(TAG, "clearTokenFromDaemonConfig called - would need ADB shell to clear");
    }
    
    @Override
    public ValidationResult validateToken(String token) {
        if (token == null || token.isEmpty()) {
            return ValidationResult.failure("Token is empty");
        }
        
        // Basic format check: should be like "123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
        if (!token.contains(":") || token.length() < 30) {
            return ValidationResult.failure("Invalid token format");
        }
        
        try {
            String url = TELEGRAM_API_BASE + token + "/getMe";
            Request request = new Request.Builder()
                    .url(url)
                    .get()
                    .build();
            
            try (Response response = httpClient.newCall(request).execute()) {
                if (!response.isSuccessful()) {
                    return ValidationResult.failure("HTTP " + response.code());
                }
                
                String body = response.body() != null ? response.body().string() : "";
                JSONObject json = new JSONObject(body);
                
                if (!json.optBoolean("ok", false)) {
                    String desc = json.optString("description", "Unknown error");
                    return ValidationResult.failure(desc);
                }
                
                JSONObject result = json.getJSONObject("result");
                BotInfo botInfo = new BotInfo(
                        result.getLong("id"),
                        result.optString("username", ""),
                        result.optString("first_name", "")
                );
                
                return ValidationResult.success(botInfo);
            }
        } catch (Exception e) {
            return ValidationResult.failure("Network error: " + e.getMessage());
        }
    }
    
    @Override
    @Nullable
    public BotInfo getCachedBotInfo() {
        long botId = prefs.getLong(KEY_BOT_ID, -1);
        if (botId == -1) return null;
        
        return new BotInfo(
                botId,
                prefs.getString(KEY_BOT_USERNAME, ""),
                prefs.getString(KEY_BOT_FIRST_NAME, "")
        );
    }
    
    @Override
    public void saveBotInfo(BotInfo botInfo) {
        prefs.edit()
                .putLong(KEY_BOT_ID, botInfo.getBotId())
                .putString(KEY_BOT_USERNAME, botInfo.getUsername())
                .putString(KEY_BOT_FIRST_NAME, botInfo.getFirstName())
                .apply();
    }
}
