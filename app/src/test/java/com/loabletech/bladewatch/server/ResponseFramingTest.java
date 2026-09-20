package net.bladewatch.app.server;

import java.io.File;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.junit.Assert;
import org.junit.Test;

/**
 * BladeWatch-67h8: every HTTP response must frame its own body.
 *
 * <p>Since keep-alive landed, a connection can carry several responses. If any one of them
 * fails to say how long its body is, the client cannot tell where it ends and the next
 * begins: the stream desynchronises and <em>every subsequent response on that connection is
 * corrupt</em>. That presents as random garbage rather than as a framing bug, which is why
 * it is pinned here instead of left to review.
 *
 * <p><b>The anchor matters, and the first version of this test got it wrong.</b> It keyed on
 * {@code Connection: close}, which only ever matched the four files that happened to emit
 * that header. Four more response writers — {@code ExternalStorageApiHandler},
 * {@code FormatStorageApiHandler} and two paths in {@code SurveillanceApiHandler} — never
 * emitted it at all and were therefore invisible to the guard. They turned out to be framed
 * correctly, but by luck rather than by anything checked. Keying on the STATUS LINE instead
 * covers every writer that exists, and every writer anyone adds later.
 *
 * <p>Scans the source as DATA rather than exercising the methods, because these writers take
 * an {@code OutputStream} and build headers as string literals — the property under test is
 * what the file emits. {@code app/build.gradle.kts} declares {@code src/main/java} as an
 * explicit test input, so this re-runs when those files change; without that the task would
 * stay UP-TO-DATE and the guard would silently stop running.
 */
public class ResponseFramingTest {

    /** A literal HTTP status line being written, e.g. {@code "HTTP/1.1 200 OK\r\n"}. */
    private static final Pattern STATUS_LINE = Pattern.compile("\"HTTP/1\\.1 ");

    /**
     * Statuses that carry no body, so there is nothing to frame and a {@code Content-Length}
     * would be wrong rather than merely redundant.
     *
     * <ul>
     *   <li>{@code 304} — a conditional hit. {@code Content-Length: 0} would assert the
     *       cached resource is empty; RFC 7230 permits only echoing what the 200 would have
     *       had. See the javadoc on {@code HttpResponse.sendNotModified}.
     *   <li>{@code 101} — the WebSocket upgrade. The socket stops being HTTP at that point
     *       and is handed to the stream pool, so framing does not apply.
     *   <li>{@code 204} — no content, by definition.
     * </ul>
     */
    private static final String[] BODILESS_STATUSES = {"304", "101", "204"};

    /** How many lines after the status line the header block is still being built. */
    private static final int HEADER_WINDOW_LINES = 14;

    /**
     * Blank out comments before scanning, keeping line numbers intact.
     *
     * <p>Without this the guard reports javadoc and trailing comments as violations —
     * {@code ConnectHandlerUtil.parseHttpStatus} carries {@code // e.g. "HTTP/1.1 404 Not
     * Found"} beside code that PARSES a status line, and this class's own javadoc quotes
     * the headers it describes. Both were reported as offenders on the first run. A guard
     * that cries wolf gets deleted, so it has to read code only.
     */
    static String stripComments(String src) {
        StringBuilder out = new StringBuilder(src.length());
        boolean inLine = false, inBlock = false, inStr = false, inChar = false, esc = false;
        for (int i = 0; i < src.length(); i++) {
            char c = src.charAt(i);
            char n = i + 1 < src.length() ? src.charAt(i + 1) : '\0';
            if (c == '\n') {
                inLine = false; inStr = false; esc = false;
                out.append(c);
                continue;
            }
            if (inLine || inBlock) {
                if (inBlock && c == '*' && n == '/') { inBlock = false; i++; out.append("  "); }
                else out.append(' ');
                continue;
            }
            if (inStr || inChar) {
                out.append(c);
                if (esc) esc = false;
                else if (c == '\\') esc = true;
                else if (inStr && c == '"') inStr = false;
                else if (inChar && c == '\'') inChar = false;
                continue;
            }
            if (c == '/' && n == '/') { inLine = true; out.append(' '); continue; }
            if (c == '/' && n == '*') { inBlock = true; out.append(' '); continue; }
            if (c == '"') { inStr = true; out.append(c); continue; }
            if (c == '\'') { inChar = true; out.append(c); continue; }
            out.append(c);
        }
        return out.toString();
    }

    private static File sourceRoot() {
        File f = new File("src/main/java/com/loabletech/bladewatch");
        if (!f.isDirectory()) f = new File("app/src/main/java/com/loabletech/bladewatch");
        Assert.assertTrue("could not locate the source tree from "
                + new File(".").getAbsolutePath(), f.isDirectory());
        return f;
    }

    /**
     * Every source file under the tree, in either language, so a NEW response writer is covered
     * too. Kotlin is included deliberately: the server layer is migrating (BladeWatch-9rut), and
     * a .java-only walk would quietly stop seeing writers as they convert. The scan below reads
     * CONCATENATED string literals, so a converted writer must keep building its header block
     * that way rather than switching to a Kotlin string template -- a "$status" interpolation
     * would not match, and this guard is the only thing between a missing Content-Length and a
     * desynchronised keep-alive connection.
     */
    private static List<File> allJavaSources() {
        List<File> out = new ArrayList<>();
        java.util.Deque<File> stack = new java.util.ArrayDeque<>();
        stack.push(sourceRoot());
        while (!stack.isEmpty()) {
            File[] kids = stack.pop().listFiles();
            if (kids == null) continue;
            for (File k : kids) {
                if (k.isDirectory()) stack.push(k);
                else if (k.getName().endsWith(".java") || k.getName().endsWith(".kt")) out.add(k);
            }
        }
        return out;
    }

    @Test
    public void everyResponseFramesItsBody() throws Exception {
        List<String> offenders = new ArrayList<>();
        int statusLinesSeen = 0;

        for (File f : allJavaSources()) {
            String src = stripComments(
                    new String(Files.readAllBytes(f.toPath()), StandardCharsets.UTF_8));
            if (!src.contains("\"HTTP/1.1 ")) continue;

            String relative = f.getPath().replace(File.separatorChar, '/');
            int cut = relative.indexOf("/bladewatch/");
            if (cut >= 0) relative = relative.substring(cut + "/bladewatch/".length());

            String[] lines = src.split("\n", -1);
            for (int i = 0; i < lines.length; i++) {
                Matcher m = STATUS_LINE.matcher(lines[i]);
                if (!m.find()) continue;
                statusLinesSeen++;

                // Headers are appended in the lines FOLLOWING the status line, whatever the
                // shape — concatenated literal, StringBuilder chain, or append() calls.
                StringBuilder block = new StringBuilder();
                for (int j = i; j < Math.min(lines.length, i + HEADER_WINDOW_LINES); j++) {
                    block.append(lines[j]).append('\n');
                }
                String window = block.toString();

                boolean bodiless = false;
                for (String status : BODILESS_STATUSES) {
                    if (lines[i].contains("\"HTTP/1.1 " + status)
                            || window.contains("HTTP/1.1 \" + " + status)) {
                        bodiless = true;
                        break;
                    }
                }
                if (bodiless) continue;
                if (window.contains("Content-Length")) continue;
                if (window.contains("Transfer-Encoding")) continue;

                offenders.add(relative + ":" + (i + 1));
            }
        }

        // A scan that matches nothing would pass vacuously. Pin that the writers are still
        // being found, so a refactor that moves or renames them fails loudly here.
        Assert.assertTrue(
                "No HTTP status line was found anywhere in the source tree. The response "
                        + "writers have moved or changed shape — fix this guard rather than "
                        + "deleting it; it is the only thing standing between a missing "
                        + "Content-Length and silent stream corruption under keep-alive.",
                statusLinesSeen >= 10);

        Assert.assertTrue(
                "These responses declare no body length. Under keep-alive (BladeWatch-67h8) "
                        + "the client cannot find the end of the body, so the connection "
                        + "desynchronises and every later response on it is corrupt. Give "
                        + "each an accurate Content-Length, or chunked encoding, or add its "
                        + "status to BODILESS_STATUSES if it genuinely has no body: "
                        + offenders,
                offenders.isEmpty());
    }

    /**
     * The 304 path is the deliberate exception, and "fixing" it is the likely mistake once
     * someone is adding Content-Length everywhere else. Pin that it stays bodiless.
     */
    @Test
    public void notModifiedStaysBodiless() throws Exception {
        String src = new String(Files.readAllBytes(source("server/HttpResponse").toPath()),
                StandardCharsets.UTF_8);

        int at = src.indexOf("sendNotModified");
        Assert.assertTrue("sendNotModified is gone — was the 304 path removed?", at > 0);
        int end = src.indexOf("\n    }", at);
        Assert.assertTrue("could not find the end of sendNotModified", end > at);
        String body = src.substring(at, end);

        Assert.assertFalse(
                "A 304 must not carry Content-Length: it never has a body, so there is "
                        + "nothing to frame, and a 0 would claim the cached resource is "
                        + "empty. See the javadoc on sendNotModified.",
                body.contains("Content-Length"));
    }

    /**
     * A response written immediately before an unconditional close must ANNOUNCE that close.
     *
     * <p>This is the bug that actually shipped and had to be caught on the car. Three paths
     * wrote a normal 200 and then closed, so the server sent {@code Connection: keep-alive}
     * and hung up; over Tor the client's next request got an empty status line. Loopback
     * never saw it, because {@code /status} loops correctly and {@code /login.html} did not.
     *
     * <p>A later review found two more of the same shape — the 400 for a malformed request
     * line (which fires BEFORE the keep-alive decision, so on a reused connection it
     * inherited the PREVIOUS request's "keep-alive") and the 403 for a missing vehicle
     * action token. Finding the same class of defect twice by hand is the reason it is
     * pinned here.
     *
     * <p>The rule: inside {@code handleClient}, any {@code client.close()} preceded by a
     * response write must have {@code setKeepAlive(false)} in the same run of lines.
     */
    @Test
    public void closingPathsDoNotAdvertiseKeepAlive() throws Exception {
        String[] lines = stripComments(
                new String(Files.readAllBytes(source("server/HttpServer").toPath()),
                        StandardCharsets.UTF_8)).split("\n", -1);

        int start = -1, end = -1;
        for (int i = 0; i < lines.length; i++) {
            // Both spellings: Java declares "private void handleClient", Kotlin
            // "private fun handleClient". Matching one would silently stop finding the method.
            if (start < 0 && (lines[i].contains("private void handleClient")
                    || lines[i].contains("private fun handleClient"))) start = i;
            else if (start >= 0 && lines[i].equals("    }")) { end = i; break; }
        }
        Assert.assertTrue("could not locate handleClient", start >= 0 && end > start);

        String[] writes = {"send", "serveStaticFile", "AuthApiHandler.handle", "checkAuth"};
        List<String> offenders = new ArrayList<>();
        for (int i = start; i < end; i++) {
            if (!lines[i].contains("client.close()")) continue;
            StringBuilder ctx = new StringBuilder();
            for (int j = Math.max(start, i - 7); j < i; j++) ctx.append(lines[j]).append('\n');
            String before = ctx.toString();
            boolean wrote = false;
            for (String w : writes) if (before.contains(w)) { wrote = true; break; }
            // Both spellings: Java calls out.setKeepAlive(false), Kotlin assigns
            // out.isKeepAlive = false. Matching only the Java form would let every closing path
            // pass vacuously once this file converts (BladeWatch-9rut).
            boolean announcedClose = before.contains("setKeepAlive(false)")
                    || before.replace(" ", "").contains("isKeepAlive=false");
            if (wrote && !announcedClose) {
                offenders.add("HttpServer:" + (i + 1));
            }
        }

        Assert.assertTrue(
                "These paths write a response and then close the connection, but do not call "
                        + "out.setKeepAlive(false) first — so the response advertises "
                        + "Connection: keep-alive and the server then hangs up. A client that "
                        + "believes the header sends its next request into a dead socket: "
                        + offenders,
                offenders.isEmpty());
    }

    /**
     * Keep-alive is only safe because every writer routes its {@code Connection:} header
     * through one place that knows the per-request decision. A writer that hardcodes the
     * header again would either pin a connection closed (losing the benefit) or, worse,
     * promise to keep one open that the server is about to drop.
     */
    @Test
    public void noWriterHardcodesTheConnectionHeader() throws Exception {
        List<String> offenders = new ArrayList<>();
        for (File f : allJavaSources()) {
            String src = stripComments(
                    new String(Files.readAllBytes(f.toPath()), StandardCharsets.UTF_8));
            // The single permitted definition lives in HttpResponse.connectionHeader.
            if (f.getName().equals("HttpResponse.java")
                    || f.getName().equals("HttpResponse.kt")) continue;
            // The 101 upgrade legitimately sends "Connection: Upgrade".
            String withoutUpgrade = src.replace("Connection: Upgrade", "");
            if (withoutUpgrade.contains("\"Connection: ")
                    || withoutUpgrade.contains("Connection: close")) {
                offenders.add(f.getName());
            }
        }
        Assert.assertTrue(
                "These files hardcode a Connection header instead of calling "
                        + "HttpResponse.connectionHeader(out), which is what carries the "
                        + "per-request keep-alive decision: " + offenders,
                offenders.isEmpty());
    }

    /**
     * Resolve a source file by path without its extension. The server layer is migrating from
     * Java to Kotlin (BladeWatch-9rut); a guard that keeps asking for a ".java" that no longer
     * exists stops guarding without ever failing.
     */
    private static File source(String relativeNoExtension) {
        File java = new File(sourceRoot(), relativeNoExtension + ".java");
        File kotlin = new File(sourceRoot(), relativeNoExtension + ".kt");
        Assert.assertTrue("missing " + relativeNoExtension + " (.java or .kt)",
                java.isFile() || kotlin.isFile());
        Assert.assertFalse("both a .java and a .kt exist for " + relativeNoExtension
                + " -- a half-finished conversion; this guard would read the stale copy",
                java.isFile() && kotlin.isFile());
        return java.isFile() ? java : kotlin;
    }

}
