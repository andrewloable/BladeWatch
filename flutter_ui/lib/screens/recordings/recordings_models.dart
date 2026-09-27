/// Ground truth: `RecordingFile.kt` (the native model) + `RecordingScanner.kt`
/// + `RecordingsFragment.kt` / `RecordingLibraryFragment.kt` (the filtering
/// rules) + `web/src/app/pages/recording/recording.component.ts` (the
/// already-shipped RPC-based translation of the same screen, used as a
/// cross-check since native itself reads the filesystem directly — an
/// option this Flutter APK does not have).
library;

import 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pb.dart';

/// Mirrors `RecordingType` (the proto enum) collapsed to the 3 real values —
/// `RECORDING_TYPE_UNSPECIFIED` never appears in a real `RecordingEntry`.
enum RecordingKind { normal, sentry, proximity }

/// Mirrors `RecordingAdapter.kt`'s `peakProximity` band mapping (`"very
/// close"` / `"close"` / `"mid"` / `"far"`, hardcoded English in native —
/// this port resolves each to an ARB key at the screen layer instead).
enum ProximityLabel { veryClose, close, mid, far }

const _cameraFilenamePattern = r'^cam(\d+)?_\d{8}_\d{6}(?:_\d+)?\.mp4$';

/// One recording as `ListRecordingsResponse.recordings` reports it — the
/// RPC-shape counterpart of native's file-scanned `RecordingFile`.
class RecordingItem {
  final String filename;
  final String path;
  final RecordingKind kind;
  final int timestampMs;
  final int sizeBytes;
  final int durationSeconds;
  final String dateLabel;
  final String timeLabel;
  final bool hasEvents;

  /// AI detection classes present in the sidecar (e.g. "person", "vehicle"),
  /// lowercase. A presence list, not counts — unlike native's own
  /// `RecordingFile.personCount`/etc (parsed client-side from the full
  /// sidecar JSON, an option only available with direct file access),
  /// `RecordingEntry.detected_classes` only reports which classes were
  /// seen, not how many of each. The card summary shows the class list
  /// rather than fabricated counts.
  final List<String> detectedClasses;

  /// "ALERT" / "CRITICAL", or null/empty when the clip has no sidecar or no
  /// escalation occurred.
  final String? severity;

  /// "VERY_CLOSE" / "CLOSE" / "MID" / "FAR", or null/empty.
  final String? proximity;

  const RecordingItem({
    required this.filename,
    required this.path,
    required this.kind,
    required this.timestampMs,
    required this.sizeBytes,
    required this.durationSeconds,
    required this.dateLabel,
    required this.timeLabel,
    required this.hasEvents,
    this.detectedClasses = const [],
    this.severity,
    this.proximity,
  });

  /// One clip as ListRecordings reports it.
  factory RecordingItem.fromEntry(RecordingEntry e) => RecordingItem(
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

  /// Mirrors `RecordingFile.extractCameraId()` — only `cam<N>_...` normal
  /// filenames carry a camera number; sentry/proximity filenames never
  /// match this pattern and fall through to 0 (mosaic recordings), same as
  /// native.
  int get cameraId {
    final match = RegExp(_cameraFilenamePattern).firstMatch(filename);
    if (match == null) return 0;
    return int.tryParse(match.group(1) ?? '') ?? 0;
  }

  /// Mirrors `RecordingFile.formattedSize` — decimal (1000-based) thresholds,
  /// not binary 1024-based.
  String get formattedSize {
    if (sizeBytes >= 1000000000) return '${(sizeBytes / 1000000000).toStringAsFixed(1)} GB';
    if (sizeBytes >= 1000000) return '${(sizeBytes / 1000000).toStringAsFixed(1)} MB';
    if (sizeBytes >= 1000) return '${(sizeBytes / 1000).toStringAsFixed(1)} KB';
    return '$sizeBytes B';
  }

  /// Mirrors `RecordingFile.formattedDuration`, adapted to operate on
  /// [durationSeconds] directly (the RPC already reports seconds; native's
  /// version divides its own millisecond field first). "--:--" when unknown
  /// (native's `RecordingAdapter` fallback for `durationMs <= 0`).
  String get formattedDuration {
    if (durationSeconds <= 0) return '--:--';
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final secs = durationSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  ProximityLabel? get proximityLabel => switch (proximity?.toUpperCase()) {
        'VERY_CLOSE' => ProximityLabel.veryClose,
        'CLOSE' => ProximityLabel.close,
        'MID' => ProximityLabel.mid,
        'FAR' => ProximityLabel.far,
        _ => null,
      };
}
