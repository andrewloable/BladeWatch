package net.bladewatch.app.notifications

import android.util.Log
import org.json.JSONObject
import java.util.Locale

/**
 * Canonical notification event. Emitted by sources (surveillance, tyre, proximity, etc.) and
 * consumed by sinks (PushSink, LogSink).
 *
 * Category is a dotted string ("surveillance.motion", "vehicle.health.tyre.leak"), not an enum, so
 * future categories can be added by registry config without code changes here.
 *
 * Severity drives the UI rendering on the client (vibrate pattern, requireInteraction, sound). For
 * categories with `"severity": "auto"` in the registry, the source should compute it per-event
 * from the data.
 */
class NotificationEvent(
    category: String?,
    severity: Severity?,
    title: String?,
    body: String?,
    tag: String?,
    clickUrl: String?,
    data: JSONObject?
) {

    enum class Severity { INFO, WARN, CRITICAL }

    @JvmField val category: String
    @JvmField val severity: Severity
    @JvmField val title: String
    @JvmField val body: String
    @JvmField val timestamp: Long

    /** Server-side dedupe key. Two events with the same tag collapse on display. May be null. */
    @JvmField val tag: String?

    /** Click target URL. If null, the sink falls back to the registry's defaultClickUrl. */
    @JvmField val clickUrl: String?

    /** Category-specific extras (filename, wheel index, kPa, etc.). Never null. */
    @JvmField val data: JSONObject

    init {
        requireNotNull(category) { "category required" }
        requireNotNull(severity) { "severity required" }
        requireNotNull(title) { "title required" }
        this.category = category
        this.severity = severity
        this.title = title
        this.body = body ?: ""
        this.timestamp = System.currentTimeMillis()
        this.tag = tag
        this.clickUrl = clickUrl
        this.data = data ?: JSONObject()
    }

    /** Build the wire envelope sent inside the encrypted Web Push payload. */
    fun toPayloadJson(): JSONObject {
        val j = JSONObject()
        try {
            j.put("v", 1)
            j.put("category", category)
            j.put("severity", severity.name.lowercase(Locale.US))
            j.put("title", title)
            j.put("body", body)
            j.put("ts", timestamp)
            if (tag != null) j.put("tag", tag)
            if (clickUrl != null) j.put("url", clickUrl)
            j.put("data", data)
        } catch (ignored: Exception) {
            Log.w(TAG, "toPayloadJson failed: " + ignored.message)
        }
        return j
    }

    private companion object {
        const val TAG = "NotificationEvent"
    }
}
