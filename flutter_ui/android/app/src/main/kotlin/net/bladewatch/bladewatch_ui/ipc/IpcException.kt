package net.bladewatch.bladewatch_ui.ipc

/**
 * Typed failures for [IpcClient], surfaced to Dart as distinct platform
 * channel error codes rather than a bare exception message (BladeWatch-ncbb.2).
 */
sealed class IpcException(message: String) : Exception(message) {
    /** `/data/local/tmp/bladewatch_ipc_token` is missing, empty, or unreadable. */
    class TokenUnreadable(message: String) : IpcException(message)

    /** Nothing accepted the TCP connection — the daemon isn't up (or the peer-UID
     *  gate rejected us before any response was ever written; see CommandRejected
     *  below for the case where a response — even an error one — did arrive). */
    class DaemonNotListening(message: String) : IpcException(message)

    /** The daemon responded with `{"status":"error",...}`, or a response arrived
     *  that could not be parsed as JSON at all. */
    class CommandRejected(message: String) : IpcException(message)

    /** Connected, but no response arrived within the read timeout. */
    class Timeout(message: String) : IpcException(message)
}
