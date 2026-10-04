import 'dart:convert';

import 'package:bladewatch_rpc/gen/bladewatch/v1/trips.pb.dart';
import 'package:bladewatch_rpc/rpc/services/trips_service_client.dart';
import 'package:bladewatch_rpc/trips/currency_symbols.dart';
import 'package:bladewatch_rpc/trips/trip_costs.dart';
import 'package:bladewatch_theme/dimens_tokens.dart';
import 'package:bladewatch_theme/hud_theme.dart';
import 'package:bladewatch_theme/hud_widgets.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../car/car_page.dart';
import '../../i18n.dart';
import '../common/car_map.dart';
import '../common/format.dart';
import '../common/hud_style.dart';
import '../common/loader.dart';
import '../common/stats.dart';

/// Totals over the car's weekly rollups (GetSummary.rollup_json), as the in-car Trips page sums
/// them (flutter_ui trips_controller.dart _toSummary).
class PeriodSummary {
  const PeriodSummary(this.trips, this.km, this.seconds, this.kwh, this.efficiency, [this.kwhPerKm = 0]);

  final int trips;
  final double km;
  final int seconds;
  final double kwh;
  final double efficiency;

  /// The rollups' avgEnergyPerKm, averaged as the in-car page does; x 100 is its kWh/100km.
  final double kwhPerKm;

  /// "1h 15m", and "0h 23m" under an hour, as the in-car period summary writes it.
  String get hours => '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';

  static PeriodSummary? of(List<WeeklyRollupEntry> entries) {
    var trips = 0, seconds = 0, n = 0;
    var km = 0.0, kwh = 0.0, eff = 0.0, perKm = 0.0;
    num v(Map<String, dynamic> r, String k) => (r[k] as num?) ?? 0;
    for (final e in entries) {
      final Map<String, dynamic> r;
      try {
        r = jsonDecode(e.rollupJson) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }
      n++;
      trips += v(r, 'tripCount').toInt();
      km += v(r, 'totalDistanceKm');
      seconds += v(r, 'totalDurationSeconds').toInt();
      kwh += v(r, 'totalEnergyKwh');
      // The 0-100 score, NOT avgEfficiency: that is the car's legacy SoC-delta-per-km figure,
      // which reads 0 whenever a trip's integer SoC% did not visibly drop, and showed a week
      // of driving as "1%" (BladeWatch-rdtj.41).
      eff += v(r, 'avgEfficiencyScore');
      perKm += v(r, 'avgEnergyPerKm');
    }
    // Divided by every entry, unreadable ones too, as the in-car page does, so both show the
    // same number for the same week.
    return n == 0 ? null : PeriodSummary(trips, km, seconds, kwh, eff / entries.length, perKm / entries.length);
  }
}

/// GetRange.range_json: the learned range and the car's own, for electricity and fuel, -1 meaning
/// "cannot predict".
({double estimated, double builtIn, double fuel, double builtInFuel})? parseRange(String json) {
  if (json.isEmpty) return null;
  try {
    final d = jsonDecode(json) as Map<String, dynamic>;
    final r = (d['range'] as Map<String, dynamic>?) ?? d;
    double n(String k) => ((r[k] as num?) ?? 0).toDouble().clamp(0, double.infinity);
    final out = (
      estimated: n('predictedRangeKm'),
      builtIn: n('builtInRangeKm'),
      fuel: n('fuelRangeKm'),
      builtInFuel: n('builtInFuelRangeKm'),
    );
    return out.estimated == 0 && out.builtIn == 0 && out.fuel == 0 ? null : out;
  } catch (_) {
    return null;
  }
}

/// The owner's distance unit from the trip config; km when it cannot be read.
Future<String> distanceUnit(TripsServiceClient client) async {
  try {
    return (await client.getConfig(GetConfigRequest())).config.distanceUnit;
  } catch (_) {
    return 'km';
  }
}

/// The in-car Trips page's counterpart, showing what it shows (the owner, 2026-10-04): the period
/// summary with its costs, each trip with its cost, route and scores, then the driver score, learned
/// range, the period's cost and driving DNA; and the trip settings, which the car keeps in Settings.
/// One period (7, 14 or 30 days, the car's choices) drives the list and the Stats cost card alike.
class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  var _days = 7;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: BwDimens.pagePaddingHorizontal),
          child: ContentWidth(
            child: TabBar(tabs: [Tab(text: tr('trips.tab_trips')), Tab(text: tr('trips.tab_stats')), Tab(text: tr('trips.tab_storage'))]),
          ),
        ),
        Expanded(
          child: TabBarView(children: [
            _TripList(days: _days, onDays: (d) => setState(() => _days = d)),
            _Stats(days: _days),
            const TripSettingsForm(),
          ]),
        ),
      ]),
    );
  }
}

class _TripList extends StatefulWidget {
  const _TripList({required this.days, required this.onDays});

  final int days;
  final ValueChanged<int> onDays;

  @override
  State<_TripList> createState() => _TripListState();
}

class _TripListState extends State<_TripList> with LoadersState {
  late final _client = TripsServiceClient(context.session.rpc);
  late final _list = loader(() async {
    final days = widget.days;
    final trips = await _client.listTrips(ListTripsRequest(days: days, limit: 100));
    return (
      trips: trips,
      summary: await _client.getSummary(GetSummaryRequest(days: days)),
      unit: await distanceUnit(_client),
      // Costs are a sum over the whole period (BladeWatch-mgi9, -c149) and the list is its first
      // page: page on only when that page came back full.
      costs: TripCosts.of(trips.trips.length < 100 ? trips.trips : await listTripsInPeriod(_client.listTrips, days)),
    );
  });

  @override
  void didUpdateWidget(_TripList old) {
    super.didUpdateWidget(old);
    if (old.days != widget.days) _list.load();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final hud = BwHud.of(context);
    const plain = StatTone.plain;
    // The page gutter is outside ContentWidth, so rows are exactly the content width and line up with the title bar.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: BwDimens.pagePaddingHorizontal),
      child: ContentWidth(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            // One row that scrolls, as the car has it: wrapped, "30 Days" sat alone on a second line.
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (final d in const [7, 14, 30])
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      showCheckmark: false,
                      key: ValueKey('trips.days.$d'),
                      label: Text(tr('trips.days', {'count': d})),
                      selected: widget.days == d,
                      onSelected: (_) => widget.onDays(d),
                    ),
                  ),
              ]),
            ),
          ),
          Expanded(
            child: LoaderView(
              loader: _list,
              builder: (context, v) {
                final sum = PeriodSummary.of(v.summary.summary);
                final costRow = costCells(v.costs, tr);
                return ListView(padding: const EdgeInsets.only(bottom: BwDimens.pagePaddingBottom), children: [
                  // The in-car period summary: three columns of a value over its label, then the costs.
                  if (sum != null)
                    Section(title: tr('trips.period_summary'), children: [
                      StatGrid(center: true, rows: [
                        [
                          ('${sum.trips}', tr('trips.tab_trips'), plain),
                          (sum.hours, tr('trips.hours'), plain),
                          (sum.kwh.toStringAsFixed(1), tr('trips.kwh'), plain),
                        ],
                        [
                          (Fmt.distance(sum.km, unit: v.unit), tr('trips.distance'), plain),
                          ('${sum.efficiency.toStringAsFixed(0)}%', tr('trips.efficiency'), plain),
                          ((sum.kwhPerKm * 100).toStringAsFixed(2), tr('trips.kwh_per_100km'), plain),
                        ],
                        ?costRow,
                      ]),
                      if (costRow == null) CostMessage(costs: v.costs),
                    ]),
                  if (v.trips.trips.isEmpty)
                    Padding(padding: const EdgeInsets.all(32), child: HudEmptyState(icon: Icons.route, message: tr('trips.no_trips_recorded'))),
                  for (final t in v.trips.trips)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: HudListRow(
                        key: ValueKey('trip.${t.id}'),
                        title: Fmt.dateTime(t.startTime, tr.lang),
                        subtitle: [
                          Fmt.distance(t.distanceKm, unit: v.unit),
                          Fmt.duration(t.durationSeconds),
                          if (t.tripCost > 0 && t.currency.isNotEmpty) Fmt.money(t.tripCost, t.currency),
                        ].join(' · '),
                        trailing: t.overallScore > 0 ? _ScoreBadge(t.overallScore, hud) : null,
                        onTap: () async {
                          final deleted = await Navigator.of(context).push<bool>(MaterialPageRoute(
                            builder: (_) => TrScope(tr: tr, child: SessionScope(session: context.session, child: TripDetailScreen(id: t.id))),
                          ));
                          if (deleted == true) await _list.load();
                        },
                      ),
                    ),
                ]);
              },
            ),
          ),
        ]),
      ),
    );
  }
}

/// A trip's overall score, coloured by its real band as the in-car Trips does: 70 and up the accent, 40 and up amber,
/// below that the attention magenta.
class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge(this.score, this.hud);

  final int score;
  final BwHud hud;

  @override
  Widget build(BuildContext context) {
    final color = score >= 70 ? hud.accent : (score >= 40 ? hud.warning : hud.magenta);
    return HudPanel(
      color: hud.panel,
      borderColor: color,
      radius: BwHud.radiusSmall,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text('$score', style: hudText(12, color, lineHeight: 16, weight: FontWeight.w700)),
    );
  }
}

/// One trip: its numbers, route and scores. Pops true when it was deleted.
class TripDetailScreen extends StatefulWidget {
  const TripDetailScreen({super.key, required this.id});

  final Int64 id;

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> with LoadersState {
  late final _client = TripsServiceClient(context.session.rpc);
  late final _trip = loader(() async => (
        trip: await _client.getTrip(GetTripRequest(id: widget.id)),
        trace: await _client.getGpsTrace(GetGpsTraceRequest(tripId: widget.id)),
        unit: await distanceUnit(_client),
      ));

  Future<void> _delete() async {
    final tr = context.tr;
    final navigator = Navigator.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(tr('trip.delete_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('common.cancel'))),
          FilledButton(
            key: const ValueKey('trip.delete.confirm'),
            style: destructiveStyle(context),
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('common.delete')),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    if (await act(context, () => _client.deleteTrip(DeleteTripRequest(id: widget.id)), failed: tr('errors.delete_failed'))) {
      navigator.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final hud = BwHud.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: HudTitleBar(
              title: tr('trips.trip_summary').toUpperCase(),
              onBack: () => Navigator.of(context).maybePop(),
              backTooltip: MaterialLocalizations.of(context).backButtonTooltip,
              // Destructive: the attention colour.
              trailing: IconButton(
                key: const ValueKey('trip.delete'),
                tooltip: tr('trips.delete'),
                icon: const Icon(Icons.delete_outline),
                color: hud.magenta,
                onPressed: _delete,
              ),
            ),
          ),
          Expanded(child: _body(context)),
        ]),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final tr = context.tr;
    final hud = BwHud.of(context);
    return LoaderView(
        loader: _trip,
        builder: (context, v) {
          final d = v.trip.trip;
          final s = d.summary;
          final route = [for (final p in v.trace.gps) LatLng(p.lat, p.lon)];
          return PageList(children: [
            SizedBox(
              height: 280,
              child: route.length > 1
                  ? CarMap(center: route.first, route: route, markers: [route.first, route.last])
                  : HudPanel(color: hud.panel, borderColor: hud.panelBorder, child: Center(child: Text(tr('trips.no_route_data')))),
            ),
            const SizedBox(height: 12),
            Section(title: Fmt.dateTime(s.startTime, tr.lang), children: [
              InfoRow(tr('trips.distance'), Fmt.distance(s.distanceKm, unit: v.unit)),
              InfoRow(tr('trips.duration'), Fmt.duration(s.durationSeconds)),
              // Energy per km x distance, as the in-car detail works it out (the RPC carries no total).
              if (s.energyPerKm * s.distanceKm > 0)
                InfoRow(tr('companion.energy'), '${(s.energyPerKm * s.distanceKm).toStringAsFixed(1)}${Fmt.nbsp}kWh'),
              InfoRow(tr('trips.avg_speed'), Fmt.speed(s.avgSpeedKmh, unit: v.unit)),
              InfoRow(tr('trips.max_speed'), Fmt.speed(s.maxSpeedKmh.toDouble(), unit: v.unit)),
              InfoRow(tr('trips.soc'), '${s.socStart.toStringAsFixed(0)}% → ${s.socEnd.toStringAsFixed(0)}%'),
              if (s.tripCost > 0) InfoRow(tr('trips.cost'), Fmt.money(s.tripCost, s.currency)),
              // Which tank the money came out of (BladeWatch-rdtj.48): the two halves of the cost
              // above, on a trip that recorded the fuel counter.
              if (s.hasFuelData) ...[
                InfoRow(tr('trips.fuel_cost'), Fmt.money(s.fuelCost, s.currency)),
                InfoRow(tr('trips.electric_cost'), Fmt.money(s.electricCost, s.currency)),
                InfoRow(tr('trips.fuel_used'), '${s.litresUsed.toStringAsFixed(1)} ${tr('trips.litres_short')}'),
              ],
              if (s.extTempC != 0) InfoRow(tr('trips.ext_temp'), '${s.extTempC} °C'),
              if (d.elevationGainM > 0) InfoRow(tr('trips.elev_gain'), '+${d.elevationGainM.toStringAsFixed(0)} m'),
            ]),
            // The in-car detail's score bars, coloured by band; the overall score stays on top.
            if (s.overallScore > 0)
              Section(title: tr('trips.driving_scores'), children: [
                InfoRow(tr('trips.overall'), '${s.overallScore}'),
                ScoreBars(banded: true, bars: [
                  (tr('companion.score_anticipation'), d.anticipationScore),
                  (tr('companion.score_smoothness'), d.smoothnessScore),
                  (tr('companion.score_speed'), d.speedDisciplineScore),
                  (tr('trips.efficiency'), d.efficiencyScore),
                  (tr('companion.score_consistency'), d.consistencyScore),
                ]),
              ]),
          ]);
        },
    );
  }
}

class _Stats extends StatefulWidget {
  const _Stats({required this.days});

  /// The Trips tab's period, for the cost card (the in-car Stats tab follows its filter too).
  final int days;

  @override
  State<_Stats> createState() => _StatsState();
}

class _StatsState extends State<_Stats> with LoadersState {
  late final _client = TripsServiceClient(context.session.rpc);
  late final _stats = loader(() async => (
        range: await _client.getRange(GetRangeRequest()),
        // 30 days whatever the period, as the in-car page asks for it.
        dna: await _client.getDna(GetDnaRequest(days: 30)),
        unit: await distanceUnit(_client),
        costs: TripCosts.of(await listTripsInPeriod(_client.listTrips, widget.days)),
      ));

  @override
  void didUpdateWidget(_Stats old) {
    super.didUpdateWidget(old);
    if (old.days != widget.days) _stats.load();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final hud = BwHud.of(context);
    final big = hudText(28, hud.textPrimary, lineHeight: 36, weight: FontWeight.w700);
    final mid = hudText(18, hud.textPrimary, lineHeight: 24, weight: FontWeight.w700);
    final note = hudText(14, hud.textSecondary, lineHeight: 20);
    Widget centred(String text, TextStyle style) => Center(child: Text(text, textAlign: TextAlign.center, style: style));
    return LoaderView(
      loader: _stats,
      builder: (context, v) {
        final r = parseRange(v.range.rangeJson);
        final dna = v.dna.hasDna() ? v.dna.dna : null;
        String dist(double km) => Fmt.distance(km, unit: v.unit, decimals: 0);
        final bydEstimate = tr('trips.byd_estimate_value');
        return PageList(children: [
          // The five DNA scores out of 500, and the overall one out of 100.
          Section(title: tr('trips.driver_score'), children: [
            centred(
                '${dna == null ? 0 : dna.anticipation + dna.smoothness + dna.speedDiscipline + dna.efficiency + dna.consistency} / 500',
                big),
            centred('${tr('trips.overall')}: ${dna?.overall ?? 0} / 100', note),
          ]),
          Section(title: tr('trips.personalized_range'), children: [
            if (r == null || r.estimated <= 0)
              centred(v.range.message.isNotEmpty ? v.range.message : tr('trips.not_enough_data'), note)
            else ...[
              centred(dist(r.estimated), big),
              if (r.builtIn > 0) centred('$bydEstimate ${dist(r.builtIn)}', note),
            ],
            // A PHEV's fuel range, never added into the electric one: different tanks, different
            // confidence. Absent unless the tank size is set (the car returns -1 without it).
            if (r != null && r.fuel > 0) ...[
              const SizedBox(height: 12),
              centred('${tr('trips.fuel_range')} ${dist(r.fuel)}', mid),
              if (r.builtInFuel > 0) centred('$bydEstimate ${dist(r.builtInFuel)}', note),
            ],
          ]),
          Section(title: tr('trips.cost'), children: [
            if (costCells(v.costs, tr) case final cells?) StatGrid(center: true, rows: [cells]) else CostMessage(costs: v.costs),
          ]),
          if (dna != null)
            Section(title: tr('trips.driving_dna'), children: [
              ScoreBars(bars: [
                (tr('companion.score_anticipation'), dna.anticipation),
                (tr('companion.score_smoothness'), dna.smoothness),
                (tr('companion.score_speed'), dna.speedDiscipline),
                (tr('trips.efficiency'), dna.efficiency),
                (tr('companion.score_consistency'), dna.consistency),
              ]),
            ]),
        ]);
      },
    );
  }
}

/// Trip analytics, costs (rate, currency, fuel price, tank), distance unit and trip storage -- the
/// in-car app's Settings > Trips. Shown on the Trips page and from Settings (BladeWatch-rdtj.67).
class TripSettingsForm extends StatefulWidget {
  const TripSettingsForm({super.key});

  @override
  State<TripSettingsForm> createState() => _TripSettingsFormState();
}

class _TripSettingsFormState extends State<TripSettingsForm> with LoadersState {
  late final _client = TripsServiceClient(context.session.rpc);
  late final _state = loader(() async => (
        config: (await _client.getConfig(GetConfigRequest())).config,
        storage: (await _client.getStorage(GetStorageRequest())).storage,
      ));
  final _rate = TextEditingController();
  // The currency is PICKED from CurrencySymbols, never typed (BladeWatch-gzbo). What the car stored is
  // kept, so opening Settings and pressing Apply does not rewrite it: a config holding an ISO code
  // (PHP) is shown as its symbol but only replaced when the owner picks one.
  String _currency = CurrencySymbols.defaultSymbol;
  String _storedCurrency = '';
  bool _currencyPicked = false;
  final _limit = TextEditingController();
  // PHEV pricing (BladeWatch-rdtj.48): the price the fuel costs are worked out with, and the tank
  // the fuel range is predicted from. Shown as the web shows them: on a PHEV, or whenever a value
  // is already set -- the drivetrain probe reads false while the car warms up, and a set value
  // must stay reachable to be cleared (web/src/app/util/drivetrain.ts).
  final _fuelPrice = TextEditingController();
  final _tank = TextEditingController();
  bool _filled = false;
  bool _fuelShown = false;
  String _unit = 'km';

  static bool showFuel(TripConfig c) => c.isPhev || c.fuelPricePerL > 0 || c.fuelTankCapacityL > 0;

  @override
  void dispose() {
    _rate.dispose();
    _limit.dispose();
    _fuelPrice.dispose();
    _tank.dispose();
    super.dispose();
  }

  /// Where new trips go, confirmed first as the in-car app does.
  Future<void> _moveStorage(String type, String place) async {
    final tr = context.tr;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('trips.storage_location')),
        content: Text(tr('companion.trip_storage_confirm', {'place': place})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('common.cancel'))),
          FilledButton(key: const ValueKey('trips.storage.confirm'), onPressed: () => Navigator.pop(context, true), child: Text(tr('common.ok'))),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    await act(context, () => _client.setStorage(SetStorageRequest(storageType: type)), done: tr('toast.applied'), failed: tr('errors.save_failed'));
    await _state.load();
  }

  Future<void> _apply() async {
    final tr = context.tr;
    final rate = double.tryParse(_rate.text.trim());
    final limit = int.tryParse(_limit.text.trim());
    final fuel = _fuelShown;
    final price = fuel ? double.tryParse(_fuelPrice.text.trim()) : null;
    final tank = fuel ? double.tryParse(_tank.text.trim()) : null;
    await act(context, () async {
      await _client.setConfig(SetConfigRequest(
        electricityRate: rate ?? 0,
        hasElectricityRate_4: rate != null,
        currency: _currencyPicked || _storedCurrency.isEmpty ? _currency : _storedCurrency,
        distanceUnit: _unit,
        // Sent with presence, so 0 clears a value ("not configured") instead of reading as
        // "not sent" and leaving the old one in place.
        fuelPricePerL: price ?? 0,
        hasFuelPricePerL_8: price != null && price >= 0,
        fuelTankCapacityL: tank ?? 0,
        hasFuelTankCapacityL_10: tank != null && tank >= 0,
      ));
      if (limit != null) await _client.setStorage(SetStorageRequest(storageLimitMb: Int64(limit), hasStorageLimitMb_3: true));
    }, done: tr('toast.applied'), failed: tr('errors.save_failed'));
    await _state.load();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return LoaderView(
      loader: _state,
      builder: (context, v) {
        if (!_filled) {
          _filled = true;
          _rate.text = v.config.electricityRate.toStringAsFixed(4);
          _storedCurrency = v.config.currency;
          _currency = CurrencySymbols.forStored(_storedCurrency) ?? (_storedCurrency.trim().isEmpty ? CurrencySymbols.defaultSymbol : _storedCurrency);
          _limit.text = '${v.storage.limitMb}';
          _fuelPrice.text = v.config.fuelPricePerL.toStringAsFixed(2);
          _tank.text = v.config.fuelTankCapacityL.toStringAsFixed(1);
          _unit = v.config.distanceUnit == 'mi' ? 'mi' : 'km';
        }
        _fuelShown = showFuel(v.config);
        return PageList(children: [
          Section(title: tr('trips.trip_analytics'), children: [
            SwitchListTile(
              key: const ValueKey('trips.enabled'),
              contentPadding: EdgeInsets.zero,
              title: Text(tr('trips.trip_analytics_sub')),
              value: v.config.enabled,
              onChanged: (on) async {
                await act(context, () => _client.setConfig(SetConfigRequest(enabled: on, hasEnabled_2: true)), failed: tr('errors.save_failed'));
                await _state.load();
              },
            ),
            const SizedBox(height: 8),
            // Currency first: the rates below are in it, and their units say so (₱/kWh, ₱/L).
            DropdownButtonFormField<String>(
              key: const ValueKey('trips.currency'),
              initialValue: _currency,
              isExpanded: true,
              decoration: InputDecoration(labelText: tr('trips.currency')),
              // The current value is always present exactly once: a legacy free-text value that is not in
              // the list (Rs.) is prepended, or the dropdown would assert on the mismatch.
              items: [
                if (!CurrencySymbols.symbols.contains(_currency)) _currency,
                ...CurrencySymbols.symbols,
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() {
                _currency = v ?? _currency;
                _currencyPicked = true;
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('trips.rate'),
              controller: _rate,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: tr('trips.electricity_rate'), suffixText: '$_currency/kWh'),
            ),
            if (_fuelShown) ...[
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('trips.fuel_price'),
                controller: _fuelPrice,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: tr('trips.fuel_price'), suffixText: '$_currency/L', helperText: tr('trips.fuel_price_sub'), helperMaxLines: 3),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('trips.tank'),
                controller: _tank,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: tr('trips.tank_capacity'), helperText: tr('trips.tank_capacity_sub'), helperMaxLines: 3),
              ),
            ],
            const SizedBox(height: 12),
            Text(tr('trip.settings.distance_unit'), style: Theme.of(context).textTheme.titleSmall),
            Wrap(spacing: 8, children: [
              for (final (unit, key) in [('km', 'trip.settings.unit_km'), ('mi', 'trip.settings.unit_miles')])
                ChoiceChip(
                  showCheckmark: false,
                  key: ValueKey('trips.unit.$unit'),
                  label: Text(tr(key)),
                  selected: _unit == unit,
                  // Saved with the rest by Apply, as the in-car app does.
                  onSelected: (_) => setState(() => _unit = unit),
                ),
            ]),
          ]),
          Section(title: tr('trips.trip_storage'), children: [
            Text(tr('trips.storage_location'), style: Theme.of(context).textTheme.titleSmall),
            Wrap(spacing: 8, children: [
              for (final (type, key) in [('INTERNAL', 'trips.internal'), ('SD_CARD', 'trips.sd_card')])
                ChoiceChip(
                  showCheckmark: false,
                  key: ValueKey('trips.storage.$type'),
                  label: Text(tr(key)),
                  selected: (v.storage.storageType.isEmpty ? 'INTERNAL' : v.storage.storageType) == type,
                  onSelected: (_) => _moveStorage(type, tr(key)),
                ),
            ]),
            // Forced break before "trips", same pattern as BladeWatch-rdtj.72.3's Diagnostics fix --
            // confirmed at 2x text scale it wrapped with "trips" left alone on its own line.
            InfoRow(tr('trips.used'), '${v.storage.usedMb.toStringAsFixed(1)} MB ·\n${v.storage.tripsCount} ${tr('trips.trips_count')}'),
            const SizedBox(height: 16),
            TextField(
              key: const ValueKey('trips.limit'),
              controller: _limit,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: tr('trips.mb_limit')),
            ),
          ]),
          FilledButton(key: const ValueKey('trips.apply'), onPressed: _apply, child: Text(tr('trips.apply'))),
          const SizedBox(height: 12),
          Section(title: tr('trips.database_catalog'), children: [
            Text(tr('trips.database_catalog_sub')),
            const SizedBox(height: 8),
            OutlinedButton(
              key: const ValueKey('trips.sync'),
              onPressed: () async {
                final r = await _client.syncTrips(SyncTripsRequest());
                if (context.mounted) {
                  say(ScaffoldMessenger.of(context), r.success ? '+${r.added} / -${r.removed} · ${r.total}' : r.error);
                }
              },
              child: Text(tr('trips.sync_database')),
            ),
          ]),
        ]);
      },
    );
  }
}
