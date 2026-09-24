import 'package:bladewatch_companion/screens/surveillance/surveillance_screen.dart';
import 'package:bladewatch_companion/screens/trips/trips_screen.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/safe_locations.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/surveillance.pb.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/trips.pb.dart';
import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support.dart';

void main() {
  group('trips', () {
    test('PeriodSummary sums the rollups and skips unreadable ones', () {
      expect(PeriodSummary.of([]), isNull);
      final s = PeriodSummary.of([
        WeeklyRollupEntry(rollupJson: '{"tripCount":2,"totalDistanceKm":10.5,"totalDurationSeconds":600,"totalEnergyKwh":2,"avgEfficiency":80}'),
        WeeklyRollupEntry(rollupJson: 'nope'),
        WeeklyRollupEntry(rollupJson: '{"tripCount":1,"avgEfficiency":60}'),
      ])!;
      expect((s.trips, s.km, s.seconds, s.kwh, s.efficiency), (3, 10.5, 600, 2.0, 70.0));
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

    testWidgets('the list with its period, a trip\'s route and scores, and delete', (tester) async {
      final s = TestSession();
      stubAll(s);
      await pumpScreen(tester, s, const TripsScreen(), size: const Size(1200, 1600));
      expect(find.text(t('trips.period_summary')), findsOneWidget);
      expect(find.text('88'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('trips.days.30')));
      await tester.pumpAndSettle();
      expect((s.rpc.calls.lastWhere((c) => c.method == 'ListTrips').request as ListTripsRequest).days, 30);

      await tester.tap(find.byKey(const ValueKey('trip.7')));
      await tester.pumpAndSettle();
      expect(find.text(t('trips.trip_summary')), findsOneWidget);
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
      expect(find.text(t('trips.period_summary')), findsOneWidget, reason: 'back on the list, reloaded');
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
      expect(find.text(t('trips.no_trips_recorded')), findsOneWidget);
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
