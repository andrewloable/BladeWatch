import 'dart:async';

import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_rpc/rpc/rpc_transport.dart';
import 'package:bladewatch_rpc/rpc/services/trips_service_client.dart';
import 'package:bladewatch_ui/screens/settings/settings_trips_screen.dart';
import 'package:bladewatch_ui/screens/trips/trips_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';
import 'package:bladewatch_ui/widgets/bw_choice_chip.dart';

/// These cases moved here with the pane itself: they were the Trips screen's
/// "Storage tab" group before the trip settings became a Settings section.
/// The widget keys kept their `trips.storage.*` spelling so the move is a
/// relocation, not a rewrite of what is being asserted.

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
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: brightness),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SettingsTripsScreen(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Trips settings pane', () {
    testWidgets('renders the loaded config/storage values', (tester) async {
      stubAllLoads(
        // isPhev, so the fuel fields are on screen at all — their SEEDING is what this
        // asserts; whether they appear for a given drivetrain is covered separately below.
        config: {'enabled': true, 'electricityRate': 0.15, 'currency': 'USD', 'distanceUnit': 'km', 'isPhev': true},
        storage: {
          'storageType': 'INTERNAL',
          'limitMb': '500',
          'usedMb': 10.0,
          'usedUnit': 'MB',
          'sdCardAvailable': false,
          'tripsCount': 2,
          'storagePath': '/x',
        },
      );
      await pumpScreen(tester);

      // BladeWatch-9uu6/-gzbo: currency is PICKED, and from a list of SYMBOLS: a config holding the
      // code USD shows the dollar sign.
      final currencyField = tester.widget<DropdownButtonFormField<String>>(
        find.byKey(const ValueKey('trips.storage.currency')),
      );
      expect(currencyField.initialValue, r'$');
      final sw = tester.widget<SwitchListTile>(find.byKey(const ValueKey('trips.storage.analytics')));
      expect(sw.value, isTrue);

      // PHEV pricing seeds from the loaded config too — persisting a value is only half of
      // "it persists" if the settings screen then shows the default instead.
      final fuelPrice = tester.widget<TextField>(find.byKey(const ValueKey('trips.storage.fuelPrice')));
      expect(fuelPrice.controller!.text, '0.00', reason: 'absent from this config, so it must read as not-configured');
      final tank = tester.widget<TextField>(find.byKey(const ValueKey('trips.storage.tankCapacity')));
      expect(tank.controller!.text, '0.0');
    });

    testWidgets('toggling the analytics switch and re-selecting Internal storage update local state', (tester) async {
      stubAllLoads(
        config: {'enabled': false, 'electricityRate': 0.1, 'currency': 'USD', 'distanceUnit': 'km'},
        storage: {
          'storageType': 'INTERNAL',
          'limitMb': '500',
          'usedMb': 0.0,
          'usedUnit': 'MB',
          'sdCardAvailable': true,
          'tripsCount': 0,
          'storagePath': '',
        },
      );
      await pumpScreen(tester);

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
      stubAllLoads(
        storage: {
          'storageType': 'INTERNAL',
          'limitMb': '500',
          'usedMb': 0.0,
          'usedUnit': 'MB',
          'sdCardAvailable': false,
          'tripsCount': 0,
          'storagePath': '',
        },
      );
      await pumpScreen(tester);

      expect(find.text('SD Card (N/A)'), findsOneWidget);
      final chip = tester.widget<BwChoiceChip>(find.byKey(const ValueKey('trips.storage.location.sdCard')));
      expect(chip.onSelected, isNull);
    });

    testWidgets('applying changes saves and shows a failure snackbar when it fails', (tester) async {
      stubAllLoads(
        storage: {
          'storageType': 'INTERNAL',
          'limitMb': '500',
          'usedMb': 0.0,
          'usedUnit': 'MB',
          'sdCardAvailable': true,
          'tripsCount': 0,
          'storagePath': '',
        },
      );
      await pumpScreen(tester);
      rpc.stubError('TripsService', 'SetConfig', const ConnectError('unavailable', 'no daemon'));

      await tester.tap(find.byKey(const ValueKey('trips.storage.apply')));
      await tester.pumpAndSettle();

      expect(find.text('Failed to save'), findsOneWidget);
    });

    testWidgets('applying changes succeeds and reloads', (tester) async {
      stubAllLoads(
        storage: {
          'storageType': 'INTERNAL',
          'limitMb': '500',
          'usedMb': 0.0,
          'usedUnit': 'MB',
          'sdCardAvailable': true,
          'tripsCount': 0,
          'storagePath': '',
        },
      );
      await pumpScreen(tester);
      rpc.stubJson('TripsService', 'SetConfig', {'success': true});
      rpc.stubJson('TripsService', 'SetStorage', {'success': true});

      await tester.tap(find.byKey(const ValueKey('trips.storage.location.sdCard')));
      await tester.tap(find.byKey(const ValueKey('trips.storage.apply')));
      await tester.pumpAndSettle();

      final setStorageCall = rpc.calls.lastWhere((c) => c.method == 'SetStorage');
      expect((setStorageCall.request as dynamic).storageType, 'SD_CARD');
    });

    /// BladeWatch-9uu6/-gzbo: the owner's currency choice has to actually reach the daemon —
    /// that is the whole point of "the selection persists". Picking from the dropdown and
    /// applying must send the chosen SYMBOL, not what the screen loaded with.
    Future<void> pumpWithCurrency(WidgetTester tester, String? currency) async {
      stubAllLoads(
        config: {
          'enabled': true,
          'electricityRate': 0.15,
          'currency': ?currency,
          'distanceUnit': 'km',
        },
        storage: {
          'storageType': 'INTERNAL',
          'limitMb': '500',
          'usedMb': 0.0,
          'usedUnit': 'MB',
          'sdCardAvailable': true,
          'tripsCount': 0,
          'storagePath': '',
        },
      );
      await pumpScreen(tester);
      rpc.stubJson('TripsService', 'SetConfig', {'success': true});
      rpc.stubJson('TripsService', 'SetStorage', {'success': true});
    }

    DropdownButtonFormField<String> picker(WidgetTester tester) =>
        tester.widget<DropdownButtonFormField<String>>(find.byKey(const ValueKey('trips.storage.currency')));

    // DropdownButtonFormField does not expose its items; the DropdownButton inside it does.
    List<String> menu(WidgetTester tester) => tester
        .widget<DropdownButton<String>>(
          find.descendant(
            of: find.byKey(const ValueKey('trips.storage.currency')),
            matching: find.byType(DropdownButton<String>),
          ),
        )
        .items!
        .map((i) => i.value!)
        .toList();

    Future<String?> applyAndReadCurrency(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('trips.storage.apply')));
      await tester.pumpAndSettle();
      return (rpc.calls.lastWhere((c) => c.method == 'SetConfig').request as dynamic).currency as String?;
    }

    testWidgets('picking a currency sends the chosen symbol on apply', (tester) async {
      await pumpWithCurrency(tester, 'USD');
      // The callback is invoked directly rather than driving the menu route.
      expect(
        picker(tester).onChanged,
        isNotNull,
        reason: 'the picker is usable at once: there is no catalogue to load',
      );
      picker(tester).onChanged!('\u20B1');
      await tester.pumpAndSettle();

      expect(await applyAndReadCurrency(tester), '\u20B1', reason: 'the chosen symbol, not the one loaded at open');
    });

    testWidgets('a car storing an ISO code shows its symbol and is NOT rewritten by a bare Apply', (tester) async {
      await pumpWithCurrency(tester, 'PHP');
      expect(picker(tester).initialValue, '\u20B1');

      expect(
        await applyAndReadCurrency(tester),
        'PHP',
        reason: 'opening Settings and pressing Apply must not change what history was priced in',
      );
    });

    testWidgets('picking the symbol a stored code already maps to does replace it', (tester) async {
      await pumpWithCurrency(tester, 'PHP');
      picker(tester).onChanged!('\u20B1');
      await tester.pumpAndSettle();
      expect(await applyAndReadCurrency(tester), '\u20B1');
    });

    testWidgets('a legacy free-text value is offered once, first, and survives a bare Apply', (tester) async {
      await pumpWithCurrency(tester, 'Rs.');
      expect(picker(tester).initialValue, 'Rs.');
      final items = menu(tester);
      expect(items.where((v) => v == 'Rs.'), hasLength(1));
      expect(items.first, 'Rs.');

      expect(await applyAndReadCurrency(tester), 'Rs.');
    });

    testWidgets('a fresh car (nothing stored) selects the dollar sign and sends it', (tester) async {
      await pumpWithCurrency(tester, null);
      expect(picker(tester).initialValue, r'$');
      expect(await applyAndReadCurrency(tester), r'$');
    });

    testWidgets('the menu offers symbols only: no ISO code, no duplicate', (tester) async {
      await pumpWithCurrency(tester, 'USD');
      final items = menu(tester);
      expect(items, hasLength(80));
      expect(items.toSet(), hasLength(items.length));
      for (final v in items) {
        expect(RegExp(r'^[A-Za-z]{3}$').hasMatch(v), isFalse, reason: '"$v" is code-shaped');
      }
    });

    /// PHEV pricing typed on the head unit must reach the daemon too — it was web-only
    /// before, so a PHEV owner's fuel cost silently stayed 0.
    testWidgets('fuel price and tank capacity are sent on apply', (tester) async {
      stubAllLoads(
        // isPhev — the fuel fields only exist on a car that has a tank.
        config: {'enabled': true, 'electricityRate': 0.15, 'currency': 'USD', 'distanceUnit': 'km', 'isPhev': true},
        storage: {
          'storageType': 'INTERNAL',
          'limitMb': '500',
          'usedMb': 0.0,
          'usedUnit': 'MB',
          'sdCardAvailable': true,
          'tripsCount': 0,
          'storagePath': '',
        },
      );
      await pumpScreen(tester);
      rpc.stubJson('TripsService', 'SetConfig', {'success': true});
      rpc.stubJson('TripsService', 'SetStorage', {'success': true});

      await tester.enterText(find.byKey(const ValueKey('trips.storage.fuelPrice')), '1.85');
      await tester.enterText(find.byKey(const ValueKey('trips.storage.tankCapacity')), '47.5');
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
        storage: {
          'storageType': 'INTERNAL',
          'limitMb': '500',
          'usedMb': 0.0,
          'usedUnit': 'MB',
          'sdCardAvailable': true,
          'tripsCount': 0,
          'storagePath': '',
        },
      );
      await pumpScreen(tester);

      expect(find.byKey(const ValueKey('trips.storage.fuelPrice')), findsNothing);
      expect(find.byKey(const ValueKey('trips.storage.tankCapacity')), findsNothing);
      // The ELECTRIC settings are untouched — a BEV still prices its own energy.
      expect(find.byKey(const ValueKey('trips.storage.rate')), findsOneWidget);
      expect(find.byKey(const ValueKey('trips.storage.currency')), findsOneWidget);
    });

    testWidgets('shows the fuel settings on a PHEV', (tester) async {
      stubAllLoads(
        config: {'enabled': true, 'electricityRate': 0.15, 'currency': 'USD', 'distanceUnit': 'km', 'isPhev': true},
        storage: {
          'storageType': 'INTERNAL',
          'limitMb': '500',
          'usedMb': 0.0,
          'usedUnit': 'MB',
          'sdCardAvailable': true,
          'tripsCount': 0,
          'storagePath': '',
        },
      );
      await pumpScreen(tester);

      expect(find.byKey(const ValueKey('trips.storage.fuelPrice')), findsOneWidget);
      expect(find.byKey(const ValueKey('trips.storage.tankCapacity')), findsOneWidget);
    });

    /// The drivetrain probe reads false while the HAL warms up. An owner who has already
    /// configured a fuel price must still be able to SEE and clear it — otherwise the value
    /// keeps being applied by a field that has vanished, which is unfixable from the UI.
    testWidgets('keeps a configured fuel price visible even when the probe says BEV', (tester) async {
      stubAllLoads(
        config: {
          'enabled': true,
          'electricityRate': 0.15,
          'currency': 'USD',
          'distanceUnit': 'km',
          'isPhev': false,
          'fuelPricePerL': 1.85,
        },
        storage: {
          'storageType': 'INTERNAL',
          'limitMb': '500',
          'usedMb': 0.0,
          'usedUnit': 'MB',
          'sdCardAvailable': true,
          'tripsCount': 0,
          'storagePath': '',
        },
      );
      await pumpScreen(tester);

      final field = tester.widget<TextField>(find.byKey(const ValueKey('trips.storage.fuelPrice')));
      expect(field.controller!.text, '1.85');
    });

    testWidgets('shows the running state while the sync RPC is in flight', (tester) async {
      stubAllLoads();
      final gated = _GatedRpcTransport();
      controller = TripsController(tripsService: TripsServiceClient(rpc), longTripsService: TripsServiceClient(gated));
      await pumpScreen(tester);

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
      longRpc.stubJson('TripsService', 'SyncTrips', {'success': false, 'error': ''});

      await tester.tap(find.byKey(const ValueKey('trips.sync.button')));
      await tester.pumpAndSettle();

      expect(find.text('Sync failed'), findsOneWidget);
    });
  });
}
