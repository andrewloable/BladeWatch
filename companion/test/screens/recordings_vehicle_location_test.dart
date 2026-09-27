import 'dart:io';

import 'package:bladewatch_companion/car/media.dart';
import 'package:bladewatch_companion/screens/common/car_map.dart';
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

    testWidgets('a second tap while a clip is saving starts no second download', (tester) async {
      // A car that takes the request and holds it: the first download is still running.
      final held = <HttpRequest>[];
      final server = (await tester.runAsync(() async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        server.listen(held.add);
        return server;
      }))!;
      // Real sockets under the test's fake clock: let the IO happen, then run what it scheduled.
      Future<void> settle() async {
        for (var i = 0; i < 10; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
          await tester.pump();
        }
      }
      final s = TestSession(baseUrl: Uri.parse('http://127.0.0.1:${server.port}'));
      await pumpScreen(tester, s, const ClipPlayerScreen(filename: 'a.mp4', canPlay: false));
      final tmp = (await tester.runAsync(() => Directory.systemTemp.createTemp('save')))!;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => tmp.path,
      );
      for (var i = 0; i < 2; i++) {
        // flutter_test answers every HttpClient request with a 400; this download needs real sockets.
        await HttpOverrides.runWithHttpOverrides(() => tester.tap(find.byKey(const ValueKey('player.save'))), _RealHttp());
        await settle();
      }
      expect(held, hasLength(1), reason: 'a second download would delete the first one\'s .part');

      await tester.runAsync(() async {
        held.single.response.statusCode = 404;
        await held.single.response.close();
      });
      await settle();
      expect(find.byKey(const ValueKey('player.saved')), findsOneWidget);
      await tester.runAsync(() async {
        await server.close(force: true);
        await tmp.delete(recursive: true);
      });
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
      // BladeWatch-rdtj.47: a car with a tank says which range this is; the dashboard's is the total.
      expect(find.text(t('companion.week_elec_range')), findsOneWidget);
      expect(find.text(t('vehicle.range')), findsNothing);
      expect(find.text(t('companion.week_fuel_range')), findsNothing, reason: 'no fuel range reported');
      expect(find.text('21 °C'), findsOneWidget);
      expect(find.text('25 °C'), findsOneWidget); // outside air (BladeWatch-eh3u)
      // BladeWatch-rdtj.54: the -/+ buttons say which setting they change and which way. An
      // IconButton's tooltip is what a screen reader announces (SemanticsData.tooltip).
      final semantics = tester.ensureSemantics();
      for (final (key, name) in [('temp', t('vehicle.temperature')), ('fan', t('vehicle.fan'))]) {
        expect(tester.getSemantics(find.byKey(ValueKey('$key.down'))).tooltip, t('companion.step_down', {'name': name}));
        expect(tester.getSemantics(find.byKey(ValueKey('$key.up'))).tooltip, t('companion.step_up', {'name': name}));
      }
      semantics.dispose();
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

    testWidgets('range: plain on a BEV; electric and fuel on a car with a tank', (tester) async {
      final s = TestSession();
      s.rpc.stubJson('VehicleService', 'GetState', {
        'success': true,
        'battery': {'soc': 70.0, 'rangeKm': 300},
      });
      await pumpScreen(tester, s, const VehicleScreen(), size: const Size(420, 2400));
      expect(find.text(t('vehicle.range')), findsOneWidget);
      expect(find.text(t('companion.week_elec_range')), findsNothing);
      await unmount(tester);

      final p = TestSession();
      p.rpc.stubJson('VehicleService', 'GetState', {
        'success': true,
        'battery': {'soc': 70.0, 'rangeKm': 86, 'fuelRangeKm': 356},
      });
      await pumpScreen(tester, p, const VehicleScreen(), size: const Size(420, 2400));
      expect(find.text(t('companion.week_elec_range')), findsOneWidget);
      expect(find.text('86 km'), findsOneWidget);
      expect(find.text(t('companion.week_fuel_range')), findsOneWidget);
      expect(find.text('356 km'), findsOneWidget);
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

    // BladeWatch-rdtj.46: one window to a set opening, each through the same confirmation.
    testWidgets('one window to a preset: named in the question, sent only after OK', (tester) async {
      final s = TestSession();
      state(s); // lf 0, rf 10, lr 0, rr 100
      s.rpc.stubJson('VehicleService', 'IssueActionToken', {'success': true, 'token': 'act', 'expiresInSeconds': 30});
      s.rpc.stubJson('VehicleService', 'MoveWindow', {'success': true});
      await pumpScreen(tester, s, const VehicleScreen(), size: const Size(420, 2400));
      bool on(String k) => tester.widget<ChoiceChip>(find.byKey(ValueKey(k))).selected;
      expect((on('window.4.100'), on('window.1.0'), on('window.2.0'), on('window.2.25')), (true, true, false, false),
          reason: 'where each window is; 10% is neither 0 nor 25');

      await tester.tap(find.byKey(const ValueKey('window.1.50')));
      await tester.pumpAndSettle();
      expect(find.text(t('companion.window_to', {'window': t('companion.window_1'), 'percent': 50})), findsOneWidget);
      expect(find.text(t('companion.window_confirm')), findsOneWidget);
      await tester.tap(find.text(t('common.cancel')));
      await tester.pumpAndSettle();
      expect(s.rpc.calls.where((c) => c.method == 'MoveWindow'), isEmpty, reason: 'cancel sends nothing');

      for (final key in ['window.1.50', 'window.3.0']) {
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('window.confirm')));
        await tester.pumpAndSettle();
      }
      final moves = s.rpc.calls.where((c) => c.method == 'MoveWindow').map((c) => c.request as MoveWindowRequest).toList();
      expect((moves[0].windowIndex, moves[0].targetPercent, moves[0].direction), (1, 50, ''));
      expect((moves[1].windowIndex, moves[1].hasTargetPercent(), moves[1].targetPercent), (3, true, 0),
          reason: 'fully closed is sent as 0%, not left out');
      await unmount(tester);
    });

    // BladeWatch-rdtj.69: the sunroof and sunshade, as the in-car app offers them.
    testWidgets('sunroof and sunshade: only when the car has them, 0/50/100 only, confirmed first', (tester) async {
      final s = TestSession();
      s.rpc.stubJson('VehicleService', 'GetState', {
        'success': true,
        'windows': {'lf': 0, 'rf': 0, 'lr': 0, 'rr': 0, 'sunroof': 60, 'sunshade': -1},
        'capabilities': {
          'windows': {'sunroof': true},
        },
      });
      s.rpc.stubJson('VehicleService', 'IssueActionToken', {'success': true, 'token': 'act', 'expiresInSeconds': 30});
      s.rpc.stubJson('VehicleService', 'MoveWindow', {'success': true});
      await pumpScreen(tester, s, const VehicleScreen(), size: const Size(420, 2600));

      expect(find.text(t('vehicle.sunroof')), findsOneWidget);
      expect(find.text(t('vehicle.sunshade')), findsNothing, reason: 'this car has no sunshade');
      expect(find.byKey(const ValueKey('window.5.25')), findsNothing, reason: 'the panel has no 25% or 75%');
      bool on(String k) => tester.widget<ChoiceChip>(find.byKey(ValueKey(k))).selected;
      expect((on('window.5.0'), on('window.5.50'), on('window.5.100')), (false, true, false), reason: '60% is nearest 50%');

      await tester.ensureVisible(find.byKey(const ValueKey('window.5.100')));
      await tester.tap(find.byKey(const ValueKey('window.5.100')));
      await tester.pumpAndSettle();
      expect(find.text(t('companion.window_to', {'window': t('vehicle.sunroof'), 'percent': 100})), findsOneWidget);
      await tester.tap(find.text(t('common.cancel')));
      await tester.pumpAndSettle();
      expect(s.rpc.calls.where((c) => c.method == 'MoveWindow'), isEmpty);

      await tester.tap(find.byKey(const ValueKey('window.5.0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('window.confirm')));
      await tester.pumpAndSettle();
      final move = s.rpc.calls.lastWhere((c) => c.method == 'MoveWindow').request as MoveWindowRequest;
      expect((move.windowIndex, move.hasTargetPercent(), move.targetPercent), (5, true, 0));
      await unmount(tester);
    });

    test('which sun-panel preset lights, as in the car', () {
      expect([for (final p in [-1, 0, 2, 3, 49, 74, 75, 76, 100]) sunPanelPreset(p)], [null, 0, 0, 50, 50, 50, 100, 100, 100]);
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
      // BladeWatch-rdtj.57: "Back to the car" starts a fresh map on the car, wherever it was panned.
      final before = tester.widget(find.byType(CarMap)).key;
      await tester.tap(find.byKey(const ValueKey('location.recenter')));
      await tester.pump();
      expect(tester.widget(find.byType(CarMap)).key, isNot(before));
      expect(find.textContaining('± 8 m'), findsOneWidget);
      // BladeWatch-rdtj.54: it is announced as what it does.
      final semantics = tester.ensureSemantics();
      expect(tester.getSemantics(find.byKey(const ValueKey('location.copy'))).tooltip, t('companion.copy_map_link'));
      semantics.dispose();
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

/// The real HttpClient, in place of flutter_test's canned 400s.
class _RealHttp extends HttpOverrides {}
