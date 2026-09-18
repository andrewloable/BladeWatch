package net.bladewatch.app.byd;

import net.bladewatch.app.logging.DaemonLogger;

import org.json.JSONArray;
import org.json.JSONObject;

import java.lang.reflect.Field;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.Set;

/**
 * Read-only inventory of BladeWatch's declared {@code BydFeatureIds.ADAS_*} ids against the
 * real BYD SDK, on demand only (BladeWatch-2pnn.3).
 *
 * <p>{@code BydFeatureIds.resolveOrFallback} silently substitutes a numeric literal when the
 * real SDK field is absent, and the failure logs at DEBUG (stripped by R8 in release) — so a
 * declared id proves nothing about whether THIS car has that field, and there was previously
 * no way to find out on a shipped build. This class answers that, and nothing else: it never
 * calls a setter, never runs on a timer, and never writes to the vehicle.
 */
public final class AdasFieldInventory {

    private static final DaemonLogger logger = DaemonLogger.getInstance("AdasFieldInventory");
    private static final String SDK_CLASS = "android.hardware.bydauto.BYDAutoFeatureIds";
    private static final String SDK_ADAS_INNER_CLASS = "Adas";

    /**
     * One row per {@code BydFeatureIds.ADAS_*} constant: {name, sdkFieldName, fallback},
     * transcribed by hand from that constant's {@code resolveOrFallback(sdkFieldName, fallback)}
     * call site (BydFeatureIds.java, ADAS block). This duplication is deliberate — an
     * "independent" check that read its expected mapping from the thing it audits would not be
     * independent of anything. Keep in sync with BydFeatureIds.java; {@link #probe} logs a
     * warning (and the test suite fails loudly, see AdasFieldInventoryTest) if the count drifts.
     */
    private static final Object[][] DECLARED = {
        {"ADAS_OMS_DRIVER_DETECTION", "Adas.OMS_DRIVER_DETECTION_RESULT", 834666600},
        {"ADAS_OMS_PASSENGER_DETECTION", "Adas.OMS_PASSENGER_DETECTION_RESULT", 834666605},
        {"ADAS_SLR_STATUS_SET", "Adas.ADAS_SLR_STATUS_SET", 944767040},
        {"ADAS_ISLA_SWITCH_SET", "Adas.ADAS_ISLA_SWITCH_SET", 944767044},
        {"ADAS_ISLA_SWITCH_STATUS", "Adas.ADAS_ISLA_SWITCH_STATUS_5R13V", 760217615},
        {"ADAS_ISLC_SWITCH_SET", "Adas.ADAS_ISLC_SWITCH_SET", 1324560408},
        {"ADAS_ISLC_SWITCH_STATUS", "Adas.ADAS_ISLC_SWITCH_STATUS_5R13V", 760217611},
        {"ADAS_ELKA_SWITCH_SET", "Adas.ADAS_ELKA_SWITCH_SET", 944767046},
        {"ADAS_ELKA_SWITCH_STATE", "Adas.ADAS_ELKA_SWITCH_STATE", 854589482},
        {"ADAS_FCW_LEVEL_SET", "Adas.ADAS_FCW_LEVEL_SET", 1324560420},
        {"ADAS_FCW_LEVEL_STATUS", "Adas.ADAS_FCW_LEVEL_STATUS", 327155720},
        {"ADAS_RCTA_STATE_SET", "Adas.ADAS_RCTA_STATE_SET", 944766990},
        {"ADAS_RTCA_SWITCH_STATE", "Adas.ADAS_RTCA_SWITCH_STATE", 1098907674},
        {"ADAS_RTCB_SWITCH_STATE", "Adas.ADAS_RTCB_SWITCH_STATE", 1098907688},
        {"ADAS_ECTB_STATE_SET", "Adas.ADAS_ECTB_STATE_SET", 944767006},
        {"ADAS_FCTA_SWITCH_STATUS", "Adas.ADAS_FCTA_SWITCH_STATUS", 748683276},
        {"ADAS_FCTA_SWITCH_SET", "Adas.ADAS_FCTA_SWITCH_SET", 1324560400},
        {"ADAS_FCTB_SWITCH_STATUS", "Adas.ADAS_FCTB_SWITCH_STATUS", 748683278},
        {"ADAS_FCTB_SWITCH_SET", "Adas.ADAS_FCTB_SWITCH_SET", 1324560402},
        {"ADAS_TLA_SWITCH_SET", "Adas.ADAS_TLA_SWITCH_SET", 1324560410},
        {"ADAS_TLA_SWITCH_STATUS", "Adas.ADAS_TLA_SWITCH_STATUS_5R13V", 760217640},
        {"ADAS_DOW_STATE_SET", "Adas.ADAS_DOW_STATE_SET", 944766994},
        {"ADAS_DOW_SWITCH_STATE", "Adas.ADAS_DOW_SWITCH_STATE", 1098907678},
        {"ADAS_RCW_SWITCH_STATE", "Adas.ADAS_RCW_SWITCH_STATE", 1098907676},
        {"ADAS_RCW_STATE_SET", "Adas.ADAS_RCW_STATE_SET", 944766992},
        {"ADAS_ESP_STATE", "Adas.ADAS_ESP_STATE", 305135676},
        {"ADAS_ESP_STATE_SET", "Adas.ADAS_ESP_STATE_SET", 944766984},
        {"ADAS_SLW_FUNC_SWITCH_STATE", "Adas.ADAS_SLW_FUNC_SWITCH_STATE", 535834664},
        {"ADAS_SLW_FUNC_SWITCH_STATE_SET", "Adas.ADAS_SLW_FUNC_SWITCH_STATE_SET", 850452531},
    };

    private static final Set<String> DECLARED_SDK_FIELD_NAMES;
    static {
        Set<String> names = new LinkedHashSet<>();
        for (Object[] row : DECLARED) {
            names.add((String) row[1]);
        }
        DECLARED_SDK_FIELD_NAMES = Collections.unmodifiableSet(names);
    }

    private AdasFieldInventory() {}

    /**
     * Counts {@code BydFeatureIds}' own {@code ADAS_*} fields via reflection — the coverage
     * cross-check that {@link #DECLARED} has not silently drifted out of sync with it.
     */
    public static int countDeclaredAdasFieldsOnBydFeatureIds() {
        int count = 0;
        for (Field f : BydFeatureIds.class.getDeclaredFields()) {
            if (f.getName().startsWith("ADAS_")) {
                count++;
            }
        }
        return count;
    }

    /**
     * Runs the probe. {@code adasDevice} is the live {@code BYDAutoADASDevice} (or {@code null}
     * if unavailable / not yet initialised, e.g. in a JVM unit test) — pass
     * {@code BydDataCollector.getInstance().getAdasDevice()}.
     */
    public static JSONObject probe(Object adasDevice) throws org.json.JSONException {
        int liveCount = countDeclaredAdasFieldsOnBydFeatureIds();
        if (liveCount != DECLARED.length) {
            logger.warn("AdasFieldInventory.DECLARED has " + DECLARED.length
                + " entries but BydFeatureIds now declares " + liveCount
                + " ADAS_* fields -- update DECLARED, this inventory is stale.");
        }

        JSONObject result = new JSONObject();
        result.put("sdkClassPresent", sdkClassPresent());

        JSONArray declared = new JSONArray();
        for (Object[] row : DECLARED) {
            declared.put(probeOne(adasDevice, (String) row[0], (String) row[1], (Integer) row[2]));
        }
        result.put("declared", declared);
        result.put("sdkOnly", sdkOnlyFields());
        return result;
    }

    private static JSONObject probeOne(Object adasDevice, String name, String sdkFieldName, int fallback)
            throws org.json.JSONException {
        JSONObject entry = new JSONObject();
        entry.put("name", name);
        entry.put("sdkFieldName", sdkFieldName);
        entry.put("fallbackId", fallback);

        // Independently re-run the SAME kind of reflection lookup BydFeatureIds.resolveOrFallback
        // does, rather than comparing resolvedId == fallbackId (they can legitimately be equal
        // when the hardcoded literal happens to be correct).
        Integer sdkValue = resolveFromSdk(sdkFieldName);
        entry.put("resolvedFromSdk", sdkValue != null);
        entry.put("resolvedId", resolveActualConstant(name, fallback));

        if (adasDevice == null) {
            entry.put("readValue", JSONObject.NULL);
            entry.put("readStatus", BydDeviceHelper.ReadStatus.NO_DEVICE.name());
            return entry;
        }
        BydDeviceHelper.GetResult r =
            BydDeviceHelper.callGetSingleWithStatus(adasDevice, resolveActualConstant(name, fallback));
        entry.put("readStatus", r.status.name());
        entry.put("readValue", r.status == BydDeviceHelper.ReadStatus.OK ? (Object) r.value : JSONObject.NULL);
        return entry;
    }

    /** BladeWatch's actual compiled value for {@code BydFeatureIds.<name>} (whatever resolveOrFallback decided). */
    private static int resolveActualConstant(String name, int fallback) {
        try {
            return BydFeatureIds.class.getField(name).getInt(null);
        } catch (Exception e) {
            logger.warn("AdasFieldInventory: BydFeatureIds." + name + " not found -- DECLARED table is stale");
            return fallback;
        }
    }

    /** Independent reflection lookup, mirroring BydFeatureIds.resolveOrFallback's algorithm but never calling it. */
    private static Integer resolveFromSdk(String fieldName) {
        try {
            Class<?> cls = Class.forName(SDK_CLASS);
            if (fieldName.contains(".")) {
                String[] parts = fieldName.split("\\.");
                for (Class<?> inner : cls.getDeclaredClasses()) {
                    if (inner.getSimpleName().equals(parts[0])) {
                        return inner.getField(parts[1]).getInt(null);
                    }
                }
                return null;
            }
            return cls.getField(fieldName).getInt(null);
        } catch (Exception e) {
            return null;
        }
    }

    /**
     * Whether {@code android.hardware.bydauto.BYDAutoFeatureIds} loads at all.
     *
     * <p><b>This is a weaker signal than it looks.</b> BladeWatch ships its own compile-time
     * stub at this exact class name ({@code app/src/main/java/android/hardware/bydauto/BYDAutoFeatureIds.java})
     * with no {@code Adas} inner class. On a real device the boot classloader's real SDK class
     * shadows that stub (higher priority — see CLAUDE.md's "BYD SDK Stub Pattern"), so this
     * being {@code true} there does mean a real SDK is present. In a plain JVM unit test there
     * is no boot classloader, so this is {@code true} for the harmless reason that BladeWatch's
     * OWN stub loaded — it says nothing about ADAS support. Read {@code resolvedFromSdk} per
     * entry (and whether {@code sdkOnly} is non-empty) for the signal that actually means
     * something; do not treat this field alone as "car has ADAS".
     */
    private static boolean sdkClassPresent() {
        try {
            Class.forName(SDK_CLASS);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    /** Every field the real SDK's Adas class declares that BladeWatch never declared at all. */
    private static JSONArray sdkOnlyFields() {
        JSONArray out = new JSONArray();
        try {
            Class<?> cls = Class.forName(SDK_CLASS);
            for (Class<?> inner : cls.getDeclaredClasses()) {
                if (!inner.getSimpleName().equals(SDK_ADAS_INNER_CLASS)) {
                    continue;
                }
                for (Field f : inner.getDeclaredFields()) {
                    String qualified = SDK_ADAS_INNER_CLASS + "." + f.getName();
                    if (DECLARED_SDK_FIELD_NAMES.contains(qualified)) {
                        continue;
                    }
                    try {
                        JSONObject entry = new JSONObject();
                        entry.put("sdkFieldName", qualified);
                        entry.put("id", f.getInt(null));
                        out.put(entry);
                    } catch (Exception ignored) {
                        // Not a readable static int field -- skip it.
                    }
                }
            }
        } catch (Exception e) {
            // sdkClassPresent already reports this; sdkOnly is simply empty on this build.
        }
        return out;
    }
}
