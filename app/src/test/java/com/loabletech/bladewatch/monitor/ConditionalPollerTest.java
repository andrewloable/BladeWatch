package net.bladewatch.app.monitor;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import net.bladewatch.app.monitor.ConditionalPoller.Subscription;

import org.junit.Before;
import org.junit.Test;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.Delayed;
import java.util.concurrent.Future;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * BladeWatch-t1lg.2: {@link ConditionalPoller} against a hand-driven fake
 * {@link ScheduledExecutorService} -- no real-time delay anywhere in this file (a
 * sleep-based test for a poller is flaky by construction). Every tick is triggered by calling
 * {@link FakeScheduledExecutorService#tick()} directly.
 */
public class ConditionalPollerTest {

    private FakeScheduledExecutorService exec;
    private AtomicInteger sampleCalls;
    private ConditionalPoller<Integer> poller;

    @Before
    public void setUp() {
        exec = new FakeScheduledExecutorService();
        sampleCalls = new AtomicInteger(0);
        poller = new ConditionalPoller<>("test", 1000L, sampleCalls::incrementAndGet, exec);
    }

    @Test
    public void noSubscribers_notPolling_noTaskScheduled() {
        assertFalse(poller.isPolling());
        assertEquals(0, exec.scheduleCount);
    }

    @Test
    public void firstSubscribe_startsPolling_andSamplesImmediately() {
        List<Integer> received = new ArrayList<>();

        poller.subscribe(received::add);

        assertTrue(poller.isPolling());
        assertEquals(1, sampleCalls.get());
        assertEquals(List.of(1), received);
    }

    @Test
    public void twoSubscribers_supplierInvokedOncePerTick_bothReceiveSameValue() {
        List<Integer> a = new ArrayList<>();
        List<Integer> b = new ArrayList<>();
        poller.subscribe(a::add);
        poller.subscribe(b::add);
        int before = sampleCalls.get();

        exec.tick();

        assertEquals("supplier must be invoked exactly once for this tick", before + 1, sampleCalls.get());
        assertEquals(a.get(a.size() - 1), b.get(b.size() - 1));
    }

    @Test
    public void closingOneOfTwo_stillPolling() {
        Subscription s1 = poller.subscribe(v -> { });
        poller.subscribe(v -> { });

        s1.close();

        assertTrue(poller.isPolling());
    }

    @Test
    public void closingLastSubscriber_stopsPolling_andCancelsTask() {
        Subscription s = poller.subscribe(v -> { });
        FakeScheduledFuture future = exec.lastFuture;

        s.close();

        assertFalse(poller.isPolling());
        assertTrue(future.cancelled);
    }

    @Test
    public void closeThenSubscribeAgain_resumesAndSamplesImmediately() {
        Subscription s = poller.subscribe(v -> { });
        s.close();
        int before = sampleCalls.get();

        List<Integer> received = new ArrayList<>();
        poller.subscribe(received::add);

        assertTrue(poller.isPolling());
        assertEquals(before + 1, sampleCalls.get());
        assertEquals(1, received.size());
    }

    @Test
    public void closeTwice_noExceptionAndDoesNotStopEarlyForTheOther() {
        Subscription s1 = poller.subscribe(v -> { });
        poller.subscribe(v -> { });

        s1.close();
        s1.close(); // must not throw, must not affect the other subscriber

        assertTrue(poller.isPolling());
    }

    @Test
    public void throwingConsumer_doesNotBlockTheOtherConsumer_orStopPolling() {
        List<Integer> good = new ArrayList<>();
        poller.subscribe(v -> { throw new RuntimeException("boom"); });
        poller.subscribe(good::add);
        int before = good.size();

        exec.tick();
        exec.tick();

        assertTrue(poller.isPolling());
        assertEquals(before + 2, good.size());
    }

    @Test
    public void latest_nullBeforeFirstSample_thenMostRecentValue() {
        assertNull(poller.latest());

        poller.subscribe(v -> { });
        assertEquals(Integer.valueOf(1), poller.latest());

        exec.tick();
        assertEquals(Integer.valueOf(2), poller.latest());
    }

    @Test
    public void shutdown_cancelsTask_andSubscribeDoesNotResurrectIt() {
        poller.subscribe(v -> { });
        FakeScheduledFuture future = exec.lastFuture;

        poller.shutdown();
        poller.subscribe(v -> { });

        assertTrue(future.cancelled);
        assertFalse(poller.isPolling());
    }

    /** Captures exactly the one call ConditionalPoller makes (scheduleAtFixedRate); every other method throws. */
    static final class FakeScheduledExecutorService implements ScheduledExecutorService {
        Runnable scheduledTask;
        int scheduleCount = 0;
        FakeScheduledFuture lastFuture;

        void tick() {
            scheduledTask.run();
        }

        @Override
        public ScheduledFuture<?> scheduleAtFixedRate(Runnable command, long initialDelay, long period, TimeUnit unit) {
            scheduledTask = command;
            scheduleCount++;
            lastFuture = new FakeScheduledFuture();
            return lastFuture;
        }

        @Override public ScheduledFuture<?> schedule(Runnable command, long delay, TimeUnit unit) {
            throw new UnsupportedOperationException();
        }
        @Override public <V> ScheduledFuture<V> schedule(Callable<V> callable, long delay, TimeUnit unit) {
            throw new UnsupportedOperationException();
        }
        @Override public ScheduledFuture<?> scheduleWithFixedDelay(Runnable command, long initialDelay, long delay, TimeUnit unit) {
            throw new UnsupportedOperationException();
        }
        @Override public void shutdown() { throw new UnsupportedOperationException(); }
        @Override public List<Runnable> shutdownNow() { throw new UnsupportedOperationException(); }
        @Override public boolean isShutdown() { throw new UnsupportedOperationException(); }
        @Override public boolean isTerminated() { throw new UnsupportedOperationException(); }
        @Override public boolean awaitTermination(long timeout, TimeUnit unit) { throw new UnsupportedOperationException(); }
        @Override public <T> Future<T> submit(Callable<T> task) { throw new UnsupportedOperationException(); }
        @Override public <T> Future<T> submit(Runnable task, T result) { throw new UnsupportedOperationException(); }
        @Override public Future<?> submit(Runnable task) { throw new UnsupportedOperationException(); }
        @Override public <T> List<Future<T>> invokeAll(Collection<? extends Callable<T>> tasks) { throw new UnsupportedOperationException(); }
        @Override public <T> List<Future<T>> invokeAll(Collection<? extends Callable<T>> tasks, long timeout, TimeUnit unit) { throw new UnsupportedOperationException(); }
        @Override public <T> T invokeAny(Collection<? extends Callable<T>> tasks) { throw new UnsupportedOperationException(); }
        @Override public <T> T invokeAny(Collection<? extends Callable<T>> tasks, long timeout, TimeUnit unit) { throw new UnsupportedOperationException(); }
        @Override public void execute(Runnable command) { throw new UnsupportedOperationException(); }
    }

    static final class FakeScheduledFuture implements ScheduledFuture<Object> {
        boolean cancelled = false;

        @Override public long getDelay(TimeUnit unit) { return 0; }
        @Override public int compareTo(Delayed o) { return 0; }
        @Override public boolean cancel(boolean mayInterruptIfRunning) {
            cancelled = true;
            return true;
        }
        @Override public boolean isCancelled() { return cancelled; }
        @Override public boolean isDone() { return cancelled; }
        @Override public Object get() { throw new UnsupportedOperationException(); }
        @Override public Object get(long timeout, TimeUnit unit) { throw new UnsupportedOperationException(); }
    }
}
