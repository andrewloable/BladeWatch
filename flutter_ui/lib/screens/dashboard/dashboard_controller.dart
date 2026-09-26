import 'package:flutter/foundation.dart';

import 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/system.pb.dart';
import '../../platform/daemon_channel.dart';
import 'package:bladewatch_rpc/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/trips_service_client.dart';
import 'package:bladewatch_rpc/trips/trip_costs.dart';
import 'dashboard_models.dart';
import '../../shell/disposed_safe_notifier.dart';

/// Pure-Dart port of `DashboardFragment`'s behaviour (no Flutter imports).
/// Ground truth: `app/src/main/java/com/loabletech/bladewatch/ui/fragment/DashboardFragment.kt`.
/// `DashboardInsight.kt`, which the task description for this screen names as
/// a logic source, is **dead code** — grepped the whole native source tree;
/// it is referenced nowhere outside its own file. The live Dashboard (the
/// "SOTA Dashboard" in `DashboardFragment`'s own header comment) has its own,
/// different, inline logic, which is what this class actually ports.
///
/// Two data sources this port deliberately does **not** match 1:1 with the
/// native fragment, both because the native mechanism is ADB/local-storage
/// only and unreachable from the Flutter APK (Epic 1's IPC-only rule):
/// - **Today's recording count** comes from `RecordingsService.ListRecordings`
///   (`date: <today>`)'s `total` field over RPC, not a local directory walk
///   (`RecordingScanner`) — the daemon already exposes exactly this count.
/// - **Recording-in-progress** comes from `SystemService.GetStatus()`'s
///   `recording` field — the native fragment got it from `RecordingViewModel`
///   instead (ADB-based), which has no IPC equivalent.
///
/// The native connect card (the tunnel's QR code, device id and the web app's access code) is
/// gone with tor (BladeWatch-rdtj.12): a companion pairs through the pairing dialog instead.
class DashboardController extends ChangeNotifier with DisposedSafeNotifier {
  DashboardController({
    required TripsServiceClient tripsService,
    required RecordingsServiceClient recordingsService,
    required SystemServiceClient systemService,
    required DaemonChannel daemonChannel,
  })  : _tripsService = tripsService, // ignore: prefer_initializing_formals
        _recordingsService = recordingsService, // ignore: prefer_initializing_formals
        _systemService = systemService, // ignore: prefer_initializing_formals
        _daemonChannel = daemonChannel; // ignore: prefer_initializing_formals

  final TripsServiceClient _tripsService;
  final RecordingsServiceClient _recordingsService;
  final SystemServiceClient _systemService;
  final DaemonChannel _daemonChannel;

  TripStatsState _tripStats = const TripStatsState.loading();
  TripStatsState get tripStats => _tripStats;

  DriveInfo _drive = const DriveInfo();
  DriveInfo get drive => _drive;

  RecordingsMetricState _recordingsMetric = const RecordingsMetricState.loading();
  RecordingsMetricState get recordingsMetric => _recordingsMetric;

  DaemonsSummaryState _daemonsSummary = const DaemonsSummaryState.loading();
  DaemonsSummaryState get daemonsSummary => _daemonsSummary;

  VehicleTileState _vehicleTile = const VehicleTileState.loading();
  VehicleTileState get vehicleTile => _vehicleTile;

  /// BladeWatch-rdtj.17: the Pear peer, which the Remote access tile reports while it is on.
  PearStatus _pear = PearStatus.unknown;
  PearStatus get pear => _pear;

  /// Refreshes every tile. Each data source is independently try/caught so
  /// one RPC/channel failure never blocks the others from updating — mirrors
  /// the native fragment's per-tile `catch (_: Throwable) {}` pattern.
  /// Notifies listeners exactly once after everything settles.
  Future<void> refresh() async {
    await Future.wait([
      _refreshTripStats(),
      _refreshRecordingsAndDaemonState(),
      _refreshDaemonsSummary(),
      _refreshVehicleTile(),
      _refreshPear(),
    ]);
    notifyListeners();
  }

  /// Gear, drive mode, Auto Hold and EV/HEV change under the driver's hand, so the screen reads
  /// them on their own short cycle: through [refresh] a change waited for the slowest tile of the
  /// 15 s reload, and the owner saw EV/HEV and Auto Hold never move (BladeWatch-7zp9).
  Future<void> refreshDrive() async {
    try {
      final drive = _driveOf(await _systemService.getStatus(GetStatusRequest()));
      if (drive == _drive) return;
      _drive = drive;
      notifyListeners();
    } catch (_) {
      // Keep what is shown; the next tick or the full refresh tries again.
    }
  }

  static DriveInfo _driveOf(GetStatusResponse status) {
    String label(String v) => v.isEmpty ? DriveInfo.unknown : v;
    final d = status.driveStatus;
    return DriveInfo(
      gear: label(d.gear),
      driveMode: label(d.driveMode),
      autoHold: label(d.autoHold),
      energyMode: label(d.energyMode),
    );
  }

  Future<void> _refreshTripStats() async {
    try {
      // Every trip of the week, not the first page: the costs are a sum (BladeWatch-39d2).
      final trips = await listTripsInPeriod(_tripsService.listTrips, 7);
      var distanceKm = 0.0;
      var durationSeconds = 0;
      for (final trip in trips) {
        distanceKm += trip.distanceKm;
        durationSeconds += trip.durationSeconds;
      }
      _tripStats = TripStatsState(
        loading: false,
        available: true,
        tripCount: trips.length,
        totalDistanceKm: distanceKm,
        totalDurationSeconds: durationSeconds,
        costs: TripCosts.of(trips),
      );
    } catch (_) {
      _tripStats = const TripStatsState.unavailable();
    }
  }

  // GetStatus feeds both the recordings tile's isRecording flag and the drive chips, so it's
  // fetched once and shared.
  Future<void> _refreshRecordingsAndDaemonState() async {
    bool isRecording = false;
    try {
      final status = await _systemService.getStatus(GetStatusRequest());
      isRecording = status.recording.isNotEmpty;
      _drive = _driveOf(status);
    } catch (_) {
      // Leave isRecording at its default; the count fetch below is independent.
    }

    try {
      final today = _todayDateString();
      final response = await _recordingsService.listRecordings(ListRecordingsRequest(date: today, pageSize: 1));
      _recordingsMetric = RecordingsMetricState(loading: false, todayCount: response.total, isRecording: isRecording);
    } catch (_) {
      _recordingsMetric = RecordingsMetricState(loading: false, todayCount: 0, isRecording: isRecording);
    }
  }

  Future<void> _refreshDaemonsSummary() async {
    try {
      final statuses = await _daemonChannel.processStatus();
      final running = statuses.values.where((v) => v).length;
      _daemonsSummary = DaemonsSummaryState(loading: false, running: running, total: statuses.length);
    } catch (_) {
      _daemonsSummary = const DaemonsSummaryState(loading: false, running: 0, total: 0);
    }
  }

  Future<void> _refreshVehicleTile() async {
    String? modelId;
    // BladeWatch-p7vi: GetSohNominal is a removed-feature stub that always
    // answers "unset", so reading it only ever produced a tile stuck on
    // "Tap to set". The tile now reflects the selected model instead.
    try {
      final resp = await _systemService.getSelectedModel(GetSelectedModelRequest());
      if (resp.modelId.isNotEmpty) modelId = resp.modelId;
    } catch (_) {}
    _vehicleTile = VehicleTileState(loading: false, modelId: modelId);
  }

  Future<void> _refreshPear() async {
    try {
      _pear = await _daemonChannel.pearStatus();
    } catch (_) {
      _pear = PearStatus.unknown;
    }
  }

  /// `YYYY-MM-DD` — the format the daemon's date filter requires.
  ///
  /// `RecordingsApiHandler.dateRangeMs`
  /// (app/src/main/java/com/loabletech/bladewatch/server/RecordingsApiHandler.java:733)
  /// splits this on '-' and demands exactly 3 parts. A value in any other
  /// shape is not an error: it returns the EMPTY range {0, 0}, so the response
  /// is a perfectly well-formed `total: 0`. Sending `YYYYMMDD` therefore made
  /// the Dashboard report "Today's recordings 0" on a day with 37 of them.
  String _todayDateString() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
