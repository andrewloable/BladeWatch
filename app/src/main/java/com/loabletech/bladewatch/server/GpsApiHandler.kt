package net.bladewatch.app.server

import net.bladewatch.app.daemon.CameraDaemon
import net.bladewatch.app.monitor.GpsMonitor
import org.json.JSONObject

/**
 * GPS location and tracking, behind `VehicleService.{GetGpsLocation, StartGps, StopGps}`.
 *
 * BladeWatch-6mnq: this used to be a REST handler — a `handle(method, path, body, OutputStream)`
 * entry point that matched `/api/gps*` and wrote JSON into the stream, which the Connect layer
 * then captured back out of the stream into a string. The methods below RETURN their JSON
 * instead, and the Connect impl calls them directly. The class name is kept so the diff stays
 * readable; it is no longer an HTTP handler.
 */
object GpsApiHandler {

    /**
     * Current location.
     *
     * Starts the monitor if it is not already running: a caller asking where the car is has no
     * other way to turn tracking on, and returning "no location" while silently leaving it off
     * would look like a GPS fault rather than a state the caller could fix.
     */
    @JvmStatic
    @Throws(Exception::class)
    fun location(): JSONObject {
        val gps = GpsMonitor.getInstance()
        if (!gps.isRunning) {
            CameraDaemon.log("GPS: Auto-starting GPS tracking")
            gps.start()
        }

        val response = JSONObject()
        response.put("success", true)
        response.put("location", gps.getLocationJson())
        response.put("googleMapsUrl", gps.getGoogleMapsUrl())

        CameraDaemon.log(
            "GPS: Sending location - lat=" + gps.latitude +
                ", lng=" + gps.longitude + ", hasLocation=" + gps.hasLocation()
        )
        return response
    }

    /** Starts tracking and returns the location as it stands at that moment. */
    @JvmStatic
    @Throws(Exception::class)
    fun start(): JSONObject {
        val gps = GpsMonitor.getInstance()
        gps.start()

        val response = JSONObject()
        response.put("success", true)
        response.put("message", Messages.get("messages.gps_tracking_started"))
        response.put("location", gps.getLocationJson())
        return response
    }

    /** Stops tracking. */
    @JvmStatic
    @Throws(Exception::class)
    fun stop(): JSONObject {
        val gps = GpsMonitor.getInstance()
        gps.stop()

        val response = JSONObject()
        response.put("success", true)
        response.put("message", Messages.get("messages.gps_tracking_stopped"))
        return response
    }
}
