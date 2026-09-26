import 'package:bladewatch_rpc/rpc/services/vehicle_service_client.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/vehicle.pb.dart' show GetVehicleStateRequest;
import '../../platform/public_config_channel.dart';

/// The Network health tile's bottom-line remote-access status (the Pear peer, since tor's removal).
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

/// Reads the daemon's `camera` config section into a [CameraProbeConfig]
/// (BladeWatch-i2wv).
///
/// A class rather than a closure in `main.dart` so it is reachable from tests:
/// the composition root is not covered, and an adapter with a real branch in it
/// should not hide there.
class CameraProbeSource {
  final PublicConfigChannel _channel;

  const CameraProbeSource(this._channel);

  /// A failed read falls back to the default, which [DiagnosticsController]
  /// renders as "Probing…" — the same defensive fallthrough native's
  /// `updateCameraTile()` uses when its own config read throws.
  Future<CameraProbeConfig> read() async {
    final probe = await _channel.getCameraProbe();
    if (probe == null) return const CameraProbeConfig();
    return CameraProbeConfig(
      probedCameraId: probe.probedCameraId,
      manualOverride: probe.manualOverride,
    );
  }
}

/// Battery state of CHARGE for the Diagnostics tile (BladeWatch-1ovy).
///
/// Same source the Vehicle screen uses — `VehicleService.GetVehicleState` ->
/// `battery.soc` — so the two screens cannot disagree about the same number.
///
/// A class rather than a closure in `main.dart` for the same reason as
/// [CameraProbeSource]: the composition root is not covered by tests, and a
/// branch should not hide there.
class BatterySocSource {
  final VehicleServiceClient _vehicleService;

  const BatterySocSource(this._vehicleService);

  /// Null on any failure, and null for a vehicle that reports no pack at all.
  /// The tile renders null as "Not available" rather than 0%, which would be
  /// indistinguishable from a flat battery.
  Future<int?> read() async {
    try {
      final resp = await _vehicleService.getState(GetVehicleStateRequest());
      // Same success gate VehicleController._fetchState() applies before reading
      // any field off this response.
      if (!resp.success) return null;
      final soc = resp.battery.soc.toInt();
      // 0 is what the proto's default gives for "no reading", and a genuinely
      // flat pack is not something this tile needs to distinguish at the cost of
      // showing 0% every time the vehicle is asleep.
      if (soc <= 0 || soc > 100) return null;
      return soc;
    } catch (_) {
      return null;
    }
  }
}
