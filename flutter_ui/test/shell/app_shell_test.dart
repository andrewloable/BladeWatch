import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/shell/app_shell.dart';
import 'package:bladewatch_ui/shell/drive_side.dart';
import 'package:bladewatch_ui/shell/nav_rail.dart';
import 'package:bladewatch_ui/shell/route_stubs.dart';
import 'package:bladewatch_ui/shell/shell_controller.dart';
import 'package:bladewatch_ui/theme/hud_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {Size size = const Size(1920, 1080)}) => MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        theme: BwHud.themeData(Brightness.light),
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

    await tester.tap(find.text('TRIPS'));
    await tester.pump();

    expect(controller.selectedRoute, BwRoutes.trips);
    expect(find.textContaining(BwRoutes.trips), findsWidgets);
  });

  testWidgets('landscape (960x540dp): language button lives at the top of the rail', (tester) async {
    final controller = ShellController();
    await tester.pumpWidget(_wrap(
      AppShell(controller: controller, onLanguageTap: () {}),
      size: const Size(1920, 1080),
    ));

    expect(find.byIcon(Icons.translate), findsOneWidget);
    final navRail = tester.widget<NavRail>(find.byType(NavRail));
    expect(navRail.showLanguageHeader, isTrue);
  });

  testWidgets('portrait (540x960dp): the language button is in the rail too, there is no toolbar', (tester) async {
    final controller = ShellController();
    await tester.pumpWidget(_wrap(
      AppShell(controller: controller, onLanguageTap: () {}),
      size: const Size(1080, 1920),
    ));

    expect(find.byIcon(Icons.translate), findsOneWidget);
    expect(tester.widget<NavRail>(find.byType(NavRail)).showLanguageHeader, isTrue);
    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets('tapping the language button calls onLanguageTap exactly once', (tester) async {
    var taps = 0;
    final controller = ShellController();
    await tester.pumpWidget(_wrap(AppShell(controller: controller, onLanguageTap: () => taps++)));

    await tester.tap(find.byIcon(Icons.translate));

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

  testWidgets('has no toolbar and no accent stripe: each screen draws its own title bar', (tester) async {
    final controller = ShellController();
    await tester.pumpWidget(_wrap(AppShell(controller: controller, onLanguageTap: () {})));

    expect(find.byType(AppBar), findsNothing);
    expect(find.byKey(const ValueKey('accentStripe')), findsNothing);
  });

  // BladeWatch-0kru: this used to assert the opposite — that the pill always
  // showed the placeholder "Connecting…". That WAS the bug: native hides the bar
  // entirely with no tunnel, and the app has no tunnel configured here, so
  // nothing is connecting. Inverted rather than deleted, so the regression it
  // now guards is explicit. Full coverage lives in status_pill_test.dart.
  testWidgets('shows no status pill when there is no tunnel', (tester) async {
    final controller = ShellController();
    await tester.pumpWidget(_wrap(AppShell(controller: controller, onLanguageTap: () {})));
    await tester.pumpAndSettle();

    expect(find.text('Connecting…'), findsNothing);
    expect(find.byKey(const ValueKey('shell.statusPill.url')), findsNothing);
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

  // BladeWatch-8w4p / 2llu.6: every screen draws its own HUD title bar; there is no M3 toolbar or accent stripe.
  group('HUD shell', () {
    testWidgets('the Dashboard screen has no toolbar and no accent stripe', (tester) async {
      final controller = ShellController(initialRoute: BwRoutes.dashboard);
      await tester.pumpWidget(
        _wrap(AppShell(controller: controller, onLanguageTap: () {}, dashboardScreen: const Text('DASHBOARD CONTENT'))),
      );

      expect(find.byType(AppBar), findsNothing);
      expect(find.byKey(const ValueKey('accentStripe')), findsNothing);
      expect(find.text('DASHBOARD CONTENT'), findsOneWidget);
    });

    testWidgets('the Dashboard page background is the HUD one', (tester) async {
      final controller = ShellController(initialRoute: BwRoutes.dashboard);
      await tester.pumpWidget(
        _wrap(AppShell(controller: controller, onLanguageTap: () {}, dashboardScreen: const Text('DASHBOARD CONTENT'))),
      );

      expect(tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor, BwHud.light.pageBackground);
    });

    testWidgets('portrait Dashboard: the language button moves from the toolbar to the rail', (tester) async {
      var taps = 0;
      final controller = ShellController(initialRoute: BwRoutes.dashboard);
      await tester.pumpWidget(
        _wrap(
          AppShell(controller: controller, onLanguageTap: () => taps++, dashboardScreen: const Text('D')),
          size: const Size(1080, 1920),
        ),
      );

      expect(find.byIcon(Icons.translate), findsOneWidget);
      expect(tester.widget<NavRail>(find.byType(NavRail)).showLanguageHeader, isTrue);
      await tester.tap(find.byIcon(Icons.translate));
      expect(taps, 1);
    });

    testWidgets('a route with no screen mounted (a stub) is on the HUD page background, with no toolbar', (tester) async {
      final controller = ShellController(initialRoute: BwRoutes.startup);
      await tester.pumpWidget(_wrap(AppShell(controller: controller, onLanguageTap: () {}, dashboardScreen: const Text('D'))));

      expect(find.byType(StubScreen), findsOneWidget);
      expect(find.byType(AppBar), findsNothing);
      expect(find.byKey(const ValueKey('accentStripe')), findsNothing);
      expect(tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor, BwHud.light.pageBackground);
    });

    // BladeWatch-2llu.6: the HUD ThemeData is the app's own, so the stage and everything pushed on it read it.
    testWidgets('the stage runs on the HUD ThemeData and a screen pushed onto it inherits it', (tester) async {
      ThemeData? onStage;
      ThemeData? pushed;
      final controller = ShellController(initialRoute: BwRoutes.dashboard);
      await tester.pumpWidget(_wrap(AppShell(
        controller: controller,
        onLanguageTap: () {},
        dashboardScreen: Builder(
          builder: (context) {
            onStage = Theme.of(context);
            return TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (c) {
                  pushed = Theme.of(c);
                  return const Text('PUSHED');
                },
              )),
              child: const Text('go'),
            );
          },
        ),
      )));
      expect(onStage!.extension<BwHud>(), same(BwHud.light));
      expect(onStage!.colorScheme.primary, BwHud.light.accent);
      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();
      expect(find.text('PUSHED'), findsOneWidget);
      expect(pushed!.extension<BwHud>(), same(BwHud.light));
      expect(pushed!.colorScheme.primary, BwHud.light.accent);
    });

    testWidgets('every screen route: no toolbar, no accent stripe', (tester) async {
      for (final (route, screen) in [(BwRoutes.liveView, 'LIVE SCREEN'), (BwRoutes.recordings, 'REC'), (BwRoutes.location, 'LOC'), (BwRoutes.vehicle, 'VEH'), (BwRoutes.trips, 'TRP'), (BwRoutes.diagnostics, 'DIA'), (BwRoutes.settings, 'SET'), (BwRoutes.settingsAbout, 'ABT'), (BwRoutes.surveillance, 'SRV')]) {
        final controller = ShellController(initialRoute: route);
        await tester.pumpWidget(_wrap(AppShell(
          controller: controller,
          onLanguageTap: () {},
          liveViewScreen: const Text('LIVE SCREEN'),
          recordingsScreen: const Text('REC'),
          locationScreen: const Text('LOC'),
          vehicleScreen: const Text('VEH'),
          tripsScreen: const Text('TRP'),
          diagnosticsScreen: const Text('DIA'),
          settingsScreen: const Text('SET'),
          settingsAboutScreen: const Text('ABT'),
          surveillanceScreen: const Text('SRV'),
        )));
        expect(find.text(screen), findsOneWidget, reason: route);
        expect(find.byType(AppBar), findsNothing, reason: route);
        expect(find.byKey(const ValueKey('accentStripe')), findsNothing, reason: route);
      }
    });

    testWidgets('the rail edge follows the drive side', (tester) async {
      final controller = ShellController(initialRoute: BwRoutes.trips, initialDriveSide: DriveSide.right);
      await tester.pumpWidget(_wrap(AppShell(controller: controller, onLanguageTap: () {})));

      expect(tester.widget<NavRail>(find.byType(NavRail)).onRight, isTrue);
    });
  });
}
