package com.overdrive.app.telegram.impl;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;

import androidx.annotation.Nullable;
import androidx.security.crypto.EncryptedSharedPreferences;
import androidx.security.crypto.MasterKey;

import com.overdrive.app.telegram.IOwnerStore;
import com.overdrive.app.telegram.model.NotificationPreferences;
import com.overdrive.app.telegram.model.OwnerInfo;

import java.io.IOException;
import java.security.GeneralSecurityException;

/**
 * Encrypted storage for owner data and notification preferences.
 * Uses EncryptedSharedPreferences for secure storage.
 * 
 * Note: Daemon config file (/data/local/tmp/telegram_config.properties) is written
 * by the daemon itself when /pair command is received, or via ADB shell from
 * TelegramSettingsFragment, because app process can't write to /data/local/tmp directly.
 */
public class OwnerStore implements IOwnerStore {
    
    private static final String TAG = "OwnerStore";
    
    private static final String PREFS_NAME = "telegram_owner_prefs";
    
    // Owner keys
    private static final String KEY_OWNER_CHAT_ID = "owner_chat_id";
    private static final String KEY_OWNER_USERNAME = "owner_username";
    private static final String KEY_OWNER_FIRST_NAME = "owner_first_name";
    private static final String KEY_OWNER_PAIRED_AT = "owner_paired_at";
    
    // Preference keys
    private static final String KEY_PREF_CRITICAL = "pref_critical_alerts";
    private static final String KEY_PREF_CONNECTIVITY = "pref_connectivity";
    private static final String KEY_PREF_MOTION_TEXT = "pref_motion_text";
    private static final String KEY_PREF_VIDEO_UPLOADS = "pref_video_uploads";
    
    private final SharedPreferences prefs;
    
    public OwnerStore(Context context) {
        this.prefs = createEncryptedPrefs(context);
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
            // Fallback to regular prefs if encryption fails (shouldn't happen)
            return context.getSharedPreferences(PREFS_NAME + "_fallback", Context.MODE_PRIVATE);
        }
    }
    
    @Override
    public void saveOwner(OwnerInfo owner) {
        prefs.edit()
                .putLong(KEY_OWNER_CHAT_ID, owner.getChatId())
                .putString(KEY_OWNER_USERNAME, owner.getUsername())
                .putString(KEY_OWNER_FIRST_NAME, owner.getFirstName())
                .putLong(KEY_OWNER_PAIRED_AT, owner.getPairedAt())
                .apply();
        
        // Note: Daemon config file is written by the daemon itself when /pair command is received
        // because app process can't write to /data/local/tmp directly
        Log.d(TAG, "Owner saved to encrypted prefs: " + owner.getChatId());
    }
    
    /**
     * Note: Direct file write to /data/local/tmp doesn't work from app process.
     * Owner info is written by the daemon itself when /pair command is received.
     * This method is kept for reference but is effectively a no-op.
     */
    @SuppressWarnings("unused")
    private void writeOwnerToDaemonConfig(OwnerInfo owner) {
        // App process (UID 10xxx) cannot write to /data/local/tmp
        // Owner is saved by daemon when /pair command is received
        Log.d(TAG, "writeOwnerToDaemonConfig called - owner is saved by daemon via /pair command");
    }
    
    @Override
    @Nullable
    public OwnerInfo getOwner() {
        long chatId = prefs.getLong(KEY_OWNER_CHAT_ID, -1);
        if (chatId == -1) return null;
        
        return new OwnerInfo(
                chatId,
                prefs.getString(KEY_OWNER_USERNAME, ""),
                prefs.getString(KEY_OWNER_FIRST_NAME, ""),
                prefs.getLong(KEY_OWNER_PAIRED_AT, 0)
        );
    }
    
    @Override
    public boolean hasOwner() {
        return prefs.getLong(KEY_OWNER_CHAT_ID, -1) != -1;
    }
    
    @Override
    public void clearOwner() {
        prefs.edit()
                .remove(KEY_OWNER_CHAT_ID)
                .remove(KEY_OWNER_USERNAME)
                .remove(KEY_OWNER_FIRST_NAME)
                .remove(KEY_OWNER_PAIRED_AT)
                .apply();
        
        // Note: Clearing from daemon config is handled via ADB shell in TelegramSettingsFragment
        Log.d(TAG, "Owner cleared from encrypted prefs");
    }
    
    /**
     * Note: Direct file write to /data/local/tmp doesn't work from app process.
     * Owner clearing from daemon config is handled via ADB shell in TelegramSettingsFragment.
     */
    @SuppressWarnings("unused")
    private void clearOwnerFromDaemonConfig() {
        // App process (UID 10xxx) cannot write to /data/local/tmp
        // Clearing is handled via ADB shell in TelegramSettingsFragment
        Log.d(TAG, "clearOwnerFromDaemonConfig called - delegated to TelegramSettingsFragment via ADB shell");
    }
    
    @Override
    public void savePreferences(NotificationPreferences p) {
        prefs.edit()
                .putBoolean(KEY_PREF_CRITICAL, p.isCriticalAlerts())
                .putBoolean(KEY_PREF_CONNECTIVITY, p.isConnectivityUpdates())
                .putBoolean(KEY_PREF_MOTION_TEXT, p.isMotionText())
                .putBoolean(KEY_PREF_VIDEO_UPLOADS, p.isVideoUploads())
                .apply();
    }
    
    @Override
    public NotificationPreferences getPreferences() {
        return new NotificationPreferences(
                prefs.getBoolean(KEY_PREF_CRITICAL, true),
                prefs.getBoolean(KEY_PREF_CONNECTIVITY, true),
                prefs.getBoolean(KEY_PREF_MOTION_TEXT, true),
                prefs.getBoolean(KEY_PREF_VIDEO_UPLOADS, false)
        );
    }
}
