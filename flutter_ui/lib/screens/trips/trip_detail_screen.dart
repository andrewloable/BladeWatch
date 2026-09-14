import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../widgets/osm_tile_layer.dart';

import '../../gen/l10n/app_localizations.dart';
import 'trip_detail_controller.dart';
import 'trip_route.dart';
import 'trips_models.dart';

/// Ground truth: `TripDetailController.kt` (457 LOC), including its route map
/// — see [_RouteCard]. The map was deferred when this screen was first ported
/// (flutter_map was BladeWatch-yz1e.6's dependency to introduce) and retrofitted
/// in BladeWatch-fj8c once that had landed, reusing the same tile source the
/// Location screen uses rather than a second one.
class TripDetailScreen extends StatefulWidget {
  final TripDetailController controller;
  final int tripId;
  final TripsConfig? config;
  final VoidCallback onClose;

  const TripDetailScreen({super.key, required this.controller, required this.tripId, required this.config, required this.onClose});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.controller.load(widget.tripId);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final c = widget.controller;

    return Column(
      children: [
        ColoredBox(
          color: theme.colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(children: [
              TextButton.icon(
                key: const ValueKey('tripDetail.back'),
                onPressed: widget.onClose,
                icon: const Icon(Icons.chevron_left),
                label: Text(l10n.cd_back),
              ),
            ]),
          ),
        ),
        Expanded(child: _body(context, l10n, theme, c)),
      ],
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n, ThemeData theme, TripDetailController c) {
    if (c.loading) {
      return Center(key: const ValueKey('tripDetail.loading'), child: Text(l10n.trips_detail_loading));
    }
    if (c.hasError || c.detail == null) {
      return Center(key: const ValueKey('tripDetail.error'), child: Text(l10n.trips_detail_unavailable));
    }

    final trip = c.detail!;
    final distUnit = widget.config?.distanceUnit ?? 'km';

    return ListView(
      key: const ValueKey('tripDetail.loaded'),
      padding: const EdgeInsets.all(12),
      children: [
        Text(trip.formattedDateTitle, style: theme.textTheme.titleLarge),
        Text(trip.formattedTimeRange, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        _RouteCard(telemetry: c.telemetry),
        const SizedBox(height: 12),
        _SummaryCard(trip: trip, distanceUnit: distUnit),
        const SizedBox(height: 12),
        _ScoresCard(trip: trip),
      ],
    );
  }
}

/// The trip's route drawn on a map. Ground truth: `TripDetailController.kt`'s
/// `renderRoute()` (line 221) and the map card it builds (line 180) — same
/// MAPNIK tiles, same accent-coloured polyline, same accent start dot and
/// error-coloured end dot, same "fewer than 2 GPS points shows the message and
/// no map" threshold, same padded fit to the route's bounding box.
///
/// Native's map is also pannable inside its ScrollView (it calls
/// `requestDisallowInterceptTouchEvent` on touch); `flutter_map` handles that
/// gesture arena itself, so no equivalent is needed here.
class _RouteCard extends StatelessWidget {
  final List<TelemetryPoint> telemetry;
  const _RouteCard({required this.telemetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final points = tripRoutePoints(telemetry);

    return Card(
      key: const ValueKey('tripDetail.routeCard'),
      color: theme.colorScheme.surfaceContainer,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 260,
        // Native hides the MapView entirely below 2 points rather than showing
        // an empty world map, and says so in words.
        child: points.length < 2
            ? Center(
                key: const ValueKey('tripDetail.route.empty'),
                child: Text(
                  l10n.trip_no_route_data,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              )
            : _RouteMap(points: points),
      ),
    );
  }
}

class _RouteMap extends StatelessWidget {
  final List<LatLng> points;
  const _RouteMap({required this.points});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final night = theme.brightness == Brightness.dark;

    return FlutterMap(
      key: const ValueKey('tripDetail.route.map'),
      options: MapOptions(
        // Fitting the CAMERA to the route's bounds is what makes the trip
        // visible at all; native does the same with zoomToBoundingBox, and the
        // padding is its increaseByScale(1.4f) equivalent.
        initialCameraFit: CameraFit.bounds(
          bounds: tripRouteBounds(points),
          padding: const EdgeInsets.all(28),
        ),
      ),
      children: [
        bwTileLayerFor(night: night),
        PolylineLayer(
          polylines: [
            Polyline(points: points, strokeWidth: 4, color: theme.colorScheme.primary),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: points.first,
              width: 18,
              height: 18,
              child: _RouteDot(color: theme.colorScheme.primary),
            ),
            Marker(
              point: points.last,
              width: 18,
              height: 18,
              child: _RouteDot(color: theme.colorScheme.error),
            ),
          ],
        ),
        // SimpleAttributionWidget prepends its own "©", so the source text must NOT
        // repeat it — on device this rendered as "© © OpenStreetMap contributors"
        // (BladeWatch-imh6.2).
        const SimpleAttributionWidget(source: Text('OpenStreetMap contributors')),
      ],
    );
  }
}

/// Native draws these as a filled circle with a white ring
/// (`TripDetailController.dotMarker`), which is what keeps an accent-coloured
/// dot visible against an accent-coloured polyline.
class _RouteDot extends StatelessWidget {
  final Color color;
  const _RouteDot({required this.color});

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
    ),
  );
}

class _SummaryCard extends StatelessWidget {
  final TripDetailData trip;
  final String distanceUnit;
  const _SummaryCard({required this.trip, required this.distanceUnit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final distStr = formatDistance(trip.distanceKm, distanceUnit);
    final avgSpd = formatSpeed(trip.avgSpeedKmh, distanceUnit);
    final maxSpd = formatSpeed(trip.maxSpeedKmh, distanceUnit);
    final energyStr = trip.energyUsedKwh > 0 ? '${trip.energyUsedKwh.toStringAsFixed(1)} kWh' : '--';
    final costStr = trip.tripCost > 0 && trip.currency.isNotEmpty ? '${trip.currency} ${trip.tripCost.toStringAsFixed(2)}' : '--';
    final socStr = '${trip.socStart.toStringAsFixed(0)} → ${trip.socEnd.toStringAsFixed(0)}%';
    final tempStr = trip.extTempC != 0.0 ? '${trip.extTempC.toStringAsFixed(0)}°C' : '--';
    final elevStr = trip.elevationGainM > 0 ? '+${trip.elevationGainM.toStringAsFixed(0)}m' : '--';

    final cells = [
      (l10n.trips_detail_distance, distStr),
      (l10n.trips_detail_duration, trip.formattedDuration),
      (l10n.trips_detail_energy, energyStr),
      (l10n.trips_detail_avg_speed, avgSpd),
      (l10n.trips_detail_max_speed, maxSpd),
      (l10n.trips_detail_soc, socStr),
      (l10n.trips_detail_cost, costStr),
      (l10n.trips_detail_ext_temp, tempStr),
      (l10n.trips_detail_elev_gain, elevStr),
    ];

    return Card(
      key: const ValueKey('tripDetail.summaryCard'),
      color: theme.colorScheme.surfaceContainer,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.trips_detail_summary_title, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              children: [
                for (final (label, value) in cells)
                  SizedBox(
                    width: 120,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(children: [
                        Text(value, style: theme.textTheme.titleMedium),
                        Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 11)),
                      ]),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoresCard extends StatelessWidget {
  final TripDetailData trip;
  const _ScoresCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    Color colorFor(int score) {
      if (score >= 70) return theme.colorScheme.primary;
      if (score >= 40) return Colors.amber;
      return theme.colorScheme.error;
    }

    final bars = [
      (l10n.trips_dna_anticipation, trip.anticipationScore),
      (l10n.trips_dna_smoothness, trip.smoothnessScore),
      (l10n.trips_dna_speed_discipline, trip.speedDisciplineScore),
      (l10n.trips_dna_efficiency, trip.efficiencyScore),
      (l10n.trips_dna_consistency, trip.consistencyScore),
    ];

    return Card(
      key: const ValueKey('tripDetail.scoresCard'),
      color: theme.colorScheme.surfaceContainer,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.trips_detail_scores_title, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            for (final (label, score) in bars)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  SizedBox(width: 130, child: Text(label, style: theme.textTheme.bodyMedium)),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: score.clamp(0, 100) / 100,
                        minHeight: 8,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        color: colorFor(score),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('$score', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}
