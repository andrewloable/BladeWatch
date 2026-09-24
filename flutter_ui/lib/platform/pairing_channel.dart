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

  static Future<Map<String, dynamic>> _map(Future<Object?> call) async =>
      Map<String, dynamic>.from(await call as Map);
}
