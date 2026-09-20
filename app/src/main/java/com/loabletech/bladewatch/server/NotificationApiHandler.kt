package net.bladewatch.app.server

import android.util.Base64
import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.notifications.CategoryRegistry
import net.bladewatch.app.notifications.NotificationBus
import net.bladewatch.app.notifications.NotificationEvent
import net.bladewatch.app.notifications.push.PushSubscription
import net.bladewatch.app.notifications.push.SubscriptionStore
import net.bladewatch.app.notifications.push.VapidKeyStore
import net.bladewatch.app.server.connect.ConnectException
import org.json.JSONArray
import org.json.JSONObject
import java.util.Locale

/**
 * The Web Push subsystem's operations, behind `NotificationsService`.
 *
 * All of them require auth, which the caller applies before dispatch.
 *
 * BladeWatch-6mnq: this was a REST handler matching /api/notifications/ and /api/push/ paths and
 * writing JSON into an OutputStream that the Connect layer captured straight back out. Each
 * operation now RETURNS its JSON, and the HTTP status codes that carried meaning became Connect
 * error codes: 503 not-initialised → unavailable, 400 → invalid_argument, 404 → not_found.
 */
object NotificationApiHandler {

    private val logger: DaemonLogger = DaemonLogger.getInstance("NotificationApiHandler")

    private const val B64_FLAGS = Base64.URL_SAFE or Base64.NO_PADDING or Base64.NO_WRAP

    @Volatile
    private var registry: CategoryRegistry? = null

    @Volatile
    private var subStore: SubscriptionStore? = null

    @Volatile
    private var keyStore: VapidKeyStore? = null

    /** Wire the dependencies once at daemon startup. */
    @JvmStatic
    fun init(r: CategoryRegistry?, s: SubscriptionStore?, k: VapidKeyStore?) {
        registry = r
        subStore = s
        keyStore = k
    }

    /** Every operation needs the three stores; without them there is nothing to answer with. */
    @Throws(ConnectException::class)
    private fun requireReady(): Triple<CategoryRegistry, SubscriptionStore, VapidKeyStore> {
        val r = registry
        val s = subStore
        val k = keyStore
        if (r == null || s == null || k == null) {
            throw ConnectException("unavailable", "Notifications not initialized")
        }
        return Triple(r, s, k)
    }

    @JvmStatic
    @Throws(Exception::class)
    fun getCategories(): JSONObject {
        val (r, _, k) = requireReady()
        val root = JSONObject(r.rawJson())
        root.put("vapidPublicKey", k.publicKeyB64Url())
        return root
    }

    @JvmStatic
    @Throws(Exception::class)
    fun subscribe(requestBody: String?): JSONObject {
        val (_, store, _) = requireReady()
        if (requestBody.isNullOrEmpty()) {
            throw ConnectException("invalid_argument", "missing body")
        }
        try {
            val j = JSONObject(requestBody)
            val endpoint = j.getString("endpoint")
            val keys = j.getJSONObject("keys")
            val p256dh = Base64.decode(keys.getString("p256dh"), B64_FLAGS)
            val auth = Base64.decode(keys.getString("auth"), B64_FLAGS)
            val label = j.optString("label", null)

            val id = SubscriptionStore.idForEndpoint(endpoint)

            val existing = store.get(id)
            val sub: PushSubscription
            if (existing != null) {
                // Re-subscribe — keep prefs, refresh keys
                sub = PushSubscription(
                    id, endpoint, p256dh, auth, label ?: existing.label, existing.createdAt
                )
                sub.lastSeenAt = System.currentTimeMillis()
                sub.minSeverity = existing.minSeverity
                sub.mutedCategories.addAll(existing.mutedCategories)
                sub.quietHours = existing.quietHours
            } else {
                sub = PushSubscription(
                    id, endpoint, p256dh, auth, label, System.currentTimeMillis()
                )
            }
            store.put(sub)

            val resp = JSONObject()
            resp.put("success", true)
            resp.put("id", id)
            return resp
        } catch (e: Exception) {
            // A malformed endpoint or un-decodable key is the caller's problem, not ours.
            throw ConnectException("invalid_argument", "invalid subscription: " + e.message)
        }
    }

    @JvmStatic
    @Throws(Exception::class)
    fun unsubscribe(requestBody: String?): JSONObject {
        val (_, store, _) = requireReady()
        if (requestBody.isNullOrEmpty()) {
            throw ConnectException("invalid_argument", "missing body")
        }
        val j = JSONObject(requestBody)
        var id = j.optString("id", null)
        if (id == null) {
            val endpoint = j.optString("endpoint", null)
            if (endpoint != null) id = SubscriptionStore.idForEndpoint(endpoint)
        }
        if (id == null) {
            throw ConnectException("invalid_argument", "id or endpoint required")
        }
        val resp = JSONObject()
        resp.put("success", store.remove(id))
        return resp
    }

    @JvmStatic
    @Throws(Exception::class)
    fun listSubscriptions(): JSONObject {
        val (_, store, _) = requireReady()
        val arr = JSONArray()
        for (s in store.all()) {
            val j = JSONObject()
            j.put("id", s.id)
            j.put("label", s.label ?: "")
            j.put("createdAt", s.createdAt)
            j.put("lastSeenAt", s.lastSeenAt)
            j.put("minSeverity", s.minSeverity.name.lowercase(Locale.US))
            val muted = JSONArray()
            for (c in s.mutedCategories) muted.put(c)
            j.put("mutedCategories", muted)
            s.quietHours?.let { qhv ->
                val qh = JSONObject()
                qh.put("startMin", qhv.startMin)
                qh.put("endMin", qhv.endMin)
                qh.put("allowCritical", qhv.allowCritical)
                j.put("quietHours", qh)
            }
            arr.put(j)
        }
        val resp = JSONObject()
        resp.put("success", true)
        resp.put("subscriptions", arr)
        return resp
    }

    @JvmStatic
    @Throws(Exception::class)
    fun updatePreferences(requestBody: String?): JSONObject {
        val (_, store, _) = requireReady()
        if (requestBody.isNullOrEmpty()) {
            throw ConnectException("invalid_argument", "missing body")
        }
        val j = JSONObject(requestBody)
        val sub = store.get(j.getString("id"))
            ?: throw ConnectException("not_found", "subscription not found")

        if (j.has("mutedCategories")) {
            val muted = j.getJSONArray("mutedCategories")
            sub.mutedCategories.clear()
            for (i in 0 until muted.length()) {
                sub.mutedCategories.add(muted.getString(i))
            }
        }
        if (j.has("minSeverity")) {
            try {
                sub.minSeverity = NotificationEvent.Severity.valueOf(
                    j.getString("minSeverity").uppercase(Locale.US)
                )
            } catch (ignored: Exception) {
                logger.warn("Failed to parse minSeverity value: " + ignored.message)
            }
        }
        if (j.has("quietHours")) {
            val qhRaw = j.get("quietHours")
            if (qhRaw === JSONObject.NULL) {
                sub.quietHours = null
            } else {
                val qh = qhRaw as JSONObject
                sub.quietHours = PushSubscription.QuietHours(
                    qh.getInt("startMin"),
                    qh.getInt("endMin"),
                    qh.optBoolean("allowCritical", true)
                )
            }
        }

        // re-persist — the store mutates in place but the file write happens via put()
        store.put(sub)
        return success()
    }

    @JvmStatic
    @Throws(Exception::class)
    fun sendTest(requestBody: String?): JSONObject {
        requireReady()
        var category = "surveillance.motion"
        var severityStr = "info"
        if (!requestBody.isNullOrEmpty()) {
            try {
                val j = JSONObject(requestBody)
                category = j.optString("category", category)
                severityStr = j.optString("severity", severityStr)
            } catch (ignored: Exception) {
                logger.warn("Failed to parse sendTest body: " + ignored.message)
            }
        }
        val severity = try {
            NotificationEvent.Severity.valueOf(severityStr.uppercase(Locale.US))
        } catch (e: Exception) {
            logger.warn("Failed to parse severity '$severityStr': " + e.message)
            NotificationEvent.Severity.INFO
        }
        NotificationBus.get().publish(
            NotificationEvent(
                category,
                severity,
                "Test notification",
                "If you're seeing this, push delivery works.",
                "test-" + System.currentTimeMillis(),
                null,
                JSONObject().put("test", true)
            )
        )
        return success()
    }

    @Throws(Exception::class)
    private fun success(): JSONObject {
        val resp = JSONObject()
        resp.put("success", true)
        return resp
    }
}
