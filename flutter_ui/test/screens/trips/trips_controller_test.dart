import 'package:bladewatch_ui/rpc/services/trips_service_client.dart';
import 'package:bladewatch_ui/screens/trips/trips_controller.dart';
import 'package:bladewatch_ui/screens/trips/trips_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_rpc_client.dart';

void main() {
  late FakeRpcClient rpc;
  late FakeRpcClient longRpc;
  late TripsController controller;

  void stubAllLoads({
    List<Map<String, dynamic>> trips = const [],
    List<Map<String, dynamic>> rollups = const [],
    Map<String, dynamic>? dna,
    String rangeJson = '{}',
    Map<String, dynamic>? config,
    Map<String, dynamic>? storage,
  }) {
    rpc.stubJson('TripsService', 'ListTrips', {'success': true, 'trips': trips});
    rpc.stubJson('TripsService', 'GetSummary', {'success': true, 'summary': rollups});
    rpc.stubJson('TripsService', 'GetDna', {'success': true, 'dna': dna});
    rpc.stubJson('TripsService', 'GetRange', {'success': true, 'rangeJson': rangeJson});
    rpc.stubJson('TripsService', 'GetConfig', {'success': true, 'config': config});
    rpc.stubJson('TripsService', 'GetStorage', {'success': true, 'storage': storage});
  }

  Map<String, dynamic> aTrip({int id = 1}) => {
        'id': '$id',
        'startTime': '1000',
        'endTime': '2000',
        'distanceKm': 12.5,
        'durationSeconds': 900,
        'overallScore': 80,
        'tripCost': 2.5,
        'currency': 'USD',
      };

  setUp(() {
    rpc = FakeRpcClient();
    longRpc = FakeRpcClient();
    controller = TripsController(tripsService: TripsServiceClient(rpc), longTripsService: TripsServiceClient(longRpc));
  });

  test('starts in the loading state, on the Trips tab, 7-day filter', () {
    expect(controller.state, isA<TripsLoading>());
    expect(controller.activeTab, TripsTab.trips);
    expect(controller.activeFilter, TripsDaysFilter.seven);
  });

  group('load', () {
    test('populates a Loaded state from all 6 RPCs', () async {
      stubAllLoads(
        trips: [aTrip()],
        rollups: [
          {'rollupJson': '{"tripCount":3,"totalDistanceKm":30.0,"totalDurationSeconds":1800,"totalEnergyKwh":10.0,"avgEfficiency":85.0,"avgEnergyPerKm":0.2}'}
        ],
        dna: {'anticipation': 80, 'smoothness': 70, 'speedDiscipline': 60, 'efficiency': 90, 'consistency': 75, 'overall': 77},
        rangeJson: '{"range":{"predictedRangeKm":320.5,"builtInRangeKm":300.0}}',
        config: {'enabled': true, 'electricityRate': 0.15, 'currency': 'USD', 'distanceUnit': 'km'},
        storage: {'storageType': 'INTERNAL', 'limitMb': '500', 'usedMb': 120.0, 'usedUnit': 'MB', 'sdCardAvailable': false, 'tripsCount': 5, 'storagePath': '/x'},
      );

      await controller.load();

      final state = controller.state as TripsLoaded;
      expect(state.trips, hasLength(1));
      expect(state.summary!.tripCount, 3);
      expect(state.dna!.overall, 77);
      expect(state.range!.estimatedKm, 320.5);
      expect(state.config!.currency, 'USD');
      expect(state.storage!.tripsCount, 5);
    });

    test('requests GetDna with a hardcoded 30 days regardless of the active filter', () async {
      stubAllLoads();
      controller.selectFilter(TripsDaysFilter.seven);

      await controller.load();

      final dnaCall = rpc.calls.firstWhere((c) => c.method == 'GetDna');
      expect((dnaCall.request as dynamic).days, 30);
    });

    test('requests ListTrips/GetSummary with the active filter\'s day count and limit 100', () async {
      stubAllLoads();
      await controller.selectFilter(TripsDaysFilter.thirty);

      final listCall = rpc.calls.firstWhere((c) => c.method == 'ListTrips');
      expect((listCall.request as dynamic).days, 30);
      expect((listCall.request as dynamic).limit, 100);
    });

    test('averages summary rollups across entries and sums counts/totals', () async {
      stubAllLoads(rollups: [
        {'rollupJson': '{"tripCount":2,"totalDistanceKm":10.0,"totalDurationSeconds":600,"totalEnergyKwh":4.0,"avgEfficiency":80.0,"avgEnergyPerKm":0.1}'},
        {'rollupJson': '{"tripCount":3,"totalDistanceKm":20.0,"totalDurationSeconds":900,"totalEnergyKwh":6.0,"avgEfficiency":90.0,"avgEnergyPerKm":0.3}'},
      ]);

      await controller.load();

      final summary = (controller.state as TripsLoaded).summary!;
      expect(summary.tripCount, 5);
      expect(summary.totalDistanceKm, 30.0);
      expect(summary.totalDurationSeconds, 1500);
      expect(summary.totalEnergyKwh, 10.0);
      expect(summary.avgEfficiency, 85.0); // (80+90)/2
      expect(summary.avgEnergyPerKm, 0.2); // (0.1+0.3)/2
    });

    test('skips an unparseable rollup entry rather than crashing', () async {
      stubAllLoads(rollups: [
        {'rollupJson': 'not json'},
        {'rollupJson': '{"tripCount":1,"totalDistanceKm":5.0,"totalDurationSeconds":300,"totalEnergyKwh":1.0,"avgEfficiency":50.0,"avgEnergyPerKm":0.1}'},
      ]);

      await controller.load();

      final summary = (controller.state as TripsLoaded).summary!;
      expect(summary.tripCount, 1);
    });

    test('reads range from the nested "range" object when present', () async {
      stubAllLoads(rangeJson: '{"range":{"predictedRangeKm":250.0,"builtInRangeKm":240.0}}');
      await controller.load();
      final range = (controller.state as TripsLoaded).range!;
      expect(range.estimatedKm, 250.0);
      expect(range.builtInKm, 240.0);
    });

    test('reads range from the top-level object when there is no nested "range" key', () async {
      stubAllLoads(rangeJson: '{"predictedRangeKm":100.0,"builtInRangeKm":90.0}');
      await controller.load();
      final range = (controller.state as TripsLoaded).range!;
      expect(range.estimatedKm, 100.0);
    });

    test('transitions to Error when a request fails', () async {
      rpc.stubError('TripsService', 'ListTrips', const ConnectError('unavailable', 'no daemon'));

      await controller.load();

      expect(controller.state, isA<TripsError>());
    });

    test('notifies listeners', () async {
      stubAllLoads();
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.load();

      expect(notifications, greaterThan(0));
    });
  });

  group('selectTab', () {
    test('switches the active tab without reloading data', () async {
      stubAllLoads();
      await controller.load();
      final callsBefore = rpc.calls.length;

      controller.selectTab(TripsTab.stats);

      expect(controller.activeTab, TripsTab.stats);
      expect(rpc.calls.length, callsBefore);
    });
  });

  group('selectFilter', () {
    test('changes the filter and reloads', () async {
      stubAllLoads();
      await controller.load();
      final callsBefore = rpc.calls.length;

      await controller.selectFilter(TripsDaysFilter.fourteen);

      expect(controller.activeFilter, TripsDaysFilter.fourteen);
      expect(rpc.calls.length, greaterThan(callsBefore));
    });
  });

  group('applyStorageChanges', () {
    test('saves config and storage, then reloads, returning true on success', () async {
      stubAllLoads(storage: {'storageType': 'INTERNAL', 'limitMb': '500', 'usedMb': 1.0, 'usedUnit': 'MB', 'sdCardAvailable': true, 'tripsCount': 1, 'storagePath': ''});
      await controller.load();
      rpc.stubJson('TripsService', 'SetConfig', {'success': true});
      rpc.stubJson('TripsService', 'SetStorage', {'success': true});

      final ok = await controller.applyStorageChanges(
        enabled: true,
        rate: 0.2,
        fuelPricePerL: 1.8,
        fuelTankCapacityL: 50.0,
        currency: 'EUR',
        distanceUnit: 'mi',
        storageType: 'SD_CARD',
      );

      expect(ok, isTrue);
      final setConfigCall = rpc.calls.firstWhere((c) => c.method == 'SetConfig');
      expect((setConfigCall.request as dynamic).currency, 'EUR');
      // BladeWatch-9uu6: PHEV pricing must actually reach the daemon, with its presence
      // companions — proto3 omits default scalars, so without them a deliberate 0 would be
      // indistinguishable from "not sent" and the daemon would keep the old value.
      expect((setConfigCall.request as dynamic).fuelPricePerL, 1.8);
      expect((setConfigCall.request as dynamic).hasFuelPricePerL_8, isTrue);
      expect((setConfigCall.request as dynamic).fuelTankCapacityL, 50.0);
      expect((setConfigCall.request as dynamic).hasFuelTankCapacityL_10, isTrue);
      final setStorageCall = rpc.calls.firstWhere((c) => c.method == 'SetStorage');
      expect((setStorageCall.request as dynamic).storageType, 'SD_CARD');
      expect((setStorageCall.request as dynamic).storageLimitMb.toInt(), 500); // resends the loaded limit unchanged
    });

    test('returns false without throwing when SetConfig fails', () async {
      stubAllLoads(storage: {'storageType': 'INTERNAL', 'limitMb': '500', 'usedMb': 1.0, 'usedUnit': 'MB', 'sdCardAvailable': true, 'tripsCount': 1, 'storagePath': ''});
      await controller.load();
      rpc.stubJson('TripsService', 'SetConfig', {'success': false, 'error': 'nope'});
      rpc.stubJson('TripsService', 'SetStorage', {'success': true});

      final ok = await controller.applyStorageChanges(enabled: true, rate: 0.2, fuelPricePerL: 0, fuelTankCapacityL: 0, currency: 'USD', distanceUnit: 'km', storageType: 'INTERNAL');

      expect(ok, isFalse);
    });

    test('returns false without throwing when there is no loaded storage to resend the limit from', () async {
      stubAllLoads(storage: null);
      await controller.load();

      final ok = await controller.applyStorageChanges(enabled: true, rate: 0.2, fuelPricePerL: 0, fuelTankCapacityL: 0, currency: 'USD', distanceUnit: 'km', storageType: 'INTERNAL');

      expect(ok, isFalse);
    });
  });

  group('syncDatabase', () {
    test('sets syncRunning while in flight and a success message after', () async {
      longRpc.stubJson('TripsService', 'SyncTrips', {'success': true, 'added': 2, 'removed': 1, 'total': 10});
      final states = <bool>[];
      controller.addListener(() => states.add(controller.syncRunning));

      await controller.syncDatabase();

      expect(states, contains(true));
      expect(controller.syncRunning, isFalse);
      expect(controller.syncResult, isNotNull);
      expect(controller.syncResult!.success, isTrue);
      expect(controller.syncResult!.added, 2);
      expect(controller.syncResult!.removed, 1);
      expect(controller.syncResult!.total, 10);
    });

    test('uses the long-timeout client, not the default one', () async {
      longRpc.stubJson('TripsService', 'SyncTrips', {'success': true, 'added': 0, 'removed': 0, 'total': 0});

      await controller.syncDatabase();

      expect(longRpc.calls, hasLength(1));
      expect(rpc.calls.where((c) => c.method == 'SyncTrips'), isEmpty);
    });

    test('sets a failure outcome with the server\'s error text when the sync fails', () async {
      longRpc.stubJson('TripsService', 'SyncTrips', {'success': false, 'error': 'disk full'});

      await controller.syncDatabase();

      expect(controller.syncResult!.success, isFalse);
      expect(controller.syncResult!.error, 'disk full');
    });

    test('leaves error null when the server reports failure with no error text', () async {
      longRpc.stubJson('TripsService', 'SyncTrips', {'success': false, 'error': ''});

      await controller.syncDatabase();

      expect(controller.syncResult!.success, isFalse);
      expect(controller.syncResult!.error, isNull);
    });

    test('sets a failure outcome with no error text when the RPC throws', () async {
      longRpc.stubError('TripsService', 'SyncTrips', const ConnectError('unavailable', 'no daemon'));

      await controller.syncDatabase();

      expect(controller.syncResult!.success, isFalse);
      expect(controller.syncResult!.error, isNull);
    });

    test('dismissSyncResult clears the result', () async {
      longRpc.stubJson('TripsService', 'SyncTrips', {'success': false, 'error': 'x'});
      await controller.syncDatabase();

      controller.dismissSyncResult();

      expect(controller.syncResult, isNull);
    });
  });

  group('detail overlay', () {
    test('openDetail/closeDetail toggle selectedTripId', () {
      expect(controller.selectedTripId, isNull);

      controller.openDetail(42);
      expect(controller.selectedTripId, 42);

      controller.closeDetail();
      expect(controller.selectedTripId, isNull);
    });

    test('notifies listeners on open and close', () {
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.openDetail(1);
      controller.closeDetail();

      expect(notifications, 2);
    });
  });
}
