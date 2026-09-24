import 'package:bladewatch_rpc/rpc/jwt_source.dart';

import 'platform_channel.dart';

/// Dart side of the `auth.*` channel group (BladeWatch-ncbb.2) — implements
/// [JwtSource] (BladeWatch-ncbb.1) so it plugs directly into `ConnectClient`.
/// All the actual work (fetching the device secret over loopback IPC,
/// signing the JWT) happens in Kotlin
/// (`flutter_ui/android/app/src/main/kotlin/net/bladewatch/bladewatch_ui/auth/JwtMinter.kt`);
/// this class only carries the call across the platform channel.
class AuthChannel implements JwtSource {
  final PlatformChannel _channel;

  const AuthChannel(this._channel);

  @override
  Future<String?> mintJwt() => _channel.invoke<String?>('auth', 'mintJwt');

  @override
  Future<int> stateVersion() => _channel.invoke<int>('auth', 'stateVersion');

  /// Bumps the version [stateVersion] reports — call after the device
  /// secret is known to have rotated, so `ConnectClient` drops its cached
  /// JWT immediately instead of waiting out the TTL.
  Future<void> invalidate() => _channel.invoke<void>('auth', 'invalidate');

  /// BladeWatch-yz1e.2 (Dashboard access-code tile): the raw device secret,
  /// for deliberate, user-initiated display — see `JwtMinter.getAccessCode()`'s
  /// doc comment for why this is safe despite [ConfigChannel]'s warning
  /// against reading this section generically. Null if unavailable.
  Future<String?> getAccessCode() => _channel.invoke<String?>('auth', 'getAccessCode');

  /// Generates and persists a new random access code; null if the daemon
  /// rejected the write.
  Future<String?> regenerateAccessCode() => _channel.invoke<String?>('auth', 'regenerateAccessCode');

  /// Sets a user-chosen access code. False if too short or the daemon
  /// rejected the write.
  Future<bool> setCustomAccessCode(String password) =>
      _channel.invoke<bool>('auth', 'setCustomAccessCode', {'password': password});
}
