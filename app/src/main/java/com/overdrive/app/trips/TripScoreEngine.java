package com.overdrive.app.trips;

import com.overdrive.app.logging.DaemonLogger;

import java.util.ArrayList;
import java.util.List;

/**
 * SOTA Kinematic Scoring Engine for Driving DNA.
 *
 * Classifies the trip's kinematic state (HEAVY_GRIDLOCK, URBAN_FLOW, HIGHWAY_CRUISING)
 * and dynamically adjusts scoring targets per state. Uses pedal jerk integral for
 * smoothness, coast gap detection with EV-aware thresholds, speed variance for
 * discipline, and kWh-based efficiency with state-dependent baselines.
 *
 * Five axes: Anticipation, Smoothness, Speed Discipline, Efficiency, Consistency.
 * All scores are integers in [0, 100] where 100 is optimal.
 */
public class TripScoreEngine {

    private static final DaemonLogger logger = DaemonLogger.getInstance("TripScoreEngine");

    // ==================== Constants ====================

    private static final int MIN_SAMPLES = 30;
    private static final int MIN_COAST_TRANSITIONS = 3;
    private static final double MAX_COAST_GAP_SECONDS = 30.0;
    private static final int MIN_DRIVING_SPEED = 3;
    private static final double MIN_EFFICIENCY_DISTANCE = 0.5;
    private static final int MIN_RECENT_TRIPS_FOR_CONSISTENCY = 2;
    private static final int SMOOTHNESS_WINDOW_SIZE = 10;
    private static final int MIN_WINDOW_DRIVING_SAMPLES = 5;
    private static final int LAUNCH_PROFILE_SAMPLES = 50;
    private static final int HISTOGRAM_BUCKET_WIDTH = 10;
    private static final int HISTOGRAM_BUCKET_COUNT = 11;
    private static final int DEFAULT_SCORE = 50;

    // ==================== Kinematic State ====================

    public enum KinematicState {
        HEAVY_GRIDLOCK,   // avgSpeed < 22, stopsPerKm >= 1.5
        URBAN_FLOW,       // Default — mixed city driving
        HIGHWAY_CRUISING  // avgSpeed > 75, stopsPerKm <= 0.2
    }

    static class StateInfo {
        KinematicState state;
        double stopsPerKm;
        double avgSpeedKmh;
    }

    /**
     * Classify the kinematic state of a trip based on average speed and stop frequency.
     */
    static StateInfo classifyState(List<TelemetrySample> samples, double distanceKm, int durationSeconds) {
        StateInfo info = new StateInfo();
        info.avgSpeedKmh = durationSeconds > 0 ? distanceKm / (durationSeconds / 3600.0) : 0;

        int stopCount = 0;
        boolean wasMoving = false;
        for (TelemetrySample s : samples) {
            if (s.speedKmh > MIN_DRIVING_SPEED) wasMoving = true;
            if (s.speedKmh == 0 && wasMoving) {
                stopCount++;
                wasMoving = false;
            }
        }
        info.stopsPerKm = distanceKm > 0 ? (double) stopCount / distanceKm : 0;

        if (info.avgSpeedKmh < 22 && info.stopsPerKm >= 1.5) {
            info.state = KinematicState.HEAVY_GRIDLOCK;
        } else if (info.avgSpeedKmh > 75 && info.stopsPerKm <= 0.2) {
            info.state = KinematicState.HIGHWAY_CRUISING;
        } else {
            info.state = KinematicState.URBAN_FLOW;
        }
        return info;
    }

    // ==================== Public API ====================

    public TripRecord computeSummary(TripRecord trip, List<TelemetrySample> samples) {
        if (samples == null || samples.size() < MIN_SAMPLES) {
            logger.warn("computeSummary: insufficient samples (" + (samples != null ? samples.size() : 0) + "), using defaults");
            trip.anticipationScore = DEFAULT_SCORE;
            trip.smoothnessScore = DEFAULT_SCORE;
            trip.speedDisciplineScore = DEFAULT_SCORE;
            trip.efficiencyScore = DEFAULT_SCORE;
            trip.consistencyScore = DEFAULT_SCORE;
            trip.kinematicState = KinematicState.URBAN_FLOW.name();
            trip.microMomentsJson = new MicroMoments().toJson().toString();
            return trip;
        }

        // 1. Classify kinematic state
        StateInfo stateInfo = classifyState(samples, trip.distanceKm, trip.durationSeconds);
        trip.kinematicState = stateInfo.state.name();

        // 2. Single-pass O(N) analysis
        List<Long> coastGapMs = new ArrayList<>();
        double pedalJerkSum = 0;
        double speedVarianceSum = 0;
        int lastAccel = 0, lastBrake = 0;
        Long coastStartTime = null;
        int drivingSampleCount = 0;

        for (int i = 0; i < samples.size(); i++) {
            TelemetrySample s = samples.get(i);
            int accel = s.accelPedalPercent;
            int brake = s.brakePedalPercent;
            int speed = s.speedKmh;

            // --- Pedal Jerk (smoothness) ---
            if (i > 0) {
                pedalJerkSum += Math.abs(accel - lastAccel) + Math.abs(brake - lastBrake);
            }

            // --- Coast Gap (anticipation) ---
            // EV-aware: accel < 5% counts as lifting off (regen zone)
            if (accel < 5 && brake == 0 && speed > MIN_DRIVING_SPEED) {
                if (coastStartTime == null) coastStartTime = s.timestampMs;
            } else if (brake > 0 && coastStartTime != null) {
                long gapMs = s.timestampMs - coastStartTime;
                double gapSec = gapMs / 1000.0;
                if (gapSec > 0 && gapSec < MAX_COAST_GAP_SECONDS) {
                    coastGapMs.add(gapMs);
                }
                coastStartTime = null;
            } else if (accel >= 5) {
                coastStartTime = null; // Aborted coast
            }

            // --- Speed Variance (discipline) ---
            if (speed > MIN_DRIVING_SPEED) {
                speedVarianceSum += Math.abs(speed - stateInfo.avgSpeedKmh);
                drivingSampleCount++;
            }

            lastAccel = accel;
            lastBrake = brake;
        }

        // 3. Score each axis with state-dependent targets

        // A. Anticipation — coast gap before braking
        double targetGapMs;
        switch (stateInfo.state) {
            case HEAVY_GRIDLOCK:   targetGapMs = 800;  break;  // Short gaps expected in traffic
            case HIGHWAY_CRUISING: targetGapMs = 1500; break;  // Moderate — highway exits/merges
            default:               targetGapMs = 2500; break;  // Urban — longer coast = better anticipation
        }
        if (coastGapMs.size() >= MIN_COAST_TRANSITIONS) {
            double avgGap = 0;
            for (long g : coastGapMs) avgGap += g;
            avgGap /= coastGapMs.size();
            trip.anticipationScore = clamp((int) Math.round(avgGap / targetGapMs * 100), 0, 100);
        } else {
            trip.anticipationScore = DEFAULT_SCORE;
        }

        // B. Smoothness — pedal jerk integral (lower = smoother)
        double durationSec = samples.size() / 5.0; // 5Hz samples
        if (durationSec < 1) durationSec = 1;
        double normalizedJerk = pedalJerkSum / durationSec; // Avg pedal delta per second
        double maxJerk;
        switch (stateInfo.state) {
            case HEAVY_GRIDLOCK:   maxJerk = 20; break;  // Traffic requires more pedal work
            case HIGHWAY_CRUISING: maxJerk = 8;  break;  // Highway should be very smooth
            default:               maxJerk = 12; break;  // Urban — moderate
        }
        trip.smoothnessScore = clamp((int) Math.round((1.0 - normalizedJerk / maxJerk) * 100), 0, 100);

        // C. Speed Discipline — variance from average speed
        double avgSpeedVariance = drivingSampleCount > 0 ? speedVarianceSum / drivingSampleCount : 0;
        double maxVariance;
        switch (stateInfo.state) {
            case HEAVY_GRIDLOCK:   maxVariance = 18; break;  // High variance expected
            case HIGHWAY_CRUISING: maxVariance = 8;  break;  // Tight speed holding expected
            default:               maxVariance = 14; break;  // Urban — moderate
        }
        trip.speedDisciplineScore = clamp((int) Math.round((1.0 - avgSpeedVariance / maxVariance) * 100), 0, 100);

        // D. Efficiency — kWh/km with state-dependent targets
        double energyUsed = trip.getEnergyUsedKwh();
        if (energyUsed > 0 && trip.distanceKm >= MIN_EFFICIENCY_DISTANCE) {
            double kwhPerKm = energyUsed / trip.distanceKm;
            double targetEff, maxEff;
            switch (stateInfo.state) {
                case HEAVY_GRIDLOCK:   targetEff = 0.12; maxEff = 0.28; break; // Regen-heavy, can be efficient
                case HIGHWAY_CRUISING: targetEff = 0.16; maxEff = 0.32; break; // Aero drag, higher baseline
                default:               targetEff = 0.13; maxEff = 0.28; break; // Urban sweet spot
            }
            double score = (1.0 - (kwhPerKm - targetEff) / (maxEff - targetEff)) * 100;
            trip.efficiencyScore = clamp((int) Math.round(score), 0, 100);
        } else if (trip.distanceKm >= MIN_EFFICIENCY_DISTANCE) {
            // Fallback: SoC-based
            double socDelta = trip.socStart - trip.socEnd;
            if (socDelta > 0) {
                double consumptionPerKm = socDelta / trip.distanceKm;
                double score = (2.5 - consumptionPerKm) / 2.0 * 100;
                trip.efficiencyScore = clamp((int) Math.round(score), 0, 100);
            } else {
                trip.efficiencyScore = DEFAULT_SCORE;
            }
        } else {
            trip.efficiencyScore = DEFAULT_SCORE;
        }

        // E. Consistency — computed later with recent trips
        trip.consistencyScore = DEFAULT_SCORE;

        // 4. Extract micro-moments
        MicroMoments microMoments = extractMicroMoments(samples);
        trip.microMomentsJson = microMoments.toJson().toString();

        // 5. Compute avg/max speed from samples
        long sumSpeed = 0;
        int maxSpeed = 0;
        for (TelemetrySample s : samples) {
            sumSpeed += s.speedKmh;
            if (s.speedKmh > maxSpeed) maxSpeed = s.speedKmh;
        }
        trip.avgSpeedKmh = (double) sumSpeed / samples.size();
        trip.maxSpeedKmh = maxSpeed;

        logger.info("Scores [" + stateInfo.state + " avgSpd=" + String.format("%.0f", stateInfo.avgSpeedKmh)
                + " stops/km=" + String.format("%.1f", stateInfo.stopsPerKm) + "] "
                + "A=" + trip.anticipationScore + " S=" + trip.smoothnessScore
                + " SD=" + trip.speedDisciplineScore + " E=" + trip.efficiencyScore
                + " C=" + trip.consistencyScore);

        return trip;
    }

    /**
     * Consistency Score (0-100): deviation from rolling average of recent trips.
     * Uses energyPerKm when available, falls back to efficiencySocPerKm.
     * Compares current trip against the same metric from recent trips.
     */
    public int computeConsistency(double currentEfficiency, List<TripRecord> recentTrips) {
        if (recentTrips == null || recentTrips.size() < MIN_RECENT_TRIPS_FOR_CONSISTENCY) {
            return DEFAULT_SCORE;
        }

        // Determine which metric to use based on what's available
        boolean useKwh = currentEfficiency > 0 && currentEfficiency < 1; // kWh/km is typically 0.1-0.3
        double sum = 0;
        int count = 0;
        for (TripRecord t : recentTrips) {
            double val = useKwh ? t.energyPerKm : t.efficiencySocPerKm;
            if (val > 0) { sum += val; count++; }
        }
        if (count < MIN_RECENT_TRIPS_FOR_CONSISTENCY) return DEFAULT_SCORE;

        double avgEfficiency = sum / count;
        double deviation = Math.abs(currentEfficiency - avgEfficiency);

        // Normalize: for kWh/km, 0.05 deviation is significant; for %/km, 0.5 is significant
        double maxDeviation = useKwh ? 0.08 : 1.0;
        int score = (int) Math.round((1.0 - deviation / maxDeviation) * 100);
        return clamp(score, 0, 100);
    }

    // ==================== Micro-Moment Extraction ====================

    MicroMoments extractMicroMoments(List<TelemetrySample> samples) {
        MicroMoments mm = new MicroMoments();
        extractLaunchProfiles(samples, mm);
        extractCoastBrakeEvents(samples, mm);
        extractPedalSmoothnessWindows(samples, mm);
        logger.info("Micro-moments: launches=" + mm.launches.size()
                + " coastBrake=" + mm.coastBrakeEvents.size()
                + " smoothnessWindows=" + mm.smoothnessWindows.size());
        return mm;
    }

    int[] computeSpeedHistogram(List<TelemetrySample> samples) {
        int[] counts = new int[HISTOGRAM_BUCKET_COUNT];
        for (TelemetrySample s : samples) {
            int bucket = s.speedKmh / HISTOGRAM_BUCKET_WIDTH;
            if (bucket >= HISTOGRAM_BUCKET_COUNT) bucket = HISTOGRAM_BUCKET_COUNT - 1;
            counts[bucket]++;
        }
        int[] pct = new int[HISTOGRAM_BUCKET_COUNT];
        int total = samples.size();
        if (total > 0) {
            for (int i = 0; i < HISTOGRAM_BUCKET_COUNT; i++) {
                pct[i] = (int) Math.round((double) counts[i] / total * 100);
            }
        }
        return pct;
    }

    // ==================== Private Helpers ====================

    private void extractLaunchProfiles(List<TelemetrySample> samples, MicroMoments mm) {
        boolean wasStationary = false;
        for (int i = 0; i < samples.size(); i++) {
            TelemetrySample s = samples.get(i);
            if (s.speedKmh == 0) { wasStationary = true; continue; }
            if (wasStationary && s.speedKmh > MIN_DRIVING_SPEED) {
                MicroMoments.LaunchProfile lp = new MicroMoments.LaunchProfile();
                lp.startTime = s.timestampMs;
                int endIdx = Math.min(i + LAUNCH_PROFILE_SAMPLES, samples.size());
                List<Integer> curve = new ArrayList<>();
                int peakAccel = 0;
                for (int j = i; j < endIdx; j++) {
                    int accel = samples.get(j).accelPedalPercent;
                    curve.add(accel);
                    if (accel > peakAccel) peakAccel = accel;
                }
                lp.accelCurve = new int[curve.size()];
                for (int k = 0; k < curve.size(); k++) lp.accelCurve[k] = curve.get(k);
                lp.peakAccelPercent = peakAccel;
                mm.launches.add(lp);
                wasStationary = false;
            }
            if (s.speedKmh > 0) wasStationary = false;
        }
    }

    private void extractCoastBrakeEvents(List<TelemetrySample> samples, MicroMoments mm) {
        Long accelReleaseTime = null;
        for (TelemetrySample s : samples) {
            if (s.accelPedalPercent < 5 && s.brakePedalPercent == 0 && accelReleaseTime == null && s.speedKmh > MIN_DRIVING_SPEED) {
                accelReleaseTime = s.timestampMs;
            }
            if (s.brakePedalPercent > 0 && accelReleaseTime != null) {
                long gapMs = s.timestampMs - accelReleaseTime;
                if (gapMs > 0 && gapMs < MAX_COAST_GAP_SECONDS * 1000) {
                    MicroMoments.CoastBrakeEvent event = new MicroMoments.CoastBrakeEvent();
                    event.coastGapMs = gapMs;
                    event.speedAtBrake = s.speedKmh;
                    mm.coastBrakeEvents.add(event);
                }
                accelReleaseTime = null;
            }
            if (s.accelPedalPercent >= 5) accelReleaseTime = null;
        }
    }

    private void extractPedalSmoothnessWindows(List<TelemetrySample> samples, MicroMoments mm) {
        int step = SMOOTHNESS_WINDOW_SIZE / 2;
        for (int i = 0; i <= samples.size() - SMOOTHNESS_WINDOW_SIZE; i += step) {
            List<Integer> accelValues = new ArrayList<>();
            for (int j = i; j < i + SMOOTHNESS_WINDOW_SIZE && j < samples.size(); j++) {
                if (samples.get(j).speedKmh > MIN_DRIVING_SPEED) {
                    accelValues.add(samples.get(j).accelPedalPercent);
                }
            }
            if (accelValues.size() < MIN_WINDOW_DRIVING_SAMPLES) continue;
            MicroMoments.PedalSmoothnessWindow window = new MicroMoments.PedalSmoothnessWindow();
            window.startTime = samples.get(i).timestampMs;
            window.stdDev = stddev(accelValues);
            mm.smoothnessWindows.add(window);
        }
    }

    static int clamp(int value, int min, int max) {
        return Math.max(min, Math.min(max, value));
    }

    static double stddev(List<Integer> values) {
        if (values == null || values.isEmpty()) return 0.0;
        double sum = 0;
        for (int v : values) sum += v;
        double mean = sum / values.size();
        double sumSqDiff = 0;
        for (int v : values) { double d = v - mean; sumSqDiff += d * d; }
        return Math.sqrt(sumSqDiff / values.size());
    }
}
