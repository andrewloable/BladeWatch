import 'package:bladewatch_rpc/rpc/services/trips_service_client.dart';
import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';
import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/screens/trips/trip_detail_controller.dart';
import 'package:bladewatch_ui/screens/trips/trip_detail_screen.dart';
import 'package:bladewatch_ui/screens/trips/trips_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/hud_test_env.dart';

/// BladeWatch-reml.4: the trip detail shows EV and HEV driving separately. EV driving carries kWh
/// and the electricity cost, HEV driving carries litres and the fuel cost, and HEV driving shows no
/// kWh anywhere.
void main() {
  hudTestEnvironment();
  late FakeRpcClient rpc;
  late TripDetailController controller;

  Map<String, dynamic> response({
    double evKm = 0,
    double evKwh = 0,
    double hevKm = 0,
    double hevLitres = 0,
    bool split = true,
    double energyPerKm = 0,
    double electricCost = 0,
    double fuelCost = 0,
    bool hasFuelData = false,
  }) => {
    'success': true,
    'trip': {
      'summary': {
        'id': '1',
        'startTime': '1000',
        'endTime': '5000',
        'distanceKm': evKm + hevKm,
        'durationSeconds': 1200,
        'avgSpeedKmh': 45.0,
        'maxSpeedKmh': 90,
        'socStart': 80.0,
        'socEnd': 60.0,
        'tripCost': electricCost + fuelCost,
        'currency': 'USD',
        'overallScore': 88,
        'extTempC': 22,
        'energyPerKm': energyPerKm,
        'electricCost': electricCost,
        'fuelCost': fuelCost,
        'hasFuelData': hasFuelData,
        'litresUsed': hevLitres,
        'hasEnergySplit': split,
        'evKm': evKm,
        'evKwh': evKwh,
        'hevKm': hevKm,
        'hevLitres': hevLitres,
      },
      'anticipationScore': 70,
      'smoothnessScore': 60,
      'speedDisciplineScore': 90,
      'efficiencyScore': 80,
      'consistencyScore': 75,
    },
  };

  setUp(() {
    rpc = FakeRpcClient();
    controller = TripDetailController(tripsService: TripsServiceClient(rpc));
    rpc.stubJson('TripsService', 'GetTelemetry', {'success': true, 'telemetry': []});
  });

  Future<void> pump(WidgetTester tester, Map<String, dynamic> r, {String unit = 'km'}) async {
    rpc.stubJson('TripsService', 'GetTrip', r);
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(brightness: Brightness.light),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TripDetailScreen(
          controller: controller,
          tripId: 1,
          config: TripsConfig(enabled: true, electricityRate: 0.2, currency: 'USD', distanceUnit: unit),
          onClose: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  final evCard = find.byKey(const ValueKey('tripDetail.evCard'));
  final hevCard = find.byKey(const ValueKey('tripDetail.hevCard'));

  testWidgets('an EV trip shows the EV card with kWh and no fuel row anywhere', (tester) async {
    await pump(tester, response(evKm: 20, evKwh: 3.0, energyPerKm: 0.15, electricCost: 0.6, hasFuelData: true));

    expect(evCard, findsOneWidget);
    expect(hevCard, findsNothing);
    expect(find.text('3.0 kWh'), findsWidgets);
    expect(find.text('Fuel Used'), findsNothing, reason: 'an EV trip must not show a fuel row, even on a PHEV');
    expect(find.text('Fuel Cost'), findsNothing);
  });

  /// Regression: today a PHEV trip shows kWh and both costs. HEV driving shows litres only.
  testWidgets('an HEV trip shows the HEV card and not one kWh anywhere on the screen', (tester) async {
    await pump(tester, response(hevKm: 20, hevLitres: 1.2, fuelCost: 2.16, hasFuelData: true));

    expect(hevCard, findsOneWidget);
    expect(evCard, findsNothing);
    expect(find.text('1.2 L'), findsOneWidget);
    expect(find.textContaining('kWh'), findsNothing);
    expect(find.text('Electric Cost'), findsNothing);
  });

  testWidgets('a mixed trip shows both cards, each with only its own figures', (tester) async {
    await pump(
      tester,
      response(evKm: 10, evKwh: 1.5, hevKm: 20, hevLitres: 1.2, energyPerKm: 0.15, electricCost: 0.3, fuelCost: 2.16),
    );

    expect(evCard, findsOneWidget);
    expect(hevCard, findsOneWidget);
    expect(find.descendant(of: evCard, matching: find.textContaining(' L')), findsNothing);
    expect(find.descendant(of: evCard, matching: find.text('1.5 kWh')), findsOneWidget);
    expect(find.descendant(of: hevCard, matching: find.textContaining('kWh')), findsNothing);
    expect(find.descendant(of: hevCard, matching: find.text('1.2 L')), findsOneWidget);
    expect(find.descendant(of: evCard, matching: find.text('\$0.30')), findsOneWidget);
    expect(find.descendant(of: hevCard, matching: find.text('\$2.16')), findsOneWidget);
    expect(find.descendant(of: evCard, matching: find.text('15.0 kWh')), findsOneWidget, reason: '1.5 kWh over 10 km');
    expect(find.descendant(of: hevCard, matching: find.text('6.0 L')), findsOneWidget, reason: '1.2 L over 20 km');
  });

  testWidgets('the summary energy cell is the EV kWh, not energy per km times the whole distance', (tester) async {
    await pump(
      tester,
      response(evKm: 10, evKwh: 1.5, hevKm: 20, hevLitres: 1.2, energyPerKm: 0.15, electricCost: 0.3, fuelCost: 2.16),
    );

    final summary = find.byKey(const ValueKey('tripDetail.summaryCard'));
    expect(find.descendant(of: summary, matching: find.text('1.5 kWh')), findsOneWidget);
    expect(find.descendant(of: summary, matching: find.text('4.5 kWh')), findsNothing);
  });

  testWidgets('miles: distances and the per-100 labels follow the unit', (tester) async {
    await pump(
      tester,
      response(evKm: 16.0934, evKwh: 2.0, hevKm: 32.1869, hevLitres: 2.0, energyPerKm: 0.124, electricCost: 0.4, fuelCost: 3.6),
      unit: 'mi',
    );

    expect(find.descendant(of: evCard, matching: find.text('10.0 mi')), findsOneWidget);
    expect(find.descendant(of: hevCard, matching: find.text('20.0 mi')), findsOneWidget);
    expect(find.descendant(of: evCard, matching: find.text('kWh / 100 mi')), findsOneWidget);
    expect(find.descendant(of: hevCard, matching: find.text('L / 100 mi')), findsOneWidget);
    expect(find.text('kWh / 100 km'), findsNothing);
  });

  testWidgets('a trip recorded before the split shows no mode cards and its old fuel rows', (tester) async {
    await pump(
      tester,
      response(split: false, hasFuelData: true, hevLitres: 1.25, fuelCost: 1.5, electricCost: 2.0, evKm: 0, hevKm: 0)
        ..['trip']['summary']['distanceKm'] = 20.0,
    );

    expect(evCard, findsNothing);
    expect(hevCard, findsNothing);
    expect(find.text('Fuel Used'), findsOneWidget);
    expect(find.text('Fuel Cost'), findsOneWidget);
  });
}
