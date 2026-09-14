/// Drives the REAL dart:io thumbnail fetcher against a real loopback server.
///
/// Kept in its own file deliberately: `flutter_test`'s
/// `TestWidgetsFlutterBinding` — installed as soon as any `testWidgets` call
/// exists in a suite — replaces `HttpClient` with a stub that answers every
/// request with 400 and never touches the network. thumbnail_image_test.dart
/// has widget tests, so the real fetcher can only be exercised from a suite
/// with none, the same reason hero_asset_server_test.dart has no widget tests.
///
/// Without this, `createIoThumbnailFetcher`'s Retry-After parsing and body
/// draining — the code that actually talks to the daemon — would be the one
/// part of the 202 handshake never executed by a test.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_ui/screens/recordings/thumbnail_image.dart';

final _jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3]);

void main() {
  group('createIoThumbnailFetcher (the real dart:io fetcher)', () {
    // The tests above inject a fake, which leaves the real fetcher's header
    // parsing and body draining unexercised — exactly the code that talks to
    // the daemon. These drive it against a real loopback server instead.
    late HttpServer server;
    late Uri base;
    late List<String> hits;

    setUp(() async {
      hits = [];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      base = Uri.parse('http://127.0.0.1:${server.port}');
      unawaited(() async {
        await for (final request in server) {
          hits.add(request.uri.path);
          if (hits.length == 1) {
            // Exactly what RecordingsApiHandler.serveThumbnail sends while it
            // generates in the background.
            request.response
              ..statusCode = 202
              ..headers.set(HttpHeaders.retryAfterHeader, '2')
              ..headers.contentType = ContentType.json
              ..write('{"status":"generating"}');
          } else {
            request.response
              ..statusCode = 200
              ..headers.contentType = ContentType('image', 'jpeg')
              ..add(_jpeg);
          }
          await request.response.close();
        }
      }());
    });

    tearDown(() => server.close(force: true));

    test('parses Retry-After, drains the 202 body, and returns the JPEG', () async {
      final slept = <Duration>[];

      final bytes = await fetchThumbnail(
        base.replace(path: '/thumb/a.mp4'),
        const {'Authorization': 'Bearer tok'},
        fetch: createIoThumbnailFetcher(),
        sleep: (d) async => slept.add(d),
      );

      expect(bytes, _jpeg);
      expect(hits, ['/thumb/a.mp4', '/thumb/a.mp4']);
      // The server's own Retry-After: 2 was honoured, not the 1s default.
      expect(slept, [const Duration(seconds: 2)]);
    });
  });

}
