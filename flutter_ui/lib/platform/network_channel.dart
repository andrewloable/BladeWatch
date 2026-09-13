import 'platform_channel.dart';

enum NetworkType { wifi, mobile, ethernet, offline }

class CurrentNetwork {
  final NetworkType type;

  /// The connected Wi-Fi SSID, quotes stripped — only set when [type] is
  /// [NetworkType.wifi].
  final String? ssid;

  const CurrentNetwork(this.type, this.ssid);
}

/// Dart side of the `network.*` channel group (BladeWatch-yz1e.4) — this
/// APK's own on-device Wi-Fi/connectivity probe (native's equivalent:
/// `DiagnosticsFragment.kt`'s `computeNetworkTopLine()`). All the actual
/// `ConnectivityManager`/`WifiManager` calls happen in Kotlin
/// (`flutter_ui/android/app/src/main/kotlin/net/bladewatch/bladewatch_ui/network/NetworkInfoChannel.kt`);
/// this class only carries the call and types the result.
class NetworkChannel {
  final PlatformChannel _channel;

  const NetworkChannel(this._channel);

  Future<CurrentNetwork> currentNetwork() async {
    final result = await _channel.invoke<Map<Object?, Object?>>('network', 'current');
    final type = switch (result['type']) {
      'wifi' => NetworkType.wifi,
      'mobile' => NetworkType.mobile,
      'ethernet' => NetworkType.ethernet,
      _ => NetworkType.offline,
    };
    return CurrentNetwork(type, result['ssid'] as String?);
  }
}
