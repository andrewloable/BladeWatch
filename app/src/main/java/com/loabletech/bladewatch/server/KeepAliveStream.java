package net.bladewatch.app.server;

import java.io.FilterOutputStream;
import java.io.IOException;
import java.io.OutputStream;

/**
 * Carries the per-request keep-alive decision to the response writers.
 *
 * <p>BladeWatch-67h8. Every writer in this package already receives the request's
 * {@link OutputStream}, but none of them receives the {@link java.net.Socket} or any
 * per-connection state, so there was no way to tell them whether to emit
 * {@code Connection: close} or {@code Connection: keep-alive}. The alternatives were
 * threading a boolean through ~17 methods and their call sites (38 for
 * {@code sendError} alone), or a {@code ThreadLocal}. This is neither: the flag rides
 * the object that is already being passed.
 *
 * <p>Writers must not read this directly — call
 * {@link HttpResponse#connectionHeader(OutputStream)}, which degrades to
 * {@code Connection: close} for a plain stream. That default matters: a writer reached
 * with an unwrapped stream (a test, a future code path) keeps the old, always-correct
 * behaviour rather than silently promising to hold a connection open that nobody is
 * going to read from again.
 *
 * <p>Not thread-safe, and does not need to be: {@code HttpServer} is thread-per-connection,
 * so exactly one thread ever touches a given instance.
 */
final class KeepAliveStream extends FilterOutputStream {

    /** False until the server has decided this specific response may be followed by another. */
    private boolean keepAlive;

    KeepAliveStream(OutputStream delegate) {
        super(delegate);
    }

    void setKeepAlive(boolean value) {
        this.keepAlive = value;
    }

    boolean isKeepAlive() {
        return keepAlive;
    }

    /**
     * {@link FilterOutputStream}'s inherited {@code write(byte[], int, int)} loops over
     * single-byte writes, which would turn every response body into one syscall per byte
     * through the buffered stream underneath. Delegate the bulk form directly.
     */
    @Override
    public void write(byte[] b, int off, int len) throws IOException {
        out.write(b, off, len);
    }
}
