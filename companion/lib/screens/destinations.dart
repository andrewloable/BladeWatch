import 'package:flutter/material.dart';

import '../car/car_store.dart';
import 'about/about_screen.dart';
import 'alerts/alert_settings_screen.dart';
import 'alerts/alerts_controller.dart';
import 'dashboard/dashboard_screen.dart';
import 'diagnostics/diagnostics_screen.dart';
import 'events/events_screen.dart';
import 'live/live_screen.dart';
import 'location/location_screen.dart';
import 'performance/performance_screen.dart';
import 'recordings/recordings_screen.dart';
import 'settings/settings_screen.dart';
import 'surveillance/surveillance_screen.dart';
import 'trips/trips_screen.dart';
import 'vehicle/vehicle_screen.dart';

/// One place in the app. [label] is a catalog key -- the web's own nav labels.
class Destination {
  const Destination(this.id, this.icon, this.label, this.build);

  final String id;
  final IconData icon;
  final String label;
  final WidgetBuilder build;
}

/// Everything the web app offered, in the companion (BladeWatch-rdtj.11's parity checklist):
/// the web login is pairing, which runs before any of these. The first four are a phone's
/// bottom bar; the rest are under "More".
List<Destination> destinations({
  required AlertsController alerts,
  required CarStore store,
  required Future<void> Function(String? lang) onLanguage,
  required Future<void> Function() onUnpair,
}) =>
    [
      Destination('dashboard', Icons.dashboard_outlined, 'nav.dashboard', (_) => const DashboardScreen()),
      Destination('live', Icons.videocam_outlined, 'nav.live', (_) => const LiveScreen()),
      Destination('events', Icons.notifications_outlined, 'nav.events', (_) => EventsScreen(alerts: alerts)),
      Destination('recordings', Icons.video_library_outlined, 'nav.recordings', (_) => const RecordingsScreen()),
      Destination('vehicle', Icons.directions_car_outlined, 'nav.vehicle', (_) => const VehicleScreen()),
      Destination('location', Icons.place_outlined, 'nav.location', (_) => const LocationScreen()),
      Destination('trips', Icons.route_outlined, 'nav.trips', (_) => const TripsScreen()),
      Destination('surveillance', Icons.shield_outlined, 'nav.surveillance', (_) => const SurveillanceScreen()),
      Destination('notifications', Icons.tune, 'nav.notifications', (_) => AlertSettingsScreen(alerts: alerts, store: store)),
      Destination('settings', Icons.settings_outlined, 'nav.settings',
          (_) => SettingsScreen(store: store, onLanguage: onLanguage, onUnpair: onUnpair)),
      Destination('performance', Icons.speed, 'nav.performance', (_) => const PerformanceScreen()),
      Destination('diagnostics', Icons.health_and_safety_outlined, 'nav.diagnostics', (_) => const DiagnosticsScreen()),
      Destination('about', Icons.info_outline, 'nav.about', (_) => const AboutScreen()),
    ];
