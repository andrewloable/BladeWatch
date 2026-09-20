package net.bladewatch.app.server;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.junit.Assert;
import org.junit.Test;

/**
 * BladeWatch-jwko: the vehicle second factor, restored on the path clients actually use.
 *
 * <p>uy93.5 added a short-lived action token on top of the session JWT for vehicle actuation
 * from non-loopback callers — the tunnel threat model. It was gated on
 * {@code path.startsWith("/api/vehicle/")}. Every real command goes to
 * {@code /bladewatch.v1.VehicleService/*}, which never matched, so the control had been inert
 * for every client since the Connect migration: over the tunnel a session JWT alone actuated
 * the car.
 *
 * <p>A guard keyed on a path nothing matches is worse than no guard, because the reader believes
 * it. These tests exist so it cannot decay that way again — in particular
 * {@link #everyVehicleCommandIsClassified}, which fails when a new RPC is registered without
 * anyone deciding whether it actuates the car.
 */
public class VehicleActionGateTest {

    @Test
    public void actuationFromTheTunnelNeedsTheSecondFactor() {
        for (String method : new String[] {
                "SetClimate", "MoveWindow", "Trunk", "SetSeat", "SetLights",
                "SetAdas", "SetChargeCap", "SetScreen", "SetMediaVolume" }) {
            assertTrue(method + " actuates the car and must require an action token",
                    VehicleActionGate.requiresActionToken(
                            "/bladewatch.v1.VehicleService/" + method));
        }
    }

    @Test
    public void readsAndNonActuationAreNotGated() {
        // Gating a read would make the About and Vehicle pages demand a token to display
        // anything, for no security gain — nothing here touches the car.
        for (String method : new String[] {
                "GetState", "GetChargeCap", "GetAcDiagnostics", "GetSeatDiagnostics",
                "GetGpsLocation", "StartGps", "StopGps", "IssueActionToken" }) {
            assertFalse(method + " does not actuate the car and must not be gated",
                    VehicleActionGate.requiresActionToken(
                            "/bladewatch.v1.VehicleService/" + method));
        }
    }

    @Test
    public void theTokenIssuerItselfIsNeverGated() {
        // Gating it would make the token unobtainable: you would need a token to get a token.
        assertFalse(VehicleActionGate.requiresActionToken(
                "/bladewatch.v1.VehicleService/IssueActionToken"));
    }

    @Test
    public void otherServicesAreUntouched() {
        assertFalse(VehicleActionGate.requiresActionToken("/bladewatch.v1.TripsService/DeleteTrip"));
        assertFalse(VehicleActionGate.requiresActionToken("/bladewatch.v1.SystemService/GetStatus"));
        assertFalse(VehicleActionGate.requiresActionToken("/video/2026-09-19/clip.mp4"));
        assertFalse(VehicleActionGate.requiresActionToken(null));
        // A query string must not let a command slip past the match.
        assertTrue(VehicleActionGate.requiresActionToken(
                "/bladewatch.v1.VehicleService/Trunk?x=1"));
    }

    /**
     * Every registered VehicleService RPC is either gated or explicitly listed as read-only.
     *
     * <p>This is the anti-decay guard. Adding a command without touching the gate leaves it
     * ungated by default, which is exactly how uy93.5 stopped protecting anything — silently,
     * with the control still visible in the codebase.
     */
    @Test
    public void everyVehicleCommandIsClassified() throws IOException {
        String impl = readSource("app/src/main/java/com/loabletech/bladewatch/server/connect/impl/"
                + "VehicleServiceImpl");
        Matcher m = Pattern.compile(
                "register\\(\"bladewatch\\.v1\\.VehicleService\",\\s*\"([A-Za-z]+)\"").matcher(impl);
        List<String> unclassified = new ArrayList<>();
        int seen = 0;
        while (m.find()) {
            seen++;
            String method = m.group(1);
            String path = "/bladewatch.v1.VehicleService/" + method;
            boolean gated = VehicleActionGate.requiresActionToken(path);
            boolean declaredReadOnly = VehicleActionGate.isDeclaredReadOnly(method);
            if (gated == declaredReadOnly) unclassified.add(method);
        }
        Assert.assertTrue("found no VehicleService registrations — the scan is broken, and a "
                + "guard that cannot fail is worse than no guard", seen > 0);
        assertEquals("These VehicleService RPCs are neither gated nor declared read-only. Decide "
                + "whether each actuates the car and add it to the right list in "
                + "VehicleActionGate (BladeWatch-jwko). Unclassified: " + unclassified,
                List.of(), unclassified);
    }

    private static String read(String relative) throws IOException {
        Path p = Path.of(relative);
        if (!Files.isRegularFile(p)) p = Path.of("..").resolve(relative);
        Assert.assertTrue("missing " + relative + " from " + new File(".").getAbsolutePath(),
                Files.isRegularFile(p));
        return new String(Files.readAllBytes(p), StandardCharsets.UTF_8);
    }
    /**
     * Read a source file named without its extension. The Connect impls are mid-migration to
     * Kotlin (BladeWatch-9rut), so the guard follows the file rather than the language; if both
     * spellings exist the conversion is half-finished and the guard would read the stale one.
     */
    private static String readSource(String relativeNoExtension) throws IOException {
        Path java = locate(relativeNoExtension + ".java");
        Path kotlin = locate(relativeNoExtension + ".kt");
        Assert.assertTrue("missing " + relativeNoExtension + " (.java or .kt) from "
                + new File(".").getAbsolutePath(), java != null || kotlin != null);
        Assert.assertFalse("both a .java and a .kt exist for " + relativeNoExtension
                + " -- a half-finished conversion; this guard would read the stale copy",
                java != null && kotlin != null);
        return new String(Files.readAllBytes(java != null ? java : kotlin),
                StandardCharsets.UTF_8);
    }

    private static Path locate(String relative) {
        Path p = Path.of(relative);
        if (Files.isRegularFile(p)) return p;
        p = Path.of("..").resolve(relative);
        return Files.isRegularFile(p) ? p : null;
    }

}
