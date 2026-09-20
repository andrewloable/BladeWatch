package net.bladewatch.app.server;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.junit.Assert;
import org.junit.Test;

/**
 * BladeWatch-qrcj: every path prefix HttpServer hands to
 * {@code RecordingsApiHandler.handleWithRange} must actually be handled there.
 *
 * <p>This is not hypothetical. BladeWatch-6mnq removed the REST JSON dispatch from
 * RecordingsApiHandler, and the {@code /thumb/} branch went with it — while HttpServer kept
 * routing {@code /thumb/} to that method. handleWithRange returned false for it, the request fell
 * through to the static-file 404, and every thumbnail silently stopped loading: the events list,
 * the recordings grid, and the hero image in a Web Push notification banner. {@code
 * serveThumbnail} and its whole generation chain sat unreachable. Nothing failed, because nothing was
 * checking that the two sides agreed.
 *
 * <p>Reads both files as source TEXT: HttpServer needs a bound socket and RecordingsApiHandler
 * needs StorageManager's singletons, so neither can be exercised on the JVM. {@code
 * app/build.gradle.kts} declares {@code src/main/java} as a test input, so this re-runs when
 * either side changes rather than going UP-TO-DATE exactly when it matters.
 */
public class RecordingsRouteCoverageTest {

    /** The routing condition in HttpServer, e.g. {@code path.startsWith("/video/")}. */
    private static final Pattern STARTS_WITH =
            Pattern.compile("path\\.startsWith\\(\"(/[^\"]+)\"\\)");

    @Test
    public void everyPrefixRoutedToHandleWithRangeIsHandledThere() throws IOException {
        List<String> routed = prefixesRoutedToHandleWithRange();
        Assert.assertTrue(
                "Found no prefixes routed to RecordingsApiHandler.handleWithRange. Either the "
                        + "routing moved or this guard has stopped reading HttpServer -- fix it "
                        + "rather than deleting it.",
                routed.size() >= 2);

        String handler = read("server/RecordingsApiHandler");
        List<String> unhandled = new ArrayList<>();
        for (String prefix : routed) {
            if (!handler.contains("startsWith(\"" + prefix + "\")")) {
                unhandled.add(prefix);
            }
        }

        Assert.assertEquals(
                "HttpServer routes these prefixes to RecordingsApiHandler.handleWithRange, but "
                        + "that method does not handle them -- it returns false and the request "
                        + "falls through to the static-file 404. This is exactly how every "
                        + "thumbnail silently broke (BladeWatch-qrcj). Unhandled: " + unhandled,
                List.of(), unhandled);
    }

    /**
     * The prefixes in the single {@code if} that calls handleWithRange. Read from the condition
     * itself rather than a hardcoded list, so adding a third prefix to the route is covered
     * automatically.
     */
    private static List<String> prefixesRoutedToHandleWithRange() throws IOException {
        String[] lines = read("server/HttpServer").split("\n", -1);
        int call = -1;
        for (int i = 0; i < lines.length; i++) {
            if (lines[i].contains("RecordingsApiHandler.handleWithRange(")) {
                call = i;
                break;
            }
        }
        Assert.assertTrue("HttpServer no longer calls RecordingsApiHandler.handleWithRange",
                call >= 0);

        // The condition is on the line above the call, or the same line.
        StringBuilder condition = new StringBuilder();
        for (int i = Math.max(0, call - 3); i <= call; i++) {
            condition.append(lines[i]).append('\n');
        }

        List<String> prefixes = new ArrayList<>();
        Matcher m = STARTS_WITH.matcher(condition.toString());
        while (m.find()) {
            prefixes.add(m.group(1));
        }
        return prefixes;
    }

    /**
     * Read a source file by path without its extension. The server layer is migrating from Java to
     * Kotlin (BladeWatch-9rut); a guard that keeps asking for a ".java" that no longer exists
     * stops guarding without ever failing.
     */
    private static String read(String relativeNoExtension) throws IOException {
        File root = new File("src/main/java/com/loabletech/bladewatch");
        if (!root.isDirectory()) root = new File("app/src/main/java/com/loabletech/bladewatch");
        Assert.assertTrue("could not locate the source tree from "
                + new File(".").getAbsolutePath(), root.isDirectory());
        File java = new File(root, relativeNoExtension + ".java");
        File kotlin = new File(root, relativeNoExtension + ".kt");
        Assert.assertTrue("missing " + relativeNoExtension + " (.java or .kt)",
                java.isFile() || kotlin.isFile());
        Assert.assertFalse("both a .java and a .kt exist for " + relativeNoExtension
                + " -- a half-finished conversion; this guard would read the stale copy",
                java.isFile() && kotlin.isFile());
        File f = java.isFile() ? java : kotlin;
        return new String(Files.readAllBytes(f.toPath()), StandardCharsets.UTF_8);
    }
}
