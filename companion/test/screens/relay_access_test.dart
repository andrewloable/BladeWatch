import 'dart:io';

import 'package:bladewatch_companion/car/car_page.dart';
import 'package:bladewatch_companion/car/car_store.dart';
import 'package:bladewatch_companion/screens/settings/relay_access.dart';
import 'package:bladewatch_companion/transport/transport_selector.dart';
import 'package:bladewatch_companion/tv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support.dart';

/// BladeWatch-a7mu: Settings > Relay access in the companion, and its way in from the
/// "can't reach the car" page.
void main() {
  hudTestEnvironment();

  late int changes;
  setUp(() => changes = 0);

  Future<CarStore> pumpPanel(WidgetTester tester, {CarStore? store, bool tv = false}) async {
    final s = store ?? testStore(car: testCar());
    Widget panel = SingleChildScrollView(
      child: RelayAccessPanel(store: s, onChanged: () async => changes++),
    );
    if (tv) panel = DpadFieldExit(child: panel);
    await pumpScreen(tester, TestSession(), panel);
    return s;
  }

  Future<CarStore> reload(CarStore store) async => CarStore(store.file)..car = null;

  // CarStore.save does real file work (and a chmod on desktops), which only completes when it is
  // started inside runAsync: run [gesture] there and let real time pass until [done].
  Future<void> act(WidgetTester tester, Future<void> Function() gesture, bool Function() done) async {
    await tester.runAsync(() async {
      await gesture();
      for (var i = 0; i < 300 && !done(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    expect(done(), isTrue, reason: 'the save never finished');
    await tester.pumpAndSettle();
  }

  testWidgets('off by default; switching it on is saved and applied', (tester) async {
    final store = await pumpPanel(tester);
    expect(tester.widget<SwitchListTile>(find.byKey(const ValueKey('relay.enabled'))).value, isFalse);
    expect(find.byKey(const ValueKey('relay.key.field')), findsNothing);

    await act(tester, () => tester.tap(find.byKey(const ValueKey('relay.enabled'))), () => changes == 1);
    expect(store.relayEnabled, isTrue);
    final again = await reload(store);
    await tester.runAsync(again.load);
    expect(again.relayEnabled, isTrue, reason: 'saved to the file');
    expect(changes, 1);
    expect(find.text(t('companion.relay_key_needed')), findsOneWidget);
  });

  testWidgets('typing groups the key; Save stores the bare digits and shows only the last group', (tester) async {
    final store = await pumpPanel(tester, store: testStore(car: testCar())..relayEnabled = true);
    await tester.enterText(find.byKey(const ValueKey('relay.key.field')), '482109375562');
    await tester.pump();
    expect(find.text('4821-0937-5562'), findsOneWidget);

    await act(tester, () => tester.tap(find.byKey(const ValueKey('relay.key.save'))), () => changes == 1);
    expect(store.relayKey, '482109375562');
    expect(store.relayKeyInUse, '482109375562');
    expect(changes, 1);
    expect(find.byKey(const ValueKey('relay.key.field')), findsNothing);
    expect(find.text('••••-••••-5562'), findsOneWidget);
    expect(find.textContaining('4821'), findsNothing, reason: 'the full key is never shown after Save');
  });

  testWidgets("the keyboard's Done key saves too", (tester) async {
    final store = await pumpPanel(tester, store: testStore(car: testCar())..relayEnabled = true);
    await tester.enterText(find.byKey(const ValueKey('relay.key.field')), '4821 0937 5562');
    await act(tester, () => tester.testTextInput.receiveAction(TextInputAction.done), () => changes == 1);
    expect(store.relayKey, '482109375562');
  });

  testWidgets('a short key is refused and nothing is saved', (tester) async {
    final store = await pumpPanel(tester, store: testStore(car: testCar())..relayEnabled = true);
    await tester.enterText(find.byKey(const ValueKey('relay.key.field')), '4821');
    await tester.tap(find.byKey(const ValueKey('relay.key.save')));
    await tester.pumpAndSettle();
    expect(find.text(t('companion.relay_key_invalid')), findsOneWidget);
    expect(store.relayKey, isNull);
    expect(changes, 0);
  });

  testWidgets('Change opens the field with Cancel; Remove key forgets it and switches off', (tester) async {
    final store = await pumpPanel(
      tester,
      store: testStore(car: testCar())
        ..relayEnabled = true
        ..relayKey = '482109375562',
    );
    expect(find.byKey(const ValueKey('relay.key.masked')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('relay.key.change')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('relay.key.field')), findsOneWidget);
    expect(find.text(t('companion.relay_key_needed')), findsNothing, reason: 'a key is already set');
    await tester.tap(find.byKey(const ValueKey('relay.key.cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('relay.key.masked')), findsOneWidget);

    await act(tester, () => tester.tap(find.byKey(const ValueKey('relay.key.remove'))), () => changes == 1);
    expect(store.relayKey, isNull);
    expect(store.relayEnabled, isFalse);
    expect(tester.widget<SwitchListTile>(find.byKey(const ValueKey('relay.enabled'))).value, isFalse);
  });

  testWidgets('a store that cannot be written keeps the old setting and says so', (tester) async {
    // A file where the store's directory should be: nothing can be written under it.
    final blocker = File('${Directory.systemTemp.createTempSync('relay-blocked').path}/not-a-dir')..writeAsStringSync('x');
    final store = CarStore(File('${blocker.path}/companion.json'));
    await pumpPanel(tester, store: store);
    var waited = 0;
    await act(tester, () => tester.tap(find.byKey(const ValueKey('relay.enabled'))), () => ++waited > 30);
    expect(store.relayEnabled, isFalse);
    expect(find.byKey(const ValueKey('relay.error')), findsOneWidget);
    expect(changes, 0);
  });

  testWidgets('on a TV, down leaves the key field for its buttons', (tester) async {
    await pumpPanel(tester, store: testStore(car: testCar())..relayEnabled = true, tv: true);
    await tester.tap(find.byKey(const ValueKey('relay.key.field')));
    await tester.pump();
    bool inField() =>
        FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<TextField>() != null;
    expect(inField(), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(inField(), isFalse, reason: 'the remote is not stuck in the field');
  });

  group('the "can\'t reach the car" page', () {
    Future<TestSession> pumpCarPage(WidgetTester tester, {CarStore? store}) async {
      final s = TestSession(phase: TransportPhase.failed);
      await pumpScreen(tester, s, CarPage(store: store, child: const Text('the screen')));
      return s;
    }

    testWidgets('offers Relay access, and a saved change looks for the car again', (tester) async {
      final store = testStore(car: testCar());
      final s = await pumpCarPage(tester, store: store);
      expect(find.text(t('companion.unreachable').toUpperCase()), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('car.relayAccess')));
      await tester.pumpAndSettle();
      expect(find.byType(RelayAccessPanel), findsOneWidget);
      await act(tester, () => tester.tap(find.byKey(const ValueKey('relay.enabled'))), () => s.retries == 1);
      await tester.enterText(find.byKey(const ValueKey('relay.key.field')), '482109375562');
      await act(tester, () => tester.tap(find.byKey(const ValueKey('relay.key.save'))), () => s.retries == 2);
      expect(store.relayKeyInUse, '482109375562');
      expect(s.retries, 2, reason: 'one search per saved change');

      await tester.tap(find.byKey(const ValueKey('relay.close')));
      await tester.pumpAndSettle();
      expect(find.byType(RelayAccessPanel), findsNothing);
    });

    testWidgets('while still looking, it is offered too', (tester) async {
      final s = TestSession(phase: TransportPhase.discovering);
      await pumpScreen(tester, s, CarPage(store: testStore(car: testCar()), child: const Text('the screen')));
      expect(find.byKey(const ValueKey('car.relayAccess')), findsOneWidget);
    });

    testWidgets('without a store there is no relay button', (tester) async {
      await pumpCarPage(tester);
      expect(find.byKey(const ValueKey('car.relayAccess')), findsNothing);
    });
  });

  test('the key formatter keeps 12 digits in groups of four and drops the rest', () {
    const f = RelayKeyInputFormatter();
    String format(String text) => f.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: text)).text;
    expect(format('48210'), '4821-0');
    expect(format('4821 0937 5562'), '4821-0937-5562');
    expect(format('4821-0937-5562-99'), '4821-0937-5562');
    expect(format('ab48c21'), '4821');
  });
}
