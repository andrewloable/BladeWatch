import 'package:bladewatch_companion/car/car_page.dart';
import 'package:bladewatch_companion/car/car_session.dart';
import 'package:bladewatch_companion/i18n.dart';
import 'package:bladewatch_rpc/rpc/connect_error.dart';
import 'package:bladewatch_rpc/rpc/rpc_transport.dart';
import 'package:bladewatch_companion/transport/transport_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support.dart';

void main() {
  Future<TestSession> pumpPage(WidgetTester tester, TransportPhase phase, {VoidCallback? onPairAgain}) async {
    final s = TestSession(phase: phase);
    await pumpScreen(tester, s, CarPage(onPairAgain: onPairAgain, child: const Text('the screen')));
    return s;
  }

  testWidgets('connected shows the screen', (tester) async {
    await pumpPage(tester, TransportPhase.lan);
    expect(find.text('the screen'), findsOneWidget);
  });

  testWidgets('looking, then reconnecting after having connected -- distinct from unreachable', (tester) async {
    final s = await pumpPage(tester, TransportPhase.discovering);
    expect(find.text(t('companion.looking')), findsOneWidget);
    expect(find.text('the screen'), findsNothing);

    await s.go(tester, TransportPhase.pear);
    expect(find.text('the screen'), findsOneWidget);
    await s.go(tester, TransportPhase.discovering);
    expect(find.text(t('companion.reconnecting')), findsOneWidget);

    await s.go(tester, TransportPhase.failed);
    expect(find.text(t('companion.unreachable')), findsOneWidget);
    await tester.tap(find.text(t('common.retry')));
    expect(s.retries, 1);
  });

  testWidgets('reached but not answering hides the stale screen until the car answers (yzuc)', (tester) async {
    final car = _Silent();
    final s = TestSession(phase: TransportPhase.pear);
    final session = CarSession(
      rpc: car,
      baseUrl: Uri.parse('http://x'),
      jwt: () async => null,
      initialPhase: TransportPhase.pear,
      probeEvery: const Duration(seconds: 1),
    );
    await tester.pumpWidget(MaterialApp(
      builder: (context, nav) => TrScope(tr: testTr, child: nav!),
      home: SessionScope(session: session, child: const Scaffold(body: CarPage(child: Text('the screen')))),
    ));
    expect(find.text('the screen'), findsOneWidget);
    await expectLater(session.rpc.call('A', 'B', null, (j) => j), throwsA(anything));
    await tester.pump();
    expect(find.text(t('companion.not_answering')), findsOneWidget);
    expect(find.text('the screen'), findsNothing);

    car.silent = false;
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('the screen'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    session.dispose();
    s.session.dispose();
  });

  testWidgets('a car that removed this device offers pairing again, whatever the route', (tester) async {
    var paired = 0;
    final s = await pumpPage(tester, TransportPhase.lan, onPairAgain: () => paired++);
    s.session.markRefused();
    await tester.pump();
    expect(find.text(t('companion.refused')), findsOneWidget);
    await tester.tap(find.text(t('companion.pair_again')));
    expect(paired, 1);
  });

  testWidgets('LoadError says what failed and retries', (tester) async {
    var retried = 0;
    await pumpScreen(tester, TestSession(), LoadError(onRetry: () => retried++));
    expect(find.text(t('errors.load_failed')), findsOneWidget);
    await tester.tap(find.text(t('common.retry')));
    expect(retried, 1);
  });
}

class _Silent implements RpcTransport {
  bool silent = true;

  @override
  Future<T> call<T>(String service, String method, Object? request, T Function(Object? json) decode) async {
    if (silent) throw const ConnectError(httpStatus: 0, code: 'unavailable', message: 'nothing behind the gateway');
    return decode(<String, dynamic>{});
  }
}
