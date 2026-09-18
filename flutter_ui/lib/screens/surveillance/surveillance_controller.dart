import 'package:fixnum/fixnum.dart';

import 'package:flutter/foundation.dart';

import '../../widgets/storage_limit.dart';

import '../../gen/bladewatch/v1/recordings.pb.dart' show GetStatsRequest;
import '../../gen/bladewatch/v1/safe_locations.pb.dart' as sl;
import '../../gen/bladewatch/v1/storage.pb.dart' as storage_pb;
import '../../gen/bladewatch/v1/surveillance.pb.dart' as pb;
import '../../rpc/services/recordings_service_client.dart';
import '../../rpc/services/safe_locations_service_client.dart';
import '../../rpc/services/storage_service_client.dart';
import '../../rpc/services/surveillance_service_client.dart';
import 'surveillance_models.dart';
import '../../shell/disposed_safe_notifier.dart';
import '../settings/settings_recording_models.dart' show StorageLimitImpact;

/// Ground truth: `SurveillanceSettingsController.kt`, the shared controller
/// behind BOTH the standalone `surveillanceSettingsWebFragment` destination
/// and the Settings sub-rail's Surveillance row (this task's "two entry
/// points" note) — mirrors `RecordingSettingsController`'s identical split.
///
/// Edit state is one flat set of fields shared across every tab, not
/// per-tab state — matches native exactly: switching tabs never resets or
/// saves, and Apply on any non-Storage tab saves the FULL merged state
/// regardless of which tab is on screen (`applyChanges()`'s single shared
/// `config.copy(...)`).
class SurveillanceSettingsController extends ChangeNotifier with DisposedSafeNotifier {
  SurveillanceSettingsController({
    required SurveillanceServiceClient surveillanceService,
    required SurveillanceServiceClient longSurveillanceService,
    required SafeLocationsServiceClient safeLocationsService,
    required StorageServiceClient storageService,
    required RecordingsServiceClient recordingsService,
  })  : _surveillanceService = surveillanceService, // ignore: prefer_initializing_formals
        _longSurveillanceService = longSurveillanceService, // ignore: prefer_initializing_formals
        _safeLocationsService = safeLocationsService, // ignore: prefer_initializing_formals
        _storageService = storageService, // ignore: prefer_initializing_formals
        _recordingsService = recordingsService; // ignore: prefer_initializing_formals

  final SurveillanceServiceClient _surveillanceService;
  // SyncCatalog can run long (mirrors Trips' SyncTrips / `longTripsService`):
  // ground truth `ConnectClientProvider.longSurveillanceService()`.
  final SurveillanceServiceClient _longSurveillanceService;
  final SafeLocationsServiceClient _safeLocationsService;
  final StorageServiceClient _storageService;
  final RecordingsServiceClient _recordingsService;

  static const _toggleSettleDelay = Duration(milliseconds: 300);

  bool _loading = true;
  bool get loading => _loading;

  SurveillanceConfig? _loadedConfig;

  SurveillanceStatus? _status;
  SurveillanceStatus? get status => _status;

  SurveillanceStorageSettings? _storageSettings;
  SurveillanceStorageSettings? get storageSettings => _storageSettings;

  bool _safeLocFeatureEnabled = false;
  bool get safeLocFeatureEnabled => _safeLocFeatureEnabled;

  List<SafeZone> _safeZones = const [];
  List<SafeZone> get safeZones => _safeZones;

  double _currentLat = 0;
  double get currentLat => _currentLat;

  double _currentLng = 0;
  double get currentLng => _currentLng;

  bool _editEnabled = false;
  bool get editEnabled => _editEnabled;

  String _editPreset = 'OUTDOOR';
  String get editPreset => _editPreset;

  int _editSensitivity = 3;
  int get editSensitivity => _editSensitivity;

  bool _editDetectPerson = true;
  bool get editDetectPerson => _editDetectPerson;

  bool _editDetectCar = true;
  bool get editDetectCar => _editDetectCar;

  bool _editDetectBike = true;
  bool get editDetectBike => _editDetectBike;

  int _editPreRecord = 5;
  int get editPreRecord => _editPreRecord;

  int _editPostRecord = 10;
  int get editPostRecord => _editPostRecord;

  bool _editNightMode = false;
  bool get editNightMode => _editNightMode;

  bool _editAiEnabled = true;
  bool get editAiEnabled => _editAiEnabled;

  bool _editCameraFront = true;
  bool get editCameraFront => _editCameraFront;

  bool _editCameraRight = true;
  bool get editCameraRight => _editCameraRight;

  bool _editCameraRear = true;
  bool get editCameraRear => _editCameraRear;

  bool _editCameraLeft = true;
  bool get editCameraLeft => _editCameraLeft;

  String _editDeterrent = 'silent';
  String get editDeterrent => _editDeterrent;

  // No UI control edits this (native has none either) — loaded, held, and
  // re-sent unchanged by every save.
  int _editDeterrentCooldown = 60;

  String _editStorageType = 'INTERNAL';
  String get editStorageType => _editStorageType;

  int _editStorageLimitMb = 500;
  int get editStorageLimitMb => _editStorageLimitMb;

  FormatDriveResult _formatState = const FormatDriveResult.idle();
  FormatDriveResult get formatState => _formatState;

  SyncCatalogResult _syncState = const SyncCatalogResult.idle();
  SyncCatalogResult get syncState => _syncState;

  /// Storage-limit slider bounds — ground truth: `renderStorage()`'s
  /// `minMb`/`maxMb`, capping at the selected volume's physical size and
  /// falling back to the daemon's configured max when unknown (0).
  int get storageLimitMinMb {
    final min = _storageSettings?.minLimitMb ?? 100;
    return min < 100 ? 100 : min;
  }

  int get storageLimitMaxMb {
    final s = _storageSettings;
    final daemonMax = s == null ? 100000 : (_editStorageType == 'SD_CARD' ? s.maxLimitMbSdCard : s.maxLimitMb);
    final totalMb = s == null ? 0 : (_editStorageType == 'SD_CARD' ? s.sdCardTotalMb : s.internalTotalMb);
    final maxMb = totalMb > 0 ? totalMb : daemonMax;
    return maxMb < storageLimitMinMb + 100 ? storageLimitMinMb + 100 : maxMb;
  }

  Future<void> load() async {
    SurveillanceConfig? config;
    try {
      final resp = await _surveillanceService.getConfig(pb.GetSurveillanceConfigRequest());
      if (resp.success) {
        final c = resp.config;
        config = SurveillanceConfig(
          enabled: c.enabled,
          distancePreset: c.distancePreset.isNotEmpty ? c.distancePreset : 'OUTDOOR',
          sensitivityLevel: c.sensitivity > 0 ? c.sensitivity : 3,
          detectPerson: c.detectPerson,
          detectCar: c.detectCar,
          detectBike: c.detectBike,
          preRecordSeconds: c.preRecordSeconds > 0 ? c.preRecordSeconds : 5,
          postRecordSeconds: c.postRecordSeconds > 0 ? c.postRecordSeconds : 10,
          nightMode: c.nightMode,
          aiEnabled: c.aiEnabled,
          aiConfidence: c.aiConfidence > 0 ? c.aiConfidence : 0.4,
          cameraFront: c.cameraFront,
          cameraRight: c.cameraRight,
          cameraRear: c.cameraRear,
          cameraLeft: c.cameraLeft,
          deterrentAction: c.deterrentAction.isNotEmpty ? c.deterrentAction : 'silent',
          deterrentCooldownSeconds: c.deterrentCooldownSeconds > 0 ? c.deterrentCooldownSeconds : 60,
        );
      }
    } catch (_) {
      config = null;
    }
    _loadedConfig = config;
    if (config != null) {
      _editEnabled = config.enabled;
      _editPreset = config.distancePreset;
      _editSensitivity = config.sensitivityLevel;
      _editDetectPerson = config.detectPerson;
      _editDetectCar = config.detectCar;
      _editDetectBike = config.detectBike;
      _editPreRecord = config.preRecordSeconds;
      _editPostRecord = config.postRecordSeconds;
      _editNightMode = config.nightMode;
      _editAiEnabled = config.aiEnabled;
      _editCameraFront = config.cameraFront;
      _editCameraRight = config.cameraRight;
      _editCameraRear = config.cameraRear;
      _editCameraLeft = config.cameraLeft;
      _editDeterrent = config.deterrentAction;
      _editDeterrentCooldown = config.deterrentCooldownSeconds;
    }

    // Status is never genuinely absent in native (fetchStatus() always
    // constructs a value) — isRunning/eventsToday default independently so
    // one endpoint failing doesn't blank out the other.
    var isRunning = false;
    var cameraYielded = false;
    try {
      final resp = await _surveillanceService.getStatus(pb.GetSurveillanceStatusRequest());
      isRunning = resp.pipelineRunning || resp.surveillanceActive;
      cameraYielded = resp.cameraYielded;
    } catch (_) {}
    var eventsToday = 0;
    try {
      final resp = await _recordingsService.getStats(GetStatsRequest());
      eventsToday = resp.stats.surveillanceCount;
    } catch (_) {}
    _status = SurveillanceStatus(isRunning: isRunning, eventsToday: eventsToday, cameraYielded: cameraYielded);

    try {
      final resp = await _storageService.getStorageSettings(storage_pb.GetStorageSettingsRequest());
      final s = SurveillanceStorageSettings(
        storageType: resp.surveillanceStorageType.isNotEmpty ? resp.surveillanceStorageType : 'INTERNAL',
        limitMb: resp.surveillanceLimitMb.toInt() > 0 ? resp.surveillanceLimitMb.toInt() : 500,
        surveillanceSizeBytes: resp.surveillanceSizeBytes.toInt(),
        surveillanceCount: resp.surveillanceCount,
        sdCardAvailable: resp.sdCardAvailable,
        path: resp.surveillancePath,
        minLimitMb: resp.minLimitMb.toInt() > 0 ? resp.minLimitMb.toInt() : 100,
        maxLimitMb: resp.maxLimitMb.toInt() > 0 ? resp.maxLimitMb.toInt() : 100000,
        maxLimitMbSdCard: resp.maxLimitMbSdCard.toInt() > 0 ? resp.maxLimitMbSdCard.toInt() : 100000,
        internalTotalMb: resp.internalTotalBytes.toInt() ~/ (1024 * 1024),
        sdCardTotalMb: resp.sdCardTotalBytes.toInt() ~/ (1024 * 1024),
      );
      _storageSettings = s;
      _editStorageType = s.storageType;
      _editStorageLimitMb = s.limitMb.clamp(storageLimitMinMb, storageLimitMaxMb);
    } catch (_) {
      _storageSettings = null;
    }

    try {
      final resp = await _safeLocationsService.listZones(sl.ListZonesRequest());
      _safeLocFeatureEnabled = resp.featureEnabled;
      _safeZones = resp.zones.map((z) => SafeZone(id: z.id, name: z.name, lat: z.lat, lng: z.lng, radiusM: z.radiusM)).toList();
      _currentLat = resp.currentLat;
      _currentLng = resp.currentLng;
    } catch (_) {
      _safeLocFeatureEnabled = false;
      _safeZones = const [];
      _currentLat = 0;
      _currentLng = 0;
    }

    _loading = false;
    notifyListeners();
  }

  // ─────────────────────────── GENERAL ─────────────────────────────────

  /// Ground truth: the Enable Surveillance switch — applies immediately via
  /// Enable/Disable, not gated behind Apply. The settle delay mirrors
  /// native's `Thread.sleep(300)` before re-fetching status.
  Future<void> toggleSurveillance(bool value) async {
    _editEnabled = value;
    notifyListeners();
    try {
      if (value) {
        await _surveillanceService.enable(pb.EnableSurveillanceRequest());
      } else {
        await _surveillanceService.disable(pb.DisableSurveillanceRequest());
      }
    } catch (_) {}
    await Future.delayed(_toggleSettleDelay);
    await load();
  }

  // ─────────────────────────── DETECTION ───────────────────────────────

  /// Ground truth: the Safe Locations switch — applies immediately.
  Future<void> toggleSafeLocations(bool value) async {
    _safeLocFeatureEnabled = value;
    notifyListeners();
    try {
      await _safeLocationsService.toggle(sl.ToggleSafeLocationsRequest(enabled: value, enabledSet: true));
    } catch (_) {}
    await load();
  }

  /// Ground truth: `client.addSafeZone("Safe Zone", currentLat, currentLng,
  /// 150)` — one tap, no name/radius entry (native has no such dialog).
  Future<void> addSafeZoneAtCurrentLocation() async {
    try {
      await _safeLocationsService.addZone(
        sl.AddZoneRequest(name: kDefaultSafeZoneName, lat: _currentLat, lng: _currentLng, radiusM: kDefaultSafeZoneRadiusM),
      );
    } catch (_) {}
    await load();
  }

  Future<void> deleteSafeZone(String id) async {
    try {
      await _safeLocationsService.deleteZone(sl.DeleteZoneRequest(id: id));
    } catch (_) {}
    await load();
  }

  void selectPreset(String preset) {
    _editPreset = preset;
    notifyListeners();
  }

  void selectSensitivity(int level) {
    _editSensitivity = level;
    notifyListeners();
  }

  void setDetectPerson(bool value) {
    _editDetectPerson = value;
    notifyListeners();
  }

  void setDetectCar(bool value) {
    _editDetectCar = value;
    notifyListeners();
  }

  void setDetectBike(bool value) {
    _editDetectBike = value;
    notifyListeners();
  }

  // ─────────────────────────── RECORDING ────────────────────────────────

  void selectPreRecord(int seconds) {
    _editPreRecord = seconds;
    notifyListeners();
  }

  void selectPostRecord(int seconds) {
    _editPostRecord = seconds;
    notifyListeners();
  }

  // ─────────────────────────── ADVANCED ─────────────────────────────────

  void setCameraFront(bool value) {
    _editCameraFront = value;
    notifyListeners();
  }

  void setCameraRight(bool value) {
    _editCameraRight = value;
    notifyListeners();
  }

  void setCameraRear(bool value) {
    _editCameraRear = value;
    notifyListeners();
  }

  void setCameraLeft(bool value) {
    _editCameraLeft = value;
    notifyListeners();
  }

  void setAiEnabled(bool value) {
    _editAiEnabled = value;
    notifyListeners();
  }

  void setNightMode(bool value) {
    _editNightMode = value;
    notifyListeners();
  }

  void selectDeterrent(String action) {
    _editDeterrent = action;
    notifyListeners();
  }

  // ─────────────────────────── STORAGE ─────────────────────────────────

  void selectStorageType(String type) {
    if (type == 'SD_CARD' && !(_storageSettings?.sdCardAvailable ?? false)) return;
    _editStorageType = type;
    _editStorageLimitMb = _editStorageLimitMb.clamp(storageLimitMinMb, storageLimitMaxMb);
    notifyListeners();
  }

  void setStorageLimitMb(int mb) {
    // See SettingsRecordingController.setStorageLimitMb (BladeWatch-htel).
    _editStorageLimitMb = snapStorageMb(mb, storageLimitMinMb, storageLimitMaxMb);
    notifyListeners();
  }

  void startFormat() {
    _formatState = const FormatDriveResult(state: FormatDriveState.confirming);
    notifyListeners();
  }

  void cancelFormat() {
    _formatState = const FormatDriveResult.idle();
    notifyListeners();
  }

  void dismissFormatResult() {
    _formatState = const FormatDriveResult.idle();
    notifyListeners();
  }

  Future<void> confirmFormat() async {
    _formatState = const FormatDriveResult(state: FormatDriveState.running);
    notifyListeners();
    try {
      final volumes = await _storageService.listFormatVolumes(storage_pb.ListFormatVolumesRequest());
      final first = volumes.volumes.where((v) => v.mounted).firstOrNull;
      if (first == null) {
        _formatState = const FormatDriveResult(state: FormatDriveState.failed, message: 'Error: No removable drive found');
      } else {
        final resp = await _storageService.formatVolume(storage_pb.FormatVolumeRequest(volumeId: first.volumeId));
        if (resp.success) {
          _formatState = FormatDriveResult(
            state: FormatDriveState.succeeded,
            message: 'Formatted successfully. New path: ${resp.mountPath.isNotEmpty ? resp.mountPath : "unknown"}',
          );
          await load();
        } else {
          final msg = resp.message.isNotEmpty ? resp.message : (resp.error.isNotEmpty ? resp.error : 'Unknown result');
          _formatState = FormatDriveResult(state: FormatDriveState.failed, message: 'Error: $msg');
        }
      }
    } catch (e) {
      _formatState = FormatDriveResult(state: FormatDriveState.failed, message: 'Error: $e');
    }
    notifyListeners();
  }

  void dismissSyncResult() {
    _syncState = const SyncCatalogResult.idle();
    notifyListeners();
  }

  Future<void> startSync() async {
    _syncState = const SyncCatalogResult(state: SyncDriveState.running);
    notifyListeners();
    try {
      final resp = await _longSurveillanceService.syncCatalog(pb.SyncSurveillanceCatalogRequest());
      if (resp.success) {
        _syncState = SyncCatalogResult(state: SyncDriveState.succeeded, message: 'Synced: +${resp.added} -${resp.removed}');
      } else {
        final err = resp.error;
        _syncState = SyncCatalogResult(
          state: SyncDriveState.failed,
          message: err == 'sync_in_progress' ? 'Sync already in progress' : 'Sync failed: $err',
        );
      }
    } catch (e) {
      _syncState = SyncCatalogResult(state: SyncDriveState.failed, message: '$e');
    }
    notifyListeners();
  }

  // ─────────────────────────── APPLY ────────────────────────────────────

  Future<ApplyResult> applyChanges(SurveillanceSettingsTab tab) async {
    final result = tab == SurveillanceSettingsTab.storage ? await _saveStorage() : await _saveConfig();
    await load();
    return result;
  }

  Future<ApplyResult> _saveConfig() async {
    try {
      final proto = pb.SurveillanceConfig(
        enabled: _editEnabled,
        sensitivity: _editSensitivity,
        distancePreset: _editPreset,
        detectPerson: _editDetectPerson,
        detectCar: _editDetectCar,
        detectBike: _editDetectBike,
        preRecordSeconds: _editPreRecord,
        postRecordSeconds: _editPostRecord,
        nightMode: _editNightMode,
        aiEnabled: _editAiEnabled,
        aiConfidence: _loadedConfig?.aiConfidence ?? 0.4,
        cameraFront: _editCameraFront,
        cameraRight: _editCameraRight,
        cameraRear: _editCameraRear,
        cameraLeft: _editCameraLeft,
        deterrentAction: _editDeterrent,
        deterrentCooldownSeconds: _editDeterrentCooldown,
      );
      final resp = await _surveillanceService.setConfig(pb.SetSurveillanceConfigRequest(config: proto));
      return ApplyResult(ok: resp.success, error: resp.error.isNotEmpty ? resp.error : null);
    } catch (e) {
      return ApplyResult(ok: false, error: '$e');
    }
  }

  Future<ApplyResult> _saveStorage() async {
    try {
      final resp = await _storageService.setStorageSettings(
        storage_pb.SetStorageSettingsRequest(surveillanceStorageType: _editStorageType, surveillanceLimitMb: Int64(_editStorageLimitMb)),
      );
      return ApplyResult(ok: resp.success, error: resp.error.isNotEmpty ? resp.error : null);
    } catch (e) {
      return ApplyResult(ok: false, error: '$e');
    }
  }

  /// BladeWatch-gyg1.6: the Surveillance Storage tab's own version of
  /// RecordingSettingsController.previewStorageLimitImpact (BladeWatch-gyg1.4) -- same
  /// reasoning, same model, ported field-for-field to surveillanceLimitMb/surveillanceImpact.
  /// Returns null when nothing needs confirming: the limit is unchanged or raised, or the
  /// preview itself says nothing would be deleted. Performs no write -- applyChanges(storage)
  /// is still the only path that actually changes the limit.
  Future<StorageLimitImpact?> previewStorageLimitImpact() async {
    final current = _storageSettings?.limitMb;
    if (current == null || _editStorageLimitMb >= current) return null;
    try {
      final resp = await _storageService.previewStorageLimitChange(
        storage_pb.PreviewStorageLimitChangeRequest(surveillanceLimitMb: Int64(_editStorageLimitMb)),
      );
      if (!resp.hasSurveillanceImpact()) return null;
      final impact = resp.surveillanceImpact;
      if (impact.fileCount == 0) return null;
      return StorageLimitImpact.known(fileCount: impact.fileCount, totalBytes: impact.totalBytes.toInt());
    } catch (_) {
      return const StorageLimitImpact.unknown();
    }
  }
}
