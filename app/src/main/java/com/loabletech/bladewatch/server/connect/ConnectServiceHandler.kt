package net.bladewatch.app.server.connect

/**
 * Handler for one RPC method within a Connect service.
 *
 * Receives the raw JSON request body and returns a [ConnectResponse] carrying the JSON body and
 * any extra HTTP headers (e.g. Set-Cookie) to forward to the client.
 *
 * Throw [ConnectException] to return a typed Connect error response.
 *
 * `fun interface`, not a plain one: every registration is a Java method reference
 * (`this::handleGetQuality`), which only compiles against a SAM type.
 */
fun interface ConnectServiceHandler {
    @Throws(ConnectException::class)
    fun handle(requestJson: String?, clientIdentity: String?): ConnectResponse
}
