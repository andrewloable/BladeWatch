import 'package:bladewatch_companion/screens/surveillance/surveillance_screen.dart';
import 'package:bladewatch_companion/screens/trips/trips_screen.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/safe_locations.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/surveillance.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/trips.pb.dart';
import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';
import 'package:fixnum/fixnum.dart';
import 'package:bladewatch_theme/hud_theme.dart';
import 'package:bladewatch_theme/hud_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support.dart';

void main() {
  hudTestEnvironment();

  group('trips', () {
    test('PeriodSummary sums the rollups and skips unreadable ones', () {
      expect(PeriodSummary.of([]), isNull);
      expect(PeriodSummary.of([WeeklyRollupEntry(rollupJson: 'nope')]), isNull);
      // BladeWatch-rdtj.41: the score, not the legacy avgEfficiency (1 here, as on the car), and
      // divided by every entry like the in-car page: (81 + 60) / 3.
      final s = PeriodSummary.of([
        WeeklyRollupEntry(
            rollupJson: '{"tripCount":2,"totalDistanceKm":10.5,"totalDurationSeconds":600,"totalEnergyKwh":2,"avgEfficiency":1,"avgEfficiencyScore":81}'),
        WeeklyRollupEntry(rollupJson: 'nope'),
        WeeklyRollupEntry(rollupJson: '{"tripCount":1,"avgEfficiency":1,"avgEfficiencyScore":60}'),
      ])!;
      expect((s.trips, s.km, s.seconds, s.kwh, s.efficiency), (3, 10.5, 600, 2.0, 47.0));
    });

    test('parseRange takes the learned, built-in and fuel range, nested or flat', () {
      expect(parseRange(''), isNull);
      expect(parseRange('x'), isNull);
      expect(parseRange('{"predictedRangeKm":-1}'), isNull, reason: '-1 is "cannot predict"');
      final r = parseRange('{"range":{"predictedRangeKm":310,"builtInRangeKm":300,"fuelRangeKm":500}}')!;
      expect((r.estimated, r.builtIn, r.fuel), (310.0, 300.0, 500.0));
    });

    void stubAll(TestSession s) {
      s.rpc.stubJson('TripsService', 'ListTrips', {
        'trips': [
          {'id': '7', 'startTime': '1700000000000', 'distanceKm': 12.0, 'durationSeconds': 900, 'overallScore': 88},
        ],
      });
      s.rpc.stubJson('TripsService', 'GetSummary', {
        'summary': [{'rollupJson': '{"tripCount":1,"totalDistanceKm":12,"totalDurationSeconds":900}'}],
      });
      s.rpc.stubJson('TripsService', 'GetTrip', {
        'trip': {
          'summary': {'id': '7', 'startTime': '1700000000000', 'distanceKm': 12.0, 'overallScore': 88, 'tripCost': 1.5, 'currency': 'PHP', 'hasFuelData': true, 'litresUsed': 0.4},
          'elevationGainM': 20.0,
          'anticipationScore': 90,
        },
      });
      s.rpc.stubJson('TripsService', 'GetGpsTrace', {
        'gps': [
          {'lat': 14.5, 'lon': 121.0},
          {'lat': 14.6, 'lon': 121.1},
        ],
      });
      s.rpc.stubJson('TripsService', 'DeleteTrip', {'success': true});
      s.rpc.stubJson('TripsService', 'GetRange', {'rangeJson': '{"predictedRangeKm":310,"builtInRangeKm":300,"fuelRangeKm":500}'});
      s.rpc.stubJson('TripsService', 'GetDna', {'dna': {'overall': 77, 'smoothness': 60}});
      s.rpc.stubJson('TripsService', 'GetConfig', {'config': {'enabled': true, 'electricityRate': 11.5, 'currency': 'PHP'}});
      s.rpc.stubJson('TripsService', 'GetStorage', {'storage': {'storageType': 'SD_CARD', 'limitMb': '500', 'usedMb': 12.5, 'tripsCount': 40}});
      s.rpc.stubJson('TripsService', 'SetConfig', {'success': true});
      s.rpc.stubJson('TripsService', 'SetStorage', {'success': true});
      s.rpc.stubJson('TripsService', 'SyncTrips', {'success': true, 'added': 2, 'removed': 1, 'total': 41});
    }

    testWidgets('HUD: trips are rows with a score badge in its real band, the detail has a title bar and a magenta delete', (tester) async {
      final s = TestSession();
      stubAll(s);
      s.rpc.stubJson('TripsService', 'ListTrips', {
        'trips': [
          {'id': '7', 'startTime': '1700000000000', 'distanceKm': 12.0, 'durationSeconds': 900, 'overallScore': 88},
          {'id': '8', 'startTime': '1699990000000', 'distanceKm': 5.0, 'durationSeconds': 400, 'overallScore': 55},
          {'id': '9', 'startTime': '1699980000000', 'distanceKm': 2.0, 'durationSeconds': 100, 'overallScore': 20},
        ],
      });
      await pumpScreen(tester, s, const TripsScreen(), size: const Size(1200, 1600));
      const hud = BwHud.light;
      Color band(String id) => tester
          .widget<HudPanel>(find.descendant(of: find.byKey(ValueKey('trip.$id')), matching: find.byType(HudPanel)).last)
          .borderColor;
      expect(band('7'), hud.accent);
      expect(band('8'), hud.warning);
      expect(band('9'), hud.magenta);
      expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('trips.days.7'))).showCheckmark, isFalse);

      await tester.tap(find.byKey(const ValueKey('trip.7')));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byType(HudTitleBar), matching: find.text(t('trips.trip_summary').toUpperCase())), findsOneWidget);
      expect(tester.widget<IconButton>(find.byKey(const ValueKey('trip.delete'))).color, hud.magenta);
      expect(find.byKey(const ValueKey('hud.back')), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('the list with its period, a trip\'s route and scores, and delete', (tester) async {
      final s = TestSession();
      stubAll(s);
      await pumpScreen(tester, s, const TripsScreen(), size: const Size(1200, 1600));
      expect(find.text(t('trips.period_summary').toUpperCase()), findsOneWidget, reason: 'a section title is an upper-case label');
      expect(find.text('88'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('trips.days.30')));
      await tester.pumpAndSettle();
      expect((s.rpc.calls.lastWhere((c) => c.method == 'ListTrips').request as ListTripsRequest).days, 30);

      await tester.tap(find.byKey(const ValueKey('trip.7')));
      await tester.pumpAndSettle();
      expect(find.text(t('trips.trip_summary').toUpperCase()), findsOneWidget);
      expect(find.text('1.50 PHP'), findsOneWidget);
      expect(find.text('+20 m'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('trip.delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t('common.cancel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('trip.delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('trip.delete.confirm')));
      await tester.pumpAndSettle();
      expect((s.rpc.calls.lastWhere((c) => c.method == 'DeleteTrip').request as DeleteTripRequest).id.toInt(), 7);
      expect(find.text(t('trips.period_summary').toUpperCase()), findsOneWidget, reason: 'back on the list, reloaded');
      await unmount(tester);
    });

    testWidgets('a trip without a route says so; an empty list says so', (tester) async {
      final s = TestSession();
      stubAll(s);
      s.rpc.stubJson('TripsService', 'GetGpsTrace', {'gps': []});
      s.rpc.stubJson('TripsService', 'GetTrip', {'trip': {'summary': {'id': '7'}}});
      await pumpScreen(tester, s, TripDetailScreen(id: Int64(7)), size: const Size(1200, 1600));
      expect(find.text(t('trips.no_route_data')), findsOneWidget);

      s.rpc.stubJson('TripsService', 'ListTrips', {'trips': []});
      s.rpc.stubJson('TripsService', 'GetSummary', {'summary': []});
      await unmount(tester);
      await pumpScreen(tester, s, const TripsScreen());
      expect(find.text(t('trips.no_trips_recorded').toUpperCase()), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('stats: learned range and driving DNA, or "not enough data"', (tester) async {
      final s = TestSession();
      stubAll(s);
      await pumpScreen(tester, s, const TripsScreen(), size: const Size(1200, 1600));
      await tester.tap(find.text(t('trips.tab_stats')));
      await tester.pumpAndSettle();
      expect(find.text('310 km'), findsOneWidget);
      expect(find.text('77'), findsOneWidget);

      s.rpc.stubJson('TripsService', 'GetRange', {'message': 'Learning'});
      s.rpc.stubJson('TripsService', 'GetDna', {});
      await unmount(tester);
      await pumpScreen(tester, s, const TripsScreen(), size: const Size(1200, 1600));
      await tester.tap(find.text(t('trips.tab_stats')));
      await tester.pumpAndSettle();
      expect(find.text('Learning'), findsOneWidget);
      expect(find.text(t('trips.no_dna_data')), findsOneWidget);
      await unmount(tester);
    });

    // BladeWatch-rdtj.48: PHEV pricing, as the web offers it, and the trip's cost halves.
    testWidgets('fuel price and tank: shown on a PHEV or when set, saved with presence', (tester) async {
      final s = TestSession();
      stubAll(s);
      s.rpc.stubJson('TripsService', 'GetConfig', {'config': {'enabled': true, 'electricityRate': 11.5, 'currency': 'PHP', 'isPhev': true}});
      await pumpScreen(tester, s, const TripsScreen(), size: const Size(1200, 1600));
      await tester.tap(find.text(t('trips.tab_storage')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('trips.fuel_price')), '68.5');
      await tester.enterText(find.byKey(const ValueKey('trips.tank')), '52');
      await tester.tap(find.byKey(const ValueKey('trips.apply')));
      await tester.pumpAndSettle();
      var r = s.rpc.calls.lastWhere((c) => c.method == 'SetConfig').request as SetConfigRequest;
      expect((r.fuelPricePerL, r.hasFuelPricePerL_8, r.fuelTankCapacityL, r.hasFuelTankCapacityL_10), (68.5, true, 52.0, true));
      await unmount(tester);

      // A BEV with nothing set: no tank to ask about, and nothing sent for one.
      final bev = TestSession();
      stubAll(bev);
      await pumpScreen(tester, bev, const TripsScreen(), size: const Size(1200, 1600));
      await tester.tap(find.text(t('trips.tab_storage')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('trips.fuel_price')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('trips.apply')));
      await tester.pumpAndSettle();
      r = bev.rpc.calls.lastWhere((c) => c.method == 'SetConfig').request as SetConfigRequest;
      expect((r.hasFuelPricePerL_8, r.hasFuelTankCapacityL_10), (false, false));
      await unmount(tester);

      // Set once, the probe reading "no tank" (warming up): still there, and 0 clears it.
      final warming = TestSession();
      stubAll(warming);
      warming.rpc.stubJson('TripsService', 'GetConfig', {'config': {'currency': 'PHP', 'fuelPricePerL': 70.0}});
      await pumpScreen(tester, warming, const TripsScreen(), size: const Size(1200, 1600));
      await tester.tap(find.text(t('trips.tab_storage')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('trips.fuel_price')), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('trips.fuel_price')), '0');
      await tester.tap(find.byKey(const ValueKey('trips.apply')));
      await tester.pumpAndSettle();
      r = warming.rpc.calls.lastWhere((c) => c.method == 'SetConfig').request as SetConfigRequest;
      expect((r.fuelPricePerL, r.hasFuelPricePerL_8), (0.0, true));
      await unmount(tester);
    });

    testWidgets('a trip shows its fuel and electric halves and the outside temperature', (tester) async {
      final s = TestSession();
      stubAll(s);
      s.rpc.stubJson('TripsService', 'GetTrip', {
        'trip': {
          'summary': {
            'id': '7', 'startTime': '1700000000000', 'tripCost': 9.75, 'currency': 'PHP',
            'hasFuelData': true, 'litresUsed': 0.5, 'fuelCost': 7.25, 'electricCost': 2.5, 'extTempC': 31,
          },
        },
      });
      await pumpScreen(tester, s, TripDetailScreen(id: Int64(7)), size: const Size(1200, 1600));
      expect(find.text('9.75 PHP'), findsOneWidget);
      expect(find.text('7.25 PHP'), findsOneWidget);
      expect(find.text('2.50 PHP'), findsOneWidget);
      expect(find.text('31 °C'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('storage: analytics toggle, rate, currency, limit, and sync', (tester) async {
      final s = TestSession();
      stubAll(s);
      await pumpScreen(tester, s, const TripsScreen(), size: const Size(1200, 1600));
      await tester.tap(find.text(t('trips.tab_storage')));
      await tester.pumpAndSettle();
      expect(find.text(t('trips.sd_card')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('trips.enabled')));
      await tester.pumpAndSettle();
      final off = s.rpc.calls.lastWhere((c) => c.method == 'SetConfig').request as SetConfigRequest;
      expect((off.enabled, off.hasEnabled_2), (false, true));

      await tester.enterText(find.byKey(const ValueKey('trips.rate')), '12.25');
      await tester.enterText(find.byKey(const ValueKey('trips.limit')), '800');
      await tester.tap(find.byKey(const ValueKey('trips.apply')));
      await tester.pumpAndSettle();
      final cfg = s.rpc.calls.lastWhere((c) => c.method == 'SetConfig').request as SetConfigRequest;
      expect((cfg.electricityRate, cfg.hasElectricityRate_4, cfg.currency), (12.25, true, 'PHP'));
      expect((s.rpc.calls.lastWhere((c) => c.method == 'SetStorage').request as SetStorageRequest).storageLimitMb.toInt(), 800);

      await tester.tap(find.byKey(const ValueKey('trips.sync')));
      await tester.pumpAndSettle();
      expect(find.text('+2 / -1 · 41'), findsOneWidget);
      await unmount(tester);
    });

    // BladeWatch-gzbo: the currency is PICKED from a list of symbols (it used to be a typed text box), and
    // what the car stored is only replaced when the owner actually picks.
    group('currency picker', () {
      Future<TestSession> pumpStorage(WidgetTester tester, String? currency) async {
        final s = TestSession();
        stubAll(s);
        s.rpc.stubJson('TripsService', 'GetConfig', {
          'config': {'enabled': true, 'electricityRate': 11.5, 'currency': ?currency},
        });
        await pumpScreen(tester, s, const TripsScreen(), size: const Size(1200, 1600));
        await tester.tap(find.text(t('trips.tab_storage')));
        await tester.pumpAndSettle();
        return s;
      }

      DropdownButtonFormField<String> picker(WidgetTester tester) =>
          tester.widget<DropdownButtonFormField<String>>(find.byKey(const ValueKey('trips.currency')));
      List<String> menu(WidgetTester tester) => tester
          .widget<DropdownButton<String>>(
              find.descendant(of: find.byKey(const ValueKey('trips.currency')), matching: find.byType(DropdownButton<String>)))
          .items!
          .map((i) => i.value!)
          .toList();
      Future<String> apply(WidgetTester tester, TestSession s) async {
        await tester.tap(find.byKey(const ValueKey('trips.apply')));
        await tester.pumpAndSettle();
        return (s.rpc.calls.lastWhere((c) => c.method == 'SetConfig').request as SetConfigRequest).currency;
      }

      testWidgets('is a dropdown of 80 symbols: no ISO code, no duplicate, no free text', (tester) async {
        await pumpStorage(tester, 'PHP');
        expect(find.byType(TextField).evaluate().where((e) => (e.widget as TextField).decoration?.labelText == t('trips.currency')), isEmpty);
        final items = menu(tester);
        expect(items, hasLength(80));
        expect(items.toSet(), hasLength(80));
        for (final v in items) {
          expect(RegExp(r'^[A-Za-z]{3}$').hasMatch(v), isFalse, reason: '"$v" is code-shaped');
        }
        await unmount(tester);
      });

      testWidgets('a stored ISO code shows its symbol and a bare Apply leaves it alone', (tester) async {
        final s = await pumpStorage(tester, 'PHP');
        expect(picker(tester).initialValue, '\u20B1');
        expect(await apply(tester, s), 'PHP');
        await unmount(tester);
      });

      testWidgets('picking a symbol sends it', (tester) async {
        final s = await pumpStorage(tester, 'PHP');
        picker(tester).onChanged!('\u20AC');
        await tester.pumpAndSettle();
        expect(await apply(tester, s), '\u20AC');
        await unmount(tester);
      });

      testWidgets('a legacy value is offered once, first, and survives; a fresh car defaults to the dollar', (tester) async {
        final s = await pumpStorage(tester, 'Rs.');
        expect(menu(tester).where((v) => v == 'Rs.'), hasLength(1));
        expect(menu(tester).first, 'Rs.');
        expect(await apply(tester, s), 'Rs.');
        await unmount(tester);

        final fresh = await pumpStorage(tester, null);
        expect(picker(tester).initialValue, r'$');
        expect(await apply(tester, fresh), r'$');
        await unmount(tester);
      });

      testWidgets('a trip priced in a symbol reads symbol first; a code stays after the amount', (tester) async {
        final s = TestSession();
        stubAll(s);
        s.rpc.stubJson('TripsService', 'GetTrip', {
          'trip': {
            'summary': {'id': '7', 'startTime': '1700000000000', 'distanceKm': 12.0, 'overallScore': 88, 'tripCost': 1.5, 'currency': '\u20B1'},
          },
        });
        await pumpScreen(tester, s, const TripsScreen(), size: const Size(1200, 1600));
        await tester.tap(find.byKey(const ValueKey('trip.7')));
        await tester.pumpAndSettle();
        expect(find.text('\u20B1 1.50'), findsOneWidget);
        await unmount(tester);
      });
    });
  });

  group('SurveillanceScreen', () {
    void stubAll(TestSession s, {bool active = true}) {
      s.rpc.stubJson('SurveillanceService', 'GetStatus', {'surveillanceActive': active, 'pipelineRunning': active});
      s.rpc.stubJson('SurveillanceService', 'GetConfig', {
        'config': {
          'sensitivity': 3,
          'distancePreset': 'BALANCED',
          'detectPerson': true,
          'cameraFront': true,
          'cameraRight': true,
          'cameraRear': true,
          'cameraLeft': true,
          'deterrentAction': 'FLASH',
        },
      });
      s.rpc.stubJson('SafeLocationsService', 'ListZones', {
        'zones': [
          {'id': 'z1', 'name': 'Home', 'radiusM': 100, 'enabled': true},
          {'id': 'z2', 'name': 'Work', 'radiusM': 50},
        ],
        'featureEnabled': true,
        'inSafeZone': true,
      });
      s.rpc.stubJson('SurveillanceService', 'SetConfig', {'success': true});
      s.rpc.stubJson('SurveillanceService', 'Enable', {'success': true});
      s.rpc.stubJson('SurveillanceService', 'Disable', {'success': true});
      s.rpc.stubJson('SafeLocationsService', 'Toggle', {'success': true});
      s.rpc.stubJson('SafeLocationsService', 'DeleteZone', {'success': true});
      s.rpc.stubJson('SurveillanceService', 'GetSnapshot', {'imageJpeg': base64Png});
    }

    testWidgets('HUD: a snapshot is in a 4 dp frame, zone delete is magenta, event-seconds choices have no check mark', (tester) async {
      final s = TestSession();
      stubAll(s);
      await pumpScreen(tester, s, const SurveillanceScreen(), size: const Size(1200, 3400));
      expect(find.descendant(of: find.byKey(const ValueKey('surv.snapshot.0')), matching: find.byType(HudPanel)), findsOneWidget);
      expect(tester.widget<IconButton>(find.byKey(const ValueKey('zone.delete.z1'))).color, BwHud.light.magenta);
      expect(tester.widget<ChoiceChip>(find.byKey(const ValueKey('surv.pre.5'))).showCheckmark, isFalse);
      await unmount(tester);
    });

    // BladeWatch-rdtj.50: the web's AI confidence and event seconds; untouched fields ride along.
    testWidgets('AI confidence and event seconds are saved; what was not touched is kept', (tester) async {
      final s = TestSession();
      stubAll(s);
      s.rpc.stubJson('SurveillanceService', 'GetConfig', {
        'config': {
          'sensitivity': 3, 'aiEnabled': true, 'aiConfidence': 0.5, 'preRecordSeconds': 5, 'postRecordSeconds': 10,
          'minObjectSize': 0.02, 'deterrentCooldownSeconds': 60, 'shadowThreshold': 0.7, 'cameraFront': true,
        },
      });
      await pumpScreen(tester, s, const SurveillanceScreen(), size: const Size(1200, 3400));
      expect(find.textContaining('(0.50)'), findsOneWidget);
      await tester.drag(find.byKey(const ValueKey('surv.aiConfidence')), const Offset(1000, 0));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('surv.pre.10')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('surv.post.30')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('surv.save')));
      await tester.pumpAndSettle();
      final sent = (s.rpc.calls.lastWhere((c) => c.method == 'SetConfig').request as SetSurveillanceConfigRequest).config;
      expect((sent.aiConfidence, sent.preRecordSeconds, sent.postRecordSeconds), (1.0, 10, 30));
      expect((sent.minObjectSize, sent.deterrentCooldownSeconds, sent.shadowThreshold, sent.cameraFront), (0.02, 60, 0.7, true),
          reason: 'fields this page does not show are sent back as they were');

      await tester.tap(find.byKey(const ValueKey('surv.ai')));
      await tester.pump();
      expect(find.byKey(const ValueKey('surv.aiConfidence')), findsNothing, reason: 'only while AI detection is on');
      await unmount(tester);
    });

    testWidgets('refresh all loads the four snapshots, one after another', (tester) async {
      final s = TestSession();
      stubAll(s);
      await pumpScreen(tester, s, const SurveillanceScreen(), size: const Size(1200, 3400));
      await tester.tap(find.byKey(const ValueKey('surv.refreshAll')));
      await tester.pumpAndSettle();
      final asked = s.rpc.calls.where((c) => c.method == 'GetSnapshot').map((c) => (c.request as GetSnapshotRequest).quadrant).toList();
      expect(asked, [0, 1, 2, 3]);
      expect(find.textContaining(t('surveillance.tap_to_load')), findsNothing, reason: 'all four loaded');
      await unmount(tester);
    });

    testWidgets('saves the WHOLE config with the edits, cameras included (q0p4)', (tester) async {
      final s = TestSession();
      stubAll(s);
      await pumpScreen(tester, s, const SurveillanceScreen(), size: const Size(1200, 3000));
      await tester.tap(find.byKey(const ValueKey('surv.night')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('surv.rear')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('surv.preset')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t('surveillance.preset_far')).last);
      await tester.pumpAndSettle();
      await tester.drag(find.byKey(const ValueKey('surv.sensitivity')), const Offset(400, 0));
      await tester.pump();
      for (final k in ['surv.ai', 'surv.car', 'surv.bike', 'surv.person', 'surv.front', 'surv.right', 'surv.left']) {
        await tester.tap(find.byKey(ValueKey(k)));
        await tester.pump();
        await tester.tap(find.byKey(ValueKey(k)));
        await tester.pump();
      }
      await tester.tap(find.byKey(const ValueKey('surv.save')));
      await tester.pumpAndSettle();

      final sent = (s.rpc.calls.lastWhere((c) => c.method == 'SetConfig').request as SetSurveillanceConfigRequest).config;
      expect((sent.cameraFront, sent.cameraRight, sent.cameraRear, sent.cameraLeft), (true, true, false, true));
      expect((sent.nightMode, sent.detectPerson, sent.distancePreset, sent.deterrentAction), (true, true, 'FAR', 'FLASH'));
      expect(sent.sensitivity, 5);
      expect(find.text(t('toast.saved')), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('arms and disarms, loads snapshots, toggles and deletes safe zones; a refused save says so', (tester) async {
      final s = TestSession();
      stubAll(s);
      await pumpScreen(tester, s, const SurveillanceScreen(), size: const Size(1200, 3000));
      expect(find.text(t('surveillance.active')), findsOneWidget);
      expect(find.text(t('status.safe')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('surv.active')));
      await tester.pumpAndSettle();
      expect(s.rpc.calls.where((c) => c.method == 'Disable'), hasLength(1));

      stubAll(s, active: false);
      await unmount(tester);
      await pumpScreen(tester, s, const SurveillanceScreen(), size: const Size(1200, 3000));
      expect(find.text(t('surveillance.inactive')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('surv.active')));
      await tester.pumpAndSettle();
      expect(s.rpc.calls.where((c) => c.method == 'Enable'), hasLength(1));

      await tester.tap(find.byKey(const ValueKey('surv.snapshot.2')));
      await tester.pumpAndSettle();
      expect((s.rpc.calls.lastWhere((c) => c.method == 'GetSnapshot').request as GetSnapshotRequest).quadrant, 2);
      s.rpc.stubError('SurveillanceService', 'GetSnapshot', const ConnectError('unavailable', 'x'));
      await tester.tap(find.byKey(const ValueKey('surv.snapshot.0')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('surv.zones')));
      await tester.pumpAndSettle();
      expect((s.rpc.calls.lastWhere((c) => c.method == 'Toggle').request as ToggleSafeLocationsRequest).enabled, isFalse);
      await tester.tap(find.byKey(const ValueKey('zone.delete.z2')));
      await tester.pumpAndSettle();
      expect((s.rpc.calls.lastWhere((c) => c.method == 'DeleteZone').request as DeleteZoneRequest).id, 'z2');

      s.rpc.stubJson('SurveillanceService', 'SetConfig', {'success': false, 'error': 'invalid'});
      await tester.tap(find.byKey(const ValueKey('surv.save')));
      await tester.pumpAndSettle();
      expect(find.text(t('errors.save_failed')), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('no safe zones says so', (tester) async {
      final s = TestSession();
      stubAll(s);
      s.rpc.stubJson('SafeLocationsService', 'ListZones', {'zones': []});
      await pumpScreen(tester, s, const SurveillanceScreen(), size: const Size(1200, 3000));
      expect(find.text(t('surveillance.no_safe_zones')), findsOneWidget);
      await unmount(tester);
    });
  });
}
