import 'package:bladewatch_rpc/gen/bladewatch/v1/system.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/trips.pb.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/trips_service_client.dart';
import 'package:bladewatch_theme/color_tokens.dart';
import 'package:flutter/material.dart';

import '../../car/car_page.dart';
import '../../i18n.dart';
import '../../transport/transport_selector.dart';
import '../common/format.dart';
import '../common/loader.dart';

/// The web dashboard's counterpart: how the car is reached, whether it is recording, its battery,
/// and this week's driving. Status refreshes every 5 s, like the web page.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with LoadersState {
  late final _system = SystemServiceClient(context.session.rpc);
  late final _status = loader(() => _system.getStatus(GetStatusRequest()), poll: const Duration(seconds: 5));
  late final _week = loader(() => TripsServiceClient(context.session.rpc).listTrips(ListTripsRequest(days: 7, limit: 100)));

  @override
  Widget build(BuildContext context) => LoaderView(
        loader: _status,
        builder: (context, s) => PageList(children: [
          _Chips(status: s),
          const SizedBox(height: 12),
          _Battery(status: s, system: _system),
          ListenableBuilder(listenable: _week, builder: (context, _) => _Week(trips: _week.value?.trips, unit: s.distanceUnit)),
        ]),
      );
}

class _Chips extends StatelessWidget {
  const _Chips({required this.status});

  final GetStatusResponse status;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final colors = Theme.of(context).extension<BwStatusColors>()!;
    final rec = status.recordingStatus;
    Widget chip(String label, Color color, {Key? key}) => Chip(
          key: key,
          avatar: Icon(Icons.circle, size: 10, color: color),
          label: Text(label),
        );
    return Wrap(spacing: 8, runSpacing: 8, children: [
      chip(tr(context.session.phase == TransportPhase.lan ? 'companion.route_lan' : 'companion.route_pear'), colors.success,
          key: const ValueKey('dash.route')),
      chip(tr(rec.pipelineRunning ? 'dashboard.services_up' : 'dashboard.services_partial'),
          rec.pipelineRunning ? colors.success : colors.warning),
      chip(tr(rec.isRecording ? 'dashboard.recording' : 'dashboard.idle'), rec.isRecording ? colors.danger : colors.info,
          key: const ValueKey('dash.recording')),
      chip('${tr('status.acc')} ${tr(status.acc ? 'status.on' : 'status.off')}', status.acc ? colors.success : colors.info),
      if (status.inSafeZone) chip(status.safeZoneName.isEmpty ? tr('status.safe') : status.safeZoneName, colors.info),
    ]);
  }
}

class _Battery extends StatelessWidget {
  const _Battery({required this.status, required this.system});

  final GetStatusResponse status;
  final SystemServiceClient system;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final s = status;
    return Section(
      title: tr('dashboard.vehicle'),
      trailing: TextButton(
        key: const ValueKey('dash.capacity'),
        onPressed: () => showDialog<void>(context: context, builder: (_) => TrScope(tr: tr, child: _CapacityDialog(system: system))),
        child: Text(tr('dashboard.battery_capacity')),
      ),
      children: [
        if (!s.vehicleDataReady) Text(tr('status.waiting_vehicle')),
        if (s.hasSoc()) InfoRow('SOC', Fmt.percent(s.soc.percent)),
        if (s.hasRange() && s.range.totalRangeKm > 0) InfoRow(tr('companion.range'), Fmt.distance(s.range.totalRangeKm, unit: s.distanceUnit)),
        if (s.hasCharging() && s.charging.stateName.isNotEmpty) InfoRow(tr('companion.charging'), s.charging.stateName),
        if (s.hasSoh() && s.soh.percent > 0) InfoRow(tr('dashboard.state_of_health'), '${s.soh.percent.toStringAsFixed(1)}%'),
        if (s.battery.level.isNotEmpty) InfoRow(tr('status.battery_12v'), s.battery.level),
      ],
    );
  }
}

class _Week extends StatelessWidget {
  const _Week({required this.trips, required this.unit});

  final List<TripSummary>? trips;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final t = trips;
    final km = t?.fold<double>(0, (a, e) => a + e.distanceKm) ?? 0;
    final secs = t?.fold<int>(0, (a, e) => a + e.durationSeconds) ?? 0;
    return Section(title: tr('dashboard.this_week'), children: [
      InfoRow(tr('dashboard.trips'), t == null ? '—' : '${t.length}'),
      InfoRow(tr('dashboard.distance'), t == null ? '—' : Fmt.distance(km, unit: unit)),
      InfoRow(tr('dashboard.drive_time'), t == null ? '—' : Fmt.duration(secs)),
    ]);
  }
}

/// Nominal battery capacity, which State of Health is measured against.
class _CapacityDialog extends StatefulWidget {
  const _CapacityDialog({required this.system});

  final SystemServiceClient system;

  @override
  State<_CapacityDialog> createState() => _CapacityDialogState();
}

class _CapacityDialogState extends State<_CapacityDialog> with LoadersState {
  late final _soh = loader(() => widget.system.getSohStatus(GetSohStatusRequest()));
  final _input = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _save({bool reset = false}) async {
    final tr = context.tr;
    final kwh = double.tryParse(_input.text.trim());
    if (!reset && (kwh == null || kwh < 8 || kwh > 120)) {
      setState(() => _message = tr('companion.capacity_range'));
      return;
    }
    try {
      final r = await widget.system.setSohNominal(reset ? SetSohNominalRequest() : SetSohNominalRequest(nominalKwh: kwh));
      setState(() => _message = r.success ? tr('toast.saved') : (r.error.isEmpty ? tr('errors.save_failed') : r.error));
      await _soh.load();
    } catch (_) {
      setState(() => _message = tr('errors.save_failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return AlertDialog(
      title: Text(tr('dashboard.battery_capacity')),
      content: SizedBox(
        width: 360,
        child: ListenableBuilder(
          listenable: _soh,
          builder: (context, _) {
            final s = _soh.value;
            if (s != null && _input.text.isEmpty && s.nominalCapacityKwh > 0) _input.text = s.nominalCapacityKwh.toStringAsFixed(1);
            return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(tr('dashboard.battery_capacity_desc')),
              const SizedBox(height: 12),
              InfoRow(tr('dashboard.state_of_health'), s == null || s.displaySoh <= 0 ? '—' : '${s.displaySoh.toStringAsFixed(1)}%'),
              InfoRow(tr('dashboard.source'), s?.nominalSource.isNotEmpty == true ? s!.nominalSource : '—'),
              TextField(
                key: const ValueKey('capacity.input'),
                controller: _input,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: tr('dashboard.nominal_capacity_kwh')),
              ),
              if (_message != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_message!, key: const ValueKey('capacity.message'))),
            ]);
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('dashboard.close'))),
        TextButton(key: const ValueKey('capacity.reset'), onPressed: () => _save(reset: true), child: Text(tr('dashboard.reset'))),
        FilledButton(key: const ValueKey('capacity.save'), onPressed: _save, child: Text(tr('dashboard.save'))),
      ],
    );
  }
}
