package net.bladewatch.app.server.connect

/**
 * Carries a Connect protocol error code and message.
 *
 * Connect error codes: `invalid_argument`, `not_found`, `permission_denied`, `unavailable`,
 * `internal`, `unimplemented`, `unauthenticated`, `already_exists`, `resource_exhausted`.
 *
 * Extends [Exception], so it stays CHECKED for the Java that still throws it. Kotlin has no
 * checked exceptions, so every Kotlin function that throws this needs `@Throws` or its Java
 * callers will not compile — see [ConnectServiceHandler].
 */
open class ConnectException(
    /** The Connect error code, e.g. `invalid_argument`. */
    val code: String,
    message: String,
) : Exception(message) {

    /** Java callers use `getCode()`; the Kotlin property already generates it. */
    companion object
}
