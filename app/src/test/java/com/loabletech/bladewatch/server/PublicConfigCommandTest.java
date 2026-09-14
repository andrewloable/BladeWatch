package net.bladewatch.app.server;

import org.json.JSONObject;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

/**
 * BladeWatch-hygs: the {@code config_get_section}/{@code config_put} IPC commands.
 *
 * <p>What these tests pin is the ALLOWLIST, not the read/write itself: the happy path
 * ends in {@code UnifiedConfigManager}, which reads and writes a real file under
 * {@code /storage/emulated/0} and logs through {@code android.util.Log} — neither
 * exists in a JVM unit test, so it is exercised on device instead. The allowlist is
 * the part that has security consequences if it drifts, and it is pure logic.
 */
public class PublicConfigCommandTest {

    private TcpCommandServer server;

    @Before
    public void setUp() {
        server = new TcpCommandServer(19876);
    }

    @Test
    public void allowsOnlyTheTwoSettingsOwnedSections() {
        Assert.assertTrue(TcpCommandServer.isPublicConfigSectionAllowed("statusOverlay"));
        Assert.assertTrue(TcpCommandServer.isPublicConfigSectionAllowed("developerOptions"));
    }

    @Test
    public void refusesEveryOtherConfigSection() {
        // These are the sections a generic public-config write would otherwise expose.
        // network.lanHttpEnabled in particular decides whether the HTTP server binds
        // beyond loopback (see the Security Notes in CLAUDE.md).
        for (String section : new String[] {
                "network", "surveillance", "recording", "streaming", "proximityGuard",
                "vehicle", "tripAnalytics", "telemetryOverlay", "auth", "",
        }) {
            Assert.assertFalse(
                    "section should not be writable over IPC: " + section,
                    TcpCommandServer.isPublicConfigSectionAllowed(section));
        }
    }

    // BladeWatch-i2wv: the Diagnostics Camera tile needs to READ camera config. The
    // tempting fix was to add "camera" to the write allowlist, which would have handed
    // out unvalidated write access to satisfy a read-only tile. These pin the split.

    @Test
    public void cameraSectionIsReadableButNotWritable() {
        Assert.assertTrue(
                "Diagnostics' camera tile must be able to read it",
                TcpCommandServer.isPublicConfigSectionReadable("camera"));
        Assert.assertFalse(
                "camera config must NOT be writable over IPC",
                TcpCommandServer.isPublicConfigSectionAllowed("camera"));
    }

    @Test
    public void everyWritableSectionIsAlsoReadable() {
        for (String section : new String[] {"statusOverlay", "developerOptions"}) {
            Assert.assertTrue(
                    "writable implies readable: " + section,
                    TcpCommandServer.isPublicConfigSectionReadable(section));
        }
    }

    @Test
    public void theReadAllowlistIsStillNarrow() {
        // Widening the READ gate is cheaper than widening the write gate, but it is
        // not free — config sections carry device detail. Everything outside the
        // named set stays unreadable too.
        for (String section : new String[] {
                "network", "surveillance", "recording", "streaming", "proximityGuard",
                "vehicle", "tripAnalytics", "telemetryOverlay", "auth", "",
        }) {
            Assert.assertFalse(
                    "section should not be readable over IPC: " + section,
                    TcpCommandServer.isPublicConfigSectionReadable(section));
        }
    }

    @Test
    public void configPutStillRefusesTheCameraSection() throws Exception {
        JSONObject resp = server.processCommand(new JSONObject()
                .put("cmd", "config_put")
                .put("section", "camera")
                .put("key", "probedCameraId")
                .put("value", 3));

        Assert.assertEquals("error", resp.getString("status"));
    }

    @Test
    public void cameraSectionExposesOnlyTheTwoTileFields() throws Exception {
        // A realistic section, including the device-identifying strings the real one
        // carries — the whole point is that those do NOT come back out.
        TcpCommandServer.cameraConfigForTest = new JSONObject()
                .put("probedCameraId", 0)
                .put("manualOverride", false)
                .put("firmwareFingerprint", "BYD-AUTO/DiLink3.0/...:user/release-keys")
                .put("buildDisplay", "QKQ1.210910.001 release-keys")
                .put("buildIncremental", "eng.build.20251023.052448")
                .put("roBuildIncremental", "eng.build.20251023.052448")
                .put("productDevice", "DiLink3.0")
                .put("nativeProbeReport", "some internal probe detail");
        JSONObject resp;
        try {
            resp = server.processCommand(
                    new JSONObject().put("cmd", "config_get_section").put("section", "camera"));
        } finally {
            TcpCommandServer.cameraConfigForTest = null;
        }

        Assert.assertEquals("ok", resp.getString("status"));
        JSONObject section = resp.getJSONObject("section");

        // Exactly the two fields the Diagnostics tile renders, and nothing else.
        // The real camera config also holds firmwareFingerprint, buildDisplay,
        // buildIncremental and productDevice — device-identifying strings that must
        // not cross this boundary to satisfy a status tile. A future change that
        // returns the section wholesale fails here.
        Assert.assertTrue(section.has("probedCameraId"));
        Assert.assertTrue(section.has("manualOverride"));
        Assert.assertEquals(2, section.length());
        for (String leaked : new String[] {
                "firmwareFingerprint", "buildDisplay", "buildIncremental",
                "roBuildIncremental", "productDevice", "nativeProbeReport",
        }) {
            Assert.assertFalse(
                    "must not be exposed over IPC: " + leaked, section.has(leaked));
        }
    }

    @Test
    public void getSectionRejectsANonAllowlistedSection() throws Exception {
        JSONObject resp = server.processCommand(
                new JSONObject().put("cmd", "config_get_section").put("section", "network"));

        Assert.assertEquals("error", resp.getString("status"));
        Assert.assertFalse(resp.has("section"));
    }

    @Test
    public void putRejectsANonAllowlistedSection() throws Exception {
        JSONObject resp = server.processCommand(new JSONObject()
                .put("cmd", "config_put")
                .put("section", "network")
                .put("key", "lanHttpEnabled")
                .put("value", true));

        Assert.assertEquals("error", resp.getString("status"));
    }

    @Test
    public void putRejectsAnAllowlistedSectionWithNoKey() throws Exception {
        JSONObject resp = server.processCommand(new JSONObject()
                .put("cmd", "config_put")
                .put("section", "statusOverlay")
                .put("value", true));

        Assert.assertEquals("error", resp.getString("status"));
    }

    @Test
    public void putRejectsAMissingValueRatherThanWritingNull() throws Exception {
        JSONObject resp = server.processCommand(new JSONObject()
                .put("cmd", "config_put")
                .put("section", "statusOverlay")
                .put("key", "cameraVisible"));

        Assert.assertEquals("error", resp.getString("status"));
    }
}
