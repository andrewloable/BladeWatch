package net.bladewatch.app.byd.radar

import android.content.Context
import android.hardware.bydauto.radar.AbsBYDAutoRadarListener
import net.bladewatch.app.byd.EventCallback
import net.bladewatch.app.byd.LogCallback
import org.json.JSONObject
import java.util.Arrays
import kotlin.math.min

/** Manages the BYD Radar device and its events. */
class RadarManager(
    private val context: Context,
    private val eventCallback: EventCallback,
    private val logCallback: LogCallback?
) {

    private var radarDevice: Any? = null

    var isRegistered = false
        private set

    private val lastStates = IntArray(RadarConstants.SENSOR_COUNT) { -1 }

    fun register() {
        try {
            log("Registering radar listener...")

            val radarClass = Class.forName("android.hardware.bydauto.radar.BYDAutoRadarDevice")
            val getInstance = radarClass.getMethod("getInstance", Context::class.java)
            val device = getInstance.invoke(null, context)
            radarDevice = device

            if (device == null) {
                log("ERROR: BYDAutoRadarDevice.getInstance() returned null")
                return
            }
            log("Got radar device: $device")

            val registerListener = radarClass.getMethod(
                "registerListener",
                Class.forName("android.hardware.bydauto.radar.AbsBYDAutoRadarListener")
            )
            registerListener.invoke(device, RadarListener())

            isRegistered = true
            log("Radar listener registered successfully")

            // Get the initial states
            fetchInitialStates(radarClass)
        } catch (e: Exception) {
            log("ERROR registering radar listener: " + e.message)
            e.printStackTrace()
        }
    }

    private fun fetchInitialStates(radarClass: Class<*>) {
        try {
            val states = radarClass.getMethod("getAllRadarProbeStates").invoke(radarDevice) as? IntArray
            if (states != null) {
                for (i in 0 until min(states.size, RadarConstants.SENSOR_COUNT)) {
                    lastStates[i] = states[i]
                }
                log("Initial radar states: " + Arrays.toString(states))
            }
        } catch (e: Exception) {
            log("Could not get initial radar states: " + e.message)
        }
    }

    fun getLastStates(): IntArray = lastStates.clone()

    fun getStateAsJson(): JSONObject {
        val radar = JSONObject()
        try {
            for (i in 0 until RadarConstants.SENSOR_COUNT) {
                radar.put(
                    RadarConstants.AREA_NAMES[i], RadarConstants.stateToString(lastStates[i])
                )
            }
        } catch (e: Exception) {
            log("Error building radar state JSON: " + e.message)
        }
        return radar
    }

    private fun log(message: String) {
        logCallback?.log("[Radar] $message")
    }

    // ==================== LISTENER ====================

    private inner class RadarListener : AbsBYDAutoRadarListener() {
        override fun onRadarProbeStateChanged(area: Int, state: Int) {
            log(
                ">>> RADAR: area=" + RadarConstants.areaToString(area) +
                    " state=" + RadarConstants.stateToString(state)
            )

            if (area >= 0 && area < RadarConstants.SENSOR_COUNT) {
                lastStates[area] = state
            }

            try {
                val event = JSONObject()
                event.put("type", "radar")
                event.put("area", area)
                event.put("areaName", RadarConstants.areaToString(area))
                event.put("state", state)
                event.put("stateName", RadarConstants.stateToString(state))
                event.put("timestamp", System.currentTimeMillis())
                eventCallback.onEvent(event)
            } catch (e: Exception) {
                log("Error broadcasting radar event: " + e.message)
            }
        }

        override fun onReverseRadarSwitchStateChanged(state: Int) {
            log(">>> RADAR SWITCH: " + (if (state == 1) "ON" else "OFF"))

            try {
                val event = JSONObject()
                event.put("type", "radarSwitch")
                event.put("state", state)
                event.put("enabled", state == 1)
                event.put("timestamp", System.currentTimeMillis())
                eventCallback.onEvent(event)
            } catch (e: Exception) {
                log("Error broadcasting radar switch event: " + e.message)
            }
        }
    }
}
