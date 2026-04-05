package com.overdrive.app.trips;

import com.overdrive.app.abrp.SohEstimator;
import com.overdrive.app.logging.DaemonLogger;

/**
 * Personalized range prediction using bucketed consumption model.
 * Classifies driving conditions into buckets (speed × temp × style) and uses
 * historical consumption data to predict remaining range with confidence intervals.
 */
public class RangeEstimator {

    private static final String TAG = "RangeEstimator";
    private static final DaemonLogger logger = DaemonLogger.getInstance(TAG);

    private final TripDatabase database;
    private final SohEstimator sohEstimator;

    public RangeEstimator(TripDatabase database, SohEstimator sohEstimator) {
        this.database = database;
        this.sohEstimator = sohEstimator;
    }

    /**
     * Compute the bucket key for the given conditions.
     * Format: "{speedProfile}_{tempBand}_{styleBracket}"
     *
     * Speed: "city" (<40), "suburban" (40-80), "highway" (>80)
     * Temp:  "cold" (<10°C), "mild" (10-25°C), "hot" (>25°C)
     * Style: "low" (<40), "mid" (40-70), "high" (>70)
     */
    static String computeBucketKey(double avgSpeedKmh, int extTempC, int dnaScore) {
        String speed;
        if (avgSpeedKmh < 40) {
            speed = "city";
        } else if (avgSpeedKmh <= 80) {
            speed = "suburban";
        } else {
            speed = "highway";
        }

        String temp;
        if (extTempC < 10) {
            temp = "cold";
        } else if (extTempC <= 25) {
            temp = "mild";
        } else {
            temp = "hot";
        }

        String style;
        if (dnaScore < 40) {
            style = "low";
        } else if (dnaScore <= 70) {
            style = "mid";
        } else {
            style = "high";
        }

        return speed + "_" + temp + "_" + style;
    }

    /**
     * Estimate remaining range based on current conditions and historical consumption data.
     *
     * @param currentSocPercent  Current battery state of charge (0-100%)
     * @param currentSpeedKmh    Current vehicle speed in km/h
     * @param extTempC           External temperature in °C
     * @param dnaOverallScore    Current overall Driving DNA score (0-100)
     * @return RangeEstimate with predicted range and confidence interval, or null if insufficient data
     */
    public RangeEstimate estimate(double currentSocPercent, double currentSpeedKmh,
                                  int extTempC, int dnaOverallScore) {
        double nominalCapacityKwh = sohEstimator.getNominalCapacityKwh();
        double remainingEnergyKwh = currentSocPercent / 100.0 * nominalCapacityKwh;

        String bucketKey = computeBucketKey(currentSpeedKmh, extTempC, dnaOverallScore);
        ConsumptionBucket bucket = database.getBucket(bucketKey);

        // Fall back to overall average if matched bucket has fewer than 3 samples
        if (bucket == null || bucket.sampleCount < 3) {
            bucket = database.getOverallAverage();
        }

        // Not enough data yet — need at least 10 total trip samples
        if (bucket == null || bucket.sampleCount < 10) {
            logger.debug("Not enough consumption data for range estimate (samples: " +
                    (bucket != null ? bucket.sampleCount : 0) + ")");
            return null;
        }

        double mean = bucket.getMean();
        double stddev = bucket.getStdDev();

        if (mean <= 0) {
            logger.warn("Invalid mean consumption rate: " + mean);
            return null;
        }

        double predictedRange = remainingEnergyKwh / mean;
        double lowerBound = remainingEnergyKwh / (mean + stddev);
        double upperBound = remainingEnergyKwh / Math.max(0.01, mean - stddev);

        RangeEstimate estimate = new RangeEstimate();
        estimate.predictedRangeKm = predictedRange;
        estimate.lowerBoundKm = lowerBound;
        estimate.upperBoundKm = upperBound;
        estimate.bucketKey = bucket.bucketKey;
        estimate.sampleCount = bucket.sampleCount;

        logger.debug("Range estimate: " + String.format("%.1f", predictedRange) +
                " km [" + String.format("%.1f", lowerBound) + "-" +
                String.format("%.1f", upperBound) + "] bucket=" + bucket.bucketKey +
                " samples=" + bucket.sampleCount);

        return estimate;
    }

    /**
     * Called when a trip is completed to update the consumption bucket.
     * Computes the consumption rate (kWh/km) and stores it in the matching bucket.
     */
    public void onTripCompleted(TripRecord trip) {
        if (trip.distanceKm <= 0) {
            logger.debug("Skipping consumption update for zero-distance trip");
            return;
        }

        double consumptionRate;
        String source;

        // Prefer direct kWh measurement from BMS
        double energyUsed = trip.getEnergyUsedKwh();
        if (energyUsed > 0) {
            consumptionRate = energyUsed / trip.distanceKm;
            source = "kWh=" + String.format("%.2f", energyUsed);
        } else {
            // Fallback: derive from SoC delta × nominal capacity
            double nominalCapacityKwh = sohEstimator.getNominalCapacityKwh();
            double socDelta = trip.socStart - trip.socEnd;

            if (socDelta <= 0) {
                logger.debug("Skipping consumption update for non-positive SoC delta: " + socDelta);
                return;
            }

            consumptionRate = (socDelta * nominalCapacityKwh / 100.0) / trip.distanceKm;
            source = "SoC delta=" + String.format("%.1f", socDelta) + "%";
        }

        String bucketKey = computeBucketKey(trip.avgSpeedKmh, trip.extTempC, trip.getOverallScore());
        database.updateConsumptionBucket(bucketKey, consumptionRate);

        logger.info("Updated consumption bucket: " + bucketKey +
                " rate=" + String.format("%.4f", consumptionRate) + " kWh/km" +
                " (" + source + ", dist=" + String.format("%.1f", trip.distanceKm) + "km)");
    }
}
