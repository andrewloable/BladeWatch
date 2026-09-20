package net.bladewatch.app.server.connect

/**
 * Carries the JSON body and any extra HTTP response headers (e.g. Set-Cookie) that a Connect
 * service handler wants the dispatcher to forward to the client.
 */
class ConnectResponse private constructor(
    body: String?,
    extraHeaders: List<String>?,
) {

    @JvmField
    val body: String = body ?: "{}"

    /** Additional "Name: Value" header strings to append to the HTTP response. */
    @JvmField
    val extraHeaders: List<String> = extraHeaders?.toList() ?: emptyList()

    companion object {
        /** Wrap a plain JSON body with no extra headers. */
        @JvmStatic
        fun of(body: String?): ConnectResponse = ConnectResponse(body, null)

        /** Wrap a JSON body and attach one or more Set-Cookie headers to forward. */
        @JvmStatic
        fun withCookies(body: String?, setCookieValues: List<String>): ConnectResponse =
            ConnectResponse(body, setCookieValues.map { "Set-Cookie: $it" })
    }
}
