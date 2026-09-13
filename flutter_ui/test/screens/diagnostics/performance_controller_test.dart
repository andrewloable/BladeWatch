import 'dart:convert';

import 'package:bladewatch_ui/rpc/jwt_source.dart';
import 'package:bladewatch_ui/rpc/raw_http_sender.dart';
import 'package:bladewatch_ui/rpc/services/system_service_client.dart';
import 'package:bladewatch_ui/screens/diagnostics/performance_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_rpc_client.dart';

class _FakeJwtSource implements JwtSource {
  @override
  Future<String?> mintJwt() async => 'jwt-1';
  @override
  Future<int> stateVersion() async => 0;
}

void main() {
  late FakeRpcClient rpc;
  late List<(Uri, Map<String, String>, String)> sentRequests;
  late RawHttpResponse Function(Uri uri, Map<String, String> headers, String body) respondWith;
  late PerformanceController controller;

  setUp(() {
    rpc = FakeRpcClient();
    sentRequests = [];
    respondWith = (uri, headers, body) => const RawHttpResponse(200, '{"status":"ok","clientId":"c1"}');
    controller = PerformanceController(
      systemService: SystemServiceClient(rpc),
      jwtSource: _FakeJwtSource(),
      baseUrl: Uri.parse('http://127.0.0.1:8080'),
      send: (uri, headers, body) async {
        sentRequests.add((uri, headers, body));
        return respondWith(uri, headers, body);
      },
    );
  });

  test('defaults to the real IO sender and 127.0.0.1:8080 when neither is given', () {
    expect(
      () => PerformanceController(systemService: SystemServiceClient(rpc), jwtSource: _FakeJwtSource()),
      returnsNormally,
    );
  });

  test('starts in the connecting state with no snapshot', () {
    expect(controller.state, PerformanceViewState.connecting);
    expect(controller.snapshot, isNull);
  });

  group('connect', () {
    test('POSTs to /api/performance/connect with a clientId', () async {
      await controller.connect();

      expect(sentRequests, hasLength(1));
      final (uri, _, body) = sentRequests.single;
      expect(uri.path, '/api/performance/connect');
      final decoded = jsonDecode(body) as Map;
      expect(decoded['clientId'], isA<String>());
      expect((decoded['clientId'] as String), isNotEmpty);
    });

    test('does not throw and does not block polling from starting even if the daemon rejects connect', () async {
      respondWith = (uri, headers, body) => const RawHttpResponse(500, 'error');

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
      sentRequests.clear();

      await controller.poll();

      expect(sentRequests, hasLength(1));
      expect(sentRequests.single.$1.path, '/api/performance/heartbeat');
      final decoded = jsonDecode(sentRequests.single.$3) as Map;
      expect(decoded['clientId'], 'c1');
    });

    test('does not send a heartbeat if connect was never called', () async {
      rpc.stubJson('SystemService', 'GetPerformance', {'success': true, 'performanceJson': '{}'});

      await controller.poll();

      expect(sentRequests, isEmpty);
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
    test('POSTs to /api/performance/disconnect with the clientId', () async {
      await controller.connect();
      sentRequests.clear();

      await controller.disconnect();

      expect(sentRequests, hasLength(1));
      expect(sentRequests.single.$1.path, '/api/performance/disconnect');
      final decoded = jsonDecode(sentRequests.single.$3) as Map;
      expect(decoded['clientId'], 'c1');
    });

    test('is a harmless no-op if connect was never called', () async {
      await controller.disconnect();

      expect(sentRequests, isEmpty);
    });
  });
}
