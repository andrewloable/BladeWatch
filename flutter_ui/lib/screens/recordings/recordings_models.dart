/// Ground truth: `RecordingFile.kt` (the native model) + `RecordingScanner.kt`
/// + `RecordingsFragment.kt` / `RecordingLibraryFragment.kt` (the filtering
/// rules) + `web/src/app/pages/recording/recording.component.ts` (the
/// already-shipped RPC-based translation of the same screen, used as a
/// cross-check since native itself reads the filesystem directly — an
/// option this Flutter APK does not have).
library;

/// Mirrors `RecordingType` (the proto enum) collapsed to the 3 real values —
/// `RECORDING_TYPE_UNSPECIFIED` never appears in a real `RecordingEntry`.
enum RecordingKind { normal, sentry, proximity }

/// The two top-level segments `RecordingsFragment`'s `MaterialButtonToggleGroup`
/// switches between. Dashcam covers both [RecordingKind.normal] and
/// [RecordingKind.proximity] (both come off the dashcam encoder, just
/// triggered differently); Surveillance is [RecordingKind.sentry] alone.
enum RecordingSource { dashcam, surveillance }

enum TimeOfDayBucket { morning, afternoon, evening, night }

enum RelativeDay { today, yesterday, other }

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

/// Every filter dimension `RecordingsFragment` owns, bundled — mirrors its
/// own field set (`currentSource`, `dateNarrowed`/`calendar`/`selectedDay`,
/// `actorClassFilter`, `severityFilter`, `dashcamTypes`).
class RecordingsFilterState {
  final RecordingSource source;
  final bool dateNarrowed;

  /// Local midnight epoch ms of the selected day. Meaningless when
  /// [dateNarrowed] is false.
  final int selectedDayMs;

  /// Lowercase class names ("person", "vehicle", "bike", "animal").
  /// Surveillance-only.
  final Set<String> actorClasses;

  /// Uppercase severities ("ALERT", "CRITICAL"). Surveillance-only.
  final Set<String> severities;

  /// Uppercase type narrowing ("NORMAL", "PROXIMITY"). Dashcam-only; empty
  /// or both selected means "show both" (native's exact `applyAllFiltersTo`
  /// rule).
  final Set<String> dashcamTypes;

  const RecordingsFilterState({
    required this.source,
    required this.dateNarrowed,
    required this.selectedDayMs,
    this.actorClasses = const {},
    this.severities = const {},
    this.dashcamTypes = const {},
  });

  RecordingsFilterState copyWith({
    RecordingSource? source,
    bool? dateNarrowed,
    int? selectedDayMs,
    Set<String>? actorClasses,
    Set<String>? severities,
    Set<String>? dashcamTypes,
  }) =>
      RecordingsFilterState(
        source: source ?? this.source,
        dateNarrowed: dateNarrowed ?? this.dateNarrowed,
        selectedDayMs: selectedDayMs ?? this.selectedDayMs,
        actorClasses: actorClasses ?? this.actorClasses,
        severities: severities ?? this.severities,
        dashcamTypes: dashcamTypes ?? this.dashcamTypes,
      );

  bool get chipsActive =>
      source == RecordingSource.dashcam ? dashcamTypes.isNotEmpty : (actorClasses.isNotEmpty || severities.isNotEmpty);
}

/// The post-segment/date/chip list shown in the grid. Mirrors the combined
/// pipeline `RecordingsFragment.applyAllFiltersTo()` +
/// `RecordingLibraryFragment.loadRecordingsForSelectedDate()` run together
/// (this port has no fragment-hosting-fragment split — see
/// `recordings_screen.dart`'s doc comment) — equally cross-checked against
/// `recording.component.ts`'s `visible` computed, the already-shipped web
/// translation of the same two-fragment pipeline.
List<RecordingItem> visibleRecordings(List<RecordingItem> all, RecordingsFilterState filter) {
  var list = all.where((r) => _matchesSource(r, filter)).toList();

  if (filter.dateNarrowed) {
    final start = filter.selectedDayMs;
    final end = start + 86400000;
    list = list.where((r) => r.timestampMs >= start && r.timestampMs < end).toList();
  }

  if (filter.source == RecordingSource.surveillance &&
      (filter.actorClasses.isNotEmpty || filter.severities.isNotEmpty)) {
    list = list.where((r) {
      // A clip with no sidecar (e.g. a legacy or unclassified capture) has
      // no signal to gate on -- excluding it entirely would empty the list
      // whenever any chip is active. Mirrors
      // RecordingLibraryFragment.loadRecordingsForSelectedDate()'s
      // `hasSidecar` bypass exactly (a rule the web reference does NOT
      // reproduce -- native is this port's ground truth, so native wins
      // where the two disagree).
      final hasSidecar = (r.severity != null && r.severity!.isNotEmpty) || r.detectedClasses.isNotEmpty;
      if (!hasSidecar) return true;
      final classOk =
          filter.actorClasses.isEmpty || r.detectedClasses.any((c) => filter.actorClasses.contains(c.toLowerCase()));
      final sevOk = filter.severities.isEmpty ||
          (r.severity != null && filter.severities.contains(r.severity!.toUpperCase()));
      return classOk && sevOk;
    }).toList();
  }

  return list;
}

bool _matchesSource(RecordingItem r, RecordingsFilterState filter) {
  if (filter.source == RecordingSource.surveillance) return r.kind == RecordingKind.sentry;
  final wantsNormal = filter.dashcamTypes.contains('NORMAL');
  final wantsProximity = filter.dashcamTypes.contains('PROXIMITY');
  if (wantsNormal && !wantsProximity) return r.kind == RecordingKind.normal;
  if (wantsProximity && !wantsNormal) return r.kind == RecordingKind.proximity;
  return r.kind == RecordingKind.normal || r.kind == RecordingKind.proximity;
}

/// Mirrors `RecordingSectionHeaderDecoration.timeOfDayLabel()`'s hour bucket.
TimeOfDayBucket timeOfDayBucketFor(int timestampMs) {
  final hour = DateTime.fromMillisecondsSinceEpoch(timestampMs).hour;
  if (hour >= 5 && hour <= 11) return TimeOfDayBucket.morning;
  if (hour >= 12 && hour <= 16) return TimeOfDayBucket.afternoon;
  if (hour >= 17 && hour <= 20) return TimeOfDayBucket.evening;
  return TimeOfDayBucket.night;
}

/// The section a recording belongs to in single-day mode (grouped by
/// [TimeOfDayBucket]) or multi-day mode (grouped by [DateSection]). Kept as
/// a semantic marker rather than display text -- like `location_models.dart`'s
/// state-to-banner split, resolving ARB strings is the screen's job.
sealed class RecordingSection {
  const RecordingSection();
}

class TimeOfDaySection extends RecordingSection {
  final TimeOfDayBucket bucket;
  const TimeOfDaySection(this.bucket);

  @override
  bool operator ==(Object other) => other is TimeOfDaySection && other.bucket == bucket;
  @override
  int get hashCode => bucket.hashCode;
}

class DateSection extends RecordingSection {
  /// Local midnight epoch ms of the day this section covers.
  final int dayStartMs;
  final RelativeDay relativeDay;
  const DateSection(this.dayStartMs, this.relativeDay);

  @override
  bool operator ==(Object other) =>
      other is DateSection && other.dayStartMs == dayStartMs && other.relativeDay == relativeDay;
  @override
  int get hashCode => Object.hash(dayStartMs, relativeDay);
}

int _localMidnight(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return DateTime(d.year, d.month, d.day).millisecondsSinceEpoch;
}

/// Mirrors `RecordingSectionHeaderDecoration.dateLabel()`'s today/yesterday/
/// formatted-date classification.
DateSection dateSectionFor(int timestampMs, int nowMs) {
  final day = _localMidnight(timestampMs);
  final today = _localMidnight(nowMs);
  final yesterday = today - 86400000;
  final relative = day == today
      ? RelativeDay.today
      : (day == yesterday ? RelativeDay.yesterday : RelativeDay.other);
  return DateSection(day, relative);
}

/// Mirrors `RecordingSectionHeaderDecoration.labelFor()`'s `singleDayMode`
/// dispatch.
RecordingSection sectionFor(RecordingItem item, bool singleDayMode, int nowMs) => singleDayMode
    ? TimeOfDaySection(timeOfDayBucketFor(item.timestampMs))
    : dateSectionFor(item.timestampMs, nowMs);

/// One contiguous run of same-section items, in the order they appear in
/// [items] — relies on [items] already being sorted (newest-first, same as
/// `RecordingScanner.scanRecordings()`'s `sortedByDescending`), exactly like
/// `RecordingSectionHeaderDecoration` relies on adapter order rather than
/// re-grouping/re-sorting by label itself.
class RecordingSectionGroup {
  final RecordingSection section;
  final List<RecordingItem> items;
  const RecordingSectionGroup(this.section, this.items);
}

/// Splits an already-ordered list into contiguous same-section runs.
List<RecordingSectionGroup> groupIntoSections(List<RecordingItem> items, bool singleDayMode, int nowMs) {
  final groups = <RecordingSectionGroup>[];
  for (final item in items) {
    final section = sectionFor(item, singleDayMode, nowMs);
    if (groups.isNotEmpty && groups.last.section == section) {
      groups.last.items.add(item);
    } else {
      groups.add(RecordingSectionGroup(section, [item]));
    }
  }
  return groups;
}
