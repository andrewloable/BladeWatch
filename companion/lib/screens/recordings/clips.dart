import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pb.dart';
import 'package:bladewatch_rpc/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_theme/color_tokens.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../../car/car_page.dart';
import '../../car/car_session.dart';
import '../../car/media.dart';
import '../../i18n.dart';
import '../common/format.dart';
import 'video_capability.dart';

/// A clip's `/thumb/` image, fetched through the gateway once and kept for the session.
class ClipThumb extends StatefulWidget {
  const ClipThumb(this.filename, {super.key, this.fetch});

  final String filename;
  final Future<MediaResponse> Function(CarSession session, String path)? fetch;

  // ponytail: a bounded map, not an LRU -- cleared when full; thumbnails re-fetch cheaply.
  static final _cache = <String, Uint8List>{};

  @override
  State<ClipThumb> createState() => _ClipThumbState();
}

class _ClipThumbState extends State<ClipThumb> {
  Uint8List? _bytes;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bytes != null || _failed) return;
    _bytes = ClipThumb._cache[widget.filename];
    if (_bytes == null) unawaited(_load(context.session, widget.filename));
  }

  // Reused for another clip (a list refilled in place): drop the old image, fetch the new one.
  @override
  void didUpdateWidget(ClipThumb old) {
    super.didUpdateWidget(old);
    if (old.filename == widget.filename) return;
    _failed = false;
    _bytes = ClipThumb._cache[widget.filename];
    if (_bytes == null) unawaited(_load(context.session, widget.filename));
  }

  Future<void> _load(CarSession session, String filename) async {
    try {
      final r = await (widget.fetch ?? fetchMedia)(session, '/thumb/${Uri.encodeComponent(filename)}');
      if (!r.ok) throw StateError('${r.status}');
      if (ClipThumb._cache.length > 200) ClipThumb._cache.clear();
      ClipThumb._cache[filename] = r.bytes;
      // A late answer for a clip this widget no longer shows must not overwrite the current one.
      if (mounted && filename == widget.filename) setState(() => _bytes = r.bytes);
    } catch (_) {
      if (mounted && filename == widget.filename) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    return SizedBox(
      width: 96,
      height: 54,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: bytes != null
            ? Image.memory(bytes, fit: BoxFit.cover)
            : ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(_failed ? Icons.videocam_off_outlined : Icons.movie_outlined, size: 20),
              ),
      ),
    );
  }
}

String clipTypeLabel(Tr tr, RecordingType t) => switch (t) {
      RecordingType.RECORDING_TYPE_SENTRY => tr('events.badge_sentry'),
      RecordingType.RECORDING_TYPE_PROXIMITY => tr('events.badge_proximity'),
      _ => tr('events.badge_normal'),
    };

/// One clip in a list: thumbnail, when, how long, what was seen.
class ClipTile extends StatelessWidget {
  const ClipTile({super.key, required this.clip, this.onDelete, this.selected, this.onSelect, this.playlist = const []});

  final RecordingEntry clip;
  final VoidCallback? onDelete;

  /// The list this clip sits in, for the player's previous and next.
  final List<RecordingEntry> playlist;

  /// Non-null while the list is picking clips (BladeWatch-rdtj.43): a tap then ticks the clip
  /// instead of playing it, and there is no per-clip delete.
  final bool? selected;
  final ValueChanged<bool>? onSelect;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final c = clip;
    final seen = c.detectedClasses.isEmpty ? '' : ' · ${c.detectedClasses.join(', ')}';
    return ListTile(
      key: ValueKey('clip.${c.filename}'),
      leading: ClipThumb(c.filename),
      title: Text(Fmt.dateTime(c.timestampMs, tr.lang)),
      subtitle: Text('${clipTypeLabel(tr, c.type)} · ${Fmt.duration(c.durationSeconds.toInt())} · ${Fmt.bytes(c.sizeBytes.toInt())}$seen'),
      trailing: selected != null
          ? Checkbox(key: ValueKey('clip.check.${c.filename}'), value: selected, onChanged: (v) => onSelect?.call(v ?? false))
          : onDelete == null
              ? null
              : IconButton(
                  key: ValueKey('clip.delete.${c.filename}'),
                  tooltip: tr('common.delete'),
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
      onTap: selected != null ? () => onSelect?.call(!selected!) : () => openClip(context, c.filename, playlist: playlist),
    );
  }
}

/// Plays a clip (Android, iOS, macOS), or offers to save it where video_player has no player.
/// [playlist] is the list it was opened from, walked by previous and next.
Future<void> openClip(BuildContext context, String filename, {List<RecordingEntry> playlist = const []}) {
  final session = context.session;
  final tr = context.tr;
  return Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => TrScope(
      tr: tr,
      child: SessionScope(session: session, child: ClipPlayerScreen(filename: filename, playlist: List.of(playlist))),
    ),
  ));
}

/// Where in a clip something was detected, from the car's event-timeline sidecar.
typedef DetectionSpan = ({int startMs, int endMs, String type});

/// GetEventTimeline's timeline_json: the spans, the per-class counts, and the sidecar's own idea
/// of the clip length. Null when there is no usable sidecar.
({List<DetectionSpan> spans, Map<String, int> counts, int durationMs})? parseTimeline(String json) {
  if (json.isEmpty) return null;
  try {
    final d = jsonDecode(json) as Map<String, dynamic>;
    int n(Object? v) => (v as num?)?.toInt() ?? 0;
    final spans = <DetectionSpan>[
      for (final e in (d['events'] as List? ?? const []).whereType<Map<String, dynamic>>())
        (startMs: n(e['start']), endMs: e['end'] == null ? n(e['start']) : n(e['end']), type: (e['type'] as String?) ?? 'motion'),
    ];
    final counts = <String, int>{
      for (final MapEntry(:key, :value) in ((d['stats'] as Map<String, dynamic>?) ?? const {}).entries)
        if (value is num && value > 0) key: value.toInt(),
    };
    return (spans: spans, counts: counts, durationMs: n(d['durationMs']));
  } catch (_) {
    return null;
  }
}

/// When a clip was taken: the car's timestamp, else the one in its name (event_20260927_111206).
DateTime? clipTime(String filename, [RecordingEntry? entry]) {
  if (entry != null && entry.timestampMs > 0) return DateTime.fromMillisecondsSinceEpoch(entry.timestampMs.toInt());
  final m = RegExp(r'(\d{8})_(\d{6})').firstMatch(filename);
  return m == null ? null : DateTime.tryParse('${m[1]}T${m[2]}');
}

class ClipPlayerScreen extends StatefulWidget {
  const ClipPlayerScreen({
    super.key,
    required this.filename,
    this.playlist = const [],
    this.canPlay,
    this.retryPause = const Duration(seconds: 2),
    this.patience = const Duration(minutes: 10),
    this.onPlayer,
  });

  final String filename;

  /// The clips around this one, for previous and next (BladeWatch-rdtj.44); empty from an alert.
  final List<RecordingEntry> playlist;

  /// Test seam; by default the platforms video_player implements.
  final bool? canPlay;

  /// The pause before the n-th attempt to recover a playing clip is n times this.
  final Duration retryPause;

  /// How long a clip waits for the route to come back after a drop before giving up.
  final Duration patience;

  /// Test seam: every player this screen creates, so a device test can follow playback without
  /// depending on rendered frames (integration_test/pear_drop_ui_test.dart).
  final void Function(VideoPlayerController controller)? onPlayer;

  @override
  State<ClipPlayerScreen> createState() => _ClipPlayerScreenState();
}

class _ClipPlayerScreenState extends State<ClipPlayerScreen> {
  VideoPlayerController? _video;
  bool _failed = false;
  String? _saved;

  // The clip on screen: previous and next change it in place, as the web player does.
  // [_clip] counts the changes, so a recovery still waiting for the route when the owner moved on
  // does not start a second player for the clip that was left.
  int _clip = 0;
  late String _filename = widget.filename;
  late int _index = widget.playlist.indexWhere((c) => c.filename == widget.filename);
  RecordingEntry? get _entry => _index < 0 ? null : widget.playlist[_index];

  // BladeWatch-rdtj.44: where in the clip something was seen, from the car's sidecar.
  List<DetectionSpan> _spans = const [];
  Map<String, int> _counts = const {};
  int _sidecarMs = 0;

  // BladeWatch-tayl: a clip that was playing when the connection dropped carries on from where
  // it was, once the route is back, instead of dying on an error. A drop the session sees waits
  // for the route (up to [ClipPlayerScreen.patience]) without spending a try: from mobile data a
  // reconnect took 5 s to 90+ s. Only errors while the route is up count against
  // [_maxRecoveries].
  static const _maxRecoveries = 5;
  Duration _at = Duration.zero;
  bool _played = false;
  bool _recovering = false;
  int _recoveries = 0;

  // BladeWatch-rdtj.31: over a link slower than the clip (mobile data, 4-6 Mbit/s against a
  // 6 Mbit/s clip) the player holds still until it has buffered enough -- 4 to 23 s measured. Show
  // that it is loading, and after [_slowAfter] seconds say why and offer the download, rather than
  // a frozen frame.
  static const _slowAfter = 5;
  Timer? _stallTimer;
  Duration? _lastPosition;
  int _stalled = 0;

  bool get _canPlay => widget.canPlay ?? (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  // BladeWatch-rdtj.73: once VideoCapability answers (Android only), every /video/ request for
  // the rest of this screen's life carries this device's decode ceiling, so the car can decide
  // whether to serve the native file or a transcoded one. Empty (never set) on every other
  // platform, and before the first answer -- both mean "no hint", which is exactly the request
  // this screen always sent before this feature existed.
  String _hintQuery = '';

  String get _path => '/video/${Uri.encodeComponent(_filename)}$_hintQuery';

  // A save is an archival copy, not a "can this screen's player show it" question -- always the
  // untranscoded original, regardless of what _path is currently serving for playback.
  String get _nativePath => '/video/${Uri.encodeComponent(_filename)}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Not while [_recover] waits for the route: the session reconnecting notifies this screen too,
    // and starting here as well would race two players for the same clip.
    VideoCapability.ensureStarted();
    if (_video == null && _canPlay && !_failed && !_recovering) {
      unawaited(_start(context.session));
      unawaited(_loadTimeline(context.session));
    }
  }

  Future<void> _loadTimeline(CarSession session) async {
    final filename = _filename;
    if (_entry != null && !_entry!.hasEvents) return; // no sidecar to ask for
    try {
      final r = await RecordingsServiceClient(session.rpc).getEventTimeline(GetEventTimelineRequest(filename: filename));
      final t = parseTimeline(r.timelineJson);
      if (t == null || !mounted || filename != _filename) return;
      setState(() {
        _spans = t.spans;
        _counts = t.counts;
        _sidecarMs = t.durationMs;
      });
    } catch (_) {
      // No sidecar, or the car could not say: the plain progress bar stands. Nothing is invented.
    }
  }

  /// Previous (-1) or next (+1) in the list the clip was opened from.
  void _go(int delta) {
    final i = _index + delta;
    if (_index < 0 || i < 0 || i >= widget.playlist.length) return;
    final session = context.session;
    _stallTimer?.cancel();
    unawaited(_video?.dispose());
    setState(() {
      _clip++;
      _recovering = false;
      _index = i;
      _filename = widget.playlist[i].filename;
      _video = null;
      _failed = false;
      _saved = null;
      _at = Duration.zero;
      _played = false;
      _recoveries = 0;
      _stalled = 0;
      _spans = const [];
      _counts = const {};
      _sidecarMs = 0;
    });
    if (_canPlay) unawaited(_start(session));
    unawaited(_loadTimeline(session));
  }

  Future<void> _start(CarSession session) async {
    try {
      final hint = VideoCapability.known;
      _hintQuery = hint == null ? '' : '?maxW=${hint.$1}&maxH=${hint.$2}';
      if (_hintQuery.isNotEmpty && !await _awaitTranscode(session)) {
        if (mounted) setState(() => _failed = true);
        return;
      }
      final video = VideoPlayerController.networkUrl(session.baseUrl.resolve(_path), httpHeaders: await session.authHeaders());
      _video = video;
      widget.onPlayer?.call(video);
      video.addListener(() => _onValue(video));
      await video.initialize();
      if (_at > Duration.zero) await video.seekTo(_at);
      await video.play();
      _played = true;
      _watchStall(video);
      if (mounted) setState(() {});
    } catch (_) {
      // A clip that never played is simply unavailable; one that was playing gets another go.
      if (_played) {
        unawaited(_recover());
      } else if (mounted) {
        setState(() => _failed = true);
      }
    }
  }

  /// Polls [_path] with a 1-byte Range probe until the car stops answering 202 (BladeWatch-rdtj.73:
  /// this clip doesn't fit the device's decode ceiling and is being transcoded in the background).
  /// A 5-minute clip measured ~107s to decode alone on the car's own hardware, so this budgets
  /// generously rather than giving up early on a clip that is genuinely still on its way. False
  /// only on a real timeout or if the clip changed while this was waiting.
  Future<bool> _awaitTranscode(CarSession session) async {
    final clip = _clip;
    final deadline = DateTime.now().add(const Duration(minutes: 5));
    while (DateTime.now().isBefore(deadline)) {
      if (!mounted || clip != _clip) return false;
      final r = await fetchMedia(session, _path, extraHeaders: const {'Range': 'bytes=0-0'});
      if (r.status != 202) return true;
      final retryAfter = int.tryParse(r.headers['retry-after'] ?? '') ?? 3;
      await Future<void>.delayed(Duration(seconds: retryAfter));
    }
    return false;
  }

  void _onValue(VideoPlayerController video) {
    if (!identical(video, _video)) return;
    final v = video.value;
    if (v.hasError) {
      if (_played) unawaited(_recover());
    } else if (v.isCompleted && _index >= 0 && _index < widget.playlist.length - 1) {
      _go(1); // on to the next clip, as the web player does
    } else if (v.isInitialized && v.position > Duration.zero) {
      _at = v.position;
    }
  }

  /// Counts the seconds [video] has been meant to play without moving.
  void _watchStall(VideoPlayerController video) {
    _stallTimer?.cancel();
    _lastPosition = null;
    _stalled = 0;
    _stallTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final v = video.value;
      final still = v.isPlaying && v.position == _lastPosition && v.position < v.duration;
      _lastPosition = v.position;
      final stalled = still ? _stalled + 1 : 0;
      if (stalled != _stalled && mounted) setState(() => _stalled = stalled);
    });
  }

  Future<void> _recover() async {
    if (_recovering || !mounted) return;
    _recovering = true;
    final clip = _clip;
    final session = context.session;
    final old = _video;
    _stallTimer?.cancel();
    setState(() {
      _video = null; // the spinner, while it reconnects
      _stalled = 0;
    });
    unawaited(old?.dispose());
    if (!session.connected) {
      final back = await untilConnected(session, widget.patience);
      if (clip != _clip) return; // moved to another clip meanwhile: that one has its own player
      _recovering = false;
      if (!mounted) return;
      if (back) {
        await _start(session);
      } else {
        setState(() => _failed = true);
      }
      return;
    }
    if (++_recoveries > _maxRecoveries) {
      _recovering = false;
      if (mounted) setState(() => _failed = true);
      return;
    }
    await Future<void>.delayed(widget.retryPause * _recoveries);
    if (clip != _clip) return;
    _recovering = false;
    if (mounted) await _start(context.session);
  }

  // One download at a time: a second would start by deleting the first one's .part file. There
  // are two Download buttons while a clip is slow to start.
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    _saving = true;
    final session = context.session;
    final tr = context.tr;
    try {
      final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final dest = File('${dir.path}/$_filename');
      final ok = await downloadMedia(session, _nativePath, dest);
      if (mounted) setState(() => _saved = ok ? tr('companion.saved_to', {'path': dest.path}) : tr('errors.generic'));
    } finally {
      _saving = false;
    }
  }

  @override
  void dispose() {
    _stallTimer?.cancel();
    unawaited(_video?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final video = _video;
    final ready = video != null && video.value.isInitialized;
    final when = clipTime(_filename, _entry);
    final entry = _entry;
    return Scaffold(
      // When it was taken and what kind of clip, like the list row; the file name, which is what
      // this used to show, is kept small underneath (BladeWatch-rdtj.44).
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(
            when == null ? _filename : Fmt.dateTime(Int64(when.millisecondsSinceEpoch), tr.lang),
            key: const ValueKey('player.title'),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            [if (entry != null) clipTypeLabel(tr, entry.type), if (when != null) _filename].join(' · '),
            style: Theme.of(context).textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ]),
        actions: [
        IconButton(key: const ValueKey('player.save'), tooltip: tr('common.download'), icon: const Icon(Icons.download), onPressed: _save),
      ]),
      body: Column(children: [
        Expanded(
          child: Center(
            child: ready
                ? Stack(alignment: Alignment.center, children: [
                    AspectRatio(aspectRatio: video.value.aspectRatio, child: VideoPlayer(video)),
                    if (_stalled > 0) const CircularProgressIndicator(),
                  ])
                : !_canPlay || _failed
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(tr(_canPlay ? 'errors.load_failed' : 'companion.player_unsupported'), textAlign: TextAlign.center),
                      )
                    : const CircularProgressIndicator(),
          ),
        ),
        if (ready)
          ValueListenableBuilder(
            valueListenable: video,
            builder: (context, v, _) {
              final total = v.duration > Duration.zero ? v.duration : Duration(milliseconds: _sidecarMs);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [
                  Text(_clock(v.position), key: const ValueKey('player.position')),
                  Expanded(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      _DetectionStrip(spans: _spans, totalMs: total.inMilliseconds),
                      VideoProgressIndicator(video, allowScrubbing: true, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10)),
                    ]),
                  ),
                  Text(_clock(total), key: const ValueKey('player.duration')),
                ]),
              );
            },
          ),
        if (ready)
          Text(
            _counts.isEmpty ? tr('companion.no_detections') : _legend(tr),
            key: const ValueKey('player.legend'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (ready || widget.playlist.length > 1)
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (widget.playlist.length > 1)
              IconButton(
                key: const ValueKey('player.previous'),
                tooltip: tr('companion.prev_clip'),
                onPressed: _index > 0 ? () => _go(-1) : null,
                icon: const Icon(Icons.skip_previous),
              ),
            if (ready)
              ValueListenableBuilder(
                valueListenable: video,
                builder: (context, v, _) => IconButton(
                  key: const ValueKey('player.play'),
                  iconSize: 40,
                  tooltip: tr(v.isPlaying ? 'companion.player_pause' : 'companion.player_play'),
                  icon: Icon(v.isPlaying ? Icons.pause_circle : Icons.play_circle),
                  onPressed: () => v.isPlaying ? video.pause() : video.play(),
                ),
              ),
            if (widget.playlist.length > 1) ...[
              IconButton(
                key: const ValueKey('player.next'),
                tooltip: tr('companion.next_clip'),
                onPressed: _index >= 0 && _index < widget.playlist.length - 1 ? () => _go(1) : null,
                icon: const Icon(Icons.skip_next),
              ),
              Text('${_index + 1} / ${widget.playlist.length}', key: const ValueKey('player.count')),
            ],
          ]),
        if (ready && _stalled >= _slowAfter)
          Padding(
            key: const ValueKey('player.slow'),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              Expanded(child: Text(tr('companion.player_slow'))),
              TextButton.icon(onPressed: _save, icon: const Icon(Icons.download), label: Text(tr('common.download'))),
            ]),
          ),
        if (_saved != null) Padding(padding: const EdgeInsets.all(12), child: Text(_saved!, key: const ValueKey('player.saved'))),
      ]),
    );
  }

  static String _clock(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  String _legend(Tr tr) {
    final names = {
      'person': tr('surveillance.person'),
      'car': tr('surveillance.car'),
      'vehicle': tr('surveillance.car'),
      'bike': tr('surveillance.bike'),
      'motion': tr('companion.motion'),
    };
    return [for (final MapEntry(:key, :value) in _counts.entries) '${names[key] ?? key} $value'].join(' · ');
  }
}

/// The detection spans laid along the clip: person red, vehicle blue, bike green, anything else
/// grey -- the web player's colours, taken from the theme's status colours.
class _DetectionStrip extends StatelessWidget {
  const _DetectionStrip({required this.spans, required this.totalMs});

  final List<DetectionSpan> spans;
  final int totalMs;

  @override
  Widget build(BuildContext context) {
    if (spans.isEmpty || totalMs <= 0) return const SizedBox(height: 6);
    final colors = Theme.of(context).extension<BwStatusColors>()!;
    Color color(String type) => switch (type) {
          'person' => colors.danger,
          'car' || 'vehicle' => colors.info,
          'bike' => colors.success,
          _ => Theme.of(context).colorScheme.outline,
        };
    return LayoutBuilder(
      builder: (context, box) => SizedBox(
        key: const ValueKey('player.spans'),
        height: 6,
        child: Stack(children: [
          for (final s in spans)
            Positioned(
              left: 8 + (box.maxWidth - 16) * (s.startMs.clamp(0, totalMs) / totalMs),
              width: ((box.maxWidth - 16) * ((s.endMs - s.startMs).clamp(0, totalMs) / totalMs)).clamp(2, box.maxWidth),
              top: 0,
              bottom: 0,
              child: ColoredBox(color: color(s.type)),
            ),
        ]),
      ),
    );
  }
}
