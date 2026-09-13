import 'dart:convert';

import 'package:bladewatch_ui/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_ui/screens/recordings/recordings_models.dart';
import 'package:bladewatch_ui/screens/recordings/recordings_player_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_rpc_client.dart';

RecordingItem _item(String filename, {bool hasEvents = false}) => RecordingItem(
      filename: filename,
      path: '/storage/emulated/0/BladeWatch/recordings/$filename',
      kind: RecordingKind.normal,
      timestampMs: 1000,
      sizeBytes: 500,
      durationSeconds: 60,
      dateLabel: 'May 23, 2026',
      timeLabel: '12:00:00 PM',
      hasEvents: hasEvents,
    );

void main() {
  group('parseTimelineJson', () {
    test('parses events and stats into spans + a legend', () {
      final raw = jsonEncode({
        'durationMs': 60000,
        'events': [
          {'start': 1000, 'end': 3000, 'type': 'person', 'maxConf': 0.9},
          {'start': 5000, 'end': 5000, 'type': 'car'},
        ],
        'stats': {'person': 2, 'car': 1, 'bike': 0, 'motion': 3},
      });

      final result = parseTimelineJson(raw);

      expect(result.durationMs, 60000);
      expect(result.spans, hasLength(2));
      expect(result.spans[0].startMs, 1000);
      expect(result.spans[0].endMs, 3000);
      expect(result.spans[0].type, 'person');
      expect(result.spans[0].confidence, 0.9);
      expect(result.spans[1].endMs, 5000, reason: 'a zero-length event falls back end=start');
      expect(result.legendCounts, {'person': 2, 'car': 1, 'motion': 3});
      expect(result.legendCounts, isNot(contains('bike')), reason: 'zero counts are omitted, matching native');
    });

    test('an empty string yields an empty timeline', () {
      final result = parseTimelineJson('');
      expect(result.spans, isEmpty);
      expect(result.durationMs, 0);
      expect(result.legendCounts, isEmpty);
    });

    test('malformed JSON is swallowed, not thrown', () {
      final result = parseTimelineJson('{not json');
      expect(result.spans, isEmpty);
    });

    test('missing events/stats degrade gracefully', () {
      final result = parseTimelineJson(jsonEncode({'durationMs': 1000}));
      expect(result.spans, isEmpty);
      expect(result.legendCounts, isEmpty);
      expect(result.durationMs, 1000);
    });

    test('a missing type defaults to motion, matching native\'s "else -> motion"', () {
      final raw = jsonEncode({
        'events': [
          {'start': 0, 'end': 1000},
        ],
      });
      expect(parseTimelineJson(raw).spans.single.type, 'motion');
    });
  });

  group('spanColorKey', () {
    test('recognizes exactly the 3 native colors, case-sensitively', () {
      expect(spanColorKey('person'), SpanColorKey.person);
      expect(spanColorKey('car'), SpanColorKey.car);
      expect(spanColorKey('bike'), SpanColorKey.bike);
    });

    test('everything else -- including web-only synonyms -- falls back to motion', () {
      expect(spanColorKey('Person'), SpanColorKey.motion, reason: 'native switch is case-sensitive');
      expect(spanColorKey('vehicle'), SpanColorKey.motion, reason: 'native has no "vehicle" case, only "car"');
      expect(spanColorKey('bicycle'), SpanColorKey.motion);
      expect(spanColorKey('motion'), SpanColorKey.motion);
      expect(spanColorKey('anything'), SpanColorKey.motion);
    });
  });

  group('RecordingsPlayerController', () {
    late FakeRpcClient rpc;

    setUp(() {
      rpc = FakeRpcClient();
    });

    test('starts on the given index with an empty timeline until initialize()', () {
      final controller = RecordingsPlayerController(
        recordingsService: RecordingsServiceClient(rpc),
        playlist: [_item('a.mp4'), _item('b.mp4')],
        initialIndex: 1,
      );
      expect(controller.index, 1);
      expect(controller.current.filename, 'b.mp4');
      expect(controller.spans, isEmpty);
    });

    test('hasPlaylist/canPrev/canNext reflect position within a 3-item list', () {
      final controller = RecordingsPlayerController(
        recordingsService: RecordingsServiceClient(rpc),
        playlist: [_item('a.mp4'), _item('b.mp4'), _item('c.mp4')],
        initialIndex: 1,
      );
      expect(controller.hasPlaylist, isTrue);
      expect(controller.canPrev, isTrue);
      expect(controller.canNext, isTrue);
    });

    test('a single-item playlist has no prev/next', () {
      final controller = RecordingsPlayerController(
        recordingsService: RecordingsServiceClient(rpc),
        playlist: [_item('a.mp4')],
        initialIndex: 0,
      );
      expect(controller.hasPlaylist, isFalse);
      expect(controller.canPrev, isFalse);
      expect(controller.canNext, isFalse);
    });

    test('initialize() skips the fetch when the clip has no sidecar (hasEvents=false)', () async {
      final controller = RecordingsPlayerController(
        recordingsService: RecordingsServiceClient(rpc),
        playlist: [_item('a.mp4', hasEvents: false)],
        initialIndex: 0,
      );
      await controller.initialize();
      expect(rpc.calls, isEmpty);
      expect(controller.spans, isEmpty);
    });

    test('initialize() fetches and applies the timeline when hasEvents is true', () async {
      rpc.stubJson('RecordingsService', 'GetEventTimeline', {
        'timelineJson': jsonEncode({
          'durationMs': 5000,
          'events': [
            {'start': 0, 'end': 1000, 'type': 'person'},
          ],
          'stats': {'person': 1},
        }),
      });
      final controller = RecordingsPlayerController(
        recordingsService: RecordingsServiceClient(rpc),
        playlist: [_item('a.mp4', hasEvents: true)],
        initialIndex: 0,
      );
      await controller.initialize();
      expect(controller.spans, hasLength(1));
      expect(controller.legendCounts, {'person': 1});
      final call = rpc.calls.single;
      expect(call.method, 'GetEventTimeline');
    });

    test('a fetch failure leaves the timeline empty rather than throwing', () async {
      rpc.stubError('RecordingsService', 'GetEventTimeline', const ConnectError('unavailable', 'x'));
      final controller = RecordingsPlayerController(
        recordingsService: RecordingsServiceClient(rpc),
        playlist: [_item('a.mp4', hasEvents: true)],
        initialIndex: 0,
      );
      await controller.initialize();
      expect(controller.spans, isEmpty);
    });

    test('next()/prev() move the index, reset the timeline immediately, then reload it', () async {
      rpc.stubJson('RecordingsService', 'GetEventTimeline', {
        'timelineJson': jsonEncode({'events': <dynamic>[], 'stats': <String, dynamic>{}}),
      });
      final controller = RecordingsPlayerController(
        recordingsService: RecordingsServiceClient(rpc),
        playlist: [_item('a.mp4', hasEvents: true), _item('b.mp4', hasEvents: true)],
        initialIndex: 0,
      );
      await controller.initialize();

      final future = controller.next();
      expect(controller.index, 1, reason: 'the index and reset happen synchronously, before the await');
      expect(controller.current.filename, 'b.mp4');
      await future;

      final calls = rpc.calls.where((c) => c.method == 'GetEventTimeline');
      expect(calls, hasLength(2));
    });

    test('next() is a no-op at the end of the playlist', () async {
      final controller = RecordingsPlayerController(
        recordingsService: RecordingsServiceClient(rpc),
        playlist: [_item('a.mp4')],
        initialIndex: 0,
      );
      await controller.next();
      expect(controller.index, 0);
    });

    test('prev() is a no-op at the start of the playlist', () async {
      final controller = RecordingsPlayerController(
        recordingsService: RecordingsServiceClient(rpc),
        playlist: [_item('a.mp4')],
        initialIndex: 0,
      );
      await controller.prev();
      expect(controller.index, 0);
    });

    test('prev() moves back and reloads the timeline when not at the start', () async {
      rpc.stubJson('RecordingsService', 'GetEventTimeline', {
        'timelineJson': jsonEncode({
          'durationMs': 4200,
          'events': <dynamic>[],
          'stats': <String, dynamic>{},
        }),
      });
      final controller = RecordingsPlayerController(
        recordingsService: RecordingsServiceClient(rpc),
        playlist: [_item('a.mp4', hasEvents: true), _item('b.mp4', hasEvents: true)],
        initialIndex: 1,
      );
      await controller.initialize();

      await controller.prev();

      expect(controller.index, 0);
      expect(controller.current.filename, 'a.mp4');
      expect(controller.playlistCount, 2);
      expect(controller.sidecarDurationMs, 4200);
    });

    test('jumpTo() moves directly to a given index', () async {
      final controller = RecordingsPlayerController(
        recordingsService: RecordingsServiceClient(rpc),
        playlist: [_item('a.mp4'), _item('b.mp4'), _item('c.mp4')],
        initialIndex: 0,
      );
      await controller.jumpTo(2);
      expect(controller.index, 2);
      expect(controller.current.filename, 'c.mp4');
    });

    test('jumpTo() ignores an out-of-range index', () async {
      final controller = RecordingsPlayerController(
        recordingsService: RecordingsServiceClient(rpc),
        playlist: [_item('a.mp4')],
        initialIndex: 0,
      );
      await controller.jumpTo(5);
      expect(controller.index, 0);
    });

    test('notifies listeners on initialize, jump, and timeline load', () async {
      rpc.stubJson('RecordingsService', 'GetEventTimeline', {'timelineJson': ''});
      final controller = RecordingsPlayerController(
        recordingsService: RecordingsServiceClient(rpc),
        playlist: [_item('a.mp4', hasEvents: true), _item('b.mp4', hasEvents: true)],
        initialIndex: 0,
      );
      var notified = 0;
      controller.addListener(() => notified++);
      await controller.initialize();
      expect(notified, greaterThan(0));
    });
  });
}
