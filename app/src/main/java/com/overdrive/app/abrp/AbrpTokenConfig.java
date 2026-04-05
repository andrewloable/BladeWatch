package com.overdrive.app.abrp;

import android.content.Context;
import android.content.SharedPreferences;
import android.util.Log;

import androidx.annotation.Nullable;
import androidx.security.crypto.EncryptedSharedPreferences;
import androidx.security.crypto.MasterKey;

import java.io.IOException;
import java.security.GeneralSecurityException;

/**
 * ABRP user token configuration with encrypted storage.
 *
 * Mirrors the BotTokenConfig pattern: token is stored in EncryptedSharedPreferences
 * on the app side. Daemon config file (/data/local/tmp/abrp_config.properties) is
 * written via ADB shell from AbrpSettingsFragment because the app process can't
 * write to /data/local/tmp directly.
 */
public class AbrpTokenConfig {

    private static final String TAG = "AbrpTokenConfig";

    private static final String PREFS_NAME = "abrp_prefs";
    private static final String KEY_TOKEN = "user_token";

    private final SharedPreferences prefs;

    public AbrpTokenConfig(Context context) {
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
            Log.w(TAG, "Failed to create encrypted prefs, falling back to regular prefs", e);
            return context.getSharedPreferences(PREFS_NAME + "_fallback", Context.MODE_PRIVATE);
        }
    }

    public void saveToken(String token) {
        prefs.edit().putString(KEY_TOKEN, token).apply();
    }

    @Nullable
    public String getToken() {
        return prefs.getString(KEY_TOKEN, null);
    }

    public boolean hasToken() {
        String token = getToken();
        return token != null && !token.isEmpty();
    }

    public void clearToken() {
        prefs.edit().remove(KEY_TOKEN).apply();
    }
}
