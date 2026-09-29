/// Ground truth: `VehicleModels.kt` + `VehicleFormatters.kt`.
///
/// Only CLIMATE/WINDOWS are ported (seat control was removed end to end,
/// BladeWatch-7bx4) — `VehicleTab` originally also had
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
/// SetClimate, plus SystemService's GetSelectedModel/
/// SetSelectedModel/GetModelsManifest for appearance.
enum VehicleTab { climate, windows }

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

class VehicleCapabilities {
  final WindowCapabilities windows;

  const VehicleCapabilities({this.windows = const WindowCapabilities()});
}

class BatteryInfo {
  final int soc;
  final int rangeKm;

  /// PHEV tank level, 0-100, and the fuel range beside it. Both are 0 on a BEV
  /// because the daemon OMITS them there rather than sending a zero (see
  /// BatteryStatus in vehicle.proto) — so 0 means "no fuel system", which is
  /// exactly the condition for hiding the fuel readout.
  final int fuelPercent;
  final int fuelRangeKm;

  /// Whether this car has a fuel system worth showing a readout for.
  ///
  /// Derived from the data rather than from a drivetrain flag: a PHEV whose HAL
  /// has not answered yet looks like a BEV for a moment, which is the right
  /// behaviour — better a missing row than a "0%" tank on a car that has one.
  bool get hasFuel => fuelPercent > 0 || fuelRangeKm > 0;

  const BatteryInfo({this.soc = 0, this.rangeKm = 0, this.fuelPercent = 0, this.fuelRangeKm = 0});
}

class ClimateInfo {
  final bool acOn;
  final int setpointC;
  /// Outside air. The car exposes no cabin temperature (BladeWatch-eh3u).
  final double? outsideTempC;
  final int fanLevel;
  final bool maxCooling;

  const ClimateInfo({this.acOn = false, this.setpointC = 22, this.outsideTempC, this.fanLevel = 3, this.maxCooling = false});
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

  /// The reason to show for a refused command — never null.
  ///
  /// The daemon can refuse with an EMPTY message, and `_mapCommand` maps an
  /// empty message to null. So `return result.message` handed the caller null,
  /// and every call site reads null as success: the command had already been
  /// reverted, so the control visibly snapped back with NO explanation. That
  /// applied to the AC toggle, temperature and fan.
  ///
  /// Falls back to `outcome`, then to the empty string, which
  /// `showVehicleCommandError` renders as the localised
  /// `vehicle_action_failed`. The window path used to end in a hardcoded
  /// English 'failed' instead, which no locale could translate.
  String get failure => message ?? outcome ?? '';
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
  final ClimateInfo climate;
  final TyreSetInfo tyres;
  final bool loaded;

  const VehicleState({
    this.doors = const DoorState(),
    this.windows = const WindowState(),
    this.capabilities = const VehicleCapabilities(),
    this.battery = const BatteryInfo(),
    this.climate = const ClimateInfo(),
    this.tyres = const TyreSetInfo(),
    this.loaded = false,
  });
}

const List<int> kWindowPresets = [0, 25, 50, 75, 100];

/// The sunroof and sunshade have only BYD's one-touch close / half / open: there is no
/// position feedback to stop at 25 or 75, so moveWindowToPercent sends 25 as a full CLOSE and
/// 75 as a full OPEN. Offer only what the panel does (BladeWatch-b3n7).
const List<int> kSunPanelPresets = [0, 50, 100];

/// The presets a window area offers: 1-4 are the side windows, 5 the sunroof, 6 the sunshade.
List<int> presetsForArea(int area) => area >= 5 ? kSunPanelPresets : kWindowPresets;

/// Which of [presets] a window at [current]% highlights. Closed (0-2%) lights the first
/// (0%); any open window lights the NEAREST opening preset, ties to the higher one; unknown
/// (negative) lights nothing.
///
/// It used to light a preset only within +/-10 of it, so a vented window (Vent 12% lands at
/// 14-16%) lit 25% at 15% and nothing at 14%: four windows after one command showed two
/// states (BladeWatch-rm6p). An open window must never read as closed either.
int? presetFor(int current, [List<int> presets = kWindowPresets]) {
  if (current < 0) return null;
  if (current <= 2) return presets.first;
  return presets.skip(1).reduce((a, b) => (current - a).abs() < (current - b).abs() ? a : b);
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
