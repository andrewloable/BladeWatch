import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:bladewatch_companion/app.dart';
import 'package:bladewatch_companion/car/car_session.dart';
import 'package:bladewatch_companion/car/car_store.dart';
import 'package:bladewatch_companion/i18n.dart';
import 'package:bladewatch_companion/screens/pairing/pairing_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

/// Screenshots of every page, from the real car, using THIS machine's existing pairing -- read
/// from a temporary copy, so the real companion.json (its alert cursor) is left untouched.
/// Opens pages only; never presses a control, so nothing on the car changes.
///
///     flutter drive --release -d macos --driver=test_driver/integration_test.dart \
///       --target=integration_test/screenshots_test.dart --dart-define=BW_SHOTS=<dir>
///
/// Run it in release: debug-mode frames on the live and recordings pages take seconds each, and
/// every wait here is made of real frames. Each page gets about 15 s, hard-capped at 20 s.
///
/// The captures are raw: they show the car's real surroundings, location and network. Redact
/// before sharing anything.
const _out = String.fromEnvironment('BW_SHOTS');

/// Comma-separated page ids to capture; empty means all. Lets a slow run be resumed.
const _only = String.fromEnvironment('BW_PAGES');

/// A car's pairing QR text, for a device that is not paired yet (a fresh iPhone install). Pairing
/// adds the device to the car's list: remove it there afterwards.
const _pairing = String.fromEnvironment('BW_PAIRING');

const _pages = [
  'dashboard', 'live', 'events', 'recordings', 'vehicle', 'location', 'trips', //
  'surveillance', 'notifications', 'settings', 'performance', 'diagnostics', 'about',
];

/// Pumps real time until [done] or [max]. Pumping is required: without it the app draws nothing
/// after its first frame. Each pump waits for a real frame, so the window must be visible (see
/// the `open` call below) or macOS throttles every frame to about a second.
Future<void> _wait(WidgetTester tester, bool Function() done, Duration max) async {
  final end = DateTime.now().add(max);
  while (!done() && DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshots of every page from the real car', (tester) async {
    await initializeDateFormatting();
    // A desktop window on macOS; a phone keeps its own screen, so the phone layout is what is shot.
    if (Platform.isMacOS) {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
    }
    final phone = tester.view.physicalSize.width / tester.view.devicePixelRatio < 700; // HomeShell.wideMinWidth
    final en = await Tr.load(rootBundle, 'en');

    final real = File('${(await getApplicationSupportDirectory()).path}/companion.json');
    final copy = File('${Directory.systemTemp.createTempSync('bw-shots').path}/companion.json');
    if (real.existsSync()) real.copySync(copy.path);
    final store = CarStore(copy);
    await store.load();
    if (store.car == null && _pairing.isNotEmpty) {
      final pairing = PairingController(openSession: CarSession.open);
      store.car = await pairing.pair(_pairing, 'Screenshots device');
      expect(store.car, isNotNull, reason: 'pairing failed: ${pairing.error}');
    }
    expect(store.car, isNotNull, reason: 'this device is not paired with the car');

    final t0 = DateTime.now();
    // ignore: avoid_print
    void log(String what) => print('step $what at ${DateTime.now().difference(t0).inSeconds} s');
    final shotKey = GlobalKey();
    Future<void> shot(String name) async {
      final boundary = shotKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      log('capture $name');
      final image = await boundary.toImage(pixelRatio: Platform.isMacOS ? 2 : tester.view.devicePixelRatio).timeout(const Duration(seconds: 20));
      final png = await image.toByteData(format: ui.ImageByteFormat.png).timeout(const Duration(seconds: 20));
      File('$_out/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
      // ignore: avoid_print
      print('shot $name');
    }

    await tester.pumpWidget(RepaintBoundary(key: shotKey, child: CompanionApp(store: store, loadTr: (lang) async => en)));
    // `open` on the running bundle brings its window to the front instead of starting a second copy.
    if (Platform.isMacOS) await Process.run('open', [Directory(Platform.resolvedExecutable).parent.parent.parent.path]);
    Finder drawer(String key) => find.descendant(of: find.byType(NavigationDrawer), matching: find.text(en('nav.$key')));
    // The phone's bottom bar shows only the first four places; the rest are one tap into More.
    Future<void> go(String key) async {
      if (!phone) return tester.tap(drawer(key));
      if (const ['dashboard', 'live', 'events', 'recordings'].contains(key)) return tester.tap(find.byTooltip(en('nav.$key')).last);
      await tester.tap(find.byTooltip(en('nav.more')).last);
      await _wait(tester, () => false, const Duration(seconds: 1));
      final row = find.byKey(ValueKey('more.$key'));
      await tester.scrollUntilVisible(row, 50, scrollable: find.byType(Scrollable).last);
      await tester.tap(row);
    }

    bool shellUp() => phone ? find.byType(NavigationBar).evaluate().isNotEmpty : drawer('dashboard').evaluate().isNotEmpty;
    await _wait(tester, shellUp, const Duration(seconds: 60));
    await _wait(tester, () => find.byKey(const ValueKey('car.looking')).evaluate().isEmpty, const Duration(seconds: 120));
    expect(find.byKey(const ValueKey('car.looking')), findsNothing, reason: 'never reached the car');

    for (final key in _pages) {
      if (_only.isNotEmpty && !_only.split(',').contains(key)) continue;
      final n = _pages.indexOf(key) + 1;
      log('open $key');
      // A page that cannot be captured within 20 s is skipped, not waited for.
      try {
        await (() async {
          await go(key);
          log('tapped $key');
          await _wait(tester, () => false, const Duration(seconds: 5)); // load, images included
          if (key == 'live') {
            await _wait(tester, () => find.byKey(const ValueKey('live.frame')).evaluate().isNotEmpty, const Duration(seconds: 8));
            await _wait(tester, () => false, const Duration(seconds: 2));
          }
          await shot('${n.toString().padLeft(2, '0')}_$key');
        })()
            .timeout(const Duration(seconds: 20));
      } on TimeoutException {
        log('SKIPPED $key: over 20 s');
      }
    }
    await tester.pumpWidget(const SizedBox());
    copy.parent.deleteSync(recursive: true);
  }, skip: _out.isEmpty, timeout: const Timeout(Duration(minutes: 10)));
}
