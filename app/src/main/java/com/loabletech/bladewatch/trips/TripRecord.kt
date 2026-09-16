package net.bladewatch.app.trips

import net.bladewatch.app.logging.DaemonLogger
import org.json.JSONObject

/**
 * Mutable record representing a trip from start to finalization. Contains all trip summary
 * fields, Driving DNA scores, and references to micro-moments JSON and telemetry file.
 *
 * **Sentinel convention for the observed counters** (fuelPct, fuelCon, elecCon): **-1 means
 * the reading was unavailable; 0 is a legitimate measurement.** The two are not
 * interchangeable and must never be collapsed. A PHEV leg driven entirely on the engine
 * really did draw 0 kWh from the pack, and a PHEV leg driven entirely on electricity really
 * did burn 0 litres — treating either as "no data" makes the trip cost silently wrong rather
 * than visibly missing, which is the harder failure to notice and the harder one to correct
 * after the fact.
 *
 * The computed fields (litresUsed, fuelCost, electricCost, fuelPricePerL) default to 0
 * because they are sums, not observations: nothing measured is nothing spent.
 *
 * **Java interop.** Every field carries [JvmField] and that is load-bearing, not decoration.
 * `TripDatabase`, `TripDetector`, `TripAnalyticsManager` and `TripApiHandler` are all Java and
 * all assign these directly (`trip.litresUsed = x`). Without [JvmField] Kotlin would emit
 * private fields behind getters and every one of those call sites would stop compiling.
 */
class TripRecord {

    @JvmField var id: Long = 0                  // Auto-increment PK
    @JvmField var startTime: Long = 0           // Epoch ms
    @JvmField var endTime: Long = 0             // Epoch ms
    @JvmField var distanceKm: Double = 0.0      // Odometer delta
    @JvmField var durationSeconds: Int = 0
    @JvmField var avgSpeedKmh: Double = 0.0
    @JvmField var maxSpeedKmh: Int = 0
    @JvmField var socStart: Double = 0.0        // %
    @JvmField var socEnd: Double = 0.0          // %
    @JvmField var kwhStart: Double = 0.0        // Remaining kWh at trip start (from BMS)
    @JvmField var kwhEnd: Double = 0.0          // Remaining kWh at trip end (from BMS)
    @JvmField var efficiencySocPerKm: Double = 0.0  // SoC% / km (legacy)
    @JvmField var energyPerKm: Double = 0.0     // kWh / km (from BMS kWh readings)
    @JvmField var electricityRate: Double = 0.0 // Cost per kWh at time of trip
    /**
     * Display currency, snapshotted at cost time so a trip keeps the currency it was priced
     * in — there is no conversion, by design.
     *
     * Normally an ISO 4217 code ("USD", "PHP"); may be a bare symbol on configs predating the
     * currency picker. Renderers format a known code via ICU and fall back to prefix display
     * for anything else, so both shapes keep working.
     */
    @JvmField var currency: String? = null

    /**
     * Total trip cost: electricCost + fuelCost. On a BEV fuelCost is 0, so this is unchanged
     * from the electric-only figure it has always been.
     */
    @JvmField var tripCost: Double = 0.0

    // ── PHEV fuel leg (BladeWatch-fpdz). -1 = unavailable, 0 = a real reading. ──
    @JvmField var fuelPctStart: Double = -1.0   // Tank level % at trip start, 0-100
    @JvmField var fuelPctEnd: Double = -1.0     // Tank level % at trip end, 0-100
    @JvmField var fuelConStart: Double = -1.0   // Lifetime fuel counter (litres) at start
    @JvmField var fuelConEnd: Double = -1.0     // Lifetime fuel counter (litres) at end
    @JvmField var litresUsed: Double = 0.0      // Litres burned this trip (counter delta)
    @JvmField var fuelPricePerL: Double = 0.0   // Price per litre snapshot at trip end
    @JvmField var fuelCost: Double = 0.0        // litresUsed x fuelPricePerL
    @JvmField var electricCost: Double = 0.0    // energyUsed x electricityRate

    // Lifetime electricity counter. Not gated on drivetrain — it is meaningful on a BEV too,
    // and it is what lets a trip shorter than SoC resolution report a real figure instead of
    // a flat zero. Consumed by the metered tier of getEnergyUsedKwh (BladeWatch-fpdz.5).
    @JvmField var elecConStart: Double = -1.0   // Lifetime electricity counter (kWh) at start
    @JvmField var elecConEnd: Double = -1.0     // Lifetime electricity counter (kWh) at end

    @JvmField var kinematicState: String? = null   // HEAVY_GRIDLOCK, URBAN_FLOW, HIGHWAY_CRUISING
    @JvmField var gradientProfile: String? = null  // FLAT, HILLY, MOUNTAIN
    @JvmField var elevationGainM: Double = 0.0     // Cumulative meters gained (uphill)
    @JvmField var elevationLossM: Double = 0.0     // Cumulative meters lost (downhill)
    @JvmField var avgGradientPercent: Double = 0.0 // Average gradient over the trip
    @JvmField var startLat: Double = 0.0
    @JvmField var startLon: Double = 0.0
    @JvmField var endLat: Double = 0.0
    @JvmField var endLon: Double = 0.0
    @JvmField var extTempC: Int = 0

    // Driving DNA scores (0-100)
    @JvmField var anticipationScore: Int = 0
    @JvmField var smoothnessScore: Int = 0
    @JvmField var speedDisciplineScore: Int = 0
    @JvmField var efficiencyScore: Int = 0
    @JvmField var consistencyScore: Int = 0

    @JvmField var microMomentsJson: String? = null   // JSON blob
    @JvmField var telemetryFilePath: String? = null  // Path to .jsonl.gz
    @JvmField var routeId: Long = -1                 // Route cluster ID for similar-trip lookups

    /** Overall Driving DNA score: the mean of the five axis scores. */
    fun getOverallScore(): Int = Math.round(
        (anticipationScore + smoothnessScore + speedDisciplineScore
            + efficiencyScore + consistencyScore) / 5.0
    ).toInt()

    /**
     * Gross electricity drawn this trip, from the lifetime counter delta.
     *
     * A flat counter legitimately returns 0 — a PHEV leg driven entirely on the engine drew
     * nothing from the pack — which is a true reading, not a missing one. Callers distinguish
     * the two via [hasMeteredEnergy].
     */
    fun getMeteredEnergyKwh(): Double =
        if (elecConStart >= 0 && elecConEnd >= 0 && elecConEnd >= elecConStart) {
            elecConEnd - elecConStart
        } else {
            0.0
        }

    /**
     * Whether both ends of the lifetime electricity counter were captured and are
     * self-consistent — i.e. [getMeteredEnergyKwh] is a real measurement (possibly a true 0)
     * rather than "no data". Callers use this to avoid falling through to a coarser tier when
     * the meter legitimately says the pack supplied nothing.
     */
    fun hasMeteredEnergy(): Boolean =
        elecConStart >= 0 && elecConEnd >= 0 && elecConEnd >= elecConStart

    /**
     * Energy consumed this trip, in kWh, for cost and efficiency. Always non-negative.
     *
     * **The remaining-energy delta wins whenever it can answer.** It is NET of regeneration,
     * which is the quantity cost must be based on: you only buy back the energy the pack
     * actually ended up short. The metered counter is GROSS draw, so preferring it would
     * inflate the cost of a regen-heavy trip and put stored history on two different axes
     * depending on which channels a trim happens to expose.
     *
     * The metered counter is therefore used only where the net delta CANNOT answer — which is
     * precisely the case that tier exists for. Remaining energy is derived from a
     * 1%-resolution SoC (~0.6 kWh, several km of driving), so on a short trip it reports a
     * flat 0 while the accumulator still advances. Trading a little regen accuracy for a real
     * number beats reporting zero, and on a trip that short the regen component is negligible.
     */
    fun getEnergyUsedKwh(): Double {
        val haveNet = kwhStart > 0 && kwhEnd > 0
        // Tier 1 — net remaining-energy delta (regen-inclusive).
        if (haveNet && kwhStart > kwhEnd) {
            return kwhStart - kwhEnd
        }
        // A pack that ended strictly FULLER than it started regenerated more than it drew, so
        // on balance it consumed nothing. Report 0 rather than falling through to the gross
        // counter: billing energy that was put back would charge for a trip that cost nothing
        // and would leave this trip's cost and its efficiency score on opposite signs.
        if (haveNet && kwhEnd > kwhStart) {
            return 0.0
        }
        // Tier 2 — metered gross draw. Reached when the net delta cannot resolve the trip:
        // either there is no remaining-energy channel at all, or (the important case) the two
        // readings are EQUAL. Equal is not "consumed nothing" — it is "below the resolution of
        // this channel", because remaining energy is derived from an integer SoC whose
        // smallest step is several km of driving. That is precisely the short trip this tier
        // exists to measure, so it must not be mistaken for a measured zero.
        if (hasMeteredEnergy()) {
            return getMeteredEnergyKwh()
        }
        return 0.0
    }

    /**
     * The trip's resolved energy use for ROLLUP totals. Prefers the direct measurement; when
     * that is 0, falls back to `energyPerKm * distanceKm` — the same figure the stored
     * per-trip rate and cost were computed from, so a rollup total stays consistent with the
     * per-trip numbers the UI shows. Always non-negative.
     */
    fun getResolvedEnergyKwh(): Double {
        val measured = getEnergyUsedKwh()
        if (measured > 0) return measured
        val estimated = energyPerKm * distanceKm
        return if (estimated > 0) estimated else 0.0
    }

    /**
     * Whether this trip recorded both ends of the fuel counter — i.e. whether it has a fuel
     * leg at all.
     *
     * Derived from the STORED trip, deliberately never from a live drivetrain probe. A
     * historical trip must render the same way forever, including on a car whose drivetrain
     * reads differently today (a firmware change, a different vehicle, a HAL that was warming
     * up when the trip was recorded).
     *
     * Note this is true for a PHEV leg that burned 0 litres: the counter WAS read, and its
     * answer was zero. That is exactly the distinction a bare `litresUsed > 0` check loses.
     */
    fun hasFuelData(): Boolean = fuelConStart >= 0 && fuelConEnd >= 0

    /** Serialize all fields to JSON (full detail, including micro-moments). */
    fun toJson(): JSONObject {
        val json = JSONObject()
        try {
            putCommon(json)
            json.put("microMomentsJson", microMomentsJson ?: "")
            json.put("telemetryFilePath", telemetryFilePath ?: "")
            // Raw lifetime counters belong only in the full detail view.
            json.put("fuelPctStart", fuelPctStart)
            json.put("fuelPctEnd", fuelPctEnd)
            json.put("fuelConStart", fuelConStart)
            json.put("fuelConEnd", fuelConEnd)
            json.put("fuelPricePerL", fuelPricePerL)
            json.put("elecConStart", elecConStart)
            json.put("elecConEnd", elecConEnd)
        } catch (e: Exception) {
            logger.warn("TripRecord.toJson: failed to serialize: " + e.message)
        }
        return json
    }

    /** Serialize to summary JSON (excludes micro-moments and raw counters, for list views). */
    fun toSummaryJson(): JSONObject {
        val json = JSONObject()
        try {
            putCommon(json)
        } catch (e: Exception) {
            logger.warn("TripRecord.toSummaryJson: failed to serialize: " + e.message)
        }
        return json
    }

    /**
     * The fields both projections share.
     *
     * Extracted because the Java original carried two near-identical 30-line blocks, and a
     * field added to one but not the other is exactly the kind of drift nobody notices. The
     * derived fuel values live here — a list view needs the cost of the fuel leg; it does not
     * need the lifetime counters the cost was derived from, which would only invite a client
     * to compute its own delta and then disagree with the daemon the moment a counter resets.
     */
    private fun putCommon(json: JSONObject) {
        json.put("id", id)
        json.put("startTime", startTime)
        json.put("endTime", endTime)
        json.put("distanceKm", distanceKm)
        json.put("durationSeconds", durationSeconds)
        json.put("avgSpeedKmh", avgSpeedKmh)
        json.put("maxSpeedKmh", maxSpeedKmh)
        json.put("socStart", socStart)
        json.put("socEnd", socEnd)
        json.put("kwhStart", kwhStart)
        json.put("kwhEnd", kwhEnd)
        json.put("energyUsedKwh", getEnergyUsedKwh())
        json.put("efficiencySocPerKm", efficiencySocPerKm)
        json.put("energyPerKm", energyPerKm)
        json.put("electricityRate", electricityRate)
        json.put("currency", currency ?: "")
        json.put("tripCost", tripCost)
        json.put("litresUsed", litresUsed)
        json.put("fuelCost", fuelCost)
        json.put("electricCost", electricCost)
        // BEV representation: the fuel values are emitted as 0 (proto3's default for a
        // double), never as null or omitted. One consistent shape for every trip; hasFuelData
        // is what tells a client whether a fuel leg exists, so a PHEV that burned 0 litres
        // stays distinguishable from a car with no fuel system.
        json.put("hasFuelData", hasFuelData())
        json.put("kinematicState", kinematicState ?: "")
        json.put("gradientProfile", gradientProfile ?: "")
        json.put("elevationGainM", elevationGainM)
        json.put("elevationLossM", elevationLossM)
        json.put("avgGradientPercent", avgGradientPercent)
        json.put("startLat", startLat)
        json.put("startLon", startLon)
        json.put("endLat", endLat)
        json.put("endLon", endLon)
        json.put("extTempC", extTempC)
        json.put("anticipationScore", anticipationScore)
        json.put("smoothnessScore", smoothnessScore)
        json.put("speedDisciplineScore", speedDisciplineScore)
        json.put("efficiencyScore", efficiencyScore)
        json.put("consistencyScore", consistencyScore)
        json.put("overallScore", getOverallScore())
    }

    private companion object {
        private const val TAG = "TripRecord"
        private val logger = DaemonLogger.getInstance(TAG)
    }
}
