/// Ground truth: `VehicleModels.kt` + `VehicleFormatters.kt`.
///
/// Only CLIMATE/SEATS/WINDOWS are ported — `VehicleTab` originally also had
/// TRUNK/LIGHTS/ADAS/CHARGING (and `VehiclePanels.kt` still has complete,
/// RPC-backed `build*Tab()` functions for all four), but commit `59c3b91`
/// ("update vehicle UI to enhance climate control and window management
/// features", 2026-06-12) deliberately removed them from `VehicleTab` and
/// `renderTabContent()`'s dispatch — confirmed both by that commit's diff
/// (a clean, matched 4-line enum removal + 6-line `when`-arm removal, not
/// leftover cruft) and by the baseline reference screenshots
/// (`screenshots/native/05_vehicle.png`/`05b_vehicle_windows.png`), which
/// show only Climate/Windows (Seats hidden — this test vehicle reports no
/// seat capabilities). The task's own "8 tabs" description predates that
/// commit. This port matches native's CURRENT, deliberately-trimmed
/// behavior, not the stale description — see docs/build-and-operations.md
/// for the full evidence trail.
///
/// Similarly, `VehicleService` has RPCs for Lock/Unlock/Flash/FindCar/
/// SetBatteryHeat/charging-schedule/GPS that `VehicleClient.kt` (the
/// Vehicle screen's own RPC mapping) never calls at all — those belong to
/// other screens or nothing at all, not this one. Only the RPCs
/// `VehicleClient.kt` actually calls are ported: GetState, MoveWindow,
/// SetClimate, SetSeat, plus SystemService's GetSelectedModel/
/// SetSelectedModel/GetModelsManifest for appearance.
enum VehicleTab { climate, seats, windows }

enum TyreTier { muted, alert, warn, caution, normal }

/// Same presets as native's `VehicleController.COLOR_PRESETS` (sRGB hex).
/// Names are ARB-resolved at the widget layer (native hardcodes English
/// here too, but this port's "no hardcoded literals" rule is stricter —
/// see `surveillance`'s equivalent note); this list carries only the wire
/// hex values, matching how `surveillance_models.dart` keeps fixed option
/// lists as plain constants rather than an enum with no native counterpart.
const List<String> kColorPresetHexes = ['#E8E8EC', '#1A1A1E', '#1E3A5F', '#1B4D3E', '#C8102E', '#5C5C66'];
const String kDefaultColor = '#E8E8EC';
// Seal 5 DM-i — shares destroyer.glb with Destroyer 05 in the manifest.
const String kDefaultModelId = 'seal5-dmi-dynamic';
const String kFallbackModelFile = 'destroyer.glb';

// Door lock: 1=locked, 2=unlocked, -1=unknown.
class DoorState {
  final int overall;
  final int lf;
  final int rf;
  final int lr;
  final int rr;

  const DoorState({this.overall = -1, this.lf = -1, this.rf = -1, this.lr = -1, this.rr = -1});
}

// Window: 0=closed, 100=fully open, -1=unknown.
class WindowState {
  final int lf;
  final int rf;
  final int lr;
  final int rr;
  final int sunroof;
  final int sunshade;

  const WindowState({this.lf = -1, this.rf = -1, this.lr = -1, this.rr = -1, this.sunroof = -1, this.sunshade = -1});
}

class WindowCapabilities {
  final bool sunroof;
  final bool sunshade;

  const WindowCapabilities({this.sunroof = false, this.sunshade = false});
}

class SeatCapabilities {
  final bool driverHeat;
  final bool passengerHeat;
  final bool driverCool;
  final bool passengerCool;
  final bool driverMemoryRecall;

  const SeatCapabilities({
    this.driverHeat = false,
    this.passengerHeat = false,
    this.driverCool = false,
    this.passengerCool = false,
    this.driverMemoryRecall = false,
  });

  bool get anyAvailable => driverHeat || passengerHeat || driverCool || passengerCool || driverMemoryRecall;
}

class VehicleCapabilities {
  final WindowCapabilities windows;
  final SeatCapabilities seats;

  const VehicleCapabilities({this.windows = const WindowCapabilities(), this.seats = const SeatCapabilities()});
}

class BatteryInfo {
  final int soc;
  final int rangeKm;

  const BatteryInfo({this.soc = 0, this.rangeKm = 0});
}

class SeatsInfo {
  // [driver, passenger], each 0-2.
  final List<int> heat;
  final List<int> cool;

  const SeatsInfo({this.heat = const [0, 0], this.cool = const [0, 0]});
}

class ClimateInfo {
  final bool acOn;
  final int setpointC;
  final double? insideTempC;
  final int fanLevel;
  final bool maxCooling;

  const ClimateInfo({this.acOn = false, this.setpointC = 22, this.insideTempC, this.fanLevel = 3, this.maxCooling = false});
}

class TyreInfo {
  final double? psi;
  final int? kPa;
  final int? temperatureC;
  final int pressureState;
  final int airLeakState;
  final int signalState;

  const TyreInfo({this.psi, this.kPa, this.temperatureC, this.pressureState = 0, this.airLeakState = 0, this.signalState = 0});
}

class TyreSetInfo {
  final TyreInfo fl;
  final TyreInfo fr;
  final TyreInfo rl;
  final TyreInfo rr;

  const TyreSetInfo({this.fl = const TyreInfo(), this.fr = const TyreInfo(), this.rl = const TyreInfo(), this.rr = const TyreInfo()});
}

class VehicleCommandResult {
  final bool ok;
  final String? outcome;
  final String? message;

  const VehicleCommandResult({required this.ok, this.outcome, this.message});
}

class ModelEntry {
  final String id;
  final String name;
  final String file;
  final bool bundled;

  const ModelEntry({required this.id, required this.name, required this.file, required this.bundled});
}

class VehicleAppearance {
  final String modelId;
  final String color;

  const VehicleAppearance({required this.modelId, required this.color});
}

class VehicleState {
  final DoorState doors;
  final WindowState windows;
  final VehicleCapabilities capabilities;
  final BatteryInfo battery;
  final SeatsInfo seats;
  final ClimateInfo climate;
  final TyreSetInfo tyres;
  final bool loaded;

  const VehicleState({
    this.doors = const DoorState(),
    this.windows = const WindowState(),
    this.capabilities = const VehicleCapabilities(),
    this.battery = const BatteryInfo(),
    this.seats = const SeatsInfo(),
    this.climate = const ClimateInfo(),
    this.tyres = const TyreSetInfo(),
    this.loaded = false,
  });
}

const List<int> _kWindowPresets = [0, 25, 50, 75, 100];

/// Returns the nearest window preset if `current` is within +/-10 of it,
/// else null. Returns null for unknown (-1) or any negative value.
int? presetFor(int current) {
  if (current < 0) return null;
  final nearest = _kWindowPresets.reduce((a, b) => (current - a).abs() <= (current - b).abs() ? a : b);
  return (nearest - current).abs() <= 10 ? nearest : null;
}

/// Maps a [TyreInfo] to a visual tier. Priority order:
///   muted   - no signal (signalState != 0) or no PSI data
///   alert   - air leak detected (airLeakState >= 1) or PSI < 22 (flat)
///   warn    - TPMS hardware flagged pressure anomaly (pressureState >= 1)
///   caution - PSI out of normal range (< 34 or > 45) without hardware flag
///   normal  - PSI 34-45 and all sensors clear
TyreTier tyreTier(TyreInfo t) {
  if (t.signalState != 0 || t.psi == null) return TyreTier.muted;
  if (t.airLeakState >= 1 || t.psi! < 22.0) return TyreTier.alert;
  if (t.pressureState >= 1) return TyreTier.warn;
  if (t.psi! < 34.0 || t.psi! > 45.0) return TyreTier.caution;
  return TyreTier.normal;
}
