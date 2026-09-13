import 'dart:typed_data';

import 'platform_channel.dart';

/// Dart side of the `adb.*` channel group (BladeWatch-yz1e.4) — carries the
/// ADB Console's key material across the platform channel. All the actual
/// key generation/storage/signing happens in Kotlin
/// (`flutter_ui/android/app/src/main/kotlin/net/bladewatch/bladewatch_ui/adb/AdbKeyChannel.kt`,
/// same class name, different layer); this class only carries the calls.
/// The ADB wire protocol itself (`flutter_ui/lib/adb/adb_client.dart`) is
/// pure Dart and treats this as its only source of key material.
class AdbKeyChannel {
  final PlatformChannel _channel;

  const AdbKeyChannel(this._channel);

  /// The ADB-formatted public key blob (`"<base64> <label>"`), sent in an
  /// AUTH(RSAPUBLICKEY) packet. Generates a key pair on first call.
  Future<String> getPublicKey() => _channel.invoke<String>('adb', 'getPublicKey');

  /// Signs a 20-byte ADB AUTH token, for an AUTH(SIGNATURE) packet.
  Future<Uint8List> sign(Uint8List token) =>
      _channel.invoke<Uint8List>('adb', 'sign', {'token': token});
}
