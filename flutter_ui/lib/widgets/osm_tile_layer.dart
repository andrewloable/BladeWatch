import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// The one OpenStreetMap tile source this app uses, in the one place it is
/// defined.
///
/// Both map surfaces — the Location screen and the trip detail route
/// (BladeWatch-fj8c) — render the same MAPNIK tiles native's OSMDroid
/// `TileSourceFactory.MAPNIK` serves. Keeping the URL template, the user agent
/// and the night treatment together stops a second, subtly different tile
/// source appearing the next time a map is added.
TileLayer bwOsmTileLayer() => TileLayer(
  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'net.bladewatch.flutter',
);

/// Ports native's `TilesOverlay.INVERT_COLORS`
/// (`TripDetailController.applyMapAppearance` / the Location screen's own map):
/// OSM ships no dark tiles, so a dark UI inverts the light ones rather than
/// leaving a glaring white rectangle in the middle of a night dashboard.
const ColorFilter bwNightTileFilter = ColorFilter.matrix(<double>[
  -1, 0, 0, 0, 255,
  0, -1, 0, 0, 255,
  0, 0, -1, 0, 255,
  0, 0, 0, 1, 0,
]);

/// [bwOsmTileLayer], inverted when [night] — the whole tile treatment in one
/// call so neither map can drift from the other.
Widget bwTileLayerFor({required bool night}) {
  final layer = bwOsmTileLayer();
  return night ? ColorFiltered(colorFilter: bwNightTileFilter, child: layer) : layer;
}
