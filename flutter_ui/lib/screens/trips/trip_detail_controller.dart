import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:bladewatch_ui/gen/bladewatch/v1/trips.pb.dart';
import 'package:bladewatch_ui/rpc/services/trips_service_client.dart';
import 'package:fixnum/fixnum.dart';

import 'trips_models.dart';
import '../../shell/disposed_safe_notifier.dart';

/// Controller behind the trip detail overlay — BladeWatch-yz1e.5. Ground
/// truth: `TripDetailController.kt` (457 LOC). The route map itself
/// (OSMDroid natively) is not ported here — see the task's closing notes;
/// [telemetry] is still fetched and exposed (GPS point count, same
/// `hasGps`/2-point threshold as native's `renderRoute()`) so the screen can
/// show an honest "N GPS points recorded" / "no route data" line instead of
/// silently dropping the data.
///
/// [hasError] collapses every native failure mode into one state,
/// matching native itself: `TripsClient.fetchTripDetail()` returns null
/// uniformly whether the RPC failed outright or the response had no
/// `trip`/`trip.summary` — ConnectRPC's Kotlin client wraps network errors
/// as a `ResponseMessage.Failure` value rather than a thrown exception, so
/// native's own `!is ResponseMessage.Success` check already treats them
/// the same way this class's try/catch does.
class TripDetailController extends ChangeNotifier with DisposedSafeNotifier {
  final TripsServiceClient _tripsService;

  TripDetailController({required TripsServiceClient tripsService}) : _tripsService = tripsService; // ignore: prefer_initializing_formals

  bool _loading = true;
  bool get loading => _loading;

  bool _hasError = false;
  bool get hasError => _hasError;

  TripDetailData? _detail;
  TripDetailData? get detail => _detail;

  List<TelemetryPoint> _telemetry = const [];
  List<TelemetryPoint> get telemetry => _telemetry;

  Future<void> load(int tripId) async {
    _loading = true;
    _hasError = false;
    _detail = null;
    _telemetry = const [];
    notifyListeners();

    try {
      final resp = await _tripsService.getTrip(GetTripRequest(id: Int64(tripId)));
      if (!resp.hasTrip() || !resp.trip.hasSummary()) {
        _hasError = true;
      } else {
        _detail = _toDetail(resp.trip);
        final telemetryResp = await _tripsService.getTelemetry(GetTelemetryRequest(tripId: Int64(tripId)));
        _telemetry = telemetryResp.telemetry.map(_toTelemetryPoint).whereType<TelemetryPoint>().toList();
      }
    } catch (_) {
      _hasError = true;
    }

    _loading = false;
    notifyListeners();
  }

  static TripDetailData _toDetail(TripDetail t) {
    final s = t.summary;
    return TripDetailData(
      id: s.id.toInt(),
      startTime: DateTime.fromMillisecondsSinceEpoch(s.startTime.toInt()),
      endTime: DateTime.fromMillisecondsSinceEpoch(s.endTime.toInt()),
      distanceKm: s.distanceKm,
      durationSeconds: s.durationSeconds,
      avgSpeedKmh: s.avgSpeedKmh,
      maxSpeedKmh: s.maxSpeedKmh.toDouble(),
      socStart: s.socStart,
      socEnd: s.socEnd,
      // TripSummary has no direct kWh-consumed field, only energyPerKm — but energyPerKm *
      // distanceKm IS that value, exactly (the daemon derives energyPerKm from the same
      // energyUsedKwh internally; see TripScoreEngine's own kWh-preferred efficiency
      // computation). Native hardcoded this to 0.0 reasoning the field "doesn't exist" and
      // the Flutter port faithfully reproduced that — this is the fix, not a port gap.
      energyUsedKwh: s.energyPerKm * s.distanceKm,
      efficiencySocPerKm: 0.0,
      currency: s.currency,
      tripCost: s.tripCost,
      gradientProfile: s.gradientProfile,
      elevationGainM: t.elevationGainM,
      elevationLossM: t.elevationLossM,
      extTempC: s.extTempC.toDouble(),
      anticipationScore: t.anticipationScore,
      smoothnessScore: t.smoothnessScore,
      speedDisciplineScore: t.speedDisciplineScore,
      efficiencyScore: t.efficiencyScore,
      consistencyScore: t.consistencyScore,
      overallScore: s.overallScore,
      telemetryFilePath: '',
      hasFuelData: s.hasFuelData,
      litresUsed: s.litresUsed,
      fuelCost: s.fuelCost,
      electricCost: s.electricCost,
    );
  }

  static TelemetryPoint? _toTelemetryPoint(TelemetrySample sample) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(sample.sampleJson) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
    return TelemetryPoint(
      timestampMs: (json['t'] as num?)?.toInt() ?? 0,
      speedKmh: (json['s'] as num?)?.toInt() ?? 0,
      accelPercent: (json['a'] as num?)?.toInt() ?? 0,
      brakePercent: (json['b'] as num?)?.toInt() ?? 0,
      lat: (json['la'] as num?)?.toDouble() ?? 0.0,
      lon: (json['lo'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
