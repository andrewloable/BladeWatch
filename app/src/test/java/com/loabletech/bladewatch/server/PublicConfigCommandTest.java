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
