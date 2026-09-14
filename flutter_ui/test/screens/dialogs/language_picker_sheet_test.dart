import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/screens/dialogs/language_picker_sheet.dart';
import 'package:bladewatch_ui/shell/locale_controller.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeLocaleStore implements LocaleStore {
  String? stored;
  final writes = <String>[];

  /// Set false to model a store that cannot persist (BladeWatch-vcur).
  bool writable = true;

  @override
  Future<String?> readRaw() async => stored;

  @override
  Future<bool> writeRaw(String tag) async {
    writes.add(tag);
    if (!writable) return false;
    stored = tag;
    return true;
  }
}

void main() {
  late FakeLocaleStore store;
  late LocaleController controller;

  setUp(() {
    store = FakeLocaleStore();
    controller = LocaleController(store: store);
  });

  Future<void> pumpSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
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
              onPressed: () => showLanguagePickerSheet(context, controller),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the Auto row plus all 17 supported languages', (tester) async {
    await pumpSheet(tester);

    expect(find.byKey(const ValueKey('languagePicker.row.auto')), findsOneWidget);
    for (final tag in kSupportedLocaleTags) {
      expect(find.byKey(ValueKey('languagePicker.row.$tag')), findsOneWidget);
    }
    expect(find.text('17 languages available'), findsOneWidget);
  });

  testWidgets('shows every native-script name', (tester) async {
    await pumpSheet(tester);

    for (final name in kLocaleNativeNames.values) {
      expect(find.text(name), findsOneWidget);
    }
  });

  testWidgets('Auto is checked by default (before any selection)', (tester) async {
    await pumpSheet(tester);

    final autoTile = tester.widget<ListTile>(find.byKey(const ValueKey('languagePicker.row.auto')));
    final autoTrailing = autoTile.trailing! as Row;
    final autoIcon = autoTrailing.children.whereType<Icon>().first;
    expect(autoIcon.color, isNot(Colors.transparent));

    final jaTile = tester.widget<ListTile>(find.byKey(const ValueKey('languagePicker.row.ja')));
    final jaTrailing = jaTile.trailing! as Row;
    final jaIcon = jaTrailing.children.whereType<Icon>().first;
    expect(jaIcon.color, Colors.transparent);
  });

  testWidgets('tapping a language row selects it and closes the sheet', (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.byKey(const ValueKey('languagePicker.row.ja')));
    await tester.pumpAndSettle();

    expect(store.writes, ['ja']);
    expect(find.byType(LanguagePickerSheet), findsNothing);
  });

  testWidgets('tapping Auto after a manual selection persists the auto sentinel', (tester) async {
    store.stored = 'ja';
    await controller.load();
    await pumpSheet(tester);

    await tester.tap(find.byKey(const ValueKey('languagePicker.row.auto')));
    await tester.pumpAndSettle();

    expect(store.writes, ['auto']);
  });

  testWidgets('the current selection shows a checkmark, reflected from the controller', (tester) async {
    store.stored = 'de';
    await controller.load();
    await pumpSheet(tester);

    final deTile = tester.widget<ListTile>(find.byKey(const ValueKey('languagePicker.row.de')));
    final deIcon = (deTile.trailing! as Row).children.whereType<Icon>().first;
    expect(deIcon.color, isNot(Colors.transparent));

    final autoTile = tester.widget<ListTile>(find.byKey(const ValueKey('languagePicker.row.auto')));
    final autoIcon = (autoTile.trailing! as Row).children.whereType<Icon>().first;
    expect(autoIcon.color, Colors.transparent);
  });

  testWidgets('the close button dismisses the sheet without selecting anything', (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.byKey(const ValueKey('languagePicker.close')));
    await tester.pumpAndSettle();

    expect(store.writes, isEmpty);
    expect(find.byType(LanguagePickerSheet), findsNothing);
  });

  testWidgets('the Auto row subtitle names the resolved system language', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('ja');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);

    await pumpSheet(tester);

    expect(find.textContaining('日本語'), findsWidgets);
  });

  testWidgets('the Auto row subtitle falls back to English for an unsupported system locale', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('xx');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);

    await pumpSheet(tester);

    expect(find.textContaining('English'), findsWidgets);
  });

  testWidgets('the Auto row subtitle resolves a region-qualified system locale', (tester) async {
    tester.platformDispatcher.localeTestValue = const Locale('zh', 'CN');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);

    await pumpSheet(tester);

    expect(find.textContaining('简体中文'), findsWidgets);
  });

  testWidgets('renders without error in dark theme', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
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
            onPressed: () => showLanguagePickerSheet(context, controller),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  // ── BladeWatch-vcur: a language that could not be saved must say so. The
  // old store wrote to a directory the app UID cannot create, applied the
  // language anyway, and let the user discover the loss on next launch. ────
  testWidgets('tells the user when the choice could not be saved', (tester) async {
    store.writable = false;
    await pumpSheet(tester);

    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();

    expect(controller.rawTag, 'de', reason: 'still applied for this session');
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('could not be saved'), findsOneWidget);
  });

  testWidgets('says nothing when the choice saved normally', (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.text('Deutsch'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
  });
}
