package net.bladewatch.app.trips

import net.bladewatch.app.logging.DaemonLogger
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt
import kotlin.math.sqrt

/**
 * Single-pass kinematic scoring engine for Driving DNA.
 *
 * Processes the whole telemetry array in ONE pass, computing all five DNA scores, micro-moments,
 * the speed histogram, avg/max speed and the kinematic classification simultaneously. On a
 * two-hour 5Hz drive — 36,000 samples — it touches the array exactly once, which matters on head
 * unit hardware where cache thrashing and memory bandwidth are real constraints.
 *
 * Scoring axes:
 *  - Anticipation: EV-aware coast-gap detection (accel below 5% counts as regen lift-off)
 *  - Smoothness: pedal jerk integral, the sum of |Δaccel| + |Δbrake| per second
 *  - Speed discipline: rolling-window speed standard deviation
 *  - Efficiency: kWh/km against state-dependent baselines, falling back to SoC
 *  - Consistency: percentage deviation from the rolling 10-trip average
 *
 * All scores are integers in [0, 100] where 100 is optimal.
 */
class TripScoreEngine {

    /** Traffic classification. Orthogonal to [GradientProfile], which classifies terrain. */
    enum class KinematicState {
        /** avgSpeed < 22, stopsPerKm >= 1.5 */
        HEAVY_GRIDLOCK,

        /** The default — mixed city driving. */
        URBAN_FLOW,

        /** avgSpeed > 75, stopsPerKm <= 0.2 */
        HIGHWAY_CRUISING
    }

    /**
     * Terrain classification from cumulative elevation per km. Climb and descent are SEPARATE
     * profiles because the physics and the optimal driving behaviour differ fundamentally.
     */
    enum class GradientProfile {
        /** < 5 m gain/loss per km. */
        FLAT,

        /** 5-15 m gain or loss per km. */
        HILLY,

        /** > 15 m gain per km. */
        MOUNTAIN_CLIMB,

        /** > 15 m loss per km — regen territory. */
        MOUNTAIN_DESCENT
    }

    /**
     * Compute all trip scores, micro-moments and stats in a single pass.
     *
     * After this call the [TripRecord] has all five DNA scores, `kinematicState`,
     * `microMomentsJson`, `avgSpeedKmh` and `maxSpeedKmh` populated.
     */
    fun computeSummary(trip: TripRecord, samples: List<TelemetrySample>?): TripRecord {
        if (samples == null || samples.size < MIN_SAMPLES) {
            logger.warn(
                "computeSummary: insufficient samples (" + (samples?.size ?: 0) +
                    "), using defaults"
            )
            trip.anticipationScore = DEFAULT_SCORE
            trip.smoothnessScore = DEFAULT_SCORE
            trip.speedDisciplineScore = DEFAULT_SCORE
            trip.efficiencyScore = DEFAULT_SCORE
            trip.consistencyScore = DEFAULT_SCORE
            trip.kinematicState = KinematicState.URBAN_FLOW.name
            trip.microMomentsJson = MicroMoments().toJson().toString()
            return trip
        }

        val n = samples.size

        // Kinematic state classification
        var stopCount = 0
        var wasMoving = false

        // Avg/max speed
        var sumSpeed = 0L
        var maxSpeed = 0

        // Elevation (gradient profile)
        var elevationGain = 0.0
        var elevationLoss = 0.0
        var lastValidAlt = Double.NaN
        var altSampleCounter = 0

        // Speed histogram
        val histCounts = IntArray(HISTOGRAM_BUCKET_COUNT)

        // Pedal jerk (smoothness)
        var pedalJerkSum = 0.0
        var lastAccel = 0
        var lastBrake = 0

        // Coast gap (anticipation)
        var coastStartTime: Long? = null
        var coastGapSumMs = 0L
        var coastGapCount = 0

        // Launch profiles (micro-moments)
        var wasStationary = false
        var launchCaptureRemaining = 0
        var launchPeakAccel = 0
        var launchStartTime = 0L
        var launchCurveBuffer: MutableList<Int>? = null

        // Coast-brake events (micro-moments)
        var mmCoastStartTime: Long? = null

        // Speed discipline: circular buffer + naive sum-of-squares variance
        val sdWindowSpeeds = IntArray(SD_WINDOW_SIZE)
        val sdWindowIsDriving = BooleanArray(SD_WINDOW_SIZE)
        var sdWindowDrivingCount = 0
        var sdWindowSum = 0.0
        var sdWindowSumSq = 0.0
        var sdTotalScore = 0.0
        var sdWindowCount = 0
        var sdStepCounter = 0

        // Pedal smoothness: circular buffer
        val smoothWindowAccel = IntArray(SMOOTH_WINDOW_SIZE)
        val smoothWindowDriving = BooleanArray(SMOOTH_WINDOW_SIZE)
        var smoothStepCounter = 0

        val microMoments = MicroMoments()

        // ───────────────── SINGLE PASS: iterate samples exactly once ─────────────────
        for (i in 0 until n) {
            val s = samples[i]
            val speed = s.speedKmh
            val accel = s.accelPedalPercent
            val brake = s.brakePedalPercent

            // 1. Avg/max speed
            sumSpeed += speed
            if (speed > maxSpeed) maxSpeed = speed

            // 2. Speed histogram
            var bucket = speed / HISTOGRAM_BUCKET_WIDTH
            if (bucket >= HISTOGRAM_BUCKET_COUNT) bucket = HISTOGRAM_BUCKET_COUNT - 1
            histCounts[bucket]++

            // 3. Kinematic state: stop counting
            if (speed > MIN_DRIVING_SPEED) wasMoving = true
            if (speed == 0 && wasMoving) {
                stopCount++
                wasMoving = false
            }

            // 3b. Elevation, sampled every ALT_SAMPLE_INTERVAL to smooth GPS altitude noise
            altSampleCounter++
            if (altSampleCounter >= ALT_SAMPLE_INTERVAL) {
                altSampleCounter = 0
                val alt = s.altitude
                if (alt != 0.0 && !alt.isNaN()) {
                    if (!lastValidAlt.isNaN()) {
                        val delta = alt - lastValidAlt
                        if (abs(delta) >= ALT_NOISE_THRESHOLD) {
                            if (delta > 0) elevationGain += delta else elevationLoss += abs(delta)
                            lastValidAlt = alt
                        }
                    } else {
                        lastValidAlt = alt
                    }
                }
            }

            // 4. Pedal jerk (smoothness)
            if (i > 0) {
                pedalJerkSum += abs(accel - lastAccel) + abs(brake - lastBrake)
            }

            // 5. Coast gap (anticipation). EV-aware: accel below 5% is lifting off into regen.
            // Coasting ends on the brake OR on re-applied power — one-pedal driving.
            if (accel < 5 && brake == 0 && speed > MIN_DRIVING_SPEED) {
                if (coastStartTime == null) coastStartTime = s.timestampMs
            } else if ((brake > 0 || accel >= 15) && coastStartTime != null) {
                val gapMs = s.timestampMs - coastStartTime!!
                val gapSec = gapMs / 1000.0
                if (gapSec > 0 && gapSec < MAX_COAST_GAP_SECONDS) {
                    coastGapSumMs += gapMs
                    coastGapCount++
                }
                coastStartTime = null
            } else if (accel in 5..14) {
                // Light throttle: not a coast-end, just cancel the tracking.
                coastStartTime = null
            }

            // 6. Launch profile capture (micro-moments)
            if (launchCaptureRemaining > 0) {
                launchCurveBuffer!!.add(accel)
                if (accel > launchPeakAccel) launchPeakAccel = accel
                launchCaptureRemaining--
                if (launchCaptureRemaining == 0) {
                    microMoments.launches.add(
                        finishLaunch(launchStartTime, launchPeakAccel, launchCurveBuffer!!)
                    )
                }
            } else {
                if (speed == 0) {
                    wasStationary = true
                } else if (wasStationary && speed > MIN_DRIVING_SPEED) {
                    launchStartTime = s.timestampMs
                    launchPeakAccel = accel
                    launchCurveBuffer = ArrayList<Int>(LAUNCH_PROFILE_SAMPLES).also { it.add(accel) }
                    launchCaptureRemaining = LAUNCH_PROFILE_SAMPLES - 1
                    wasStationary = false
                }
                if (speed > 0) wasStationary = false
            }

            // 7. Coast-brake events (micro-moments)
            if (accel < 5 && brake == 0 && mmCoastStartTime == null && speed > MIN_DRIVING_SPEED) {
                mmCoastStartTime = s.timestampMs
            }
            if (brake > 0 && mmCoastStartTime != null) {
                val gapMs = s.timestampMs - mmCoastStartTime!!
                if (gapMs > 0 && gapMs < (MAX_COAST_GAP_SECONDS * 1000).toLong()) {
                    microMoments.coastBrakeEvents.add(
                        MicroMoments.CoastBrakeEvent().apply {
                            coastGapMs = gapMs
                            speedAtBrake = speed
                        }
                    )
                }
                mmCoastStartTime = null
            }
            if (accel >= 5) mmCoastStartTime = null

            // 8. Speed discipline: rolling window via circular buffer
            val isDriving = speed > MIN_DRIVING_SPEED
            val circIdx = i % SD_WINDOW_SIZE

            if (i >= SD_WINDOW_SIZE && sdWindowIsDriving[circIdx]) {
                val oldSpeed = sdWindowSpeeds[circIdx]
                sdWindowDrivingCount--
                sdWindowSum -= oldSpeed
                sdWindowSumSq -= oldSpeed.toDouble() * oldSpeed
            }

            sdWindowSpeeds[circIdx] = speed
            sdWindowIsDriving[circIdx] = isDriving
            if (isDriving) {
                sdWindowDrivingCount++
                sdWindowSum += speed
                sdWindowSumSq += speed.toDouble() * speed
            }

            sdStepCounter++
            if (i >= SD_WINDOW_SIZE - 1 && sdStepCounter >= SD_WINDOW_STEP) {
                sdStepCounter = 0
                if (sdWindowDrivingCount >= SD_MIN_DRIVING) {
                    val mean = sdWindowSum / sdWindowDrivingCount
                    var variance = (sdWindowSumSq / sdWindowDrivingCount) - (mean * mean)
                    if (variance < 0) variance = 0.0 // floating-point guard
                    sdTotalScore += sqrt(variance)
                    sdWindowCount++
                }
            }

            // 9. Pedal smoothness: rolling window via circular buffer
            val smoothCircIdx = i % SMOOTH_WINDOW_SIZE
            smoothWindowAccel[smoothCircIdx] = accel
            smoothWindowDriving[smoothCircIdx] = isDriving

            smoothStepCounter++
            if (i >= SMOOTH_WINDOW_SIZE - 1 && smoothStepCounter >= SMOOTH_WINDOW_STEP) {
                smoothStepCounter = 0
                var drivingCount = 0
                var aSum = 0.0
                var aSumSq = 0.0
                for (w in 0 until SMOOTH_WINDOW_SIZE) {
                    if (smoothWindowDriving[w]) {
                        drivingCount++
                        aSum += smoothWindowAccel[w]
                        aSumSq += smoothWindowAccel[w].toDouble() * smoothWindowAccel[w]
                    }
                }
                if (drivingCount >= SMOOTH_MIN_DRIVING) {
                    val aMean = aSum / drivingCount
                    var aVar = (aSumSq / drivingCount) - (aMean * aMean)
                    if (aVar < 0) aVar = 0.0
                    microMoments.smoothnessWindows.add(
                        MicroMoments.PedalSmoothnessWindow().apply {
                            startTime = samples[max(0, i - SMOOTH_WINDOW_SIZE + 1)].timestampMs
                            stdDev = sqrt(aVar)
                        }
                    )
                }
            }

            lastAccel = accel
            lastBrake = brake
        }
        // ───────────────── END SINGLE PASS ─────────────────

        // Finalise an in-progress launch (the trip ended mid-launch).
        launchCurveBuffer?.let { buf ->
            if (launchCaptureRemaining > 0 && buf.isNotEmpty()) {
                microMoments.launches.add(finishLaunch(launchStartTime, launchPeakAccel, buf))
            }
        }

        // ── Kinematic state ──
        val avgSpeedKmh =
            if (trip.durationSeconds > 0) trip.distanceKm / (trip.durationSeconds / 3600.0) else 0.0
        val stopsPerKm = if (trip.distanceKm > 0) stopCount / trip.distanceKm else 0.0

        val kinState = when {
            avgSpeedKmh < 22 && stopsPerKm >= 1.5 -> KinematicState.HEAVY_GRIDLOCK
            avgSpeedKmh > 75 && stopsPerKm <= 0.2 -> KinematicState.HIGHWAY_CRUISING
            else -> KinematicState.URBAN_FLOW
        }
        trip.kinematicState = kinState.name

        // ── Gradient profile ──
        val gainPerKm = if (trip.distanceKm > 0) elevationGain / trip.distanceKm else 0.0
        val lossPerKm = if (trip.distanceKm > 0) elevationLoss / trip.distanceKm else 0.0
        val gradProfile = when {
            gainPerKm > 15 -> GradientProfile.MOUNTAIN_CLIMB
            lossPerKm > 15 -> GradientProfile.MOUNTAIN_DESCENT
            gainPerKm > 5 || lossPerKm > 5 -> GradientProfile.HILLY
            else -> GradientProfile.FLAT
        }
        trip.gradientProfile = gradProfile.name
        trip.elevationGainM = elevationGain
        trip.elevationLossM = elevationLoss
        trip.avgGradientPercent = if (trip.distanceKm > 0) {
            (elevationGain - elevationLoss) / (trip.distanceKm * 1000) * 100
        } else {
            0.0
        }

        // ── Gradient compensation ──
        // Adjusts thresholds by terrain so a driver is neither penalised nor over-rewarded for
        // physics they cannot control.
        //
        // CLIMB needs more energy, more pedal variation, less coasting opportunity.
        // DESCENT recovers energy through regen (bestEff can go NEGATIVE), and the driver
        // modulates that regen with the accelerator, so higher jerk is expected and there is
        // little coasting — speed is managed by regen, not by coasting to a stop.
        val efficiencyBestAdjust: Double
        val efficiencyGradientFactor: Double
        val smoothnessGradientFactor: Double
        val anticipationGradientFactor: Double
        when (gradProfile) {
            GradientProfile.MOUNTAIN_CLIMB -> {
                efficiencyBestAdjust = 0.0
                efficiencyGradientFactor = 1.6 // 60% wider efficiency range
                smoothnessGradientFactor = 1.4 // 40% more jerk tolerance
                anticipationGradientFactor = 0.6 // 40% shorter coast gap expected
            }
            GradientProfile.MOUNTAIN_DESCENT -> {
                efficiencyBestAdjust = -0.05 // a good driver should be net-negative kWh/km
                efficiencyGradientFactor = 1.0 // they should not be consuming much
                smoothnessGradientFactor = 1.35 // regen modulation moves the pedal
                anticipationGradientFactor = 0.5 // very little coasting
            }
            GradientProfile.HILLY -> {
                efficiencyBestAdjust = 0.0
                efficiencyGradientFactor = 1.25
                smoothnessGradientFactor = 1.15
                anticipationGradientFactor = 0.85
            }
            GradientProfile.FLAT -> {
                efficiencyBestAdjust = 0.0
                efficiencyGradientFactor = 1.0
                smoothnessGradientFactor = 1.0
                anticipationGradientFactor = 1.0
            }
        }

        trip.avgSpeedKmh = sumSpeed.toDouble() / n
        trip.maxSpeedKmh = maxSpeed

        // ───────────── SCORES, all from accumulators, no re-iteration ─────────────

        // A. Anticipation — coast gap before braking, gradient-adjusted.
        var targetGapMs = when (kinState) {
            KinematicState.HEAVY_GRIDLOCK -> 800.0
            KinematicState.HIGHWAY_CRUISING -> 1500.0
            else -> 2500.0
        }
        targetGapMs *= anticipationGradientFactor
        trip.anticipationScore = if (targetGapMs <= 0) {
            DEFAULT_SCORE
        } else if (coastGapCount >= MIN_COAST_TRANSITIONS) {
            val avgGapMs = coastGapSumMs.toDouble() / coastGapCount
            clamp((avgGapMs / targetGapMs * 100).roundToInt(), 0, 100)
        } else {
            DEFAULT_SCORE
        }

        // B. Smoothness — pedal jerk integral, lower is smoother.
        // Normalised by the ACTUAL elapsed time from timestamps, not an assumed 5Hz rate: the
        // CPU governor and GC make the polling interval jitter.
        val actualDurationMs = samples[n - 1].timestampMs - samples[0].timestampMs
        var durationSec = actualDurationMs / 1000.0
        if (durationSec < 1) durationSec = 1.0
        val normalizedJerk = pedalJerkSum / durationSec
        var maxJerk = when (kinState) {
            KinematicState.HEAVY_GRIDLOCK -> 20.0
            KinematicState.HIGHWAY_CRUISING -> 8.0
            else -> 12.0
        }
        maxJerk *= smoothnessGradientFactor
        trip.smoothnessScore = clamp(((1.0 - normalizedJerk / maxJerk) * 100).roundToInt(), 0, 100)

        // C. Speed discipline — mean of the per-window standard deviations.
        val maxStdDev = when (kinState) {
            KinematicState.HEAVY_GRIDLOCK -> 20.0
            KinematicState.HIGHWAY_CRUISING -> 12.0
            else -> 16.0
        }
        trip.speedDisciplineScore = if (sdWindowCount > 0) {
            val avgStdDev = sdTotalScore / sdWindowCount
            clamp(((1.0 - avgStdDev / maxStdDev) * 100).roundToInt(), 0, 100)
        } else {
            DEFAULT_SCORE
        }

        // D. Efficiency — kWh/km against realistic BYD EV baselines, gradient-adjusted. Uphill
        // widens the acceptable range; downhill shifts bestEff below zero, because a good driver
        // should be GAINING battery on a descent.
        val energyUsed = trip.getEnergyUsedKwh()
        if (energyUsed > 0 && trip.distanceKm >= MIN_EFFICIENCY_DISTANCE) {
            val kwhPerKm = energyUsed / trip.distanceKm
            var bestEff: Double
            var worstEff: Double
            when (kinState) {
                KinematicState.HEAVY_GRIDLOCK -> { bestEff = 0.10; worstEff = 0.35 }
                KinematicState.HIGHWAY_CRUISING -> { bestEff = 0.14; worstEff = 0.35 }
                else -> { bestEff = 0.11; worstEff = 0.32 }
            }
            bestEff += efficiencyBestAdjust
            worstEff *= efficiencyGradientFactor
            val effRange = worstEff - bestEff
            trip.efficiencyScore = if (effRange <= 0) {
                100
            } else {
                clamp(((worstEff - kwhPerKm) / effRange * 100).roundToInt(), 0, 100)
            }
        } else if (trip.distanceKm >= MIN_EFFICIENCY_DISTANCE) {
            val socDelta = trip.socStart - trip.socEnd
            trip.efficiencyScore = if (socDelta > 0) {
                val consumptionPerKm = socDelta / trip.distanceKm
                clamp(((3.5 - consumptionPerKm) / 3.0 * 100).roundToInt(), 0, 100)
            } else {
                DEFAULT_SCORE
            }
        } else {
            trip.efficiencyScore = DEFAULT_SCORE
        }

        // E. Consistency — computed later, with recent trips from the DB.
        trip.consistencyScore = DEFAULT_SCORE

        trip.microMomentsJson = microMoments.toJson().toString()

        logger.info(
            "Scores [" + kinState + "/" + gradProfile +
                " avgSpd=" + String.format("%.0f", avgSpeedKmh) +
                " stops/km=" + String.format("%.1f", stopsPerKm) +
                " elev+" + String.format("%.0f", elevationGain) +
                "/-" + String.format("%.0f", elevationLoss) + "m" +
                " gain/km=" + String.format("%.1f", gainPerKm) +
                " loss/km=" + String.format("%.1f", lossPerKm) + "] " +
                "A=" + trip.anticipationScore + " S=" + trip.smoothnessScore +
                " SD=" + trip.speedDisciplineScore + " E=" + trip.efficiencyScore +
                " C=" + trip.consistencyScore
        )

        return trip
    }

    private fun finishLaunch(startMs: Long, peakAccel: Int, curve: List<Int>):
        MicroMoments.LaunchProfile = MicroMoments.LaunchProfile().apply {
        startTime = startMs
        peakAccelPercent = peakAccel
        accelCurve = curve.toIntArray()
    }

    /**
     * Consistency score: percentage deviation from the rolling average.
     *
     * Uses `energyPerKm` when available, falling back to `efficiencySocPerKm`. Percentage-based
     * so a 0.02 kWh/km deviation on a 0.15 average (~13%) scores the same as 0.04 on 0.30
     * (~13%). 0% deviation scores 100; 50% or more scores 0.
     */
    fun computeConsistency(currentEfficiency: Double, recentTrips: List<TripRecord>?): Int {
        if (recentTrips == null || recentTrips.size < MIN_RECENT_TRIPS_FOR_CONSISTENCY) {
            return DEFAULT_SCORE
        }

        val useKwh = currentEfficiency > 0 && currentEfficiency < 1
        var sum = 0.0
        var count = 0
        for (t in recentTrips) {
            val v = if (useKwh) t.energyPerKm else t.efficiencySocPerKm
            if (v > 0) {
                sum += v
                count++
            }
        }
        if (count < MIN_RECENT_TRIPS_FOR_CONSISTENCY) return DEFAULT_SCORE

        val avgEfficiency = sum / count
        val deviation = abs(currentEfficiency - avgEfficiency)
        val pctDeviation = if (avgEfficiency > 0) deviation / avgEfficiency else 0.0
        val maxPctDeviation = 0.50
        return clamp(((1.0 - pctDeviation / maxPctDeviation) * 100).roundToInt(), 0, 100)
    }

    /**
     * Speed histogram as per-bucket PERCENTAGES.
     *
     * A lightweight post-processing step — the counting inside [computeSummary] is the one that
     * runs on the hot path.
     */
    internal fun computeSpeedHistogram(samples: List<TelemetrySample>): IntArray {
        val counts = IntArray(HISTOGRAM_BUCKET_COUNT)
        for (s in samples) {
            var bucket = s.speedKmh / HISTOGRAM_BUCKET_WIDTH
            if (bucket >= HISTOGRAM_BUCKET_COUNT) bucket = HISTOGRAM_BUCKET_COUNT - 1
            counts[bucket]++
        }
        val pct = IntArray(HISTOGRAM_BUCKET_COUNT)
        val total = samples.size
        if (total > 0) {
            for (i in 0 until HISTOGRAM_BUCKET_COUNT) {
                pct[i] = (counts[i].toDouble() / total * 100).roundToInt()
            }
        }
        return pct
    }

    companion object {
        private val logger: DaemonLogger = DaemonLogger.getInstance("TripScoreEngine")

        private const val MIN_SAMPLES = 30
        private const val MIN_COAST_TRANSITIONS = 3
        private const val MAX_COAST_GAP_SECONDS = 30.0
        private const val MIN_DRIVING_SPEED = 3
        private const val MIN_EFFICIENCY_DISTANCE = 0.5
        private const val MIN_RECENT_TRIPS_FOR_CONSISTENCY = 2
        private const val LAUNCH_PROFILE_SAMPLES = 50
        private const val HISTOGRAM_BUCKET_WIDTH = 10
        private const val HISTOGRAM_BUCKET_COUNT = 11
        private const val DEFAULT_SCORE = 50

        /** 30 samples at 5Hz = 6 seconds. */
        private const val SD_WINDOW_SIZE = 30

        /** 50% overlap. */
        private const val SD_WINDOW_STEP = 15

        /** At least half the window must be driving. */
        private const val SD_MIN_DRIVING = 15

        /** 10 samples at 5Hz = 2 seconds. */
        private const val SMOOTH_WINDOW_SIZE = 10
        private const val SMOOTH_WINDOW_STEP = 5
        private const val SMOOTH_MIN_DRIVING = 5

        /** Minimum altitude delta that counts — filters GPS noise at roughly 2m accuracy. */
        private const val ALT_NOISE_THRESHOLD = 2.0

        /** Every 5th sample at 5Hz = 1 second, to reduce GPS jitter. */
        private const val ALT_SAMPLE_INTERVAL = 5

        @JvmStatic
        internal fun clamp(value: Int, min: Int, max: Int): Int = max(min, min(max, value))
    }
}
