package net.bladewatch.app.server;

import org.json.JSONObject;
import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

import java.io.File;
import java.io.FileOutputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;

/**
 * BladeWatch-abcx: the "daemon_set_enabled" IPC command.
 *
 * <p>What is pinned here is the ALLOW-LIST and the kill decision — the parts with
 * consequences. The config write itself lands in {@code UnifiedConfigManager}, which
 * touches a real file under {@code /storage/emulated/0} and logs through
 * {@code android.util.Log}; neither exists in a JVM unit test, so that half is exercised
 * on device instead.
 */
public class DaemonSetEnabledCommandTest {

    @Rule
    public TemporaryFolder tmp = new TemporaryFolder();

    private TcpCommandServer server;

    @Before
    public void setUp() throws Exception {
        server = new TcpCommandServer(19876);
        TcpCommandServer.procRootForTest = tmp.newFolder("proc");
        TcpCommandServer.killedPidsForTest = new ArrayList<>();
        TcpCommandServer.daemonEnabledWritesForTest = new java.util.LinkedHashMap<>();
    }

    @After
    public void tearDown() {
        TcpCommandServer.procRootForTest = null;
        TcpCommandServer.killedPidsForTest = null;
        TcpCommandServer.daemonEnabledWritesForTest = null;
    }

    private void fakeProcess(int pid, String... argv) throws Exception {
        File dir = new File(TcpCommandServer.procRootForTest, String.valueOf(pid));
        Assert.assertTrue(dir.mkdirs());
        try (FileOutputStream out = new FileOutputStream(new File(dir, "cmdline"))) {
            for (String arg : argv) {
                out.write(arg.getBytes(StandardCharsets.UTF_8));
                out.write(0);
            }
        }
    }

    private JSONObject setEnabled(String type, boolean enabled) throws Exception {
        return server.processCommand(new JSONObject()
                .put("cmd", "daemon_set_enabled").put("type", type).put("enabled", enabled));
    }

    // --- the allow-list is the security boundary ---

    @Test
    public void refusesToStopTheCameraDaemonThatHostsThisServer() throws Exception {
        // Stopping it would kill the socket answering this very request, and the Flutter
        // APK has no ADB to start it again.
        fakeProcess(101, "byd_cam_daemon");

        JSONObject resp = setEnabled("CAMERA_DAEMON", false);

        Assert.assertEquals("error", resp.getString("status"));
        Assert.assertTrue("nothing may be killed for a refused type",
                TcpCommandServer.killedPidsForTest.isEmpty());
        Assert.assertTrue("nothing may be recorded for a refused type",
                TcpCommandServer.daemonEnabledWritesForTest.isEmpty());
    }

    @Test
    public void refusesTheCoreSurveillanceDaemons() throws Exception {
        // Their stop cannot stick — DaemonStartupManager relaunches every CORE daemon
        // within 30s from an app-process-only set this process cannot reach.
        for (String type : new String[] {"SENTRY_DAEMON", "ACC_SENTRY_DAEMON"}) {
            Assert.assertEquals("error", setEnabled(type, false).getString("status"));
        }
        Assert.assertTrue(TcpCommandServer.killedPidsForTest.isEmpty());
    }

    @Test
    public void refusesAnUnknownOrEmptyType() throws Exception {
        for (String type : new String[] {"", "NOT_A_DAEMON", "tor", "tor_tunnel", "pear", "pear_peer"}) {
            Assert.assertEquals("type must match the enum exactly: " + type,
                    "error", setEnabled(type, false).getString("status"));
        }
        Assert.assertTrue(TcpCommandServer.killedPidsForTest.isEmpty());
    }

    @Test
    public void refusesATypeWithShellMetacharacters() throws Exception {
        // Nothing from the wire reaches a shell, and the allow-list is why.
        JSONObject resp = setEnabled("TOR_TUNNEL; rm -rf /data", false);

        Assert.assertEquals("error", resp.getString("status"));
        Assert.assertTrue(TcpCommandServer.killedPidsForTest.isEmpty());
    }

    // --- the kill decision ---

    @Test
    public void disablingTheTunnelKillsTheRunningProcess() throws Exception {
        // The health check only ever RELAUNCHES, never kills, so without this the tunnel
        // keeps serving until the next reboot while the switch reads "off".
        fakeProcess(202, "/data/local/tmp/bladewatch_tor", "-f", "/data/local/tmp/tor/torrc");

        JSONObject resp = setEnabled("TOR_TUNNEL", false);

        Assert.assertEquals("ok", resp.getString("status"));
        Assert.assertEquals(java.util.Collections.singletonList(202), TcpCommandServer.killedPidsForTest);
        Assert.assertEquals(Boolean.FALSE, TcpCommandServer.daemonEnabledWritesForTest.get("TOR_TUNNEL"));
    }

    @Test
    public void enablingTheTunnelKillsNothing() throws Exception {
        // Enabling is "record the intent"; DaemonStartupManager's health check does the
        // actual launch through TorLauncher.
        fakeProcess(203, "/data/local/tmp/bladewatch_tor", "-f", "/data/local/tmp/tor/torrc");

        JSONObject resp = setEnabled("TOR_TUNNEL", true);

        Assert.assertEquals("ok", resp.getString("status"));
        Assert.assertTrue(TcpCommandServer.killedPidsForTest.isEmpty());
        // Recording the intent IS the whole of "start": the health check does the launch.
        Assert.assertEquals(Boolean.TRUE, TcpCommandServer.daemonEnabledWritesForTest.get("TOR_TUNNEL"));
    }

    // --- BladeWatch-rdtj.3: the Pear peer is toggleable on the same terms as tor ---

    @Test
    public void disablingThePearPeerKillsOnlyPearDaemon() throws Exception {
        fakeProcess(401, "pear_daemon");
        // The nohup wrapper PearLauncher starts it through. Its command line CONTAINS
        // "pear_daemon", so a substring match would kill it too -- which is the pkill -f bug
        // that kills the ADB shell. Only argv[0] may match.
        fakeProcess(402, "sh", "-c", "CLASSPATH=/data/app/x/base.apk app_process /system/bin "
                + "--nice-name=pear_daemon net.bladewatch.app.daemon.PearDaemon");
        fakeProcess(403, "/data/local/tmp/bladewatch_tor", "-f", "/data/local/tmp/tor/torrc");
        fakeProcess(404, "byd_cam_daemon");

        JSONObject resp = setEnabled("PEAR_PEER", false);

        Assert.assertEquals("ok", resp.getString("status"));
        Assert.assertEquals(java.util.Collections.singletonList(401), TcpCommandServer.killedPidsForTest);
        Assert.assertEquals(Boolean.FALSE, TcpCommandServer.daemonEnabledWritesForTest.get("PEAR_PEER"));
    }

    @Test
    public void enablingThePearPeerRecordsIntentAndKillsNothing() throws Exception {
        fakeProcess(405, "pear_daemon");

        JSONObject resp = setEnabled("PEAR_PEER", true);

        Assert.assertEquals("ok", resp.getString("status"));
        Assert.assertTrue(TcpCommandServer.killedPidsForTest.isEmpty());
        Assert.assertEquals(Boolean.TRUE, TcpCommandServer.daemonEnabledWritesForTest.get("PEAR_PEER"));
    }

    @Test
    public void disablingKillsOnlyTheTunnelAndNotOtherDaemons() throws Exception {
        fakeProcess(301, "/data/local/tmp/bladewatch_tor", "-f", "/data/local/tmp/tor/torrc");
        fakeProcess(302, "byd_cam_daemon");
        fakeProcess(303, "sentry_daemon");
        fakeProcess(304, "sh", "-c", "echo /data/local/tmp/tor.log");

        setEnabled("TOR_TUNNEL", false);

        Assert.assertEquals(java.util.Collections.singletonList(301), TcpCommandServer.killedPidsForTest);
    }

    @Test
    public void disablingWhenNothingIsRunningKillsNothingAndDoesNotFail() throws Exception {
        JSONObject resp = setEnabled("TOR_TUNNEL", false);

        Assert.assertTrue(TcpCommandServer.killedPidsForTest.isEmpty());
        Assert.assertEquals(0, resp.getInt("killed"));
    }
}
