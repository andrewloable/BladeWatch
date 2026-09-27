import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bladewatch_companion/transport/lan_prober.dart';
import 'package:bladewatch_companion/transport/local_gateway.dart';
import 'package:bladewatch_companion/transport/mux_bridge.dart';
import 'package:bladewatch_companion/transport/pear_mux.dart';
import 'package:bladewatch_companion/transport/transport_selector.dart';
import 'package:flutter_test/flutter_test.dart';

class QuietLink implements PeerLink {
  final _in = StreamController<Uint8List>.broadcast();

  @override
  Stream<Uint8List> get messages => _in.stream;

  @override
  Future<void> send(Uint8List message) async {}

  Future<void> drop() => _in.close();
}

/// A car that answers every OPEN with OPENED, so its streams can be resumed; records what it got.
class AnsweringLink implements PeerLink {
  final _in = StreamController<Uint8List>.broadcast();
  final List<MuxFrame> log = [];

  @override
  Stream<Uint8List> get messages => _in.stream;

  @override
  Future<void> send(Uint8List message) async {
    final f = PearMux.decode(message)!;
    log.add(f);
    if (f.type == PearMux.open && !_in.isClosed) _in.add(PearMux.openedFrame(f.stream, List.filled(16, 7)));
  }

  Future<void> drop() => _in.close();
}

/// BladeWatch-rdtj.8: choosing between the LAN and Pear, and noticing when that choice goes stale.
void main() {
  late LocalGateway gateway;
  final lan = LanEndpoint(InternetAddress('192.168.1.50'), 8443, 'ab' * 32);

  setUp(() async => gateway = await LocalGateway.start());
  tearDown(() => gateway.close());

  TransportSelector selector({
    required Future<LanEndpoint?> Function() findOnLan,
    required Future<MuxBridge?> Function(void Function() onClosed) connectPear,
    Stream<void>? networkChanges,
    Duration retryAfter = const Duration(seconds: 30),
  }) =>
      TransportSelector(
        gateway: gateway,
        pinnedFingerprint: 'ab' * 32,
        findOnLan: findOnLan,
        connectPear: connectPear,
        networkChanges: networkChanges,
        retryAfter: retryAfter,
      );

  test('the LAN wins when the car answers a probe, and Pear is not even tried', () async {
    var pearTried = false;
    final s = selector(findOnLan: () async => lan, connectPear: (_) async {
      pearTried = true;
      return null;
    });
    await s.evaluate();
    expect(s.phase, TransportPhase.lan);
    expect((gateway.route as LanRoute).endpoint, lan);
    expect(pearTried, isFalse);
    await s.dispose();
  });

  test('no answer on the LAN falls back to Pear', () async {
    final bridge = MuxBridge(QuietLink());
    final s = selector(findOnLan: () async => null, connectPear: (_) async => bridge);
    await s.evaluate();
    expect(s.phase, TransportPhase.pear);
    final route = gateway.route as PearRoute;
    expect(route.bridge, same(bridge));
    expect(route.fingerprint, 'ab' * 32, reason: 'the Pear route is pinned to the pairing certificate too');
    await s.dispose();
  });

  test('a LAN probe that throws counts as no answer, and Pear is tried (gfmk)', () async {
    final bridge = MuxBridge(QuietLink());
    final s = selector(findOnLan: () async => throw const SocketException('No route to host'), connectPear: (_) async => bridge);
    await s.evaluate();
    expect(s.phase, TransportPhase.pear);
    await s.dispose();
  });

  test('a Pear step that throws ends in failed, which still retries by itself (gfmk)', () async {
    var attempts = 0;
    final s = selector(
      findOnLan: () async => throw StateError('probe'),
      connectPear: (_) async {
        attempts++;
        throw StateError('worklet');
      },
      retryAfter: const Duration(milliseconds: 100),
    );
    await s.evaluate();
    expect(s.phase, TransportPhase.failed);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(attempts, greaterThanOrEqualTo(2));
    await s.dispose();
  });

  test('"still looking" and "failed" are different phases, and a failure retries by itself', () async {
    var attempts = 0;
    final s = selector(
      findOnLan: () async => null,
      connectPear: (_) async {
        attempts++;
        return null;
      },
      retryAfter: const Duration(milliseconds: 100),
    );
    final seen = <TransportPhase>[];
    s.phases.listen(seen.add);
    await s.evaluate();
    await Future<void>.delayed(Duration.zero); // a broadcast stream delivers on a later microtask
    expect(seen, [TransportPhase.discovering, TransportPhase.failed]);
    expect(gateway.route, isNull);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(attempts, greaterThanOrEqualTo(2), reason: 'it keeps trying after a failure');
    await s.dispose();
  });

  test('a network change re-evaluates: leaving the car\'s Wi-Fi moves the session to Pear', () async {
    var onCarWifi = true;
    final changes = StreamController<void>();
    final s = selector(
      findOnLan: () async => onCarWifi ? lan : null,
      connectPear: (_) async => MuxBridge(QuietLink()),
      networkChanges: changes.stream,
    );
    s.start();
    await pumpUntil(() => s.phase == TransportPhase.lan);
    onCarWifi = false;
    changes.add(null);
    await pumpUntil(() => s.phase == TransportPhase.pear);
    expect(gateway.route, isA<PearRoute>());
    await s.dispose();
    await changes.close();
  });

  test('the Pear connection dropping re-evaluates, and the dead bridge is replaced', () async {
    final links = <QuietLink>[];
    final s = selector(
      findOnLan: () async => null,
      connectPear: (onClosed) async {
        final link = QuietLink();
        links.add(link);
        return MuxBridge(link, onClosed: onClosed);
      },
    );
    await s.evaluate();
    final first = (gateway.route as PearRoute).bridge;
    await links.first.drop();
    await pumpUntil(() => links.length == 2 && s.phase == TransportPhase.pear);
    expect((gateway.route as PearRoute).bridge, isNot(same(first)));
    expect(first.isClosed, isTrue);
    await s.dispose();
  });

  test('a newer evaluation supersedes one still in flight', () async {
    final slowLan = Completer<LanEndpoint?>();
    var calls = 0;
    final s = selector(
      findOnLan: () {
        calls++;
        return calls == 1 ? slowLan.future : Future.value(null);
      },
      connectPear: (_) async => MuxBridge(QuietLink()),
    );
    final first = s.evaluate();
    await s.evaluate(); // lands on Pear
    slowLan.complete(lan); // the stale answer arrives late
    await first;
    expect(s.phase, TransportPhase.pear, reason: 'a stale LAN answer must not win');
    await s.dispose();
  });

  test('a Pear connection that arrives after being superseded is shut down', () async {
    final slowPear = Completer<MuxBridge?>();
    var calls = 0;
    final s = selector(
      findOnLan: () async => calls++ == 0 ? null : lan,
      connectPear: (_) => slowPear.future,
    );
    final first = s.evaluate();
    await Future<void>.delayed(Duration.zero);
    await s.evaluate(); // now the LAN answers
    final late = MuxBridge(QuietLink());
    slowPear.complete(late);
    await first;
    expect(late.isClosed, isTrue);
    expect(s.phase, TransportPhase.lan);
    await s.dispose();
  });

  test('after dispose nothing runs and the route is cleared', () async {
    final s = selector(findOnLan: () async => lan, connectPear: (_) async => null);
    await s.evaluate();
    await s.dispose();
    await s.evaluate();
    expect(gateway.route, isNull);
  });

  test('addressChanges fires when the set of addresses changes, not on every poll', () async {
    final answers = [
      ['192.168.1.2'],
      null, // a poll that fails is skipped, not reported as a change
      ['192.168.1.2'],
      ['10.0.0.7'],
    ];
    var i = 0;
    final events = <void>[];
    final errors = <Object>[];
    final sub = addressChanges(
      every: const Duration(milliseconds: 5),
      ownAddresses: () async {
        final answer = answers[i < answers.length - 1 ? i++ : i];
        if (answer == null) throw const SocketException('no interfaces');
        return [for (final a in answer) InternetAddress(a)];
      },
    ).listen(events.add, onError: errors.add);
    // Until the change arrives, not a fixed 100 ms: under coverage a 5 ms poll can run far fewer
    // times than that allows, and the test failed with no event at all (BladeWatch-rdtj.39). Then
    // a few more polls, which must stay quiet: the last answer repeats.
    final sw = Stopwatch()..start();
    while (events.isEmpty && sw.elapsed < const Duration(seconds: 5)) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await sub.cancel().timeout(const Duration(seconds: 1));
    expect(events, hasLength(1));
    expect(errors, isEmpty);
  });

  // BladeWatch-bbvx: what a dropped Pear connection carried goes on over the next one.
  group('streams across a Pear reconnect', () {
    late ServerSocket local;
    final sockets = <Socket>[];

    setUp(() async => local = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0));
    tearDown(() async {
      for (final c in sockets) {
        c.destroy();
      }
      sockets.clear();
      await local.close();
    });

    /// One app connection carried by [bridge]; the completer completes when the app's socket closes.
    Future<Completer<void>> carry(MuxBridge bridge) async {
      final accepted = local.first;
      final app = await Socket.connect(InternetAddress.loopbackIPv4, local.port);
      sockets.add(app);
      bridge.pipe(await accepted);
      final done = Completer<void>();
      app.listen((_) {}, onDone: done.complete, onError: (Object _) {});
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return done;
    }

    test('the next Pear route adopts the dropped one\'s streams', () async {
      final links = [AnsweringLink(), AnsweringLink()];
      final bridges = <MuxBridge>[];
      final s = selector(
        findOnLan: () async => null,
        connectPear: (onClosed) async => (bridges..add(MuxBridge(links[bridges.length], onClosed: onClosed))).last,
      );
      await s.evaluate();
      final appDone = await carry(bridges[0]);
      await links[0].drop();
      await pumpUntil(() => bridges.length == 2 && s.phase == TransportPhase.pear);
      expect(links[1].log.map((f) => f.type), contains(PearMux.reattach));
      expect(bridges[0].isClosed, isTrue);
      expect(bridges[1].openStreams, 1);
      var closed = false;
      unawaited(appDone.future.then((_) => closed = true));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(closed, isFalse, reason: 'the app never saw the drop');
      await s.dispose();
    });

    test('while Pear keeps failing the dropped bridge is parked, and a later route adopts it', () async {
      final first = AnsweringLink();
      final later = AnsweringLink();
      var calls = 0;
      late MuxBridge b1;
      final s = selector(
        findOnLan: () async => null,
        retryAfter: const Duration(milliseconds: 50),
        connectPear: (onClosed) async => switch (++calls) {
          1 => b1 = MuxBridge(first, onClosed: onClosed),
          2 => null, // the car is not found at once
          _ => MuxBridge(later, onClosed: onClosed),
        },
      );
      await s.evaluate();
      await carry(b1);
      await first.drop();
      await pumpUntil(() => calls >= 3 && s.phase == TransportPhase.pear);
      expect(later.log.map((f) => f.type), contains(PearMux.reattach));
      await s.dispose();
    });

    test('finding the car on the LAN instead closes the parked streams', () async {
      final first = AnsweringLink();
      var calls = 0;
      late MuxBridge b1;
      var onLan = false;
      final s = selector(
        findOnLan: () async => onLan ? lan : null,
        retryAfter: const Duration(milliseconds: 50),
        connectPear: (onClosed) async {
          if (++calls == 1) return b1 = MuxBridge(first, onClosed: onClosed);
          onLan = true; // the phone joins the car's Wi-Fi meanwhile
          return null;
        },
      );
      await s.evaluate();
      final appDone = await carry(b1);
      await first.drop();
      await pumpUntil(() => s.phase == TransportPhase.lan);
      await appDone.future.timeout(const Duration(seconds: 5));
      expect(b1.isClosed, isTrue);
      await s.dispose();
    });

    test('disposing closes a parked bridge too', () async {
      final first = AnsweringLink();
      late MuxBridge b1;
      var calls = 0;
      final s = selector(
        findOnLan: () async => null,
        connectPear: (onClosed) async => ++calls == 1 ? b1 = MuxBridge(first, onClosed: onClosed) : null,
      );
      await s.evaluate();
      await carry(b1);
      await first.drop();
      await pumpUntil(() => s.phase == TransportPhase.failed);
      expect(b1.isDetached, isTrue);
      await s.dispose();
      expect(b1.isClosed, isTrue);
    });
  });

  test('addressChanges reads this device\'s real addresses by default', () async {
    final sub = addressChanges(every: const Duration(milliseconds: 5)).listen((_) {});
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await sub.cancel().timeout(const Duration(seconds: 1), onTimeout: () => fail('cancel must not hang'));
  });
}

Future<void> pumpUntil(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) throw TimeoutException('condition not met');
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}
