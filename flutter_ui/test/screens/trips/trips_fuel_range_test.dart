import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/rpc/services/trips_service_client.dart';
import 'package:bladewatch_ui/screens/trips/trip_detail_controller.dart';
import 'package:bladewatch_ui/screens/trips/trips_controller.dart';
import 'package:bladewatch_ui/screens/trips/trips_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_rpc_client.dart';

/// BladeWatch-3zno: the PHEV fuel range on the Trips range card.
///
/// Reported SEPARATELY from the electric range and never summed into it — the two are drawn
/// from different tanks with different confidence, and one combined number would hide which
/// is about to run out.
///
/// The case that matters most is the hidden one. The daemon returns -1
/// (`FuelConsumption.CANNOT_PREDICT`) when the owner has not configured a tank capacity,
/// because BYD local data exposes no tank size. Rendering that as "-1 km" — or inventing a
/// capacity to avoid it — puts a wrong range on a dashboard the driver acts on.
void main() {
  late FakeRpcClient rpc;
  late FakeRpcClient longRpc;
  late TripsController controller;

  void stubRange(String rangeJson) {
    rpc.stubJson('TripsService', 'ListTrips', {'success': true, 'trips': []});
    rpc.stubJson('TripsService', 'GetSummary', {'success': true, 'summary': []});
    rpc.stubJson('TripsService', 'GetDna', {'success': true, 'dna': null});
    rpc.stubJson('TripsService', 'GetRange', {'success': true, 'rangeJson': rangeJson});
    rpc.stubJson('TripsService', 'GetConfig', {'success': true, 'config': null});
    rpc.stubJson('TripsService', 'GetStorage', {'success': true, 'storage': null});
  }

  setUp(() {
    rpc = FakeRpcClient();
    longRpc = FakeRpcClient();
    controller = TripsController(
      tripsService: TripsServiceClient(rpc),
      longTripsService: TripsServiceClient(longRpc),
    );
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TripsScreen(
          controller: controller,
          detailControllerFactory: () =>
              TripDetailController(tripsService: TripsServiceClient(rpc)),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    // The range card lives on the Stats tab, not the trip list.
    await tester.tap(find.byKey(const ValueKey('trips.tab.stats')));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the fuel range alongside the electric one on a PHEV', (tester) async {
    stubRange('{"predictedRangeKm": 210, "builtInRangeKm": 205, '
        '"fuelRangeKm": 480, "builtInFuelRangeKm": 460}');
    await pumpScreen(tester);

    expect(find.byKey(const ValueKey('trips.rangeCard')), findsOneWidget);
    expect(find.textContaining('Fuel range'), findsOneWidget);
    expect(find.textContaining('480'), findsOneWidget);
    // The electric figure is untouched and still the headline.
    expect(find.textContaining('210'), findsOneWidget);
  });

  testWidgets('shows no fuel range on a BEV', (tester) async {
    stubRange('{"predictedRangeKm": 210, "builtInRangeKm": 205}');
    await pumpScreen(tester);

    expect(find.byKey(const ValueKey('trips.rangeCard')), findsOneWidget);
    expect(find.textContaining('Fuel range'), findsNothing);
  });

  /// THE guard: an unconfigured tank capacity yields the daemon's -1 sentinel. It must be
  /// hidden, never rendered — a "-1 km" range reads as a fault, and a guessed one is worse.
  testWidgets('hides the fuel range when the daemon cannot predict it', (tester) async {
    stubRange('{"predictedRangeKm": 210, "builtInRangeKm": 205, "fuelRangeKm": -1}');
    await pumpScreen(tester);

    expect(find.textContaining('Fuel range'), findsNothing);
    expect(find.textContaining('-1'), findsNothing);
  });

  /// A PHEV can learn a fuel rate before it has enough electric samples. The fuel figure must
  /// still show rather than the card collapsing to "not enough data".
  testWidgets('shows the fuel range even with no electric estimate yet', (tester) async {
    stubRange('{"predictedRangeKm": 0, "builtInRangeKm": 0, "fuelRangeKm": 480}');
    await pumpScreen(tester);

    expect(find.textContaining('Fuel range'), findsOneWidget);
    expect(find.textContaining('480'), findsOneWidget);
  });
}
