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
            val body = extractClassBody(source, "class $className extends VehicleCommand")
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

        @Throws(IOException::class)
        private fun read(relative: String): String {
            val p = sourceRoot().resolve("com/loabletech/bladewatch").resolve(relative)
            Assert.assertTrue("missing source file: $p", Files.isRegularFile(p))
            return String(Files.readAllBytes(p), StandardCharsets.UTF_8)
        }

        /** Naive brace-counting extraction of one class's body, starting at its declaration. */
        private fun extractClassBody(source: String, declaration: String): String {
            val idx = source.indexOf(declaration)
            Assert.assertTrue("could not find class declaration '$declaration' in source", idx >= 0)
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
