import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../gen/bladewatch/v1/system.pb.dart';
import '../../rpc/services/system_service_client.dart';
import 'dashboard_models.dart';

/// Outcome of [VehicleDialogController.save].
///
/// BladeWatch-p7vi: there is no longer an `invalidCapacity` case — the capacity
/// field is gone, because the daemon's SoH endpoints are removed-feature stubs
/// that refuse every write. [rpcFailed] covers BOTH a thrown transport error and
/// a transport-level success whose body says the write was refused; checking only
/// for a thrown error is what previously reported a rejected save as a success.
enum VehicleSaveResult { success, rpcFailed }

/// Pure-Dart port of `DashboardFragment.showVehicleCapacityDialog()`, reduced to
/// the half that still works.
///
/// BladeWatch-p7vi: battery State-of-Health estimation was removed from the
/// daemon. `handleSohSetNominal`/`handleSohGetNominal` are stubs — the setter
/// refuses every write and the getter always answers "unset" — so the capacity
/// field, its Reset action and the SoH summary offered operations that could not
/// succeed, and were removed rather than left to fail. The vehicle MODEL
/// selection remains, because `ModelsApiHandler` genuinely persists it.
class VehicleDialogController extends ChangeNotifier {
  VehicleDialogController({required SystemServiceClient systemService})
      : _systemService = systemService; // ignore: prefer_initializing_formals

  final SystemServiceClient _systemService;

  VehicleDialogState _state = const VehicleDialogState.loading();
  VehicleDialogState get state => _state;

  String? _lastError;

  /// The daemon's own explanation for the last refused save or reset, or null
  /// when the failure carried none (a thrown transport error) or nothing has
  /// failed. Lets the dialog say WHY rather than showing a generic failure.
  String? get lastError => _lastError;

  /// Loads the model manifest and the current selection. The two SoH reads this
  /// used to make were dropped with the capacity field (BladeWatch-p7vi) —
  /// `GetSohNominal` unconditionally answers "unset" and `GetSohStatus` answers
  /// nothing, so calling them only produced a permanently pending display.
  Future<void> load() async {
    var models = const <VehicleModelEntry>[];
    String? selectedModelId;

    try {
      final resp = await _systemService.getModelsManifest(GetModelsManifestRequest());
      if (resp.manifestJson.isNotEmpty) {
        models = _parseModels(resp.manifestJson);
      }
    } catch (_) {}

    try {
      final resp = await _systemService.getSelectedModel(GetSelectedModelRequest());
      if (resp.modelId.isNotEmpty && models.any((m) => m.id == resp.modelId)) {
        selectedModelId = resp.modelId;
      }
    } catch (_) {}

    _state = VehicleDialogState(loading: false, models: models, selectedModelId: selectedModelId);
    notifyListeners();
  }

  static List<VehicleModelEntry> _parseModels(String manifestJson) {
    final json = jsonDecode(manifestJson);
    if (json is! Map<String, dynamic>) return const [];
    final arr = json['models'];
    if (arr is! List) return const [];
    final entries = <VehicleModelEntry>[];
    for (final raw in arr) {
      if (raw is! Map<String, dynamic>) continue;
      final id = raw['id'] as String? ?? '';
      if (id.isEmpty) continue;
      final name = raw['name'] as String? ?? '';
      final title = raw['title'] as String? ?? '';
      final kwh = (raw['nominalKwh'] as num?)?.toDouble() ?? 0.0;
      entries.add(VehicleModelEntry(id: id, title: name.isNotEmpty ? name : (title.isNotEmpty ? title : id), nominalKwh: kwh));
    }
    return entries;
  }

  VehicleModelEntry? _findModel(String modelId) {
    for (final m in _state.models) {
      if (m.id == modelId) return m;
    }
    return null;
  }

  /// Selecting a model records the choice. It used to auto-fill the capacity
  /// field from the manifest's kWh; that field is gone (BladeWatch-p7vi), and
  /// the manifest kWh is still what the daemon uses internally.
  void selectModel(String modelId) {
    if (_findModel(modelId) == null) return;
    _state = _state.copyWith(selectedModelId: modelId);
    notifyListeners();
  }

  /// Persists the selected model.
  ///
  /// Checks the response's `ok` flag, not merely the absence of a thrown error:
  /// this server answers HTTP 200 with a body saying whether the write landed,
  /// so a refusal never throws. Reporting one as a success is the exact defect
  /// BladeWatch-p7vi was filed for, on the sibling SoH endpoint.
  Future<VehicleSaveResult> save() async {
    final modelId = _state.selectedModelId;
    if (modelId == null || modelId.isEmpty) {
      _lastError = null;
      return VehicleSaveResult.success;
    }
    try {
      final resp = await _systemService.setSelectedModel(SetSelectedModelRequest(modelId: modelId));
      if (!resp.ok) {
        _lastError = resp.error;
        return VehicleSaveResult.rpcFailed;
      }
    } catch (_) {
      _lastError = null;
      return VehicleSaveResult.rpcFailed;
    }
    _lastError = null;
    return VehicleSaveResult.success;
  }
}
