package net.bladewatch.app.manifest;

import java.io.File;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.junit.Assert;
import org.junit.Test;

/**
 * BladeWatch-81g9.1: the main APK is a UI-LESS SERVICE HOST.
 *
 * <p>Phase 4 deletes the native in-car UI, leaving {@code net.bladewatch.flutter} as the only
 * thing the user opens. These pin the two manifest properties that make that true, because both
 * are one careless edit away from silently reverting and neither shows up in a build failure:
 *
 * <ul>
 *   <li>a LAUNCHER entry reappearing would put two BladeWatch icons on the head unit's app list,
 *       one of which opens a screen with no content;
 *   <li>MainActivity disappearing would take the startup bootstrap with it — storage setup,
 *       device-id generation and the daemon launch — and nothing would start on a cold boot.
 * </ul>
 *
 * <p>Reads the manifest from source rather than the built APK: this is a plain JVM test, and the
 * property under test is what the file declares.
 */
public class ServiceHostManifestTest {

    private static String manifest() throws Exception {
        // The test runs with the module dir as CWD; fall back to the repo root so it
        // works from either.
        File f = new File("src/main/AndroidManifest.xml");
        if (!f.exists()) f = new File("app/src/main/AndroidManifest.xml");
        Assert.assertTrue("could not locate the app manifest from " + new File(".").getAbsolutePath(),
                f.exists());
        return new String(Files.readAllBytes(f.toPath()), StandardCharsets.UTF_8);
    }

    @Test
    public void theServiceHostHasNoLauncherEntry() throws Exception {
        Assert.assertFalse(
                "The daemon APK must not have a launcher entry — net.bladewatch.flutter is the "
                        + "only in-car UI. Two icons, one of them empty, is the regression.",
                manifest().contains("android.intent.category.LAUNCHER"));
    }

    @Test
    public void mainActivityStillExistsToRunTheBootstrap() throws Exception {
        // It is not only UI. Its onCreate runs DeviceIdGenerator.generateDeviceId before any
        // daemon starts, the BYD whitelist, storage setup and DaemonStartupManager. Deleting
        // it would break cold boot with no compile error anywhere.
        Assert.assertTrue(
                "MainActivity must stay declared — it hosts the startup bootstrap",
                manifest().contains("net.bladewatch.app.ui.MainActivity"));
    }

    @Test
    public void mainActivityStaysExportedAsTheAdbRecoveryPath() throws Exception {
        // With the launcher entry gone, `am start -n net.bladewatch.app/.ui.MainActivity` over
        // ADB is the only remaining way in when the Flutter APK is broken or absent.
        String m = manifest();
        int at = m.indexOf("net.bladewatch.app.ui.MainActivity");
        Assert.assertTrue("MainActivity not found in the manifest", at > 0);
        // Look only at this activity's own declaration, not the whole file.
        int end = m.indexOf("/>", at);
        int endTag = m.indexOf("</activity>", at);
        if (endTag > 0 && (end < 0 || endTag < end)) end = endTag;
        Assert.assertTrue("could not find the end of the MainActivity declaration", end > at);
        Assert.assertTrue(
                "MainActivity must stay exported — it is the ADB recovery path once the "
                        + "launcher entry is gone",
                m.substring(at, end).contains("android:exported=\"true\""));
    }
}
