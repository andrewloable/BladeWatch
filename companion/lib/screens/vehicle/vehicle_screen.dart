import 'package:bladewatch_rpc/gen/bladewatch/v1/vehicle.pb.dart';
import 'package:bladewatch_rpc/rpc/services/vehicle_service_client.dart';
import 'package:flutter/material.dart';

import '../../car/car_page.dart';
import '../../car/car_session.dart';
import '../../i18n.dart';
import '../common/loader.dart';

/// Runs actuating VehicleService calls with the car's short-lived action token -- the second
/// factor the car requires from every remote caller (VehicleActionGate), cached for its
/// lifetime like the web's interceptor. The car's own safety interlock still decides; nothing
/// here can widen what it allows.
class VehicleActions {
  VehicleActions(this.session, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final CarSession session;
  final DateTime Function() _now;
  String? _token;
  DateTime _until = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> run(Future<VehicleCommandResponse> Function(VehicleServiceClient client) call) async {
    if (_token == null || !_now().isBefore(_until)) {
      final t = await VehicleServiceClient(session.rpc).issueActionToken(IssueActionTokenRequest());
      if (!t.success || t.token.isEmpty) throw VehicleRefused(t.error);
      _token = t.token;
      // A second early: a token that expires in transit reads as a refused command.
      _until = _now().add(Duration(seconds: (t.expiresInSeconds - 1).clamp(0, 3600)));
    }
    final r = await call(VehicleServiceClient(session.withHeaders({'X-Vehicle-Action-Token': _token!})));
    if (!r.success) throw VehicleRefused(r.error.isNotEmpty ? r.error : r.message);
  }
}

class VehicleRefused implements Exception {
  const VehicleRefused(this.reason);

  final String reason;

  @override
  String toString() => reason;
}

/// The web vehicle page's counterpart: state (doors, windows, battery, climate, tyres) polled
/// every 3 s, and climate and window controls. No seat controls: removed end to end
/// (BladeWatch-7bx4).
///
/// Remote-use safety: moving a window from a phone means nobody can see whether a hand or a pet
/// is in the way, so every window command asks first. Climate is reversible and harmless, so it
/// does not.
/// MoveWindow target openings offered per window: the web's presets.
const windowPresets = [0, 25, 50, 75, 100];

/// The sunroof and sunshade (BladeWatch-rdtj.69): BYD's one-touch close / half / open only, with no
/// position feedback, so the car sends 25 as a full close and 75 as a full open. The in-car app's
/// kSunPanelPresets (BladeWatch-b3n7).
const sunPanelPresets = [0, 50, 100];

/// Which of [sunPanelPresets] a panel at [pos]% lights, as the in-car app decides: closed (0-2%)
/// lights 0, any opening the nearest of 50 and 100 with ties to the higher, unknown (negative) none.
int? sunPanelPreset(int pos) => pos < 0 ? null : (pos <= 2 ? 0 : ((pos - 50).abs() < (pos - 100).abs() ? 50 : 100));

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> with LoadersState {
  late final _state = loader(() => VehicleServiceClient(context.session.rpc).getState(GetVehicleStateRequest()),
      poll: const Duration(seconds: 3));
  late final _actions = VehicleActions(context.session);
  String? _busy;

  Future<void> _do(String key, Future<VehicleCommandResponse> Function(VehicleServiceClient c) call) async {
    setState(() => _busy = key);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _actions.run(call);
      await _state.load();
    } catch (e) {
      final reason = e is VehicleRefused && e.reason.isNotEmpty ? e.reason : context.tr('errors.generic');
      say(messenger, reason);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  /// Every window command asks first: remote use means no one may be watching the glass. The
  /// car's own interlock still decides. [what] names the window and the target for a single one.
  Future<void> _windows(String key, MoveWindowRequest request, {String? what}) async {
    final tr = context.tr;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(what ?? tr('vehicle.windows'), key: const ValueKey('window.what')),
        content: Text(tr('companion.window_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('common.cancel'))),
          FilledButton(key: const ValueKey('window.confirm'), onPressed: () => Navigator.pop(context, true), child: Text(tr('common.ok'))),
        ],
      ),
    );
    if (yes == true) await _do(key, (c) => c.moveWindow(request));
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return LoaderView(
      loader: _state,
      builder: (context, s) {
        final busy = _busy != null;
        final c = s.climate;
        final b = s.battery;
        // range_km is the ELECTRIC range. The dashboard's "Range" is the total, so on a car with
        // a tank this one says so (BladeWatch-rdtj.47): 86 km here beside 442 km there read as
        // two answers to one question. The fuel fields are absent on a BEV.
        final fuel = b.fuelPercent > 0 || b.fuelRangeKm > 0;
        return PageList(children: [
          Section(title: tr('vehicle.title'), children: [
            InfoRow(tr('vehicle.lock'), s.doors.overall == 0 ? tr('vehicle.unlocked') : tr('companion.locked')),
            InfoRow(tr('vehicle.charge'), '${b.soc.toStringAsFixed(0)}%'),
            InfoRow(tr(fuel ? 'companion.week_elec_range' : 'vehicle.range'), '${b.rangeKm} km'),
            if (b.fuelPercent > 0) InfoRow(tr('vehicle.fuel'), '${b.fuelPercent.toStringAsFixed(0)}%'),
            if (b.fuelRangeKm > 0) InfoRow(tr('companion.week_fuel_range'), '${b.fuelRangeKm} km'),
          ]),
          Section(title: tr('vehicle.climate'), children: [
            if (!s.hasClimate()) Text(tr('vehicle.climate_unavailable')),
            if (s.hasClimate()) ...[
              SwitchListTile(
                key: const ValueKey('climate.ac'),
                title: Text(tr('vehicle.air_conditioning')),
                value: c.acOn,
                onChanged: busy
                    ? null
                    : (on) => _do('ac', (v) => v.setClimate(SetClimateRequest(action: on ? 'power_on' : 'power_off', setpointC: c.setpointC.roundToDouble()))),
              ),
              SwitchListTile(
                key: const ValueKey('climate.max'),
                title: Text(tr('vehicle.max_cooling')),
                value: c.maxCooling,
                onChanged: busy ? null : (on) => _do('max', (v) => v.setClimate(SetClimateRequest(action: 'max_cooling', on: on))),
              ),
              _Stepper(
                label: tr('vehicle.temperature'),
                value: '${c.setpointC.toStringAsFixed(0)} °C',
                enabled: !busy,
                keyName: 'temp',
                onStep: (d) => _do('temp', (v) => v.setClimate(
                    SetClimateRequest(action: 'set_temp', setpointC: (c.setpointC.round() + d).clamp(17, 33).toDouble()))),
              ),
              _Stepper(
                label: tr('vehicle.fan'),
                value: '${c.fanLevel}',
                enabled: !busy,
                keyName: 'fan',
                onStep: (d) => _do('fan', (v) => v.setClimate(SetClimateRequest(action: 'set_fan', fanLevel: (c.fanLevel + d).clamp(1, 7)))),
              ),
              if (c.hasOutsideTempC()) InfoRow(tr('vehicle.outside'), '${c.outsideTempC.toStringAsFixed(0)} °C'),
            ],
          ]),
          Section(title: tr('vehicle.windows'), children: [
            // One window to a set opening, as the web offers (BladeWatch-rdtj.46). Presets only,
            // each confirmed: nothing moves while a finger drags.
            for (final (idx, pos) in [(1, s.windows.lf), (2, s.windows.rf), (3, s.windows.lr), (4, s.windows.rr)]) ...[
              InfoRow(tr('companion.window_$idx'), '$pos%'),
              Wrap(spacing: 6, runSpacing: 4, children: [
                for (final p in windowPresets)
                  ChoiceChip(
                    key: ValueKey('window.$idx.$p'),
                    label: Text('$p%'),
                    // Within 5 points counts as there: the car reports the glass a little off its target.
                    selected: (pos - p).abs() <= 5,
                    onSelected: busy
                        ? null
                        : (_) => _windows('win-$idx-$p', MoveWindowRequest(windowIndex: idx, targetPercent: p),
                            what: tr('companion.window_to', {'window': tr('companion.window_$idx'), 'percent': p})),
                  ),
              ]),
            ],
            // The sunroof and sunshade, only when the car has them (window 5 and 6).
            for (final (idx, key, pos, has) in [
              (5, 'vehicle.sunroof', s.windows.sunroof, s.capabilities.windows.sunroof),
              (6, 'vehicle.sunshade', s.windows.sunshade, s.capabilities.windows.sunshade),
            ])
              if (has) ...[
                InfoRow(tr(key), pos < 0 ? '—' : '$pos%'),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  for (final p in sunPanelPresets)
                    ChoiceChip(
                      key: ValueKey('window.$idx.$p'),
                      label: Text('$p%'),
                      selected: sunPanelPreset(pos) == p,
                      onSelected: busy
                          ? null
                          : (_) => _windows('win-$idx-$p', MoveWindowRequest(windowIndex: idx, targetPercent: p),
                              what: tr('companion.window_to', {'window': tr(key), 'percent': p})),
                    ),
                ]),
              ],
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              OutlinedButton(
                key: const ValueKey('windows.close'),
                onPressed: busy ? null : () => _windows('all-close', MoveWindowRequest(windowIndex: 0, direction: 'close')),
                child: Text(tr('vehicle_control.close_all_windows_label')),
              ),
              OutlinedButton(
                key: const ValueKey('windows.vent'),
                onPressed: busy ? null : () => _windows('all-vent', MoveWindowRequest(windowIndex: 0, targetPercent: 12)),
                child: Text(tr('vehicle.vent')),
              ),
              OutlinedButton(
                key: const ValueKey('windows.open'),
                onPressed: busy ? null : () => _windows('all-open', MoveWindowRequest(windowIndex: 0, direction: 'open')),
                child: Text(tr('vehicle.open')),
              ),
            ]),
          ]),
          if (s.hasTyres())
            Section(title: tr('companion.tyres'), children: [
              for (final (name, t) in [('FL', s.tyres.fl), ('FR', s.tyres.fr), ('RL', s.tyres.rl), ('RR', s.tyres.rr)])
                InfoRow(name, '${t.psi.toStringAsFixed(1)} psi · ${t.tempC} °C${t.leakState > 0 ? ' · ${tr('vehicle.leak')}' : ''}'),
            ]),
        ]);
      },
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.value, required this.enabled, required this.keyName, required this.onStep});

  final String label;
  final String value;
  final bool enabled;
  final String keyName;
  final ValueChanged<int> onStep;

  // Tooltips name the action and the setting (BladeWatch-rdtj.54): a screen reader otherwise
  // announced a bare "button" for a control that changes the real car.
  //
  // maxLines/overflow (BladeWatch-rdtj.72.1, found on a real phone): ListTile shrinks its title
  // column to fit whatever trailing needs, and two IconButtons plus the value text left too
  // little room for "Temperature" -- Text has no overflow handling by default, so Flutter hard-
  // wrapped it mid-word ("Tempera"/"ture") instead of clipping. This is the guaranteed fix:
  // verified on the real phone this was found on, "Temperature" now ellipsizes cleanly
  // ("Tempera…") instead of breaking. visualDensity narrows the IconButtons' own 48dp default
  // tap targets, which helps but is not by itself enough to fit "Temperature" whole on that
  // device -- an ellipsis is the correct, expected outcome for the longest of this label's 17
  // translations (checked; none of the others is longer) on a narrow phone, not a residual bug.
  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            key: ValueKey('$keyName.down'),
            tooltip: context.tr('companion.step_down', {'name': label}),
            onPressed: enabled ? () => onStep(-1) : null,
            icon: const Icon(Icons.remove),
            visualDensity: VisualDensity.compact,
          ),
          Text(value),
          IconButton(
            key: ValueKey('$keyName.up'),
            tooltip: context.tr('companion.step_up', {'name': label}),
            onPressed: enabled ? () => onStep(1) : null,
            icon: const Icon(Icons.add),
            visualDensity: VisualDensity.compact,
          ),
        ]),
      );
}
