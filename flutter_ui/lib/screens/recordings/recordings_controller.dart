import 'package:flutter/foundation.dart';

import '../../gen/bladewatch/v1/recordings.pb.dart';
import '../../rpc/services/recordings_service_client.dart';
import 'recordings_models.dart';
import '../../shell/disposed_safe_notifier.dart';

int _defaultNowMs() => DateTime.now().millisecondsSinceEpoch;

int _localMidnight(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return DateTime(d.year, d.month, d.day).millisecondsSinceEpoch;
}

/// Aggregate counts/bytes for the header summary line and the segmented
/// control's per-segment counts. Ground truth: `RecordingsFragment.aggregate()`
/// + `RecordingStats` (the RPC's `GetStats`) -- `dashcamCount` is
/// `recordingsCount + proximityCount`, matching native's own
/// `dashcamStats.total` combining NORMAL + PROXIMITY. [todayCount] has no
/// RPC equivalent (`RecordingStats` carries no "today" count) so it is
/// computed client-side from the same `ListRecordings` payload already
/// fetched for the grid, mirroring `aggregate()`'s `today++` exactly, just
/// sourced from the RPC list instead of a filesystem scan.
class RecordingsStats {
  final int totalBytes;
  final int totalCount;
  final int dashcamCount;
  final int surveillanceCount;
  final int todayCount;

  const RecordingsStats({
    required this.totalBytes,
    required this.totalCount,
    required this.dashcamCount,
    required this.surveillanceCount,
    required this.todayCount,
  });
}

sealed class RecordingsLoadState {
  const RecordingsLoadState();
}

class RecordingsLoading extends RecordingsLoadState {
  const RecordingsLoading();
}

class RecordingsError extends RecordingsLoadState {
  const RecordingsError();
}

class RecordingsLoaded extends RecordingsLoadState {
  final List<RecordingItem> all;
  final RecordingsStats stats;
  const RecordingsLoaded(this.all, this.stats);
}

/// Outcome of [RecordingsController.deleteSelected] -- structured, not a
/// composed English sentence (same reasoning as `TripsController`'s
/// `SyncOutcome`): the screen renders it through ARB placeholders.
class BatchDeleteOutcome {
  final int deleted;
  final int failed;
  const BatchDeleteOutcome({required this.deleted, required this.failed});
}

/// Ground truth: `RecordingsFragment.kt` (segment/date/chip filter state +
/// header counts) + `RecordingLibraryFragment.kt` (the list itself,
/// multi-select, delete). This port collapses native's parent-fragment +
/// embedded-child-fragment split into one controller -- see
/// `recordings_screen.dart`'s doc comment for why.
///
/// Fetches the whole catalog once via `ListRecordings(pageSize: 1000)` and
/// filters segment/date/chips entirely client-side, exactly matching
/// `recording.component.ts` (the already-shipped Angular translation of this
/// same screen) -- `RecordingsApiHandler` clamps `pageSize` to 50 server-side
/// regardless of what is requested, a real, already-accepted limit neither
/// reference client works around.
class RecordingsController extends ChangeNotifier with DisposedSafeNotifier {
  RecordingsController({
    required RecordingsServiceClient recordingsService,
    int Function() nowMs = _defaultNowMs,
  })  : _service = recordingsService, // ignore: prefer_initializing_formals
        _nowMs = nowMs { // ignore: prefer_initializing_formals
    _filter = RecordingsFilterState(
      source: RecordingSource.dashcam,
      dateNarrowed: true,
      selectedDayMs: _localMidnight(_nowMs()),
    );
  }

  final RecordingsServiceClient _service;
  final int Function() _nowMs;

  RecordingsLoadState _state = const RecordingsLoading();
  RecordingsLoadState get state => _state;

  late RecordingsFilterState _filter;
  RecordingsFilterState get filter => _filter;

  /// The controller's own notion of "now" -- widgets computing today/
  /// yesterday/section-relative-day text must read this instead of calling
  /// `DateTime.now()` directly, or their classification silently diverges
  /// from the controller's (harmless with the real-clock default, but it
  /// breaks the injected fake clock this controller otherwise supports
  /// throughout, and a screen that can't be driven by a fake clock can't be
  /// deterministically tested).
  int get nowMs => _nowMs();

  bool _selectMode = false;
  bool get selectMode => _selectMode;

  final Set<String> _selected = {};
  Set<String> get selected => Set.unmodifiable(_selected);

  /// The post-filter list the grid renders. Empty (not an error) before the
  /// first successful [load].
  List<RecordingItem> get visible {
    final s = _state;
    if (s is! RecordingsLoaded) return const [];
    return visibleRecordings(s.all, _filter);
  }

  Future<void> load() async {
    _state = const RecordingsLoading();
    notifyListeners();
    try {
      final results = await Future.wait([
        _service.listRecordings(ListRecordingsRequest(type: '', pageSize: 1000)),
        _service.getStats(GetStatsRequest()),
      ]);
      final listResp = results[0] as ListRecordingsResponse;
      final statsResp = results[1] as GetStatsResponse;

      final all = listResp.recordings.map(_toItem).toList()
        ..sort((a, b) => b.timestampMs.compareTo(a.timestampMs));

      final todayStart = _localMidnight(_nowMs());
      final todayCount = all.where((r) => r.timestampMs >= todayStart).length;
      final stats = statsResp.stats;

      _state = RecordingsLoaded(
        all,
        RecordingsStats(
          totalBytes: stats.totalSizeBytes.toInt(),
          totalCount: stats.totalCount,
          dashcamCount: stats.recordingsCount + stats.proximityCount,
          surveillanceCount: stats.surveillanceCount,
          todayCount: todayCount,
        ),
      );
    } catch (_) {
      _state = const RecordingsError();
    }
    notifyListeners();
  }

  RecordingItem _toItem(RecordingEntry e) => RecordingItem(
        filename: e.filename,
        path: e.path,
        kind: switch (e.type) {
          RecordingType.RECORDING_TYPE_SENTRY => RecordingKind.sentry,
          RecordingType.RECORDING_TYPE_PROXIMITY => RecordingKind.proximity,
          _ => RecordingKind.normal,
        },
        timestampMs: e.timestampMs.toInt(),
        sizeBytes: e.sizeBytes.toInt(),
        durationSeconds: e.durationSeconds.toInt(),
        dateLabel: e.dateLabel,
        timeLabel: e.timeLabel,
        hasEvents: e.hasEvents,
        detectedClasses: List.unmodifiable(e.detectedClasses),
        severity: e.severity.isEmpty ? null : e.severity,
        proximity: e.proximity.isEmpty ? null : e.proximity,
      );

  // -------- Segment + date (all client-side, no reload) --------

  void setSource(RecordingSource source) {
    _filter = _filter.copyWith(source: source);
    _selectMode = false;
    _selected.clear();
    notifyListeners();
  }

  /// The date card's clear-X -- widens to every day without touching chips.
  void setDateNarrowed(bool narrowed) {
    _filter = _filter.copyWith(dateNarrowed: narrowed);
    notifyListeners();
  }

  void goToday() {
    _filter = _filter.copyWith(dateNarrowed: true, selectedDayMs: _localMidnight(_nowMs()));
    notifyListeners();
  }

  void goYesterday() {
    _filter = _filter.copyWith(dateNarrowed: true, selectedDayMs: _localMidnight(_nowMs()) - 86400000);
    notifyListeners();
  }

  /// One-day jump. Clamped at today, mirroring native's `shiftSelectedDay`.
  void shiftDay(int delta) {
    final next = _filter.selectedDayMs + delta * 86400000;
    if (next > _localMidnight(_nowMs())) return;
    _filter = _filter.copyWith(dateNarrowed: true, selectedDayMs: next);
    notifyListeners();
  }

  void pickDate(int dayMs) {
    _filter = _filter.copyWith(dateNarrowed: true, selectedDayMs: _localMidnight(dayMs));
    notifyListeners();
  }

  // -------- Chip filters --------

  void toggleActorClass(String name) {
    _filter = _filter.copyWith(actorClasses: _toggled(_filter.actorClasses, name));
    notifyListeners();
  }

  /// The filter sheet's "Any" chip -- clears the actor-class row only,
  /// leaving severity untouched. Mirrors `chipActorAny`'s click handler
  /// (distinct from [resetChips], which clears every dimension).
  void resetActorClasses() {
    _filter = _filter.copyWith(actorClasses: const {});
    notifyListeners();
  }

  void toggleSeverity(String name) {
    _filter = _filter.copyWith(severities: _toggled(_filter.severities, name));
    notifyListeners();
  }

  /// The filter sheet's "Any" chip for severity -- mirrors `chipSevAny`.
  void resetSeverities() {
    _filter = _filter.copyWith(severities: const {});
    notifyListeners();
  }

  void toggleDashcamType(String name) {
    _filter = _filter.copyWith(dashcamTypes: _toggled(_filter.dashcamTypes, name));
    notifyListeners();
  }

  void resetChips() {
    _filter = _filter.copyWith(actorClasses: const {}, severities: const {}, dashcamTypes: const {});
    notifyListeners();
  }

  static Set<String> _toggled(Set<String> set, String value) {
    final next = Set<String>.of(set);
    if (!next.remove(value)) next.add(value);
    return next;
  }

  // -------- Multi-select --------

  void enterSelectMode() {
    _selectMode = true;
    notifyListeners();
  }

  void exitSelectMode() {
    _selectMode = false;
    _selected.clear();
    notifyListeners();
  }

  void toggleSelected(String filename) {
    if (!_selected.remove(filename)) _selected.add(filename);
    notifyListeners();
  }

  /// Selects every currently-visible item, or deselects all if they are
  /// already all selected -- mirrors `recording.component.ts`'s
  /// `selectAllVisible` toggle (native's own `btnSelectAll` only ever
  /// selects, never toggles off; the toggle is a small, well-justified
  /// usability improvement this port follows the web reference for).
  void selectAllVisible() {
    final v = visible;
    final allSelected = v.isNotEmpty && v.every((r) => _selected.contains(r.filename));
    if (allSelected) {
      _selected.clear();
    } else {
      _selected
        ..clear()
        ..addAll(v.map((r) => r.filename));
    }
    notifyListeners();
  }

  // -------- Delete --------

  /// Deletes one recording. Removes it from [state] on success; leaves
  /// [state] untouched (including on a thrown exception) on failure.
  Future<bool> deleteRecording(String filename) async {
    try {
      final resp = await _service.deleteRecording(DeleteRecordingRequest(filename: filename));
      if (resp.success) _removeFromState(filename);
      return resp.success;
    } catch (_) {
      return false;
    }
  }

  /// Deletes every selected recording one at a time -- mirrors both
  /// native's `batchDeleteRecordings()` and the web reference's
  /// `deleteSelected()`, neither of which calls the dedicated `BatchDelete`
  /// RPC despite it existing; matching that precedent keeps delete/partial-
  /// failure behaviour identical across all three clients rather than
  /// introducing new, unverified atomicity semantics.
  Future<BatchDeleteOutcome> deleteSelected() async {
    final names = List<String>.of(_selected);
    var deleted = 0;
    var failed = 0;
    for (final name in names) {
      if (await deleteRecording(name)) {
        deleted++;
      } else {
        failed++;
      }
    }
    exitSelectMode();
    return BatchDeleteOutcome(deleted: deleted, failed: failed);
  }

  /// Removes a deleted clip from the cached list without a full reload --
  /// mirrors the web reference's optimistic `all.update(...)`. [RecordingsStats]
  /// is intentionally left as-is (stale by one clip) until the next [load],
  /// matching the web reference exactly: neither re-fetches `GetStats` after
  /// a delete.
  void _removeFromState(String filename) {
    final s = _state;
    if (s is! RecordingsLoaded) return;
    _state = RecordingsLoaded(s.all.where((r) => r.filename != filename).toList(), s.stats);
    notifyListeners();
  }
}
