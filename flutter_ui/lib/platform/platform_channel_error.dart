/// Error types for [PlatformChannel] (BladeWatch-ncbb.2) — shared between the
/// real [MethodChannelBridge] and the test double `FakePlatformChannel`
/// (flutter_ui/test/fakes/fake_platform_channel.dart), so a controller
/// catches the same types regardless of which one it's actually talking to.
library;

/// The three failure modes that actually occur on this hardware: a dead
/// shell call, the daemon not being up yet, or a denied permission.
enum PlatformChannelErrorReason { shellCallFailed, daemonNotUp, permissionDenied }

class PlatformChannelError implements Exception {
  final PlatformChannelErrorReason reason;
  final String message;

  const PlatformChannelError(this.reason, this.message);

  @override
  String toString() => 'PlatformChannelError(${reason.name}): $message';
}

class ChannelTimeoutException implements Exception {
  final String group;
  final String method;

  const ChannelTimeoutException(this.group, this.method);

  @override
  String toString() => '$group/$method timed out';
}
