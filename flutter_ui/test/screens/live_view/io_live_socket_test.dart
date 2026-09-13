import 'dart:async';
import 'dart:io';

import 'package:bladewatch_ui/screens/live_view/live_view_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Real-server integration test for [IoLiveSocket]/[connectIoLiveSocket] —
/// mirrors `raw_http_sender_test.dart`'s own approach to a thin `dart:io`
/// wrapper: spin up a real local server rather than treat the class as
/// untestable. [LiveViewController]'s own logic is covered separately
/// against a fake [LiveSocket].
void main() {
  group('connectIoLiveSocket', () {
    late HttpServer server;

    tearDown(() async {
      await server.close(force: true);
    });

    test('connects to a real WebSocket server and delivers its messages', () async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) async {
        final socket = await WebSocketTransformer.upgrade(request);
        socket.add('hello');
      });

      final live = await connectIoLiveSocket('ws://127.0.0.1:${server.port}');
      final message = await live.messages.first;

      expect(message, 'hello');
      await live.close();
    });

    test('close() ends the connection', () async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final serverDone = Completer<bool>();
      server.listen((request) async {
        final socket = await WebSocketTransformer.upgrade(request);
        socket.listen((_) {}, onDone: () => serverDone.complete(true));
      });

      final live = await connectIoLiveSocket('ws://127.0.0.1:${server.port}');
      await live.close();

      expect(await serverDone.future.timeout(const Duration(seconds: 5)), isTrue);
    });
  });
}
