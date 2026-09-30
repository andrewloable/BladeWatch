import 'dart:async';
import 'dart:convert';

import 'package:bladewatch_companion/screens/common/format.dart';
import 'package:bladewatch_companion/screens/recordings/clips.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pb.dart';
import 'package:fixnum/fixnum.dart';
import 'package:bladewatch_companion/transport/transport_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import '../support.dart';

/// An in-memory video platform: every player initialises at once, reports [position], records
/// seeks, and can have its connection "dropped" -- an error on its event stream, which is what a
/// real player does when the gateway's connection to the car goes away.
class _FakeVideo extends VideoPlayerPlatform {
  final events = <int, StreamController<VideoEvent>>{};
  final seeks = <Duration>[];
  var created = 0;
  var position = Duration.zero;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    final id = ++created;
    events[id] = StreamController<VideoEvent>()
      ..add(VideoEvent(eventType: VideoEventType.initialized, duration: const Duration(minutes: 2), size: const Size(160, 90)));
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => events[playerId]!.stream;

  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> play(int playerId) async {}
  @override
  Future<void> pause(int playerId) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<void> setPreventsDisplaySleepDuringVideoPlayback(int playerId, bool preventsDisplaySleep) async {}
  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    seeks.add(position);
    this.position = position;
  }

  @override
  Future<Duration> getPosition(int playerId) async => position;

  @override
  Future<void> dispose(int playerId) async => events.remove(playerId)?.close();

  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox.expand();

  void drop(int playerId) => events[playerId]!.addError(PlatformException(code: 'network', message: 'connection dropped'));

  void complete(int playerId) => events[playerId]!.add(VideoEvent(eventType: VideoEventType.completed));
}

void main() {
  hudTestEnvironment();

  late _FakeVideo platform;
  late VideoPlayerPlatform original;

  setUp(() {
    original = VideoPlayerPlatform.instance;
    platform = _FakeVideo();
    VideoPlayerPlatform.instance = platform;
  });

  tearDown(() => VideoPlayerPlatform.instance = original);

  // BladeWatch-tayl: a clip that was playing when the connection dropped carries on from there.
  testWidgets('a dropped clip reconnects and resumes where it was', (tester) async {
    await pumpScreen(tester, TestSession(), const ClipPlayerScreen(filename: 'a.mp4', canPlay: true, retryPause: Duration(milliseconds: 10)));
    await tester.pump();
    await tester.pump();
    expect(find.byType(VideoPlayer), findsOneWidget);
    // BladeWatch-rdtj.54: the play/pause button is announced, and follows the state.
    final semantics = tester.ensureSemantics();
    expect(tester.getSemantics(find.byKey(const ValueKey('player.play'))).tooltip, anyOf(t('companion.player_play'), t('companion.player_pause')));
    semantics.dispose();

    platform.position = const Duration(seconds: 42);
    await tester.pump(const Duration(seconds: 1)); // the controller polls its position while playing

    platform.drop(1);
    await tester.pump();
    await tester.pump();
    expect(find.byType(VideoPlayer), findsNothing, reason: 'a spinner while it reconnects, not an error');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();
    await tester.pump();
    expect(platform.created, 2, reason: 'a fresh player for the same clip');
    expect(platform.seeks, contains(const Duration(seconds: 42)), reason: 'resumed at the position it had reached');
    expect(find.byType(VideoPlayer), findsOneWidget);
  });

  testWidgets('it gives up after five tries, and says the clip will not load', (tester) async {
    await pumpScreen(tester, TestSession(), const ClipPlayerScreen(filename: 'a.mp4', canPlay: true, retryPause: Duration(milliseconds: 10)));
    await tester.pump();
    await tester.pump();
    for (var i = 1; i <= 6; i++) {
      platform.drop(platform.created);
      await tester.pump();
      await tester.pump(Duration(milliseconds: 10 * i + 5));
      await tester.pump();
      await tester.pump();
    }
    expect(platform.created, 6, reason: 'the first player and five recoveries');
    expect(find.text(t('errors.load_failed')), findsOneWidget);
  });

  // BladeWatch-tayl, from mobile data: reconnects took 5 s to 90+ s. Drops the session sees must
  // wait for the route rather than use up the five tries -- seven long outages in a row still play.
  testWidgets('drops while the route is down wait for it and never use up the tries', (tester) async {
    final s = TestSession();
    await pumpScreen(tester, s, const ClipPlayerScreen(filename: 'a.mp4', canPlay: true, retryPause: Duration(milliseconds: 10)));
    await tester.pump();
    await tester.pump();
    for (var i = 0; i < 7; i++) {
      await s.go(tester, TransportPhase.discovering);
      platform.drop(platform.created);
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget, reason: 'waiting, not failed');
      await tester.pump(const Duration(seconds: 90)); // a long outage
      await s.go(tester, TransportPhase.pear);
      await tester.pump();
      await tester.pump();
    }
    expect(platform.created, 8, reason: 'seven outages, seven recoveries, none of them counted');
    expect(find.text(t('errors.load_failed')), findsNothing);
    expect(find.byType(VideoPlayer), findsOneWidget);
  });

  // BladeWatch-rdtj.31: over a link slower than the clip the player holds still while it buffers
  // (4-23 s from mobile data). The fake never moves on its own, which is exactly that.
  testWidgets('a clip that does not move shows it is loading, then says why and offers the download', (tester) async {
    await pumpScreen(tester, TestSession(), const ClipPlayerScreen(filename: 'a.mp4', canPlay: true));
    await tester.pump();
    await tester.pump();
    expect(find.byType(VideoPlayer), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(CircularProgressIndicator), findsOneWidget, reason: 'loading, over the frame');
    expect(find.byKey(const ValueKey('player.slow')), findsNothing, reason: 'too soon to explain');

    await tester.pump(const Duration(seconds: 4));
    expect(find.text(t('companion.player_slow')), findsOneWidget);
    expect(find.widgetWithText(TextButton, t('common.download')), findsOneWidget);

    platform.position = const Duration(seconds: 1); // it has buffered enough and moves
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('player.slow')), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('an outage longer than its patience says the clip will not load', (tester) async {
    final s = TestSession();
    await pumpScreen(
      tester,
      s,
      const ClipPlayerScreen(filename: 'a.mp4', canPlay: true, retryPause: Duration(milliseconds: 10), patience: Duration(seconds: 5)),
    );
    await tester.pump();
    await tester.pump();
    await s.go(tester, TransportPhase.discovering);
    platform.drop(1);
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();
    expect(find.text(t('errors.load_failed')), findsOneWidget);
    expect(platform.created, 1, reason: 'nothing to reconnect to');
  });

  // BladeWatch-rdtj.44: the web player's times, detection timeline and previous/next.
  group('the player', () {
    RecordingEntry clip(String name, {bool events = true}) =>
        RecordingEntry(filename: name, type: RecordingType.RECORDING_TYPE_SENTRY, timestampMs: Int64(DateTime(2026, 9, 27, 11, 12).millisecondsSinceEpoch), hasEvents: events);

    test('parseTimeline reads spans, counts and length; anything else is no timeline', () {
      expect(parseTimeline(''), isNull);
      expect(parseTimeline('not json'), isNull);
      final t = parseTimeline(jsonEncode({
        'durationMs': 90000,
        'events': [
          {'start': 1000, 'end': 4000, 'type': 'person'},
          {'start': 7000},
        ],
        'stats': {'person': 2, 'car': 0},
      }))!;
      expect(t.spans, [(startMs: 1000, endMs: 4000, type: 'person'), (startMs: 7000, endMs: 7000, type: 'motion')]);
      expect(t.counts, {'person': 2}, reason: 'a zero count is left out');
      expect(t.durationMs, 90000);
    });

    test('clipTime: the car\'s timestamp, else the one in the name', () {
      expect(clipTime('x.mp4', clip('x.mp4')), DateTime(2026, 9, 27, 11, 12));
      expect(clipTime('event_20260927_111206.mp4'), DateTime(2026, 9, 27, 11, 12, 6));
      expect(clipTime('clip.mp4'), isNull);
    });

    testWidgets('titles the clip by when it was taken, shows the times and where things were seen', (tester) async {
      final s = TestSession();
      s.rpc.stubJson('RecordingsService', 'GetEventTimeline', {
        'timelineJson': jsonEncode({
          'durationMs': 120000,
          'events': [
            {'start': 0, 'end': 30000, 'type': 'person'},
            {'start': 60000, 'end': 90000, 'type': 'car'},
          ],
          'stats': {'person': 2, 'car': 1},
        }),
      });
      await pumpScreen(tester, s, const ClipPlayerScreen(filename: 'event_20260927_111206.mp4', canPlay: true));
      await tester.pump();
      await tester.pump();
      expect(find.text(Fmt.dateTime(Int64(DateTime(2026, 9, 27, 11, 12, 6).millisecondsSinceEpoch), 'en')), findsOneWidget);
      expect(find.textContaining('event_20260927_111206.mp4'), findsOneWidget, reason: 'the name, small, under the time');
      expect(find.text('0:00'), findsOneWidget);
      expect(find.text('2:00'), findsOneWidget);
      expect(find.descendant(of: find.byKey(const ValueKey('player.spans')), matching: find.byType(ColoredBox)), findsNWidgets(2));
      expect(find.text('${t('surveillance.person')} 2 · ${t('surveillance.car')} 1'), findsOneWidget);
      expect(find.byKey(const ValueKey('player.next')), findsNothing, reason: 'no list to walk from a lone clip');
    });

    testWidgets('no sidecar: the plain bar and "nothing detected"; a clip without events is not asked about', (tester) async {
      final s = TestSession(); // GetEventTimeline unstubbed: the call fails
      await pumpScreen(tester, s, const ClipPlayerScreen(filename: 'a.mp4', canPlay: true));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('player.spans')), findsNothing);
      expect(find.text(t('companion.no_detections')), findsOneWidget);
      expect(find.text('a.mp4'), findsOneWidget, reason: 'no time in the name: the name is the title');

      final quiet = TestSession();
      await pumpScreen(tester, quiet, ClipPlayerScreen(filename: 'q.mp4', canPlay: true, playlist: [clip('q.mp4', events: false)]));
      await tester.pump();
      expect(quiet.rpc.calls.where((c) => c.method == 'GetEventTimeline'), isEmpty);
    });

    testWidgets('moving on while a dropped clip waits for the route starts one player, not two', (tester) async {
      final s = TestSession(phase: TransportPhase.pear);
      s.rpc.stubJson('RecordingsService', 'GetEventTimeline', {'timelineJson': ''});
      await pumpScreen(tester, s, ClipPlayerScreen(filename: 'a.mp4', canPlay: true, retryPause: const Duration(milliseconds: 10), playlist: [clip('a.mp4'), clip('b.mp4')]));
      await tester.pump();
      await tester.pump();
      await s.go(tester, TransportPhase.discovering);
      platform.drop(1); // a's recovery now waits for the route
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('player.next')));
      await tester.pump();
      await tester.pump();
      expect(platform.created, 2, reason: 'b has its player');
      await s.go(tester, TransportPhase.pear); // the route is back: a's old recovery wakes up
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      expect(platform.created, 2, reason: 'no second player for the clip that was left');
      expect(find.text('2 / 2'), findsOneWidget);
    });

    testWidgets('previous and next walk the list it came from, and the end of a clip plays the next', (tester) async {
      final s = TestSession();
      s.rpc.stubJson('RecordingsService', 'GetEventTimeline', {'timelineJson': ''});
      await pumpScreen(tester, s, ClipPlayerScreen(filename: 'b.mp4', canPlay: true, playlist: [clip('a.mp4'), clip('b.mp4'), clip('c.mp4')]));
      await tester.pump();
      await tester.pump();
      expect(find.text('2 / 3'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('player.next')));
      await tester.pump();
      await tester.pump();
      expect(find.text('3 / 3'), findsOneWidget);
      expect(platform.created, 2, reason: 'a player for the new clip');
      expect((s.rpc.calls.last.request as GetEventTimelineRequest).filename, 'c.mp4');
      expect(tester.widget<IconButton>(find.byKey(const ValueKey('player.next'))).onPressed, isNull);

      await tester.tap(find.byKey(const ValueKey('player.previous')));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('player.previous')));
      await tester.pump();
      await tester.pump();
      expect(find.text('1 / 3'), findsOneWidget);
      expect(tester.widget<IconButton>(find.byKey(const ValueKey('player.previous'))).onPressed, isNull);

      platform.complete(platform.created);
      await tester.pump();
      await tester.pump();
      await tester.pump();
      expect(find.text('2 / 3'), findsOneWidget, reason: 'the end of a clip plays the next');
    });
  });
}
