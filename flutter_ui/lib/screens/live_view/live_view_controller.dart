import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../gen/bladewatch/v1/recordings.pb.dart';
import '../../gen/bladewatch/v1/stream.pb.dart';
import '../../gen/bladewatch/v1/system.pb.dart';
import '../../platform/live_view_texture_channel.dart';
import '../../rpc/jwt_source.dart';
import '../../rpc/services/recordings_service_client.dart';
import '../../rpc/services/stream_service_client.dart';
import '../../rpc/services/system_service_client.dart';
import 'live_view_models.dart';

/// Narrow abstraction over `dart:io`'s `WebSocket` — the plugin's only test
/// seam for networking. `WebSocket` delivers each logical message as one
/// stream event, fragmentation already reassembled per RFC 6455 (confirmed
/// by the same protocol already working against a standard browser
/// WebSocket client for the Angular SPA's own live view — see
/// `LiveViewController`'s doc comment), so [messages] needs no framing
/// logic of its own. [IoLiveSocket]/[connectIoLiveSocket] are covered by a
/// real-server integration test (`io_live_socket_test.dart`), the same
/// approach `raw_http_sender_test.dart` uses for its own thin real-I/O
/// wrapper, rather than being mocked; [LiveViewController]'s own logic is
/// tested separately against a fake of this interface.
abstract class LiveSocket {
  Stream<dynamic> get messages;
  Future<void> close();
}

class IoLiveSocket implements LiveSocket {
  final WebSocket _socket;
  const IoLiveSocket(this._socket);

  @override
  Stream<dynamic> get messages => _socket;

  @override
  Future<void> close() => _socket.close();
}

typedef LiveSocketConnector = Future<LiveSocket> Function(String url);

Future<LiveSocket> connectIoLiveSocket(String url) async => IoLiveSocket(await WebSocket.connect(url));

/// Ground truth: `LiveViewController.kt` + `LiveStreamClient.kt`. Unlike
/// every other screen this session, this one keeps the real per-frame
/// decode pipeline in Kotlin (`LiveViewTexturePlugin`/`MediaCodecFrameDecoder`
/// — Dart has no hardware H.264 decode, and a software decoder cannot hold
/// frame rate on this head unit's GPU) — but everything upstream of the raw
/// decoded bytes moves to Dart, deliberately diverging from the task's own
/// "just swap where the Surface comes from" framing:
///
/// - The 3 `StreamService` RPCs `LiveStreamClient.kt` actually calls
///   (Enable, SetViewMode, GetQuality — of `StreamService`'s 7; Disable/
///   GetStatus/SetQuality/GetViewMode are never called by this screen
///   either, native or here) go through the generated `StreamServiceClient`
///   Dart client, per this project's own "call the SAME RPCs via the
///   generated Dart client" rule — `ConnectClientProvider`/`AuthManager`,
///   which `LiveStreamClient.kt` uses for these, are the MAIN app's own
///   singletons and are not reachable from this separate Flutter APK at
///   all, so *some* deviation from "just swap the Surface" was unavoidable
///   regardless of preference.
/// - The WebSocket connection itself (handshake, frame parsing, fragment
///   reassembly) is **not** ported into Kotlin either, even though it
///   technically could be with enough new native networking code: `dart:io`'s
///   own `WebSocket` is RFC 6455 compliant and already proven against this
///   exact server by the Angular SPA's standard browser WebSocket client
///   (see `web/src/app/pages/live/` and `SotaPlayer.js`) — using it keeps
///   the new native surface to exactly the one thing Dart genuinely cannot
///   do (MediaCodec), which is also the smallest surface this task's own
///   "a leaked MediaCodec is unrecoverable" warning could apply to.
///
/// See docs/build-and-operations.md for the full evidence trail.
class LiveViewController extends ChangeNotifier {
  LiveViewController({
    required StreamServiceClient streamService,
    required SystemServiceClient systemService,
    required RecordingsServiceClient recordingsService,
    required JwtSource jwtSource,
    required LiveViewTextureChannel textureChannel,
    LiveSocketConnector connect = connectIoLiveSocket,
    Duration retryDelay = const Duration(seconds: 2),
    int maxConnectAttempts = 20,
  })  : _streamService = streamService, // ignore: prefer_initializing_formals
        _systemService = systemService, // ignore: prefer_initializing_formals
        _recordingsService = recordingsService, // ignore: prefer_initializing_formals
        _jwtSource = jwtSource, // ignore: prefer_initializing_formals
        _textureChannel = textureChannel, // ignore: prefer_initializing_formals
        _connect = connect, // ignore: prefer_initializing_formals
        _retryDelay = retryDelay, // ignore: prefer_initializing_formals
        _maxConnectAttempts = maxConnectAttempts; // ignore: prefer_initializing_formals

  final StreamServiceClient _streamService;
  final SystemServiceClient _systemService;
  final RecordingsServiceClient _recordingsService;
  final JwtSource _jwtSource;
  final LiveViewTextureChannel _textureChannel;
  final LiveSocketConnector _connect;
  final Duration _retryDelay;
  final int _maxConnectAttempts;

  static const _wsUrl = 'ws://127.0.0.1:8080/ws';

  LiveViewState _state = const LiveViewState();
  LiveViewState get state => _state;

  int? _textureId;
  int? get textureId => _textureId;

  bool _running = false;
  bool _codecConfigSent = false;
  bool _disposed = false;
  int _generation = 0;
  StreamSubscription<dynamic>? _subscription;
  LiveSocket? _socket;

  /// Creates the texture (once) and starts the connect-and-stream flow. A
  /// no-op if already running — mirrors native's `running.compareAndSet`
  /// guard in `LiveStreamClient.connect()`.
  ///
  /// Unlike the RPC/socket steps inside [_connectAndStream] (each already
  /// its own try/catch, folded into the connect-retry loop), texture
  /// creation is a one-shot platform channel call with nothing to retry it
  /// against — a failure here (e.g. the native plugin not registered yet)
  /// is caught directly and surfaced the same way an exhausted connect
  /// budget is, rather than propagating as an unhandled Future error out of
  /// this fire-and-forget call (`LiveViewScreen.initState` does not await
  /// or catch it, matching every other screen controller's `start()`).
  Future<void> start() async {
    if (_running) return;
    _running = true;
    final myGen = ++_generation;
    if (_textureId == null) {
      try {
        _textureId = await _textureChannel.createTexture();
      } catch (e) {
        if (_generation != myGen) return;
        _running = false;
        // Safe to include the error here, unlike the connect path below: this
        // is a platform-channel call carrying only a texture id, with no JWT
        // and no URL in it.
        _publish(LiveStreamStatus.unavailable('Camera starting — tap retry (create texture failed: $e)'));
        return;
      }
    }
    unawaited(_refreshRecordingStatus());
    await _connectAndStream(myGen);
  }

  /// One-shot check, mirroring `DashboardController`'s own `GetStatus`-derived
  /// `isRecording` (`status.recording.isNotEmpty`) -- this screen does not poll, so a
  /// recording that starts/stops while the screen is already open is picked up the
  /// next time it is opened, not live. Left at the default (not recording) on
  /// failure: the safe failure mode is a hidden/disabled mark button, not one that
  /// claims to work and then fails.
  Future<void> _refreshRecordingStatus() async {
    try {
      final status = await _systemService.getStatus(GetStatusRequest());
      if (_disposed) return;
      _state = _state.copyWith(isRecording: status.recording.isNotEmpty);
      notifyListeners();
    } catch (_) {
      // Leave isRecording at its default.
    }
  }

  /// Bookmarks the recording currently being written. The in-flight guard below is
  /// what actually makes a double-tap send exactly one RPC -- the screen additionally
  /// hides the button while [MarkStatus.marking], but the controller does not rely on
  /// that for correctness.
  Future<void> markRecording() async {
    if (!_state.isRecording || _state.markStatus == MarkStatus.marking) return;
    _state = _state.copyWith(markStatus: MarkStatus.marking, clearMarkMessage: true);
    notifyListeners();
    String message;
    try {
      final resp = await _recordingsService.markRecording(MarkRecordingRequest());
      message = resp.success ? 'Bookmarked' : (resp.reason.isNotEmpty ? resp.reason : 'Could not bookmark');
    } catch (_) {
      message = 'Could not bookmark';
    }
    if (_disposed) return;
    _state = _state.copyWith(markStatus: MarkStatus.idle, markMessage: message);
    notifyListeners();
  }

  Future<void> _connectAndStream(int myGen) async {
    _publish(const LiveStreamStatus.connecting());
    var attempt = 0;
    LiveSocket? socket;
    var width = 640;
    var height = 480;
    // Which step failed, so an exhausted budget says something more useful
    // than a blanket "Camera starting". Deliberately a STAGE NAME and not the
    // exception text: the connect URL carries `?token=<jwt>`, and a socket
    // error normally embeds the URI it failed on, so echoing the error would
    // put a live JWT on the screen and into logs.
    var stage = 'start';
    while (_running && _generation == myGen && socket == null) {
      attempt++;
      try {
        stage = 'enable stream';
        await _streamService.enable(EnableStreamRequest());
        stage = 'set view mode';
        await _streamService.setViewMode(SetViewModeRequest(viewMode: _state.direction.viewMode));
        stage = 'query dimensions';
        final dims = await _queryDimensions();
        width = dims.$1;
        height = dims.$2;
        stage = 'auth';
        final jwt = await _jwtSource.mintJwt();
        if (jwt == null || jwt.isEmpty) throw StateError('auth not ready');
        stage = 'websocket connect';
        socket = await _connect('$_wsUrl?token=${Uri.encodeComponent(jwt)}');
      } catch (_) {
        if (!_running || _generation != myGen) return;
        if (attempt >= _maxConnectAttempts) {
          _running = false;
          _publish(LiveStreamStatus.unavailable('Camera starting — tap retry (failed at: $stage)'));
          return;
        }
        _publish(const LiveStreamStatus.connecting());
        await Future.delayed(_retryDelay);
      }
    }
    if (socket == null || !_running || _generation != myGen) return;
    _socket = socket;
    _codecConfigSent = false;
    await _textureChannel.configure(textureId: _textureId!, width: width, height: height);
    _subscription = socket.messages.listen(
      (data) => _onMessage(data, myGen),
      onError: (Object error) => _onSocketEnded(myGen, 'Stream error: $error'),
      onDone: () => _onSocketEnded(myGen, 'Stream disconnected'),
      cancelOnError: true,
    );
  }

  Future<(int, int)> _queryDimensions() async {
    try {
      final resp = await _streamService.getQuality(GetStreamQualityRequest());
      for (final option in resp.options) {
        if (option.id == resp.current) return (option.width, option.height);
      }
    } catch (_) {}
    return (640, 480);
  }

  void _onMessage(dynamic data, int myGen) {
    if (_generation != myGen) return;
    final bytes = data is Uint8List ? data : Uint8List.fromList(data as List<int>);
    final isCodecConfig = !_codecConfigSent;
    _codecConfigSent = true;
    _textureChannel.feedFrame(textureId: _textureId!, bytes: bytes, isCodecConfig: isCodecConfig);
    if (!isCodecConfig) _publish(const LiveStreamStatus.live());
  }

  /// A mid-stream drop (the socket errors or the server closes it) — native
  /// leaves the screen in whatever state it last was, with no further
  /// feedback and no automatic retry (`readWsFrame` failures just `break`
  /// the read loop with no `publish()` call at all — confirmed by reading
  /// `LiveStreamClient.kt`'s frame loop directly). This port deliberately
  /// improves on that: an unexplained frozen frame with no error and no way
  /// to recover short of leaving and re-entering the screen is worse than
  /// showing the same Error state + retry affordance native already uses
  /// for a failed initial connection. Not a functional behavior change to
  /// anything the daemon does — purely how this screen reacts to a
  /// disconnection it cannot prevent either way.
  void _onSocketEnded(int myGen, String reason) {
    if (_generation != myGen || !_running) return;
    _running = false;
    _publish(LiveStreamStatus.error(reason));
  }

  Future<void> selectDirection(LiveViewDirection direction) async {
    if (direction == _state.direction) return;
    _state = _state.copyWith(direction: direction);
    notifyListeners();
    try {
      await _streamService.setViewMode(SetViewModeRequest(viewMode: direction.viewMode));
    } catch (_) {
      // Fire-and-forget, matching native's selectDirection(): logged there,
      // silently ignored here -- the next full reconnect (retry/restart)
      // re-sends the current direction anyway.
    }
  }

  /// Stops streaming and releases the texture — call from the screen's
  /// `dispose()`. Flutter's shell fully tears down a route's widget on
  /// navigation (no Fragment-style pause-but-not-destroy state to
  /// preserve), so unlike native's separate `onPause()`/`onDestroy()` split
  /// this does both at once — matching every other screen controller this
  /// session's own `dispose()` convention.
  Future<void> stop() async {
    _generation++;
    _running = false;
    await _subscription?.cancel();
    _subscription = null;
    await _socket?.close();
    _socket = null;
    final id = _textureId;
    if (id != null) {
      _textureId = null;
      await _textureChannel.dispose(id);
    }
    _publish(const LiveStreamStatus.idle());
  }

  Future<void> retry() async {
    await stop();
    await start();
  }

  /// Guarded by [_disposed]: unlike [selectDirection]'s `notifyListeners()`
  /// (always the first, synchronous action in its function), every call
  /// here follows at least one `await` — e.g. [stop]'s fire-and-forget
  /// invocation from `LiveViewScreen.dispose()` can still be mid-chain when
  /// the surrounding app tears this whole object down via `dispose()`
  /// (`ChangeNotifier` throws on `notifyListeners()` after that point).
  void _publish(LiveStreamStatus status) {
    if (_disposed) return;
    _state = _state.copyWith(status: status);
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
