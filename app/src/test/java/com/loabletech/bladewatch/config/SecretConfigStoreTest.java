package net.bladewatch.app.config;

import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

import java.io.File;
import java.nio.charset.StandardCharsets;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.PosixFilePermission;
import java.util.EnumSet;
import java.util.Set;

public class SecretConfigStoreTest {

    private Path tempDir;
    private File storeFile;

    @Before
    public void setUp() throws Exception {
        tempDir = Files.createTempDirectory("secret-config-store-test");
        storeFile = tempDir.resolve("secrets.json").toFile();
    }

    @After
    public void tearDown() throws Exception {
        deleteRecursive(tempDir.toFile());
    }

    @Test
    public void writesReadsAndDeletesValues() {
        SecretConfigStore store = new SecretConfigStore(storeFile);

        Assert.assertTrue(store.putString("auth", "deviceSecret", "secret-123"));
        Assert.assertEquals("secret-123", store.getString("auth", "deviceSecret"));

        Assert.assertTrue(store.delete("auth", "deviceSecret"));
        Assert.assertNull(store.getString("auth", "deviceSecret"));
    }

    @Test
    public void missingFileLoadsAsEmpty() {
        SecretConfigStore store = new SecretConfigStore(storeFile);

        Assert.assertFalse(store.exists());
        Assert.assertNull(store.getString("tunnel", "token"));
        Assert.assertNotNull(store.loadSection("tunnel"));
    }

    @Test
    public void invalidJsonIsRecoveredOnWrite() throws Exception {
        Files.write(storeFile.toPath(), "{not-json".getBytes(StandardCharsets.UTF_8));

        SecretConfigStore store = new SecretConfigStore(storeFile);
        Assert.assertNull(store.getString("tunnel", "token"));
        Assert.assertTrue(store.putString("tunnel", "token", "tunnel-secret"));
        Assert.assertEquals("tunnel-secret", store.getString("tunnel", "token"));
    }

    @Test
    public void permissionsRemainOwnerOnly() throws Exception {
        SecretConfigStore store = new SecretConfigStore(storeFile);
        Assert.assertTrue(store.putString("tunnel", "enableToken", "enable-secret"));

        if (!FileSystems.getDefault().supportedFileAttributeViews().contains("posix")) {
            return;
        }

        Set<PosixFilePermission> perms = Files.getPosixFilePermissions(storeFile.toPath());
        Assert.assertTrue(perms.contains(PosixFilePermission.OWNER_READ));
        Assert.assertTrue(perms.contains(PosixFilePermission.OWNER_WRITE));
        Assert.assertFalse(perms.contains(PosixFilePermission.GROUP_READ));
        Assert.assertFalse(perms.contains(PosixFilePermission.GROUP_WRITE));
        Assert.assertFalse(perms.contains(PosixFilePermission.GROUP_EXECUTE));
        Assert.assertFalse(perms.contains(PosixFilePermission.OTHERS_READ));
        Assert.assertFalse(perms.contains(PosixFilePermission.OTHERS_WRITE));
        Assert.assertFalse(perms.contains(PosixFilePermission.OTHERS_EXECUTE));
    }

    // --- read-after-write: all getter types (functional preservation baseline for uy93.4) ---

    @Test
    public void readAfterWritePreservesString() {
        SecretConfigStore store = new SecretConfigStore(storeFile);
        store.putString("auth", "key", "hello_world");
        Assert.assertEquals("hello_world", store.getString("auth", "key"));
    }

    @Test
    public void readAfterWritePreservesLong() {
        SecretConfigStore store = new SecretConfigStore(storeFile);
        store.putLong("stats", "count", 42L);
        Assert.assertEquals(42L, store.getLong("stats", "count", 0L));
    }

    @Test
    public void readAfterWritePreservesBoolean() {
        SecretConfigStore store = new SecretConfigStore(storeFile);
        store.putBoolean("flags", "enabled", true);
        Assert.assertTrue(store.getBoolean("flags", "enabled", false));
    }

    @Test
    public void readAfterWritePreservesMultipleSections() {
        SecretConfigStore store = new SecretConfigStore(storeFile);
        store.putString("sec1", "k1", "v1");
        store.putString("sec2", "k2", "v2");
        Assert.assertEquals("v1", store.getString("sec1", "k1"));
        Assert.assertEquals("v2", store.getString("sec2", "k2"));
    }

    @Test
    public void loadSectionReturnsAllWrittenKeysInSection() {
        SecretConfigStore store = new SecretConfigStore(storeFile);
        store.putString("mysec", "a", "alpha");
        store.putString("mysec", "b", "beta");
        org.json.JSONObject section = store.loadSection("mysec");
        Assert.assertEquals("alpha", section.optString("a"));
        Assert.assertEquals("beta", section.optString("b"));
    }

    // --- uy93.4 regression: secrets never written or left at legacy path ---

    @Test
    public void noWriteToLegacyPathAfterUy93_4() throws Exception {
        // uy93.4: mirrorLegacy() removed — writing secrets must NOT create or touch legacy path.
        File legacyFile = tempDir.resolve("legacy_secrets.json").toFile();
        SecretConfigStore store = new SecretConfigStore(storeFile);
        store.legacyPathForTest = legacyFile.getAbsolutePath();

        store.putString("auth", "token", "tok123");

        Assert.assertFalse("uy93.4: legacy path must NOT be written after a secret put",
                legacyFile.exists());
    }

    @Test
    public void legacyFileDeletedAfterFirstWriteToNewPrimary() throws Exception {
        // uy93.4: upgrade path — if legacy exists and a write happens (migrating to primary),
        // the legacy file is deleted so plaintext secrets don't linger in /data/local/tmp.
        File primaryFile = tempDir.resolve("primary_secrets.json").toFile();
        File legacyFile = tempDir.resolve("legacy_secrets.json").toFile();

        // Pre-create a legacy file (simulates in-place upgrade)
        java.nio.file.Files.write(legacyFile.toPath(),
                "{\"auth\":{\"token\":\"legacy_value\"}}".getBytes(java.nio.charset.StandardCharsets.UTF_8));

        SecretConfigStore store = new SecretConfigStore(primaryFile);
        store.legacyPathForTest = legacyFile.getAbsolutePath();

        // First write triggers migration + deletion
        store.putString("auth", "newKey", "new_value");

        Assert.assertFalse("uy93.4: legacy file must be deleted after write to primary",
                legacyFile.exists());
        // Primary should have the new value
        Assert.assertEquals("new_value", store.getString("auth", "newKey"));
    }

    @Test
    public void legacyReadFallbackWhenPrimaryAbsent() throws Exception {
        // Pin current behavior: if primary file is absent, store reads from LEGACY_PATH.
        File primaryFile = tempDir.resolve("primary_secrets.json").toFile();
        File legacyFile = tempDir.resolve("legacy_secrets.json").toFile();

        // Write legacy content directly
        java.nio.file.Files.write(legacyFile.toPath(),
                "{\"auth\":{\"token\":\"legacy_value\"}}".getBytes(java.nio.charset.StandardCharsets.UTF_8));

        SecretConfigStore store = new SecretConfigStore(primaryFile);
        store.legacyPathForTest = legacyFile.getAbsolutePath();

        // Primary doesn't exist — store should fall back to legacy
        Assert.assertFalse(primaryFile.exists());
        Assert.assertEquals("legacy_value", store.getString("auth", "token"));
    }

    @Test
    public void primaryFileWinsOverLegacyWhenBothExist() throws Exception {
        File primaryFile = tempDir.resolve("primary_secrets.json").toFile();
        File legacyFile = tempDir.resolve("legacy_secrets.json").toFile();

        // Write different values to each
        java.nio.file.Files.write(legacyFile.toPath(),
                "{\"auth\":{\"token\":\"legacy_value\"}}".getBytes(java.nio.charset.StandardCharsets.UTF_8));

        SecretConfigStore store = new SecretConfigStore(primaryFile);
        store.legacyPathForTest = legacyFile.getAbsolutePath();
        store.putString("auth", "token", "primary_value");

        // Primary should win
        Assert.assertEquals("primary_value", store.getString("auth", "token"));
    }

    private void deleteRecursive(File file) {
        if (file == null || !file.exists()) {
            return;
        }
        if (file.isDirectory()) {
            File[] children = file.listFiles();
            if (children != null) {
                for (File child : children) {
                    deleteRecursive(child);
                }
            }
        }
        file.delete();
    }

    // ── BladeWatch-078u: the store must live where rw------- can actually
    // take effect. It used to sit on sdcardfs, which synthesises permissions
    // from its mount options, so chmod 600 there was a silent no-op and a
    // non-owner uid (shell) could read the file on the head unit. ───────────

    @Test
    public void defaultPathIsOnARealFilesystemNotSdcardfs() {
        Assert.assertEquals(
                "the store must be somewhere POSIX permissions are honoured",
                "/data/local/tmp/bladewatch_secrets.json",
                SecretConfigStore.DEFAULT_PATH);
        Assert.assertFalse(
                "sdcardfs cannot enforce owner-only, so it must not be the primary path",
                SecretConfigStore.DEFAULT_PATH.startsWith("/storage/emulated/"));
        Assert.assertTrue(
                "the sdcardfs location stays readable so an upgraded device keeps its deviceSecret",
                SecretConfigStore.LEGACY_PATH.startsWith("/storage/emulated/"));
    }

    @Test
    public void migrationCarriesAnExistingSecretForwardAndRemovesTheExposedCopy() throws Exception {
        File legacy = tempDir.resolve("legacy-secrets.json").toFile();
        Files.write(legacy.toPath(),
                "{\"auth\":{\"deviceSecret\":\"carried-forward\"}}".getBytes(StandardCharsets.UTF_8));

        SecretConfigStore store = new SecretConfigStore(storeFile);
        store.legacyPathForTest = legacy.getAbsolutePath();

        // The read fallback finds it even before any migration runs — that is
        // what keeps a paired device working across the upgrade.
        Assert.assertEquals("carried-forward", store.getString("auth", "deviceSecret"));

        // A write migrates it forward and removes the exposed copy.
        store.putString("auth", "tokenEpoch", "7");

        Assert.assertTrue("the primary file must now exist", storeFile.exists());
        Assert.assertFalse("the legacy plaintext copy must not linger", legacy.exists());

        SecretConfigStore reopened = new SecretConfigStore(storeFile);
        Assert.assertEquals("the paired secret must survive the move",
                "carried-forward", reopened.getString("auth", "deviceSecret"));
        Assert.assertEquals("7", reopened.getString("auth", "tokenEpoch"));
    }

    @Test
    public void migrationIsANoOpWhenThePrimaryAlreadyExists() throws Exception {
        SecretConfigStore store = new SecretConfigStore(storeFile);
        store.putString("auth", "deviceSecret", "already-here");

        File legacy = tempDir.resolve("legacy-secrets.json").toFile();
        Files.write(legacy.toPath(),
                "{\"auth\":{\"deviceSecret\":\"stale\"}}".getBytes(StandardCharsets.UTF_8));
        store.legacyPathForTest = legacy.getAbsolutePath();

        store.canWriteDirectlyForTest = Boolean.TRUE; // else the uid gate makes this vacuous
        Assert.assertFalse("an existing primary must never be overwritten by a stale legacy copy",
                store.migrateFromLegacyIfNeeded());
        Assert.assertEquals("already-here", store.getString("auth", "deviceSecret"));
    }

    @Test
    public void migrationIsANoOpWhenThereIsNothingToCarry() {
        SecretConfigStore store = new SecretConfigStore(storeFile);
        store.legacyPathForTest = tempDir.resolve("does-not-exist.json").toString();
        store.canWriteDirectlyForTest = Boolean.TRUE;
        Assert.assertFalse(store.migrateFromLegacyIfNeeded());
    }

    @Test
    public void migrationMovesTheStoreAndLeavesItOwnerOnly() throws Exception {
        File legacy = tempDir.resolve("legacy-secrets.json").toFile();
        Files.write(legacy.toPath(),
                "{\"auth\":{\"deviceSecret\":\"paired-device\"}}".getBytes(StandardCharsets.UTF_8));
        // sdcardfs cannot hold 600; model the loose mode the real file had.
        if (FileSystems.getDefault().supportedFileAttributeViews().contains("posix")) {
            Files.setPosixFilePermissions(legacy.toPath(), EnumSet.of(
                    PosixFilePermission.OWNER_READ, PosixFilePermission.OWNER_WRITE,
                    PosixFilePermission.GROUP_READ, PosixFilePermission.GROUP_WRITE));
        }

        SecretConfigStore store = new SecretConfigStore(storeFile);
        store.legacyPathForTest = legacy.getAbsolutePath();
        store.canWriteDirectlyForTest = Boolean.TRUE; // stand in for the daemon's uid 2000

        Assert.assertTrue("the migration must report that it moved something",
                store.migrateFromLegacyIfNeeded());

        Assert.assertTrue(storeFile.exists());
        Assert.assertFalse("the exposed sdcardfs copy must be gone", legacy.exists());
        Assert.assertEquals("the paired deviceSecret must survive",
                "paired-device", new SecretConfigStore(storeFile).getString("auth", "deviceSecret"));

        if (FileSystems.getDefault().supportedFileAttributeViews().contains("posix")) {
            Set<PosixFilePermission> perms = Files.getPosixFilePermissions(storeFile.toPath());
            Assert.assertEquals("the migrated file must be owner-only, which is the point of 078u",
                    EnumSet.of(PosixFilePermission.OWNER_READ, PosixFilePermission.OWNER_WRITE),
                    perms);
        }
    }

    @Test
    public void migrationRefusesToRunFromAProcessThatMayNotWriteTheStore() throws Exception {
        File legacy = tempDir.resolve("legacy-secrets.json").toFile();
        Files.write(legacy.toPath(),
                "{\"auth\":{\"deviceSecret\":\"paired-device\"}}".getBytes(StandardCharsets.UTF_8));

        SecretConfigStore store = new SecretConfigStore(storeFile);
        store.legacyPathForTest = legacy.getAbsolutePath();
        // The app process: canWriteDirectly() is false for any uid but 2000.
        store.canWriteDirectlyForTest = Boolean.FALSE;

        Assert.assertFalse("only the daemon may write the secret store directly",
                store.migrateFromLegacyIfNeeded());
        Assert.assertFalse("nothing may be created in /data/local/tmp from the app uid",
                storeFile.exists());
        Assert.assertTrue("and the legacy copy must be left for the daemon to migrate",
                legacy.exists());
    }
}
