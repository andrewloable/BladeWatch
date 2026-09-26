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
    }

    @After
    public void tearDown() {
        AuthMiddleware.setLoopbackBypassOverride(null);
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

    @Test
    public void loopbackBypassStillWorksForTheInCarListener() throws Exception {
        // The safety net has a real purpose — a same-device caller with no cached JWT — and it
        // survives tor's removal (BladeWatch-rdtj.12) on the in-car listener, where it belongs.
        AuthMiddleware.setLoopbackBypassOverride(Boolean.TRUE);

        boolean allowed = AuthMiddleware.checkAuth(
                "/api/vehicle/trunk", null, null, new ByteArrayOutputStream(),
                new InetSocketAddress("127.0.0.1", 8080), false, ListenerTrust.LOCAL_APPS);

        Assert.assertTrue("local callers still need the safety net", allowed);
    }

    // --- BladeWatch-rdtj.4: trust belongs to the LISTENER, not the source address ---

    @Test
    public void aRemoteListenerNeverGetsTheLoopbackBypass() throws Exception {
        // BladeWatch-rdtj.12's acceptance: a DEBUG build (bypass forced on, the worst case), tor
        // gone so there is no tunnel process to notice, and a request arriving the way the Pear
        // pump delivers it -- from 127.0.0.1 onto the REMOTE listener on 8444. It must still be
        // refused without a JWT: the listener decides, never the address.
        AuthMiddleware.setLoopbackBypassOverride(Boolean.TRUE);

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        boolean allowed = AuthMiddleware.checkAuth(
                "/api/vehicle/trunk", null, null, out,
                new InetSocketAddress("127.0.0.1", HttpServer.PEAR_TLS_PORT), false, ListenerTrust.REMOTE);

        Assert.assertFalse("a remote peer arriving via loopback must not inherit local trust", allowed);
        Assert.assertTrue(out.toString("UTF-8").contains("401 Unauthorized"));
    }

    /** BladeWatch-rdtj.12: the vehicle-control RPCs specifically, over the Pear pump, bypass forced on. */
    @Test
    public void vehicleControlOverThePearPumpWithoutAJwtIsA401() throws Exception {
        AuthMiddleware.setLoopbackBypassOverride(Boolean.TRUE);
        for (String method : new String[] {"MoveWindow", "SetClimate", "Trunk", "SetLights", "SetAdas", "SetChargeCap"}) {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            boolean allowed = AuthMiddleware.checkAuth(
                    "/bladewatch.v1.VehicleService/" + method, null, null, out,
                    new InetSocketAddress("127.0.0.1", HttpServer.PEAR_TLS_PORT), false, ListenerTrust.REMOTE);
            Assert.assertFalse(method + " must need a JWT over Pear", allowed);
            Assert.assertTrue(method + ": " + out.toString("UTF-8"), out.toString("UTF-8").contains("401 Unauthorized"));
        }
    }

    @Test
    public void aCallerThatDoesNotDeclareItsListenerFailsClosed() throws Exception {
        // Stands in for any listener or caller added later without thinking about trust: the
        // shorter overloads assume REMOTE, so forgetting is a denial, never an open door.
        AuthMiddleware.setLoopbackBypassOverride(Boolean.TRUE);

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
        // headers must still be distrusted, even on the in-car listener.
        AuthMiddleware.setLoopbackBypassOverride(Boolean.TRUE);

        // LOCAL_APPS on purpose: with the listener eligible and the bypass forced on, the forwarding
        // header is the ONLY reason left to refuse.
        boolean allowed = AuthMiddleware.checkAuth(
                "/api/vehicle/trunk", null, null, new ByteArrayOutputStream(),
                new InetSocketAddress("127.0.0.1", 8080), true, ListenerTrust.LOCAL_APPS);

        Assert.assertFalse(allowed);
    }

    private boolean checkPublic(String path) throws Exception {
        return AuthMiddleware.checkAuth(path, null, null, new ByteArrayOutputStream(), null, false);
    }
}
