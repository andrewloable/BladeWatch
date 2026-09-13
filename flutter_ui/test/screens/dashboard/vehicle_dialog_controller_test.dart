import 'package:bladewatch_ui/rpc/services/system_service_client.dart';
import 'package:bladewatch_ui/screens/dashboard/vehicle_dialog_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_rpc_client.dart';

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
    test('populates the capacity field from GetSohNominal', () async {
      rpc.stubJson('SystemService', 'GetSohNominal', {'nominalKwh': 82.5, 'nominalSource': 'user'});
      rpc.stubJson('SystemService', 'GetSohStatus', {'success': true});
      stubManifest([]);
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      final c = buildController();

      await c.load();

      expect(c.state.capacityText, '82.5');
      expect(c.state.loading, isFalse);
    });

    test('leaves the capacity field blank when no nominal kWh is set', () async {
      rpc.stubJson('SystemService', 'GetSohNominal', {});
      rpc.stubJson('SystemService', 'GetSohStatus', {'success': true});
      stubManifest([]);
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      final c = buildController();

      await c.load();

      expect(c.state.capacityText, '');
    });

    test('populates the model list from the manifest JSON', () async {
      rpc.stubJson('SystemService', 'GetSohNominal', {});
      rpc.stubJson('SystemService', 'GetSohStatus', {'success': true});
      stubManifest([
        {'id': 'seal', 'name': 'BYD Seal', 'nominalKwh': 82.5},
        {'id': 'atto3', 'name': 'BYD Atto 3', 'nominalKwh': 60.5},
      ]);
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      final c = buildController();

      await c.load();

      expect(c.state.models, hasLength(2));
      expect(c.state.models[0].id, 'seal');
      expect(c.state.models[0].title, 'BYD Seal');
      expect(c.state.models[0].nominalKwh, closeTo(82.5, 0.001));
    });

    test('pre-selects the currently selected model', () async {
      rpc.stubJson('SystemService', 'GetSohNominal', {});
      rpc.stubJson('SystemService', 'GetSohStatus', {'success': true});
      stubManifest([
        {'id': 'seal', 'name': 'BYD Seal', 'nominalKwh': 82.5},
      ]);
      rpc.stubJson('SystemService', 'GetSelectedModel', {'modelId': 'seal'});
      final c = buildController();

      await c.load();

      expect(c.state.selectedModelId, 'seal');
    });

    test('does not pre-select a selected model id absent from the manifest', () async {
      rpc.stubJson('SystemService', 'GetSohNominal', {});
      rpc.stubJson('SystemService', 'GetSohStatus', {'success': true});
      stubManifest([
        {'id': 'seal', 'name': 'BYD Seal', 'nominalKwh': 82.5},
      ]);
      rpc.stubJson('SystemService', 'GetSelectedModel', {'modelId': 'not-in-manifest'});
      final c = buildController();

      await c.load();

      expect(c.state.selectedModelId, isNull);
    });

    test('populates the SoH summary from GetSohStatus', () async {
      rpc.stubJson('SystemService', 'GetSohNominal', {});
      rpc.stubJson('SystemService', 'GetSohStatus', {
        'success': true,
        'nominalCapacityKwh': 82.5,
        'nominalSource': 'auto',
        'displaySoh': 97.2,
        'displaySource': 'live',
      });
      stubManifest([]);
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      final c = buildController();

      await c.load();

      expect(c.state.nominalKwh, closeTo(82.5, 0.001));
      expect(c.state.nominalSource, 'auto');
      expect(c.state.displaySoh, closeTo(97.2, 0.001));
      expect(c.state.displaySource, 'live');
      expect(c.state.hasCapacitySummary, isTrue);
      expect(c.state.hasSohSummary, isTrue);
    });

    test('a failed RPC leaves that section at its loading defaults rather than crashing load()', () async {
      rpc.stubError('SystemService', 'GetSohNominal', const ConnectError('unavailable', 'down'));
      rpc.stubError('SystemService', 'GetSohStatus', const ConnectError('unavailable', 'down'));
      rpc.stubError('SystemService', 'GetModelsManifest', const ConnectError('unavailable', 'down'));
      rpc.stubError('SystemService', 'GetSelectedModel', const ConnectError('unavailable', 'down'));
      final c = buildController();

      await c.load();

      expect(c.state.loading, isFalse);
      expect(c.state.capacityText, '');
      expect(c.state.models, isEmpty);
      expect(c.state.hasSohSummary, isFalse);
    });
  });

  group('selectModel()', () {
    test('auto-fills the capacity field with the manifest kWh for the chosen model', () async {
      rpc.stubJson('SystemService', 'GetSohNominal', {});
      rpc.stubJson('SystemService', 'GetSohStatus', {'success': true});
      stubManifest([
        {'id': 'seal', 'name': 'BYD Seal', 'nominalKwh': 82.5},
      ]);
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      final c = buildController();
      await c.load();

      c.selectModel('seal');

      expect(c.state.selectedModelId, 'seal');
      expect(c.state.capacityText, '82.5');
    });

    test('does not touch the capacity field when the model has no manifest kWh', () async {
      rpc.stubJson('SystemService', 'GetSohNominal', {'nominalKwh': 50.0, 'nominalSource': 'user'});
      rpc.stubJson('SystemService', 'GetSohStatus', {'success': true});
      stubManifest([
        {'id': 'mystery', 'name': 'Mystery', 'nominalKwh': 0},
      ]);
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      final c = buildController();
      await c.load();

      c.selectModel('mystery');

      expect(c.state.capacityText, '50.0');
    });

    test('selecting an unknown model id is a no-op', () async {
      rpc.stubJson('SystemService', 'GetSohNominal', {});
      rpc.stubJson('SystemService', 'GetSohStatus', {'success': true});
      stubManifest([]);
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      final c = buildController();
      await c.load();

      c.selectModel('does-not-exist');

      expect(c.state.selectedModelId, isNull);
    });
  });

  test('setCapacityText() updates the field and notifies', () async {
    rpc.stubJson('SystemService', 'GetSohNominal', {});
    rpc.stubJson('SystemService', 'GetSohStatus', {'success': true});
    stubManifest([]);
    rpc.stubJson('SystemService', 'GetSelectedModel', {});
    final c = buildController();
    await c.load();
    var notified = 0;
    c.addListener(() => notified++);

    c.setCapacityText('75.0');

    expect(c.state.capacityText, '75.0');
    expect(notified, 1);
  });

  group('save()', () {
    Future<VehicleDialogController> readyController() async {
      rpc.stubJson('SystemService', 'GetSohNominal', {});
      rpc.stubJson('SystemService', 'GetSohStatus', {'success': true});
      stubManifest([]);
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      final c = buildController();
      await c.load();
      return c;
    }

    test('rejects a non-numeric value without calling any RPC', () async {
      final c = await readyController();
      c.setCapacityText('not a number');

      final result = await c.save();

      expect(result, VehicleSaveResult.invalidCapacity);
      expect(rpc.calls.where((call) => call.method == 'SetSohNominal'), isEmpty);
    });

    test('rejects a value below 8.0 kWh', () async {
      final c = await readyController();
      c.setCapacityText('7.9');

      expect(await c.save(), VehicleSaveResult.invalidCapacity);
    });

    test('rejects a value above 120.0 kWh', () async {
      final c = await readyController();
      c.setCapacityText('120.1');

      expect(await c.save(), VehicleSaveResult.invalidCapacity);
    });

    test('accepts the boundary values 8.0 and 120.0', () async {
      rpc.stubJson('SystemService', 'SetSohNominal', {'success': true});
      final c = await readyController();

      c.setCapacityText('8.0');
      expect(await c.save(), VehicleSaveResult.success);

      c.setCapacityText('120.0');
      expect(await c.save(), VehicleSaveResult.success);
    });

    test('a valid capacity calls SetSohNominal with that value', () async {
      rpc.stubJson('SystemService', 'SetSohNominal', {'success': true});
      final c = await readyController();
      c.setCapacityText('82.5');

      await c.save();

      final call = rpc.calls.firstWhere((call) => call.method == 'SetSohNominal');
      final req = call.request as dynamic;
      expect(req.nominalKwh, closeTo(82.5, 0.001));
    });

    test('also calls SetSelectedModel when a model is selected', () async {
      rpc.stubJson('SystemService', 'SetSohNominal', {'success': true});
      rpc.stubJson('SystemService', 'SetSelectedModel', {'ok': true});
      stubManifest([
        {'id': 'seal', 'name': 'BYD Seal', 'nominalKwh': 82.5},
      ]);
      rpc.stubJson('SystemService', 'GetSohNominal', {});
      rpc.stubJson('SystemService', 'GetSohStatus', {'success': true});
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      final c = buildController();
      await c.load();
      c.selectModel('seal');

      await c.save();

      final call = rpc.calls.firstWhere((call) => call.method == 'SetSelectedModel');
      final req = call.request as dynamic;
      expect(req.modelId, 'seal');
    });

    test('does not call SetSelectedModel when no model is selected', () async {
      rpc.stubJson('SystemService', 'SetSohNominal', {'success': true});
      final c = await readyController();
      c.setCapacityText('82.5');

      await c.save();

      expect(rpc.calls.where((call) => call.method == 'SetSelectedModel'), isEmpty);
    });

    test('returns rpcFailed when SetSohNominal fails, without throwing', () async {
      rpc.stubError('SystemService', 'SetSohNominal', const ConnectError('unavailable', 'down'));
      final c = await readyController();
      c.setCapacityText('82.5');

      expect(await c.save(), VehicleSaveResult.rpcFailed);
    });
  });

  group('reset()', () {
    test('calls SetSohNominal with no value set', () async {
      rpc.stubJson('SystemService', 'SetSohNominal', {'success': true});
      final c = buildController();

      final ok = await c.reset();

      expect(ok, isTrue);
      final call = rpc.calls.single;
      expect(call.method, 'SetSohNominal');
      final req = call.request as dynamic;
      expect(req.hasNominalKwh(), isFalse);
    });

    test('returns false without throwing when the RPC fails', () async {
      rpc.stubError('SystemService', 'SetSohNominal', const ConnectError('unavailable', 'down'));
      final c = buildController();

      expect(await c.reset(), isFalse);
    });
  });
}
