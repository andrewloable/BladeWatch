package net.bladewatch.app.daemon

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

/** BladeWatch-lw0o: the car accepts companions it cannot find announced. */
class PearDaemonJoinTest {

    @Test
    fun `the car joins its topic accepting unannounced companions`() {
        val params = PearDaemon.joinParams("ab".repeat(32))
        assertEquals("ab".repeat(32), params.getString("topic"))
        assertTrue(params.getBoolean("acceptUnannounced"))
        // The car must keep announcing: it is what every companion looks up.
        assertTrue(!params.has("server") || params.getBoolean("server"))
    }
}
