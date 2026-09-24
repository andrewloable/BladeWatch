import 'dart:io';

import 'package:bladewatch_companion/app.dart';
import 'package:bladewatch_companion/car/car_session.dart';
import 'package:bladewatch_companion/car/car_store.dart';
import 'package:bladewatch_companion/i18n.dart';
import 'package:bladewatch_companion/screens/pairing/pairing_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// BladeWatch-rdtj.11 and -yzuc on real hardware: pair, then open every page of the companion
/// against the real car and check each one loads without an error. With BW_KILL the runner stops
/// byd_cam_daemon on "kill now" -- its restart wrapper too, so the outage outlasts the Pear pump's
/// 15 s connect deadline, inside which a restart only looks like slow answers -- and the app must
/// say the car isn't answering, then recover by itself when the service host's health check
/// (every 30 s) brings the daemon back.
///
/// Opens pages only -- it never presses a control, so nothing on the car is changed or actuated.
///
///     flutter test integration_test/screens_e2e_test.dart -d macos \
///       --dart-define=BW_PAIRING=<qr text> [--dart-define=BW_KILL=true] \
///       | while read l; do echo "$l"; case "$l" in *"kill now"*) adb -s ... shell 'for p in $(ps -A -o PID,ARGS | grep -E "start_[c]am_daemon" | awk "{print \$1}"); do kill -9 $p; done; killall -9 byd_cam_daemon';; esac; done
///
/// Pairing adds this machine to the car's paired devices: remove it in the car afterwards.
const _qr = String.fromEnvironment('BW_PAIRING');
const _kill = bool.fromEnvironment('BW_KILL');

/// Every place in the app, by its nav label (screens/destinations.dart).
const _pages = [
  'nav.dashboard', 'nav.live', 'nav.events', 'nav.recordings', 'nav.vehicle', 'nav.location', 'nav.trips', //
  'nav.surveillance', 'nav.notifications', 'nav.settings', 'nav.performance', 'nav.diagnostics', 'nav.about',
];

/// Pumps real time until [done] or [max].
Future<void> _wait(WidgetTester tester, bool Function() done, Duration max) async {
  final end = DateTime.now().add(max);
  while (!done() && DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('every page loads from the real car, and a stopped daemon is shown as such', (tester) async {
    await initializeDateFormatting();
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    final en = await Tr.load(rootBundle, 'en');

    final t0 = DateTime.now();
    // ignore: avoid_print
    void step(String what) => print('step $what at ${DateTime.now().difference(t0).inSeconds} s');
    final pairing = PairingController(openSession: CarSession.open);
    pairing.addListener(() => step('pairing ${pairing.step.name}'));
    final car = await pairing.pair(_qr, 'companion screens e2e');
    step('paired ${car != null}');
    expect(car, isNotNull, reason: 'pairing failed: ${pairing.error}');
    final store = CarStore(File('${Directory.systemTemp.createTempSync('screens-e2e').path}/companion.json'))..car = car;

    await tester.pumpWidget(CompanionApp(store: store, loadTr: (lang) async => en));
    Finder drawer(String key) => find.descendant(of: find.byType(NavigationDrawer), matching: find.text(en(key)));
    await _wait(tester, () => drawer('nav.dashboard').evaluate().isNotEmpty, const Duration(seconds: 20));
    step('app up');
    await _wait(tester, () => find.text(en('companion.looking')).evaluate().isEmpty, const Duration(seconds: 120));
    step('connected');

    for (final key in _pages) {
      await tester.tap(drawer(key));
      await _wait(tester, () => false, const Duration(seconds: 6)); // load, and poll at least once
      if (key == 'nav.live') {
        // The car turns streaming on at the first 503; a still follows within a few seconds.
        await _wait(tester, () => find.byKey(const ValueKey('live.frame')).evaluate().isNotEmpty, const Duration(seconds: 30));
        final frame = find.byKey(const ValueKey('live.frame')).evaluate().isNotEmpty;
        // ignore: avoid_print
        print('live frame shown: $frame');
        expect(frame, isTrue, reason: 'live view must show a still from the car');
      }
      final failed = find.text(en('errors.load_failed')).evaluate().isNotEmpty;
      final exception = tester.takeException();
      // ignore: avoid_print
      print('page ${en(key)}: ${failed ? 'LOAD FAILED' : 'ok'}${exception == null ? '' : ' exception $exception'}');
      expect(failed, isFalse, reason: '${en(key)} failed to load');
      expect(exception, isNull);
    }

    if (_kill) {
      await tester.tap(drawer('nav.dashboard'));
      await _wait(tester, () => false, const Duration(seconds: 3));
      // ignore: avoid_print
      print('kill now');
      final started = DateTime.now();
      bool silent() => find.text(en('companion.not_answering')).evaluate().isNotEmpty;
      await _wait(tester, silent, const Duration(seconds: 45)); // the pump's 15 s, a 5 s poll, margin
      expect(silent(), isTrue, reason: 'the stopped daemon must be shown');
      // ignore: avoid_print
      print('not answering shown after ${DateTime.now().difference(started).inSeconds} s');
      // Back to the page itself -- not merely to some other connection state.
      bool anyState() => const ['car.silent', 'car.looking', 'car.unreachable', 'car.refused']
          .any((k) => find.byKey(ValueKey(k)).evaluate().isNotEmpty);
      await _wait(tester, () => !anyState(), const Duration(seconds: 180));
      expect(anyState(), isFalse, reason: 'it must clear by itself once the daemon is back');
      await _wait(tester, () => false, const Duration(seconds: 6));
      expect(find.text(en('errors.load_failed')), findsNothing, reason: 'and the page loads again');
      // ignore: avoid_print
      print('recovered after ${DateTime.now().difference(started).inSeconds} s');
    }
    await tester.pumpWidget(const SizedBox());
  }, skip: _qr.isEmpty, timeout: const Timeout(Duration(minutes: 8)));
}
