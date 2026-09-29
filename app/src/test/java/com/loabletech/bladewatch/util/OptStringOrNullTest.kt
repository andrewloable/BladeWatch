package net.bladewatch.app.util

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

/**
 * [optStringOrNull] replaced 19 `optString(name, null)` calls, which passed null where the
 * Android SDK declares the fallback non-null (a compiler warning). It must return what
 * Android's `optString(name, null)` returned, so request parsing on the car is unchanged.
 */
class OptStringOrNullTest {

    @Test
    fun `an absent key is null`() {
        assertNull(JSONObject("{}").optStringOrNull("id"))
    }

    @Test
    fun `a string is returned as is`() {
        assertEquals("z1", JSONObject("""{"id":"z1"}""").optStringOrNull("id"))
    }

    @Test
    fun `a non-string value is its string form, as on Android`() {
        assertEquals("5", JSONObject("""{"id":5}""").optStringOrNull("id"))
        assertEquals("true", JSONObject("""{"id":true}""").optStringOrNull("id"))
    }

    @Test
    fun `an explicit JSON null reads as the text null, as Android's optString did`() {
        assertEquals("null", JSONObject("""{"id":null}""").optStringOrNull("id"))
    }
}
