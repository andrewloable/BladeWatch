import 'dart:convert';
import 'dart:io';

import 'package:bladewatch_companion/app.dart';
import 'package:bladewatch_companion/car/car_store.dart';
import 'package:bladewatch_companion/i18n.dart';
import 'package:bladewatch_companion/screens/about/about_screen.dart';
import 'package:bladewatch_companion/screens/dashboard/dashboard_screen.dart';
import 'package:bladewatch_companion/screens/pairing/pairing_controller.dart';
import 'package:bladewatch_companion/screens/pairing/pairing_screen.dart';
import 'package:bladewatch_companion/screens/settings/settings_screen.dart';
import 'package:bladewatch_companion/screens/trips/trips_screen.dart';
import 'package:bladewatch_companion/screens/vehicle/vehicle_screen.dart';
import 'package:bladewatch_companion/transport/transport_selector.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/stream.pb.dart';
import 'package:bladewatch_rpc/pairing/pairing_payload.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

/// pumpAndSettle never settles while a screen polls: animations get a fixed second instead.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// The store without its file: real file I/O never completes inside testWidgets' fake-async
/// zone. The file itself is covered by test/car/car_store_test.dart.
class MemoryStore extends CarStore {
  MemoryStore({PairedCar? car}) : super(File('unused')) {
    this.car = car;
  }

  var saves = 0;

  @override
  Future<void> save() async => saves++;
}

Future<void> realTime(WidgetTester tester, Finder until) async {
  for (var i = 0; i < 20 && until.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  late TestSession s;
  late List<PairedCar> opened;
  late List<String> loaded;

  void stubCar() {
    s.rpc.stubJson('SystemService', 'GetStatus', {'recordingStatus': {}});
    s.rpc.stubJson('TripsService', 'ListTrips', {'trips': []});
    s.rpc.stubJson('NotificationsService', 'ListInbox', {
      'entries': [
        {'id': '5', 'title': 'alert'},
        {'id': '6', 'title': 'alert'},
      ],
      'latestId': '6',
    });
    s.rpc.stubJson('VehicleService', 'GetState', {'success': true});
  }

  Future<CompanionAppState> pumpApp(WidgetTester tester, CarStore store, {Size size = const Size(420, 900), bool fakeRedeem = false}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    s = TestSession();
    stubCar();
    opened = [];
    loaded = [];
    await tester.pumpWidget(CompanionApp(
      store: store,
      loadTr: (lang) async {
        loaded.add(lang);
        return testTr;
      },
      openSession: (car) async {
        opened.add(car);
        return s.session;
      },
      pairing: fakeRedeem
          ? PairingController(openSession: (car) async => TestSession().session, redeem: (u, code, n) async => testCredential)
          : null,
    ));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    return tester.state<CompanionAppState>(find.byType(CompanionApp));
  }

  testWidgets('unpaired: pairing first, then the car\'s screens', (tester) async {
    final store = MemoryStore();
    await pumpApp(tester, store, fakeRedeem: true);
    expect(find.byType(PairingScreen), findsOneWidget);
    expect(loaded.single, isNotEmpty, reason: 'the device language');

    final qr = PairingPayload(
      deviceId: 'dev-1',
      pearTopic: 'a' * 64,
      tlsPort: 8443,
      tlsFingerprint: 'b' * 64,
      probeKey: 'c' * 64,
      code: 'x',
      expiresAt: DateTime.now().add(const Duration(minutes: 5)),
    ).encode();
    await tester.enterText(find.byKey(const ValueKey('pair.code')), qr);
    await tester.tap(find.byKey(const ValueKey('pair.submit')));
    await realTime(tester, find.byType(DashboardScreen));
    expect(store.car?.deviceId, 'dev-1', reason: 'pairing is remembered');
    expect(find.byType(DashboardScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('phone: four in the bar, the rest under More; the Events badge counts new alerts', (tester) async {
    await pumpApp(tester, MemoryStore(car: testCar(cursor: '5')));
    expect(opened.single.deviceId, 'dev-1');
    expect(find.byKey(const ValueKey('nav.bar')), findsOneWidget);
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('1'), findsOneWidget, reason: 'one alert above the cursor');

    await tester.tap(find.byKey(const ValueKey('nav.more')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('more.vehicle')));
    await settle(tester);
    expect(find.byType(VehicleScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nav.more')));
    await settle(tester);
    await tester.tapAt(const Offset(10, 10)); // dismissed: stays where it was
    await settle(tester);
    expect(find.byType(VehicleScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav.dashboard')));
    await settle(tester);
    expect(find.byType(DashboardScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav.more')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('more.settings')));
    await settle(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  // BladeWatch: on a real Android phone, "Dashboard" and "Recordings" wrapped mid-word in the old Material bar
  // (NavigationDestination.label is a String with no maxLines/overflow control). The HUD bar's labels are one
  // line each, scaled down to their fifth of the width. The fixed test font would not reproduce the wrap
  // (docs: "a fixed-width placeholder font"), so this pins the fix at the property level.
  testWidgets('phone: every bottom-bar label is one line, scaled down rather than wrapped', (tester) async {
    await pumpApp(tester, MemoryStore(car: testCar()));
    for (final id in ['dashboard', 'live', 'events', 'recordings', 'more']) {
      final label = find.descendant(of: find.byKey(ValueKey('nav.$id')), matching: find.text(t('nav.$id').toUpperCase()));
      expect(tester.widget<Text>(label).maxLines, 1, reason: id);
      expect(find.ancestor(of: label, matching: find.byType(FittedBox)), findsOneWidget, reason: id);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('phone: the More sheet shows every place at once; a short screen scrolls to the last', (tester) async {
    // BladeWatch-rdtj.51: 412x780 is the Android phone emulator's logical size, where the old
    // 9/16 cap showed seven of nine.
    await pumpApp(tester, MemoryStore(car: testCar()), size: const Size(412, 780));
    await tester.tap(find.byKey(const ValueKey('nav.more')));
    await settle(tester);
    final screen = Offset.zero & const Size(412, 780);
    final rows = find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('more.'));
    expect(rows, findsNWidgets(9));
    for (final e in rows.evaluate()) {
      final r = tester.getRect(find.byWidget(e.widget));
      expect(screen.contains(r.topLeft) && screen.contains(r.bottomRight - const Offset(1, 1)), isTrue, reason: '${e.widget.key} is on screen');
    }
    await tester.tap(find.byKey(const ValueKey('more.about')));
    await settle(tester);
    expect(find.byType(AboutScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());

    await pumpApp(tester, MemoryStore(car: testCar()), size: const Size(600, 360));
    await tester.tap(find.byKey(const ValueKey('nav.more')));
    await settle(tester);
    // It scrolls: 360 is too short for nine. scrollUntilVisible stops once the row is BUILT,
    // part of it can still be past the edge, so ensureVisible brings the whole row in.
    await tester.scrollUntilVisible(find.byKey(const ValueKey('more.about')), 50, scrollable: find.byType(Scrollable).last);
    await tester.ensureVisible(find.byKey(const ValueKey('more.about')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('more.about')));
    await settle(tester);
    expect(find.byType(AboutScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  // BladeWatch-rdtj.40: "ダッシュボード" wrapped onto two lines in the bar. The test font draws every
  // glyph one em wide, which is what CJK glyphs really are, so these four are measured as they
  // render; Latin glyphs are narrower in real fonts than in the test font, so they are not.
  for (final lang in ['ja', 'ko', 'zh-CN', 'zh-TW']) {
    testWidgets('phone: every bottom-bar label fits on one line in $lang', (tester) async {
      Map<String, Object?> read(String l) => jsonDecode(File('assets/i18n/$l.json').readAsStringSync()) as Map<String, Object?>;
      final tr = Tr(lang, read(lang), read('en'));
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      s = TestSession();
      stubCar();
      await tester.pumpWidget(CompanionApp(
        store: MemoryStore(car: testCar())..language = lang,
        loadTr: (_) async => tr,
        openSession: (car) async => s.session,
      ));
      await settle(tester);
      for (final key in ['nav.dashboard', 'nav.live', 'nav.events', 'nav.recordings', 'nav.more']) {
        final label = find.descendant(of: find.byKey(const ValueKey('nav.bar')), matching: find.text(tr(key).toUpperCase()));
        expect(label, findsOneWidget, reason: key);
        expect(tester.getSize(label).height, lessThan(24), reason: '${tr(key)} wraps');
      }
      await tester.pumpWidget(const SizedBox());
    });
  }

  // BladeWatch-rdtj.57: the week's card leads to the trips, as the web's "View all trips" did.
  testWidgets('This Week opens the trips', (tester) async {
    await pumpApp(tester, MemoryStore(car: testCar()), size: const Size(1280, 900));
    s.rpc.stubJson('TripsService', 'GetSummary', {'summary': []});
    await tester.tap(find.byKey(const ValueKey('dash.allTrips')));
    await settle(tester);
    expect(find.byType(TripsScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('wide: a permanent drawer with every place', (tester) async {
    // BladeWatch-rdtj.52: edge to edge (Android 15), with a 24 px status bar over the app.
    tester.view.padding = const FakeViewPadding(top: 24);
    addTearDown(tester.view.resetPadding);
    await pumpApp(tester, MemoryStore(car: testCar()), size: const Size(1280, 900));
    expect(find.byKey(const ValueKey('nav.panel')), findsOneWidget);
    expect(tester.getRect(find.text('BladeWatch')).top, greaterThanOrEqualTo(24), reason: 'the drawer header clears the status bar');
    expect(find.text(t('nav.diagnostics').toUpperCase()), findsOneWidget);
    await tester.tap(find.descendant(of: find.byKey(const ValueKey('nav.panel')), matching: find.text(t('nav.vehicle').toUpperCase())));
    await settle(tester);
    expect(find.byType(VehicleScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());

    // BladeWatch-rdtj.52: the Android tablet is 800 dp tall, short of thirteen places. Scrolled to
    // About, the list moves and the name stays whole below the status bar.
    await pumpApp(tester, MemoryStore(car: testCar()), size: const Size(1280, 700));
    final before = tester.getRect(find.text('BladeWatch'));
    final about = find.descendant(of: find.byKey(const ValueKey('nav.panel')), matching: find.text(t('nav.about').toUpperCase()));
    await tester.scrollUntilVisible(about, 50, scrollable: find.descendant(of: find.byKey(const ValueKey('nav.panel')), matching: find.byType(Scrollable)));
    await tester.ensureVisible(about);
    await settle(tester);
    expect(tester.getRect(find.text('BladeWatch')), before, reason: 'the header does not scroll with the places');
    expect(before.top, greaterThanOrEqualTo(24));
    await tester.tap(about);
    await settle(tester);
    expect(find.byType(AboutScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('language, resume, a refusal, and unpairing', (tester) async {
    final store = MemoryStore(car: testCar());
    final app = await pumpApp(tester, store);
    await app.setLanguage('de');
    await tester.pump();
    expect(store.language, 'de');
    expect(loaded.last, 'de');
    await app.setLanguage(null);
    expect(store.language, isNull);

    void sleepAndWake() {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    }

    // BladeWatch-rdtj.38: where the car sits on its Wi-Fi is remembered for the next search.
    s.rpc.stubJson('SystemService', 'GetStatus', {'network': {'type': 'wifi', 'ip': '192.0.2.7'}});
    final savesBefore = store.saves;
    await s.go(tester, TransportPhase.discovering);
    await s.go(tester, TransportPhase.pear);
    await tester.pump();
    expect(store.car!.lanHint, '192.0.2.7');
    expect(store.saves, greaterThan(savesBefore));

    // BladeWatch-rdtj.36: a link that still answers is left alone; a lost one is looked for.
    s.rpc.stub('StreamService', 'GetQuality', GetStreamQualityResponse());
    sleepAndWake();
    await tester.pump();
    expect(s.retries, 0, reason: 'a healthy link is not torn down on resume');
    await s.go(tester, TransportPhase.discovering);
    sleepAndWake();
    await tester.pump();
    expect(s.retries, 1, reason: 'a resumed app looks for a car it lost at once');

    s.session.markRefused();
    await tester.pump();
    expect(find.text(t('companion.refused').toUpperCase()), findsOneWidget);
    await tester.tap(find.text(t('companion.pair_again')));
    await realTime(tester, find.byType(PairingScreen));
    expect(find.byType(PairingScreen), findsOneWidget);
    expect(store.car, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a paired car shows a spinner until its session is open', (tester) async {
    final store = MemoryStore(car: testCar());
    tester.view.physicalSize = const Size(420, 900);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(CompanionApp(
      store: store,
      loadTr: (lang) async => testTr,
      openSession: (car) => Future.delayed(const Duration(seconds: 1), () => TestSession(phase: TransportPhase.discovering).session),
    ));
    await tester.pump();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });

  test('Tr.english is what the tests read; the app loads per language', () {
    expect(testTr.lang, 'en');
    expect(Tr.languages, contains('en'));
  });
}
