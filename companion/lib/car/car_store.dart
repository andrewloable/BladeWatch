import 'dart:convert';
import 'dart:io';

import 'package:bladewatch_rpc/pairing/pairing_payload.dart';
import 'package:fixnum/fixnum.dart';

import '../transport/car_auth.dart';

/// The one car this companion is paired with, everything needed to find it, prove it is the
/// car, and log in. Built once from the pairing QR plus the credential its code earned.
class PairedCar {
  const PairedCar({
    required this.deviceId,
    required this.pearTopic,
    required this.tlsFingerprint,
    required this.probeKey,
    required this.credential,
    this.inboxCursor = Int64.ZERO,
  });

  factory PairedCar.fromPairing(PairingPayload qr, CompanionCredential credential) => PairedCar(
        deviceId: qr.deviceId,
        pearTopic: qr.pearTopic,
        tlsFingerprint: qr.tlsFingerprint,
        probeKey: qr.probeKey,
        credential: credential,
      );

  final String deviceId;
  final String pearTopic;
  final String tlsFingerprint;
  final String probeKey;
  final CompanionCredential credential;

  /// The last alert id collected from the car's inbox (BladeWatch-rdtj.14).
  final Int64 inboxCursor;

  PairedCar withCursor(Int64 cursor) => PairedCar(
        deviceId: deviceId,
        pearTopic: pearTopic,
        tlsFingerprint: tlsFingerprint,
        probeKey: probeKey,
        credential: credential,
        inboxCursor: cursor,
      );

  Map<String, Object?> toJson() => {
        'deviceId': deviceId,
        'pearTopic': pearTopic,
        'tlsFingerprint': tlsFingerprint,
        'probeKey': probeKey,
        'companionId': credential.companionId,
        'token': credential.token,
        'inboxCursor': inboxCursor.toString(),
      };

  static PairedCar fromJson(Map<String, Object?> j) => PairedCar(
        deviceId: j['deviceId'] as String,
        pearTopic: j['pearTopic'] as String,
        tlsFingerprint: j['tlsFingerprint'] as String,
        probeKey: j['probeKey'] as String,
        credential: CompanionCredential(j['companionId'] as String, j['token'] as String),
        inboxCursor: Int64.parseInt(j['inboxCursor'] as String? ?? '0'),
      );
}

/// What the companion remembers between launches: the paired car and a few preferences.
///
/// One JSON file in the app's private support directory, owner-only where the OS has POSIX
/// modes, replaced atomically. The companion token in it logs in as this device until the car
/// un-pairs it, so Android backup is off for this app (AndroidManifest allowBackup=false).
/// ponytail: a private file, not the OS keychain -- the app sandbox already isolates it on
/// phones; move the token to a keychain if desktop threat models ever need it.
class CarStore {
  CarStore(this.file);

  final File file;

  PairedCar? car;

  /// A language the owner picked, overriding the device's; null follows the device.
  String? language;

  /// Alert categories the owner muted in this app (the store-and-forward counterpart of the
  /// web's per-subscription mutes).
  Set<String> mutedCategories = {};

  Future<void> load() async {
    try {
      final j = jsonDecode(await file.readAsString()) as Map<String, Object?>;
      final c = j['car'];
      car = c is Map<String, Object?> ? PairedCar.fromJson(c) : null;
      language = j['language'] as String?;
      mutedCategories = {...?(j['muted'] as List?)?.cast<String>()};
    } catch (_) {
      // First launch, or an unreadable file: start unpaired rather than crash.
    }
  }

  Future<void> save() async {
    final tmp = File('${file.path}.tmp');
    await tmp.parent.create(recursive: true);
    await tmp.writeAsString('');
    // Desktops share the home directory with every process of the user; phones sandbox the app
    // (and iOS forbids spawning a process at all). Owner-only BEFORE the token is written.
    if (Platform.isMacOS || Platform.isLinux) await Process.run('chmod', ['600', tmp.path]);
    await tmp.writeAsString(jsonEncode({
      'car': car?.toJson(),
      'language': language,
      'muted': mutedCategories.toList()..sort(),
    }));
    await tmp.rename(file.path);
  }
}
