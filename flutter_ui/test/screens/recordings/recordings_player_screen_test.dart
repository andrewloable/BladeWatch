import 'dart:convert';

import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/rpc/jwt_source.dart';
import 'package:bladewatch_ui/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_ui/screens/recordings/recordings_models.dart';
import 'package:bladewatch_ui/screens/recordings/recordings_player_controller.dart';
import 'package:bladewatch_ui/screens/recordings/recordings_player_screen.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_rpc_client.dart';
import '../../fakes/fake_video_player_platform.dart';

class _FakeJwtSource implements JwtSource {
  @override
  Future<String?> mintJwt() async => 'jwt-1';
  @override
  Future<int> stateVersion() async => 0;
}

RecordingItem _item(String filename, {bool hasEvents = false}) => RecordingItem(
      filename: filename,
      path: '/storage/emulated/0/BladeWatch/recordings/$filename',
      kind: RecordingKind.normal,
      timestampMs: 1000,
      sizeBytes: 1500,
      durationSeconds: 60,
      dateLabel: 'May 23, 2026',
      timeLabel: '12:00:00 PM',
      hasEvents: hasEvents,
    );

void main() {
  late FakeVideoPlayerPlatform fakeVideo;
  late FakeRpcClient rpc;

  setUp(() {
    fakeVideo = FakeVideoPlayerPlatform.install();
    rpc = FakeRpcClient();
  });

  Widget wrap(Widget child) => MaterialApp(
        theme: BladeWatchTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      );

  // _start() chains mintJwt -> controller.initialize() (an RPC round trip
  // when hasEvents) -> _loadVideoForCurrent() -> VideoPlayerController's own
  // initialize()/play(), which waits on FakeVideoPlayerPlatform's
  // videoEventsFor() stream (a scheduleMicrotask hop of its own). Each hop
  // is a separate awaited microtask, so this needs more bounded pump()s
  // than a simpler screen -- same reasoning as location_screen_test.dart's
  // settle() helper.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 15; i++) {
      await tester.pump();
    }
  }

  testWidgets('renders the video surface and transport once initialized', (tester) async {
    final controller = RecordingsPlayerController(
      recordingsService: RecordingsServiceClient(rpc),
      playlist: [_item('a.mp4')],
      initialIndex: 0,
    );
    await tester.pumpWidget(wrap(RecordingsPlayerScreen(controller: controller, jwtSource: _FakeJwtSource())));
    await settle(tester);

    expect(find.byKey(const ValueKey('recordings.player.playPause')), findsOneWidget);
    expect(find.text('a.mp4'), findsOneWidget);
    expect(fakeVideo.isPlaying(0), isTrue, reason: 'autoplay, matching native videoView.start() on prepared');
  });

  testWidgets('tapping play/pause toggles playback', (tester) async {
    final controller = RecordingsPlayerController(
      recordingsService: RecordingsServiceClient(rpc),
      playlist: [_item('a.mp4')],
      initialIndex: 0,
    );
    await tester.pumpWidget(wrap(RecordingsPlayerScreen(controller: controller, jwtSource: _FakeJwtSource())));
    await settle(tester);
    expect(fakeVideo.isPlaying(0), isTrue);

    await tester.tap(find.byKey(const ValueKey('recordings.player.playPause')));
    await settle(tester);
    expect(fakeVideo.isPlaying(0), isFalse);

    await tester.tap(find.byKey(const ValueKey('recordings.player.playPause')));
    await settle(tester);
    expect(fakeVideo.isPlaying(0), isTrue);
  });

  testWidgets('prev/next are absent for a single-item playlist', (tester) async {
    final controller = RecordingsPlayerController(
      recordingsService: RecordingsServiceClient(rpc),
      playlist: [_item('a.mp4')],
      initialIndex: 0,
    );
    await tester.pumpWidget(wrap(RecordingsPlayerScreen(controller: controller, jwtSource: _FakeJwtSource())));
    await settle(tester);

    expect(find.byKey(const ValueKey('recordings.player.prev')), findsNothing);
    expect(find.byKey(const ValueKey('recordings.player.next')), findsNothing);
  });

  testWidgets('next() advances to the following clip and shows its title', (tester) async {
    final controller = RecordingsPlayerController(
      recordingsService: RecordingsServiceClient(rpc),
      playlist: [_item('a.mp4'), _item('b.mp4')],
      initialIndex: 0,
    );
    await tester.pumpWidget(wrap(RecordingsPlayerScreen(controller: controller, jwtSource: _FakeJwtSource())));
    await settle(tester);
    expect(find.text('a.mp4'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('recordings.player.next')));
    await settle(tester);

    expect(find.text('b.mp4'), findsOneWidget);
    expect(controller.index, 1);
  });

  testWidgets('prev() moves back to the preceding clip', (tester) async {
    final controller = RecordingsPlayerController(
      recordingsService: RecordingsServiceClient(rpc),
      playlist: [_item('a.mp4'), _item('b.mp4')],
      initialIndex: 1,
    );
    await tester.pumpWidget(wrap(RecordingsPlayerScreen(controller: controller, jwtSource: _FakeJwtSource())));
    await settle(tester);
    expect(find.text('b.mp4'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('recordings.player.prev')));
    await settle(tester);

    expect(find.text('a.mp4'), findsOneWidget);
    expect(controller.index, 0);
  });

  testWidgets('reaching the end of the clip auto-advances when a next clip exists', (tester) async {
    final controller = RecordingsPlayerController(
      recordingsService: RecordingsServiceClient(rpc),
      playlist: [_item('a.mp4'), _item('b.mp4')],
      initialIndex: 0,
    );
    await tester.pumpWidget(wrap(RecordingsPlayerScreen(controller: controller, jwtSource: _FakeJwtSource())));
    await settle(tester);
    expect(find.text('a.mp4'), findsOneWidget);

    fakeVideo.completeVideo(0);
    await settle(tester);

    expect(find.text('b.mp4'), findsOneWidget);
    expect(controller.index, 1);
  });

  testWidgets('the overlay auto-hides after 3 seconds of playback', (tester) async {
    final controller = RecordingsPlayerController(
      recordingsService: RecordingsServiceClient(rpc),
      playlist: [_item('a.mp4')],
      initialIndex: 0,
    );
    await tester.pumpWidget(wrap(RecordingsPlayerScreen(controller: controller, jwtSource: _FakeJwtSource())));
    await settle(tester);
    expect(find.byKey(const ValueKey('recordings.player.playPause')), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await settle(tester);

    expect(find.byKey(const ValueKey('recordings.player.playPause')), findsNothing);
  });

  testWidgets('the legend labels car/bike/motion counts too', (tester) async {
    rpc.stubJson('RecordingsService', 'GetEventTimeline', {
      'timelineJson': jsonEncode({
        'durationMs': 5000,
        'events': <dynamic>[],
        'stats': {'car': 1, 'bike': 2, 'motion': 3},
      }),
    });
    final controller = RecordingsPlayerController(
      recordingsService: RecordingsServiceClient(rpc),
      playlist: [_item('a.mp4', hasEvents: true)],
      initialIndex: 0,
    );
    await tester.pumpWidget(wrap(RecordingsPlayerScreen(controller: controller, jwtSource: _FakeJwtSource())));
    await settle(tester);

    expect(find.textContaining('1 car'), findsOneWidget);
    expect(find.textContaining('2 bike'), findsOneWidget);
    expect(find.textContaining('3 motion'), findsOneWidget);
  });

  testWidgets('prev is disabled on the first clip, next disabled on the last', (tester) async {
    final controller = RecordingsPlayerController(
      recordingsService: RecordingsServiceClient(rpc),
      playlist: [_item('a.mp4'), _item('b.mp4')],
      initialIndex: 0,
    );
    await tester.pumpWidget(wrap(RecordingsPlayerScreen(controller: controller, jwtSource: _FakeJwtSource())));
    await settle(tester);

    final prevButton = tester.widget<IconButton>(find.byKey(const ValueKey('recordings.player.prev')));
    expect(prevButton.onPressed, isNull);
    final nextButton = tester.widget<IconButton>(find.byKey(const ValueKey('recordings.player.next')));
    expect(nextButton.onPressed, isNotNull);
  });

  testWidgets('shows the no-events label when the clip has no sidecar', (tester) async {
    final controller = RecordingsPlayerController(
      recordingsService: RecordingsServiceClient(rpc),
      playlist: [_item('a.mp4', hasEvents: false)],
      initialIndex: 0,
    );
    await tester.pumpWidget(wrap(RecordingsPlayerScreen(controller: controller, jwtSource: _FakeJwtSource())));
    await settle(tester);

    expect(find.text('No events'), findsOneWidget);
  });

  testWidgets('shows the legend once the timeline loads events', (tester) async {
    rpc.stubJson('RecordingsService', 'GetEventTimeline', {
      'timelineJson': jsonEncode({
        'durationMs': 5000,
        'events': [
          {'start': 0, 'end': 1000, 'type': 'person'},
        ],
        'stats': {'person': 2},
      }),
    });
    final controller = RecordingsPlayerController(
      recordingsService: RecordingsServiceClient(rpc),
      playlist: [_item('a.mp4', hasEvents: true)],
      initialIndex: 0,
    );
    await tester.pumpWidget(wrap(RecordingsPlayerScreen(controller: controller, jwtSource: _FakeJwtSource())));
    await settle(tester);

    expect(find.text('2 person'), findsOneWidget);
    expect(find.byKey(const ValueKey('recordings.player.timeline')), findsOneWidget);
  });

  testWidgets('tapping the timeline seeks the video', (tester) async {
    final controller = RecordingsPlayerController(
      recordingsService: RecordingsServiceClient(rpc),
      playlist: [_item('a.mp4')],
      initialIndex: 0,
    );
    await tester.pumpWidget(wrap(RecordingsPlayerScreen(controller: controller, jwtSource: _FakeJwtSource())));
    await settle(tester);

    await tester.tapAt(tester.getCenter(find.byKey(const ValueKey('recordings.player.timeline'))));
    await settle(tester);

    expect(fakeVideo.positionOf(0), greaterThan(Duration.zero));
  });

  testWidgets('the back button pops the screen', (tester) async {
    final controller = RecordingsPlayerController(
      recordingsService: RecordingsServiceClient(rpc),
      playlist: [_item('a.mp4')],
      initialIndex: 0,
    );
    await tester.pumpWidget(wrap(Builder(builder: (context) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => RecordingsPlayerScreen(controller: controller, jwtSource: _FakeJwtSource()),
            )),
            child: const Text('open'),
          ),
        ),
      );
    })));
    await tester.tap(find.text('open'));
    await settle(tester);
    expect(find.byType(RecordingsPlayerScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('recordings.player.back')));
    await settle(tester);

    expect(find.byType(RecordingsPlayerScreen), findsNothing);
  });

  testWidgets('tapping the video area toggles the overlay controls', (tester) async {
    final controller = RecordingsPlayerController(
      recordingsService: RecordingsServiceClient(rpc),
      playlist: [_item('a.mp4')],
      initialIndex: 0,
    );
    await tester.pumpWidget(wrap(RecordingsPlayerScreen(controller: controller, jwtSource: _FakeJwtSource())));
    await settle(tester);
    expect(find.byKey(const ValueKey('recordings.player.playPause')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('recordings.player.tapToggle')));
    await settle(tester);
    expect(find.byKey(const ValueKey('recordings.player.playPause')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('recordings.player.tapToggle')));
    await settle(tester);
    expect(find.byKey(const ValueKey('recordings.player.playPause')), findsOneWidget);
  });

  testWidgets('renders in dark theme without crashing', (tester) async {
    final controller = RecordingsPlayerController(
      recordingsService: RecordingsServiceClient(rpc),
      playlist: [_item('a.mp4')],
      initialIndex: 0,
    );
    await tester.pumpWidget(MaterialApp(
      theme: BladeWatchTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: RecordingsPlayerScreen(controller: controller, jwtSource: _FakeJwtSource()),
    ));
    await settle(tester);

    expect(tester.takeException(), isNull);
  });
}
