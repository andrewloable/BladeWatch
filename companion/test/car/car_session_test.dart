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
