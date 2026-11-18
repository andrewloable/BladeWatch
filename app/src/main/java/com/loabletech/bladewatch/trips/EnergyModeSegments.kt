package net.bladewatch.app.trips

import org.json.JSONArray
import org.json.JSONObject

/**
 * Splits one trip into EV and HEV segments and totals what each used (BladeWatch-reml.1).
 *
 * A BYD plug-in hybrid drives in EV or HEV energy mode, chosen by the driver or forced by the car
 * at a low battery, and a trip can switch several times. Costing has to follow the mode: electricity
 * only for EV driving, fuel only for HEV driving. So the trip is cut at every mode change and each
 * stretch is measured on its own.
 *
 * Owner decisions this encodes:
 *  - **EV segments record kWh and no litres. HEV segments record litres and NO kWh**, not even as
 *    information: electricity use while the engine drives is not reported at all.
 *  - A reading that goes backwards is a counter reset, not negative consumption: it counts as 0.
 *
 * The mode is the car's raw `getEnergyMode`: 1 = EV, 3 = HEV (see byd/DriveState.kt). Anything
 * else, including "unavailable", is unknown: a segment carries the last known mode forward, and a
 * stretch before the first known mode takes the first mode that arrives. If no mode is EVER known
 * (the HAL never answered) the trip is EV on a car without a fuel system, and on a PHEV it is HEV
 * when the fuel counter rose by more than [FUEL_RISE_LITRES], otherwise EV. That last rule is a
 * planning choice, not a measured one: it is the only reading that can tell the two apart.
 *
 * Pure: no Android types and no singletons, so it runs on the JVM. Thread-safe by [Synchronized]
 * (the sampler thread feeds it while the trip-end path reads it).
 */
class EnergyModeSegments {

    /** One reading of the car. -1 means unavailable for every counter. */
    data class Snapshot(
        val timeMs: Long,
        val modeRaw: Int,
        val odometerKm: Double,
        val elecConKwh: Double,
        val kwhRemaining: Double,
        val fuelConL: Double,
        val gpsDistanceKm: Double,
    )

    /** What each mode used over the whole trip, plus the timeline. */
    data class Result(
        val evKm: Double,
        val evKwh: Double,
        val evSeconds: Long,
        val hevKm: Double,
        val hevLitres: Double,
        val hevSeconds: Long,
        val segmentsJson: String,
    )

    /** What the open trip has used so far: EV kWh and HEV litres. */
    data class Live(val evKwh: Double, val hevLitres: Double)

    private enum class Mode { EV, HEV }

    private var openMode: Mode? = null
    private var openStart: Snapshot? = null
    private var last: Snapshot? = null

    private var evKm = 0.0
    private var evKwh = 0.0
    private var evSeconds = 0L
    private var hevKm = 0.0
    private var hevLitres = 0.0
    private var hevSeconds = 0L

    /** The closed segments, oldest first; capped, the running totals are not. */
    private val timeline = ArrayList<JSONObject>()

    /** Begin tracking at the start of a trip. */
    @Synchronized
    fun start(s: Snapshot) {
        reset()
        openMode = modeOf(s.modeRaw)
        openStart = s
        last = s
    }

    /** Feed the latest reading. Cuts a segment when the mode changes. */
    @Synchronized
    fun onSnapshot(s: Snapshot) {
        if (openStart == null) return
        val m = modeOf(s.modeRaw)
        val cur = openMode
        when {
            // Unknown reading: stay in the current segment (or keep waiting for a first mode).
            m == null -> last = s
            cur == null -> {
                // First known mode: the stretch before it belongs to it.
                openMode = m
                last = s
            }
            m == cur -> last = s
            else -> {
                close(s)
                openMode = m
                openStart = s
                last = s
            }
        }
    }

    /** The trip is over: close the open segment and total everything. */
    @Synchronized
    fun finish(s: Snapshot, isPhev: Boolean): Result {
        if (openStart == null) return Result(0.0, 0.0, 0, 0.0, 0.0, 0, "[]")
        last = s
        if (openMode == null) {
            // The mode was never known. Decide from the fuel counter, on a car that has a tank.
            val fuelDelta = counterDelta(openStart!!.fuelConL, s.fuelConL)
            openMode = if (isPhev && fuelDelta > FUEL_RISE_LITRES) Mode.HEV else Mode.EV
        }
        close(s)
        val result = Result(
            evKm = evKm, evKwh = evKwh, evSeconds = evSeconds,
            hevKm = hevKm, hevLitres = hevLitres, hevSeconds = hevSeconds,
            segmentsJson = JSONArray(timeline).toString(),
        )
        openStart = null
        openMode = null
        last = null
        return result
    }

    /**
     * What the trip has used SO FAR, for a live cost display: the closed segments plus the open one
     * up to the latest reading. Read-only: it closes nothing, so a later [finish] is unaffected. An
     * open segment whose mode is not known yet counts as EV. Null when no trip is tracked.
     */
    @Synchronized
    fun live(): Live? {
        val start = openStart ?: return null
        val end = last ?: return null
        var kwh = evKwh
        var litres = hevLitres
        if ((openMode ?: Mode.EV) == Mode.EV) {
            kwh += segmentKwh(start, end)
        } else {
            litres += counterDelta(start.fuelConL, end.fuelConL)
        }
        return Live(kwh, litres)
    }

    /** Whether a trip is being tracked. */
    @Synchronized
    fun isTracking(): Boolean = openStart != null

    private fun reset() {
        evKm = 0.0; evKwh = 0.0; evSeconds = 0
        hevKm = 0.0; hevLitres = 0.0; hevSeconds = 0
        timeline.clear()
        openMode = null
        openStart = null
        last = null
    }

    /** Close the open segment at [end] and add it to its mode's totals. */
    private fun close(end: Snapshot) {
        val start = openStart ?: return
        val mode = openMode ?: Mode.EV
        val km = segmentKm(start, end)
        val seconds = ((end.timeMs - start.timeMs) / 1000).coerceAtLeast(0)
        val seg = JSONObject()
            .put("mode", mode.name)
            .put("startMs", start.timeMs)
            .put("endMs", end.timeMs)
            .put("km", km)
        if (mode == Mode.EV) {
            val kwh = segmentKwh(start, end)
            evKm += km; evKwh += kwh; evSeconds += seconds
            seg.put("kwh", kwh)
        } else {
            val litres = counterDelta(start.fuelConL, end.fuelConL)
            hevKm += km; hevLitres += litres; hevSeconds += seconds
            seg.put("litres", litres)
        }
        if (timeline.size >= MAX_TIMELINE) timeline.removeAt(0)
        timeline.add(seg)
    }

    /** Odometer delta when both ends are real, else the GPS distance delta, else 0. */
    private fun segmentKm(a: Snapshot, b: Snapshot): Double {
        if (a.odometerKm > 0 && b.odometerKm > a.odometerKm) return b.odometerKm - a.odometerKm
        val gps = b.gpsDistanceKm - a.gpsDistanceKm
        return if (a.gpsDistanceKm >= 0 && b.gpsDistanceKm >= 0 && gps > 0) gps else 0.0
    }

    /**
     * kWh an EV segment drew, in the SAME order of preference as [TripRecord.getEnergyUsedKwh], so a
     * trip that is all EV costs exactly what it cost before the split (a BEV must not change):
     *
     *  1. The NET drop in the pack's remaining energy, which includes regeneration: you only pay
     *     for what the pack ended up short. A pack that ended fuller consumed nothing (0), rather
     *     than falling through to the gross counter.
     *  2. The metered GROSS counter, only where the net figure cannot answer (no remaining-energy
     *     channel at all).
     *
     * (The whole-trip SoC fallback in the manager's energy resolution is not repeated per segment.)
     */
    private fun segmentKwh(a: Snapshot, b: Snapshot): Double {
        val haveNet = a.kwhRemaining > 0 && b.kwhRemaining > 0
        if (haveNet && a.kwhRemaining > b.kwhRemaining) return a.kwhRemaining - b.kwhRemaining
        if (haveNet && b.kwhRemaining > a.kwhRemaining) return 0.0
        if (a.elecConKwh >= 0 && b.elecConKwh >= 0 && b.elecConKwh >= a.elecConKwh) {
            return b.elecConKwh - a.elecConKwh
        }
        return 0.0
    }

    /** A lifetime counter's rise; 0 when either end is missing or it went backwards (a reset). */
    private fun counterDelta(a: Double, b: Double): Double =
        if (a >= 0 && b >= 0 && b >= a) b - a else 0.0

    private fun modeOf(raw: Int): Mode? = when (raw) {
        MODE_EV -> Mode.EV
        MODE_HEV -> Mode.HEV
        else -> null
    }

    /** The state to persist with an open manual trip. */
    @Synchronized
    fun toJson(): JSONObject {
        val j = JSONObject()
            .put("evKm", evKm).put("evKwh", evKwh).put("evSeconds", evSeconds)
            .put("hevKm", hevKm).put("hevLitres", hevLitres).put("hevSeconds", hevSeconds)
            .put("timeline", JSONArray(timeline))
        openStart?.let { j.put("openStart", snapshotJson(it)) }
        last?.let { j.put("last", snapshotJson(it)) }
        openMode?.let { j.put("openMode", it.name) }
        return j
    }

    /** Resume from [toJson]. A missing or malformed state leaves the tracker stopped. */
    @Synchronized
    fun restore(j: JSONObject?) {
        reset()
        if (j == null) return
        try {
            evKm = j.optDouble("evKm", 0.0); evKwh = j.optDouble("evKwh", 0.0)
            evSeconds = j.optLong("evSeconds", 0)
            hevKm = j.optDouble("hevKm", 0.0); hevLitres = j.optDouble("hevLitres", 0.0)
            hevSeconds = j.optLong("hevSeconds", 0)
            j.optJSONArray("timeline")?.let { a ->
                for (i in 0 until a.length()) timeline.add(a.getJSONObject(i))
            }
            openStart = j.optJSONObject("openStart")?.let(::snapshotOf)
            last = j.optJSONObject("last")?.let(::snapshotOf)
            openMode = j.optString("openMode", "").let { n -> Mode.values().firstOrNull { it.name == n } }
        } catch (e: Exception) {
            reset()
        }
    }

    private fun snapshotJson(s: Snapshot) = JSONObject()
        .put("timeMs", s.timeMs).put("modeRaw", s.modeRaw).put("odometerKm", s.odometerKm)
        .put("elecConKwh", s.elecConKwh).put("kwhRemaining", s.kwhRemaining)
        .put("fuelConL", s.fuelConL).put("gpsDistanceKm", s.gpsDistanceKm)

    private fun snapshotOf(j: JSONObject) = Snapshot(
        j.getLong("timeMs"), j.getInt("modeRaw"), j.getDouble("odometerKm"),
        j.getDouble("elecConKwh"), j.getDouble("kwhRemaining"),
        j.getDouble("fuelConL"), j.getDouble("gpsDistanceKm"),
    )

    companion object {
        /** BydDataCollector.getEnergyMode: 1 = EV, 3 = HEV (BladeWatch-os88). */
        const val MODE_EV = 1
        const val MODE_HEV = 3

        /** Litres the fuel counter must rise to call a never-labelled PHEV trip an HEV one. */
        const val FUEL_RISE_LITRES = 0.05

        /** Timeline entries kept; the totals above are never capped. */
        internal const val MAX_TIMELINE = 200
    }
}
