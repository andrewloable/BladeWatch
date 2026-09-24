import 'dart:io';

import 'package:bladewatch_companion/app.dart';
import 'package:bladewatch_companion/car/car_store.dart';
import 'package:bladewatch_companion/i18n.dart';
import 'package:bladewatch_companion/screens/dashboard/dashboard_screen.dart';
import 'package:bladewatch_companion/screens/pairing/pairing_controller.dart';
import 'package:bladewatch_companion/screens/pairing/pairing_screen.dart';
import 'package:bladewatch_companion/screens/settings/settings_screen.dart';
import 'package:bladewatch_companion/screens/vehicle/vehicle_screen.dart';
import 'package:bladewatch_companion/transport/transport_selector.dart';
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
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('1'), findsOneWidget, reason: 'one alert above the cursor');

    await tester.tap(find.text(t('nav.more')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('more.vehicle')));
    await settle(tester);
    expect(find.byType(VehicleScreen), findsOneWidget);
    await tester.tap(find.text(t('nav.more')));
    await settle(tester);
    await tester.tapAt(const Offset(10, 10)); // dismissed: stays where it was
    await settle(tester);
    expect(find.byType(VehicleScreen), findsOneWidget);

    await tester.tap(find.text(t('nav.dashboard')));
    await settle(tester);
    expect(find.byType(DashboardScreen), findsOneWidget);

    await tester.tap(find.text(t('nav.more')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('more.settings')));
    await settle(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('wide: a permanent drawer with every place', (tester) async {
    await pumpApp(tester, MemoryStore(car: testCar()), size: const Size(1280, 900));
    expect(find.byType(NavigationDrawer), findsOneWidget);
    expect(find.text(t('nav.diagnostics')), findsOneWidget);
    await tester.tap(find.descendant(of: find.byType(NavigationDrawer), matching: find.text(t('nav.vehicle'))));
    await settle(tester);
    expect(find.byType(VehicleScreen), findsOneWidget);
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

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    expect(s.retries, 1, reason: 'a resumed phone looks for the car again');

    s.session.markRefused();
    await tester.pump();
    expect(find.text(t('companion.refused')), findsOneWidget);
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
