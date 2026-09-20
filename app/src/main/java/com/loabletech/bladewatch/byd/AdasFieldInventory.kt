package net.bladewatch.app.byd

import net.bladewatch.app.logging.DaemonLogger

import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

/**
 * Read-only inventory of BladeWatch's declared `BydFeatureIds.ADAS_*` ids against the
 * real BYD SDK, on demand only (BladeWatch-2pnn.3).
 *
 * `BydFeatureIds.resolveOrFallback` silently substitutes a numeric literal when the
 * real SDK field is absent, and the failure logs at DEBUG (stripped by R8 in release) — so a
 * declared id proves nothing about whether THIS car has that field, and there was previously
 * no way to find out on a shipped build. This object answers that, and nothing else: it never
 * calls a setter, never runs on a timer, and never writes to the vehicle.
 */
object AdasFieldInventory {

    private val logger = DaemonLogger.getInstance("AdasFieldInventory")
    private const val SDK_CLASS = "android.hardware.bydauto.BYDAutoFeatureIds"
    private const val SDK_ADAS_INNER_CLASS = "Adas"

    /** One row of [DECLARED]. */
    private class Declared(
        val name: String,
        val sdkFieldName: String,
        val fallback: Int
    )

    /**
     * One row per `BydFeatureIds.ADAS_*` constant, transcribed by hand from that constant's
     * `resolveOrFallback(sdkFieldName, fallback)` call site (BydFeatureIds.java, ADAS block).
     * This duplication is deliberate — an "independent" check that read its expected mapping
     * from the thing it audits would not be independent of anything. Keep in sync with
     * BydFeatureIds.java; [probe] logs a warning (and the test suite fails loudly, see
     * AdasFieldInventoryTest) if the count drifts.
     */
    private val DECLARED = listOf(
            Declared("ADAS_OMS_DRIVER_DETECTION", "Adas.OMS_DRIVER_DETECTION_RESULT", 834666600),
            Declared("ADAS_OMS_PASSENGER_DETECTION", "Adas.OMS_PASSENGER_DETECTION_RESULT", 834666605),
            Declared("ADAS_SLR_STATUS_SET", "Adas.ADAS_SLR_STATUS_SET", 944767040),
            Declared("ADAS_ISLA_SWITCH_SET", "Adas.ADAS_ISLA_SWITCH_SET", 944767044),
            Declared("ADAS_ISLA_SWITCH_STATUS", "Adas.ADAS_ISLA_SWITCH_STATUS_5R13V", 760217615),
            Declared("ADAS_ISLC_SWITCH_SET", "Adas.ADAS_ISLC_SWITCH_SET", 1324560408),
            Declared("ADAS_ISLC_SWITCH_STATUS", "Adas.ADAS_ISLC_SWITCH_STATUS_5R13V", 760217611),
            Declared("ADAS_ELKA_SWITCH_SET", "Adas.ADAS_ELKA_SWITCH_SET", 944767046),
            Declared("ADAS_ELKA_SWITCH_STATE", "Adas.ADAS_ELKA_SWITCH_STATE", 854589482),
            Declared("ADAS_FCW_LEVEL_SET", "Adas.ADAS_FCW_LEVEL_SET", 1324560420),
            Declared("ADAS_FCW_LEVEL_STATUS", "Adas.ADAS_FCW_LEVEL_STATUS", 327155720),
            Declared("ADAS_RCTA_STATE_SET", "Adas.ADAS_RCTA_STATE_SET", 944766990),
            Declared("ADAS_RTCA_SWITCH_STATE", "Adas.ADAS_RTCA_SWITCH_STATE", 1098907674),
            Declared("ADAS_RTCB_SWITCH_STATE", "Adas.ADAS_RTCB_SWITCH_STATE", 1098907688),
            Declared("ADAS_ECTB_STATE_SET", "Adas.ADAS_ECTB_STATE_SET", 944767006),
            Declared("ADAS_FCTA_SWITCH_STATUS", "Adas.ADAS_FCTA_SWITCH_STATUS", 748683276),
            Declared("ADAS_FCTA_SWITCH_SET", "Adas.ADAS_FCTA_SWITCH_SET", 1324560400),
            Declared("ADAS_FCTB_SWITCH_STATUS", "Adas.ADAS_FCTB_SWITCH_STATUS", 748683278),
            Declared("ADAS_FCTB_SWITCH_SET", "Adas.ADAS_FCTB_SWITCH_SET", 1324560402),
            Declared("ADAS_TLA_SWITCH_SET", "Adas.ADAS_TLA_SWITCH_SET", 1324560410),
            Declared("ADAS_TLA_SWITCH_STATUS", "Adas.ADAS_TLA_SWITCH_STATUS_5R13V", 760217640),
            Declared("ADAS_DOW_STATE_SET", "Adas.ADAS_DOW_STATE_SET", 944766994),
            Declared("ADAS_DOW_SWITCH_STATE", "Adas.ADAS_DOW_SWITCH_STATE", 1098907678),
            Declared("ADAS_RCW_SWITCH_STATE", "Adas.ADAS_RCW_SWITCH_STATE", 1098907676),
            Declared("ADAS_RCW_STATE_SET", "Adas.ADAS_RCW_STATE_SET", 944766992),
            Declared("ADAS_ESP_STATE", "Adas.ADAS_ESP_STATE", 305135676),
            Declared("ADAS_ESP_STATE_SET", "Adas.ADAS_ESP_STATE_SET", 944766984),
            Declared("ADAS_SLW_FUNC_SWITCH_STATE", "Adas.ADAS_SLW_FUNC_SWITCH_STATE", 535834664),
            Declared("ADAS_SLW_FUNC_SWITCH_STATE_SET", "Adas.ADAS_SLW_FUNC_SWITCH_STATE_SET", 850452531),
    )

    private val DECLARED_SDK_FIELD_NAMES: Set<String> =
        DECLARED.mapTo(LinkedHashSet()) { it.sdkFieldName }

    /**
     * Counts `BydFeatureIds`' own `ADAS_*` fields via reflection — the coverage
     * cross-check that [DECLARED] has not silently drifted out of sync with it.
     */
    @JvmStatic
    fun countDeclaredAdasFieldsOnBydFeatureIds(): Int =
        BydFeatureIds::class.java.declaredFields.count { it.name.startsWith("ADAS_") }

    /**
     * Runs the probe. [adasDevice] is the live `BYDAutoADASDevice` (or `null`
     * if unavailable / not yet initialised, e.g. in a JVM unit test) — pass
     * `BydDataCollector.getInstance().getAdasDevice()`.
     */
    @JvmStatic
    @Throws(JSONException::class)
    fun probe(adasDevice: Any?): JSONObject {
        val liveCount = countDeclaredAdasFieldsOnBydFeatureIds()
        if (liveCount != DECLARED.size) {
            logger.warn(
                "AdasFieldInventory.DECLARED has " + DECLARED.size +
                    " entries but BydFeatureIds now declares " + liveCount +
                    " ADAS_* fields -- update DECLARED, this inventory is stale."
            )
        }

        val result = JSONObject()
        result.put("sdkClassPresent", sdkClassPresent())

        val declared = JSONArray()
        for (row in DECLARED) {
            declared.put(probeOne(adasDevice, row))
        }
        result.put("declared", declared)
        result.put("sdkOnly", sdkOnlyFields())
        return result
    }

    @Throws(JSONException::class)
    private fun probeOne(adasDevice: Any?, row: Declared): JSONObject {
        val entry = JSONObject()
        entry.put("name", row.name)
        entry.put("sdkFieldName", row.sdkFieldName)
        entry.put("fallbackId", row.fallback)

        // Independently re-run the SAME kind of reflection lookup BydFeatureIds.resolveOrFallback
        // does, rather than comparing resolvedId == fallbackId (they can legitimately be equal
        // when the hardcoded literal happens to be correct).
        entry.put("resolvedFromSdk", resolveFromSdk(row.sdkFieldName) != null)
        val actual = resolveActualConstant(row.name, row.fallback)
        entry.put("resolvedId", actual)

        if (adasDevice == null) {
            entry.put("readValue", JSONObject.NULL)
            entry.put("readStatus", BydDeviceHelper.ReadStatus.NO_DEVICE.name)
            return entry
        }
        val r = BydDeviceHelper.callGetSingleWithStatus(adasDevice, actual)
        entry.put("readStatus", r.status.name)
        entry.put(
            "readValue",
            if (r.status == BydDeviceHelper.ReadStatus.OK) r.value else JSONObject.NULL
        )
        return entry
    }

    /** BladeWatch's actual compiled value for `BydFeatureIds.<name>` (whatever resolveOrFallback decided). */
    private fun resolveActualConstant(name: String, fallback: Int): Int = try {
        BydFeatureIds::class.java.getField(name).getInt(null)
    } catch (e: Exception) {
        logger.warn("AdasFieldInventory: BydFeatureIds.$name not found -- DECLARED table is stale")
        fallback
    }

    /** Independent reflection lookup, mirroring BydFeatureIds.resolveOrFallback's algorithm but never calling it. */
    private fun resolveFromSdk(fieldName: String): Int? = try {
        val cls = Class.forName(SDK_CLASS)
        if (fieldName.contains(".")) {
            val parts = fieldName.split(".")
            cls.declaredClasses
                .firstOrNull { it.simpleName == parts[0] }
                ?.getField(parts[1])
                ?.getInt(null)
        } else {
            cls.getField(fieldName).getInt(null)
        }
    } catch (e: Exception) {
        null
    }

    /**
     * Whether `android.hardware.bydauto.BYDAutoFeatureIds` loads at all.
     *
     * **This is a weaker signal than it looks.** BladeWatch ships its own compile-time
     * stub at this exact class name (`app/src/main/java/android/hardware/bydauto/BYDAutoFeatureIds.java`)
     * with no `Adas` inner class. On a real device the boot classloader's real SDK class
     * shadows that stub (higher priority — see CLAUDE.md's "BYD SDK Stub Pattern"), so this
     * being `true` there does mean a real SDK is present. In a plain JVM unit test there
     * is no boot classloader, so this is `true` for the harmless reason that BladeWatch's
     * OWN stub loaded — it says nothing about ADAS support. Read `resolvedFromSdk` per
     * entry (and whether `sdkOnly` is non-empty) for the signal that actually means
     * something; do not treat this field alone as "car has ADAS".
     */
    private fun sdkClassPresent(): Boolean = try {
        Class.forName(SDK_CLASS)
        true
    } catch (e: Exception) {
        false
    }

    /** Every field the real SDK's Adas class declares that BladeWatch never declared at all. */
    private fun sdkOnlyFields(): JSONArray {
        val out = JSONArray()
        try {
            val cls = Class.forName(SDK_CLASS)
            for (inner in cls.declaredClasses) {
                if (inner.simpleName != SDK_ADAS_INNER_CLASS) {
                    continue
                }
                for (f in inner.declaredFields) {
                    val qualified = SDK_ADAS_INNER_CLASS + "." + f.name
                    if (DECLARED_SDK_FIELD_NAMES.contains(qualified)) {
                        continue
                    }
                    try {
                        val entry = JSONObject()
                        entry.put("sdkFieldName", qualified)
                        entry.put("id", f.getInt(null))
                        out.put(entry)
                    } catch (ignored: Exception) {
                        // Not a readable static int field -- skip it.
                    }
                }
            }
        } catch (e: Exception) {
            // sdkClassPresent already reports this; sdkOnly is simply empty on this build.
        }
        return out
    }
}
