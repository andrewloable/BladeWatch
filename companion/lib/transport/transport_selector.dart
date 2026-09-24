import 'dart:async';
import 'dart:io';

import 'lan_prober.dart';
import 'local_gateway.dart';
import 'mux_bridge.dart';

/// How the companion is reaching the car. `discovering` and `failed` are deliberately distinct:
/// a DHT lookup can take 30 s or more, and a phone whose screen locked mid-handshake looks
/// broken -- the UI must be able to say "still looking" instead of "can't reach the car".
enum TransportPhase { discovering, lan, pear, failed }

/// Picks the path to the car (BladeWatch-rdtj.8): the LAN when the car answers a probe -- lower
/// latency, full bandwidth, no DHT, and the only thing that works when phone and car share a NAT --
/// otherwise Pear. Re-evaluates when the phone's addresses change (it joined or left a Wi-Fi) and
/// when the Pear connection drops, and retries on its own after a failure.
class TransportSelector {
  TransportSelector({
    required this.gateway,
    required this.pinnedFingerprint,
    required this.findOnLan,
    required this.connectPear,
    this.networkChanges,
    this.retryAfter = const Duration(seconds: 30),
  });

  final LocalGateway gateway;

  /// The car's TLS certificate pin, from pairing. Both routes end in TLS checked against it.
  final String pinnedFingerprint;
  final Future<LanEndpoint?> Function() findOnLan;

  /// Joins the car's topic and returns a bridge to the peer that proved to be the car (see
  /// `findCarOverPear`), or null. [onClosed] fires if that connection later drops.
  final Future<MuxBridge?> Function(void Function() onClosed) connectPear;
  final Stream<void>? networkChanges;
  final Duration retryAfter;

  final _phases = StreamController<TransportPhase>.broadcast();
  TransportPhase _phase = TransportPhase.discovering;
  StreamSubscription<void>? _changes;
  Timer? _retry;
  int _generation = 0;
  bool _disposed = false;

  TransportPhase get phase => _phase;

  Stream<TransportPhase> get phases => _phases.stream;

  void start() {
    _changes = networkChanges?.listen((_) => evaluate());
    unawaited(evaluate());
  }

  /// One full selection. A newer call supersedes an older one still in flight.
  Future<void> evaluate() async {
    if (_disposed) return;
    final generation = ++_generation;
    _retry?.cancel();
    _set(TransportPhase.discovering);

    // A step that throws found nothing: the selection must always end in lan, pear or failed --
    // failed is what schedules the retry (BladeWatch-gfmk).
    LanEndpoint? lan;
    try {
      lan = await findOnLan();
    } catch (_) {
      lan = null;
    }
    if (generation != _generation) return;
    if (lan != null) {
      _route(LanRoute(lan));
      _set(TransportPhase.lan);
      return;
    }

    MuxBridge? bridge;
    try {
      bridge = await connectPear(() {
        if (generation == _generation) unawaited(evaluate());
      });
    } catch (_) {
      bridge = null;
    }
    if (generation != _generation) {
      bridge?.shutdown(); // superseded while connecting
      return;
    }
    if (bridge != null) {
      _route(PearRoute(bridge, pinnedFingerprint));
      _set(TransportPhase.pear);
      return;
    }

    _route(null);
    _set(TransportPhase.failed);
    _retry = Timer(retryAfter, () => unawaited(evaluate()));
  }

  void _route(GatewayRoute? next) {
    final previous = gateway.route;
    gateway.route = next;
    if (previous is PearRoute && !identical(previous, next)) previous.bridge.shutdown();
  }

  void _set(TransportPhase phase) {
    _phase = phase;
    if (!_phases.isClosed) _phases.add(phase);
  }

  Future<void> dispose() async {
    _disposed = true;
    _generation++;
    _retry?.cancel();
    await _changes?.cancel();
    _route(null);
    await _phases.close();
  }
}

/// Emits whenever this device's set of IPv4 addresses changes -- it joined or left a Wi-Fi.
/// Polled: no plugin, and five seconds is fast enough to notice leaving the car's Wi-Fi.
///
/// Not an async* loop: that only notices a cancel at its next yield, and with stable addresses it
/// never yields -- cancel() would never complete and the poll would outlive its listener.
Stream<void> addressChanges({
  Duration every = const Duration(seconds: 5),
  Future<List<InternetAddress>> Function()? ownAddresses,
}) =>
    Stream<void>.periodic(every)
        .asyncMap((_) => (ownAddresses ?? _ownIPv4)())
        .handleError((Object _) {}) // a failed poll is skipped, not a reason to re-route
        .map((list) => (list.map((a) => a.address).toList()..sort()).join(','))
        .distinct()
        .skip(1) // the first poll is the baseline, not a change
        .map((_) {});

Future<List<InternetAddress>> _ownIPv4() async =>
    [for (final iface in await NetworkInterface.list(type: InternetAddressType.IPv4)) ...iface.addresses];
