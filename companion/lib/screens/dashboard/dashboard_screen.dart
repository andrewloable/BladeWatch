import 'package:bladewatch_rpc/gen/bladewatch/v1/system.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/trips.pb.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/trips_service_client.dart';
import 'package:bladewatch_rpc/trips/trip_costs.dart';
import 'package:bladewatch_theme/hud_theme.dart';
import 'package:bladewatch_theme/hud_widgets.dart';
import 'package:flutter/material.dart';

import '../../car/car_page.dart';
import '../../i18n.dart';
import '../../transport/transport_selector.dart';
import '../common/energy_sizes.dart';
import '../common/format.dart';
import '../common/stats.dart';
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
  late final _trips = TripsServiceClient(context.session.rpc);
  late final _status = loader(() => _system.getStatus(GetStatusRequest()), poll: const Duration(seconds: 5));
  // Every trip of the week, not the first page: the costs are a sum (BladeWatch-39d2). Reloaded
  // once a minute: it used to load only when the page opened, so a trip that ended while it was
  // up never showed (the owner's cadence, 2026-09-27; charge and fuel ride the 5 s status).
  late final _week = loader(
    () => listTripsInPeriod(_trips.listTrips, 7),
    poll: const Duration(minutes: 1),
  );
  // Pack and tank size, for "77% / 14.1 kWh": they change only when the owner edits a setting.
  late final _sizes = loader(() => EnergySizes.load(context.session.rpc), poll: const Duration(minutes: 1));

  @override
  Widget build(BuildContext context) => LoaderView(
        loader: _status,
        builder: (context, s) => ListenableBuilder(
          listenable: Listenable.merge([_week, _sizes]),
          builder: (context, _) {
            final sizes = _sizes.value ?? EnergySizes.unknown;
            return PageList(children: [
              _Chips(status: s),
              const SizedBox(height: 12),
              _Vehicle(status: s, sizes: sizes),
              _Week(trips: _week.value, status: s),
            ]);
          },
        ),
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

/// The car now, as the in-car VEHICLE card shows it: a value over its label, two to a row, then
/// charging, health and the 12 V battery as plain rows. No SOC row (it is Battery) and no total
/// range (it is the two ranges added up, and the electric one on a BEV).
class _Vehicle extends StatelessWidget {
  const _Vehicle({required this.status, required this.sizes});

  final GetStatusResponse status;
  final EnergySizes sizes;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final s = status;
    final unit = s.distanceUnit;
    final range = s.range;
    // BladeWatch-4zr7: fuel only on a car with a tank. proto3 reads "absent" as zero, so a BEV
    // reports zero for both.
    final hasFuel = s.hasRange() && (range.fuelPercent > 0 || range.fuelRangeKm > 0);
    const plain = StatTone.plain;
    return Section(
      title: tr('dashboard.vehicle'),
      children: [
        if (!s.vehicleDataReady) Text(tr('status.waiting_vehicle')),
        if (s.hasSoc() || s.hasRange())
          StatGrid(rows: [
            [
              (s.hasSoc() ? Fmt.energy(s.soc.percent, sizes.packKwh, 'kWh', decimals: 1) : '—', tr('companion.week_battery'), plain),
              // "Range" on a BEV; on a car with a tank it says which one (BladeWatch-rdtj.47).
              (s.hasRange() ? Fmt.distance(range.elecRangeKm, unit: unit) : '—', tr(hasFuel ? 'companion.week_elec_range' : 'vehicle.range'), plain),
            ],
            if (hasFuel)
              [
                (Fmt.energy(range.fuelPercent, sizes.tankL, 'L'), tr('companion.week_fuel'), plain),
                (Fmt.distance(range.fuelRangeKm, unit: unit), tr('companion.week_fuel_range'), plain),
              ],
          ]),
        const SizedBox(height: 8),
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
    final km = t?.fold<double>(0, (a, e) => a + e.distanceKm) ?? 0;
    final secs = t?.fold<int>(0, (a, e) => a + e.durationSeconds) ?? 0;
    // BladeWatch-39d2: what the week cost, under the three it always showed. Fuel is left out
    // on a car that recorded none; no sum is given across currencies.
    final costs = t == null || t.isEmpty ? null : TripCosts.of(t);
    final costRow = costs == null ? null : costCells(costs, tr);
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
      StatGrid(rows: [
        [
          (t == null ? '—' : '${t.length}', tr('dashboard.trips'), StatTone.info),
          (t == null ? '—' : Fmt.distance(km, unit: unit), tr('dashboard.distance'), StatTone.info),
          (t == null ? '—' : Fmt.duration(secs), tr('dashboard.drive_time'), StatTone.drive),
        ],
        ?costRow,
      ]),
      if (costs != null && costRow == null) CostMessage(costs: costs),
    ]);
  }
}
