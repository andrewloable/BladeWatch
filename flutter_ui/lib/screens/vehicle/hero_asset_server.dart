/// Serves the hero's bundled assets over loopback HTTP so the 3D model can
/// actually load.
///
/// `loadFlutterAsset` puts the page on a `file://` origin, and three.js's
/// GLTFLoader/DRACOLoader fetch the `.glb` and the Draco decoder with the Fetch
/// API. WebView refuses that outright — observed on device as:
///
///     Fetch API cannot load
///     file:///android_asset/flutter_assets/assets/web/shared/models/seal.glb.
///     URL scheme must be "http" or "https" for CORS request.
///     Hero model load failed: Failed to fetch
///
/// so the page rendered but stayed empty. Native hit the identical wall and
/// solved it by serving a synthetic `https://bladewatch.assets` origin from
/// `shouldInterceptRequest` (see `VehicleHeroView.kt`, whose comment says a
/// real https origin "avoids the sandboxed WebView's block on file:// XHR").
/// `webview_flutter` exposes no request-interception hook, so this is the
/// same idea in pure Dart: a loopback HTTP origin instead of a synthetic https
/// one. `hero.html` stays byte-identical to native's, which is the point.
///
/// Bound to 127.0.0.1 only, and the Flutter APK's network security config
/// already permits cleartext to exactly that host. What it serves is the
/// packaged three.js bundle and the car models — no device data, no secrets,
/// nothing from the daemon.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

/// Maps a request path to the Flutter asset key it may serve, or null if the
/// path escapes the hero asset tree.
///
/// Pure so the traversal rules are testable without binding a socket. Only
/// `assets/web/**` is reachable: the server must never become a way to read
/// the rest of the bundle.
String? heroAssetKeyFor(String requestPath) {
  var path = Uri.decodeComponent(requestPath);
  if (path.startsWith('/')) path = path.substring(1);
  if (path.isEmpty) return null;

  // Reject traversal and absolute/UNC-ish forms outright rather than trying to
  // normalise them.
  if (path.contains('..') || path.contains('\\') || path.contains('//')) return null;
  for (final segment in path.split('/')) {
    if (segment.isEmpty || segment == '.' || segment == '..') return null;
  }

  if (!path.startsWith('web/')) return null;
  return 'assets/$path';
}

/// Content type for an asset path. `.wasm` and `.glb` matter: the Draco decoder
/// is instantiated via `WebAssembly.instantiateStreaming`, which rejects a
/// wrong MIME type, and browsers are picky about model payloads.
String heroContentTypeFor(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.html')) return 'text/html; charset=utf-8';
  if (lower.endsWith('.js')) return 'application/javascript; charset=utf-8';
  if (lower.endsWith('.json')) return 'application/json; charset=utf-8';
  if (lower.endsWith('.wasm')) return 'application/wasm';
  if (lower.endsWith('.glb')) return 'model/gltf-binary';
  if (lower.endsWith('.gltf')) return 'model/gltf+json';
  if (lower.endsWith('.bin')) return 'application/octet-stream';
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  if (lower.endsWith('.hdr')) return 'application/octet-stream';
  return 'application/octet-stream';
}

/// A loopback HTTP server exposing the bundled hero assets.
///
/// One instance is shared for the app's lifetime ([instance]): the Vehicle
/// screen can be entered and left repeatedly, and rebinding a port per visit
/// would be pointless churn.
class HeroAssetServer {
  static final HeroAssetServer instance = HeroAssetServer();

  HttpServer? _server;
  Future<Uri>? _starting;

  /// Loads an asset's bytes. Injectable so tests can serve fixtures without
  /// depending on a real asset bundle.
  final Future<ByteData> Function(String key) _loadAsset;

  HeroAssetServer({Future<ByteData> Function(String key)? loadAsset})
      : _loadAsset = loadAsset ?? rootBundle.load;

  /// Starts the server if needed and returns its base URI. Concurrent callers
  /// share one start.
  Future<Uri> start() => _starting ??= _start();

  Future<Uri> _start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    unawaited(_serve(server));
    return Uri.parse('http://127.0.0.1:${server.port}');
  }

  Future<void> _serve(HttpServer server) async {
    await for (final request in server) {
      unawaited(_handle(request));
    }
  }

  /// Every path sets a status (and possibly a body) and then falls through to
  /// the single close in the `finally`. Closing in one place rather than per
  /// branch means a dropped connection — the WebView navigating away
  /// mid-fetch — cannot leave a response open or take the server down, and it
  /// leaves no defensive branch that no test ever executes.
  Future<void> _handle(HttpRequest request) async {
    try {
      if (request.method != 'GET') {
        request.response.statusCode = HttpStatus.methodNotAllowed;
        return;
      }

      final key = heroAssetKeyFor(request.uri.path);
      if (key == null) {
        request.response.statusCode = HttpStatus.forbidden;
        return;
      }

      final ByteData data;
      try {
        data = await _loadAsset(key);
      } catch (_) {
        request.response.statusCode = HttpStatus.notFound;
        return;
      }

      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.parse(heroContentTypeFor(key))
        ..headers.set(HttpHeaders.cacheControlHeader, 'no-cache')
        ..add(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    } finally {
      try {
        await request.response.close();
      } catch (_) {
        // Peer already gone; nothing left to send and nothing to recover.
      }
    }
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    _starting = null;
    if (server != null) await server.close(force: true);
  }
}
