/// The 3 daemons the Startup screen watches — ground truth: `coreDaemons` in
/// `app/src/main/java/com/loabletech/bladewatch/ui/fragment/StartupFragment.kt`.
/// `DaemonType` has a 4th value, `PEAR_PEER`, deliberately excluded here —
/// do not add it to this screen.
enum CoreDaemon { camera, sentry, accSentry }

/// Matches the `daemon.processStatus` response's key names 1:1 (see
/// `TcpCommandServer.java`'s `daemonStatus` command and `DaemonType.name` in
/// `app/src/main/java/com/loabletech/bladewatch/ui/model/DaemonType.kt`).
extension CoreDaemonProcessKey on CoreDaemon {
  String get processStatusKey => switch (this) {
        CoreDaemon.camera => 'CAMERA_DAEMON',
        CoreDaemon.sentry => 'SENTRY_DAEMON',
        CoreDaemon.accSentry => 'ACC_SENTRY_DAEMON',
      };
}

/// Only two states are reachable from a binary process-liveness check
/// (`daemon.processStatus` reports running/not-running, nothing else) —
/// unlike the native `DaemonStatus` enum's STARTING/ERROR, which come from
/// `DaemonsViewModel`'s own optimistic client-side tracking around an
/// ADB-issued start command the Flutter APK never issues. See
/// `StartupController`'s doc comment for the full reasoning.
enum DaemonRowStatus { waiting, ready }

class DaemonRowState {
  final DaemonRowStatus status;

  /// Time since the screen opened. Keeps ticking up while [status] is
  /// [DaemonRowStatus.waiting]; frozen at the moment [status] became
  /// [DaemonRowStatus.ready] (mirrors the native elapsed-label behaviour in
  /// `StartupFragment.updateDaemonRow`).
  final Duration elapsed;

  const DaemonRowState({required this.status, required this.elapsed});
}

/// Overall header phase — ground truth: the `tvStartupHeader.text = when {...}`
/// block in `StartupFragment.tickerRunnable`. [starting] is reached when at
/// least one (but not all) core daemons are observed running: a real signal
/// derived from actual process state, not a fabricated timer-based guess —
/// see `StartupController`'s doc comment.
enum StartupPhase { preparing, starting, verifying, ready }
