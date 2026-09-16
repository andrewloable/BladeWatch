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

    /**
     * BladeWatch-p9ag: the bootstrap activity must declare a TRANSLUCENT theme.
     *
     * <p>Reported by the owner from the head unit: starting the service host showed a blank
     * WHITE SCREEN. The activity deliberately never calls {@code setContentView} — it exists
     * only to kick off daemon startup and calls {@code moveTaskToBack(true)} immediately — so
     * with an ordinary opaque theme the window paints the bare theme background and nothing
     * else.
     *
     * <p>It is not only visible when started by hand. The Flutter APK's
     * {@code wakeServiceHost()} starts this component on its first {@code onResume}, so every
     * cold start of the in-car UI flashes it.
     *
     * <p>A translucent window is the fix rather than giving this activity a progress UI,
     * because the thing it would be covering IS the progress UI: the Flutter Startup screen
     * already shows the brand lockup, "Getting your dashcam ready" and per-daemon progress.
     * The white window was hiding it. Adding content here would also mean calling
     * setContentView, which {@link #mainActivityIsNotAUiActivity()} and the class comment on
     * MainActivity both forbid.
     *
     * <p>NOT {@code Theme.NoDisplay}: that requires the activity to finish before it resumes,
     * and this one backgrounds itself instead of finishing, which crashes under NoDisplay on
     * modern Android.
     */
    @Test
    public void bootstrapActivityDeclaresATranslucentTheme() throws Exception {
        String m = manifest();
        int at = m.indexOf("net.bladewatch.app.ui.MainActivity");
        Assert.assertTrue("MainActivity is missing from the manifest", at > 0);
        int end = m.indexOf("/>", at);
        String decl = m.substring(at, end);

        Assert.assertTrue(
                "MainActivity has no UI and must not paint one — an opaque theme shows a "
                        + "blank white window over the Flutter startup screen. Declaration was: "
                        + decl,
                decl.contains("android:theme") && decl.contains("Translucent"));
        Assert.assertFalse(
                "Theme.NoDisplay crashes an activity that backgrounds itself instead of "
                        + "finishing, which is what this one does: " + decl,
                decl.contains("NoDisplay"));
    }

    /**
     * BladeWatch-p9ag, second defect: the bootstrap window must not be able to take input.
     *
     * <p>Making it translucent removed the white flash but exposed an older bug —
     * {@code moveTaskToBack(true)} does not reliably background this task. Measured on the
     * head unit 2026-09-15, the invisible window sat directly on top of the Flutter UI and
     * stayed the resumed activity:
     *
     * <pre>
     *   Window #9  net.bladewatch.app/.ui.MainActivity     (invisible, on top)
     *   Window #10 net.bladewatch.flutter/...MainActivity  (the real UI, beneath)
     *   mResumedActivity: net.bladewatch.app/.ui.MainActivity
     * </pre>
     *
     * <p>While opaque that read as a white screen — obviously broken. Transparent, the UI
     * showed through perfectly and only TOUCH was swallowed, so the in-car app looked
     * frozen with nothing on screen to explain it. That is a strictly worse failure, which
     * is why the flags are pinned rather than left to the theme.
     */
    @Test
    public void bootstrapActivityCannotTakeFocusOrTouch() throws Exception {
        // Same CWD dance as manifest() above.
        File f = new File("src/main/java/com/loabletech/bladewatch/ui/MainActivity.kt");
        if (!f.exists()) f = new File("app/src/main/java/com/loabletech/bladewatch/ui/MainActivity.kt");
        Assert.assertTrue("could not locate MainActivity.kt", f.exists());
        String src = new String(Files.readAllBytes(f.toPath()), StandardCharsets.UTF_8);

        Assert.assertTrue(
                "The bootstrap window has no UI and must not be focusable — an invisible "
                        + "window holding focus swallows every tap meant for the Flutter UI.",
                src.contains("FLAG_NOT_FOCUSABLE"));
        Assert.assertTrue(
                "...nor touchable, for the same reason.",
                src.contains("FLAG_NOT_TOUCHABLE"));
    }
}
