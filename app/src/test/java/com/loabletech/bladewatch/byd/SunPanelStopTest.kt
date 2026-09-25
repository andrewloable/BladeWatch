package net.bladewatch.app.byd

import org.junit.Assert.assertEquals
import org.junit.Test

/** BladeWatch-b3n7: the sunroof has only open, half and close, so every target snaps to one. */
class SunPanelStopTest {

    @Test
    fun `targets snap to the three stops the hardware has`() {
        assertEquals(listOf(0, 0, 50, 50, 50, 100, 100), listOf(0, 25, 26, 50, 74, 75, 100).map(BydDataCollector::sunPanelStop))
    }
}
