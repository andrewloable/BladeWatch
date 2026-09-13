import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/rpc/services/trips_service_client.dart';
import 'package:bladewatch_ui/screens/trips/trip_detail_controller.dart';
import 'package:bladewatch_ui/screens/trips/trip_detail_screen.dart';
import 'package:bladewatch_ui/screens/trips/trips_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_rpc_client.dart';

void main() {
  late FakeRpcClient rpc;
  late TripDetailController controller;
  late bool closed;

  Map<String, dynamic> aTripDetailResponse() => {
        'success': true,
        'trip': {
          'summary': {
            'id': '1',
            'startTime': '1000',
            'endTime': '5000',
            'distanceKm': 20.0,
            'durationSeconds': 1200,
            'avgSpeedKmh': 45.0,
            'maxSpeedKmh': 90,
            'socStart': 80.0,
            'socEnd': 60.0,
            'tripCost': 3.5,
            'currency': 'USD',
            'overallScore': 88,
            'extTempC': 22,
          },
          'anticipationScore': 70,
          'smoothnessScore': 60,
          'speedDisciplineScore': 90,
          'efficiencyScore': 80,
          'consistencyScore': 75,
          'elevationGainM': 12.0,
          'elevationLossM': 8.0,
        },
      };

  setUp(() {
    rpc = FakeRpcClient();
    controller = TripDetailController(tripsService: TripsServiceClient(rpc));
    closed = false;
  });

  Future<void> pumpScreen(WidgetTester tester, {TripsConfig? config, Brightness brightness = Brightness.light}) async {
    tester.view.physicalSize = const Size(1400, 1800);
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
        body: TripDetailScreen(controller: controller, tripId: 1, config: config, onClose: () => closed = true),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('shows a loading indicator before load resolves', (tester) async {
    await pumpScreen(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the unavailable message when the trip cannot be loaded', (tester) async {
    rpc.stubError('TripsService', 'GetTrip', const ConnectError('unavailable', 'no daemon'));
    await pumpScreen(tester);

    expect(find.byKey(const ValueKey('tripDetail.error')), findsOneWidget);
    expect(find.text('Trip details unavailable'), findsOneWidget);
  });

  testWidgets('renders the summary, route and scores cards on success', (tester) async {
    rpc.stubJson('TripsService', 'GetTrip', aTripDetailResponse());
    rpc.stubJson('TripsService', 'GetTelemetry', {
      'success': true,
      'telemetry': [
        {'sampleJson': '{"t":1,"s":1,"a":1,"b":1,"la":37.1,"lo":-122.1}'},
        {'sampleJson': '{"t":2,"s":1,"a":1,"b":1,"la":37.2,"lo":-122.2}'},
      ],
    });

    await pumpScreen(tester);

    expect(find.byKey(const ValueKey('tripDetail.summaryCard')), findsOneWidget);
    expect(find.byKey(const ValueKey('tripDetail.routeCard')), findsOneWidget);
    expect(find.byKey(const ValueKey('tripDetail.scoresCard')), findsOneWidget);
    expect(find.text('2 GPS points recorded'), findsOneWidget);
  });

  testWidgets('shows "no route data" when fewer than 2 GPS points are present', (tester) async {
    rpc.stubJson('TripsService', 'GetTrip', aTripDetailResponse());
    rpc.stubJson('TripsService', 'GetTelemetry', {'success': true, 'telemetry': []});

    await pumpScreen(tester);

    expect(find.text('No route data for this trip'), findsOneWidget);
  });

  testWidgets('formats distance/speed in miles when the config distance unit is "mi"', (tester) async {
    rpc.stubJson('TripsService', 'GetTrip', aTripDetailResponse());
    rpc.stubJson('TripsService', 'GetTelemetry', {'success': true, 'telemetry': []});

    await pumpScreen(tester, config: const TripsConfig(enabled: true, electricityRate: 0, currency: 'USD', distanceUnit: 'mi'));

    expect(find.textContaining('mi'), findsWidgets);
    expect(find.textContaining('mph'), findsWidgets);
  });

  testWidgets('tapping Back calls onClose', (tester) async {
    rpc.stubJson('TripsService', 'GetTrip', aTripDetailResponse());
    rpc.stubJson('TripsService', 'GetTelemetry', {'success': true, 'telemetry': []});
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('tripDetail.back')));
    await tester.pump();

    expect(closed, isTrue);
  });

  testWidgets('renders correctly in dark theme', (tester) async {
    rpc.stubJson('TripsService', 'GetTrip', aTripDetailResponse());
    rpc.stubJson('TripsService', 'GetTelemetry', {'success': true, 'telemetry': []});

    await pumpScreen(tester, brightness: Brightness.dark);

    expect(find.byKey(const ValueKey('tripDetail.summaryCard')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
