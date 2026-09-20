package net.bladewatch.app.notifications;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import net.bladewatch.app.trips.TripRecord;

import org.json.JSONObject;
import org.junit.Test;

import java.io.File;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

/**
 * BladeWatch-nmao.3: {@link TripEventNotifier} publishes trip lifecycle events, modelled on
 * {@code ChargingEventNotifier}. {@code NotificationBus.publish} dispatches asynchronously on
 * its own executor, so assertions wait on a latch rather than sleeping a fixed amount.
 */
public class TripEventNotifierTest {

    private static final class CapturingSink implements NotificationBus.Sink {
        final List<NotificationEvent> events = new CopyOnWriteArrayList<>();
        final CountDownLatch latch;
        CapturingSink(int expectedCount) { latch = new CountDownLatch(expectedCount); }
        public void onNotification(NotificationEvent event) {
            events.add(event);
            latch.countDown();
        }
    }

    @Test
    public void onTripEnded_publishesExactlyOneEvent_withTripsEndedCategory() throws InterruptedException {
        CapturingSink sink = new CapturingSink(1);
        NotificationBus.get().subscribe(sink);
        try {
            TripRecord trip = new TripRecord();
            trip.distanceKm = 12.3;
            trip.durationSeconds = 900;

            TripEventNotifier.getInstance().onTripEnded(trip);

            assertTrue("event did not arrive within timeout", sink.latch.await(2, TimeUnit.SECONDS));
            assertEquals(1, sink.events.size());
            assertEquals("trips.ended", sink.events.get(0).category);
        } finally {
            NotificationBus.get().unsubscribe(sink);
        }
    }

    @Test
    public void onTripDiscarded_publishesZeroEvents() throws InterruptedException {
        CapturingSink sink = new CapturingSink(1);
        NotificationBus.get().subscribe(sink);
        try {
            TripRecord trip = new TripRecord();

            TripEventNotifier.getInstance().onTripDiscarded(trip, "too short");

            // Negative case: confirm absence with a bounded wait, not a sleep guess.
            assertFalse("a discarded trip must not publish anything", sink.latch.await(300, TimeUnit.MILLISECONDS));
            assertTrue(sink.events.isEmpty());
        } finally {
            NotificationBus.get().unsubscribe(sink);
        }
    }

    @Test
    public void onTripEnded_payloadContainsDistanceAndDuration() throws Exception {
        CapturingSink sink = new CapturingSink(1);
        NotificationBus.get().subscribe(sink);
        try {
            TripRecord trip = new TripRecord();
            trip.distanceKm = 7.5;
            trip.durationSeconds = 600;

            TripEventNotifier.getInstance().onTripEnded(trip);

            assertTrue(sink.latch.await(2, TimeUnit.SECONDS));
            JSONObject data = sink.events.get(0).data;
            assertEquals(7.5, data.getDouble("distanceKm"), 0.0001);
            assertEquals(600, data.getInt("durationSeconds"));
        } finally {
            NotificationBus.get().unsubscribe(sink);
        }
    }

    @Test
    public void categoriesJson_hasTripsEndedAndStarted_bothDefaultOff() throws Exception {
        JSONObject root = readCategoriesJson();
        org.json.JSONArray categories = root.getJSONArray("categories");

        JSONObject tripsEnded = findCategory(categories, "trips.ended");
        JSONObject tripsStarted = findCategory(categories, "trips.started");

        assertTrue("trips.ended category missing from notifications-categories.json", tripsEnded != null);
        assertTrue("trips.started category missing from notifications-categories.json", tripsStarted != null);
        assertFalse("trips.ended must default off (fires every time the owner parks)",
                tripsEnded.getBoolean("defaultEnabled"));
        assertFalse("trips.started must default off",
                tripsStarted.getBoolean("defaultEnabled"));
    }

    /**
     * BladeWatch-vga1: the summary line used to be a hardcoded {@code "%.1f km - %d min"}, so an
     * owner configured for miles was shown a kilometre figure labelled km — a wrong number with
     * a wrong unit, and untranslated besides, unlike the title next to it. The conversion and
     * the catalog-key choice are pure statics precisely so they are testable here:
     * {@code Messages} reads its catalogs from {@code /data/local/tmp/web/server-i18n}, a device
     * path that does not exist in a JVM test, so asserting on a fully formatted sentence would
     * assert on nothing.
     */
    @Test
    public void distanceInUnit_convertsForMiles_andLeavesKilometresAlone() {
        assertEquals(12.3, TripEventNotifier.distanceInUnit(12.3, "km"), 0.0001);
        assertEquals("100 km is 62.14 mi", 62.1371,
                TripEventNotifier.distanceInUnit(100.0, "mi"), 0.001);
        assertEquals("an unrecognised unit must fall back to km, never silently convert",
                12.3, TripEventNotifier.distanceInUnit(12.3, "furlongs"), 0.0001);
    }

    @Test
    public void summaryKey_picksTheUnitSpecificCatalogEntry() {
        assertEquals("notifications.trip_summary_km", TripEventNotifier.summaryKey("km"));
        assertEquals("notifications.trip_summary_mi", TripEventNotifier.summaryKey("mi"));
        assertEquals("notifications.trip_summary_km", TripEventNotifier.summaryKey(""));
    }

    /** Both keys must exist in every locale — {@code validateI18nCatalogs} covers parity
     *  against en, but only for keys that are in en to begin with. */
    @Test
    public void bothTripSummaryKeys_carryTheUnitWordInEveryLocale() throws Exception {
        Path dir = Path.of("src/main/assets/server-i18n");
        if (!Files.isDirectory(dir)) dir = Path.of("app/src/main/assets/server-i18n");
        assertTrue("could not locate server-i18n from " + new File(".").getAbsolutePath(),
                Files.isDirectory(dir));

        int checked = 0;
        for (Path f : Files.newDirectoryStream(dir, "*.json")) {
            JSONObject notifications =
                    new JSONObject(new String(Files.readAllBytes(f), StandardCharsets.UTF_8))
                            .getJSONObject("notifications");
            for (String key : List.of("trip_summary_km", "trip_summary_mi")) {
                String value = notifications.optString(key, null);
                assertTrue(f.getFileName() + " is missing notifications." + key, value != null);
                assertTrue(f.getFileName() + "'s " + key + " must interpolate distance {0}",
                        value.contains("{0}"));
                assertTrue(f.getFileName() + "'s " + key + " must interpolate duration {1}",
                        value.contains("{1}"));
            }
            assertTrue(f.getFileName() + "'s trip_summary_km must carry the km unit word",
                    notifications.getString("trip_summary_km").contains("km"));
            checked++;
        }
        assertEquals("expected all 17 server-i18n locales", 17, checked);
    }

    private static JSONObject findCategory(org.json.JSONArray categories, String id) throws Exception {
        for (int i = 0; i < categories.length(); i++) {
            JSONObject c = categories.getJSONObject(i);
            if (id.equals(c.optString("id"))) return c;
        }
        return null;
    }

    private static JSONObject readCategoriesJson() throws Exception {
        Path p = Path.of("src/main/assets/notifications-categories.json");
        if (!Files.isRegularFile(p)) p = Path.of("app/src/main/assets/notifications-categories.json");
        assertTrue("could not locate notifications-categories.json from "
                + new File(".").getAbsolutePath(), Files.isRegularFile(p));
        String text = new String(Files.readAllBytes(p), StandardCharsets.UTF_8);
        return new JSONObject(text);
    }
}
