import 'dart:async';
import 'dart:io';

import 'lan_prober.dart';
import 'mux_bridge.dart';
import 'pinned_tls.dart';

/// Where the gateway sends a new connection right now.
sealed class GatewayRoute {}

/// Straight to the car's LAN TLS listener.
final class LanRoute implements GatewayRoute {
  final LanEndpoint endpoint;

  LanRoute(this.endpoint);
}

/// Through a Pear connection to the car's Pear TLS listener.
final class PearRoute implements GatewayRoute {
  final MuxBridge bridge;
  final String fingerprint;

  PearRoute(this.bridge, this.fingerprint);
}

/// The car as ONE local port (BladeWatch-rdtj.8). ConnectRPC, the live-view WebSocket and video
/// players all speak plain HTTP to `http://127.0.0.1:<port>` and never learn whether the bytes go
/// over the LAN or Pear. Both routes end in TLS pinned to the certificate from pairing, so the
/// car is authenticated end to end either way.
///
/// Bound to 127.0.0.1 only: nothing else on the phone's network may use it as a way into the car.
class LocalGateway {
  LocalGateway._(this._server) {
    _server.listen(_accept);
  }

  static Future<LocalGateway> start() async =>
      LocalGateway._(await ServerSocket.bind(InternetAddress.loopbackIPv4, 0));

  final ServerSocket _server;

  /// Set by the transport selector; null until the car has been found.
  GatewayRoute? route;

  int get port => _server.port;

  Uri get baseUrl => Uri.parse('http://127.0.0.1:$port');

  Future<void> close() => _server.close();

  Future<void> _accept(Socket local) async {
    try {
      final remote = switch (route) {
        LanRoute(:final endpoint) => await PinnedTls.connect(endpoint.address, endpoint.port, endpoint.fingerprint),
        PearRoute(:final bridge, :final fingerprint) => await openPearTls(bridge, fingerprint),
        null => throw StateError('the car has not been found yet'),
      };
      _splice(local, remote);
    } catch (_) {
      local.destroy();
    }
  }

  /// TLS to the car through one new stream of [bridge]. Dart can only run TLS over a real
  /// socket, so the stream is fronted by a throwaway loopback socket pair: one end goes into the
  /// mux, TLS runs on the other.
  ///
  /// [timeout] defaults to [pearHandshakeTimeout]; see there.
  static Future<SecureSocket> openPearTls(MuxBridge bridge, String fingerprint, {Duration timeout = pearHandshakeTimeout}) async {
    final listener = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    try {
      final accepted = listener.first;
      final raw = await Socket.connect(InternetAddress.loopbackIPv4, listener.port);
      bridge.pipe(await accepted);
      return await PinnedTls.secure(raw, fingerprint, timeout: timeout);
    } finally {
      await listener.close();
    }
  }

  /// How long a TLS handshake through Pear may take (owner's setting, 2026-09-24). The first one
  /// on a connection waits for the car to tag it: pear-end holds a dialing peer's messages until
  /// its own DHT query finds that peer's announcement (flutter_pear's tagInboundConnection),
  /// measured at 11.3 s on the real DHT.
  static const pearHandshakeTimeout = Duration(seconds: 60);

  /// Both directions, with backpressure: addStream pauses the source while the sink is full.
  static void _splice(Socket a, Socket b) {
    Future<void> oneWay(Socket from, Socket to) async {
      try {
        await to.addStream(from);
        await to.close();
      } catch (_) {
        a.destroy();
        b.destroy();
      }
    }

    unawaited(oneWay(a, b));
    unawaited(oneWay(b, a));
  }
}
