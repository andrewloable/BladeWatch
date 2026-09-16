package net.bladewatch.app.launcher

import java.io.File
import java.nio.charset.StandardCharsets
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-v9xw: watchdog scripts must resolve the APK path at RUN TIME.
 *
 * The scripts used to bake `context.applicationInfo.sourceDir` in when the script was
 * written. That path carries a per-install hash — `/data/app/net.bladewatch.app-<hash>/
 * base.apk` — and `adb install -r` changes it, so after every reinstall the script pointed
 * at an APK that no longer existed and app_process aborted:
 *
 *     name: main  >>> byd_cam_daemon <<<
 *     Abort message: 'No pending exception expected:
 *       java.lang.ClassNotFoundException: net.bladewatch.app.daemon.CameraDaemon'
 *
 * It self-healed on respawn, which is exactly what made it easy to live with and easy to
 * miss: one spurious NATIVE CRASH per install, in the same logcat where a real crash would
 * appear.
 *
 * `DaemonLauncher` needs a `Context` and an ADB connection, so the scripts cannot be built
 * in a unit test. This reads the generator as DATA — the property under test is what the
 * emitted script says. `app/build.gradle.kts` declares `src/main/java` as an explicit test
 * input, so this re-runs when that file changes.
 */
class WatchdogApkPathTest {

    private fun launcherSource(): String {
        var f = File("src/main/java/com/loabletech/bladewatch/launcher/DaemonLauncher.kt")
        if (!f.isFile) {
            f = File("app/src/main/java/com/loabletech/bladewatch/launcher/DaemonLauncher.kt")
        }
        assertTrue("could not locate DaemonLauncher.kt from ${File(".").absolutePath}", f.isFile)
        return String(f.readBytes(), StandardCharsets.UTF_8)
    }

    /** `pm path` is the authoritative source and must be consulted by the script itself. */
    @Test
    fun `the script asks package manager for the apk path`() {
        assertTrue(
            "the emitted watchdog script must run `pm path <package>` at run time. Baking " +
                "applicationInfo.sourceDir in is what broke on every install -r.",
            launcherSource().contains("pm path \${context.packageName}"))
    }

    /**
     * Both respawn loops must resolve. The camera daemon is the one that actually crashed;
     * the ACC sentry watchdog has the same shape and would have followed.
     */
    @Test
    fun `both watchdog loops resolve the path inside the loop`() {
        val src = launcherSource()
        val calls = Regex("apkResolutionLines\\(").findAll(src).count()
        assertTrue(
            "expected the resolver to be emitted by both the camera and ACC sentry " +
                "watchdogs plus its own declaration (found $calls occurrences)",
            calls >= 3)

        // Emitted INSIDE `while true`, not once at the top: an install that happens while
        // the watchdog is alive must be picked up on the next respawn.
        val loopStarts = Regex("\"while true; do\",\\s*\\n\\s*\\*apkResolutionLines")
            .findAll(src.replace("\r\n", "\n")).count()
        assertTrue(
            "apkResolutionLines must be the first thing inside each respawn loop " +
                "(found $loopStarts loops starting with it)",
            loopStarts >= 2)
    }

    /**
     * A cold boot can start the watchdog before package manager answers. The resolver must
     * fall back to the baked path rather than launching with an empty CLASSPATH — that
     * would turn a recoverable reinstall bug into a boot failure.
     */
    @Test
    fun `resolution falls back when package manager is not ready`() {
        val src = launcherSource()
        assertTrue("must test that pm returned something usable",
            src.contains("if [ -n \\\"\\\$RESOLVED\\\" ] && [ -f \\\"\\\$RESOLVED\\\" ]"))
        assertTrue(
            "must fall back to the baked path — a cold boot can outrun package manager",
            src.contains("elif [ -f \\\"\$bakedApkPath\\\" ]"))
    }

    /**
     * The launch line must use the RESOLVED variables. Leaving a baked `$apkPath` in the
     * command is the whole bug, and it would still compile and still look right.
     */
    @Test
    fun `the camera launch line uses the resolved apk and lib dir`() {
        val src = launcherSource()
        val launchAt = src.indexOf("net.bladewatch.app.daemon.CameraDaemon \" +")
        assertTrue("could not find the CameraDaemon launch line", launchAt > 0)
        val block = src.substring(maxOf(0, launchAt - 600), launchAt + 200)

        assertTrue("CLASSPATH must use the resolved \$APK_PATH",
            block.contains("CLASSPATH=/system/framework/bmmcamera.jar:\\\"\\\$APK_PATH\\\""))
        assertTrue("java.library.path must use the resolved \$NATIVE_LIB_DIR",
            block.contains("java.library.path=\\\"\\\$NATIVE_LIB_DIR\\\""))
        assertTrue(
            "the launch line must not re-introduce the baked Kotlin interpolations — " +
                "that is the bug this guards",
            !block.contains("bmmcamera.jar:\$apkPath") &&
                !block.contains("java.library.path=\$nativeLibDir"))
    }
}
