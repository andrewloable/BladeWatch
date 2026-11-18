package net.bladewatch.app.trips

import net.bladewatch.app.trips.EnergyModeSegments.Snapshot
import org.json.JSONArray
import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** BladeWatch-reml.1: the EV/HEV split of one trip. */
class EnergyModeSegmentsTest {

    private val EPS = 1e-9
    private val EV = 1
    private val HEV = 3
    private val NONE = -1

    private fun snap(
        t: Long,
        mode: Int,
        odo: Double = -1.0,
        elec: Double = -1.0,
        remain: Double = -1.0,
        fuel: Double = -1.0,
        gps: Double = -1.0,
    ) = Snapshot(t * 1000, mode, odo, elec, remain, fuel, gps)

    @Test
    fun `an all EV trip records kWh and no litres`() {
        val s = EnergyModeSegments()
        s.start(snap(0, EV, odo = 100.0, elec = 50.0, fuel = 300.0))
        s.onSnapshot(snap(30, EV, odo = 105.0, elec = 50.7, fuel = 300.0))

        val r = s.finish(snap(60, EV, odo = 110.0, elec = 51.5, fuel = 300.0), isPhev = true)

        assertEquals(10.0, r.evKm, EPS)
        assertEquals(1.5, r.evKwh, EPS)
        assertEquals(60L, r.evSeconds)
        assertEquals(0.0, r.hevKm, EPS)
        assertEquals(0.0, r.hevLitres, EPS)
    }

    /** HEV driving records litres and NO kWh, even though the electric counter moved. */
    @Test
    fun `an all HEV trip records litres and no kWh`() {
        val s = EnergyModeSegments()
        s.start(snap(0, HEV, odo = 100.0, elec = 50.0, fuel = 300.0))

        val r = s.finish(snap(120, HEV, odo = 120.0, elec = 52.0, fuel = 301.2), isPhev = true)

        assertEquals(20.0, r.hevKm, EPS)
        assertEquals(1.2, r.hevLitres, EPS)
        assertEquals(0.0, r.evKwh, EPS, )
        assertEquals(0.0, r.evKm, EPS)
    }

    /** Regression: today the whole trip is costed on both legs. Each mode gets only its own. */
    @Test
    fun `a mixed trip gives each mode only its own distance and counter`() {
        val s = EnergyModeSegments()
        s.start(snap(0, EV, odo = 100.0, elec = 50.0, fuel = 300.0))
        s.onSnapshot(snap(30, EV, odo = 104.0, elec = 50.4, fuel = 300.0))
        s.onSnapshot(snap(60, HEV, odo = 108.0, elec = 50.8, fuel = 300.0))   // switch at km 108

        val r = s.finish(snap(180, HEV, odo = 120.0, elec = 52.0, fuel = 301.0), isPhev = true)

        assertEquals(8.0, r.evKm, EPS)
        assertEquals(0.8, r.evKwh, EPS)
        assertEquals(60L, r.evSeconds)
        assertEquals(12.0, r.hevKm, EPS)
        assertEquals(1.0, r.hevLitres, EPS)
        assertEquals(120L, r.hevSeconds)
        assertEquals(20.0, r.evKm + r.hevKm, EPS)
    }

    @Test
    fun `several switches sum per mode`() {
        val s = EnergyModeSegments()
        s.start(snap(0, EV, odo = 0.0 + 1, elec = 10.0, fuel = 5.0))
        s.onSnapshot(snap(10, HEV, odo = 6.0, elec = 10.5, fuel = 5.0))     // EV 5 km 0.5 kWh
        s.onSnapshot(snap(20, EV, odo = 16.0, elec = 11.0, fuel = 6.0))     // HEV 10 km 1.0 L
        val r = s.finish(snap(30, EV, odo = 19.0, elec = 11.3, fuel = 6.0), isPhev = true)  // EV 3 km 0.3 kWh

        assertEquals(8.0, r.evKm, EPS)
        assertEquals(0.8, r.evKwh, EPS)
        assertEquals(10.0, r.hevKm, EPS)
        assertEquals(1.0, r.hevLitres, EPS)
        assertEquals(3, JSONArray(r.segmentsJson).length())
    }

    @Test
    fun `an unknown reading in the middle keeps the current segment`() {
        val s = EnergyModeSegments()
        s.start(snap(0, EV, odo = 100.0, elec = 50.0))
        s.onSnapshot(snap(10, NONE, odo = 102.0, elec = 50.2))
        s.onSnapshot(snap(20, NONE, odo = 104.0, elec = 50.4))
        s.onSnapshot(snap(30, EV, odo = 106.0, elec = 50.6))

        val r = s.finish(snap(40, EV, odo = 108.0, elec = 50.8), isPhev = true)

        assertEquals(8.0, r.evKm, EPS)
        assertEquals(0.8, r.evKwh, EPS)
        assertEquals(1, JSONArray(r.segmentsJson).length(), "one segment, not split by the gap")
    }

    private fun assertEquals(expected: Int, actual: Int, message: String) =
        org.junit.Assert.assertEquals(message, expected, actual)

    @Test
    fun `an unknown start is assigned to the first known mode`() {
        val s = EnergyModeSegments()
        s.start(snap(0, NONE, odo = 100.0, fuel = 300.0))
        s.onSnapshot(snap(10, NONE, odo = 103.0, fuel = 300.2))
        s.onSnapshot(snap(20, HEV, odo = 106.0, fuel = 300.4))

        val r = s.finish(snap(30, HEV, odo = 110.0, fuel = 300.9), isPhev = true)

        assertEquals(10.0, r.hevKm, EPS)
        assertEquals(0.9, r.hevLitres, 1e-9)
        assertEquals(0.0, r.evKm, EPS)
    }

    @Test
    fun `a mode never known on a PHEV that burned fuel is HEV, on one that did not it is EV`() {
        val burned = EnergyModeSegments()
        burned.start(snap(0, NONE, odo = 0.0 + 1, elec = 10.0, fuel = 100.0))
        val h = burned.finish(snap(60, NONE, odo = 11.0, elec = 10.4, fuel = 100.5), isPhev = true)
        assertEquals(10.0, h.hevKm, EPS)
        assertEquals(0.5, h.hevLitres, EPS)
        assertEquals(0.0, h.evKwh, EPS)

        val quiet = EnergyModeSegments()
        quiet.start(snap(0, NONE, odo = 1.0, elec = 10.0, fuel = 100.0))
        val e = quiet.finish(snap(60, NONE, odo = 11.0, elec = 10.4, fuel = 100.04), isPhev = true)
        assertEquals(10.0, e.evKm, EPS)
        assertEquals(0.4, e.evKwh, EPS)
        assertEquals(0.0, e.hevLitres, EPS)
    }

    @Test
    fun `a mode never known on a car without a tank is EV even if a fuel counter moved`() {
        val s = EnergyModeSegments()
        s.start(snap(0, NONE, odo = 1.0, elec = 10.0, fuel = 100.0))

        val r = s.finish(snap(60, NONE, odo = 11.0, elec = 10.4, fuel = 105.0), isPhev = false)

        assertEquals(10.0, r.evKm, EPS)
        assertEquals(0.0, r.hevKm, EPS)
    }

    @Test
    fun `a counter that went backwards counts as zero`() {
        val ev = EnergyModeSegments()
        ev.start(snap(0, EV, odo = 1.0, elec = 500.0, remain = 20.0))
        // The metered counter reset; the pack still says 1.5 kWh went out.
        val r = ev.finish(snap(60, EV, odo = 6.0, elec = 3.0, remain = 18.5), isPhev = true)
        assertEquals(1.5, r.evKwh, EPS)

        val hev = EnergyModeSegments()
        hev.start(snap(0, HEV, odo = 1.0, fuel = 900.0))
        val h = hev.finish(snap(60, HEV, odo = 6.0, fuel = 2.0), isPhev = true)
        assertEquals(0.0, h.hevLitres, EPS)
        assertEquals(5.0, h.hevKm, EPS)
    }

    @Test
    fun `without an odometer the GPS distance is used`() {
        val s = EnergyModeSegments()
        s.start(snap(0, EV, gps = 0.0, elec = 1.0))

        val r = s.finish(snap(60, EV, gps = 3.5, elec = 1.4), isPhev = true)

        assertEquals(3.5, r.evKm, EPS)
    }

    @Test
    fun `without the metered counter the pack's remaining energy is used`() {
        val s = EnergyModeSegments()
        s.start(snap(0, EV, odo = 1.0, remain = 20.0))

        val r = s.finish(snap(60, EV, odo = 6.0, remain = 18.5), isPhev = false)

        assertEquals(1.5, r.evKwh, EPS)
    }

    @Test
    fun `a state saved mid trip finishes exactly like one that was never saved`() {
        fun run(saveAndRestore: Boolean): EnergyModeSegments.Result {
            var s = EnergyModeSegments()
            s.start(snap(0, EV, odo = 100.0, elec = 50.0, fuel = 300.0))
            s.onSnapshot(snap(30, EV, odo = 104.0, elec = 50.4, fuel = 300.0))
            s.onSnapshot(snap(60, HEV, odo = 108.0, elec = 50.8, fuel = 300.0))
            if (saveAndRestore) {
                val saved = JSONObject(s.toJson().toString())
                s = EnergyModeSegments()
                s.restore(saved)
                assertTrue(s.isTracking())
            }
            s.onSnapshot(snap(90, HEV, odo = 114.0, elec = 51.0, fuel = 300.5))
            return s.finish(snap(120, HEV, odo = 120.0, elec = 52.0, fuel = 301.0), isPhev = true)
        }

        val plain = run(false)
        val restored = run(true)

        assertEquals(plain, restored)
        assertEquals(8.0, restored.evKm, EPS)
        assertEquals(12.0, restored.hevKm, EPS)
    }

    @Test
    fun `restore of nothing or garbage leaves the tracker stopped`() {
        val s = EnergyModeSegments()
        s.restore(null)
        assertFalse(s.isTracking())
        s.restore(JSONObject().put("openStart", JSONObject().put("timeMs", 1)))
        assertFalse(s.isTracking())
    }

    @Test
    fun `finish without a start is empty and finish stops the tracker`() {
        val s = EnergyModeSegments()
        assertEquals(0.0, s.finish(snap(1, EV), isPhev = true).evKm, EPS)

        s.start(snap(0, EV, odo = 1.0))
        assertTrue(s.isTracking())
        s.finish(snap(10, EV, odo = 2.0), isPhev = true)
        assertFalse(s.isTracking())
    }

    @Test
    fun `the timeline is capped but the totals are not`() {
        val s = EnergyModeSegments()
        s.start(snap(0, EV, odo = 0.0 + 1, elec = 0.0))
        var odo = 1.0
        var elec = 0.0
        for (i in 1..(EnergyModeSegments.MAX_TIMELINE + 50)) {
            odo += 1.0
            elec += 0.1
            s.onSnapshot(snap(i.toLong() * 10, if (i % 2 == 0) EV else HEV, odo = odo, elec = elec, fuel = 0.0))
        }
        val r = s.finish(snap(100_000, EV, odo = odo + 1, elec = elec + 0.1), isPhev = true)

        assertEquals(EnergyModeSegments.MAX_TIMELINE, JSONArray(r.segmentsJson).length())
        assertEquals((EnergyModeSegments.MAX_TIMELINE + 51).toDouble(), r.evKm + r.hevKm, 1e-6)
    }

    /**
     * Regression (review of reml.1): the net remaining-energy drop must win over the gross metered
     * counter, exactly as TripRecord.getEnergyUsedKwh does, or an all-EV trip would no longer cost
     * what it used to.
     */
    @Test
    fun `net remaining energy wins over the gross metered counter, like getEnergyUsedKwh`() {
        val s = EnergyModeSegments()
        s.start(snap(0, EV, odo = 1.0, elec = 10.0, remain = 20.0))   // regen trip: gross 1.0, net 0.8

        val r = s.finish(snap(60, EV, odo = 6.0, elec = 11.0, remain = 19.2), isPhev = false)

        assertEquals(0.8, r.evKwh, EPS)
    }

    @Test
    fun `a pack that ended fuller consumed nothing, not the gross counter`() {
        val s = EnergyModeSegments()
        s.start(snap(0, EV, odo = 1.0, elec = 10.0, remain = 20.0))

        val r = s.finish(snap(60, EV, odo = 6.0, elec = 10.6, remain = 20.4), isPhev = false)

        assertEquals(0.0, r.evKwh, EPS)
    }

    /** The per-segment kWh of an all-EV trip equals the trip-level figure the record computes. */
    @Test
    fun `an all EV trip matches TripRecord getEnergyUsedKwh`() {
        for ((remain0, remain1, elec0, elec1) in listOf(
            listOf(20.0, 18.5, 10.0, 11.9),      // net drop
            listOf(20.0, 20.4, 10.0, 10.6),      // regen: nothing
            listOf(-1.0, -1.0, 10.0, 11.2),      // no remaining-energy channel: metered
            listOf(20.0, 20.0, 10.0, 10.3),      // equal: below resolution, metered
        )) {
            val trip = TripRecord().apply {
                kwhStart = remain0.coerceAtLeast(0.0); kwhEnd = remain1.coerceAtLeast(0.0)
                elecConStart = elec0; elecConEnd = elec1
            }
            val s = EnergyModeSegments()
            s.start(snap(0, EV, odo = 1.0, elec = elec0, remain = remain0))
            val r = s.finish(snap(60, EV, odo = 6.0, elec = elec1, remain = remain1), isPhev = false)

            assertEquals("remain $remain0->$remain1 elec $elec0->$elec1", trip.getEnergyUsedKwh(), r.evKwh, EPS)
        }
    }

    // ── live(): what the trip has used so far (BladeWatch-reml live cost) ──

    @Test
    fun `live is null when nothing is tracked`() {
        assertEquals(null, EnergyModeSegments().live())
    }

    @Test
    fun `live counts EV so far as kWh and no litres`() {
        val s = EnergyModeSegments()
        s.start(snap(0, EV, odo = 100.0, elec = 50.0, fuel = 300.0))
        s.onSnapshot(snap(30, EV, odo = 104.0, elec = 50.6, fuel = 300.0))

        val l = s.live()!!

        assertEquals(0.6, l.evKwh, EPS)
        assertEquals(0.0, l.hevLitres, EPS)
    }

    @Test
    fun `live counts HEV so far as litres and no kWh`() {
        val s = EnergyModeSegments()
        s.start(snap(0, HEV, odo = 100.0, elec = 50.0, fuel = 300.0))
        s.onSnapshot(snap(30, HEV, odo = 104.0, elec = 50.6, fuel = 300.4))

        val l = s.live()!!

        assertEquals(0.0, l.evKwh, EPS)
        assertEquals(0.4, l.hevLitres, EPS)
    }

    @Test
    fun `live in a mixed trip is the closed segments plus the open one`() {
        val s = EnergyModeSegments()
        s.start(snap(0, EV, odo = 100.0, elec = 50.0, fuel = 300.0))
        s.onSnapshot(snap(60, HEV, odo = 108.0, elec = 50.8, fuel = 300.0))   // EV closed: 0.8 kWh
        s.onSnapshot(snap(90, HEV, odo = 112.0, elec = 51.1, fuel = 300.5))   // HEV open: 0.5 L

        val l = s.live()!!

        assertEquals(0.8, l.evKwh, EPS)
        assertEquals(0.5, l.hevLitres, EPS)
    }

    /** Regression for the contract: reading the live figure must not change the final one. */
    @Test
    fun `live leaves the tracker untouched so a later finish is unchanged`() {
        fun run(peek: Boolean): EnergyModeSegments.Result {
            val s = EnergyModeSegments()
            s.start(snap(0, EV, odo = 100.0, elec = 50.0, fuel = 300.0))
            s.onSnapshot(snap(60, HEV, odo = 108.0, elec = 50.8, fuel = 300.0))
            s.onSnapshot(snap(90, HEV, odo = 112.0, elec = 51.1, fuel = 300.5))
            if (peek) { s.live(); s.live() }
            return s.finish(snap(120, HEV, odo = 120.0, elec = 52.0, fuel = 301.0), isPhev = true)
        }

        assertEquals(run(false), run(true))
    }

    @Test
    fun `live treats a mode not yet known as EV`() {
        val s = EnergyModeSegments()
        s.start(snap(0, NONE, odo = 1.0, elec = 10.0, fuel = 100.0))
        s.onSnapshot(snap(30, NONE, odo = 3.0, elec = 10.3, fuel = 100.2))

        val l = s.live()!!

        assertEquals(0.3, l.evKwh, EPS)
        assertEquals(0.0, l.hevLitres, EPS)
    }
}

