package net.bladewatch.app.trips

/**
 * Fuel-side consumption learning and range prediction for PHEVs (BladeWatch-fpdz.9).
 *
 * The electric side of [RangeEstimator] learns kWh/km into buckets keyed by speed, temperature
 * and driving score. This is the same idea in litres, and it deliberately reuses that bucket
 * store and that key derivation — a fuel bucket is just the electric key under [FUEL_PREFIX],
 * so the two estimators stay directly comparable and no schema change is needed.
 *
 * **There is no tank capacity in BYD local data.** Remaining litres therefore cannot be
 * derived, and this object does not invent a constant for it. [predictRangeKm] requires the
 * owner to have configured a tank size and returns [CANNOT_PREDICT] otherwise; the car's own
 * `fuelRangeKm` from the HAL remains available as the built-in comparison, exactly as
 * `builtInRangeKm` already serves the electric estimate.
 */
object FuelConsumption {

    /** Bucket-key namespace, so fuel samples can never be averaged into the kWh/km buckets. */
    const val FUEL_PREFIX = "fuel_"

    /**
     * Plausible fuel consumption band, in litres per km. Samples outside it are rejected as
     * garbage rather than allowed to poison a bucket average.
     *
     * 0.02–0.20 L/km is 2–20 L/100 km. **Inherited from Overdrive and NOT re-derived on this
     * car** — the same provenance as the dewarp strengths and the sub-30 kWh capacity
     * threshold. Treat as a reasonable default, not a measured value.
     */
    const val MIN_LITRES_PER_KM = 0.02
    const val MAX_LITRES_PER_KM = 0.20

    /** Returned by [predictRangeKm] when there is not enough information to predict. */
    const val CANNOT_PREDICT = -1.0

    /** Namespaced bucket key for a fuel sample, from the electric key. */
    @JvmStatic
    fun fuelBucketKey(electricBucketKey: String): String = FUEL_PREFIX + electricBucketKey

    /**
     * Litres per km for a completed trip, or null when this trip teaches us nothing.
     *
     * Returns null — rather than 0 — for a trip that burned nothing. A PHEV leg driven
     * entirely on electricity is a real, correct trip, but its fuel rate is not 0 L/km; it is
     * undefined. Feeding 0 into the bucket would drag the learned average toward zero and
     * inflate every subsequent range prediction.
     *
     * The explicit zero and distance checks below are stated for intent, not because they are
     * load-bearing: the sanity band would reject a 0 or negative rate anyway. Mutation-tested
     * both ways — deleting the zero check alone changes nothing, deleting the band breaks
     * three tests. Kept so a reader finds the rule where they look for it rather than
     * inferring it from a numeric range.
     */
    @JvmStatic
    fun litresPerKm(litresUsed: Double, distanceKm: Double): Double? {
        if (!distanceKm.isFinite() || distanceKm <= 0) return null
        if (!litresUsed.isFinite() || litresUsed <= 0) return null
        val rate = litresUsed / distanceKm
        if (rate < MIN_LITRES_PER_KM || rate > MAX_LITRES_PER_KM) return null
        return rate
    }

    /**
     * Predicted fuel range in km, or [CANNOT_PREDICT] when it cannot be computed.
     *
     * Absent a tank capacity this returns [CANNOT_PREDICT] rather than a guess: a wrong range
     * figure on a dashboard is worse than no figure, because the driver acts on it.
     *
     * @param tankCapacityL owner-configured tank size; 0 means not configured
     * @param fuelPercent tank level 0-100, or -1/NaN when unavailable
     * @param litresPerKm learned consumption rate
     */
    @JvmStatic
    fun predictRangeKm(tankCapacityL: Double, fuelPercent: Double, litresPerKm: Double): Double {
        // isFinite, not just > 0: an Infinity capacity yields an Infinity range, which JSON
        // cannot represent and `JSONObject.put` rejects outright.
        if (!tankCapacityL.isFinite() || tankCapacityL <= 0) return CANNOT_PREDICT
        if (fuelPercent.isNaN() || fuelPercent < 0 || fuelPercent > 100) return CANNOT_PREDICT
        if (litresPerKm < MIN_LITRES_PER_KM || litresPerKm > MAX_LITRES_PER_KM) return CANNOT_PREDICT
        val remainingLitres = tankCapacityL * (fuelPercent / 100.0)
        return remainingLitres / litresPerKm
    }
}
