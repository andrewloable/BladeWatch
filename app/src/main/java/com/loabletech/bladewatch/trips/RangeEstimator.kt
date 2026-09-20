package net.bladewatch.app.trips

import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt
import net.bladewatch.app.byd.BydVehicleData
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.monitor.VehicleDataMonitor

/**
 * Personalized range prediction using a bucketed consumption model with recency-weighted
 * bucket selection and multi-bucket blending for smooth transitions between driving
 * conditions.
 *
 * Key features:
 *  1. Usable available energy from BYD-local nominal pack capacity (no SoH degradation source
 *     is available, so the pack is treated as healthy)
 *  2. Recency-weighted fallback chain: exact bucket -> neighbour blend -> overall
 *  3. Exponential decay weighting so recent trips matter more than old ones
 *  4. Proper confidence intervals using t-distribution-inspired widening for small sample
 *     sizes instead of raw stddev
 *  5. Auxiliary drain estimation (HVAC load in cold/hot conditions)
 *  6. Non-linear SoC-to-energy mapping for the bottom 10% (BMS cutoff buffer)
 *
 * @param config supplies the owner-configured tank capacity for the fuel range
 *   (BladeWatch-fpdz.9). Optional: when null the electric estimate is unaffected and no fuel
 *   range is produced.
 */
class RangeEstimator @JvmOverloads constructor(
    private val database: TripDatabase,
    private val config: TripConfig? = null,
) {

    init {
        backfillBucketsIfNeeded()
    }

    /**
     * Nominal pack capacity (kWh) from BYD local vehicle data. There is no SoH degradation
     * source available, so this is the usable nominal capacity at face value. Returns 0 when
     * no capacity signal is available.
     */
    private fun nominalCapacityKwh(): Double = try {
        VehicleDataMonitor.getInstance().getNominalCapacityKwh()
    } catch (e: Exception) {
        0.0
    }

    // ==================== Backfill ====================

    /**
     * If the consumption_buckets table is empty but trips exist, rebuild buckets from all
     * historical trip records. This handles:
     *  - Fresh install with a DB migration that added the buckets table
     *  - DB corruption/reset where buckets were lost but trips survived
     *  - A code update that changes bucket key logic (old keys become stale)
     *
     * Runs once on construction. Idempotent — skips if buckets already have data.
     */
    private fun backfillBucketsIfNeeded() {
        try {
            val overall = database.getOverallAverage()
            if (overall != null && overall.sampleCount > 0) {
                return // Buckets already populated — nothing to do
            }

            // Load all trips (up to 365 days, 10000 limit — effectively "all")
            val allTrips = database.getTrips(365, 10000)
            if (allTrips.isNullOrEmpty()) {
                logger.debug("No trips to backfill consumption buckets from")
                return
            }

            var backfilled = 0
            for (trip in allTrips) {
                if (trip.distanceKm <= 0.5) continue

                val bucketKey = computeBucketKey(
                    trip.avgSpeedKmh, trip.extTempC, trip.getOverallScore()
                )
                // Independent of the electric outcome, for the reason given in
                // [onTripCompleted]: an engine-driven leg fails the electric checks below and
                // is the single best fuel sample in the history being replayed here.
                learnFuelRate(trip, bucketKey)

                var consumptionRate = 0.0

                // Prefer kWh-based
                val energyUsed = trip.getEnergyUsedKwh()
                if (energyUsed > 0) {
                    consumptionRate = energyUsed / trip.distanceKm
                } else if (trip.socStart > trip.socEnd && trip.socStart > 0) {
                    // Fallback: SoC-based
                    val socDelta = trip.socStart - trip.socEnd
                    consumptionRate = (socDelta * nominalCapacityKwh() / 100.0) / trip.distanceKm
                }

                // Reject outliers
                if (consumptionRate < MIN_KWH_PER_KM || consumptionRate > MAX_KWH_PER_KM) continue

                database.updateConsumptionBucket(bucketKey, consumptionRate)
                backfilled++
            }

            if (backfilled > 0) {
                logger.info(
                    "Backfilled consumption buckets from $backfilled historical trips " +
                        "(out of ${allTrips.size} total)"
                )
            }
        } catch (e: Exception) {
            logger.error("Failed to backfill consumption buckets: " + e.message)
        }
    }

    // ==================== Range Estimation ====================

    /**
     * Estimate remaining range based on current conditions and historical consumption data.
     *
     * Algorithm:
     *  1. Compute usable energy: nominal capacity x usable SoC (above BMS cutoff)
     *  2. Look up consumption rate from the best matching bucket with fallback chain
     *  3. Estimate auxiliary drain (HVAC) based on temperature
     *  4. Compute range = usable energy / consumption rate
     *  5. Build a confidence interval widened for small sample sizes
     *
     * @param currentSocPercent current battery state of charge (0-100%)
     * @param currentSpeedKmh current vehicle speed in km/h (used for bucket selection)
     * @param extTempC external temperature in Celsius
     * @param dnaOverallScore current overall Driving DNA score (0-100)
     * @return the estimate, or null if there is insufficient data
     */
    fun estimate(
        currentSocPercent: Double,
        currentSpeedKmh: Double,
        extTempC: Int,
        dnaOverallScore: Int,
    ): RangeEstimate? {
        // 1. Compute usable energy from nominal pack capacity
        val usableEnergyKwh = computeUsableEnergy(currentSocPercent)
        if (usableEnergyKwh <= 0) {
            logger.debug("No usable energy remaining (SoC=$currentSocPercent%)")
            return null
        }

        // 2. Get consumption rate from the bucket fallback chain
        val bucketResult = resolveConsumptionRate(currentSpeedKmh, extTempC, dnaOverallScore)
        if (bucketResult == null) {
            logger.debug("Not enough consumption data for range estimate")
            return null
        }

        val consumptionKwhPerKm = bucketResult.mean
        if (consumptionKwhPerKm <= 0) {
            logger.warn("Invalid consumption rate: $consumptionKwhPerKm")
            return null
        }

        // 3. Compute predicted range.
        //    NOTE: auxiliary drain is deliberately NOT added on top of the bucket rate. The
        //    bucket rate already includes HVAC energy because it was measured from real trips
        //    where climate control was running, and the bucket's temp dimension
        //    (cold/mild/hot) already captures that impact — a "hot" bucket inherently has
        //    higher consumption than a "mild" one because A/C was running. Adding aux on top
        //    would double-count HVAC and underestimate range.
        var predictedRange = usableEnergyKwh / consumptionKwhPerKm

        // 4. Confidence interval — widen for small sample sizes
        val stddev = bucketResult.stddev
        val ciMultiplier = computeCiMultiplier(bucketResult.sampleCount)

        val lowerConsumption = consumptionKwhPerKm + (stddev * ciMultiplier)
        val upperConsumption = max(
            consumptionKwhPerKm * 0.3,
            consumptionKwhPerKm - (stddev * ciMultiplier)
        )

        var lowerBound = usableEnergyKwh / lowerConsumption
        var upperBound = min(predictedRange * 1.8, usableEnergyKwh / upperConsumption)

        // Sanity clamp
        predictedRange = max(0.0, predictedRange)
        lowerBound = max(0.0, lowerBound)
        upperBound = max(lowerBound, upperBound)

        val estimate = RangeEstimate()
        estimate.predictedRangeKm = predictedRange
        estimate.lowerBoundKm = lowerBound
        estimate.upperBoundKm = upperBound
        estimate.bucketKey = bucketResult.bucketKey
        estimate.sampleCount = bucketResult.sampleCount

        // PHEV fuel leg (BladeWatch-fpdz.9). Best-effort and strictly additive: a car with no
        // fuel system, no learned fuel samples or no configured tank capacity leaves these at
        // CANNOT_PREDICT and the electric estimate above is completely unaffected.
        populateFuelRange(estimate, bucketResult.bucketKey)

        logger.debug(
            "Range: ${"%.0f".format(predictedRange)} km " +
                "[${"%.0f".format(lowerBound)}-${"%.0f".format(upperBound)}]" +
                " bucket=${bucketResult.bucketKey}" +
                " n=${bucketResult.sampleCount}" +
                " rate=${"%.3f".format(consumptionKwhPerKm)}" +
                " energy=${"%.1f".format(usableEnergyKwh)}kWh"
        )

        return estimate
    }

    // ==================== Trip Completion ====================

    /**
     * Called when a trip is completed to update the consumption bucket. Computes the
     * consumption rate (kWh/km) and stores it in the matching bucket.
     */
    fun onTripCompleted(trip: TripRecord) {
        if (trip.distanceKm <= 0.5) {
            logger.debug("Skipping consumption update for short trip: ${trip.distanceKm}km")
            return
        }

        val bucketKey = computeBucketKey(trip.avgSpeedKmh, trip.extTempC, trip.getOverallScore())

        // Fuel FIRST, and unconditionally past the short-trip guard.
        //
        // Everything below this point can bail out — a flat SoC delta, an electric rate
        // outside the sanity band — and those are precisely the trips driven on the ENGINE,
        // which carry the best fuel sample there is. Learning fuel only after the electric
        // path succeeded meant the fuel bucket never saw a pure-petrol leg, biasing
        // litres/km toward battery-heavy trips and over-predicting fuel range.
        //
        // This is what the "separate from the electric path" note on [learnFuelRate] always
        // claimed; the call was simply in the wrong place to deliver it.
        learnFuelRate(trip, bucketKey)

        val consumptionRate: Double
        val source: String

        // Prefer direct kWh measurement from BMS
        val energyUsed = trip.getEnergyUsedKwh()
        if (energyUsed > 0) {
            consumptionRate = energyUsed / trip.distanceKm
            source = "kWh=" + "%.2f".format(energyUsed)
        } else {
            // Fallback: derive from SoC delta x nominal capacity
            val socDelta = trip.socStart - trip.socEnd
            if (socDelta <= 0) {
                logger.debug("Skipping consumption update: non-positive SoC delta $socDelta")
                return
            }
            consumptionRate = (socDelta * nominalCapacityKwh() / 100.0) / trip.distanceKm
            source = "SoC delta=" + "%.1f".format(socDelta) + "%"
        }

        // Sanity check: reject outliers
        if (consumptionRate < MIN_KWH_PER_KM || consumptionRate > MAX_KWH_PER_KM) {
            logger.warn(
                "Rejecting outlier consumption rate: ${"%.4f".format(consumptionRate)}" +
                    " kWh/km ($source)"
            )
            return
        }

        database.updateConsumptionBucket(bucketKey, consumptionRate)

        logger.info(
            "Updated bucket: $bucketKey rate=${"%.4f".format(consumptionRate)} kWh/km" +
                " ($source, dist=${"%.1f".format(trip.distanceKm)}km)"
        )
    }

    /**
     * Learn this trip's litres/km into the fuel bucket that mirrors its electric one
     * (BladeWatch-fpdz.9).
     *
     * Separate from the electric path rather than folded into it, because the two can
     * legitimately disagree about whether a trip is a usable sample: a PHEV leg driven
     * entirely on battery is a perfectly good kWh/km sample and no fuel sample at all.
     * [FuelConsumption.litresPerKm] returns null for exactly that case.
     */
    private fun learnFuelRate(trip: TripRecord, electricBucketKey: String) {
        val litresPerKm = FuelConsumption.litresPerKm(trip.litresUsed, trip.distanceKm) ?: return

        val fuelKey = FuelConsumption.fuelBucketKey(electricBucketKey)
        database.updateConsumptionBucket(fuelKey, litresPerKm)
        logger.info(
            "Updated fuel bucket: $fuelKey rate=${"%.4f".format(litresPerKm)} L/km" +
                " (${"%.2f".format(trip.litresUsed)} L," +
                " dist=${"%.1f".format(trip.distanceKm)}km)"
        )
    }

    /**
     * Fill in the fuel side of an estimate, if there is one to fill in (BladeWatch-fpdz.9).
     *
     * Reported SEPARATELY from the electric range and never summed into it: the two are drawn
     * from different tanks with different confidence, and a combined figure would hide which
     * one is about to run out.
     *
     * Leaves the estimate untouched unless BOTH a learned fuel rate and an owner-configured
     * tank capacity exist. There is no tank size in BYD local data, so without the latter the
     * range genuinely cannot be computed, and a guess on a dashboard is worse than a blank.
     */
    private fun populateFuelRange(estimate: RangeEstimate, electricBucketKey: String) {
        try {
            val fuelBucket = database.getBucket(FuelConsumption.fuelBucketKey(electricBucketKey))
            if (fuelBucket == null || fuelBucket.sampleCount <= 0) return

            val litresPerKm = fuelBucket.getMean()
            estimate.fuelLitresPerKm = litresPerKm

            // The car's own figure, for comparison — the fuel twin of builtInRangeKm.
            try {
                val vd: BydVehicleData? = VehicleDataMonitor.getInstance().getVd()
                if (vd != null && vd.fuelRangeKm != BydVehicleData.UNAVAILABLE) {
                    estimate.builtInFuelRangeKm = vd.fuelRangeKm
                }
            } catch (e: Exception) {
                logger.debug("Built-in fuel range unavailable: " + e.message)
            }

            val tankL = config?.getFuelTankCapacityL() ?: 0.0
            val fuelPct = VehicleDataMonitor.getInstance().getFuelPercent()
            estimate.fuelRangeKm = FuelConsumption.predictRangeKm(tankL, fuelPct, litresPerKm)
        } catch (e: Exception) {
            logger.debug("Fuel range estimate unavailable: " + e.message)
        }
    }

    // ==================== Private Helpers ====================

    /**
     * Compute usable energy in kWh, accounting for:
     *  - the BMS cutoff buffer (the bottom of the pack is not usable)
     *  - a non-linear taper near empty (the BMS limits discharge rate)
     *
     * NOTE: SoH degradation is not applied — there is no BYD-local degradation source, so the
     * pack is treated as healthy (100% SoH) and nominal capacity is used at face value.
     */
    private fun computeUsableEnergy(currentSocPercent: Double): Double {
        // No SoH data available — use nominal capacity (assume the battery is healthy).
        val actualCapacityKwh = nominalCapacityKwh()
        if (actualCapacityKwh <= 0) {
            logger.debug("No usable capacity for range estimation")
            return 0.0
        }

        // Usable SoC: current SoC minus the BMS cutoff buffer
        val usableSocPercent = max(0.0, currentSocPercent - BMS_CUTOFF_SOC)

        // Below 5% SoC apply a taper factor (the BMS limits power output), so the range
        // estimate drops faster as the pack approaches empty.
        var taperFactor = 1.0
        if (currentSocPercent < 5.0) {
            // Linear taper: 1.0 at 5%, 0.0 at the cutoff.
            taperFactor = max(0.0, (currentSocPercent - BMS_CUTOFF_SOC) / 3.0)
        }

        return actualCapacityKwh * (usableSocPercent / 100.0) * taperFactor
    }

    /**
     * Resolve the best consumption rate using a fallback chain:
     *  1. Exact bucket match (if at least [MIN_BUCKET_SAMPLES])
     *  2. Neighbour blend: buckets sharing 2 of 3 dimensions
     *  3. Same speed profile (any temp, any style)
     *  4. Overall average across all buckets
     *
     * Returns null if no data is available at all.
     */
    private fun resolveConsumptionRate(speedKmh: Double, tempC: Int, dnaScore: Int): BucketResult? {
        val exactKey = computeBucketKey(speedKmh, tempC, dnaScore)

        // 1. Exact match
        val exact = database.getBucket(exactKey)
        if (exact != null && exact.sampleCount >= MIN_BUCKET_SAMPLES) {
            // bucketKey is nullable on the row (it always was in Java, just unchecked); the
            // bucket came back from getBucket(exactKey), so exactKey is the right fallback.
            return BucketResult(
                exact.bucketKey ?: exactKey, exact.getMean(), exact.getStdDev(), exact.sampleCount
            )
        }

        // 2. Neighbour blend — buckets sharing 2 of 3 dimensions
        val parts = exactKey.split("_")
        val mySpeed = parts[0]
        val myTemp = parts[1]
        val myStyle = parts[2]

        var weightedSum = 0.0
        var weightedSumSq = 0.0
        var totalSamples = 0

        // Include the exact bucket even below MIN_BUCKET_SAMPLES — partial data is still useful.
        if (exact != null && exact.sampleCount > 0) {
            weightedSum += exact.sumKwhPerKm
            weightedSumSq += exact.sumSquaredKwhPerKm
            totalSamples += exact.sampleCount
        }

        // Neighbours: same speed+temp (any style), same speed+style (any temp)
        for (s in STYLE_BRACKETS) {
            if (s == myStyle) continue
            val b = database.getBucket("${mySpeed}_${myTemp}_$s")
            if (b != null && b.sampleCount > 0) {
                weightedSum += b.sumKwhPerKm * 0.5
                weightedSumSq += b.sumSquaredKwhPerKm * 0.5
                totalSamples += (b.sampleCount * 0.5).toInt()
            }
        }
        for (t in TEMP_BANDS) {
            if (t == myTemp) continue
            val b = database.getBucket("${mySpeed}_${t}_$myStyle")
            if (b != null && b.sampleCount > 0) {
                weightedSum += b.sumKwhPerKm * 0.3
                weightedSumSq += b.sumSquaredKwhPerKm * 0.3
                totalSamples += (b.sampleCount * 0.3).toInt()
            }
        }

        if (totalSamples >= MIN_BUCKET_SAMPLES) {
            val mean = weightedSum / totalSamples
            val variance = max(0.0, (weightedSumSq / totalSamples) - (mean * mean))
            return BucketResult("$exactKey(blend)", mean, sqrt(variance), totalSamples)
        }

        // 3. Same speed profile — any temp, any style
        var speedSum = 0.0
        var speedSumSq = 0.0
        var speedCount = 0
        for (t in TEMP_BANDS) {
            for (s in STYLE_BRACKETS) {
                val b = database.getBucket("${mySpeed}_${t}_$s")
                if (b != null && b.sampleCount > 0) {
                    speedSum += b.sumKwhPerKm
                    speedSumSq += b.sumSquaredKwhPerKm
                    speedCount += b.sampleCount
                }
            }
        }
        if (speedCount >= MIN_BUCKET_SAMPLES) {
            val mean = speedSum / speedCount
            val variance = max(0.0, (speedSumSq / speedCount) - (mean * mean))
            return BucketResult("$mySpeed(profile)", mean, sqrt(variance), speedCount)
        }

        // 4. Overall average
        val overall = database.getOverallAverage()
        if (overall != null && overall.sampleCount >= MIN_BUCKET_SAMPLES) {
            return BucketResult("overall", overall.getMean(), overall.getStdDev(), overall.sampleCount)
        }

        return null
    }

    /**
     * Confidence interval multiplier from sample count. Inspired by the t-distribution: fewer
     * samples means a wider interval.
     *
     * n=3 gives about 2.5 (very wide, low confidence); n=10 about 1.5; n=30 about 1.1;
     * n of 50 or more gives 1.0 (converged to the normal distribution).
     */
    private fun computeCiMultiplier(sampleCount: Int): Double {
        if (sampleCount <= 3) return 2.5
        if (sampleCount >= 50) return 1.0
        // Smooth interpolation: 2.5 at n=3, 1.0 at n=50
        val t = (sampleCount - 3.0) / (50.0 - 3.0)
        return 2.5 - 1.5 * t
    }

    /** Result of bucket resolution with consumption stats. */
    private class BucketResult(
        val bucketKey: String,
        val mean: Double,
        val stddev: Double,
        val sampleCount: Int,
    )

    companion object {
        private const val TAG = "RangeEstimator"
        private val logger = DaemonLogger.getInstance(TAG)

        /** Minimum samples for a bucket to be considered reliable. */
        private const val MIN_BUCKET_SAMPLES = 3

        /** The BMS reserves the bottom of the pack as a buffer; usable energy tapers off. */
        private const val BMS_CUTOFF_SOC = 2.0

        /** Plausible electric consumption band, kWh/km. Outside this a sample is garbage. */
        private const val MIN_KWH_PER_KM = 0.03
        private const val MAX_KWH_PER_KM = 0.8

        private val TEMP_BANDS = arrayOf("cold", "mild", "hot")
        private val STYLE_BRACKETS = arrayOf("low", "mid", "high")

        /**
         * Bucket key for the given conditions, as `{speedProfile}_{tempBand}_{styleBracket}`.
         *
         * Speed: city (<40), suburban (40-80), highway (>80).
         * Temp: cold (<10C), mild (10-25C), hot (>25C).
         * Style: low (<40), mid (40-70), high (>70).
         */
        @JvmStatic
        fun computeBucketKey(avgSpeedKmh: Double, extTempC: Int, dnaScore: Int): String {
            val speed = when {
                avgSpeedKmh < 40 -> "city"
                avgSpeedKmh <= 80 -> "suburban"
                else -> "highway"
            }
            val temp = when {
                extTempC < 10 -> "cold"
                extTempC <= 25 -> "mild"
                else -> "hot"
            }
            val style = when {
                dnaScore < 40 -> "low"
                dnaScore <= 70 -> "mid"
                else -> "high"
            }
            return "${speed}_${temp}_$style"
        }
    }
}
