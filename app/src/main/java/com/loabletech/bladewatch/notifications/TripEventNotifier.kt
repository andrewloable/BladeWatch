package net.bladewatch.app.notifications

import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.server.Messages
import net.bladewatch.app.trips.TripConfig
import net.bladewatch.app.trips.TripDetector
import net.bladewatch.app.trips.TripRecord
import org.json.JSONObject
import java.util.Locale

/**
 * Publishes `trips.started` / `trips.ended` notifications from [TripDetector.TripListener]
 * callbacks. Modelled on `ChargingEventNotifier`: a pure downstream consumer that never mutates
 * trip state.
 *
 * Discarded trips (below the minimum duration/distance thresholds) are not real trips from the
 * owner's perspective and never publish anything.
 */
class TripEventNotifier private constructor() : TripDetector.TripListener {

    override fun onTripStarted(trip: TripRecord) {
        val data = JSONObject()
        try {
            data.put("startTime", trip.startTime)
        } catch (ignored: Exception) {
            logger.warn("Failed to build trip started event data: " + ignored.message)
        }
        publish("trips.started", Messages.get("notifications.trip_started"), "", data)
    }

    override fun onTripEnded(trip: TripRecord) {
        val data = JSONObject()
        try {
            data.put("distanceKm", trip.distanceKm)
            data.put("durationSeconds", trip.durationSeconds)
            if (trip.energyPerKm > 0) data.put("energyPerKm", trip.energyPerKm)
        } catch (ignored: Exception) {
            logger.warn("Failed to build trip ended event data: " + ignored.message)
        }
        publish("trips.ended", Messages.get("notifications.trip_ended"), formatSummary(trip), data)
    }

    override fun onTripDiscarded(trip: TripRecord, reason: String) {
        // Below minimum duration/distance -- not a real trip. Publish nothing.
    }

    companion object {
        private val logger: DaemonLogger = DaemonLogger.getInstance("TripEventNotifier")
        private val INSTANCE = TripEventNotifier()

        @JvmStatic
        fun getInstance(): TripEventNotifier = INSTANCE

        /** 1 mile in kilometres — the same constant `BydDataCollector` uses. */
        private const val MILES_TO_KM = 1.60934

        /**
         * `trip.distanceKm` expressed in the owner's configured unit. Pure, with the unit passed
         * in rather than read from [TripConfig], so the conversion is testable off-device.
         * Anything other than "mi" means kilometres — an unrecognised unit must never silently
         * convert.
         */
        @JvmStatic
        fun distanceInUnit(distanceKm: Double, unit: String?): Double =
            if ("mi" == unit) distanceKm / MILES_TO_KM else distanceKm

        /**
         * Catalog key for the summary line. The unit word lives in the catalog rather than in
         * this file so translators localise it, matching `notifications.charging_started`'s
         * "{0} kW" shape — the pattern `ChargingEventNotifier` already follows.
         */
        @JvmStatic
        fun summaryKey(unit: String?): String =
            if ("mi" == unit) "notifications.trip_summary_mi" else "notifications.trip_summary_km"

        /** Owner's configured distance unit, or "km" if the config cannot be read. */
        private fun distanceUnit(): String = try {
            TripConfig().apply { load() }.getDistanceUnit()
        } catch (t: Throwable) {
            logger.warn("Failed to read distance unit, defaulting to km: " + t.message)
            "km"
        }

        private fun formatSummary(trip: TripRecord): String {
            val unit = distanceUnit()
            val minutes = trip.durationSeconds / 60
            // Both args pre-formatted as strings: MessageFormat would otherwise apply locale
            // digit grouping to a bare number ("1,000 min" on a 16-hour trip).
            return Messages.get(
                summaryKey(unit),
                String.format(Locale.US, "%.1f", distanceInUnit(trip.distanceKm, unit)),
                minutes.toString()
            )
        }

        private fun publish(category: String, title: String, body: String, data: JSONObject) {
            try {
                NotificationBus.get().publish(
                    NotificationEvent(
                        category, NotificationEvent.Severity.INFO, title, body, null, "/trips", data
                    )
                )
            } catch (t: Throwable) {
                logger.warn("Failed to publish trip notification: " + t.message)
            }
        }
    }
}
