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

    link.fromCar(PearMux.windowFrame(id, 10000));
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
    link.fromCar(PearMux.windowFrame(4242, 5));
    link.fromCar(PearMux.openFrame(1)); // the car never opens streams
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(bridge.isClosed, isFalse);
    expect(link.log, isEmpty);
  });
}
