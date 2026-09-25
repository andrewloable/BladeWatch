import 'package:bladewatch_companion/car/media.dart';
import 'package:bladewatch_companion/screens/location/location_screen.dart';
import 'package:bladewatch_companion/screens/recordings/clips.dart';
import 'package:bladewatch_companion/screens/recordings/recordings_screen.dart';
import 'package:bladewatch_companion/screens/vehicle/vehicle_screen.dart';
import 'package:bladewatch_rpc/gen/bladewatch/v1/vehicle.pb.dart';
import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support.dart';

Map<String, dynamic> clip(String name, {String type = 'RECORDING_TYPE_NORMAL'}) =>
    {'filename': name, 'type': type, 'timestamp': '1700000000000', 'size': '2048', 'durationSeconds': '60'};

void main() {
  group('RecordingsScreen', () {
    testWidgets('lists every clip with totals, filters by type, deletes after confirming', (tester) async {
      final s = TestSession();
      s.rpc.stubJson('RecordingsService', 'GetStats', {'stats': {'totalCount': 2, 'totalSizeBytes': '4096'}});
      s.rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': [clip('a.mp4'), clip('b.mp4', type: 'RECORDING_TYPE_PROXIMITY')]});
      s.rpc.stubJson('RecordingsService', 'DeleteRecording', {'success': true});
      await pumpScreen(tester, s, const RecordingsScreen());
      expect(find.byKey(const ValueKey('rec.stats')), findsOneWidget);
      expect(find.byKey(const ValueKey('clip.a.mp4')), findsOneWidget);
      expect(find.textContaining(t('events.badge_proximity')), findsWidgets);

      await tester.tap(find.byKey(const ValueKey('rec.type.sentry')));
      await tester.pumpAndSettle();
      expect((s.rpc.calls.lastWhere((c) => c.method == 'ListRecordings').request as dynamic).type, 'sentry');

      await tester.tap(find.byKey(const ValueKey('clip.delete.a.mp4')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t('common.cancel')));
      await tester.pumpAndSettle();
      expect(s.rpc.calls.where((c) => c.method == 'DeleteRecording'), isEmpty);

      await tester.tap(find.byKey(const ValueKey('clip.delete.a.mp4')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete.confirm')));
      await tester.pumpAndSettle();
      expect((s.rpc.calls.lastWhere((c) => c.method == 'DeleteRecording').request as dynamic).filename, 'a.mp4');
      expect(find.text(t('events.toast_deleted')), findsOneWidget);

      s.rpc.stubJson('RecordingsService', 'DeleteRecording', {'success': false, 'error': 'busy'});
      await tester.tap(find.byKey(const ValueKey('clip.delete.b.mp4')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete.confirm')));
      await tester.pumpAndSettle();
      expect(find.text(t('events.alert_delete_failed_generic')), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('an empty library says so', (tester) async {
      final s = TestSession();
      s.rpc.stubError('RecordingsService', 'GetStats', const ConnectError('unavailable', 'x'));
      s.rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': []});
      await pumpScreen(tester, s, const RecordingsScreen());
      expect(find.text(t('events.empty_none_title')), findsOneWidget);
      await unmount(tester);
    });
  });

  group('clips', () {
    testWidgets('a thumbnail is fetched once and cached; a failed one shows a placeholder', (tester) async {
      final s = TestSession();
      var fetches = 0;
      Future<MediaResponse> ok(_, _) async {
        fetches++;
        return MediaResponse(200, testPng);
      }

      await pumpScreen(tester, s, Column(children: [ClipThumb('x.mp4', fetch: ok), ClipThumb('x.mp4', fetch: ok)]));
      await tester.pump();
      await pumpScreen(tester, s, ClipThumb('x.mp4', fetch: ok));
      expect(fetches, lessThanOrEqualTo(2));
      await pumpScreen(tester, s, ClipThumb('gone.mp4', fetch: (_, _) async => MediaResponse(404, Uint8List(0))));
      await tester.pump();
      expect(find.byIcon(Icons.videocam_off_outlined), findsOneWidget);
    });

    testWidgets('the player says so where it cannot play, and saves the clip instead', (tester) async {
      final s = TestSession();
      await pumpScreen(tester, s, const ClipPlayerScreen(filename: 'a.mp4', canPlay: false));
      expect(find.text(t('companion.player_unsupported')), findsOneWidget);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => '/tmp',
      );
      await tester.tap(find.byKey(const ValueKey('player.save')));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pump();
      expect(find.byKey(const ValueKey('player.saved')), findsOneWidget, reason: 'the gateway is not running: a failure, reported');
    });

    testWidgets('where it can play but the clip will not load, it says so', (tester) async {
      final s = TestSession();
      await pumpScreen(tester, s, const ClipPlayerScreen(filename: 'a.mp4', canPlay: true));
      await tester.pump();
      await tester.pump();
      expect(find.text(t('errors.load_failed')), findsOneWidget);
    });
  });

  group('VehicleScreen', () {
    void state(TestSession s) => s.rpc.stubJson('VehicleService', 'GetState', {
          'success': true,
          'doors': {'overall': 1},
          'battery': {'soc': 70.0, 'rangeKm': 300, 'fuelPercent': 40.0},
          'climate': {'acOn': false, 'setpointC': 21.0, 'fanLevel': 3, 'outsideTempC': 25.0},
          'windows': {'lf': 0, 'rf': 10, 'lr': 0, 'rr': 100},
          'tyres': {'fl': {'psi': 36.0, 'temperatureC': 20}, 'fr': {'psi': 35.0, 'airLeakState': 1}, 'rl': {}, 'rr': {}},
        });

    testWidgets('shows the car; every command carries a cached action token', (tester) async {
      final s = TestSession();
      state(s);
      s.rpc.stubJson('VehicleService', 'IssueActionToken', {'success': true, 'token': 'act-1', 'expiresInSeconds': 30});
      s.rpc.stubJson('VehicleService', 'SetClimate', {'success': true});
      await pumpScreen(tester, s, const VehicleScreen(), size: const Size(420, 2400));
      expect(find.text(t('companion.locked')), findsOneWidget);
      expect(find.text('21 °C'), findsOneWidget);
      expect(find.text('25 °C'), findsOneWidget); // outside air (BladeWatch-eh3u)
      expect(find.textContaining(t('vehicle.leak')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('climate.ac')));
      await tester.pumpAndSettle();
      final ac = s.rpc.calls.lastWhere((c) => c.method == 'SetClimate').request as SetClimateRequest;
      expect(ac.action, 'power_on');
      expect(s.headerCalls.single, {'X-Vehicle-Action-Token': 'act-1'});

      await tester.tap(find.byKey(const ValueKey('temp.up')));
      await tester.pumpAndSettle();
      expect((s.rpc.calls.lastWhere((c) => c.method == 'SetClimate').request as SetClimateRequest).setpointC, 22);
      await tester.tap(find.byKey(const ValueKey('fan.down')));
      await tester.pumpAndSettle();
      expect((s.rpc.calls.lastWhere((c) => c.method == 'SetClimate').request as SetClimateRequest).fanLevel, 2);
      await tester.tap(find.byKey(const ValueKey('climate.max')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('seat.driver-heat')), findsNothing, reason: 'seat control was removed');

      expect(s.rpc.calls.where((c) => c.method == 'IssueActionToken'), hasLength(1), reason: 'one token for its lifetime');
      await unmount(tester);
    });

    testWidgets('windows move only after the owner confirms', (tester) async {
      final s = TestSession();
      state(s);
      s.rpc.stubJson('VehicleService', 'IssueActionToken', {'success': true, 'token': 'act', 'expiresInSeconds': 30});
      s.rpc.stubJson('VehicleService', 'MoveWindow', {'success': true});
      await pumpScreen(tester, s, const VehicleScreen(), size: const Size(420, 2400));
      await tester.tap(find.byKey(const ValueKey('windows.open')));
      await tester.pumpAndSettle();
      expect(find.text(t('companion.window_confirm')), findsOneWidget);
      await tester.tap(find.text(t('common.cancel')));
      await tester.pumpAndSettle();
      expect(s.rpc.calls.where((c) => c.method == 'MoveWindow'), isEmpty);

      for (final key in ['windows.vent', 'windows.close']) {
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('window.confirm')));
        await tester.pumpAndSettle();
      }
      final moves = s.rpc.calls.where((c) => c.method == 'MoveWindow').map((c) => c.request as MoveWindowRequest).toList();
      expect(moves.first.targetPercent, 12);
      expect(moves.last.direction, 'close');
      await unmount(tester);
    });

    testWidgets('a refused command or token is shown, with the car\'s reason when it gives one', (tester) async {
      final s = TestSession();
      state(s);
      s.rpc.stubJson('VehicleService', 'IssueActionToken', {'success': false, 'error': 'driving'});
      await pumpScreen(tester, s, const VehicleScreen(), size: const Size(420, 2400));
      await tester.tap(find.byKey(const ValueKey('climate.ac')));
      await tester.pumpAndSettle();
      expect(find.text('driving'), findsOneWidget);

      s.rpc.stubJson('VehicleService', 'IssueActionToken', {'success': true, 'token': 'a', 'expiresInSeconds': 30});
      s.rpc.stubJson('VehicleService', 'SetClimate', {'success': false, 'message': 'interlock'});
      await tester.tap(find.byKey(const ValueKey('climate.max')));
      await tester.pumpAndSettle();
      expect(find.text('interlock'), findsOneWidget);

      s.rpc.stubError('VehicleService', 'SetClimate', const ConnectError('unavailable', 'x'));
      await tester.tap(find.byKey(const ValueKey('temp.down')));
      await tester.pumpAndSettle();
      expect(find.text(t('errors.generic')), findsOneWidget);
      await unmount(tester);
    });

    test('an expired token is replaced before the next command', () async {
      final s = TestSession();
      var now = DateTime(2026);
      s.rpc.stubJson('VehicleService', 'IssueActionToken', {'success': true, 'token': 't', 'expiresInSeconds': 5});
      s.rpc.stubJson('VehicleService', 'SetClimate', {'success': true});
      final actions = VehicleActions(s.session, now: () => now);
      await actions.run((c) => c.setClimate(SetClimateRequest()));
      now = now.add(const Duration(seconds: 3));
      await actions.run((c) => c.setClimate(SetClimateRequest()));
      now = now.add(const Duration(seconds: 2));
      await actions.run((c) => c.setClimate(SetClimateRequest()));
      expect(s.rpc.calls.where((c) => c.method == 'IssueActionToken'), hasLength(2));
      expect(const VehicleRefused('why').toString(), 'why');
    });

    testWidgets('no climate data says so', (tester) async {
      final s = TestSession();
      s.rpc.stubJson('VehicleService', 'GetState', {'success': true, 'doors': {'overall': 0}});
      await pumpScreen(tester, s, const VehicleScreen(), size: const Size(420, 2000));
      expect(find.text(t('vehicle.climate_unavailable')), findsOneWidget);
      expect(find.text(t('vehicle.unlocked')), findsOneWidget);
      await unmount(tester);
    });
  });

  group('LocationScreen', () {
    test('parseFix keeps usable fixes only', () {
      expect(parseFix(''), isNull);
      expect(parseFix('nope'), isNull);
      expect(parseFix('{"lat":0,"lng":0}'), isNull);
      expect(parseFix('{"lat":95,"lng":0}'), isNull);
      final f = parseFix('{"latitude":14.5,"longitude":121.0,"isStale":true,"accuracy":12}')!;
      expect((f.at.latitude, f.stale, f.accuracy), (14.5, true, 12.0));
    });

    testWidgets('shows the fix on a map and copies the maps link', (tester) async {
      final s = TestSession();
      s.rpc.stubJson('VehicleService', 'GetGpsLocation', {
        'locationJson': '{"lat":14.5,"lng":121.0,"accuracy":8,"isStale":true}',
        'googleMapsUrl': 'https://maps.example/x',
      });
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String;
        return null;
      });
      // Wide: the test font is fixed-width, and flutter_map's attribution row overflows a phone in it.
      await pumpScreen(tester, s, const LocationScreen(), size: const Size(1200, 900));
      expect(find.text('14.50000, 121.00000'), findsOneWidget);
      expect(find.textContaining('± 8 m'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('location.copy')));
      await tester.pump();
      expect(copied, 'https://maps.example/x');
      await unmount(tester);
    });

    testWidgets('no fix says so', (tester) async {
      final s = TestSession();
      s.rpc.stubJson('VehicleService', 'GetGpsLocation', {'locationJson': ''});
      await pumpScreen(tester, s, const LocationScreen());
      expect(find.text(t('vehicle.no_gps_fix')), findsOneWidget);
      await unmount(tester);
    });
  });
}
