import 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pb.dart';
import 'package:bladewatch_rpc/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_ui/screens/recordings/recordings_controller.dart';
import 'package:bladewatch_ui/screens/recordings/recordings_models.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';

Map<String, dynamic> entry(String filename, {String type = 'RECORDING_TYPE_NORMAL', int timestampMs = 1000}) => {
      'filename': filename,
      'path': '/storage/emulated/0/BladeWatch/recordings/$filename',
      'type': type,
      'timestamp': timestampMs.toString(),
      'size': '1500',
      'durationSeconds': '60',
    };

const _down = ConnectError('unavailable', 'down');

/// BladeWatch-rdtj.70: the library a page at a time, filtered by the car, as the companion does.
void main() {
  test('days are keyed as the car names them, yyyy-MM-dd: anything else filters to nothing', () {
    expect(RecordingsController.dayKey(DateTime(2026, 9, 7)), '2026-09-07');
  });

  late FakeRpcClient rpc;
  late RecordingsController c;
  final now = DateTime(2026, 5, 23, 15, 0).millisecondsSinceEpoch;

  void page(List<String> names, {int total = 0}) => rpc.stubJson('RecordingsService', 'ListRecordings', {
        'recordings': [for (final n in names) entry(n)],
        'total': total == 0 ? names.length : total,
      });

  List<ListRecordingsRequest> listCalls() =>
      [for (final call in rpc.calls.where((c) => c.method == 'ListRecordings')) call.request as ListRecordingsRequest];

  setUp(() {
    rpc = FakeRpcClient();
    rpc.stubJson('RecordingsService', 'GetStats', {
      'stats': {'totalCount': 1042, 'totalSizeBytes': '113100000000'},
    });
    rpc.stubJson('RecordingsService', 'GetDates', {
      'dates': ['2026-05-20', '2026-05-23', '2026-05-18'],
    });
    c = RecordingsController(recordingsService: RecordingsServiceClient(rpc), nowMs: () => now, pageSize: 2);
  });

  group('paging', () {
    test('load asks for the first page, every type and day, and the totals', () async {
      page(['a.mp4', 'b.mp4'], total: 5);
      await c.load();
      final r = listCalls().single;
      expect((r.type, r.date, r.page, r.pageSize, r.classFilter, r.severityFilter), ('', '', 1, 2, '', ''));
      expect(c.clips.map((i) => i.filename), ['a.mp4', 'b.mp4']);
      expect(c.loaded, isTrue);
      expect(c.done, isFalse, reason: '2 of 5');
      expect(c.stats!.totalCount, 1042);
      expect(c.stats!.totalBytes, 113100000000);
    });

    test('more fetches the next page, skips a clip seen twice, and ends at the total', () async {
      page(['a.mp4', 'b.mp4'], total: 3);
      await c.load();
      page(['b.mp4', 'c.mp4'], total: 3); // a new clip shifted the offsets by one
      await c.more();
      expect(listCalls().last.page, 2);
      expect(c.clips.map((i) => i.filename), ['a.mp4', 'b.mp4', 'c.mp4']);
      expect(c.done, isTrue);
      await c.more();
      expect(listCalls(), hasLength(2), reason: 'nothing more to ask for');
    });

    test('a page of clips already here ends the list too, so it never asks forever', () async {
      page(['a.mp4', 'b.mp4'], total: 9);
      await c.load();
      await c.more(); // the same two again
      expect(c.done, isTrue);
      await c.more();
      expect(listCalls(), hasLength(2));
    });

    test('an empty page ends the list even when the total runs ahead', () async {
      page(['a.mp4', 'b.mp4'], total: 9);
      await c.load();
      page([], total: 9);
      await c.more();
      expect(c.done, isTrue);
    });

    test('a failed first page is a failure; a failed later page keeps the clips for a retry', () async {
      rpc.stubError('RecordingsService', 'ListRecordings', _down);
      await c.load();
      expect(c.failed, isTrue);
      expect(c.loaded, isFalse);

      page(['a.mp4', 'b.mp4'], total: 4);
      await c.load();
      expect(c.failed, isFalse);
      rpc.stubError('RecordingsService', 'ListRecordings', _down);
      await c.more();
      expect(c.pageFailed, isTrue);
      expect(c.clips, hasLength(2));
      page(['c.mp4', 'd.mp4'], total: 4);
      await c.more();
      expect(c.pageFailed, isFalse);
      expect(c.clips, hasLength(4));
    });

    test('a page that answers after the filter changed is dropped', () async {
      final old = rpc.stubPending('RecordingsService', 'ListRecordings');
      final first = c.reset();
      page(['sentry.mp4']);
      c.setType('sentry');
      await Future<void>.delayed(Duration.zero);
      old.complete({
        'recordings': [entry('stale.mp4')],
        'total': 1,
      });
      await first;
      await Future<void>.delayed(Duration.zero);
      expect(c.clips.map((i) => i.filename), ['sentry.mp4']);
    });

    test('a failed stats or dates call leaves the list working', () async {
      rpc.stubError('RecordingsService', 'GetStats', _down);
      rpc.stubError('RecordingsService', 'GetDates', _down);
      page(['a.mp4']);
      await c.load();
      expect(c.stats, isNull);
      expect(c.clips, hasLength(1));
    });
  });

  group('filters are the car\'s', () {
    setUp(() => page(['a.mp4']));

    test('type and day go in the request and start from page 1', () async {
      await c.load();
      c.setType('proximity');
      await Future<void>.delayed(Duration.zero);
      c.setDay(c.yesterdayKey);
      await Future<void>.delayed(Duration.zero);
      final r = listCalls().last;
      expect((r.type, r.date, r.page), ('proximity', '2026-05-22', 1));
      c.setDay(null);
      await Future<void>.delayed(Duration.zero);
      expect(listCalls().last.date, '');
    });

    test('who and how bad are sent for sentry clips only, and cleared by another type', () async {
      await c.load();
      c.setType('sentry');
      c.toggleActor('person');
      c.toggleActor('vehicle');
      c.toggleSeverity('CRITICAL');
      await Future<void>.delayed(Duration.zero);
      var r = listCalls().last;
      expect((r.classFilter, r.severityFilter), ('person,vehicle', 'CRITICAL'));
      c.toggleActor('person');
      await Future<void>.delayed(Duration.zero);
      expect(listCalls().last.classFilter, 'vehicle');
      c.resetWhoAndSeverity();
      await Future<void>.delayed(Duration.zero);
      r = listCalls().last;
      expect((r.classFilter, r.severityFilter), ('', ''));

      c.toggleSeverity('ALERT');
      c.setType('normal');
      await Future<void>.delayed(Duration.zero);
      expect(c.severities, isEmpty);
      expect(listCalls().last.severityFilter, '');
    });

    test('a filter change drops the selection', () async {
      await c.load();
      c.enterSelectMode();
      c.toggleSelected('a.mp4');
      c.setType('normal');
      expect(c.selected, isEmpty);
    });
  });

  group('day arrows', () {
    setUp(() => page(['a.mp4']));

    test('today and yesterday come from the injected clock', () {
      expect(c.todayKey, '2026-05-23');
      expect(c.yesterdayKey, '2026-05-22');
      expect(RecordingsController.dayKey(DateTime(2026, 1, 2)), '2026-01-02');
    });

    test('with the car\'s days known, the arrows skip empty days and stop at today', () async {
      await c.load();
      expect(c.step(-1), isNull, reason: 'every day is shown: no arrows');
      c.setDay('2026-05-23');
      expect(c.step(-1), '2026-05-20');
      expect(c.step(1), isNull);
      c.setDay('2026-05-20');
      expect(c.step(-1), '2026-05-18');
      expect(c.step(1), '2026-05-23');
      c.setDay('2026-05-18');
      expect(c.step(-1), isNull);
    });

    test('without them, a calendar day at a time, never past today', () async {
      rpc.stubError('RecordingsService', 'GetDates', ConnectError('unimplemented', 'old car'));
      await c.load();
      c.setDay('2026-05-22');
      expect(c.step(-1), '2026-05-21');
      expect(c.step(1), '2026-05-23');
      c.setDay('2026-05-23');
      expect(c.step(1), isNull);
    });

    test('a day after today the car lists is still not offered', () async {
      rpc.stubJson('RecordingsService', 'GetDates', {
        'dates': ['2026-05-23', '2026-05-30'],
      });
      await c.load();
      c.setDay('2026-05-23');
      expect(c.step(1), isNull);
    });
  });

  group('select', () {
    setUp(() => page(['a.mp4', 'b.mp4']));

    test('toggle, all, none, and leaving select mode', () async {
      await c.load();
      c.enterSelectMode();
      expect(c.selectMode, isTrue);
      c.toggleSelected('a.mp4');
      expect(c.selected, {'a.mp4'});
      expect(c.allSelected, isFalse);
      c.toggleSelectAll();
      expect(c.selected, {'a.mp4', 'b.mp4'});
      expect(c.allSelected, isTrue);
      c.toggleSelectAll();
      expect(c.selected, isEmpty);
      c.toggleSelected('b.mp4');
      c.toggleSelected('b.mp4');
      expect(c.selected, isEmpty);
      c.toggleSelected('a.mp4');
      c.exitSelectMode();
      expect(c.selectMode, isFalse);
      expect(c.selected, isEmpty);
    });
  });

  group('delete', () {
    setUp(() => page(['a.mp4', 'b.mp4'], total: 2));

    test('one clip: gone from the list on success, kept on failure', () async {
      await c.load();
      rpc.stubJson('RecordingsService', 'DeleteRecording', {'success': true});
      expect(await c.deleteRecording('a.mp4'), isTrue);
      expect(c.clips.map((i) => i.filename), ['b.mp4']);
      expect(c.done, isTrue);

      rpc.stubJson('RecordingsService', 'DeleteRecording', {'success': false, 'error': 'busy'});
      expect(await c.deleteRecording('b.mp4'), isFalse);
      rpc.stubError('RecordingsService', 'DeleteRecording', _down);
      expect(await c.deleteRecording('b.mp4'), isFalse);
      expect(c.clips, hasLength(1));
    });

    test('the selection in one BatchDelete: dropped when all went, reloaded when some did not', () async {
      await c.load();
      c.enterSelectMode();
      c.toggleSelectAll();
      rpc.stubJson('RecordingsService', 'BatchDelete', {'deleted': 2, 'failed': 0});
      final all = await c.deleteSelected();
      expect((all.deleted, all.failed), (2, 0));
      expect((rpc.calls.lastWhere((x) => x.method == 'BatchDelete').request as BatchDeleteRequest).filenames, ['a.mp4', 'b.mp4']);
      expect(c.clips, isEmpty);
      expect(c.selectMode, isFalse);

      await c.load();
      c.enterSelectMode();
      c.toggleSelectAll();
      final before = listCalls().length;
      rpc.stubJson('RecordingsService', 'BatchDelete', {'deleted': 1, 'failed': 1});
      final some = await c.deleteSelected();
      expect((some.deleted, some.failed), (1, 1));
      await Future<void>.delayed(Duration.zero);
      expect(listCalls().length, before + 1, reason: 'which one failed is unknown: reload');
    });

    test('a BatchDelete that throws counts every clip as failed', () async {
      await c.load();
      c.enterSelectMode();
      c.toggleSelectAll();
      rpc.stubError('RecordingsService', 'BatchDelete', _down);
      final r = await c.deleteSelected();
      expect((r.deleted, r.failed), (0, 2));
    });
  });

  test('rows carry the entry\'s kind', () async {
    rpc.stubJson('RecordingsService', 'ListRecordings', {
      'recordings': [entry('event_1.mp4', type: 'RECORDING_TYPE_SENTRY')],
      'total': 1,
    });
    await c.load();
    expect(c.clips.single.kind, RecordingKind.sentry);
  });
}
