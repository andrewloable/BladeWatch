import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/screens/settings/settings_about_controller.dart';
import 'package:bladewatch_ui/screens/settings/settings_about_screen.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:bladewatch_ui/widgets/hud_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/hud_test_env.dart';


void main() {
  hudTestEnvironment();

  late bool setupGuideShown;

  setUp(() {
    setupGuideShown = false;
  });

  SettingsAboutController buildController() => SettingsAboutController(
    versionSource: () async =>
        const AppVersionInfo(version: '1.2.3', buildNumber: '7', packageName: 'net.bladewatch.incarapp'),
  );

  Future<void> pumpTall(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(widget);
  }

  Widget wrap(SettingsAboutController controller) => MaterialApp(
    theme: BladeWatchTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SettingsAboutScreen(controller: controller, onShowSetupGuide: () => setupGuideShown = true),
    ),
  );

  testWidgets('HUD: the page header is the title bar with the one-line description under it', (tester) async {
    await pumpTall(tester, wrap(buildController()));
    await tester.pumpAndSettle();

    expect(find.byType(HudTitleBar), findsOneWidget);
    expect(find.descendant(of: find.byType(HudTitleBar), matching: find.text('ABOUT BLADEWATCH')), findsOneWidget);
    expect(find.byKey(const ValueKey('hud.back')), findsNothing);
  });

  testWidgets('renders version and package once loaded', (tester) async {
    await pumpTall(tester, wrap(buildController()));
    await tester.pumpAndSettle();

    expect(find.text('1.2.3'), findsOneWidget);
    expect(find.text('net.bladewatch.incarapp'), findsOneWidget);
  });

  testWidgets('tapping the license row shows the license dialog text', (tester) async {
    await pumpTall(tester, wrap(buildController()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('about.license')));
    await tester.pumpAndSettle();

    expect(find.textContaining('MIT License'), findsOneWidget);
    // The bundled HUD typeface's SIL OFL notice travels with the licence (BladeWatch-8w4p.1).
    expect(find.textContaining('SIL Open Font License'), findsOneWidget);
  });

  testWidgets('tapping the setup-guide row invokes the callback', (tester) async {
    await pumpTall(tester, wrap(buildController()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('about.setupGuide')));

    expect(setupGuideShown, isTrue);
  });

  testWidgets('the setup-guide row is labelled as the setup guide, not as the About page', (tester) async {
    // It was wired to the right callback but labelled with
    // settings_about_row_title/subtitle — the strings for the Settings hub's
    // "About BladeWatch / Version, license, support development." ROW. On
    // device that made it read as a duplicate of the page header, so there was
    // no discoverable way to reopen the guide. Native labels it
    // setup_guide_title/subtitle. The older test above only asserted the tap
    // fired, which is why the wrong label went unnoticed.
    await pumpTall(tester, wrap(buildController()));
    await tester.pumpAndSettle();

    final row = find.byKey(const ValueKey('about.setupGuide'));
    expect(find.descendant(of: row, matching: find.text('Getting Started')), findsOneWidget);
    expect(
      find.descendant(of: row, matching: find.text('Three quick steps to get the best experience:')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.text('Version, license, support development.')),
      findsNothing,
    );
  });

  testWidgets('renders without error in dark theme', (tester) async {
    await pumpTall(
      tester,
      MaterialApp(
        theme: BladeWatchTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SettingsAboutScreen(controller: buildController(), onShowSetupGuide: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
