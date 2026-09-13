import 'package:flutter/services.dart';

import 'platform_channel.dart';
import 'platform_channel_error.dart';

/// The real [PlatformChannel], backed by a Flutter [MethodChannel] to the
/// Kotlin side under `flutter_ui/android/app/src/main/kotlin/` — the actual
/// IPC client, JWT minting, daemon control, secret config, and OTA update
/// logic all live there (BladeWatch-ncbb.2); this class only carries method
/// calls across the platform boundary and maps the native error codes back
/// to the shared [PlatformChannelError]/[ChannelTimeoutException] types.
///
/// Method name on the wire is `"<group>.<method>"` (e.g. `"auth.mintJwt"`) —
/// the Kotlin side dispatches on that single string rather than needing a
/// separate `MethodChannel` per group.
class MethodChannelBridge implements PlatformChannel {
  static const _defaultChannelName = 'net.bladewatch.flutter/privileged';

  final MethodChannel _channel;

  MethodChannelBridge([MethodChannel? channel]) : _channel = channel ?? const MethodChannel(_defaultChannelName);

  @override
  Future<T> invoke<T>(String group, String method, [Object? args]) async {
    try {
      return await _channel.invokeMethod<T>('$group.$method', args) as T;
    } on PlatformException catch (e) {
      throw _mapException(group, method, e);
    } on MissingPluginException {
      // No handler registered on the native side at all — from the caller's
      // point of view this is indistinguishable from "nothing is there yet".
      throw PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, '$group.$method: no native handler registered');
    }
  }

  Exception _mapException(String group, String method, PlatformException e) {
    switch (e.code) {
      case 'TIMEOUT':
        return ChannelTimeoutException(group, method);
      case 'DAEMON_NOT_LISTENING':
        return PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, e.message ?? e.code);
      case 'PERMISSION_DENIED':
        return PlatformChannelError(PlatformChannelErrorReason.permissionDenied, e.message ?? e.code);
      case 'TOKEN_UNREADABLE':
      case 'COMMAND_REJECTED':
        return PlatformChannelError(PlatformChannelErrorReason.shellCallFailed, e.message ?? e.code);
      default:
        return PlatformChannelError(PlatformChannelErrorReason.shellCallFailed, '${e.code}: ${e.message ?? ''}');
    }
  }
}
