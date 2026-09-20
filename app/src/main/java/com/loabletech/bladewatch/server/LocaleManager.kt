package net.bladewatch.app.server

import net.bladewatch.app.daemon.CameraDaemon
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.util.Locale

/**
 * Cross-process locale persistence for the BladeWatch daemon.
 *
 * The HTTP server runs as UID 2000 (shell), which cannot read app-private SharedPreferences. We
 * use the same cross-UID-readable file pattern as the daemon launchers: a plain text file that
 * both the daemon and the Kotlin settings UI can read and write.
 *
 * The locale chosen here drives:
 *  - the `locale` field in `/status`, so a client picks up changes made via the Android settings
 *    drawer on its next poll;
 *  - [Messages] catalog lookups for server-emitted JSON `error` / `message` fields;
 *  - SRT sidecar generation language at recording close.
 */
object LocaleManager {

    /** All locales we ship translations for. en is the base. */
    @JvmField
    val SUPPORTED: List<String> = listOf(
        "en", "zh-CN", "zh-TW", "pt-BR", "es", "de", "fr", "it",
        "nb", "nl", "ja", "ko", "th", "vi", "hi", "tr", "ru"
    )

    private val SUPPORTED_SET: Set<String> = HashSet(SUPPORTED)
    private const val DEFAULT_LANG = "en"

    /**
     * Sentinel written to the state file when the user picks "Auto (follow system)".
     * Distinguishes "user explicitly wants system locale" from "user has never chosen" (the
     * latter also resolves to system).
     */
    const val AUTO_TAG = "auto"

    /**
     * Where the chosen locale lives (BladeWatch-vcur).
     *
     * NOT `/data/local/tmp/.bladewatch/` any more. That directory is `0771 shell:shell`: the app
     * UID gets `--x`, so it may traverse in and read a world-readable file but may NOT create
     * anything. The daemon (uid 2000) could write there, the two in-car UIs could not, and the
     * failure was swallowed — so picking a language appeared to work and was silently lost on the
     * next launch.
     *
     * This directory is created by `setupStorageDirectories()` and both APKs already write
     * `bladewatch_config.json` into it; the daemon can read it because shell is in `sdcard_rw`. A
     * locale tag is not a secret, so the sdcardfs permission weakness tracked in BladeWatch-078u
     * does not apply.
     */
    private const val STATE_DIR = "/storage/emulated/0/BladeWatch/data"
    private const val STATE_FILE = "$STATE_DIR/locale"

    /**
     * The pre-BladeWatch-vcur location, still READ so a device whose web UI already persisted a
     * language keeps it. The web picker goes through the daemon, which runs as shell and so could
     * always write here.
     */
    private const val LEGACY_STATE_FILE = "/data/local/tmp/.bladewatch/locale"

    /**
     * Whether the last [set]/[setAuto] actually reached disk. Exposed so the picker can tell the
     * user instead of reverting silently, which is what made BladeWatch-vcur hard to notice.
     */
    @Volatile
    private var lastPersistOk = true

    /** In-memory cache so we don't disk-read on every request. */
    @Volatile
    private var cachedLocale: String? = null

    @Volatile
    private var cachedAt: Long = 0

    private const val CACHE_TTL_MS = 5_000L

    /** The raw persisted tag, preferring the current path over the legacy one. */
    private fun readRawFile(): String? {
        for (path in arrayOf(STATE_FILE, LEGACY_STATE_FILE)) {
            try {
                val f = File(path)
                if (!f.exists() || !f.canRead()) continue
                FileInputStream(f).use { fis ->
                    val buf = ByteArray(16)
                    val n = fis.read(buf)
                    if (n > 0) {
                        val tag = String(buf, 0, n, Charsets.UTF_8).trim()
                        if (tag.isNotEmpty()) return tag
                    }
                }
            } catch (e: Exception) {
                CameraDaemon.log("LocaleManager.readRawFile($path): " + e.message)
            }
        }
        return null
    }

    /**
     * Write the tag, returning whether it reached disk. Callers must not assume success: the whole
     * point of BladeWatch-vcur is that this can fail.
     */
    private fun writeRawFile(tag: String): Boolean = try {
        val dir = File(STATE_DIR)
        if (!dir.exists() && !dir.mkdirs()) {
            CameraDaemon.log("LocaleManager: cannot create $STATE_DIR")
            false
        } else {
            FileOutputStream(STATE_FILE).use { fos ->
                fos.write(tag.toByteArray(Charsets.UTF_8))
            }
            // Readable by the other process too — daemon and both UIs share it.
            File(STATE_FILE).setReadable(true, false)
            true
        }
    } catch (e: Exception) {
        CameraDaemon.log("LocaleManager.writeRawFile: " + e.message)
        false
    }

    /** True when the last persist attempt reached disk. */
    @JvmStatic
    fun lastPersistSucceeded(): Boolean = lastPersistOk

    /**
     * Resolve any tag (e.g. "zh-Hans-CN", "pt", "no") to one of [SUPPORTED]. Mirrors the JS-side
     * `resolveLang` so server and client agree.
     */
    @JvmStatic
    fun resolve(raw: String?): String {
        if (raw.isNullOrEmpty()) return DEFAULT_LANG
        val lower = raw.lowercase()
        // Exact match first
        for (s in SUPPORTED) {
            if (s.lowercase() == lower) return s
        }
        // Common region/script aliases
        if (lower.startsWith("zh-hans") || lower == "zh-cn" || lower == "zh") return "zh-CN"
        if (lower.startsWith("zh-hant") || lower == "zh-tw" || lower == "zh-hk") return "zh-TW"
        if (lower.startsWith("pt")) return "pt-BR"
        if (lower.startsWith("no") || lower.startsWith("nn")) return "nb"
        // Bare-language fallback
        val dash = lower.indexOf('-')
        val bare = if (dash > 0) lower.substring(0, dash) else lower
        for (s in SUPPORTED) {
            val b = s.lowercase()
            val d = b.indexOf('-')
            if ((if (d > 0) b.substring(0, d) else b) == bare) return s
        }
        return DEFAULT_LANG
    }

    @JvmStatic
    fun isSupported(tag: String?): Boolean = tag != null && SUPPORTED_SET.contains(tag)

    /**
     * Raw persisted value: a supported tag, [AUTO_TAG], or null if nothing has been written yet.
     * Used by the picker UI so it can show the "Auto" row as currently selected when appropriate.
     * The HTTP server and message catalogs should keep using [get].
     */
    @JvmStatic
    fun getRaw(): String? = synchronized(LocaleManager::class.java) {
        val tag = readRawFile()
        if (tag != null && (AUTO_TAG == tag || isSupported(tag))) tag else null
    }

    /**
     * True when the user has explicitly chosen "Auto", or when no choice has ever been persisted.
     * In both cases the active locale should follow the device default (BCP-47 of
     * `Locale.getDefault()`).
     */
    @JvmStatic
    fun isAuto(): Boolean {
        val raw = getRaw()
        return raw == null || AUTO_TAG == raw
    }

    /**
     * Persist the "follow system" sentinel. After this, [get] resolves via the device default on
     * each call (the cache is invalidated on write).
     */
    @JvmStatic
    fun setAuto() {
        synchronized(LocaleManager::class.java) {
            lastPersistOk = writeRawFile(AUTO_TAG)
            cachedLocale = null
            cachedAt = 0L
            Messages.invalidate()
        }
    }

    /**
     * Parse an HTTP `Accept-Language` header (e.g. "fr-CA,fr;q=0.9,en;q=0.8") and return the first
     * supported locale. Used on the first request only — once the user has explicitly chosen a
     * locale via the picker we honour [get] instead.
     */
    @JvmStatic
    fun fromAcceptLanguage(header: String?): String {
        if (header.isNullOrEmpty()) return DEFAULT_LANG
        for (p in header.split(",")) {
            var tag = p.trim()
            val semi = tag.indexOf(';')
            if (semi > 0) tag = tag.substring(0, semi).trim()
            if (tag.isEmpty()) continue
            val resolved = resolve(tag)
            // resolve() returns 'en' both for "I want English" and "I want something we don't
            // support"; only treat the latter as a miss.
            if (resolved != DEFAULT_LANG || tag.lowercase().startsWith("en")) {
                return resolved
            }
        }
        return DEFAULT_LANG
    }

    /**
     * Resolve the active locale. Returns one of [SUPPORTED].
     *
     * Resolution order:
     *  1. Persisted user pick (specific tag) → that tag.
     *  2. Persisted "Auto" sentinel OR no file → resolve `Locale.getDefault()` via [resolve].
     *
     * This way the HTTP server and [Messages] always see a real, supported tag without having to
     * know about Auto.
     */
    @JvmStatic
    fun get(): String {
        val now = System.currentTimeMillis()
        cachedLocale?.let { if (now - cachedAt < CACHE_TTL_MS) return it }
        synchronized(LocaleManager::class.java) {
            var resolved = DEFAULT_LANG
            try {
                val raw = readRawFile()
                resolved = if (!raw.isNullOrEmpty() && AUTO_TAG != raw && isSupported(raw)) {
                    raw
                } else {
                    // Auto / unset → resolve from Locale.getDefault(). The daemon process
                    // inherits the BYD system locale at fork.
                    val def = Locale.getDefault()
                    var tag = def.language
                    val region = def.country
                    if (!region.isNullOrEmpty()) tag = "$tag-$region"
                    resolve(tag)
                }
            } catch (e: Exception) {
                CameraDaemon.log("LocaleManager.get: " + e.message)
            }
            cachedLocale = resolved
            cachedAt = now
            return resolved
        }
    }

    /**
     * Persist a new locale. Returns the resolved tag actually written, so callers can echo it back
     * even if the input was an alias.
     *
     * The literal string "auto" writes the [AUTO_TAG] sentinel so subsequent [get] calls follow
     * the system locale; the returned tag is then the system-resolved language, so callers can
     * show the right UI feedback.
     */
    @JvmStatic
    fun set(tag: String?): String {
        if (tag != null && AUTO_TAG.equals(tag.trim(), ignoreCase = true)) {
            setAuto()
            return get()
        }
        val resolved = resolve(tag)
        synchronized(LocaleManager::class.java) {
            lastPersistOk = writeRawFile(resolved)
            cachedLocale = resolved
            cachedAt = System.currentTimeMillis()
            // Drop any cached Messages catalog so the next server-side i18n lookup loads the new
            // locale's JSON.
            Messages.invalidate()
        }
        return resolved
    }
}
