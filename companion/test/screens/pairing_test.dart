import 'dart:async';

import 'package:bladewatch_companion/car/car_store.dart';
import 'package:bladewatch_companion/i18n.dart';
import 'package:bladewatch_companion/screens/pairing/pairing_controller.dart';
import 'package:bladewatch_companion/screens/pairing/pairing_screen.dart';
import 'package:bladewatch_companion/screens/pairing/qr_scan_page.dart';
import 'package:bladewatch_companion/transport/car_auth.dart';
import 'package:bladewatch_companion/transport/transport_selector.dart';
import 'package:bladewatch_rpc/pairing/pairing_payload.dart';
import 'package:bladewatch_theme/bladewatch_theme.dart';
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

void main() {
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

  group('PairingScreen', () {
    Future<(PairingController, List<PairedCar>)> pump(WidgetTester tester, {Future<String?> Function(BuildContext)? scan}) async {
      final s = TestSession(phase: TransportPhase.lan);
      final paired = <PairedCar>[];
      final c = PairingController(openSession: (car) async => s.session, redeem: (u, code, n) async => testCredential);
      await tester.pumpWidget(MaterialApp(
        theme: BladeWatchTheme.dark(),
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
    expect(find.text(t('companion.pair_scan')), findsOneWidget);
  });
}

