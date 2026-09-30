import 'package:flutter/material.dart';

import '../theme/hud_theme.dart';
import 'nav_rail.dart';
import 'route_stubs.dart';
import 'shell_controller.dart';

/// The Flutter counterpart of `activity_main_new.xml` /
/// `layout-land/activity_main_new.xml`: navigation rail + content stage. There is no toolbar: on the HUD
/// skin (the app's only theme) every screen draws its own `HudTitleBar`, and the language button, which the
/// Android portrait layout kept in the toolbar's end-cluster, lives at the top of the rail in both
/// orientations. The rail is 80 dp wide, compact (52 dp items) in landscape.
class AppShell extends StatelessWidget {
  final ShellController controller;
  final VoidCallback onLanguageTap;

  /// The real Dashboard screen (BladeWatch-yz1e.2), shown in place of the
  /// [StubScreen] when [ShellController.selectedRoute] is [BwRoutes.dashboard].
  /// Optional and defaulting to null so every existing caller/test that
  /// doesn't care about Dashboard content keeps getting the stub unchanged —
  /// each of Epic 2's other screen tasks adds its own such slot the same way
  /// as it lands, rather than this shell taking on an 11-route registry
  /// up front for screens that don't exist yet.
  final Widget? dashboardScreen;

  /// The real Settings hub (BladeWatch-yz1e.3), shown for [BwRoutes.settings].
  /// Same optional/defaulting-to-null shape as [dashboardScreen] — see its
  /// doc comment for why.
  final Widget? settingsScreen;

  /// The real Settings → About screen (BladeWatch-yz1e.3), shown for
  /// [BwRoutes.settingsAbout] — its own top-level rail destination, separate
  /// from the Settings sub-rail (see `BwRoutes`' own doc comment).
  final Widget? settingsAboutScreen;

  /// The real Diagnostics hub (BladeWatch-yz1e.4), shown for
  /// [BwRoutes.diagnostics]. Same optional/defaulting-to-null shape as
  /// [dashboardScreen] — see its doc comment for why.
  final Widget? diagnosticsScreen;

  /// The real Trips screen (BladeWatch-yz1e.5), shown for [BwRoutes.trips].
  /// Same optional/defaulting-to-null shape as [dashboardScreen] — see its
  /// doc comment for why.
  final Widget? tripsScreen;

  /// The real Location screen (BladeWatch-yz1e.6), shown for
  /// [BwRoutes.location]. Same optional/defaulting-to-null shape as
  /// [dashboardScreen] — see its doc comment for why.
  final Widget? locationScreen;

  /// The real Recordings screen (BladeWatch-yz1e.7), shown for
  /// [BwRoutes.recordings]. Same optional/defaulting-to-null shape as
  /// [dashboardScreen] — see its doc comment for why.
  final Widget? recordingsScreen;

  /// The real Surveillance settings screen (BladeWatch-yz1e.8), shown for
  /// [BwRoutes.surveillance] — this screen's standalone entry point (native:
  /// `SurveillanceSettingsFragment`/`surveillanceSettingsWebFragment`), kept
  /// alongside its Settings sub-rail mount (see `SettingsScreen`'s
  /// `_Section.surveillance`) since native reaches it from both. Same
  /// optional/defaulting-to-null shape as [dashboardScreen] — see its doc
  /// comment for why.
  final Widget? surveillanceScreen;

  /// The real Vehicle screen (BladeWatch-yz1e.9), shown for
  /// [BwRoutes.vehicle]. Same optional/defaulting-to-null shape as
  /// [dashboardScreen] — see its doc comment for why.
  final Widget? vehicleScreen;

  /// The real Live View screen (BladeWatch-yz1e.10), shown for
  /// [BwRoutes.liveView]. Same optional/defaulting-to-null shape as
  /// [dashboardScreen] — see its doc comment for why.
  final Widget? liveViewScreen;

  const AppShell({
    super.key,
    required this.controller,
    required this.onLanguageTap,
    this.dashboardScreen,
    this.settingsScreen,
    this.settingsAboutScreen,
    this.diagnosticsScreen,
    this.tripsScreen,
    this.locationScreen,
    this.recordingsScreen,
    this.surveillanceScreen,
    this.vehicleScreen,
    this.liveViewScreen,
  });

  Widget? _screenFor(String route) => switch (route) {
    BwRoutes.dashboard => dashboardScreen,
    BwRoutes.settings => settingsScreen,
    BwRoutes.settingsAbout => settingsAboutScreen,
    BwRoutes.diagnostics => diagnosticsScreen,
    BwRoutes.trips => tripsScreen,
    BwRoutes.location => locationScreen,
    BwRoutes.recordings => recordingsScreen,
    BwRoutes.surveillance => surveillanceScreen,
    BwRoutes.vehicle => vehicleScreen,
    BwRoutes.liveView => liveViewScreen,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;

        final rail = NavRail(
          selectedRoute: controller.selectedRoute,
          onSelect: controller.selectRoute,
          showLanguageHeader: true,
          onLanguageTap: onLanguageTap,
          compact: isLandscape,
          onRight: controller.railOnRight,
        );

        // A Navigator scoped to the STAGE, not the whole window. Native keeps the nav rail visible when you
        // open a sub-screen (ADB Console, Performance); pushing on the root navigator covered the rail and
        // left the user with no sense of place (BladeWatch-mrsc).
        //
        // Dialogs are unaffected: showDialog defaults to useRootNavigator: true, so they still cover the
        // whole window rather than being trapped inside the stage.
        final stage = Navigator(
          // Keyed by route so switching rail destination rebuilds the stage navigator, discarding any
          // sub-screen that was open. Without this, leaving Diagnostics while the ADB Console was pushed
          // would keep showing the console under the new destination.
          key: ValueKey('stageNav.${controller.selectedRoute}'),
          onGenerateRoute: (settings) => MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => _screenFor(controller.selectedRoute) ?? StubScreen(routeName: controller.selectedRoute),
          ),
        );

        return Scaffold(
          backgroundColor: BwHud.of(context).pageBackground,
          body: SafeArea(
            child: Row(
              children: controller.railOnRight ? [Expanded(child: stage), rail] : [rail, Expanded(child: stage)],
            ),
          ),
        );
      },
    );
  }
}
