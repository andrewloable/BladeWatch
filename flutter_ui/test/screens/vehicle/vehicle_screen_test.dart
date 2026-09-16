import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/rpc/services/system_service_client.dart';
import 'package:bladewatch_ui/rpc/services/vehicle_service_client.dart';
import 'package:bladewatch_ui/screens/vehicle/vehicle_controller.dart';
import 'package:bladewatch_ui/screens/vehicle/vehicle_screen.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_rpc_client.dart';

void main() {
  late FakeRpcClient rpc;

  VehicleController buildController() => VehicleController(vehicleService: VehicleServiceClient(rpc), systemService: SystemServiceClient(rpc));

  void stubState({
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
    double? fuelPercent,
    int? fuelRangeKm,
    List<int> heat = const [0, 0],
    List<int> cool = const [0, 0],
    bool acOn = false,
    int setpointC = 22,
    double insideTempC = 0.0,
    int fanLevel = 3,
    bool maxCooling = false,
    Map<String, Object?> flTyre = const {'kPa': 250, 'psi': 36.3, 'temperatureC': 29},
  }) {
    rpc.stubJson('VehicleService', 'GetState', {
      'success': true,
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
      'battery': {
        'soc': soc,
        'rangeKm': rangeKm,
        // Omitted, not zeroed, when null — that is exactly how the daemon
        // reports a BEV, so the default stub IS the BEV case.
        if (fuelPercent != null) 'fuelPercent': fuelPercent,
        if (fuelRangeKm != null) 'fuelRangeKm': fuelRangeKm,
      },
      'seats': {'heat': heat, 'cool': cool},
      'climate': {'acOn': acOn, 'setpointC': setpointC, 'insideTempC': insideTempC, 'fanLevel': fanLevel, 'maxCooling': maxCooling},
      'tyres': {
        'fl': flTyre,
        'fr': <String, Object?>{},
        'rl': <String, Object?>{},
        'rr': <String, Object?>{},
      },
    });
  }

  void stubAppearance({String modelId = '', String color = '', List<Map<String, Object?>> models = const []}) {
    rpc.stubJson('SystemService', 'GetSelectedModel', {'modelId': modelId, 'color': color});
    rpc.stubJson('SystemService', 'GetModelsManifest', {'manifestJson': '{"models":${_jsonList(models)}}'});
  }

  setUp(() {
    rpc = FakeRpcClient();
  });

  Future<void> pump(WidgetTester tester, VehicleController controller, {ThemeData? theme}) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      theme: theme ?? BladeWatchTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: VehicleScreen(controller: controller, heroBuilder: (context, c) => const SizedBox.shrink()),
      ),
    ));
  }

  testWidgets('shows a loading indicator before data arrives', (tester) async {
    final c = buildController();
    await pump(tester, c);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  group('status card', () {
    testWidgets('shows Locked with known charge/range', (tester) async {
      stubState(doorsOverall: 1, soc: 62, rangeKm: 210);
      stubAppearance();
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      expect(find.text('Locked'), findsOneWidget);
      expect(find.text('Charge: 62%'), findsOneWidget);
      expect(find.text('Range: 210 km'), findsOneWidget);
    });

    testWidgets('shows the fuel level and fuel range on a PHEV', (tester) async {
      stubState(doorsOverall: 1, soc: 62, rangeKm: 210, fuelPercent: 74, fuelRangeKm: 480);
      stubAppearance();
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      expect(find.text('Charge: 62%'), findsOneWidget);
      expect(find.text('Range: 210 km'), findsOneWidget);
      expect(find.text('Fuel: 74%'), findsOneWidget);
      expect(find.text('Fuel range: 480 km'), findsOneWidget);
    });

    testWidgets('shows no fuel rows on a BEV, rather than a 0% tank', (tester) async {
      // The daemon OMITS the fuel keys on a BEV; a "Fuel: 0%" here would be a
      // readout for hardware the car does not have.
      stubState(doorsOverall: 1, soc: 62, rangeKm: 210);
      stubAppearance();
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('vehicle.status.fuel')), findsNothing);
      expect(find.byKey(const ValueKey('vehicle.status.fuelRange')), findsNothing);
    });

    testWidgets('shows Unlocked', (tester) async {
      stubState(doorsOverall: 2);
      stubAppearance();
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      expect(find.text('Unlocked'), findsOneWidget);
    });

    testWidgets('shows unknown charge/range when soc is 0', (tester) async {
      stubState(doorsOverall: 1, soc: 0);
      stubAppearance();
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      expect(find.text('Charge: —'), findsOneWidget);
      expect(find.text('Range: —'), findsOneWidget);
    });

    testWidgets('shows the data-unavailable banner after 3 consecutive failures', (tester) async {
      rpc.stubError('VehicleService', 'GetState', const ConnectError('unavailable', 'down'));
      stubAppearance();
      final c = buildController();
      await pump(tester, c);
      await tester.pump();
      await c.poll();
      await tester.pump();
      await c.poll();
      await tester.pump();

      expect(find.text('Vehicle data unavailable.'), findsOneWidget);
    });
  });

  group('tabs', () {
    testWidgets('Seats tab is hidden when no seat capability is reported', (tester) async {
      stubState();
      stubAppearance();
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('vehicle.tab.climate')), findsOneWidget);
      expect(find.byKey(const ValueKey('vehicle.tab.seats')), findsNothing);
      expect(find.byKey(const ValueKey('vehicle.tab.windows')), findsOneWidget);
    });

    testWidgets('Seats tab appears when any seat capability is reported', (tester) async {
      stubState(capDriverHeat: true);
      stubAppearance();
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('vehicle.tab.seats')), findsOneWidget);
    });

    testWidgets('switching to Windows shows the window grid', (tester) async {
      stubState();
      stubAppearance();
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('vehicle.tab.windows')));
      await tester.pumpAndSettle();

      expect(find.text('Front Left (0%)'), findsOneWidget);
    });
  });

  group('climate tab', () {
    testWidgets('shows inside temperature when known', (tester) async {
      stubState(insideTempC: 26.5);
      stubAppearance();
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      expect(find.text('Inside: 26.5°C'), findsOneWidget);
    });

    testWidgets('toggling AC calls SetClimate and flips the button label', (tester) async {
      stubState(acOn: false);
      stubAppearance();
      rpc.stubJson('VehicleService', 'SetClimate', {'success': true});
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('vehicle.climate.ac')));
      await tester.pumpAndSettle();

      expect(find.text('AC On'), findsOneWidget);
    });

    testWidgets('a failed AC toggle shows a snackbar with the server message', (tester) async {
      stubState(acOn: false);
      stubAppearance();
      rpc.stubJson('VehicleService', 'SetClimate', {'success': false, 'message': 'AC busy'});
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('vehicle.climate.ac')));
      await tester.pumpAndSettle();

      expect(find.text('AC busy'), findsOneWidget);
    });

    testWidgets('toggling max cooling flips the button label', (tester) async {
      stubState(maxCooling: false);
      stubAppearance();
      rpc.stubJson('VehicleService', 'SetClimate', {'success': true});
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('vehicle.climate.maxCooling')));
      await tester.pumpAndSettle();

      expect(find.text('Max Cooling: ON'), findsOneWidget);
    });

    testWidgets('temp stepper increases and decreases the displayed value', (tester) async {
      stubState(setpointC: 22);
      stubAppearance();
      rpc.stubJson('VehicleService', 'SetClimate', {'success': true});
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('vehicle.climate.temp.plus')));
      await tester.pumpAndSettle();
      expect(find.text('23°C'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('vehicle.climate.temp.minus')));
      await tester.pumpAndSettle();
      expect(find.text('22°C'), findsOneWidget);
    });

    testWidgets('fan stepper increases the displayed level', (tester) async {
      stubState(fanLevel: 3);
      stubAppearance();
      rpc.stubJson('VehicleService', 'SetClimate', {'success': true});
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('vehicle.climate.fan.plus')));
      await tester.pumpAndSettle();

      expect(find.text('Level 4'), findsOneWidget);
    });
  });

  group('seats tab', () {
    Future<void> openSeats(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('vehicle.tab.seats')));
      await tester.pumpAndSettle();
    }

    testWidgets('driver row shows only the capabilities the vehicle reports', (tester) async {
      stubState(capDriverHeat: true);
      stubAppearance();
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openSeats(tester);

      expect(find.byKey(const ValueKey('vehicle.seat.heat.1')), findsOneWidget);
      expect(find.byKey(const ValueKey('vehicle.seat.cool.1')), findsNothing);
    });

    testWidgets('cycling driver heat calls SetSeat and updates the label', (tester) async {
      stubState(capDriverHeat: true, heat: [0, 0]);
      stubAppearance();
      rpc.stubJson('VehicleService', 'SetSeat', {'success': true});
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openSeats(tester);

      await tester.tap(find.byKey(const ValueKey('vehicle.seat.heat.1')));
      await tester.pumpAndSettle();

      expect(find.text('Heat (Low)'), findsOneWidget);
    });

    testWidgets('passenger cool control appears when capable and cycling calls SetSeat', (tester) async {
      stubState(capPassengerCool: true, cool: [0, 0]);
      stubAppearance();
      rpc.stubJson('VehicleService', 'SetSeat', {'success': true});
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openSeats(tester);

      expect(find.byKey(const ValueKey('vehicle.seat.cool.2')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('vehicle.seat.cool.2')));
      await tester.pumpAndSettle();

      expect(find.text('Cool (Low)'), findsOneWidget);
    });

    testWidgets('memory recall buttons appear only for the driver and call SetSeat', (tester) async {
      stubState(capDriverHeat: true, capDriverMemory: true);
      stubAppearance();
      rpc.stubJson('VehicleService', 'SetSeat', {'success': true});
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openSeats(tester);

      expect(find.byKey(const ValueKey('vehicle.seat.recall.1')), findsOneWidget);
      expect(find.byKey(const ValueKey('vehicle.seat.recall.2')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('vehicle.seat.recall.1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('vehicle.seat.recall.2')));
      await tester.pumpAndSettle();

      expect(rpc.calls.where((c) => c.method == 'SetSeat').length, greaterThanOrEqualTo(2));
    });

    testWidgets('a failed memory recall shows a snackbar', (tester) async {
      stubState(capDriverHeat: true, capDriverMemory: true);
      stubAppearance();
      rpc.stubJson('VehicleService', 'SetSeat', {'success': false, 'message': 'no memory saved'});
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openSeats(tester);

      await tester.tap(find.byKey(const ValueKey('vehicle.seat.recall.1')));
      await tester.pumpAndSettle();

      expect(find.text('no memory saved'), findsOneWidget);
    });
  });

  group('windows tab', () {
    Future<void> openWindows(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('vehicle.tab.windows')));
      await tester.pumpAndSettle();
    }

    // BladeWatch-c2h1: "close all" used to route through the BYD cloud CLOSEWINDOW
    // command, which worked with the car asleep. 61b4d7f deleted that path, so every
    // control on this tab is now the local SDK primitive and needs the head unit
    // awake. Without the note a remote tap just looks like it silently did nothing.
    testWidgets('the windows tab says the controls need the car awake', (tester) async {
      stubState();
      stubAppearance();
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openWindows(tester);

      expect(find.byKey(const ValueKey('vehicle.window.awakeNote')), findsOneWidget);
    });

    testWidgets('tapping a preset calls MoveWindow with the right area/percent', (tester) async {
      stubState();
      stubAppearance();
      rpc.stubJson('VehicleService', 'MoveWindow', {'success': true});
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openWindows(tester);

      await tester.tap(find.byKey(const ValueKey('vehicle.window.1_50')));
      await tester.pumpAndSettle();

      expect(rpc.calls.any((c) => c.method == 'MoveWindow'), isTrue);
    });

    testWidgets('close all / vent / open all call MoveWindow', (tester) async {
      stubState();
      stubAppearance();
      rpc.stubJson('VehicleService', 'MoveWindow', {'success': true});
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openWindows(tester);

      await tester.tap(find.byKey(const ValueKey('vehicle.window.closeAll')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('vehicle.window.vent')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('vehicle.window.openAll')));
      await tester.pumpAndSettle();

      expect(rpc.calls.where((c) => c.method == 'MoveWindow').length, 3);
    });

    testWidgets('sunroof cell appears only when capable', (tester) async {
      stubState(capSunroof: true, sunroof: 0);
      stubAppearance();
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openWindows(tester);

      expect(find.text('Sunroof (0%)'), findsOneWidget);
      expect(find.text('Sunshade (–%)'), findsNothing);
    });

    testWidgets('a failed window action shows a snackbar', (tester) async {
      stubState();
      stubAppearance();
      rpc.stubJson('VehicleService', 'MoveWindow', {'success': false, 'message': 'jammed'});
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openWindows(tester);

      await tester.tap(find.byKey(const ValueKey('vehicle.window.1_50')));
      await tester.pumpAndSettle();

      expect(find.text('jammed'), findsOneWidget);
    });
  });

  group('appearance', () {
    testWidgets('tapping a color swatch calls SetSelectedModel', (tester) async {
      stubState();
      stubAppearance();
      rpc.stubJson('SystemService', 'SetSelectedModel', {'ok': true});
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('vehicle.color.#1A1A1E')));
      await tester.pumpAndSettle();

      expect(rpc.calls.any((c) => c.method == 'SetSelectedModel'), isTrue);
    });

    testWidgets('the custom color dialog applies a composed hex', (tester) async {
      stubState();
      stubAppearance();
      rpc.stubJson('SystemService', 'SetSelectedModel', {'ok': true});
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('vehicle.color.custom')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('vehicle.color.custom.apply')), findsOneWidget);

      // Drag a slider so the composed hex actually differs from the current
      // default color -- selectColor() is a no-op when unchanged, matching
      // native's identical `if (hex == selectedColor) return` guard.
      await tester.drag(find.byType(Slider).first, const Offset(-200, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('vehicle.color.custom.apply')));
      await tester.pumpAndSettle();

      expect(rpc.calls.any((c) => c.method == 'SetSelectedModel'), isTrue);
    });

    testWidgets('the model name is not tappable with 0 or 1 models', (tester) async {
      stubState();
      stubAppearance(models: [
        {'id': 'seal5-dmi-dynamic', 'name': 'BYD Seal 5 DM-i Dynamic', 'file': 'destroyer.glb', 'bundled': true},
      ]);
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      final text = tester.widget<GestureDetector>(find.byKey(const ValueKey('vehicle.model.name')));
      expect(text.onTap, isNull);
    });

    testWidgets('the model picker lists all models and selecting one calls SetSelectedModel', (tester) async {
      stubState();
      stubAppearance(models: [
        {'id': 'seal5-dmi-dynamic', 'name': 'BYD Seal 5 DM-i Dynamic', 'file': 'destroyer.glb', 'bundled': true},
        {'id': 'tang', 'name': 'BYD Tang', 'file': 'tang.glb', 'bundled': true},
      ]);
      rpc.stubJson('SystemService', 'SetSelectedModel', {'ok': true});
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('vehicle.model.name')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('vehicle.model.picker.tang')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('vehicle.model.picker.tang')));
      await tester.pumpAndSettle();

      final req = rpc.calls.lastWhere((c) => c.method == 'SetSelectedModel');
      expect((req.request as dynamic).modelId, 'tang');
    });
  });

  group('tyre cards', () {
    testWidgets('shows PSI/kPa/temperature for each corner', (tester) async {
      stubState(flTyre: {'kPa': 250, 'psi': 36.3, 'temperatureC': 29});
      stubAppearance();
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      expect(find.textContaining('36.3 PSI'), findsOneWidget);
      expect(find.textContaining('250 kPa'), findsOneWidget);
    });

    testWidgets('shows an unknown placeholder when no tyre data exists', (tester) async {
      stubState(flTyre: const {});
      stubAppearance();
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      expect(find.text('—'), findsWidgets);
    });

    testWidgets('shows FAST LEAK / SLOW LEAK / low text for the alert tier', (tester) async {
      stubState(flTyre: {'psi': 20.0, 'airLeakState': 2});
      stubAppearance();
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      expect(find.text('FAST LEAK'), findsOneWidget);
    });

    testWidgets('shows a slow-leak label for airLeakState 1', (tester) async {
      stubState(flTyre: {'psi': 36.0, 'airLeakState': 1});
      stubAppearance();
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      expect(find.text('SLOW LEAK'), findsOneWidget);
    });

    testWidgets('shows a low-pressure alert label when under 22 psi with no leak flag', (tester) async {
      stubState(flTyre: {'psi': 21.0});
      stubAppearance();
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      expect(find.text('LOW'), findsOneWidget);
    });

    testWidgets('shows "Check pressure" for the warn tier', (tester) async {
      stubState(flTyre: {'psi': 36.0, 'pressureState': 1});
      stubAppearance();
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      expect(find.text('Check pressure'), findsOneWidget);
    });

    testWidgets('shows HIGH for the caution tier above the normal range', (tester) async {
      stubState(flTyre: {'psi': 46.0});
      stubAppearance();
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      expect(find.text('HIGH'), findsOneWidget);
    });
  });

  testWidgets('renders without error in dark theme', (tester) async {
    stubState();
    stubAppearance();
    await pump(tester, buildController(), theme: BladeWatchTheme.dark());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  /// The daemon refuses by answering 200 with success:false — and it can do so
  /// with NO message. Every path must still tell the driver something.
  ///
  /// Before this, the appearance writes returned null for a blank refusal, so
  /// `error != null` was false and nothing was shown at all: the swatch snapped
  /// back with no explanation, which reads as a broken tap rather than a refused
  /// command. The climate/seat paths showed a snackbar containing empty text.
  group('a refusal with no reason still reports', () {
    testWidgets('a blank appearance refusal shows the generic message', (tester) async {
      stubState();
      stubAppearance();
      rpc.stubJson('SystemService', 'SetSelectedModel', {'ok': false});
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('vehicle.color.#1A1A1E')));
      await tester.pumpAndSettle();

      expect(find.text('Action failed. Check vehicle connection.'), findsOneWidget);
    });

    testWidgets('an appearance refusal WITH a reason shows that reason', (tester) async {
      stubState();
      stubAppearance();
      rpc.stubJson('SystemService', 'SetSelectedModel', {'ok': false, 'error': 'Model locked'});
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('vehicle.color.#1A1A1E')));
      await tester.pumpAndSettle();

      expect(find.text('Model locked'), findsOneWidget);
      expect(find.text('Action failed. Check vehicle connection.'), findsNothing);
    });

    testWidgets('a blank seat refusal shows the generic message', (tester) async {
      stubState(capDriverHeat: true, heat: [0, 0]);
      stubAppearance();
      rpc.stubJson('VehicleService', 'SetSeat', {'success': false});
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('vehicle.tab.seats')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('vehicle.seat.heat.1')));
      await tester.pumpAndSettle();
      expect(find.text('Action failed. Check vehicle connection.'), findsOneWidget);
    });

    /// The cool button is a hand-copied twin of the heat one, so it gets its own
    /// case: every seat defect so far has been present in exactly one of the two.
    testWidgets('a blank seat COOL refusal reports too, not just heat', (tester) async {
      stubState(capDriverCool: true, cool: [0, 0]);
      stubAppearance();
      rpc.stubJson('VehicleService', 'SetSeat', {'success': false});
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('vehicle.tab.seats')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('vehicle.seat.cool.1')));
      await tester.pumpAndSettle();

      expect(find.text('Action failed. Check vehicle connection.'), findsOneWidget);
    });
  });
}

String _jsonList(List<Map<String, Object?>> models) {
  final entries = models.map((m) {
    final parts = m.entries.map((e) {
      final v = e.value;
      final encoded = v is String ? '"$v"' : '$v';
      return '"${e.key}":$encoded';
    }).join(',');
    return '{$parts}';
  }).join(',');
  return '[$entries]';

}
