import 'dart:async';
import 'dart:io';

import 'package:bladewatch_companion/car/speed_test.dart';
import 'package:bladewatch_companion/transport/transport_selector.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support.dart';

/// BladeWatch-j6ra.2: the runner against a real loopback server playing the car's
/// `GET /speedtest/down?bytes=N` (the Kotlin side is SpeedTestApiHandler).
void main() {
  late HttpServer car;
  final queries = <String>[];
  final ports = <int>[];
  final auth = <String?>[];

  /// What the fake car does with a request for [bytes]; a test swaps it to misbehave.
  late Future<void> Function(HttpRequest r, int bytes) serve;

  setUp(() async {
    queries.clear();
    ports.clear();
    auth.clear();
    serve = (r, bytes) async {
      r.response.contentLength = bytes;
      r.response.add(List.filled(bytes, 0));
    };
    car = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    car.listen((r) async {
      queries.add(r.uri.query);
      ports.add(r.connectionInfo!.remotePort);
      auth.add(r.headers.value('authorization'));
      try {
        await serve(r, int.parse(r.uri.queryParameters['bytes']!));
        await r.response.close();
      } catch (_) {
        // the client hung up mid-body, which is the point of several tests
      }
    });
  });

  tearDown(() => car.close(force: true));

  TestSession session({TransportPhase phase = TransportPhase.lan}) =>
      TestSession(phase: phase, baseUrl: Uri.parse('http://127.0.0.1:${car.port}'));

  const chunk = 1 << 20;
  const quick = Duration(milliseconds: 200);

  test('pings on one kept-alive connection, then downloads in chunks', () async {
    await runSpeedTest(session().session, duration: quick, chunkBytes: chunk);

    expect(queries.take(5), everyElement('bytes=0'), reason: 'a warm-up and four timed pings');
    expect(ports.take(5).toSet(), hasLength(1), reason: 'every ping on one connection');
    expect(queries.skip(5), isNotEmpty);
    expect(queries.skip(5), everyElement('bytes=$chunk'));
  });

  test('the warm-up is not timed: only the four pings after it count', () async {
    serve = (r, bytes) async {
      // The first request is the one that pays for the connection (over Pear: the TLS handshake).
      await Future<void>.delayed(queries.length == 1 ? const Duration(milliseconds: 400) : const Duration(milliseconds: 30));
      r.response.contentLength = bytes;
      r.response.add(List.filled(bytes, 0));
    };

    final result = await runSpeedTest(session().session, duration: quick, chunkBytes: chunk);

    expect(result.pingMs, inInclusiveRange(25, 200));
  });

  test('every request carries the session JWT', () async {
    await runSpeedTest(session().session, duration: quick, chunkBytes: chunk);

    expect(auth, isNotEmpty);
    expect(auth, everyElement('Bearer jwt'));
  });

  test('counts the bytes it received and works Mbit/s out from them', () async {
    final result = await runSpeedTest(session().session, duration: quick, chunkBytes: chunk);

    final downloads = queries.skip(5).length;
    // Whole chunks, except the last one, which is cut off when the time is up.
    expect(result.bytes, inInclusiveRange((downloads - 1) * chunk + 1, downloads * chunk));
    expect(result.elapsed, greaterThanOrEqualTo(quick));
    expect(result.mbps, closeTo(result.bytes * 8 / result.elapsed.inMicroseconds, 1e-9));
    expect(result.mbps, greaterThan(0));
  });

  test('stops at the duration even when the body is nowhere near done', () async {
    serve = (r, bytes) async {
      r.response.contentLength = bytes;
      if (bytes == 0) return;
      // About 100 KB/s: the whole 1 MiB would take ten seconds.
      for (var i = 0; i < bytes ~/ 1024; i++) {
        r.response.add(List.filled(1024, 0));
        await r.response.flush();
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    };
    final clock = Stopwatch()..start();

    final result = await runSpeedTest(session().session, duration: const Duration(milliseconds: 300), chunkBytes: chunk);

    expect(clock.elapsed, lessThan(const Duration(seconds: 3)));
    expect(result.bytes, inInclusiveRange(1, chunk - 1));
    expect(queries.skip(5), hasLength(1));
  });

  // BladeWatch-a7ev: its downloads fill the link, so the session's "is the car still there?" question
  // times out behind them. Without this hold the car was shown as silent and the screen, and its result, replaced.
  test('holds the session\'s watchdog for the whole transfer, and lets go afterwards, even after a failure', () async {
    final s = session();
    final seen = <bool>[];
    serve = (r, bytes) async {
      seen.add(s.session.bulkTransfer);
      r.response.contentLength = bytes;
      r.response.add(List.filled(bytes, 0));
    };

    await runSpeedTest(s.session, duration: quick, chunkBytes: chunk);

    expect(seen.length, greaterThan(5));
    expect(seen, everyElement(isTrue));
    expect(s.session.bulkTransfer, isFalse);

    serve = (r, bytes) async => r.response.statusCode = 503;
    await expectLater(runSpeedTest(s.session, duration: quick), throwsA(isA<HttpException>()));
    expect(s.session.bulkTransfer, isFalse);
  });

  test('says which path it measured: the session phase when it started', () async {
    final lan = await runSpeedTest(session().session, duration: quick, chunkBytes: chunk);
    final pear = await runSpeedTest(session(phase: TransportPhase.pear).session, duration: quick, chunkBytes: chunk);

    expect([lan.phase, pear.phase], [TransportPhase.lan, TransportPhase.pear]);
  });

  test('a refusal from the car throws, in the pings or in the download', () async {
    serve = (r, bytes) async => r.response.statusCode = 503;
    await expectLater(runSpeedTest(session().session, duration: quick), throwsA(isA<HttpException>()));

    serve = (r, bytes) async {
      if (bytes > 0) {
        r.response.statusCode = 401;
        return;
      }
      r.response.contentLength = 0;
    };
    await expectLater(runSpeedTest(session().session, duration: quick, chunkBytes: chunk), throwsA(isA<HttpException>()));
  });

  test('a connection that drops mid-download throws rather than reporting a partial number', () async {
    serve = (r, bytes) async {
      r.response.contentLength = bytes;
      if (bytes == 0) return;
      final socket = await r.response.detachSocket();
      socket.add(List.filled(1000, 0));
      await socket.flush();
      socket.destroy();
    };

    await expectLater(runSpeedTest(session().session, duration: quick, chunkBytes: chunk), throwsA(isA<IOException>()));
  });

  test('a car that stops answering times out', () async {
    serve = (r, bytes) => Completer<void>().future;

    await expectLater(
      runSpeedTest(session().session, duration: quick, chunkBytes: chunk, timeout: const Duration(milliseconds: 200)),
      throwsA(isA<TimeoutException>()),
    );
  });
}
