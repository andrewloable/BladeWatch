import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_pear/flutter_pear.dart';

import 'local_gateway.dart';
import 'mux_bridge.dart';
import 'pear_mux.dart';

/// flutter_pear's connection, as the transport sees it: messages in, messages out. `data` closes
/// when the peer drops, which is how [MuxBridge] learns the car is gone.
///
/// `data` is a broadcast stream, so anything that arrives before a listener is lost. That is safe
/// only because the car never speaks first: every stream starts with the companion's OPEN.
class PearConnectionLink implements PeerLink {
  PearConnectionLink(this._connection);

  final PearConnection _connection;

  @override
  Stream<Uint8List> get messages => _connection.data;

  @override
  Future<void> send(Uint8List message) => _connection.write(message);
}

/// Finds the CAR among the peers on its topic (BladeWatch-rdtj.8).
///
/// pear-end joins every topic as server and client, so the companion's other paired devices
/// announce there too and can connect to this one. A peer counts as the car only once a TLS
/// handshake through it completes against [fingerprint] -- the pin from pairing, which only the
/// car's certificate matches. Other companions never answer, and are dropped after the handshake
/// times out. Returns null if no peer proves itself within [timeout].
Future<MuxBridge?> findCarOverPear(
  Stream<PeerLink> links,
  String fingerprint, {
  void Function()? onClosed,
  // Longer than LocalGateway.pearHandshakeTimeout, so a peer that connects late still gets it.
  Duration timeout = const Duration(seconds: 90),
  Future<bool> Function(MuxBridge bridge, String fingerprint)? isCar,
}) async {
  final check = isCar ?? _completesPinnedTls;
  final found = Completer<MuxBridge?>();
  final sub = links.listen((link) async {
    if (found.isCompleted) return;
    var chosen = false;
    late final MuxBridge bridge;
    // Only the peer that proved to be the car reports its connection dropping.
    bridge = MuxBridge(link, onClosed: () => chosen ? onClosed?.call() : null);
    if (await check(bridge, fingerprint) && !found.isCompleted) {
      chosen = true;
      found.complete(bridge);
    } else {
      bridge.shutdown();
    }
  });
  final timer = Timer(timeout, () => found.isCompleted ? null : found.complete(null));
  final car = await found.future;
  timer.cancel();
  await sub.cancel();
  return car;
}


Future<bool> _completesPinnedTls(MuxBridge bridge, String fingerprint) async {
  try {
    final tls = await LocalGateway.openPearTls(bridge, fingerprint);
    tls.destroy();
    return true;
  } catch (_) {
    return false;
  }
}

/// Every peer connection [swarm] (the car's topic, `pear.join(PearKey.fromHex(topic))`) yields.
Stream<PeerLink> pearLinks(PearSwarm swarm) => swarm.connections.map(PearConnectionLink.new);
