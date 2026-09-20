package net.bladewatch.app.manifest;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import org.junit.Assert;
import org.junit.Test;

/**
 * BladeWatch-hdt7: the BYD "remaining kWh" channel is not energy on this car.
 *
 * <p>Measured off the device's own SoC history (963 rows, 2026-09-19) it mirrors SoC percent
 * 1:1 -- soc=73/remain=72.9, soc=77/remain=77.0, soc=79/remain=78.8. Anything that stores or
 * reports {@code BydVehicleData.remainKwh} as an energy value is therefore reporting a
 * percentage with a kWh label, overstating by roughly 5.4x on this 18.3 kWh pack.
 *
 * <p>{@code VehicleDataMonitor.getBatteryRemainPowerKwh()} is the one accessor that validates
 * the channel against SoC and nominal capacity and substitutes a computed value when the BMS
 * reading is inconsistent. Three of the four writers in {@code SocHistoryDatabase} already go
 * through it; {@code recordAccEvent} did not, and its column feeds {@code getLastParkingDelta},
 * whose {@code deltaKwh} is surfaced over the {@code GetParkingDelta} RPC.
 *
 * <p>This reads the method body as source TEXT rather than through the classpath, because
 * {@code SocHistoryDatabase} needs a live H2 database and a BYD HAL and cannot be built on the
 * JVM. {@code app/build.gradle.kts} declares {@code src/main/java} as a test input, so this
 * re-runs when the source changes rather than passing stale -- see the "Gradle up-to-date
 * blindness" note in CLAUDE.md.
 */
public class NoRawRemainKwhStoredAsEnergyTest {

    @Test
    public void recordAccEventDoesNotStoreTheRawChannel() throws IOException {
        String body = stripComments(recordAccEventBody());
        Assert.assertFalse(
                "SocHistoryDatabase.recordAccEvent reads BydVehicleData.remainKwh directly. That "
                        + "channel mirrors SoC percent on this car, so the value lands in "
                        + "ACC_EVENTS.remaining_kwh as a percentage labelled kWh and reaches the UI "
                        + "through getLastParkingDelta's deltaKwh. Use "
                        + "VehicleDataMonitor.getBatteryRemainPowerKwh(), as the other writers in "
                        + "this file do (BladeWatch-hdt7).",
                body.contains("remainKwh"));
    }

    @Test
    public void recordAccEventStillGoesThroughTheValidatingAccessor() throws IOException {
        String body = recordAccEventBody();
        // Not storing the raw channel is only half of it: a version that simply dropped the
        // column would also pass the check above while silently losing the data.
        Assert.assertTrue(
                "SocHistoryDatabase.recordAccEvent no longer calls getBatteryRemainPowerKwh(), so "
                        + "ACC_EVENTS.remaining_kwh is no longer populated from the validated "
                        + "accessor (BladeWatch-hdt7).",
                body.contains("getBatteryRemainPowerKwh"));
    }

    /**
     * The body of {@code recordAccEvent}, in whichever language the file is written in today.
     * Java spells the signature {@code public void recordAccEvent(} and Kotlin
     * {@code fun recordAccEvent(} -- a guard that only knows one of them stops guarding the
     * moment the file is converted, without ever failing (BladeWatch-dmrg).
     */
    private static String recordAccEventBody() throws IOException {
        String source = read("monitor/SocHistoryDatabase.java");
        String signature = source.contains("public void recordAccEvent(")
                ? "public void recordAccEvent(" : "fun recordAccEvent(";
        return extractMethodBody(source, signature);
    }

    /**
     * Removes comments so the assertion below reads CODE, not prose. Without this, a comment
     * that names the forbidden field -- including one explaining why it must not be used --
     * fails the check, which would push the next author into deleting the explanation.
     */
    private static String stripComments(String java) {
        return java.replaceAll("(?s)/\\*.*?\\*/", " ").replaceAll("(?m)//.*$", " ");
    }

    private static Path sourceRoot() {
        Path p = Path.of("src/main/java");
        if (!Files.isDirectory(p)) p = Path.of("app/src/main/java");
        Assert.assertTrue("could not locate the app sources from "
                + new File(".").getAbsolutePath(), Files.isDirectory(p));
        return p;
    }

    /**
     * Read a source file by path, in whichever language it is written in today. The extension in
     * the argument is advisory: the app sources are migrating from Java to Kotlin
     * (BladeWatch-dmrg), and a guard that keeps asking for a ".java" that no longer exists stops
     * guarding without ever failing. Both spellings present means a half-finished conversion, and
     * this would read the stale copy.
     */
    private static String read(String relative) throws IOException {
        int dot = relative.lastIndexOf('.');
        String base = relative.endsWith(".java") || relative.endsWith(".kt")
                ? relative.substring(0, dot) : relative;
        Path dir = sourceRoot().resolve("com/loabletech/bladewatch");
        Path java = dir.resolve(base + ".java");
        Path kotlin = dir.resolve(base + ".kt");
        boolean hasJava = Files.isRegularFile(java);
        boolean hasKotlin = Files.isRegularFile(kotlin);
        Assert.assertTrue("missing source file (.java or .kt): " + dir.resolve(base),
                hasJava || hasKotlin);
        Assert.assertFalse("both a .java and a .kt exist for " + base
                + " -- a half-finished conversion; this guard would read the stale copy",
                hasJava && hasKotlin);
        return new String(Files.readAllBytes(hasJava ? java : kotlin), StandardCharsets.UTF_8);
    }

    /** Naive brace-counting extraction of one method's body, starting at its signature. */
    private static String extractMethodBody(String source, String signature) {
        int sigIdx = source.indexOf(signature);
        Assert.assertTrue("could not find method signature '" + signature + "' in source", sigIdx >= 0);
        int openBrace = source.indexOf('{', sigIdx);
        Assert.assertTrue("could not find opening brace after '" + signature + "'", openBrace >= 0);
        int depth = 0;
        for (int i = openBrace; i < source.length(); i++) {
            char c = source.charAt(i);
            if (c == '{') {
                depth++;
            } else if (c == '}') {
                depth--;
                if (depth == 0) return source.substring(openBrace, i + 1);
            }
        }
        throw new AssertionError("unbalanced braces while extracting '" + signature + "'");
    }
}
