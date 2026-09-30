import 'dart:async';

import 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pb.dart';
import 'package:bladewatch_rpc/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_theme/dimens_tokens.dart';
import 'package:bladewatch_theme/hud_theme.dart';
import 'package:bladewatch_theme/hud_widgets.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../car/car_page.dart';
import '../../i18n.dart';
import '../common/format.dart';
import '../common/hud_style.dart';
import '../common/loader.dart';
import 'clip_pages.dart';

/// The web recording library's counterpart: every clip on the car, filterable by type and day,
/// with storage totals, playback and delete. Clips arrive a page at a time (BladeWatch-rdtj.42).
class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key, this.today});

  /// ListRecordings' `type` filter values, as the car names them ('' is everything).
  static const types = ['', 'normal', 'sentry', 'proximity'];

  /// Test seam: the date "today" is.
  final DateTime Function()? today;

  /// ListRecordings' and GetDates' day format.
  /// yyyy-MM-dd, as the car names days in GetDates and filters ListRecordings by. It refuses any
  /// other form with an empty list, which is how yyyyMMdd left Today and Yesterday empty.
  static String dayKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> with LoadersState {
  late final _client = RecordingsServiceClient(context.session.rpc);
  var _type = '';

  /// The day shown, as the car names days (yyyy-MM-dd); null is every day.
  String? _day;
  late final _stats = loader(() => _client.getStats(GetStatsRequest()));
  // Days with at least one clip, so the arrows skip empty ones. Without them (an older car, or
  // the call failed) the arrows step a day at a time.
  late final _dates = loader(() => _client.getDates(GetDatesRequest()));
  late final _pages = ClipPages((page, size) => _client.listRecordings(ListRecordingsRequest(
        type: _type,
        date: _day ?? '',
        page: page,
        pageSize: size,
        // Who and how bad, for surveillance clips only, as the web offers (BladeWatch-rdtj.43).
        // The car filters, so paging stays right.
        classFilter: _type == 'sentry' ? _actors.join(',') : '',
        severityFilter: _type == 'sentry' ? _severities.join(',') : '',
      )))
    ..more();

  /// ListRecordings' class_filter and severity_filter values, as the car names them.
  static const actors = ['person', 'vehicle', 'bike', 'animal'];
  static const severities = ['ALERT', 'CRITICAL'];
  final _actors = <String>{};
  final _severities = <String>{};

  /// Ticked filenames while picking clips to delete together; null when not picking.
  Set<String>? _picked;

  DateTime get _now => (widget.today ?? DateTime.now)();
  String get _todayKey => RecordingsScreen.dayKey(_now);
  String get _yesterdayKey => RecordingsScreen.dayKey(_now.subtract(const Duration(days: 1)));

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _filter({String? type, String? day, bool allDays = false, void Function()? change}) {
    setState(() {
      if (type != null) _type = type;
      if (day != null || allDays) _day = day;
      change?.call();
      if (_type != 'sentry') {
        _actors.clear();
        _severities.clear();
      }
      if (_picked != null) _picked = {};
    });
    _pages.reset();
  }

  Future<void> _deletePicked() async {
    final tr = context.tr;
    final names = _picked!.toList();
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(tr('companion.delete_selected_confirm', {'count': names.length})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('common.cancel'))),
          FilledButton(
            key: const ValueKey('delete.confirm'),
            style: destructiveStyle(context),
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('common.delete')),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    BatchDeleteResponse? result;
    final ok = await act(context, () async {
      result = await _client.batchDelete(BatchDeleteRequest(filenames: names));
    }, failed: tr('events.alert_delete_failed_generic'));
    final r = result;
    if (!ok || r == null || !mounted) return;
    say(
      ScaffoldMessenger.of(context),
      r.failed == 0
          ? tr('companion.batch_deleted', {'count': r.deleted})
          : tr('companion.batch_delete_partial', {'deleted': r.deleted, 'failed': r.failed}),
    );
    setState(() => _picked = null);
    // The car does not say which ones failed: drop them all when none did, else reload.
    if (r.failed == 0) {
      names.forEach(_pages.remove);
    } else {
      unawaited(_pages.reset());
    }
    await _stats.load();
  }

  Widget _filters(BuildContext context) {
    final tr = context.tr;
    final names = {
      'person': tr('surveillance.person'),
      'vehicle': tr('dashboard.vehicle'),
      'bike': tr('surveillance.bike'),
      'animal': tr('companion.actor_animal'),
      'ALERT': tr('companion.sev_alert'),
      'CRITICAL': tr('companion.sev_critical'),
    };
    Widget row(String label, List<String> values, Set<String> chosen) => Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelMedium),
            for (final v in values)
              FilterChip(
                key: ValueKey('rec.filter.$v'),
                label: Text(names[v]!),
                selected: chosen.contains(v),
                onSelected: (on) => _filter(change: () => on ? chosen.add(v) : chosen.remove(v)),
              ),
          ],
        );
    return Padding(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        row(tr('companion.filter_who'), actors, _actors),
        row(tr('companion.filter_severity'), severities, _severities),
        if (_actors.isNotEmpty || _severities.isNotEmpty)
          ActionChip(
            key: const ValueKey('rec.filter.reset'),
            label: Text(tr('dashboard.reset')),
            onPressed: () => _filter(change: () {
              _actors.clear();
              _severities.clear();
            }),
          ),
      ]),
    );
  }

  Widget _selectBar(BuildContext context) {
    final tr = context.tr;
    final picked = _picked;
    if (picked == null) {
      return Align(
        alignment: AlignmentDirectional.centerEnd,
        child: TextButton(key: const ValueKey('rec.select'), onPressed: () => setState(() => _picked = {}), child: Text(tr('companion.select'))),
      );
    }
    final all = picked.length == _pages.clips.length && picked.isNotEmpty;
    return Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
      Text(tr('companion.selected_count', {'count': picked.length}), key: const ValueKey('rec.picked')),
      TextButton(
        key: const ValueKey('rec.select_all'),
        onPressed: () => setState(() => _picked = all ? {} : {for (final c in _pages.clips) c.filename}),
        child: Text(tr(all ? 'companion.deselect_all' : 'companion.select_all')),
      ),
      FilledButton.tonal(
        key: const ValueKey('rec.delete_picked'),
        style: destructiveStyle(context),
        onPressed: picked.isEmpty ? null : _deletePicked,
        child: Text(tr('common.delete')),
      ),
      TextButton(key: const ValueKey('rec.select_cancel'), onPressed: () => setState(() => _picked = null), child: Text(tr('common.cancel'))),
    ]);
  }

  /// The next day before (-1) or after (+1) the one shown that has clips; one calendar day when
  /// the car's list of days is not known. Never past today.
  String? _step(int direction) {
    final day = _day;
    if (day == null) return null;
    final known = (_dates.value?.dates ?? const <String>[]).toList()..sort();
    if (known.isNotEmpty) {
      final candidates = direction < 0 ? known.where((d) => d.compareTo(day) < 0) : known.where((d) => d.compareTo(day) > 0);
      if (candidates.isEmpty) return null;
      final next = direction < 0 ? candidates.last : candidates.first;
      return next.compareTo(_todayKey) > 0 ? null : next;
    }
    final d = DateTime.parse(day).add(Duration(days: direction));
    final next = RecordingsScreen.dayKey(d);
    return next.compareTo(_todayKey) > 0 ? null : next;
  }

  Future<void> _delete(RecordingEntry clip) async {
    final tr = context.tr;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(tr('events.confirm_delete_one', {'filename': clip.filename})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('common.cancel'))),
          FilledButton(
            key: const ValueKey('delete.confirm'),
            style: destructiveStyle(context),
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr('common.delete')),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    final ok = await act(context, () async {
      final r = await _client.deleteRecording(DeleteRecordingRequest(filename: clip.filename));
      if (!r.success) throw StateError(r.error);
    }, done: tr('events.toast_deleted'), failed: tr('events.alert_delete_failed_generic'));
    if (ok) {
      _pages.remove(clip.filename);
      await _stats.load();
    }
  }

  Widget _days(BuildContext context) {
    final tr = context.tr;
    final day = _day;
    final previous = _step(-1);
    final next = _step(1);
    return Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
      ChoiceChip(
        showCheckmark: false,
        key: const ValueKey('rec.day.today'),
        label: Text(tr('recording.today')),
        selected: day == _todayKey,
        onSelected: (_) => _filter(day: _todayKey),
      ),
      ChoiceChip(
        showCheckmark: false,
        key: const ValueKey('rec.day.yesterday'),
        label: Text(tr('recording.yesterday')),
        selected: day == _yesterdayKey,
        onSelected: (_) => _filter(day: _yesterdayKey),
      ),
      ChoiceChip(
        showCheckmark: false,
        key: const ValueKey('rec.day.all'),
        label: Text(tr('events.all')),
        selected: day == null,
        onSelected: (_) => _filter(allDays: true),
      ),
      if (day != null)
        Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            key: const ValueKey('rec.day.previous'),
            tooltip: tr('recording.previous_day'),
            onPressed: previous == null ? null : () => _filter(day: previous),
            icon: const Icon(Icons.chevron_left),
          ),
          Text(DateFormat.yMMMd(tr.lang).format(DateTime.parse(day)), key: const ValueKey('rec.day.label')),
          IconButton(
            key: const ValueKey('rec.day.next'),
            tooltip: tr('recording.next_day'),
            onPressed: next == null ? null : () => _filter(day: next),
            icon: const Icon(Icons.chevron_right),
          ),
        ]),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final labels = [tr('events.all'), tr('events.badge_normal'), tr('events.badge_sentry'), tr('events.badge_proximity')];
    // Rows as wide as the page's content, not the window (BladeWatch-rdtj.56).
    final hud = BwHud.of(context);
    return Padding(padding: const EdgeInsets.symmetric(horizontal: BwDimens.pagePaddingHorizontal), child: ContentWidth(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ListenableBuilder(
        listenable: _stats,
        builder: (context, _) {
          final s = _stats.value?.stats;
          return s == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${tr('events.video_count.other', {'count': s.totalCount})} · ${Fmt.bytes(s.totalSizeBytes.toInt())}',
                    key: const ValueKey('rec.stats'),
                    style: hudText(12, hud.textSecondary, lineHeight: 16, em: 0.05),
                  ),
                );
        },
      ),
      // A Wrap, not a sideways scroll: on a phone the fourth chip used to be cut off at the edge with nothing to say it scrolls.
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (var i = 0; i < RecordingsScreen.types.length; i++)
            ChoiceChip(
              showCheckmark: false,
              key: ValueKey('rec.type.${RecordingsScreen.types[i]}'),
              label: Text(labels[i]),
              selected: _type == RecordingsScreen.types[i],
              onSelected: (_) => _filter(type: RecordingsScreen.types[i]),
            ),
        ]),
      ),
      ListenableBuilder(listenable: _dates, builder: (context, _) => _days(context)),
      if (_type == 'sentry') _filters(context),
      ListenableBuilder(listenable: _pages, builder: (context, _) => _pages.clips.isEmpty && _picked == null ? const SizedBox.shrink() : _selectBar(context)),
      Expanded(
        child: ClipPageList(
          pages: _pages,
          onDelete: _delete,
          selection: _picked,
          onToggle: (name, on) => setState(() => on ? _picked!.add(name) : _picked!.remove(name)),
        ),
      ),
    ])));
  }
}
