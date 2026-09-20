package net.bladewatch.app.byd

import org.json.JSONObject

/** Callback interface for broadcasting BYD events. */
fun interface EventCallback {
    fun onEvent(event: JSONObject)
}
