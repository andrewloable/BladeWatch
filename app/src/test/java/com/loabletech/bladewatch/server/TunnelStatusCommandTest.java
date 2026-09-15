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
 * BladeWatch-3lbz.2: the "tunnelStatus" IPC command, now backed by a Tor onion service.
 *
 * <p>The daemon reads tor's own files directly — it already runs as shell UID, the same UID tor
 * is launched under, and both live in {@code /data/local/tmp} — so no ADB and no shell exec is
 * involved.
 *
 * <p><b>The behaviour that changed, and the reason most of these tests exist.</b>
 * The previous tunnel only printed its URL once it was live, so "a URL exists" meant "reachable".
 * Tor is the opposite: it writes {@code hs/hostname} within about a second of the FIRST launch and
 * then keeps it forever, including across reboots, long before the network is up. Measured on the
 * head unit on 2026-09-14, a cold start takes ~82 s to reach "Bootstrapped 100%" (a warm restart
 * ~6 s). Reporting the hostname as soon as it exists would put an online QR code on the Dashboard
 * pointing at a service that is unreachable for the next minute and a half.
 *
 * <p>So the gate is the BOOTSTRAP STATE in {@code tor.log}, not the presence of the hostname file.
 */
public class TunnelStatusCommandTest {

    /** A syntactically valid v3 onion address: 56 chars of base32, no 0/1/8/9. */
    private static final String ONION =
            "abcdefghijklmnopqrstuvwxyz234567abcdefghijklmnopqrstuvwx.onion";

    @Rule
    public TemporaryFolder tmp = new TemporaryFolder();

    private TcpCommandServer server;

    @Before
    public void setUp() {
        server = new TcpCommandServer(19876);
    }

    @After
    public void tearDown() {
        TcpCommandServer.torLogPathForTest = null;
        TcpCommandServer.torHostnamePathForTest = null;
        TcpCommandServer.procRootForTest = null;
        TcpCommandServer.daemonEnabledReadsForTest = null;
    }

    /** An empty fake /proc — i.e. no tor process anywhere (BladeWatch-xzhv seam). */
    private void noProcessesRunning() throws Exception {
        TcpCommandServer.procRootForTest = tmp.newFolder("proc-empty");
    }

    /** A fake /proc containing a real-shaped live tor, exec'd by path as tor is. */
    private void torRunning() throws Exception {
        File procRoot = tmp.newFolder("proc-tor");
        File dir = new File(procRoot, "4242");
        Assert.assertTrue(dir.mkdirs());
        try (java.io.FileOutputStream out = new java.io.FileOutputStream(new File(dir, "cmdline"))) {
            for (String arg : new String[] {
                    "/data/local/tmp/bladewatch_tor", "-f", "/data/local/tmp/tor/torrc"}) {
                out.write(arg.getBytes(java.nio.charset.StandardCharsets.UTF_8));
                out.write(0);
            }
        }
        TcpCommandServer.procRootForTest = procRoot;
    }

    private void writeLog(String contents) throws Exception {
        File log = tmp.newFile("tor.log");
        try (Writer w = new FileWriter(log)) {
            w.write(contents);
        }
        TcpCommandServer.torLogPathForTest = log.getAbsolutePath();
    }

    private void writeHostname(String contents) throws Exception {
        File hn = tmp.newFile("hostname");
        try (Writer w = new FileWriter(hn)) {
            w.write(contents);
        }
        TcpCommandServer.torHostnamePathForTest = hn.getAbsolutePath();
    }

    /** A log that has reached 100% on its current run. */
    private void bootstrapped() throws Exception {
        writeLog("Sep 14 22:17:07.000 [notice] Bootstrapped 0% (starting): Starting\n"
                + "Sep 14 22:17:11.000 [notice] Bootstrapped 75% (enough_dirinfo)\n"
                + "Sep 14 22:17:13.000 [notice] Bootstrapped 100% (done): Done\n");
    }

    // --- readTorOnionUrl ---

    @Test
    public void readsTheOnionAddressFromTheHiddenServiceHostnameFile() throws Exception {
        writeHostname(ONION + "\n");

        Assert.assertEquals("http://" + ONION, TcpCommandServer.readTorOnionUrl());
    }

    @Test
    public void returnsNullWhenTheHostnameFileDoesNotExist() {
        TcpCommandServer.torHostnamePathForTest = new File(tmp.getRoot(), "nope").getAbsolutePath();

        Assert.assertNull(TcpCommandServer.readTorOnionUrl());
    }

    @Test
    public void returnsNullForAnEmptyHostnameFileRatherThanThrowing() throws Exception {
        writeHostname("");

        Assert.assertNull(TcpCommandServer.readTorOnionUrl());
    }

    @Test
    public void rejectsAHostnameFileThatIsNotAV3OnionAddress() throws Exception {
        // The Dashboard turns whatever comes back into a QR code, so a truncated or
        // half-written file must not become a link that silently goes nowhere.
        writeHostname("not-an-onion-address\n");

        Assert.assertNull(TcpCommandServer.readTorOnionUrl());
    }

    // --- isTorBootstrapped ---

    @Test
    public void isNotBootstrappedWhileTheLogHasNotReachedOneHundredPercent() throws Exception {
        writeLog("Bootstrapped 0% (starting): Starting\n"
                + "Bootstrapped 45% (requesting_descriptors)\n");

        Assert.assertFalse(TcpCommandServer.isTorBootstrapped());
    }

    @Test
    public void isBootstrappedOnceTheLogReachesOneHundredPercent() throws Exception {
        bootstrapped();

        Assert.assertTrue(TcpCommandServer.isTorBootstrapped());
    }

    @Test
    public void aStaleHundredPercentFromAnEarlierRunDoesNotCountAsBootstrapped() throws Exception {
        // tor appends to the same log across launches. After a restart the previous
        // run's success line is still in the file, sitting above the new run's
        // "Bootstrapped 0%". Reading it as live would republish the URL during the
        // window when the service is not actually reachable.
        writeLog("Sep 14 22:12:17.000 [notice] Bootstrapped 100% (done): Done\n"
                + "Sep 14 22:16:50.000 [notice] Catching signal TERM, exiting cleanly.\n"
                + "Sep 14 22:17:07.000 [notice] Bootstrapped 0% (starting): Starting\n"
                + "Sep 14 22:17:10.000 [notice] Bootstrapped 10% (conn_done)\n");

        Assert.assertFalse(TcpCommandServer.isTorBootstrapped());
    }

    @Test
    public void countsTheSecondRunOnceItReachesOneHundredPercentAgain() throws Exception {
        writeLog("Bootstrapped 100% (done): Done\n"
                + "Catching signal TERM, exiting cleanly.\n"
                + "Bootstrapped 0% (starting): Starting\n"
                + "Bootstrapped 100% (done): Done\n");

        Assert.assertTrue(TcpCommandServer.isTorBootstrapped());
    }

    @Test
    public void isNotBootstrappedWhenTheLogDoesNotExist() {
        TcpCommandServer.torLogPathForTest = new File(tmp.getRoot(), "nope.log").getAbsolutePath();

        Assert.assertFalse(TcpCommandServer.isTorBootstrapped());
    }

    @Test
    public void readsBootstrapStateNearTheEndOfALogLargerThanTheTailWindow() throws Exception {
        // Never load the whole log into memory: the implementation this replaces
        // documented 85 MB+ allocations from doing exactly that.
        StringBuilder sb = new StringBuilder();
        while (sb.length() < 400 * 1024) {
            sb.append("Sep 14 22:00:00.000 [notice] noise line that says nothing at all\n");
        }
        sb.append("Sep 14 22:17:13.000 [notice] Bootstrapped 100% (done): Done\n");
        writeLog(sb.toString());

        Assert.assertTrue(TcpCommandServer.isTorBootstrapped());
    }

    // --- processCommand("tunnelStatus") ---

    @Test
    public void reportsOfflineAndNoUrlWhenTheTunnelProcessIsNotRunning() throws Exception {
        // The hostname file and a bootstrapped log BOTH exist, so this pins the liveness
        // gate specifically: tor's hostname file survives forever once written, and must
        // never be reported as a live tunnel on its own.
        writeHostname(ONION + "\n");
        bootstrapped();
        noProcessesRunning();

        JSONObject resp = server.processCommand(new JSONObject().put("cmd", "tunnelStatus"));

        Assert.assertEquals("ok", resp.getString("status"));
        Assert.assertFalse(resp.getBoolean("running"));
        Assert.assertTrue("url must be JSON null, not the persisted address", resp.isNull("url"));
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
    public void reportsTheOnionUrlWhenTorIsRunningAndBootstrapped() throws Exception {
        writeHostname(ONION + "\n");
        bootstrapped();
        torRunning();

        JSONObject resp = server.processCommand(new JSONObject().put("cmd", "tunnelStatus"));

        Assert.assertTrue(resp.getBoolean("running"));
        Assert.assertEquals("http://" + ONION, resp.getString("url"));
    }

    @Test
    public void reportsRunningWithNoUrlWhileTorIsStillBootstrapping() throws Exception {
        // THE headline case. The hostname file already exists — tor writes it about a
        // second after first launch — but the network is not up for ~82 s on a cold
        // start. The client renders this as "connecting", not "online".
        writeHostname(ONION + "\n");
        writeLog("Bootstrapped 0% (starting): Starting\n"
                + "Bootstrapped 45% (requesting_descriptors)\n");
        torRunning();

        JSONObject resp = server.processCommand(new JSONObject().put("cmd", "tunnelStatus"));

        Assert.assertTrue(resp.getBoolean("running"));
        Assert.assertTrue("a bootstrapping tunnel must not publish its address",
                resp.isNull("url"));
    }

    @Test
    public void reportsRunningWithNoUrlWhenBootstrappedButTheHostnameIsMissing() throws Exception {
        // Should not happen in practice, but it must degrade to "connecting" rather
        // than throwing and taking the IPC command down with it.
        bootstrapped();
        torRunning();
        TcpCommandServer.torHostnamePathForTest = new File(tmp.getRoot(), "gone").getAbsolutePath();

        JSONObject resp = server.processCommand(new JSONObject().put("cmd", "tunnelStatus"));

        Assert.assertTrue(resp.getBoolean("running"));
        Assert.assertTrue(resp.isNull("url"));
    }

    // --- BladeWatch-y7x2: the enabled intent, for hiding the Dashboard connect card ---

    /**
     * The Dashboard hides its connect card entirely when the owner has switched the tunnel
     * off. That needs "the user asked for no tunnel", which is NOT the same as "no tunnel is
     * running" — an enabled tunnel is also not running for the first minute while tor
     * bootstraps, and hiding the card during that window would make the Dashboard look
     * broken exactly while the user waits for it.
     */
    @Test
    public void reportsTheEnabledIntentAlongsideLiveness() throws Exception {
        TcpCommandServer.daemonEnabledReadsForTest = new java.util.HashMap<>();
        TcpCommandServer.daemonEnabledReadsForTest.put("TOR_TUNNEL", true);
        noProcessesRunning();

        JSONObject resp = server.processCommand(new JSONObject().put("cmd", "tunnelStatus"));

        Assert.assertFalse("not up yet", resp.getBoolean("running"));
        Assert.assertTrue("but the owner has asked for it", resp.getBoolean("enabled"));
    }

    @Test
    public void reportsNotEnabledWhenTheOwnerHasSwitchedTheTunnelOff() throws Exception {
        TcpCommandServer.daemonEnabledReadsForTest = new java.util.HashMap<>();
        TcpCommandServer.daemonEnabledReadsForTest.put("TOR_TUNNEL", false);
        noProcessesRunning();

        JSONObject resp = server.processCommand(new JSONObject().put("cmd", "tunnelStatus"));

        Assert.assertFalse(resp.getBoolean("enabled"));
    }

    @Test
    public void alwaysReportsTheEnabledKey() throws Exception {
        noProcessesRunning();

        JSONObject resp = server.processCommand(new JSONObject().put("cmd", "tunnelStatus"));

        Assert.assertTrue("the client branches on this; it may not be absent",
                resp.has("enabled"));
    }
}
