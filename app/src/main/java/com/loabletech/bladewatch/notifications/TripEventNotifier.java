package net.bladewatch.app.notifications;

import net.bladewatch.app.logging.DaemonLogger;
import net.bladewatch.app.server.Messages;
import net.bladewatch.app.trips.TripDetector;
import net.bladewatch.app.trips.TripRecord;

import org.json.JSONObject;

/**
 * Publishes {@code trips.started} / {@code trips.ended} notifications from
 * {@link TripDetector.TripListener} callbacks. Modelled on {@code ChargingEventNotifier}: a
 * pure downstream consumer that never mutates trip state.
 *
 * <p>Discarded trips (below the minimum duration/distance thresholds) are not real trips from
 * the owner's perspective and never publish anything.
 */
public final class TripEventNotifier implements TripDetector.TripListener {

    private static final DaemonLogger logger = DaemonLogger.getInstance("TripEventNotifier");
    private static final TripEventNotifier INSTANCE = new TripEventNotifier();

    public static TripEventNotifier getInstance() { return INSTANCE; }

    private TripEventNotifier() {}

    @Override
    public void onTripStarted(TripRecord trip) {
        JSONObject data = new JSONObject();
        try {
            data.put("startTime", trip.startTime);
        } catch (Exception ignored) {
            logger.warn("Failed to build trip started event data: " + ignored.getMessage());
        }
        publish("trips.started", Messages.get("notifications.trip_started"), "", data);
    }

    @Override
    public void onTripEnded(TripRecord trip) {
        JSONObject data = new JSONObject();
        try {
            data.put("distanceKm", trip.distanceKm);
            data.put("durationSeconds", trip.durationSeconds);
            if (trip.energyPerKm > 0) data.put("energyPerKm", trip.energyPerKm);
        } catch (Exception ignored) {
            logger.warn("Failed to build trip ended event data: " + ignored.getMessage());
        }
        publish("trips.ended", Messages.get("notifications.trip_ended"), formatSummary(trip), data);
    }

    @Override
    public void onTripDiscarded(TripRecord trip, String reason) {
        // Below minimum duration/distance -- not a real trip. Publish nothing.
    }

    /** 1 mile in kilometres — the same constant {@code BydDataCollector} uses. */
    private static final double MILES_TO_KM = 1.60934;

    /**
     * [trip.distanceKm] expressed in the owner's configured unit. Pure, with the unit passed
     * in rather than read from {@link net.bladewatch.app.trips.TripConfig}, so the conversion
     * is testable off-device. Anything other than "mi" means kilometres — an unrecognised unit
     * must never silently convert.
     */
    static double distanceInUnit(double distanceKm, String unit) {
        return "mi".equals(unit) ? distanceKm / MILES_TO_KM : distanceKm;
    }

    /**
     * Catalog key for the summary line. The unit word lives in the catalog rather than in this
     * file so translators localise it, matching {@code notifications.charging_started}'s
     * "{0} kW" shape — the pattern {@code ChargingEventNotifier} already follows.
     */
    static String summaryKey(String unit) {
        return "mi".equals(unit) ? "notifications.trip_summary_mi" : "notifications.trip_summary_km";
    }

    /** Owner's configured distance unit, or "km" if the config cannot be read. */
    private static String distanceUnit() {
        try {
            net.bladewatch.app.trips.TripConfig config = new net.bladewatch.app.trips.TripConfig();
            config.load();
            return config.getDistanceUnit();
        } catch (Throwable t) {
            logger.warn("Failed to read distance unit, defaulting to km: " + t.getMessage());
            return "km";
        }
    }

    private static String formatSummary(TripRecord trip) {
        String unit = distanceUnit();
        long minutes = trip.durationSeconds / 60;
        // Both args pre-formatted as strings: MessageFormat would otherwise apply locale
        // digit grouping to a bare number ("1,000 min" on a 16-hour trip).
        return Messages.get(summaryKey(unit),
                String.format(java.util.Locale.US, "%.1f", distanceInUnit(trip.distanceKm, unit)),
                String.valueOf(minutes));
    }

    private static void publish(String category, String title, String body, JSONObject data) {
        try {
            NotificationBus.get().publish(new NotificationEvent(
                    category, NotificationEvent.Severity.INFO, title, body, null, "/trips", data));
        } catch (Throwable t) {
            logger.warn("Failed to publish trip notification: " + t.getMessage());
        }
    }
}
