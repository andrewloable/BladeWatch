package net.bladewatch.app.surveillance

import net.bladewatch.app.logging.DaemonLogger

import java.io.File
import java.text.MessageFormat
import java.util.Locale

/**
 * SRT subtitle sidecar writer for dashcam recordings.
 *
 * Burned-in video overlay text is intentionally English (universal numerals
 * + km/h). The SRT sidecar emitted by this class carries localized prose
 * ("Person detected close range", "Charging started · 4.3 kW") so playback
 * tools that auto-load matching `.srt` files (VLC, video.js, ExoPlayer)
 * can show the user their language without re-encoding the video.
 *
 * Lifecycle:
 * 1. Caller instantiates one writer per recording / segment.
 * 2. Surveillance / charging / proximity code calls [addEvent] with an offset
 *    measured in milliseconds since the start of the .mp4.
 * 3. On finalize, caller invokes [write] with the playable `.mp4` (already
 *    renamed from .tmp). The SRT lands at `<basename>.srt` next to the mp4.
 *
 * Failure semantics: writing the SRT must never break recording. Every
 * public entry point swallows exceptions internally and routes them to the
 * daemon log. An empty buffer skips the write entirely (no zero-byte .srt).
 *
 * i18n: text is resolved through `net.bladewatch.app.server.Messages`
 * if present (loaded reflectively to avoid a hard build dependency on a class
 * that may be authored by a parallel agent). When the catalog is unavailable
 * we fall back to the i18n key itself with simple [MessageFormat]
 * substitution — useful for development and for unit tests.
 *
 * @param locale baked at construction time — matches the locale the user picked.
 */
class SrtWriter @JvmOverloads constructor(locale: String? = resolveCurrentLocale()) {

    private val locale: String = locale ?: "en"

    private val events = ArrayList<Event>()

    /** Single-event record. Internal for tests. */
    internal class Event(
        @JvmField val offsetMs: Long,
        @JvmField val key: String,
        @JvmField val args: Array<out Any?>
    )

    /**
     * Buffer an event. [offsetMs] is milliseconds since the recording
     * (segment) started. Negative offsets are clamped to 0; we'd rather show
     * a pre-roll event at t=0 than silently drop it.
     *
     * Safe to call from any thread.
     */
    @Synchronized
    fun addEvent(offsetMs: Long, i18nKey: String?, vararg args: Any?) {
        if (i18nKey.isNullOrEmpty()) return
        if (events.size >= MAX_EVENTS) {
            // Don't spam the log on every drop — log once at the boundary.
            if (events.size == MAX_EVENTS) {
                logger.warn(
                    "SRT buffer full ($MAX_EVENTS events); dropping further additions"
                )
            }
            return
        }
        events.add(Event(maxOf(0L, offsetMs), i18nKey, args))
    }

    /** True if no events have been buffered. */
    @Synchronized
    fun isEmpty(): Boolean = events.isEmpty()

    /** Buffered event count. Mainly for diagnostics / tests. */
    @Synchronized
    fun size(): Int = events.size

    /**
     * Finalize: write `<basename>.srt` next to [mp4File].
     * Skips silently if the buffer is empty or the file path is unusable.
     * Never throws.
     *
     * @return the [File] written, or `null` if nothing was written.
     */
    fun write(mp4File: File?): File? {
        val snapshot: List<Event>
        synchronized(this) {
            if (events.isEmpty()) {
                return null
            }
            snapshot = ArrayList(events)
        }

        if (mp4File == null) {
            logger.warn("SRT write skipped: mp4File is null")
            return null
        }

        return try {
            // Sort chronologically — surveillance writers don't always submit
            // events in order (e.g. the timeline collector flushes a pre-record
            // ring buffer mid-stream).
            val sorted = snapshot.sortedBy { it.offsetMs }

            val name = mp4File.name
            val dot = name.lastIndexOf('.')
            val base = if (dot > 0) name.substring(0, dot) else name
            val srtFile = File(mp4File.parentFile, "$base.srt")
            val tmpFile = File(srtFile.absolutePath + ".tmp")

            val sb = StringBuilder(sorted.size * 64)
            var idx = 1
            for (ev in sorted) {
                val text = render(ev.key, ev.args)
                if (text.isEmpty()) continue

                val startMs = ev.offsetMs
                val endMs = startMs + ENTRY_DURATION_MS

                sb.append(idx++).append('\n')
                sb.append(formatTimestamp(startMs)).append(" --> ")
                    .append(formatTimestamp(endMs)).append('\n')
                sb.append(text).append('\n')
                sb.append('\n')
            }

            if (sb.isEmpty()) {
                // Every event resolved to empty text — nothing to ship.
                return null
            }

            tmpFile.writeText(sb.toString())

            // Atomic-ish swap so a half-written file never appears under the
            // final name (matches the discipline used by the JSON sidecar
            // writer in EventTimelineCollector).
            if (!tmpFile.renameTo(srtFile)) {
                srtFile.writeText(sb.toString())
                tmpFile.delete()
            }

            try {
                srtFile.setReadable(true, false)
            } catch (ignored: Exception) {
                // Best-effort; not all filesystems honour this.
                logger.warn(
                    "SRT setReadable failed on " + srtFile.name + ": " + ignored.message
                )
            }

            logger.info(
                "SRT sidecar written: " + srtFile.name +
                    " (" + (idx - 1) + " entries, locale=" + locale + ")"
            )
            srtFile
        } catch (e: Exception) {
            logger.warn("SRT write failed for " + mp4File.name + ": " + e.message)
            null
        }
    }

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------

    /**
     * Resolve an i18n key against the locale catalog and apply MessageFormat
     * substitution. The catalog (`net.bladewatch.app.server.Messages`)
     * is looked up reflectively so this class compiles even if Messages
     * doesn't exist yet (a parallel agent ships it).
     */
    private fun render(key: String, args: Array<out Any?>): String {
        // Fallback: return the key itself with arg substitution. This is
        // legible enough during development that bugs get spotted early.
        val template = lookupCatalog(key, locale) ?: key
        if (args.isEmpty()) return template
        return try {
            MessageFormat.format(template, *args)
        } catch (e: Exception) {
            // Bad placeholder in the template — emit the raw template so the
            // operator at least sees what fired.
            logger.warn("MessageFormat failed for SRT key '$key': " + e.message)
            template
        }
    }

    companion object {
        private val logger = DaemonLogger.getInstance("SrtWriter")

        /** How long each subtitle entry stays on screen. */
        private const val ENTRY_DURATION_MS = 4_000L

        /** Cap on buffered events so a chatty pipeline can't OOM us. */
        private const val MAX_EVENTS = 1024

        /** Format ms as `HH:MM:SS,mmm` — the SRT V2 timestamp form. */
        @JvmStatic
        internal fun formatTimestamp(ms: Long): String {
            val clamped = if (ms < 0) 0L else ms
            val totalSec = clamped / 1000L
            return String.format(
                Locale.US, "%02d:%02d:%02d,%03d",
                totalSec / 3600L, (totalSec % 3600L) / 60L, totalSec % 60L, clamped % 1000L
            )
        }

        /** Reflectively call `Messages.get(locale, key)` or `Messages.get(key)`. */
        private fun lookupCatalog(key: String, locale: String): String? {
            try {
                val cls = Class.forName("net.bladewatch.app.server.Messages")
                // Try (locale, key) first
                try {
                    val m = cls.getMethod("get", String::class.java, String::class.java)
                    val out = m.invoke(null, locale, key)
                    if (out is String) return out
                } catch (ignored: NoSuchMethodException) {
                    logger.debug("Messages.get(String,String) not found, trying single-arg")
                }

                // Fallback to a single-arg signature that resolves the locale
                // internally (some catalogs use a thread-local locale set by
                // LocaleManager.get()).
                try {
                    val m = cls.getMethod("get", String::class.java)
                    val out = m.invoke(null, key)
                    if (out is String) return out
                } catch (ignored: NoSuchMethodException) {
                    logger.debug("Messages.get(String) not found either, falling through")
                }
            } catch (e: ClassNotFoundException) {
                logger.debug(
                    "Messages class not on classpath, using key as fallback: " + e.message
                )
            } catch (e: Exception) {
                // Reflection failure — log once and stop trying.
                logger.warn("Messages reflection failed: " + e.message)
            }
            return null
        }

        private fun resolveCurrentLocale(): String {
            try {
                val cls = Class.forName("net.bladewatch.app.server.LocaleManager")
                val out = cls.getMethod("get").invoke(null)
                if (out is String) return out
            } catch (ignored: Exception) {
                // LocaleManager unavailable — default to English.
                logger.warn(
                    "LocaleManager resolution failed — defaulting to 'en': " + ignored.message
                )
            }
            return "en"
        }

        // ------------------------------------------------------------------
        // i18n key constants — kept here so the recording call sites don't have
        // to remember string spelling and Find Usages turns up every emitter.
        // ------------------------------------------------------------------

        const val K_PERSON_DETECTED = "srt.person_detected"
        const val K_PERSON_CLOSE = "srt.person_close"
        const val K_VEHICLE_DETECTED = "srt.vehicle_detected"
        const val K_MOTION_STARTED = "srt.motion_started"
        const val K_PROXIMITY_RED = "srt.proximity_red"
        const val K_PROXIMITY_YELLOW = "srt.proximity_yellow"
        const val K_RECORDING_STARTED = "srt.recording_started"
    }
}
