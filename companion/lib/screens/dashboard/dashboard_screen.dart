import 'package:bladewatch_rpc/gen/bladewatch/v1/system.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/trips.pb.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/trips_service_client.dart';
import 'package:bladewatch_rpc/trips/currency_symbols.dart';
import 'package:bladewatch_rpc/trips/trip_costs.dart';
import 'package:bladewatch_theme/hud_theme.dart';
import 'package:bladewatch_theme/hud_widgets.dart';
import 'package:flutter/material.dart';

import '../../car/car_page.dart';
import '../../i18n.dart';
import '../../transport/transport_selector.dart';
import '../common/format.dart';
import '../common/shell_nav.dart';
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
  // Every trip of the week, not the first page: the costs are a sum (BladeWatch-39d2). Reloaded
  // once a minute: it used to load only when the page opened, so a trip that ended while it was
  // up never showed (the owner's cadence, 2026-09-27; charge and fuel ride the 5 s status).
  late final _week = loader(
    () => listTripsInPeriod(TripsServiceClient(context.session.rpc).listTrips, 7),
    poll: const Duration(minutes: 1),
  );

  @override
  Widget build(BuildContext context) => LoaderView(
        loader: _status,
        builder: (context, s) => PageList(children: [
          _Chips(status: s),
          const SizedBox(height: 12),
          _Battery(status: s, system: _system),
          ListenableBuilder(listenable: _week, builder: (context, _) => _Week(trips: _week.value, status: s)),
        ]),
      );
}

/// The status chips. Each dot is REAL state (HUD rule 5): the recording dot is magenta and pulses only while the car
/// records, and an off or idle thing is a grey dot, never a coloured one.
class _Chips extends StatelessWidget {
  const _Chips({required this.status});

  final GetStatusResponse status;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final rec = status.recordingStatus;
    Widget chip(String label, HudDotState state, {Key? key, bool pulse = false}) =>
        _StatusChip(key: key, label: label, state: state, pulse: pulse);
    return Wrap(spacing: 8, runSpacing: 8, children: [
      chip(tr(context.session.phase == TransportPhase.lan ? 'companion.route_lan' : 'companion.route_pear'), HudDotState.ok,
          key: const ValueKey('dash.route')),
      chip(tr(rec.pipelineRunning ? 'dashboard.services_up' : 'dashboard.services_partial'),
          rec.pipelineRunning ? HudDotState.ok : HudDotState.warning),
      chip(tr(rec.isRecording ? 'dashboard.recording' : 'dashboard.idle'), rec.isRecording ? HudDotState.bad : HudDotState.idle,
          key: const ValueKey('dash.recording'), pulse: rec.isRecording),
      chip('${tr('status.acc')} ${tr(status.acc ? 'status.on' : 'status.off')}', status.acc ? HudDotState.ok : HudDotState.idle),
      if (status.inSafeZone) chip(status.safeZoneName.isEmpty ? tr('status.safe') : status.safeZoneName, HudDotState.ok),
    ]);
  }
}

/// A status chip: a 4 dp box, a state dot, an upper-case 12 dp label (not a button).
class _StatusChip extends StatelessWidget {
  const _StatusChip({super.key, required this.label, required this.state, this.pulse = false});

  final String label;
  final HudDotState state;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    final hud = BwHud.of(context);
    return HudPanel(
      color: hud.panel,
      borderColor: hud.chipBorder,
      radius: BwHud.radiusSmall,
      shadows: hud.tileShadow,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HudStatusDot(state, pulse: pulse),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label.toUpperCase(), style: hudText(12, hud.textSecondary, lineHeight: 16, weight: FontWeight.w700, em: 0.05)),
          ),
        ],
      ),
    );
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
  const _Week({required this.trips, required this.status});

  final List<TripSummary>? trips;
  final GetStatusResponse status;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final t = trips;
    final unit = status.distanceUnit;
    final range = status.range;
    // BladeWatch-4zr7: fuel only on a car with a tank. proto3 reads "absent" as zero, so a BEV
    // reports zero for both.
    final hasFuel = status.hasRange() && (range.fuelPercent > 0 || range.fuelRangeKm > 0);
    final km = t?.fold<double>(0, (a, e) => a + e.distanceKm) ?? 0;
    final secs = t?.fold<int>(0, (a, e) => a + e.durationSeconds) ?? 0;
    // BladeWatch-39d2: what the week cost, under the three it always showed. Fuel is left out
    // on a car that recorded none; no sum is given across currencies.
    final costs = t == null || t.isEmpty ? null : TripCosts.of(t);
    String money(double v) => CurrencySymbols.money(v, costs!.currency);
    final nav = ShellNav.of(context);
    return Section(
        title: tr('dashboard.this_week'),
        // To the week's trips, as the web's "View all trips" did (BladeWatch-rdtj.57).
        trailing: nav == null
            ? null
            : TextButton(key: const ValueKey('dash.allTrips'), onPressed: () => nav.go('trips'), child: Text(tr('companion.view_all_trips'))),
        children: [
      // The week's figures as the in-car card shows them: a value over its label, the first two cyan and the drive
      // time magenta, each scaled down before it would wrap.
      _StatRow(stats: [
        (t == null ? '—' : '${t.length}', tr('dashboard.trips'), _StatTone.info),
        (t == null ? '—' : Fmt.distance(km, unit: unit), tr('dashboard.distance'), _StatTone.info),
        (t == null ? '—' : Fmt.duration(secs), tr('dashboard.drive_time'), _StatTone.drive),
      ]),
      const SizedBox(height: 8),
      if (costs != null && costs.costed) ...[
        if (costs.hasFuel) InfoRow(tr('trips.fuel_cost'), money(costs.fuel)),
        InfoRow(tr('trips.electric_cost'), money(costs.electric)),
        InfoRow(tr('companion.total_cost'), money(costs.total)),
      ] else if (costs != null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(tr(costs.mixedCurrencies ? 'companion.costs_mixed_currency' : 'trip.cost_hint'),
              key: const ValueKey('week.costs.message')),
        ),
      // BladeWatch-4zr7: the car's charge and fuel now, after the week's figures (as the in-car card
      // has them since its design review: the week's rows stay together).
      if (status.hasSoc()) InfoRow(tr('companion.week_battery'), Fmt.percent(status.soc.percent)),
      if (status.hasRange()) InfoRow(tr('companion.week_elec_range'), Fmt.distance(range.elecRangeKm, unit: unit)),
      if (hasFuel) ...[
        InfoRow(tr('companion.week_fuel'), Fmt.percent(range.fuelPercent)),
        InfoRow(tr('companion.week_fuel_range'), Fmt.distance(range.fuelRangeKm, unit: unit)),
      ],
    ]);
  }
}

enum _StatTone { info, drive }

class _StatRow extends StatelessWidget {
  const _StatRow({required this.stats});

  final List<(String value, String label, _StatTone tone)> stats;

  @override
  Widget build(BuildContext context) {
    final hud = BwHud.of(context);
    final drive = _StatTone.drive;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final (value, label, tone) in stats)
        Expanded(
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  value,
                  maxLines: 1,
                  style: hudText(20, tone == drive ? hud.driveTimeValue : hud.textPrimary,
                      lineHeight: 28, weight: FontWeight.w700, em: -0.025, shadows: hudGlow(tone == drive ? hud.glowMagenta : hud.glowCyan)),
                ),
              ),
              Text(label,
                  style: hudText(12, tone == drive ? hud.magenta : hud.statLabel, lineHeight: 16, weight: hud.labelWeight, em: 0.05)),
            ]),
          ),
        ),
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
      // Scrolls at a large text size instead of overflowing (BladeWatch-rdtj.55).
      scrollable: true,
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
              // The web dialog's other two readings (BladeWatch-rdtj.57): the capacity the car uses
              // now, and where its health figure came from.
              InfoRow(tr('companion.capacity_current'), s == null || s.nominalCapacityKwh <= 0 ? '—' : '${s.nominalCapacityKwh.toStringAsFixed(1)} kWh'),
              InfoRow(tr('companion.soh_source'), s?.displaySource.isNotEmpty == true ? s!.displaySource : '—'),
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
