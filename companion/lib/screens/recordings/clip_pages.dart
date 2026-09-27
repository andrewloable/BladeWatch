import 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pb.dart';
import 'package:flutter/material.dart';

import '../../i18n.dart';
import '../../car/car_page.dart';
import 'clips.dart';

/// The car's clips a page at a time (BladeWatch-rdtj.42). One request for 200 left every older
/// clip out of reach: the owner saw "1042 videos" over a list that stopped at 200.
///
/// ponytail: pages are offsets, and the car keeps recording while you scroll, so a new clip
/// shifts the next page down by one; a filename seen twice is skipped. A clip can be missed the
/// same way until the list is refreshed. Move to a cursor (older than X) if that ever matters.
class ClipPages extends ChangeNotifier {
  ClipPages(this._fetch, {this.pageSize = 50});

  /// One page, 1-based, as ListRecordings takes it.
  final Future<ListRecordingsResponse> Function(int page, int pageSize) _fetch;
  final int pageSize;

  final clips = <RecordingEntry>[];
  final _seen = <String>{};
  int total = 0;
  int _page = 0;
  int _generation = 0;
  bool loading = false;

  /// The first page failed: there is nothing to show.
  Object? error;

  /// A later page failed: the clips already here stay, with a retry at the end.
  bool pageFailed = false;
  bool _disposed = false;

  bool get loaded => _page > 0;
  bool get done => loaded && clips.length >= total;

  /// From the first page again: the filter changed, or the owner pulled to refresh.
  Future<void> reset() {
    _generation++;
    clips.clear();
    _seen.clear();
    total = 0;
    _page = 0;
    error = null;
    pageFailed = false;
    loading = false;
    return more();
  }

  Future<void> more() async {
    if (loading || done || _disposed) return; // a frame callback can land after the list is gone
    final generation = _generation;
    loading = true;
    pageFailed = false;
    _notify();
    try {
      final r = await _fetch(_page + 1, pageSize);
      if (generation != _generation) return;
      _page++;
      var added = 0;
      for (final c in r.recordings) {
        if (_seen.add(c.filename)) {
          clips.add(c);
          added++;
        }
      }
      // A page with nothing new -- empty, or only clips already here -- ends the list whatever
      // total says, so a total that runs ahead of the clips (deleted meanwhile) cannot ask for
      // pages forever (BladeWatch-rdtj.70 found the second case).
      total = added == 0 ? clips.length : r.total;
      error = null;
    } catch (e) {
      if (generation != _generation) return;
      if (_page == 0) {
        error = e;
      } else {
        pageFailed = true;
      }
    } finally {
      if (generation == _generation) {
        loading = false;
        _notify();
      }
    }
  }

  /// A clip deleted here: gone from the list without reloading every page.
  void remove(String filename) {
    if (clips.any((c) => c.filename == filename)) {
      clips.removeWhere((c) => c.filename == filename);
      total--;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// A [ClipPages] on screen: the next page loads as the end of the list comes into view.
class ClipPageList extends StatelessWidget {
  const ClipPageList({super.key, required this.pages, this.onDelete, this.selection, this.onToggle});

  final ClipPages pages;
  final void Function(RecordingEntry clip)? onDelete;

  /// The ticked filenames while picking clips; null when not picking.
  final Set<String>? selection;
  final void Function(String filename, bool on)? onToggle;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: pages,
        builder: (context, _) {
          final tr = context.tr;
          if (!pages.loaded) {
            if (pages.error != null && !pages.loading) return LoadError(onRetry: pages.reset);
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: pages.reset,
            child: pages.clips.isEmpty
                ? ListView(children: [
                    Padding(padding: const EdgeInsets.all(32), child: Text(tr('events.empty_none_title'), textAlign: TextAlign.center)),
                  ])
                : ListView.builder(
                    itemCount: pages.clips.length + (pages.done ? 0 : 1),
                    itemBuilder: (context, i) {
                      if (i < pages.clips.length) {
                        final c = pages.clips[i];
                        final picking = selection;
                        if (picking != null) {
                          return ClipTile(clip: c, selected: picking.contains(c.filename), onSelect: (on) => onToggle?.call(c.filename, on));
                        }
                        return ClipTile(clip: c, onDelete: onDelete == null ? null : () => onDelete!(c), playlist: pages.clips);
                      }
                      if (pages.pageFailed) {
                        return Center(
                          child: TextButton(key: const ValueKey('clips.retry'), onPressed: pages.more, child: Text(tr('common.retry'))),
                        );
                      }
                      // The end is in view: ask for the next page once this frame is drawn.
                      WidgetsBinding.instance.addPostFrameCallback((_) => pages.more());
                      return const Padding(
                        key: ValueKey('clips.more'),
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
          );
        },
      );
}
