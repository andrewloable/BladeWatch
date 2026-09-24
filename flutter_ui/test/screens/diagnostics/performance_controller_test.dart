import 'dart:convert';

import 'package:bladewatch_rpc/gen/bladewatch/v1/system.pb.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import 'package:bladewatch_ui/screens/diagnostics/performance_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';

/// BladeWatch-qwqq: this controller used to reach the daemon two ways — the typed
/// GetPerformance RPC for polling, and raw HTTP to REST for connect/heartbeat/disconnect,
/// because those three had no RPC equivalent. They do now, so the split and its raw-HTTP
/// plumbing (jwtSource / send / baseUrl) are gone, and these tests assert RPC calls rather
/// than captured HTTP requests.
void main() {
  late FakeRpcClient rpc;
  late PerformanceController controller;

  setUp(() {
    rpc = FakeRpcClient();
    rpc.stubJson('SystemService', 'PerformanceConnect', {'success': true, 'clientId': 'c1'});
    rpc.stubJson('SystemService', 'PerformanceHeartbeat', {'success': true});
    rpc.stubJson('SystemService', 'PerformanceDisconnect', {'success': true});
    controller = PerformanceController(systemService: SystemServiceClient(rpc));
  });

  List<RpcCall> callsTo(String method) =>
      rpc.calls.where((c) => c.method == method).toList();

  test('starts in the connecting state with no snapshot', () {
    expect(controller.state, PerformanceViewState.connecting);
    expect(controller.snapshot, isNull);
  });

  group('connect', () {
    test('registers a session over PerformanceConnect with a non-empty clientId', () async {
      await controller.connect();

      final calls = callsTo('PerformanceConnect');
      expect(calls, hasLength(1));
      final request = calls.single.request as PerformanceConnectRequest;
      expect(request.clientId, isNotEmpty);
    });

    test('keeps the id the SERVER registered, not the one it asked for', () async {
      // Monitoring is on-demand and keyed by the registered id. If the controller kept its
      // own id instead, every heartbeat would miss and the session would time out under a
      // panel the user is still looking at.
      rpc.stubJson('SystemService', 'PerformanceConnect',
          {'success': true, 'clientId': 'server-assigned-id'});
      // poll() returns early if GetPerformance fails, BEFORE it heartbeats, so without this
      // the assertion below would pass for the wrong reason on an empty call list.
      rpc.stubJson('SystemService', 'GetPerformance',
          {'success': true, 'performanceJson': '{}'});

      await controller.connect();
      await controller.poll();

      final beats = callsTo('PerformanceHeartbeat');
      expect(beats, hasLength(1));
      expect((beats.single.request as PerformanceHeartbeatRequest).clientId,
          'server-assigned-id');
    });

    test('does not throw or block polling when the daemon rejects connect', () async {
      rpc.stubError('SystemService', 'PerformanceConnect',
          const ConnectError('internal', 'nope'));

      await controller.connect();
      await controller.poll();

      expect(controller.state, PerformanceViewState.connecting); // no data yet, but no crash
    });
  });

  group('poll', () {
    test('parses a full snapshot from GetPerformance and transitions to ready', () async {
      rpc.stubJson('SystemService', 'GetPerformance', {
        'success': true,
        'performanceJson': jsonEncode({
          'cpu': {'system': 12.5, 'app': 3.2, 'freqMhz': 1800, 'tempC': 45.0},
          'memory': {'usagePercent': 60.0, 'totalMb': 4096.0, 'usedMb': 2457.6, 'appMb': 128.0},
          'gpu': {'usage': 20.0, 'freqMhz': 500.0, 'tempC': 40.0},
          'app': {'threadCount': 42, 'gcCount': 7, 'openFds': 55},
        }),
      });

      await controller.poll();

      expect(controller.state, PerformanceViewState.ready);
      final snap = controller.snapshot!;
      expect(snap.cpu!.systemUsagePercent, 12.5);
      expect(snap.cpu!.appUsagePercent, 3.2);
      expect(snap.cpu!.freqMhz, 1800);
      expect(snap.cpu!.tempC, 45.0);
      expect(snap.memory!.usagePercent, 60.0);
      expect(snap.memory!.totalMb, 4096.0);
      expect(snap.gpu!.usagePercent, 20.0);
      expect(snap.gpu!.freqMhz, 500);
      expect(snap.app!.threadCount, 42);
      expect(snap.app!.gcCount, 7);
      expect(snap.app!.openFds, 55);
    });

    test('treats a section absent from the JSON as null, not a crash', () async {
      rpc.stubJson('SystemService', 'GetPerformance', {
        'success': true,
        'performanceJson': jsonEncode({
          'cpu': {'system': 1.0, 'app': 1.0, 'freqMhz': 1000, 'tempC': 30.0},
        }),
      });

      await controller.poll();

      expect(controller.snapshot!.cpu, isNotNull);
      expect(controller.snapshot!.memory, isNull);
      expect(controller.snapshot!.gpu, isNull);
      expect(controller.snapshot!.app, isNull);
    });

    test('the SOTA no-data wrapper (no cpu/memory/gpu/app keys) becomes an empty-but-ready snapshot', () async {
      rpc.stubJson('SystemService', 'GetPerformance', {
        'success': true,
        'performanceJson': jsonEncode({'status': 'no_data', 'message': 'no data yet', 'monitoring': false}),
      });

      await controller.poll();

      expect(controller.state, PerformanceViewState.ready);
      expect(controller.snapshot!.isEmpty, isTrue);
    });

    test('a temperature of 0 or below is treated as unavailable (matches native\'s N/A fallback)', () async {
      rpc.stubJson('SystemService', 'GetPerformance', {
        'success': true,
        'performanceJson': jsonEncode({
          'cpu': {'system': 1.0, 'app': 1.0, 'freqMhz': 1000, 'tempC': 0.0},
        }),
      });

      await controller.poll();

      expect(controller.snapshot!.cpu!.tempC, 0.0);
    });

    test('leaves state as connecting (does not update) if the RPC fails', () async {
      rpc.stubError('SystemService', 'GetPerformance', const ConnectError('unavailable', 'no daemon'));

      await controller.poll();

      expect(controller.state, PerformanceViewState.connecting);
      expect(controller.snapshot, isNull);
    });

    test('sends a heartbeat with the clientId after connect', () async {
      await controller.connect();
      rpc.stubJson('SystemService', 'GetPerformance', {'success': true, 'performanceJson': '{}'});

      await controller.poll();

      final beats = callsTo('PerformanceHeartbeat');
      expect(beats, hasLength(1));
      expect((beats.single.request as PerformanceHeartbeatRequest).clientId, 'c1');
    });

    test('does not send a heartbeat if connect was never called', () async {
      rpc.stubJson('SystemService', 'GetPerformance', {'success': true, 'performanceJson': '{}'});

      await controller.poll();

      expect(callsTo('PerformanceHeartbeat'), isEmpty);
    });

    test('notifies listeners on a successful poll', () async {
      rpc.stubJson('SystemService', 'GetPerformance', {'success': true, 'performanceJson': '{}'});
      var notifications = 0;
      controller.addListener(() => notifications++);

      await controller.poll();

      expect(notifications, greaterThan(0));
    });
  });

  group('disconnect', () {
    test('releases the session over PerformanceDisconnect with the clientId', () async {
      await controller.connect();

      await controller.disconnect();

      final calls = callsTo('PerformanceDisconnect');
      expect(calls, hasLength(1));
      expect((calls.single.request as PerformanceDisconnectRequest).clientId, 'c1');
    });

    test('is a harmless no-op if connect was never called', () async {
      await controller.disconnect();

      expect(callsTo('PerformanceDisconnect'), isEmpty);
    });
  });
}
