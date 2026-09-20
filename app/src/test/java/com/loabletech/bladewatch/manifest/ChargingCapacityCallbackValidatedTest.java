package net.bladewatch.app.manifest;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import org.junit.Assert;
import org.junit.Test;

/**
 * BladeWatch-62tg: every writer of {@code remainKwh} must validate before writing.
 *
 * <p>The three polled sources in {@code BydDataCollector.collectBodywork} all go through
 * {@code BydSignalRules} first. The block comment above them explains why at length: without
 * it, sources race and last-writer-wins, and on a Seal a correct 16.5 kWh reading was
 * overwritten by a wrong 20.6 kWh one, poisoning every downstream auto-detection.
 *
 * <p>{@code handleChargingCapacityChanged} had none of that. It accepted anything in
 * {@code 0..200} -- a window that admits the whole 0-100 percentage range -- and wrote it
 * straight into {@code remainKwh}, so an unvalidated callback could clobber a validated poll.
 *
 * <p>Read as source TEXT rather than through the classpath: {@code BydDataCollector} needs the
 * BYD HAL and cannot be constructed on the JVM. {@code app/build.gradle.kts} declares
 * {@code src/main/java} as a test input, so this re-runs when the source changes.
 *
 * <p>Deliberately NOT pinned here: a percentage that happens to equal the current SoC still
 * passes {@code isRemainKwhConsistentWithSoc}, because its implied capacity is ~100 kWh and
 * that is a real BYD pack size. No SoC-only rule can separate that from a genuine reading.
 * It is caught downstream by {@code NominalCapacityResolver.looksLikeSocMirror} instead of by
 * teaching the collector a model-specific rule.
 */
public class ChargingCapacityCallbackValidatedTest {

    @Test
    public void theCallbackValidatesBeforeWritingRemainKwh() throws IOException {
        String source = read("byd/BydDataCollector.java");
        String body = stripComments(extractMethodBody(source, handleChargingCapacityChangedSignature(source)));
        Assert.assertTrue(
                "BydDataCollector.handleChargingCapacityChanged writes remainKwh without "
                        + "consulting BydSignalRules. Every other remainKwh writer validates first, "
                        + "so an unvalidated callback can overwrite a validated poll "
                        + "(BladeWatch-62tg).",
                body.contains("BydSignalRules"));
    }

    @Test
    public void theCallbackStillCrossChecksAgainstSoc() throws IOException {
        String source = read("byd/BydDataCollector.java");
        String body = stripComments(extractMethodBody(source, handleChargingCapacityChangedSignature(source)));
        // Naming BydSignalRules is not the same as cross-checking SoC: isPlausibleRemainKwh
        // alone is a 1-120 window that still admits the entire percentage range.
        Assert.assertTrue(
                "BydDataCollector.handleChargingCapacityChanged no longer cross-checks the value "
                        + "against SoC, so a percentage in the 1-120 range is still accepted as kWh "
                        + "(BladeWatch-62tg).",
                body.contains("isRemainKwhConsistentWithSoc"));
    }

    /**
     * The {@code handleChargingCapacityChanged} signature, in whichever language {@code
     * BydDataCollector} is written in today. Java spells it {@code private void
     * handleChargingCapacityChanged(} and Kotlin {@code private fun
     * handleChargingCapacityChanged(} -- a guard that only knows one of them stops guarding
     * the moment the file is converted, without ever failing (BladeWatch-dmrg).
     */
    private static String handleChargingCapacityChangedSignature(String source) {
        return source.contains("private void handleChargingCapacityChanged(")
                ? "private void handleChargingCapacityChanged("
                : "private fun handleChargingCapacityChanged(";
    }

    /** Removes comments so the assertions read CODE, not prose. */
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
