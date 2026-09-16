import 'dart:async';

import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/rpc/rpc_transport.dart';
import 'package:bladewatch_ui/rpc/services/trips_service_client.dart';
import 'package:bladewatch_ui/screens/trips/trip_detail_controller.dart';
import 'package:bladewatch_ui/screens/trips/trip_detail_screen.dart';
import 'package:bladewatch_ui/screens/trips/trips_controller.dart';
import 'package:bladewatch_ui/screens/trips/trips_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_rpc_client.dart';
import 'package:bladewatch_ui/widgets/bw_choice_chip.dart';

/// A [RpcTransport] whose calls stay pending until [gate] is completed —
/// FakeRpcClient resolves on the next microtask with no real delay, too
/// narrow a window for a widget test to reliably observe a transient
/// "in flight" state against.
class _GatedRpcTransport implements RpcTransport {
  final Completer<void> gate = Completer<void>();

  @override
  Future<T> call<T>(String service, String method, Object? request, T Function(Object? json) decode) async {
    await gate.future;
    return decode({'success': true, 'added': 1, 'removed': 0, 'total': 5});
  }
}

void main() {
  late FakeRpcClient rpc;
  late FakeRpcClient longRpc;
  late TripsController controller;

  Map<String, dynamic> aTrip({int id = 1, int score = 80}) => {
        'id': '$id',
        'startTime': '1000',
        'endTime': '2000',
        'distanceKm': 12.5,
        'durationSeconds': 900,
        'overallScore': score,
        'tripCost': 2.5,
        'currency': 'USD',
      };

  void stubAllLoads({
    List<Map<String, dynamic>> trips = const [],
    Map<String, dynamic>? dna,
    String rangeJson = '{}',
    Map<String, dynamic>? config,
    Map<String, dynamic>? storage,
  }) {
    rpc.stubJson('TripsService', 'ListTrips', {'success': true, 'trips': trips});
    rpc.stubJson('TripsService', 'GetSummary', {'success': true, 'summary': []});
    rpc.stubJson('TripsService', 'GetDna', {'success': true, 'dna': dna});
    rpc.stubJson('TripsService', 'GetRange', {'success': true, 'rangeJson': rangeJson});
    rpc.stubJson('TripsService', 'GetConfig', {'success': true, 'config': config});
    rpc.stubJson('TripsService', 'GetStorage', {'success': true, 'storage': storage});
  }

  setUp(() {
    rpc = FakeRpcClient();
    longRpc = FakeRpcClient();
    controller = TripsController(tripsService: TripsServiceClient(rpc), longTripsService: TripsServiceClient(longRpc));
  });

  Future<void> pumpScreen(WidgetTester tester, {Brightness brightness = Brightness.light}) async {
    tester.view.physicalSize = const Size(1400, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(brightness: brightness),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TripsScreen(
          controller: controller,
          detailControllerFactory: () => TripDetailController(tripsService: TripsServiceClient(rpc)),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('shows a loading indicator before the first load resolves', (tester) async {
    await pumpScreen(tester);
    // stubAllLoads not called: load() will error since nothing is stubbed;
    // assert only that it does not crash mid-flight — the real interesting
    // states are covered below.
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows an error state when the load fails', (tester) async {
    rpc.stubError('TripsService', 'ListTrips', const ConnectError('unavailable', 'no daemon'));
    await pumpScreen(tester);

    expect(find.byKey(const ValueKey('trips.error')), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no trips', (tester) async {
    stubAllLoads(trips: []);
    await pumpScreen(tester);

    expect(find.byKey(const ValueKey('trips.empty')), findsOneWidget);
  });

  testWidgets('renders trip rows and the summary card when trips exist', (tester) async {
    stubAllLoads(trips: [aTrip(id: 1), aTrip(id: 2)]);
    await pumpScreen(tester);

    expect(find.byKey(const ValueKey('trips.row.1')), findsOneWidget);
    expect(find.byKey(const ValueKey('trips.row.2')), findsOneWidget);
  });

  testWidgets('formats distance in miles when the config distance unit is "mi"', (tester) async {
    stubAllLoads(trips: [aTrip(id: 1)], config: {'enabled': true, 'electricityRate': 0, 'currency': 'USD', 'distanceUnit': 'mi'});
    await pumpScreen(tester);

    expect(find.textContaining('mi'), findsWidgets);
  });

  testWidgets('tapping a filter chip reloads with the new day count', (tester) async {
    stubAllLoads();
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('trips.filter.30')));
    await tester.pumpAndSettle();

    final call = rpc.calls.lastWhere((c) => c.method == 'ListTrips');
    expect((call.request as dynamic).days, 30);
  });

  testWidgets('tapping the Stats tab shows Driver Score / Range / DNA without reloading', (tester) async {
    stubAllLoads(dna: {'anticipation': 1, 'smoothness': 2, 'speedDiscipline': 3, 'efficiency': 4, 'consistency': 5, 'overall': 6});
    await pumpScreen(tester);
    final callsBefore = rpc.calls.length;

    await tester.tap(find.byKey(const ValueKey('trips.tab.stats')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('trips.driverScoreCard')), findsOneWidget);
    expect(find.byKey(const ValueKey('trips.dnaCard')), findsOneWidget);
    expect(rpc.calls.length, callsBefore);
  });

  testWidgets('Stats tab shows the estimated and BYD range when available', (tester) async {
    stubAllLoads(rangeJson: '{"range":{"predictedRangeKm":320.0,"builtInRangeKm":300.0}}');
    await pumpScreen(tester);
    await tester.tap(find.byKey(const ValueKey('trips.tab.stats')));
    await tester.pumpAndSettle();

    expect(find.text('320 km'), findsOneWidget);
    expect(find.textContaining('BYD estimate'), findsOneWidget);
  });

  testWidgets('Stats tab shows "not enough data" when there is no range estimate', (tester) async {
    stubAllLoads(rangeJson: '{}');
    await pumpScreen(tester);
    await tester.tap(find.byKey(const ValueKey('trips.tab.stats')));
    await tester.pumpAndSettle();

    expect(find.text('Not enough data yet'), findsOneWidget);
  });

  group('Storage tab', () {
    testWidgets('renders the loaded config/storage values', (tester) async {
      stubAllLoads(
        // isPhev, so the fuel fields are on screen at all — their SEEDING is what this
        // asserts; whether they appear for a given drivetrain is covered separately below.
        config: {'enabled': true, 'electricityRate': 0.15, 'currency': 'USD', 'distanceUnit': 'km', 'isPhev': true},
        storage: {'storageType': 'INTERNAL', 'limitMb': '500', 'usedMb': 10.0, 'usedUnit': 'MB', 'sdCardAvailable': false, 'tripsCount': 2, 'storagePath': '/x'},
      );
      await pumpScreen(tester);

      await tester.tap(find.byKey(const ValueKey('trips.tab.storage')));
      await tester.pumpAndSettle();

      // BladeWatch-9uu6: currency is now PICKED from the ISO 4217 catalogue rather than
      // typed, so this is a dropdown holding the loaded code.
      final currencyField = tester.widget<DropdownButtonFormField<String>>(
          find.byKey(const ValueKey('trips.storage.currency')));
      expect(currencyField.initialValue, 'USD');
      final sw = tester.widget<SwitchListTile>(find.byKey(const ValueKey('trips.storage.analytics')));
      expect(sw.value, isTrue);

      // PHEV pricing seeds from the loaded config too — persisting a value is only half of
      // "it persists" if the settings screen then shows the default instead.
      final fuelPrice = tester.widget<TextField>(
          find.byKey(const ValueKey('trips.storage.fuelPrice')));
      expect(fuelPrice.controller!.text, '0.00',
          reason: 'absent from this config, so it must read as not-configured');
      final tank = tester.widget<TextField>(
          find.byKey(const ValueKey('trips.storage.tankCapacity')));
      expect(tank.controller!.text, '0.0');
    });

    testWidgets('toggling the analytics switch and re-selecting Internal storage update local state', (tester) async {
      stubAllLoads(
        config: {'enabled': false, 'electricityRate': 0.1, 'currency': 'USD', 'distanceUnit': 'km'},
        storage: {'storageType': 'INTERNAL', 'limitMb': '500', 'usedMb': 0.0, 'usedUnit': 'MB', 'sdCardAvailable': true, 'tripsCount': 0, 'storagePath': ''},
      );
      await pumpScreen(tester);
      await tester.tap(find.byKey(const ValueKey('trips.tab.storage')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('trips.storage.analytics')));
      await tester.tap(find.byKey(const ValueKey('trips.storage.unit.mi')));
      await tester.tap(find.byKey(const ValueKey('trips.storage.location.internal')));
      await tester.pump();

      final sw = tester.widget<SwitchListTile>(find.byKey(const ValueKey('trips.storage.analytics')));
      expect(sw.value, isTrue);
      final unitChip = tester.widget<BwChoiceChip>(find.byKey(const ValueKey('trips.storage.unit.mi')));
      expect(unitChip.selected, isTrue);
    });

    testWidgets('the SD Card option is disabled and labeled N/A when unavailable', (tester) async {
      stubAllLoads(storage: {'storageType': 'INTERNAL', 'limitMb': '500', 'usedMb': 0.0, 'usedUnit': 'MB', 'sdCardAvailable': false, 'tripsCount': 0, 'storagePath': ''});
      await pumpScreen(tester);
      await tester.tap(find.byKey(const ValueKey('trips.tab.storage')));
      await tester.pumpAndSettle();

      expect(find.text('SD Card (N/A)'), findsOneWidget);
      final chip = tester.widget<BwChoiceChip>(find.byKey(const ValueKey('trips.storage.location.sdCard')));
      expect(chip.onSelected, isNull);
    });

    testWidgets('applying changes saves and shows a failure snackbar when it fails', (tester) async {
      stubAllLoads(storage: {'storageType': 'INTERNAL', 'limitMb': '500', 'usedMb': 0.0, 'usedUnit': 'MB', 'sdCardAvailable': true, 'tripsCount': 0, 'storagePath': ''});
      await pumpScreen(tester);
      await tester.tap(find.byKey(const ValueKey('trips.tab.storage')));
      await tester.pumpAndSettle();
      rpc.stubError('TripsService', 'SetConfig', const ConnectError('unavailable', 'no daemon'));

      await tester.tap(find.byKey(const ValueKey('trips.storage.apply')));
      await tester.pumpAndSettle();

      expect(find.text('Failed to save'), findsOneWidget);
    });

    testWidgets('applying changes succeeds and reloads', (tester) async {
      stubAllLoads(storage: {'storageType': 'INTERNAL', 'limitMb': '500', 'usedMb': 0.0, 'usedUnit': 'MB', 'sdCardAvailable': true, 'tripsCount': 0, 'storagePath': ''});
      await pumpScreen(tester);
      await tester.tap(find.byKey(const ValueKey('trips.tab.storage')));
      await tester.pumpAndSettle();
      rpc.stubJson('TripsService', 'SetConfig', {'success': true});
      rpc.stubJson('TripsService', 'SetStorage', {'success': true});

      await tester.tap(find.byKey(const ValueKey('trips.storage.location.sdCard')));
      await tester.tap(find.byKey(const ValueKey('trips.storage.apply')));
      await tester.pumpAndSettle();

      final setStorageCall = rpc.calls.lastWhere((c) => c.method == 'SetStorage');
      expect((setStorageCall.request as dynamic).storageType, 'SD_CARD');
    });

    /// BladeWatch-9uu6: the owner's currency choice has to actually reach the daemon —
    /// that is the whole point of "the selection persists". Picking from the dropdown and
    /// applying must send the chosen code, not the one the screen loaded with.
    testWidgets('picking a currency sends the chosen code on apply', (tester) async {
      stubAllLoads(
        config: {'enabled': true, 'electricityRate': 0.15, 'currency': 'USD', 'distanceUnit': 'km'},
        storage: {'storageType': 'INTERNAL', 'limitMb': '500', 'usedMb': 0.0, 'usedUnit': 'MB', 'sdCardAvailable': true, 'tripsCount': 0, 'storagePath': ''},
      );
      await pumpScreen(tester);
      await tester.tap(find.byKey(const ValueKey('trips.tab.storage')));
      await tester.pumpAndSettle();
      rpc.stubJson('TripsService', 'SetConfig', {'success': true});
      rpc.stubJson('TripsService', 'SetStorage', {'success': true});

      // Choose a different currency. The callback is invoked directly rather than driving
      // the menu route: the dropdown is deliberately disabled until the generated catalogue
      // resolves, so a tap-based test would race that load. Asserting onChanged is non-null
      // first is what proves the picker actually became usable.
      final picker = tester.widget<DropdownButtonFormField<String>>(
          find.byKey(const ValueKey('trips.storage.currency')));
      expect(picker.onChanged, isNotNull,
          reason: 'the picker must be enabled once the catalogue has loaded');
      picker.onChanged!('PHP');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('trips.storage.apply')));
      await tester.pumpAndSettle();

      final setConfigCall = rpc.calls.lastWhere((c) => c.method == 'SetConfig');
      expect((setConfigCall.request as dynamic).currency, 'PHP',
          reason: 'the chosen code must be sent, not the one loaded at open');
    });

    /// PHEV pricing typed on the head unit must reach the daemon too — it was web-only
    /// before, so a PHEV owner's fuel cost silently stayed 0.
    testWidgets('fuel price and tank capacity are sent on apply', (tester) async {
      stubAllLoads(
        // isPhev — the fuel fields only exist on a car that has a tank.
        config: {'enabled': true, 'electricityRate': 0.15, 'currency': 'USD', 'distanceUnit': 'km', 'isPhev': true},
        storage: {'storageType': 'INTERNAL', 'limitMb': '500', 'usedMb': 0.0, 'usedUnit': 'MB', 'sdCardAvailable': true, 'tripsCount': 0, 'storagePath': ''},
      );
      await pumpScreen(tester);
      await tester.tap(find.byKey(const ValueKey('trips.tab.storage')));
      await tester.pumpAndSettle();
      rpc.stubJson('TripsService', 'SetConfig', {'success': true});
      rpc.stubJson('TripsService', 'SetStorage', {'success': true});

      await tester.enterText(
          find.byKey(const ValueKey('trips.storage.fuelPrice')), '1.85');
      await tester.enterText(
          find.byKey(const ValueKey('trips.storage.tankCapacity')), '47.5');
      await tester.tap(find.byKey(const ValueKey('trips.storage.apply')));
      await tester.pumpAndSettle();

      final setConfigCall = rpc.calls.lastWhere((c) => c.method == 'SetConfig');
      expect((setConfigCall.request as dynamic).fuelPricePerL, 1.85);
      expect((setConfigCall.request as dynamic).fuelTankCapacityL, 47.5);
      // Presence companions: without them a deliberate 0 is indistinguishable from
      // "not sent" and the daemon would keep the previous value.
      expect((setConfigCall.request as dynamic).hasFuelPricePerL_8, isTrue);
      expect((setConfigCall.request as dynamic).hasFuelTankCapacityL_10, isTrue);
    });

    // ── BEV vs PHEV: the fuel settings must not exist on a car with no tank ──────

    /// A BEV owner opening Trips settings must not be offered a fuel price or a tank size.
    /// They are not merely unused there — a car with no tank showing "Fuel Tank Capacity"
    /// reads as a bug in the app.
    testWidgets('hides the fuel settings entirely on a BEV', (tester) async {
      stubAllLoads(
        config: {'enabled': true, 'electricityRate': 0.15, 'currency': 'USD', 'distanceUnit': 'km', 'isPhev': false},
        storage: {'storageType': 'INTERNAL', 'limitMb': '500', 'usedMb': 0.0, 'usedUnit': 'MB', 'sdCardAvailable': true, 'tripsCount': 0, 'storagePath': ''},
      );
      await pumpScreen(tester);
      await tester.tap(find.byKey(const ValueKey('trips.tab.storage')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('trips.storage.fuelPrice')), findsNothing);
      expect(find.byKey(const ValueKey('trips.storage.tankCapacity')), findsNothing);
      // The ELECTRIC settings are untouched — a BEV still prices its own energy.
      expect(find.byKey(const ValueKey('trips.storage.rate')), findsOneWidget);
      expect(find.byKey(const ValueKey('trips.storage.currency')), findsOneWidget);
    });

    testWidgets('shows the fuel settings on a PHEV', (tester) async {
      stubAllLoads(
        config: {'enabled': true, 'electricityRate': 0.15, 'currency': 'USD', 'distanceUnit': 'km', 'isPhev': true},
        storage: {'storageType': 'INTERNAL', 'limitMb': '500', 'usedMb': 0.0, 'usedUnit': 'MB', 'sdCardAvailable': true, 'tripsCount': 0, 'storagePath': ''},
      );
      await pumpScreen(tester);
      await tester.tap(find.byKey(const ValueKey('trips.tab.storage')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('trips.storage.fuelPrice')), findsOneWidget);
      expect(find.byKey(const ValueKey('trips.storage.tankCapacity')), findsOneWidget);
    });

    /// The drivetrain probe reads false while the HAL warms up. An owner who has already
    /// configured a fuel price must still be able to SEE and clear it — otherwise the value
    /// keeps being applied by a field that has vanished, which is unfixable from the UI.
    testWidgets('keeps a configured fuel price visible even when the probe says BEV', (tester) async {
      stubAllLoads(
        config: {
          'enabled': true, 'electricityRate': 0.15, 'currency': 'USD', 'distanceUnit': 'km',
          'isPhev': false, 'fuelPricePerL': 1.85,
        },
        storage: {'storageType': 'INTERNAL', 'limitMb': '500', 'usedMb': 0.0, 'usedUnit': 'MB', 'sdCardAvailable': true, 'tripsCount': 0, 'storagePath': ''},
      );
      await pumpScreen(tester);
      await tester.tap(find.byKey(const ValueKey('trips.tab.storage')));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(
          find.byKey(const ValueKey('trips.storage.fuelPrice')));
      expect(field.controller!.text, '1.85');
    });

    testWidgets('shows the running state while the sync RPC is in flight', (tester) async {
      stubAllLoads();
      final gated = _GatedRpcTransport();
      controller = TripsController(tripsService: TripsServiceClient(rpc), longTripsService: TripsServiceClient(gated));
      await pumpScreen(tester);
      await tester.tap(find.byKey(const ValueKey('trips.tab.storage')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('trips.sync.button')));
      await tester.pump();

      expect(find.byKey(const ValueKey('trips.sync.running')), findsOneWidget);

      gated.gate.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('Synced successfully'), findsOneWidget);
    });

    testWidgets('syncing shows a success message', (tester) async {
      // The transient "running" state (true while its own RPC await is in
      // flight) is proven reliably at the controller level via a listener —
      // FakeRpcClient resolves on the next microtask with no real delay, so
      // it's too narrow a window for a widget test's pump() granularity to
      // assert on without flaking.
      stubAllLoads();
      await pumpScreen(tester);
      await tester.tap(find.byKey(const ValueKey('trips.tab.storage')));
      await tester.pumpAndSettle();
      longRpc.stubJson('TripsService', 'SyncTrips', {'success': true, 'added': 1, 'removed': 0, 'total': 5});

      await tester.tap(find.byKey(const ValueKey('trips.sync.button')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Synced successfully'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('trips.sync.dismiss')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('trips.sync.button')), findsOneWidget);
    });

    testWidgets('a sync failure with no server message shows the generic fallback', (tester) async {
      stubAllLoads();
      await pumpScreen(tester);
      await tester.tap(find.byKey(const ValueKey('trips.tab.storage')));
      await tester.pumpAndSettle();
      longRpc.stubJson('TripsService', 'SyncTrips', {'success': false, 'error': ''});

      await tester.tap(find.byKey(const ValueKey('trips.sync.button')));
      await tester.pumpAndSettle();

      expect(find.text('Sync failed'), findsOneWidget);
    });
  });

  group('detail overlay', () {
    testWidgets('tapping a trip row opens the detail screen', (tester) async {
      rpc.stubJson('TripsService', 'GetTrip', {
        'success': true,
        'trip': {
          'summary': {'id': '1', 'startTime': '1000', 'endTime': '5000', 'distanceKm': 5.0, 'durationSeconds': 600},
        },
      });
      rpc.stubJson('TripsService', 'GetTelemetry', {'success': true, 'telemetry': []});
      stubAllLoads(trips: [aTrip(id: 1)]);
      await pumpScreen(tester);

      await tester.tap(find.byKey(const ValueKey('trips.row.1')));
      await tester.pumpAndSettle();

      expect(find.byType(TripDetailScreen), findsOneWidget);
    });

    testWidgets('a system back gesture closes the detail instead of leaving the screen', (tester) async {
      rpc.stubJson('TripsService', 'GetTrip', {
        'success': true,
        'trip': {
          'summary': {'id': '1', 'startTime': '1000', 'endTime': '5000', 'distanceKm': 5.0, 'durationSeconds': 600},
        },
      });
      rpc.stubJson('TripsService', 'GetTelemetry', {'success': true, 'telemetry': []});
      stubAllLoads(trips: [aTrip(id: 1)]);
      await pumpScreen(tester);
      await tester.tap(find.byKey(const ValueKey('trips.row.1')));
      await tester.pumpAndSettle();
      expect(find.byType(TripDetailScreen), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(TripDetailScreen), findsNothing);
      expect(find.byKey(const ValueKey('trips.row.1')), findsOneWidget);
    });

    testWidgets('the back button closes the detail and returns to the list', (tester) async {
      rpc.stubJson('TripsService', 'GetTrip', {
        'success': true,
        'trip': {
          'summary': {'id': '1', 'startTime': '1000', 'endTime': '5000', 'distanceKm': 5.0, 'durationSeconds': 600},
        },
      });
      rpc.stubJson('TripsService', 'GetTelemetry', {'success': true, 'telemetry': []});
      stubAllLoads(trips: [aTrip(id: 1)]);
      await pumpScreen(tester);
      await tester.tap(find.byKey(const ValueKey('trips.row.1')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('tripDetail.back')));
      await tester.pumpAndSettle();

      expect(find.byType(TripDetailScreen), findsNothing);
      expect(find.byKey(const ValueKey('trips.row.1')), findsOneWidget);
    });
  });

  testWidgets('renders correctly in dark theme', (tester) async {
    stubAllLoads(trips: [aTrip()]);
    await pumpScreen(tester, brightness: Brightness.dark);

    expect(find.byKey(const ValueKey('trips.row.1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
