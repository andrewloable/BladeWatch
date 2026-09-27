package net.bladewatch.app.monitor

import org.junit.Assert.assertEquals
import org.junit.Test

/** BladeWatch-rdtj.58: the app's CPU figure is a share of the same total as the system's. */
class AppCpuShareTest {
    @Test
    fun oneBusyCoreOfEightIsAnEighthOfTheMachine() {
        // 8 cores over one second at 100 jiffies/s: 800 jiffies in all. The app kept one core
        // busy (100); the system was half busy (50%). It used to read 50/50.
        assertEquals(12.5, appCpuSharePercent(appDelta = 100, cpuDelta = 800, systemPercent = 50.0), 1e-9)
    }

    @Test
    fun neverAboveTheSystemFigureNorBelowZero() {
        assertEquals(30.0, appCpuSharePercent(appDelta = 400, cpuDelta = 800, systemPercent = 30.0), 1e-9)
        assertEquals(0.0, appCpuSharePercent(appDelta = -5, cpuDelta = 800, systemPercent = 30.0), 1e-9)
    }

    @Test
    fun noElapsedTimeReadsZero() {
        assertEquals(0.0, appCpuSharePercent(appDelta = 10, cpuDelta = 0, systemPercent = 30.0), 1e-9)
    }
}
