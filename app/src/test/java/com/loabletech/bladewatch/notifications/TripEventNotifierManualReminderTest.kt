package net.bladewatch.app.notifications

import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** BladeWatch-gklt.4: the reminder is published on the bus for the companion's inbox. */
class TripEventNotifierManualReminderTest {

    private class Sink(count: Int) : NotificationBus.Sink {
        val events = CopyOnWriteArrayList<NotificationEvent>()
        val latch = CountDownLatch(count)
        override fun onNotification(event: NotificationEvent) {
            events.add(event)
            latch.countDown()
        }
    }

    @Test
    fun `reminder is published as a warning in its own category`() {
        val sink = Sink(1)
        NotificationBus.get().subscribe(sink)
        try {
            TripEventNotifier.getInstance().onManualTripReminder("parked_30m", 1_700_000_000_000L)

            assertTrue(sink.latch.await(2, TimeUnit.SECONDS))
            val e = sink.events.single()
            assertEquals("trips.manual_reminder", e.category)
            assertEquals(NotificationEvent.Severity.WARN, e.severity)
            assertEquals("parked_30m", e.data.getString("reason"))
            assertEquals(1_700_000_000_000L, e.data.getLong("startTime"))
        } finally {
            NotificationBus.get().unsubscribe(sink)
        }
    }
}
