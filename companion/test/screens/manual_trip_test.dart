import 'dart:convert';
import 'dart:io';

import 'package:bladewatch_companion/screens/dashboard/dashboard_screen.dart';
import 'package:bladewatch_companion/screens/trips/trips_screen.dart';
import 'package:bladewatch_companion/transport/transport_selector.dart';
import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support.dart';

/// BladeWatch-gklt.7: the companion shows a manual trip read-only, and marks manual trips in the
/// trip list. The Start Trip / Stop Trip control is the in-car dashboard's alone.
void main() {
  hudTestEnvironment();

  void baseStatus(TestSession s) => s.rpc.stubJson('SystemService', 'GetStatus', {
        'vehicleDataReady': true,
        'acc': true,
        'recordingStatus': {'isRecording': false, 'pipelineRunning': true},
      });

  void stubWeek(TestSession s) => s.rpc.stubJson('TripsService', 'ListTrips', {'trips': []});

  Map<String, dynamic> active({bool manual = true, bool open = true, int startMs = 1700000000000}) => {
        'status': {'active': open, 'manual': manual, 'startTimeMs': '$startMs'},
      };

  final manualRow = find.byKey(const ValueKey('dash.manualTrip'));

  group('dashboard', () {
    testWidgets('a manual trip shows when it started and how long it has run', (tester) async {
      final s = TestSession(phase: TransportPhase.pear);
      baseStatus(s);
      stubWeek(s);
      final start = DateTime.now().millisecondsSinceEpoch - const Duration(hours: 2, minutes: 5).inMilliseconds;
      s.rpc.stubJson('TripsService', 'GetActiveTrip', active(startMs: start));
      await pumpScreen(tester, s, const DashboardScreen());
      await tester.pump();

      expect(manualRow, findsOneWidget);
      expect(find.text(t('companion.manual_trip_started')), findsOneWidget);
      expect(find.text(t('companion.manual_trip_elapsed')), findsOneWidget);
      expect(find.textContaining('2h 5m'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('there is no start or stop control anywhere on the dashboard', (tester) async {
      final s = TestSession(phase: TransportPhase.pear);
      baseStatus(s);
      stubWeek(s);
      s.rpc.stubJson('TripsService', 'GetActiveTrip', active(startMs: DateTime.now().millisecondsSinceEpoch));
      await pumpScreen(tester, s, const DashboardScreen());
      await tester.pump();

      expect(manualRow, findsOneWidget);
      expect(find.descendant(of: manualRow, matching: find.byType(ButtonStyleButton)), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.textContaining(RegExp('start trip|stop trip', caseSensitive: false)), findsNothing);
      await unmount(tester);
    });

    testWidgets('no row without a manual trip: none open, an auto trip, or a failed read', (tester) async {
      for (final stub in <void Function(TestSession)?>[
        (s) => s.rpc.stubJson('TripsService', 'GetActiveTrip', active(open: false, manual: false)),
        (s) => s.rpc.stubJson('TripsService', 'GetActiveTrip', active(manual: false)),
        (s) => s.rpc.stubError('TripsService', 'GetActiveTrip', const ConnectError('unavailable', 'down')),
        null, // GetActiveTrip not stubbed at all: an older car without the call
      ]) {
        final s = TestSession(phase: TransportPhase.pear);
        baseStatus(s);
        stubWeek(s);
        stub?.call(s);
        await pumpScreen(tester, s, const DashboardScreen());
        await tester.pump();

        expect(manualRow, findsNothing);
        await unmount(tester);
      }
    });
  });

  group('trip list', () {
    testWidgets('a manual trip carries a Manual badge and an auto trip does not', (tester) async {
      final s = TestSession();
      s.rpc.stubJson('TripsService', 'ListTrips', {
        'trips': [
          {'id': '7', 'startTime': '1700000000000', 'distanceKm': 12.0, 'durationSeconds': 900, 'overallScore': 88, 'manual': true},
          {'id': '8', 'startTime': '1699990000000', 'distanceKm': 5.0, 'durationSeconds': 400, 'overallScore': 55},
          {'id': '9', 'startTime': '1699980000000', 'distanceKm': 2.0, 'durationSeconds': 100, 'manual': true},
        ],
      });
      s.rpc.stubJson('TripsService', 'GetSummary', {'summary': []});
      s.rpc.stubJson('TripsService', 'GetConfig', {'config': {}});
      await pumpScreen(tester, s, const TripsScreen(), size: const Size(1200, 1600));

      expect(find.byKey(const ValueKey('trip.7.manual')), findsOneWidget);
      expect(find.byKey(const ValueKey('trip.9.manual')), findsOneWidget, reason: 'also without a score');
      expect(find.byKey(const ValueKey('trip.8.manual')), findsNothing);
      expect(find.text(t('companion.trip_manual_badge').toUpperCase()), findsNWidgets(2));
      await unmount(tester);
    });
  });

  group('alert category', () {
    test('the manual trip reminder category has a translated label in every language', () async {
      // The alert settings screen shows the car's English label for a category it has no
      // companion.cat_<id> key for, so a new category needs one in every language.
      final dir = Directory('assets/i18n');
      expect(dir.existsSync(), isTrue);
      final english = (jsonDecode(File('assets/i18n/en.json').readAsStringSync()) as Map)['companion'] as Map;
      expect(english['cat_trips_manual_reminder'], 'Manual trip still recording');
      var languages = 0;
      for (final f in dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json'))) {
        languages++;
        final c = (jsonDecode(f.readAsStringSync()) as Map)['companion'] as Map;
        expect(c['cat_trips_manual_reminder'], isA<String>(), reason: f.path);
        if (!f.path.endsWith('/en.json')) {
          expect(c['cat_trips_manual_reminder'], isNot(english['cat_trips_manual_reminder']), reason: '${f.path} left in English');
        }
      }
      expect(languages, 17);
    });
  });
}

