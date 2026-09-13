package net.bladewatch.app.launcher

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-ofzb: after a BYD firmware update resets adb_enabled to 0, the
 * app is the only thing that can turn it back on (no ADB, no root). These
 * tests pin the exact branches that matter on a car with no USB access:
 * the retry must run at most once, and there must be no path that writes 0.
 */
class AdbSelfHealerTest {

    /** Fake gateway — real Settings.Global access needs a live ContentResolver
     *  and isn't reachable from a JVM unit test (no Robolectric in this project). */
    private class FakeGateway(
        private var enabled: Boolean,
        private val throwOnEnable: Boolean = false,
    ) : AdbEnableGateway {
        var enableCallCount = 0
            private set

        override fun isAdbEnabled(): Boolean = enabled

        override fun enableAdb(): Boolean {
            enableCallCount++
            if (throwOnEnable) return false
            enabled = true
            return true
        }
    }

    @Test fun `no-op when adb_enabled is already 1`() {
        val gateway = FakeGateway(enabled = true)
        var healed = false
        var couldNotHealReason: String? = null
        val healer = AdbSelfHealer(
            gateway = gateway,
            isPortOpen = { false },
            sleep = { throw AssertionError("must not wait for adbd when no heal was attempted") },
            onHealed = { healed = true },
            onCouldNotHeal = { couldNotHealReason = it },
        )

        assertFalse(healer.attemptHeal())
        assertFalse(healed)
        assertEquals(0, gateway.enableCallCount)
        assertTrue(couldNotHealReason!!.contains("already"))
    }

    @Test fun `heals when adb_enabled is 0 and the port opens after enabling`() {
        val gateway = FakeGateway(enabled = false)
        var sleptMs = -1L
        var healed = false
        val healer = AdbSelfHealer(
            gateway = gateway,
            // Simulate adbd coming up once BYD's persist flag lets the port open.
            isPortOpen = { gateway.isAdbEnabled() },
            sleep = { sleptMs = it },
            onHealed = { healed = true },
        )

        assertTrue(healer.attemptHeal())
        assertTrue(healed)
        assertEquals(1, gateway.enableCallCount)
        assertEquals(AdbSelfHealer.WAIT_FOR_ADBD_MS, sleptMs)
    }

    @Test fun `could-not-heal when writing throws SecurityException`() {
        val gateway = FakeGateway(enabled = false, throwOnEnable = true)
        var reason: String? = null
        val healer = AdbSelfHealer(
            gateway = gateway,
            isPortOpen = { false },
            sleep = { throw AssertionError("must not wait for adbd if the write itself failed") },
            onCouldNotHeal = { reason = it },
        )

        assertFalse(healer.attemptHeal())
        assertEquals(1, gateway.enableCallCount)
        assertTrue(reason!!.contains("SecurityException"))
    }

    @Test fun `could-not-heal when the write succeeds but the port never opens`() {
        // adb_enabled=1 wrote fine, but BYD's own persist.sys.adb.wiress.enable
        // did not survive the firmware update — the TCP transport stays down.
        val gateway = FakeGateway(enabled = false)
        var reason: String? = null
        val healer = AdbSelfHealer(
            gateway = gateway,
            isPortOpen = { false },
            sleep = { },
            onCouldNotHeal = { reason = it },
        )

        assertFalse(healer.attemptHeal())
        assertEquals(1, gateway.enableCallCount)
        assertTrue(reason!!.contains("still closed"))
    }

    @Test fun `retries the port check at most once — never loops against a dead adbd`() {
        val gateway = FakeGateway(enabled = false)
        var portCheckCount = 0
        val healer = AdbSelfHealer(
            gateway = gateway,
            isPortOpen = { portCheckCount++; false },
            sleep = { },
        )

        healer.attemptHeal()

        assertEquals(1, portCheckCount)
    }

    @Test fun `never writes adb_enabled to 0`() {
        // AdbEnableGateway exposes only isAdbEnabled() (read) and enableAdb()
        // (writes a hardcoded 1) — there is no method on this interface, and
        // therefore no call AdbSelfHealer could ever make, capable of writing
        // 0. This test exercises every branch and asserts the end state is
        // never disabled.
        val alreadyOn = FakeGateway(enabled = true)
        AdbSelfHealer(alreadyOn, isPortOpen = { true }, sleep = {}).attemptHeal()
        assertTrue(alreadyOn.isAdbEnabled())

        val healable = FakeGateway(enabled = false)
        AdbSelfHealer(healable, isPortOpen = { true }, sleep = {}).attemptHeal()
        assertTrue(healable.isAdbEnabled())

        val stuckOff = FakeGateway(enabled = false)
        AdbSelfHealer(stuckOff, isPortOpen = { false }, sleep = {}).attemptHeal()
        // Could not heal (port never opened), but the write itself still only
        // ever set it to 1 — it is not "stuck off" because of us.
        assertTrue(stuckOff.isAdbEnabled())
    }
}
