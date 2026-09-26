package net.bladewatch.app.server;

import java.lang.reflect.Field;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import org.junit.Assert;
import org.junit.Test;

/**
 * BladeWatch-sxzg: a remote viewer must not be able to starve the in-car UI.
 *
 * <p><b>The observed failure.</b> The owner reported that the in-car Flutter UI became
 * unresponsive whenever remote access was on, and recovered the instant it was switched
 * off. Measured on the head unit 2026-09-15, it was neither a render loop nor a CPU
 * shortage:
 *
 * <pre>
 *   dumpsys gfxinfo net.bladewatch.flutter
 *     Total frames rendered: 257 ... 257 again 10 s later   -> nothing was repainting
 *     Janky frames: 114 (44%)   99th percentile: 600 ms
 *   head unit: 497% of 800% idle
 * </pre>
 *
 * <p>Zero frames over ten seconds rules out an animation; frames arriving 600 ms late on an
 * idle machine is the signature of a thread BLOCKED WAITING. The in-car UI speaks ConnectRPC
 * to {@code 127.0.0.1:8080} — the very server remote clients reach — so it shares one
 * fixed pool with every remote client.
 *
 * <p><b>The specific hazard this test pins.</b> {@code streamH264ToWebSocket} sets
 * {@code setSoTimeout(0)} and then blocks for the WHOLE viewing session. Run on a request
 * thread, each viewer permanently removes one worker from the pool that the in-car UI's RPCs
 * also queue on. Ordinary requests are bounded by their 15 s timeout; a stream is bounded by
 * nothing.
 *
 * <p>Asserted against the source rather than by standing up a server and a camera, because
 * the property that matters — "streaming does not execute on the request pool" — is
 * structural, and the alternative needs a GPU pipeline this JVM does not have.
 */
public class HttpServerPoolIsolationTest {

    /**
     * HttpServer's source, in whichever language it is written in today. The server layer is
     * migrating from Java to Kotlin (BladeWatch-9rut); a guard that keeps asking for a ".java"
     * that no longer exists stops guarding without ever failing.
     */
    private static String source() throws Exception {
        Path java = locate("HttpServer.java");
        Path kotlin = locate("HttpServer.kt");
        Assert.assertTrue("could not locate HttpServer (.java or .kt)",
                java != null || kotlin != null);
        Assert.assertFalse("both HttpServer.java and HttpServer.kt exist -- a half-finished "
                + "conversion; this guard would read the stale copy", java != null && kotlin != null);
        return new String(Files.readAllBytes(java != null ? java : kotlin),
                StandardCharsets.UTF_8);
    }

    private static Path locate(String filename) {
        Path p = Path.of("src/main/java/com/loabletech/bladewatch/server/" + filename);
        if (Files.isRegularFile(p)) return p;
        p = Path.of("app/src/main/java/com/loabletech/bladewatch/server/" + filename);
        return Files.isRegularFile(p) ? p : null;
    }

    @Test
    public void streamingHasItsOwnExecutorSeparateFromRequestHandling() throws Exception {
        String src = source();

        Assert.assertTrue(
                "There must be a dedicated executor for long-lived streams. Sharing the "
                        + "request pool lets each viewer hold a worker for their whole "
                        + "session, and the in-car UI queues behind them.",
                src.contains("streamPool"));
        Assert.assertTrue(
                "the WebSocket stream must be dispatched onto it, not run inline on the "
                        + "request thread",
                src.contains("streamPool.execute") || src.contains("streamPool.submit"));
    }

    /**
     * The request pool is what the in-car UI's RPCs land on. It must stay a bounded pool
     * whose workers are freed by the existing 15 s socket timeout.
     */
    @Test
    public void requestPoolStillExistsAndIsBounded() throws Exception {
        String src = source();

        Assert.assertTrue("the request pool must still exist",
                src.contains("newFixedThreadPool"));
        Assert.assertTrue(
                "requests must still be dispatched to the request pool",
                src.contains("threadPool.execute"));
    }

    /**
     * Both pools have to be shut down, or a daemon restart leaks non-daemon threads and the
     * process never exits.
     */
    @Test
    public void bothPoolsAreShutDown() throws Exception {
        String src = source();
        int idx = src.indexOf("streamPool.shutdown");
        Assert.assertTrue("streamPool must be shut down alongside threadPool", idx > 0);
    }

    /** The field must actually be there at runtime, not just in a comment. */
    @Test
    public void streamPoolFieldIsReal() throws Exception {
        Field f = HttpServer.class.getDeclaredField("streamPool");
        Assert.assertNotNull(f);
    }

    /**
     * The trap this nearly shipped with.
     *
     * <p>{@code handleClient} ends in {@code finally { client.close(); }}. Handing the socket
     * to the streaming pool and returning would therefore close it immediately — killing
     * every live view the instant it started, while the pool-isolation tests above still
     * passed. Ownership has to be tracked explicitly.
     */
    @Test
    public void handingOffTheSocketSuppressesTheFinallyClose() throws Exception {
        String src = source();

        Assert.assertTrue(
                "handleClient must track that the socket's ownership moved to the stream",
                src.contains("socketHandedOff"));
        Assert.assertTrue(
                "the finally-close must be conditional, or the stream's socket is closed "
                        + "out from under it",
                src.contains("if (!socketHandedOff)"));
    }

    /**
     * The upgrade reports whether ownership actually transferred: a FAILED handshake never
     * reaches the stream, so that socket is still the caller's to close. Returning a blanket
     * true would leak a socket per failed upgrade.
     */
    @Test
    public void aFailedUpgradeDoesNotClaimOwnership() throws Exception {
        String src = source();
        // Both spellings: Java declares "private boolean handleWebSocketUpgrade", Kotlin
        // "private fun handleWebSocketUpgrade(...): Boolean". Matching one would silently stop
        // finding the method (BladeWatch-9rut).
        int sig = src.indexOf("private boolean handleWebSocketUpgrade");
        if (sig < 0) sig = src.indexOf("private fun handleWebSocketUpgrade");
        Assert.assertTrue("handleWebSocketUpgrade must report ownership transfer", sig > 0);

        String body = src.substring(sig, Math.min(src.length(), sig + 2500));
        Assert.assertTrue("must claim ownership on the success path", body.contains("return true"));
        Assert.assertTrue("must NOT claim ownership when the handshake fails",
                body.contains("return false"));
    }
}
