import 'dart:async';
import 'dart:io';

import 'package:bladewatch_companion/car/car_store.dart';
import 'package:bladewatch_companion/device_name.dart';
import 'package:bladewatch_companion/i18n.dart';
import 'package:bladewatch_companion/screens/pairing/pairing_controller.dart';
import 'package:bladewatch_companion/screens/pairing/pairing_screen.dart';
import 'package:bladewatch_companion/screens/pairing/qr_scan_page.dart';
import 'package:bladewatch_companion/transport/car_auth.dart';
import 'package:bladewatch_companion/transport/transport_selector.dart';
import 'package:bladewatch_companion/transport/wifi_pairing.dart';
import 'package:bladewatch_rpc/pairing/pairing_payload.dart';
import 'package:bladewatch_theme/hud_theme.dart';
import 'package:bladewatch_theme/hud_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support.dart';

String qr({DateTime? expires, String code = 'one-time'}) => PairingPayload(
      deviceId: 'dev-1',
      pearTopic: 'a' * 64,
      tlsPort: 8443,
      tlsFingerprint: 'b' * 64,
      probeKey: 'c' * 64,
      code: code,
      expiresAt: expires ?? DateTime.now().add(const Duration(minutes: 5)),
    ).encode();

/// A car's Wi-Fi pairing as the controller sees it. [results] answers each poll: null (the owner
/// has not answered), a payload, or something to throw.
class FakeWifi implements WifiPairing {
  FakeWifi({this.fingerprint = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb', this.startError, List<Object?>? results})
      : results = results ?? [];

  @override
  final PairingCar car = (address: InternetAddress.loopbackIPv4, port: 8443);
  @override
  final String? fingerprint;
  final Object? startError;
  final List<Object?> results;
  String? name;
  var closed = false;

  @override
  Future<String> start(String name) async {
    this.name = name;
    if (startError != null) throw startError!;
    return '482913';
  }

  @override
  Future<String?> result() async {
    final r = results.isEmpty ? null : results.removeAt(0);
    if (r is Exception || r is Error) throw r!;
    return r as String?;
  }

  @override
  void close() => closed = true;
}

void main() {
  hudTestEnvironment();

  group('PairingController', () {
    late TestSession s;
    late List<PairedCar> opened;
    late List<(Uri, String, String)> redeemed;

    PairingController controller({Future<CompanionCredential> Function(Uri, String, String)? redeem, Duration? timeout}) {
      s = TestSession(phase: TransportPhase.discovering);
      opened = [];
      redeemed = [];
      return PairingController(
        openSession: (car) async {
          opened.add(car);
          return s.session;
        },
        redeem: redeem ??
            (url, code, name) async {
              redeemed.add((url, code, name));
              return testCredential;
            },
        findTimeout: timeout ?? const Duration(seconds: 5),
      );
    }

    test('finds the car, redeems the code there, and returns the paired car', () async {
      final c = controller();
      final steps = <PairingStep>[];
      c.addListener(() => steps.add(c.step));
      final pairing = c.pair(qr(), '  My phone ');
      await Future<void>.delayed(Duration.zero);
      expect(c.busy, isTrue);
      expect(opened.single.credential.token, isEmpty, reason: 'no credential before the code is redeemed');
      s.phases.add(TransportPhase.lan);

      final car = await pairing;
      expect(car!.deviceId, 'dev-1');
      expect(car.credential.token, 'tok');
      expect(redeemed.single.$2, 'one-time');
      expect(redeemed.single.$3, 'My phone');
      expect(steps, [PairingStep.connecting, PairingStep.redeeming, PairingStep.idle]);
    });

    test('refuses bad and expired codes without touching the network', () async {
      final c = controller();
      expect(await c.pair('not a code', 'x'), isNull);
      expect(c.error, 'companion.pair_bad_code');
      expect(await c.pair(qr(expires: DateTime.now().subtract(const Duration(seconds: 1))), 'x'), isNull);
      expect(c.error, 'companion.pair_expired');
      expect(c.step, PairingStep.failed);
      expect(opened, isEmpty);
    });

    test('a car that never answers, a used code and any other failure each say so', () async {
      final c = controller(timeout: const Duration(milliseconds: 50));
      expect(await c.pair(qr(), 'x'), isNull);
      expect(c.error, 'companion.pair_not_found');

      final refused = controller(redeem: (u, code, n) async => throw const CarAuthRefused('pairing_code_refused'));
      final a = refused.pair(qr(), 'x');
      s.phases.add(TransportPhase.pear);
      expect(await a, isNull);
      expect(refused.error, 'companion.pair_refused');

      final other = controller(redeem: (u, code, n) async => throw const CarAuthRefused('Locked for 30s'));
      final b = other.pair(qr(), 'x');
      s.phases.add(TransportPhase.lan);
      expect(await b, isNull);
      expect(other.error, 'errors.generic');

      final broken = controller(redeem: (u, code, n) async => throw StateError('socket'));
      final d = broken.pair(qr(), 'x');
      s.phases.add(TransportPhase.lan);
      expect(await d, isNull);
      expect(broken.error, 'errors.generic');
    });

    test('by default the code is redeemed at the car through the session\'s gateway', () async {
      final c = PairingController(openSession: (car) async => TestSession(phase: TransportPhase.lan).session);
      expect(await c.pair(qr(), 'x'), isNull, reason: 'nothing listens at the test gateway');
      expect(c.error, 'errors.generic');
    });

    test('an already-connected session skips the wait', () async {
      final c = PairingController(
        openSession: (car) async => TestSession(phase: TransportPhase.lan).session,
        redeem: (u, code, n) async => testCredential,
      );
      expect(await c.pair(qr(), 'x'), isNotNull);
    });
  });

  // Owner request 2026-09-27: the car's list shows this device by its own name, not "Mac".
  // BladeWatch 1.4.1.2: pairing without a camera, by number over the car's Wi-Fi.
  group('Wi-Fi pairing', () {
    final car = (address: InternetAddress.loopbackIPv4, port: 8443);
    late TestSession s;
    late List<(Uri, String, String)> redeemed;
    late FakeWifi wifi;
    late int searches;

    PairingController controller({List<PairingCar?>? found, FakeWifi? w, Duration search = const Duration(seconds: 5), Duration poll = Duration.zero}) {
      s = TestSession();
      redeemed = [];
      wifi = w ?? FakeWifi(results: [null, qr()]);
      searches = 0;
      final answers = [...?found];
      return PairingController(
        openSession: (car) async => s.session,
        redeem: (url, code, name) async {
          redeemed.add((url, code, name));
          return testCredential;
        },
        findWifiCar: () async {
          searches++;
          return answers.isEmpty ? null : answers.removeAt(0);
        },
        openWifi: (car) => wifi,
        searchTimeout: search,
        pollInterval: poll,
      );
    }

    test('finds the car, shows the number, and once the owner confirms redeems the payload like a QR', () async {
      final c = controller(found: [null, car]);
      final steps = <PairingStep>[];
      String? shown;
      c.addListener(() {
        steps.add(c.step);
        if (c.step == PairingStep.comparing) shown = c.number;
      });
      final paired = await c.pairOverWifi('  Living room TV ');
      expect(paired?.deviceId, 'dev-1');
      expect(paired?.lanHint, '127.0.0.1', reason: 'the session probes the address that answered first');
      expect(searches, 2, reason: 'silence is the normal "not yet": it keeps looking');
      expect(wifi.name, 'Living room TV');
      expect(shown, '482913');
      expect(redeemed.single.$2, 'one-time');
      expect(wifi.closed, isTrue);
      expect(c.number, isNull);
      expect(steps.first, PairingStep.searching);
      expect(steps, containsAllInOrder([PairingStep.comparing, PairingStep.connecting, PairingStep.redeeming, PairingStep.idle]));
    });

    test('no car with pairing open on this Wi-Fi says so after one search at least', () async {
      final c = controller(search: Duration.zero);
      expect(await c.pairOverWifi('TV'), isNull);
      expect(c.error, 'companion.wifi_not_found');
      expect(searches, 1);
    });

    test('a payload for another certificate than the one the number covers is refused', () async {
      final c = controller(found: [car], w: FakeWifi(fingerprint: 'c' * 64, results: [qr()]));
      expect(await c.pairOverWifi('TV'), isNull);
      expect(c.error, 'companion.wifi_refused');
      expect(redeemed, isEmpty);
    });

    test('a car not ready, a refusal in the car, and anything else each say so', () async {
      final busy = controller(found: [car], w: FakeWifi(startError: const WifiPairingRefused('wifi_pairing_closed')));
      expect(await busy.pairOverWifi('TV'), isNull);
      expect(busy.error, 'companion.wifi_busy');
      expect(wifi.closed, isTrue);

      final refused = controller(found: [car], w: FakeWifi(results: [null, const WifiPairingRefused('wifi_pairing_refused')]));
      expect(await refused.pairOverWifi('TV'), isNull);
      expect(refused.error, 'companion.wifi_refused');
      expect(refused.number, isNull);

      final broken = controller(found: [car], w: FakeWifi(startError: StateError('socket')));
      expect(await broken.pairOverWifi('TV'), isNull);
      expect(broken.error, 'errors.generic');
    });

    test('cancel stops it while searching and while waiting for the owner', () async {
      late PairingController c;
      c = PairingController(
        openSession: (car) async => TestSession().session,
        findWifiCar: () async {
          c.cancel();
          return null;
        },
      );
      expect(await c.pairOverWifi('TV'), isNull);
      expect(c.step, PairingStep.idle);
      expect(c.error, isNull);

      final waiting = controller(found: [car], w: FakeWifi(results: List.filled(1000, null, growable: true)));
      waiting.addListener(() {
        if (waiting.step == PairingStep.comparing) waiting.cancel();
      });
      expect(await waiting.pairOverWifi('TV'), isNull);
      expect(waiting.step, PairingStep.idle);
      expect(waiting.number, isNull);
      expect(wifi.closed, isTrue);
    });

    testWidgets('on a TV or desktop the screen offers it, shows the number to compare, and can cancel', (tester) async {
      final c = controller(found: [car], w: FakeWifi(results: List.filled(1000, null, growable: true)), poll: const Duration(milliseconds: 100));
      await tester.pumpWidget(MaterialApp(
        theme: BwHud.themeData(Brightness.dark),
        home: TrScope(tr: testTr, child: PairingScreen(controller: c, onPaired: (_) {}, wifi: true, defaultName: 'TV')),
      ));
      expect(find.text(t('companion.wifi_pair_hint')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pair.wifi')));
      await tester.pump();
      await tester.pump();
      expect(find.text('482 913'), findsOneWidget);
      expect(find.text(t('companion.wifi_compare')), findsOneWidget);
      expect(find.text(t('companion.wifi_waiting')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('pair.cancel')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const ValueKey('pair.number')), findsNothing);
      expect(c.step, PairingStep.idle);
    });

    testWidgets('a confirmed Wi-Fi pairing lands on the paired car, and phones never see it', (tester) async {
      final c = controller(found: [car]);
      final paired = <PairedCar>[];
      await tester.pumpWidget(MaterialApp(
        theme: BwHud.themeData(Brightness.dark),
        home: TrScope(tr: testTr, child: PairingScreen(controller: c, onPaired: paired.add, wifi: true, defaultName: 'TV')),
      ));
      await tester.tap(find.byKey(const ValueKey('pair.wifi')));
      await tester.pumpAndSettle();
      expect(paired.single.deviceId, 'dev-1');

      await tester.pumpWidget(MaterialApp(
        theme: BwHud.themeData(Brightness.dark),
        home: TrScope(tr: testTr, child: PairingScreen(controller: controller(), onPaired: (_) {}, defaultName: 'Phone')),
      ));
      expect(find.byKey(const ValueKey('pair.wifi')), findsNothing);
      expect(find.text(t('companion.pair_hint')), findsOneWidget);
    });
  });

  group('device name', () {
    test('the platform\'s name, trimmed; the generic one when it says nothing or fails', () async {
      expect(await deviceName('Mac', read: () async => "  Andrew's MacBook Pro "), "Andrew's MacBook Pro");
      expect(await deviceName('Mac', read: () async => '  '), 'Mac');
      expect(await deviceName('Mac', read: () async => null), 'Mac');
      expect(await deviceName('Mac', read: () async => throw StateError('no plugin')), 'Mac');
    });

    Future<void> pumpDetecting(WidgetTester tester, Future<String> Function(String) detect) async {
      final s = TestSession(phase: TransportPhase.lan);
      final c = PairingController(openSession: (car) async => s.session, redeem: (u, code, n) async => testCredential);
      await tester.pumpWidget(MaterialApp(
        theme: BwHud.themeData(Brightness.dark),
        home: TrScope(tr: testTr, child: PairingScreen(controller: c, onPaired: (_) {}, detectName: detect)),
      ));
    }

    String field(WidgetTester tester) =>
        tester.widget<TextField>(find.byKey(const ValueKey('pair.name'))).controller!.text;

    testWidgets('the screen pre-fills the detected name', (tester) async {
      String? askedWith;
      await pumpDetecting(tester, (generic) async {
        askedWith = generic;
        return 'Studio Mac';
      });
      await tester.pump();
      expect(askedWith, isNotEmpty, reason: 'the generic name is the fallback');
      expect(field(tester), 'Studio Mac');
    });

    testWidgets('a name typed before detection finishes is kept', (tester) async {
      final detected = Completer<String>();
      await pumpDetecting(tester, (_) => detected.future);
      await tester.enterText(find.byKey(const ValueKey('pair.name')), 'My laptop');
      detected.complete('Studio Mac');
      await tester.pump();
      expect(field(tester), 'My laptop');
    });
  });

  group('PairingScreen', () {
    Future<(PairingController, List<PairedCar>)> pump(WidgetTester tester, {Future<String?> Function(BuildContext)? scan}) async {
      final s = TestSession(phase: TransportPhase.lan);
      final paired = <PairedCar>[];
      final c = PairingController(openSession: (car) async => s.session, redeem: (u, code, n) async => testCredential);
      await tester.pumpWidget(MaterialApp(
        theme: BwHud.themeData(Brightness.dark),
        home: TrScope(tr: testTr, child: PairingScreen(controller: c, onPaired: paired.add, scan: scan, defaultName: 'Test phone')),
      ));
      return (c, paired);
    }

    testWidgets('pasting the code pairs; a bad paste explains why', (tester) async {
      final (_, paired) = await pump(tester);
      expect(find.byKey(const ValueKey('pair.scan')), findsNothing, reason: 'no camera scanner on this platform');
      expect(find.text('Test phone'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('pair.code')), 'garbage');
      await tester.tap(find.byKey(const ValueKey('pair.submit')));
      await tester.pump();
      expect(find.text(t('companion.pair_bad_code')), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('pair.code')), qr());
      await tester.tap(find.byKey(const ValueKey('pair.submit')));
      await tester.pumpAndSettle();
      expect(paired.single.deviceId, 'dev-1');
      expect(find.byKey(const ValueKey('pair.error')), findsNothing);
    });

    testWidgets('HUD: the title bar names the page, the form is one panel, a bad paste is magenta', (tester) async {
      await pump(tester);
      expect(find.descendant(of: find.byType(HudTitleBar), matching: find.text(t('companion.pair_title').toUpperCase())), findsOneWidget);
      expect(find.byType(HudPanel), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('pair.code')), 'garbage');
      await tester.tap(find.byKey(const ValueKey('pair.submit')));
      await tester.pump();
      expect(tester.widget<Text>(find.byKey(const ValueKey('pair.error'))).style!.color, BwHud.dark.magenta);
    });

    testWidgets('scanning fills in the code and pairs; a cancelled scan does nothing', (tester) async {
      final answers = [null, qr()];
      final (_, paired) = await pump(tester, scan: (_) async => answers.removeAt(0));
      await tester.tap(find.byKey(const ValueKey('pair.scan')));
      await tester.pumpAndSettle();
      expect(paired, isEmpty);
      await tester.tap(find.byKey(const ValueKey('pair.scan')));
      await tester.pumpAndSettle();
      expect(paired, hasLength(1));
    });

    testWidgets('while it looks for the car the form is locked and says so', (tester) async {
      final session = TestSession(phase: TransportPhase.discovering);
      final gate = Completer<CompanionCredential>();
      final c = PairingController(openSession: (car) async => session.session, redeem: (u, code, n) => gate.future);
      await tester.pumpWidget(MaterialApp(
        home: TrScope(tr: testTr, child: PairingScreen(controller: c, onPaired: (_) {}, defaultName: 'x')),
      ));
      await tester.enterText(find.byKey(const ValueKey('pair.code')), qr());
      await tester.tap(find.byKey(const ValueKey('pair.submit')));
      await tester.pump();
      expect(find.text(t('companion.pair_finding')), findsOneWidget);
      expect(tester.widget<OutlinedButton>(find.byKey(const ValueKey('pair.submit'))).onPressed, isNull);
      session.phases.add(TransportPhase.lan);
      await tester.pump();
      await tester.pump();
      expect(find.text(t('companion.pair_redeeming')), findsOneWidget);
      gate.complete(testCredential);
      await tester.pumpAndSettle();
    });

    testWidgets('the default device name comes from the platform', (tester) async {
      final c = PairingController(openSession: (car) async => TestSession().session);
      await tester.pumpWidget(MaterialApp(home: TrScope(tr: testTr, child: PairingScreen(controller: c, onPaired: (_) {}))));
      expect(tester.widget<TextField>(find.byKey(const ValueKey('pair.name'))).controller!.text, isNotEmpty);
    });
  });

  testWidgets('the scanner takes the first code only, and closing it gives nothing', (tester) async {
    final results = <String?>[];
    late void Function(String) report;
    await tester.pumpWidget(MaterialApp(
      home: TrScope(
        tr: testTr,
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () async => results.add(await Navigator.of(context).push<String>(MaterialPageRoute(
              builder: (_) => TrScope(tr: testTr, child: QrScanPage(scanner: (onCode) {
                report = onCode;
                return const Text('camera');
              })),
            ))),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('camera'), findsOneWidget);
    report('first');
    report('second');
    await tester.pumpAndSettle();
    expect(results, ['first']);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(results, ['first', null]);
  });

  testWidgets('the scan page has the HUD back arrow and frames the camera', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: BwHud.themeData(Brightness.dark),
      home: TrScope(tr: testTr, child: QrScanPage(scanner: (_) => const Text('camera'))),
    ));
    expect(find.byKey(const ValueKey('hud.back')), findsOneWidget);
    expect(find.descendant(of: find.byType(HudPanel), matching: find.text('camera')), findsOneWidget);
    expect(tester.widget<HudPanel>(find.byType(HudPanel)).borderColor, BwHud.dark.accent);
  });

  testWidgets('scanPairingQr opens the scan page', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TrScope(
        tr: testTr,
        child: Builder(builder: (context) => TextButton(onPressed: () => scanPairingQr(context), child: const Text('open'))),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(QrScanPage), findsOneWidget);
    expect(find.descendant(of: find.byType(HudTitleBar), matching: find.text(t('companion.pair_scan').toUpperCase())), findsOneWidget);
  });
}

