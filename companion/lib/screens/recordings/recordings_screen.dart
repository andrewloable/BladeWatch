import 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pb.dart';
import 'package:bladewatch_rpc/rpc/services/recordings_service_client.dart';
import 'package:flutter/material.dart';

import '../../car/car_page.dart';
import '../../i18n.dart';
import '../common/format.dart';
import '../common/loader.dart';
import 'clips.dart';

/// The web recording library's counterpart: every clip on the car, filterable by type, with
/// storage totals, playback and delete.
class RecordingsScreen extends StatefulWidget {
  const RecordingsScreen({super.key});

  /// ListRecordings' `type` filter values, as the car names them ('' is everything).
  static const types = ['', 'normal', 'sentry', 'proximity'];

  @override
  State<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends State<RecordingsScreen> with LoadersState {
  late final _client = RecordingsServiceClient(context.session.rpc);
  var _type = '';
  late final _stats = loader(() => _client.getStats(GetStatsRequest()));
  late final _list = loader(() => _client.listRecordings(ListRecordingsRequest(type: _type, pageSize: 200)));

  void _filter(String type) {
    setState(() => _type = type);
    _list.load();
  }

  Future<void> _delete(RecordingEntry clip) async {
    final tr = context.tr;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(tr('events.confirm_delete_one', {'filename': clip.filename})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(tr('common.cancel'))),
          FilledButton(key: const ValueKey('delete.confirm'), onPressed: () => Navigator.pop(context, true), child: Text(tr('common.delete'))),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    final ok = await act(context, () async {
      final r = await _client.deleteRecording(DeleteRecordingRequest(filename: clip.filename));
      if (!r.success) throw StateError(r.error);
    }, done: tr('events.toast_deleted'), failed: tr('events.alert_delete_failed_generic'));
    if (ok) await Future.wait([_list.load(), _stats.load()]);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final labels = [tr('events.all'), tr('events.badge_normal'), tr('events.badge_sentry'), tr('events.badge_proximity')];
    return Column(children: [
      ListenableBuilder(
        listenable: _stats,
        builder: (context, _) {
          final s = _stats.value?.stats;
          return s == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(
                    '${tr('events.video_count.other', {'count': s.totalCount})} · ${Fmt.bytes(s.totalSizeBytes.toInt())}',
                    key: const ValueKey('rec.stats'),
                  ),
                );
        },
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        child: Wrap(spacing: 8, children: [
          for (var i = 0; i < RecordingsScreen.types.length; i++)
            ChoiceChip(
              key: ValueKey('rec.type.${RecordingsScreen.types[i]}'),
              label: Text(labels[i]),
              selected: _type == RecordingsScreen.types[i],
              onSelected: (_) => _filter(RecordingsScreen.types[i]),
            ),
        ]),
      ),
      Expanded(
        child: LoaderView(
          loader: _list,
          builder: (context, r) => r.recordings.isEmpty
              ? ListView(children: [
                  Padding(padding: const EdgeInsets.all(32), child: Text(tr('events.empty_none_title'), textAlign: TextAlign.center)),
                ])
              : ListView(children: [for (final c in r.recordings) ClipTile(clip: c, onDelete: () => _delete(c))]),
        ),
      ),
    ]);
  }
}
