package net.bladewatch.app.monitor

import net.bladewatch.app.logging.DaemonLogger
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.ScheduledExecutorService
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit
import java.util.function.Consumer
import java.util.function.Supplier

/**
 * Polls a value only while at least one subscriber wants it. Zero subscribers means no scheduled
 * task exists at all — not a task that returns early; a no-op task still wakes the CPU
 * (BladeWatch-t1lg.2).
 *
 * Modelled on Overdrive's ConditionalPoller (see docs/evaluations/overdrive-automations.md): the
 * one piece of that project's automation subsystem that stands alone and pays for itself with none
 * of the rest. This class does not start an automation engine and must not grow
 * condition/trigger/rule concepts.
 */
class ConditionalPoller<T>(
    private val name: String,
    private val intervalMs: Long,
    private val sample: Supplier<T>,
    private val executor: ScheduledExecutorService
) {

    /** Returned by [subscribe]; [close] stops receiving samples. Idempotent. */
    fun interface Subscription : AutoCloseable {
        override fun close()
    }

    private val subscribers = CopyOnWriteArrayList<Consumer<T>>()
    private val lock = Any()
    private var task: ScheduledFuture<*>? = null

    @Volatile
    private var latest: T? = null

    @Volatile
    private var shutdown = false

    /**
     * Add a subscriber. Starts the schedule if this is the first one, taking one sample
     * immediately so the first subscriber does not wait a full interval. A no-op that returns an
     * inert subscription if called after [shutdown].
     */
    fun subscribe(onSample: Consumer<T>): Subscription {
        if (shutdown) {
            return Subscription { }
        }
        var isFirst: Boolean
        synchronized(lock) {
            isFirst = task == null
            subscribers.add(onSample)
            if (!shutdown && task == null) {
                // First recurring tick after intervalMs — the immediate sample below covers "now",
                // so the schedule itself must not also fire at delay 0 or a real executor would
                // double-sample on the first subscriber.
                task = executor.scheduleAtFixedRate(
                    ::tick, intervalMs, intervalMs, TimeUnit.MILLISECONDS
                )
            }
        }
        // Synchronous, not scheduled: the first subscriber must not wait for the executor to get
        // around to running the task (immaterial for a real executor, but this is also what makes
        // the immediate sample deterministically testable against a fake one).
        if (isFirst) {
            tick()
        }
        return Subscription { unsubscribe(onSample) }
    }

    private fun unsubscribe(onSample: Consumer<T>) {
        subscribers.remove(onSample)
        synchronized(lock) {
            if (subscribers.isEmpty() && task != null) {
                task?.cancel(false)
                task = null
            }
        }
    }

    private fun tick() {
        val value: T = try {
            sample.get()
        } catch (e: Exception) {
            logger.warn(name + ": sample failed: " + e.message)
            return
        }
        latest = value
        // Per-subscriber try/catch, matching NotificationBus.publish's shape — one throwing
        // subscriber must not stop the poll loop or starve the others.
        for (c in subscribers) {
            try {
                c.accept(value)
            } catch (e: Exception) {
                logger.warn(name + ": subscriber threw: " + e.message)
            }
        }
    }

    /** The last sampled value, or null if never sampled. */
    fun latest(): T? = latest

    /** For tests and diagnostics. */
    fun isPolling(): Boolean = synchronized(lock) { task != null }

    /** Cancels the schedule permanently; subsequent [subscribe] calls do not resurrect it. */
    fun shutdown() {
        shutdown = true
        synchronized(lock) {
            task?.cancel(false)
            task = null
        }
        subscribers.clear()
    }

    private companion object {
        val logger: DaemonLogger = DaemonLogger.getInstance("ConditionalPoller")
    }
}
