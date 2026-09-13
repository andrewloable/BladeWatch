import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';

import '../../gen/bladewatch/v1/recordings.pb.dart';
import '../../gen/bladewatch/v1/settings.pb.dart';
import '../../gen/bladewatch/v1/storage.pb.dart';
import '../../gen/bladewatch/v1/system.pb.dart' hide RecordingStatus;
import '../../rpc/services/recordings_service_client.dart';
import '../../rpc/services/settings_service_client.dart';
import '../../rpc/services/storage_service_client.dart';
import '../../rpc/services/system_service_client.dart';
import 'settings_recording_models.dart';

class ApplyResult {
  final bool ok;
  final String? error;

  const ApplyResult({required this.ok, this.error});
}

/// Ground truth: `RecordingSettingsController.kt` (the shared controller
/// behind BOTH the standalone `recordingSettingsWebFragment` destination and
/// the Settings sub-rail's Recording row — see this task's own "two entry
/// points" note). `BwRoutes` has no slot for a standalone destination not
/// backed by a rail icon, so this Flutter port mounts this controller only
/// from the Settings sub-rail; the native standalone nav destination has no
/// Flutter equivalent surface yet (documented gap, not silently dropped).
class RecordingSettingsController extends ChangeNotifier {
  RecordingSettingsController({
    required SystemServiceClient systemService,
    required RecordingsServiceClient recordingsService,
    required SettingsServiceClient settingsService,
    required StorageServiceClient storageService,
  })  : _systemService = systemService, // ignore: prefer_initializing_formals
        _recordingsService = recordingsService, // ignore: prefer_initializing_formals
        _settingsService = settingsService, // ignore: prefer_initializing_formals
        _storageService = storageService; // ignore: prefer_initializing_formals

  final SystemServiceClient _systemService;
  final RecordingsServiceClient _recordingsService;
  final SettingsServiceClient _settingsService;
  final StorageServiceClient _storageService;

  bool _loading = true;
  bool get loading => _loading;

  RecordingStatus? _status;
  RecordingStatus? get status => _status;

  RecordingStorageSettings? _storageSettings;
  RecordingStorageSettings? get storageSettings => _storageSettings;

  RecordingMode _selectedMode = RecordingMode.none;
  RecordingMode get selectedMode => _selectedMode;

  RecordingQuality _selectedQuality = RecordingQuality.standard;
  RecordingQuality get selectedQuality => _selectedQuality;

  String _selectedCodec = 'H264';

  RecordingLimit _selectedLimit = RecordingLimit.five;
  RecordingLimit get selectedLimit => _selectedLimit;

  String _selectedStorageType = 'INTERNAL';
  String get selectedStorageType => _selectedStorageType;

  int _selectedLimitMb = 500;
  int get selectedLimitMb => _selectedLimitMb;

  bool _dirty = false;
  bool get dirty => _dirty;

  FormatDriveResult _formatState = const FormatDriveResult.idle();
  FormatDriveResult get formatState => _formatState;

  SyncCatalogResult _syncState = const SyncCatalogResult.idle();
  SyncCatalogResult get syncState => _syncState;

  int get storageLimitMinMb => (_storageSettings?.minLimitMb ?? 100).clamp(0, 1 << 30).toInt() < 100
      ? 100
      : (_storageSettings?.minLimitMb ?? 100);

  /// Caps the slider at the physical size of the selected volume; falls back
  /// to the daemon's configured max if the size is unknown (0) — ports
  /// `renderStorage()`'s `totalMb`/`daemonMax`/`maxMb` computation exactly.
  int get storageLimitMaxMb {
    final s = _storageSettings;
    if (s == null) return 100000;
    final totalMb = _selectedStorageType == 'SD_CARD' ? s.sdCardTotalMb : s.internalTotalMb;
    final daemonMax = _selectedStorageType == 'SD_CARD' ? s.maxLimitMbSdCard : s.maxLimitMb;
    final maxMb = totalMb > 0 ? totalMb : daemonMax;
    return maxMb < storageLimitMinMb + 100 ? storageLimitMinMb + 100 : maxMb;
  }

  Future<void> load() async {
    RecordingStatus? status;
    var isRecording = false;
    try {
      final resp = await _systemService.getStatus(GetStatusRequest());
      final rs = resp.recordingStatus;
      isRecording = rs.isRecording;
      final mode = rs.configuredMode.isNotEmpty ? rs.configuredMode : 'NONE';
      var normalCount = 0;
      var proximityCount = 0;
      try {
        final stats = await _recordingsService.getStats(GetStatsRequest());
        normalCount = stats.stats.recordingsCount;
        proximityCount = stats.stats.proximityCount;
      } catch (_) {}
      status = RecordingStatus(currentMode: mode, isRecording: isRecording, normalTodayCount: normalCount, proximityTodayCount: proximityCount);
      _selectedMode = RecordingMode.fromValue(mode);
    } catch (_) {
      status = null;
    }
    _status = status;

    try {
      final resp = await _settingsService.getQuality(GetQualityRequest());
      _selectedQuality = RecordingQuality.fromValue(resp.recordingQuality.isNotEmpty ? resp.recordingQuality : 'STANDARD');
      _selectedCodec = resp.codec.isNotEmpty ? resp.codec : 'H264';
      _selectedLimit = RecordingLimit.fromMinutes(resp.recordingSegmentMinutes > 0 ? resp.recordingSegmentMinutes : 5);
    } catch (_) {}

    try {
      final resp = await _storageService.getStorageSettings(GetStorageSettingsRequest());
      _storageSettings = RecordingStorageSettings(
        storageType: resp.recordingsStorageType.isNotEmpty ? resp.recordingsStorageType : 'INTERNAL',
        limitMb: resp.recordingsLimitMb.toInt() > 0 ? resp.recordingsLimitMb.toInt() : 500,
        recordingsSizeBytes: resp.recordingsSizeBytes.toInt(),
        recordingsCount: resp.recordingsCount,
        sdCardAvailable: resp.sdCardAvailable,
        sdCardFreeFormatted: resp.sdCardFreeFormatted,
        internalFreeFormatted: resp.internalFreeFormatted,
        recordingsPath: resp.recordingsPath,
        minLimitMb: resp.minLimitMb.toInt() > 0 ? resp.minLimitMb.toInt() : 100,
        maxLimitMb: resp.maxLimitMb.toInt() > 0 ? resp.maxLimitMb.toInt() : 100000,
        maxLimitMbSdCard: resp.maxLimitMbSdCard.toInt() > 0 ? resp.maxLimitMbSdCard.toInt() : 100000,
        internalTotalMb: resp.internalTotalBytes.toInt() ~/ (1024 * 1024),
        sdCardTotalMb: resp.sdCardTotalBytes.toInt() ~/ (1024 * 1024),
      );
      _selectedStorageType = _storageSettings!.storageType;
      _selectedLimitMb = _storageSettings!.limitMb.clamp(storageLimitMinMb, storageLimitMaxMb);
    } catch (_) {}

    _dirty = false;
    _loading = false;
    notifyListeners();
  }

  void selectMode(RecordingMode mode) {
    _selectedMode = mode;
    _dirty = true;
    notifyListeners();
  }

  void selectLimit(RecordingLimit limit) {
    _selectedLimit = limit;
    _dirty = true;
    notifyListeners();
  }

  void selectQuality(RecordingQuality quality) {
    _selectedQuality = quality;
    _dirty = true;
    notifyListeners();
  }

  void selectStorageType(String type) {
    if (type == 'SD_CARD' && !(_storageSettings?.sdCardAvailable ?? false)) return;
    _selectedStorageType = type;
    _selectedLimitMb = _selectedLimitMb.clamp(storageLimitMinMb, storageLimitMaxMb);
    _dirty = true;
    notifyListeners();
  }

  void setStorageLimitMb(int mb) {
    _selectedLimitMb = mb.clamp(storageLimitMinMb, storageLimitMaxMb);
    _dirty = true;
    notifyListeners();
  }

  Future<ApplyResult> applyChanges(RecordingSettingsTab tab) async {
    ApplyResult result;
    switch (tab) {
      case RecordingSettingsTab.capture:
        result = await _saveMode();
        if (result.ok) result = await _saveLimit();
      case RecordingSettingsTab.quality:
        result = await _saveQuality();
      case RecordingSettingsTab.storage:
        result = await _saveStorage();
      case RecordingSettingsTab.status:
        result = const ApplyResult(ok: true);
    }
    _dirty = false;
    await load();
    return result;
  }

  Future<ApplyResult> _saveMode() async {
    try {
      final resp = await _settingsService.setRecordingMode(SetRecordingModeRequest(mode: _selectedMode.value));
      return ApplyResult(ok: resp.success, error: resp.error.isNotEmpty ? resp.error : null);
    } catch (e) {
      return ApplyResult(ok: false, error: e.toString());
    }
  }

  Future<ApplyResult> _saveLimit() async {
    try {
      final resp = await _settingsService.setQuality(SetQualityRequest(recordingSegmentMinutes: _selectedLimit.minutes));
      return ApplyResult(ok: resp.success, error: resp.error.isNotEmpty ? resp.error : null);
    } catch (e) {
      return ApplyResult(ok: false, error: e.toString());
    }
  }

  Future<ApplyResult> _saveQuality() async {
    try {
      final resp = await _settingsService.setQuality(SetQualityRequest(recordingQuality: _selectedQuality.value, codec: _selectedCodec));
      final err = resp.error.isNotEmpty ? resp.error : (!resp.success && resp.message.isNotEmpty ? resp.message : null);
      return ApplyResult(ok: resp.success, error: err);
    } catch (e) {
      return ApplyResult(ok: false, error: e.toString());
    }
  }

  Future<ApplyResult> _saveStorage() async {
    try {
      final resp = await _storageService.setStorageSettings(
          SetStorageSettingsRequest(recordingsStorageType: _selectedStorageType, recordingsLimitMb: Int64(_selectedLimitMb)));
      return ApplyResult(ok: resp.success, error: resp.error.isNotEmpty ? resp.error : null);
    } catch (e) {
      return ApplyResult(ok: false, error: e.toString());
    }
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
      final volumes = await _storageService.listFormatVolumes(ListFormatVolumesRequest());
      final first = volumes.volumes.where((v) => v.mounted).firstOrNull;
      if (first == null) {
        _formatState = const FormatDriveResult(state: FormatDriveState.failed, message: 'No removable drive found');
      } else {
        final resp = await _storageService.formatVolume(FormatVolumeRequest(volumeId: first.volumeId));
        _formatState = resp.success
            ? FormatDriveResult(state: FormatDriveState.succeeded, message: resp.mountPath)
            : FormatDriveResult(state: FormatDriveState.failed, message: resp.error.isNotEmpty ? resp.error : resp.message);
        if (resp.success) await load();
      }
    } catch (e) {
      _formatState = FormatDriveResult(state: FormatDriveState.failed, message: e.toString());
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
      final resp = await _recordingsService.syncCatalog(SyncCatalogRequest());
      _syncState = resp.success
          ? SyncCatalogResult(state: SyncDriveState.succeeded, message: 'added=${resp.added} removed=${resp.removed}')
          : SyncCatalogResult(state: SyncDriveState.failed, message: resp.error);
    } catch (e) {
      _syncState = SyncCatalogResult(state: SyncDriveState.failed, message: e.toString());
    }
    notifyListeners();
  }
}
