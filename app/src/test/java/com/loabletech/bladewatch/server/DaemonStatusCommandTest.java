package net.bladewatch.app.server;

import org.json.JSONObject;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Rule;
import org.junit.Test;
import org.junit.rules.TemporaryFolder;

import java.io.File;
import java.io.FileOutputStream;
import java.nio.charset.StandardCharsets;

/**
 * BladeWatch-1xt9: the "daemonStatus" IPC command — process-liveness for
 * CAMERA_DAEMON/SENTRY_DAEMON/ACC_SENTRY_DAEMON/ZROK_TUNNEL, computed locally (no ADB —
 * the daemon process already runs as shell UID, the same UID the daemons run as).
 *
 * <p>BladeWatch-xzhv: liveness is now an argv[0] match read from procfs, not
 * {@code pgrep -f} over whole command lines, so these tests drive a FAKE /proc tree via
 * {@link TcpCommandServer#procRootForTest}. That is what makes the matching rules — the
 * ones that were wrong on the device — testable here at all.
 */
public class DaemonStatusCommandTest {

    @Rule
    public TemporaryFolder tmp = new TemporaryFolder();

    private TcpCommandServer server;
    private File procRoot;

    @Before
    public void setUp() throws Exception {
        server = new TcpCommandServer(19876);
        procRoot = tmp.newFolder("proc");
        TcpCommandServer.procRootForTest = procRoot;
    }

    @org.junit.After
    public void tearDown() {
        TcpCommandServer.procRootForTest = null;
    }

    /**
     * Writes a {@code /proc/<pid>/cmdline} exactly as the kernel presents one:
     * NUL-separated argv, NUL-terminated.
     */
    private void fakeProcess(int pid, String... argv) throws Exception {
        File dir = new File(procRoot, String.valueOf(pid));
        Assert.assertTrue(dir.mkdirs());
        try (FileOutputStream out = new FileOutputStream(new File(dir, "cmdline"))) {
            for (String arg : argv) {
                out.write(arg.getBytes(StandardCharsets.UTF_8));
                out.write(0);
            }
        }
    }

    /**
     * app_process overwrites argv[0] with the nice-name and pads the region, so the
     * live daemon's argv[0] is the name followed by filler. Reproduced exactly, because
     * forgetting that padding is how a naive equality check would miss every daemon.
     */
    private void fakeNiceNamedDaemon(int pid, String niceName) throws Exception {
        StringBuilder padded = new StringBuilder(niceName);
        while (padded.length() < 120) padded.append(' ');
        fakeProcess(pid, padded.toString());
    }

    // --- the BladeWatch-xzhv regression ---

    @Test
    public void aProcessThatMerelyMentionsADaemonNameIsNotThatDaemon() throws Exception {
        // The exact on-device false positive: a shell whose command line contains the
        // zrok log path, with no zrok process anywhere. `pgrep -f` matched this.
        fakeProcess(101, "sh", "-c", "echo hi > /data/local/tmp/zrok.log");

        Assert.assertFalse(server.isProcessRunning("zrok"));
    }

    @Test
    public void theLauncherShellIsNotMistakenForTheDaemonItLaunches() throws Exception {
        // Observed live on the head unit: the sh -c that starts a daemon keeps its own
        // argv[0] of "sh" and lingers alongside the daemon.
        fakeProcess(102, "sh", "-c",
                "CLASSPATH=/data/app/net.bladewatch.app-x==/base.apk app_process /system/bin "
                        + "--nice-name=sentry_daemon net.bladewatch.app.daemon.SentryDaemon");

        Assert.assertFalse(server.isProcessRunning("sentry_daemon"));
    }

    @Test
    public void aWatcherScriptNamedAfterADaemonIsNotThatDaemon() throws Exception {
        fakeProcess(103, "sh", "/data/local/tmp/start_acc_sentry.sh");

        Assert.assertFalse(server.isProcessRunning("acc_sentry_daemon"));
    }

    // --- what must still work ---

    @Test
    public void findsAnAppProcessDaemonByItsNiceName() throws Exception {
        fakeNiceNamedDaemon(201, "byd_cam_daemon");

        Assert.assertTrue(server.isProcessRunning("byd_cam_daemon"));
    }

    @Test
    public void findsZrokWhichIsExecdByPathRatherThanRenamed() throws Exception {
        // zrok is not an app_process daemon: argv[0] is the binary path, so the match
        // has to compare basenames, not raw argv[0].
        fakeProcess(202, "/data/local/tmp/zrok", "share", "reserved", "abc123");

        Assert.assertTrue(server.isProcessRunning("zrok"));
    }

    @Test
    public void sentryDaemonDoesNotMatchAccSentryDaemon() throws Exception {
        // The property the old pattern's leading-boundary group existed for; exact
        // equality on argv[0] preserves it.
        fakeNiceNamedDaemon(203, "acc_sentry_daemon");

        Assert.assertFalse(server.isProcessRunning("sentry_daemon"));
        Assert.assertTrue(server.isProcessRunning("acc_sentry_daemon"));
    }

    @Test
    public void isFalseForANameNothingIsRunningUnder() throws Exception {
        fakeNiceNamedDaemon(204, "byd_cam_daemon");

        Assert.assertFalse(server.isProcessRunning("definitely_nonexistent_bladewatch_daemon"));
    }

    // --- robustness against a real procfs ---

    @Test
    public void skipsNonPidEntriesAndUnreadableProcesses() throws Exception {
        // /proc is full of non-PID entries (net, self, meminfo) and PIDs that vanish
        // between listing and opening; neither may throw or produce a match.
        Assert.assertTrue(new File(procRoot, "net").mkdirs());
        Assert.assertTrue(new File(procRoot, "self").mkdirs());
        Assert.assertTrue(new File(procRoot, "305").mkdirs()); // a PID dir with no cmdline
        fakeProcess(306); // kernel-thread style: empty cmdline
        fakeNiceNamedDaemon(307, "sentry_daemon");

        Assert.assertTrue(server.isProcessRunning("sentry_daemon"));
        Assert.assertFalse(server.isProcessRunning("net"));
        Assert.assertFalse(server.isProcessRunning("self"));
    }

    @Test
    public void isFalseWhenProcCannotBeListedAtAll() {
        TcpCommandServer.procRootForTest = new File(tmp.getRoot(), "no-such-proc");

        Assert.assertFalse(server.isProcessRunning("byd_cam_daemon"));
    }

    @Test
    public void isFalseForAnEmptyOrNullName() throws Exception {
        fakeNiceNamedDaemon(401, "byd_cam_daemon");

        Assert.assertFalse(server.isProcessRunning(""));
        Assert.assertFalse(server.isProcessRunning(null));
    }

    // --- processCommand("daemonStatus") wiring ---

    @Test
    public void reportsOkStatusAndAllFourDaemonKeys() throws Exception {
        JSONObject resp = server.processCommand(new JSONObject().put("cmd", "daemonStatus"));

        Assert.assertEquals("ok", resp.getString("status"));
        JSONObject daemons = resp.getJSONObject("daemons");
        Assert.assertTrue(daemons.has("CAMERA_DAEMON"));
        Assert.assertTrue(daemons.has("SENTRY_DAEMON"));
        Assert.assertTrue(daemons.has("ACC_SENTRY_DAEMON"));
        Assert.assertTrue(daemons.has("ZROK_TUNNEL"));
    }

    @Test
    public void reportsTheRealPerDaemonLivenessFromProc() throws Exception {
        fakeNiceNamedDaemon(501, "byd_cam_daemon");
        fakeNiceNamedDaemon(502, "acc_sentry_daemon");

        JSONObject daemons = server.processCommand(new JSONObject().put("cmd", "daemonStatus"))
                .getJSONObject("daemons");

        Assert.assertTrue(daemons.getBoolean("CAMERA_DAEMON"));
        Assert.assertTrue(daemons.getBoolean("ACC_SENTRY_DAEMON"));
        Assert.assertFalse(daemons.getBoolean("SENTRY_DAEMON"));
        Assert.assertFalse(daemons.getBoolean("ZROK_TUNNEL"));
    }
}
