package net.bladewatch.app.server

import net.bladewatch.app.logging.DaemonLogger
import net.bladewatch.app.notifications.CategoryRegistry
import net.bladewatch.app.notifications.NotificationBus
import net.bladewatch.app.notifications.NotificationEvent
import net.bladewatch.app.server.connect.ConnectException
import org.json.JSONObject
import java.util.Locale

/**
 * The operations behind `NotificationsService` that need the category registry: the category list
 * and the test alert. The store-and-forward inbox (`ListInbox`) is [net.bladewatch.app.notifications.CompanionInbox].
 *
 * All of them require auth, which the caller applies before dispatch. An operation RETURNS its JSON,
 * and a failure is a Connect error code: not initialised -> unavailable.
 */
object NotificationApiHandler {

    private val logger: DaemonLogger = DaemonLogger.getInstance("NotificationApiHandler")

    @Volatile
    private var registry: CategoryRegistry? = null

    /** Wire the dependency once at daemon startup. */
    @JvmStatic
    fun init(r: CategoryRegistry?) {
        registry = r
    }

    @Throws(ConnectException::class)
    private fun requireReady(): CategoryRegistry =
        registry ?: throw ConnectException("unavailable", "Notifications not initialized")

    @JvmStatic
    @Throws(Exception::class)
    fun getCategories(): JSONObject = JSONObject(requireReady().rawJson())

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
        return JSONObject().put("success", true)
    }
}
