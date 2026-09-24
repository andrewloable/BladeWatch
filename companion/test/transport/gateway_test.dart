import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bladewatch_companion/transport/lan_prober.dart';
import 'package:bladewatch_companion/transport/local_gateway.dart';
import 'package:bladewatch_companion/transport/mux_bridge.dart';
import 'package:bladewatch_companion/transport/pear_link.dart';
import 'package:bladewatch_companion/transport/pear_mux.dart';
import 'package:flutter_pear/flutter_pear.dart';
// ignore: implementation_imports
import 'package:flutter_pear/src/rpc.dart';
// ignore: implementation_imports
import 'package:flutter_pear/src/schema.dart';
import 'package:flutter_pear_test/flutter_pear_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_certs.dart';

/// Two in-memory ends of one Pear connection.
class LinkEnd implements PeerLink {
  final _in = StreamController<Uint8List>.broadcast();
  late LinkEnd other;

  @override
  Stream<Uint8List> get messages => _in.stream;

  @override
  Future<void> send(Uint8List message) async => other._in.add(message);

  Future<void> drop() => _in.close();
}

(LinkEnd, LinkEnd) linkPair() {
  final a = LinkEnd();
  final b = LinkEnd();
  a.other = b;
  b.other = a;
  return (a, b);
}

/// Just enough of the car's PearStreamPump: OPEN -> TCP to [port], bytes both ways, CLOSE.
class FakeCarPump {
  FakeCarPump(this.link, this.port) {
    link.messages.listen(_onMessage);
  }

  final PeerLink link;
  final int port;
  final Map<int, Socket> _sockets = {};

  Future<void> _onMessage(Uint8List message) async {
    final f = PearMux.decode(message)!;
    switch (f.type) {
      case PearMux.open:
        final s = await Socket.connect(InternetAddress.loopbackIPv4, port);
        _sockets[f.stream] = s;
        s.listen(
          (bytes) {
            for (var i = 0; i < bytes.length; i += PearMux.maxData) {
              link.send(PearMux.dataFrame(f.stream, bytes.sublist(i, (i + PearMux.maxData).clamp(0, bytes.length))));
            }
          },
          onDone: () => link.send(PearMux.closeFrame(f.stream)),
          onError: (Object _) {},
        );
      case PearMux.data:
        _sockets[f.stream]?.add(f.payload);
        await link.send(PearMux.windowFrame(f.stream, f.payload.length));
      case PearMux.close:
        _sockets.remove(f.stream)?.destroy();
    }
  }
}

/// A peer that joined the topic but is not the car: it never answers anything.
class SilentPeer {
  SilentPeer(PeerLink link) {
    link.messages.listen((_) {});
  }
}

/// BladeWatch-rdtj.8: the local gateway, end to end over both routes.
void main() {
  late SecureServerSocket car;
  late LocalGateway gateway;
  final pin = fingerprintOfPem(certA);

  setUp(() async {
    car = await tlsEchoServer();
    gateway = await LocalGateway.start();
  });

  tearDown(() async {
    await gateway.close();
    await car.close();
  });

  Future<String> roundTrip(String message) async {
    final s = await Socket.connect(InternetAddress.loopbackIPv4, gateway.port);
    s.add(message.codeUnits);
    final reply = await s.first.timeout(const Duration(seconds: 5));
    s.destroy();
    return String.fromCharCodes(reply);
  }

  /// True when the gateway hangs up without sending a byte -- a close or a reset both count.
  Future<bool> isClosedWithoutData() async {
    final s = await Socket.connect(InternetAddress.loopbackIPv4, gateway.port);
    // The refusal is a reset, and a reset fails the pending write too -- on `done`, not the stream.
    unawaited(s.done.then((_) {}, onError: (Object _) {}));
    s.add('hello'.codeUnits);
    var received = 0;
    final done = Completer<void>();
    void finish() => done.isCompleted ? null : done.complete(); // an error is followed by done
    s.listen((b) => received += b.length, onDone: finish, onError: (Object _) => finish());
    await done.future.timeout(const Duration(seconds: 15));
    s.destroy();
    return received == 0;
  }

  test('the gateway listens on loopback only', () {
    expect(gateway.baseUrl.host, '127.0.0.1');
    expect(gateway.baseUrl.port, gateway.port);
  });

  test('with no route yet, a connection is refused rather than left hanging', () async {
    expect(await isClosedWithoutData(), isTrue);
  });

  test('LAN route: plain HTTP in, pinned TLS to the car, bytes both ways', () async {
    gateway.route = LanRoute(LanEndpoint(InternetAddress.loopbackIPv4, car.port, pin));
    expect(await roundTrip('GET /status'), 'GET /status');
  });

  test('LAN route: a car presenting any other certificate is refused', () async {
    gateway.route = LanRoute(LanEndpoint(InternetAddress.loopbackIPv4, car.port, fingerprintOfPem(certB)));
    expect(await isClosedWithoutData(), isTrue);
  });

  test('Pear route: TLS runs end to end through the mux to the car', () async {
    final (companionEnd, carEnd) = linkPair();
    FakeCarPump(carEnd, car.port);
    gateway.route = PearRoute(MuxBridge(companionEnd), pin);
    expect(await roundTrip('GET /status'), 'GET /status');
    expect(await roundTrip('again'), 'again', reason: 'every connection is its own stream');
  });

  test('Pear route: a peer that cannot present the pinned certificate gets nothing', () async {
    final (companionEnd, carEnd) = linkPair();
    FakeCarPump(carEnd, car.port);
    gateway.route = PearRoute(MuxBridge(companionEnd), fingerprintOfPem(certB));
    expect(await isClosedWithoutData(), isTrue);
  });

  group('findCarOverPear', () {
    test('picks the peer that proves to be the car, not another companion on the topic', () async {
      final (silentCompanion, silentOther) = linkPair();
      SilentPeer(silentOther);
      final (carLinkCompanion, carLinkCar) = linkPair();
      FakeCarPump(carLinkCar, car.port);

      final links = StreamController<PeerLink>();
      final found = findCarOverPear(links.stream, pin, timeout: const Duration(seconds: 20));
      links.add(silentCompanion); // another paired phone connects first
      links.add(carLinkCompanion);
      final bridge = await found;
      expect(bridge, isNotNull);
      gateway.route = PearRoute(bridge!, pin);
      expect(await roundTrip('via the real car'), 'via the real car');
      await links.close();
    });

    test('no car within the timeout is null', () async {
      final links = StreamController<PeerLink>();
      expect(await findCarOverPear(links.stream, pin, timeout: const Duration(milliseconds: 200)), isNull);
      await links.close();
    });

    test('only the chosen connection reports that it dropped', () async {
      final drops = <String>[];
      final (rejected, _) = linkPair();
      final (chosen, _) = linkPair();
      final links = StreamController<PeerLink>();
      var offered = 0;
      final found = findCarOverPear(
        links.stream,
        pin,
        onClosed: () => drops.add('car'),
        isCar: (_, _) async => ++offered == 2, // the second peer offered is the car
      );
      links.add(rejected);
      links.add(chosen);
      expect(await found, isNotNull);
      expect(drops, isEmpty, reason: 'the rejected peer is shut down without reporting');
      // Drop each connection from the bridge's own side, as flutter_pear does when it closes.
      await rejected.drop();
      await chosen.drop();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(drops, ['car']);
      await links.close();
    });

    test('over flutter_pear itself: found through the swarm, TLS through it, and a drop is reported', () async {
      final hub = FakeSwarmHub();
      final companionWorklet = FakeBareWorklet(hub: hub);
      final companionRpc = PearRpc(companionWorklet);
      final carWorklet = FakeBareWorklet(hub: hub);
      final carRpc = PearRpc(carWorklet);
      await companionRpc.call(PearMethod.attachInfo);
      await carRpc.call(PearMethod.attachInfo);
      final topic = PearCrypto.unsafeTopicFromString('bladewatch-test-car');

      final carSwarm = await PearSwarm.join(carRpc, topic);
      carSwarm.connections.listen((c) => FakeCarPump(PearConnectionLink(c), car.port));
      final companionSwarm = await PearSwarm.join(companionRpc, topic);

      var dropped = false;
      final bridge = await findCarOverPear(pearLinks(companionSwarm), pin, onClosed: () => dropped = true);
      expect(bridge, isNotNull);
      gateway.route = PearRoute(bridge!, pin);
      expect(await roundTrip('through the swarm'), 'through the swarm');

      companionWorklet.disconnectFrom(carWorklet);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(dropped, isTrue, reason: 'PearConnection.data closing is how the selector learns to re-route');
      expect(bridge.isClosed, isTrue);
      await companionRpc.dispose();
      await carRpc.dispose();
    });
  });
}
