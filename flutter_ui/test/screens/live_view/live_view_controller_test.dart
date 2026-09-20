import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bladewatch_ui/gen/bladewatch/v1/stream.pb.dart';
import 'package:bladewatch_ui/platform/live_view_texture_channel.dart';
import 'package:bladewatch_ui/rpc/jwt_source.dart';
import 'package:bladewatch_ui/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_ui/rpc/services/stream_service_client.dart';
import 'package:bladewatch_ui/rpc/services/system_service_client.dart';
import 'package:bladewatch_ui/screens/live_view/live_view_controller.dart';
import 'package:bladewatch_ui/screens/live_view/live_view_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_platform_channel.dart';
import '../../fakes/fake_rpc_client.dart';

class _FakeJwtSource implements JwtSource {
  String? next = 'fake.jwt.token';
  final calls = <int>[];

  @override
  Future<String?> mintJwt() async {
    calls.add(1);
    return next;
  }

  @override
  Future<int> stateVersion() async => 0;
}

class FakeLiveSocket implements LiveSocket {
  final _controller = StreamController<dynamic>();
  bool closed = false;

  @override
  Stream<dynamic> get messages => _controller.stream;

  @override
  Future<void> close() async {
    closed = true;
    await _controller.close();
  }

  void emit(dynamic data) => _controller.add(data);
  void emitError(Object error) => _controller.addError(error);
  Future<void> emitDone() => _controller.close();
}

Future<void> flush() => Future.delayed(Duration.zero);

void main() {
  late FakeRpcClient rpc;
  late FakePlatformChannel channel;
  late _FakeJwtSource jwt;

  setUp(() {
    rpc = FakeRpcClient();
    channel = FakePlatformChannel();
    jwt = _FakeJwtSource();
    channel.stub('liveView', 'createTexture', 7);
    channel.stub('liveView', 'configure', null);
    channel.stub('liveView', 'feedFrame', null);
    channel.stub('liveView', 'dispose', null);
  });

  LiveViewController build({
    List<FakeLiveSocket> Function()? sockets,
    LiveSocketConnector? connect,
    List<String>? connectedUrls,
    int maxConnectAttempts = 20,
  }) {
    final pool = sockets != null ? sockets() : <FakeLiveSocket>[];
    var index = 0;
    return LiveViewController(
      streamService: StreamServiceClient(rpc),
      systemService: SystemServiceClient(rpc),
      recordingsService: RecordingsServiceClient(rpc),
      jwtSource: jwt,
      textureChannel: LiveViewTextureChannel(channel),
      retryDelay: Duration.zero,
      maxConnectAttempts: maxConnectAttempts,
      connect: connect ??
          (connect == null && sockets != null
              ? (url) async {
                  connectedUrls?.add(url);
                  return pool[index++];
                }
              : (url) async => throw StateError('no connector configured')),
    );
  }

  void stubHappyRpcPath({String currentId = 'medium', int width = 1280, int height = 720}) {
    rpc.stubJson('StreamService', 'Enable', {'success': true});
    rpc.stubJson('StreamService', 'SetViewMode', {'success': true});
    rpc.stubJson('StreamService', 'GetQuality', {
      'success': true,
      'current': currentId,
      'options': [
        {'id': currentId, 'name': 'Medium', 'width': width, 'height': height},
      ],
    });
  }

  group('start(): connecting', () {
    test('creates the texture exactly once and transitions to connecting', () async {
      stubHappyRpcPath();
      final urls = <String>[];
      final socket = FakeLiveSocket();
      final c = build(sockets: () => [socket], connectedUrls: urls);

      final future = c.start();
      await flush();

      expect(c.textureId, 7);
      expect(rpc.calls.where((call) => call.method == 'Enable'), isNotEmpty);
      await future;
      expect(urls.single, startsWith('ws://127.0.0.1:8080/ws?token='));
      expect(c.state.status.phase, LiveStreamPhase.connecting);
    });

    test('createTexture failing is caught and published as unavailable, not thrown', () async {
      channel.stubError('liveView', 'createTexture', const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'no plugin'));
      final c = build();

      await c.start();

      expect(c.textureId, isNull);
      expect(c.state.status.phase, LiveStreamPhase.unavailable);
      expect(rpc.calls, isEmpty);
    });

    test('calling start() twice while already running is a no-op', () async {
      stubHappyRpcPath();
      final socket = FakeLiveSocket();
      final c = build(sockets: () => [socket]);
      await c.start();
      final callsBefore = channel.calls.length;

      await c.start();

      expect(channel.calls.length, callsBefore);
    });

    test('SetViewMode is sent with the current direction', () async {
      stubHappyRpcPath();
      final socket = FakeLiveSocket();
      final c = build(sockets: () => [socket]);

      await c.start();

      final req = rpc.calls.firstWhere((call) => call.method == 'SetViewMode').request as SetViewModeRequest;
      expect(req.viewMode, LiveViewDirection.front.viewMode);
    });

    test('GetQuality dimensions are passed to configure()', () async {
      stubHappyRpcPath(currentId: 'high', width: 1920, height: 1080);
      final socket = FakeLiveSocket();
      final c = build(sockets: () => [socket]);

      await c.start();

      final call = channel.calls.firstWhere((c) => c.method == 'configure');
      final args = call.args as Map;
      expect(args['width'], 1920);
      expect(args['height'], 1080);
    });

    test('GetQuality with no matching option falls back to 640x480', () async {
      rpc.stubJson('StreamService', 'Enable', {'success': true});
      rpc.stubJson('StreamService', 'SetViewMode', {'success': true});
      rpc.stubJson('StreamService', 'GetQuality', {'success': true, 'current': 'missing', 'options': []});
      final socket = FakeLiveSocket();
      final c = build(sockets: () => [socket]);

      await c.start();

      final call = channel.calls.firstWhere((c) => c.method == 'configure');
      final args = call.args as Map;
      expect(args['width'], 640);
      expect(args['height'], 480);
    });

    test('GetQuality throwing falls back to 640x480', () async {
      rpc.stubJson('StreamService', 'Enable', {'success': true});
      rpc.stubJson('StreamService', 'SetViewMode', {'success': true});
      rpc.stubError('StreamService', 'GetQuality', const ConnectError('unavailable', 'down'));
      final socket = FakeLiveSocket();
      final c = build(sockets: () => [socket]);

      await c.start();

      final call = channel.calls.firstWhere((c) => c.method == 'configure');
      final args = call.args as Map;
      expect(args['width'], 640);
      expect(args['height'], 480);
    });

    test('a null JWT is treated as a retryable connect failure', () async {
      stubHappyRpcPath();
      jwt.next = null;
      final socket = FakeLiveSocket();
      final c = build(sockets: () => [socket], maxConnectAttempts: 2);

      await c.start();

      expect(c.state.status.phase, LiveStreamPhase.unavailable);
      expect(jwt.calls.length, 2);
    });
  });

  group('retry budget', () {
    test('retries on connect failure up to the budget then goes unavailable', () async {
      stubHappyRpcPath();
      var attempts = 0;
      final c = LiveViewController(
        streamService: StreamServiceClient(rpc),
        systemService: SystemServiceClient(rpc),
        recordingsService: RecordingsServiceClient(rpc),
        jwtSource: jwt,
        textureChannel: LiveViewTextureChannel(channel),
        retryDelay: Duration.zero,
        maxConnectAttempts: 3,
        connect: (url) async {
          attempts++;
          throw const SocketException('refused');
        },
      );

      await c.start();

      expect(attempts, 3);
      expect(c.state.status.phase, LiveStreamPhase.unavailable);
      // The reason names the stage that failed. Every failure used to collapse
      // to one generic string, so a missing plugin, a rejected JWT, a failing
      // StreamService RPC and a refused socket were indistinguishable — on
      // device that left "Camera unavailable" with nothing to go on.
      expect(c.state.status.reason, startsWith('Camera starting — tap retry'));
      expect(c.state.status.reason, contains('websocket connect'));
    });

    test('the failure reason never contains the JWT', () async {
      // The connect URL carries ?token=<jwt>, and a socket error normally
      // embeds the URI it failed on. The reason must therefore never be built
      // from the exception text — it would put a live token on the screen and
      // into logs. CLAUDE.md: never log or copy secret values.
      stubHappyRpcPath();
      const secret = 'SUPER-SECRET-JWT-VALUE';
      jwt.next = secret;
      final c = LiveViewController(
        streamService: StreamServiceClient(rpc),
        systemService: SystemServiceClient(rpc),
        recordingsService: RecordingsServiceClient(rpc),
        jwtSource: jwt,
        textureChannel: LiveViewTextureChannel(channel),
        retryDelay: Duration.zero,
        maxConnectAttempts: 2,
        // The real dart:io WebSocket error embeds the URI; reproduce that shape.
        connect: (url) async => throw SocketException('refused on $url'),
      );

      await c.start();

      expect(c.state.status.phase, LiveStreamPhase.unavailable);
      expect(c.state.status.reason, isNot(contains(secret)));
      expect(c.state.status.reason, isNot(contains('token=')));
    });

    test('succeeds after some failed attempts', () async {
      stubHappyRpcPath();
      var attempts = 0;
      final socket = FakeLiveSocket();
      final c = LiveViewController(
        streamService: StreamServiceClient(rpc),
        systemService: SystemServiceClient(rpc),
        recordingsService: RecordingsServiceClient(rpc),
        jwtSource: jwt,
        textureChannel: LiveViewTextureChannel(channel),
        retryDelay: Duration.zero,
        maxConnectAttempts: 5,
        connect: (url) async {
          attempts++;
          if (attempts < 3) throw const SocketException('refused');
          return socket;
        },
      );

      await c.start();

      expect(attempts, 3);
      expect(c.state.status.phase, LiveStreamPhase.connecting);
    });
  });

  group('streaming frames', () {
    test('the first message is fed as codec config and does not flip to live', () async {
      stubHappyRpcPath();
      final socket = FakeLiveSocket();
      final c = build(sockets: () => [socket]);
      await c.start();

      socket.emit(Uint8List.fromList([1, 2, 3]));
      await flush();

      final feed = channel.calls.firstWhere((c) => c.method == 'feedFrame');
      final args = feed.args as Map;
      expect(args['isCodecConfig'], isTrue);
      expect(args['textureId'], 7);
      expect(c.state.status.phase, LiveStreamPhase.connecting);
    });

    test('the second message is fed as a real frame and flips to live', () async {
      stubHappyRpcPath();
      final socket = FakeLiveSocket();
      final c = build(sockets: () => [socket]);
      await c.start();
      socket.emit(Uint8List.fromList([1]));
      await flush();

      socket.emit(Uint8List.fromList([2]));
      await flush();

      final feeds = channel.calls.where((c) => c.method == 'feedFrame').toList();
      expect((feeds.last.args as Map)['isCodecConfig'], isFalse);
      expect(c.state.status.phase, LiveStreamPhase.live);
    });

    test('a non-Uint8List List<int> message is converted before feeding', () async {
      stubHappyRpcPath();
      final socket = FakeLiveSocket();
      final c = build(sockets: () => [socket]);
      await c.start();

      socket.emit(<int>[9, 9]);
      await flush();

      final feed = channel.calls.firstWhere((c) => c.method == 'feedFrame');
      expect((feed.args as Map)['bytes'], isA<Uint8List>());
    });
  });

  group('mid-stream disconnection', () {
    test('a socket error moves to the error phase', () async {
      stubHappyRpcPath();
      final socket = FakeLiveSocket();
      final c = build(sockets: () => [socket]);
      await c.start();

      socket.emitError(const SocketException('reset'));
      await flush();

      expect(c.state.status.phase, LiveStreamPhase.error);
      expect(c.state.status.reason, contains('Stream error'));
    });

    test('the server closing the socket moves to the error phase with a disconnected reason', () async {
      stubHappyRpcPath();
      final socket = FakeLiveSocket();
      final c = build(sockets: () => [socket]);
      await c.start();

      await socket.emitDone();
      await flush();

      expect(c.state.status.phase, LiveStreamPhase.error);
      expect(c.state.status.reason, 'Stream disconnected');
    });
  });

  group('selectDirection', () {
    test('is a no-op when unchanged', () async {
      final c = build();
      await c.selectDirection(LiveViewDirection.front);
      expect(rpc.calls, isEmpty);
    });

    test('updates state and calls SetViewMode', () async {
      rpc.stubJson('StreamService', 'SetViewMode', {'success': true});
      final c = build();

      await c.selectDirection(LiveViewDirection.rear);

      expect(c.state.direction, LiveViewDirection.rear);
      final req = rpc.calls.single.request as SetViewModeRequest;
      expect(req.viewMode, LiveViewDirection.rear.viewMode);
    });

    test('a throwing SetViewMode is swallowed', () async {
      rpc.stubError('StreamService', 'SetViewMode', const ConnectError('unavailable', 'down'));
      final c = build();

      await c.selectDirection(LiveViewDirection.left);

      expect(c.state.direction, LiveViewDirection.left);
    });
  });

  group('stop/retry', () {
    test('stop cancels the subscription, closes the socket, disposes the texture, and goes idle', () async {
      stubHappyRpcPath();
      final socket = FakeLiveSocket();
      final c = build(sockets: () => [socket]);
      await c.start();

      await c.stop();

      expect(socket.closed, isTrue);
      expect(c.textureId, isNull);
      expect(channel.calls.any((call) => call.method == 'dispose'), isTrue);
      expect(c.state.status.phase, LiveStreamPhase.idle);
    });

    test('stop before start is safe (no texture to dispose)', () async {
      final c = build();
      await c.stop();
      expect(channel.calls.where((c) => c.method == 'dispose'), isEmpty);
    });

    test('retry stops then starts again, creating a fresh texture', () async {
      stubHappyRpcPath();
      final socketA = FakeLiveSocket();
      final socketB = FakeLiveSocket();
      channel.stub('liveView', 'createTexture', 7);
      var createCount = 0;
      final originalStub = channel;
      // Re-stub createTexture to return increasing ids across calls.
      final c = LiveViewController(
        streamService: StreamServiceClient(rpc),
        systemService: SystemServiceClient(rpc),
        recordingsService: RecordingsServiceClient(rpc),
        jwtSource: jwt,
        textureChannel: LiveViewTextureChannel(originalStub),
        retryDelay: Duration.zero,
        connect: (url) async => createCount++ == 0 ? socketA : socketB,
      );
      await c.start();
      final firstId = c.textureId;

      await c.retry();

      expect(c.textureId, firstId); // fake channel always returns the same stubbed id
      expect(socketA.closed, isTrue);
      expect(channel.calls.where((call) => call.method == 'createTexture').length, 2);
    });
  });

  group('recording status', () {
    test('start() refreshes isRecording from GetStatus', () async {
      stubHappyRpcPath();
      rpc.stubJson('SystemService', 'GetStatus', {'recording': [0]});
      final c = build(sockets: () => [FakeLiveSocket()]);

      await c.start();
      await flush();

      expect(c.state.isRecording, isTrue);
    });

    test('GetStatus reporting nothing recording leaves isRecording false', () async {
      stubHappyRpcPath();
      rpc.stubJson('SystemService', 'GetStatus', {'recording': []});
      final c = build(sockets: () => [FakeLiveSocket()]);

      await c.start();
      await flush();

      expect(c.state.isRecording, isFalse);
    });

    test('GetStatus throwing leaves isRecording false rather than propagating', () async {
      stubHappyRpcPath();
      rpc.stubError('SystemService', 'GetStatus', const ConnectError('unavailable', 'down'));
      final c = build(sockets: () => [FakeLiveSocket()]);

      await c.start();
      await flush();

      expect(c.state.isRecording, isFalse);
    });
  });

  group('markRecording', () {
    Future<LiveViewController> buildRecording() async {
      stubHappyRpcPath();
      rpc.stubJson('SystemService', 'GetStatus', {'recording': [0]});
      final c = build(sockets: () => [FakeLiveSocket()]);
      await c.start();
      await flush();
      return c;
    }

    test('not recording: markRecording is a no-op and sends no RPC', () async {
      stubHappyRpcPath();
      rpc.stubJson('SystemService', 'GetStatus', {'recording': []});
      final c = build(sockets: () => [FakeLiveSocket()]);
      await c.start();
      await flush();

      await c.markRecording();

      expect(rpc.calls.where((call) => call.method == 'MarkRecording'), isEmpty);
    });

    test('recording: markRecording sends MarkRecording and reports success', () async {
      final c = await buildRecording();
      rpc.stubJson('RecordingsService', 'MarkRecording', {
        'success': true,
        'filename': 'clip1.mp4',
        'markTimestampMs': '1000',
      });

      await c.markRecording();

      expect(rpc.calls.where((call) => call.method == 'MarkRecording').length, 1);
      expect(c.state.markStatus, MarkStatus.idle);
      expect(c.state.markMessage, isNotNull);
    });

    test('a double tap inside one in-flight call sends exactly one RPC', () async {
      final c = await buildRecording();
      rpc.stubJson('RecordingsService', 'MarkRecording', {'success': true, 'filename': 'clip1.mp4', 'markTimestampMs': '1000'});
      // Fire both taps before either has a chance to complete -- the guard under
      // test is markStatus == marking, not a timer, so no delay is needed here.
      final first = c.markRecording();
      final second = c.markRecording();

      await first;
      await second;

      expect(rpc.calls.where((call) => call.method == 'MarkRecording').length, 1);
    });

    test('a failed RPC surfaces a message and returns markStatus to idle (no permanent spinner)', () async {
      final c = await buildRecording();
      rpc.stubError('RecordingsService', 'MarkRecording', const ConnectError('unavailable', 'daemon down'));

      await c.markRecording();

      expect(c.state.markStatus, MarkStatus.idle);
      expect(c.state.markMessage, isNotNull);
    });

    test('server-reported failure (nothing recording server-side) surfaces the reason', () async {
      final c = await buildRecording();
      rpc.stubJson('RecordingsService', 'MarkRecording', {'success': false, 'reason': 'not_recording'});

      await c.markRecording();

      expect(c.state.markStatus, MarkStatus.idle);
      expect(c.state.markMessage, 'not_recording');
    });
  });
}
