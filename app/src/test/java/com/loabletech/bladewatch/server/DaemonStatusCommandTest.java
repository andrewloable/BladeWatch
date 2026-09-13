package net.bladewatch.app.server;

import org.json.JSONObject;
import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

/**
 * BladeWatch-1xt9: the "daemonStatus" IPC command — process-liveness check for
 * CAMERA_DAEMON/SENTRY_DAEMON/ACC_SENTRY_DAEMON/ZROK_TUNNEL, computed locally via
 * `pgrep -x <processName>` (no ADB — the daemon process already runs as shell UID).
 */
public class DaemonStatusCommandTest {

    private TcpCommandServer server;

    @Before
    public void setUp() {
        server = new TcpCommandServer(19876);
    }

    @After
    public void tearDown() {
        TcpCommandServer.pgrepCommandForTest = null;
    }

    // --- processCommand("daemonStatus") wiring ---

    @Test
    public void reportsOkStatusAndAllFourDaemonKeys() throws Exception {
        JSONObject cmd = new JSONObject();
        cmd.put("cmd", "daemonStatus");
        JSONObject resp = server.processCommand(cmd);

        Assert.assertEquals("ok", resp.getString("status"));
        JSONObject daemons = resp.getJSONObject("daemons");
        Assert.assertTrue(daemons.has("CAMERA_DAEMON"));
        Assert.assertTrue(daemons.has("SENTRY_DAEMON"));
        Assert.assertTrue(daemons.has("ACC_SENTRY_DAEMON"));
        Assert.assertTrue(daemons.has("ZROK_TUNNEL"));
    }

    @Test
    public void noneOfTheRealAndroidDaemonProcessesExistOnTheDevMachine() throws Exception {
        JSONObject cmd = new JSONObject();
        cmd.put("cmd", "daemonStatus");
        JSONObject resp = server.processCommand(cmd);

        JSONObject daemons = resp.getJSONObject("daemons");
        Assert.assertFalse(daemons.getBoolean("CAMERA_DAEMON"));
        Assert.assertFalse(daemons.getBoolean("SENTRY_DAEMON"));
        Assert.assertFalse(daemons.getBoolean("ACC_SENTRY_DAEMON"));
        Assert.assertFalse(daemons.getBoolean("ZROK_TUNNEL"));
    }

    @Test
    public void aFailedProcessCheckResolvesToFalseRatherThanThrowing() throws Exception {
        // Force the pgrep invocation itself to fail (nonexistent binary path)
        // rather than merely "found no match" -- proves the catch branch in
        // isProcessRunning() is reached and still yields a well-formed
        // response instead of propagating an exception through processCommand.
        TcpCommandServer.pgrepCommandForTest = "/nonexistent/path/to/pgrep";

        JSONObject cmd = new JSONObject();
        cmd.put("cmd", "daemonStatus");
        JSONObject resp = server.processCommand(cmd);

        Assert.assertEquals("ok", resp.getString("status"));
        Assert.assertFalse(resp.getJSONObject("daemons").getBoolean("CAMERA_DAEMON"));
    }

    // --- isProcessRunning(String) directly ---

    @Test
    public void isProcessRunningIsTrueForAProcessSpawnedByThisTest() throws Exception {
        // A real, deterministic "is this process alive" check, not a mock:
        // spawn a controlled subprocess with a known command name and pgrep
        // for it while it is still running.
        Process sleeper = new ProcessBuilder("sleep", "5").start();
        try {
            Assert.assertTrue(server.isProcessRunning("sleep"));
        } finally {
            sleeper.destroyForcibly();
        }
    }

    @Test
    public void isProcessRunningIsFalseForANonexistentProcessName() throws Exception {
        Assert.assertFalse(server.isProcessRunning("definitely_nonexistent_process_bladewatch_test"));
    }

    @Test
    public void isProcessRunningIsFalseWhenThePgrepInvocationItselfFails() throws Exception {
        TcpCommandServer.pgrepCommandForTest = "/nonexistent/path/to/pgrep";
        Assert.assertFalse(server.isProcessRunning("anything"));
    }
}
