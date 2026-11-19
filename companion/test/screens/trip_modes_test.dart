import 'package:bladewatch_companion/screens/trips/trips_screen.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support.dart';

/// BladeWatch-reml.4: the companion's trip detail shows EV and HEV driving separately. EV driving
/// carries kWh and the electricity cost, HEV driving carries litres and the fuel cost, and HEV
/// driving shows no kWh anywhere.
void main() {
  hudTestEnvironment();

  Map<String, dynamic> trip({
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
    'trip': {
      'summary': {
        'id': '7',
        'startTime': '1700000000000',
        'distanceKm': evKm + hevKm,
        'durationSeconds': 1200,
        'energyPerKm': energyPerKm,
        'tripCost': electricCost + fuelCost,
        'currency': 'USD',
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
    },
  };

  Future<void> open(WidgetTester tester, Map<String, dynamic> t, {String unit = 'km'}) async {
    final s = TestSession();
    s.rpc.stubJson('TripsService', 'GetGpsTrace', {'gps': []});
    s.rpc.stubJson('TripsService', 'GetConfig', {'config': {'distanceUnit': unit}});
    s.rpc.stubJson('TripsService', 'GetTrip', t);
    await pumpScreen(tester, s, TripDetailScreen(id: Int64(7)), size: const Size(1200, 2000));
    await tester.pumpAndSettle();
  }

  final ev = find.byKey(const ValueKey('trip.evSection'));
  final hev = find.byKey(const ValueKey('trip.hevSection'));
  const nb = ' ';

  testWidgets('an EV trip shows the EV section with kWh and no fuel row', (tester) async {
    await open(tester, trip(evKm: 20, evKwh: 3.0, energyPerKm: 0.15, electricCost: 0.6, hasFuelData: true));

    expect(ev, findsOneWidget);
    expect(hev, findsNothing);
    expect(find.text('3.0${nb}kWh'), findsWidgets);
    expect(find.text(t('trips.fuel_used')), findsNothing, reason: 'an EV trip must show no fuel row, even on a PHEV');
    expect(find.text(t('trips.fuel_cost')), findsNothing);
    await unmount(tester);
  });

  testWidgets('an HEV trip shows the HEV section and not one kWh anywhere', (tester) async {
    await open(tester, trip(hevKm: 20, hevLitres: 1.2, fuelCost: 2.16, hasFuelData: true));

    expect(hev, findsOneWidget);
    expect(ev, findsNothing);
    expect(find.text('1.2 ${t('trips.litres_short')}'), findsOneWidget);
    expect(find.textContaining('kWh'), findsNothing);
    expect(find.text(t('trips.electric_cost')), findsNothing);
    await unmount(tester);
  });

  testWidgets('a mixed trip shows both sections, each with only its own figures', (tester) async {
    await open(tester, trip(evKm: 10, evKwh: 1.5, hevKm: 20, hevLitres: 1.2, energyPerKm: 0.15, electricCost: 0.3, fuelCost: 2.16));

    expect(ev, findsOneWidget);
    expect(hev, findsOneWidget);
    expect(find.descendant(of: ev, matching: find.text('1.5${nb}kWh')), findsOneWidget);
    expect(find.descendant(of: ev, matching: find.text('15.0')), findsOneWidget, reason: '1.5 kWh over 10 km');
    expect(find.descendant(of: hev, matching: find.textContaining('kWh')), findsNothing);
    expect(find.descendant(of: hev, matching: find.text('1.2 ${t('trips.litres_short')}')), findsOneWidget);
    expect(find.descendant(of: hev, matching: find.text('6.0')), findsOneWidget, reason: '1.2 L over 20 km');
    expect(find.descendant(of: ev, matching: find.text('\$0.30')), findsOneWidget);
    expect(find.descendant(of: hev, matching: find.text('\$2.16')), findsOneWidget);
    // The summary's energy row is the EV kWh, not energyPerKm x the whole 30 km (4.5).
    expect(find.text('4.5${nb}kWh'), findsNothing);
    await unmount(tester);
  });

  testWidgets('miles: distances and the per-100 labels follow the unit', (tester) async {
    await open(
      tester,
      trip(evKm: 16.09344, evKwh: 2.0, hevKm: 32.18688, hevLitres: 2.0, energyPerKm: 0.124, electricCost: 0.4, fuelCost: 3.6),
      unit: 'mi',
    );

    expect(find.descendant(of: ev, matching: find.text('10.0${nb}mi')), findsOneWidget);
    expect(find.descendant(of: hev, matching: find.text('20.0${nb}mi')), findsOneWidget);
    expect(find.descendant(of: ev, matching: find.text(t('companion.trip_kwh_per_100', {'unit': 'mi'}))), findsOneWidget);
    expect(find.descendant(of: hev, matching: find.text(t('companion.trip_l_per_100', {'unit': 'mi'}))), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a trip recorded before the split shows no mode sections and its old fuel rows', (tester) async {
    await open(tester, trip(split: false, hasFuelData: true, hevLitres: 1.25, fuelCost: 1.5, electricCost: 2.0));

    expect(ev, findsNothing);
    expect(hev, findsNothing);
    expect(find.text(t('trips.fuel_used')), findsOneWidget);
    expect(find.text(t('trips.fuel_cost')), findsOneWidget);
    await unmount(tester);
  });
}
