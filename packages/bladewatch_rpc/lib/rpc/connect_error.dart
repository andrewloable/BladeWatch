/// A Connect protocol error surfaced by the daemon, e.g.
/// `{"code":"not_found","message":"..."}` from
/// ConnectDispatcher.sendConnectError (see
/// app/src/main/java/com/loabletech/bladewatch/server/connect/ConnectDispatcher.java).
/// Every RPC failure surfaces as this typed error, never a raw string.
class ConnectError implements Exception {
  /// The HTTP status the daemon responded with (0 if the request never
  /// completed at all, e.g. a timeout).
  final int httpStatus;
  final String code;
  final String message;

  const ConnectError({required this.httpStatus, required this.code, required this.message});

  @override
  String toString() => 'ConnectError($code, http=$httpStatus): $message';

  @override
  bool operator ==(Object other) =>
      other is ConnectError &&
      other.httpStatus == httpStatus &&
      other.code == code &&
      other.message == message;

  @override
  int get hashCode => Object.hash(httpStatus, code, message);
}
