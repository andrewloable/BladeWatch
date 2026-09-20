package net.bladewatch.app.telemetry

import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-y78o.5: makes the burned-in telemetry overlay's fields selectable per recording
 * type -- explicitly excluding VIN and location (GPS lat/lon stays on its own separate,
 * unconditional, untouched code path in OverlayBitmapRenderer -- see this issue's close reason
 * for the product decision behind that). OverlayBitmapRenderer itself draws with
 * android.graphics.Canvas/Bitmap, which are compile-only stubs here (no Robolectric, no real
 * device) -- these tests exercise the SELECTION logic (OverlayFieldSelectionResolver, pure
 * org.json, no android.* import) rather than actual pixel output, the same "test the decision,
 * not the drawing" split this project uses throughout (see e.g. VehicleCommandRouter's
 * structural guard tests for the same underlying constraint).
 */
class OverlayFieldSelectionTest {

    @Test
    fun defaultConfig_forEveryRecordingType_resolvesToExactlyTodaysFieldSet() {
        // No "telemetryOverlay" section at all -- an existing install's actual persisted
        // config shape today, before this issue ever ran. Assert field-by-field, not a count.
        for (type in RecordingOverlayType.entries) {
            val resolved = OverlayFieldSelectionResolver.resolve(null, type)
            assertEquals(OverlayField.entries.toSet(), resolved)
            assertTrue(resolved.contains(OverlayField.SPEED))
            assertTrue(resolved.contains(OverlayField.GEAR))
            assertTrue(resolved.contains(OverlayField.TURN_SIGNAL_LEFT))
            assertTrue(resolved.contains(OverlayField.TURN_SIGNAL_RIGHT))
            assertTrue(resolved.contains(OverlayField.BRAKE_PEDAL))
            assertTrue(resolved.contains(OverlayField.ACCEL_PEDAL))
            assertTrue(resolved.contains(OverlayField.SEATBELT_DRIVER))
            assertTrue(resolved.contains(OverlayField.SEATBELT_PASSENGER))
            assertTrue(resolved.contains(OverlayField.TIMESTAMP))
        }
    }

    @Test
    fun deselectingOneField_removesOnlyThatField_leavesOthersUnchanged() {
        var config: JSONObject? = null
        val withoutBrake = OverlayField.entries.toSet() - OverlayField.BRAKE_PEDAL
        config = OverlayFieldSelectionResolver.withSelection(config, RecordingOverlayType.CONTINUOUS, withoutBrake)

        val resolved = OverlayFieldSelectionResolver.resolve(config, RecordingOverlayType.CONTINUOUS)

        assertFalse(resolved.contains(OverlayField.BRAKE_PEDAL))
        for (field in OverlayField.entries) {
            if (field != OverlayField.BRAKE_PEDAL) assertTrue("$field should still be enabled", resolved.contains(field))
        }
    }

    @Test
    fun selectingNoFields_resolvesToAnEmptySet_aLegalRepresentableState() {
        val config = OverlayFieldSelectionResolver.withSelection(null, RecordingOverlayType.CONTINUOUS, emptySet())

        val resolved = OverlayFieldSelectionResolver.resolve(config, RecordingOverlayType.CONTINUOUS)

        assertTrue(resolved.isEmpty())
    }

    @Test
    fun perTypeIndependence_changingSurveillancesSelectionLeavesContinuousUnchanged() {
        var config: JSONObject? = null
        config = OverlayFieldSelectionResolver.withSelection(config, RecordingOverlayType.CONTINUOUS, OverlayField.ALL)
        config = OverlayFieldSelectionResolver.withSelection(
            config,
            RecordingOverlayType.SURVEILLANCE,
            setOf(OverlayField.SPEED),
        )

        val continuous = OverlayFieldSelectionResolver.resolve(config, RecordingOverlayType.CONTINUOUS)
        val surveillance = OverlayFieldSelectionResolver.resolve(config, RecordingOverlayType.SURVEILLANCE)

        assertEquals(OverlayField.ALL, continuous)
        assertEquals(setOf(OverlayField.SPEED), surveillance)
    }

    @Test
    fun noAvailableOverlayField_isNamedForVinOrLocation_reflectedOverTheEnumeration() {
        // Case-insensitive, and derived from the actual enum (not a hardcoded list of what
        // exists today) -- this must fail the moment someone adds such a field, not just today.
        val forbidden = setOf("vin", "location", "latitude", "longitude", "gps", "address", "coordinates")
        for (field in OverlayField.entries) {
            val lower = field.name.lowercase()
            for (bad in forbidden) {
                assertFalse(
                    "OverlayField.${field.name} must not be named/contain '$bad' -- " +
                        "VIN and location are explicitly excluded from this checklist",
                    lower.contains(bad),
                )
            }
        }
    }

    @Test
    fun unknownFieldNameInConfig_isIgnored_notRendered_doesNotThrow() {
        val fields = JSONObject()
        val continuousArray = JSONArray()
        continuousArray.put("SPEED")
        continuousArray.put("not_a_real_field")
        continuousArray.put("vin") // must never resolve to a real field even if hand-typed in
        fields.put("continuous", continuousArray)
        val telemetryOverlay = JSONObject().put("fields", fields)

        val resolved = OverlayFieldSelectionResolver.resolve(telemetryOverlay, RecordingOverlayType.CONTINUOUS)

        assertEquals(setOf(OverlayField.SPEED), resolved)
    }
}
