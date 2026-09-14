import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/platform/prefs_channel.dart';
import 'package:bladewatch_ui/screens/settings/settings_appearance_controller.dart';
import 'package:bladewatch_ui/screens/settings/settings_appearance_screen.dart';
import 'package:bladewatch_ui/shell/shell_controller.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:bladewatch_ui/shell/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_platform_channel.dart';

class _MemLocaleStore implements LocaleStore {
  String? _tag;
  @override
  Future<String?> readRaw() async => _tag;
  @override
  Future<bool> writeRaw(String tag) async {
    _tag = tag;
    return true;
  }
}

void main() {
  late FakePlatformChannel channel;
  late ShellController shellController;
  late bool languagePickerOpened;

  Widget wrap(SettingsAppearanceController controller) => MaterialApp(
        theme: BladeWatchTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SettingsAppearanceScreen(
        localeController: LocaleController(store: _MemLocaleStore()),controller: controller, onOpenLanguagePicker: () => languagePickerOpened = true),
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

  /// Selection is asserted through SEMANTICS rather than by casting to a widget
  /// type: the theme and drive-side options are now preview/subtitle tiles
  /// (BladeWatch-mrsc) instead of ChoiceChips, and a test that pins the widget
  /// class breaks on every presentation change while proving nothing a user
  /// would notice. Semantics is also what an accessibility service reads.
  bool isSelected(WidgetTester tester, String key) =>
      tester
          .widget<Semantics>(
            find.ancestor(of: find.byKey(ValueKey(key)), matching: find.byType(Semantics)).first,
          )
          .properties
          .selected ??
      false;

  testWidgets('the language row shows Auto while following the system', (tester) async {
    await tester.pumpWidget(wrap(buildController()));
    await tester.pumpAndSettle();

    // Native shows the CURRENT language on this row plus how many exist; the
    // port used to show neither (BladeWatch-mrsc).
    final row = find.byKey(const ValueKey('language.card'));
    expect(find.descendant(of: row, matching: find.text('Auto')), findsOneWidget);
    expect(find.descendant(of: row, matching: find.textContaining('languages available')), findsOneWidget);
  });

  testWidgets('the language row shows the chosen language in its own script', (tester) async {
    final store = _MemLocaleStore();
    await store.writeRaw('de');
    final locales = LocaleController(store: store);
    await locales.load();

    await tester.pumpWidget(MaterialApp(
      theme: BladeWatchTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SettingsAppearanceScreen(
          localeController: locales,
          controller: buildController(),
          onOpenLanguagePicker: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byKey(const ValueKey('language.card')), matching: find.text('Deutsch')),
      findsOneWidget,
    );
  });

  testWidgets('renders the default (system, left) selections', (tester) async {
    await tester.pumpWidget(wrap(buildController()));
    await tester.pumpAndSettle();

    expect(isSelected(tester, 'theme.system'), isTrue);
    expect(isSelected(tester, 'driveSide.left'), isTrue);
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

    expect(isSelected(tester, 'theme.light'), isTrue);
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

    expect(isSelected(tester, 'theme.dark'), isTrue);
    final call = channel.calls.firstWhere((c) => c.method == 'setThemeMode');
    expect((call.args as Map)['value'], 'dark');
  });

  testWidgets('tapping the Right drive-side chip selects it and updates the caption', (tester) async {
    await tester.pumpWidget(wrap(buildController()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('driveSide.right')));
    await tester.pump();

    expect(isSelected(tester, 'driveSide.right'), isTrue);
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
      home: Scaffold(body: SettingsAppearanceScreen(
        localeController: LocaleController(store: _MemLocaleStore()),controller: buildController(), onOpenLanguagePicker: () {})),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
