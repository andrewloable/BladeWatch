/// Thumbnail loading for the recordings grid, which needs a retry that
/// `Image.network` cannot express.
///
/// `RecordingsApiHandler.serveThumbnail`
/// (app/src/main/java/com/loabletech/bladewatch/server/RecordingsApiHandler.java:249)
/// does NOT block while a thumbnail is generated. When the JPEG is not in the
/// cache it queues background generation and answers immediately with:
///
///     HTTP/1.1 202 Accepted
///     Retry-After: 1
///     {"status":"generating"}
///
/// Its own doc comment says "client should retry". `Image.network` has no
/// concept of that: it treats any non-image body as a decode failure, falls
/// into `errorBuilder`, and never asks again. Observed on device as a grid of
/// permanently grey tiles that only filled in on a LATER visit to the screen,
/// once some earlier 202 had quietly finished generating in the background —
/// and a clip recorded after that visit was grey again.
///
/// So this fetches the bytes itself and honours the 202 + `Retry-After`
/// handshake. [fetchThumbnail] is a pure function over an injected
/// [ThumbnailFetcher], the same seam `RawHttpSender` gives `ConnectClient`, so
/// the retry policy is unit-testable without a socket.
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'recordings_media_urls.dart';

class ThumbnailResponse {
  final int statusCode;
  final Uint8List bytes;

  /// Parsed `Retry-After`, when the server sent a well-formed delay-seconds
  /// value. Null means "server didn't say" — the caller falls back to its own
  /// default rather than giving up.
  final Duration? retryAfter;

  const ThumbnailResponse(this.statusCode, this.bytes, {this.retryAfter});
}

typedef ThumbnailFetcher = Future<ThumbnailResponse> Function(
  Uri uri,
  Map<String, String> headers,
);

/// Bounded retry around the daemon's 202 handshake.
///
/// Returns the JPEG bytes, or null if the thumbnail could not be obtained —
/// either a hard failure (404 for a clip whose MP4 is gone, 401, a socket
/// error) or [maxAttempts] exhausted while generation was still pending.
/// Null is a normal outcome, not an error: the grid shows its placeholder.
///
/// Only 202 is retried. A 404 means the video file itself is missing and no
/// amount of waiting changes that, so retrying it would just burn requests on
/// every tile of a stale listing.
Future<Uint8List?> fetchThumbnail(
  Uri uri,
  Map<String, String> headers, {
  required ThumbnailFetcher fetch,
  int maxAttempts = 5,
  Duration defaultRetryAfter = const Duration(seconds: 1),
  Duration maxRetryAfter = const Duration(seconds: 5),
  Future<void> Function(Duration) sleep = _realSleep,
}) async {
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    final ThumbnailResponse response;
    try {
      response = await fetch(uri, headers);
    } catch (_) {
      // Connection refused / timeout — the daemon may still be starting. Treat
      // it like a pending generation rather than a permanent failure, but
      // still inside the same bounded attempt budget.
      if (attempt == maxAttempts) return null;
      await sleep(defaultRetryAfter);
      continue;
    }

    if (response.statusCode == 200) {
      return response.bytes.isEmpty ? null : response.bytes;
    }
    if (response.statusCode != 202) {
      return null;
    }
    if (attempt == maxAttempts) {
      return null;
    }

    // Clamp the server's hint: a bad or hostile Retry-After must not park a
    // widget for minutes.
    var delay = response.retryAfter ?? defaultRetryAfter;
    if (delay > maxRetryAfter) delay = maxRetryAfter;
    if (delay < Duration.zero) delay = defaultRetryAfter;
    await sleep(delay);
  }
  return null;
}

Future<void> _realSleep(Duration d) => Future<void>.delayed(d);

/// The real fetcher. Mirrors `createIoHttpSender`'s configuration for the same
/// reason: this project ships Tailscale/sing-box, and a system proxy must
/// never intercept a loopback call to the daemon.
ThumbnailFetcher createIoThumbnailFetcher({
  Duration connectTimeout = const Duration(seconds: 5),
  Duration readTimeout = const Duration(seconds: 10),
}) {
  final httpClient = HttpClient()
    ..connectionTimeout = connectTimeout
    ..findProxy = (_) => 'DIRECT';

  return (Uri uri, Map<String, String> headers) async {
    final request = await httpClient.getUrl(uri).timeout(connectTimeout);
    headers.forEach(request.headers.set);
    final response = await request.close().timeout(readTimeout);

    Duration? retryAfter;
    final raw = response.headers.value(HttpHeaders.retryAfterHeader);
    if (raw != null) {
      // Only the delay-seconds form: that is what the daemon sends. An
      // HTTP-date Retry-After parses as null and the caller's default is used.
      final seconds = int.tryParse(raw.trim());
      if (seconds != null && seconds >= 0) retryAfter = Duration(seconds: seconds);
    }

    // A 202 body is a short JSON status, not an image; draining it keeps the
    // connection reusable for the retry.
    final builder = BytesBuilder(copy: false);
    await for (final chunk in response.timeout(readTimeout)) {
      builder.add(chunk);
    }
    return ThumbnailResponse(response.statusCode, builder.takeBytes(), retryAfter: retryAfter);
  };
}

/// Grid tile image that survives the 202 handshake. Renders nothing until
/// bytes arrive, so the caller's placeholder shows through — matching the old
/// `errorBuilder: (..) => SizedBox.shrink()` behaviour on permanent failure.
class ThumbnailImage extends StatefulWidget {
  final String filename;
  final String jwt;
  final ThumbnailFetcher? fetcher;
  final Uri? baseUrl;

  const ThumbnailImage({
    super.key,
    required this.filename,
    required this.jwt,
    this.fetcher,
    this.baseUrl,
  });

  @override
  State<ThumbnailImage> createState() => _ThumbnailImageState();
}

class _ThumbnailImageState extends State<ThumbnailImage> {
  static final ThumbnailFetcher _sharedFetcher = createIoThumbnailFetcher();

  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(ThumbnailImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Grid tiles are recycled onto different clips as the list scrolls or the
    // day filter changes; without this the tile would keep showing the
    // previous clip's frame.
    if (oldWidget.filename != widget.filename || oldWidget.jwt != widget.jwt) {
      _bytes = null;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final filename = widget.filename;
    final bytes = await fetchThumbnail(
      thumbUrl(filename, baseUrl: widget.baseUrl),
      {'Authorization': 'Bearer ${widget.jwt}'},
      fetch: widget.fetcher ?? _sharedFetcher,
    );
    // Guard against the tile having been recycled onto another clip while the
    // retry loop was sleeping.
    if (!mounted || widget.filename != filename) return;
    setState(() => _bytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) return const SizedBox.shrink();
    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );
  }
}
