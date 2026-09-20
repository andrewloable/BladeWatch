package net.bladewatch.app.server

import net.bladewatch.app.daemon.CameraDaemon
import org.json.JSONObject
import java.io.File
import java.io.FileInputStream
import java.text.MessageFormat

/**
 * Server-side i18n message catalog.
 *
 * Loads JSON catalogs lazily per locale from `/data/local/tmp/web/server-i18n/<lang>.json`, falls
 * back to en for missing keys, and interpolates positional args as {0}/{1}.
 *
 * Catalogs are keyed by the same dotted-path scheme as the web-side runtime so both layers stay
 * aligned (e.g. errors.daemon_unavailable).
 */
object Messages {

    private val CATALOGS = HashMap<String, JSONObject>()
    private const val DIR = "/data/local/tmp/web/server-i18n"

    @JvmStatic
    fun get(key: String): String = get(key, *emptyArray())

    @JvmStatic
    fun get(key: String, vararg args: Any?): String {
        val lang = LocaleManager.get()
        var raw = lookup(lang, key)
        if (raw == null && lang != "en") raw = lookup("en", key)
        if (raw == null) return key // dev-visible miss
        if (args.isEmpty()) return raw
        return try {
            MessageFormat.format(raw, *args)
        } catch (e: Exception) {
            CameraDaemon.log("Messages.get: format failed for key '$key': " + e.message)
            raw
        }
    }

    @Synchronized
    private fun lookup(lang: String, key: String): String? {
        var cat = CATALOGS[lang]
        if (cat == null) {
            cat = load(lang)
            if (cat != null) CATALOGS[lang] = cat
        }
        if (cat == null) return null
        // Walk the dotted path: "errors.daemon_unavailable"
        var cur: Any? = cat
        for (p in key.split(".")) {
            val obj = cur as? JSONObject ?: return null
            cur = obj.opt(p) ?: return null
        }
        return cur as? String
    }

    private fun load(lang: String): JSONObject? = try {
        val f = File("$DIR/$lang.json")
        if (!f.exists() || !f.canRead()) {
            null
        } else {
            FileInputStream(f).use { fis ->
                val buf = ByteArray(f.length().toInt())
                var read = 0
                while (read < buf.size) {
                    val n = fis.read(buf, read, buf.size - read)
                    if (n < 0) break
                    read += n
                }
                JSONObject(String(buf, 0, read, Charsets.UTF_8))
            }
        }
    } catch (e: Exception) {
        CameraDaemon.log("Messages.load($lang): " + e.message)
        null
    }

    /** Hot-reload for the picker switch. */
    @JvmStatic
    @Synchronized
    fun invalidate() {
        CATALOGS.clear()
    }
}
