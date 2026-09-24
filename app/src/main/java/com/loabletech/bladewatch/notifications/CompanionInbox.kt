package net.bladewatch.app.notifications

import java.io.File
import java.util.concurrent.TimeUnit
import org.json.JSONArray
import org.json.JSONObject

/**
 * Store and forward for the companion app (BladeWatch-rdtj.14, owner's decision): the car keeps
 * the notifications it raised, and a companion fetches the ones it has not seen whenever it
 * connects -- over the LAN or Pear, with no push service in between. So an alert reaches the owner
 * when the companion next connects, not in real time while the phone is pocketed; that is the
 * trade the owner chose over a central push dependency.
 *
 * A sink beside PushSink, so it holds exactly what browsers are pushed (the gate is applied by
 * publishers, before the bus). Bounded by count and age. Every entry gets a strictly increasing id
 * that is never reused, across restarts too: the next id is persisted with the entries. An event
 * whose tag matches a held entry replaces it -- "recording in progress" becomes the final alert.
 *
 * The file describes when the car was disturbed, so it lives in the shell-only /data/local/tmp,
 * mode 600, and holds no category extras (`data`) -- only what the notification itself showed,
 * click URL included (for a clip that names the clip, as the push payload does).
 */
class CompanionInbox(
    private val file: File,
    private val maxEntries: Int = MAX_ENTRIES,
    private val maxAgeMs: Long = MAX_AGE_MS,
    private val now: () -> Long = System::currentTimeMillis,
) : NotificationBus.Sink {

    private val entries = ArrayList<JSONObject>() // oldest first
    private var nextId = 1L

    init {
        load()
    }

    @Synchronized
    override fun onNotification(event: NotificationEvent) {
        event.tag?.let { tag -> entries.removeAll { it.optString("tag") == tag } }
        entries.add(
            JSONObject()
                .put("id", nextId++)
                .put("timestampMs", event.timestamp)
                .put("category", event.category)
                .put("severity", severityName(event.severity))
                .put("title", event.title)
                .put("body", event.body)
                .put("clickUrl", event.clickUrl ?: "")
                .put("tag", event.tag ?: ""),
        )
        prune()
        save()
    }

    /** ListInboxResponse as proto3 JSON: entries after [afterId], oldest first. */
    @Synchronized
    fun list(afterId: Long, limit: Int): JSONObject {
        prune()
        val max = if (limit <= 0) DEFAULT_LIMIT else minOf(limit, MAX_LIMIT)
        val page = JSONArray()
        entries.asSequence().filter { it.getLong("id") > afterId }.take(max).forEach { page.put(it) }
        return JSONObject()
            .put("entries", page)
            .put("latestId", entries.lastOrNull()?.getLong("id") ?: 0L)
            .put("oldestId", entries.firstOrNull()?.getLong("id") ?: 0L)
    }

    private fun prune() {
        val cutoff = now() - maxAgeMs
        entries.removeAll { it.getLong("timestampMs") < cutoff }
        while (entries.size > maxEntries) entries.removeAt(0)
    }

    private fun load() {
        val stored = try {
            if (file.isFile) JSONObject(file.readText()) else null
        } catch (e: Exception) {
            null // unreadable: start empty rather than refuse to record new alerts
        } ?: return
        val list = stored.optJSONArray("entries") ?: JSONArray()
        for (i in 0 until list.length()) list.optJSONObject(i)?.let { entries.add(it) }
        nextId = maxOf(stored.optLong("nextId", 1L), (entries.lastOrNull()?.getLong("id") ?: 0L) + 1)
    }

    private fun save() {
        try {
            val tmp = File(file.path + ".tmp")
            tmp.writeText(JSONObject().put("nextId", nextId).put("entries", JSONArray(entries)).toString())
            tmp.setReadable(false, false)
            tmp.setWritable(false, false)
            tmp.setReadable(true, true)
            tmp.setWritable(true, true)
            tmp.renameTo(file)
        } catch (e: Exception) {
            // Keep serving from memory; the next event tries again.
        }
    }

    companion object {
        const val PATH = "/data/local/tmp/bladewatch_inbox.json"
        const val MAX_ENTRIES = 200
        val MAX_AGE_MS = TimeUnit.DAYS.toMillis(14)
        const val DEFAULT_LIMIT = 100
        const val MAX_LIMIT = 500

        /** NotificationEvent.Severity onto the proto's NotificationSeverity (WARN is ALERT there). */
        fun severityName(s: NotificationEvent.Severity): String = when (s) {
            NotificationEvent.Severity.INFO -> "NOTIFICATION_SEVERITY_INFO"
            NotificationEvent.Severity.WARN -> "NOTIFICATION_SEVERITY_ALERT"
            NotificationEvent.Severity.CRITICAL -> "NOTIFICATION_SEVERITY_CRITICAL"
        }
    }
}
