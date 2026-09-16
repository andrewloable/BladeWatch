package net.bladewatch.app.trips

import java.io.File
import java.nio.charset.StandardCharsets
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-fpdz.8: the trip API contract.
 *
 * The daemon's Connect layer passes the handler's JSON straight through, so what
 * [TripRecord.toJson] and [TripRecord.toSummaryJson] emit IS the wire response. Two things
 * therefore have to hold, and only one of them is about the new feature:
 *
 *  1. Every field a shipped client already reads is still present, with the same name. This is
 *     the one way this task could break the Flutter UI or a remote browser client.
 *  2. The proto carries the new fields at NEW numbers, so a client built against the old
 *     schema still parses these messages.
 */
class TripApiContractTest {

    private companion object {
        const val EPS = 1e-9

        /**
         * Every key the trip detail response emitted BEFORE this epic. Hard-coded rather than
         * derived, because deriving it from the current code would make the test agree with
         * whatever the code happens to do — which is the opposite of a contract test.
         */
        val PRE_EPIC_DETAIL_KEYS = setOf(
            "id", "startTime", "endTime", "distanceKm", "durationSeconds", "avgSpeedKmh",
            "maxSpeedKmh", "socStart", "socEnd", "kwhStart", "kwhEnd", "energyUsedKwh",
            "efficiencySocPerKm", "energyPerKm", "electricityRate", "currency", "tripCost",
            "kinematicState", "gradientProfile", "elevationGainM", "elevationLossM",
            "avgGradientPercent", "startLat", "startLon", "endLat", "endLon", "extTempC",
            "anticipationScore", "smoothnessScore", "speedDisciplineScore", "efficiencyScore",
            "consistencyScore", "overallScore", "microMomentsJson", "telemetryFilePath",
        )

        val PRE_EPIC_SUMMARY_KEYS = PRE_EPIC_DETAIL_KEYS - setOf(
            "microMomentsJson", "telemetryFilePath",
        )
    }

    private fun protoSource(): String {
        var f = File("../proto/bladewatch/v1/trips.proto")
        if (!f.isFile) f = File("proto/bladewatch/v1/trips.proto")
        assertTrue("could not locate trips.proto from ${File(".").absolutePath}", f.isFile)
        return String(f.readBytes(), StandardCharsets.UTF_8)
    }

    // ── 1. nothing that shipped may disappear ──

    @Test
    fun `every pre-epic detail field is still emitted`() {
        val keys = TripRecord().toJson().keys().asSequence().toSet()
        val missing = PRE_EPIC_DETAIL_KEYS - keys
        assertTrue("the trip detail response dropped fields a shipped client reads: $missing",
            missing.isEmpty())
    }

    @Test
    fun `every pre-epic summary field is still emitted`() {
        val keys = TripRecord().toSummaryJson().keys().asSequence().toSet()
        val missing = PRE_EPIC_SUMMARY_KEYS - keys
        assertTrue("the trip list response dropped fields a shipped client reads: $missing",
            missing.isEmpty())
    }

    // ── 2. the new fields ──

    @Test
    fun `detail exposes the full fuel leg including the raw counters`() {
        val j = TripRecord().apply {
            fuelConStart = 1200.0
            fuelConEnd = 1203.5
            fuelPctStart = 80.0
            fuelPctEnd = 74.5
            elecConStart = 5000.0
            elecConEnd = 5008.4
            litresUsed = 3.5
            fuelPricePerL = 1.80
            fuelCost = 6.30
            electricCost = 2.10
        }.toJson()

        for (k in listOf("litresUsed", "fuelCost", "electricCost", "fuelPricePerL",
                "fuelPctStart", "fuelPctEnd", "fuelConStart", "fuelConEnd",
                "elecConStart", "elecConEnd", "hasFuelData")) {
            assertTrue("detail must expose $k", j.has(k))
        }
        assertEquals(3.5, j.getDouble("litresUsed"), EPS)
        assertTrue(j.getBoolean("hasFuelData"))
    }

    @Test
    fun `summary exposes the costs but not the raw counters`() {
        val j = TripRecord().apply {
            fuelConStart = 1200.0
            fuelConEnd = 1203.5
            litresUsed = 3.5
            fuelCost = 6.30
        }.toSummaryJson()

        assertTrue(j.has("litresUsed"))
        assertTrue(j.has("fuelCost"))
        assertTrue(j.has("hasFuelData"))
        assertFalse("a list row must not carry lifetime counters", j.has("fuelConStart"))
        assertFalse("a list row must not carry lifetime counters", j.has("elecConStart"))
    }

    // ── 3. the BEV representation is one consistent shape ──

    /**
     * A BEV emits the fuel keys as 0, never null and never absent — one shape for every trip,
     * so a client needs no special case. `hasFuelData` is what separates "no fuel system" from
     * "a PHEV that burned nothing".
     */
    @Test
    fun `a bev emits zeroes rather than nulls or omissions`() {
        val j = TripRecord().apply { distanceKm = 10.0 }.toJson()

        assertEquals(0.0, j.getDouble("litresUsed"), EPS)
        assertEquals(0.0, j.getDouble("fuelCost"), EPS)
        assertEquals(0.0, j.getDouble("electricCost"), EPS)
        assertFalse("a BEV has no fuel leg", j.getBoolean("hasFuelData"))
        assertFalse("must not be null", j.isNull("litresUsed"))
    }

    /**
     * THE distinction the flag exists for. Both trips report 0 litres; only one of them has a
     * fuel system. A client checking `litresUsed > 0` cannot tell them apart.
     */
    @Test
    fun `a phev that burned nothing is distinguishable from a bev`() {
        val bev = TripRecord().toJson()
        val phevOnBattery = TripRecord().apply {
            fuelConStart = 1200.0
            fuelConEnd = 1200.0
            litresUsed = 0.0
        }.toJson()

        assertEquals("both report zero litres",
            bev.getDouble("litresUsed"), phevOnBattery.getDouble("litresUsed"), EPS)
        assertFalse(bev.getBoolean("hasFuelData"))
        assertTrue("the PHEV's counter WAS read; its answer was zero",
            phevOnBattery.getBoolean("hasFuelData"))
    }

    // ── 4. wire compatibility ──

    /**
     * Parse one proto message body into field name -> field number.
     *
     * Deliberately a real parse rather than a substring search. The first version of this test
     * asserted only that `trip_cost = 11;` still APPEARED, which stays true when a new field
     * also claims 11 — so it passed against a duplicate-number mutation (measured). Wire
     * breaks are about the number space, so the test has to read the number space.
     */
    private fun fieldsOf(message: String): Map<String, Int> {
        val proto = protoSource()
        val start = proto.indexOf("message $message {")
        assertTrue("proto must declare message $message", start >= 0)
        val body = proto.substring(start, proto.indexOf("\n}", start))
        return Regex("""^\s*(?:repeated\s+)?[A-Za-z0-9_.]+\s+([a-z0-9_]+)\s*=\s*(\d+)\s*;""",
            RegexOption.MULTILINE)
            .findAll(body)
            .associate { it.groupValues[1] to it.groupValues[2].toInt() }
    }

    /**
     * New proto fields must take NEW numbers. Reusing a number silently reinterprets an
     * existing field for any client built against the old schema — the classic protobuf wire
     * break, invisible at compile time on both sides.
     */
    @Test
    fun `new proto fields use new numbers and do not disturb existing ones`() {
        val summary = fieldsOf("TripSummary")
        val detail = fieldsOf("TripDetail")

        // Field numbers must be unique WITHIN a message. This is the assertion that catches a
        // reused number.
        for ((name, fields) in listOf("TripSummary" to summary, "TripDetail" to detail)) {
            val dupes = fields.values.groupingBy { it }.eachCount().filter { it.value > 1 }
            assertTrue("$name reuses field number(s) ${dupes.keys} — that is a wire break",
                dupes.isEmpty())
        }

        // The pre-existing numbering must be untouched.
        for ((field, number) in mapOf(
            "id" to 1, "distance_km" to 4, "energy_per_km" to 10, "trip_cost" to 11,
            "currency" to 12, "ext_temp_c" to 20,
        )) {
            assertEquals("TripSummary.$field must still be field number $number",
                number, summary[field])
        }

        // And the new ones must sit strictly above the old high-water mark.
        for (field in listOf("litres_used", "fuel_cost", "electric_cost", "has_fuel_data")) {
            val n = summary[field]
            assertTrue("TripSummary must declare $field", n != null)
            assertTrue("TripSummary.$field = $n must be above the pre-epic maximum of 20",
                n!! > 20)
        }
        for (field in listOf("fuel_pct_start", "fuel_pct_end", "fuel_con_start", "fuel_con_end",
                "fuel_price_per_l", "elec_con_start", "elec_con_end")) {
            val n = detail[field]
            assertTrue("TripDetail must declare $field", n != null)
            assertTrue("TripDetail.$field = $n must be above the pre-epic maximum of 10",
                n!! > 10)
        }
    }

    /**
     * The drivetrain flag the settings UI gates on.
     *
     * It rides on TripConfig rather than a config-only message because the settings screen is
     * the one place that needs it, and it must not disturb the four pre-epic config fields.
     *
     * The JSON key matters as much as the number: the Connect layer passes the handler's JSON
     * straight through, so `TripApiHandler.handleGetConfig` has to emit exactly the camelCase
     * name protobuf derives from `is_phev`. Get that wrong and both UIs silently see `false`
     * on every car — which looks like "every vehicle is a BEV" rather than like a bug.
     */
    @Test
    fun `the drivetrain flag is a new config field and its json key matches`() {
        val config = fieldsOf("TripConfig")

        val dupes = config.values.groupingBy { it }.eachCount().filter { it.value > 1 }
        assertTrue("TripConfig reuses field number(s) ${dupes.keys} — that is a wire break",
            dupes.isEmpty())

        for ((field, number) in mapOf(
            "enabled" to 1, "electricity_rate" to 2, "currency" to 3, "distance_unit" to 4,
        )) {
            assertEquals("TripConfig.$field must still be field number $number",
                number, config[field])
        }

        val n = config["is_phev"]
        assertTrue("TripConfig must declare is_phev", n != null)
        assertTrue("TripConfig.is_phev = $n must be above the pre-epic maximum of 4", n!! > 4)

        // protobuf's json_name for `is_phev` is `isPhev`; the handler must emit that spelling.
        val handler = handlerSource()
        assertTrue(
            "TripApiHandler.handleGetConfig must put(\"isPhev\", ...) so the UIs can read it",
            handler.contains("put(\"isPhev\""),
        )
    }

    /** The handler source, read as data. Declared as a test input in app/build.gradle.kts. */
    private fun handlerSource(): String {
        var f = File("src/main/java/com/loabletech/bladewatch/trips/TripApiHandler.kt")
        if (!f.isFile) f = File("app/src/main/java/com/loabletech/bladewatch/trips/TripApiHandler.kt")
        assertTrue("could not locate TripApiHandler.kt from ${File(".").absolutePath}", f.isFile)
        return f.readText(StandardCharsets.UTF_8)
    }

    /** The config message must carry the fuel price, or no client can set it. */
    @Test
    fun `proto trip config exposes the fuel price`() {
        assertTrue("TripConfig must expose fuel_price_per_l",
            protoSource().contains("fuel_price_per_l = 5;"))
    }
}
