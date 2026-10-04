import 'platform_channel.dart';

/// A pairing QR the daemon just minted (BladeWatch-rdtj.7).
class PairingOffer {
  /// The QR text. A single-use code plus public routing data -- never a credential, never logged.
  final String payload;
  final DateTime expiresAt;

  /// The owner's LAN-access opt-in at the moment of minting.
  final bool lanEnabled;

  const PairingOffer({required this.payload, required this.expiresAt, required this.lanEnabled});
}

/// A companion app that has redeemed a pairing code.
class PairedDevice {
  final String id;
  final String name;
  final DateTime pairedAt;

  const PairedDevice({required this.id, required this.name, required this.pairedAt});
}

/// A device without a camera asking to pair over Wi-Fi (BladeWatch 1.4.1.2), waiting for the owner
/// to compare [number] with the one the device shows.
class WifiPairingRequest {
  final String id;
  final String name;
  final String number;

  const WifiPairingRequest({required this.id, required this.name, required this.number});
}

/// Dart side of the `pairing.*` channel group (BladeWatch-rdtj.7): the in-car "Pair a device"
/// flow. Thin wrappers over the Kotlin `PairingControl`, which thin-wraps TcpCommandServer's
/// `pairingMint` / `pairingList` / `pairingRevoke` / `lanAccessSet` -- commands only the in-car
/// UI can reach, so pairing and un-pairing need someone at the car. Errors propagate unchanged.
class PairingChannel {
  final PlatformChannel _channel;

  const PairingChannel(this._channel);

  Future<PairingOffer> mint() async {
    final r = await _map(_channel.invoke('pairing', 'mint'));
    return PairingOffer(
      payload: r['payload'] as String,
      expiresAt: DateTime.fromMillisecondsSinceEpoch((r['expiresAt'] as num).toInt()),
      lanEnabled: r['lanEnabled'] as bool? ?? false,
    );
  }

  Future<List<PairedDevice>> list() async {
    final r = await _map(_channel.invoke('pairing', 'list'));
    return [
      for (final raw in (r['companions'] as List? ?? const []))
        PairedDevice(
          id: (raw as Map)['id'] as String,
          name: raw['name'] as String? ?? '',
          pairedAt: DateTime.fromMillisecondsSinceEpoch((raw['pairedAt'] as num? ?? 0).toInt()),
        ),
    ];
  }

  Future<void> revoke(String id) => _channel.invoke('pairing', 'revoke', {'id': id});

  /// Returns the setting now in force.
  Future<bool> setLanAccess(bool enabled) async {
    final r = await _map(_channel.invoke('pairing', 'setLanAccess', {'enabled': enabled}));
    return r['enabled'] as bool? ?? enabled;
  }

  /// Opens Wi-Fi pairing, keeps it open, or shuts it. Returns the LAN-access opt-in it needs.
  Future<bool> wifiWindow(bool open) async {
    final r = await _map(_channel.invoke('pairing', 'wifiWindow', {'open': open}));
    return r['lanEnabled'] as bool? ?? false;
  }

  Future<WifiPairingRequest?> wifiPending() async {
    final raw = (await _map(_channel.invoke('pairing', 'wifiPending')))['request'];
    if (raw is! Map) return null;
    return WifiPairingRequest(id: raw['id'] as String, name: raw['name'] as String? ?? '', number: raw['number'] as String);
  }

  Future<void> wifiDecide(String id, bool accept) => _channel.invoke('pairing', 'wifiDecide', {'id': id, 'accept': accept});

  static Future<Map<String, dynamic>> _map(Future<Object?> call) async =>
      Map<String, dynamic>.from(await call as Map);
}
