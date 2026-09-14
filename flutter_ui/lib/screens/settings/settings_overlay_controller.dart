import 'package:flutter/foundation.dart';
import '../../shell/disposed_safe_notifier.dart';

/// Ground truth: `SettingsOverlayFragment.kt`. Backed by
/// `UnifiedConfigManager`'s `statusOverlay` section — a **public**, non-secret
/// config section the daemon and app UID both read directly from a
/// world-rw file. No platform channel exposes generic
/// `UnifiedConfigManager` section read/write today (`ConfigChannel`/
/// `SecretConfigChannel` only cover the daemon-owned *secret* store) — filed
/// as a follow-up (see this screen's task notes). [loadSettings]/[persist]
/// are injected so this controller (and its tests) don't depend on that
/// follow-up landing; the defaults mirror native's own fallback values
/// (`optBoolean(key, true)`) and quietly no-op on write, exactly the same
/// shape as `DashboardController.tunnelUrlSource`.
class SettingsOverlayController extends ChangeNotifier with DisposedSafeNotifier {
  SettingsOverlayController({
    Future<({bool cameraVisible, bool tripVisible})> Function()? loadSettings,
    Future<void> Function(String key, bool value)? persist,
  })  : _loadSettings = loadSettings ?? _defaultLoad,
        _persist = persist ?? _defaultPersist;

  static Future<({bool cameraVisible, bool tripVisible})> _defaultLoad() async => (cameraVisible: true, tripVisible: true);
  static Future<void> _defaultPersist(String key, bool value) async {}

  final Future<({bool cameraVisible, bool tripVisible})> Function() _loadSettings;
  final Future<void> Function(String key, bool value) _persist;

  bool _loading = true;
  bool get loading => _loading;

  bool _cameraVisible = true;
  bool get cameraVisible => _cameraVisible;

  bool _tripVisible = true;
  bool get tripVisible => _tripVisible;

  Future<void> load() async {
    try {
      final settings = await _loadSettings();
      _cameraVisible = settings.cameraVisible;
      _tripVisible = settings.tripVisible;
    } catch (_) {
      _cameraVisible = true;
      _tripVisible = true;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> setCameraVisible(bool value) async {
    final previous = _cameraVisible;
    _cameraVisible = value;
    notifyListeners();
    if (!await _tryPersist('cameraVisible', value)) {
      _cameraVisible = previous;
      notifyListeners();
    }
  }

  Future<void> setTripVisible(bool value) async {
    final previous = _tripVisible;
    _tripVisible = value;
    notifyListeners();
    if (!await _tryPersist('tripVisible', value)) {
      _tripVisible = previous;
      notifyListeners();
    }
  }

  /// The switch moves first (so it feels instant) but SNAPS BACK if the write
  /// did not land. Native never needed this — it wrote the config file in
  /// process — but this port writes it over IPC to the daemon, which can be
  /// down. Leaving the switch in its new position after a failed write would
  /// show a setting that silently reverts on the next app start.
  Future<bool> _tryPersist(String key, bool value) async {
    try {
      await _persist(key, value);
      return true;
    } catch (_) {
      return false;
    }
  }
}
