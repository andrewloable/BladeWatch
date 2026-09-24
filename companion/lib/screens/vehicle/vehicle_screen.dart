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

/// The web vehicle page's counterpart: state (doors, windows, battery, climate, seats, tyres)
/// polled every 3 s, and climate, seat and window controls.
///
/// Remote-use safety: moving a window from a phone means nobody can see whether a hand or a pet
/// is in the way, so every window command asks first. Climate and seats are reversible and
/// harmless, so they do not.
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

  Future<void> _windows(String key, MoveWindowRequest request) async {
    final tr = context.tr;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('vehicle.windows')),
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
        int level(List<int> l, int i) => i < l.length ? l[i] : 0;
        String seatLabel(int l) => [tr('vehicle.off'), tr('vehicle.level_low'), tr('vehicle.level_high')][l.clamp(0, 2)];
        Widget seat(String label, String key, int current, int seatIndex, String action, SetSeatRequest Function(int next) build) =>
            ListTile(
              key: ValueKey('seat.$key'),
              title: Text(label),
              trailing: Text(seatLabel(current)),
              enabled: !busy,
              onTap: () => _do(key, (v) => v.setSeat(build((current + 1) % 3))),
            );
        final heat = s.seats.heat;
        final cool = s.seats.cool;
        SetSeatRequest seatReq(int seatIndex, String action, int next, {int? dh, int? ph, int? dv, int? pv}) => SetSeatRequest(
              seatIndex: seatIndex,
              action: action,
              level: next,
              driverHeat: dh ?? level(heat, 0),
              passengerHeat: ph ?? level(heat, 1),
              driverVent: dv ?? level(cool, 0),
              passengerVent: pv ?? level(cool, 1),
            );
        return PageList(children: [
          Section(title: tr('vehicle.title'), children: [
            InfoRow(tr('vehicle.lock'), s.doors.overall == 0 ? tr('vehicle.unlocked') : tr('companion.locked')),
            InfoRow(tr('vehicle.charge'), '${s.battery.soc.toStringAsFixed(0)}%'),
            InfoRow(tr('vehicle.range'), '${s.battery.rangeKm} km'),
            if (s.battery.fuelPercent > 0) InfoRow(tr('vehicle.fuel'), '${s.battery.fuelPercent.toStringAsFixed(0)}%'),
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
              InfoRow(tr('vehicle.cabin'), '${c.insideTempC.toStringAsFixed(0)} °C'),
            ],
          ]),
          Section(title: tr('vehicle.seats'), children: [
            seat('${tr('vehicle.driver')} · ${tr('vehicle.heat')}', 'driver-heat', level(heat, 0), 1, 'heating',
                (n) => seatReq(1, 'heating', n, dh: n)),
            seat('${tr('vehicle.passenger')} · ${tr('vehicle.heat')}', 'passenger-heat', level(heat, 1), 2, 'heating',
                (n) => seatReq(2, 'heating', n, ph: n)),
            if (s.seats.ventilatedSupported) ...[
              seat('${tr('vehicle.driver')} · ${tr('vehicle.cool_vent')}', 'driver-vent', level(cool, 0), 1, 'ventilation',
                  (n) => seatReq(1, 'ventilation', n, dv: n)),
              seat('${tr('vehicle.passenger')} · ${tr('vehicle.cool_vent')}', 'passenger-vent', level(cool, 1), 2, 'ventilation',
                  (n) => seatReq(2, 'ventilation', n, pv: n)),
            ],
          ]),
          Section(title: tr('vehicle.windows'), children: [
            for (final (idx, pos) in [(1, s.windows.lf), (2, s.windows.rf), (3, s.windows.lr), (4, s.windows.rr)])
              InfoRow(tr('companion.window_$idx'), '$pos%'),
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

  @override
  Widget build(BuildContext context) => ListTile(
        title: Text(label),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(key: ValueKey('$keyName.down'), onPressed: enabled ? () => onStep(-1) : null, icon: const Icon(Icons.remove)),
          Text(value),
          IconButton(key: ValueKey('$keyName.up'), onPressed: enabled ? () => onStep(1) : null, icon: const Icon(Icons.add)),
        ]),
      );
}
