import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../gen/l10n/app_localizations.dart';
import '../../rpc/jwt_source.dart';
import 'recordings_media_urls.dart';
import 'recordings_player_controller.dart';

/// Full-screen video player with a detection-event timeline overlay. Ground
/// truth: `VideoPlayerFragment.kt` (478 LOC) + `EventTimelineView.kt` (the
/// custom canvas view, ported to a `CustomPainter` here) + `sheet_recording_library_filters.xml`'s
/// sibling layout `fragment_video_player.xml`.
///
/// Native's `ARG_INLINE` mode (embedded in `RecordingsFragment`'s landscape
/// right pane, with its own maximize/minimize toggle) is not ported — this
/// shell has no precedent anywhere in Epic 2 for an inline-embedded child
/// screen; every other drill-down (Trip Detail, dialogs, etc.) uses a full
/// navigation push, which is what this screen is, uniformly, regardless of
/// orientation. Both of native's entry points (grid tap, and the inline
/// pane's own tap-to-open) land here identically since the inline pane
/// itself is not built.
///
/// One deliberate behavioural improvement over native: the timeline strip
/// is tap-to-seek here. Native's own `eventTimeline.setOnClickListener`
/// body is empty despite its own comment claiming "works for tap-to-seek" --
/// confirmed dead/non-functional by reading the code, not assumed -- so this
/// follows `video-player.component.ts` (the web reference), which
/// implements real click-to-seek on the same visual element, instead of
/// reproducing native's apparent oversight.
class RecordingsPlayerScreen extends StatefulWidget {
  final RecordingsPlayerController controller;
  final JwtSource jwtSource;

  /// What the back control does. Null (the pushed, full-screen case) pops the
  /// route, as before. The recordings screen's embedded detail pane passes a
  /// callback instead, because there is no route of its own to pop there and
  /// the button would otherwise be dead.
  final VoidCallback? onClose;

  const RecordingsPlayerScreen({
    super.key,
    required this.controller,
    required this.jwtSource,
    this.onClose,
  });

  @override
  State<RecordingsPlayerScreen> createState() => _RecordingsPlayerScreenState();
}

class _RecordingsPlayerScreenState extends State<RecordingsPlayerScreen> {
  VideoPlayerController? _video;
  String? _jwt;
  bool _overlayVisible = true;
  Timer? _hideOverlayTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    unawaited(_start());
  }

  Future<void> _start() async {
    _jwt = await widget.jwtSource.mintJwt();
    await widget.controller.initialize();
    await _loadVideoForCurrent();
  }

  Future<void> _loadVideoForCurrent() async {
    final jwt = _jwt;
    final old = _video;
    _video = VideoPlayerController.networkUrl(
      videoUrl(widget.controller.current.filename),
      httpHeaders: jwt != null ? {'Authorization': 'Bearer $jwt'} : const {},
    );
    await old?.dispose();
    await _video!.initialize();
    _video!.addListener(_onVideoTick);
    await _video!.play();
    _scheduleOverlayHide();
    if (mounted) setState(() {});
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _onVideoTick() {
    if (_video != null && _video!.value.isCompleted && widget.controller.canNext) {
      unawaited(_goNext());
    }
  }

  Future<void> _goNext() async {
    await widget.controller.next();
    await _loadVideoForCurrent();
  }

  Future<void> _goPrev() async {
    await widget.controller.prev();
    await _loadVideoForCurrent();
  }

  void _togglePlayPause() {
    final v = _video;
    if (v == null) return;
    if (v.value.isPlaying) {
      v.pause();
      _hideOverlayTimer?.cancel();
    } else {
      v.play();
      _scheduleOverlayHide();
    }
    setState(() {});
  }

  void _seekTo(Duration position) {
    _video?.seekTo(position);
  }

  void _toggleOverlay() {
    setState(() => _overlayVisible = !_overlayVisible);
    if (_overlayVisible) _scheduleOverlayHide();
  }

  void _scheduleOverlayHide() {
    _hideOverlayTimer?.cancel();
    _hideOverlayTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && (_video?.value.isPlaying ?? false)) setState(() => _overlayVisible = false);
    });
  }

  @override
  void dispose() {
    _hideOverlayTimer?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    _video?.removeListener(_onVideoTick);
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = widget.controller;
    final video = _video;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            key: const ValueKey('recordings.player.tapToggle'),
            // Without this, GestureDetector's default deferToChild behavior
            // only registers taps inside the AspectRatio-letterboxed video
            // rect itself -- tapping the surrounding black bars (most of a
            // 16:9 clip in a taller window) would silently do nothing.
            behavior: HitTestBehavior.opaque,
            onTap: _toggleOverlay,
            child: Center(
              child: video != null && video.value.isInitialized
                  ? AspectRatio(aspectRatio: video.value.aspectRatio, child: VideoPlayer(video))
                  : const CircularProgressIndicator(),
            ),
          ),
          if (_overlayVisible) _buildTopBar(context, l10n, c),
          if (_overlayVisible) _buildBottomControls(context, l10n, c, video),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AppLocalizations l10n, RecordingsPlayerController c) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black54,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              IconButton(
                key: const ValueKey('recordings.player.back'),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                tooltip: l10n.cd_back,
                onPressed: widget.onClose ?? () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Text(
                  c.current.filename.isEmpty ? l10n.player_title_recording : c.current.filename,
                  style: const TextStyle(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(c.current.formattedSize, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(
    BuildContext context,
    AppLocalizations l10n,
    RecordingsPlayerController c,
    VideoPlayerController? video,
  ) {
    final position = video?.value.position ?? Duration.zero;
    final duration = (video?.value.duration ?? Duration.zero) > Duration.zero
        ? video!.value.duration
        : Duration(milliseconds: c.sidecarDurationMs);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: Colors.black54,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(_fmt(position), style: const TextStyle(color: Colors.white)),
                  Expanded(
                    child: _TimelineStrip(
                      key: const ValueKey('recordings.player.timeline'),
                      spans: c.spans,
                      duration: duration,
                      position: position,
                      onSeek: _seekTo,
                    ),
                  ),
                  Text(duration > Duration.zero ? _fmt(duration) : l10n.player_time_zero,
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
              if (c.legendCounts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_legendText(l10n, c.legendCounts), style: const TextStyle(color: Colors.white70)),
                )
              else if (c.current.hasEvents == false || c.spans.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(l10n.video_player_no_events, style: const TextStyle(color: Colors.white54)),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (c.hasPlaylist)
                    IconButton(
                      key: const ValueKey('recordings.player.prev'),
                      icon: const Icon(Icons.skip_previous, color: Colors.white),
                      tooltip: l10n.cd_player_prev,
                      onPressed: c.canPrev ? _goPrev : null,
                    ),
                  IconButton(
                    key: const ValueKey('recordings.player.playPause'),
                    tooltip: l10n.cd_play_pause,
                    iconSize: 40,
                    icon: Icon(
                      (video?.value.isPlaying ?? false) ? Icons.pause_circle : Icons.play_circle,
                      color: Colors.white,
                    ),
                    onPressed: _togglePlayPause,
                  ),
                  if (c.hasPlaylist)
                    IconButton(
                      key: const ValueKey('recordings.player.next'),
                      icon: const Icon(Icons.skip_next, color: Colors.white),
                      tooltip: l10n.cd_player_next,
                      onPressed: c.canNext ? _goNext : null,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _legendText(AppLocalizations l10n, Map<String, int> counts) {
    String labelFor(String key) => switch (key) {
          'person' => l10n.video_player_legend_person,
          'car' => l10n.video_player_legend_car,
          'bike' => l10n.video_player_legend_bike,
          _ => l10n.video_player_legend_motion,
        };
    return counts.entries.map((e) => '${e.value} ${labelFor(e.key)}').join(' · ');
  }

  String _fmt(Duration d) {
    final totalSec = d.inSeconds;
    final min = totalSec ~/ 60;
    final sec = totalSec % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}

class _TimelineStrip extends StatelessWidget {
  final List<TimelineSpan> spans;
  final Duration duration;
  final Duration position;
  final ValueChanged<Duration> onSeek;

  const _TimelineStrip({
    super.key,
    required this.spans,
    required this.duration,
    required this.position,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _seekFromLocalX(details.localPosition.dx, context),
      child: SizedBox(
        height: 24,
        child: CustomPaint(
          painter: _TimelinePainter(spans: spans, durationMs: duration.inMilliseconds, playheadMs: position.inMilliseconds),
        ),
      ),
    );
  }

  void _seekFromLocalX(double dx, BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || duration <= Duration.zero) return;
    final ratio = (dx / box.size.width).clamp(0.0, 1.0);
    onSeek(duration * ratio);
  }
}

class _TimelinePainter extends CustomPainter {
  final List<TimelineSpan> spans;
  final int durationMs;
  final int playheadMs;

  const _TimelinePainter({required this.spans, required this.durationMs, required this.playheadMs});

  static const _colors = {
    SpanColorKey.motion: Color(0x99888888),
    SpanColorKey.person: Color(0xCCFF4444),
    SpanColorKey.car: Color(0xCC4488FF),
    SpanColorKey.bike: Color(0xCC44CC44),
  };

  @override
  void paint(Canvas canvas, Size size) {
    if (durationMs <= 0 || size.width <= 0) return;
    final barTop = size.height * 0.2;
    final barBottom = size.height * 0.8;

    for (final span in spans) {
      final left = (span.startMs / durationMs) * size.width;
      final right = ((span.endMs / durationMs) * size.width).clamp(left + 2, size.width);
      final paint = Paint()..color = _colors[spanColorKey(span.type)]!;
      canvas.drawRect(Rect.fromLTRB(left, barTop, right, barBottom), paint);
    }

    if (playheadMs >= 0 && playheadMs <= durationMs) {
      final x = (playheadMs / durationMs) * size.width;
      canvas.drawRect(Rect.fromLTRB(x - 1.5, 0, x + 1.5, size.height), Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) =>
      oldDelegate.spans != spans || oldDelegate.durationMs != durationMs || oldDelegate.playheadMs != playheadMs;
}
