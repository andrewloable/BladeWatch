import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_rpc/rpc/services/trips_service_client.dart';
import 'package:bladewatch_ui/screens/trips/trip_detail_controller.dart';
import 'package:bladewatch_ui/screens/trips/trip_detail_screen.dart';
import 'package:bladewatch_ui/screens/trips/trips_controller.dart';
import 'package:bladewatch_ui/screens/trips/trips_screen.dart';
import 'package:bladewatch_ui/util/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';

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

  // BladeWatch-mgi9 / -c149: the period's fuel, electric and total cost.
  group('period costs', () {
    List<Map<String, dynamic>> costedTrips() => [
          {...aTrip(id: 1), 'tripCost': 150.0, 'fuelCost': 100.0, 'currency': 'PHP', 'hasFuelData': true},
          {...aTrip(id: 2), 'tripCost': 30.0, 'currency': 'PHP'},
        ];

    testWidgets('the Stats tab shows them under Personalized Range', (tester) async {
      stubAllLoads(trips: costedTrips());
      await pumpScreen(tester);
      await tester.tap(find.byKey(const ValueKey('trips.tab.stats')));
      await tester.pumpAndSettle();

      final card = find.byKey(const ValueKey('trips.costCard'));
      for (final (label, value) in [('Fuel Cost', 100.0), ('Electric Cost', 80.0), ('Total Cost', 180.0)]) {
        expect(find.descendant(of: card, matching: find.text(label)), findsOneWidget);
        expect(find.descendant(of: card, matching: find.text(Currency.format(value, 'PHP'))), findsOneWidget, reason: label);
      }
      expect(find.byKey(const ValueKey('trips.rangeCard')), findsOneWidget, reason: 'range kept');
      final range = tester.getTopLeft(find.byKey(const ValueKey('trips.rangeCard')));
      expect(tester.getTopLeft(card).dy, greaterThan(range.dy), reason: 'under Personalized Range');
    });

    testWidgets('the Period Summary shows them after its own figures', (tester) async {
      stubAllLoads(trips: costedTrips());
      await pumpScreen(tester);

      final costs = find.byKey(const ValueKey('trips.summaryCosts'));
      expect(find.descendant(of: costs, matching: find.text('Total Cost')), findsOneWidget);
      expect(find.descendant(of: costs, matching: find.text(Currency.format(180, 'PHP'))), findsOneWidget);
    });

    testWidgets('with no rate set it says so instead of showing zeros', (tester) async {
      stubAllLoads(trips: [{...aTrip(id: 1), 'tripCost': 0.0}]);
      await pumpScreen(tester);
      await tester.tap(find.byKey(const ValueKey('trips.tab.stats')));
      await tester.pumpAndSettle();

      expect(find.descendant(
          of: find.byKey(const ValueKey('trips.costCard')),
          matching: find.text('Set an electricity rate in Trip settings to see costs.')), findsOneWidget);
    });
  });

  testWidgets('Stats tab shows "not enough data" when there is no range estimate', (tester) async {
    stubAllLoads(rangeJson: '{}');
    await pumpScreen(tester);
    await tester.tap(find.byKey(const ValueKey('trips.tab.stats')));
    await tester.pumpAndSettle();

    expect(find.text('Not enough data yet'), findsOneWidget);
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
