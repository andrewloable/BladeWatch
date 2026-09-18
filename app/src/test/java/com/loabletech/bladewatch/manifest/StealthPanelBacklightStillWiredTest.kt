package net.bladewatch.app.manifest

import org.junit.Assert
import org.junit.Test
import java.io.File
import java.io.IOException
import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.Path

/**
 * BladeWatch-2000.3: the constraint was explicit -- "Do not change the stealth-panel path in
 * AccSentryDaemon. It works and surveillance depends on it. Extract a shared helper if you
 * must, but its behaviour must be identical afterwards — pin that with a test if you extract."
 *
 * `AccSentryDaemon.setBacklightState`'s PowerManager/BYD-hardware-service reflection cascade
 * was extracted into `BacklightController` so the new explicit screen on/off vehicle command
 * could share it. This is a source-level guard (the actual reflection is not exercisable in a
 * plain JVM test on any of these classes) pinning two things a future refactor could silently
 * break: the stealth-panel call sites still exist, unchanged, and `setBacklightState` still
 * delegates to the shared class rather than a re-duplicated copy of the reflection logic.
 */
class StealthPanelBacklightStillWiredTest {

    @Test
    @Throws(IOException::class)
    fun stealthPanelCallSitesStillInvokeSetBacklightState() {
        val daemon = read("daemon/AccSentryDaemon.java")
        Assert.assertTrue(
            "AccSentryDaemon no longer calls setBacklightState(true) -- the stealth panel's wake path is gone",
            daemon.contains("setBacklightState(true)")
        )
        Assert.assertTrue(
            "AccSentryDaemon no longer calls setBacklightState(false) -- the stealth panel's sleep-fallback path is gone",
            daemon.contains("setBacklightState(false)")
        )
    }

    @Test
    @Throws(IOException::class)
    fun setBacklightStateDelegatesToTheSharedController() {
        val daemon = read("daemon/AccSentryDaemon.java")
        val body = extractMethodBody(daemon, "private static void setBacklightState(boolean on)")
        Assert.assertTrue(
            "AccSentryDaemon.setBacklightState no longer delegates to BacklightController -- either the " +
                "extraction was reverted (fine, as long as the reflection logic itself is still there) or " +
                "the two implementations have silently diverged",
            body.contains("BacklightController.setBacklight")
        )
    }

    @Test
    @Throws(IOException::class)
    fun backlightControllerStillTriesBothPowerManagerNameVariants() {
        // BacklightController.kt, not .java -- it was converted to Kotlin after this test was
        // first written; the reflection method-name string literals are unchanged either way.
        val controller = read("byd/BacklightController.kt")
        Assert.assertTrue(
            "BacklightController no longer tries the camelCase PowerManager method name",
            controller.contains("turnBacklightOn")
        )
        Assert.assertTrue(
            "BacklightController no longer tries the PascalCase PowerManager method name -- this is the " +
                "one BYD's vendor SDK actually exposes on this firmware",
            controller.contains("TurnBacklightOn")
        )
    }

    companion object {
        private fun sourceRoot(): Path {
            var p = Path.of("src/main/java")
            if (!Files.isDirectory(p)) p = Path.of("app/src/main/java")
            Assert.assertTrue(
                "could not locate the app sources from " + File(".").absolutePath,
                Files.isDirectory(p)
            )
            return p
        }

        @Throws(IOException::class)
        private fun read(relative: String): String {
            val p = sourceRoot().resolve("com/loabletech/bladewatch").resolve(relative)
            Assert.assertTrue("missing source file: $p", Files.isRegularFile(p))
            return String(Files.readAllBytes(p), StandardCharsets.UTF_8)
        }

        /** Naive brace-counting extraction of one method's body, starting at its signature. */
        private fun extractMethodBody(source: String, signature: String): String {
            val sigIdx = source.indexOf(signature)
            Assert.assertTrue("could not find method signature '$signature' in source", sigIdx >= 0)
            val openBrace = source.indexOf('{', sigIdx)
            Assert.assertTrue("could not find opening brace after '$signature'", openBrace >= 0)
            var depth = 0
            for (i in openBrace until source.length) {
                when (source[i]) {
                    '{' -> depth++
                    '}' -> {
                        depth--
                        if (depth == 0) return source.substring(openBrace, i + 1)
                    }
                }
            }
            throw AssertionError("unbalanced braces while extracting '$signature'")
        }
    }
}
