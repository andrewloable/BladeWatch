import 'package:flutter/foundation.dart';

import '../../platform/config_channel.dart';
import '../../platform/daemon_channel.dart';
import 'settings_daemons_models.dart';

/// Ground truth: `DaemonsFragment.kt` + `DaemonAdapter.kt`. Per-daemon
/// start/stop has no IPC path today — `daemon.start`/`daemon.stop`
/// (`DaemonControl.kt`) only control camera *recording* within the already-
/// running camera daemon, not daemon *process* lifecycle (launching/killing
/// the `app_process` daemons themselves is exactly the ADB-shell-execution
/// class of operation Epic 1's IPC-only rule walls off). [setDaemonEnabled]
/// is injected — same shape as `DashboardController.tunnelUrlSource` — so
/// this screen is fully buildable/testable now; its default always reports
/// "not supported" until a follow-up adds a narrow, enum-constrained
/// `daemon.startType`/`stopType` IPC command mirroring BladeWatch-1xt9's
/// `pgrep`-based design (see this screen's task notes).
///
/// Debug-only log download (`DaemonsFragment.onDownloadLogClicked`) is
/// deliberately NOT ported — it shells out via ADB and shares a file via
/// `FileProvider`, a developer convenience gated to `BuildConfig.DEBUG`
/// builds, not a release end-user feature.
class SettingsDaemonsController extends ChangeNotifier {
  SettingsDaemonsController({
    required DaemonChannel daemonChannel,
    required ConfigChannel configChannel,
    Future<bool> Function(DaemonKind kind, bool enabled)? setDaemonEnabled,
  })  : _daemonChannel = daemonChannel, // ignore: prefer_initializing_formals
        _configChannel = configChannel, // ignore: prefer_initializing_formals
        _setDaemonEnabled = setDaemonEnabled ?? _unsupported;

  static Future<bool> _unsupported(DaemonKind kind, bool enabled) async => false;
  static const String _zrokSection = 'zrok';
  static const String _zrokTokenKey = 'enableToken';

  final DaemonChannel _daemonChannel;
  final ConfigChannel _configChannel;
  final Future<bool> Function(DaemonKind kind, bool enabled) _setDaemonEnabled;

  bool _loading = true;
  bool get loading => _loading;

  List<DaemonRowState> _rows = const [];
  List<DaemonRowState> get rows => _rows;

  Future<void> load() async {
    try {
      final statuses = await _daemonChannel.processStatus();
      _rows = DaemonKind.values.map((k) => DaemonRowState(kind: k, running: statuses[k.nativeKey] ?? false)).toList();
    } catch (_) {
      _rows = DaemonKind.values.map((k) => DaemonRowState(kind: k, running: false)).toList();
    }
    _loading = false;
    notifyListeners();
  }

  /// Returns true on success (and refreshes [rows] from the daemon so the
  /// switch reflects reality rather than an optimistic guess); false if
  /// unsupported or the daemon rejected it — the row is left unchanged.
  Future<bool> toggle(DaemonKind kind, bool enabled) async {
    final ok = await _setDaemonEnabled(kind, enabled);
    if (ok) await load();
    return ok;
  }

  Future<String?> getZrokToken() => _configChannel.get(_zrokSection, _zrokTokenKey);

  Future<bool> saveZrokToken(String token) => _configChannel.put(_zrokSection, _zrokTokenKey, token);

  Future<bool> deleteZrokToken() => _configChannel.delete(_zrokSection, _zrokTokenKey);

  /// Ground truth: `DaemonsFragment.resetZrokEnvironment()`. Simplified:
  /// native also calls `ZrokController.disableEnvironment()`, which removes
  /// zrok's own local environment files via shell — unreachable from the
  /// Flutter APK, so this stops the tunnel (when a start/stop capability is
  /// available) and deletes the saved token, which is the part that
  /// actually matters to the user (re-enabling needs a fresh token either
  /// way). Returns true iff the token delete succeeds; stopping the tunnel
  /// is best-effort and doesn't gate the result.
  Future<bool> resetZrokEnvironment() async {
    final wasRunning = _rows.any((r) => r.kind == DaemonKind.zrokTunnel && r.running);
    if (wasRunning) {
      await _setDaemonEnabled(DaemonKind.zrokTunnel, false);
    }
    return deleteZrokToken();
  }
}
