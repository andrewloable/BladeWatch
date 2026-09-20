package net.bladewatch.app.server

import java.io.FilterOutputStream
import java.io.IOException
import java.io.OutputStream

/**
 * Carries the per-request keep-alive decision to the response writers.
 *
 * BladeWatch-67h8. Every writer in this package already receives the request's [OutputStream], but
 * none of them receives the [java.net.Socket] or any per-connection state, so there was no way to
 * tell them whether to emit `Connection: close` or `Connection: keep-alive`. The alternatives were
 * threading a boolean through ~17 methods and their call sites (38 for `sendError` alone), or a
 * ThreadLocal. This is neither: the flag rides the object that is already being passed.
 *
 * Writers must not read this directly — call [HttpResponse.connectionHeader], which degrades to
 * `Connection: close` for a plain stream. That default matters: a writer reached with an unwrapped
 * stream (a test, a future code path) keeps the old, always-correct behaviour rather than silently
 * promising to hold a connection open that nobody is going to read from again.
 *
 * Not thread-safe, and does not need to be: `HttpServer` is thread-per-connection, so exactly one
 * thread ever touches a given instance.
 */
internal class KeepAliveStream(delegate: OutputStream) : FilterOutputStream(delegate) {

    /** False until the server has decided this specific response may be followed by another. */
    var isKeepAlive: Boolean = false

    /**
     * [FilterOutputStream]'s inherited `write(byte[], int, int)` loops over single-byte writes,
     * which would turn every response body into one syscall per byte through the buffered stream
     * underneath. Delegate the bulk form directly.
     */
    @Throws(IOException::class)
    override fun write(b: ByteArray, off: Int, len: Int) {
        out.write(b, off, len)
    }
}
