package net.bladewatch.app.notifications.push

import android.util.Base64
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.notifications.NotificationEvent
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.Locale

/**
 * Per-device Web Push subscription with user preferences.
 *
 * Persisted as JSON; one entry per phone the user installed the PWA on. Preferences (muted
 * categories, severity floor, quiet hours) are scoped to this subscription so each device can
 * have its own notification settings.
 */
class PushSubscription(
    /** Stable identifier — derived from the endpoint URL hash to keep PII out of file names. */
    @JvmField val id: String,
    @JvmField val endpoint: String,
    /** P-256 public key from `PushSubscription.toJSON().keys.p256dh`, raw 65 bytes. */
    @JvmField val p256dh: ByteArray,
    /** 16-byte auth secret from `PushSubscription.toJSON().keys.auth`. */
    @JvmField val auth: ByteArray,
    /** User-visible label, e.g. "iPhone 11 Pro". May be null. */
    @JvmField val label: String?,
    @JvmField val createdAt: Long
) {

    @Volatile
    @JvmField
    var lastSeenAt: Long = createdAt

    /** Categories the user has muted on this device. */
    @JvmField
    val mutedCategories: MutableSet<String> = HashSet()

    /** Severity floor — events below this are dropped before encryption. */
    @Volatile
    @JvmField
    var minSeverity: NotificationEvent.Severity = NotificationEvent.Severity.INFO

    /** Quiet hours window. May be null. */
    @Volatile
    @JvmField
    var quietHours: QuietHours? = null

    fun isMuted(category: String): Boolean {
        if (mutedCategories.contains(category)) return true
        // dotted-prefix mute: muting "vehicle.health" mutes "vehicle.health.tyre.leak" too
        for (muted in mutedCategories) {
            if (muted.endsWith(".*")) {
                val prefix = muted.substring(0, muted.length - 1)
                if (category.startsWith(prefix)) return true
            }
        }
        return false
    }

    fun inQuietHours(now: Long): Boolean = quietHours?.contains(now) == true

    fun toJson(): JSONObject {
        val j = JSONObject()
        try {
            j.put("id", id)
            j.put("endpoint", endpoint)
            j.put("p256dh", Base64.encodeToString(p256dh, B64_FLAGS))
            j.put("auth", Base64.encodeToString(auth, B64_FLAGS))
            if (label != null) j.put("label", label)
            j.put("createdAt", createdAt)
            j.put("lastSeenAt", lastSeenAt)

            val muted = JSONArray()
            for (c in mutedCategories) muted.put(c)
            j.put("mutedCategories", muted)
            j.put("minSeverity", minSeverity.name.lowercase(Locale.US))

            quietHours?.let { qhv ->
                val qh = JSONObject()
                qh.put("startMin", qhv.startMin)
                qh.put("endMin", qhv.endMin)
                qh.put("allowCritical", qhv.allowCritical)
                j.put("quietHours", qh)
            }
        } catch (ignored: Exception) {
            logger.warn(
                "Failed to serialize push subscription: " + ignored.message + " (" + ignored + ")"
            )
        }
        return j
    }

    class QuietHours(
        /** Minutes since local midnight. */
        @JvmField val startMin: Int,
        @JvmField val endMin: Int,
        @JvmField val allowCritical: Boolean
    ) {
        fun contains(epochMillis: Long): Boolean {
            val c = Calendar.getInstance()
            c.timeInMillis = epochMillis
            val min = c.get(Calendar.HOUR_OF_DAY) * 60 + c.get(Calendar.MINUTE)
            if (startMin == endMin) return false
            return if (startMin < endMin) {
                min in startMin until endMin
            } else {
                // wraps midnight
                min >= startMin || min < endMin
            }
        }
    }

    companion object {
        private val logger: DaemonLogger = DaemonLogger.getInstance("PushSubscription")

        private const val B64_FLAGS = Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP

        @JvmStatic
        @Throws(Exception::class)
        fun fromJson(j: JSONObject): PushSubscription {
            val p256dh = Base64.decode(j.getString("p256dh"), B64_FLAGS)
            val auth = Base64.decode(j.getString("auth"), B64_FLAGS)

            val s = PushSubscription(
                j.getString("id"),
                j.getString("endpoint"),
                p256dh,
                auth,
                j.optString("label", null),
                j.optLong("createdAt", System.currentTimeMillis())
            )
            s.lastSeenAt = j.optLong("lastSeenAt", s.createdAt)

            val muted = j.optJSONArray("mutedCategories")
            if (muted != null) {
                for (i in 0 until muted.length()) s.mutedCategories.add(muted.getString(i))
            }

            val sev = j.optString("minSeverity", "info")
            try {
                s.minSeverity = NotificationEvent.Severity.valueOf(sev.uppercase(Locale.US))
            } catch (ignored: Exception) {
                logger.warn(
                    "Invalid minSeverity value in push subscription, defaulting to INFO: " +
                        ignored.message
                )
                s.minSeverity = NotificationEvent.Severity.INFO
            }

            val qh = j.optJSONObject("quietHours")
            if (qh != null) {
                s.quietHours = QuietHours(
                    qh.getInt("startMin"),
                    qh.getInt("endMin"),
                    qh.optBoolean("allowCritical", true)
                )
            }

            return s
        }
    }
}
