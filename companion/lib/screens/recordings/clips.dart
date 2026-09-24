import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pb.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../../car/car_page.dart';
import '../../car/car_session.dart';
import '../../car/media.dart';
import '../../i18n.dart';
import '../common/format.dart';

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
  const ClipTile({super.key, required this.clip, this.onDelete});

  final RecordingEntry clip;
  final VoidCallback? onDelete;

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
      trailing: onDelete == null
          ? null
          : IconButton(
              key: ValueKey('clip.delete.${c.filename}'),
              tooltip: tr('common.delete'),
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
      onTap: () => openClip(context, c.filename),
    );
  }
}

/// Plays a clip (Android, iOS, macOS), or offers to save it where video_player has no player.
Future<void> openClip(BuildContext context, String filename) {
  final session = context.session;
  final tr = context.tr;
  return Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => TrScope(tr: tr, child: SessionScope(session: session, child: ClipPlayerScreen(filename: filename))),
  ));
}

class ClipPlayerScreen extends StatefulWidget {
  const ClipPlayerScreen({super.key, required this.filename, this.canPlay});

  final String filename;

  /// Test seam; by default the platforms video_player implements.
  final bool? canPlay;

  @override
  State<ClipPlayerScreen> createState() => _ClipPlayerScreenState();
}

class _ClipPlayerScreenState extends State<ClipPlayerScreen> {
  VideoPlayerController? _video;
  bool _failed = false;
  String? _saved;

  bool get _canPlay => widget.canPlay ?? (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  String get _path => '/video/${Uri.encodeComponent(widget.filename)}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_video == null && _canPlay && !_failed) unawaited(_start(context.session));
  }

  Future<void> _start(CarSession session) async {
    try {
      final video = VideoPlayerController.networkUrl(session.baseUrl.resolve(_path), httpHeaders: await session.authHeaders());
      _video = video;
      await video.initialize();
      await video.play();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _save() async {
    final session = context.session;
    final tr = context.tr;
    final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final dest = File('${dir.path}/${widget.filename}');
    final ok = await downloadMedia(session, _path, dest);
    if (mounted) setState(() => _saved = ok ? tr('companion.saved_to', {'path': dest.path}) : tr('errors.generic'));
  }

  @override
  void dispose() {
    unawaited(_video?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final video = _video;
    final ready = video != null && video.value.isInitialized;
    return Scaffold(
      appBar: AppBar(title: Text(widget.filename, overflow: TextOverflow.ellipsis), actions: [
        IconButton(key: const ValueKey('player.save'), tooltip: tr('common.download'), icon: const Icon(Icons.download), onPressed: _save),
      ]),
      body: Column(children: [
        Expanded(
          child: Center(
            child: ready
                ? AspectRatio(aspectRatio: video.value.aspectRatio, child: VideoPlayer(video))
                : !_canPlay || _failed
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(tr(_canPlay ? 'errors.load_failed' : 'companion.player_unsupported'), textAlign: TextAlign.center),
                      )
                    : const CircularProgressIndicator(),
          ),
        ),
        if (ready) ...[
          VideoProgressIndicator(video, allowScrubbing: true, padding: const EdgeInsets.all(12)),
          ValueListenableBuilder(
            valueListenable: video,
            builder: (context, v, _) => IconButton(
              iconSize: 40,
              icon: Icon(v.isPlaying ? Icons.pause_circle : Icons.play_circle),
              onPressed: () => v.isPlaying ? video.pause() : video.play(),
            ),
          ),
        ],
        if (_saved != null) Padding(padding: const EdgeInsets.all(12), child: Text(_saved!, key: const ValueKey('player.saved'))),
      ]),
    );
  }
}
