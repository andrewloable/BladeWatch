/// Minimal fake `VideoPlayerPlatform` so widget tests can mount
/// `video_player`-backed screens with no real platform decoder available
/// (there is none in `flutter test`). Registers itself as
/// `VideoPlayerPlatform.instance`, matching the standard federated-plugin
/// testing pattern (the package ships no fake of its own to reuse).
///
/// Deliberately minimal: enough for `VideoPlayerController.initialize()` to
/// resolve (one synthetic `VideoEventType.initialized` event) and for
/// play/pause/seek to update in-memory state a test can assert on — not a
/// real decoder, no actual frames.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  final Map<int, StreamController<VideoEvent>> _controllers = {};
  final Map<int, Duration> _positions = {};
  final Map<int, bool> _playing = {};
  int _nextId = 0;

  /// Duration reported for every created player's `initialized` event.
  Duration fakeDuration = const Duration(seconds: 30);

  static FakeVideoPlayerPlatform install() {
    final fake = FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = fake;
    return fake;
  }

  bool isPlaying(int playerId) => _playing[playerId] ?? false;
  Duration positionOf(int playerId) => _positions[playerId] ?? Duration.zero;

  /// Simulates playback reaching the end of the clip, for tests of
  /// auto-advance-to-next-clip behaviour.
  void completeVideo(int playerId) {
    _controllers[playerId]?.add(VideoEvent(eventType: VideoEventType.completed));
  }

  @override
  Future<void> init() async {}

  @override
  Future<int?> create(DataSource dataSource) async {
    final id = _nextId++;
    _positions[id] = Duration.zero;
    _playing[id] = false;
    return id;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    // Emit the "initialized" event from onListen, not eagerly in create():
    // VideoPlayerController.initialize() calls create() and subscribes to
    // this stream in separate awaited steps, so an eagerly-scheduled
    // microtask can fire before anyone is listening -- on a broadcast
    // stream that means the event is silently dropped and initialize()
    // hangs forever waiting for one that already came and went.
    late StreamController<VideoEvent> controller;
    controller = StreamController<VideoEvent>(
      onListen: () {
        controller.add(VideoEvent(
          eventType: VideoEventType.initialized,
          duration: fakeDuration,
          size: const Size(1280, 720),
        ));
      },
    );
    _controllers[playerId] = controller;
    return controller.stream;
  }

  @override
  Future<void> play(int playerId) async {
    _playing[playerId] = true;
  }

  @override
  Future<void> pause(int playerId) async {
    _playing[playerId] = false;
  }

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    _positions[playerId] = position;
  }

  @override
  Future<Duration> getPosition(int playerId) async => _positions[playerId] ?? Duration.zero;

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> dispose(int playerId) async {
    await _controllers.remove(playerId)?.close();
    _positions.remove(playerId);
    _playing.remove(playerId);
  }

  @override
  Widget buildViewWithOptions(VideoViewOptions options) => const SizedBox.shrink();
}
