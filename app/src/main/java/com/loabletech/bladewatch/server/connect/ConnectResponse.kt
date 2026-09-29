package net.bladewatch.app.server.connect

/** The JSON body a Connect service handler returns. */
class ConnectResponse private constructor(body: String?) {

    @JvmField
    val body: String = body ?: "{}"

    companion object {
        /** Wrap a JSON body. */
        @JvmStatic
        fun of(body: String?): ConnectResponse = ConnectResponse(body)
    }
}
