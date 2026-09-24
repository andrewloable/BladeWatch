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
 * BladeWatch-1996, the network half: the refresh can run `dumpsys wifi`, and GetStatus waited
 * 600-850 ms for it every ~11 s on the head unit. It must never make GetStatus wait, except once,
 * on the very first call.
 */
class NetworkMonitorRefreshTest {

    private var now = 1_000_000L
    private val refreshes = AtomicInteger()

    @Before
    fun setUp() {
        NetworkMonitor.resetForTest()
        NetworkMonitor.clock = { now }
        NetworkMonitor.refreshAction = { refreshes.incrementAndGet() }
    }

    @After
    fun tearDown() = NetworkMonitor.resetForTest()

    @Test
    fun `the first call refreshes inline, later calls within 10 s do not refresh at all`() {
        NetworkMonitor.getNetworkInfo()
        assertEquals(1, refreshes.get())
        now += 9_000
        NetworkMonitor.getNetworkInfo()
        assertEquals(1, refreshes.get())
    }

    @Test
    fun `a stale cache is refreshed in the background, and the caller never waits for it`() {
        NetworkMonitor.getNetworkInfo()
        val release = CountDownLatch(1)
        val started = CountDownLatch(1)
        NetworkMonitor.refreshAction = {
            refreshes.incrementAndGet()
            started.countDown()
            release.await(5, TimeUnit.SECONDS) // a slow dumpsys
        }
        now += 11_000
        val t0 = System.nanoTime()
        NetworkMonitor.getNetworkInfo()
        val waitedMs = (System.nanoTime() - t0) / 1_000_000
        assertTrue("the refresh must not block GetStatus (waited $waitedMs ms)", waitedMs < 1_000)
        assertTrue(started.await(5, TimeUnit.SECONDS))

        now += 11_000 // stale again while the first refresh is still running: no second one
        NetworkMonitor.getNetworkInfo()
        release.countDown()
        assertEquals(2, refreshes.get())
    }

    @Test
    fun `a failing refresh is not retried on every call`() {
        NetworkMonitor.getNetworkInfo() // the fake never updates the cache, like a failed refresh
        repeat(20) {
            now += 400
            NetworkMonitor.getNetworkInfo()
        }
        assertEquals("one attempt per 10 s, not one per call", 1, refreshes.get())
    }
}
