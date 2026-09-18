package net.bladewatch.app.manifest;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import org.junit.Assert;
import org.junit.Test;

/**
 * BladeWatch-2pnn.2: every vehicle actuation must funnel through the motion interlock.
 *
 * <p>{@code VehicleCommandRouter.execute(VehicleCommand)} is the single chokepoint every
 * command passes through -- see {@code NoUngatedTrunkOpenTest} for why a per-command
 * interlock was rejected once already. This reads the method body as source TEXT (not via
 * the classpath) and pins that it still references {@code DrivingSafetyGuard}. A future
 * refactor that deletes the guard call would otherwise compile clean and pass every
 * behavioural test that does not happen to exercise the deleted branch -- a guard that
 * cannot fail is worse than no guard.
 */
public class NoUngatedActuationTest {

    private static Path sourceRoot() {
        Path p = Path.of("src/main/java");
        if (!Files.isDirectory(p)) p = Path.of("app/src/main/java");
        Assert.assertTrue("could not locate the app sources from "
                + new File(".").getAbsolutePath(), Files.isDirectory(p));
        return p;
    }

    @Test
    public void executeReferencesTheMotionGuard() throws IOException {
        String router = read("byd/routing/VehicleCommandRouter.java");
        String body = extractMethodBody(router, "execute(VehicleCommand cmd)");
        Assert.assertTrue(
                "VehicleCommandRouter.execute(VehicleCommand) no longer references "
                        + "DrivingSafetyGuard -- the motion interlock (BladeWatch-2pnn.2) has been "
                        + "removed or bypassed. Every vehicle actuation must be gated here, not "
                        + "per-command.",
                body.contains("DrivingSafetyGuard"));
    }

    /**
     * Referencing the guard is not the same as obeying it. Mutating the gate to
     * {@code if (false && decision != ALLOW)} keeps the {@code DrivingSafetyGuard} reference
     * above intact while letting every command through, so the check above alone would pass a
     * router with no working interlock. The refusal path has exactly one expression --
     * {@code CommandResult.blockedUnsafe} -- so pinning that it is still reachable from this
     * method body closes that gap without parsing Java.
     */
    @Test
    public void executeStillHasARefusalPath() throws IOException {
        String router = read("byd/routing/VehicleCommandRouter.java");
        String body = extractMethodBody(router, "execute(VehicleCommand cmd)");
        Assert.assertTrue(
                "VehicleCommandRouter.execute(VehicleCommand) no longer returns "
                        + "CommandResult.blockedUnsafe -- it may still consult DrivingSafetyGuard, "
                        + "but nothing is refused any more, so the motion interlock "
                        + "(BladeWatch-2pnn.2) does not actually gate anything.",
                body.contains("blockedUnsafe"));
    }

    private static String read(String relative) throws IOException {
        Path p = sourceRoot().resolve("com/loabletech/bladewatch").resolve(relative);
        Assert.assertTrue("missing source file: " + p, Files.isRegularFile(p));
        return new String(Files.readAllBytes(p), StandardCharsets.UTF_8);
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
