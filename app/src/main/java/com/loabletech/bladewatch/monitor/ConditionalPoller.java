package net.bladewatch.app.monitor;

import net.bladewatch.app.logging.DaemonLogger;

import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;
import java.util.function.Supplier;

/**
 * Polls a value only while at least one subscriber wants it. Zero subscribers means no
 * scheduled task exists at all -- not a task that returns early; a no-op task still wakes the
 * CPU (BladeWatch-t1lg.2).
 *
 * <p>Modelled on Overdrive's {@code ConditionalPoller} (see
 * docs/evaluations/overdrive-automations.md): the one piece of that project's automation
 * subsystem that stands alone and pays for itself with none of the rest. This class does not
 * start an automation engine and must not grow condition/trigger/rule concepts.
 */
public final class ConditionalPoller<T> {

    private static final DaemonLogger logger = DaemonLogger.getInstance("ConditionalPoller");

    /** Returned by {@link #subscribe}; {@link #close} stops receiving samples. Idempotent. */
    public interface Subscription extends AutoCloseable {
        @Override
        void close();
    }

    private final String name;
    private final long intervalMs;
    private final Supplier<T> sample;
    private final ScheduledExecutorService executor;

    private final CopyOnWriteArrayList<Consumer<T>> subscribers = new CopyOnWriteArrayList<>();
    private final Object lock = new Object();
    private ScheduledFuture<?> task;
    private volatile T latest;
    private volatile boolean shutdown = false;

    public ConditionalPoller(String name, long intervalMs, Supplier<T> sample, ScheduledExecutorService executor) {
        this.name = name;
        this.intervalMs = intervalMs;
        this.sample = sample;
        this.executor = executor;
    }

    /**
     * Adds a subscriber. Starts the schedule if this is the first one, taking one sample
     * immediately so the first subscriber does not wait a full interval. A no-op that returns
     * an inert subscription if called after {@link #shutdown}.
     */
    public Subscription subscribe(Consumer<T> onSample) {
        if (shutdown) {
            return () -> { };
        }
        boolean isFirst;
        synchronized (lock) {
            isFirst = task == null;
            subscribers.add(onSample);
            if (!shutdown && task == null) {
                // First recurring tick after intervalMs -- the immediate sample below covers
                // "now", so the schedule itself must not also fire at delay 0 or a real
                // executor would double-sample on the first subscriber.
                task = executor.scheduleAtFixedRate(this::tick, intervalMs, intervalMs, TimeUnit.MILLISECONDS);
            }
        }
        // Synchronous, not scheduled: the first subscriber must not wait for the executor to
        // get around to running the task (immaterial for a real executor, but this is also
        // what makes the immediate sample deterministically testable against a fake one).
        if (isFirst) {
            tick();
        }
        return () -> unsubscribe(onSample);
    }

    private void unsubscribe(Consumer<T> onSample) {
        subscribers.remove(onSample);
        synchronized (lock) {
            if (subscribers.isEmpty() && task != null) {
                task.cancel(false);
                task = null;
            }
        }
    }

    private void tick() {
        T value;
        try {
            value = sample.get();
        } catch (Exception e) {
            logger.warn(name + ": sample failed: " + e.getMessage());
            return;
        }
        latest = value;
        // Per-subscriber try/catch, matching NotificationBus.publish's shape -- one throwing
        // subscriber must not stop the poll loop or starve the others.
        for (Consumer<T> c : subscribers) {
            try {
                c.accept(value);
            } catch (Exception e) {
                logger.warn(name + ": subscriber threw: " + e.getMessage());
            }
        }
    }

    /** Last sampled value, or null if never sampled. */
    public T latest() {
        return latest;
    }

    /** For tests and diagnostics. */
    public boolean isPolling() {
        synchronized (lock) {
            return task != null;
        }
    }

    /** Cancels the schedule permanently; subsequent {@link #subscribe} calls do not resurrect it. */
    public void shutdown() {
        shutdown = true;
        synchronized (lock) {
            if (task != null) {
                task.cancel(false);
                task = null;
            }
        }
        subscribers.clear();
    }
}
