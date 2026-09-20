package net.bladewatch.app.surveillance

import net.bladewatch.app.surveillance.Actor.ClassGroup
import net.bladewatch.app.surveillance.Actor.Proximity
import net.bladewatch.app.surveillance.Actor.Severity
import net.bladewatch.app.surveillance.Actor.Trend

/**
 * The single source of truth for NOTICE / ALERT / CRITICAL.
 *
 * The rules are intentionally in one place so the CRITICAL definition can evolve (g-sensor, audio,
 * allowlist) without scattering edits across the codebase.
 *
 * No metric thresholds — proximity is pixel-relative.
 */
object SeverityClassifier {

    /**
     * Classify an in-flight tracker observation.
     *
     * @param classGroup coarse class
     * @param proximity last-frame proximity band
     * @param peakProximity closest approach across the actor's life
     * @param trend approach/recede/stable
     * @param isStatic the tracker's "no motion / no growth" verdict
     * @param dwellMs time spent at proximity at or above [peakProximity] (continuous)
     * @return the chosen severity
     */
    @JvmStatic
    fun classify(
        classGroup: ClassGroup,
        proximity: Proximity,
        peakProximity: Proximity,
        trend: Trend,
        isStatic: Boolean,
        dwellMs: Long
    ): Severity {
        if (classGroup == ClassGroup.UNKNOWN || classGroup == ClassGroup.ANIMAL) {
            return Severity.NOTICE
        }

        // SAFETY GATE — a static *non-person* actor never escalates above NOTICE.
        //
        // The classic FP this prevents: the user walks past their parked car next to two other
        // parked cars; YOLO sees all three vehicles plus the person, the cars are "very close" and
        // high-confidence, but they have NEVER MOVED. Without this gate, the thumbnail picker
        // chose the highest-confidence VERY_CLOSE actor — a car — masking the actual moving
        // person.
        //
        // CAREFUL: this rule must NOT apply to PERSON. A person standing perfectly still at the
        // driver door for 30 seconds hits isStatic=true after ~800 ms but is exactly the threat we
        // want CRITICAL to catch (loitering / tampering). The per-class rules below correctly fire
        // CRITICAL on a static person at VERY_CLOSE.
        if (isStatic && classGroup != ClassGroup.PERSON) {
            return Severity.NOTICE
        }

        // CRITICAL — physical threat hints (proximity + intent)
        if (classGroup == ClassGroup.PERSON) {
            // VERY_CLOSE is itself the threat signal; no dwell required.
            if (proximity == Proximity.VERY_CLOSE) {
                return Severity.CRITICAL
            }
            if (proximity == Proximity.CLOSE) {
                return Severity.ALERT
            }
            if (proximity == Proximity.MID && trend == Trend.APPROACHING) {
                return Severity.ALERT
            }
        }

        if (classGroup == ClassGroup.VEHICLE) {
            // Vehicles only escalate when actually moving toward the camera. Parked cars next to
            // ours stay at NOTICE.
            if (trend == Trend.APPROACHING && proximity == Proximity.VERY_CLOSE) {
                return Severity.ALERT
            }
            if (trend == Trend.APPROACHING && proximity == Proximity.CLOSE) {
                return Severity.ALERT
            }
        }

        if (classGroup == ClassGroup.BIKE) {
            if (proximity == Proximity.VERY_CLOSE && trend != Trend.STABLE) {
                return Severity.ALERT
            }
        }

        return Severity.NOTICE
    }

    /** Pick the higher of two severities. */
    @JvmStatic
    fun max(a: Severity?, b: Severity?): Severity? {
        if (a == null) return b
        if (b == null) return a
        return if (a.ordinal >= b.ordinal) a else b
    }
}
