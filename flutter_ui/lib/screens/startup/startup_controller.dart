import 'package:flutter/foundation.dart';

import '../../platform/daemon_channel.dart';
import 'startup_models.dart';
import '../../shell/disposed_safe_notifier.dart';

/// Pure-Dart port of `StartupFragment`'s behaviour (no Flutter imports).
///
/// **Why there is no `DaemonRowStatus.starting` driven by a start command:**
/// the native screen never issues a start command itself — it only observes
/// `DaemonsViewModel.daemonStates`, which `DaemonStartupManager` (running in
/// the *main* APK's process) drives via ADB on its own staggered timer. The
/// Flutter APK cannot launch daemons (Epic 1's IPC-only rule; ADB access is
/// out of scope for this whole refactor) and has no way to observe "is
/// starting" as a distinct signal from "not yet observed running" — a
/// process-liveness poll (`daemon.processStatus`) is binary. [StartupPhase]
/// approximates the native header's STARTING phase honestly instead: it
/// fires when *some but not all* core daemons are observed running, a real
/// signal from actual process state, not a fabricated timer guess.
///
/// Whether daemons actually start at all when the Flutter APK is launched
/// **without** the native app ever having run (so `DaemonStartupManager`
/// never started) is a real open question this task cannot verify — CODE
/// ONLY, no device. Noted for Phase 3 (`BladeWatch-imh6`) to check on a real
/// device; the "Continue anyway" escape hatch (120s) means the screen is
/// still usable either way.
class StartupController extends ChangeNotifier with DisposedSafeNotifier {
  StartupController({
    required DaemonChannel daemonChannel,
    DateTime Function() clock = DateTime.now,
    Duration continueAnywayDelay = const Duration(seconds: 120),
    Duration readyToNavigateDelay = const Duration(milliseconds: 1500),
    required Future<bool> Function() healthCheck,
  })  : _clock = clock,
        // ignore: prefer_initializing_formals
        _daemonChannel = daemonChannel,
        // ignore: prefer_initializing_formals
        _continueAnywayDelay = continueAnywayDelay,
        // ignore: prefer_initializing_formals
        _readyToNavigateDelay = readyToNavigateDelay,
        // ignore: prefer_initializing_formals
        _healthCheck = healthCheck,
        _openedAt = clock() {
    _rows = {for (final d in CoreDaemon.values) d: const DaemonRowState(status: DaemonRowStatus.waiting, elapsed: Duration.zero)};
  }

  final DaemonChannel _daemonChannel;
  final DateTime Function() _clock;
  final Duration _continueAnywayDelay;
  final Duration _readyToNavigateDelay;
  final Future<bool> Function() _healthCheck;
  final DateTime _openedAt;

  late Map<CoreDaemon, DaemonRowState> _rows;
  Map<CoreDaemon, DaemonRowState> get rows => Map.unmodifiable(_rows);

  StartupPhase _phase = StartupPhase.preparing;
  StartupPhase get phase => _phase;

  bool _showContinueButton = false;
  bool get showContinueButton => _showContinueButton;

  bool _navigateToDashboard = false;
  bool get navigateToDashboard => _navigateToDashboard;

  String? _channelErrorMessage;
  String? get channelErrorMessage => _channelErrorMessage;

  DateTime? _readyAt;

  /// Advances the screen by one poll. The widget layer drives this on a
  /// ~1s `Timer.periodic` (plain plumbing, not business logic — the timer
  /// itself lives in the widget, not here, so this method stays directly
  /// callable/testable with no fake-timer machinery needed).
  Future<void> tick() async {
    if (_navigateToDashboard) return; // mirrors StartupFragment's `navigated` guard

    final elapsedSinceOpen = _clock().difference(_openedAt);
    if (!_showContinueButton && elapsedSinceOpen >= _continueAnywayDelay) {
      _showContinueButton = true;
    }

    try {
      final statuses = await _daemonChannel.processStatus();
      _channelErrorMessage = null;
      for (final d in CoreDaemon.values) {
        final running = statuses[d.processStatusKey] ?? false;
        final current = _rows[d]!;
        if (running && current.status == DaemonRowStatus.waiting) {
          _rows[d] = DaemonRowState(status: DaemonRowStatus.ready, elapsed: elapsedSinceOpen);
        } else if (!running) {
          _rows[d] = DaemonRowState(status: DaemonRowStatus.waiting, elapsed: elapsedSinceOpen);
        }
        // running && already ready: elapsed stays frozen at its recorded value.
      }
      await _recomputePhase();
    } catch (e) {
      _channelErrorMessage = e.toString();
    }

    notifyListeners();
  }

  Future<void> _recomputePhase() async {
    final readyCount = _rows.values.where((r) => r.status == DaemonRowStatus.ready).length;

    if (readyCount < CoreDaemon.values.length) {
      _phase = readyCount == 0 ? StartupPhase.preparing : StartupPhase.starting;
      _readyAt = null;
      return;
    }

    if (_phase != StartupPhase.ready) {
      _phase = StartupPhase.verifying;
      if (await _healthCheck()) {
        _phase = StartupPhase.ready;
        _readyAt = _clock();
      }
      return;
    }

    // Already ready: decide whether readyToNavigateDelay has elapsed.
    if (_readyAt != null && _clock().difference(_readyAt!) >= _readyToNavigateDelay) {
      _navigateToDashboard = true;
    }
  }

  /// Wired to the "Continue anyway" / "Continue →" button — the native
  /// fragment reuses one button for both purposes; see its doc comment on
  /// `btnContinueAnyway`.
  void continueAnyway() {
    if (_navigateToDashboard) return;
    _navigateToDashboard = true;
    notifyListeners();
  }
}
