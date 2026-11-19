package net.bladewatch.app.trips

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** BladeWatch-gklt.4: when the driver is reminded to stop an open manual trip. */
class ManualTripReminderTest {

    private var now = 1_000_000L
    private val fired = mutableListOf<String>()
    private val reminder = ManualTripReminder({ now }, { fired.add(it) })

    private fun minutes(m: Long) { now += m * 60_000L }

    @Test
    fun `acc off fires once`() {
        reminder.onManualTripStarted(D, accOn = true)

        reminder.onAcc(false)
        reminder.onAcc(true)
        reminder.onAcc(false)

        assertEquals(listOf("acc_off"), fired)
        assertEquals(1L, reminder.seq)
    }

    @Test
    fun `acc off re-arms after driving`() {
        reminder.onManualTripStarted(D, accOn = true)
        reminder.onAcc(false)
        reminder.onAcc(true)
        reminder.onGear(D)
        reminder.onGear(P)

        reminder.onAcc(false)

        assertEquals(listOf("acc_off", "acc_off"), fired)
        assertEquals(2L, reminder.seq)
    }

    @Test
    fun `parked 29 minutes does not fire and 30 does`() {
        reminder.onManualTripStarted(D, accOn = true)
        reminder.onGear(P)

        minutes(29); now += 59_000; reminder.tick()
        assertTrue(fired.isEmpty())

        now += 1_000; reminder.tick()
        assertEquals(listOf("parked_30m"), fired)
    }

    @Test
    fun `parked for two hours fires only once`() {
        reminder.onManualTripStarted(D, accOn = true)
        reminder.onGear(P)

        repeat(120) { minutes(1); reminder.tick() }

        assertEquals(listOf("parked_30m"), fired)
    }

    @Test
    fun `driving and parking again fires again`() {
        reminder.onManualTripStarted(D, accOn = true)
        reminder.onGear(P)
        minutes(31); reminder.tick()
        reminder.onGear(D)
        reminder.onGear(P)
        minutes(31); reminder.tick()

        assertEquals(listOf("parked_30m", "parked_30m"), fired)
    }

    @Test
    fun `driving resets the parked timer`() {
        reminder.onManualTripStarted(D, accOn = true)
        reminder.onGear(P)
        minutes(20); reminder.tick()
        reminder.onGear(D)
        minutes(5)
        reminder.onGear(P)
        minutes(20); reminder.tick()

        assertTrue("only 20 min since the last park", fired.isEmpty())
    }

    @Test
    fun `starting a trip while already parked counts from the start`() {
        reminder.onManualTripStarted(P, accOn = true)

        minutes(30); reminder.tick()

        assertEquals(listOf("parked_30m"), fired)
    }

    @Test
    fun `parked time does not count while acc is off`() {
        reminder.onManualTripStarted(P, accOn = true)
        minutes(10)
        reminder.onAcc(false)          // fires acc_off, stops the park clock
        fired.clear()

        minutes(120); reminder.tick()

        assertTrue(fired.isEmpty())
    }

    @Test
    fun `nothing fires without an open manual trip`() {
        reminder.onAcc(false)
        reminder.onGear(P)
        minutes(120); reminder.tick()

        assertTrue(fired.isEmpty())

        reminder.onManualTripStarted(D, accOn = true)
        reminder.onManualTripEnded()
        reminder.onAcc(false)

        assertTrue(fired.isEmpty())
        assertEquals(0L, reminder.seq)
    }

    @Test
    fun `a restart does not forget how long the car has been parked`() {
        reminder.onManualTripStarted(P, accOn = true)
        minutes(10)
        val saved = reminder.toJson()

        val fired2 = mutableListOf<String>()
        val restarted = ManualTripReminder({ now }, { fired2.add(it) })
        restarted.restore(saved)

        minutes(19); restarted.tick()
        assertTrue("only 29 minutes parked in total", fired2.isEmpty())

        minutes(1); restarted.tick()
        assertEquals(listOf("parked_30m"), fired2)
    }

    @Test
    fun `a restart does not resend an acc off reminder that was already sent`() {
        reminder.onManualTripStarted(D, accOn = true)
        reminder.onAcc(false)                   // acc_off sent, seq 1
        val saved = reminder.toJson()

        val fired2 = mutableListOf<String>()
        val restarted = ManualTripReminder({ now }, { fired2.add(it) })
        restarted.restore(saved)
        restarted.onAcc(false)                  // the same off event seen again after the restart

        assertTrue(fired2.isEmpty())
        assertEquals(1L, restarted.seq)
        assertEquals("acc_off", restarted.lastReason)
    }

    @Test
    fun `restore tolerates a missing or empty state`() {
        reminder.restore(null)
        assertEquals(0L, reminder.seq)

        reminder.restore(org.json.JSONObject())
        reminder.onAcc(false)

        assertEquals(listOf("acc_off"), fired)
    }

    private companion object {
        const val P = 1
        const val D = 4
    }
}
