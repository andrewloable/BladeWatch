import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/platform/prefs_channel.dart';
import 'package:bladewatch_ui/screens/settings/settings_appearance_controller.dart';
import 'package:bladewatch_ui/screens/settings/settings_appearance_screen.dart';
import 'package:bladewatch_ui/shell/shell_controller.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_platform_channel.dart';

void main() {
  late FakePlatformChannel channel;
  late ShellController shellController;
  late bool languagePickerOpened;

  Widget wrap(SettingsAppearanceController controller) => MaterialApp(
        theme: BladeWatchTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SettingsAppearanceScreen(controller: controller, onOpenLanguagePicker: () => languagePickerOpened = true),
        ),
      );

  setUp(() {
    channel = FakePlatformChannel();
    shellController = ShellController();
    languagePickerOpened = false;
    channel.stub('prefs', 'getThemeMode', null);
    channel.stub('prefs', 'getDriveSide', null);
    channel.stub('prefs', 'setThemeMode', null);
    channel.stub('prefs', 'setDriveSide', null);
  });

  SettingsAppearanceController buildController() =>
      SettingsAppearanceController(prefs: PrefsChannel(channel), shellController: shellController);

  testWidgets('renders the default (system, left) selections', (tester) async {
    await tester.pumpWidget(wrap(buildController()));
    await tester.pumpAndSettle();

    final systemChip = tester.widget<ChoiceChip>(find.byKey(const ValueKey('theme.system')));
    expect(systemChip.selected, isTrue);
    final leftChip = tester.widget<ChoiceChip>(find.byKey(const ValueKey('driveSide.left')));
    expect(leftChip.selected, isTrue);
  });

  testWidgets('tapping the System chip re-selects it and persists via the prefs channel', (tester) async {
    await tester.pumpWidget(wrap(buildController()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('theme.system')));
    await tester.pump();

    final call = channel.calls.firstWhere((c) => c.method == 'setThemeMode');
    expect((call.args as Map)['value'], 'system');
  });

  testWidgets('tapping the Light chip selects it and persists via the prefs channel', (tester) async {
    await tester.pumpWidget(wrap(buildController()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('theme.light')));
    await tester.pump();

    final lightChip = tester.widget<ChoiceChip>(find.byKey(const ValueKey('theme.light')));
    expect(lightChip.selected, isTrue);
    final call = channel.calls.firstWhere((c) => c.method == 'setThemeMode');
    expect((call.args as Map)['value'], 'light');
  });

  testWidgets('tapping the Left drive-side chip persists via the prefs channel', (tester) async {
    await tester.pumpWidget(wrap(buildController()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('driveSide.left')));
    await tester.pump();

    final call = channel.calls.firstWhere((c) => c.method == 'setDriveSide');
    expect((call.args as Map)['value'], 'left');
  });

  testWidgets('tapping the Dark chip selects it and persists via the prefs channel', (tester) async {
    await tester.pumpWidget(wrap(buildController()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('theme.dark')));
    await tester.pump();

    final darkChip = tester.widget<ChoiceChip>(find.byKey(const ValueKey('theme.dark')));
    expect(darkChip.selected, isTrue);
    final call = channel.calls.firstWhere((c) => c.method == 'setThemeMode');
    expect((call.args as Map)['value'], 'dark');
  });

  testWidgets('tapping the Right drive-side chip selects it and updates the caption', (tester) async {
    await tester.pumpWidget(wrap(buildController()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('driveSide.right')));
    await tester.pump();

    final rightChip = tester.widget<ChoiceChip>(find.byKey(const ValueKey('driveSide.right')));
    expect(rightChip.selected, isTrue);
    expect(find.text('Navigation on right'), findsOneWidget);
  });

  testWidgets('tapping the Auto drive-side chip shows the detected-side caption', (tester) async {
    await tester.pumpWidget(wrap(buildController()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('driveSide.auto')));
    await tester.pump();

    expect(find.text('Auto — vehicle reports left-hand drive'), findsOneWidget);
  });

  testWidgets('tapping the language card invokes the callback', (tester) async {
    await tester.pumpWidget(wrap(buildController()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('language.card')));

    expect(languagePickerOpened, isTrue);
  });

  testWidgets('renders without error in dark theme', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: BladeWatchTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SettingsAppearanceScreen(controller: buildController(), onOpenLanguagePicker: () {})),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
