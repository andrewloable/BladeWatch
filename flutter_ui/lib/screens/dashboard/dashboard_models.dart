/// Trip-stats hero state — ground truth: `DashboardFragment.refreshTripStats()`.
class TripStatsState {
  final bool loading;

  /// False when the RPC call itself failed (native: `dataAvailable == false`,
  /// shows `dashboard_trips_unavailable`) — distinct from "loaded, zero trips"
  /// (native: `dashboard_trips_no_data`).
  final bool available;
  final int tripCount;
  final double totalDistanceKm;
  final int totalDurationSeconds;

  const TripStatsState({
    required this.loading,
    required this.available,
    required this.tripCount,
    required this.totalDistanceKm,
    required this.totalDurationSeconds,
  });

  const TripStatsState.loading()
      : loading = true,
        available = false,
        tripCount = 0,
        totalDistanceKm = 0,
        totalDurationSeconds = 0;

  const TripStatsState.unavailable()
      : loading = false,
        available = false,
        tripCount = 0,
        totalDistanceKm = 0,
        totalDurationSeconds = 0;

  /// "0 km" / "1.2 km" below 1000km, "N km" (no decimal) at/above —
  /// `DashboardFragment.refreshTripStats()`'s `distanceStr` formatting.
  String get distanceLabel => totalDistanceKm >= 1000
      ? '${totalDistanceKm.toStringAsFixed(0)} km'
      : '${totalDistanceKm.toStringAsFixed(1)} km';

  /// "Nh Mm" / "Mm" — `DashboardFragment.formatDuration()`.
  String get driveTimeLabel {
    final h = totalDurationSeconds ~/ 3600;
    final m = (totalDurationSeconds % 3600) ~/ 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}

/// Recordings metric tile — ground truth: `refreshMetricsTiles()`/
/// `renderRecordingsValue()`. `todayCount` comes from
/// `RecordingsService.ListRecordings(date: today)`'s `total` field over RPC,
/// **not** a local directory walk (`RecordingScanner`) like the native
/// fragment — the Flutter APK has no direct filesystem access to
/// `/storage/emulated/0/BladeWatch/`, and the daemon already exposes exactly
/// this count over RPC. Same source of truth as the Recordings screen either
/// way, satisfying the same intent as the native comment on `refreshMetricsTiles()`.
class RecordingsMetricState {
  final bool loading;
  final int todayCount;
  final bool isRecording;

  const RecordingsMetricState({required this.loading, required this.todayCount, required this.isRecording});

  const RecordingsMetricState.loading()
      : loading = true,
        todayCount = 0,
        isRecording = false;
}

/// Daemon summary tile — ground truth: the `daemonsViewModel.daemonStates`
/// observer's `running`/`total` count. Sourced from `daemon.processStatus`
/// (BladeWatch-1xt9) rather than the native's ADB-based per-daemon
/// `DaemonsViewModel`, which counts all 4 `DaemonType` values (incl. Zrok);
/// `daemon.processStatus` reports the same 4, so the count is directly
/// comparable.
class DaemonsSummaryState {
  final bool loading;
  final int running;
  final int total;

  const DaemonsSummaryState({required this.loading, required this.running, required this.total});

  const DaemonsSummaryState.loading()
      : loading = true,
        running = 0,
        total = 0;
}

/// Tunnel tile + hero chip + QR/placeholder state — ground truth:
/// `updateTunnelTile()`/`rebuildTunnelChips()`/`showPlaceholder()`. Zrok is
/// the only tunnel type this app has ever shipped (`collectAvailableTunnels()`
/// only ever adds `ZROK_TUNNEL`), so unlike the native code's
/// generic-looking `List<Pair<DaemonType, String>>` machinery, this models
/// Zrok directly rather than a list of one.
enum TunnelPhase { offline, connecting, online }

class TunnelState {
  final TunnelPhase phase;
  final String? url;

  const TunnelState({required this.phase, this.url});

  const TunnelState.loading() : phase = TunnelPhase.offline, url = null;
}

/// Vehicle metric tile — ground truth: `refreshVehicleTile()`.
class VehicleTileState {
  final bool loading;
  final double nominalKwh;
  final String? modelId;

  const VehicleTileState({required this.loading, required this.nominalKwh, this.modelId});

  const VehicleTileState.loading() : loading = true, nominalKwh = 0, modelId = null;

  bool get hasCapacity => nominalKwh > 0;
}

/// Access-code (auth) tile — ground truth: `loadAuthState()`/
/// `toggleTokenVisibility()`. `deviceId` is a **separate, purely local**
/// concern from the access code (native: `DeviceIdGenerator`, not
/// `AuthManager`) — see `DashboardController`'s doc comment for why the
/// Flutter port derives it differently.
class AccessCodeState {
  final bool loading;
  final String? secret;
  final bool visible;

  const AccessCodeState({required this.loading, this.secret, required this.visible});

  const AccessCodeState.loading() : loading = true, secret = null, visible = false;

  /// The masked display value — `dashboard_token_masked`'s dot pattern is
  /// applied by the widget layer (a pure string constant); this getter only
  /// decides *which* value (masked vs real) should be shown.
  String? get displayValue => visible ? secret : null;
}

/// One entry in the vehicle model manifest dropdown — ground truth: the
/// local `ModelEntry` data class inside `showVehicleCapacityDialog()`.
class VehicleModelEntry {
  final String id;
  final String title;
  final double nominalKwh;

  const VehicleModelEntry({required this.id, required this.title, required this.nominalKwh});
}

/// State for the vehicle-capacity dialog — ground truth:
/// `DashboardFragment.showVehicleCapacityDialog()`.
class VehicleDialogState {
  final bool loading;
  final List<VehicleModelEntry> models;
  final String? selectedModelId;

  /// The capacity text field's current value — a string (not a double)
  /// because it is user-edited input, same as the native `TextInputEditText`.
  final String capacityText;

  // Summary section — each shown only when its backing data is meaningful,
  // mirroring the native's per-line `visibility = View.VISIBLE` gating.
  final double nominalKwh;
  final String nominalSource;
  final double displaySoh;
  final String displaySource;

  const VehicleDialogState({
    required this.loading,
    required this.models,
    required this.selectedModelId,
    required this.capacityText,
    required this.nominalKwh,
    required this.nominalSource,
    required this.displaySoh,
    required this.displaySource,
  });

  const VehicleDialogState.loading()
      : loading = true,
        models = const [],
        selectedModelId = null,
        capacityText = '',
        nominalKwh = 0,
        nominalSource = 'unset',
        displaySoh = -1,
        displaySource = 'unavailable';

  VehicleDialogState copyWith({
    bool? loading,
    List<VehicleModelEntry>? models,
    String? selectedModelId,
    String? capacityText,
    double? nominalKwh,
    String? nominalSource,
    double? displaySoh,
    String? displaySource,
  }) =>
      VehicleDialogState(
        loading: loading ?? this.loading,
        models: models ?? this.models,
        selectedModelId: selectedModelId ?? this.selectedModelId,
        capacityText: capacityText ?? this.capacityText,
        nominalKwh: nominalKwh ?? this.nominalKwh,
        nominalSource: nominalSource ?? this.nominalSource,
        displaySoh: displaySoh ?? this.displaySoh,
        displaySource: displaySource ?? this.displaySource,
      );

  bool get hasCapacitySummary => nominalKwh > 0;
  bool get hasSohSummary => displaySoh > 0;
}

/// Human-readable display name for a model id — ground truth:
/// `DashboardFragment.modelDisplayName()`. A plain lookup table, not
/// localizable data (these are brand/model names, not UI chrome) — mirrors
/// the native function exactly, including its literal `"—"` for a null id
/// and its title-case fallback for an unrecognized one.
String modelDisplayName(String? modelId) {
  if (modelId == null) return '—';
  const names = {
    'seal': 'BYD Seal',
    'atto3': 'BYD Atto 3',
    'atto-3': 'BYD Atto 3',
    'atto2': 'BYD Atto 2',
    'atto-2': 'BYD Atto 2',
    'atto1': 'BYD Atto 1',
    'atto-1': 'BYD Atto 1',
    'han': 'BYD Han',
    'tang': 'BYD Tang',
    'song': 'BYD Song',
    'qin': 'BYD Qin',
    'dolphin': 'BYD Dolphin',
    'seagull': 'BYD Seagull',
    'sealion6': 'BYD Sealion 6',
    'sealion7': 'BYD Sealion 7',
    'sealu': 'BYD Seal U',
    'seal-u': 'BYD Seal U',
    'seal5-dmi-dynamic': 'BYD Seal 5 DM-i Dynamic',
    'seal5-dmi-premium': 'BYD Seal 5 DM-i Premium',
  };
  final lower = modelId.toLowerCase();
  if (names.containsKey(lower)) return names[lower]!;
  if (modelId.isEmpty) return modelId;
  return modelId[0].toUpperCase() + modelId.substring(1);
}
