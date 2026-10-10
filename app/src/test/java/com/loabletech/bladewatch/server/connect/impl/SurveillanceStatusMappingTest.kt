package net.bladewatch.app.server.connect.impl

import org.json.JSONObject
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * BladeWatch-nrwh: GetSurveillanceStatus must not conflate "camera pipeline running",
 * "persisted user preference" and "sentry armed". [SurveillanceServiceImpl.flatStatus] is the
 * whole mapping; these cases pin each field to its own source.
 */
class SurveillanceStatusMappingTest {

    private fun status(active: Boolean, enabled: Boolean, armed: Boolean, cameraYielded: Boolean = false,
                       nativeAppActive: Boolean = false): JSONObject =
        JSONObject()
            .put("active", active)
            .put("enabled", enabled)
            .put("armed", armed)
            .put("cameraYielded", cameraYielded)
            .put("nativeAppActive", nativeAppActive)

    @Test
    fun k1_parkedWaitingForLock_isPreferenceOnButNotArmed() {
        val j = SurveillanceServiceImpl.flatStatus(status(active = true, enabled = true, armed = false), true)
        assertTrue(j.getBoolean("pipelineRunning"))
        assertTrue(j.getBoolean("surveillanceActive"))
        assertFalse(j.getBoolean("armed"))
    }

    @Test
    fun k2_armed_setsArmed() {
        val j = SurveillanceServiceImpl.flatStatus(status(active = true, enabled = true, armed = true), true)
        assertTrue(j.getBoolean("armed"))
    }

    @Test
    fun k3_staleIntentFlagIsIgnored() {
        // The 2026-10-10 bug: status.enabled stayed true while nothing was armed. The persisted
        // preference is what surveillanceActive reports, so a false preference wins.
        val j = SurveillanceServiceImpl.flatStatus(status(active = true, enabled = true, armed = false), false)
        assertFalse(j.getBoolean("surveillanceActive"))
        assertFalse(j.getBoolean("armed"))
    }

    @Test
    fun k4_drivingWithPreferenceOn_isPreferenceOnNotArmed() {
        val j = SurveillanceServiceImpl.flatStatus(status(active = true, enabled = false, armed = false), true)
        assertTrue(j.getBoolean("pipelineRunning"))
        assertTrue(j.getBoolean("surveillanceActive"))
        assertFalse(j.getBoolean("armed"))
    }

    @Test
    fun k7_pipelineRunningComesFromActiveNotEnabled() {
        // enabled (the stale intent flag) is true, the camera pipeline is not running: the flat
        // pipelineRunning must follow "active", not "enabled".
        val j = SurveillanceServiceImpl.flatStatus(status(active = false, enabled = true, armed = false), true)
        assertFalse(j.getBoolean("pipelineRunning"))
        assertTrue(j.getBoolean("surveillanceActive"))
        assertFalse(j.getBoolean("armed"))
    }

    @Test
    fun k5_nullStatus_setsOnlySurveillanceActive() {
        val j = SurveillanceServiceImpl.flatStatus(null, true)
        assertTrue(j.getBoolean("surveillanceActive"))
        assertFalse(j.has("armed"))
        assertFalse(j.has("pipelineRunning"))
        assertFalse(j.has("cameraYielded"))
        assertFalse(j.has("nativeAppActive"))
    }

    @Test
    fun k6a_cameraYieldedPassesThroughWithoutNativeAppActive() {
        val j = SurveillanceServiceImpl.flatStatus(
            status(active = false, enabled = false, armed = false, cameraYielded = true, nativeAppActive = false),
            false)
        assertTrue(j.getBoolean("cameraYielded"))
        assertFalse(j.getBoolean("nativeAppActive"))
        assertFalse(j.getBoolean("pipelineRunning"))
    }

    @Test
    fun k6b_nativeAppActivePassesThroughWithoutCameraYielded() {
        val j = SurveillanceServiceImpl.flatStatus(
            status(active = false, enabled = false, armed = false, cameraYielded = false, nativeAppActive = true),
            false)
        assertFalse(j.getBoolean("cameraYielded"))
        assertTrue(j.getBoolean("nativeAppActive"))
        assertFalse(j.getBoolean("pipelineRunning"))
    }
}
