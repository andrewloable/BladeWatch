package net.bladewatch.app.server

import net.bladewatch.app.surveillance.SafeLocationManager
import org.json.JSONObject

/**
 * Geofence zone management, behind
 * `SafeLocationsService.{ListZones, AddZone, UpdateZone, DeleteZone, Toggle}`.
 *
 * BladeWatch-6mnq: this was a REST handler that matched `/api/surveillance/safe-locations`,
 * pulled the zone id out of a QUERY STRING, and wrote JSON into an OutputStream that the Connect
 * layer immediately captured back out again. Each operation is now its own method taking its own
 * arguments and returning its JSON — the id is a parameter rather than something parsed out of a
 * URL.
 */
object SafeLocationApiHandler {

    /** All zones plus whether the feature is on. */
    @JvmStatic
    @Throws(Exception::class)
    fun listZones(): JSONObject = SafeLocationManager.getInstance().statusJson

    /** Turns the whole feature on or off. */
    @JvmStatic
    @Throws(Exception::class)
    fun toggle(enabled: Boolean?): JSONObject {
        val mgr = SafeLocationManager.getInstance()
        // A null request flips the current state — the REST body treated an absent "enabled" the
        // same way, and the UI relies on it for a plain toggle button.
        mgr.setFeatureEnabled(enabled ?: !mgr.isFeatureEnabled)
        val resp = JSONObject()
        resp.put("success", true)
        resp.put("enabled", mgr.isFeatureEnabled)
        return resp
    }

    /** Adds a zone. Refuses 0,0 — it is the null island, not a place anyone parks. */
    @JvmStatic
    @Throws(Exception::class)
    fun addZone(name: String?, lat: Double, lng: Double, radiusM: Int): JSONObject {
        if (lat == 0.0 && lng == 0.0) {
            return error(Messages.get("errors.safelocation_invalid_coordinates"))
        }
        val zone = SafeLocationManager.getInstance()
            .addZone(sanitizeZoneName(name), lat, lng, radiusM)
            ?: return error(Messages.get("errors.safelocation_max_zones"))
        val resp = JSONObject()
        resp.put("success", true)
        resp.put("zone", zone.toJson())
        return resp
    }

    /** Updates a zone in place. [patch] carries whichever fields are changing. */
    @JvmStatic
    @Throws(Exception::class)
    fun updateZone(id: String?, patch: JSONObject?): JSONObject {
        if (id.isNullOrEmpty()) {
            return error(Messages.get("errors.safelocation_missing_zone_id"))
        }
        val updated = SafeLocationManager.getInstance().updateZone(id, patch ?: JSONObject())
        val resp = JSONObject()
        resp.put("success", updated)
        if (!updated) resp.put("error", Messages.get("errors.safelocation_zone_not_found"))
        return resp
    }

    /** Removes a zone. */
    @JvmStatic
    @Throws(Exception::class)
    fun deleteZone(id: String?): JSONObject {
        if (id.isNullOrEmpty()) {
            return error(Messages.get("errors.safelocation_missing_zone_id"))
        }
        val removed = SafeLocationManager.getInstance().removeZone(id)
        val resp = JSONObject()
        resp.put("success", removed)
        if (!removed) resp.put("error", Messages.get("errors.safelocation_zone_not_found"))
        return resp
    }

    /**
     * Sanitize a zone name: strip angle brackets, cap the length, fall back to a default.
     *
     * The zone name is rendered into the legacy web UI's innerHTML and into a Leaflet popup,
     * neither of which escapes — see the stored-XSS note in this project's memory. Stripping the
     * brackets here is what makes that safe at the source.
     *
     * Public rather than package-private only so SafeLocationRequestShapeTest, which is Java, can
     * still call it: Kotlin mangles `internal` names on the JVM.
     */
    @JvmStatic
    fun sanitizeZoneName(name: String?): String {
        if (name == null || name.trim().isEmpty()) return "Unnamed"
        val cleaned = name.replace("<", "").replace(">", "").trim()
        if (cleaned.isEmpty()) return "Unnamed"
        return if (cleaned.length > 64) cleaned.substring(0, 64) else cleaned
    }

    @Throws(Exception::class)
    private fun error(message: String): JSONObject {
        val resp = JSONObject()
        resp.put("success", false)
        resp.put("error", message)
        return resp
    }
}
