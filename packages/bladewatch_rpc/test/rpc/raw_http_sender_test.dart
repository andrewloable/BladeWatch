import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_rpc/rpc/raw_http_sender.dart';

void main() {
  group('createIoHttpSender', () {
    late HttpServer server;

    tearDown(() async {
      await server.close(force: true);
    });

    test('performs a real POST round trip with the given headers and body', () async {
      String? capturedMethod;
      Map<String, String> capturedHeaders = {};
      String? capturedBody;

      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        capturedMethod = request.method;
        request.headers.forEach((name, values) => capturedHeaders[name] = values.join(','));
        capturedBody = await utf8.decoder.bind(request).join();
        request.response.statusCode = 200;
        request.response.write('{"ok":true}');
        await request.response.close();
      });

      final send = createIoHttpSender();
      final response = await send(
        Uri.parse('http://127.0.0.1:${server.port}/bladewatch.v1.SystemService/GetStatus'),
        {'Content-Type': 'application/json', 'Connect-Protocol-Version': '1'},
        '{"foo":"bar"}',
      );

      expect(capturedMethod, 'POST');
      expect(capturedHeaders['content-type'], 'application/json');
      expect(capturedHeaders['connect-protocol-version'], '1');
      expect(capturedBody, '{"foo":"bar"}');
      expect(response.statusCode, 200);
      expect(response.body, '{"ok":true}');
    });

    test('surfaces a non-2xx status with its body rather than throwing', () async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        request.response.statusCode = 404;
        request.response.write('{"code":"not_found","message":"nope"}');
        await request.response.close();
      });

      final send = createIoHttpSender();
      final response = await send(
        Uri.parse('http://127.0.0.1:${server.port}/x'),
        const {},
        '{}',
      );

      expect(response.statusCode, 404);
      expect(response.body, '{"code":"not_found","message":"nope"}');
    });

    test('a connect timeout throws rather than hanging forever', () async {
      // 10.255.255.1 is a non-routable address reserved for documentation/
      // testing (RFC 5737-style) — connections to it stall instead of
      // immediately refusing, which is exactly what exercises a connect
      // timeout rather than an instant "connection refused".
      final send = createIoHttpSender(connectTimeout: const Duration(milliseconds: 200));

      await expectLater(
        () => send(Uri.parse('http://10.255.255.1:8080/x'), const {}, '{}'),
        throwsA(anything),
      );
    }, timeout: const Timeout(Duration(seconds: 5)));
  });

  // The GET counterpart used for plain REST reads (e.g. the telemetry field checklist). It was
  // only ever exercised through flutter_ui's screens before this package was extracted
  // (BladeWatch-rdtj.10); the companion depends on it too, so it is pinned here directly.
  group('createIoGetSender', () {
    HttpServer? server;

    tearDown(() async {
      await server?.close(force: true);
    });

    test('performs a real GET with the given headers and returns status and body', () async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server!.listen((request) async {
        expect(request.method, 'GET');
        expect(request.headers.value('Authorization'), 'Bearer t');
        request.response
          ..statusCode = 200
          ..write('{"fields":[]}');
        await request.response.close();
      });

      final get = createIoGetSender();
      final response = await get(
        Uri.parse('http://127.0.0.1:${server!.port}/api/telemetry/fields'),
        {'Authorization': 'Bearer t'},
      );

      expect(response.statusCode, 200);
      expect(response.body, '{"fields":[]}');
    });

    test('surfaces a non-2xx status with its body rather than throwing', () async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server!.listen((request) async {
        request.response
          ..statusCode = 401
          ..write('unauthorized');
        await request.response.close();
      });

      final response = await createIoGetSender()(
        Uri.parse('http://127.0.0.1:${server!.port}/x'),
        const {},
      );

      expect(response.statusCode, 401);
      expect(response.body, 'unauthorized');
    });
  });
}
