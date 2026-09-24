import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bladewatch_rpc/gen/bladewatch/v1/stream.pb.dart';
import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/platform/live_view_texture_channel.dart';
import 'package:bladewatch_ui/platform/location_channel.dart';
import 'package:bladewatch_ui/platform/network_channel.dart';
import 'package:bladewatch_ui/platform/prefs_channel.dart';
import 'package:bladewatch_rpc/rpc/jwt_source.dart';
import 'package:bladewatch_rpc/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/stream_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import 'package:bladewatch_ui/screens/live_view/live_view_controller.dart';
import 'package:bladewatch_ui/screens/live_view/live_view_models.dart';
import 'package:bladewatch_ui/screens/live_view/live_view_screen.dart';
import 'package:bladewatch_ui/screens/location/location_controller.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_platform_channel.dart';
import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';

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
      systemService: SystemServiceClient(rpc),
      recordingsService: RecordingsServiceClient(rpc),
      jwtSource: jwt,
      textureChannel: LiveViewTextureChannel(channel),
      retryDelay: Duration.zero,
      maxConnectAttempts: maxConnectAttempts,
      connect: connect ?? (url) async => throw StateError('no connector configured'),
    );
  }

  // BladeWatch-y78o.2: the Live screen now embeds a location preview fed by the SAME
  // LocationController class location_screen_test.dart exercises directly -- a second,
  // independent FakePlatformChannel so its 'location'/'prefs'/'network' stubs never collide
  // with `channel`'s own 'liveView' stubs above.
  LocationController buildLocationController() {
    final locationChannel = FakePlatformChannel();
    locationChannel.stub('location', 'hasPermission', true);
    locationChannel.stub('location', 'providerEnabled', {'gps': true, 'network': false});
    locationChannel.stub('location', 'startUpdates', {'ok': true});
    locationChannel.stub('location', 'stopUpdates', null);
    locationChannel.stub('location', 'currentSample', {
      'latitude': 37.7749,
      'longitude': -122.4194,
      'bearingDegrees': 45.0,
      'provider': 'gps',
      'timestampMs': DateTime.now().millisecondsSinceEpoch,
    });
    locationChannel.stub('prefs', 'getLocationUiMode', null);
    locationChannel.stub('prefs', 'getThemeMode', null);
    locationChannel.stub('network', 'current', {'type': 'wifi', 'ssid': 'car'});
    return LocationController(
      channel: LocationChannel(locationChannel),
      prefs: PrefsChannel(locationChannel),
      networkChannel: NetworkChannel(locationChannel),
    );
  }

  Future<void> pump(
    WidgetTester tester,
    LiveViewController controller, {
    LocationController? locationController,
    VoidCallback? onOpenLocation,
  }) async {
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
      home: Scaffold(
        body: LiveViewScreen(
          controller: controller,
          locationController: locationController ?? buildLocationController(),
          onOpenLocation: onOpenLocation ?? () {},
        ),
      ),
    ));
    // One extra pump: LiveViewScreen.initState fires an un-awaited start()+poll() on the
    // location controller (same fire-and-forget shape as LiveViewController.start() itself,
    // called the line above it) — this flushes that microtask chain so the preview reflects
    // the stubbed fix before assertions run. No Timer is created (see LiveViewScreen's own
    // doc comment on why), so this is a bounded pump, not a pumpAndSettle() hang risk.
    await tester.pump();
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

  testWidgets('the mark button is absent when nothing is recording', (tester) async {
    stubHappyRpcPath();
    rpc.stubJson('SystemService', 'GetStatus', {'recording': []});
    final controller = buildController(connect: (url) async => _FakeLiveSocket());
    await pump(tester, controller);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('liveView.mark')), findsNothing);
  });

  testWidgets('the mark button appears when recording and tapping it sends MarkRecording', (tester) async {
    // The genuine double-tap-inside-one-in-flight-call race is covered at the
    // controller level (live_view_controller_test.dart), where the two calls can be
    // fired without awaiting between them. tester.tap() pumps a settling frame after
    // each tap, so by the second tap here the fake RPC's near-instant response has
    // already resolved the first call -- this widget test exercises the button
    // wiring (visible, tappable, shows feedback), not the race itself.
    stubHappyRpcPath();
    rpc.stubJson('SystemService', 'GetStatus', {'recording': [0]});
    rpc.stubJson('RecordingsService', 'MarkRecording', {'success': true, 'filename': 'clip1.mp4', 'markTimestampMs': '1000'});
    final controller = buildController(connect: (url) async => _FakeLiveSocket());
    await pump(tester, controller);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('liveView.mark')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('liveView.mark')));
    await tester.pumpAndSettle();

    expect(rpc.calls.where((c) => c.method == 'MarkRecording').length, 1);
    expect(find.text('Bookmarked'), findsOneWidget);
  });

  // BladeWatch-y78o.2: give the camera the whole stage, with a narrow utility rail carrying
  // the location preview and Live's existing controls.

  testWidgets('renders the camera stage and the utility rail together', (tester) async {
    stubHappyRpcPath();
    final controller = buildController(connect: (url) async => _FakeLiveSocket());
    await pump(tester, controller);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('liveView.stage')), findsOneWidget);
    expect(find.byKey(const ValueKey('liveView.utilityRail')), findsOneWidget);
  });

  testWidgets('tapping the location preview navigates to the location destination', (tester) async {
    stubHappyRpcPath();
    final controller = buildController(connect: (url) async => _FakeLiveSocket());
    var opened = false;
    await pump(tester, controller, onOpenLocation: () => opened = true);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('liveView.locationPreview')));
    await tester.pumpAndSettle();

    expect(opened, isTrue);
  });

  testWidgets('the location preview shows the car location once a fix is available', (tester) async {
    stubHappyRpcPath();
    final controller = buildController(connect: (url) async => _FakeLiveSocket());
    await pump(tester, controller);
    await tester.pumpAndSettle();

    // "Car location" is location_car_location_title — the same string
    // LocationScreen's own LocationFresh banner uses (BladeWatch-y78o.2 reuses it rather
    // than adding a new l10n key for a state this project already has a label for).
    expect(find.text('Car location'), findsOneWidget);
  });

  test(
    'BladeWatch-y78o.2 does not modify nav_rail.dart — a source-level pin, '
    'since the issue forbids touching it and requires proof',
    () {
      // A plain FNV-1a32 + byte-length pin, computed against nav_rail.dart's content BEFORE
      // this issue's changes started (recorded in the close reason). No git shell-out (this
      // must run the same way in CI as locally, with no assumption about cwd being inside a
      // git worktree) and no new dependency (`crypto` is only a transitive one here) — see the
      // close reason for why this alternative was chosen over "not in this change's diff".
      final bytes = File('lib/shell/nav_rail.dart').readAsBytesSync();
      expect(bytes.length, 5181, reason: 'nav_rail.dart byte length changed — it must not be modified');

      var hash = 0x811c9dc5;
      for (final b in bytes) {
        hash ^= b;
        hash = (hash * 0x01000193) & 0xFFFFFFFF;
      }
      expect(
        hash,
        0x5f1891c7,
        reason: 'nav_rail.dart content changed — BladeWatch-y78o.2 must not modify this file',
      );
    },
  );
}
