import 'dart:convert';

import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/rpc/jwt_source.dart';
import 'package:bladewatch_ui/rpc/raw_http_sender.dart';
import 'package:bladewatch_ui/rpc/services/system_service_client.dart';
import 'package:bladewatch_ui/screens/diagnostics/performance_controller.dart';
import 'package:bladewatch_ui/screens/diagnostics/performance_screen.dart';
import 'package:flutter/material.dart';
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
  late PerformanceController controller;

  setUp(() {
    rpc = FakeRpcClient();
    controller = PerformanceController(
      systemService: SystemServiceClient(rpc),
      jwtSource: _FakeJwtSource(),
      send: (uri, headers, body) async => const RawHttpResponse(200, '{"status":"ok","clientId":"c1"}'),
    );
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: PerformanceScreen(controller: controller)),
    ));
  }

  testWidgets('shows a connecting indicator before the first poll resolves', (tester) async {
    await pumpScreen(tester);

    expect(find.byKey(const ValueKey('perf.connecting')), findsOneWidget);
  });

  testWidgets('renders all 4 cards when every section is present', (tester) async {
    rpc.stubJson('SystemService', 'GetPerformance', {
      'success': true,
      'performanceJson': jsonEncode({
        'cpu': {'system': 12.5, 'app': 3.2, 'freqMhz': 1800, 'tempC': 45.0},
        'memory': {'usagePercent': 60.0, 'totalMb': 4096.0, 'usedMb': 2457.6, 'appMb': 128.0},
        'gpu': {'usage': 20.0, 'freqMhz': 500.0, 'tempC': 0.0},
        'app': {'threadCount': 42, 'gcCount': 7, 'openFds': 55},
      }),
    });

    // PerformanceScreen owns a permanent periodic poll timer once mounted,
    // so pumpAndSettle() (which waits for zero pending timers) never
    // returns — bounded pump()s instead, enough to flush connect()+poll().
    await pumpScreen(tester);
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('perf.cpu')), findsOneWidget);
    expect(find.byKey(const ValueKey('perf.memory')), findsOneWidget);
    expect(find.byKey(const ValueKey('perf.gpu')), findsOneWidget);
    expect(find.byKey(const ValueKey('perf.app')), findsOneWidget);
    expect(find.text('12.5%'), findsOneWidget);
    expect(find.text('N/A'), findsOneWidget); // GPU tempC == 0.0
    expect(find.text('45.0°C'), findsOneWidget); // CPU tempC
    expect(find.text('42'), findsOneWidget); // thread count
  });

  testWidgets('omits a card whose section is absent from the snapshot', (tester) async {
    rpc.stubJson('SystemService', 'GetPerformance', {
      'success': true,
      'performanceJson': jsonEncode({
        'cpu': {'system': 1.0, 'app': 1.0, 'freqMhz': 1000, 'tempC': 30.0},
      }),
    });

    await pumpScreen(tester);
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('perf.cpu')), findsOneWidget);
    expect(find.byKey(const ValueKey('perf.memory')), findsNothing);
    expect(find.byKey(const ValueKey('perf.gpu')), findsNothing);
    expect(find.byKey(const ValueKey('perf.app')), findsNothing);
  });

  testWidgets('shows no cards but no crash for the empty SOTA no-data snapshot', (tester) async {
    rpc.stubJson('SystemService', 'GetPerformance', {
      'success': true,
      'performanceJson': jsonEncode({'status': 'no_data', 'message': 'no data yet', 'monitoring': false}),
    });

    await pumpScreen(tester);
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('perf.ready')), findsOneWidget);
    expect(find.byKey(const ValueKey('perf.cpu')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing the screen disconnects the client', (tester) async {
    var disconnectSent = false;
    controller = PerformanceController(
      systemService: SystemServiceClient(rpc),
      jwtSource: _FakeJwtSource(),
      send: (uri, headers, body) async {
        if (uri.path == '/api/performance/disconnect') disconnectSent = true;
        return const RawHttpResponse(200, '{"status":"ok","clientId":"c1"}');
      },
    );
    rpc.stubJson('SystemService', 'GetPerformance', {'success': true, 'performanceJson': '{}'});
    // PerformanceScreen owns a permanent 3-second periodic poll timer once
    // mounted, so pumpAndSettle() (which waits for zero pending timers)
    // would never return — a few bounded pump()s instead.
    await pumpScreen(tester);
    await tester.pump();
    await tester.pump();

    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    expect(disconnectSent, isTrue);
  });

  testWidgets('renders correctly in dark theme', (tester) async {
    rpc.stubJson('SystemService', 'GetPerformance', {
      'success': true,
      'performanceJson': jsonEncode({
        'cpu': {'system': 1.0, 'app': 1.0, 'freqMhz': 1000, 'tempC': 30.0},
      }),
    });
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: PerformanceScreen(controller: controller)),
    ));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('perf.cpu')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
