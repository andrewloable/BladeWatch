import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../gen/bladewatch/v1/system.pb.dart';
import '../../rpc/services/system_service_client.dart';
import 'dashboard_models.dart';

/// Outcome of [VehicleDialogController.save] — ground truth:
/// `DashboardFragment`'s positive-button handler (invalid capacity shows a
/// Toast and returns without calling the RPC at all) plus `postNominalAndModel`'s
/// try/catch (an RPC failure is otherwise silent in the native fragment; this
/// port surfaces it so the widget can show its own error state).
enum VehicleSaveResult { success, invalidCapacity, rpcFailed }

/// Pure-Dart port of `DashboardFragment.showVehicleCapacityDialog()`'s
/// pre-populate/save/reset logic (native:
/// app/src/main/java/com/loabletech/bladewatch/ui/fragment/DashboardFragment.kt,
/// lines ~859-1042). SoH-summary-text formatting (nominal-source suffixes,
/// live/calibration/oem/nominal display-source labels) is left to the widget
/// layer, same split as `AccessCodeState.displayValue`/`DaemonsSummaryState` —
/// this controller exposes only the raw fields.
class VehicleDialogController extends ChangeNotifier {
  VehicleDialogController({required SystemServiceClient systemService})
      : _systemService = systemService; // ignore: prefer_initializing_formals

  static const double minCapacityKwh = 8.0;
  static const double maxCapacityKwh = 120.0;

  final SystemServiceClient _systemService;

  VehicleDialogState _state = const VehicleDialogState.loading();
  VehicleDialogState get state => _state;

  /// Loads all four sections in parallel-ish (each independently try/caught,
  /// same as native): capacity input value, SoH summary, model manifest, and
  /// the currently-selected model.
  Future<void> load() async {
    var capacityText = '';
    var nominalKwh = 0.0;
    var nominalSource = 'unset';
    var displaySoh = -1.0;
    var displaySource = 'unavailable';
    var models = const <VehicleModelEntry>[];
    String? selectedModelId;

    try {
      final resp = await _systemService.getSohNominal(GetSohNominalRequest());
      if (resp.hasNominalKwh() && resp.nominalKwh > 0) {
        capacityText = resp.nominalKwh.toStringAsFixed(1);
      }
    } catch (_) {}

    try {
      final resp = await _systemService.getSohStatus(GetSohStatusRequest());
      nominalKwh = resp.nominalCapacityKwh;
      if (resp.nominalSource.isNotEmpty) nominalSource = resp.nominalSource;
      displaySoh = resp.displaySoh;
      if (resp.displaySource.isNotEmpty) displaySource = resp.displaySource;
    } catch (_) {}

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

    _state = VehicleDialogState(
      loading: false,
      models: models,
      selectedModelId: selectedModelId,
      capacityText: capacityText,
      nominalKwh: nominalKwh,
      nominalSource: nominalSource,
      displaySoh: displaySoh,
      displaySource: displaySource,
    );
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

  /// Selecting a model auto-fills the capacity field with its manifest kWh —
  /// ground truth: the dropdown's `setOnItemClickListener` — but only when
  /// the manifest actually has a kWh value for it; otherwise the field is
  /// left untouched.
  void selectModel(String modelId) {
    final entry = _findModel(modelId);
    if (entry == null) return;
    _state = _state.copyWith(
      selectedModelId: modelId,
      capacityText: entry.nominalKwh > 0 ? entry.nominalKwh.toStringAsFixed(1) : null,
    );
    notifyListeners();
  }

  void setCapacityText(String text) {
    _state = _state.copyWith(capacityText: text);
    notifyListeners();
  }

  /// Validates locally first (native: the positive-button handler's
  /// 8.0-120.0 kWh bound, shown as a Toast on failure without ever calling
  /// the RPC), then saves. A `SetSelectedModel` failure is swallowed exactly
  /// like native's independent try/catch — only the capacity RPC failing is
  /// reported back to the caller.
  Future<VehicleSaveResult> save() async {
    final kwh = double.tryParse(_state.capacityText.trim());
    if (kwh == null || kwh < minCapacityKwh || kwh > maxCapacityKwh) {
      return VehicleSaveResult.invalidCapacity;
    }
    try {
      await _systemService.setSohNominal(SetSohNominalRequest(nominalKwh: kwh));
    } catch (_) {
      return VehicleSaveResult.rpcFailed;
    }
    final modelId = _state.selectedModelId;
    if (modelId != null && modelId.isNotEmpty) {
      try {
        await _systemService.setSelectedModel(SetSelectedModelRequest(modelId: modelId));
      } catch (_) {}
    }
    return VehicleSaveResult.success;
  }

  /// Clears the user override — ground truth: the dialog's neutral
  /// ("Reset") button calls `postNominal(null)`, i.e. `SetSohNominal` with no
  /// value set, not the unrelated `ResetSoh` RPC (that one backs a separate,
  /// bulk-reset dialog in `MainActivity`).
  Future<bool> reset() async {
    try {
      await _systemService.setSohNominal(SetSohNominalRequest());
      return true;
    } catch (_) {
      return false;
    }
  }
}
