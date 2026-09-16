import 'platform_channel.dart';

/// Dart side of the `config.*` channel group (BladeWatch-ncbb.2) — for the
/// settings backed by the daemon-owned secret
/// store. Thin-wraps the Kotlin `SecretConfigChannel` class
/// (`secret_get`/`secret_put`/`secret_delete` over loopback IPC). Any
/// [PlatformChannelError] / [ChannelTimeoutException] propagates unchanged.
///
/// **Never add a method that reads the whole `auth` section or its
/// `deviceSecret` key** — `AuthChannel` is the only caller allowed to touch
/// that value, and even it never returns the raw secret to Dart (see the
/// Security Notes in CLAUDE.md).
class ConfigChannel {
  final PlatformChannel _channel;

  const ConfigChannel(this._channel);

  /// Returns the stored value, or null if the key isn't set.
  Future<String?> get(String section, String key) =>
      _channel.invoke<String?>('config', 'get', {'section': section, 'key': key});

  Future<bool> put(String section, String key, String value) =>
      _channel.invoke<bool>('config', 'put', {'section': section, 'key': key, 'value': value});

  Future<bool> delete(String section, String key) =>
      _channel.invoke<bool>('config', 'delete', {'section': section, 'key': key});
}
