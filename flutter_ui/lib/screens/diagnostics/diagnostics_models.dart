/// The Network health tile's bottom-line tunnel status — ported from
/// `DiagnosticsFragment.kt`'s `computeTunnelState()`.
enum TunnelState { online, connecting, offline }

/// The Camera health tile's status — ported from `updateCameraTile()`.
enum CameraTileStatus { offline, probing, active }

/// The Battery health tile's dot-color classification — ported from
/// `refreshBatteryTile()`'s `dotRes` thresholds. Native also has a
/// `finalSoh < 50.0` ("degraded"/red-dot) branch, but it's dead code: a
/// [BatteryHealthLevel] is only ever computed for an SOH reading native (and
/// this port) already required to be in the 60-110 range (`SohEstimator`'s
/// accept band — BYD packs read up to ~104% new), so that branch's condition
/// can never be true. Not ported — see BladeWatch-yz1e.4's task notes.
enum BatteryHealthLevel { pending, good, moderate, neutral }

/// The public (non-secret) "camera" config section
/// (`UnifiedConfigManager`'s `probedCameraId`/`manualOverride`) has no IPC
/// path yet (BladeWatch-hygs). Defaults mirror native's own
/// fallback-on-read-failure values, which happen to also be an honest
/// "nothing probed yet" state.
class CameraProbeConfig {
  final int probedCameraId;
  final bool manualOverride;

  const CameraProbeConfig({this.probedCameraId = -1, this.manualOverride = false});
}
