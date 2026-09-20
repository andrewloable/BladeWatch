package net.bladewatch.app.manifest

import org.junit.Assert
import org.junit.Test
import java.io.File
import java.io.IOException
import java.nio.charset.StandardCharsets
import java.nio.file.Files
import java.nio.file.Path

/**
 * BladeWatch-2000.1: "assert that each command reaches the right collector method... and no
 * other collector method is called". `BydDataCollector` has a private constructor (singleton)
 * and this project has no Mockito/Robolectric, so that cannot be a behavioural stub test --
 * see `ClimateCommandRoutingTest`'s own doc comment for the same finding against every
 * pre-existing VehicleCommand subclass, not just these four. Verified instead as a
 * source-text guard, matching `NoUngatedActuationTest` /
 * `StealthPanelBacklightStillWiredTest`'s identical shape: each new command class's
 * `executeViaSdk` body must call its OWN collector method and must not call any of the other
 * three's.
 */
class ClimateCommandCollectorWiringTest {

    // Four separate test methods, not one method with four assertion calls, so that a defect
    // affecting only one command class fails only that command's test -- e.g. swapping the
    // front/rear defrost bodies must fail exactly frontDefrostCommand_callsOnlyItsOwn... and
    // rearDefrostCommand_callsOnlyItsOwn..., not silently hide behind an earlier assertion in
    // the same method.

    @Test
    @Throws(IOException::class)
    fun frontDefrostCommand_callsOnlyItsOwnCollectorMethod() {
        assertCallsOnlyItsOwn(
            read("byd/routing/VehicleCommandRouter.java"), "FrontDefrostCommand", "setFrontDefrost",
            arrayOf("setRearDefrost", "setAcWindMode", "setAcCycleMode")
        )
    }

    @Test
    @Throws(IOException::class)
    fun rearDefrostCommand_callsOnlyItsOwnCollectorMethod() {
        assertCallsOnlyItsOwn(
            read("byd/routing/VehicleCommandRouter.java"), "RearDefrostCommand", "setRearDefrost",
            arrayOf("setFrontDefrost", "setAcWindMode", "setAcCycleMode")
        )
    }

    @Test
    @Throws(IOException::class)
    fun windModeCommand_callsOnlyItsOwnCollectorMethod() {
        assertCallsOnlyItsOwn(
            read("byd/routing/VehicleCommandRouter.java"), "ClimateSetWindModeCommand", "setAcWindMode",
            arrayOf("setFrontDefrost", "setRearDefrost", "setAcCycleMode")
        )
    }

    @Test
    @Throws(IOException::class)
    fun cycleModeCommand_callsOnlyItsOwnCollectorMethod() {
        assertCallsOnlyItsOwn(
            read("byd/routing/VehicleCommandRouter.java"), "ClimateSetCycleModeCommand", "setAcCycleMode",
            arrayOf("setFrontDefrost", "setRearDefrost", "setAcWindMode")
        )
    }

    companion object {
        private fun assertCallsOnlyItsOwn(source: String, className: String, expectedMethod: String, mustNotCall: Array<String>) {
            val body = extractCommandClassBody(source, className)
            Assert.assertTrue(
                "$className.executeViaSdk must call BydDataCollector.$expectedMethod",
                body.contains("$expectedMethod(")
            )
            for (forbidden in mustNotCall) {
                Assert.assertFalse(
                    "$className must not call $forbidden -- that belongs to a different command",
                    body.contains("$forbidden(")
                )
            }
        }

        private fun sourceRoot(): Path {
            var p = Path.of("src/main/java")
            if (!Files.isDirectory(p)) p = Path.of("app/src/main/java")
            Assert.assertTrue(
                "could not locate the app sources from " + File(".").absolutePath,
                Files.isDirectory(p)
            )
            return p
        }

        /**
         * Read a source file by path, in whichever language it is written in today. The
         * extension in the argument is advisory: the app sources are migrating from Java to
         * Kotlin (BladeWatch-dmrg), and a guard that keeps asking for a ".java" that no longer
         * exists stops guarding without ever failing. Both spellings present means a
         * half-finished conversion, and this would read the stale copy.
         */
        @Throws(IOException::class)
        private fun read(relative: String): String {
            val base = relative.substringBeforeLast('.')
            val dir = sourceRoot().resolve("com/loabletech/bladewatch")
            val java = dir.resolve("$base.java")
            val kotlin = dir.resolve("$base.kt")
            val hasJava = Files.isRegularFile(java)
            val hasKotlin = Files.isRegularFile(kotlin)
            Assert.assertTrue("missing source file (.java or .kt): " + dir.resolve(base),
                hasJava || hasKotlin)
            Assert.assertFalse(
                "both a .java and a .kt exist for $base -- a half-finished conversion; " +
                    "this guard would read the stale copy",
                hasJava && hasKotlin
            )
            return String(
                Files.readAllBytes(if (hasJava) java else kotlin), StandardCharsets.UTF_8
            )
        }

        /**
         * The body of one VehicleCommand subclass, in whichever language it is written in
         * today: Java spells the declaration `class X extends VehicleCommand`, Kotlin spells
         * it `class X(...) : VehicleCommand()`. Matching only one leaves this guard unable to
         * find the class at all once the file is converted -- and a guard that cannot run is
         * worse than no guard.
         */
        private fun extractCommandClassBody(source: String, className: String): String {
            val decl = Regex("""class\s+${Regex.escape(className)}\b[^{]*VehicleCommand[^{]*""")
            val m = decl.find(source)
            Assert.assertTrue(
                "could not find a VehicleCommand subclass named '$className' in either " +
                    "language's spelling",
                m != null
            )
            return extractClassBody(source, m!!.range.first, className)
        }

        /** Naive brace-counting extraction of one class's body, starting at its declaration. */
        private fun extractClassBody(source: String, idx: Int, declaration: String): String {
            val openBrace = source.indexOf('{', idx)
            Assert.assertTrue("could not find opening brace after '$declaration'", openBrace >= 0)
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
            throw AssertionError("unbalanced braces while extracting '$declaration'")
        }
    }
}
