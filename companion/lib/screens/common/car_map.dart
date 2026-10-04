import 'package:bladewatch_theme/hud_theme.dart';
import 'package:bladewatch_theme/hud_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../tv.dart';

/// OpenStreetMap with the car's markers and, for a trip, its route, in a 4 dp bordered HUD frame: the route is the
/// accent, the markers (the car, a trip's ends) are the attention magenta. The same tile source and night treatment as the
/// in-car UI (flutter_ui/lib/widgets/osm_tile_layer.dart): OSM has no dark tiles, so a dark theme inverts the light ones.
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
    final hud = BwHud.of(context);
    final tiles = TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'net.bladewatch.companionapp',
    );
    // Not focusable on a TV: flutter_map takes the arrow keys to pan, so once the remote reached the
    // map it could never leave it (the owner, Location, 2026-10-04). A keyboard still pans it.
    final map = ExcludeFocus(
      excluding: isTv(context),
      child: FlutterMap(
        options: route.length > 1
            ? MapOptions(initialCameraFit: CameraFit.coordinates(coordinates: route, padding: const EdgeInsets.all(32)))
            : MapOptions(initialCenter: center, initialZoom: zoom),
        children: [
          night ? ColorFiltered(colorFilter: _invert, child: tiles) : tiles,
          if (route.length > 1) PolylineLayer(polylines: [Polyline(points: route, strokeWidth: 4, color: hud.accent)]),
          MarkerLayer(markers: [
            for (final m in markers) Marker(point: m, width: 36, height: 36, child: Icon(Icons.location_on, size: 36, color: hud.magenta)),
          ]),
          // Ten points so 'flutter_map | © OpenStreetMap contributors' fits a phone's width in Space Mono (at the theme's 14 it
          // ran off the map's edge, seen in a real macOS render at 390 dp).
          DefaultTextStyle.merge(
            style: const TextStyle(fontSize: 10),
            child: const SimpleAttributionWidget(source: Text('OpenStreetMap contributors')),
          ),
        ],
      ),
    );
    return HudPanel(color: hud.panel, borderColor: hud.panelBorder, clipBehavior: Clip.antiAlias, child: map);
  }
}
