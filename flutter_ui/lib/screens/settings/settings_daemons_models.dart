/// The 4 daemon processes `daemon.processStatus` reports on (BladeWatch-1xt9).
/// [nativeKey] is the exact key that IPC response uses.
enum DaemonKind {
  camera('CAMERA_DAEMON'),
  sentry('SENTRY_DAEMON'),
  accSentry('ACC_SENTRY_DAEMON'),
  torTunnel('TOR_TUNNEL');

  final String nativeKey;
  const DaemonKind(this.nativeKey);

  /// Whether this daemon can be started/stopped from this UI (BladeWatch-abcx).
  ///
  /// Only the Tor tunnel can, and the reasons are structural, not missing work:
  ///
  /// - **Camera** hosts the loopback IPC server this app talks to. Stopping it kills
  ///   the only channel that could start it again — this APK has no ADB.
  /// - **Surveillance / ACC Surveillance** are core daemons. `DaemonStartupManager`'s
  ///   health check relaunches them within 30s unless they are in an in-memory set that
  ///   lives in the OTHER APK's process, so a stop issued here would silently undo
  ///   itself. Showing a switch that reverts is worse than showing no switch.
  ///
  /// The daemon enforces the same list; this is what lets the UI say so up front
  /// instead of letting the user discover it by toggling.
  bool get canToggle => this == DaemonKind.torTunnel;
}

/// Ground truth: `DaemonAdapter.kt`'s per-row bind logic, reduced to what
/// `daemon.processStatus` can actually report (a flat running/not-running
/// bool) — uptime and subprocess lists come from native's ADB-based
/// `DaemonsViewModel`, which has no IPC equivalent (same simplification as
/// the Dashboard's daemons-summary tile).
class DaemonRowState {
  final DaemonKind kind;
  final bool running;

  /// BladeWatch-dh1r: what the USER asked for, which is not the same question as
  /// [running] and must drive the switch. Enabling only records intent — the daemon's
  /// health check launches on its next cycle and tor then needs up to a minute to
  /// bootstrap, so a switch bound to [running] springs back to off and invites a second
  /// tap that disables the tunnel again.
  ///
  /// Meaningful only where [DaemonKind.canToggle]; false elsewhere and unused there.
  final bool enabled;

  const DaemonRowState({
    required this.kind,
    required this.running,
    this.enabled = false,
  });

  /// True while the user has asked for this daemon but it is not up yet — the window
  /// the Settings row used to render as a plain "off".
  bool get pending => enabled && !running;
}
