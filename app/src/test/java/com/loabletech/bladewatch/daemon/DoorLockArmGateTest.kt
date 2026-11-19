package net.bladewatch.app.daemon

import net.bladewatch.app.daemon.DoorLockArmGate.Action
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** BladeWatch-l55j: when the ACC-OFF door-lock gate arms and disarms, and re-arms after an ACC cycle. */
class DoorLockArmGateTest {

    @Test
    fun lockArmsOnceAndRepeatedLockIsNoOp() {
        val gate = DoorLockArmGate()
        assertEquals(Action.ARM, gate.onLockEvent(true, false))
        assertTrue(gate.armed)
        assertEquals(Action.NONE, gate.onLockEvent(true, false))
    }

    @Test
    fun unlockDisarmsOnlyWhenArmed() {
        val gate = DoorLockArmGate()
        assertEquals(Action.NONE, gate.onLockEvent(false, false))
        assertFalse(gate.armed)

        gate.onLockEvent(true, false)
        assertEquals(Action.DISARM, gate.onLockEvent(false, false))
        assertFalse(gate.armed)
    }

    @Test
    fun accOnIsIgnoredByEveryDecision() {
        val gate = DoorLockArmGate()
        assertEquals(Action.NONE, gate.onLockEvent(true, true))
        assertFalse(gate.armed)

        gate.onLockEvent(true, false)
        assertEquals(Action.NONE, gate.onLockEvent(false, true))
        assertTrue(gate.armed)

        assertEquals(Action.NONE, gate.onTimeout(true, gate.session))

        val fresh = DoorLockArmGate()
        assertEquals(Action.NONE, fresh.onTimeout(true, fresh.session))
        assertFalse(fresh.armed)
        assertEquals(Action.ARM, fresh.onTimeout(false, fresh.session)) // an ACC-ON timeout must not consume the arm
    }

    @Test
    fun timeoutArmsWhenNothingElseDid() {
        val gate = DoorLockArmGate()
        assertEquals(Action.ARM, gate.onTimeout(false, gate.session))
        assertTrue(gate.armed)
        assertEquals(Action.NONE, gate.onTimeout(false, gate.session))
        assertEquals(Action.NONE, gate.onLockEvent(true, false))
    }

    @Test
    fun timeoutArmedGateRearmsAfterEveryAccCycle() {
        // REGRESSION (BladeWatch-l55j): the gate must forget the previous ACC-OFF session on
        // every ACC transition, or the next 60 s timeout skips arming and sentry never re-arms.
        val gate = DoorLockArmGate()
        repeat(3) { cycle ->
            assertEquals("cycle $cycle: timeout must arm", Action.ARM, gate.onTimeout(false, gate.session))
            gate.reset() // ACC ON
            gate.reset() // next ACC OFF gate entry
        }
    }

    @Test
    fun lockArmedGateRearmsAfterAccCycle() {
        // REGRESSION (BladeWatch-l55j): a lock-armed gate must also be reset by the ACC cycle.
        val gate = DoorLockArmGate()
        assertEquals(Action.ARM, gate.onLockEvent(true, false))
        gate.reset() // ACC ON
        gate.reset() // next ACC OFF gate entry
        assertEquals(Action.ARM, gate.onTimeout(false, gate.session))
    }

    @Test
    fun timeoutOfAnEarlierGateSessionNeverArmsALaterOne() {
        // REGRESSION (BladeWatch-l55j): ACC OFF at t=0, ON at t=20, OFF at t=40. The t=0 timeout
        // wakes at t=60 and must not arm the t=40 session 20 s early.
        val gate = DoorLockArmGate()
        val first = gate.reset() // ACC OFF #1
        gate.reset() // ACC ON
        val second = gate.reset() // ACC OFF #2
        assertEquals(Action.NONE, gate.onTimeout(false, first))
        assertFalse(gate.armed)
        assertEquals(Action.ARM, gate.onTimeout(false, second))
    }

    @Test
    fun resetStartsANewSessionEachTime() {
        val gate = DoorLockArmGate()
        val a = gate.reset()
        val b = gate.reset()
        val c = gate.reset()
        assertTrue("session ids must increase: $a, $b, $c", a < b && b < c)
    }

    @Test
    fun disarmKeepsTheSessionSoItsTimeoutCanRearm() {
        // Watchdog path (BladeWatch-l55j): disarm() must not start a new session, or the open
        // session's timeout could no longer re-arm.
        val gate = DoorLockArmGate()
        val s = gate.reset()
        assertEquals(Action.ARM, gate.onTimeout(false, s))
        gate.disarm()
        assertFalse(gate.armed)
        assertEquals(s, gate.session)
        assertEquals(Action.ARM, gate.onTimeout(false, s))
    }
}
