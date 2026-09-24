package net.bladewatch.app.camera

import net.bladewatch.app.camera.PanoramicCameraGpu.WatchdogVerdict
import org.junit.Assert.assertEquals
import org.junit.Test

/**
 * BladeWatch-honj: a stop() that landed before start()'s GL init left a watchdog with no GL thread
 * to beat for it, and 10 s later it restarted a healthy daemon. The watchdog of a stopped start must
 * stand down -- and a genuinely hung GL thread of the current start must still restart the process.
 */
class GlWatchdogVerdictTest {

    @Test
    fun `a hung GL thread of the current start still restarts the process`() {
        assertEquals(WatchdogVerdict.HUNG, PanoramicCameraGpu.watchdogVerdict(3, 3, 10_001, 10_000))
    }

    @Test
    fun `the watchdog of a stopped start stands down however stale its heartbeat`() {
        assertEquals(WatchdogVerdict.SUPERSEDED, PanoramicCameraGpu.watchdogVerdict(3, 4, 10_001, 10_000))
        assertEquals(WatchdogVerdict.SUPERSEDED, PanoramicCameraGpu.watchdogVerdict(3, 5, 0, 10_000))
    }

    @Test
    fun `a heartbeat within the timeout is healthy`() {
        assertEquals(WatchdogVerdict.HEALTHY, PanoramicCameraGpu.watchdogVerdict(3, 3, 10_000, 10_000))
    }
}
