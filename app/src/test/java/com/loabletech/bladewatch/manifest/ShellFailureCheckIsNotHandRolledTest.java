package net.bladewatch.app.manifest;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import org.junit.Assert;
import org.junit.Test;

/**
 * BladeWatch-ieva: one definition of "did this shell command fail", not two.
 *
 * <p>BladeWatch-boat replaced {@code result.contains("Error")} in
 * {@code SentryDaemon.restartLocationService} with {@link net.bladewatch.app.daemon.ShellResultClassifier},
 * because the real refusal output on this head unit contains no such substring. The identical
 * decision, over the identical {@code am start-foreground-service} command, survived unfixed in
 * {@code ServiceLauncher.startLocationSidecarService} — where it is worse, because the result
 * chooses between {@code callback.onError} and {@code callback.onLaunched} and so reaches the UI.
 *
 * <p>Its old condition also mapped EMPTY output to a successful launch. A command that produced
 * nothing at all did not demonstrably start anything; the classifier treats null/blank as
 * failure for exactly that reason.
 *
 * <p>Read as source TEXT rather than through the classpath: {@code ServiceLauncher} needs ADB and
 * an Android context and cannot be constructed on the JVM. {@code app/build.gradle.kts} declares
 * {@code src/main/java} as a test input, so this re-runs when the source changes.
 */
public class ShellFailureCheckIsNotHandRolledTest {

    @Test
    public void startLocationSidecarServiceUsesTheSharedClassifier() throws IOException {
        String body = stripComments(extractMethodBody(
                read("launcher/ServiceLauncher.kt"),
                "fun startLocationSidecarService("));
        Assert.assertTrue(
                "ServiceLauncher.startLocationSidecarService does not use ShellResultClassifier. "
                        + "It is the same decision over the same am command that BladeWatch-boat "
                        + "fixed in SentryDaemon; a second copy is how the first one drifted "
                        + "(BladeWatch-ieva).",
                body.contains("ShellResultClassifier"));
    }

    @Test
    public void startLocationSidecarServiceDoesNotHandRollTheMarkers() throws IOException {
        String body = stripComments(extractMethodBody(
                read("launcher/ServiceLauncher.kt"),
                "fun startLocationSidecarService("));
        // Referencing the classifier is not the same as relying on it: a call site could consult
        // it and still keep its own substring test alongside, which is the drift this pins shut.
        Assert.assertFalse(
                "ServiceLauncher.startLocationSidecarService still tests the output for failure "
                        + "markers itself. The marker list belongs in ShellResultClassifier and "
                        + "nowhere else (BladeWatch-ieva).",
                body.contains("contains(\"Error\")") || body.contains("contains(\"Exception\")"));
    }

    /** Removes comments so the assertions read CODE, not prose. */
    private static String stripComments(String source) {
        return source.replaceAll("(?s)/\\*.*?\\*/", " ").replaceAll("(?m)//.*$", " ");
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
