import 'package:bladewatch_ui/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_ui/screens/recordings/recordings_controller.dart';
import 'package:bladewatch_ui/screens/recordings/recordings_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_rpc_client.dart';

Map<String, dynamic> _entry({
  required String filename,
  required String type,
  int timestampMs = 1000,
  int sizeBytes = 500,
  int durationSeconds = 60,
  bool hasEvents = false,
  List<String> detectedClasses = const [],
  String severity = '',
  String proximity = '',
}) =>
    {
      'filename': filename,
      'path': '/storage/emulated/0/BladeWatch/recordings/$filename',
      'type': type,
      'timestamp': timestampMs.toString(),
      'size': sizeBytes.toString(),
      'durationSeconds': durationSeconds.toString(),
      'dateFormatted': 'May 23, 2026',
      'timeFormatted': '12:00:00 PM',
      'hasEvents': hasEvents,
      'detectedClasses': detectedClasses,
      'peakSeverity': severity,
      'peakProximity': proximity,
    };

void main() {
  late FakeRpcClient rpc;
  late RecordingsController controller;
  final now = DateTime(2026, 5, 23, 15, 0).millisecondsSinceEpoch;

  void stubStats({int total = 0, int recordings = 0, int surveillance = 0, int proximity = 0, int totalBytes = 0}) {
    rpc.stubJson('RecordingsService', 'GetStats', {
      'stats': {
        'recordingsSizeBytes': '0',
        'surveillanceSizeBytes': '0',
        'proximitySizeBytes': '0',
        'recordingsCount': recordings,
        'surveillanceCount': surveillance,
        'proximityCount': proximity,
        'totalSizeBytes': totalBytes.toString(),
        'totalCount': total,
      },
    });
  }

  setUp(() {
    rpc = FakeRpcClient();
    controller = RecordingsController(
      recordingsService: RecordingsServiceClient(rpc),
      nowMs: () => now,
    );
  });

  test('the real-clock default is used when nowMs is not overridden', () {
    final realClockController = RecordingsController(recordingsService: RecordingsServiceClient(rpc));
    expect(realClockController.filter.dateNarrowed, isTrue);
    expect(realClockController.filter.selectedDayMs, lessThanOrEqualTo(DateTime.now().millisecondsSinceEpoch));
  });

  test('nowMs exposes the injected clock', () {
    expect(controller.nowMs, now);
  });

  test('initial filter defaults to Dashcam, narrowed to today', () {
    expect(controller.filter.source, RecordingSource.dashcam);
    expect(controller.filter.dateNarrowed, isTrue);
    expect(controller.filter.selectedDayMs, DateTime(2026, 5, 23).millisecondsSinceEpoch);
  });

  test('initial state is loading, visible is empty', () {
    expect(controller.state, isA<RecordingsLoading>());
    expect(controller.visible, isEmpty);
  });

  group('load()', () {
    test('populates all recordings sorted newest-first and today/segment stats', () async {
      rpc.stubJson('RecordingsService', 'ListRecordings', {
        'recordings': [
          _entry(filename: 'cam_20260522_080000.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now - 86400000),
          _entry(filename: 'cam_20260523_080000.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now),
        ],
      });
      stubStats(total: 10, recordings: 6, surveillance: 3, proximity: 1, totalBytes: 123456);

      await controller.load();

      expect(controller.state, isA<RecordingsLoaded>());
      final loaded = controller.state as RecordingsLoaded;
      expect(loaded.all.map((r) => r.filename), ['cam_20260523_080000.mp4', 'cam_20260522_080000.mp4']);
      expect(loaded.stats.totalCount, 10);
      expect(loaded.stats.dashcamCount, 7, reason: 'recordingsCount + proximityCount');
      expect(loaded.stats.surveillanceCount, 3);
      expect(loaded.stats.totalBytes, 123456);
      expect(loaded.stats.todayCount, 1, reason: 'only the clip timestamped "now" falls in the local today window');
    });

    test('maps every RecordingType to the right RecordingKind', () async {
      rpc.stubJson('RecordingsService', 'ListRecordings', {
        'recordings': [
          _entry(filename: 'a.mp4', type: 'RECORDING_TYPE_NORMAL'),
          _entry(filename: 'b.mp4', type: 'RECORDING_TYPE_SENTRY'),
          _entry(filename: 'c.mp4', type: 'RECORDING_TYPE_PROXIMITY'),
        ],
      });
      stubStats();
      await controller.load();
      final loaded = controller.state as RecordingsLoaded;
      final byName = {for (final r in loaded.all) r.filename: r.kind};
      expect(byName['a.mp4'], RecordingKind.normal);
      expect(byName['b.mp4'], RecordingKind.sentry);
      expect(byName['c.mp4'], RecordingKind.proximity);
    });

    test('empty severity/proximity strings become null, not empty strings', () async {
      rpc.stubJson('RecordingsService', 'ListRecordings', {
        'recordings': [_entry(filename: 'a.mp4', type: 'RECORDING_TYPE_NORMAL')],
      });
      stubStats();
      await controller.load();
      final loaded = controller.state as RecordingsLoaded;
      expect(loaded.all.single.severity, isNull);
      expect(loaded.all.single.proximity, isNull);
    });

    test('a populated severity/proximity/detectedClasses round-trips', () async {
      rpc.stubJson('RecordingsService', 'ListRecordings', {
        'recordings': [
          _entry(
            filename: 'a.mp4',
            type: 'RECORDING_TYPE_SENTRY',
            severity: 'ALERT',
            proximity: 'CLOSE',
            detectedClasses: ['person', 'vehicle'],
            hasEvents: true,
          ),
        ],
      });
      stubStats();
      await controller.load();
      final rec = (controller.state as RecordingsLoaded).all.single;
      expect(rec.severity, 'ALERT');
      expect(rec.proximity, 'CLOSE');
      expect(rec.detectedClasses, ['person', 'vehicle']);
      expect(rec.hasEvents, isTrue);
    });

    test('an RPC failure surfaces RecordingsError, not an uncaught throw', () async {
      rpc.stubError('RecordingsService', 'ListRecordings', const ConnectError('unavailable', 'no daemon'));
      stubStats();
      await controller.load();
      expect(controller.state, isA<RecordingsError>());
    });

    test('visible reflects the loaded list through the current filter', () async {
      rpc.stubJson('RecordingsService', 'ListRecordings', {
        'recordings': [
          _entry(filename: 'a.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now),
          _entry(filename: 'b.mp4', type: 'RECORDING_TYPE_SENTRY', timestampMs: now),
        ],
      });
      stubStats();
      await controller.load();
      expect(controller.visible.map((r) => r.filename), ['a.mp4']);
    });
  });

  group('segment + date navigation', () {
    test('setSource switches the segment without reloading', () async {
      controller.setSource(RecordingSource.surveillance);
      expect(controller.filter.source, RecordingSource.surveillance);
      expect(rpc.calls, isEmpty);
    });

    test('setSource exits select mode', () {
      controller.enterSelectMode();
      controller.setSource(RecordingSource.surveillance);
      expect(controller.selectMode, isFalse);
    });

    test('setDateNarrowed(false) shows all days', () {
      controller.setDateNarrowed(false);
      expect(controller.filter.dateNarrowed, isFalse);
    });

    test('goYesterday narrows to the day before today', () {
      controller.goYesterday();
      expect(controller.filter.dateNarrowed, isTrue);
      expect(controller.filter.selectedDayMs, DateTime(2026, 5, 22).millisecondsSinceEpoch);
    });

    test('goToday narrows back to today', () {
      controller.goYesterday();
      controller.goToday();
      expect(controller.filter.selectedDayMs, DateTime(2026, 5, 23).millisecondsSinceEpoch);
    });

    test('shiftDay(-1) moves one day back', () {
      controller.shiftDay(-1);
      expect(controller.filter.selectedDayMs, DateTime(2026, 5, 22).millisecondsSinceEpoch);
    });

    test('shiftDay(+1) is clamped at today, cannot go into the future', () {
      controller.shiftDay(1);
      expect(controller.filter.selectedDayMs, DateTime(2026, 5, 23).millisecondsSinceEpoch);
    });

    test('pickDate narrows to the given day, normalized to local midnight', () {
      controller.pickDate(DateTime(2026, 1, 5, 18, 30).millisecondsSinceEpoch);
      expect(controller.filter.selectedDayMs, DateTime(2026, 1, 5).millisecondsSinceEpoch);
      expect(controller.filter.dateNarrowed, isTrue);
    });
  });

  group('chip filters', () {
    test('toggleActorClass adds then removes', () {
      controller.toggleActorClass('person');
      expect(controller.filter.actorClasses, {'person'});
      controller.toggleActorClass('person');
      expect(controller.filter.actorClasses, isEmpty);
    });

    test('toggleSeverity adds then removes', () {
      controller.toggleSeverity('ALERT');
      expect(controller.filter.severities, {'ALERT'});
      controller.toggleSeverity('ALERT');
      expect(controller.filter.severities, isEmpty);
    });

    test('toggleDashcamType adds then removes', () {
      controller.toggleDashcamType('NORMAL');
      expect(controller.filter.dashcamTypes, {'NORMAL'});
      controller.toggleDashcamType('NORMAL');
      expect(controller.filter.dashcamTypes, isEmpty);
    });

    test('resetActorClasses clears only the actor row', () {
      controller.toggleActorClass('person');
      controller.toggleSeverity('ALERT');
      controller.resetActorClasses();
      expect(controller.filter.actorClasses, isEmpty);
      expect(controller.filter.severities, {'ALERT'});
    });

    test('resetSeverities clears only the severity row', () {
      controller.toggleActorClass('person');
      controller.toggleSeverity('ALERT');
      controller.resetSeverities();
      expect(controller.filter.severities, isEmpty);
      expect(controller.filter.actorClasses, {'person'});
    });

    test('resetChips clears every chip dimension', () {
      controller.toggleActorClass('person');
      controller.toggleSeverity('ALERT');
      controller.toggleDashcamType('NORMAL');
      controller.resetChips();
      expect(controller.filter.actorClasses, isEmpty);
      expect(controller.filter.severities, isEmpty);
      expect(controller.filter.dashcamTypes, isEmpty);
    });
  });

  group('multi-select', () {
    Future<void> loadTwo() async {
      rpc.stubJson('RecordingsService', 'ListRecordings', {
        'recordings': [
          _entry(filename: 'a.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now),
          _entry(filename: 'b.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now),
        ],
      });
      stubStats();
      await controller.load();
    }

    test('enterSelectMode/exitSelectMode toggle state and clear selection', () {
      controller.enterSelectMode();
      expect(controller.selectMode, isTrue);
      controller.toggleSelected('a.mp4');
      controller.exitSelectMode();
      expect(controller.selectMode, isFalse);
      expect(controller.selected, isEmpty);
    });

    test('toggleSelected adds then removes a filename', () {
      controller.toggleSelected('a.mp4');
      expect(controller.selected, {'a.mp4'});
      controller.toggleSelected('a.mp4');
      expect(controller.selected, isEmpty);
    });

    test('selectAllVisible selects every visible item, then deselects all on a second call', () async {
      await loadTwo();
      controller.selectAllVisible();
      expect(controller.selected, {'a.mp4', 'b.mp4'});
      controller.selectAllVisible();
      expect(controller.selected, isEmpty);
    });

    test('selectAllVisible only selects the currently filtered subset', () async {
      rpc.stubJson('RecordingsService', 'ListRecordings', {
        'recordings': [
          _entry(filename: 'a.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now),
          _entry(filename: 'b.mp4', type: 'RECORDING_TYPE_SENTRY', timestampMs: now),
        ],
      });
      stubStats();
      await controller.load();
      controller.selectAllVisible();
      expect(controller.selected, {'a.mp4'});
    });
  });

  group('delete', () {
    test('deleteRecording removes the item from state on success', () async {
      rpc.stubJson('RecordingsService', 'ListRecordings', {
        'recordings': [_entry(filename: 'a.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now)],
      });
      stubStats();
      await controller.load();

      rpc.stubJson('RecordingsService', 'DeleteRecording', {'success': true});
      final ok = await controller.deleteRecording('a.mp4');

      expect(ok, isTrue);
      expect((controller.state as RecordingsLoaded).all, isEmpty);
    });

    test('deleteRecording leaves state untouched on failure', () async {
      rpc.stubJson('RecordingsService', 'ListRecordings', {
        'recordings': [_entry(filename: 'a.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now)],
      });
      stubStats();
      await controller.load();

      rpc.stubJson('RecordingsService', 'DeleteRecording', {'success': false, 'error': 'locked'});
      final ok = await controller.deleteRecording('a.mp4');

      expect(ok, isFalse);
      expect((controller.state as RecordingsLoaded).all, hasLength(1));
    });

    test('deleteRecording returns false and does not throw on an RPC exception', () async {
      rpc.stubError('RecordingsService', 'DeleteRecording', const ConnectError('unavailable', 'x'));
      expect(await controller.deleteRecording('a.mp4'), isFalse);
    });

    Future<void> loadTwoForDelete() async {
      rpc.stubJson('RecordingsService', 'ListRecordings', {
        'recordings': [
          _entry(filename: 'a.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now),
          _entry(filename: 'b.mp4', type: 'RECORDING_TYPE_NORMAL', timestampMs: now),
        ],
      });
      stubStats();
      await controller.load();
      controller.toggleSelected('a.mp4');
      controller.toggleSelected('b.mp4');
    }

    test('deleteSelected loops individual deletes, tallies successes, and exits select mode', () async {
      await loadTwoForDelete();
      rpc.stubJson('RecordingsService', 'DeleteRecording', {'success': true});

      final outcome = await controller.deleteSelected();

      expect(outcome.deleted, 2);
      expect(outcome.failed, 0);
      expect(controller.selectMode, isFalse);
      expect(controller.selected, isEmpty);
      expect((controller.state as RecordingsLoaded).all, isEmpty);
      final deleteCalls = rpc.calls.where((c) => c.method == 'DeleteRecording');
      expect(deleteCalls, hasLength(2));
    });

    test('deleteSelected tallies failures without removing anything from state', () async {
      await loadTwoForDelete();
      rpc.stubJson('RecordingsService', 'DeleteRecording', {'success': false, 'error': 'locked'});

      final outcome = await controller.deleteSelected();

      expect(outcome.deleted, 0);
      expect(outcome.failed, 2);
      expect((controller.state as RecordingsLoaded).all, hasLength(2));
    });
  });
}
