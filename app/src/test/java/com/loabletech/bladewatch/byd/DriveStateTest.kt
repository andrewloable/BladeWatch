package net.bladewatch.app.byd

import org.junit.Assert.assertEquals
import org.junit.Test

/** BladeWatch-7zp9 / os88: labels only where measured; raw values always; nothing guessed. */
class DriveStateTest {

    @Test
    fun `a gear letter passes, anything else is UNKNOWN`() {
        assertEquals("D", DriveState.toJson("D", 1, 0, 1).getString("gear"))
        assertEquals("UNKNOWN", DriveState.toJson("UNKNOWN(9)", 1, 0, 1).getString("gear"))
        assertEquals("UNKNOWN", DriveState.toJson(null, 1, 0, 1).getString("gear"))
    }

    @Test
    fun `the values measured on the head unit get their labels`() {
        // ECO and NORMAL both read 1 on the car, so 1 names both, never one of them.
        assertEquals("ECO/NORMAL", DriveState.driveMode(1))
        assertEquals("SPORT", DriveState.driveMode(2))
        assertEquals("UNKNOWN", DriveState.driveMode(3)) // predicted NORMAL by a constant family; never observed
        assertEquals("DISABLED", DriveState.autoHold(0))
        assertEquals("ENABLED", DriveState.autoHold(1))
        assertEquals("EV", DriveState.energyMode(1))
        assertEquals("HEV", DriveState.energyMode(3))
    }

    @Test
    fun `an unmeasured value is UNKNOWN, never a guess, and its raw value is kept`() {
        val j = DriveState.toJson("P", 7, 2, 2)
        assertEquals("UNKNOWN", j.getString("driveMode"))
        assertEquals(7, j.getInt("driveModeRaw"))
        assertEquals("UNKNOWN", j.getString("autoHold"))
        assertEquals(2, j.getInt("autoHoldRaw"))
        assertEquals("UNKNOWN", j.getString("energyMode"))
        assertEquals(2, j.getInt("energyModeRaw"))
    }

    @Test
    fun `an unavailable raw value is sent as -1`() {
        val u = BydVehicleData.UNAVAILABLE
        val j = DriveState.toJson("P", u, u, u)
        assertEquals(-1, j.getInt("driveModeRaw"))
        assertEquals(-1, j.getInt("autoHoldRaw"))
        assertEquals(-1, j.getInt("energyModeRaw"))
    }
}
