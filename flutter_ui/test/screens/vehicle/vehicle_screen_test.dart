import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/vehicle_service_client.dart';
import 'package:bladewatch_ui/screens/vehicle/vehicle_controller.dart';
import 'package:bladewatch_ui/screens/vehicle/vehicle_screen.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';

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
    int soc = 50,
    int rangeKm = 36,
    double? fuelPercent,
    int? fuelRangeKm,
    bool acOn = false,
    int setpointC = 22,
    double? outsideTempC,
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
      },
      'battery': {
        'soc': soc,
        'rangeKm': rangeKm,
        // Omitted, not zeroed, when null — that is exactly how the daemon
        // reports a BEV, so the default stub IS the BEV case.
        'fuelPercent': ?fuelPercent,
        'fuelRangeKm': ?fuelRangeKm,
      },
      'climate': {'acOn': acOn, 'setpointC': setpointC, 'outsideTempC': ?outsideTempC, 'fanLevel': fanLevel, 'maxCooling': maxCooling},
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

  Future<void> pump(WidgetTester tester, VehicleController controller, {ThemeData? theme, Size? size}) async {
    tester.view.physicalSize = size ?? const Size(1600, 1000);
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

    testWidgets('the readout pill clears the tyre cards it used to overlap', (tester) async {
      // It sat hard right, on top of the RL/FL cards (Positioned right: 14),
      // and being translucent it let them show through. The PHEV fuel rows made
      // it tall enough to reach them. Assert the real geometry, not the widget
      // tree: a future layout change that re-introduces the collision has to
      // fail here.
      stubState(doorsOverall: 1, soc: 62, rangeKm: 210, fuelPercent: 74, fuelRangeKm: 480);
      stubAppearance();
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      final pill = tester.getRect(find.byKey(const ValueKey('vehicle.status.charge')));
      for (final label in ['RR', 'FR', 'RL', 'FL']) {
        final card = tester.getRect(find.text(label));
        expect(pill.overlaps(card), isFalse, reason: 'readout pill overlaps the $label tyre card');
      }
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
    // BladeWatch-7bx4: seat control was removed end to end -- there is no Seats tab at all.
    testWidgets('only Climate and Windows tabs exist', (tester) async {
      stubState();
      stubAppearance();
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('vehicle.tab.climate')), findsOneWidget);
      expect(find.byKey(const ValueKey('vehicle.tab.seats')), findsNothing);
      expect(find.byKey(const ValueKey('vehicle.tab.windows')), findsOneWidget);
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
    // BladeWatch-eh3u: labelled as what it is -- the outside air, not the cabin.
    testWidgets('shows the outside temperature when known', (tester) async {
      stubState(outsideTempC: 26.5);
      stubAppearance();
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      expect(find.text('Outside: 26.5°C'), findsOneWidget);
      expect(find.textContaining('Inside'), findsNothing);
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

    testWidgets('toggling the screen calls SetScreen and flips the button label (BladeWatch-2000.3)',
        (tester) async {
      stubState();
      stubAppearance();
      rpc.stubJson('VehicleService', 'SetScreen', {'success': true});
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      expect(find.text('Screen: ON'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('vehicle.screen.toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Screen: OFF'), findsOneWidget);
      expect((rpc.calls.last.request as dynamic).on, isFalse);
    });

    testWidgets('a screen toggle blocked by the motion interlock shows a snackbar with the server message',
        (tester) async {
      stubState();
      stubAppearance();
      rpc.stubJson('VehicleService', 'SetScreen', {'success': false, 'message': 'Blocked while moving'});
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('vehicle.screen.toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Blocked while moving'), findsOneWidget);
      expect(find.text('Screen: ON'), findsOneWidget);
    });

    testWidgets('stepping media volume up calls SetMediaVolume and shows the new percent (BladeWatch-2000.2)',
        (tester) async {
      stubState();
      stubAppearance();
      rpc.stubJson('VehicleService', 'SetMediaVolume', {'success': true});
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      expect(find.text('0%'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('vehicle.media.volume.plus')));
      await tester.pumpAndSettle();

      expect(find.text('5%'), findsOneWidget);
      expect((rpc.calls.last.request as dynamic).action, 'step_up');
    });

    testWidgets('tapping mute calls SetMediaVolume with action=mute and flips the button label',
        (tester) async {
      stubState();
      stubAppearance();
      rpc.stubJson('VehicleService', 'SetMediaVolume', {'success': true});
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      expect(find.text('Mute'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('vehicle.media.mute')));
      await tester.pumpAndSettle();

      expect(find.text('Muted'), findsOneWidget);
      expect((rpc.calls.last.request as dynamic).action, 'mute');
    });

    testWidgets('a failed media volume command shows a snackbar with the server message', (tester) async {
      stubState();
      stubAppearance();
      rpc.stubJson('VehicleService', 'SetMediaVolume', {'success': false, 'message': 'audio busy'});
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('vehicle.media.mute')));
      await tester.pumpAndSettle();

      expect(find.text('audio busy'), findsOneWidget);
      expect(find.text('Mute'), findsOneWidget);
    });

    testWidgets('tapping front defrost calls SetClimate with action=front_defrost (BladeWatch-2000.1)',
        (tester) async {
      stubState();
      stubAppearance();
      rpc.stubJson('VehicleService', 'SetClimate', {'success': true});
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('vehicle.climate.frontDefrost')));
      await tester.pumpAndSettle();

      expect((rpc.calls.last.request as dynamic).action, 'front_defrost');
      expect((rpc.calls.last.request as dynamic).on, isTrue);
    });

    testWidgets('tapping rear defrost calls SetClimate with action=rear_defrost', (tester) async {
      stubState();
      stubAppearance();
      rpc.stubJson('VehicleService', 'SetClimate', {'success': true});
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('vehicle.climate.rearDefrost')));
      await tester.pumpAndSettle();

      expect((rpc.calls.last.request as dynamic).action, 'rear_defrost');
      expect((rpc.calls.last.request as dynamic).on, isTrue);
    });

    testWidgets('a failed defrost command shows a snackbar with the server message', (tester) async {
      stubState();
      stubAppearance();
      rpc.stubJson('VehicleService', 'SetClimate', {'success': false, 'message': 'Blocked while moving'});
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('vehicle.climate.frontDefrost')));
      await tester.pumpAndSettle();

      expect(find.text('Blocked while moving'), findsOneWidget);
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

    /// Whether the preset chip [key] is drawn highlighted (primary background).
    bool lit(WidgetTester tester, String key) {
      final button = tester.widget<TextButton>(find.byKey(ValueKey(key)));
      final context = tester.element(find.byKey(ValueKey(key)));
      return button.style!.backgroundColor!.resolve({}) == Theme.of(context).colorScheme.primary;
    }

    // BladeWatch-rm6p: after Vent 12% the car reported 16/15/15/14 and Rear Right lit nothing.
    testWidgets('four vented windows all light the same preset', (tester) async {
      stubState(lf: 16, rf: 15, lr: 15, rr: 14);
      stubAppearance();
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openWindows(tester);

      for (final area in [1, 2, 3, 4]) {
        expect(lit(tester, 'vehicle.window.${area}_25'), isTrue, reason: 'window $area');
        expect(lit(tester, 'vehicle.window.${area}_0'), isFalse, reason: 'an open window is not closed');
      }
    });

    // BladeWatch-b3n7: 25% fully closed the sunroof and 75% fully opened it.
    testWidgets('the sunroof offers only close / half / open', (tester) async {
      stubState(capSunroof: true, sunroof: 50);
      stubAppearance();
      await pump(tester, buildController());
      await tester.pumpAndSettle();
      await openWindows(tester);

      for (final pct in [0, 50, 100]) {
        expect(find.byKey(ValueKey('vehicle.window.5_$pct')), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('vehicle.window.5_25')), findsNothing);
      expect(find.byKey(const ValueKey('vehicle.window.5_75')), findsNothing);
      expect(lit(tester, 'vehicle.window.5_50'), isTrue);
      expect(find.byKey(const ValueKey('vehicle.window.1_25')), findsOneWidget, reason: 'side windows keep all five');
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
  /// command. The climate path showed a snackbar containing empty text.
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

    // Was pinned on the seat buttons until seat control was removed (BladeWatch-7bx4); the
    // AC toggle takes the same _mapCommand -> showVehicleCommandError path.
    testWidgets('a blank climate refusal shows the generic message', (tester) async {
      stubState(acOn: false);
      stubAppearance();
      rpc.stubJson('VehicleService', 'SetClimate', {'success': false});
      await pump(tester, buildController());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('vehicle.climate.ac')));
      await tester.pumpAndSettle();
      expect(find.text('Action failed. Check vehicle connection.'), findsOneWidget);
    });
  });

  // ───────────────────── BladeWatch-vuul: responsive layout ──────────────────
  //
  // The head unit ROTATES. The sizes below are a deliberately CONSERVATIVE stand-in for the
  // real body (~1280x553dp landscape, measured — see docs/ui-ux-design-language.md): smaller in
  // both axes, so anything that fits here fits on the car. This screen was built
  // for portrait and broke in landscape — the controls panel wanted ~452dp of the ~553dp
  // available (a fixed maxHeight: 360, plus tab chips, plus the appearance bar) and, being a
  // Stack sibling of a Positioned.fill hero and four Positioned tyre cards, nothing shared a
  // constraint. The panel covered the car and sliced the tyre cards through their kPa line.
  //
  // These assert real geometry at the two real device sizes. The project's testing notes warn
  // that `flutter test` uses a fixed-width placeholder font, so text FIT is not measurable
  // here — which is why nothing below asserts text width or overflow. Card position and
  // containment are font-independent, and they are what actually regressed.
  group('responsive layout', () {
    const landscape = Size(960, 540);
    const portrait = Size(540, 960);

    /// The real thing, measured: display 1280x720dp, less the system bars
    /// (dumpsys window mStable=[0,84][1920,990]) and the app toolbar. The two sizes above are
    /// deliberately tighter; this one is the configuration the car actually runs, and it takes
    /// a DIFFERENT branch — at 1280 wide the controls column is 576dp, so the climate controls
    /// go two-up, where at 960 they stack.
    const deviceLandscape = Size(1280, 553);

    Future<void> pumpAt(WidgetTester tester, Size size) async {
      stubState(doorsOverall: 1, soc: 62, rangeKm: 210, fuelPercent: 74, fuelRangeKm: 480);
      stubAppearance();
      await pump(tester, buildController(), size: size);
      await tester.pumpAndSettle();
    }

    void expectAllTyreCardsOnScreen(WidgetTester tester, Size size) {
      final screen = Rect.fromLTWH(0, 0, size.width, size.height);
      for (final label in ['RR', 'FR', 'RL', 'FL']) {
        final card = tester.getRect(find.text(label));
        expect(
          screen.contains(card.topLeft) && screen.contains(card.bottomRight),
          isTrue,
          reason: '$label tyre card is clipped by the viewport at $size — $card',
        );
      }
    }

    testWidgets('landscape keeps all four tyre cards fully on screen', (tester) async {
      await pumpAt(tester, landscape);
      expectAllTyreCardsOnScreen(tester, landscape);
    });

    testWidgets('portrait keeps all four tyre cards fully on screen', (tester) async {
      await pumpAt(tester, portrait);
      expectAllTyreCardsOnScreen(tester, portrait);
    });

    testWidgets('the real head-unit landscape size keeps all four tyre cards on screen', (tester) async {
      await pumpAt(tester, deviceLandscape);
      expectAllTyreCardsOnScreen(tester, deviceLandscape);

      // And the controls are still beside the car, not over it.
      final chips = tester.getRect(find.byKey(const ValueKey('vehicle.tab.climate')));
      for (final label in ['RR', 'FR', 'RL', 'FL']) {
        expect(tester.getRect(find.text(label)).right <= chips.left, isTrue,
            reason: '$label tyre card runs under the controls column at $deviceLandscape');
      }
    });

    testWidgets('landscape puts the controls beside the car, not over it', (tester) async {
      await pumpAt(tester, landscape);

      // The tab chips mark the left edge of the controls column; every tyre card must sit
      // entirely to their left. In the broken layout the panel spanned the full width and
      // covered all four.
      final chips = tester.getRect(find.byKey(const ValueKey('vehicle.tab.climate')));
      for (final label in ['RR', 'FR', 'RL', 'FL']) {
        final card = tester.getRect(find.text(label));
        expect(card.right <= chips.left, isTrue, reason: '$label tyre card runs under the controls column');
      }
    });

    /// The car must take every pixel the controls do not.
    ///
    /// The first version of this layout used Expanded(hero) + Flexible(controls). Both are
    /// flex children with flex 1, so RenderFlex split the height 50/50: the hero was capped at
    /// half the screen, the controls took only their content, and the remainder became dead
    /// space at the bottom. Measured at 720x1280 — hero 640, controls 200, 440px of nothing.
    /// Containment and ordering assertions do not see trailing slack, so this measures it.
    testWidgets('portrait leaves no dead space below the controls', (tester) async {
      await pumpAt(tester, portrait);

      final chips = tester.getRect(find.byKey(const ValueKey('vehicle.tab.climate')));
      final heroBottom = tester.getRect(find.byKey(const ValueKey('vehicle.status.charge'))).bottom;

      // The controls start where the hero ends — no gap between the two panes …
      expect(chips.top - heroBottom < portrait.height * 0.2, isTrue,
          reason: 'gap of ${chips.top - heroBottom}px between the hero and the controls');
      // … and the hero occupies well over half the screen, rather than exactly half.
      expect(heroBottom > portrait.height * 0.5, isTrue,
          reason: 'hero ends at $heroBottom of ${portrait.height} — it is being capped at 50%');
    });

    testWidgets('portrait stacks the controls below the car', (tester) async {
      await pumpAt(tester, portrait);

      final chips = tester.getRect(find.byKey(const ValueKey('vehicle.tab.climate')));
      final charge = tester.getRect(find.byKey(const ValueKey('vehicle.status.charge')));
      expect(charge.bottom <= chips.top, isTrue, reason: 'controls are not below the hero in portrait');
    });

    // One orientation per test: the controller polls on a timer, so pumping a second size in
    // the same test never lets pumpAndSettle reach a quiescent frame.
    void expectChargeClearOfTyreCards(WidgetTester tester, Size size) {
      final charge = tester.getRect(find.byKey(const ValueKey('vehicle.status.charge')));
      for (final label in ['RR', 'FR', 'RL', 'FL']) {
        expect(
          charge.overlaps(tester.getRect(find.text(label))),
          isFalse,
          reason: 'charge readout overlaps the $label tyre card at $size',
        );
      }
    }

    testWidgets('landscape keeps the charge readout clear of the tyre cards', (tester) async {
      await pumpAt(tester, landscape);
      expectChargeClearOfTyreCards(tester, landscape);
    });

    testWidgets('portrait keeps the charge readout clear of the tyre cards', (tester) async {
      await pumpAt(tester, portrait);
      expectChargeClearOfTyreCards(tester, portrait);
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
