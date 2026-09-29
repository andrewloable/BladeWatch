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
 * Routes: GetCategories, SendTest ([NotificationApiHandler]) and ListInbox ([CompanionInbox]).
 */
class NotificationsServiceImpl(private val inbox: CompanionInbox) {

    fun register(dispatcher: ConnectDispatcher) {
        dispatcher.register(
            "bladewatch.v1.NotificationsService", "GetCategories", this::handleGetCategories
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
        // GetCategoriesResponse{categories_json:"<registry blob>"}: the registry blob, stringified.
        json { JSONObject().put("categoriesJson", NotificationApiHandler.getCategories().toString()) }

    @Throws(ConnectException::class)
    private fun handleSendTest(req: String?, clientIdentity: String?): ConnectResponse =
        json { NotificationApiHandler.sendTest(req) }

    @Throws(ConnectException::class)
    private fun handleListInbox(req: String?, clientIdentity: String?): ConnectResponse =
        // proto3 JSON writes int64 as a string ("afterId":"42"); optLong reads either form.
        json { body(req).let { inbox.list(it.optLong("afterId", 0L), it.optInt("limit", 0)) } }
}
