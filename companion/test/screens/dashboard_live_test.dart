import 'dart:typed_data';

import 'package:bladewatch_companion/car/media.dart';
import 'package:bladewatch_companion/screens/dashboard/dashboard_screen.dart';
import 'package:bladewatch_companion/screens/live/live_screen.dart';
import 'package:bladewatch_companion/transport/transport_selector.dart';
import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support.dart';


void status(TestSession s, {bool recording = true, bool safe = true}) => s.rpc.stubJson('SystemService', 'GetStatus', {
      'vehicleDataReady': true,
      'acc': true,
      'distanceUnit': 'mi',
      'soc': {'percent': 81.0},
      'range': {'totalRangeKm': 321.0},
      'charging': {'stateName': 'Charging'},
      'soh': {'percent': 97.5},
      'battery': {'level': '12.6 V'},
      'inSafeZone': safe,
      'safeZoneName': safe ? 'Home' : '',
      'recordingStatus': {'isRecording': recording, 'pipelineRunning': recording},
    });

void main() {
  group('DashboardScreen', () {
    testWidgets('route, recording, ACC, safe zone, battery and this week', (tester) async {
      final s = TestSession(phase: TransportPhase.pear);
      status(s);
      s.rpc.stubJson('TripsService', 'ListTrips', {
        'trips': [
          {'distanceKm': 10.0, 'durationSeconds': 600},
          {'distanceKm': 6.0, 'durationSeconds': 3000},
        ],
      });
      await pumpScreen(tester, s, const DashboardScreen());
      await tester.pump();
      expect(find.text(t('companion.route_pear')), findsOneWidget);
      expect(find.text(t('dashboard.recording')), findsOneWidget);
      expect(find.text(t('dashboard.services_up')), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('81%'), findsOneWidget);
      expect(find.text('199.5 mi'), findsOneWidget, reason: '321 km in the owner\'s miles');
      expect(find.text('12.6 V'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1h 0m'), findsOneWidget);
      expect((s.rpc.calls.firstWhere((c) => c.method == 'ListTrips').request as dynamic).days, 7);
      expect(find.text(t('trip.cost_hint')), findsOneWidget, reason: 'no rate set: say so, no zeros');
      await unmount(tester);
    });

    // BladeWatch-39d2: the week's fuel, electric and total cost.
    testWidgets('this week shows what it cost, and never sums across currencies', (tester) async {
      final s = TestSession(phase: TransportPhase.pear);
      status(s);
      s.rpc.stubJson('TripsService', 'ListTrips', {
        'trips': [
          {'distanceKm': 10.0, 'durationSeconds': 600, 'tripCost': 150.0, 'fuelCost': 100.0, 'currency': 'PHP', 'hasFuelData': true},
          {'distanceKm': 6.0, 'durationSeconds': 3000, 'tripCost': 30.0, 'currency': 'PHP'},
        ],
      });
      await pumpScreen(tester, s, const DashboardScreen(), size: const Size(420, 1600));
      await tester.pump();
      expect(find.text('100.00 PHP'), findsOneWidget);
      expect(find.text('80.00 PHP'), findsOneWidget);
      expect(find.text('180.00 PHP'), findsOneWidget);
      expect(find.text(t('companion.total_cost')), findsOneWidget);
      await unmount(tester);

      final m = TestSession(phase: TransportPhase.pear);
      status(m);
      m.rpc.stubJson('TripsService', 'ListTrips', {
        'trips': [
          {'tripCost': 10.0, 'currency': 'PHP'},
          {'tripCost': 10.0, 'currency': 'USD'},
        ],
      });
      await pumpScreen(tester, m, const DashboardScreen(), size: const Size(420, 1600));
      await tester.pump();
      expect(find.text(t('companion.costs_mixed_currency')), findsOneWidget);
      expect(find.text(t('companion.total_cost')), findsNothing);
      await unmount(tester);
    });

    testWidgets('idle, not ready, LAN route, and a week that failed to load', (tester) async {
      final s = TestSession(phase: TransportPhase.lan);
      status(s, recording: false, safe: false);
      s.rpc.stubError('TripsService', 'ListTrips', const ConnectError('unavailable', 'x'));
      await pumpScreen(tester, s, const DashboardScreen());
      expect(find.text(t('companion.route_lan')), findsOneWidget);
      expect(find.text(t('dashboard.idle')), findsOneWidget);
      expect(find.text(t('dashboard.services_partial')), findsOneWidget);
      expect(find.text('—'), findsNWidgets(3));
      await unmount(tester);
    });

    testWidgets('battery capacity: validates, saves, resets and reports a refusal', (tester) async {
      final s = TestSession();
      status(s);
      s.rpc.stubJson('TripsService', 'ListTrips', {'trips': []});
      s.rpc.stubJson('SystemService', 'GetSohStatus', {'displaySoh': 96.0, 'nominalCapacityKwh': 82.5, 'nominalSource': 'model'});
      s.rpc.stubJson('SystemService', 'SetSohNominal', {'success': true});
      await pumpScreen(tester, s, const DashboardScreen());
      await tester.tap(find.byKey(const ValueKey('dash.capacity')));
      await tester.pumpAndSettle();
      expect(find.text('82.5'), findsOneWidget, reason: 'editing starts from the current value');
      expect(find.text('96.0%'), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('capacity.input')), '500');
      await tester.tap(find.byKey(const ValueKey('capacity.save')));
      await tester.pumpAndSettle();
      expect(find.text(t('companion.capacity_range')), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('capacity.input')), '75');
      await tester.tap(find.byKey(const ValueKey('capacity.save')));
      await tester.pumpAndSettle();
      expect(find.text(t('toast.saved')), findsOneWidget);
      expect((s.rpc.calls.lastWhere((c) => c.method == 'SetSohNominal').request as dynamic).nominalKwh, 75);

      s.rpc.stubJson('SystemService', 'SetSohNominal', {'success': false, 'error': 'nope'});
      await tester.tap(find.byKey(const ValueKey('capacity.reset')));
      await tester.pumpAndSettle();
      expect(find.text('nope'), findsOneWidget);
      expect((s.rpc.calls.lastWhere((c) => c.method == 'SetSohNominal').request as dynamic).hasNominalKwh(), isFalse);

      s.rpc.stubJson('SystemService', 'SetSohNominal', {'success': false});
      await tester.tap(find.byKey(const ValueKey('capacity.reset')));
      await tester.pumpAndSettle();
      expect(find.text(t('errors.save_failed')), findsOneWidget);

      s.rpc.stubError('SystemService', 'SetSohNominal', const ConnectError('unavailable', 'x'));
      await tester.tap(find.byKey(const ValueKey('capacity.save')));
      await tester.pumpAndSettle();
      expect(find.text(t('errors.save_failed')), findsOneWidget);

      await tester.tap(find.text(t('dashboard.close')));
      await tester.pumpAndSettle();
      await unmount(tester);
    });

    testWidgets('a status that never loads offers a retry', (tester) async {
      final s = TestSession();
      s.rpc.stubError('SystemService', 'GetStatus', const ConnectError('unavailable', 'x'));
      s.rpc.stubJson('TripsService', 'ListTrips', {'trips': []});
      await pumpScreen(tester, s, const DashboardScreen());
      expect(find.text(t('errors.load_failed')), findsOneWidget);
      status(s);
      await tester.tap(find.text(t('common.retry')));
      await tester.pump();
      await tester.pump();
      expect(find.text('81%'), findsOneWidget);
      await unmount(tester);
    });
  });

  group('LiveScreen', () {
    testWidgets('turns streaming on when the car has no still yet, then shows it', (tester) async {
      final s = TestSession(phase: TransportPhase.pear);
      final answers = [MediaResponse(503, Uint8List(0)), MediaResponse(200, testPng)];
      var enabled = 0;
      await pumpScreen(tester, s, LiveScreen(fetch: (_) async => answers.length > 1 ? answers.removeAt(0) : answers.first, enable: (_) async => enabled++));
      expect(find.text(t('companion.live_starting')), findsOneWidget);
      expect(enabled, 1);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(find.byKey(const ValueKey('live.frame')), findsOneWidget);
      expect(find.textContaining(t('companion.live_note')), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('keeps the last frame through a failed fetch, and does not re-enable within 10 s', (tester) async {
      final s = TestSession(phase: TransportPhase.lan);
      var calls = 0;
      var enabled = 0;
      await pumpScreen(
        tester,
        s,
        LiveScreen(
          fetch: (_) async {
            calls++;
            if (calls == 1) return MediaResponse(200, testPng);
            if (calls == 2) throw StateError('dropped');
            return MediaResponse(503, Uint8List(0));
          },
          enable: (_) async {
            enabled++;
            throw StateError('pipeline busy');
          },
        ),
      );
      expect(find.byKey(const ValueKey('live.frame')), findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const ValueKey('live.frame')), findsOneWidget);
      expect(enabled, 1, reason: 'the first 503 turns streaming on');
      await tester.pump(const Duration(seconds: 3));
      expect(enabled, 1, reason: 'not again within 10 s');
      await unmount(tester);
    });

    testWidgets('the real fetch and enable are used by default', (tester) async {
      final s = TestSession();
      s.rpc.stubJson('StreamService', 'Enable', {'success': true});
      await pumpScreen(tester, s, const LiveScreen());
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await unmount(tester);
    });
  });
}

