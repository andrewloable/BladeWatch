import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/platform/prefs_channel.dart';
import 'package:bladewatch_ui/platform/setup_channel.dart';
import 'package:bladewatch_ui/screens/dialogs/language_picker_sheet.dart';
import 'package:bladewatch_ui/screens/dialogs/setup_guide_controller.dart';
import 'package:bladewatch_ui/screens/dialogs/setup_guide_dialog.dart';
import 'package:bladewatch_ui/screens/settings/settings_about_controller.dart';
import 'package:bladewatch_ui/shell/locale_controller.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_platform_channel.dart';

class FakeLocaleStore implements LocaleStore {
  @override
  Future<String?> readRaw() async => null;
  @override
  Future<void> writeRaw(String tag) async {}
}

void main() {
  late FakePlatformChannel channel;
  late SetupGuideController controller;
  late LocaleController localeController;

  const info = AppVersionInfo(version: '1.2.0', buildNumber: '7', packageName: 'net.bladewatch.flutter');

  setUp(() {
    channel = FakePlatformChannel();
    channel.stub('setup', 'openAutoStartSettings', null);
    channel.stub('setup', 'openOverlaySettings', null);
    channel.stub('prefs', 'setSetupGuideLastSeenBuild', null);
    controller = SetupGuideController(prefs: PrefsChannel(channel), setup: SetupChannel(channel), versionSource: () async => info);
    localeController = LocaleController(store: FakeLocaleStore());
  });

  Future<void> pumpDialog(WidgetTester tester, {String? updatedToVersion}) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      theme: BladeWatchTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showSetupGuideDialog(context, controller, localeController, updatedToVersion: updatedToVersion),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the title and all 3 steps with no version banner by default', (tester) async {
    await pumpDialog(tester);

    expect(find.text('Getting Started'), findsOneWidget);
    expect(find.text('Pick Your Language'), findsOneWidget);
    expect(find.text('Disable Auto-Start Restriction'), findsOneWidget);
    expect(find.text('Allow Display Over Other Apps'), findsOneWidget);
    expect(find.byKey(const ValueKey('setupGuide.versionBanner')), findsNothing);
  });

  testWidgets('shows the version banner when updatedToVersion is set', (tester) async {
    await pumpDialog(tester, updatedToVersion: '1.2.0');

    expect(find.byKey(const ValueKey('setupGuide.versionBanner')), findsOneWidget);
    expect(find.textContaining('1.2.0'), findsWidgets);
  });

  testWidgets('the language step shows a checkmark; auto-start and overlay do not', (tester) async {
    await pumpDialog(tester);

    // 3 step cards; only the language one shows a check icon (see the
    // dialog's own doc comment for why the other two never do).
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('tapping "Choose Language" opens the language picker sheet', (tester) async {
    await pumpDialog(tester);

    await tester.tap(find.byKey(const ValueKey('setupGuide.openLanguage')));
    await tester.pumpAndSettle();

    expect(find.byType(LanguagePickerSheet), findsOneWidget);
  });

  testWidgets('tapping "Open BYD Auto-Start" calls SetupChannel.openAutoStartSettings', (tester) async {
    await pumpDialog(tester);

    await tester.tap(find.byKey(const ValueKey('setupGuide.openAutoStart')));
    await tester.pump();

    expect(channel.calls.any((c) => c.group == 'setup' && c.method == 'openAutoStartSettings'), isTrue);
  });

  testWidgets('tapping "Open Overlay Settings" calls SetupChannel.openOverlaySettings', (tester) async {
    await pumpDialog(tester);

    await tester.tap(find.byKey(const ValueKey('setupGuide.openOverlay')));
    await tester.pump();

    expect(channel.calls.any((c) => c.group == 'setup' && c.method == 'openOverlaySettings'), isTrue);
  });

  testWidgets('"Remind me later" closes the dialog without marking it seen', (tester) async {
    await pumpDialog(tester);

    await tester.tap(find.byKey(const ValueKey('setupGuide.skip')));
    await tester.pumpAndSettle();

    expect(find.text('Getting Started'), findsNothing);
    expect(channel.calls.where((c) => c.method == 'setSetupGuideLastSeenBuild'), isEmpty);
  });

  testWidgets('"Done" marks the current build seen and closes the dialog', (tester) async {
    await pumpDialog(tester);

    await tester.tap(find.byKey(const ValueKey('setupGuide.done')));
    await tester.pumpAndSettle();

    expect(find.text('Getting Started'), findsNothing);
    final call = channel.calls.singleWhere((c) => c.method == 'setSetupGuideLastSeenBuild');
    expect((call.args as Map)['value'], '7');
  });

  testWidgets('renders without error in dark theme', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      theme: BladeWatchTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => showSetupGuideDialog(context, controller, localeController, updatedToVersion: '1.2.0'),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
