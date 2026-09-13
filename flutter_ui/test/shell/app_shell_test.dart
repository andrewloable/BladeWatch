import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/shell/app_shell.dart';
import 'package:bladewatch_ui/shell/drive_side.dart';
import 'package:bladewatch_ui/shell/nav_rail.dart';
import 'package:bladewatch_ui/shell/route_stubs.dart';
import 'package:bladewatch_ui/shell/shell_controller.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {Size size = const Size(1920, 1080)}) => MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        theme: BladeWatchTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

void main() {
  testWidgets('renders the rail and the stub for the initially selected route', (tester) async {
    final controller = ShellController(initialRoute: BwRoutes.dashboard);
    await tester.pumpWidget(_wrap(AppShell(controller: controller, onLanguageTap: () {})));

    expect(find.byType(NavRail), findsOneWidget);
    expect(find.textContaining(BwRoutes.dashboard), findsWidgets);
  });

  testWidgets('tapping a rail destination updates the controller and swaps the content', (tester) async {
    final controller = ShellController(initialRoute: BwRoutes.dashboard);
    await tester.pumpWidget(_wrap(AppShell(controller: controller, onLanguageTap: () {})));

    await tester.tap(find.text('Trips'));
    await tester.pump();

    expect(controller.selectedRoute, BwRoutes.trips);
    expect(find.textContaining(BwRoutes.trips), findsWidgets);
  });

  testWidgets('landscape (960x540dp): language button lives in the rail, not the toolbar', (tester) async {
    final controller = ShellController();
    await tester.pumpWidget(_wrap(
      AppShell(controller: controller, onLanguageTap: () {}),
      size: const Size(1920, 1080),
    ));

    expect(find.byIcon(Icons.language), findsOneWidget);
    final navRail = tester.widget<NavRail>(find.byType(NavRail));
    expect(navRail.showLanguageHeader, isTrue);
  });

  testWidgets('portrait (540x960dp): language button lives in the toolbar, not the rail', (tester) async {
    final controller = ShellController();
    await tester.pumpWidget(_wrap(
      AppShell(controller: controller, onLanguageTap: () {}),
      size: const Size(1080, 1920),
    ));

    expect(find.byIcon(Icons.language), findsOneWidget);
    final navRail = tester.widget<NavRail>(find.byType(NavRail));
    expect(navRail.showLanguageHeader, isFalse);
  });

  testWidgets('tapping the language button calls onLanguageTap exactly once', (tester) async {
    var taps = 0;
    final controller = ShellController();
    await tester.pumpWidget(_wrap(AppShell(controller: controller, onLanguageTap: () => taps++)));

    await tester.tap(find.byIcon(Icons.language));

    expect(taps, 1);
  });

  testWidgets('drive side left: rail renders before the content in reading order', (tester) async {
    final controller = ShellController(initialDriveSide: DriveSide.left);
    await tester.pumpWidget(_wrap(AppShell(controller: controller, onLanguageTap: () {})));

    final railX = tester.getTopLeft(find.byType(NavRail)).dx;
    final stageX = tester.getTopLeft(find.byType(StubScreen)).dx;
    expect(railX, lessThan(stageX));
  });

  testWidgets('drive side right: rail renders after the content in reading order', (tester) async {
    final controller = ShellController(initialDriveSide: DriveSide.right);
    await tester.pumpWidget(_wrap(AppShell(controller: controller, onLanguageTap: () {})));

    final railX = tester.getTopLeft(find.byType(NavRail)).dx;
    final stageX = tester.getTopLeft(find.byType(StubScreen)).dx;
    expect(railX, greaterThan(stageX));
  });

  testWidgets('toggling drive side at runtime re-renders the shell in the new order', (tester) async {
    final controller = ShellController(initialDriveSide: DriveSide.left);
    await tester.pumpWidget(_wrap(AppShell(controller: controller, onLanguageTap: () {})));
    expect(tester.getTopLeft(find.byType(NavRail)).dx, lessThan(tester.getTopLeft(find.byType(StubScreen)).dx));

    controller.setDriveSide(DriveSide.right);
    await tester.pump();

    expect(tester.getTopLeft(find.byType(NavRail)).dx, greaterThan(tester.getTopLeft(find.byType(StubScreen)).dx));
  });

  testWidgets('shows the accent stripe (primary-to-tertiary gradient bar)', (tester) async {
    final controller = ShellController();
    await tester.pumpWidget(_wrap(AppShell(controller: controller, onLanguageTap: () {})));

    expect(find.byKey(const ValueKey('accentStripe')), findsOneWidget);
  });

  testWidgets('shows the default (not-yet-connected) status pill text', (tester) async {
    final controller = ShellController();
    await tester.pumpWidget(_wrap(AppShell(controller: controller, onLanguageTap: () {})));

    expect(find.text('Connecting…'), findsOneWidget);
  });

  testWidgets('toolbar title reflects the currently selected rail destination', (tester) async {
    final controller = ShellController(initialRoute: BwRoutes.vehicle);
    await tester.pumpWidget(_wrap(AppShell(controller: controller, onLanguageTap: () {})));

    expect(find.widgetWithText(AppBar, 'Vehicle'), findsOneWidget);
  });

  testWidgets('renders the provided dashboardScreen instead of the stub when the route is dashboard', (tester) async {
    final controller = ShellController(initialRoute: BwRoutes.dashboard);
    await tester.pumpWidget(_wrap(AppShell(
      controller: controller,
      onLanguageTap: () {},
      dashboardScreen: const Text('DASHBOARD CONTENT'),
    )));

    expect(find.text('DASHBOARD CONTENT'), findsOneWidget);
    expect(find.byType(StubScreen), findsNothing);
  });

  testWidgets('renders the provided settingsScreen for the settings route', (tester) async {
    final controller = ShellController(initialRoute: BwRoutes.settings);
    await tester.pumpWidget(_wrap(AppShell(
      controller: controller,
      onLanguageTap: () {},
      settingsScreen: const Text('SETTINGS CONTENT'),
    )));

    expect(find.text('SETTINGS CONTENT'), findsOneWidget);
  });

  testWidgets('renders the provided settingsAboutScreen for the settingsAbout route', (tester) async {
    final controller = ShellController(initialRoute: BwRoutes.settingsAbout);
    await tester.pumpWidget(_wrap(AppShell(
      controller: controller,
      onLanguageTap: () {},
      settingsAboutScreen: const Text('ABOUT CONTENT'),
    )));

    expect(find.text('ABOUT CONTENT'), findsOneWidget);
  });

  testWidgets('renders the provided diagnosticsScreen for the diagnostics route', (tester) async {
    final controller = ShellController(initialRoute: BwRoutes.diagnostics);
    await tester.pumpWidget(_wrap(AppShell(
      controller: controller,
      onLanguageTap: () {},
      diagnosticsScreen: const Text('DIAGNOSTICS CONTENT'),
    )));

    expect(find.text('DIAGNOSTICS CONTENT'), findsOneWidget);
  });

  testWidgets('renders the provided tripsScreen for the trips route', (tester) async {
    final controller = ShellController(initialRoute: BwRoutes.trips);
    await tester.pumpWidget(_wrap(AppShell(
      controller: controller,
      onLanguageTap: () {},
      tripsScreen: const Text('TRIPS CONTENT'),
    )));

    expect(find.text('TRIPS CONTENT'), findsOneWidget);
  });

  testWidgets('renders the provided locationScreen for the location route', (tester) async {
    final controller = ShellController(initialRoute: BwRoutes.location);
    await tester.pumpWidget(_wrap(AppShell(
      controller: controller,
      onLanguageTap: () {},
      locationScreen: const Text('LOCATION CONTENT'),
    )));

    expect(find.text('LOCATION CONTENT'), findsOneWidget);
  });

  testWidgets('renders the provided recordingsScreen for the recordings route', (tester) async {
    final controller = ShellController(initialRoute: BwRoutes.recordings);
    await tester.pumpWidget(_wrap(AppShell(
      controller: controller,
      onLanguageTap: () {},
      recordingsScreen: const Text('RECORDINGS CONTENT'),
    )));

    expect(find.text('RECORDINGS CONTENT'), findsOneWidget);
  });

  testWidgets('renders the provided surveillanceScreen for the surveillance route', (tester) async {
    final controller = ShellController(initialRoute: BwRoutes.surveillance);
    await tester.pumpWidget(_wrap(AppShell(
      controller: controller,
      onLanguageTap: () {},
      surveillanceScreen: const Text('SURVEILLANCE CONTENT'),
    )));

    expect(find.text('SURVEILLANCE CONTENT'), findsOneWidget);
  });

  testWidgets('renders the provided vehicleScreen for the vehicle route', (tester) async {
    final controller = ShellController(initialRoute: BwRoutes.vehicle);
    await tester.pumpWidget(_wrap(AppShell(
      controller: controller,
      onLanguageTap: () {},
      vehicleScreen: const Text('VEHICLE CONTENT'),
    )));

    expect(find.text('VEHICLE CONTENT'), findsOneWidget);
  });

  testWidgets('renders the provided liveViewScreen for the liveView route', (tester) async {
    final controller = ShellController(initialRoute: BwRoutes.liveView);
    await tester.pumpWidget(_wrap(AppShell(
      controller: controller,
      onLanguageTap: () {},
      liveViewScreen: const Text('LIVE VIEW CONTENT'),
    )));

    expect(find.text('LIVE VIEW CONTENT'), findsOneWidget);
  });

  testWidgets('a provided dashboardScreen does not affect other routes', (tester) async {
    final controller = ShellController(initialRoute: BwRoutes.trips);
    await tester.pumpWidget(_wrap(AppShell(
      controller: controller,
      onLanguageTap: () {},
      dashboardScreen: const Text('DASHBOARD CONTENT'),
    )));

    expect(find.text('DASHBOARD CONTENT'), findsNothing);
    expect(find.byType(StubScreen), findsOneWidget);
  });

  testWidgets('toolbar title falls back to the raw route name for a route with no rail entry', (tester) async {
    // startup/surveillance/dialogs are reachable stubs but not rail
    // destinations (see BwRoutes' doc comment) -- no RailDestination.label
    // matches, so _currentTitle falls through to the route name itself.
    final controller = ShellController(initialRoute: BwRoutes.startup);
    await tester.pumpWidget(_wrap(AppShell(controller: controller, onLanguageTap: () {})));

    expect(find.widgetWithText(AppBar, BwRoutes.startup), findsOneWidget);
  });
}
