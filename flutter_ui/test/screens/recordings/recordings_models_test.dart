import 'package:bladewatch_ui/screens/recordings/recordings_models.dart';
import 'package:flutter_test/flutter_test.dart';

RecordingItem _item({
  String filename = 'cam_20260523_120000.mp4',
  RecordingKind kind = RecordingKind.normal,
  int timestampMs = 1000,
  int sizeBytes = 500,
  int durationSeconds = 0,
  bool hasEvents = false,
  List<String> detectedClasses = const [],
  String? severity,
  String? proximity,
}) =>
    RecordingItem(
      filename: filename,
      path: '/storage/emulated/0/BladeWatch/recordings/$filename',
      kind: kind,
      timestampMs: timestampMs,
      sizeBytes: sizeBytes,
      durationSeconds: durationSeconds,
      dateLabel: 'May 23, 2026',
      timeLabel: '12:00:00 PM',
      hasEvents: hasEvents,
      detectedClasses: detectedClasses,
      severity: severity,
      proximity: proximity,
    );

void main() {
  group('RecordingItem.cameraId', () {
    test('extracts the numbered camera from a cam<N>_ filename', () {
      expect(_item(filename: 'cam2_20260523_120000.mp4').cameraId, 2);
    });

    test('defaults to 0 for a mosaic cam_ recording with no number', () {
      expect(_item(filename: 'cam_20260523_120000.mp4').cameraId, 0);
    });

    test('defaults to 0 for sentry/proximity filenames', () {
      expect(_item(filename: 'event_20260523_120000.mp4', kind: RecordingKind.sentry).cameraId, 0);
      expect(_item(filename: 'proximity_20260523_120000.mp4', kind: RecordingKind.proximity).cameraId, 0);
    });

    test('handles a segmented continuation suffix', () {
      expect(_item(filename: 'cam3_20260523_120000_2.mp4').cameraId, 3);
    });
  });

  group('RecordingItem.formattedSize', () {
    test('formats bytes/KB/MB/GB with the same decimal thresholds as native', () {
      expect(_item(sizeBytes: 500).formattedSize, '500 B');
      expect(_item(sizeBytes: 1500).formattedSize, '1.5 KB');
      expect(_item(sizeBytes: 1500000).formattedSize, '1.5 MB');
      expect(_item(sizeBytes: 1500000000).formattedSize, '1.5 GB');
    });
  });

  group('RecordingItem.formattedDuration', () {
    test('shows the unknown placeholder when duration is 0', () {
      expect(_item(durationSeconds: 0).formattedDuration, '--:--');
    });

    test('formats under an hour as m:ss', () {
      expect(_item(durationSeconds: 90).formattedDuration, '1:30');
    });

    test('formats an hour or more as h:mm:ss', () {
      expect(_item(durationSeconds: 3725).formattedDuration, '1:02:05');
    });
  });

  group('RecordingItem.proximityLabel', () {
    test('maps every known band to its lowercase label', () {
      expect(_item(proximity: 'VERY_CLOSE').proximityLabel, ProximityLabel.veryClose);
      expect(_item(proximity: 'CLOSE').proximityLabel, ProximityLabel.close);
      expect(_item(proximity: 'MID').proximityLabel, ProximityLabel.mid);
      expect(_item(proximity: 'FAR').proximityLabel, ProximityLabel.far);
    });

    test('is null when proximity is absent or unrecognized', () {
      expect(_item(proximity: null).proximityLabel, isNull);
      expect(_item(proximity: 'nonsense').proximityLabel, isNull);
    });
  });

  group('visibleRecordings', () {
    final normal = _item(filename: 'cam_20260523_083000.mp4', kind: RecordingKind.normal, timestampMs: 1000);
    final proximity = _item(filename: 'proximity_20260523_090000.mp4', kind: RecordingKind.proximity, timestampMs: 2000);
    final sentry = _item(
      filename: 'event_20260523_100000.mp4',
      kind: RecordingKind.sentry,
      timestampMs: 3000,
      detectedClasses: const ['person'],
      severity: 'ALERT',
    );
    final all = [normal, proximity, sentry];

    RecordingsFilterState dashcamFilter({Set<String> types = const {}}) => RecordingsFilterState(
          source: RecordingSource.dashcam,
          dateNarrowed: false,
          selectedDayMs: 0,
          dashcamTypes: types,
        );

    RecordingsFilterState surveillanceFilter({Set<String> actors = const {}, Set<String> severities = const {}}) =>
        RecordingsFilterState(
          source: RecordingSource.surveillance,
          dateNarrowed: false,
          selectedDayMs: 0,
          actorClasses: actors,
          severities: severities,
        );

    test('dashcam with no type chips shows both normal and proximity, not sentry', () {
      final result = visibleRecordings(all, dashcamFilter());
      expect(result, containsAll([normal, proximity]));
      expect(result, isNot(contains(sentry)));
    });

    test('dashcam with both type chips selected also shows both (same as none)', () {
      final result = visibleRecordings(all, dashcamFilter(types: {'NORMAL', 'PROXIMITY'}));
      expect(result, containsAll([normal, proximity]));
    });

    test('dashcam narrowed to NORMAL only excludes proximity', () {
      final result = visibleRecordings(all, dashcamFilter(types: {'NORMAL'}));
      expect(result, [normal]);
    });

    test('dashcam narrowed to PROXIMITY only excludes normal', () {
      final result = visibleRecordings(all, dashcamFilter(types: {'PROXIMITY'}));
      expect(result, [proximity]);
    });

    test('surveillance shows only sentry clips', () {
      final result = visibleRecordings(all, surveillanceFilter());
      expect(result, [sentry]);
    });

    test('surveillance actor filter matches a clip carrying that class', () {
      final result = visibleRecordings(all, surveillanceFilter(actors: {'person'}));
      expect(result, [sentry]);
    });

    test('surveillance actor filter excludes a clip missing that class', () {
      final result = visibleRecordings(all, surveillanceFilter(actors: {'vehicle'}));
      expect(result, isEmpty);
    });

    test('surveillance severity filter matches on the clip severity', () {
      expect(visibleRecordings(all, surveillanceFilter(severities: {'ALERT'})), [sentry]);
      expect(visibleRecordings(all, surveillanceFilter(severities: {'CRITICAL'})), isEmpty);
    });

    test('a clip with no sidecar (no severity, no classes) bypasses chip narrowing', () {
      final bare = _item(filename: 'event_20260523_110000.mp4', kind: RecordingKind.sentry, timestampMs: 4000);
      final result = visibleRecordings([bare], surveillanceFilter(actors: {'person'}));
      expect(result, [bare], reason: 'no signal to gate on, so it passes through unfiltered like native does');
    });

    test('date narrowing keeps only clips inside the selected local day', () {
      final dayStart = DateTime(2026, 5, 23).millisecondsSinceEpoch;
      final inDay = _item(filename: 'cam_20260523_083000.mp4', timestampMs: dayStart + 1000);
      final outOfDay = _item(filename: 'cam_20260524_083000.mp4', timestampMs: dayStart + 86400000 + 1000);
      final filter = RecordingsFilterState(
        source: RecordingSource.dashcam,
        dateNarrowed: true,
        selectedDayMs: dayStart,
      );
      final result = visibleRecordings([inDay, outOfDay], filter);
      expect(result, [inDay]);
    });
  });

  group('timeOfDayBucketFor', () {
    int atHour(int hour) => DateTime(2026, 5, 23, hour).millisecondsSinceEpoch;

    test('buckets each hour range correctly', () {
      expect(timeOfDayBucketFor(atHour(5)), TimeOfDayBucket.morning);
      expect(timeOfDayBucketFor(atHour(11)), TimeOfDayBucket.morning);
      expect(timeOfDayBucketFor(atHour(12)), TimeOfDayBucket.afternoon);
      expect(timeOfDayBucketFor(atHour(16)), TimeOfDayBucket.afternoon);
      expect(timeOfDayBucketFor(atHour(17)), TimeOfDayBucket.evening);
      expect(timeOfDayBucketFor(atHour(20)), TimeOfDayBucket.evening);
      expect(timeOfDayBucketFor(atHour(21)), TimeOfDayBucket.night);
      expect(timeOfDayBucketFor(atHour(4)), TimeOfDayBucket.night);
    });
  });

  group('dateSectionFor', () {
    test('classifies today, yesterday, and other days', () {
      final now = DateTime(2026, 5, 23, 15, 0).millisecondsSinceEpoch;
      final today = DateTime(2026, 5, 23, 8, 0).millisecondsSinceEpoch;
      final yesterday = DateTime(2026, 5, 22, 8, 0).millisecondsSinceEpoch;
      final older = DateTime(2026, 5, 1, 8, 0).millisecondsSinceEpoch;

      expect(dateSectionFor(today, now).relativeDay, RelativeDay.today);
      expect(dateSectionFor(yesterday, now).relativeDay, RelativeDay.yesterday);
      expect(dateSectionFor(older, now).relativeDay, RelativeDay.other);
    });

    test('dayStartMs is local midnight regardless of the time of day', () {
      final morning = DateTime(2026, 5, 23, 1, 0).millisecondsSinceEpoch;
      final night = DateTime(2026, 5, 23, 23, 59).millisecondsSinceEpoch;
      final now = DateTime(2026, 5, 23, 12, 0).millisecondsSinceEpoch;
      expect(dateSectionFor(morning, now).dayStartMs, dateSectionFor(night, now).dayStartMs);
    });
  });

  group('RecordingSection equality', () {
    test('TimeOfDaySection compares by bucket', () {
      expect(const TimeOfDaySection(TimeOfDayBucket.morning), const TimeOfDaySection(TimeOfDayBucket.morning));
      expect(const TimeOfDaySection(TimeOfDayBucket.morning), isNot(const TimeOfDaySection(TimeOfDayBucket.night)));
    });

    test('DateSection compares by day and relative classification', () {
      const a = DateSection(1000, RelativeDay.today);
      const b = DateSection(1000, RelativeDay.today);
      const c = DateSection(2000, RelativeDay.today);
      expect(a, b);
      expect(a, isNot(c));
    });

    test('equal sections share a hashCode (usable as Map/Set keys)', () {
      expect(
        const TimeOfDaySection(TimeOfDayBucket.evening).hashCode,
        const TimeOfDaySection(TimeOfDayBucket.evening).hashCode,
      );
      expect(const DateSection(1000, RelativeDay.yesterday).hashCode, const DateSection(1000, RelativeDay.yesterday).hashCode);
    });

    test('sectionFor dispatches on singleDayMode', () {
      final now = DateTime(2026, 5, 23, 12).millisecondsSinceEpoch;
      final morningItem = _item(timestampMs: DateTime(2026, 5, 23, 8).millisecondsSinceEpoch);
      expect(sectionFor(morningItem, true, now), const TimeOfDaySection(TimeOfDayBucket.morning));
      expect(sectionFor(morningItem, false, now), isA<DateSection>());
    });
  });

  group('RecordingsFilterState.chipsActive', () {
    test('dashcam: active only when a type chip is selected', () {
      const base = RecordingsFilterState(source: RecordingSource.dashcam, dateNarrowed: false, selectedDayMs: 0);
      expect(base.chipsActive, isFalse);
      expect(base.copyWith(dashcamTypes: {'NORMAL'}).chipsActive, isTrue);
    });

    test('surveillance: active when either actor or severity chips are set', () {
      const base = RecordingsFilterState(source: RecordingSource.surveillance, dateNarrowed: false, selectedDayMs: 0);
      expect(base.chipsActive, isFalse);
      expect(base.copyWith(actorClasses: {'person'}).chipsActive, isTrue);
      expect(base.copyWith(severities: {'ALERT'}).chipsActive, isTrue);
    });
  });

  group('groupIntoSections', () {
    test('splits an ordered list into contiguous same-section runs', () {
      final now = DateTime(2026, 5, 23, 22).millisecondsSinceEpoch;
      final morning1 = _item(filename: 'a.mp4', timestampMs: DateTime(2026, 5, 23, 8).millisecondsSinceEpoch);
      final morning2 = _item(filename: 'b.mp4', timestampMs: DateTime(2026, 5, 23, 9).millisecondsSinceEpoch);
      final evening = _item(filename: 'c.mp4', timestampMs: DateTime(2026, 5, 23, 18).millisecondsSinceEpoch);

      final groups = groupIntoSections([evening, morning2, morning1], true, now);

      expect(groups, hasLength(2));
      expect(groups[0].section, const TimeOfDaySection(TimeOfDayBucket.evening));
      expect(groups[0].items, [evening]);
      expect(groups[1].section, const TimeOfDaySection(TimeOfDayBucket.morning));
      expect(groups[1].items, [morning2, morning1]);
    });

    test('does not merge two non-adjacent runs of the same section', () {
      final now = DateTime(2026, 5, 23, 22).millisecondsSinceEpoch;
      final morning = _item(filename: 'a.mp4', timestampMs: DateTime(2026, 5, 23, 8).millisecondsSinceEpoch);
      final evening = _item(filename: 'b.mp4', timestampMs: DateTime(2026, 5, 23, 18).millisecondsSinceEpoch);
      final morningAgain = _item(filename: 'c.mp4', timestampMs: DateTime(2026, 5, 22, 8).millisecondsSinceEpoch);

      final groups = groupIntoSections([morning, evening, morningAgain], true, now);

      expect(groups, hasLength(3), reason: 'relies on caller ordering, does not re-sort/re-group by label');
    });

    test('empty input yields no groups', () {
      expect(groupIntoSections(const [], true, 0), isEmpty);
    });
  });
}
