package net.bladewatch.app.server.connect.impl

import net.bladewatch.app.auth.AuthManager
import net.bladewatch.app.server.connect.ConnectDispatcher
import net.bladewatch.app.server.connect.ConnectException
import net.bladewatch.app.server.connect.ConnectResponse

/**
 * Connect protocol handler for bladewatch.v1.AuthService: cache invalidation only. The web login
 * (Login, Logout, GetAuthStatus) was removed with the web app (BladeWatch-rdtj.22).
 */
class AuthServiceImpl {

    fun register(dispatcher: ConnectDispatcher) {
        dispatcher.register(
            "bladewatch.v1.AuthService", "InvalidateAuthCache",
            this::handleInvalidateAuthCache
        )
    }

    @Throws(ConnectException::class)
    private fun handleInvalidateAuthCache(
        requestJson: String?,
        clientIdentity: String?
    ): ConnectResponse = try {
        AuthManager.invalidateCache()
        ConnectResponse.of("{\"success\":true}")
    } catch (e: Exception) {
        ConnectResponse.of("{\"success\":false}")
    }
}
