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
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await sub.cancel().timeout(const Duration(seconds: 1));
    expect(events, hasLength(1));
    expect(errors, isEmpty);
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
