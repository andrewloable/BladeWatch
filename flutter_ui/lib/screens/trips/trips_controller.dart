import 'dart:convert';

import 'package:flutter/foundation.dart';

// DnaScores/TripsConfig/TripsStorage collide with this file's own hand-written
// model classes of the same name — same shape as yz1e.3's RecordingStatus
// collision.
import 'package:bladewatch_ui/gen/bladewatch/v1/trips.pb.dart' hide DnaScores;
import 'package:bladewatch_ui/gen/bladewatch/v1/trips.pb.dart' as pb show DnaScores;
import 'package:bladewatch_ui/rpc/services/trips_service_client.dart';
import 'package:fixnum/fixnum.dart';

import 'trips_models.dart';
import '../../shell/disposed_safe_notifier.dart';

/// Controller behind the Trips screen's 3 tabs (Trips/Stats/Storage) —
/// BladeWatch-yz1e.5. Ground truth: `TripsController.kt` (852 LOC). The trip
/// detail overlay's own data/lifecycle is a separate controller
/// ([TripDetailController], mirroring native's own separate
/// `TripDetailController.kt`) — this class only tracks which trip id (if
/// any) is currently selected.
///
/// [longTripsService] is a *second* [TripsServiceClient] instance built on a
/// long-read-timeout `ConnectClient` (`main.dart` wires
/// `createIoHttpSender(readTimeout: Duration(seconds: 120))`) — `SyncTrips`
/// can take ~120s, and the default 10s client would time it out. Mirrors
/// `ConnectClientProvider.longTripsService()`.
class TripsController extends ChangeNotifier with DisposedSafeNotifier {
  final TripsServiceClient _tripsService;
  final TripsServiceClient _longTripsService;

  TripsController({required TripsServiceClient tripsService, required TripsServiceClient longTripsService})
      : _tripsService = tripsService, // ignore: prefer_initializing_formals
        _longTripsService = longTripsService; // ignore: prefer_initializing_formals

  TripsTab _activeTab = TripsTab.trips;
  TripsTab get activeTab => _activeTab;

  TripsDaysFilter _activeFilter = TripsDaysFilter.seven;
  TripsDaysFilter get activeFilter => _activeFilter;

  TripsLoadState _state = const TripsLoading();
  TripsLoadState get state => _state;

  bool _syncRunning = false;
  bool get syncRunning => _syncRunning;
  SyncOutcome? _syncResult;
  SyncOutcome? get syncResult => _syncResult;

  int? _selectedTripId;
  int? get selectedTripId => _selectedTripId;

  /// Switches the visible tab only — native re-renders from the already
  /// loaded state without a fresh fetch when switching tabs.
  void selectTab(TripsTab tab) {
    _activeTab = tab;
    notifyListeners();
  }

  Future<void> selectFilter(TripsDaysFilter filter) {
    _activeFilter = filter;
    return load();
  }

  Future<void> load() async {
    _state = const TripsLoading();
    notifyListeners();

    try {
      final results = await Future.wait([
        _tripsService.listTrips(ListTripsRequest(days: _activeFilter.days, limit: 100)),
        _tripsService.getSummary(GetSummaryRequest(days: _activeFilter.days)),
        // Hardcoded 30 days regardless of the active Trips/Stats filter —
        // matches native's own `client.fetchDna(30)` call exactly.
        _tripsService.getDna(GetDnaRequest(days: 30)),
        _tripsService.getRange(GetRangeRequest()),
        _tripsService.getConfig(GetConfigRequest()),
        _tripsService.getStorage(GetStorageRequest()),
      ]);

      final listResp = results[0] as ListTripsResponse;
      final summaryResp = results[1] as GetSummaryResponse;
      final dnaResp = results[2] as GetDnaResponse;
      final rangeResp = results[3] as GetRangeResponse;
      final configResp = results[4] as GetConfigResponse;
      final storageResp = results[5] as GetStorageResponse;

      _state = TripsLoaded(
        trips: listResp.trips.map(_toTripItem).toList(),
        summary: _toSummary(summaryResp),
        dna: dnaResp.hasDna() ? _toDna(dnaResp.dna) : null,
        range: _toRange(rangeResp.rangeJson),
        config: configResp.hasConfig() ? _toConfig(configResp.config) : null,
        storage: storageResp.hasStorage() ? _toStorage(storageResp.storage) : null,
      );
    } catch (e) {
      _state = TripsError('$e');
    }
    notifyListeners();
  }

  /// Storage tab's "Apply Changes" — saves both config and storage type,
  /// resending the currently-loaded storage limit unchanged (native's own
  /// Storage tab has no control that edits the byte limit itself).
  Future<bool> applyStorageChanges({
    required bool enabled,
    required double rate,
    required String currency,
    required String distanceUnit,
    required String storageType,
  }) async {
    final loaded = _state;
    final currentLimitMb = loaded is TripsLoaded ? loaded.storage?.limitMb : null;
    if (currentLimitMb == null) return false;

    try {
      final configResp = await _tripsService.setConfig(SetConfigRequest(
        enabled: enabled,
        hasEnabled_2: true,
        electricityRate: rate,
        hasElectricityRate_4: true,
        currency: currency,
        distanceUnit: distanceUnit,
      ));
      final storageResp = await _tripsService.setStorage(SetStorageRequest(
        storageType: storageType,
        storageLimitMb: Int64(currentLimitMb),
        hasStorageLimitMb_3: true,
      ));
      final ok = configResp.success && storageResp.success;
      await load();
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<void> syncDatabase() async {
    _syncRunning = true;
    notifyListeners();

    try {
      final resp = await _longTripsService.syncTrips(SyncTripsRequest());
      _syncResult = SyncOutcome(
        success: resp.success,
        added: resp.added,
        removed: resp.removed,
        total: resp.total,
        error: resp.success || resp.error.isEmpty ? null : resp.error,
      );
    } catch (_) {
      _syncResult = const SyncOutcome(success: false);
    }
    _syncRunning = false;
    notifyListeners();
  }

  void dismissSyncResult() {
    _syncResult = null;
    notifyListeners();
  }

  void openDetail(int tripId) {
    _selectedTripId = tripId;
    notifyListeners();
  }

  void closeDetail() {
    _selectedTripId = null;
    notifyListeners();
  }

  static TripItem _toTripItem(TripSummary t) => TripItem(
        id: t.id.toInt(),
        startTime: DateTime.fromMillisecondsSinceEpoch(t.startTime.toInt()),
        endTime: DateTime.fromMillisecondsSinceEpoch(t.endTime.toInt()),
        distanceKm: t.distanceKm,
        durationSeconds: t.durationSeconds,
        overallScore: t.overallScore,
        tripCost: t.tripCost,
        currency: t.currency,
        energyKwh: 0.0, // proto TripSummary has energyPerKm, not energyUsedKwh — see trips_models.dart
      );

  static TripsSummary _toSummary(GetSummaryResponse resp) {
    var tripCount = 0;
    var totalDist = 0.0;
    var totalDur = 0;
    var totalEnergy = 0.0;
    var totalEfficiency = 0.0;
    var energyPerKmSum = 0.0;
    for (final entry in resp.summary) {
      final Map<String, dynamic> r;
      try {
        r = jsonDecode(entry.rollupJson) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }
      tripCount += (r['tripCount'] as num?)?.toInt() ?? 0;
      totalDist += (r['totalDistanceKm'] as num?)?.toDouble() ?? 0.0;
      totalDur += (r['totalDurationSeconds'] as num?)?.toInt() ?? 0;
      totalEnergy += (r['totalEnergyKwh'] as num?)?.toDouble() ?? 0.0;
      totalEfficiency += (r['avgEfficiency'] as num?)?.toDouble() ?? 0.0;
      energyPerKmSum += (r['avgEnergyPerKm'] as num?)?.toDouble() ?? 0.0;
    }
    // The divisor is the ORIGINAL entry count (including unparseable ones,
    // which contribute 0 to the sums but still dilute the average) — matches
    // native's `resp.message.summaryList.size`, not a "successfully parsed"
    // count.
    final count = resp.summary.length;
    return TripsSummary(
      tripCount: tripCount,
      totalDistanceKm: totalDist,
      totalDurationSeconds: totalDur,
      totalEnergyKwh: totalEnergy,
      avgEnergyPerKm: count > 0 ? energyPerKmSum / count : 0.0,
      avgEfficiency: count > 0 ? totalEfficiency / count : 0.0,
    );
  }

  static DnaScores _toDna(pb.DnaScores dna) => DnaScores(
        anticipation: dna.anticipation,
        smoothness: dna.smoothness,
        speedDiscipline: dna.speedDiscipline,
        efficiency: dna.efficiency,
        consistency: dna.consistency,
        overall: dna.overall,
      );

  static RangeEstimate? _toRange(String rangeJson) {
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(rangeJson) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
    final range = (json['range'] as Map<String, dynamic>?) ?? json;
    return RangeEstimate(
      estimatedKm: (range['predictedRangeKm'] as num?)?.toDouble() ?? 0.0,
      builtInKm: (range['builtInRangeKm'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static TripsConfig _toConfig(TripConfig cfg) => TripsConfig(
        enabled: cfg.enabled,
        electricityRate: cfg.electricityRate,
        currency: cfg.currency,
        distanceUnit: cfg.distanceUnit,
      );

  static TripsStorage _toStorage(TripStorageInfo s) => TripsStorage(
        storageType: s.storageType,
        limitMb: s.limitMb.toInt(),
        usedMb: s.usedMb,
        usedUnit: s.usedUnit,
        sdCardAvailable: s.sdCardAvailable,
        tripsCount: s.tripsCount,
        storagePath: s.storagePath,
      );
}
