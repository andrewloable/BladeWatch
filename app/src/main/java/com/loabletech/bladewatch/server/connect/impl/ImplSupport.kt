package net.bladewatch.app.server.connect.impl

import net.bladewatch.app.server.connect.ConnectException
import net.bladewatch.app.server.connect.ConnectResponse
import org.json.JSONObject

/**
 * The wrapper every Connect impl method used to spell out by hand: call the handler, stringify its
 * JSON, let a typed [ConnectException] through, and turn anything else into a generic internal
 * error so handler internals never reach the client.
 *
 * Extracted while migrating the impls to Kotlin — it was 11 files' worth of the identical
 * three-branch try/catch, and transcribing it once is both shorter and harder to get subtly wrong.
 */
@Throws(ConnectException::class)
internal inline fun json(op: () -> JSONObject): ConnectResponse = try {
    ConnectResponse.of(op().toString())
} catch (ce: ConnectException) {
    throw ce
} catch (e: Exception) {
    throw ConnectException("internal", "An internal error occurred")
}

/** As [json], but the operation has already produced the response body as a string. */
@Throws(ConnectException::class)
internal inline fun jsonString(op: () -> String): ConnectResponse = try {
    ConnectResponse.of(op())
} catch (ce: ConnectException) {
    throw ce
} catch (e: Exception) {
    throw ConnectException("internal", "An internal error occurred")
}

/** An empty or unparseable body is an empty request, not a failure. */
internal fun body(req: String?): JSONObject {
    if (req.isNullOrEmpty()) return JSONObject()
    return try {
        JSONObject(req)
    } catch (e: Exception) {
        JSONObject()
    }
}
