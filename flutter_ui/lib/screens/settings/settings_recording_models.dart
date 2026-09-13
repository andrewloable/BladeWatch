/// Ground truth: `RecordingSettingsModels.kt`. Labels/descriptions are a
/// widget-layer (l10n) concern here, unlike native's hardcoded-English
/// enum fields — these enums carry only the wire `value` each maps to.
enum RecordingSettingsTab { status, capture, quality, storage }

enum RecordingMode {
  none('NONE'),
  continuous('CONTINUOUS'),
  driveMode('DRIVE_MODE'),
  proximityGuard('PROXIMITY_GUARD');

  final String value;
  const RecordingMode(this.value);

  static RecordingMode fromValue(String v) => RecordingMode.values.firstWhere((m) => m.value == v, orElse: () => RecordingMode.none);
}

enum RecordingQuality {
  economy('ECONOMY'),
  standard('STANDARD'),
  high('HIGH'),
  premium('PREMIUM'),
  max('MAX');

  final String value;
  const RecordingQuality(this.value);

  static RecordingQuality fromValue(String v) =>
      RecordingQuality.values.firstWhere((q) => q.value == v.toUpperCase(), orElse: () => RecordingQuality.standard);
}

/// Per-file recording segment length, in minutes.
enum RecordingLimit {
  one(1),
  five(5),
  ten(10);

  final int minutes;
  const RecordingLimit(this.minutes);

  static RecordingLimit fromMinutes(int m) => RecordingLimit.values.firstWhere((l) => l.minutes == m, orElse: () => RecordingLimit.five);
}

class RecordingStatus {
  final String currentMode;
  final bool isRecording;
  final int normalTodayCount;
  final int proximityTodayCount;

  const RecordingStatus({
    required this.currentMode,
    required this.isRecording,
    required this.normalTodayCount,
    required this.proximityTodayCount,
  });
}

class RecordingStorageSettings {
  final String storageType;
  final int limitMb;
  final int recordingsSizeBytes;
  final int recordingsCount;
  final bool sdCardAvailable;
  final String sdCardFreeFormatted;
  final String internalFreeFormatted;
  final String recordingsPath;
  final int minLimitMb;
  final int maxLimitMb;
  final int maxLimitMbSdCard;
  final int internalTotalMb;
  final int sdCardTotalMb;

  const RecordingStorageSettings({
    required this.storageType,
    required this.limitMb,
    required this.recordingsSizeBytes,
    required this.recordingsCount,
    required this.sdCardAvailable,
    required this.sdCardFreeFormatted,
    required this.internalFreeFormatted,
    required this.recordingsPath,
    this.minLimitMb = 100,
    this.maxLimitMb = 100000,
    this.maxLimitMbSdCard = 100000,
    this.internalTotalMb = 0,
    this.sdCardTotalMb = 0,
  });
}

/// Format-drive sub-flow state — ground truth:
/// `RecordingSettingsController.kt`'s `formatConfirmPending`/`formatRunning`/
/// `formatResultMessage` fields, modeled as one sealed-ish state instead of
/// 3 independent booleans (a strictly narrower state space is easier to
/// render exhaustively and impossible to get into a self-contradictory
/// combination of the 3 flags).
enum FormatDriveState { idle, confirming, running, succeeded, failed }

class FormatDriveResult {
  final FormatDriveState state;
  final String? message;

  const FormatDriveResult({required this.state, this.message});
  const FormatDriveResult.idle() : state = FormatDriveState.idle, message = null;
}

enum SyncDriveState { idle, running, succeeded, failed }

class SyncCatalogResult {
  final SyncDriveState state;
  final String? message;

  const SyncCatalogResult({required this.state, this.message});
  const SyncCatalogResult.idle() : state = SyncDriveState.idle, message = null;
}
