import 'package:bladewatch_rpc/trips/trip_costs.dart';
import 'package:intl/intl.dart';

enum TripsTab { trips, stats }

enum TripsDaysFilter {
  seven(7),
  fourteen(14),
  thirty(30);

  final int days;
  const TripsDaysFilter(this.days);
}

String formatTripDuration(int durationSeconds) {
  final h = durationSeconds ~/ 3600;
  final m = (durationSeconds % 3600) ~/ 60;
  return h > 0 ? '${h}h ${m}m' : '${m}m';
}

class TripItem {
  final int id;
  final DateTime startTime;
  final DateTime endTime;
  final double distanceKm;
  final int durationSeconds;
  final int overallScore;
  final double tripCost;
  final String currency;
  // proto TripSummary has energyPerKm, not energyUsedKwh — native hardcodes
  // this to 0.0 (see TripsClient.kt's own comment); reproduced as-is, not
  // fixed here (the task's own instruction: file a separate issue if this
  // looks like a bug, don't silently change displayed behaviour).
  final double energyKwh;

  const TripItem({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.distanceKm,
    required this.durationSeconds,
    required this.overallScore,
    required this.tripCost,
    required this.currency,
    required this.energyKwh,
  });

  String get formattedDate => DateFormat('MMM d, yyyy HH:mm').format(startTime);
  String get formattedDuration => formatTripDuration(durationSeconds);
}

/// [energyUsedKwh] is derived client-side as `energyPerKm * distanceKm` — TripSummary has no
/// direct kWh-consumed field, but that product IS the value (see TripDetailController's own
/// comment). Native's `TripsClient.fetchTripDetail` hardcodes this to 0.0 instead, reasoning
/// the field "doesn't exist"; that produced a permanently blank Energy tile on the trip detail
/// screen even when SoC and electric cost both showed real usage. Not reproduced here.
///
/// [efficiencySocPerKm] and [telemetryFilePath] stay hardcoded to 0.0 / empty, matching native —
/// the RPC response genuinely has no field for these (TripDetail/TripSummary proto messages
/// checked directly), and neither is currently rendered by this screen.
class TripDetailData {
  final int id;
  final DateTime startTime;
  final DateTime endTime;
  final double distanceKm;
  final int durationSeconds;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final double socStart;
  final double socEnd;
  final double energyUsedKwh;
  final double efficiencySocPerKm;
  final String currency;
  final double tripCost;
  final String gradientProfile;
  final double elevationGainM;
  final double elevationLossM;
  final double extTempC;
  final int anticipationScore;
  final int smoothnessScore;
  final int speedDisciplineScore;
  final int efficiencyScore;
  final int consistencyScore;
  final int overallScore;
  final String telemetryFilePath;

  /// Whether this trip recorded BOTH ends of the fuel counter.
  ///
  /// Derived from the STORED trip by the daemon, not from a live drivetrain probe, so a
  /// historical trip renders the same way on a car whose drivetrain reads differently today.
  /// On a BEV this is false and the fuel rows are not shown at all.
  final bool hasFuelData;

  /// Litres of petrol burned on this trip. A real 0 on a PHEV leg driven entirely on battery.
  final double litresUsed;

  /// The two halves of [tripCost]. They sum to it, so showing them is a breakdown rather than
  /// extra information — which is the point: the driver cannot otherwise tell which tank the
  /// money went to.
  final double fuelCost;
  final double electricCost;

  const TripDetailData({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.distanceKm,
    required this.durationSeconds,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.socStart,
    required this.socEnd,
    required this.energyUsedKwh,
    required this.efficiencySocPerKm,
    required this.currency,
    required this.tripCost,
    required this.gradientProfile,
    required this.elevationGainM,
    required this.elevationLossM,
    required this.extTempC,
    required this.anticipationScore,
    required this.smoothnessScore,
    required this.speedDisciplineScore,
    required this.efficiencyScore,
    required this.consistencyScore,
    required this.overallScore,
    required this.telemetryFilePath,
    this.hasFuelData = false,
    this.litresUsed = 0,
    this.fuelCost = 0,
    this.electricCost = 0,
  });

  String get formattedDateTitle => DateFormat('EEEE, MMMM d').format(startTime);
  String get formattedTimeRange => '${DateFormat('HH:mm').format(startTime)} – ${DateFormat('HH:mm').format(endTime)}';
  String get formattedDuration => formatTripDuration(durationSeconds);
}

class TelemetryPoint {
  final int timestampMs;
  final int speedKmh;
  final int accelPercent;
  final int brakePercent;
  final double lat;
  final double lon;

  const TelemetryPoint({
    required this.timestampMs,
    required this.speedKmh,
    required this.accelPercent,
    required this.brakePercent,
    required this.lat,
    required this.lon,
  });

  bool get hasGps => lat != 0.0 && lon != 0.0;
}

class TripsSummary {
  final int tripCount;
  final double totalDistanceKm;
  final int totalDurationSeconds;
  final double totalEnergyKwh;
  final double avgEnergyPerKm;
  final double avgEfficiency;

  const TripsSummary({
    required this.tripCount,
    required this.totalDistanceKm,
    required this.totalDurationSeconds,
    required this.totalEnergyKwh,
    required this.avgEnergyPerKm,
    required this.avgEfficiency,
  });

  String get formattedHours {
    final h = totalDurationSeconds ~/ 3600;
    final m = (totalDurationSeconds % 3600) ~/ 60;
    return '${h}h ${m}m';
  }
}

class DnaScores {
  final int anticipation;
  final int smoothness;
  final int speedDiscipline;
  final int efficiency;
  final int consistency;
  final int overall;

  const DnaScores({
    required this.anticipation,
    required this.smoothness,
    required this.speedDiscipline,
    required this.efficiency,
    required this.consistency,
    required this.overall,
  });

  /// Native's own comment: "Score out of 700 = sum of 7 axes, but we have 5
  /// with max 100 each = 500 max. Display as out of 500 to match the 5-axis
  /// DNA." [overall] (the proto's own field, scored against a different axis
  /// count) is shown separately, not folded into this — reproduced exactly.
  int get scoreOutOf500 => anticipation + smoothness + speedDiscipline + efficiency + consistency;
}

class RangeEstimate {
  final double estimatedKm;
  final double builtInKm;

  /// Predicted PHEV fuel range, or <= 0 when it cannot be computed.
  ///
  /// The daemon returns -1 (`FuelConsumption.CANNOT_PREDICT`) when the owner has not
  /// configured a tank capacity — BYD local data exposes no tank size, so without it the
  /// range genuinely cannot be derived and nothing is guessed. Callers gate on `> 0`, which
  /// covers both the sentinel and a plain absent field.
  final double fuelRangeKm;

  /// The car's own fuel-range readout, for comparison. The fuel twin of [builtInKm].
  final double builtInFuelRangeKm;

  const RangeEstimate({
    required this.estimatedKm,
    required this.builtInKm,
    this.fuelRangeKm = 0,
    this.builtInFuelRangeKm = 0,
  });
}

class TripsConfig {
  final bool enabled;
  final double electricityRate;

  /// Cost per litre for the PHEV fuel leg. 0 means NOT CONFIGURED — the litres burned are
  /// still recorded, they just cannot be costed.
  final double fuelPricePerL;

  /// Fuel tank capacity in litres. 0 means NOT CONFIGURED, and there is no default: BYD
  /// exposes no tank size, so without it the fuel range cannot be computed. A guessed
  /// capacity would put a wrong range on the dashboard, which is worse than a blank one.
  final double fuelTankCapacityL;

  /// Normally an ISO 4217 code; may be a bare symbol on configs predating the picker.
  final String currency;
  final String distanceUnit;

  /// Whether this vehicle has a fuel system at all.
  ///
  /// A live drivetrain read carried on the config, NOT a stored setting. See
  /// [showFuelSettings] for why it is not used as a bare hide/show flag.
  final bool isPhev;

  /// Whether the fuel settings are meaningful for THIS car.
  ///
  /// A BEV has no tank, so a fuel price and a tank capacity are not merely unused there — they
  /// read as a bug in the app.
  ///
  /// Deliberately not a bare [isPhev]. An already-configured value stays visible so it can be
  /// cleared: the drivetrain probe returns false while the HAL is warming up, and a PHEV owner
  /// who had set a fuel price must never find the field gone while the value is still being
  /// applied. Same principle as keeping a legacy currency in the picker.
  bool get showFuelSettings => isPhev || fuelPricePerL > 0 || fuelTankCapacityL > 0;

  const TripsConfig({
    required this.enabled,
    required this.electricityRate,
    this.fuelPricePerL = 0,
    this.fuelTankCapacityL = 0,
    this.isPhev = false,
    required this.currency,
    required this.distanceUnit,
  });
}

class TripsStorage {
  final String storageType;
  final int limitMb;
  final double usedMb;
  final String usedUnit;
  final bool sdCardAvailable;
  final int tripsCount;
  final String storagePath;

  const TripsStorage({
    required this.storageType,
    required this.limitMb,
    required this.usedMb,
    required this.usedUnit,
    required this.sdCardAvailable,
    required this.tripsCount,
    required this.storagePath,
  });
}

/// Result of [TripsController.syncDatabase] — structured, not a composed
/// English sentence (unlike native's `TripSyncResult.message`), so the
/// screen can render it through the ARB catalog. [error] is a raw
/// server-supplied message when the daemon rejected the sync (not a
/// hardcoded literal); the screen falls back to a generic localized string
/// when it's null, matching native's own `"Sync failed"` fallback.
class SyncOutcome {
  final bool success;
  final int added;
  final int removed;
  final int total;
  final String? error;

  const SyncOutcome({required this.success, this.added = 0, this.removed = 0, this.total = 0, this.error});
}

sealed class TripsLoadState {
  const TripsLoadState();
}

class TripsLoading extends TripsLoadState {
  const TripsLoading();
}

class TripsError extends TripsLoadState {
  final String message;
  const TripsError(this.message);
}

class TripsLoaded extends TripsLoadState {
  final List<TripItem> trips;
  final TripsSummary? summary;
  final DnaScores? dna;
  final RangeEstimate? range;
  final TripsConfig? config;
  final TripsStorage? storage;

  /// What the active period's trips cost, over the WHOLE period (BladeWatch-mgi9, -c149).
  final TripCosts costs;

  const TripsLoaded({
    required this.trips,
    required this.summary,
    required this.dna,
    required this.range,
    required this.config,
    required this.storage,
    this.costs = const TripCosts(),
  });
}

/// Miles in a kilometre.
const double kMilesPerKm = 0.621371;

/// Formats a distance in the user's chosen unit.
///
/// [unit] is `TripConfig.distanceUnit` as the daemon reports it — `'mi'` or
/// `'km'`. Anything else falls back to kilometres, which is what the daemon does
/// too (`HttpServer` defaults `distanceUnit` to `"km"` when the probe fails).
///
/// This exists because the conversion was inlined at five call sites and MISSED
/// at a sixth: the Trips → Stats range card rendered `'$km km'` unconditionally,
/// so a miles user saw their trips in `mi` and the range estimate in `km` on the
/// same screen.
String formatDistance(double km, String unit, {int decimals = 1}) => unit == 'mi'
    ? '${(km * kMilesPerKm).toStringAsFixed(decimals)} mi'
    : '${km.toStringAsFixed(decimals)} km';

/// Formats a speed in the user's chosen unit. Same [unit] values as
/// [formatDistance].
String formatSpeed(double kmh, String unit, {int decimals = 0}) => unit == 'mi'
    ? '${(kmh * kMilesPerKm).toStringAsFixed(decimals)} mph'
    : '${kmh.toStringAsFixed(decimals)} km/h';
