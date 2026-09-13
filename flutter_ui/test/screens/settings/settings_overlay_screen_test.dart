import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/screens/settings/settings_overlay_controller.dart';
import 'package:bladewatch_ui/screens/settings/settings_overlay_screen.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(SettingsOverlayController controller) => MaterialApp(
        theme: BladeWatchTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SettingsOverlayScreen(controller: controller)),
      );

  testWidgets('renders both switches on by default', (tester) async {
    final c = SettingsOverlayController();
    await tester.pumpWidget(wrap(c));
    await tester.pumpAndSettle();

    final cameraSwitch = tester.widget<SwitchListTile>(find.byKey(const ValueKey('overlay.camera')));
    final tripSwitch = tester.widget<SwitchListTile>(find.byKey(const ValueKey('overlay.trip')));
    expect(cameraSwitch.value, isTrue);
    expect(tripSwitch.value, isTrue);
  });

  testWidgets('tapping the camera switch turns it off', (tester) async {
    final c = SettingsOverlayController();
    await tester.pumpWidget(wrap(c));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('overlay.camera')));
    await tester.pump();

    final cameraSwitch = tester.widget<SwitchListTile>(find.byKey(const ValueKey('overlay.camera')));
    expect(cameraSwitch.value, isFalse);
  });

  testWidgets('tapping the trip switch turns it off', (tester) async {
    final c = SettingsOverlayController();
    await tester.pumpWidget(wrap(c));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('overlay.trip')));
    await tester.pump();

    final tripSwitch = tester.widget<SwitchListTile>(find.byKey(const ValueKey('overlay.trip')));
    expect(tripSwitch.value, isFalse);
  });

  testWidgets('reflects a loaded state where an indicator is already off', (tester) async {
    final c = SettingsOverlayController(loadSettings: () async => (cameraVisible: false, tripVisible: true));
    await tester.pumpWidget(wrap(c));
    await tester.pumpAndSettle();

    final cameraSwitch = tester.widget<SwitchListTile>(find.byKey(const ValueKey('overlay.camera')));
    expect(cameraSwitch.value, isFalse);
  });

  testWidgets('renders without error in dark theme', (tester) async {
    final c = SettingsOverlayController();
    await tester.pumpWidget(MaterialApp(
      theme: BladeWatchTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SettingsOverlayScreen(controller: c)),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
