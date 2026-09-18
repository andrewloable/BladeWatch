package net.bladewatch.app.byd.routing

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-2000.3: "any transition out of the parked state while the screen is off must
 * turn it back on automatically. Do not require a user action to recover."
 *
 * Constructed directly with an injected decision source and recovery action rather than via
 * [ScreenAutoRecovery.getInstance], so the recovery firing is asserted on a stub (no real
 * `ConditionalPoller`/executor tick needed -- `onSample` is internal and called directly here,
 * exercising the same decision logic a live poll would).
 */
class ScreenAutoRecoveryTest {

    @Test
    fun `armed then unsafe motion turns the screen back on`() {
        var turnedOn = false
        val recovery = ScreenAutoRecovery({ DrivingSafetyGuard.Decision.ALLOW }, {
            turnedOn = true
            true
        })

        recovery.armed()
        recovery.onSample(DrivingSafetyGuard.Decision.BLOCK_MOVING)

        assertTrue("the screen must have been turned back on with no user action", turnedOn)
    }

    @Test
    fun `armed then unsafe motion disarms after recovering`() {
        val recovery = ScreenAutoRecovery({ DrivingSafetyGuard.Decision.ALLOW }, { true })

        recovery.armed()
        assertTrue(recovery.isArmed())
        recovery.onSample(DrivingSafetyGuard.Decision.BLOCK_MOVING)

        assertFalse("must disarm after recovering, so a later sample does not re-fire", recovery.isArmed())
    }

    @Test
    fun `not armed, unsafe motion does nothing`() {
        var turnedOn = false
        val recovery = ScreenAutoRecovery({ DrivingSafetyGuard.Decision.ALLOW }, {
            turnedOn = true
            true
        })

        recovery.onSample(DrivingSafetyGuard.Decision.BLOCK_MOVING)

        assertFalse("never armed (screen was never turned off by this feature) -- must not act", turnedOn)
    }

    @Test
    fun `armed, safe motion does nothing`() {
        var turnedOn = false
        val recovery = ScreenAutoRecovery({ DrivingSafetyGuard.Decision.ALLOW }, {
            turnedOn = true
            true
        })

        recovery.armed()
        recovery.onSample(DrivingSafetyGuard.Decision.ALLOW)

        assertFalse("still safely parked -- must not act", turnedOn)
        assertTrue("must stay armed -- the car has not left the parked state", recovery.isArmed())
    }

    @Test
    fun `disarm stops further auto recovery`() {
        var turnedOn = false
        val recovery = ScreenAutoRecovery({ DrivingSafetyGuard.Decision.ALLOW }, {
            turnedOn = true
            true
        })

        recovery.armed()
        recovery.disarm()
        recovery.onSample(DrivingSafetyGuard.Decision.BLOCK_MOVING)

        assertFalse("disarmed (e.g. by a user-issued screen-on) -- must not act", turnedOn)
    }

    /**
     * BladeWatch-c9ib: [ConditionalPoller.subscribe] runs the first tick SYNCHRONOUSLY, so a
     * decision source that is already unsafe recovers and disarms from inside the
     * `poller.subscribe(...)` call -- before its return value has been assigned to
     * `subscription`. `disarm()` then had nothing to close, and the handle it should have
     * closed was assigned immediately afterwards, leaving a 2-second poll running forever with
     * `armed == false`: pure waste, and the exact thing ConditionalPoller exists to avoid.
     */
    @Test
    fun `recovering on the immediate first sample leaves no poll running`() {
        var turnedOn = false
        val recovery = ScreenAutoRecovery({ DrivingSafetyGuard.Decision.BLOCK_MOVING }, {
            turnedOn = true
            true
        })

        recovery.armed()

        assertTrue("the immediate first sample was unsafe -- the screen must come back on", turnedOn)
        assertFalse("must not stay armed after recovering", recovery.isArmed())
        assertFalse(
            "the poll must stop when disarming happens during subscribe()'s synchronous first tick",
            recovery.isPolling(),
        )
    }

    @Test
    fun `getInstance returns the same singleton every time`() {
        assertEquals(ScreenAutoRecovery.getInstance(), ScreenAutoRecovery.getInstance())
    }
}
