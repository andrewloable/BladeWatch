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
/// Material Symbols Rounded, which Flutter doesn't bundle; visual sign-off
/// against the real Material Symbols art is Phase 3 (`BladeWatch-imh6`).
class RailDestination {
  final String routeName;
  final IconData icon;
  final String Function(AppLocalizations) label;

  const RailDestination({required this.routeName, required this.icon, required this.label});
}

/// It is **nine** items, not eight — see the divider note on [aboutIndex].
const List<RailDestination> railDestinations = [
  RailDestination(routeName: BwRoutes.dashboard, icon: Icons.dashboard, label: _railDashboard),
  RailDestination(routeName: BwRoutes.location, icon: Icons.location_on, label: _railLocation),
  RailDestination(routeName: BwRoutes.liveView, icon: Icons.live_tv, label: _railLive),
  RailDestination(routeName: BwRoutes.recordings, icon: Icons.videocam, label: _railRecordings),
  RailDestination(routeName: BwRoutes.vehicle, icon: Icons.directions_car, label: _railVehicle),
  RailDestination(routeName: BwRoutes.trips, icon: Icons.timeline, label: _railTrips),
  RailDestination(routeName: BwRoutes.diagnostics, icon: Icons.monitor_heart, label: _railDiagnostics),
  RailDestination(routeName: BwRoutes.settings, icon: Icons.settings, label: _railSettings),
  RailDestination(routeName: BwRoutes.settingsAbout, icon: Icons.system_update, label: _railAbout),
];

/// Index of the About entry — [NavRail] paints the hairline divider
/// immediately before this index, matching the `<View>` divider that sits
/// directly above `railDestAbout` in `activity_main_new.xml`.
const int aboutRailIndex = 8;

String _railDashboard(AppLocalizations l) => l.rail_dashboard;
String _railLocation(AppLocalizations l) => l.rail_location;
String _railLive(AppLocalizations l) => l.rail_live;
String _railRecordings(AppLocalizations l) => l.rail_recordings;
String _railVehicle(AppLocalizations l) => l.rail_vehicle;
String _railTrips(AppLocalizations l) => l.rail_trips;
String _railDiagnostics(AppLocalizations l) => l.rail_diagnostics;
String _railSettings(AppLocalizations l) => l.rail_settings;
String _railAbout(AppLocalizations l) => l.settings_section_about;
