package net.bladewatch.app.notifications

import android.content.Context
import android.util.Log
import org.json.JSONObject
import java.io.ByteArrayOutputStream
import java.util.Collections

/**
 * Loads `notifications-categories.json` from the APK assets.
 *
 * Single source of truth for the registry — both the server-side defaults (severity floor, click
 * URL fallback) and the categories RPC hydrate from the same file.
 */
class CategoryRegistry private constructor(
    private val byId: Map<String, Entry>,
    private val rawJson: String,
    private val version: Int
) {

    class Entry internal constructor(
        @JvmField val id: String,
        @JvmField val label: String,
        @JvmField val group: String,
        @JvmField val defaultEnabled: Boolean,
        /** "info", "warn", "critical", or "auto" (use the event's own severity). */
        @JvmField val severity: String,
        @JvmField val defaultClickUrl: String,
        @JvmField val note: String?,
        /**
         * When true, this category delivers even during the user's configured quiet hours.
         * Reserved for events the user explicitly wants regardless of time of day (e.g. charging
         * complete — the whole point is to wake them so they unplug). Defaults to false.
         */
        @JvmField val bypassQuietHours: Boolean
    )

    fun get(id: String): Entry? = byId[id]

    fun all(): Map<String, Entry> = Collections.unmodifiableMap(byId)

    fun rawJson(): String = rawJson

    fun version(): Int = version

    companion object {
        @JvmStatic
        @Throws(Exception::class)
        fun loadFromAssets(ctx: Context): CategoryRegistry =
            ctx.assets.open("notifications-categories.json").use { input ->
                // is.available() is a hint, not a contract — InputStream.read may return short,
                // leaving trailing garbage that corrupts JSON parsing. Read in a loop until EOF.
                val bos = ByteArrayOutputStream()
                val buf = ByteArray(4096)
                while (true) {
                    val n = input.read(buf)
                    if (n <= 0) break
                    bos.write(buf, 0, n)
                }
                parse(bos.toString("UTF-8"))
            }

        @JvmStatic
        @Throws(Exception::class)
        fun parse(json: String): CategoryRegistry {
            val root = JSONObject(json)
            val version = root.optInt("version", 1)
            val arr = root.getJSONArray("categories")
            val map = LinkedHashMap<String, Entry>()
            for (i in 0 until arr.length()) {
                val c = arr.getJSONObject(i)
                val e = Entry(
                    c.getString("id"),
                    c.getString("label"),
                    c.optString("group", ""),
                    c.optBoolean("defaultEnabled", true),
                    c.optString("severity", "info"),
                    c.optString("defaultClickUrl", "/"),
                    c.optString("note", null),
                    c.optBoolean("bypassQuietHours", false)
                )
                // Duplicate IDs would silently overwrite (LinkedHashMap.put returns the previous
                // value); log and skip the second occurrence so config typos surface early
                // instead of subtly changing notification behaviour.
                if (map.containsKey(e.id)) {
                    Log.w(
                        "CategoryRegistry",
                        "Duplicate category id '" + e.id + "' at index " + i +
                            " — keeping first occurrence"
                    )
                    continue
                }
                map[e.id] = e
            }
            return CategoryRegistry(map, json, version)
        }
    }
}
