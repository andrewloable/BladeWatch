package net.bladewatch.app.byd;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import org.json.JSONArray;
import org.json.JSONObject;
import org.junit.Test;

import java.lang.reflect.InvocationTargetException;

/**
 * BladeWatch-2pnn.3: {@link AdasFieldInventory} in a JVM unit test, where the REAL BYD SDK is
 * never present. These tests target the shape and the failure path, not real on-device values.
 *
 * <p>Note a subtlety specific to this codebase's "BYD SDK Stub Pattern" (see CLAUDE.md):
 * {@code android.hardware.bydauto.BYDAutoFeatureIds} is NOT simply absent here.
 * {@code app/src/main/java/android/hardware/bydauto/BYDAutoFeatureIds.java} is a checked-in
 * compile-time stub with no {@code Adas} inner class, and it compiles into this module's own
 * classes -- so {@code Class.forName} on it SUCCEEDS in a plain JVM test (there is no Android
 * boot classloader here to shadow it with the real on-device class, unlike on an actual head
 * unit, where the boot classloader's real class takes priority over the app's own stub). So
 * {@code sdkClassPresent} is {@code true} in this test, for a reason that has nothing to do
 * with whether a real ADAS SDK is present -- what actually distinguishes "no real SDK" here is
 * that every {@code Adas.*} field lookup fails (no such inner class), so every entry's
 * {@code resolvedFromSdk} is {@code false} regardless of {@code sdkClassPresent}.
 */
public class AdasFieldInventoryTest {

    @Test
    public void doesNotThrow_evenThoughThisModulesOwnStubClassLoadsFine() throws Exception {
        JSONObject result = AdasFieldInventory.probe(null);

        // True here because BladeWatch's own compile-time stub loads -- see the class javadoc.
        // This is what a real device with no boot-classloader override would ALSO see if the
        // real BYDAutoFeatureIds class were somehow entirely missing; the point of this
        // assertion is that probe() completes and returns a well-formed boolean either way.
        assertTrue(result.has("sdkClassPresent"));
    }

    @Test
    public void noAdasFieldsOnTheStub_everyDeclaredEntryIsUnresolvedAndNoDevice() throws Exception {
        JSONObject result = AdasFieldInventory.probe(null);

        JSONArray declared = result.getJSONArray("declared");
        assertTrue(declared.length() > 0);
        for (int i = 0; i < declared.length(); i++) {
            JSONObject entry = declared.getJSONObject(i);
            assertFalse("entry " + i + " (" + entry.optString("name") + ") claimed resolvedFromSdk",
                    entry.getBoolean("resolvedFromSdk"));
            assertEquals("entry " + i + " (" + entry.optString("name") + ") readStatus",
                    "NO_DEVICE", entry.getString("readStatus"));
        }
    }

    @Test
    public void declaredCount_isDerivedFromBydFeatureIdsReflection_notHardcoded() throws Exception {
        // The count comes from reflecting over BydFeatureIds' own ADAS_* fields -- this
        // assertion is the guard that fails loudly if a 30th id is added without updating
        // AdasFieldInventory's DECLARED table.
        int reflectedCount = AdasFieldInventory.countDeclaredAdasFieldsOnBydFeatureIds();
        assertEquals(29, reflectedCount);

        JSONObject result = AdasFieldInventory.probe(null);
        assertEquals(reflectedCount, result.getJSONArray("declared").length());
    }

    @Test
    public void probeResult_containsAllThreeTopLevelKeys() throws Exception {
        JSONObject result = AdasFieldInventory.probe(null);

        assertTrue(result.has("sdkClassPresent"));
        assertTrue(result.has("declared"));
        assertTrue(result.has("sdkOnly"));
    }

    @Test
    public void permissionDenied_mapsToPermissionDenied_notFailed() {
        // callGetSingle can't be driven through a real SecurityException with no BYD device
        // present in a JVM test, so per this issue's own fallback, the status mapping is
        // extracted into a pure static and tested directly.
        assertEquals(BydDeviceHelper.ReadStatus.PERMISSION_DENIED,
                BydDeviceHelper.statusForFailure(new SecurityException("denied")));
    }

    @Test
    public void otherFailure_mapsToFailed_notPermissionDenied() {
        assertEquals(BydDeviceHelper.ReadStatus.FAILED,
                BydDeviceHelper.statusForFailure(new RuntimeException("boom")));
    }

    /**
     * BladeWatch-t87k: the bare-SecurityException case above is a shape production never
     * produces. {@code statusForFailure}'s only caller classifies what
     * {@code Method.invoke} threw, and reflection wraps anything the target method raises in
     * an {@link java.lang.reflect.InvocationTargetException} — so a real permission refusal
     * arrives wrapped, and was being reported as a generic FAILED.
     *
     * <p>This is the distinction the whole endpoint exists to draw: of 123 requested BYDAUTO
     * permissions only 20 are granted, the _GET/_SET variants being signature-protected and
     * ungrantable, so a refusal is the EXPECTED outcome for much of this inventory.
     */
    @Test
    public void wrappedSecurityException_mapsToPermissionDenied() {
        Exception wrapped = new InvocationTargetException(new SecurityException("denied"));
        assertEquals("the production shape: reflection wraps what the SDK threw",
                BydDeviceHelper.ReadStatus.PERMISSION_DENIED,
                BydDeviceHelper.statusForFailure(wrapped));
    }

    @Test
    public void doublyWrappedSecurityException_mapsToPermissionDenied() {
        Exception wrapped = new InvocationTargetException(
                new InvocationTargetException(new SecurityException("denied")));
        assertEquals(BydDeviceHelper.ReadStatus.PERMISSION_DENIED,
                BydDeviceHelper.statusForFailure(wrapped));
    }

    @Test
    public void wrappedNonSecurityException_stillMapsToFailed() {
        Exception wrapped = new InvocationTargetException(new IllegalStateException("boom"));
        assertEquals("unwrapping must not turn every failure into a permission problem",
                BydDeviceHelper.ReadStatus.FAILED,
                BydDeviceHelper.statusForFailure(wrapped));
    }

    @Test
    public void wrapperWithNoCause_mapsToFailed_andTerminates() {
        Exception wrapped = new InvocationTargetException(null);
        assertEquals(BydDeviceHelper.ReadStatus.FAILED,
                BydDeviceHelper.statusForFailure(wrapped));
    }
}
