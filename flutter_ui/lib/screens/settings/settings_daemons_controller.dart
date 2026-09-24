import 'package:flutter/foundation.dart';

import '../../platform/daemon_channel.dart';
import 'settings_daemons_models.dart';
import '../../shell/disposed_safe_notifier.dart';

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
class SettingsDaemonsController extends ChangeNotifier with DisposedSafeNotifier {
  /// No ConfigChannel any more: the only thing this screen ever read from the
  /// secret store was the tunnel's enable token, and a Tor onion service has no
  /// token. Other screens still use that channel; only this dependency is gone.
  SettingsDaemonsController({
    required DaemonChannel daemonChannel,
    Future<bool> Function(DaemonKind kind, bool enabled)? setDaemonEnabled,
  })  : _daemonChannel = daemonChannel, // ignore: prefer_initializing_formals
        _setDaemonEnabled = setDaemonEnabled ?? _unsupported;

  static Future<bool> _unsupported(DaemonKind kind, bool enabled) async => false;
  final DaemonChannel _daemonChannel;
  final Future<bool> Function(DaemonKind kind, bool enabled) _setDaemonEnabled;

  bool _loading = true;
  bool get loading => _loading;

  List<DaemonRowState> _rows = const [];
  List<DaemonRowState> get rows => _rows;

  /// BladeWatch-rdtj.17: what the Pear row shows beyond running/off -- whether the car can be
  /// found right now, and its connected devices. Read separately, so a failure here never
  /// blanks the other rows.
  PearStatus _pear = PearStatus.unknown;
  PearStatus get pear => _pear;

  Future<void> load() async {
    try {
      final status = await _daemonChannel.daemonStatus();
      _rows = DaemonKind.values
          .map((k) => DaemonRowState(
                kind: k,
                running: status.running[k.nativeKey] ?? false,
                enabled: status.enabled[k.nativeKey] ?? false,
              ))
          .toList();
    } catch (_) {
      _rows = DaemonKind.values.map((k) => DaemonRowState(kind: k, running: false)).toList();
    }
    try {
      _pear = await _daemonChannel.pearStatus();
    } catch (_) {
      _pear = PearStatus.unknown;
    }
    _loading = false;
    notifyListeners();
  }

  /// BladeWatch-dh1r: re-read while the screen is on screen.
  ///
  /// The screen used to call [load] once from initState and never again, so a tunnel
  /// that came up thirty seconds later was still shown as "Waiting" until the user
  /// navigated away and back. Unlike [load] this never flips [loading] back on, so a
  /// background refresh cannot flash a spinner over a screen the user is reading.
  Future<void> refresh() => load();

  /// Returns true on success (and refreshes [rows] from the daemon so the
  /// switch reflects reality rather than an optimistic guess); false if
  /// unsupported or the daemon rejected it — the row is left unchanged.
  /// Adapts [DaemonChannel]'s string-keyed API to this controller's
  /// [DaemonKind]-typed seam. A named factory rather than an inline closure at the
  /// call site so the DaemonKind -> nativeKey mapping lives somewhere a test can
  /// reach — main.dart's wiring closures are not exercised by any test.
  static Future<bool> Function(DaemonKind, bool) enabledSetterFor(DaemonChannel channel) =>
      (kind, enabled) => channel.setDaemonEnabled(kind.nativeKey, enabled);

  Future<bool> toggle(DaemonKind kind, bool enabled) async {
    // Answered here rather than by the daemon: the daemon refuses these too, but
    // there is no reason to spend an IPC round trip discovering a fact this process
    // already knows (BladeWatch-abcx, see DaemonKind.canToggle).
    if (!kind.canToggle) return false;
    final ok = await _setDaemonEnabled(kind, enabled);
    if (!ok) return false;

    // BladeWatch-dh1r: hold the new intent locally before re-reading.
    //
    // Enabling only RECORDS intent — the daemon's health check launches on its next
    // cycle and tor then needs up to a minute to bootstrap. load() runs a fraction of a
    // second later and correctly reports running=false, so binding the switch to
    // liveness made it spring straight back to off. The user's natural second tap then
    // DISABLED the tunnel they had just enabled, because the disable path also kills the
    // process. Carrying the intent forward is what stops that.
    _rows = _rows
        .map((r) => r.kind == kind
            ? DaemonRowState(kind: r.kind, running: r.running, enabled: enabled)
            : r)
        .toList();
    notifyListeners();

    await load();
    return true;
  }

}
