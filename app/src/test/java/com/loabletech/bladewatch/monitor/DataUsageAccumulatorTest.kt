package net.bladewatch.app.monitor

import org.junit.Assert.assertEquals
import org.junit.Test
import java.util.Calendar
import java.util.TimeZone

/**
 * BladeWatch-t1lg.1: [DataUsageAccumulator] is the pure, Android-free accounting for
 * BladeWatch's own monthly network usage. TrafficStats' UID counters are cumulative since boot
 * and reset to zero on every reboot -- the whole risk here is that reset, and this is the
 * class the issue requires be testable without a device for exactly that reason.
 */
class DataUsageAccumulatorTest {

    /** A fixed millisecond timestamp for a given (year, month 1-12, day) in the default
     * timezone, so tests are deterministic regardless of the machine's own timezone. */
    private fun ms(year: Int, month: Int, day: Int): Long {
        val cal = Calendar.getInstance(TimeZone.getDefault())
        cal.clear()
        cal.set(year, month - 1, day, 12, 0, 0)
        return cal.timeInMillis
    }

    @Test
    fun `first ever sample credits the whole reading, not zero`() {
        val acc = DataUsageAccumulator()

        acc.sample(1000L, ms(2026, 9, 5))

        assertEquals(1000L, acc.accumulatedThisMonth)
        assertEquals(1000L, acc.lastReading)
    }

    @Test
    fun `a later sample in the same month adds only the delta`() {
        val acc = DataUsageAccumulator()
        acc.sample(1000L, ms(2026, 9, 5))

        acc.sample(1500L, ms(2026, 9, 6))

        assertEquals(1500L, acc.accumulatedThisMonth)
    }

    @Test
    fun `several samples in the same month sum their deltas`() {
        val acc = DataUsageAccumulator()
        acc.sample(1000L, ms(2026, 9, 1))
        acc.sample(1500L, ms(2026, 9, 5))
        acc.sample(1800L, ms(2026, 9, 10))

        acc.sample(2200L, ms(2026, 9, 15))

        // 1000 (first) + 500 + 300 + 400 = 2200, matching the final cumulative reading exactly
        // since nothing rebooted -- the running total and the raw counter delta must agree.
        assertEquals(2200L, acc.accumulatedThisMonth)
    }

    @Test
    fun `a reboot -- current less than last reading -- credits the new reading whole, never subtracts`() {
        val acc = DataUsageAccumulator()
        acc.sample(5000L, ms(2026, 9, 5))
        assertEquals(5000L, acc.accumulatedThisMonth)

        // Device rebooted; the cumulative-since-boot counter restarted near zero.
        acc.sample(200L, ms(2026, 9, 6))

        // 5000 (pre-reboot) + 200 (post-reboot, credited whole) = 5200. NOT 5000 - 200 = 4800,
        // and NOT silently reset to 200.
        assertEquals(5200L, acc.accumulatedThisMonth)
        assertEquals(200L, acc.lastReading)
    }

    @Test
    fun `a reboot never drives the month total negative`() {
        val acc = DataUsageAccumulator()
        acc.sample(100L, ms(2026, 9, 5))

        acc.sample(0L, ms(2026, 9, 6))

        assertEquals(100L, acc.accumulatedThisMonth)
    }

    @Test
    fun `crossing a month boundary rolls the finished month into lastMonthTotal and starts fresh`() {
        val acc = DataUsageAccumulator()
        acc.sample(1000L, ms(2026, 8, 20))
        acc.sample(4000L, ms(2026, 8, 31))
        assertEquals(4000L, acc.accumulatedThisMonth)

        acc.sample(4500L, ms(2026, 9, 1))

        assertEquals("August's finished total must be preserved", 4000L, acc.lastMonthTotal)
        assertEquals("September starts from this sample's delta, not August's total",
            500L, acc.accumulatedThisMonth)
    }

    @Test
    fun `a reboot landing exactly on a month rollover is credited to the new month, not the old one`() {
        val acc = DataUsageAccumulator()
        acc.sample(9000L, ms(2026, 8, 31))

        // Rebooted AND the month changed in the same sample.
        acc.sample(150L, ms(2026, 9, 1))

        assertEquals(9000L, acc.lastMonthTotal)
        assertEquals(150L, acc.accumulatedThisMonth)
    }

    @Test
    fun `a negative reading -- TrafficStats UNSUPPORTED sentinel -- is never applied`() {
        val acc = DataUsageAccumulator()
        acc.sample(1000L, ms(2026, 9, 5))

        acc.sample(-1L, ms(2026, 9, 6))

        assertEquals("a bad reading must never corrupt the running total", 1000L, acc.accumulatedThisMonth)
        assertEquals("a bad reading must never become the new baseline either", 1000L, acc.lastReading)
    }

    @Test
    fun `two consecutive month rollovers each carry their own finished total`() {
        val acc = DataUsageAccumulator()
        acc.sample(1000L, ms(2026, 7, 15))
        // July -> August rollover: July's total (1000) becomes lastMonthTotal; this sample's
        // own delta (2000 - 1000 = 1000) opens August.
        acc.sample(2000L, ms(2026, 8, 1))
        assertEquals(1000L, acc.lastMonthTotal)
        acc.sample(2000L, ms(2026, 8, 20))  // no-op delta, August stays at 1000

        // August -> September rollover: August's finished total (1000) becomes lastMonthTotal,
        // overwriting July's; this sample's own delta (2600 - 2000 = 600) opens September.
        acc.sample(2600L, ms(2026, 9, 1))

        assertEquals("lastMonthTotal must now be August's total, not July's", 1000L, acc.lastMonthTotal)
        assertEquals(600L, acc.accumulatedThisMonth)
    }
}
