import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pb.dart';
import 'package:bladewatch_rpc/rpc/services/recordings_service_client.dart';
import 'recordings_models.dart';
import '../../shell/disposed_safe_notifier.dart';

/// One detection-event span on the timeline, relative to the clip start.
/// Mirrors native's `EventTimelineView.TimelineEvent`.
class TimelineSpan {
  final int startMs;
  final int endMs;
  final String type;
  final double confidence;

  const TimelineSpan({required this.startMs, required this.endMs, required this.type, this.confidence = 0});
}

class ParsedTimeline {
  final List<TimelineSpan> spans;
  final int durationMs;

  /// Non-zero legend counts only, keyed by the sidecar's own vocabulary
  /// ("person"/"car"/"bike"/"motion") -- mirrors
  /// `VideoPlayerFragment.loadEventTimeline()`'s legend `buildString`, which
  /// likewise only appends a class when its count is greater than 0.
  final Map<String, int> legendCounts;

  const ParsedTimeline({required this.spans, required this.durationMs, required this.legendCounts});

  static const empty = ParsedTimeline(spans: [], durationMs: 0, legendCounts: {});
}

/// Parses `GetEventTimelineResponse.timeline_json` (the EventTimelineCollector
/// v3 sidecar, verbatim JSON per the proto's own doc comment) into spans +
/// duration + legend. Mirrors `VideoPlayerFragment.loadEventTimeline()`
/// exactly (same field names: `durationMs`, `events[].start/end/type/maxConf`,
/// `stats{person,car,bike,motion}`) -- cross-checked against
/// `video-player.component.ts`'s `fetchSpans()`, the already-shipped web
/// parse of the same payload. Any parse failure (missing sidecar, malformed
/// JSON) degrades to [ParsedTimeline.empty] rather than throwing, matching
/// both reference implementations' silent-fallback behaviour.
ParsedTimeline parseTimelineJson(String raw) {
  if (raw.isEmpty) return ParsedTimeline.empty;
  try {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final durationMs = (json['durationMs'] as num?)?.toInt() ?? 0;
    final eventsRaw = json['events'] as List<dynamic>? ?? const [];
    final spans = eventsRaw.map((e) {
      final m = e as Map<String, dynamic>;
      final start = (m['start'] as num?)?.toInt() ?? 0;
      return TimelineSpan(
        startMs: start,
        endMs: (m['end'] as num?)?.toInt() ?? start,
        type: (m['type'] as String?) ?? 'motion',
        confidence: (m['maxConf'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    final statsRaw = json['stats'] as Map<String, dynamic>?;
    final legend = <String, int>{};
    if (statsRaw != null) {
      for (final key in const ['person', 'car', 'bike', 'motion']) {
        final v = (statsRaw[key] as num?)?.toInt() ?? 0;
        if (v > 0) legend[key] = v;
      }
    }
    return ParsedTimeline(spans: spans, durationMs: durationMs, legendCounts: legend);
  } catch (_) {
    return ParsedTimeline.empty;
  }
}

enum SpanColorKey { person, car, bike, motion }

/// Mirrors `EventTimelineView.onDraw()`'s exact `when (ev.type)` switch --
/// case-sensitive, only "person"/"car"/"bike" recognized, everything else
/// (including the web player's extra synonyms like "vehicle"/"bicycle") maps
/// to motion/gray. Native is this port's ground truth; the web reference's
/// looser matching is not reproduced.
SpanColorKey spanColorKey(String type) => switch (type) {
      'person' => SpanColorKey.person,
      'car' => SpanColorKey.car,
      'bike' => SpanColorKey.bike,
      _ => SpanColorKey.motion,
    };

/// Ground truth: `VideoPlayerFragment.kt`'s playlist (`playlistPaths`/
/// `playlistIndex`/`jumpTo`) + event-timeline loading
/// (`loadEventTimeline`). Actual video playback (play/pause/seek/position)
/// is owned by the screen's own `video_player.VideoPlayerController` --
/// same split as `LocationScreen` owning `flutter_map`'s `MapController`
/// directly, since neither is a plain-Dart-testable object this controller
/// could hold without pulling in a Flutter-coupled dependency.
class RecordingsPlayerController extends ChangeNotifier with DisposedSafeNotifier {
  RecordingsPlayerController({
    required RecordingsServiceClient recordingsService,
    required List<RecordingItem> playlist,
    required int initialIndex,
  })  : _service = recordingsService, // ignore: prefer_initializing_formals
        _playlist = playlist, // ignore: prefer_initializing_formals
        _index = initialIndex; // ignore: prefer_initializing_formals

  final RecordingsServiceClient _service;
  final List<RecordingItem> _playlist;
  int _index;

  RecordingItem get current => _playlist[_index];
  int get index => _index;
  int get playlistCount => _playlist.length;
  bool get hasPlaylist => _playlist.length >= 2;
  bool get canPrev => _index > 0;
  bool get canNext => _index < _playlist.length - 1;

  List<TimelineSpan> _spans = const [];
  List<TimelineSpan> get spans => _spans;
  int _sidecarDurationMs = 0;
  int get sidecarDurationMs => _sidecarDurationMs;
  Map<String, int> _legendCounts = const {};
  Map<String, int> get legendCounts => _legendCounts;

  /// Loads the timeline for the clip [initialIndex] started on. Call once
  /// from the screen's `initState`.
  Future<void> initialize() => _loadTimelineForCurrent();

  Future<void> prev() async {
    if (!canPrev) return;
    await _jumpTo(_index - 1);
  }

  Future<void> next() async {
    if (!canNext) return;
    await _jumpTo(_index + 1);
  }

  Future<void> jumpTo(int newIndex) async {
    if (newIndex < 0 || newIndex >= _playlist.length) return;
    await _jumpTo(newIndex);
  }

  Future<void> _jumpTo(int newIndex) async {
    _index = newIndex;
    _resetTimeline();
    notifyListeners();
    await _loadTimelineForCurrent();
  }

  void _resetTimeline() {
    _spans = const [];
    _sidecarDurationMs = 0;
    _legendCounts = const {};
  }

  Future<void> _loadTimelineForCurrent() async {
    final item = current;
    // No sidecar -- nothing to fetch, mirrors both reference
    // implementations skipping the call entirely when hasEvents is false.
    if (!item.hasEvents) return;
    try {
      final resp = await _service.getEventTimeline(GetEventTimelineRequest(filename: item.filename));
      final parsed = parseTimelineJson(resp.timelineJson);
      // Guard against a stale response landing after the user moved on.
      if (identical(item, current)) {
        _spans = parsed.spans;
        _sidecarDurationMs = parsed.durationMs;
        _legendCounts = parsed.legendCounts;
        notifyListeners();
      }
    } catch (_) {
      // Sidecar missing/unparsable server-side -- leave the timeline empty.
    }
  }
}
