import 'package:flutter/foundation.dart';

import '../../platform/pairing_channel.dart';
import '../../shell/disposed_safe_notifier.dart';

/// State for the in-car "Pair a device" dialog (BladeWatch-rdtj.7): the current single-use QR,
/// the LAN-access opt-in, and the devices already paired.
///
/// The QR is only ever minted on request -- opening the dialog is the explicit action. A
/// permanently visible pairing code would be a permanently visible way in.
///
/// DisposedSafeNotifier because the dialog disposes this when it closes, and a mint or revoke
/// can still be in flight then.
class PairingController extends ChangeNotifier with DisposedSafeNotifier {
  final PairingChannel _channel;
  final DateTime Function() _now;

  PairingOffer? offer;
  bool lanEnabled = false;
  List<PairedDevice> devices = const [];

  /// Minting the QR failed; the code area shows a retry. Kept apart from [actionFailed] so a
  /// device list that loads fine cannot hide a code that never came.
  bool mintFailed = false;

  /// The last list / remove / LAN change failed; the dialog says so rather than doing nothing.
  bool actionFailed = false;

  PairingController(this._channel, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  Future<void> start() => Future.wait([newCode(), refreshDevices()]);

  Future<void> newCode() async {
    try {
      offer = await _channel.mint();
      lanEnabled = offer!.lanEnabled;
      mintFailed = false;
    } catch (_) {
      mintFailed = true;
    }
    notifyListeners();
  }

  Future<void> refreshDevices() => _action(() async => devices = await _channel.list());

  Future<void> setLanAccess(bool enabled) => _action(() async => lanEnabled = await _channel.setLanAccess(enabled));

  Future<void> remove(String id) => _action(() async {
        await _channel.revoke(id);
        devices = await _channel.list();
      });

  /// Time left on the current code; zero once it has expired (or before one exists).
  Duration get remaining {
    final expiresAt = offer?.expiresAt;
    if (expiresAt == null) return Duration.zero;
    final left = expiresAt.difference(_now());
    return left.isNegative ? Duration.zero : left;
  }

  bool get expired => offer != null && remaining == Duration.zero;

  Future<void> _action(Future<void> Function() call) async {
    try {
      await call();
      actionFailed = false;
    } catch (_) {
      actionFailed = true;
    }
    notifyListeners();
  }
}
