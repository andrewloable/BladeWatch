import 'dart:async';
import 'dart:io';

import 'package:bladewatch_rpc/gen/bladewatch/v1/stream.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/system.pb.dart';
import 'package:bladewatch_rpc/rpc/connect_client.dart';
import 'package:bladewatch_rpc/rpc/connect_error.dart';
import 'package:bladewatch_rpc/rpc/jwt_source.dart';
import 'package:bladewatch_rpc/rpc/raw_http_sender.dart';
import 'package:bladewatch_rpc/rpc/rpc_transport.dart';
import 'package:bladewatch_rpc/rpc/services/stream_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
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
    this.quietAfter,
    this.probeTimeout = const Duration(seconds: 2),
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
      if (connected) unawaited(_learnLan());
      notifyListeners();
    });
    if (quietAfter != null) _watch();
  }

  final RpcTransport _inner;

  /// Every RPC to the car goes through this. It watches the answers: see [answering].
  late final RpcTransport rpc = _Watched(_inner, _heard);

  /// How often a car that stopped answering is asked again.
  final Duration probeEvery;

  /// A car that has said nothing for this long is asked something cheap (BladeWatch-rdtj.53);
  /// null turns the watch off, as most tests want.
  ///
  /// Why: over Pear a dead car is silence, not an error. Its connection is dropped only once
  /// Hyperswarm times it out, and an RPC meanwhile waits out the HTTP client's 10 s read timeout;
  /// with the screens polling every 5 s, a stopped pear_daemon went unnoticed for 14-18 s while
  /// the last data sat on screen as if live. Now: quiet for [quietAfter], then two [probeTimeout]
  /// questions in a row without an answer -- about 6 s -- and the car shows as not answering.
  /// Two, so that one slow answer on a busy mobile link does not flip the page.
  ///
  /// ponytail: fixed 2 s + 2 x 2 s; tune here if a real link proves slower or faster.
  final Duration? quietAfter;
  final Duration probeTimeout;
  Timer? _watchTimer;
  int _quietTicks = 0;
  bool _asking = false;

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
    if (answered) _quietTicks = 0;
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

  // Counted in timer ticks, not wall-clock time, so a test's fake clock drives it too.
  void _watch() {
    _watchTimer?.cancel();
    _quietTicks = 0;
    _watchTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _quietTicks++;
      if (_quietTicks * 500 >= quietAfter!.inMilliseconds) unawaited(_askQuietCar());
    });
  }

  Future<void> _askQuietCar() async {
    // Not while the route is down (the selector says so) or the car is already known silent
    // (the [probeEvery] probe asks then).
    if (_asking || !connected || !_answering) return;
    _asking = true;
    try {
      for (var miss = 0; miss < 2; miss++) {
        if (await _ask()) {
          _heard(true);
          return;
        }
      }
      if (connected) _heard(false);
    } finally {
      _asking = false;
    }
  }

  /// Any HTTP answer counts, an error status included: the car is there. Asked of the inner
  /// transport, so one miss is not yet reported as silence.
  Future<bool> _ask() async {
    try {
      await StreamServiceClient(_inner).getQuality(GetStreamQualityRequest()).timeout(probeTimeout);
      return true;
    } on ConnectError catch (e) {
      return e.httpStatus != 0;
    } catch (_) {
      return false;
    }
  }

  /// The app went to the background: no questions while nobody is looking.
  void paused() {
    _watchTimer?.cancel();
    _watchTimer = null;
  }

  /// The car's own Wi-Fi address, read once each time the route comes up (BladeWatch-rdtj.38).
  /// The app keeps it as [PairedCar.lanHint] for the next search. Null while the car is on
  /// cellular: that address is private too (carrier NAT), and no LAN reaches it.
  String? get carLanAddress => _carLan;
  String? _carLan;

  Future<void> _learnLan() async {
    try {
      final network = (await SystemServiceClient(rpc).getStatus(GetStatusRequest())).network;
      final ip = network.type == 'wifi' ? network.ip : '';
      if (ip.isEmpty || ip == _carLan) return;
      _carLan = ip;
      notifyListeners();
    } catch (_) {
      // Learned on the next connection instead.
    }
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

  /// Look for the car again now -- when the owner asks, or when [resumed] finds the link down.
  void retry() => _onRetry?.call();

  /// The app is back in the foreground (BladeWatch-rdtj.36). A route that is down is looked for
  /// again at once, rather than on the selector's retry timer. A route that is up is asked one
  /// cheap question first, and torn down only if the car cannot be reached through it: after a
  /// phone sleeps, its Pear connection can be dead with nothing having said so yet.
  ///
  /// This used to call [retry] every time, which restarted a HEALTHY link on every app switch
  /// (a macOS window regaining focus is a resume too): 3 to 15 s of "Reconnecting" each time,
  /// and a desktop window refocused often enough never showed the car at all.
  Future<void> resumed({Duration timeout = const Duration(seconds: 8)}) async {
    if (quietAfter != null) _watch();
    if (!connected) return retry();
    try {
      await StreamServiceClient(rpc).getQuality(GetStreamQualityRequest()).timeout(timeout);
    } on ConnectError catch (e) {
      // Any HTTP status is the car answering, so the link is up; 0 is no answer at all.
      if (e.httpStatus == 0 && connected) retry();
    } catch (_) {
      if (connected) retry(); // timed out: nothing came back through this link
    }
  }

  /// The Authorization header for a plain HTTP fetch through the gateway (images, video).
  Future<Map<String, String>> authHeaders() async {
    final jwt = await _mintJwt();
    return {if (jwt != null) 'Authorization': 'Bearer $jwt'};
  }

  @override
  void dispose() {
    _probe?.cancel();
    _watchTimer?.cancel();
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
          () => LanProber(_hex(car.probeKey)).findCar(
                car.lanHint == null ? null : InternetAddress.tryParse(car.lanHint!),
                LanProber.candidates,
                pinnedFingerprint: car.tlsFingerprint,
              ),
      connectPear: (onClosed) async {
        try {
          // A fresh join every time the car is looked for (BladeWatch-rdtj.24). The selector only
          // asks with no live link -- at start, after a drop, on a retry, after a network change --
          // and an old dial-only swarm does not find the car again on its own: after a car-side
          // pear_daemon restart it redialed for minutes and never connected, while a new join
          // found the car in about 2 s. A new swarm also gets the replay of connections that
          // already exist, which PearSwarm.connections gives its FIRST listener only. The old one
          // is left first, so there is never a second swarm on the topic.
          final previous = swarm;
          swarm = null;
          if (previous != null) await previous.leave().catchError((Object _) {});
          final s = swarm = await join(PearKey.fromHex(car.pearTopic));
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
      quietAfter: const Duration(seconds: 2),
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
