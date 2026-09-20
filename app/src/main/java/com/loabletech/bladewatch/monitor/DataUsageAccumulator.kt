package net.bladewatch.app.monitor

import java.util.Calendar
import java.util.TimeZone

/**
 * BladeWatch-t1lg.1: pure, Android-free accounting for BladeWatch's own monthly network usage.
 *
 * `TrafficStats` UID counters (or any cumulative-since-boot byte counter) reset to zero on every
 * reboot. A naive `total = current reading` is wrong after every restart, and a naive
 * `total += current - last` goes catastrophically negative after one. This class is the fix: on
 * a reboot/counter reset (`current < lastReading`), the whole current reading is credited as new
 * traffic rather than subtracted from — never negative, never double-counted.
 *
 * No `android.*` import anywhere in this file — that is this issue's own explicit design
 * requirement, so the reboot-handling logic (the actual risk here) is testable without a device.
 */
class DataUsageAccumulator {

    // @Volatile: sample() is only ever called from NetworkMonitor's single dedicated
    // DataUsageSampler thread, but the getters are read from arbitrary HTTP-handling threads
    // (NetworkMonitor.getDataUsageInfo(), called per /status request). Without a visibility
    // guarantee here, a reader thread has no happens-before relationship with the writer and
    // could observe a stale value indefinitely under the JVM memory model, not just briefly.
    @Volatile
    var lastReading: Long = -1L
        private set
    @Volatile
    var accumulatedThisMonth: Long = 0L
        private set
    @Volatile
    var lastMonthTotal: Long = 0L
        private set

    @Volatile
    private var currentMonthKey: Int = NO_MONTH
    @Volatile
    private var lastMonthKey: Int = NO_MONTH

    /**
     * Records one sample of a cumulative-since-boot byte counter taken at [nowMs] (epoch
     * millis, device-local time — used only to decide the local-time month).
     *
     * A negative [current] (e.g. `TrafficStats.UNSUPPORTED`, -1) is a bad reading, never a real
     * measurement, and is ignored entirely — it must never corrupt the running total or become
     * the new baseline. A data counter that silently reports garbage is worse than no counter.
     */
    fun sample(current: Long, nowMs: Long) {
        if (current < 0) return

        val monthKey = monthKeyFor(nowMs)
        if (currentMonthKey == NO_MONTH) {
            currentMonthKey = monthKey
        } else if (monthKey != currentMonthKey) {
            lastMonthTotal = accumulatedThisMonth
            lastMonthKey = currentMonthKey
            accumulatedThisMonth = 0L
            currentMonthKey = monthKey
        }

        val delta = if (lastReading < 0 || current < lastReading) {
            // First-ever sample, or a reboot/counter reset happened since the last sample:
            // nothing valid to subtract from, so the whole reading is credited as new traffic.
            current
        } else {
            current - lastReading
        }
        accumulatedThisMonth += delta
        lastReading = current
    }

    /** Restores previously persisted state (e.g. after a daemon restart). Does not itself
     * validate month-key ordering — callers are expected to have persisted a consistent state. */
    fun restore(lastReading: Long, accumulatedThisMonth: Long, currentMonthKey: Int, lastMonthTotal: Long, lastMonthKey: Int) {
        this.lastReading = lastReading
        this.accumulatedThisMonth = accumulatedThisMonth
        this.currentMonthKey = currentMonthKey
        this.lastMonthTotal = lastMonthTotal
        this.lastMonthKey = lastMonthKey
    }

    fun currentMonthKeyForPersistence(): Int = currentMonthKey
    fun lastMonthKeyForPersistence(): Int = lastMonthKey

    companion object {
        private const val NO_MONTH = -1

        /** year*12 + month, monotonically increasing across year boundaries so a plain integer
         * comparison is enough to detect a rollover — no need to compare (year, month) pairs. */
        private fun monthKeyFor(nowMs: Long): Int {
            val cal = Calendar.getInstance(TimeZone.getDefault())
            cal.timeInMillis = nowMs
            return cal.get(Calendar.YEAR) * 12 + cal.get(Calendar.MONTH)
        }
    }
}
