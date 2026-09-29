import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';

import '../../widgets/storage_limit.dart';

import 'package:bladewatch_rpc/gen/bladewatch/v1/recordings.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/settings.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/storage.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/system.pb.dart' hide RecordingStatus;
import 'package:bladewatch_rpc/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/settings_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/storage_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import 'settings_recording_models.dart';
import '../../shell/disposed_safe_notifier.dart';

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
class RecordingSettingsController extends ChangeNotifier with DisposedSafeNotifier {
  RecordingSettingsController({
    required SystemServiceClient systemService,
    required RecordingsServiceClient recordingsService,
    required SettingsServiceClient settingsService,
    required StorageServiceClient storageService,
  })  : _systemService = systemService, // ignore: prefer_initializing_formals
        _recordingsService = recordingsService, // ignore: prefer_initializing_formals
        _settingsService = settingsService, // ignore: prefer_initializing_formals
        _storageService = storageService; // ignore: prefer_initializing_formals

  // jwtSource / baseUrl / getSender / postSender used to be required for the raw-HTTP
  // telemetry-overlay calls (BladeWatch-qwqq). Those now go through SettingsServiceClient,
  // which owns the transport and mints its own JWT, so they are gone rather than left as
  // dead parameters.
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

  RecordingPriority _selectedPriority = RecordingPriority.reliability;
  RecordingPriority get selectedPriority => _selectedPriority;

  /// BladeWatch-y78o.5: the burned-in telemetry overlay's field checklist for continuous
  /// (drive-mode/proximity) dashcam recording — the only recording type with any observable
  /// overlay today; see this issue's close reason for why surveillance/proximity are not
  /// separately exposed here. Defaults to every field, matching today's behaviour until the
  /// daemon is actually reached.
  Set<OverlayField> _overlayFields = OverlayField.values.toSet();
  Set<OverlayField> get overlayFields => _overlayFields;

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
      _selectedPriority = RecordingPriority.fromValue(resp.recordingPriority.isNotEmpty ? resp.recordingPriority : 'RELIABILITY');
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
        sdCardMountFailed: resp.sdCardMountFailed,
        sdCardMountError: resp.sdCardMountError.isNotEmpty ? resp.sdCardMountError : null,
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

  void selectPriority(RecordingPriority priority) {
    _selectedPriority = priority;
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
    // Snapped to native's 100 MB step so the same drag always yields the same
    // value (BladeWatch-htel).
    _selectedLimitMb = snapStorageMb(mb, storageLimitMinMb, storageLimitMaxMb);
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
      final resp = await _settingsService.setQuality(SetQualityRequest(
        recordingSegmentMinutes: _selectedLimit.minutes,
        recordingPriority: _selectedPriority.value,
      ));
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

  /// BladeWatch-gyg1.4: whether applying the current Storage-tab selections would delete
  /// existing recordings, and if so, how many and how large -- real numbers from the daemon's
  /// own selection algorithm, not an estimate. Returns null when nothing needs confirming:
  /// the limit is unchanged or raised (raising can never delete anything, so no preview call
  /// is even made), or the preview itself says nothing would be deleted. Calls the read-only
  /// PreviewStorageLimitChange RPC -- SetStorageSettings is never called by this method, only
  /// by [applyChanges], and only once the owner has confirmed.
  Future<StorageLimitImpact?> previewStorageLimitImpact() async {
    final current = _storageSettings?.limitMb;
    if (current == null || _selectedLimitMb >= current) return null;
    try {
      final resp = await _storageService
          .previewStorageLimitChange(PreviewStorageLimitChangeRequest(recordingsLimitMb: Int64(_selectedLimitMb)));
      if (!resp.hasRecordingsImpact()) return null;
      final impact = resp.recordingsImpact;
      if (impact.fileCount == 0) return null;
      return StorageLimitImpact.known(fileCount: impact.fileCount, totalBytes: impact.totalBytes.toInt());
    } catch (_) {
      return const StorageLimitImpact.unknown();
    }
  }

  /// Loads the continuous-recording overlay field selection from the daemon. Leaves
  /// [overlayFields] at its current value (defaulting to every field) on any failure —
  /// same defensive posture as [_refreshRecordingStatus]-style loads elsewhere in this app:
  /// a daemon hiccup should not make a settings screen appear to have silently changed the
  /// user's saved choice.
  Future<void> loadOverlayFields() async {
    try {
      final resp = await _settingsService
          .getTelemetryOverlayFields(GetTelemetryOverlayFieldsRequest());
      // The proto models selections as map<string, FieldList>, so each entry wraps its
      // array — an absent "continuous" key means the daemon did not answer, which must
      // leave the saved choice alone rather than clear it.
      final continuous = resp.selections['continuous'];
      if (continuous == null) return;
      final fields = <OverlayField>{};
      for (final name in continuous.fields) {
        final field = OverlayField.fromValue(name);
        if (field != null) fields.add(field);
      }
      _overlayFields = fields;
      notifyListeners();
    } catch (_) {
      // Keep the current (default-all) selection — see doc comment above.
    }
  }

  /// Toggles one field in the continuous-recording overlay checklist. Optimistic (the
  /// checkbox moves immediately) but reverts if the daemon write fails — the `before` set is
  /// captured BEFORE the optimistic update, not after, so revert-on-failure actually restores
  /// the prior state rather than being a no-op.
  Future<void> setOverlayFieldEnabled(OverlayField field, bool enabled) async {
    final before = _overlayFields;
    final next = Set<OverlayField>.from(before);
    if (enabled) {
      next.add(field);
    } else {
      next.remove(field);
    }
    _overlayFields = next;
    notifyListeners();

    try {
      final resp = await _settingsService.setTelemetryOverlayFields(
        SetTelemetryOverlayFieldsRequest(
          type: 'continuous',
          fields: [for (final f in next) f.value],
        ),
      );
      if (!resp.success) {
        _overlayFields = before;
        notifyListeners();
      }
    } catch (_) {
      _overlayFields = before;
      notifyListeners();
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
