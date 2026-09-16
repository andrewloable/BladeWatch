package net.bladewatch.app.server;

import org.junit.After;
import org.junit.Assert;
import org.junit.Before;
import org.junit.Test;

import java.io.ByteArrayOutputStream;
import java.net.InetSocketAddress;

public class AuthMiddlewareTest {

    @Before
    public void setUp() {
        AuthMiddleware.setLoopbackBypassOverride(null);
        AuthMiddleware.setTunnelActiveOverride(null);
    }

    @After
    public void tearDown() {
        AuthMiddleware.setLoopbackBypassOverride(null);
        AuthMiddleware.setTunnelActiveOverride(null);
    }

    @Test
    public void publicPathsRemainPublicWithoutAuth() throws Exception {
        Assert.assertTrue(checkPublic("/auth/token"));
        Assert.assertTrue(checkPublic("/auth/status"));
        Assert.assertTrue(checkPublic("/login.html"));
        Assert.assertTrue(checkPublic("/shared/app.js"));
        Assert.assertTrue(checkPublic("/i18n/en.json"));
    }

    @Test
    public void protectedApiWithoutJwtIsRejected() throws Exception {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        boolean allowed = AuthMiddleware.checkAuth(
                "/api/vehicle/trunk", null, null, out, null, false);
        Assert.assertFalse(allowed);
        Assert.assertTrue(out.toString("UTF-8").contains("401 Unauthorized"));
    }

    @Test
    public void loopbackWithoutJwtIsRejectedWhenBypassDisabled() throws Exception {
        AuthMiddleware.setLoopbackBypassOverride(Boolean.FALSE);
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        boolean allowed = AuthMiddleware.checkAuth(
                "/api/vehicle/trunk", null, null, out,
                new InetSocketAddress("127.0.0.1", 8080), false);
        Assert.assertFalse(allowed);
        Assert.assertTrue(out.toString("UTF-8").contains("401 Unauthorized"));
    }

    @Test
    public void signedThumbPathStillAllowsTokenBasedAccess() throws Exception {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        boolean allowed = AuthMiddleware.checkAuth(
                "/thumb/event.jpg?t=invalid", null, null, out, null, false);
        Assert.assertFalse(allowed);
    }

    // --- BladeWatch-3lbz.2: the loopback bypass versus a Tor onion service ---

    @Test
    public void loopbackBypassIsDisabledWhileTheTorTunnelIsUp() throws Exception {
        // THE regression this whole group exists for.
        //
        // The previous tunnel relayed remote traffic with X-Forwarded-* headers, so
        // hasTunnelHeaders was true for every remote request and Tier 2 switched itself off. Tor injects NOTHING:
        // the onion service opens a plain TCP connection to 127.0.0.1:8080, which at the
        // socket level is indistinguishable from an app on the head unit.
        //
        // So on a DEBUG build — the build CLAUDE.md's install procedure actually puts on the
        // car, because preserving the ADB key needs run-as — a remote visitor who merely knew
        // the onion address would have sailed straight past authentication. The tunnel being
        // up is now itself a reason to distrust loopback.
        AuthMiddleware.setLoopbackBypassOverride(Boolean.TRUE);
        AuthMiddleware.setTunnelActiveOverride(Boolean.TRUE);

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        boolean allowed = AuthMiddleware.checkAuth(
                "/api/vehicle/trunk", null, null, out,
                new InetSocketAddress("127.0.0.1", 8080), false);

        Assert.assertFalse("a remote Tor visitor must not inherit local trust", allowed);
        Assert.assertTrue(out.toString("UTF-8").contains("401 Unauthorized"));
    }

    @Test
    public void loopbackBypassStillWorksWhileNoTunnelIsRunning() throws Exception {
        // The safety net has a real purpose — a same-device caller with no cached JWT — and
        // it must survive when the car is not exposed to anyone.
        AuthMiddleware.setLoopbackBypassOverride(Boolean.TRUE);
        AuthMiddleware.setTunnelActiveOverride(Boolean.FALSE);

        boolean allowed = AuthMiddleware.checkAuth(
                "/api/vehicle/trunk", null, null, new ByteArrayOutputStream(),
                new InetSocketAddress("127.0.0.1", 8080), false);

        Assert.assertTrue("local callers still need the safety net", allowed);
    }

    @Test
    public void forwardedHeadersStillDisableTheBypassOnTheirOwn() throws Exception {
        // Regression cover for the pre-existing rule: a relay that DOES add forwarding
        // headers must still be distrusted even with no tunnel process detected.
        AuthMiddleware.setLoopbackBypassOverride(Boolean.TRUE);
        AuthMiddleware.setTunnelActiveOverride(Boolean.FALSE);

        boolean allowed = AuthMiddleware.checkAuth(
                "/api/vehicle/trunk", null, null, new ByteArrayOutputStream(),
                new InetSocketAddress("127.0.0.1", 8080), true);

        Assert.assertFalse(allowed);
    }

    private boolean checkPublic(String path) throws Exception {
        return AuthMiddleware.checkAuth(path, null, null, new ByteArrayOutputStream(), null, false);
    }
}
