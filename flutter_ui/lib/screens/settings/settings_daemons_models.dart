/// The 4 daemon processes `daemon.processStatus` reports on (BladeWatch-1xt9).
/// [nativeKey] is the exact key that IPC response uses.
enum DaemonKind {
  camera('CAMERA_DAEMON'),
  sentry('SENTRY_DAEMON'),
  accSentry('ACC_SENTRY_DAEMON'),
  zrokTunnel('ZROK_TUNNEL');

  final String nativeKey;
  const DaemonKind(this.nativeKey);
}

/// Ground truth: `DaemonAdapter.kt`'s per-row bind logic, reduced to what
/// `daemon.processStatus` can actually report (a flat running/not-running
/// bool) — uptime and subprocess lists come from native's ADB-based
/// `DaemonsViewModel`, which has no IPC equivalent (same simplification as
/// the Dashboard's daemons-summary tile).
class DaemonRowState {
  final DaemonKind kind;
  final bool running;

  const DaemonRowState({required this.kind, required this.running});
}
