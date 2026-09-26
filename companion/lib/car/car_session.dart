import 'dart:async';

import 'package:bladewatch_rpc/gen/bladewatch/v1/stream.pb.dart';
import 'package:bladewatch_rpc/rpc/connect_client.dart';
import 'package:bladewatch_rpc/rpc/connect_error.dart';
import 'package:bladewatch_rpc/rpc/jwt_source.dart';
import 'package:bladewatch_rpc/rpc/raw_http_sender.dart';
import 'package:bladewatch_rpc/rpc/rpc_transport.dart';
import 'package:bladewatch_rpc/rpc/services/stream_service_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_pear/flutter_pear.dart';

import '../transport/car_auth.dart';
import '../transport/lan_prober.dart';
import '../transport/local_gateway.dart';
import '../transport/pear_link.dart';
import '../transport/transport_selector.dart';
import 'car_store.dart';

/// The companion's live link to its paired car (BladeWatch-rdtj.11): the local gateway, the
/// route choice (LAN or Pear), the login, and one Connect client every screen shares.
///
/// Screens read [phase] to tell "still looking" from "can't reach the car" -- a DHT lookup can
/// take 30 s or more, and a phone that locked mid-handshake looks exactly like a broken link --
/// [refused] to tell "the car un-paired this device" from both, and [answering] to tell a car
/// whose daemon has stopped behind an intact route (BladeWatch-yzuc).
class CarSession extends ChangeNotifier {
  CarSession({
    required RpcTransport rpc,
    required this.baseUrl,
    required Future<String?> Function() jwt,
    Stream<TransportPhase> phases = const Stream.empty(),
    TransportPhase initialPhase = TransportPhase.discovering,
    VoidCallback? retry,
    Future<void> Function()? close,
    RpcTransport Function(Map<String, String> headers)? headerTransport,
    this.probeEvery = const Duration(seconds: 3),
  })  : _inner = rpc,
        _withHeaders = headerTransport,
        _mintJwt = jwt,
        _phase = initialPhase,
        _onRetry = retry,
        _onClose = close {
    _everConnected = connected;
    _phases = phases.listen((p) {
      _phase = p;
      _everConnected |= connected;
      if (!connected) _heard(true); // the route's own state says it now; stop probing
      notifyListeners();
    });
  }

  final RpcTransport _inner;

  /// Every RPC to the car goes through this. It watches the answers: see [answering].
  late final RpcTransport rpc = _Watched(_inner, _heard);

  /// How often a car that stopped answering is asked again.
  final Duration probeEvery;

  /// `http://127.0.0.1:<port>`, the gateway: media (stills, clips, thumbnails) is fetched here.
  final Uri baseUrl;

  final Future<String?> Function() _mintJwt;
  final RpcTransport Function(Map<String, String> headers)? _withHeaders;
  final VoidCallback? _onRetry;
  final Future<void> Function()? _onClose;
  late final StreamSubscription<TransportPhase> _phases;
  TransportPhase _phase;
  bool _refused = false;
  bool _everConnected = false;
  bool _answering = true;
  Timer? _probe;

  TransportPhase get phase => _phase;

  /// Reached the car at least once this session, so looking again reads as "reconnecting".
  bool get everConnected => _everConnected;

  bool get connected => _phase == TransportPhase.lan || _phase == TransportPhase.pear;

  /// False while the route is up but the car gives no answer at all -- its daemon stopped or is
  /// restarting. Over Pear the connection outlives that (pear_daemon is a separate process), so
  /// without this every screen kept showing its last data as if it were live. A cheap probe
  /// checks every [probeEvery] until the car answers again.
  bool get answering => _answering;

  void _heard(bool answered) {
    if (answered == _answering) return;
    _answering = answered;
    _probe?.cancel();
    if (!answered) {
      _probe = Timer.periodic(probeEvery, (_) {
        // Memory-only on the car, so asking often costs it nothing.
        unawaited(StreamServiceClient(rpc).getQuality(GetStreamQualityRequest()).then((_) {}, onError: (_) {}));
      });
    }
    notifyListeners();
  }

  /// The car answered, and refused this device's credential: it was removed in the car.
  bool get refused => _refused;

  void markRefused() {
    if (_refused) return;
    _refused = true;
    notifyListeners();
  }

  /// The same car and login, with [headers] on every call -- for a vehicle action's
  /// `X-Vehicle-Action-Token`. Reuses the session's JWT: a second login per command would trip
  /// the car's login limit.
  RpcTransport withHeaders(Map<String, String> headers) => _withHeaders?.call(headers) ?? rpc;

  /// Look for the car again now -- after the app resumes, or when the owner asks.
  void retry() => _onRetry?.call();

  /// The Authorization header for a plain HTTP fetch through the gateway (images, video).
  Future<Map<String, String>> authHeaders() async {
    final jwt = await _mintJwt();
    return {if (jwt != null) 'Authorization': 'Bearer $jwt'};
  }

  @override
  void dispose() {
    _probe?.cancel();
    unawaited(_phases.cancel());
    unawaited(_onClose?.call());
    super.dispose();
  }

  /// Opens the real link: gateway, selector and login for [car]. The two network edges are
  /// injectable for tests; by default the LAN is probed and Pear is started on first need.
  static Future<CarSession> open(
    PairedCar car, {
    Future<PearSwarm> Function(PearKey topic)? joinTopic,
    Future<LanEndpoint?> Function()? findOnLan,
    Stream<void>? networkChanges,
  }) async {
    final gateway = await LocalGateway.start();
    Pear? pear;
    PearSwarm? swarm;
    // Dial-only (BladeWatch-qryk): announcing left a DHT record per session that outlived it by
    // 20 minutes, and every later dialer tried it first. The car joins with acceptUnannounced, so
    // it uses this connection without ever finding an announcement (BladeWatch-lw0o).
    final join = joinTopic ?? (topic) async => (pear ??= await Pear.start()).join(topic, announce: false);
    final selector = TransportSelector(
      gateway: gateway,
      pinnedFingerprint: car.tlsFingerprint,
      findOnLan: findOnLan ??
          () async => LanProber(_hex(car.probeKey))
              .find(await LanProber.candidates(), pinnedFingerprint: car.tlsFingerprint),
      connectPear: (onClosed) async {
        try {
          // One join for the session's life: the swarm reconnects to the car by itself, and a
          // second join of the same topic would be a second swarm.
          final s = swarm ??= await join(PearKey.fromHex(car.pearTopic));
          return await findCarOverPear(pearLinks(s), car.tlsFingerprint, onClosed: onClosed);
        } catch (_) {
          return null; // Pear unavailable: the selector reports failed and retries.
        }
      },
      networkChanges: networkChanges ?? addressChanges(),
    );
    late final CarSession session;
    final auth = CarAuth(gateway.baseUrl);
    final login = CompanionLogin(auth, car.credential, () => session.markRefused());
    session = CarSession(
      rpc: ConnectClient(jwtSource: login, baseUrl: gateway.baseUrl),
      baseUrl: gateway.baseUrl,
      jwt: login.cached,
      phases: selector.phases,
      retry: () => unawaited(selector.evaluate()),
      headerTransport: (headers) => ConnectClient(
        jwtSource: _SharedJwt(login),
        baseUrl: gateway.baseUrl,
        send: withExtraHeaders(createIoHttpSender(), headers),
      ),
      close: () async {
        await selector.dispose();
        await gateway.close();
        await pear?.dispose();
      },
    );
    selector.start();
    return session;
  }

  static List<int> _hex(String s) =>
      [for (var i = 0; i + 1 < s.length; i += 2) int.parse(s.substring(i, i + 2), radix: 16)];
}

/// The companion login as a [JwtSource]. A `companion_refused` answer means the car no longer
/// knows this device: reported once, and never retried -- every RPC would otherwise re-try the
/// login and trip the car's lockout for everyone.
class CompanionLogin implements JwtSource {
  CompanionLogin(this._auth, this._credential, this._onRefused, {DateTime Function()? now}) : _now = now ?? DateTime.now;

  final CarAuth _auth;
  final CompanionCredential _credential;
  final VoidCallback _onRefused;
  final DateTime Function() _now;
  bool _refused = false;
  String? _jwt;
  DateTime? _at;

  @override
  Future<String?> mintJwt() async {
    if (_refused) return null;
    try {
      _jwt = await _auth.login(_credential);
      _at = _now();
      return _jwt;
    } on CarAuthRefused catch (e) {
      if (e.code == 'companion_refused') {
        _refused = true;
        _onRefused();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// The JWT for a media fetch: the last one while it is fresh (ConnectClient keeps it 4 min),
  /// else a new login.
  Future<String?> cached() async {
    final at = _at;
    if (_jwt != null && at != null && _now().difference(at) < const Duration(minutes: 4)) return _jwt;
    return mintJwt();
  }

  @override
  Future<int> stateVersion() async => 0;
}

/// [send] with [extra] on every request, on top of what the client sets (its Authorization
/// included).
RawHttpSender withExtraHeaders(RawHttpSender send, Map<String, String> extra) =>
    (uri, headers, body) => send(uri, {...headers, ...extra}, body);

/// The session login's current JWT, for a second client that must not log in again.
class _SharedJwt implements JwtSource {
  _SharedJwt(this._login);

  final CompanionLogin _login;

  @override
  Future<String?> mintJwt() => _login.cached();

  @override
  Future<int> stateVersion() async => 0;
}

/// Passes calls through, and reports whether the car answered: any response counts, only a call
/// that got no HTTP response at all (ConnectError httpStatus 0 -- refused, closed, timed out
/// through the gateway) does not.
class _Watched implements RpcTransport {
  _Watched(this._inner, this._heard);

  final RpcTransport _inner;
  final void Function(bool answered) _heard;

  @override
  Future<T> call<T>(String service, String method, Object? request, T Function(Object? json) decode) async {
    try {
      final result = await _inner.call(service, method, request, decode);
      _heard(true);
      return result;
    } on ConnectError catch (e) {
      _heard(e.httpStatus != 0);
      rethrow;
    }
  }
}
