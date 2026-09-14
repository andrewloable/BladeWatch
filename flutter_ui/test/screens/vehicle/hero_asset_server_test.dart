/// The hero asset server exists because WebView refuses `fetch()` on a
/// `file://` origin, which left the 3D car invisible on device. These tests
/// pin the two things that can silently break it again: what it is willing to
/// serve (path traversal must not reach the rest of the asset bundle) and the
/// content types three.js actually requires.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bladewatch_ui/screens/vehicle/hero_asset_server.dart';

ByteData _bytes(String s) => ByteData.view(Uint8List.fromList(utf8.encode(s)).buffer);

void main() {
  group('heroAssetKeyFor', () {
    test('maps a hero path to its bundle key', () {
      expect(heroAssetKeyFor('/web/hero/hero.html'), 'assets/web/hero/hero.html');
      expect(heroAssetKeyFor('/web/shared/models/seal.glb'), 'assets/web/shared/models/seal.glb');
      expect(
        heroAssetKeyFor('/web/shared/vendor/draco/draco_decoder.wasm'),
        'assets/web/shared/vendor/draco/draco_decoder.wasm',
      );
    });

    test('decodes percent-encoding', () {
      expect(heroAssetKeyFor('/web/shared/models/seal%2Du.glb'), 'assets/web/shared/models/seal-u.glb');
    });

    test('refuses traversal out of the web tree', () {
      expect(heroAssetKeyFor('/web/../../secret.txt'), isNull);
      expect(heroAssetKeyFor('/web/hero/../../../AndroidManifest.xml'), isNull);
      expect(heroAssetKeyFor('/../assets/secret'), isNull);
      expect(heroAssetKeyFor('/web/..%2F..%2Fsecret'), isNull);
    });

    test('refuses anything outside assets/web', () {
      // The bundle holds more than the hero's files; only the hero tree is
      // reachable.
      expect(heroAssetKeyFor('/LICENSE.txt'), isNull);
      expect(heroAssetKeyFor('/assets/LICENSE.txt'), isNull);
      expect(heroAssetKeyFor('/packages/foo/bar.dart'), isNull);
    });

    test('refuses empty, root and malformed paths', () {
      expect(heroAssetKeyFor(''), isNull);
      expect(heroAssetKeyFor('/'), isNull);
      expect(heroAssetKeyFor('/web//hero.html'), isNull);
      expect(heroAssetKeyFor(r'/web\hero\hero.html'), isNull);
    });
  });

  group('heroContentTypeFor', () {
    test('serves the types three.js requires', () {
      // WebAssembly.instantiateStreaming rejects a wrong MIME type outright,
      // so the Draco decoder depends on this exact value.
      expect(heroContentTypeFor('a/draco_decoder.wasm'), 'application/wasm');
      expect(heroContentTypeFor('a/seal.glb'), 'model/gltf-binary');
      expect(heroContentTypeFor('a/three.min.js'), startsWith('application/javascript'));
      expect(heroContentTypeFor('a/hero.html'), startsWith('text/html'));
      expect(heroContentTypeFor('a/manifest.json'), startsWith('application/json'));
    });

    test('is case-insensitive and falls back to octet-stream', () {
      expect(heroContentTypeFor('A/SEAL.GLB'), 'model/gltf-binary');
      expect(heroContentTypeFor('a/unknown.xyz'), 'application/octet-stream');
    });
  });

  group('HeroAssetServer', () {
    late HeroAssetServer server;
    late Uri base;
    late List<String> requestedKeys;

    setUp(() async {
      requestedKeys = [];
      server = HeroAssetServer(loadAsset: (key) async {
        requestedKeys.add(key);
        if (key == 'assets/web/hero/hero.html') return _bytes('<html>hero</html>');
        if (key == 'assets/web/shared/models/seal.glb') return _bytes('GLB-BYTES');
        throw Exception('asset not found: $key');
      });
      base = await server.start();
    });

    tearDown(() => server.stop());

    test('binds to loopback only', () {
      expect(base.host, '127.0.0.1');
      expect(base.port, greaterThan(0));
    });

    test('serves hero.html with an html content type', () async {
      final response = await _get(base.replace(path: '/web/hero/hero.html'));

      expect(response.statusCode, 200);
      expect(response.body, '<html>hero</html>');
      expect(response.contentType, startsWith('text/html'));
    });

    test('serves a model with the gltf-binary content type', () async {
      final response = await _get(base.replace(path: '/web/shared/models/seal.glb'));

      expect(response.statusCode, 200);
      expect(response.body, 'GLB-BYTES');
      expect(response.contentType, 'model/gltf-binary');
    });

    test('404s an asset that is not in the bundle', () async {
      final response = await _get(base.replace(path: '/web/shared/models/nope.glb'));
      expect(response.statusCode, 404);
    });

    test('403s a traversal attempt without touching the bundle', () async {
      final response = await _get(base.replace(path: '/web/../pubspec.yaml'));

      expect(response.statusCode, 403);
      // The key point: it is rejected before any asset lookup happens.
      expect(requestedKeys, isEmpty);
    });

    test('405s a non-GET method', () async {
      final client = HttpClient();
      final request = await client.postUrl(base.replace(path: '/web/hero/hero.html'));
      final response = await request.close();
      await response.drain<void>();
      client.close();

      expect(response.statusCode, 405);
    });

    test('start() is idempotent and returns the same origin', () async {
      expect(await server.start(), base);
      expect(await server.start(), base);
    });

    test('keeps serving after a failed request', () async {
      await _get(base.replace(path: '/web/shared/models/nope.glb'));
      final response = await _get(base.replace(path: '/web/hero/hero.html'));
      expect(response.statusCode, 200);
    });
  });

  group('the shared instance', () {
    test('is a lazily-created singleton backed by the real asset bundle', () {
      // VehicleHero uses HeroAssetServer.instance, not a fresh server per
      // visit; if this stopped being one shared object the Vehicle screen
      // would bind a new port on every entry. Constructing it does NOT bind a
      // socket or read an asset — start() does — so this is safe to touch.
      final a = HeroAssetServer.instance;
      final b = HeroAssetServer.instance;

      expect(identical(a, b), isTrue);
      // Also covers the default `loadAsset ?? rootBundle.load` branch, which
      // every other test bypasses by injecting a fixture loader.
      expect(HeroAssetServer(), isA<HeroAssetServer>());
    });
  });
}

class _Response {
  final int statusCode;
  final String body;
  final String contentType;
  _Response(this.statusCode, this.body, this.contentType);
}

Future<_Response> _get(Uri uri) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    return _Response(response.statusCode, body, response.headers.contentType?.toString() ?? '');
  } finally {
    client.close();
  }
}
