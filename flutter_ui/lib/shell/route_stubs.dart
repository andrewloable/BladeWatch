import 'package:flutter/material.dart';

/// The 11 screen groups Epic 2 (`BladeWatch-yz1e`) ports one at a time —
/// route names match its 11 child tasks 1:1 so each one "just fills in a
/// screen" at its own stub. `settingsAbout` is a 12th, extra destination:
/// the native app gives About its own distinct nav destination
/// (`settingsAboutFragment`, separate from `settingsFragment`), but Epic 2
/// builds it as one of the 7 sections inside yz1e.3 ("Settings hub and all
/// 7 sections"), not as its own task — it still needs its own route so the
/// rail's selection state can tell it apart from the Settings hub itself.
abstract final class BwRoutes {
  static const String startup = 'startup';
  static const String dashboard = 'dashboard';
  static const String settings = 'settings';
  static const String diagnostics = 'diagnostics';
  static const String trips = 'trips';
  static const String location = 'location';
  static const String recordings = 'recordings';
  static const String surveillance = 'surveillance';
  static const String vehicle = 'vehicle';
  static const String liveView = 'liveView';
  static const String dialogs = 'dialogs';

  /// The 11 stubs Epic 2 fills in, one per child task — see the class doc.
  static const List<String> all = [
    startup,
    dashboard,
    settings,
    diagnostics,
    trips,
    location,
    recordings,
    surveillance,
    vehicle,
    liveView,
    dialogs,
  ];

  static const String settingsAbout = 'settingsAbout';
}

/// Placeholder content for a route Epic 2 hasn't built yet. Screen content
/// is explicitly out of scope for this task ("Stubs only"); the "Epic 2
/// fills this in" text is scaffolding with a lifespan of exactly one epic —
/// deleted, not localized, once the real screen lands — so it is the one
/// other place besides the brand name that's a literal, not an ARB key.
class StubScreen extends StatelessWidget {
  final String routeName;

  const StubScreen({super.key, required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$routeName\n(Epic 2 fills this in)',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
