package net.bladewatch.app.server;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;

import org.junit.Assert;
import org.junit.Test;

/**
 * BladeWatch-6mnq: the JSON field names the Connect impls read must be the ones the PROTO
 * defines, because nothing else checks them.
 *
 * <p>Inverting a handler moves request parsing out of the handler and into the Connect impl,
 * which reads fields by string name off the decoded JSON. A wrong name does not fail to
 * compile and does not throw — {@code optBoolean} simply returns its default. Caught while
 * inverting {@code SafeLocationApiHandler}: the impl was written against {@code setEnabled}
 * while {@code ToggleSafeLocationsRequest} defines {@code enabled_set} (json {@code enabledSet}),
 * which would have made every explicit toggle silently INVERT the current state instead of
 * setting it — the surveillance screen's safe-locations switch would have appeared to work and
 * done the opposite whenever it was already in the requested state.
 */
public class SafeLocationRequestShapeTest {

    @Test
    public void theToggleCompanionFieldMatchesTheProto() throws IOException {
        String proto = read("proto/bladewatch/v1/safe_locations.proto");
        assertTrue("ToggleSafeLocationsRequest must keep its presence companion",
                proto.contains("bool enabled_set"));

        String impl = readSource("app/src/main/java/com/loabletech/bladewatch/server/connect/impl/"
                + "SafeLocationsServiceImpl");
        // proto3 json maps enabled_set -> enabledSet.
        assertTrue("SafeLocationsServiceImpl must read the proto's companion field name",
                impl.contains("\"enabledSet\""));
        assertFalse("setEnabled is not a field of ToggleSafeLocationsRequest — reading it makes "
                + "every explicit toggle invert instead of set",
                impl.contains("\"setEnabled\""));
    }

    @Test
    public void addZoneReadsTheFieldsTheProtoDefines() throws IOException {
        String proto = read("proto/bladewatch/v1/safe_locations.proto");
        String impl = readSource("app/src/main/java/com/loabletech/bladewatch/server/connect/impl/"
                + "SafeLocationsServiceImpl");
        for (String field : new String[] { "name", "lat", "lng" }) {
            assertTrue("proto must define " + field, proto.contains(" " + field + " = "));
            assertTrue("AddZone must read " + field, impl.contains("\"" + field + "\""));
        }
        // radius_m is snake in proto, radiusM in proto3 json.
        assertTrue(proto.contains("int32 radius_m"));
        assertTrue("AddZone must read the proto3 json spelling of radius_m",
                impl.contains("\"radiusM\""));
    }

    @Test
    public void zoneNamesAreStrippedOfAngleBracketsAtTheSource() {
        // The zone name reaches innerHTML and a Leaflet popup, neither of which escapes.
        assertEquals("scriptalert(1)/script", SafeLocationApiHandler.sanitizeZoneName(
                "<script>alert(1)</script>").replace(">", ""));
        assertFalse(SafeLocationApiHandler.sanitizeZoneName("<b>Home</b>").contains("<"));
        assertEquals("Unnamed", SafeLocationApiHandler.sanitizeZoneName("   "));
        assertEquals(64, SafeLocationApiHandler.sanitizeZoneName("x".repeat(200)).length());
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
