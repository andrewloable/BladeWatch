import 'package:bladewatch_ui/gen/bladewatch/v1/system.pb.dart' show SetSelectedModelRequest;
import 'package:bladewatch_ui/gen/bladewatch/v1/vehicle.pb.dart'
    show MoveWindowRequest, SetClimateRequest, SetMediaVolumeRequest, SetScreenRequest, SetSeatRequest;
import 'package:bladewatch_ui/rpc/services/system_service_client.dart';
import 'package:bladewatch_ui/rpc/services/vehicle_service_client.dart';
import 'package:bladewatch_ui/screens/vehicle/vehicle_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_rpc_client.dart';

void main() {
  late FakeRpcClient rpc;
  late int fakeNow;

  VehicleController build() => VehicleController(
        vehicleService: VehicleServiceClient(rpc),
        systemService: SystemServiceClient(rpc),
        nowMs: () => fakeNow,
      );

  void stubState({
    bool success = true,
    int doorsOverall = 1,
    int lf = 0,
    int rf = 0,
    int lr = 0,
    int rr = 0,
    int sunroof = -1,
    int sunshade = -1,
    bool capSunroof = false,
    bool capSunshade = false,
    bool capDriverHeat = false,
    bool capPassengerHeat = false,
    bool capDriverCool = false,
    bool capPassengerCool = false,
    bool capDriverMemory = false,
    int soc = 50,
    int rangeKm = 36,
    List<int> heat = const [0, 0],
    List<int> cool = const [0, 0],
    bool acOn = false,
    int setpointC = 22,
    double insideTempC = 0.0,
    int fanLevel = 3,
    bool maxCooling = false,
    int mediaVolumePercent = 40,
    bool mediaMuted = false,
    Map<String, Object?> flTyre = const {},
  }) {
    rpc.stubJson('VehicleService', 'GetState', {
      'success': success,
      'doors': {'overall': doorsOverall, 'lf': 0, 'rf': 0, 'lr': 0, 'rr': 0},
      'windows': {'lf': lf, 'rf': rf, 'lr': lr, 'rr': rr, 'sunroof': sunroof, 'sunshade': sunshade},
      'capabilities': {
        'windows': {'sunroof': capSunroof, 'sunshade': capSunshade},
        'seats': {
          'driverHeat': capDriverHeat,
          'passengerHeat': capPassengerHeat,
          'driverCool': capDriverCool,
          'passengerCool': capPassengerCool,
          'driverMemoryRecall': capDriverMemory,
        },
      },
      'battery': {'soc': soc, 'rangeKm': rangeKm},
      'seats': {'heat': heat, 'cool': cool},
      'climate': {'acOn': acOn, 'setpointC': setpointC, 'insideTempC': insideTempC, 'fanLevel': fanLevel, 'maxCooling': maxCooling},
      'mediaVolumePercent': mediaVolumePercent,
      'mediaMuted': mediaMuted,
      'tyres': {
        'fl': flTyre,
        'fr': <String, Object?>{},
        'rl': <String, Object?>{},
        'rr': <String, Object?>{},
      },
    });
  }

  setUp(() {
    rpc = FakeRpcClient();
    fakeNow = 1000000;
  });

  test('nowMs defaults to the real wall clock when not injected', () async {
    final c = VehicleController(vehicleService: VehicleServiceClient(rpc), systemService: SystemServiceClient(rpc));
    // The SUBJECT here is the real-clock lambda, reached through the debounce
    // check inside incTemp(). The RPC is unstubbed, so it throws.
    //
    // This used to assert `setpointC == 23` — that the optimistic value SURVIVED
    // a failed command. That was the fire-and-forget bug, not the clock. It now
    // asserts what the test is actually for: the call got past the debounce and
    // attempted the RPC, which is only possible if the default clock works.
    final error = await c.incTemp();

    expect(error, isNotNull, reason: 'got past the debounce and the RPC failed');
    expect(c.setpointC, 22, reason: 'a failed command reverts');
  });

  group('load()/poll()', () {
    test('happy path populates state', () async {
      stubState(doorsOverall: 2, lf: 30, soc: 62, rangeKm: 210, heat: [1, 2], cool: [0, 0], acOn: true, setpointC: 24, fanLevel: 5);
      final c = build();

      await c.load();

      expect(c.loading, isFalse);
      expect(c.state.loaded, isTrue);
      expect(c.state.doors.overall, 2);
      expect(c.state.windows.lf, 30);
      expect(c.state.battery.soc, 62);
      expect(c.state.battery.rangeKm, 210);
      expect(c.driverHeat, 1);
      expect(c.passengerHeat, 2);
      expect(c.acOn, isTrue);
      expect(c.setpointC, 24);
      expect(c.fanLevel, 5);
    });

    test('window value 255 sanitizes to -1 (unknown)', () async {
      stubState(lf: 255);
      final c = build();
      await c.load();
      expect(c.state.windows.lf, -1);
    });

    test('window value below -1 sanitizes to -1', () async {
      rpc.stubJson('VehicleService', 'GetState', {
        'success': true,
        'doors': {},
        'windows': {'lf': -5, 'rf': 0, 'lr': 0, 'rr': 0, 'sunroof': -1, 'sunshade': -1},
        'capabilities': {
          'windows': {},
          'seats': {},
        },
        'battery': {},
        'seats': {'heat': [], 'cool': []},
        'climate': {},
        'tyres': {'fl': {}, 'fr': {}, 'rl': {}, 'rr': {}},
      });
      final c = build();
      await c.load();
      expect(c.state.windows.lf, -1);
    });

    test('tyre zero-valued fields map to null (unset sentinel)', () async {
      stubState(flTyre: {'kPa': 0, 'psi': 0.0, 'temperatureC': 0, 'pressureState': 0, 'airLeakState': 0, 'signalState': 0});
      final c = build();
      await c.load();
      expect(c.state.tyres.fl.psi, isNull);
      expect(c.state.tyres.fl.kPa, isNull);
      expect(c.state.tyres.fl.temperatureC, isNull);
    });

    test('tyre real values map through', () async {
      stubState(flTyre: {'kPa': 250, 'psi': 36.3, 'temperatureC': 29, 'pressureState': 0, 'airLeakState': 0, 'signalState': 0});
      final c = build();
      await c.load();
      expect(c.state.tyres.fl.psi, 36.3);
      expect(c.state.tyres.fl.kPa, 250);
      expect(c.state.tyres.fl.temperatureC, 29);
    });

    test('insideTempC 0.0 maps to null (unset sentinel)', () async {
      stubState(insideTempC: 0.0);
      final c = build();
      await c.load();
      expect(c.state.climate.insideTempC, isNull);
    });

    test('insideTempC real value maps through', () async {
      stubState(insideTempC: 26.5);
      final c = build();
      await c.load();
      expect(c.state.climate.insideTempC, 26.5);
    });

    test('resp.success:false counts as a failure and keeps old state', () async {
      stubState(doorsOverall: 1);
      final c = build();
      await c.load();
      stubState(success: false, doorsOverall: 2);

      await c.poll();

      expect(c.state.doors.overall, 1);
    });

    test('GetState throwing counts as a failure and keeps old state', () async {
      stubState(doorsOverall: 1);
      final c = build();
      await c.load();
      rpc.stubError('VehicleService', 'GetState', const ConnectError('unavailable', 'down'));

      await c.poll();

      expect(c.state.doors.overall, 1);
      expect(c.hasError, isFalse);
    });

    test('hasError becomes true only after 3 consecutive failures', () async {
      final c = build();
      rpc.stubError('VehicleService', 'GetState', const ConnectError('unavailable', 'down'));

      await c.load();
      expect(c.hasError, isFalse);
      await c.poll();
      expect(c.hasError, isFalse);
      await c.poll();
      expect(c.hasError, isTrue);
    });

    test('a success after failures resets the fail count', () async {
      final c = build();
      rpc.stubError('VehicleService', 'GetState', const ConnectError('unavailable', 'down'));
      await c.load();
      await c.poll();

      stubState();
      await c.poll();
      rpc.stubError('VehicleService', 'GetState', const ConnectError('unavailable', 'down'));
      await c.poll();
      await c.poll();

      expect(c.hasError, isFalse);
    });
  });

  group('appearance', () {
    void stubManifest() {
      rpc.stubJson('SystemService', 'GetModelsManifest', {
        'manifestJson': '{"models":[{"id":"seal5-dmi-dynamic","name":"BYD Seal 5 DM-i Dynamic","file":"destroyer.glb","bundled":true},'
            '{"id":"tang","name":"BYD Tang","file":"tang.glb","bundled":true}]}',
      });
    }

    test('happy path applies the saved model/color and parses the manifest', () async {
      rpc.stubJson('SystemService', 'GetSelectedModel', {'modelId': 'tang', 'color': '#C8102E'});
      stubManifest();
      final c = build();

      await c.loadAppearance();

      expect(c.selectedModelId, 'tang');
      expect(c.selectedColor, '#C8102E');
      expect(c.manifestModels, hasLength(2));
      expect(c.selectedModelFile, 'tang.glb');
      expect(c.selectedModelEntry?.name, 'BYD Tang');
    });

    test('empty modelId and color leaves defaults untouched', () async {
      rpc.stubJson('SystemService', 'GetSelectedModel', {'modelId': '', 'color': ''});
      stubManifest();
      final c = build();

      await c.loadAppearance();

      expect(c.selectedModelId, 'seal5-dmi-dynamic');
      expect(c.selectedColor, '#E8E8EC');
    });

    test('GetSelectedModel throwing leaves defaults untouched', () async {
      rpc.stubError('SystemService', 'GetSelectedModel', const ConnectError('unavailable', 'down'));
      stubManifest();
      final c = build();

      await c.loadAppearance();

      expect(c.selectedModelId, 'seal5-dmi-dynamic');
      expect(c.manifestModels, hasLength(2));
    });

    test('GetModelsManifest throwing leaves the model list empty', () async {
      rpc.stubJson('SystemService', 'GetSelectedModel', {'modelId': '', 'color': ''});
      rpc.stubError('SystemService', 'GetModelsManifest', const ConnectError('unavailable', 'down'));
      final c = build();

      await c.loadAppearance();

      expect(c.manifestModels, isEmpty);
    });

    test('a manifest entry with no file falls back to "<id>.glb"', () async {
      rpc.stubJson('SystemService', 'GetSelectedModel', {'modelId': '', 'color': ''});
      rpc.stubJson('SystemService', 'GetModelsManifest', {
        'manifestJson': '{"models":[{"id":"dolphin","name":"BYD Dolphin"}]}',
      });
      final c = build();

      await c.loadAppearance();

      expect(c.manifestModels.single.file, 'dolphin.glb');
      expect(c.manifestModels.single.bundled, isFalse);
    });

    test('selectedModelFile falls back to the default GLB when the id is unknown', () async {
      final c = build();
      expect(c.selectedModelFile, 'destroyer.glb');
    });

    test('selectedModelEntry is null when the manifest is empty', () async {
      final c = build();
      expect(c.selectedModelEntry, isNull);
    });

    test('selectColor is a no-op when unchanged', () async {
      final c = build();
      await c.selectColor(c.selectedColor);
      expect(rpc.calls, isEmpty);
    });

    test('selectColor updates and calls SetSelectedModel', () async {
      rpc.stubJson('SystemService', 'SetSelectedModel', {'ok': true});
      final c = build();

      await c.selectColor('#1A1A1E');

      expect(c.selectedColor, '#1A1A1E');
      final req = rpc.calls.single.request as SetSelectedModelRequest;
      expect(req.color, '#1A1A1E');
    });

    test('selectColor reverts and reports when the write fails', () async {
      rpc.stubError('SystemService', 'SetSelectedModel', const ConnectError('unavailable', 'down'));
      final c = build();
      final before = c.selectedColor;

      // Was: "does not crash (already applied optimistically)" — asserting the
      // new value should SURVIVE a failed write. BladeWatch-p7vi fixed exactly
      // this on the dialog's call site and missed this one.
      expect(await c.selectColor('#1A1A1E'), isNotNull);
      expect(c.selectedColor, before, reason: 'a failed write must not keep the selection');
    });

    test('selectModel is a no-op when unchanged', () async {
      final c = build();
      await c.selectModel(c.selectedModelId);
      expect(rpc.calls, isEmpty);
    });

    test('selectModel updates and calls SetSelectedModel', () async {
      rpc.stubJson('SystemService', 'SetSelectedModel', {'ok': true});
      final c = build();

      await c.selectModel('tang');

      expect(c.selectedModelId, 'tang');
      final req = rpc.calls.single.request as SetSelectedModelRequest;
      expect(req.modelId, 'tang');
    });

    test('selectModel reverts and reports when the write fails', () async {
      rpc.stubError('SystemService', 'SetSelectedModel', const ConnectError('unavailable', 'down'));
      final c = build();
      final before = c.selectedModelId;

      // Was: "does not crash" with expect(c.selectedModelId, 'tang') — the model
      // was meant to STAY selected after the write failed.
      expect(await c.selectModel('tang'), isNotNull);
      expect(c.selectedModelId, before, reason: 'a failed write must not keep the selection');
    });

    // The refusal path: SetSelectedModel answers ok:false rather than throwing.
    test('a REFUSED appearance write reverts', () async {
      rpc.stubJson('SystemService', 'SetSelectedModel', {'ok': false, 'error': 'Model not available'});
      final c = build();
      final before = c.selectedColor;

      expect(await c.selectColor('#1A1A1E'), 'Model not available');
      expect(c.selectedColor, before);
    });
  });

  group('climate: AC toggle', () {
    test('turning on succeeds and sends power_on with the current setpoint', () async {
      stubState(acOn: false, setpointC: 24);
      rpc.stubJson('VehicleService', 'SetClimate', {'success': true});
      final c = build();
      await c.load();

      final error = await c.toggleAc();

      expect(error, isNull);
      expect(c.acOn, isTrue);
      final req = rpc.calls.last.request as SetClimateRequest;
      expect(req.action, 'power_on');
      expect(req.on, isTrue);
      expect(req.setpointC, 24.0);
    });

    test('turning off succeeds and sends power_off', () async {
      stubState(acOn: true);
      rpc.stubJson('VehicleService', 'SetClimate', {'success': true});
      final c = build();
      await c.load();

      await c.toggleAc();

      final req = rpc.calls.last.request as SetClimateRequest;
      expect(req.action, 'power_off');
      expect(req.on, isFalse);
    });

    test('a failure reverts the optimistic state and returns the message', () async {
      stubState(acOn: false);
      rpc.stubJson('VehicleService', 'SetClimate', {'success': false, 'message': 'AC busy'});
      final c = build();
      await c.load();

      final error = await c.toggleAc();

      expect(error, 'AC busy');
      expect(c.acOn, isFalse);
    });

    test('throwing reverts the optimistic state and returns the exception text', () async {
      stubState(acOn: false);
      rpc.stubError('VehicleService', 'SetClimate', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();

      final error = await c.toggleAc();

      expect(error, isNotNull);
      expect(c.acOn, isFalse);
    });

    test('is debounced within 600ms', () async {
      stubState();
      rpc.stubJson('VehicleService', 'SetClimate', {'success': true});
      final c = build();
      await c.load();

      await c.toggleAc();
      final callsAfterFirst = rpc.calls.length;
      await c.toggleAc();

      expect(rpc.calls.length, callsAfterFirst);
    });
  });

  group('screen toggle (BladeWatch-2000.3)', () {
    test('defaults to on, and turning off sends on=false', () async {
      stubState();
      rpc.stubJson('VehicleService', 'SetScreen', {'success': true});
      final c = build();
      await c.load();
      expect(c.screenOn, isTrue);

      final error = await c.toggleScreen();

      expect(error, isNull);
      expect(c.screenOn, isFalse);
      final req = rpc.calls.last.request as SetScreenRequest;
      expect(req.on, isFalse);
    });

    test('a failure (e.g. blocked by the motion interlock) reverts the optimistic state', () async {
      stubState();
      rpc.stubJson('VehicleService', 'SetScreen', {'success': false, 'message': 'Blocked while moving'});
      final c = build();
      await c.load();

      final error = await c.toggleScreen();

      expect(error, 'Blocked while moving');
      expect(c.screenOn, isTrue);
    });

    test('throwing reverts the optimistic state and returns the exception text', () async {
      stubState();
      rpc.stubError('VehicleService', 'SetScreen', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();

      final error = await c.toggleScreen();

      expect(error, isNotNull);
      expect(c.screenOn, isTrue);
    });

    test('is debounced within 600ms', () async {
      stubState();
      rpc.stubJson('VehicleService', 'SetScreen', {'success': true});
      final c = build();
      await c.load();

      await c.toggleScreen();
      final callsAfterFirst = rpc.calls.length;
      await c.toggleScreen();

      expect(rpc.calls.length, callsAfterFirst);
    });
  });

  group('media volume (BladeWatch-2000.2)', () {
    test('load reads the real server value, not a local guess', () async {
      stubState(mediaVolumePercent: 73, mediaMuted: true);
      final c = build();

      await c.load();

      expect(c.mediaVolumePercent, 73);
      expect(c.mediaMuted, isTrue);
    });

    test('stepVolumeUp sends step_up and optimistically increases by 5', () async {
      stubState(mediaVolumePercent: 40);
      rpc.stubJson('VehicleService', 'SetMediaVolume', {'success': true});
      final c = build();
      await c.load();

      final error = await c.stepVolumeUp();

      expect(error, isNull);
      expect(c.mediaVolumePercent, 45);
      final req = rpc.calls.last.request as SetMediaVolumeRequest;
      expect(req.action, 'step_up');
    });

    test('stepVolumeDown sends step_down and optimistically decreases by 5', () async {
      stubState(mediaVolumePercent: 40);
      rpc.stubJson('VehicleService', 'SetMediaVolume', {'success': true});
      final c = build();
      await c.load();

      final error = await c.stepVolumeDown();

      expect(error, isNull);
      expect(c.mediaVolumePercent, 35);
      final req = rpc.calls.last.request as SetMediaVolumeRequest;
      expect(req.action, 'step_down');
    });

    test('toggleMute sends mute then unmute in turn', () async {
      stubState(mediaVolumePercent: 40, mediaMuted: false);
      rpc.stubJson('VehicleService', 'SetMediaVolume', {'success': true});
      final c = build();
      await c.load();

      await c.toggleMute();
      expect(c.mediaMuted, isTrue);
      expect((rpc.calls.last.request as SetMediaVolumeRequest).action, 'mute');
    });

    test('a failure reverts the optimistic percent and mute state', () async {
      stubState(mediaVolumePercent: 40, mediaMuted: false);
      rpc.stubJson('VehicleService', 'SetMediaVolume', {'success': false, 'message': 'busy'});
      final c = build();
      await c.load();

      final error = await c.toggleMute();

      expect(error, 'busy');
      expect(c.mediaMuted, isFalse);
    });

    test('throwing reverts the optimistic state and returns the exception text', () async {
      stubState(mediaVolumePercent: 40);
      rpc.stubError('VehicleService', 'SetMediaVolume', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();

      final error = await c.stepVolumeUp();

      expect(error, isNotNull);
      expect(c.mediaVolumePercent, 40);
    });

    test('stepVolumeUp is debounced within 600ms', () async {
      stubState(mediaVolumePercent: 40);
      rpc.stubJson('VehicleService', 'SetMediaVolume', {'success': true});
      final c = build();
      await c.load();

      await c.stepVolumeUp();
      final callsAfterFirst = rpc.calls.length;
      await c.stepVolumeUp();

      expect(rpc.calls.length, callsAfterFirst);
    });
  });

  group('defrosters (BladeWatch-2000.1)', () {
    test('toggleFrontDefrost sends action=front_defrost on=true', () async {
      stubState();
      rpc.stubJson('VehicleService', 'SetClimate', {'success': true});
      final c = build();
      await c.load();
      expect(c.frontDefrostOn, isFalse);

      final error = await c.toggleFrontDefrost();

      expect(error, isNull);
      expect(c.frontDefrostOn, isTrue);
      final req = rpc.calls.last.request as SetClimateRequest;
      expect(req.action, 'front_defrost');
      expect(req.on, isTrue);
    });

    test('toggleRearDefrost sends action=rear_defrost on=true, independent of front', () async {
      stubState();
      rpc.stubJson('VehicleService', 'SetClimate', {'success': true});
      final c = build();
      await c.load();

      final error = await c.toggleRearDefrost();

      expect(error, isNull);
      expect(c.rearDefrostOn, isTrue);
      expect(c.frontDefrostOn, isFalse);
      final req = rpc.calls.last.request as SetClimateRequest;
      expect(req.action, 'rear_defrost');
      expect(req.on, isTrue);
    });

    test('a failure (e.g. blocked by the motion interlock) reverts front defrost', () async {
      stubState();
      rpc.stubJson('VehicleService', 'SetClimate', {'success': false, 'message': 'Blocked while moving'});
      final c = build();
      await c.load();

      final error = await c.toggleFrontDefrost();

      expect(error, 'Blocked while moving');
      expect(c.frontDefrostOn, isFalse);
    });

    test('throwing reverts rear defrost and returns the exception text', () async {
      stubState();
      rpc.stubError('VehicleService', 'SetClimate', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();

      final error = await c.toggleRearDefrost();

      expect(error, isNotNull);
      expect(c.rearDefrostOn, isFalse);
    });

    test('front and rear defrost debounce independently', () async {
      stubState();
      rpc.stubJson('VehicleService', 'SetClimate', {'success': true});
      final c = build();
      await c.load();

      await c.toggleFrontDefrost();
      final callsAfterFront = rpc.calls.length;
      final error = await c.toggleRearDefrost();

      expect(error, isNull);
      expect(rpc.calls.length, callsAfterFront + 1, reason: 'rear must not be blocked by front\'s debounce key');
    });
  });

  group('climate: max cooling', () {
    test('enabling succeeds and jumps the local display to 17C/level 7', () async {
      stubState(acOn: false, setpointC: 24, fanLevel: 3, maxCooling: false);
      rpc.stubJson('VehicleService', 'SetClimate', {'success': true});
      final c = build();
      await c.load();

      final error = await c.toggleMaxCooling();

      expect(error, isNull);
      expect(c.maxCooling, isTrue);
      expect(c.acOn, isTrue);
      expect(c.setpointC, 17);
      expect(c.fanLevel, 7);
      final req = rpc.calls.last.request as SetClimateRequest;
      expect(req.action, 'max_cooling');
      expect(req.maxCooling, isTrue);
      expect(req.restoreAcOn, isFalse);
      expect(req.restoreTempC, 24.0);
      expect(req.restoreFanLevel, 3);
    });

    test('disabling succeeds without jumping temp/fan', () async {
      stubState(maxCooling: true, setpointC: 17, fanLevel: 7);
      rpc.stubJson('VehicleService', 'SetClimate', {'success': true});
      final c = build();
      await c.load();

      await c.toggleMaxCooling();

      expect(c.maxCooling, isFalse);
      expect(c.setpointC, 17);
    });

    test('a failure reverts maxCooling and returns the message', () async {
      stubState(maxCooling: false);
      rpc.stubJson('VehicleService', 'SetClimate', {'success': false, 'message': 'rejected'});
      final c = build();
      await c.load();

      final error = await c.toggleMaxCooling();

      expect(error, 'rejected');
      expect(c.maxCooling, isFalse);
    });

    test('throwing reverts maxCooling', () async {
      stubState(maxCooling: false);
      rpc.stubError('VehicleService', 'SetClimate', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();

      final error = await c.toggleMaxCooling();

      expect(error, isNotNull);
      expect(c.maxCooling, isFalse);
    });
  });

  // These used to be "fire-and-forget": the stepper applied the new value
  // optimistically, sent the command, and discarded the outcome. The daemon
  // answers HTTP 200 with success:false when it REFUSES a command, so nothing
  // threw, nothing reverted, and the driver saw 25 C while the car stayed at 24.
  // The same defect BladeWatch-p7vi fixed on the SoH writes.
  //
  // The first test below is why it survived: it stubbed {'success': false} and
  // then asserted the value STAYED — encoding the bug as the expectation.
  group('climate: temp/fan steppers', () {
    test('incTemp increases and sends set_temp', () async {
      stubState(setpointC: 24);
      rpc.stubJson('VehicleService', 'SetClimate', {'success': true});
      final c = build();
      await c.load();

      expect(await c.incTemp(), isNull);

      expect(c.setpointC, 25);
      final req = rpc.calls.last.request as SetClimateRequest;
      expect(req.action, 'set_temp');
      expect(req.setpointC, 25.0);
    });

    // THE bug. The daemon returns 200 with success:false to refuse; nothing
    // throws, so a catch-only guard never runs.
    test('a REFUSED set_temp reverts the optimistic value', () async {
      stubState(setpointC: 24);
      rpc.stubJson('VehicleService', 'SetClimate', {'success': false, 'message': 'Climate unavailable'});
      final c = build();
      await c.load();

      expect(await c.incTemp(), 'Climate unavailable');
      expect(c.setpointC, 24, reason: 'a refused command must not leave 25 on screen');
    });

    test('a REFUSED set_fan reverts the optimistic value', () async {
      stubState(fanLevel: 3);
      rpc.stubJson('VehicleService', 'SetClimate', {'success': false});
      final c = build();
      await c.load();

      await c.incFan();
      expect(c.fanLevel, 3, reason: 'a refused command must not leave 4 on screen');
    });

    test('incTemp is clamped at 33 and does not call the RPC past the bound', () async {
      stubState(setpointC: 33);
      final c = build();
      await c.load();
      final callsBefore = rpc.calls.length;

      await c.incTemp();

      expect(c.setpointC, 33);
      expect(rpc.calls.length, callsBefore);
    });

    test('decTemp decreases and is clamped at 17', () async {
      stubState(setpointC: 17);
      final c = build();
      await c.load();
      final callsBefore = rpc.calls.length;

      await c.decTemp();

      expect(c.setpointC, 17);
      expect(rpc.calls.length, callsBefore);
    });

    test('decTemp above the floor sends set_temp', () async {
      stubState(setpointC: 20);
      rpc.stubJson('VehicleService', 'SetClimate', {'success': true});
      final c = build();
      await c.load();

      await c.decTemp();

      expect(c.setpointC, 19);
    });

    test('a THROWN failure reverts and reports, rather than being swallowed', () async {
      stubState(setpointC: 24);
      rpc.stubError('VehicleService', 'SetClimate', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();

      // Was: `await c.incTemp(); expect(c.setpointC, 25);` — the old assertion
      // said the value should stay at 25 after the command FAILED.
      expect(await c.incTemp(), isNotNull, reason: 'the caller needs something to show');
      expect(c.setpointC, 24, reason: 'a failed command must not leave 25 on screen');
    });

    test('incFan increases and is clamped at 7', () async {
      stubState(fanLevel: 7);
      final c = build();
      await c.load();
      final callsBefore = rpc.calls.length;

      await c.incFan();

      expect(c.fanLevel, 7);
      expect(rpc.calls.length, callsBefore);
    });

    test('incFan below the ceiling sends set_fan', () async {
      stubState(fanLevel: 3);
      rpc.stubJson('VehicleService', 'SetClimate', {'success': true});
      final c = build();
      await c.load();

      await c.incFan();

      expect(c.fanLevel, 4);
      final req = rpc.calls.last.request as SetClimateRequest;
      expect(req.action, 'set_fan');
      expect(req.fanLevel, 4);
    });

    test('decFan decreases and is clamped at 1', () async {
      stubState(fanLevel: 1);
      final c = build();
      await c.load();
      final callsBefore = rpc.calls.length;

      await c.decFan();

      expect(c.fanLevel, 1);
      expect(rpc.calls.length, callsBefore);
    });

    test('decFan above the floor sends set_fan', () async {
      stubState(fanLevel: 3);
      rpc.stubJson('VehicleService', 'SetClimate', {'success': true});
      final c = build();
      await c.load();

      await c.decFan();

      expect(c.fanLevel, 2);
    });

    test('a THROWN fan failure reverts and reports', () async {
      stubState(fanLevel: 3);
      rpc.stubError('VehicleService', 'SetClimate', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();

      expect(await c.decFan(), isNotNull);
      expect(c.fanLevel, 3, reason: 'a failed command must not leave 2 on screen');
    });
  });

  group('seats: heat/cool cycle (fire-and-forget)', () {
    test('driver heat cycles 0->1->2->0 and clears vent when turning on', () async {
      stubState(heat: [0, 0], cool: [1, 0]);
      rpc.stubJson('VehicleService', 'SetSeat', {'success': true});
      final c = build();
      await c.load();
      expect(c.driverVent, 1);

      await c.cycleSeatHeat(1);

      expect(c.driverHeat, 1);
      expect(c.driverVent, 0);
      final req = rpc.calls.last.request as SetSeatRequest;
      expect(req.seatIndex, 1);
      expect(req.action, 'heating');
      expect(req.level, 1);
    });

    test('driver heat cycles from 2 back to 0', () async {
      stubState(heat: [2, 0]);
      rpc.stubJson('VehicleService', 'SetSeat', {'success': true});
      final c = build();
      await c.load();

      await c.cycleSeatHeat(1);

      expect(c.driverHeat, 0);
    });

    test('passenger heat cycles and clears passenger vent when turning on', () async {
      stubState(heat: [0, 0], cool: [0, 1]);
      rpc.stubJson('VehicleService', 'SetSeat', {'success': true});
      final c = build();
      await c.load();
      expect(c.passengerVent, 1);

      await c.cycleSeatHeat(2);

      expect(c.passengerHeat, 1);
      expect(c.passengerVent, 0);
      final req = rpc.calls.last.request as SetSeatRequest;
      expect(req.seatIndex, 2);
      expect(req.action, 'heating');
    });

    test('passenger cool cycles and clears passenger heat when turning on', () async {
      stubState(heat: [0, 1], cool: [0, 0]);
      rpc.stubJson('VehicleService', 'SetSeat', {'success': true});
      final c = build();
      await c.load();
      expect(c.passengerHeat, 1);

      await c.cycleSeatCool(2);

      expect(c.passengerVent, 1);
      expect(c.passengerHeat, 0);
      final req = rpc.calls.last.request as SetSeatRequest;
      expect(req.seatIndex, 2);
      expect(req.action, 'ventilation');
    });

    test('a THROWN seat failure reverts and reports', () async {
      stubState();
      rpc.stubError('VehicleService', 'SetSeat', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();

      // Was: `await c.cycleSeatHeat(1); expect(c.driverHeat, 1);` — asserting the
      // UI should show heat level 1 on a seat whose command FAILED.
      expect(await c.cycleSeatHeat(1), isNotNull);
      expect(c.driverHeat, 0, reason: 'a failed command must not show the seat as heated');
    });

    // The refusal path: the daemon returns 200 with success:false, so nothing
    // throws and a catch-only guard never runs.
    test('a REFUSED seat command reverts every seat field', () async {
      stubState();
      rpc.stubJson('VehicleService', 'SetSeat', {'success': false, 'message': 'Seat unavailable'});
      final c = build();
      await c.load();

      expect(await c.cycleSeatCool(1), 'Seat unavailable');
      // cycleSeatCool clears heat when it turns vent on, so BOTH must come back.
      expect(c.driverVent, 0);
      expect(c.driverHeat, 0);
    });

    test('is debounced per seat/action key independently', () async {
      stubState();
      rpc.stubJson('VehicleService', 'SetSeat', {'success': true});
      final c = build();
      await c.load();

      await c.cycleSeatHeat(1);
      final afterFirst = rpc.calls.length;
      await c.cycleSeatHeat(1);
      expect(rpc.calls.length, afterFirst);

      await c.cycleSeatCool(1);
      expect(rpc.calls.length, afterFirst + 1);
    });
  });

  group('seats: memory recall (pending-tracked)', () {
    test('succeeds and clears pending', () async {
      stubState();
      rpc.stubJson('VehicleService', 'SetSeat', {'success': true});
      final c = build();
      await c.load();

      final future = c.recallSeatPosition(1);
      expect(c.isPending('seat_mem1'), isTrue);
      final error = await future;

      expect(error, isNull);
      expect(c.isPending('seat_mem1'), isFalse);
      final req = rpc.calls.last.request as SetSeatRequest;
      expect(req.action, 'position');
      expect(req.seatIndex, 1);
    });

    test('failure returns the message and clears pending', () async {
      stubState();
      rpc.stubJson('VehicleService', 'SetSeat', {'success': false, 'message': 'no memory saved'});
      final c = build();
      await c.load();

      final error = await c.recallSeatPosition(2);

      expect(error, 'no memory saved');
      expect(c.isPending('seat_mem2'), isFalse);
    });

    /// Was: `expect(..., 'failed')`. That pinned a hardcoded English literal as
    /// the user-visible reason — on a screen that ships in 17 locales, where no
    /// catalog could ever translate it. The fallback is now the empty string,
    /// which `showVehicleCommandError` renders as the localised
    /// `vehicle_action_failed`.
    ///
    /// It must stay NON-null either way: null is how every call site spells
    /// success, so returning null for a refusal reverts the control and then
    /// tells the driver nothing.
    test('failure with no message falls back to outcome, then to the localised generic', () async {
      stubState();
      rpc.stubJson('VehicleService', 'SetSeat', {'success': false, 'outcome': 'not_supported'});
      final c = build();
      await c.load();
      expect(await c.recallSeatPosition(1), 'not_supported');

      rpc.stubJson('VehicleService', 'SetSeat', {'success': false});
      fakeNow += 1000;
      final blank = await c.recallSeatPosition(1);
      expect(blank, isNotNull, reason: 'null would be read as success by every caller');
      expect(blank, isEmpty, reason: 'the screen substitutes vehicle_action_failed');
    });

    test('throwing returns the exception text', () async {
      stubState();
      rpc.stubError('VehicleService', 'SetSeat', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();

      final error = await c.recallSeatPosition(1);

      expect(error, isNotNull);
    });
  });

  group('windows (pending-tracked)', () {
    test('setWindowPercent succeeds', () async {
      stubState();
      rpc.stubJson('VehicleService', 'MoveWindow', {'success': true});
      final c = build();
      await c.load();

      final error = await c.setWindowPercent(1, 50);

      expect(error, isNull);
      final req = rpc.calls.last.request as MoveWindowRequest;
      expect(req.windowIndex, 1);
      expect(req.targetPercent, 50);
    });

    test('closeAllWindows sends windowIndex 0 with direction close', () async {
      stubState();
      rpc.stubJson('VehicleService', 'MoveWindow', {'success': true});
      final c = build();
      await c.load();

      await c.closeAllWindows();

      final req = rpc.calls.last.request as MoveWindowRequest;
      expect(req.windowIndex, 0);
      expect(req.direction, 'close');
    });

    test('openAllWindows sends windowIndex 0 with direction open', () async {
      stubState();
      rpc.stubJson('VehicleService', 'MoveWindow', {'success': true});
      final c = build();
      await c.load();

      await c.openAllWindows();

      final req = rpc.calls.last.request as MoveWindowRequest;
      expect(req.windowIndex, 0);
      expect(req.direction, 'open');
    });

    test('ventAllWindows sends windowIndex 0 with a target percent, no direction', () async {
      stubState();
      rpc.stubJson('VehicleService', 'MoveWindow', {'success': true});
      final c = build();
      await c.load();

      await c.ventAllWindows(12);

      final req = rpc.calls.last.request as MoveWindowRequest;
      expect(req.windowIndex, 0);
      expect(req.targetPercent, 12);
      expect(req.direction, '');
    });

    test('a failure returns the message', () async {
      stubState();
      rpc.stubJson('VehicleService', 'MoveWindow', {'success': false, 'message': 'jammed'});
      final c = build();
      await c.load();

      expect(await c.setWindowPercent(1, 100), 'jammed');
    });

    test('throwing returns the exception text', () async {
      stubState();
      rpc.stubError('VehicleService', 'MoveWindow', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();

      expect(await c.setWindowPercent(1, 100), isNotNull);
    });

    test('isPending is true only while the action is in flight', () async {
      stubState();
      rpc.stubJson('VehicleService', 'MoveWindow', {'success': true});
      final c = build();
      await c.load();

      expect(c.isPending('win_1_50'), isFalse);
      final future = c.setWindowPercent(1, 50);
      expect(c.isPending('win_1_50'), isTrue);
      await future;
      expect(c.isPending('win_1_50'), isFalse);
    });
  });

  /// The revert paths of the BladeWatch success:false sweep, completing the
  /// halves each command was missing. Both failure shapes must revert, and
  /// every command had only ONE of them pinned: cycleSeatHeat proved the thrown
  /// path, cycleSeatCool the refused path, and decTemp neither. A revert that is
  /// only exercised in one direction is a revert that has been half-checked.
  group('refusal/throw symmetry', () {
    test('a REFUSED cycleSeatHeat reverts, like the thrown path does', () async {
      stubState();
      rpc.stubJson('VehicleService', 'SetSeat', {'success': false, 'message': 'Seat refused'});
      final c = build();
      await c.load();

      expect(await c.cycleSeatHeat(1), 'Seat refused');
      expect(c.driverHeat, 0, reason: 'a refused command must not show the seat as heated');
    });

    test('a THROWN cycleSeatCool reverts, like the refused path does', () async {
      stubState();
      rpc.stubError('VehicleService', 'SetSeat', const ConnectError('unavailable', 'down'));
      final c = build();
      await c.load();

      expect(await c.cycleSeatCool(1), isNotNull);
      expect(c.driverVent, 0, reason: 'a failed command must not show the seat as vented');
      expect(c.driverHeat, 0);
    });

    test('a REFUSED decTemp restores the temperature it decremented', () async {
      stubState(setpointC: 24);
      rpc.stubJson('VehicleService', 'SetClimate', {'success': false, 'message': 'Climate unavailable'});
      final c = build();
      await c.load();

      expect(await c.decTemp(), 'Climate unavailable');
      expect(c.setpointC, 24, reason: 'a refused decrement must not leave 23 on screen');
    });
  });
}
