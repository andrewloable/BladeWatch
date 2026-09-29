import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bladewatch_companion/car/car_session.dart';
import 'package:bladewatch_companion/car/car_store.dart';
import 'package:bladewatch_companion/transport/car_auth.dart';
import 'package:bladewatch_companion/transport/lan_prober.dart';
import 'package:bladewatch_companion/transport/local_gateway.dart';
import 'package:bladewatch_companion/transport/mux_bridge.dart';
import 'package:bladewatch_companion/transport/pear_link.dart';
import 'package:bladewatch_companion/transport/pear_mux.dart';
import 'package:bladewatch_companion/transport/transport_selector.dart';
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

  /// Messages sent while set vanish, as with a connection that is dying.
  bool lose = false;

  @override
  Stream<Uint8List> get messages => _in.stream;

  @override
  Future<void> send(Uint8List message) async {
    if (!lose && !other._in.isClosed) other._in.add(message);
  }

  Future<void> drop() => _in.close();
}

(LinkEnd, LinkEnd) linkPair() {
  final a = LinkEnd();
  final b = LinkEnd();
  a.other = b;
  b.other = a;
  return (a, b);
}

/// Just enough of the car's PearStreamPump (v2, BladeWatch-bbvx): OPEN -> OPENED and TCP to
/// [port], bytes both ways within the companion's credit, the CLOSE handshake, and REATTACH from
/// any connection it serves -- resending from what the companion received. ponytail: keeps every
/// byte it sent for resending (the real pump trims on WINDOW); fine for test-sized streams.
class FakeCarPump {
  factory FakeCarPump(PeerLink link, int port) => FakeCarPump.shared(port)..serve(link);

  FakeCarPump.shared(this.port);

  final int port;
  final List<_FakeStream> _streams = [];
  int reattaches = 0;

  void serve(PeerLink link) => link.messages.listen((m) => _onMessage(link, m));

  _FakeStream? _find(PeerLink link, int id) {
    for (final s in _streams) {
      if (identical(s.link, link) && s.id == id) return s;
    }
    return null;
  }

  Future<void> _onMessage(PeerLink link, Uint8List message) async {
    final f = PearMux.decode(message)!;
    final s = _find(link, f.stream);
    switch (f.type) {
      case PearMux.open:
        final token = Uint8List.fromList(List.generate(PearMux.tokenBytes, (i) => (f.stream * 31 + i * 7) & 0xff));
        final stream = _FakeStream(link, f.stream, token);
        _streams.add(stream);
        stream.send(PearMux.openedFrame(f.stream, token));
        final socket = await Socket.connect(InternetAddress.loopbackIPv4, port);
        stream.socket = socket;
        socket.listen(
          (bytes) {
            stream.out.addAll(bytes);
            stream.pump();
          },
          onDone: () {
            stream.serverDone = true;
            stream.pump();
          },
          onError: (Object _) {},
        );
      case PearMux.data:
        if (s == null) return;
        s.socket?.add(f.payload);
        s.received += f.payload.length;
        s.recvLimit += f.payload.length;
        s.send(PearMux.windowFrame(f.stream, f.payload.length, s.received));
      case PearMux.window:
        if (s == null) return;
        s.limit += f.credit;
        s.pump();
      case PearMux.close:
        if (s == null) return;
        if (!s.closeSent) s.send(PearMux.closeFrame(f.stream));
        s.socket?.destroy();
        _streams.remove(s);
      case PearMux.reattach:
        final match = _streams.where((x) => _same(x.token, f.token)).firstOrNull;
        if (match == null) {
          unawaited(link.send(PearMux.closeFrame(f.stream)).catchError((Object _) {}));
          return;
        }
        reattaches++;
        match
          ..link = link
          ..id = f.stream
          ..limit = f.limit
          ..sent = f.received;
        match.send(PearMux.reattachedFrame(f.stream, match.received, match.recvLimit));
        match.pump();
    }
  }

  static bool _same(List<int> a, List<int> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return a.length == b.length;
  }
}

class _FakeStream {
  _FakeStream(this.link, this.id, this.token);

  PeerLink link;
  int id;
  final Uint8List token;
  Socket? socket;
  final List<int> out = []; // everything the server sent, for resending
  int sent = 0; // bytes of [out] sent to the companion
  int limit = PearMux.initialWindow;
  int received = 0;
  int recvLimit = PearMux.initialWindow;
  bool serverDone = false;
  bool closeSent = false;

  // A car whose pear_daemon has gone sends nothing more. The drop tests dispose the car's Pear
  // under traffic, and an uncaught WORKLET_DISPOSED from a send in flight then failed whichever
  // test was running (BladeWatch-rdtj.39).
  void send(Uint8List frame) => unawaited(link.send(frame).catchError((Object _) {}));

  void pump() {
    while (sent < out.length && sent < limit) {
      final end = [out.length, limit, sent + PearMux.maxData].reduce((a, b) => a < b ? a : b);
      send(PearMux.dataFrame(id, out.sublist(sent, end)));
      sent = end;
    }
    if (serverDone && sent == out.length && !closeSent) {
      closeSent = true;
      send(PearMux.closeFrame(id));
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

  // BladeWatch-bbvx: the acceptance case in miniature -- a pinned TLS session through the gateway,
  // its Pear connection dying with frames in flight both ways, and the app never noticing.
  test('a TLS session through the gateway survives a Pear reconnect, byte for byte', () async {
    final pump = FakeCarPump.shared(car.port);
    final ends = <(LinkEnd, LinkEnd)>[];
    final selector = TransportSelector(
      gateway: gateway,
      pinnedFingerprint: pin,
      findOnLan: () async => null,
      connectPear: (onClosed) async {
        final pair = linkPair();
        ends.add(pair);
        pump.serve(pair.$2);
        return findCarOverPear(Stream.value(pair.$1), pin, onClosed: onClosed);
      },
    );
    await selector.evaluate();
    expect(selector.phase, TransportPhase.pear);

    final app = await Socket.connect(InternetAddress.loopbackIPv4, gateway.port);
    final pattern = List<int>.generate(200000, (i) => i % 251);
    final got = <int>[];
    var appClosed = false;
    app.listen(got.addAll, onDone: () => appClosed = true, onError: (Object _) {});
    Future<void> until(bool Function() done) async {
      for (var i = 0; i < 1000 && !done(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }

    app.add(pattern.sublist(0, 100000));
    await until(() => got.length >= 50000);
    final (companionEnd, carEnd) = ends.first;
    companionEnd.lose = true; // the connection dies with frames in flight, both ways
    carEnd.lose = true;
    app.add(pattern.sublist(100000));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await companionEnd.drop();
    await carEnd.drop();

    await until(() => got.length >= pattern.length);
    expect(got.length, pattern.length);
    expect(got, pattern, reason: 'every byte, once, in order');
    expect(pump.reattaches, greaterThanOrEqualTo(1));
    expect(ends.length, 2, reason: 'found again on a new connection');
    expect(appClosed, isFalse);
    app.destroy();
    await selector.dispose();
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

      // As in production: the car accepts dialers it never finds announced, and the companion
      // never announces (BladeWatch-lw0o, -qryk).
      final carSwarm = await PearSwarm.join(carRpc, topic, acceptUnannounced: true);
      carSwarm.connections.listen((c) => FakeCarPump(PearConnectionLink(c), car.port));
      final companionSwarm = await PearSwarm.join(companionRpc, topic, announce: false);

      var dropped = false;
      final bridge = await findCarOverPear(pearLinks(companionSwarm), pin, onClosed: () => dropped = true);
      expect(bridge, isNotNull);
      gateway.route = PearRoute(bridge!, pin);
      expect(await roundTrip('through the swarm'), 'through the swarm');

      companionWorklet.disconnectFrom(carWorklet);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(dropped, isTrue, reason: 'PearConnection.data closing is how the selector learns to re-route');
      expect(bridge.isClosed || bridge.isDetached, isTrue, reason: 'detached streams wait for a reattach (bbvx)');
      bridge.shutdown();
      await companionRpc.dispose();
      await carRpc.dispose();
    });

    // BladeWatch-rdtj.24. On the head unit a car-side pear_daemon restart left the session in
    // "discovering" for good: the session kept ONE dial-only swarm, which went on redialing
    // (swarm state "connecting" every few seconds for minutes) and never reached the relaunched
    // car, while a fresh join found it in about 2 s. Modelled here by taking the old swarm out of
    // the topic's membership behind its back, so it can never be connected to the new car --
    // only a session that joins afresh after a drop sees the car again.
    test('after the car drops and comes back, the session finds it again (BladeWatch-rdtj.24)', () async {
      final hub = FakeSwarmHub();
      final topic = PearCrypto.unsafeTopicFromString('bladewatch-test-car');
      final companionWorklet = FakeBareWorklet(hub: hub);
      final companionRpc = PearRpc(companionWorklet);
      await companionRpc.call(PearMethod.attachInfo);
      Future<(PearRpc, FakeBareWorklet)> startCar() async {
        final worklet = FakeBareWorklet(hub: hub);
        final rpc = PearRpc(worklet);
        await rpc.call(PearMethod.attachInfo);
        final swarm = await PearSwarm.join(rpc, topic, acceptUnannounced: true);
        swarm.connections.listen((c) => FakeCarPump(PearConnectionLink(c), car.port));
        return (rpc, worklet);
      }

      Future<void> until(bool Function() done) async {
        for (var i = 0; i < 500 && !done(); i++) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
      }

      final first = await startCar();
      final session = await CarSession.open(
        PairedCar(
          deviceId: 'dev-1',
          pearTopic: topic.hex,
          tlsFingerprint: pin,
          probeKey: 'c' * 64,
          credential: const CompanionCredential('cid', 'tok'),
        ),
        findOnLan: () async => null,
        networkChanges: const Stream.empty(),
        joinTopic: (t) => PearSwarm.join(companionRpc, t, announce: false),
      );
      await until(() => session.phase == TransportPhase.pear);
      expect(session.phase, TransportPhase.pear);

      // The car's pear_daemon dies and a new one takes its place. The old swarm is stale: it will
      // never discover the new car on its own.
      hub.leave(topic.hex, companionWorklet);
      companionWorklet.disconnectFrom(first.$2);
      first.$2.disconnectFrom(companionWorklet);
      await first.$1.dispose();
      final second = await startCar();

      await until(() => session.phase != TransportPhase.pear);
      await until(() => session.phase == TransportPhase.pear);
      expect(session.phase, TransportPhase.pear, reason: 'the session must reach the restarted car');

      session.dispose();
      await companionRpc.dispose();
      await second.$1.dispose();
    });
  });
}
