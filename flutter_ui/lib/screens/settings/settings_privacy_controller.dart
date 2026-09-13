import 'package:flutter/foundation.dart';

import '../../gen/bladewatch/v1/storage.pb.dart';
import '../../rpc/services/storage_service_client.dart';

/// Ground truth: `SettingsPrivacyFragment.kt`. The reset-data action opens a
/// dialog (BladeWatch-yz1e.11's job; this screen only needs a callback to
/// show it). Storage totals come from `StorageService.GetStorageSettings`
/// (the same RPC the Recording settings' Storage tab uses) rather than
/// native's local `RecordingScanner` walk — no filesystem access from the
/// Flutter APK. The two logging toggles are backed by
/// `UnifiedConfigManager`'s `developerOptions` section — see
/// `SettingsOverlayController`'s doc comment for why [loadLoggingSettings]/
/// [persistLogging] are injected (no generic public-config IPC exists yet).
class SettingsPrivacyController extends ChangeNotifier {
  SettingsPrivacyController({
    required StorageServiceClient storageService,
    Future<({bool timingLogsEnabled, bool debugLogsEnabled})> Function()? loadLoggingSettings,
    Future<void> Function(String key, bool value)? persistLogging,
  })  : _storageService = storageService, // ignore: prefer_initializing_formals
        _loadLoggingSettings = loadLoggingSettings ?? _defaultLoadLogging,
        _persistLogging = persistLogging ?? _defaultPersistLogging;

  static Future<({bool timingLogsEnabled, bool debugLogsEnabled})> _defaultLoadLogging() async =>
      (timingLogsEnabled: true, debugLogsEnabled: false);
  static Future<void> _defaultPersistLogging(String key, bool value) async {}

  final StorageServiceClient _storageService;
  final Future<({bool timingLogsEnabled, bool debugLogsEnabled})> Function() _loadLoggingSettings;
  final Future<void> Function(String key, bool value) _persistLogging;

  bool _loading = true;
  bool get loading => _loading;

  bool _storageAvailable = false;
  bool get storageAvailable => _storageAvailable;

  int _clipCount = 0;
  int get clipCount => _clipCount;

  String? _formattedSize;
  String? get formattedSize => _formattedSize;

  bool _timingLogsEnabled = true;
  bool get timingLogsEnabled => _timingLogsEnabled;

  bool _debugLogsEnabled = false;
  bool get debugLogsEnabled => _debugLogsEnabled;

  Future<void> load() async {
    try {
      final resp = await _storageService.getStorageSettings(GetStorageSettingsRequest());
      _clipCount = resp.recordingsCount;
      _formattedSize = _formatSize(resp.recordingsSizeBytes.toInt());
      _storageAvailable = true;
    } catch (_) {
      _clipCount = 0;
      _formattedSize = null;
      _storageAvailable = false;
    }

    try {
      final logging = await _loadLoggingSettings();
      _timingLogsEnabled = logging.timingLogsEnabled;
      _debugLogsEnabled = logging.debugLogsEnabled;
    } catch (_) {
      _timingLogsEnabled = true;
      _debugLogsEnabled = false;
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> setTimingLogsEnabled(bool value) async {
    _timingLogsEnabled = value;
    notifyListeners();
    await _persistLogging('timingLogsEnabled', value);
  }

  Future<void> setDebugLogsEnabled(bool value) async {
    _debugLogsEnabled = value;
    notifyListeners();
    await _persistLogging('debugLogsEnabled', value);
  }

  /// Compact "B / KB / MB / GB / TB" formatter — ports
  /// `SettingsPrivacyFragment.formatSize()` exactly (same thresholds and
  /// decimal precision), intentionally locale-agnostic for the unit suffix.
  static String _formatSize(int bytes) {
    if (bytes < 0) return '';
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024.0;
    if (kb < 1024.0) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024.0;
    if (mb < 1024.0) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024.0;
    if (gb < 1024.0) return '${gb.toStringAsFixed(2)} GB';
    final tb = gb / 1024.0;
    return '${tb.toStringAsFixed(2)} TB';
  }
}
