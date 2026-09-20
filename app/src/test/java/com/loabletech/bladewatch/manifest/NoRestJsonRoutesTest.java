package net.bladewatch.app.manifest;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.junit.Assert;
import org.junit.Test;

/**
 * BladeWatch-6mnq: ConnectRPC is the only JSON API surface.
 *
 * <p>The REST surface and Connect were maintained in parallel, with Connect wrapping the REST
 * handlers "to keep the two surfaces in 1:1 parity". Two surfaces over one implementation is
 * how they drift: {@code GetSohNominal} reported a hardcoded "unset" while the capacity was
 * demonstrably known, and {@code ServiceLauncher} kept a hand-rolled failure check that
 * BladeWatch-boat had already replaced elsewhere. Only one surface is served now.
 *
 * <p>These routes stay plain HTTP and are NOT a JSON API — a browser must fetch them directly
 * and cannot speak Connect:
 *
 * <ul>
 *   <li>{@code /video/*} and {@code /thumb/*} — player byte-range requests and {@code <img src>}
 *   <li>{@code /api/stream/*} — MJPEG and still frames, consumed as image URLs
 *   <li>the Angular bundle, {@code /login}, {@code /manifest.json}, {@code /sw.js},
 *       {@code /i18n/*}, {@code /shared/*}
 * </ul>
 *
 * <p>Read as source TEXT: {@code HttpServer} needs a bound socket and the daemon's singletons,
 * so its routing cannot be exercised on the JVM. {@code app/build.gradle.kts} declares
 * {@code src/main/java} as a test input, so this re-runs when the routing changes.
 */
public class NoRestJsonRoutesTest {

    /** The only {@code /api/} prefix that may still be routed over HTTP. */
    private static final String ALLOWED_BINARY_PREFIX = "/api/stream";

    @Test
    public void httpServerRoutesNoJsonApiPaths() throws IOException {
        String src = stripComments(read("server/HttpServer.java"));
        List<String> offenders = new ArrayList<>();
        Matcher m = Pattern.compile("\"(/api/[A-Za-z0-9._/-]*)\"").matcher(src);
        while (m.find()) {
            String route = m.group(1);
            if (route.startsWith(ALLOWED_BINARY_PREFIX)) continue;
            offenders.add(route);
        }
        Assert.assertEquals(
                "HttpServer still routes REST JSON paths. Every JSON endpoint is a ConnectRPC "
                        + "method under /bladewatch.v1.* (BladeWatch-6mnq); only " + ALLOWED_BINARY_PREFIX
                        + ", /video/ and /thumb/ stay HTTP, because a browser fetches those "
                        + "directly and cannot speak Connect. Still routed: " + offenders,
                List.of(), offenders);
    }

    @Test
    public void theBinaryRoutesAreStillServed() throws IOException {
        // The other half of the same requirement: this must not be satisfiable by deleting the
        // media routes too, which would break the live view and video playback outright.
        String src = read("server/HttpServer.java");
        Assert.assertTrue("/video/ must still be served — a player fetches it by URL",
                src.contains("\"/video/\""));
        Assert.assertTrue("/thumb/ must still be served — it is an <img src>",
                src.contains("\"/thumb/\""));
        Assert.assertTrue(ALLOWED_BINARY_PREFIX + " must still be served — still frames are an "
                + "<img src> and MJPEG is a stream",
                src.contains("\"" + ALLOWED_BINARY_PREFIX + "\""));
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
}
