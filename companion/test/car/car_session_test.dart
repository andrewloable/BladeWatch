import 'dart:async';
import 'dart:io';

import 'package:bladewatch_companion/car/car_session.dart';
import 'package:bladewatch_companion/transport/car_auth.dart';
import 'package:bladewatch_companion/transport/transport_selector.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/system.pb.dart';
import 'package:bladewatch_rpc/rpc/connect_error.dart';
import 'package:bladewatch_rpc/rpc/raw_http_sender.dart';
import 'package:bladewatch_rpc/rpc/rpc_transport.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support.dart';

void main() {
  // BladeWatch-rdtj.36: resuming the app used to restart a healthy link every time.
  group('resumed', () {
    var retries = 0;
    CarSession make(RpcTransport rpc, {TransportPhase phase = TransportPhase.pear}) => CarSession(
          rpc: rpc,
          baseUrl: Uri.parse('http://127.0.0.1:9'),
          jwt: () async => 'jwt',
          initialPhase: phase,
          retry: () => retries++,
        );
    setUp(() => retries = 0);

    test('a link that answers is left alone', () async {
      final rpc = _Scripted(() async => <String, Object?>{});
      await make(rpc).resumed();
      expect(rpc.calls, 1);
      expect(retries, 0);
    });

    test('a car that answers with an error is still reachable', () async {
      await make(_Scripted(() async => throw const ConnectError(httpStatus: 401, code: 'unauthenticated', message: ''))).resumed();
      expect(retries, 0);
    });

    test('no answer through the link looks for the car again', () async {
      await make(_Scripted(() async => throw const ConnectError(httpStatus: 0, code: 'unavailable', message: 'reset'))).resumed();
      expect(retries, 1);
    });

    test('a link that never answers looks again once the check times out', () async {
      await make(_Scripted(() => Completer<Object?>().future)).resumed(timeout: const Duration(milliseconds: 20));
      expect(retries, 1);
    });

    test('a route that is down is looked for at once, without asking the car', () async {
      final rpc = _Scripted(() async => <String, Object?>{});
      await make(rpc, phase: TransportPhase.discovering).resumed();
      expect(retries, 1);
      expect(rpc.calls, 0);
    });
  });

  // BladeWatch-rdtj.53: a stopped pear_daemon went unnoticed for 14-18 s. Silence is now asked
  // about after 2 s, and two unanswered questions in a row mean the car is not answering.
  group('a car that goes quiet', () {
    CarSession watched(RpcTransport rpc, {TransportPhase phase = TransportPhase.pear}) => CarSession(
          rpc: rpc,
          baseUrl: Uri.parse('http://127.0.0.1:9'),
          jwt: () async => 'jwt',
          initialPhase: phase,
          quietAfter: const Duration(seconds: 2),
          probeTimeout: const Duration(seconds: 2),
        );

    testWidgets('is noticed in about 6 s, and back as soon as it answers', (tester) async {
      final car = _Quiet();
      final s = watched(car);
      await tester.pump(const Duration(seconds: 5));
      expect(s.answering, isTrue);
      expect(car.asked, greaterThan(0), reason: 'a quiet healthy car is asked, and answers');
      car.silent = true;
      final silentAt = car.asked;
      await tester.pump(const Duration(milliseconds: 4500));
      expect(s.answering, isTrue, reason: 'one unanswered question is not enough');
      await tester.pump(const Duration(seconds: 2));
      expect(s.answering, isFalse, reason: 'two in a row, about 6 s after the last answer');
      expect(car.asked - silentAt, 2);
      car.silent = false;
      await tester.pump(const Duration(seconds: 4)); // the not-answering probe (probeEvery 3 s)
      expect(s.answering, isTrue);
      s.dispose();
    });

    testWidgets('one slow answer does not flip it; an HTTP error is an answer', (tester) async {
      final car = _Quiet()..hangNext = 1;
      final s = watched(car);
      final seen = <bool>[];
      s.addListener(() => seen.add(s.answering));
      await tester.pump(const Duration(seconds: 10));
      expect(car.asked, greaterThan(2));
      expect(seen, isNot(contains(false)), reason: 'the second question was answered: never shown as silent, not even briefly');
      s.dispose();

      final refusing = _ScriptedCar()
        ..answer = false
        ..status = 401;
      final r = watched(refusing);
      await tester.pump(const Duration(seconds: 10));
      expect(r.answering, isTrue);
      r.dispose();
    });

    testWidgets('nothing is asked while the route is down or the app is in the background', (tester) async {
      final car = _Quiet();
      final down = watched(car, phase: TransportPhase.discovering);
      await tester.pump(const Duration(seconds: 10));
      expect(car.asked, 0);
      down.dispose();

      final s = watched(car);
      await tester.pump(const Duration(seconds: 3));
      final before = car.asked;
      s.paused();
      await tester.pump(const Duration(seconds: 10));
      expect(car.asked, before);
      await s.resumed(); // the resume check itself asks once
      await tester.pump(const Duration(seconds: 3));
      expect(car.asked, greaterThan(before + 1), reason: 'watching again');
      s.dispose();
    });

    // BladeWatch-a7ev: the speed test fills the link, so the watch's own question queued behind it,
    // timed out twice, and a healthy car was shown as silent -- CarPage then swapped the screen out,
    // and the result with it.
    testWidgets('a transfer that fills the link is not mistaken for a silent car', (tester) async {
      final car = _Quiet()..silent = true;
      final s = watched(car);
      final done = Completer<void>();
      final run = s.duringBulkTransfer(() => done.future);
      expect(s.bulkTransfer, isTrue);
      await tester.pump(const Duration(seconds: 10));
      expect(s.answering, isTrue);
      expect(car.asked, 0, reason: 'nothing is asked while the link is full');

      done.complete();
      await run;
      expect(s.bulkTransfer, isFalse);
      await tester.pump(const Duration(seconds: 8));
      expect(s.answering, isFalse, reason: 'a dead car is still noticed once the transfer is over');
      s.dispose();
    });

    testWidgets('an RPC that fails behind the transfer is not a silent car either, but only while it runs', (tester) async {
      final car = _ScriptedCar()..answer = false; // status 0: no HTTP answer at all
      final s = watched(car);
      final done = Completer<void>();
      final run = s.duringBulkTransfer(() => done.future);

      await expectLater(s.rpc.call('StreamService', 'GetQuality', null, (j) => j), throwsA(isA<ConnectError>()));
      expect(s.answering, isTrue);

      done.complete();
      await run;
      await expectLater(s.rpc.call('StreamService', 'GetQuality', null, (j) => j), throwsA(isA<ConnectError>()));
      expect(s.answering, isFalse);
      s.dispose();
    });

    testWidgets('the hold ends when the body throws, and overlapping transfers hold until both are done', (tester) async {
      final s = watched(_Quiet());
      await expectLater(s.duringBulkTransfer<void>(() async => throw StateError('x')), throwsStateError);
      expect(s.bulkTransfer, isFalse);

      final a = Completer<void>();
      final b = Completer<void>();
      final ra = s.duringBulkTransfer(() => a.future);
      final rb = s.duringBulkTransfer(() => b.future);
      a.complete();
      await ra;
      expect(s.bulkTransfer, isTrue, reason: 'the second transfer is still running');
      b.complete();
      await rb;
      expect(s.bulkTransfer, isFalse);
      s.dispose();
    });
  });

  // BladeWatch-rdtj.38: the car's own Wi-Fi address, learned when the route comes up.
  group('carLanAddress', () {
    Future<CarSession> reach(Map<String, Object?> network) async {
      final s = TestSession(phase: TransportPhase.discovering);
      s.rpc.stubJson('SystemService', 'GetStatus', {'network': network});
      s.phases.add(TransportPhase.pear);
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      return s.session;
    }

    test('is learned from the car when it is on Wi-Fi', () async {
      final session = await reach({'type': 'wifi', 'ip': '192.0.2.7'});
      expect(session.carLanAddress, '192.0.2.7');
    });

    test('is not a cellular address, which is private too but on no LAN', () async {
      final session = await reach({'type': 'cellular', 'ip': '10.1.2.3'});
      expect(session.carLanAddress, isNull);
    });

    test('a status that fails leaves it unknown', () async {
      final s = TestSession(phase: TransportPhase.discovering);
      s.phases.add(TransportPhase.pear);
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(s.session.carLanAddress, isNull);
    });
  });

  group('CarSession', () {
    test('tracks the phase, remembers having connected, and reports a refusal once', () async {
      final s = TestSession(phase: TransportPhase.discovering);
      final session = s.session;
      var notified = 0;
      session.addListener(() => notified++);
      expect(session.connected, isFalse);
      expect(session.everConnected, isFalse);

      s.phases.add(TransportPhase.pear);
      await Future<void>.delayed(Duration.zero);
      expect(session.connected, isTrue);
      s.phases.add(TransportPhase.discovering);
      await Future<void>.delayed(Duration.zero);
      expect(session.connected, isFalse);
      expect(session.everConnected, isTrue, reason: 'looking again now reads as reconnecting');

      session.markRefused();
      session.markRefused();
      expect(session.refused, isTrue);
      expect(notified, 3, reason: 'two phase changes and ONE refusal');

      session.retry();
      expect(s.retries, 1);
      expect(await session.authHeaders(), {'Authorization': 'Bearer jwt'});
      expect(session.withHeaders({'X': '1'}), same(s.rpc));
      expect(s.headerCalls.single, {'X': '1'});
      session.dispose();
    });

    test('a session with no header transport falls back to its own rpc; no JWT means no header', () {
      final session = CarSession(rpc: TestSession().rpc, baseUrl: Uri.parse('http://x'), jwt: () async => null);
      expect(session.withHeaders({'X': '1'}), same(session.rpc));
      expect(session.authHeaders(), completion(isEmpty));
      session.retry(); // no-op without a selector
      session.dispose();
    });

    test('open: no LAN and no Pear is "failed", and the session tears its gateway down', () async {
      final session = await CarSession.open(
        testCar(),
        findOnLan: () async => null,
        joinTopic: (_) async => throw StateError('no Pear here'),
        networkChanges: const Stream.empty(),
      );
      expect(session.baseUrl.host, '127.0.0.1');
      while (session.phase != TransportPhase.failed) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(session.connected, isFalse);
      // The login cannot reach a car through an unrouted gateway: no token, no crash.
      expect(await session.authHeaders(), isEmpty);
      final withToken = session.withHeaders({'X-Vehicle-Action-Token': 't'});
      expect(withToken, isNot(same(session.rpc)));
      // Unrouted gateway: the call fails, but it runs the shared-JWT and header path end to end.
      await expectLater(
        withToken.call('SystemService', 'GetStatus', GetStatusRequest(), (j) => j),
        throwsA(isA<ConnectError>()),
      );
      session.retry();
      session.dispose();
    });

    test('withExtraHeaders adds the action token and keeps what the client set', () async {
      Map<String, String>? sent;
      final send = withExtraHeaders((uri, headers, body) async {
        sent = headers;
        return const RawHttpResponse(200, '{}');
      }, {'X-Vehicle-Action-Token': 'act'});
      await send(Uri.parse('http://car/x'), {'Authorization': 'Bearer j', 'Content-Type': 'application/json'}, '{}');
      expect(sent, {'Authorization': 'Bearer j', 'Content-Type': 'application/json', 'X-Vehicle-Action-Token': 'act'});
    });
  });

  group('answering (BladeWatch-yzuc)', () {
    test('no answer at all marks the car silent, a probe runs until it answers, then stops', () async {
      final car = _ScriptedCar();
      final s = TestSession();
      final session = CarSession(
        rpc: car,
        baseUrl: Uri.parse('http://x'),
        jwt: () async => null,
        initialPhase: TransportPhase.pear,
        probeEvery: const Duration(milliseconds: 20),
      );
      final changes = <bool>[];
      session.addListener(() => changes.add(session.answering));

      car.answer = false;
      await expectLater(session.rpc.call('SystemService', 'GetStatus', GetStatusRequest(), (j) => j), throwsA(isA<ConnectError>()));
      expect(session.answering, isFalse);
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(car.asked.where((m) => m == 'GetQuality').length, greaterThanOrEqualTo(2), reason: 'probing while silent');

      car.answer = true;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(session.answering, isTrue);
      final probes = car.asked.length;
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(car.asked.length, probes, reason: 'the probe stops once the car answers');
      expect(changes, [false, true]);
      session.dispose();
      s.session.dispose();
    });

    test('an HTTP error is an answer; losing the route hands over to the route state', () async {
      final car = _ScriptedCar()..status = 401;
      final phases = StreamController<TransportPhase>();
      final session = CarSession(
        rpc: car,
        baseUrl: Uri.parse('http://x'),
        jwt: () async => null,
        phases: phases.stream,
        initialPhase: TransportPhase.lan,
        probeEvery: const Duration(hours: 1),
      );
      car.answer = false;
      await expectLater(session.rpc.call('A', 'B', GetStatusRequest(), (j) => j), throwsA(isA<ConnectError>()));
      expect(session.answering, isTrue, reason: 'a 401 came back: the car answered');

      car.status = 0;
      await expectLater(session.rpc.call('A', 'B', GetStatusRequest(), (j) => j), throwsA(isA<ConnectError>()));
      expect(session.answering, isFalse);
      phases.add(TransportPhase.failed);
      await Future<void>.delayed(Duration.zero);
      expect(session.answering, isTrue, reason: 'unreachable is said by the route state instead');
      session.dispose();
      await phases.close();
    });
  });

  group('CompanionLogin', () {
    RawHttpSender answering(List<String> bodies, List<Uri> seen) => (uri, headers, body) async {
          seen.add(uri);
          return RawHttpResponse(200, bodies.removeAt(0));
        };

    test('a car that no longer knows this device is reported once and never asked again', () async {
      final seen = <Uri>[];
      var refused = 0;
      final login = CompanionLogin(
        CarAuth(Uri.parse('http://car'), send: answering(['{"success":false,"error":"companion_refused"}'], seen)),
        testCredential,
        () => refused++,
      );
      expect(await login.mintJwt(), isNull);
      expect(await login.mintJwt(), isNull);
      expect(refused, 1);
      expect(seen, hasLength(1), reason: 'a retry per RPC would trip the car lockout for everyone');
      expect(await login.stateVersion(), 0);
    });

    // BladeWatch-w7by: auth_unavailable is the car saying it cannot tell right now (secret store
    // unreadable, auth not loaded after a restart) -- retry, never "removed".
    test('a rate limit, a car that cannot tell yet, or an unreachable car is not a refusal', () async {
      final seen = <Uri>[];
      var refused = 0;
      final login = CompanionLogin(
        CarAuth(Uri.parse('http://car'),
            send: answering(
                ['{"success":false,"error":"Locked for 30s"}', 'not json', '{"success":false,"error":"auth_unavailable"}'], seen)),
        testCredential,
        () => refused++,
      );
      expect(await login.mintJwt(), isNull);
      expect(await login.mintJwt(), isNull);
      expect(await login.mintJwt(), isNull);
      final down = CompanionLogin(
        CarAuth(Uri.parse('http://car'), send: (u, h, b) async => throw const SocketException('down')),
        testCredential,
        () => refused++,
      );
      expect(await down.mintJwt(), isNull);
      expect(refused, 0);
      expect(seen, hasLength(3), reason: 'each answer was a real attempt, and none latched');
    });

    test('cached reuses a JWT for 4 minutes, then logs in again', () async {
      final seen = <Uri>[];
      var now = DateTime(2026, 9, 24, 12);
      final login = CompanionLogin(
        CarAuth(Uri.parse('http://car'), send: answering(['{"success":true,"jwt":"j1"}', '{"success":true,"jwt":"j2"}'], seen)),
        testCredential,
        () {},
        now: () => now,
      );
      expect(await login.cached(), 'j1');
      now = now.add(const Duration(minutes: 3));
      expect(await login.cached(), 'j1');
      now = now.add(const Duration(minutes: 2));
      expect(await login.cached(), 'j2');
      expect(seen, hasLength(2));
    });
  });
}

/// A car that answers or not on command, failing like the gateway does when nothing is behind it.
class _ScriptedCar implements RpcTransport {
  bool answer = true;
  int status = 0;
  final asked = <String>[];

  @override
  Future<T> call<T>(String service, String method, Object? request, T Function(Object? json) decode) async {
    asked.add(method);
    if (!answer) throw ConnectError(httpStatus: status, code: status == 0 ? 'unavailable' : 'unauthenticated', message: 'x');
    return decode(<String, dynamic>{});
  }
}


/// Answers every call with [answer] (BladeWatch-rdtj.36's resume check).
class _Scripted implements RpcTransport {
  _Scripted(this.answer);

  final Future<Object?> Function() answer;
  var calls = 0;

  @override
  Future<T> call<T>(String service, String method, Object? request, T Function(Object? json) decode) async {
    calls++;
    return decode(await answer());
  }
}

/// A car that answers until [silent], and then never does -- a dead Pear link hangs, it does not
/// fail. [hangNext] makes that many calls hang even while it is not silent.
class _Quiet implements RpcTransport {
  bool silent = false;
  int hangNext = 0;
  int asked = 0;

  @override
  Future<T> call<T>(String service, String method, Object? request, T Function(Object? json) decode) {
    asked++;
    if (silent || hangNext-- > 0) return Completer<T>().future;
    return Future.value(decode(<String, dynamic>{}));
  }
}
