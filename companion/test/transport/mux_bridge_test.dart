import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bladewatch_companion/transport/mux_bridge.dart';
import 'package:bladewatch_companion/transport/pear_mux.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Pear connection in memory: what the companion sent, and a way to play the car.
class FakeLink implements PeerLink {
  final _fromCar = StreamController<Uint8List>();
  final sent = StreamController<MuxFrame>.broadcast();
  final List<MuxFrame> log = [];
  bool failSends = false;

  @override
  Stream<Uint8List> get messages => _fromCar.stream;

  @override
  Future<void> send(Uint8List message) async {
    if (failSends) throw StateError('connection closed');
    final f = PearMux.decode(message)!;
    log.add(f);
    sent.add(f);
  }

  void fromCar(Uint8List frame) => _fromCar.add(frame);

  Future<void> drop() => _fromCar.close();
}

/// BladeWatch-rdtj.8: the companion side of the stream pump.
void main() {
  late ServerSocket server;
  late FakeLink link;
  late MuxBridge bridge;
  final clients = <Socket>[];

  setUp(() async {
    server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    link = FakeLink();
    bridge = MuxBridge(link, window: 64 * 1024);
    server.listen(bridge.pipe);
  });

  tearDown(() async {
    for (final c in clients) {
      c.destroy();
    }
    clients.clear();
    bridge.shutdown();
    await server.close();
  });

  Future<Socket> connect() async {
    final c = await Socket.connect(InternetAddress.loopbackIPv4, server.port);
    clients.add(c);
    return c;
  }

  Future<MuxFrame> nextSent(int type, {int? stream}) =>
      link.sent.stream.firstWhere((f) => f.type == type && (stream == null || f.stream == stream)).timeout(const Duration(seconds: 5));

  test('a local connection opens a stream and its bytes reach the car in order', () async {
    final opened = nextSent(PearMux.open);
    final c = await connect();
    final id = (await opened).stream;
    final data = nextSent(PearMux.data, stream: id);
    c.add('GET /status'.codeUnits);
    expect((await data).payload, 'GET /status'.codeUnits);
    expect(link.log.first.type, PearMux.open, reason: 'OPEN must precede any DATA');
  });

  test('bytes from the car reach the local client, and credit goes back once they have left', () async {
    final opened = nextSent(PearMux.open);
    final c = await connect();
    final id = (await opened).stream;
    final received = <int>[];
    c.listen(received.addAll);
    final granted = nextSent(PearMux.window, stream: id);
    link.fromCar(PearMux.dataFrame(id, 'HTTP/1.1 200'.codeUnits));
    expect((await granted).credit, 12);
    await Future.doWhile(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return received.length < 12;
    }).timeout(const Duration(seconds: 5));
    expect(String.fromCharCodes(received), 'HTTP/1.1 200');
  });

  test('two local connections get their own streams and never cross', () async {
    final opens = link.sent.stream.where((f) => f.type == PearMux.open).take(2).toList();
    final a = await connect();
    final b = await connect();
    final ids = (await opens).map((f) => f.stream).toList();
    expect(ids.toSet(), hasLength(2));
    final dataFrames = link.sent.stream.where((f) => f.type == PearMux.data).take(2).toList();
    a.add('AAAA'.codeUnits);
    b.add('BBBB'.codeUnits);
    final frames = await dataFrames.timeout(const Duration(seconds: 5));
    for (final f in frames) {
      final expected = f.stream == ids.first ? 'AAAA' : 'BBBB';
      // Which socket was accepted first is up to the OS; each stream must carry one sender only.
      expect(String.fromCharCodes(f.payload), anyOf('AAAA', 'BBBB'));
      expect(frames.where((g) => g.stream == f.stream).map((g) => String.fromCharCodes(g.payload)).toSet(), hasLength(1),
          reason: 'stream ${f.stream} mixed senders ($expected)');
    }
    expect(frames.map((f) => f.stream).toSet(), hasLength(2));
  });

  test('a local close is sent to the car, and a close from the car closes the local socket', () async {
    final opened = nextSent(PearMux.open);
    final c = await connect();
    final id = (await opened).stream;
    final closed = nextSent(PearMux.close, stream: id);
    await c.close();
    expect((await closed).stream, id);

    final opened2 = nextSent(PearMux.open);
    final c2 = await connect();
    final id2 = (await opened2).stream;
    final done = Completer<void>();
    c2.listen((_) {}, onDone: done.complete);
    link.fromCar(PearMux.closeFrame(id2));
    await done.future.timeout(const Duration(seconds: 5));
    expect(bridge.openStreams, 1, reason: 'the first waits for the car to answer its CLOSE');
    link.fromCar(PearMux.closeFrame(id));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(bridge.openStreams, 0);
  });

  test('without credit from the car the local socket is not read past one window', () async {
    final opened = nextSent(PearMux.open);
    final c = await connect();
    final id = (await opened).stream;
    c.add(Uint8List(3 * 64 * 1024));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    int sentBytes() => link.log.where((f) => f.type == PearMux.data && f.stream == id).fold(0, (n, f) => n + f.payload.length);
    expect(sentBytes(), 64 * 1024, reason: 'exactly one window, then nothing until the car grants');

    link.fromCar(PearMux.windowFrame(id, 10000, 0));
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(sentBytes(), 64 * 1024 + 10000, reason: 'each grant releases exactly that much');
  });

  test('a car that overruns its credit loses the stream', () async {
    final opened = nextSent(PearMux.open);
    final c = await connect();
    final id = (await opened).stream;
    final closed = nextSent(PearMux.close, stream: id);
    final done = Completer<void>();
    c.listen((_) {}, onDone: done.complete);
    // Two full windows back to back, faster than any credit can come back.
    for (var i = 0; i < 5; i++) {
      link.fromCar(PearMux.dataFrame(id, Uint8List(PearMux.maxData)));
    }
    link.fromCar(PearMux.dataFrame(id, Uint8List(PearMux.maxData)));
    link.fromCar(PearMux.dataFrame(id, Uint8List(PearMux.maxData)));
    await closed;
    await done.future.timeout(const Duration(seconds: 5));
  });

  test('a dropped Pear connection closes every local socket, and later ones are refused', () async {
    final opened = nextSent(PearMux.open);
    final c = await connect();
    await opened;
    final done = Completer<void>();
    c.listen((_) {}, onDone: done.complete);
    await link.drop();
    await done.future.timeout(const Duration(seconds: 5));
    expect(bridge.isClosed, isTrue);

    final late = await connect();
    final lateDone = Completer<void>();
    late.listen((_) {}, onDone: lateDone.complete, onError: (Object _) => lateDone.complete());
    await lateDone.future.timeout(const Duration(seconds: 5));
  });

  test('a failed write to the car tears the bridge down', () async {
    link.failSends = true;
    final c = await connect();
    final done = Completer<void>();
    c.listen((_) {}, onDone: done.complete, onError: (Object _) => done.complete());
    await done.future.timeout(const Duration(seconds: 5));
    expect(bridge.isClosed, isTrue);
  });

  test('junk and frames for unknown streams are ignored', () async {
    link.fromCar(Uint8List.fromList([9, 9]));
    link.fromCar(PearMux.dataFrame(4242, [1]));
    link.fromCar(PearMux.windowFrame(4242, 5, 0));
    link.fromCar(PearMux.openFrame(1)); // the car never opens streams
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(bridge.isClosed, isFalse);
    expect(link.log, isEmpty);
  });

  // BladeWatch-bbvx: streams outlive the Pear connection they started on.
  group('across a reconnect', () {
    final token = Uint8List.fromList(List.generate(16, (i) => 100 + i));

    Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

    /// A local client on [bridge]'s stream whose OPEN the car has answered with [token]: the
    /// socket, the stream id, what it has received, and when it closes.
    Future<(Socket, int, List<int>, Future<void>)> openedStream() async {
      final opened = nextSent(PearMux.open);
      final c = await connect();
      final id = (await opened).stream;
      link.fromCar(PearMux.openedFrame(id, token));
      final got = <int>[];
      final done = Completer<void>();
      c.listen(got.addAll, onDone: done.complete, onError: (Object _) {});
      await settle();
      return (c, id, got, done.future);
    }

    test('a dropped connection detaches: the local socket stays open and onClosed fires once', () async {
      var told = 0;
      final l = FakeLink();
      final b = MuxBridge(l, onClosed: () => told++, grace: const Duration(milliseconds: 300));
      final srv = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      srv.listen(b.pipe);
      final opened = l.sent.stream.firstWhere((f) => f.type == PearMux.open);
      final c = await Socket.connect(InternetAddress.loopbackIPv4, srv.port);
      clients.add(c);
      final id = (await opened.timeout(const Duration(seconds: 5))).stream;
      l.fromCar(PearMux.openedFrame(id, token));
      var closed = false;
      c.listen((_) {}, onDone: () => closed = true);
      await settle();

      await l.drop();
      await settle();
      expect(b.isDetached, isTrue);
      expect(closed, isFalse, reason: 'the app keeps its connection through the gap');
      expect(told, 1);

      await Future<void>.delayed(const Duration(milliseconds: 400)); // past the grace period
      expect(b.isClosed, isTrue);
      expect(closed, isTrue);
      expect(told, 1, reason: 'reported once, not again when the grace period ends');
      await srv.close();
    });

    test('a stream the car never confirmed closes with the connection, as before', () async {
      final opened = nextSent(PearMux.open);
      final c = await connect();
      await opened; // no OPENED: no token to come back with
      final done = Completer<void>();
      c.listen((_) {}, onDone: done.complete);
      await link.drop();
      await done.future.timeout(const Duration(seconds: 5));
      expect(bridge.isClosed, isTrue);
    });

    test('adopted: REATTACH with the token, stale frames ignored, both sides resend from the other\'s offset', () async {
      final (c, id, got, _) = await openedStream();
      link.fromCar(PearMux.dataFrame(id, 'hello'.codeUnits));
      c.add('abcdef'.codeUnits);
      await settle();
      expect(String.fromCharCodes(got), 'hello');
      final sentBefore = link.log.where((f) => f.type == PearMux.data && f.stream == id).expand((f) => f.payload);
      expect(String.fromCharCodes(sentBefore), 'abcdef');

      await link.drop();
      await settle();
      c.add('ghi'.codeUnits); // written during the gap: waits
      await settle();

      final link2 = FakeLink();
      final b2 = MuxBridge(link2, window: 64 * 1024);
      final reattach = link2.sent.stream.firstWhere((f) => f.type == PearMux.reattach);
      b2.adopt(bridge);
      final r = await reattach.timeout(const Duration(seconds: 5));
      expect(r.stream, id, reason: 'the stream keeps its id');
      expect(r.token, token);
      expect(r.received, 5, reason: 'it has "hello"');
      expect(bridge.isClosed, isTrue);
      expect(b2.openStreams, 1);

      link2.fromCar(PearMux.dataFrame(id, 'zzz'.codeUnits)); // the car, still sending into the gap
      await settle();
      expect(link2.log.where((f) => f.type == PearMux.data), isEmpty, reason: 'nothing until the car answers');

      // The car got only "abc" before the drop.
      link2.fromCar(PearMux.reattachedFrame(id, 3, 1000));
      link2.fromCar(PearMux.dataFrame(id, ' world'.codeUnits));
      await settle();
      final resent = link2.log.where((f) => f.type == PearMux.data).expand((f) => f.payload);
      expect(String.fromCharCodes(resent), 'defghi');
      expect(String.fromCharCodes(got), 'hello world', reason: 'the stale "zzz" never reached the app');
      b2.shutdown();
    });

    test('a local connection made during the gap opens once adopted', () async {
      await openedStream();
      await link.drop();
      await settle();
      final c = await connect(); // piped into the detached bridge
      c.add('late'.codeUnits);
      await settle();

      final link2 = FakeLink();
      final b2 = MuxBridge(link2);
      b2.adopt(bridge);
      await settle();
      final open = link2.log.firstWhere((f) => f.type == PearMux.open);
      final data = link2.log.where((f) => f.type == PearMux.data && f.stream == open.stream).expand((f) => f.payload);
      expect(String.fromCharCodes(data), 'late');
      expect(link2.log.map((f) => f.type), containsAllInOrder([PearMux.reattach, PearMux.open, PearMux.data]));
      b2.shutdown();
    });

    test('adopting a live bridge (the transport re-routed first): a stream the car never confirmed closes', () async {
      final opened = nextSent(PearMux.open);
      final c = await connect();
      await opened; // OPEN is out, no OPENED yet
      final done = Completer<void>();
      c.listen((_) {}, onDone: done.complete, onError: (Object _) {});
      final b2 = MuxBridge(FakeLink());
      b2.adopt(bridge);
      await done.future.timeout(const Duration(seconds: 5));
      expect(bridge.isClosed, isTrue);
      expect(b2.openStreams, 0);
      b2.shutdown();
    });

    test('ids never repeat across bridges, so adopted streams cannot collide', () async {
      final (_, id, _, _) = await openedStream();
      final link2 = FakeLink();
      final b2 = MuxBridge(link2);
      final srv2 = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      srv2.listen(b2.pipe);
      final opened = link2.sent.stream.firstWhere((f) => f.type == PearMux.open);
      clients.add(await Socket.connect(InternetAddress.loopbackIPv4, srv2.port));
      expect((await opened.timeout(const Duration(seconds: 5))).stream, isNot(id));
      b2.shutdown();
      await srv2.close();
    });

    test('a CLOSE the gap swallowed goes out again after the reattach', () async {
      final (c, id, _, _) = await openedStream();
      link.failSends = true; // the connection is dying: this CLOSE is lost...
      await c.close();
      await settle();
      final link2 = FakeLink();
      final b2 = MuxBridge(link2);
      b2.adopt(bridge); // ...and the transport found the car again before noticing the drop
      final r = link2.log.firstWhere((f) => f.type == PearMux.reattach);
      final close = link2.sent.stream.firstWhere((f) => f.type == PearMux.close);
      link2.fromCar(PearMux.reattachedFrame(id, 0, 1000));
      expect((await close.timeout(const Duration(seconds: 5))).stream, r.stream);
      link2.fromCar(PearMux.closeFrame(id)); // the car answers
      await settle();
      expect(b2.openStreams, 0);
      b2.shutdown();
    });

    test('a refused reattach closes the local socket, after what already arrived', () async {
      final (_, id, got, done) = await openedStream();
      link.fromCar(PearMux.dataFrame(id, 'partial'.codeUnits));
      await settle();
      await link.drop();
      final link2 = FakeLink();
      final b2 = MuxBridge(link2);
      b2.adopt(bridge);
      link2.fromCar(PearMux.closeFrame(id)); // the car no longer has it
      await done.timeout(const Duration(seconds: 5));
      expect(String.fromCharCodes(got), 'partial');
      expect(b2.openStreams, 0);
      b2.shutdown();
    });

    test('REATTACHED with offsets this side never sent closes the stream', () async {
      final (_, id, _, _) = await openedStream();
      await link.drop();
      final link2 = FakeLink();
      final b2 = MuxBridge(link2);
      final close = link2.sent.stream.firstWhere((f) => f.type == PearMux.close);
      b2.adopt(bridge);
      link2.fromCar(PearMux.reattachedFrame(id, 99, 1000)); // it never sent 99 bytes
      expect((await close.timeout(const Duration(seconds: 5))).stream, id);
      expect(b2.openStreams, 0);
      b2.shutdown();
    });
  });

  // BladeWatch-rdtj.28: one stream moves at most window / round-trip, so the companion lets the car
  // run further ahead than the protocol's initial window -- as extra credit, with no protocol change.
  group('a receive window larger than the protocol window', () {
    late ServerSocket bigServer;
    late FakeLink bigLink;
    late MuxBridge big;

    setUp(() async {
      bigServer = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      bigLink = FakeLink();
      big = MuxBridge(bigLink, window: 64 * 1024, receiveWindow: 256 * 1024);
      bigServer.listen(big.pipe);
    });

    tearDown(() async {
      big.shutdown();
      await bigServer.close();
    });

    test('is granted to the car as extra credit right after OPEN', () async {
      final opened = bigLink.sent.stream.firstWhere((f) => f.type == PearMux.open);
      final extra = bigLink.sent.stream.firstWhere((f) => f.type == PearMux.window);
      final c = await Socket.connect(InternetAddress.loopbackIPv4, bigServer.port);
      clients.add(c);
      final id = (await opened).stream;
      final w = await extra.timeout(const Duration(seconds: 5));
      expect(w.stream, id);
      expect(w.credit, 192 * 1024, reason: 'receive window minus the protocol window');
      expect(bigLink.log.take(2).map((f) => f.type), [PearMux.open, PearMux.window], reason: 'before any data');
    });

    test('lets the car send the whole receive window, and still cuts it off beyond that', () async {
      final opened = bigLink.sent.stream.firstWhere((f) => f.type == PearMux.open);
      final c = await Socket.connect(InternetAddress.loopbackIPv4, bigServer.port);
      clients.add(c); // never read: no credit goes back while the car sends
      final id = (await opened).stream;
      var closed = false;
      final cut = bigLink.sent.stream.firstWhere((f) => f.type == PearMux.close && f.stream == id);
      unawaited(cut.then((_) => closed = true));
      // 4 x 32 KB = 128 KB: past the 64 KB protocol window, inside the 256 KB receive window.
      for (var i = 0; i < 4; i++) {
        bigLink.fromCar(PearMux.dataFrame(id, Uint8List(PearMux.maxData)));
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(closed, isFalse, reason: 'within the receive window');
      // Far past it (plus whatever the local socket's kernel buffer absorbs).
      for (var i = 0; i < 64; i++) {
        bigLink.fromCar(PearMux.dataFrame(id, Uint8List(PearMux.maxData)));
      }
      await cut.timeout(const Duration(seconds: 5));
    });
  });
}
