package net.bladewatch.app.server;

import org.json.JSONObject;
import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

import java.io.File;
import java.io.FileWriter;
import java.io.Writer;

/**
 * BladeWatch-m1po: the "tunnelStatus" IPC command — the current Zrok tunnel URL,
 * read from zrok's own log by the daemon (which already runs as shell UID, the same
 * UID zrok was launched under, so no ADB and no shell exec is involved).
 */
public class TunnelStatusCommandTest {

    @Rule
    public TemporaryFolder tmp = new TemporaryFolder();

    private TcpCommandServer server;

    @Before
    public void setUp() {
        server = new TcpCommandServer(19876);
    }

    @After
    public void tearDown() {
        TcpCommandServer.zrokLogPathForTest = null;
        TcpCommandServer.procRootForTest = null;
    }

    /** An empty fake /proc — i.e. no zrok process anywhere (BladeWatch-xzhv seam). */
    private void noProcessesRunning() throws Exception {
        TcpCommandServer.procRootForTest = tmp.newFolder("proc-empty");
    }

    /** A fake /proc containing a real-shaped live zrok, exec'd by path as zrok is. */
    private void zrokRunning() throws Exception {
        File procRoot = tmp.newFolder("proc-zrok");
        File dir = new File(procRoot, "4242");
        Assert.assertTrue(dir.mkdirs());
        try (java.io.FileOutputStream out = new java.io.FileOutputStream(new File(dir, "cmdline"))) {
            for (String arg : new String[] {"/data/local/tmp/zrok", "share", "reserved", "tok"}) {
                out.write(arg.getBytes(java.nio.charset.StandardCharsets.UTF_8));
                out.write(0);
            }
        }
        TcpCommandServer.procRootForTest = procRoot;
    }

    private void writeLog(String contents) throws Exception {
        File log = tmp.newFile("zrok.log");
        try (Writer w = new FileWriter(log)) {
            w.write(contents);
        }
        TcpCommandServer.zrokLogPathForTest = log.getAbsolutePath();
    }

    // --- readZrokTunnelUrl ---

    @Test
    public void findsTheShareUrlInTheLog() throws Exception {
        writeLog("starting\nshare url: https://bladewatch1a2b3c.share.zrok.io\nlistening\n");

        Assert.assertEquals(
                "https://bladewatch1a2b3c.share.zrok.io", TcpCommandServer.readZrokTunnelUrl());
    }

    @Test
    public void takesTheMostRecentUrlWhenTheLogSpansSeveralLaunches() throws Exception {
        // The log is appended to across launches. Native greps `| head -1` and then has
        // to reconcile the drift afterwards; the last banner is the live tunnel.
        writeLog("boot 1: https://oldnameaaa.share.zrok.io\n"
                + "…\n"
                + "boot 2: https://newnamebbb.share.zrok.io\n");

        Assert.assertEquals("https://newnamebbb.share.zrok.io", TcpCommandServer.readZrokTunnelUrl());
    }

    @Test
    public void returnsNullWhenTheLogHasNoUrl() throws Exception {
        writeLog("zrok starting\nno share yet\n");

        Assert.assertNull(TcpCommandServer.readZrokTunnelUrl());
    }

    @Test
    public void returnsNullWhenTheLogDoesNotExist() {
        TcpCommandServer.zrokLogPathForTest = new File(tmp.getRoot(), "nope.log").getAbsolutePath();

        Assert.assertNull(TcpCommandServer.readZrokTunnelUrl());
    }

    @Test
    public void returnsNullForAnEmptyLogRatherThanThrowing() throws Exception {
        writeLog("");

        Assert.assertNull(TcpCommandServer.readZrokTunnelUrl());
    }

    @Test
    public void ignoresAUrlThatIsNotAZrokShareHost() throws Exception {
        // The Dashboard turns whatever comes back into a tappable remote-access link,
        // so a stray URL in the log must not be mistaken for the tunnel.
        writeLog("fetching https://example.com/update.json\nno share\n");

        Assert.assertNull(TcpCommandServer.readZrokTunnelUrl());
    }

    @Test
    public void readsAUrlNearTheEndOfALogLargerThanTheTailWindow() throws Exception {
        StringBuilder sb = new StringBuilder();
        // Comfortably past the 256 KB tail window.
        while (sb.length() < 400 * 1024) {
            sb.append("noise line that is not a url at all\n");
        }
        sb.append("share url: https://tailnameccc.share.zrok.io\n");
        writeLog(sb.toString());

        Assert.assertEquals("https://tailnameccc.share.zrok.io", TcpCommandServer.readZrokTunnelUrl());
    }

    // --- processCommand("tunnelStatus") ---

    @Test
    public void reportsOfflineAndNoUrlWhenTheTunnelProcessIsNotRunning() throws Exception {
        // A URL IS present in the log, so this pins the liveness gate specifically:
        // a stale banner must not be reported as a live tunnel.
        writeLog("share url: https://staleddd.share.zrok.io\n");
        noProcessesRunning();

        JSONObject resp = server.processCommand(new JSONObject().put("cmd", "tunnelStatus"));

        Assert.assertEquals("ok", resp.getString("status"));
        Assert.assertFalse(resp.getBoolean("running"));
        Assert.assertTrue("url must be JSON null, not the stale value", resp.isNull("url"));
    }

    @Test
    public void alwaysReportsBothRunningAndUrlKeys() throws Exception {
        noProcessesRunning();

        JSONObject resp = server.processCommand(new JSONObject().put("cmd", "tunnelStatus"));

        // The client distinguishes offline / connecting / online from these two, so
        // neither may be absent.
        Assert.assertTrue(resp.has("running"));
        Assert.assertTrue(resp.has("url"));
    }

    @Test
    public void reportsTheUrlWhenTheTunnelProcessIsGenuinelyRunning() throws Exception {
        writeLog("boot 1: https://oldnameaaa.share.zrok.io\nboot 2: https://livenamebbb.share.zrok.io\n");
        zrokRunning();

        JSONObject resp = server.processCommand(new JSONObject().put("cmd", "tunnelStatus"));

        Assert.assertTrue(resp.getBoolean("running"));
        Assert.assertEquals("https://livenamebbb.share.zrok.io", resp.getString("url"));
    }

    @Test
    public void reportsRunningWithNoUrlWhenTheTunnelHasNotPublishedOneYet() throws Exception {
        writeLog("zrok starting up\n");
        zrokRunning();

        JSONObject resp = server.processCommand(new JSONObject().put("cmd", "tunnelStatus"));

        Assert.assertTrue(resp.getBoolean("running"));
        Assert.assertTrue(resp.isNull("url"));
    }
}
