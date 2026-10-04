import 'dart:io';

import 'package:bladewatch_companion/app.dart';
import 'package:bladewatch_companion/car/car_store.dart';
import 'package:bladewatch_companion/i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// BladeWatch 1.4.1.2 on real hardware: a desktop pairs with the car over Wi-Fi by number, with no
/// QR, through the real app -- its pairing screen, discovery, the number, and the car's screens.
///
/// Needs a powered car with Direct connection on, this machine on the car's Wi-Fi, and someone to
/// open Pair a device in the car and confirm the number this prints. Skipped otherwise:
///
///     flutter test integration_test/wifi_pair_e2e_test.dart -d macos --dart-define=BW_WIFI_PAIR=true
///
/// It uses its own store, so the machine's own pairing is left alone. It does add a device named
/// [_name] to the car's paired devices: remove it in the car afterwards.
const _run = bool.fromEnvironment('BW_WIFI_PAIR');
const _name = 'Wi-Fi pairing test';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // semanticsEnabled: false -- a macOS accessibility client switching semantics on mid-run fails
  // testWidgets' end-of-test checks (see car_e2e_test.dart).
  testWidgets('pairs over Wi-Fi by number and reaches the car', semanticsEnabled: false, skip: !_run, (tester) async {
    final dir = await Directory.systemTemp.createTemp('bw-wifi-pair');
    addTearDown(() => dir.delete(recursive: true));
    final store = CarStore(File('${dir.path}/companion.json'));
    await store.load();
    await tester.pumpWidget(CompanionApp(store: store, loadTr: (lang) => Tr.load(rootBundle, lang), wifiPairing: true));

    Future<bool> waitFor(Finder f, Duration limit) async {
      final end = DateTime.now().add(limit);
      var shown = '';
      while (DateTime.now().isBefore(end)) {
        await tester.pump();
        if (f.evaluate().isNotEmpty) return true;
        // What the screen says while it waits, whenever that changes.
        final now = [for (final t in tester.widgetList<Text>(find.byType(Text))) t.data ?? ''].where((t) => t.isNotEmpty).join(' | ');
        if (now != shown) {
          // ignore: avoid_print
          print('BW screen: $now');
          shown = now;
        }
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      return false;
    }

    expect(await waitFor(find.byKey(const ValueKey('pair.wifi')), const Duration(seconds: 20)), isTrue);
    expect(find.byKey(const ValueKey('pair.scan')), findsNothing, reason: 'a desktop does not scan');
    await tester.enterText(find.byKey(const ValueKey('pair.name')), _name);
    await tester.tap(find.byKey(const ValueKey('pair.wifi')));

    expect(await waitFor(find.byKey(const ValueKey('pair.number')), const Duration(seconds: 70)), isTrue,
        reason: 'no car with Pair a device open answered on this Wi-Fi');
    // ignore: avoid_print
    print('BW number: ${tester.widget<Text>(find.byKey(const ValueKey('pair.number'))).data!.replaceAll(' ', '')}');

    expect(await waitFor(find.byType(HomeShell), const Duration(seconds: 120)), isTrue,
        reason: 'not confirmed in the car, or never reached its screens');
    expect(store.car?.lanHint, isNotNull, reason: 'the address that answered is the first one probed');
    // ignore: avoid_print
    print('BW paired: ${store.car!.deviceId} via ${store.car!.lanHint}');
  });
}
