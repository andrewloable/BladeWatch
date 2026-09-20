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

/// BladeWatch-gyg1.3: a cap layered on top of [RecordingLimit], not a replacement for it.
/// RELIABILITY shortens the effective segment length to 1 minute regardless of the Recording
/// Limit choice, so an abrupt power loss loses at most one unfinalised segment; PERFORMANCE is
/// a pure passthrough of Recording Limit. Ground truth: `RecordingPriority` (Kotlin, daemon
/// side) -- this enum mirrors its wire names.
enum RecordingPriority {
  performance('PERFORMANCE'),
  reliability('RELIABILITY');

  final String value;
  const RecordingPriority(this.value);

  static RecordingPriority fromValue(String v) =>
      RecordingPriority.values.firstWhere((p) => p.value == v.toUpperCase(), orElse: () => RecordingPriority.reliability);
}

/// BladeWatch-y78o.5: the burned-in telemetry overlay's selectable fields. Wire names mirror
/// `OverlayField` (Kotlin, daemon side) exactly. Deliberately does NOT include VIN or location
/// -- GPS coordinates are drawn through a separate, unconditional path the daemon does not
/// expose as a toggle at all; see that enum's own doc comment for the reasoning.
enum OverlayField {
  speed('SPEED'),
  gear('GEAR'),
  turnSignalLeft('TURN_SIGNAL_LEFT'),
  turnSignalRight('TURN_SIGNAL_RIGHT'),
  brakePedal('BRAKE_PEDAL'),
  accelPedal('ACCEL_PEDAL'),
  seatbeltDriver('SEATBELT_DRIVER'),
  seatbeltPassenger('SEATBELT_PASSENGER'),
  timestamp('TIMESTAMP');

  final String value;
  const OverlayField(this.value);

  static OverlayField? fromValue(String v) {
    for (final f in OverlayField.values) {
      if (f.value.toUpperCase() == v.toUpperCase()) return f;
    }
    return null;
  }
}

/// BladeWatch-gyg1.4: the result of previewing a recordings-limit lowering before applying it.
/// `known` carries real (not estimated) numbers from the daemon's preview; `unknown` means the
/// preview call itself failed -- the caller must not silently proceed as if nothing would be
/// deleted (see the issue's "do not ship a vague warning" constraint).
enum StorageLimitImpactStatus { known, unknown }

class StorageLimitImpact {
  final StorageLimitImpactStatus status;
  final int fileCount;
  final int totalBytes;

  const StorageLimitImpact.known({required this.fileCount, required this.totalBytes}) : status = StorageLimitImpactStatus.known;
  const StorageLimitImpact.unknown()
      : status = StorageLimitImpactStatus.unknown,
        fileCount = 0,
        totalBytes = 0;
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

  /// True when the daemon's SD card mount attempts at startup were exhausted while an
  /// SD_CARD preference was already configured — see StorageManager.resolveSdCardAutoPriority.
  /// The daemon keeps retrying in the background (the SD watchdog), but the recovery path the
  /// daemon itself recommends is a restart with the card properly seated.
  final bool sdCardMountFailed;
  final String? sdCardMountError;

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
    this.sdCardMountFailed = false,
    this.sdCardMountError,
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
