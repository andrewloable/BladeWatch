import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import 'package:bladewatch_ui/screens/dashboard/vehicle_dialog_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';

/// BladeWatch-p7vi: this controller lost its whole battery-capacity half.
///
/// The daemon's `handleSohSetNominal`/`handleSohGetNominal` are removed-feature
/// stubs — the setter refuses every write and the getter always answers "unset" —
/// so the capacity field, its Reset action and the SoH summary were offering
/// operations that could not succeed. What remains is the vehicle MODEL
/// selection, which `ModelsApiHandler` genuinely persists.
void main() {
  late FakeRpcClient rpc;

  VehicleDialogController buildController() => VehicleDialogController(systemService: SystemServiceClient(rpc));

  void stubManifest(List<Map<String, Object?>> models) {
    rpc.stubJson('SystemService', 'GetModelsManifest', {
      'manifestJson':
          '{"models":[${models.map((m) => '{"id":"${m['id']}","name":"${m['name']}","nominalKwh":${m['nominalKwh']}}').join(',')}]}',
    });
  }

  setUp(() {
    rpc = FakeRpcClient();
  });

  group('load()', () {
    test('populates the model list and the current selection', () async {
      stubManifest([
        {'id': 'seal', 'name': 'BYD Seal', 'nominalKwh': 82.5},
        {'id': 'dolphin', 'name': 'BYD Dolphin', 'nominalKwh': 44.9},
      ]);
      rpc.stubJson('SystemService', 'GetSelectedModel', {'modelId': 'dolphin'});
      final c = buildController();

      await c.load();

      expect(c.state.loading, isFalse);
      expect(c.state.models.map((m) => m.id), ['seal', 'dolphin']);
      expect(c.state.selectedModelId, 'dolphin');
    });

    test('never calls the removed SOH endpoints', () async {
      // Calling them produced nothing but a permanently pending display.
      stubManifest([]);
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      final c = buildController();

      await c.load();

      expect(rpc.calls.where((call) => call.method == 'GetSohNominal'), isEmpty);
      expect(rpc.calls.where((call) => call.method == 'GetSohStatus'), isEmpty);
    });

    test('ignores a selected model that is not in the manifest', () async {
      stubManifest([
        {'id': 'seal', 'name': 'BYD Seal', 'nominalKwh': 82.5},
      ]);
      rpc.stubJson('SystemService', 'GetSelectedModel', {'modelId': 'not-a-model'});
      final c = buildController();

      await c.load();

      expect(c.state.selectedModelId, isNull);
    });

    test('a failing manifest leaves an empty list rather than crashing', () async {
      rpc.stubError('SystemService', 'GetModelsManifest', const ConnectError('unavailable', 'down'));
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      final c = buildController();

      await c.load();

      expect(c.state.loading, isFalse);
      expect(c.state.models, isEmpty);
    });

    test('malformed manifest JSON yields no models rather than throwing', () async {
      rpc.stubJson('SystemService', 'GetModelsManifest', {'manifestJson': 'not json at all'});
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      final c = buildController();

      await c.load();

      expect(c.state.models, isEmpty);
    });
  });

  group('selectModel()', () {
    Future<VehicleDialogController> readyController() async {
      stubManifest([
        {'id': 'seal', 'name': 'BYD Seal', 'nominalKwh': 82.5},
      ]);
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      final c = buildController();
      await c.load();
      return c;
    }

    test('records the choice and notifies', () async {
      final c = await readyController();
      var notified = 0;
      c.addListener(() => notified++);

      c.selectModel('seal');

      expect(c.state.selectedModelId, 'seal');
      expect(notified, 1);
    });

    test('an unknown model id is ignored', () async {
      final c = await readyController();

      c.selectModel('not-a-model');

      expect(c.state.selectedModelId, isNull);
    });
  });

  group('save()', () {
    Future<VehicleDialogController> readyController() async {
      stubManifest([
        {'id': 'seal', 'name': 'BYD Seal', 'nominalKwh': 82.5},
      ]);
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      final c = buildController();
      await c.load();
      return c;
    }

    test('persists the selected model', () async {
      rpc.stubJson('SystemService', 'SetSelectedModel', {'ok': true});
      final c = await readyController();
      c.selectModel('seal');

      expect(await c.save(), VehicleSaveResult.success);
      final call = rpc.calls.firstWhere((call) => call.method == 'SetSelectedModel');
      expect((call.request as dynamic).modelId, 'seal');
    });

    test('never touches the removed SOH setter', () async {
      rpc.stubJson('SystemService', 'SetSelectedModel', {'ok': true});
      final c = await readyController();
      c.selectModel('seal');

      await c.save();

      expect(rpc.calls.where((call) => call.method == 'SetSohNominal'), isEmpty);
    });

    test('saving with nothing selected is a no-op success', () async {
      final c = await readyController();

      expect(await c.save(), VehicleSaveResult.success);
      expect(rpc.calls.where((call) => call.method == 'SetSelectedModel'), isEmpty);
    });

    // ── The BladeWatch-p7vi defect, on the endpoint that still exists ────────
    // This server answers HTTP 200 with a body saying whether the write landed,
    // so a refusal never throws. Checking only for a thrown error reported a
    // rejected write as a success — which is exactly how the capacity field
    // appeared to save for months while persisting nothing.

    test('an ok:false response is a failure, not a success', () async {
      rpc.stubJson('SystemService', 'SetSelectedModel', {'ok': false, 'error': 'unknown model'});
      final c = await readyController();
      c.selectModel('seal');

      expect(await c.save(), VehicleSaveResult.rpcFailed);
    });

    test("the server's own reason is kept so the dialog can show it", () async {
      rpc.stubJson('SystemService', 'SetSelectedModel', {'ok': false, 'error': 'unknown model'});
      final c = await readyController();
      c.selectModel('seal');

      await c.save();

      expect(c.lastError, 'unknown model');
    });

    test('a later success clears the previous failure reason', () async {
      rpc.stubJson('SystemService', 'SetSelectedModel', {'ok': false, 'error': 'nope'});
      final c = await readyController();
      c.selectModel('seal');
      await c.save();

      rpc.stubJson('SystemService', 'SetSelectedModel', {'ok': true});
      expect(await c.save(), VehicleSaveResult.success);
      expect(c.lastError, isNull);
    });

    test('a thrown transport error is a failure and carries no reason', () async {
      rpc.stubError('SystemService', 'SetSelectedModel', const ConnectError('unavailable', 'down'));
      final c = await readyController();
      c.selectModel('seal');

      expect(await c.save(), VehicleSaveResult.rpcFailed);
      expect(c.lastError, isNull);
    });
  });
}
