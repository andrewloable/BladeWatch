package net.bladewatch.app.monitor

import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * BladeWatch-1996: the battery refresh -- an IPC round trip to the surveillance daemon -- must never
 * make SystemService.GetStatus wait, except once, on the very first call.
 */
class BatteryMonitorTest {

    private var now = 1_000_000L
    private val fetches = AtomicInteger()

    @Before
    fun setUp() {
        BatteryMonitor.resetForTest()
        BatteryMonitor.clock = { now }
        BatteryMonitor.fetcher = { fetches.incrementAndGet() }
    }

    @After
    fun tearDown() = BatteryMonitor.resetForTest()

    @Test
    fun `the first call fetches inline, later calls within 30 s do not fetch at all`() {
        BatteryMonitor.getBatteryInfo()
        assertEquals(1, fetches.get())
        now += 29_000
        BatteryMonitor.getBatteryInfo()
        assertEquals(1, fetches.get())
    }

    @Test
    fun `a stale cache is refreshed in the background, and the caller never waits for it`() {
        BatteryMonitor.getBatteryInfo()
        val release = CountDownLatch(1)
        val started = CountDownLatch(1)
        BatteryMonitor.fetcher = {
            fetches.incrementAndGet()
            started.countDown()
            release.await(5, TimeUnit.SECONDS) // a slow IPC round trip
        }
        now += 31_000
        val t0 = System.nanoTime()
        BatteryMonitor.getBatteryInfo()
        val waitedMs = (System.nanoTime() - t0) / 1_000_000
        assertTrue("the refresh must not block GetStatus (waited $waitedMs ms)", waitedMs < 1_000)
        assertTrue(started.await(5, TimeUnit.SECONDS))

        now += 31_000 // stale again while the first refresh is still running: no second one
        BatteryMonitor.getBatteryInfo()
        release.countDown()
        assertEquals(2, fetches.get())
    }

    @Test
    fun `a failing refresh is not retried on every call`() {
        BatteryMonitor.getBatteryInfo() // the fake never updates the cache, like a failed fetch
        repeat(20) {
            now += 1_000
            BatteryMonitor.getBatteryInfo()
        }
        assertEquals("one attempt per 30 s, not one per call", 1, fetches.get())
    }
}
