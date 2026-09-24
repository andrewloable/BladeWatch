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
                new InetSocketAddress("127.0.0.1", 8080), false, ListenerTrust.LOCAL_APPS);

        Assert.assertTrue("local callers still need the safety net", allowed);
    }

    // --- BladeWatch-rdtj.4: trust belongs to the LISTENER, not the source address ---

    @Test
    public void aRemoteListenerNeverGetsTheLoopbackBypass() throws Exception {
        // The LAN TLS listener, and the Pear pump's: the pump reaches this server from 127.0.0.1,
        // exactly like tor, so a loopback address proves nothing there. With every other Tier 2
        // condition forced OPEN -- debug bypass on, no tunnel -- a REMOTE listener must still deny.
        AuthMiddleware.setLoopbackBypassOverride(Boolean.TRUE);
        AuthMiddleware.setTunnelActiveOverride(Boolean.FALSE);

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        boolean allowed = AuthMiddleware.checkAuth(
                "/api/vehicle/trunk", null, null, out,
                new InetSocketAddress("127.0.0.1", 8081), false, ListenerTrust.REMOTE);

        Assert.assertFalse("a remote peer arriving via loopback must not inherit local trust", allowed);
        Assert.assertTrue(out.toString("UTF-8").contains("401 Unauthorized"));
    }

    @Test
    public void aCallerThatDoesNotDeclareItsListenerFailsClosed() throws Exception {
        // Stands in for any listener or caller added later without thinking about trust: the
        // shorter overloads assume REMOTE, so forgetting is a denial, never an open door.
        AuthMiddleware.setLoopbackBypassOverride(Boolean.TRUE);
        AuthMiddleware.setTunnelActiveOverride(Boolean.FALSE);

        boolean allowed = AuthMiddleware.checkAuth(
                "/api/vehicle/trunk", null, null, new ByteArrayOutputStream(),
                new InetSocketAddress("127.0.0.1", 8080), false);

        Assert.assertFalse("an undeclared listener must default to REMOTE", allowed);
    }

    @Test
    public void onlyTheLocalListenerOnLoopbackIsExemptFromTheVehicleSecondFactor() throws Exception {
        java.net.InetAddress loopback = java.net.InetAddress.getByName("127.0.0.1");
        java.net.InetAddress lan = java.net.InetAddress.getByName("192.0.2.10");

        Assert.assertTrue(AuthMiddleware.isLocalAppCaller(ListenerTrust.LOCAL_APPS, loopback));
        // The Pear pump: loopback, but remote. Must need the action token.
        Assert.assertFalse(AuthMiddleware.isLocalAppCaller(ListenerTrust.REMOTE, loopback));
        Assert.assertFalse(AuthMiddleware.isLocalAppCaller(ListenerTrust.REMOTE, lan));
        Assert.assertFalse(AuthMiddleware.isLocalAppCaller(ListenerTrust.LOCAL_APPS, lan));
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
