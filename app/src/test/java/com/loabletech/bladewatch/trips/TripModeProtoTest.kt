package net.bladewatch.app.trips

import java.io.File
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-reml.4: the EV/HEV fields on the wire. The Connect layer passes the handler's JSON
 * straight through, so the JSON keys must be the camelCase names protobuf derives from the field
 * names, and the field numbers must be new ones.
 */
class TripModeProtoTest {

    private fun summaryFields(): Map<String, Int> {
        var f = File("../proto/bladewatch/v1/trips.proto")
        if (!f.isFile) f = File("proto/bladewatch/v1/trips.proto")
        assertTrue("could not locate trips.proto", f.isFile)
        val proto = f.readText()
        val start = proto.indexOf("message TripSummary {")
        val body = proto.substring(start, proto.indexOf("\n}", start))
        return Regex("""^\s*(?:repeated\s+)?[A-Za-z0-9_.]+\s+([a-z0-9_]+)\s*=\s*(\d+)\s*;""", RegexOption.MULTILINE)
            .findAll(body).associate { it.groupValues[1] to it.groupValues[2].toInt() }
    }

    private fun camel(n: String) =
        n.split("_").mapIndexed { i, p -> if (i == 0) p else p.replaceFirstChar { it.uppercase() } }.joinToString("")

    @Test
    fun `the split fields take new numbers above the existing ones`() {
        val f = summaryFields()
        assertEquals(24, f["has_fuel_data"])
        assertEquals(25, f["manual"])
        assertEquals(mapOf("ev_km" to 26, "ev_kwh" to 27, "hev_km" to 28, "hev_litres" to 29, "has_energy_split" to 30),
            f.filterKeys { it in setOf("ev_km", "ev_kwh", "hev_km", "hev_litres", "has_energy_split") })
        val dupes = f.values.groupingBy { it }.eachCount().filter { it.value > 1 }
        assertTrue("reused field numbers $dupes", dupes.isEmpty())
    }

    @Test
    fun `the summary json carries every split field under its proto camelCase name`() {
        val keys = TripRecord().toSummaryJson().keys().asSequence().toSet()
        for (name in listOf("ev_km", "ev_kwh", "hev_km", "hev_litres", "has_energy_split")) {
            assertTrue("summary json is missing ${camel(name)}", camel(name) in keys)
        }
    }

    @Test
    fun `has energy split tells a recorded trip from a legacy one`() {
        assertEquals(false, TripRecord().toSummaryJson().getBoolean("hasEnergySplit"))
        assertEquals(true, TripRecord().apply { energySegmentsJson = "[]" }.toSummaryJson().getBoolean("hasEnergySplit"))
    }
}
