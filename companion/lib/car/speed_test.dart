import 'dart:async';
import 'dart:io';

import '../transport/transport_selector.dart';
import 'car_session.dart';

/// What one speed test measured on the link to the car.
class SpeedTestResult {
  const SpeedTestResult({required this.pingMs, required this.bytes, required this.elapsed, required this.phase});

  /// Round trip of an empty request on a warm connection, median of four.
  final double pingMs;

  /// Body bytes received, car to phone.
  final int bytes;

  /// How long the download phase ran.
  final Duration elapsed;

  /// The path measured: LAN or Pear, as the session had it when the test began.
  final TransportPhase phase;

  /// Bits per microsecond is Mbit/s.
  double get mbps => bytes * 8 / elapsed.inMicroseconds;
}

/// Measures the link to the car through the gateway, the way live view and clips use it
/// (BladeWatch-j6ra). The car serves `GET /speedtest/down?bytes=N` (SpeedTestApiHandler).
///
/// One kept-alive connection: a warm-up request, which pays for the connection (over Pear, a TLS
/// handshake that can take tens of seconds), then four timed empty requests for latency, then
/// [chunkBytes] downloads back to back until [duration] has passed. The last one is cut off
/// mid-body. Download only: the direction that carries video, and over Pear exactly the car's
/// uplink.
///
/// Throws on a refusal, a drop or a stall of more than [timeout]: a partial number would pass for
/// a result. The default [timeout] outlasts [LocalGateway.pearHandshakeTimeout].
Future<SpeedTestResult> runSpeedTest(
  CarSession session, {
  Duration duration = const Duration(seconds: 8),
  int chunkBytes = 16 << 20,
  Duration timeout = const Duration(seconds: 75),
}) async {
  final phase = session.phase;
  final headers = await session.authHeaders();
  // Held for the whole transfer: it fills the link, so the session's own "is the car still there?"
  // question would time out behind it and the car would be shown as silent (BladeWatch-a7ev).
  return session.duringBulkTransfer(() => _measure(session, headers, phase, duration, chunkBytes, timeout));
}

Future<SpeedTestResult> _measure(
  CarSession session,
  Map<String, String> headers,
  TransportPhase phase,
  Duration duration,
  int chunkBytes,
  Duration timeout,
) async {
  final client = HttpClient();

  Future<HttpClientResponse> get(int bytes) async {
    final request = await client.getUrl(session.baseUrl.resolve('/speedtest/down?bytes=$bytes')).timeout(timeout);
    headers.forEach(request.headers.set);
    final response = await request.close().timeout(timeout);
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw HttpException('speed test refused: HTTP ${response.statusCode}');
    }
    return response;
  }

  try {
    await (await get(0)).drain<void>(); // warm-up, not timed
    final pings = <int>[];
    final clock = Stopwatch();
    for (var i = 0; i < 4; i++) {
      clock
        ..reset()
        ..start();
      await (await get(0)).drain<void>();
      pings.add(clock.elapsedMicroseconds);
    }
    pings.sort();

    var bytes = 0;
    clock
      ..reset()
      ..start();
    while (clock.elapsed < duration) {
      await for (final data in (await get(chunkBytes)).timeout(timeout)) {
        bytes += data.length;
        if (clock.elapsed >= duration) break; // cancels the body: the connection is dropped, not drained
      }
    }
    return SpeedTestResult(
      pingMs: (pings[1] + pings[2]) / 2000, // median of four, microseconds to ms
      bytes: bytes,
      elapsed: clock.elapsed,
      phase: phase,
    );
  } finally {
    client.close(force: true);
  }
}
