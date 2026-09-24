package net.bladewatch.app.server.connect.impl

import net.bladewatch.app.notifications.CompanionInbox
import net.bladewatch.app.server.NotificationApiHandler
import net.bladewatch.app.server.connect.ConnectDispatcher
import net.bladewatch.app.server.connect.ConnectException
import net.bladewatch.app.server.connect.ConnectResponse
import org.json.JSONObject

/**
 * Connect protocol handler for bladewatch.v1.NotificationsService.
 *
 * Routes:
 *   /bladewatch.v1.NotificationsService/GetCategories      → GET  /api/notifications/categories
 *   /bladewatch.v1.NotificationsService/Subscribe          → POST /api/push/subscribe
 *   /bladewatch.v1.NotificationsService/Unsubscribe        → POST /api/push/unsubscribe
 *   /bladewatch.v1.NotificationsService/ListSubscriptions  → GET  /api/push/subscriptions
 *   /bladewatch.v1.NotificationsService/UpdatePreferences  → POST /api/push/preferences
 *   /bladewatch.v1.NotificationsService/SendTest           → POST /api/push/test
 *   /bladewatch.v1.NotificationsService/ListInbox          → (Connect only) [CompanionInbox]
 */
class NotificationsServiceImpl(private val inbox: CompanionInbox) {

    fun register(dispatcher: ConnectDispatcher) {
        dispatcher.register(
            "bladewatch.v1.NotificationsService", "GetCategories", this::handleGetCategories
        )
        dispatcher.register(
            "bladewatch.v1.NotificationsService", "Subscribe", this::handleSubscribe
        )
        dispatcher.register(
            "bladewatch.v1.NotificationsService", "Unsubscribe", this::handleUnsubscribe
        )
        dispatcher.register(
            "bladewatch.v1.NotificationsService", "ListSubscriptions",
            this::handleListSubscriptions
        )
        dispatcher.register(
            "bladewatch.v1.NotificationsService", "UpdatePreferences",
            this::handleUpdatePreferences
        )
        dispatcher.register(
            "bladewatch.v1.NotificationsService", "SendTest", this::handleSendTest
        )
        dispatcher.register(
            "bladewatch.v1.NotificationsService", "ListInbox", this::handleListInbox
        )
    }

    @Throws(ConnectException::class)
    private fun handleGetCategories(req: String?, clientIdentity: String?): ConnectResponse =
        // getCategories() merges the registry blob with vapidPublicKey at the root. The proto
        // expects GetCategoriesResponse{categories_json:"<registry blob>", vapid_public_key}, so
        // the blob is stringified back out of the merge here.
        json {
            val merged = NotificationApiHandler.getCategories()
            val vapid = merged.optString("vapidPublicKey", "")
            merged.remove("vapidPublicKey")
            JSONObject()
                .put("categoriesJson", merged.toString())
                .put("vapidPublicKey", vapid)
        }

    @Throws(ConnectException::class)
    private fun handleSubscribe(req: String?, clientIdentity: String?): ConnectResponse =
        json { NotificationApiHandler.subscribe(req) }

    @Throws(ConnectException::class)
    private fun handleUnsubscribe(req: String?, clientIdentity: String?): ConnectResponse =
        json { NotificationApiHandler.unsubscribe(req) }

    @Throws(ConnectException::class)
    private fun handleListSubscriptions(req: String?, clientIdentity: String?): ConnectResponse =
        json { NotificationApiHandler.listSubscriptions() }

    @Throws(ConnectException::class)
    private fun handleUpdatePreferences(req: String?, clientIdentity: String?): ConnectResponse =
        json { NotificationApiHandler.updatePreferences(req) }

    @Throws(ConnectException::class)
    private fun handleSendTest(req: String?, clientIdentity: String?): ConnectResponse =
        json { NotificationApiHandler.sendTest(req) }

    @Throws(ConnectException::class)
    private fun handleListInbox(req: String?, clientIdentity: String?): ConnectResponse =
        // proto3 JSON writes int64 as a string ("afterId":"42"); optLong reads either form.
        json { body(req).let { inbox.list(it.optLong("afterId", 0L), it.optInt("limit", 0)) } }
}
