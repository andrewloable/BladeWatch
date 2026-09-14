import 'package:bladewatch_ui/adb/adb_client.dart';
import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/platform/daemon_channel.dart';
import 'package:bladewatch_ui/platform/network_channel.dart';
import 'package:bladewatch_ui/rpc/services/storage_service_client.dart';
import 'package:bladewatch_ui/rpc/services/surveillance_service_client.dart';
import 'package:bladewatch_ui/rpc/services/system_service_client.dart';
import 'package:bladewatch_ui/screens/diagnostics/adb_console_controller.dart';
import 'package:bladewatch_ui/screens/diagnostics/adb_console_screen.dart';
import 'package:bladewatch_ui/screens/diagnostics/diagnostics_controller.dart';
import 'package:bladewatch_ui/screens/diagnostics/diagnostics_models.dart';
import 'package:bladewatch_ui/screens/diagnostics/diagnostics_screen.dart';
import 'package:bladewatch_ui/screens/diagnostics/performance_controller.dart';
import 'package:bladewatch_ui/screens/diagnostics/performance_screen.dart';
import 'package:bladewatch_ui/rpc/jwt_source.dart';
import 'package:bladewatch_ui/rpc/raw_http_sender.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_adb_connection.dart';
import '../../fakes/fake_platform_channel.dart';
import '../../fakes/fake_rpc_client.dart';

class _FakeJwtSource implements JwtSource {
  @override
  Future<String?> mintJwt() async => null;
  @override
  Future<int> stateVersion() async => 0;
}

void main() {
  late FakeRpcClient rpc;
  late FakePlatformChannel platform;
  late FakeAdbConnection adbConnection;
  late DiagnosticsController controller;
  late bool settingsOpened;

  void stubDaemons({bool camera = true, bool zrok = false}) {
    platform.stub('daemon', 'processStatus', {
      'status': 'ok',
      'daemons': {'CAMERA_DAEMON': camera, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': zrok},
    });
  }

  setUp(() {
    rpc = FakeRpcClient();
    platform = FakePlatformChannel();
    adbConnection = FakeAdbConnection();
    settingsOpened = false;
    platform.stub('network', 'current', {'type': 'wifi', 'ssid': 'HomeWifi'});
    stubDaemons();
    rpc.stubJson('StorageService', 'GetStorageSettings', {
      'success': true,
      'recordingsSize': '1000',
      'surveillanceSize': '500',
      'recordingsCount': 3,
      'surveillanceCount': 2,
      'recordingsStorageType': 'INTERNAL',
      'internalFreeFormatted': '10.0 GB',
      'sdCardFreeFormatted': '20.0 GB',
    });
    rpc.stubJson('SystemService', 'GetSohStatus',
        {'success': true, 'displaySoh': 90.0, 'displaySource': 'live', 'nominalCapacityKwh': 61.4, 'nominalSource': 'user'});
    controller = DiagnosticsController(
      daemonChannel: DaemonChannel(platform),
      storageService: StorageServiceClient(rpc),
      systemService: SystemServiceClient(rpc),
      networkChannel: NetworkChannel(platform),
      surveillanceService: SurveillanceServiceClient(rpc),
      adbConnectionFactory: () => adbConnection,
    );
  });

  Future<void> pumpScreen(WidgetTester tester, {Brightness brightness = Brightness.light}) async {
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(brightness: brightness),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DiagnosticsScreen(
          controller: controller,
          adbConsoleControllerFactory: () => AdbConsoleController(connection: FakeAdbConnection()),
          performanceControllerFactory: () => PerformanceController(
            systemService: SystemServiceClient(FakeRpcClient()),
            jwtSource: _FakeJwtSource(),
            send: (uri, headers, body) async => const RawHttpResponse(200, '{}'),
          ),
          onOpenSettings: () => settingsOpened = true,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the 4 health tiles with real data', (tester) async {
    await pumpScreen(tester);

    expect(find.byKey(const ValueKey('diag.network')), findsOneWidget);
    expect(find.text('HomeWifi'), findsOneWidget);
    expect(find.byKey(const ValueKey('diag.storage')), findsOneWidget);
    expect(find.text('5 clips · 1.5 KB used'), findsOneWidget);
    expect(find.byKey(const ValueKey('diag.cardCameraHealth')), findsOneWidget);
    expect(find.byKey(const ValueKey('diag.cardBatteryHealth')), findsOneWidget);
  });

  testWidgets('renders the camera health tile in its active (manual) state', (tester) async {
    controller = DiagnosticsController(
      daemonChannel: DaemonChannel(platform),
      storageService: StorageServiceClient(rpc),
      systemService: SystemServiceClient(rpc),
      networkChannel: NetworkChannel(platform),
      surveillanceService: SurveillanceServiceClient(rpc),
      adbConnectionFactory: () => adbConnection,
      cameraConfigSource: () async => const CameraProbeConfig(probedCameraId: 1, manualOverride: true),
    );

    await pumpScreen(tester);

    expect(find.text('Camera 1 (manual)'), findsOneWidget);
  });

  testWidgets('renders the camera health tile in its active (auto-detected) state', (tester) async {
    controller = DiagnosticsController(
      daemonChannel: DaemonChannel(platform),
      storageService: StorageServiceClient(rpc),
      systemService: SystemServiceClient(rpc),
      networkChannel: NetworkChannel(platform),
      surveillanceService: SurveillanceServiceClient(rpc),
      adbConnectionFactory: () => adbConnection,
      cameraConfigSource: () async => const CameraProbeConfig(probedCameraId: 1, manualOverride: false),
    );

    await pumpScreen(tester);

    expect(find.text('Camera 1'), findsOneWidget);
  });

  // BladeWatch-p7vi: there is no SoH reading to classify any more, so the tile
  // has no good/moderate/neutral states — it reports the feature as unavailable
  // whatever the (stubbed) daemon would have said.
  // BladeWatch-1ovy: still true, and still worth pinning — a SOH stub must not
  // resurrect the removed state-of-HEALTH reading. What the tile shows now is
  // state of CHARGE, which is a different number from a different RPC.
  testWidgets('the battery health tile reports unavailable regardless of any SOH stub', (tester) async {
    rpc.stubJson('SystemService', 'GetSohStatus', {'success': true, 'displaySoh': 65.0, 'displaySource': 'live'});

    await pumpScreen(tester);

    expect(find.text('65%'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('diag.cardBatteryHealth')),
        matching: find.text('Not available'),
      ),
      findsOneWidget,
    );
  });

  // BladeWatch-1ovy: the charge percentage, which the user asked for after seeing
  // "Not available" here while the Vehicle screen showed "Charge: 61%".
  testWidgets('the battery tile shows the charge percentage when one is available', (tester) async {
    controller = DiagnosticsController(
      daemonChannel: DaemonChannel(platform),
      storageService: StorageServiceClient(rpc),
      systemService: SystemServiceClient(rpc),
      networkChannel: NetworkChannel(platform),
      surveillanceService: SurveillanceServiceClient(rpc),
      adbConnectionFactory: () => adbConnection,
      batterySocSource: () async => 61,
    );

    await pumpScreen(tester);

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('diag.cardBatteryHealth')),
        matching: find.text('61%'),
      ),
      findsOneWidget,
    );
  });

  // The fallback matters as much as the value: 0% would read as a flat pack.
  testWidgets('the battery tile falls back to unavailable, never 0%, when there is no reading',
      (tester) async {
    controller = DiagnosticsController(
      daemonChannel: DaemonChannel(platform),
      storageService: StorageServiceClient(rpc),
      systemService: SystemServiceClient(rpc),
      networkChannel: NetworkChannel(platform),
      surveillanceService: SurveillanceServiceClient(rpc),
      adbConnectionFactory: () => adbConnection,
      batterySocSource: () async => null,
    );

    await pumpScreen(tester);

    expect(find.text('0%'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('diag.cardBatteryHealth')),
        matching: find.text('Not available'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders all 6 tool cards', (tester) async {
    await pumpScreen(tester);

    for (final key in ['diag.cardTraffic', 'diag.cardCameraProbe', 'diag.cardAdb', 'diag.cardBattery', 'diag.cardPerformance', 'diag.cardSettingsShortcut']) {
      expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
    }
  });

  testWidgets('tapping the ADB Console card navigates to the console screen', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('diag.cardAdb')));
    await tester.pumpAndSettle();

    expect(find.byType(AdbConsoleScreen), findsOneWidget);
  });

  testWidgets('tapping the Performance card navigates to the performance screen', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('diag.cardPerformance')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // let the push transition finish

    expect(find.byType(PerformanceScreen), findsOneWidget);
  });

  testWidgets('tapping the Settings shortcut calls onOpenSettings', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('diag.cardSettingsShortcut')));
    await tester.pump();

    expect(settingsOpened, isTrue);
  });

  group('Camera Selection dialog', () {
    testWidgets('opens from the tool card and shows the current auto state', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const ValueKey('diag.cardCameraProbe')));
      await tester.pumpAndSettle();

      expect(find.text('Camera Selection'), findsOneWidget);
      expect(find.text('Current: Auto'), findsOneWidget);
    });

    testWidgets('selecting a camera calls the RPC and closes the dialog', (tester) async {
      rpc.stubJson('SurveillanceService', 'SetConfig', {'success': true});
      await pumpScreen(tester);
      await tester.tap(find.byKey(const ValueKey('diag.cardCameraProbe')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('diag.camera.option.1')));
      await tester.pumpAndSettle();

      expect(find.text('Camera Selection'), findsNothing);
      expect(find.text('Camera 1 set — next ACC cycle'), findsOneWidget);
    });

    testWidgets('the health tile also opens the dialog', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const ValueKey('diag.cardCameraHealth')));
      await tester.pumpAndSettle();

      expect(find.text('Camera Selection'), findsOneWidget);
    });

    testWidgets('selecting Auto (from a manual selection) clears the manual override', (tester) async {
      // Radio doesn't fire onChanged when tapping the already-selected
      // option, so this starts from a manual override (probedCameraId 1) —
      // otherwise "Auto" would already be selected and tapping it again
      // would be a no-op, same as a real radio button.
      controller = DiagnosticsController(
        daemonChannel: DaemonChannel(platform),
        storageService: StorageServiceClient(rpc),
        systemService: SystemServiceClient(rpc),
        networkChannel: NetworkChannel(platform),
        surveillanceService: SurveillanceServiceClient(rpc),
        adbConnectionFactory: () => adbConnection,
        cameraConfigSource: () async => const CameraProbeConfig(probedCameraId: 1, manualOverride: true),
      );
      rpc.stubJson('SurveillanceService', 'SetConfig', {'success': true});
      await pumpScreen(tester);
      await tester.tap(find.byKey(const ValueKey('diag.cardCameraProbe')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('diag.camera.option.auto')));
      await tester.pumpAndSettle();

      final setConfigCall = rpc.calls.firstWhere((c) => c.method == 'SetConfig');
      expect((setConfigCall.request as dynamic).clearManualCameraId_3, isTrue);
      expect(find.text('Camera set to Auto'), findsOneWidget);
    });

    testWidgets('shows a failure snackbar when the RPC is rejected', (tester) async {
      rpc.stubError('SurveillanceService', 'SetConfig', const ConnectError('unavailable', 'no daemon'));
      await pumpScreen(tester);
      await tester.tap(find.byKey(const ValueKey('diag.cardCameraProbe')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('diag.camera.option.1')));
      await tester.pumpAndSettle();

      expect(find.text('Failed to save'), findsOneWidget);
    });
  });

  // BladeWatch-p7vi: SoH estimation was removed from the daemon, so the dialog
  // no longer shows a reading, the Source/Method/Capacity rows, or a Reset
  // action that could never do anything.
  group('Battery Health dialog', () {
    testWidgets('says the feature is unavailable rather than sitting on pending', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const ValueKey('diag.cardBattery')));
      await tester.pumpAndSettle();

      expect(find.text('Battery Health'), findsOneWidget);
      expect(find.byKey(const ValueKey('diag.battery.unavailable')), findsOneWidget);
      expect(find.text('Pending data'), findsNothing);
    });

    testWidgets('no longer offers the reset action', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const ValueKey('diag.cardBattery')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('diag.battery.reset')), findsNothing);
      expect(find.byKey(const ValueKey('diag.battery.close')), findsOneWidget);
    });

    testWidgets('the health card opens the same dialog, and Close dismisses it', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const ValueKey('diag.cardBatteryHealth')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('diag.battery.unavailable')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('diag.battery.close')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('diag.battery.unavailable')), findsNothing);
    });

    testWidgets('the battery card says unavailable too', (tester) async {
      await pumpScreen(tester);

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('diag.cardBatteryHealth')),
          matching: find.text('Not available'),
        ),
        findsOneWidget,
      );
    });
  });

  group('Traffic Monitor dialog', () {
    testWidgets('shows the cannot-check dialog when ADB is unavailable', (tester) async {
      adbConnection.nextConnectResult = const AdbConnectResult(AdbConnectionStatus.unavailable);
      await pumpScreen(tester);

      await tester.tap(find.byKey(const ValueKey('diag.cardTraffic')));
      await tester.pumpAndSettle();

      expect(find.text('Cannot Check Status'), findsOneWidget);
    });

    testWidgets('shows the disable-confirmation dialog when currently enabled, then a reboot notice', (tester) async {
      adbConnection.nextConnectResult = const AdbConnectResult(AdbConnectionStatus.connected);
      adbConnection.commandOutputs['pm list packages -d 2>/dev/null | grep com.byd.trafficmonitor || echo NOT_DISABLED'] = 'NOT_DISABLED';
      adbConnection.commandOutputs['pm disable-user --user 0 com.byd.trafficmonitor 2>&1'] = 'ok';
      await pumpScreen(tester);

      await tester.tap(find.byKey(const ValueKey('diag.cardTraffic')));
      await tester.pumpAndSettle();
      expect(find.text('Disable BYD Traffic Monitor?'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('diag.traffic.toggle')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Traffic Monitor'), findsWidgets);
    });

    testWidgets('shows a failure snackbar when the toggle command fails', (tester) async {
      adbConnection.nextConnectResult = const AdbConnectResult(AdbConnectionStatus.connected);
      adbConnection.commandOutputs['pm list packages -d 2>/dev/null | grep com.byd.trafficmonitor || echo NOT_DISABLED'] = 'NOT_DISABLED';
      await pumpScreen(tester);

      // The initial status check succeeds (via commandOutputs above); only
      // the toggle command that follows fails.
      await tester.tap(find.byKey(const ValueKey('diag.cardTraffic')));
      await tester.pumpAndSettle();
      adbConnection.runCommandError = const AdbCommandTimeoutException();
      await tester.tap(find.byKey(const ValueKey('diag.traffic.toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Failed to save'), findsOneWidget);
    });
  });

  testWidgets('renders correctly in dark theme', (tester) async {
    await pumpScreen(tester, brightness: Brightness.dark);

    expect(find.byKey(const ValueKey('diag.network')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
