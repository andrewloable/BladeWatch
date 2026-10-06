import 'package:flutter/foundation.dart';

import '../../shell/disposed_safe_notifier.dart';

/// Why the relay pane is showing an error line.
enum RelayKeyError {
  /// What was typed is not a 12-digit relay key.
  invalid,

  /// The daemon did not take the write -- it may be down. Nothing changed.
  saveFailed,
}

/// The owner relay (BladeWatch-a7mu): lets the car be reached from mobile data while it is
/// online through its SIM, through a relay the owner runs. Off by default.
///
/// Backed by the daemon's SECRET store, section [section], over `ConfigChannel`'s
/// secret_get/secret_put/secret_delete -- never the public config. pear_daemon reads the
/// section on its 30 s sweep and applies it, so nothing here restarts anything. The key
/// itself is held here only between Save and the write: afterwards this controller keeps
/// just its last four digits, for the masked display.
///
/// [read]/[write]/[delete] are the section-bound secret calls, injected so tests need no
/// platform channel. [write] stores strings only, so [enabledKey] holds "true"/"false".
class SettingsRelayController extends ChangeNotifier with DisposedSafeNotifier {
  static const section = 'pear_relay';
  static const enabledKey = 'enabled';
  static const keyKey = 'key';

  SettingsRelayController({required this._read, required this._write, required this._delete});

  final Future<String?> Function(String key) _read;
  final Future<bool> Function(String key, String value) _write;
  final Future<bool> Function(String key) _delete;

  bool _loading = true;
  bool get loading => _loading;

  bool _enabled = false;
  bool get enabled => _enabled;

  String? _savedLastGroup;

  /// Whether a relay key is stored on the car.
  bool get hasKey => _savedLastGroup != null;

  /// The stored key with all but its last group hidden, e.g. ••••-••••-5562; null if none.
  String? get maskedKey => _savedLastGroup == null ? null : '••••-••••-$_savedLastGroup';

  bool _editing = false;

  /// Whether the key field is showing: no key stored yet, or the owner chose Change.
  bool get showKeyField => _editing || !hasKey;

  bool _saving = false;
  bool get saving => _saving;

  RelayKeyError? _error;
  RelayKeyError? get error => _error;

  /// [input] as its bare 12 digits, or null if it is not a relay key. Spaces and dashes are
  /// ignored; only ASCII digits count. The relay and pear-end apply the same rule.
  static String? normalize(String input) {
    final digits = input.replaceAll(RegExp(r'[\s-]'), '');
    return RegExp(r'^[0-9]{12}$').hasMatch(digits) ? digits : null;
  }

  Future<void> load() async {
    try {
      _enabled = await _read(enabledKey) == 'true';
      final stored = normalize(await _read(keyKey) ?? '');
      _savedLastGroup = stored?.substring(8);
    } catch (_) {
      _enabled = false;
      _savedLastGroup = null;
    }
    _loading = false;
    notifyListeners();
  }

  /// The switch moves first and snaps back if the daemon did not take the write, like
  /// `SettingsOverlayController`: a switch left on after a failed write would show a relay
  /// that is not in use.
  Future<void> setEnabled(bool value) async {
    final previous = _enabled;
    _enabled = value;
    _error = null;
    notifyListeners();
    if (!await _tryWrite(enabledKey, value ? 'true' : 'false')) {
      _enabled = previous;
      _error = RelayKeyError.saveFailed;
      notifyListeners();
    }
  }

  void startEditing() {
    _editing = true;
    _error = null;
    notifyListeners();
  }

  void cancelEditing() {
    _editing = false;
    _error = null;
    notifyListeners();
  }

  /// Stores [input] if it is a relay key. Returns whether it was stored.
  Future<bool> saveKey(String input) async {
    final digits = normalize(input);
    if (digits == null) {
      _error = RelayKeyError.invalid;
      notifyListeners();
      return false;
    }
    _saving = true;
    _error = null;
    notifyListeners();
    final ok = await _tryWrite(keyKey, digits);
    _saving = false;
    if (ok) {
      _savedLastGroup = digits.substring(8);
      _editing = false;
    } else {
      _error = RelayKeyError.saveFailed;
    }
    notifyListeners();
    return ok;
  }

  /// Deletes the stored key and turns relay access off.
  Future<void> removeKey() async {
    final deleted = await _tryDelete(keyKey);
    final switchedOff = await _tryWrite(enabledKey, 'false');
    if (deleted) _savedLastGroup = null;
    if (switchedOff) _enabled = false;
    _editing = false;
    _error = deleted && switchedOff ? null : RelayKeyError.saveFailed;
    notifyListeners();
  }

  Future<bool> _tryWrite(String key, String value) async {
    try {
      return await _write(key, value);
    } catch (_) {
      return false;
    }
  }

  Future<bool> _tryDelete(String key) async {
    try {
      return await _delete(key);
    } catch (_) {
      return false;
    }
  }
}
