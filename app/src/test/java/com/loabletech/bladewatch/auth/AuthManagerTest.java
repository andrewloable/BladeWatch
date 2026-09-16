package net.bladewatch.app.auth;

import net.bladewatch.app.config.SecretConfigBridge;
import net.bladewatch.app.config.SecretConfigStore;

import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

import java.io.File;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.Base64;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

public class AuthManagerTest {

    @Before
    public void setUp() {
        AuthManager.clearTestState();
        SecretConfigBridge.INSTANCE.directStoreForTest = null;
    }

    @After
    public void tearDown() {
        AuthManager.clearTestState();
        SecretConfigBridge.INSTANCE.directStoreForTest = null;
    }

    // --- BladeWatch-b195: deviceId/tokenEpoch mirrored into the secret store ---
    //
    // JwtMinter.kt (flutter_ui/android) can only reach auth state over the
    // secret_get_section IPC command, which reads exclusively from
    // SecretConfigStore. writeSecretStoreMirror() is the package-private half
    // of writeToConfig() that touches only SecretConfigBridge — factored out
    // specifically so it's testable here without also depending on
    // UnifiedConfigManager (a separate class hardcoded to real device paths
    // like /storage/emulated/0/..., which this JVM test must not touch).

    @Test
    public void writeSecretStoreMirrorWritesDeviceIdAndTokenEpochAlongsideSecret() throws Exception {
        Path tempDir = Files.createTempDirectory("auth-manager-mirror-test");
        try {
            SecretConfigStore store = new SecretConfigStore(new File(tempDir.toFile(), "secrets.json"));
            SecretConfigBridge.INSTANCE.directStoreForTest = store;

            AuthManager.AuthState state = makeState("byd-b195-test", "secret-abc", 7);
            Assert.assertTrue(AuthManager.writeSecretStoreMirror(state));

            org.json.JSONObject section = store.loadSection("auth");
            Assert.assertEquals("byd-b195-test", section.optString("deviceId"));
            Assert.assertEquals("secret-abc", section.optString("deviceSecret"));
            Assert.assertEquals(7L, section.optLong("tokenEpoch"));
        } finally {
            deleteRecursive(tempDir.toFile());
        }
    }

    @Test
    public void writeSecretStoreMirrorReturnsFalseWithoutThrowingWhenTheStoreIsUnwritable() throws Exception {
        Path tempDir = Files.createTempDirectory("auth-manager-mirror-test-readonly");
        try {
            Assert.assertTrue("test setup: chmod the temp dir read-only", tempDir.toFile().setWritable(false));
            try {
                SecretConfigStore store = new SecretConfigStore(new File(tempDir.toFile(), "secrets.json"));
                SecretConfigBridge.INSTANCE.directStoreForTest = store;

                AuthManager.AuthState state = makeState("byd-test", "secret-xyz", 1);
                Assert.assertFalse(AuthManager.writeSecretStoreMirror(state));
            } finally {
                tempDir.toFile().setWritable(true);
            }
        } finally {
            deleteRecursive(tempDir.toFile());
        }
    }

    private void deleteRecursive(File file) {
        if (file == null || !file.exists()) return;
        File[] children = file.listFiles();
        if (children != null) {
            for (File child : children) deleteRecursive(child);
        }
        file.delete();
    }

    @Test
    public void generatesValidJwtForCurrentSession() {
        AuthManager.AuthState state = makeState("byd-test", "secret123", 0);
        AuthManager.setTestState(state);

        String jwt = AuthManager.generateJwt();
        Assert.assertNotNull(jwt);

        AuthManager.JwtValidation validation = AuthManager.validateJwt(jwt);
        Assert.assertTrue(validation.valid);
        Assert.assertEquals("byd-test", validation.deviceId);
    }

    @Test
    public void rejectsExpiredJwt() throws Exception {
        AuthManager.AuthState state = makeState("byd-test", "secret123", 0);
        AuthManager.setTestState(state);

        String jwt = buildJwt(state.deviceId, state.deviceSecret, -60, state.tokenEpoch);
        AuthManager.JwtValidation validation = AuthManager.validateJwt(jwt);
        Assert.assertFalse(validation.valid);
        Assert.assertEquals("Token expired", validation.error);
    }

    @Test
    public void rejectsJwtFromOldSessionVersion() throws Exception {
        AuthManager.AuthState state = makeState("byd-test", "secret123", 2);
        AuthManager.setTestState(state);

        String jwt = buildJwt(state.deviceId, state.deviceSecret, 3600, 1);
        AuthManager.JwtValidation validation = AuthManager.validateJwt(jwt);
        Assert.assertFalse(validation.valid);
        Assert.assertEquals("Session rotated", validation.error);
    }

    @Test
    public void regenerateTokenInvalidatesPreviousJwt() throws Exception {
        AuthManager.AuthState state = makeState("byd-test", "secret123", 0);
        AuthManager.setTestState(state);

        String oldJwt = AuthManager.generateJwt();
        Assert.assertTrue(AuthManager.validateJwt(oldJwt).valid);

        String newToken = AuthManager.regenerateToken();
        Assert.assertNotNull(newToken);

        Assert.assertFalse(AuthManager.validateJwt(oldJwt).valid);
        String newJwt = AuthManager.generateJwt();
        Assert.assertTrue(AuthManager.validateJwt(newJwt).valid);
    }

    // --- JWT signature pinning (baseline for uy93.3: String.equals → MessageDigest.isEqual) ---

    @Test
    public void validJwtSignatureIsAccepted() throws Exception {
        AuthManager.AuthState state = makeState("byd-test", "secret123", 0);
        AuthManager.setTestState(state);
        String jwt = buildJwt(state.deviceId, state.deviceSecret, 3600, state.tokenEpoch);
        AuthManager.JwtValidation result = AuthManager.validateJwt(jwt);
        Assert.assertTrue(result.valid);
    }

    @Test
    public void tamperedJwtSignatureIsRejected() throws Exception {
        AuthManager.AuthState state = makeState("byd-test", "secret123", 0);
        AuthManager.setTestState(state);
        String jwt = buildJwt(state.deviceId, state.deviceSecret, 3600, state.tokenEpoch);
        // Flip the last character of the signature (third dot-segment)
        int lastDot = jwt.lastIndexOf('.');
        String tampered = jwt.substring(0, lastDot + 1) + flipLastChar(jwt.substring(lastDot + 1));
        AuthManager.JwtValidation result = AuthManager.validateJwt(tampered);
        Assert.assertFalse(result.valid);
        Assert.assertEquals("Invalid signature", result.error);
    }

    // --- Thumb token signature pinning ---

    @Test
    public void validThumbTokenIsAccepted() {
        AuthManager.AuthState state = makeState("byd-test", "secret123", 0);
        AuthManager.setTestState(state);
        String filename = "event_2026_001.jpg";
        String token = AuthManager.signThumbToken(filename, 3600);
        Assert.assertNotNull(token);
        Assert.assertTrue(AuthManager.validateThumbToken(filename, token));
    }

    @Test
    public void tamperedThumbTokenSignatureIsRejected() {
        AuthManager.AuthState state = makeState("byd-test", "secret123", 0);
        AuthManager.setTestState(state);
        String filename = "event_2026_001.jpg";
        String token = AuthManager.signThumbToken(filename, 3600);
        Assert.assertNotNull(token);
        int lastDot = token.lastIndexOf('.');
        String tampered = token.substring(0, lastDot + 1) + flipLastChar(token.substring(lastDot + 1));
        Assert.assertFalse(AuthManager.validateThumbToken(filename, tampered));
    }

    private String flipLastChar(String s) {
        if (s == null || s.isEmpty()) return s;
        char last = s.charAt(s.length() - 1);
        char flipped = (last == 'A') ? 'B' : 'A';
        return s.substring(0, s.length() - 1) + flipped;
    }

    // --- device token validation: the UNAUTHENTICATED POST /auth/token path ---

    @Test
    public void validateDeviceTokenAcceptsOnlyTheExactToken() {
        AuthManager.setTestState(makeState("byd-test", "s3cret", 0));

        Assert.assertTrue("the exact token must validate",
                AuthManager.validateDeviceToken("byd-test-s3cret"));

        // Every near-miss must fail. These are the shapes a timing oracle would walk through:
        // a correct prefix of increasing length, and a correct length with one byte wrong.
        Assert.assertFalse(AuthManager.validateDeviceToken("byd-test-s3cre"));
        Assert.assertFalse(AuthManager.validateDeviceToken("byd-test-s3cretX"));
        Assert.assertFalse(AuthManager.validateDeviceToken("byd-test-s3crex"));
        Assert.assertFalse(AuthManager.validateDeviceToken("byd-test-"));
        Assert.assertFalse(AuthManager.validateDeviceToken("b"));
        Assert.assertFalse(AuthManager.validateDeviceToken("BYD-TEST-S3CRET"));
    }

    @Test
    public void validateDeviceTokenRejectsEmptyAndNull() {
        AuthManager.setTestState(makeState("byd-test", "s3cret", 0));

        Assert.assertFalse(AuthManager.validateDeviceToken(null));
        Assert.assertFalse(AuthManager.validateDeviceToken(""));
    }

    /**
     * With no auth state there is nothing to compare against, so every token must be refused.
     * Returning true here would turn an uninitialised device into an open one.
     */
    @Test
    public void validateDeviceTokenRejectsEverythingWithoutState() {
        AuthManager.clearTestState();

        Assert.assertFalse(AuthManager.validateDeviceToken("anything"));
    }

    /**
     * A blank stored secret must not make the token "byd-test-" valid.
     *
     * getDeviceToken() is deviceId + "-" + deviceSecret, so a blank secret produces a token
     * that is non-empty yet guessable by anyone who has seen the device id — which the login
     * page displays.
     *
     * getState() re-initialises rather than returning such a state, so this is defence in
     * depth, not a demonstrated break. It is pinned because AuthState.fromJson sets
     * deviceSecret = "" BY DESIGN (the secret lives in the secret store, not the config), so
     * blank-secret states genuinely exist and only one caller separates them from this check.
     */
    @Test
    public void validateDeviceTokenRejectsWhenTheStoredSecretIsBlank() {
        AuthManager.AuthState blank = makeState("byd-test", "", 0);
        AuthManager.setTestState(blank);

        Assert.assertFalse(AuthManager.validateDeviceToken("byd-test-"));
        Assert.assertFalse(AuthManager.validateDeviceToken(""));
    }

    private AuthManager.AuthState makeState(String deviceId, String secret, long epoch) {
        AuthManager.AuthState state = new AuthManager.AuthState();
        state.deviceId = deviceId;
        state.deviceSecret = secret;
        state.tokenEpoch = epoch;
        state.lastAccess = 0;
        return state;
    }

    private String buildJwt(String deviceId, String secret, long expOffsetSeconds, long epoch) throws Exception {
        long now = System.currentTimeMillis() / 1000;
        String headerJson = "{\"alg\":\"HS256\",\"typ\":\"JWT\"}";
        String payloadJson = "{\"sub\":\"" + escapeJson(deviceId) + "\","
                + "\"iat\":" + now + ","
                + "\"exp\":" + (now + expOffsetSeconds) + ","
                + "\"ver\":" + epoch + "}";

        String headerB64 = base64UrlEncode(headerJson.getBytes(StandardCharsets.UTF_8));
        String payloadB64 = base64UrlEncode(payloadJson.getBytes(StandardCharsets.UTF_8));
        String content = headerB64 + "." + payloadB64;
        String sig = hmacSha256(content, secret);
        return content + "." + sig;
    }

    private String hmacSha256(String data, String secret) throws Exception {
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
        byte[] hash = mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
        return base64UrlEncode(hash);
    }

    private String base64UrlEncode(byte[] data) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(data);
    }

    private String escapeJson(String value) {
        return value
                .replace("\\", "\\\\")
                .replace("\"", "\\\"");
    }
}
