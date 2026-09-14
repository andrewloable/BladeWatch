import 'package:flutter/foundation.dart';

import '../../gen/bladewatch/v1/recordings.pb.dart';
import '../../gen/bladewatch/v1/system.pb.dart';
import '../../gen/bladewatch/v1/trips.pb.dart';
import '../../platform/auth_channel.dart';
import '../../platform/daemon_channel.dart';
import '../../rpc/services/recordings_service_client.dart';
import '../../rpc/services/system_service_client.dart';
import '../../rpc/services/trips_service_client.dart';
import 'dashboard_models.dart';

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
/// - **Recording-in-progress** and **device id** come from
///   `SystemService.GetStatus()`'s `recording`/`deviceId` fields — the native
///   fragment gets these from `RecordingViewModel`/`DeviceIdGenerator`
///   instead (ADB- and SharedPreferences-based), which have no IPC
///   equivalent; `GetStatus` already exposes both as a byproduct of the same
///   call, and is the daemon's own canonical device id (the one
///   `AuthManager`'s JWT `sub` claim uses), not a UI-only label like
///   `DeviceIdGenerator`'s.
/// - **The Zrok tunnel URL** reaches this controller through [tunnelUrlSource],
///   wired in `main.dart` to `DaemonChannel.tunnelUrl` (the daemon's
///   `tunnelStatus` IPC command, BladeWatch-m1po). Native reads it from an
///   ADB-launched process's stdout and caches it in app-private
///   `SharedPreferences`, neither of which this APK can reach; the daemon reads
///   zrok's own log instead, and only reports a URL while the tunnel process is
///   actually alive. The injected default still reports "no tunnel", which keeps
///   every test free of a platform channel.
class DashboardController extends ChangeNotifier {
  DashboardController({
    required TripsServiceClient tripsService,
    required RecordingsServiceClient recordingsService,
    required SystemServiceClient systemService,
    required DaemonChannel daemonChannel,
    required AuthChannel authChannel,
    Future<String?> Function() tunnelUrlSource = _noTunnel,
  })  : _tunnelUrlSource = tunnelUrlSource, // ignore: prefer_initializing_formals
        _tripsService = tripsService, // ignore: prefer_initializing_formals
        _recordingsService = recordingsService, // ignore: prefer_initializing_formals
        _systemService = systemService, // ignore: prefer_initializing_formals
        _daemonChannel = daemonChannel, // ignore: prefer_initializing_formals
        _authChannel = authChannel; // ignore: prefer_initializing_formals

  static Future<String?> _noTunnel() async => null;

  static const int minAccessCodeLength = 12;

  final TripsServiceClient _tripsService;
  final RecordingsServiceClient _recordingsService;
  final SystemServiceClient _systemService;
  final DaemonChannel _daemonChannel;
  final AuthChannel _authChannel;
  final Future<String?> Function() _tunnelUrlSource;

  TripStatsState _tripStats = const TripStatsState.loading();
  TripStatsState get tripStats => _tripStats;

  RecordingsMetricState _recordingsMetric = const RecordingsMetricState.loading();
  RecordingsMetricState get recordingsMetric => _recordingsMetric;

  DaemonsSummaryState _daemonsSummary = const DaemonsSummaryState.loading();
  DaemonsSummaryState get daemonsSummary => _daemonsSummary;

  VehicleTileState _vehicleTile = const VehicleTileState.loading();
  VehicleTileState get vehicleTile => _vehicleTile;

  AccessCodeState _accessCode = const AccessCodeState.loading();
  AccessCodeState get accessCode => _accessCode;

  TunnelState _tunnel = const TunnelState.loading();
  TunnelState get tunnel => _tunnel;

  /// The daemon's canonical device id (same identity `AuthManager`'s JWT
  /// `sub` claim uses) — see this class's doc comment for why the Flutter
  /// port sources it from `GetStatus` rather than native's ADB-based
  /// `DeviceIdGenerator`. Null until the first successful `GetStatus` call.
  String? _deviceId;
  String? get deviceId => _deviceId;

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
      _refreshAccessCode(),
      _refreshTunnel(),
    ]);
    notifyListeners();
  }

  Future<void> _refreshTripStats() async {
    try {
      final response = await _tripsService.listTrips(ListTripsRequest(days: 7, limit: 100));
      var distanceKm = 0.0;
      var durationSeconds = 0;
      for (final trip in response.trips) {
        distanceKm += trip.distanceKm;
        durationSeconds += trip.durationSeconds;
      }
      _tripStats = TripStatsState(
        loading: false,
        available: true,
        tripCount: response.trips.length,
        totalDistanceKm: distanceKm,
        totalDurationSeconds: durationSeconds,
      );
    } catch (_) {
      _tripStats = const TripStatsState.unavailable();
    }
  }

  // GetStatus feeds both the recordings tile's isRecording flag and the
  // Connect card's device-id label, so it's fetched once and shared.
  Future<void> _refreshRecordingsAndDaemonState() async {
    bool isRecording = false;
    try {
      final status = await _systemService.getStatus(GetStatusRequest());
      isRecording = status.recording.isNotEmpty;
      if (status.deviceId.isNotEmpty) _deviceId = status.deviceId;
    } catch (_) {
      // Leave isRecording/deviceId at their defaults; the count fetch below is independent.
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

  Future<void> _refreshAccessCode() async {
    try {
      final secret = await _authChannel.getAccessCode();
      _accessCode = AccessCodeState(loading: false, secret: secret, visible: _accessCode.visible);
    } catch (_) {
      _accessCode = AccessCodeState(loading: false, secret: null, visible: _accessCode.visible);
    }
  }

  Future<void> _refreshTunnel() async {
    try {
      final url = await _tunnelUrlSource();
      _tunnel = (url == null || url.isEmpty)
          ? const TunnelState(phase: TunnelPhase.offline)
          : TunnelState(phase: TunnelPhase.online, url: url);
    } catch (_) {
      _tunnel = const TunnelState(phase: TunnelPhase.offline);
    }
  }

  void toggleAccessCodeVisibility() {
    _accessCode = AccessCodeState(loading: _accessCode.loading, secret: _accessCode.secret, visible: !_accessCode.visible);
    notifyListeners();
  }

  /// Returns true on success (and updates [accessCode] with the new value);
  /// false if the daemon rejected the write — mirrors
  /// `JwtMinter.regenerateAccessCode()`'s null-on-failure contract.
  Future<bool> regenerateAccessCode() async {
    final newCode = await _authChannel.regenerateAccessCode();
    if (newCode == null) return false;
    _accessCode = AccessCodeState(loading: false, secret: newCode, visible: _accessCode.visible);
    notifyListeners();
    return true;
  }

  /// Validates length locally first (same bound as
  /// `JwtMinter.CUSTOM_SECRET_MIN_LENGTH`) so an obviously-too-short password
  /// never reaches the channel at all.
  Future<bool> setCustomAccessCode(String password) async {
    if (password.length < minAccessCodeLength) return false;
    final ok = await _authChannel.setCustomAccessCode(password);
    if (!ok) return false;
    _accessCode = AccessCodeState(loading: false, secret: password, visible: _accessCode.visible);
    notifyListeners();
    return true;
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
