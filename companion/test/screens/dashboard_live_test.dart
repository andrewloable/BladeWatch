import 'dart:async';
import 'dart:typed_data';

import 'package:bladewatch_companion/car/media.dart';
import 'package:bladewatch_companion/screens/common/loader.dart';
import 'package:bladewatch_companion/screens/dashboard/dashboard_screen.dart';
import 'package:bladewatch_companion/screens/common/shell_nav.dart';
import 'package:bladewatch_companion/screens/live/live_screen.dart';
import 'package:bladewatch_companion/transport/transport_selector.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/vehicle.pb.dart';
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
      expect(find.text('81%'), findsNWidgets(2), reason: 'SOC under Vehicle, and Battery under This week (BladeWatch-4zr7)');
      expect(find.text('199.5\u00A0mi'), findsOneWidget, reason: '321 km in the owner\'s miles');
      expect(find.text('12.6 V'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('1h 0m'), findsOneWidget);
      expect((s.rpc.calls.firstWhere((c) => c.method == 'ListTrips').request as dynamic).days, 7);
      expect(find.text(t('trip.cost_hint')), findsOneWidget, reason: 'no rate set: say so, no zeros');
      await unmount(tester);
    });

    // The owner's cadence (2026-09-27): the week reloads once a minute while the page is up.
    testWidgets('this week reloads once a minute', (tester) async {
      final s = TestSession(phase: TransportPhase.pear);
      status(s);
      s.rpc.stubJson('TripsService', 'ListTrips', {'trips': []});
      await pumpScreen(tester, s, const DashboardScreen());
      await tester.pump();
      int trips() => s.rpc.calls.where((c) => c.method == 'ListTrips').length;
      final afterOpen = trips();
      await tester.pump(const Duration(seconds: 59));
      expect(trips(), afterOpen);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(trips(), greaterThan(afterOpen));
      await unmount(tester);
    });

    // BladeWatch-4zr7: the car's charge and fuel now, in This week.
    testWidgets('this week shows battery and electric range, and fuel and its range only with a tank', (tester) async {
      Future<void> show(Map<String, Object?> range, String unit) async {
        final s = TestSession(phase: TransportPhase.pear);
        s.rpc.stubJson('SystemService', 'GetStatus', {
          'vehicleDataReady': true,
          'distanceUnit': unit,
          'soc': {'percent': 77.0},
          'range': range,
          'recordingStatus': {'isRecording': false},
        });
        s.rpc.stubJson('TripsService', 'ListTrips', {'trips': []});
        await pumpScreen(tester, s, const DashboardScreen(), size: const Size(420, 1600));
        await tester.pump();
      }

      InfoRow row(String key) => tester.widget<InfoRow>(find.widgetWithText(InfoRow, t(key)));

      await show({'elecRangeKm': 81.0, 'fuelRangeKm': 351.0, 'totalRangeKm': 432.0, 'fuelPercent': 30.0}, 'km');
      expect(row('companion.week_battery').value, '77%');
      expect(row('companion.week_elec_range').value, '81.0\u00A0km');
      expect(row('companion.week_fuel').value, '30%');
      expect(row('companion.week_fuel_range').value, '351.0\u00A0km');
      await unmount(tester);

      await show({'elecRangeKm': 300.0, 'totalRangeKm': 300.0}, 'mi');
      expect(row('companion.week_elec_range').value, '186.4\u00A0mi');
      expect(find.text(t('companion.week_fuel')), findsNothing, reason: 'a BEV: no fuel, not 0%');
      expect(find.text(t('companion.week_fuel_range')), findsNothing);
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
      s.rpc.stubJson('SystemService', 'GetSohStatus', {'displaySoh': 96.0, 'nominalCapacityKwh': 82.5, 'nominalSource': 'model', 'displaySource': 'bms'});
      s.rpc.stubJson('SystemService', 'SetSohNominal', {'success': true});
      await pumpScreen(tester, s, const DashboardScreen());
      await tester.tap(find.byKey(const ValueKey('dash.capacity')));
      await tester.pumpAndSettle();
      expect(find.text('82.5'), findsOneWidget, reason: 'editing starts from the current value');
      expect(find.text('96.0%'), findsOneWidget);
      // BladeWatch-rdtj.57: the web dialog's capacity in use and where the health figure came from.
      expect(find.text('82.5 kWh'), findsOneWidget);
      expect(find.text('bms'), findsOneWidget);

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
      expect(find.text('81%'), findsNWidgets(2), reason: 'SOC under Vehicle, and Battery under This week (BladeWatch-4zr7)');
      await unmount(tester);
    });
  });

  group('LiveScreen', () {
    // BladeWatch-rdtj.68: a picked camera comes from the car whole, at its native resolution; the
    // quarter is cut here only while the car still sends the four-camera still.
    testWidgets('a picked camera is asked of the car and shown whole once it comes', (tester) async {
      final s = TestSession(phase: TransportPhase.pear);
      final paths = <String>[];
      var view = 'mosaic';
      var n = 0;
      await pumpScreen(
          tester,
          s,
          LiveScreen(
            fetch: (_, path) async {
              paths.add(path);
              n++;
              // A new picture every time, so each one is shown.
              return MediaResponse(200, Uint8List.fromList([...testPng]..last ^= n & 1), headers: {'x-still-view': view});
            },
            enable: (_) async {},
            gps: (_) async => GetGpsLocationResponse(),
          ));
      await tester.pump();
      expect(paths.last, '/api/stream/still', reason: 'all four cameras by default');

      await tester.tap(find.byKey(const ValueKey('live.camera.2')));
      await tester.pump();
      await tester.pump();
      expect(paths.last, '/api/stream/still?camera=2', reason: 'asked at once, not at the next tick');
      expect(find.byKey(const ValueKey('live.quarter')), findsOneWidget, reason: 'still the mosaic: cut the quarter');

      view = '2';
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.byKey(const ValueKey('live.quarter')), findsNothing, reason: 'the camera itself: shown whole');
      expect(find.byKey(const ValueKey('live.frame')), findsOneWidget);
      expect(s.rpc.calls.where((c) => c.method == 'SetViewMode'), isEmpty, reason: 'the car\'s shared stream is never switched');
      await unmount(tester);
    });

    // As in the in-car Live View: where the car is, or that it has no fix yet; tapping opens Location.
    testWidgets('shows the car\'s GPS fix in a chip that opens Location', (tester) async {
      final s = TestSession(phase: TransportPhase.pear);
      var json = '';
      var gpsCalls = 0;
      String? went;
      await pumpScreen(
          tester,
          s,
          ShellNav(
            go: (id) => went = id,
            child: LiveScreen(
              fetch: (_, _) async => MediaResponse(200, testPng),
              enable: (_) async {},
              gps: (_) async {
                gpsCalls++;
                return GetGpsLocationResponse(locationJson: json);
              },
            ),
          ));
      await tester.pump();
      expect(find.text(t('safe_loc.waiting_gps')), findsOneWidget, reason: 'no fix yet');

      json = '{"lat": 37.77493, "lng": -122.41942, "isStale": false}';
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(gpsCalls, 2, reason: 'asked again every 5 s');
      expect(find.text(t('vehicle.gps_location')), findsOneWidget);
      expect(find.text('37.7749, -122.4194'), findsOneWidget);

      json = '{"lat": 37.77493, "lng": -122.41942, "isStale": true}';
      await tester.pump(const Duration(seconds: 5));
      await tester.pump();
      expect(find.text('${t('vehicle.gps_location')} · ${t('status.stale')}'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('live.gps')));
      expect(went, 'location');
      await unmount(tester);
    });

    // BladeWatch-rdtj.61: one still a second; the picture changes only when a new frame comes,
    // and a failed fetch leaves the last one up.
    testWidgets('polls once a second, and replaces the still only with a different one', (tester) async {
      final s = TestSession(phase: TransportPhase.pear);
      var fetches = 0;
      var answer = MediaResponse(200, Uint8List.fromList(testPng));
      await pumpScreen(tester, s, LiveScreen(fetch: (_, _) async {
        fetches++;
        return answer;
      }, enable: (_) async {}));
      await tester.pump();
      Uint8List shown() => ((tester.widget<Image>(find.byKey(const ValueKey('live.frame')))).image as MemoryImage).bytes;
      final first = shown();
      final afterOpen = fetches;

      answer = MediaResponse(200, Uint8List.fromList(testPng)); // the same still, a new copy
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(fetches, afterOpen + 1, reason: 'one fetch a second, on Pear too');
      expect(identical(shown(), first), isTrue, reason: 'the same bytes again: the picture is kept');

      answer = MediaResponse(500, Uint8List(0)); // a failed fetch
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(identical(shown(), first), isTrue, reason: 'a failed fetch leaves the last still up');

      final next = Uint8List.fromList([...testPng]..last ^= 1);
      answer = MediaResponse(200, next);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(identical(shown(), next), isTrue, reason: 'a new frame replaces it');
      await unmount(tester);
    });

    testWidgets('turns streaming on when the car has no still yet, then shows it', (tester) async {
      final s = TestSession(phase: TransportPhase.pear);
      final answers = [MediaResponse(503, Uint8List(0)), MediaResponse(200, testPng)];
      var enabled = 0;
      await pumpScreen(tester, s, LiveScreen(fetch: (_, _) async => answers.length > 1 ? answers.removeAt(0) : answers.first, enable: (_) async => enabled++));
      expect(find.text(t('companion.live_starting')), findsOneWidget);
      expect(enabled, 1);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(find.byKey(const ValueKey('live.frame')), findsOneWidget);
      expect(find.textContaining(t('companion.live_note')), findsOneWidget);
      await unmount(tester);
    });

    // BladeWatch-rdtj.45: one camera is that quarter of the four-camera still, cut here. Nothing
    // is asked of the car: switching its shared stream would change the in-car screen too.
    testWidgets('a camera picker shows one quarter of the still, and asks the car for nothing', (tester) async {
      final s = TestSession(phase: TransportPhase.lan);
      var enabled = 0;
      await pumpScreen(tester, s, LiveScreen(fetch: (_, _) async => MediaResponse(200, testPng), enable: (_) async => enabled++));
      await tester.pump();
      expect(find.byKey(const ValueKey('live.quarter')), findsNothing, reason: 'all four to start with');
      final names = ['companion.cam_front', 'companion.cam_right', 'companion.cam_rear', 'companion.cam_left'];
      final quarters = [Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight];
      for (var q = 0; q < 4; q++) {
        await tester.tap(find.byKey(ValueKey('live.camera.$q')));
        await tester.pump();
        expect(tester.widget<Align>(find.byKey(const ValueKey('live.quarter'))).alignment, quarters[q]);
        expect(find.textContaining(t('companion.live_note_one', {'camera': t(names[q])})), findsOneWidget);
      }
      await tester.tap(find.byKey(const ValueKey('live.camera.all')));
      await tester.pump();
      expect(find.byKey(const ValueKey('live.quarter')), findsNothing);
      expect(find.textContaining(t('companion.live_note')), findsOneWidget);
      expect(s.rpc.calls.where((c) => c.method == 'SetViewMode'), isEmpty);
      expect(enabled, 0);
      await unmount(tester);
    });

    // BladeWatch-rdtj.45: on a big window the still fills the black area, it does not sit at its
    // own pixel size in the middle.
    testWidgets('the still fills a desktop window', (tester) async {
      final s = TestSession(phase: TransportPhase.lan);
      await pumpScreen(tester, s, LiveScreen(fetch: (_, _) async => MediaResponse(200, testPng), enable: (_) async {}), size: const Size(1600, 1000));
      await tester.pump();
      final frame = tester.getSize(find.byKey(const ValueKey('live.frame')));
      expect(frame.width, 1600, reason: 'a 1x1 still stretched to the area, as a 640x480 one is');
      expect(frame.height, greaterThan(800));
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
          fetch: (_, _) async {
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

    // BladeWatch-tayl: live again the moment the route is back. A fetch the drop left hanging
    // must not block that (it would until fetchMedia's 20 s timeout), and the next tick's period
    // must not be waited out either.
    testWidgets('a reconnect fetches at once, past a fetch the drop left hanging', (tester) async {
      final s = TestSession(phase: TransportPhase.pear);
      final hung = Completer<MediaResponse>();
      var calls = 0;
      await pumpScreen(
        tester,
        s,
        LiveScreen(
          fetch: (_, _) {
            calls++;
            return calls == 2 ? hung.future : Future.value(MediaResponse(200, testPng));
          },
          enable: (_) async {},
        ),
      );
      expect(calls, 1);
      await tester.pump(const Duration(seconds: 2)); // the second fetch starts, and hangs
      expect(calls, 2);
      await s.go(tester, TransportPhase.discovering);
      await tester.pump(const Duration(seconds: 6));
      expect(calls, 2, reason: 'the hanging fetch holds the ticks while the route is down');
      expect(find.byKey(const ValueKey('live.frame')), findsOneWidget, reason: 'the last frame stays');

      await s.go(tester, TransportPhase.pear);
      await tester.pump();
      expect(calls, 3, reason: 'fetched the moment the route came back, not after a timeout');
      hung.complete(MediaResponse(200, testPng)); // the stale answer is ignored
      await tester.pump();
      expect(find.byKey(const ValueKey('live.frame')), findsOneWidget);
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

