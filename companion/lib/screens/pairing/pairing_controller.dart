import 'dart:async';

import 'package:bladewatch_rpc/pairing/pairing_payload.dart';
import 'package:flutter/foundation.dart';

import '../../car/car_session.dart';
import '../../car/car_store.dart';
import '../../transport/car_auth.dart';
import '../../transport/wifi_pairing.dart';

/// [searching] and [comparing] are Wi-Fi pairing's (BladeWatch 1.4.1.2): looking for a car with
/// pairing open, then showing [PairingController.number] until the owner answers in the car.
enum PairingStep { idle, searching, comparing, connecting, redeeming, failed }

/// Pairing, the companion's replacement for the web login (BladeWatch-rdtj.7/.11): decode the
/// in-car QR, find the car with what it carries (LAN probe, else Pear), redeem its single-use
/// code there, and hand back the paired car. [error] is a catalog key.
class PairingController extends ChangeNotifier {
  PairingController({
    required this.openSession,
    Future<CompanionCredential> Function(Uri baseUrl, String code, String name)? redeem,
    DateTime Function()? now,
    this.findTimeout = const Duration(seconds: 120),
    Future<PairingCar?> Function()? findWifiCar,
    WifiPairing Function(PairingCar car)? openWifi,
    this.searchTimeout = const Duration(seconds: 60),
    this.pollInterval = const Duration(seconds: 2),
  })  : _redeem = redeem ?? ((url, code, name) => CarAuth(url).redeem(code, name: name)),
        _now = now ?? DateTime.now,
        _findWifiCar = findWifiCar ?? WifiPairing.sweep(),
        _openWifi = openWifi ?? WifiPairing.new;

  final Future<CarSession> Function(PairedCar car) openSession;
  final Future<CompanionCredential> Function(Uri baseUrl, String code, String name) _redeem;
  final DateTime Function() _now;
  final Future<PairingCar?> Function() _findWifiCar;
  final WifiPairing Function(PairingCar car) _openWifi;

  /// LAN answers in a second; Pear's lookup is allowed its documented 90 s and a margin.
  final Duration findTimeout;

  /// How long Wi-Fi pairing looks for a car with "Pair a device" open, and how often it asks
  /// whether the owner has answered.
  final Duration searchTimeout;
  final Duration pollInterval;

  PairingStep step = PairingStep.idle;
  String? error;

  /// The six digits to compare with the car's, while [step] is [PairingStep.comparing].
  String? number;
  bool _cancelled = false;

  bool get busy => step != PairingStep.idle && step != PairingStep.failed;

  /// Pairing without a camera (BladeWatch 1.4.1.2): find the car on this Wi-Fi, show the number
  /// the owner compares in the car, and once they confirm, redeem the payload the car hands over
  /// exactly as a scanned QR. Offered on TVs and desktops only; phones scan the QR.
  Future<PairedCar?> pairOverWifi(String deviceName) async {
    _cancelled = false;
    _set(PairingStep.searching);
    final until = _now().add(searchTimeout);
    PairingCar? car;
    do {
      car = await _findWifiCar();
    } while (car == null && !_cancelled && _now().isBefore(until));
    if (_cancelled) return _stop();
    if (car == null) return _fail('companion.wifi_not_found');
    final wifi = _openWifi(car);
    final String payload;
    try {
      number = await wifi.start(deviceName.trim());
      _set(PairingStep.comparing);
      String? accepted;
      while ((accepted = await wifi.result()) == null) {
        if (_cancelled) return _stop();
        await Future<void>.delayed(pollInterval);
      }
      payload = accepted!;
      // The payload must name the certificate this flow talked to -- the one the number covers.
      if (PairingPayload.decode(payload).tlsFingerprint != wifi.fingerprint) return _fail('companion.wifi_refused');
    } on WifiPairingRefused catch (e) {
      return _fail(e.code == 'wifi_pairing_closed' ? 'companion.wifi_busy' : 'companion.wifi_refused');
    } catch (_) {
      return _fail('errors.generic');
    } finally {
      wifi.close();
    }
    number = null;
    return pair(payload, deviceName, lanHint: car.address.address);
  }

  /// Stops a Wi-Fi pairing that is searching or waiting for the owner.
  void cancel() => _cancelled = true;

  PairedCar? _stop() {
    number = null;
    _set(PairingStep.idle);
    return null;
  }

  /// The paired car, or null with [error] set. [lanHint] is the car's address when it is already
  /// known -- a Wi-Fi pairing just talked to it -- so the session probes it before any sweep.
  Future<PairedCar?> pair(String qrText, String deviceName, {String? lanHint}) async {
    final PairingPayload qr;
    try {
      qr = PairingPayload.decode(qrText);
    } on FormatException {
      return _fail('companion.pair_bad_code');
    }
    if (qr.isExpiredAt(_now())) return _fail('companion.pair_expired');

    _set(PairingStep.connecting);
    // No credential yet: this session only exists to reach the car and redeem the code.
    final session = await openSession(PairedCar.fromPairing(qr, const CompanionCredential('', '')).withLanHint(lanHint));
    try {
      if (!await _connected(session)) return _fail('companion.pair_not_found');
      _set(PairingStep.redeeming);
      final credential = await _redeem(session.baseUrl, qr.code, deviceName.trim());
      _set(PairingStep.idle);
      return PairedCar.fromPairing(qr, credential).withLanHint(lanHint);
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
    number = null;
    _set(PairingStep.failed);
    return null;
  }

  void _set(PairingStep s) {
    step = s;
    if (s != PairingStep.failed) error = null;
    notifyListeners();
  }
}
