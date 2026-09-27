import 'package:bladewatch_ui/screens/recordings/recordings_models.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pb.dart';
import 'package:fixnum/fixnum.dart';
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

  // BladeWatch-rdtj.70: rows are built straight from each ListRecordings page.
  group('RecordingItem.fromEntry', () {
    test('maps every field the row and the player use', () {
      final e = RecordingEntry(
        filename: 'event_20260523_120000.mp4',
        path: '/storage/x/event_20260523_120000.mp4',
        type: RecordingType.RECORDING_TYPE_SENTRY,
        timestampMs: Int64(1779537600000),
        sizeBytes: Int64(2500000),
        durationSeconds: Int64(95),
        dateLabel: 'May 23, 2026',
        timeLabel: '12:00:00 PM',
        hasEvents: true,
        detectedClasses: ['person', 'vehicle'],
        severity: 'CRITICAL',
        proximity: 'CLOSE',
      );
      final item = RecordingItem.fromEntry(e);
      expect(item.kind, RecordingKind.sentry);
      expect(item.timestampMs, 1779537600000);
      expect(item.formattedSize, '2.5 MB');
      expect(item.formattedDuration, '1:35');
      expect(item.detectedClasses, ['person', 'vehicle']);
      expect(item.severity, 'CRITICAL');
      expect(item.proximityLabel, ProximityLabel.close);
      expect(item.hasEvents, isTrue);
    });

    test('proximity and normal types, and empty severity/proximity as null', () {
      expect(RecordingItem.fromEntry(RecordingEntry(type: RecordingType.RECORDING_TYPE_PROXIMITY)).kind, RecordingKind.proximity);
      final normal = RecordingItem.fromEntry(RecordingEntry(type: RecordingType.RECORDING_TYPE_NORMAL));
      expect(normal.kind, RecordingKind.normal);
      expect(normal.severity, isNull);
      expect(normal.proximity, isNull);
    });
  });
}
