package net.bladewatch.app.notifications

import net.bladewatch.app.surveillance.Actor
import net.bladewatch.app.surveillance.SurveillanceConfig

/**
 * Decides whether a recording's peak severity warrants a push notification, given the
 * user-configured tier toggles.
 *
 * A single decision function, so the rule lives in one place. Defaults match the
 * [SurveillanceConfig] defaults: NOTICE off, ALERT on, CRITICAL on.
 */
object NotificationGate {

    @JvmStatic
    fun shouldPush(sev: Actor.Severity?, cfg: SurveillanceConfig?): Boolean {
        if (cfg == null) {
            // Null config means "config not yet loaded" — never silently drop a notification on
            // the user, especially since the start-stage banner already published unconditionally
            // on a null config. Suppressing the final stage would leave the user with a stale
            // "Recording in progress…" banner that never gets replaced.
            return true
        }
        if (sev == null) return true // unknown severity → don't drop
        return when (sev) {
            Actor.Severity.CRITICAL -> cfg.isPushCritical
            Actor.Severity.ALERT -> cfg.isPushAlerts
            Actor.Severity.NOTICE -> cfg.isPushNotices
            else -> false
        }
    }

    /** Convenience: derive recording-level severity from a list of actors and decide. */
    @JvmStatic
    fun shouldPush(actors: List<Actor>?, cfg: SurveillanceConfig?): Boolean =
        shouldPush(maxSeverity(actors), cfg)

    @JvmStatic
    fun maxSeverity(actors: List<Actor>?): Actor.Severity {
        if (actors == null || actors.isEmpty()) return Actor.Severity.NOTICE
        var max = Actor.Severity.NOTICE
        for (a in actors) {
            val peak = a.peakSeverity
            if (peak != null && peak.ordinal > max.ordinal) {
                max = peak
            }
        }
        return max
    }
}
