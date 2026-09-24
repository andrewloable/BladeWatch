import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// OpenStreetMap with the car's markers and, for a trip, its route. The same tile source and
/// night treatment as the in-car UI (flutter_ui/lib/widgets/osm_tile_layer.dart): OSM has no
/// dark tiles, so a dark theme inverts the light ones.
class CarMap extends StatelessWidget {
  const CarMap({super.key, required this.center, this.markers = const [], this.route = const [], this.zoom = 16});

  final LatLng center;
  final List<LatLng> markers;
  final List<LatLng> route;
  final double zoom;

  static const _invert = ColorFilter.matrix(<double>[
    -1, 0, 0, 0, 255, //
    0, -1, 0, 0, 255,
    0, 0, -1, 0, 255,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final night = Theme.of(context).brightness == Brightness.dark;
    final color = Theme.of(context).colorScheme.primary;
    final tiles = TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'net.bladewatch.companion',
    );
    return FlutterMap(
      options: route.length > 1
          ? MapOptions(initialCameraFit: CameraFit.coordinates(coordinates: route, padding: const EdgeInsets.all(32)))
          : MapOptions(initialCenter: center, initialZoom: zoom),
      children: [
        night ? ColorFiltered(colorFilter: _invert, child: tiles) : tiles,
        if (route.length > 1) PolylineLayer(polylines: [Polyline(points: route, strokeWidth: 4, color: color)]),
        MarkerLayer(markers: [
          for (final m in markers) Marker(point: m, width: 36, height: 36, child: Icon(Icons.location_on, size: 36, color: color)),
        ]),
        const SimpleAttributionWidget(source: Text('OpenStreetMap contributors')),
      ],
    );
  }
}
