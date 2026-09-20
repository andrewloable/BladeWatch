/// Ground truth: `SurveillanceSettingsController.kt` + `SurveillanceSettingsModels.kt`.
/// Tab selection is pure UI state (kept in the widget, not here) — see
/// `settings_recording_models.dart` for the sibling precedent this mirrors.
enum SurveillanceSettingsTab { general, detection, recording, storage, advanced }

/// Environment preset tokens — ground truth: the controller's hardcoded
/// `listOf("OUTDOOR", "GARAGE", "STREET", "CUSTOM")` segmented row. Kept as
/// raw wire strings (not a Dart enum) because native itself never promotes
/// them past `String`, matching how `selectedStorageType` stays a raw
/// string in `RecordingSettingsController`.
const List<String> kEnvironmentPresets = ['OUTDOOR', 'GARAGE', 'STREET', 'CUSTOM'];

/// Deterrent action tokens — ground truth: the controller's hardcoded
/// `listOf("silent", "horn", "flash")` segmented row.
const List<String> kDeterrentActions = ['silent', 'horn', 'flash'];

/// Pre/post-record segmented-row options — ground truth: `renderRecording()`.
const List<int> kPreRecordOptionsSeconds = [2, 5, 10, 15];
const List<int> kPostRecordOptionsSeconds = [5, 10, 15, 20, 30];

/// Fixed name/radius used when adding a safe zone at the current GPS fix —
/// ground truth: `client.addSafeZone("Safe Zone", currentLat, currentLng, 150)`.
/// Native has no name/radius entry dialog; one tap adds this exact zone.
const String kDefaultSafeZoneName = 'Safe Zone';
const int kDefaultSafeZoneRadiusM = 150;

class SurveillanceConfig {
  final bool enabled;
  final String distancePreset;
  final int sensitivityLevel;
  final bool detectPerson;
  final bool detectCar;
  final bool detectBike;
  final int preRecordSeconds;
  final int postRecordSeconds;
  final bool nightMode;
  final bool aiEnabled;
  // Never exposed by this screen's UI (native has no control for it either) —
  // loaded from the server and re-sent unchanged on every save.
  final double aiConfidence;
  final bool cameraFront;
  final bool cameraRight;
  final bool cameraRear;
  final bool cameraLeft;
  final String deterrentAction;
  // Also never exposed by this screen's UI — see aiConfidence above.
  final int deterrentCooldownSeconds;

  const SurveillanceConfig({
    required this.enabled,
    required this.distancePreset,
    required this.sensitivityLevel,
    required this.detectPerson,
    required this.detectCar,
    required this.detectBike,
    required this.preRecordSeconds,
    required this.postRecordSeconds,
    required this.nightMode,
    required this.aiEnabled,
    required this.aiConfidence,
    required this.cameraFront,
    required this.cameraRight,
    required this.cameraRear,
    required this.cameraLeft,
    required this.deterrentAction,
    required this.deterrentCooldownSeconds,
  });
}

class SurveillanceStatus {
  final bool isRunning;
  final int eventsToday;
  // BladeWatch-gyg1.2: true only while another app actually holds the camera --
  // surfaced honestly, not as a permanent caption. See BydCameraCoordinator.isYielded().
  final bool cameraYielded;

  const SurveillanceStatus({required this.isRunning, required this.eventsToday, this.cameraYielded = false});
}

class SurveillanceStorageSettings {
  final String storageType;
  final int limitMb;
  final int surveillanceSizeBytes;
  final int surveillanceCount;
  final bool sdCardAvailable;
  final String path;
  final int minLimitMb;
  final int maxLimitMb;
  final int maxLimitMbSdCard;
  final int internalTotalMb;
  final int sdCardTotalMb;

  const SurveillanceStorageSettings({
    required this.storageType,
    required this.limitMb,
    required this.surveillanceSizeBytes,
    required this.surveillanceCount,
    required this.sdCardAvailable,
    required this.path,
    this.minLimitMb = 100,
    this.maxLimitMb = 100000,
    this.maxLimitMbSdCard = 100000,
    this.internalTotalMb = 0,
    this.sdCardTotalMb = 0,
  });
}

class SafeZone {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final int radiusM;

  const SafeZone({required this.id, required this.name, required this.lat, required this.lng, required this.radiusM});
}

/// Format-drive sub-flow state — ground truth: the controller's
/// `formatConfirmPending`/`formatRunning`/`formatResultMessage` fields.
/// Modeled as one state instead of 3 independent booleans, matching
/// `settings_recording_models.dart`'s identical `FormatDriveResult` (kept as
/// a separate copy per screen, not imported, since native keeps its own
/// separate copy of this state per controller too).
enum FormatDriveState { idle, confirming, running, succeeded, failed }

class FormatDriveResult {
  final FormatDriveState state;
  final String? message;

  const FormatDriveResult({required this.state, this.message});
  const FormatDriveResult.idle()
      : state = FormatDriveState.idle,
        message = null;
}

enum SyncDriveState { idle, running, succeeded, failed }

class SyncCatalogResult {
  final SyncDriveState state;
  final String? message;

  const SyncCatalogResult({required this.state, this.message});
  const SyncCatalogResult.idle()
      : state = SyncDriveState.idle,
        message = null;
}

class ApplyResult {
  final bool ok;
  final String? error;

  const ApplyResult({required this.ok, this.error});
}
