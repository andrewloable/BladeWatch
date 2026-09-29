import 'dart:async';

import 'package:bladewatch_rpc/pairing/pairing_payload.dart';
import 'package:flutter/foundation.dart';

import '../../car/car_session.dart';
import '../../car/car_store.dart';
import '../../transport/car_auth.dart';

enum PairingStep { idle, connecting, redeeming, failed }

/// Pairing, the companion's replacement for the web login (BladeWatch-rdtj.7/.11): decode the
/// in-car QR, find the car with what it carries (LAN probe, else Pear), redeem its single-use
/// code there, and hand back the paired car. [error] is a catalog key.
class PairingController extends ChangeNotifier {
  PairingController({
    required this.openSession,
    Future<CompanionCredential> Function(Uri baseUrl, String code, String name)? redeem,
    DateTime Function()? now,
    this.findTimeout = const Duration(seconds: 120),
  })  : _redeem = redeem ?? ((url, code, name) => CarAuth(url).redeem(code, name: name)),
        _now = now ?? DateTime.now;

  final Future<CarSession> Function(PairedCar car) openSession;
  final Future<CompanionCredential> Function(Uri baseUrl, String code, String name) _redeem;
  final DateTime Function() _now;

  /// LAN answers in a second; Pear's lookup is allowed its documented 90 s and a margin.
  final Duration findTimeout;

  PairingStep step = PairingStep.idle;
  String? error;

  bool get busy => step == PairingStep.connecting || step == PairingStep.redeeming;

  /// The paired car, or null with [error] set.
  Future<PairedCar?> pair(String qrText, String deviceName) async {
    final PairingPayload qr;
    try {
      qr = PairingPayload.decode(qrText);
    } on FormatException {
      return _fail('companion.pair_bad_code');
    }
    if (qr.isExpiredAt(_now())) return _fail('companion.pair_expired');

    _set(PairingStep.connecting);
    // No credential yet: this session only exists to reach the car and redeem the code.
    final session = await openSession(PairedCar.fromPairing(qr, const CompanionCredential('', '')));
    try {
      if (!await _connected(session)) return _fail('companion.pair_not_found');
      _set(PairingStep.redeeming);
      final credential = await _redeem(session.baseUrl, qr.code, deviceName.trim());
      _set(PairingStep.idle);
      return PairedCar.fromPairing(qr, credential);
    } on CarAuthRefused catch (e) {
      return _fail(e.code == 'pairing_code_refused' ? 'companion.pair_refused' : 'errors.generic');
    } catch (_) {
      return _fail('errors.generic');
    } finally {
      session.dispose();
    }
  }

  Future<bool> _connected(CarSession session) async {
    if (session.connected) return true;
    final done = Completer<bool>();
    void check() {
      if (session.connected && !done.isCompleted) done.complete(true);
    }

    session.addListener(check);
    try {
      return await done.future.timeout(findTimeout, onTimeout: () => false);
    } finally {
      session.removeListener(check);
    }
  }

  PairedCar? _fail(String key) {
    error = key;
    _set(PairingStep.failed);
    return null;
  }

  void _set(PairingStep s) {
    step = s;
    if (s != PairingStep.failed) error = null;
    notifyListeners();
  }
}
