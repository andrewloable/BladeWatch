/// Pins the 202 + Retry-After handshake that `Image.network` could not do.
///
/// The device symptom this prevents: `RecordingsApiHandler.serveThumbnail`
/// answers an uncached thumbnail with 202 and generates in the background, so
/// the recordings grid rendered permanently grey tiles that only filled in on
/// a later visit to the screen.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_ui/screens/recordings/thumbnail_image.dart';

final _jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 1, 2, 3]);
final _generatingBody = Uint8List.fromList('{"status":"generating"}'.codeUnits);

/// Replays a fixed script of responses and records how long the caller slept,
/// so the retry policy is asserted without a socket or a real delay.
class _ScriptedFetcher {
  final List<ThumbnailResponse> script;
  final List<Object> thrown;
  int calls = 0;
  final List<Duration> slept = [];

  _ScriptedFetcher(this.script, {this.thrown = const []});

  Future<ThumbnailResponse> call(Uri uri, Map<String, String> headers) async {
    final i = calls++;
    if (i < thrown.length && thrown[i] != _noThrow) throw thrown[i];
    return script[i];
  }

  Future<void> sleep(Duration d) async => slept.add(d);
}

const _noThrow = Object();

void main() {
  group('fetchThumbnail', () {
    test('returns bytes immediately on 200 without sleeping', () async {
      final f = _ScriptedFetcher([ThumbnailResponse(200, _jpeg)]);

      final bytes = await fetchThumbnail(
        Uri.parse('http://127.0.0.1:8080/thumb/a.mp4'),
        const {},
        fetch: f.call,
        sleep: f.sleep,
      );

      expect(bytes, _jpeg);
      expect(f.calls, 1);
      expect(f.slept, isEmpty);
    });

    test('retries a 202 and returns the bytes once generation finishes', () async {
      final f = _ScriptedFetcher([
        ThumbnailResponse(202, _generatingBody, retryAfter: const Duration(seconds: 1)),
        ThumbnailResponse(202, _generatingBody, retryAfter: const Duration(seconds: 1)),
        ThumbnailResponse(200, _jpeg),
      ]);

      final bytes = await fetchThumbnail(
        Uri.parse('http://127.0.0.1:8080/thumb/a.mp4'),
        const {},
        fetch: f.call,
        sleep: f.sleep,
      );

      expect(bytes, _jpeg);
      expect(f.calls, 3);
      expect(f.slept, [const Duration(seconds: 1), const Duration(seconds: 1)]);
    });

    test('honours the server Retry-After delay', () async {
      final f = _ScriptedFetcher([
        ThumbnailResponse(202, _generatingBody, retryAfter: const Duration(seconds: 3)),
        ThumbnailResponse(200, _jpeg),
      ]);

      await fetchThumbnail(Uri.parse('http://x/thumb/a.mp4'), const {}, fetch: f.call, sleep: f.sleep);

      expect(f.slept, [const Duration(seconds: 3)]);
    });

    test('falls back to the default delay when Retry-After is absent', () async {
      final f = _ScriptedFetcher([
        ThumbnailResponse(202, _generatingBody),
        ThumbnailResponse(200, _jpeg),
      ]);

      await fetchThumbnail(
        Uri.parse('http://x/thumb/a.mp4'),
        const {},
        fetch: f.call,
        sleep: f.sleep,
        defaultRetryAfter: const Duration(milliseconds: 250),
      );

      expect(f.slept, [const Duration(milliseconds: 250)]);
    });

    test('clamps an absurd Retry-After so a tile cannot park for minutes', () async {
      final f = _ScriptedFetcher([
        ThumbnailResponse(202, _generatingBody, retryAfter: const Duration(minutes: 10)),
        ThumbnailResponse(200, _jpeg),
      ]);

      await fetchThumbnail(
        Uri.parse('http://x/thumb/a.mp4'),
        const {},
        fetch: f.call,
        sleep: f.sleep,
        maxRetryAfter: const Duration(seconds: 5),
      );

      expect(f.slept, [const Duration(seconds: 5)]);
    });

    test('gives up after maxAttempts of continuous 202 and does not sleep after the last try', () async {
      final f = _ScriptedFetcher(List.generate(3, (_) => ThumbnailResponse(202, _generatingBody)));

      final bytes = await fetchThumbnail(
        Uri.parse('http://x/thumb/a.mp4'),
        const {},
        fetch: f.call,
        sleep: f.sleep,
        maxAttempts: 3,
      );

      expect(bytes, isNull);
      expect(f.calls, 3);
      // 3 attempts => at most 2 waits; never sleep after the final attempt.
      expect(f.slept, hasLength(2));
    });

    test('does not retry a 404 — a missing MP4 will not appear by waiting', () async {
      final f = _ScriptedFetcher([ThumbnailResponse(404, Uint8List(0))]);

      final bytes = await fetchThumbnail(
        Uri.parse('http://x/thumb/gone.mp4'),
        const {},
        fetch: f.call,
        sleep: f.sleep,
      );

      expect(bytes, isNull);
      expect(f.calls, 1);
      expect(f.slept, isEmpty);
    });

    test('does not retry a 401', () async {
      final f = _ScriptedFetcher([ThumbnailResponse(401, Uint8List(0))]);

      expect(
        await fetchThumbnail(Uri.parse('http://x/thumb/a.mp4'), const {}, fetch: f.call, sleep: f.sleep),
        isNull,
      );
      expect(f.calls, 1);
    });

    test('treats an empty 200 body as no thumbnail rather than a broken image', () async {
      final f = _ScriptedFetcher([ThumbnailResponse(200, Uint8List(0))]);

      expect(
        await fetchThumbnail(Uri.parse('http://x/thumb/a.mp4'), const {}, fetch: f.call, sleep: f.sleep),
        isNull,
      );
    });

    test('retries a thrown socket error — the daemon may still be starting', () async {
      final f = _ScriptedFetcher(
        [ThumbnailResponse(0, Uint8List(0)), ThumbnailResponse(200, _jpeg)],
        thrown: [Exception('connection refused')],
      );

      final bytes = await fetchThumbnail(
        Uri.parse('http://x/thumb/a.mp4'),
        const {},
        fetch: f.call,
        sleep: f.sleep,
      );

      expect(bytes, _jpeg);
      expect(f.calls, 2);
    });

    test('a persistently throwing fetch gives up and returns null', () async {
      final f = _ScriptedFetcher(
        List.generate(3, (_) => ThumbnailResponse(0, Uint8List(0))),
        thrown: List.generate(3, (_) => Exception('refused')),
      );

      final bytes = await fetchThumbnail(
        Uri.parse('http://x/thumb/a.mp4'),
        const {},
        fetch: f.call,
        sleep: f.sleep,
        maxAttempts: 3,
      );

      expect(bytes, isNull);
      expect(f.calls, 3);
    });

    test('sends the caller Authorization header on every attempt', () async {
      final seen = <Map<String, String>>[];
      var n = 0;
      Future<ThumbnailResponse> fetch(Uri uri, Map<String, String> headers) async {
        seen.add(Map.of(headers));
        return n++ == 0 ? ThumbnailResponse(202, _generatingBody) : ThumbnailResponse(200, _jpeg);
      }

      await fetchThumbnail(
        Uri.parse('http://x/thumb/a.mp4'),
        const {'Authorization': 'Bearer tok'},
        fetch: fetch,
        sleep: (_) async {},
      );

      // The retry must stay authenticated; /thumb/ is not in PUBLIC_PATHS.
      expect(seen, hasLength(2));
      expect(seen.every((h) => h['Authorization'] == 'Bearer tok'), isTrue);
    });
  });

  group('ThumbnailImage widget', () {
    testWidgets('renders nothing while generating, then the image', (tester) async {
      var n = 0;
      Future<ThumbnailResponse> fetch(Uri uri, Map<String, String> headers) async =>
          n++ == 0 ? ThumbnailResponse(202, _generatingBody) : ThumbnailResponse(200, _jpeg);

      await tester.pumpWidget(MaterialApp(
        home: ThumbnailImage(filename: 'a.mp4', jwt: 'tok', fetcher: fetch),
      ));

      // First frame: the 202 is still in flight, so the tile is empty and the
      // caller's placeholder shows through.
      expect(find.byType(Image), findsNothing);

      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('renders nothing when the thumbnail is permanently unavailable', (tester) async {
      Future<ThumbnailResponse> fetch(Uri uri, Map<String, String> headers) async =>
          ThumbnailResponse(404, Uint8List(0));

      await tester.pumpWidget(MaterialApp(
        home: ThumbnailImage(filename: 'gone.mp4', jwt: 'tok', fetcher: fetch),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNothing);
    });

    testWidgets('refetches when the tile is recycled onto a different clip', (tester) async {
      final requested = <String>[];
      Future<ThumbnailResponse> fetch(Uri uri, Map<String, String> headers) async {
        requested.add(uri.path);
        return ThumbnailResponse(200, _jpeg);
      }

      await tester.pumpWidget(MaterialApp(
        home: ThumbnailImage(filename: 'a.mp4', jwt: 'tok', fetcher: fetch),
      ));
      await tester.pumpAndSettle();

      await tester.pumpWidget(MaterialApp(
        home: ThumbnailImage(filename: 'b.mp4', jwt: 'tok', fetcher: fetch),
      ));
      await tester.pumpAndSettle();

      expect(requested, ['/thumb/a.mp4', '/thumb/b.mp4']);
    });
  });
}
