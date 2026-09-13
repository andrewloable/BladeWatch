import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bladewatch_ui/gen/bladewatch/v1/stream.pb.dart';
import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/platform/live_view_texture_channel.dart';
import 'package:bladewatch_ui/rpc/jwt_source.dart';
import 'package:bladewatch_ui/rpc/services/stream_service_client.dart';
import 'package:bladewatch_ui/screens/live_view/live_view_controller.dart';
import 'package:bladewatch_ui/screens/live_view/live_view_models.dart';
import 'package:bladewatch_ui/screens/live_view/live_view_screen.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_platform_channel.dart';
import '../../fakes/fake_rpc_client.dart';

class _FakeJwtSource implements JwtSource {
  String? next = 'fake.jwt.token';

  @override
  Future<String?> mintJwt() async => next;

  @override
  Future<int> stateVersion() async => 0;
}

class _FakeLiveSocket implements LiveSocket {
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

  void stubHappyRpcPath() {
    rpc.stubJson('StreamService', 'Enable', {'success': true});
    rpc.stubJson('StreamService', 'SetViewMode', {'success': true});
    rpc.stubJson('StreamService', 'GetQuality', {
      'success': true,
      'current': 'medium',
      'options': [
        {'id': 'medium', 'name': 'Medium', 'width': 1280, 'height': 720},
      ],
    });
  }

  LiveViewController buildController({LiveSocketConnector? connect, int maxConnectAttempts = 20}) {
    return LiveViewController(
      streamService: StreamServiceClient(rpc),
      jwtSource: jwt,
      textureChannel: LiveViewTextureChannel(channel),
      retryDelay: Duration.zero,
      maxConnectAttempts: maxConnectAttempts,
      connect: connect ?? (url) async => throw StateError('no connector configured'),
    );
  }

  Future<void> pump(WidgetTester tester, LiveViewController controller) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      theme: BladeWatchTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: LiveViewScreen(controller: controller)),
    ));
  }

  testWidgets('shows the connecting banner once a texture exists but no frame has arrived', (tester) async {
    stubHappyRpcPath();
    final socket = _FakeLiveSocket();
    final controller = buildController(connect: (url) async => socket);
    await pump(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('Connecting to camera…'), findsOneWidget);
    expect(controller.state.status.phase, LiveStreamPhase.connecting);
  });

  testWidgets('shows the texture and hides the banner once live', (tester) async {
    stubHappyRpcPath();
    final socket = _FakeLiveSocket();
    final controller = buildController(connect: (url) async => socket);
    await pump(tester, controller);
    await tester.pumpAndSettle();

    socket.emit(Uint8List.fromList([1]));
    await tester.pumpAndSettle();
    socket.emit(Uint8List.fromList([2]));
    await tester.pumpAndSettle();

    expect(controller.state.status.phase, LiveStreamPhase.live);
    expect(find.byKey(const ValueKey('liveView.banner')), findsNothing);
    expect(find.byType(Texture), findsOneWidget);
  });

  testWidgets('shows the unavailable banner with a retry button when the connect budget is exhausted', (tester) async {
    final controller = buildController(
      maxConnectAttempts: 1,
      connect: (url) async => throw const SocketException('refused'),
    );
    await pump(tester, controller);
    await tester.pumpAndSettle();

    expect(find.textContaining('Camera unavailable'), findsOneWidget);
    expect(find.byKey(const ValueKey('liveView.retry')), findsOneWidget);
  });

  testWidgets('shows the error banner with a retry button after a mid-stream disconnect', (tester) async {
    stubHappyRpcPath();
    final socket = _FakeLiveSocket();
    final controller = buildController(connect: (url) async => socket);
    await pump(tester, controller);
    await tester.pumpAndSettle();

    await socket.emitDone();
    await tester.pumpAndSettle();

    expect(find.textContaining('Error:'), findsOneWidget);
    expect(find.byKey(const ValueKey('liveView.retry')), findsOneWidget);
  });

  testWidgets('tapping retry re-attempts the connection', (tester) async {
    final controller = buildController(
      maxConnectAttempts: 1,
      connect: (url) async => throw const SocketException('refused'),
    );
    await pump(tester, controller);
    await tester.pumpAndSettle();
    final enableCallsBefore = rpc.calls.where((c) => c.method == 'Enable').length;

    await tester.tap(find.byKey(const ValueKey('liveView.retry')));
    await tester.pumpAndSettle();

    expect(rpc.calls.where((c) => c.method == 'Enable').length, greaterThan(enableCallsBefore));
  });

  testWidgets('the direction bar renders all five localized labels', (tester) async {
    stubHappyRpcPath();
    final controller = buildController(connect: (url) async => _FakeLiveSocket());
    await pump(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Front'), findsOneWidget);
    expect(find.text('Right'), findsOneWidget);
    expect(find.text('Rear'), findsOneWidget);
    expect(find.text('Left'), findsOneWidget);
  });

  testWidgets('tapping a direction button selects it and sends SetViewMode', (tester) async {
    stubHappyRpcPath();
    final controller = buildController(connect: (url) async => _FakeLiveSocket());
    await pump(tester, controller);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('liveView.direction.rear')));
    await tester.pumpAndSettle();

    expect(controller.state.direction, LiveViewDirection.rear);
    final req = rpc.calls.lastWhere((c) => c.method == 'SetViewMode').request as SetViewModeRequest;
    expect(req.viewMode, LiveViewDirection.rear.viewMode);
  });

}
