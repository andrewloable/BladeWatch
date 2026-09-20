package net.bladewatch.app.notifications.sinks

import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.notifications.NotificationBus
import net.bladewatch.app.notifications.NotificationEvent

/**
 * Diagnostic sink — writes every notification to the daemon log so the bus's contents are
 * visible without depending on push delivery.
 */
class LogSink : NotificationBus.Sink {

    override fun onNotification(event: NotificationEvent) {
        logger.info(
            "notification " +
                event.severity.name + " " +
                event.category + " " +
                (if (event.tag == null) "" else "[" + event.tag + "] ") +
                event.title +
                (if (event.body.isEmpty()) "" else " — " + event.body)
        )
    }

    private companion object {
        val logger: DaemonLogger = DaemonLogger.getInstance("NotificationBus")
    }
}
