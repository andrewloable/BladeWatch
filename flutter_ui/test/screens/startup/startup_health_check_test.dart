import 'dart:io';

import 'package:bladewatch_ui/screens/startup/startup_health_check.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('checkDaemonHealth', () {
    late HttpServer server;

    tearDown(() async {
      await server.close(force: true);
    });

    test('true when the server responds 200', () async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        request.response.statusCode = 200;
        await request.response.close();
      });

      expect(await checkDaemonHealth(url: 'http://127.0.0.1:${server.port}/'), isTrue);
    });

    test('true even for a non-2xx response — any response means the server is up '
        '(mirrors verifyDaemonHealth()\'s "any response means server is up")', () async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        request.response.statusCode = 404;
        await request.response.close();
      });

      expect(await checkDaemonHealth(url: 'http://127.0.0.1:${server.port}/'), isTrue);
    });

    test('false when nothing is listening on the port (connection refused)', () async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = server.port;
      await server.close(force: true);

      expect(await checkDaemonHealth(url: 'http://127.0.0.1:$port/'), isFalse);
    });

    test('false when the server accepts the connection but never responds (timeout)', () async {
      // A raw socket server that accepts the TCP connection but never writes
      // a response — the client must give up via its own timeout, not a
      // connection-refused error, exercising a genuinely different failure
      // path than the "nothing listening" case above.
      final raw = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final sub = raw.listen((socket) {
        // Accept and hold the connection open; never write anything back.
      });

      final result = await checkDaemonHealth(
        url: 'http://127.0.0.1:${raw.port}/',
        timeout: const Duration(milliseconds: 300),
      );

      expect(result, isFalse);
      await sub.cancel();
      await raw.close();
    });
  });
}
