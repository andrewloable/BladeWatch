package net.bladewatch.app.server

import org.junit.Assert.assertEquals
import org.junit.Test

/** BladeWatch-b3n7: which sunroof percent GetState reports. */
class SunroofPercentTest {

    @Test
    fun `a car that never reports a position shows where the last command sent it`() {
        assertEquals(50, VehicleControlApiHandler.sunroofPercent(0, 50, reportsPosition = false))
    }

    @Test
    fun `before any command the car's reading stands`() {
        assertEquals(0, VehicleControlApiHandler.sunroofPercent(0, null, reportsPosition = false))
    }

    @Test
    fun `a car that reports its position is believed, even after a command -- the roof switch moves it too`() {
        assertEquals(0, VehicleControlApiHandler.sunroofPercent(0, 50, reportsPosition = true))
    }
}
