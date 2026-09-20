package net.bladewatch.app.manifest;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.regex.Pattern;

import org.junit.Assert;
import org.junit.Test;

/**
 * BladeWatch-6mnq, phase 3: no handler keeps an HTTP-shaped entry point.
 *
 * <p>A REST handler's signature is {@code handle(method, path, body, OutputStream)}: it matches a
 * path, then writes JSON into a stream. The Connect layer called those through
 * {@code ConnectHandlerUtil.captureString}, which captured the bytes straight back out of the
 * stream into a string — a full HTTP request/response shape modelled in memory for no reason
 * beyond the handlers having been written that way first.
 *
 * <p>An inverted handler exposes one method per operation that RETURNS its JSON, and the Connect
 * impl calls it. This pins the handlers already inverted so they cannot drift back, and the list
 * grows as the rest follow.
 *
 * <p>Read as source TEXT: these classes need the daemon's singletons and cannot be built on the
 * JVM. {@code app/build.gradle.kts} declares {@code src/main/java} as a test input.
 */
public class NoRestHandlerEntryPointsTest {

    /**
     * Handlers that keep an {@code OutputStream} entry point ON PURPOSE, with the reason. They
     * are not JSON APIs, so ConnectRPC is not an option for them:
     *
     * <ul>
     *   <li>{@code AuthApiHandler} — {@code /auth/status} and {@code /auth/token} are the
     *       PRE-AUTH bootstrap. {@code login.html} is plain HTML served before any Connect
     *       client exists, and it is the one page that has to work when everything else is
     *       broken. {@code AuthService.Login} exists for the SPA; the bootstrap stays HTTP.
     *   <li>{@code StreamingApiHandler} — PARTIALLY exempt, like Recordings. Its seven JSON
     *       operations ARE inverted; the only HTTP route left is
     *       {@code GET /api/stream/still}, a JPEG the Angular live view consumes as an image
     *       URL.
     *   <li>{@code RecordingsApiHandler} — PARTIALLY exempt. Its JSON operations ARE inverted
     *       (BladeWatch-6mnq); only {@code handleWithRange} remains, serving {@code /video/*}
     *       and {@code /thumb/*} byte ranges to a player and an {@code <img src>}. That is why
     *       it cannot go in {@code INVERTED}: the file legitimately still names an
     *       {@code OutputStream} parameter.
     * </ul>
     */
    private static final List<String> BINARY_OR_BOOTSTRAP = Arrays.asList(
        "AuthApiHandler",
        "StreamingApiHandler",
        "RecordingsApiHandler"
    );

    /** Handlers already inverted. Add to this list as each one follows — never remove. */
    private static final List<String> INVERTED = Arrays.asList(
        "GpsApiHandler",
        "SafeLocationApiHandler",
        "FormatStorageApiHandler",
        "NotificationApiHandler",
        "ModelsApiHandler",
        "AudioTestApiHandler",
        "ExternalStorageApiHandler",
        "PerformanceApiHandler",
        "VehicleControlApiHandler",
        "SurveillanceApiHandler",
        "QualitySettingsApiHandler"
    );

    @Test
    public void invertedHandlersHaveNoOutputStreamEntryPoint() throws IOException {
        List<String> offenders = new ArrayList<>();
        for (String handler : INVERTED) {
            String src = stripComments(read("server/" + handler));
            // Match the REST ENTRY-POINT shape — a method that takes an OutputStream to write
            // its response into — not any mention of the word. SurveillanceApiHandler encodes
            // a JPEG through a ByteArrayOutputStream, which is an in-memory buffer and has
            // nothing to do with HTTP; flagging that would push the next author into
            // contorting working code to satisfy a guard.
            // A PARAMETER whose type is an OutputStream, however it is spelled — bare,
            // java.io.-qualified, or final. Anything narrower lets the shape back in under a
            // different spelling, which a first attempt at this guard did.
            if (OUTPUT_STREAM_PARAM.matcher(src).find()) {
                offenders.add(handler);
            }
        }
        Assert.assertEquals(
                "These handlers have regained an OutputStream entry point. An inverted handler "
                        + "RETURNS its JSON and the Connect impl calls it directly; writing into a "
                        + "stream only to have ConnectHandlerUtil capture it back out is the REST "
                        + "shape this removes (BladeWatch-6mnq). Offenders: " + offenders,
                List.of(), offenders);
    }

    @Test
    public void nothingCapturesAnInvertedHandlerBackOutOfAStream() throws IOException {
        // The other half: a handler could return JSON and still be called through captureString
        // by a caller that kept the old shape, which would leave the round-trip in place.
        List<String> offenders = new ArrayList<>();
        Path implDir = sourceRoot().resolve("com/loabletech/bladewatch/server/connect/impl");
        File[] impls = implDir.toFile().listFiles(
                (d, n) -> n.endsWith(".java") || n.endsWith(".kt"));
        Assert.assertTrue("found no Connect impls to scan -- this guard has stopped reading them "
                + "and can no longer fail", impls != null && impls.length > 5);
        for (File f : impls) {
            String src = stripComments(
                    new String(Files.readAllBytes(f.toPath()), StandardCharsets.UTF_8));
            for (String type : INVERTED) {
                // A PROXIMITY window, not a ';' split: Kotlin has no statement terminator, so
                // splitting on ';' would treat a whole .kt file as one statement and flag any
                // file that merely mentions both words. The window also survives the multi-line
                // lambda a capture call is normally written as.
                if (Pattern.compile("capture\\w*\\s*[({][\\s\\S]{0,200}?\\b"
                        + Pattern.quote(type) + "\\.").matcher(src).find()) {
                    offenders.add(f.getName() + " -> " + type);
                }
            }
        }
        Assert.assertEquals(
                "An inverted handler is still being called through ConnectHandlerUtil.capture*. "
                        + "Call it directly (BladeWatch-6mnq). Offenders: " + offenders,
                List.of(), offenders);
    }

    /**
     * The exemptions and the inverted list must stay disjoint.
     *
     * <p>Otherwise a handler could be "inverted" and exempt at once, which would let the
     * ratchet pass while the REST shape survived — the exact kind of guard that cannot fail.
     */
    @Test
    public void nothingIsBothInvertedAndExempt() {
        List<String> both = new ArrayList<>(INVERTED);
        both.retainAll(BINARY_OR_BOOTSTRAP);
        Assert.assertEquals("a handler cannot be both inverted and exempt from inversion",
                List.of(), both);
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
     * A PARAMETER whose type is an OutputStream, in either language's spelling:
     * Java writes {@code OutputStream out} (bare, {@code java.io.}-qualified, or {@code final}),
     * Kotlin writes {@code out: OutputStream}. Matching only one of the two would leave this
     * ratchet silently passing the moment a handler is converted -- and a guard that cannot fail
     * is worse than no guard. It still matches the ENTRY-POINT shape only, not any mention of the
     * word: SurveillanceApiHandler encodes a JPEG through a ByteArrayOutputStream, an in-memory
     * buffer with nothing to do with HTTP, and flagging that would push the next author into
     * contorting working code to satisfy a guard.
     */
    private static final Pattern OUTPUT_STREAM_PARAM = Pattern.compile(
            // Java: (OutputStream out  /  , final java.io.OutputStream out
            "[(,]\\s*(?:final\\s+)?(?:[A-Za-z_][\\w.]*\\.)?OutputStream\\s+\\w+"
            // Kotlin: (out: OutputStream  /  , out: java.io.OutputStream
            + "|[(,]\\s*(?:vararg\\s+)?\\w+\\s*:\\s*(?:[A-Za-z_][\\w.]*\\.)?OutputStream\\b");

    /**
     * Read a handler by base name, in whichever language it is written in today. Both spellings
     * present means a half-finished conversion, and the guard would read the stale copy.
     */
    private static String read(String relative) throws IOException {
        Path java = sourceRoot().resolve("com/loabletech/bladewatch").resolve(relative + ".java");
        Path kotlin = sourceRoot().resolve("com/loabletech/bladewatch").resolve(relative + ".kt");
        boolean hasJava = Files.isRegularFile(java);
        boolean hasKotlin = Files.isRegularFile(kotlin);
        Assert.assertTrue("missing source file (.java or .kt): " + java, hasJava || hasKotlin);
        Assert.assertFalse("both a .java and a .kt exist for " + relative
                + " -- a half-finished conversion; this guard would read the stale copy",
                hasJava && hasKotlin);
        return new String(Files.readAllBytes(hasJava ? java : kotlin), StandardCharsets.UTF_8);
    }
}
