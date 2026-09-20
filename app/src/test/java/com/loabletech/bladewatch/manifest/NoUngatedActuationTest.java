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
        String body = extractExecuteBody(router);
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
        String body = extractExecuteBody(router);
        Assert.assertTrue(
                "VehicleCommandRouter.execute(VehicleCommand) no longer returns "
                        + "CommandResult.blockedUnsafe -- it may still consult DrivingSafetyGuard, "
                        + "but nothing is refused any more, so the motion interlock "
                        + "(BladeWatch-2pnn.2) does not actually gate anything.",
                body.contains("blockedUnsafe"));
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

    /**
     * The router's dispatch method, in whichever language it is written in today: Java spells
     * the parameter {@code execute(VehicleCommand cmd)}, Kotlin spells it
     * {@code execute(cmd: VehicleCommand)}. Matching only one leaves this guard unable to find
     * the method at all the moment the file is converted -- and a guard that cannot run is
     * worse than no guard.
     */
    private static String extractExecuteBody(String source) {
        java.util.regex.Matcher m = EXECUTE_SIGNATURE.matcher(source);
        Assert.assertTrue("could not find VehicleCommandRouter.execute(VehicleCommand) "
                + "in either language's spelling", m.find());
        return extractMethodBody(source, m.start());
    }

    /** Java: execute(VehicleCommand cmd)   Kotlin: execute(cmd: VehicleCommand) */
    private static final java.util.regex.Pattern EXECUTE_SIGNATURE = java.util.regex.Pattern.compile(
            "\\bexecute\\s*\\(\\s*(?:final\\s+)?VehicleCommand\\s+\\w+\\s*\\)"
            + "|\\bexecute\\s*\\(\\s*\\w+\\s*:\\s*VehicleCommand\\s*\\)");

    /** Naive brace-counting extraction of one method's body, starting at its signature. */
    private static String extractMethodBody(String source, int sigIdx) {
        int openBrace = source.indexOf('{', sigIdx);
        Assert.assertTrue("could not find opening brace after the execute signature", openBrace >= 0);
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
        throw new AssertionError("unbalanced braces while extracting the execute body");
    }
}
