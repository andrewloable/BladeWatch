import 'dart:async';

import 'package:bladewatch_companion/screens/recordings/clips.dart';
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
}

void main() {
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
}
