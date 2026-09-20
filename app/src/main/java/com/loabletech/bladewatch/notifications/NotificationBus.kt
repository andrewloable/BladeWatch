package net.bladewatch.app.notifications

import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.Executors

/**
 * In-process pub/sub for [NotificationEvent]s.
 *
 * v1 is in-process only (publishers and sinks both live in CameraDaemon). If a future emit source
 * lives in another process, a `NotificationIpcServer` can sit in front of this and forward.
 */
class NotificationBus private constructor() {

    fun interface Sink {
        fun onNotification(event: NotificationEvent)
    }

    private val sinks = CopyOnWriteArrayList<Sink>()
    private val executor = Executors.newSingleThreadExecutor { r ->
        Thread(r, "NotificationBus").apply { isDaemon = true }
    }

    fun subscribe(sink: Sink?) {
        if (sink != null && !sinks.contains(sink)) sinks.add(sink)
    }

    fun unsubscribe(sink: Sink?) {
        sinks.remove(sink)
    }

    fun publish(event: NotificationEvent?) {
        if (event == null) return
        // Fast path: zero sinks means no work would happen anyway. Skip the executor hop so
        // emit-side callers (surveillance, tyre) don't pay JSON / dispatch cost when notifications
        // aren't even initialised.
        if (sinks.isEmpty()) return
        try {
            executor.execute {
                for (s in sinks) {
                    try {
                        s.onNotification(event)
                    } catch (t: Throwable) {
                        // never let one sink kill the others
                        System.err.println("NotificationBus: sink error: " + t.message)
                    }
                }
            }
        } catch (t: Throwable) {
            // RejectedExecutionException at shutdown — defensive guard against late publishes
            System.err.println("NotificationBus: publish failed: " + t.message)
        }
    }

    companion object {
        private val INSTANCE = NotificationBus()

        @JvmStatic
        fun get(): NotificationBus = INSTANCE
    }
}
