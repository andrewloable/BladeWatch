import 'package:flutter/material.dart';

import '../gen/l10n/app_localizations.dart';
import 'route_stubs.dart';

/// One row in the navigation rail. Ground truth: the `RailItem(...)` list in
/// `app/src/main/java/com/loabletech/bladewatch/ui/MainActivity.kt` (~line
/// 758), cross-checked against the `railDest*` include order in
/// `app/src/main/res/layout/activity_main_new.xml`. Icons use Flutter's
/// built-in Material Icons font by the same semantic name as the Material
/// Symbol each native `@drawable/ic_*` maps to in
/// `docs/ui-ux-design-language.md`'s icon table — not pixel-identical to
/// Material Symbols Rounded, which Flutter doesn't bundle. The HUD skin
/// (BladeWatch-8w4p) picks the closest built-in Material Icon to each Font
/// Awesome glyph of the owner's reference design instead.
class RailDestination {
  final String routeName;
  final IconData icon;
  final String Function(AppLocalizations) label;

  const RailDestination({required this.routeName, required this.icon, required this.label});
}

/// It is **nine** items, not eight.
const List<RailDestination> railDestinations = [
  RailDestination(routeName: BwRoutes.dashboard, icon: Icons.public, label: _railDashboard),
  RailDestination(routeName: BwRoutes.location, icon: Icons.navigation, label: _railLocation),
  RailDestination(routeName: BwRoutes.liveView, icon: Icons.play_arrow, label: _railLive),
  RailDestination(routeName: BwRoutes.recordings, icon: Icons.videocam, label: _railRecordings),
  RailDestination(routeName: BwRoutes.vehicle, icon: Icons.directions_car, label: _railVehicle),
  RailDestination(routeName: BwRoutes.trips, icon: Icons.show_chart, label: _railTrips),
  RailDestination(routeName: BwRoutes.diagnostics, icon: Icons.monitor_heart, label: _railDiagnostics),
  RailDestination(routeName: BwRoutes.settings, icon: Icons.settings, label: _railSettings),
  RailDestination(routeName: BwRoutes.settingsAbout, icon: Icons.info, label: _railAbout),
];

String _railDashboard(AppLocalizations l) => l.rail_dashboard;
String _railLocation(AppLocalizations l) => l.rail_location;
String _railLive(AppLocalizations l) => l.rail_live;
String _railRecordings(AppLocalizations l) => l.rail_recordings;
String _railVehicle(AppLocalizations l) => l.rail_vehicle;
String _railTrips(AppLocalizations l) => l.rail_trips;
String _railDiagnostics(AppLocalizations l) => l.rail_diagnostics;
String _railSettings(AppLocalizations l) => l.rail_settings;
String _railAbout(AppLocalizations l) => l.settings_section_about;
