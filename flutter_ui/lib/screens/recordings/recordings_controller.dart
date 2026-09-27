import 'dart:async';

import 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pb.dart';
import 'package:bladewatch_rpc/rpc/services/recordings_service_client.dart';
import 'package:flutter/foundation.dart';

import '../../shell/disposed_safe_notifier.dart';
import 'recordings_models.dart';

int _defaultNowMs() => DateTime.now().millisecondsSinceEpoch;

/// The library's header line: every clip on the car and their size, from GetStats.
class RecordingsStats {
  final int totalCount;
  final int totalBytes;

  const RecordingsStats({required this.totalCount, required this.totalBytes});
}

class BatchDeleteOutcome {
  final int deleted;
  final int failed;

  const BatchDeleteOutcome({required this.deleted, required this.failed});
}

/// The recording library as the companion presents it (BladeWatch-rdtj.70, the owner's choice):
/// every clip on the car, filtered BY THE CAR -- type, day, and for sentry clips who was seen and
/// how bad -- and fetched a page at a time as the list scrolls.
///
/// It used to make one ListRecordings(pageSize: 1000) call and filter client-side, but the car
/// clamps pageSize to 50: the library only ever held the 50 newest clips, so older days came up
/// empty. The paging is companion/lib/screens/recordings/clip_pages.dart's, ported.
/// ponytail: a second copy of that paging; share it through packages/ if a third client needs it.
///
/// ponytail: pages are offsets, and the car keeps recording while you scroll, so a new clip
/// shifts the next page down by one; a filename seen twice is skipped. A clip can be missed the
/// same way until the list is refreshed. Move to a cursor (older than X) if that ever matters.
class RecordingsController extends ChangeNotifier with DisposedSafeNotifier {
  RecordingsController({
    required RecordingsServiceClient recordingsService,
    int Function() nowMs = _defaultNowMs,
    this.pageSize = 50,
  })  : _service = recordingsService, // ignore: prefer_initializing_formals
        _nowMs = nowMs; // ignore: prefer_initializing_formals

  /// ListRecordings' `type` values, as the car names them ('' is everything).
  static const types = ['', 'normal', 'sentry', 'proximity'];

  /// ListRecordings' class_filter and severity_filter values, sentry clips only.
  static const actorClasses = ['person', 'vehicle', 'bike', 'animal'];
  static const severityLevels = ['ALERT', 'CRITICAL'];

  final RecordingsServiceClient _service;
  final int Function() _nowMs;
  final int pageSize;

  /// The controller's own notion of "now" (today, yesterday): read this, never DateTime.now(),
  /// so a fake clock drives the screen too.
  int get nowMs => _nowMs();

  // -------- Filters --------

  String _type = '';
  String get type => _type;

  /// The day shown, as the car names days (yyyy-MM-dd); null is every day.
  String? _day;
  String? get day => _day;

  final Set<String> _actors = {};
  Set<String> get actors => Set.unmodifiable(_actors);

  final Set<String> _severities = {};
  Set<String> get severities => Set.unmodifiable(_severities);

  /// yyyy-MM-dd, as the car names days in GetDates and filters ListRecordings by. It refuses any
  /// other form with an empty list, which is how yyyyMMdd left Today and Yesterday empty.
  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime get _today => DateTime.fromMillisecondsSinceEpoch(_nowMs());
  String get todayKey => dayKey(_today);
  String get yesterdayKey => dayKey(DateTime(_today.year, _today.month, _today.day - 1));

  // -------- Header --------

  RecordingsStats? _stats;
  RecordingsStats? get stats => _stats;

  // Days with at least one clip, so the arrows skip empty ones. Without them (an older car, or
  // the call failed) the arrows step a day at a time.
  List<String> _dates = const [];

  // -------- Pages --------

  final List<RecordingItem> _clips = [];
  List<RecordingItem> get clips => List.unmodifiable(_clips);
  final Set<String> _seen = {};
  int _total = 0;
  int _page = 0;
  int _generation = 0;

  bool _loading = false;
  bool get loading => _loading;

  /// The first page failed: there is nothing to show.
  bool _failed = false;
  bool get failed => _failed;

  /// A later page failed: the clips already here stay, with a retry at the end.
  bool _pageFailed = false;
  bool get pageFailed => _pageFailed;

  bool get loaded => _page > 0;
  bool get done => loaded && _clips.length >= _total;

  // -------- Select --------

  bool _selectMode = false;
  bool get selectMode => _selectMode;

  final Set<String> _selected = {};
  Set<String> get selected => Set.unmodifiable(_selected);

  bool get allSelected => _clips.isNotEmpty && _selected.length == _clips.length;

  /// Everything the screen shows: the header's totals, the days for the arrows, the first page.
  Future<void> load() => Future.wait([_loadStats(), _loadDates(), reset()]);

  Future<void> _loadStats() async {
    try {
      final s = (await _service.getStats(GetStatsRequest())).stats;
      _stats = RecordingsStats(totalCount: s.totalCount, totalBytes: s.totalSizeBytes.toInt());
      notifyListeners();
    } catch (_) {
      // The header says "…" until a later load.
    }
  }

  Future<void> _loadDates() async {
    try {
      _dates = List.of((await _service.getDates(GetDatesRequest())).dates)..sort();
      notifyListeners();
    } catch (_) {
      // The arrows step a day at a time instead.
    }
  }

  /// From the first page again: a filter changed, or the owner retried.
  Future<void> reset() {
    _generation++;
    _clips.clear();
    _seen.clear();
    _total = 0;
    _page = 0;
    _failed = false;
    _pageFailed = false;
    _loading = false;
    return more();
  }

  /// The next page, if there is one and none is on its way.
  Future<void> more() async {
    if (_loading || done) return;
    final generation = _generation;
    _loading = true;
    _pageFailed = false;
    notifyListeners();
    try {
      final r = await _service.listRecordings(ListRecordingsRequest(
        type: _type,
        date: _day ?? '',
        page: _page + 1,
        pageSize: pageSize,
        classFilter: _type == 'sentry' ? _actors.join(',') : '',
        severityFilter: _type == 'sentry' ? _severities.join(',') : '',
      ));
      if (generation != _generation) return;
      _page++;
      var added = 0;
      for (final e in r.recordings) {
        if (_seen.add(e.filename)) {
          _clips.add(RecordingItem.fromEntry(e));
          added++;
        }
      }
      // A page with nothing new -- empty, or only clips already here -- ends the list whatever
      // total says, so a total that runs ahead of the clips (deleted meanwhile) cannot ask for
      // pages forever.
      _total = added == 0 ? _clips.length : r.total;
      _failed = false;
    } catch (_) {
      if (generation != _generation) return;
      if (_page == 0) {
        _failed = true;
      } else {
        _pageFailed = true;
      }
    } finally {
      if (generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  void _filtersChanged() {
    if (_type != 'sentry') {
      _actors.clear();
      _severities.clear();
    }
    _selected.clear();
    unawaited(reset());
  }

  void setType(String type) {
    _type = type;
    _filtersChanged();
  }

  /// [day] as yyyy-MM-dd, or null for every day.
  void setDay(String? day) {
    _day = day;
    _filtersChanged();
  }

  void toggleActor(String name) {
    if (!_actors.remove(name)) _actors.add(name);
    _filtersChanged();
  }

  void toggleSeverity(String name) {
    if (!_severities.remove(name)) _severities.add(name);
    _filtersChanged();
  }

  void resetWhoAndSeverity() {
    _actors.clear();
    _severities.clear();
    _filtersChanged();
  }

  /// The next day before (-1) or after (+1) the one shown that has clips; one calendar day when
  /// the car's list of days is not known. Never past today; null when there is none.
  String? step(int direction) {
    final day = _day;
    if (day == null) return null;
    if (_dates.isNotEmpty) {
      final candidates = direction < 0 ? _dates.where((d) => d.compareTo(day) < 0) : _dates.where((d) => d.compareTo(day) > 0);
      if (candidates.isEmpty) return null;
      final next = direction < 0 ? candidates.last : candidates.first;
      return next.compareTo(todayKey) > 0 ? null : next;
    }
    final d = DateTime.parse(day);
    final next = dayKey(DateTime(d.year, d.month, d.day + direction));
    return next.compareTo(todayKey) > 0 ? null : next;
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

  /// Every loaded clip, or none if they already all are.
  void toggleSelectAll() {
    if (allSelected) {
      _selected.clear();
    } else {
      _selected
        ..clear()
        ..addAll(_clips.map((c) => c.filename));
    }
    notifyListeners();
  }

  // -------- Delete --------

  /// Deletes one clip; drops it from the list on success.
  Future<bool> deleteRecording(String filename) async {
    try {
      final r = await _service.deleteRecording(DeleteRecordingRequest(filename: filename));
      if (!r.success) return false;
      _drop([filename]);
      unawaited(_loadStats());
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Deletes the selected clips in one BatchDelete, as the companion does. The car does not say
  /// which ones failed: drop them all when none did, else reload from the first page.
  Future<BatchDeleteOutcome> deleteSelected() async {
    final names = List<String>.of(_selected);
    BatchDeleteOutcome outcome;
    try {
      final r = await _service.batchDelete(BatchDeleteRequest(filenames: names));
      outcome = BatchDeleteOutcome(deleted: r.deleted, failed: r.failed);
    } catch (_) {
      outcome = BatchDeleteOutcome(deleted: 0, failed: names.length);
    }
    _selectMode = false;
    _selected.clear();
    if (outcome.failed == 0) {
      _drop(names);
    } else {
      unawaited(reset());
    }
    unawaited(_loadStats());
    return outcome;
  }

  void _drop(List<String> names) {
    final gone = names.toSet();
    final before = _clips.length;
    _clips.removeWhere((c) => gone.contains(c.filename));
    _seen.removeAll(gone);
    _total -= before - _clips.length;
    notifyListeners();
  }
}
