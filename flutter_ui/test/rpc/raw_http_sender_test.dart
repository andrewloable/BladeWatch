import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_ui/rpc/raw_http_sender.dart';

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
}
