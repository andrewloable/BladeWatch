package net.bladewatch.app.launcher

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import net.bladewatch.app.logging.DaemonLogConfig

/**
 * BladeWatch-rdtj.3: the shell commands PearLauncher hands to ADB.
 *
 * Pure strings, like TorLauncherCommandTest, for the same reason: the decisions that fail silently
 * on a head unit are "what exactly reaches the shell". Every requirement pinned here was found on
 * the real head unit by the BladeWatch-rdtj.2 spike -- the launch shape crashed or failed to start
 * without each one.
 */
class PearLauncherCommandTest {

    private val apk = "/data/app/net.bladewatch.app-Ptm2KH1TEHuOP-M-npyBUg==/base.apk"
    private val lib = "/data/app/net.bladewatch.app-Ptm2KH1TEHuOP-M-npyBUg==/lib/arm64"
    private val launch = PearLauncher.launchCommand(apk, lib)

    @Test
    fun `launches PearDaemon as its own app_process daemon named pear_daemon`() {
        assertTrue(launch, launch.contains("CLASSPATH=$apk app_process"))
        assertTrue(launch, launch.contains("--nice-name=pear_daemon net.bladewatch.app.daemon.PearDaemon"))
        // The runtime class, not the source path: the package rename makes them disagree, and the
        // source-path spelling is a ClassNotFoundException on device.
        assertFalse(launch, launch.contains("com.loabletech"))
    }

    @Test
    fun `puts the APK's native dir first on java library path`() {
        // Without it libbare-kit.so is not found at all (UnsatisfiedLinkError); with it anywhere but
        // first, a libc++_shared.so the firmware ships can win over the APK's own copy.
        assertTrue(launch, launch.contains("-Djava.library.path=$lib:/system/lib64"))
    }

    @Test
    fun `guards against a second copy inside the same shell invocation`() {
        assertTrue(launch, launch.startsWith("if pidof pear_daemon > /dev/null 2>&1; then echo already_running;"))
        assertTrue(launch, launch.contains("> ${PearLauncher.PEAR_LOG} 2>&1 & echo launched; fi"))
    }

    @Test
    fun `never probes with pgrep`() {
        // pgrep matches comm, which reads "main" for every app_process daemon: it would never find
        // pear_daemon, so a probe wedged at "stopped" would relaunch it every 30 s forever.
        for (cmd in listOf(launch, PearLauncher.isRunningCommand(), PearLauncher.stopCommand())) {
            assertFalse(cmd, cmd.contains("pgrep"))
        }
        assertEquals(
            "pidof pear_daemon > /dev/null 2>&1 && echo yes || echo no",
            PearLauncher.isRunningCommand()
        )
    }

    @Test
    fun `stops with killall, never pkill -f, and deletes nothing`() {
        val stop = PearLauncher.stopCommand()
        assertEquals("killall -9 pear_daemon 2>/dev/null; echo done", stop)
        // pkill -f matches its own pattern inside the ADB shell's command line and kills that shell.
        assertFalse(stop, stop.contains("pkill"))
        // The storage dir will hold the car's permanent Pear identity; a stop must be reversible.
        assertFalse(stop, stop.contains("rm "))
    }

    @Test
    fun `process name fits the kernel's comm cap`() {
        assertTrue(PearLauncher.PEAR_PROCESS.length <= 15)
    }

    @Test
    fun `refuses paths that could break out of the shell command`() {
        for (bad in listOf("/data/app/x'; rm -rf /data;'", "/data/app/has space/base.apk", "/data/app/\$(id)")) {
            assertThrows(IllegalArgumentException::class.java) { PearLauncher.launchCommand(bad, lib) }
            assertThrows(IllegalArgumentException::class.java) { PearLauncher.launchCommand(apk, bad) }
        }
    }

    @Test
    fun `every log call goes through the PEAR_LAUNCHER gate`() {
        // Source scan (declared as a test input in app/build.gradle.kts): logManager may only be
        // touched inside the gated log() helper, so a new direct call cannot bypass the flag.
        val path = "src/main/java/com/loabletech/bladewatch/launcher/PearLauncher.kt"
        val src = listOf(File(path), File("app/$path")).first { it.isFile }.readText()
        val helper = src.substringAfter("private fun log(").substringBefore("\n    }\n")
        assertTrue(helper, helper.contains("DaemonLogConfig.PEAR_LAUNCHER"))
        assertEquals(
            "a logManager call outside the gated log() helper",
            helper.split("logManager.").size,
            src.split("logManager.").size
        )
        assertFalse("must ship false", DaemonLogConfig.PEAR_LAUNCHER)
    }
}
