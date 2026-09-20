package net.bladewatch.app.server.connect.impl

import net.bladewatch.app.server.SafeLocationApiHandler
import net.bladewatch.app.server.connect.ConnectDispatcher
import net.bladewatch.app.server.connect.ConnectException
import net.bladewatch.app.server.connect.ConnectResponse
import org.json.JSONObject

/**
 * Connect protocol handler for bladewatch.v1.SafeLocationsService.
 *
 * BladeWatch-6mnq: these used to go through
 * `ConnectHandlerUtil.captureString(out -> SafeLocationApiHandler.handle(VERB, PATH, ...))` — an
 * HTTP verb and path modelled in memory purely because the handler had been written as a REST
 * endpoint first. Each method now calls the operation it means, with the zone id as an argument
 * rather than a query-string fragment.
 */
class SafeLocationsServiceImpl {

    fun register(dispatcher: ConnectDispatcher) {
        dispatcher.register(
            "bladewatch.v1.SafeLocationsService", "ListZones", this::handleListZones
        )
        dispatcher.register(
            "bladewatch.v1.SafeLocationsService", "AddZone", this::handleAddZone
        )
        dispatcher.register(
            "bladewatch.v1.SafeLocationsService", "UpdateZone", this::handleUpdateZone
        )
        dispatcher.register(
            "bladewatch.v1.SafeLocationsService", "DeleteZone", this::handleDeleteZone
        )
        dispatcher.register(
            "bladewatch.v1.SafeLocationsService", "Toggle", this::handleToggle
        )
    }

    @Throws(ConnectException::class)
    private fun handleListZones(req: String?, clientIdentity: String?): ConnectResponse =
        respond { SafeLocationApiHandler.listZones() }

    @Throws(ConnectException::class)
    private fun handleAddZone(req: String?, clientIdentity: String?): ConnectResponse =
        respond {
            val input = parse(req)
            SafeLocationApiHandler.addZone(
                input.optString("name", "Unnamed"),
                input.optDouble("lat", 0.0),
                input.optDouble("lng", 0.0),
                input.optInt("radiusM", 150)
            )
        }

    @Throws(ConnectException::class)
    private fun handleUpdateZone(req: String?, clientIdentity: String?): ConnectResponse =
        respond {
            val input = parse(req)
            SafeLocationApiHandler.updateZone(input.optString("id", null), input)
        }

    @Throws(ConnectException::class)
    private fun handleDeleteZone(req: String?, clientIdentity: String?): ConnectResponse =
        respond { SafeLocationApiHandler.deleteZone(parse(req).optString("id", null)) }

    @Throws(ConnectException::class)
    private fun handleToggle(req: String?, clientIdentity: String?): ConnectResponse =
        respond {
            val input = parse(req)
            // An absent "enabled" means "flip it", which the toggle button relies on. proto3 has
            // no presence for a bare bool, so ToggleSafeLocationsRequest carries an enabled_set
            // companion (json: enabledSet) — the name the client already sends.
            val want: Boolean? =
                if (input.optBoolean("enabledSet", false)) input.optBoolean("enabled", false)
                else null
            SafeLocationApiHandler.toggle(want)
        }

    private companion object {
        /** An empty or unparseable body is an empty request, not a failure. */
        fun parse(req: String?): JSONObject {
            if (req.isNullOrEmpty()) return JSONObject()
            return try {
                JSONObject(req)
            } catch (e: Exception) {
                JSONObject()
            }
        }

        @Throws(ConnectException::class)
        fun respond(op: () -> JSONObject): ConnectResponse = try {
            ConnectResponse.of(op().toString())
        } catch (e: Exception) {
            throw ConnectException("internal", "An internal error occurred")
        }
    }
}
