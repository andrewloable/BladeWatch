import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../gen/bladewatch/v1/system.pb.dart' as sys;
import '../../gen/bladewatch/v1/vehicle.pb.dart' as pb;
import '../../rpc/services/system_service_client.dart';
import '../../rpc/services/vehicle_service_client.dart';
import 'vehicle_models.dart';
import '../../shell/disposed_safe_notifier.dart';

/// Ground truth: `VehicleController.kt` (behaviour) + `VehicleClient.kt`
/// (RPC mapping). See `vehicle_models.dart`'s doc comment for why only
/// Climate/Seats/Windows are ported and which RPCs are in scope.
///
/// Deliberately not ported: `VehicleStateCache`'s disk-backed "stale but
/// instant first paint" cache (native's `filesDir/vehicle_state.json`).
/// Flutter has no access to native's private app storage regardless (it is
/// a separate APK/UID-shared-but-separate-process), and a from-scratch
/// equivalent would need a new platform channel for a pure UX nicety —
/// mirrors BladeWatch-yz1e.6's identical call on `LocationGpsCache`. This
/// screen simply starts in a loading state until the first live poll
/// succeeds, same graceful-degradation shape native itself falls back to
/// on a cold cache miss.
class VehicleController extends ChangeNotifier with DisposedSafeNotifier {
  VehicleController({
    required VehicleServiceClient vehicleService,
    required SystemServiceClient systemService,
    int Function()? nowMs,
  })  : _vehicleService = vehicleService, // ignore: prefer_initializing_formals
        _systemService = systemService, // ignore: prefer_initializing_formals
        _nowMs = nowMs ?? (() => DateTime.now().millisecondsSinceEpoch);

  final VehicleServiceClient _vehicleService;
  final SystemServiceClient _systemService;
  final int Function() _nowMs;

  static const _debounceMs = 600;

  VehicleState _state = const VehicleState();
  VehicleState get state => _state;

  bool _loading = true;
  bool get loading => _loading;

  int _failCount = 0;
  // Ground truth: native only surfaces an error after 3 consecutive poll
  // failures (`failCount >= 3`), avoiding an error flash on one transient
  // blip.
  bool get hasError => _failCount >= 3;

  // Local optimistic climate/seat state, synced from `_state` on every
  // successful poll — matches native's identical `applyStateToViews()` sync.
  bool _acOn = false;
  bool get acOn => _acOn;

  // BladeWatch-2000.3: no status field reports this -- SetScreen is fire-and-forget, so this
  // tracks only what the owner last asked for in this session, not the actual panel state.
  bool _screenOn = true;
  bool get screenOn => _screenOn;

  // BladeWatch-2000.2: unlike screenOn above, GetVehicleState DOES report this (the real
  // AudioManager stream state), so _fetchState below overwrites these with server truth on
  // every poll -- these are not a local-only guess.
  int _mediaVolumePercent = 0;
  int get mediaVolumePercent => _mediaVolumePercent;
  bool _mediaMuted = false;
  bool get mediaMuted => _mediaMuted;
  int _setpointC = 22;
  int get setpointC => _setpointC;
  int _fanLevel = 3;
  int get fanLevel => _fanLevel;
  bool _maxCooling = false;
  bool get maxCooling => _maxCooling;
  int _driverHeat = 0;
  int get driverHeat => _driverHeat;
  int _driverVent = 0;
  int get driverVent => _driverVent;
  int _passengerHeat = 0;
  int get passengerHeat => _passengerHeat;
  int _passengerVent = 0;
  int get passengerVent => _passengerVent;

  final Map<String, bool> _inFlight = {};
  bool isPending(String key) => _inFlight[key] == true;

  final Map<String, int> _lastClick = {};

  bool _debounce(String key) {
    final now = _nowMs();
    final last = _lastClick[key] ?? 0;
    if (now - last < _debounceMs) return false;
    _lastClick[key] = now;
    return true;
  }

  // Appearance state.
  List<ModelEntry> _manifestModels = const [];
  List<ModelEntry> get manifestModels => _manifestModels;
  String _selectedModelId = kDefaultModelId;
  String get selectedModelId => _selectedModelId;
  String _selectedColor = kDefaultColor;
  String get selectedColor => _selectedColor;

  String get selectedModelFile => _manifestModels.firstWhere((m) => m.id == _selectedModelId, orElse: () => const ModelEntry(id: '', name: '', file: kFallbackModelFile, bundled: true)).file;

  ModelEntry? get selectedModelEntry {
    if (_manifestModels.isEmpty) return null;
    return _manifestModels.firstWhere((m) => m.id == _selectedModelId, orElse: () => _manifestModels.first);
  }

  Future<void> load() async {
    await _fetchState();
    _loading = false;
    notifyListeners();
  }

  Future<void> poll() async {
    await _fetchState();
    notifyListeners();
  }

  Future<void> _fetchState() async {
    try {
      final resp = await _vehicleService.getState(pb.GetVehicleStateRequest());
      if (!resp.success) {
        _registerFailure();
        return;
      }
      final m = resp;
      final newState = VehicleState(
        doors: DoorState(overall: m.doors.overall, lf: m.doors.lf, rf: m.doors.rf, lr: m.doors.lr, rr: m.doors.rr),
        windows: WindowState(
          lf: _sanitizeWindow(m.windows.lf),
          rf: _sanitizeWindow(m.windows.rf),
          lr: _sanitizeWindow(m.windows.lr),
          rr: _sanitizeWindow(m.windows.rr),
          sunroof: _sanitizeWindow(m.windows.sunroof),
          sunshade: _sanitizeWindow(m.windows.sunshade),
        ),
        capabilities: VehicleCapabilities(
          windows: WindowCapabilities(sunroof: m.capabilities.windows.sunroof, sunshade: m.capabilities.windows.sunshade),
          seats: SeatCapabilities(
            driverHeat: m.capabilities.seats.driverHeat,
            passengerHeat: m.capabilities.seats.passengerHeat,
            driverCool: m.capabilities.seats.driverCool,
            passengerCool: m.capabilities.seats.passengerCool,
            driverMemoryRecall: m.capabilities.seats.driverMemoryRecall,
          ),
        ),
        battery: BatteryInfo(
          soc: m.battery.soc.toInt(),
          rangeKm: m.battery.rangeKm,
          fuelPercent: m.battery.fuelPercent.toInt(),
          fuelRangeKm: m.battery.fuelRangeKm,
        ),
        seats: SeatsInfo(heat: m.seats.heat.toList(), cool: m.seats.cool.toList()),
        climate: ClimateInfo(
          acOn: m.climate.acOn,
          setpointC: m.climate.setpointC.toInt().clamp(16, 35),
          insideTempC: m.climate.insideTempC != 0.0 ? m.climate.insideTempC : null,
          fanLevel: m.climate.fanLevel.clamp(1, 7),
          maxCooling: m.climate.maxCooling,
        ),
        tyres: TyreSetInfo(fl: _mapTyre(m.tyres.fl), fr: _mapTyre(m.tyres.fr), rl: _mapTyre(m.tyres.rl), rr: _mapTyre(m.tyres.rr)),
        loaded: true,
      );
      _state = newState;
      _failCount = 0;
      // Sync local optimistic state from the freshly-polled server truth —
      // matches native's applyStateToViews() overwriting any pending edits.
      _driverHeat = newState.seats.heat.isNotEmpty ? newState.seats.heat[0] : 0;
      _passengerHeat = newState.seats.heat.length > 1 ? newState.seats.heat[1] : 0;
      _driverVent = newState.seats.cool.isNotEmpty ? newState.seats.cool[0] : 0;
      _passengerVent = newState.seats.cool.length > 1 ? newState.seats.cool[1] : 0;
      _acOn = newState.climate.acOn;
      _setpointC = newState.climate.setpointC;
      _fanLevel = newState.climate.fanLevel;
      _maxCooling = newState.climate.maxCooling;
      _mediaVolumePercent = m.mediaVolumePercent.clamp(0, 100);
      _mediaMuted = m.mediaMuted;
    } catch (_) {
      _registerFailure();
    }
  }

  void _registerFailure() {
    _failCount++;
  }

  static int _sanitizeWindow(int v) => (v == 255 || v < -1) ? -1 : v;

  static TyreInfo _mapTyre(pb.TyrePressure t) => TyreInfo(
        psi: t.psi != 0.0 ? t.psi : null,
        kPa: t.kPa != 0 ? t.kPa : null,
        temperatureC: t.tempC != 0 ? t.tempC : null,
        pressureState: t.pressureState,
        airLeakState: t.leakState,
        signalState: t.signalState,
      );

  static VehicleCommandResult _mapCommand(pb.VehicleCommandResponse m) =>
      VehicleCommandResult(ok: m.success, outcome: m.outcome.isNotEmpty ? m.outcome : null, message: m.message.isNotEmpty ? m.message : null);

  // ─────────────────────────── Appearance ───────────────────────────────

  Future<void> loadAppearance() async {
    VehicleAppearance? appearance;
    try {
      final resp = await _systemService.getSelectedModel(sys.GetSelectedModelRequest());
      if (resp.modelId.isNotEmpty || resp.color.isNotEmpty) {
        appearance = VehicleAppearance(modelId: resp.modelId, color: resp.color);
      }
    } catch (_) {}
    try {
      final resp = await _systemService.getModelsManifest(sys.GetModelsManifestRequest());
      final obj = jsonDecode(resp.manifestJson) as Map<String, dynamic>;
      final models = (obj['models'] as List).cast<Map<String, dynamic>>();
      _manifestModels = models
          .map((m) => ModelEntry(
                id: m['id'] as String,
                name: m['name'] as String,
                file: (m['file'] as String?) ?? '${m['id']}.glb',
                bundled: (m['bundled'] as bool?) ?? false,
              ))
          .toList();
    } catch (_) {
      _manifestModels = const [];
    }
    if (appearance != null) {
      if (appearance.color.isNotEmpty) _selectedColor = appearance.color;
      if (appearance.modelId.isNotEmpty) _selectedModelId = appearance.modelId;
    }
    notifyListeners();
  }

  /// Returns an error message to show, or null on success.
  ///
  /// SetSelectedModel answers with `ok`/`error`, NOT the success/message shape the
  /// vehicle commands use. BladeWatch-p7vi fixed this same RPC in
  /// `vehicle_dialog_controller.dart` and missed this call site, so the swatch
  /// stayed selected whether or not the daemon accepted it. There is no
  /// reconciling reload here to paper over it.
  Future<String?> selectColor(String hex) async {
    if (hex == _selectedColor) return null;
    final previous = _selectedColor;
    _selectedColor = hex;
    notifyListeners();
    return _persistAppearance(
      () => sys.SetSelectedModelRequest(color: hex),
      () => _selectedColor = previous,
    );
  }

  Future<String?> selectModel(String id) async {
    if (id == _selectedModelId) return null;
    final previous = _selectedModelId;
    _selectedModelId = id;
    notifyListeners();
    return _persistAppearance(
      () => sys.SetSelectedModelRequest(modelId: id),
      () => _selectedModelId = previous,
    );
  }

  Future<String?> _persistAppearance(
    sys.SetSelectedModelRequest Function() request,
    void Function() revert,
  ) async {
    try {
      final resp = await _systemService.setSelectedModel(request());
      if (!resp.ok) {
        revert();
        notifyListeners();
        // Empty, NOT null: a refusal with no reason is still a refusal, and
        // returning null made the caller treat it as success and show nothing
        // while the swatch snapped back. The screen substitutes
        // `vehicle_action_failed` for a blank message.
        return resp.error;
      }
    } catch (e) {
      revert();
      notifyListeners();
      return e.toString();
    }
    return null;
  }

  // ─────────────────────────── Climate ────────────────────────────────

  /// Returns an error message to show, or null on success. Reverts the
  /// optimistic update on failure — matches native's AC-toggle handler.
  Future<String?> toggleAc() async {
    if (!_debounce('ac_toggle')) return null;
    final nowOn = !_acOn;
    _acOn = nowOn;
    notifyListeners();
    try {
      final resp = nowOn ? await _vehicleService.setClimate(_climateOnRequest(_setpointC)) : await _vehicleService.setClimate(_climateOffRequest());
      final result = _mapCommand(resp);
      if (!result.ok) {
        _acOn = !nowOn;
        notifyListeners();
        return result.failure;
      }
    } catch (e) {
      _acOn = !nowOn;
      notifyListeners();
      return '$e';
    }
    return null;
  }

  /// BladeWatch-2000.3: turning the screen off while moving is refused server-side
  /// (VehicleCommandRouter's motion interlock); turning it back on always succeeds. Reverts
  /// the optimistic update on any failure, same shape as [toggleAc].
  Future<String?> toggleScreen() async {
    if (!_debounce('screen_toggle')) return null;
    final nowOn = !_screenOn;
    _screenOn = nowOn;
    notifyListeners();
    try {
      final resp = await _vehicleService.setScreen(pb.SetScreenRequest(on: nowOn));
      final result = _mapCommand(resp);
      if (!result.ok) {
        _screenOn = !nowOn;
        notifyListeners();
        return result.failure;
      }
    } catch (e) {
      _screenOn = !nowOn;
      notifyListeners();
      return '$e';
    }
    return null;
  }

  // ─────────────────────────── Media volume (BladeWatch-2000.2) ────────────────────────

  /// [beforePercent]/[beforeMuted] must be captured by the caller BEFORE its own optimistic
  /// update -- capturing them in here would capture the value the caller already changed it
  /// to, making the revert-on-failure below a no-op (caught by this issue's own tests).
  Future<String?> _sendVolumeAction(String action, int beforePercent, bool beforeMuted, {int? percent}) async {
    try {
      final resp = await _vehicleService
          .setMediaVolume(pb.SetMediaVolumeRequest(action: action, percent: percent));
      final result = _mapCommand(resp);
      if (!result.ok) {
        _mediaVolumePercent = beforePercent;
        _mediaMuted = beforeMuted;
        notifyListeners();
        return result.failure;
      }
    } catch (e) {
      _mediaVolumePercent = beforePercent;
      _mediaMuted = beforeMuted;
      notifyListeners();
      return '$e';
    }
    return null;
  }

  /// Optimistic step matching the daemon's own MediaVolumeController.STEP_PERCENT; the next
  /// poll corrects this to the real server value via _fetchState, same as the climate
  /// temp/fan steppers.
  static const int _volumeStepPercent = 5;

  // No setMediaVolumePercent here: this screen offers a stepper, not a slider, so nothing
  // calls it. The daemon's POST /api/vehicle/media-volume still accepts {"action": "set",
  // "percent": n} for the web UI — add the wrapper back when a slider needs it.

  Future<String?> stepVolumeUp() async {
    if (!_debounce('volume_step')) return null;
    final beforePercent = _mediaVolumePercent;
    final beforeMuted = _mediaMuted;
    _mediaVolumePercent = (_mediaVolumePercent + _volumeStepPercent).clamp(0, 100);
    notifyListeners();
    return _sendVolumeAction('step_up', beforePercent, beforeMuted);
  }

  Future<String?> stepVolumeDown() async {
    if (!_debounce('volume_step')) return null;
    final beforePercent = _mediaVolumePercent;
    final beforeMuted = _mediaMuted;
    _mediaVolumePercent = (_mediaVolumePercent - _volumeStepPercent).clamp(0, 100);
    notifyListeners();
    return _sendVolumeAction('step_down', beforePercent, beforeMuted);
  }

  Future<String?> toggleMute() async {
    if (!_debounce('volume_mute')) return null;
    final beforePercent = _mediaVolumePercent;
    final wasMuted = _mediaMuted;
    _mediaMuted = !wasMuted;
    notifyListeners();
    return _sendVolumeAction(wasMuted ? 'unmute' : 'mute', beforePercent, wasMuted);
  }

  // ─────────────────────────── Defrosters (BladeWatch-2000.1) ──────────────────────────
  // No status field reports these (see BladeWatch-2000.1's own close reason for why wind
  // mode/cycle mode have no UI at all) -- fire-and-forget, same as screenOn in
  // BladeWatch-2000.3.

  bool _frontDefrostOn = false;
  bool get frontDefrostOn => _frontDefrostOn;
  bool _rearDefrostOn = false;
  bool get rearDefrostOn => _rearDefrostOn;

  Future<String?> toggleFrontDefrost() async {
    if (!_debounce('front_defrost')) return null;
    final nowOn = !_frontDefrostOn;
    _frontDefrostOn = nowOn;
    notifyListeners();
    try {
      final resp = await _vehicleService.setClimate(pb.SetClimateRequest(action: 'front_defrost', on: nowOn));
      final result = _mapCommand(resp);
      if (!result.ok) {
        _frontDefrostOn = !nowOn;
        notifyListeners();
        return result.failure;
      }
    } catch (e) {
      _frontDefrostOn = !nowOn;
      notifyListeners();
      return '$e';
    }
    return null;
  }

  Future<String?> toggleRearDefrost() async {
    if (!_debounce('rear_defrost')) return null;
    final nowOn = !_rearDefrostOn;
    _rearDefrostOn = nowOn;
    notifyListeners();
    try {
      final resp = await _vehicleService.setClimate(pb.SetClimateRequest(action: 'rear_defrost', on: nowOn));
      final result = _mapCommand(resp);
      if (!result.ok) {
        _rearDefrostOn = !nowOn;
        notifyListeners();
        return result.failure;
      }
    } catch (e) {
      _rearDefrostOn = !nowOn;
      notifyListeners();
      return '$e';
    }
    return null;
  }

  /// Matches native's `climateMaxCooling`: captures the pre-toggle
  /// ac/temp/fan as restore values, and on a successful *enable* locally
  /// jumps the displayed temp/fan to 17C/level 7 (the BYD max-cooling
  /// setpoint) ahead of the next poll confirming it server-side.
  Future<String?> toggleMaxCooling() async {
    if (!_debounce('max_cooling')) return null;
    final restoreAcOn = _acOn;
    final restoreTemp = _setpointC;
    final restoreFan = _fanLevel;
    final nowMax = !_maxCooling;
    _maxCooling = nowMax;
    notifyListeners();
    try {
      final resp = await _vehicleService.setClimate(pb.SetClimateRequest(
        action: 'max_cooling',
        maxCooling: nowMax,
        restoreAcOn: restoreAcOn,
        restoreTempC: restoreTemp.toDouble(),
        restoreFanLevel: restoreFan,
      ));
      final result = _mapCommand(resp);
      if (!result.ok) {
        _maxCooling = !nowMax;
        notifyListeners();
        return result.failure;
      } else if (nowMax) {
        _acOn = true;
        _setpointC = 17;
        _fanLevel = 7;
        notifyListeners();
      }
    } catch (e) {
      _maxCooling = !nowMax;
      notifyListeners();
      return '$e';
    }
    return null;
  }

  /// Fire-and-forget, like native's temp stepper: no error feedback, no
  /// revert on failure.
  /// One climate stepper press: apply optimistically, send, and REVERT if the
  /// car refused.
  ///
  /// The refusal path is the one that was missing. The daemon answers HTTP 200
  /// with `success:false` when a command is declined, so nothing throws — the old
  /// code's `catch (_) {}` never ran and the optimistic value stayed on screen.
  /// This is the same defect BladeWatch-p7vi fixed on the SoH writes.
  Future<String?> _stepClimate({
    required void Function() apply,
    required void Function() revert,
    required pb.SetClimateRequest Function() request,
  }) async {
    apply();
    notifyListeners();
    try {
      final result = _mapCommand(await _vehicleService.setClimate(request()));
      if (!result.ok) {
        revert();
        notifyListeners();
        // Same as toggleAc/toggleMaxCooling: return whatever the daemon said.
        // A refusal with no message still reverts, and the value snapping
        // back IS the feedback.
        return result.failure;
      }
    } catch (e) {
      revert();
      notifyListeners();
      return e.toString();
    }
    return null;
  }

  Future<String?> incTemp() async {
    if (!_debounce('temp_plus') || _setpointC >= 33) return null;
    return _stepClimate(
      apply: () => _setpointC += 1,
      revert: () => _setpointC -= 1,
      request: () => pb.SetClimateRequest(action: 'set_temp', setpointC: _setpointC.toDouble()),
    );
  }

  Future<String?> decTemp() async {
    if (!_debounce('temp_minus') || _setpointC <= 17) return null;
    return _stepClimate(
      apply: () => _setpointC -= 1,
      revert: () => _setpointC += 1,
      request: () => pb.SetClimateRequest(action: 'set_temp', setpointC: _setpointC.toDouble()),
    );
  }

  Future<String?> incFan() async {
    if (!_debounce('fan_plus') || _fanLevel >= 7) return null;
    return _stepClimate(
      apply: () => _fanLevel += 1,
      revert: () => _fanLevel -= 1,
      request: () => pb.SetClimateRequest(action: 'set_fan', fanLevel: _fanLevel),
    );
  }

  Future<String?> decFan() async {
    if (!_debounce('fan_minus') || _fanLevel <= 1) return null;
    return _stepClimate(
      apply: () => _fanLevel -= 1,
      revert: () => _fanLevel += 1,
      request: () => pb.SetClimateRequest(action: 'set_fan', fanLevel: _fanLevel),
    );
  }

  static pb.SetClimateRequest _climateOnRequest(int temp) => pb.SetClimateRequest(action: 'power_on', on: true, setpointC: temp.toDouble());
  static pb.SetClimateRequest _climateOffRequest() => pb.SetClimateRequest(action: 'power_off', on: false);

  // ─────────────────────────── Seats ──────────────────────────────────

  /// Fire-and-forget cycle 0->1->2->0, like native's seat heat/cool
  /// buttons: no error feedback, no revert on failure. Heat and vent are
  /// mutually exclusive per seat (enabling one zeroes the other).
  Future<String?> cycleSeatHeat(int position) async {
    final key = 'seat_heat_$position';
    if (!_debounce(key)) return null;
    // Snapshot all four: a heat press can clear vent and vice versa, so
    // reverting only the pressed field would leave the other one wrong.
    final before = [_driverHeat, _driverVent, _passengerHeat, _passengerVent];
    final current = position == 1 ? _driverHeat : _passengerHeat;
    final newLevel = (current + 1) % 3;
    if (position == 1) {
      _driverHeat = newLevel;
      if (newLevel > 0) _driverVent = 0;
    } else {
      _passengerHeat = newLevel;
      if (newLevel > 0) _passengerVent = 0;
    }
    notifyListeners();
    void revert() {
      _driverHeat = before[0];
      _driverVent = before[1];
      _passengerHeat = before[2];
      _passengerVent = before[3];
      notifyListeners();
    }
    try {
      final result = _mapCommand(await _vehicleService.setSeat(pb.SetSeatRequest(
        seatIndex: position,
        action: 'heating',
        level: newLevel,
        driverHeat: _driverHeat,
        driverVent: _driverVent,
        passengerHeat: _passengerHeat,
        passengerVent: _passengerVent,
      )));
      if (!result.ok) {
        revert();
        return result.failure;
      }
    } catch (e) {
      revert();
      return e.toString();
    }
    return null;
  }

  Future<String?> cycleSeatCool(int position) async {
    final key = 'seat_cool_$position';
    if (!_debounce(key)) return null;
    // Snapshot all four: a heat press can clear vent and vice versa, so
    // reverting only the pressed field would leave the other one wrong.
    final before = [_driverHeat, _driverVent, _passengerHeat, _passengerVent];
    final current = position == 1 ? _driverVent : _passengerVent;
    final newLevel = (current + 1) % 3;
    if (position == 1) {
      _driverVent = newLevel;
      if (newLevel > 0) _driverHeat = 0;
    } else {
      _passengerVent = newLevel;
      if (newLevel > 0) _passengerHeat = 0;
    }
    notifyListeners();
    void revert() {
      _driverHeat = before[0];
      _driverVent = before[1];
      _passengerHeat = before[2];
      _passengerVent = before[3];
      notifyListeners();
    }
    try {
      final result = _mapCommand(await _vehicleService.setSeat(pb.SetSeatRequest(
        seatIndex: position,
        action: 'ventilation',
        level: newLevel,
        driverHeat: _driverHeat,
        driverVent: _driverVent,
        passengerHeat: _passengerHeat,
        passengerVent: _passengerVent,
      )));
      if (!result.ok) {
        revert();
        return result.failure;
      }
    } catch (e) {
      revert();
      return e.toString();
    }
    return null;
  }

  /// Uses the pending/inFlight-tracked pattern (native: `doVehicleAction`) —
  /// unlike the heat/cool cycle buttons above, memory recall shows a
  /// pending state and surfaces a failure message.
  Future<String?> recallSeatPosition(int position) async {
    final key = 'seat_mem$position';
    return _doAction(key, () async {
      final resp = await _vehicleService.setSeat(pb.SetSeatRequest(seatIndex: position, action: 'position'));
      return _mapCommand(resp);
    });
  }

  // ─────────────────────────── Windows ────────────────────────────────

  Future<String?> setWindowPercent(int area, int pct) => _doAction('win_${area}_$pct', () async {
        final resp = await _vehicleService.moveWindow(pb.MoveWindowRequest(windowIndex: area, targetPercent: pct));
        return _mapCommand(resp);
      });

  Future<String?> closeAllWindows() => _doAction('win_all_close', () async {
        final resp = await _vehicleService.moveWindow(pb.MoveWindowRequest(windowIndex: 0, direction: 'close'));
        return _mapCommand(resp);
      });

  Future<String?> openAllWindows() => _doAction('win_all_open', () async {
        final resp = await _vehicleService.moveWindow(pb.MoveWindowRequest(windowIndex: 0, direction: 'open'));
        return _mapCommand(resp);
      });

  Future<String?> ventAllWindows(int targetPercent) => _doAction('win_vent', () async {
        final resp = await _vehicleService.moveWindow(pb.MoveWindowRequest(windowIndex: 0, targetPercent: targetPercent));
        return _mapCommand(resp);
      });

  /// Ground truth: `doVehicleAction()` — debounce, mark pending, run the
  /// action, clear pending, return an error message on failure (null on
  /// success) for the widget to show.
  Future<String?> _doAction(String key, Future<VehicleCommandResult> Function() action) async {
    if (!_debounce(key)) return null;
    if (_inFlight[key] == true) return null;
    _inFlight[key] = true;
    notifyListeners();
    String? error;
    try {
      final result = await action();
      if (!result.ok) error = result.failure;
    } catch (e) {
      error = '$e';
    }
    _inFlight.remove(key);
    notifyListeners();
    return error;
  }
}
