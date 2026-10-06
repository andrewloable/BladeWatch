import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/screens/settings/settings_relay_controller.dart';
import 'package:bladewatch_ui/screens/settings/settings_relay_screen.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, String> store;
  late bool failWrites;

  SettingsRelayController controller() => SettingsRelayController(
        read: (key) async => store[key],
        write: (key, value) async {
          if (failWrites) return false;
          store[key] = value;
          return true;
        },
        delete: (key) async {
          if (failWrites) return false;
          store.remove(key);
          return true;
        },
      );

  setUp(() {
    store = {};
    failWrites = false;
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: BladeWatchTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SettingsRelayScreen(controller: controller())),
    ));
    await tester.pumpAndSettle();
  }

  SwitchListTile useSwitch(WidgetTester tester) => tester.widget<SwitchListTile>(find.byKey(const ValueKey('relay.enabled')));

  testWidgets('off by default: the switch is off and no key field shows', (tester) async {
    await pump(tester);
    expect(useSwitch(tester).value, isFalse);
    expect(find.text('Use my relay'), findsOneWidget);
    expect(find.byKey(const ValueKey('relay.key.field')), findsNothing);
  });

  testWidgets('turning it on asks for the key; typing groups it and Save stores it masked', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('relay.enabled')));
    await tester.pumpAndSettle();
    expect(store['enabled'], 'true');
    expect(find.byKey(const ValueKey('relay.key.needed')), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('relay.key.field')), '482109375562');
    await tester.pump();
    expect(find.text('4821-0937-5562'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('relay.key.save')));
    await tester.pumpAndSettle();
    expect(store['key'], '482109375562');
    expect(find.byKey(const ValueKey('relay.key.field')), findsNothing);
    expect(find.text('••••-••••-5562'), findsOneWidget);
    expect(find.textContaining('4821'), findsNothing, reason: 'the full key is never shown after Save');
  });

  testWidgets("the keyboard's Done key saves too", (tester) async {
    store['enabled'] = 'true';
    await pump(tester);
    await tester.enterText(find.byKey(const ValueKey('relay.key.field')), '482109375562');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(store['key'], '482109375562');
    expect(find.text('••••-••••-5562'), findsOneWidget);
  });

  testWidgets('a short key is refused with a message and nothing stored', (tester) async {
    store['enabled'] = 'true';
    await pump(tester);
    await tester.enterText(find.byKey(const ValueKey('relay.key.field')), '4821');
    await tester.tap(find.byKey(const ValueKey('relay.key.save')));
    await tester.pumpAndSettle();
    expect(find.text('Enter the 12-digit relay key.'), findsOneWidget);
    expect(store.containsKey('key'), isFalse);
  });

  testWidgets('Change opens the field with Cancel; Cancel goes back to the masked key', (tester) async {
    store.addAll({'enabled': 'true', 'key': '482109375562'});
    await pump(tester);
    expect(find.byKey(const ValueKey('relay.key.saved')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('relay.key.change')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('relay.key.field')), findsOneWidget);
    expect(find.byKey(const ValueKey('relay.key.needed')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('relay.key.cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('relay.key.masked')), findsOneWidget);
  });

  testWidgets('Remove key deletes it and turns relay access off', (tester) async {
    store.addAll({'enabled': 'true', 'key': '482109375562'});
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('relay.key.remove')));
    await tester.pumpAndSettle();
    expect(store.containsKey('key'), isFalse);
    expect(store['enabled'], 'false');
    expect(useSwitch(tester).value, isFalse);
  });

  testWidgets('a write the daemon refuses snaps the switch back and says so', (tester) async {
    failWrites = true;
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('relay.enabled')));
    await tester.pumpAndSettle();
    expect(useSwitch(tester).value, isFalse);
    expect(find.byKey(const ValueKey('relay.error')), findsOneWidget);
    expect(find.text('Could not save. Try again.'), findsOneWidget);
  });

  test('the key formatter keeps 12 digits in groups of four and drops the rest', () {
    const f = RelayKeyInputFormatter();
    String format(String text) => f.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text)).text;
    expect(format('4821'), '4821');
    expect(format('48210'), '4821-0');
    expect(format('4821 0937 5562'), '4821-0937-5562');
    expect(format('4821-0937-5562-99'), '4821-0937-5562');
    expect(format('ab48c21'), '4821');
    expect(format(''), '');
  });
}
