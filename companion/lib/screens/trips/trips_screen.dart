import 'dart:convert';

import 'package:bladewatch_rpc/gen/bladewatch/v1/trips.pb.dart';
import 'package:bladewatch_rpc/rpc/services/trips_service_client.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../car/car_page.dart';
import '../../i18n.dart';
import '../common/car_map.dart';
import '../common/format.dart';
import '../common/loader.dart';

/// Totals over the car's weekly rollups (GetSummary.rollup_json), as the web page sums them.
class PeriodSummary {
  const PeriodSummary(this.trips, this.km, this.seconds, this.kwh, this.efficiency);

  final int trips;
  final double km;
  final int seconds;
  final double kwh;
  final double efficiency;

  static PeriodSummary? of(List<WeeklyRollupEntry> entries) {
    var trips = 0, seconds = 0, n = 0;
    var km = 0.0, kwh = 0.0, eff = 0.0;
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
      eff += v(r, 'avgEfficiency');
    }
    return n == 0 ? null : PeriodSummary(trips, km, seconds, kwh, eff / n);
  }
}

/// GetRange.range_json: the learned range and the car's own, -1 meaning "cannot predict".
({double estimated, double builtIn, double fuel})? parseRange(String json) {
  if (json.isEmpty) return null;
  try {
    final d = jsonDecode(json) as Map<String, dynamic>;
    final r = (d['range'] as Map<String, dynamic>?) ?? d;
    double n(String k) => ((r[k] as num?) ?? 0).toDouble().clamp(0, double.infinity);
    final out = (estimated: n('predictedRangeKm'), builtIn: n('builtInRangeKm'), fuel: n('fuelRangeKm'));
    return out.estimated == 0 && out.builtIn == 0 && out.fuel == 0 ? null : out;
  } catch (_) {
    return null;
  }
}

/// The web trips page's counterpart: trips with period totals, each trip's route and scores,
/// learned range and driving DNA, and trip storage settings.
class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return DefaultTabController(
      length: 3,
      child: Column(children: [
        TabBar(tabs: [Tab(text: tr('trips.tab_trips')), Tab(text: tr('trips.tab_stats')), Tab(text: tr('trips.tab_storage'))]),
        const Expanded(child: TabBarView(children: [_TripList(), _Stats(), _Storage()])),
      ]),
    );
  }
}

class _TripList extends StatefulWidget {
  const _TripList();

  @override
  State<_TripList> createState() => _TripListState();
}

class _TripListState extends State<_TripList> with LoadersState {
  late final _client = TripsServiceClient(context.session.rpc);
  var _days = 7;
  late final _list = loader(() async => (
        trips: await _client.listTrips(ListTripsRequest(days: _days, limit: 100)),
        summary: await _client.getSummary(GetSummaryRequest(days: _days)),
      ));

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(spacing: 8, children: [
          for (final d in const [7, 30, 90])
            ChoiceChip(
              key: ValueKey('trips.days.$d'),
              label: Text(tr('trips.days', {'count': d})),
              selected: _days == d,
              onSelected: (_) {
                setState(() => _days = d);
                _list.load();
              },
            ),
        ]),
      ),
      Expanded(
        child: LoaderView(
          loader: _list,
          builder: (context, v) {
            final sum = PeriodSummary.of(v.summary.summary);
            return ListView(children: [
              if (sum != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Section(title: tr('trips.period_summary'), children: [
                    InfoRow(tr('trips.tab_trips'), '${sum.trips}'),
                    InfoRow(tr('trips.distance'), Fmt.distance(sum.km)),
                    InfoRow(tr('trips.hours'), Fmt.duration(sum.seconds)),
                    InfoRow(tr('trips.kwh'), sum.kwh.toStringAsFixed(1)),
                    InfoRow(tr('trips.efficiency'), '${sum.efficiency.toStringAsFixed(0)}%'),
                  ]),
                ),
              if (v.trips.trips.isEmpty) Padding(padding: const EdgeInsets.all(32), child: Text(tr('trips.no_trips_recorded'), textAlign: TextAlign.center)),
              for (final t in v.trips.trips)
                ListTile(
                  key: ValueKey('trip.${t.id}'),
                  title: Text(Fmt.dateTime(t.startTime, tr.lang)),
                  subtitle: Text('${Fmt.distance(t.distanceKm)} · ${Fmt.duration(t.durationSeconds)}'),
                  trailing: t.overallScore > 0 ? CircleAvatar(child: Text('${t.overallScore}')) : null,
                  onTap: () async {
                    final deleted = await Navigator.of(context).push<bool>(MaterialPageRoute(
                      builder: (_) => TrScope(tr: tr, child: SessionScope(session: context.session, child: TripDetailScreen(id: t.id))),
                    ));
                    if (deleted == true) await _list.load();
                  },
                ),
            ]);
          },
        ),
      ),
    ]);
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
          FilledButton(key: const ValueKey('trip.delete.confirm'), onPressed: () => Navigator.pop(context, true), child: Text(tr('common.delete'))),
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
    return Scaffold(
      appBar: AppBar(title: Text(tr('trips.trip_summary')), actions: [
        IconButton(key: const ValueKey('trip.delete'), tooltip: tr('trips.delete'), icon: const Icon(Icons.delete_outline), onPressed: _delete),
      ]),
      body: LoaderView(
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
                  : Center(child: Text(tr('trips.no_route_data'))),
            ),
            const SizedBox(height: 12),
            Section(title: Fmt.dateTime(s.startTime, tr.lang), children: [
              InfoRow(tr('trips.distance'), Fmt.distance(s.distanceKm)),
              InfoRow(tr('trips.duration'), Fmt.duration(s.durationSeconds)),
              InfoRow(tr('trips.avg_speed'), '${s.avgSpeedKmh.toStringAsFixed(0)} km/h'),
              InfoRow(tr('trips.max_speed'), '${s.maxSpeedKmh} km/h'),
              InfoRow(tr('trips.soc'), '${s.socStart.toStringAsFixed(0)}% → ${s.socEnd.toStringAsFixed(0)}%'),
              if (s.tripCost > 0) InfoRow(tr('trips.cost'), '${s.tripCost.toStringAsFixed(2)} ${s.currency}'),
              if (s.hasFuelData) InfoRow(tr('trips.fuel_used'), '${s.litresUsed.toStringAsFixed(2)} ${tr('trips.litres_short')}'),
              if (d.elevationGainM > 0) InfoRow(tr('trips.elev_gain'), '+${d.elevationGainM.toStringAsFixed(0)} m'),
            ]),
            if (s.overallScore > 0)
              Section(title: tr('trips.driving_scores'), children: [
                InfoRow(tr('trips.overall'), '${s.overallScore}'),
                InfoRow(tr('companion.score_anticipation'), '${d.anticipationScore}'),
                InfoRow(tr('companion.score_smoothness'), '${d.smoothnessScore}'),
                InfoRow(tr('companion.score_speed'), '${d.speedDisciplineScore}'),
                InfoRow(tr('trips.efficiency'), '${d.efficiencyScore}'),
                InfoRow(tr('companion.score_consistency'), '${d.consistencyScore}'),
              ]),
          ]);
        },
      ),
    );
  }
}

class _Stats extends StatefulWidget {
  const _Stats();

  @override
  State<_Stats> createState() => _StatsState();
}

class _StatsState extends State<_Stats> with LoadersState {
  late final _client = TripsServiceClient(context.session.rpc);
  late final _stats = loader(() async => (
        range: await _client.getRange(GetRangeRequest()),
        dna: await _client.getDna(GetDnaRequest(days: 30)),
      ));

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return LoaderView(
      loader: _stats,
      builder: (context, v) {
        final r = parseRange(v.range.rangeJson);
        final dna = v.dna.dna;
        return PageList(children: [
          Section(title: tr('trips.personalized_range'), children: [
            if (r == null) Text(v.range.message.isNotEmpty ? v.range.message : tr('trips.not_enough_data')),
            if (r != null && r.estimated > 0) InfoRow(tr('trips.personalized_range'), '${r.estimated.toStringAsFixed(0)} km'),
            if (r != null && r.builtIn > 0) InfoRow(tr('trips.byd_estimate'), '${r.builtIn.toStringAsFixed(0)} km'),
            if (r != null && r.fuel > 0) InfoRow(tr('trips.fuel_range'), '${r.fuel.toStringAsFixed(0)} km'),
          ]),
          Section(title: tr('trips.driving_dna'), children: [
            if (!v.dna.hasDna() || dna.overall == 0) Text(tr('trips.no_dna_data')),
            if (v.dna.hasDna() && dna.overall > 0) ...[
              InfoRow(tr('trips.overall'), '${dna.overall}'),
              InfoRow(tr('companion.score_anticipation'), '${dna.anticipation}'),
              InfoRow(tr('companion.score_smoothness'), '${dna.smoothness}'),
              InfoRow(tr('companion.score_speed'), '${dna.speedDiscipline}'),
              InfoRow(tr('trips.efficiency'), '${dna.efficiency}'),
              InfoRow(tr('companion.score_consistency'), '${dna.consistency}'),
            ],
          ]),
        ]);
      },
    );
  }
}

class _Storage extends StatefulWidget {
  const _Storage();

  @override
  State<_Storage> createState() => _StorageState();
}

class _StorageState extends State<_Storage> with LoadersState {
  late final _client = TripsServiceClient(context.session.rpc);
  late final _state = loader(() async => (
        config: (await _client.getConfig(GetConfigRequest())).config,
        storage: (await _client.getStorage(GetStorageRequest())).storage,
      ));
  final _rate = TextEditingController();
  final _currency = TextEditingController();
  final _limit = TextEditingController();
  bool _filled = false;

  @override
  void dispose() {
    _rate.dispose();
    _currency.dispose();
    _limit.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final tr = context.tr;
    final rate = double.tryParse(_rate.text.trim());
    final limit = int.tryParse(_limit.text.trim());
    await act(context, () async {
      await _client.setConfig(SetConfigRequest(
        electricityRate: rate ?? 0,
        hasElectricityRate_4: rate != null,
        currency: _currency.text.trim(),
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
          _currency.text = v.config.currency;
          _limit.text = '${v.storage.limitMb}';
        }
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
            TextField(
              key: const ValueKey('trips.rate'),
              controller: _rate,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: tr('trips.electricity_rate')),
            ),
            TextField(key: const ValueKey('trips.currency'), controller: _currency, decoration: InputDecoration(labelText: tr('trips.currency'))),
          ]),
          Section(title: tr('trips.trip_storage'), children: [
            InfoRow(tr('trips.storage_location'), v.storage.storageType == 'SD_CARD' ? tr('trips.sd_card') : tr('trips.internal')),
            InfoRow(tr('trips.used'), '${v.storage.usedMb.toStringAsFixed(1)} MB · ${v.storage.tripsCount} ${tr('trips.trips_count')}'),
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
