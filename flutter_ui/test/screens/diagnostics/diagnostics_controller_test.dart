import 'package:bladewatch_ui/adb/adb_client.dart';
import 'package:bladewatch_ui/platform/daemon_channel.dart';
import 'package:bladewatch_ui/platform/network_channel.dart';
import 'package:bladewatch_ui/rpc/services/storage_service_client.dart';
import 'package:bladewatch_ui/rpc/services/surveillance_service_client.dart';
import 'package:bladewatch_ui/rpc/services/system_service_client.dart';
import 'package:bladewatch_ui/screens/diagnostics/diagnostics_controller.dart';
import 'package:bladewatch_ui/screens/diagnostics/diagnostics_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_adb_connection.dart';
import '../../fakes/fake_platform_channel.dart';
import '../../fakes/fake_rpc_client.dart';

void main() {
  late FakeRpcClient rpc;
  late FakePlatformChannel platform;
  late FakeAdbConnection adbConnection;
  late DiagnosticsController controller;

  void stubDaemons({bool camera = true, bool zrok = false}) {
    platform.stub('daemon', 'processStatus', {
      'status': 'ok',
      'daemons': {
        'CAMERA_DAEMON': camera,
        'SENTRY_DAEMON': false,
        'ACC_SENTRY_DAEMON': false,
        'ZROK_TUNNEL': zrok,
      },
    });
  }

  void stubStorage({
    int recordingsBytes = 1000,
    int surveillanceBytes = 500,
    int recordingsCount = 3,
    int surveillanceCount = 2,
    String storageType = 'INTERNAL',
  }) {
    rpc.stubJson('StorageService', 'GetStorageSettings', {
      'success': true,
      'recordingsSize': '$recordingsBytes',
      'surveillanceSize': '$surveillanceBytes',
      'recordingsCount': recordingsCount,
      'surveillanceCount': surveillanceCount,
      'recordingsStorageType': storageType,
      'internalFreeFormatted': '10.0 GB',
      'sdCardFreeFormatted': '20.0 GB',
    });
  }

  void stubBattery({
    bool success = true,
    double displaySoh = 90.0,
    String displaySource = 'live',
    double nominalCapacityKwh = 0,
    String nominalSource = '',
  }) {
    rpc.stubJson('SystemService', 'GetSohStatus', {
      'success': success,
      'displaySoh': displaySoh,
      'displaySource': displaySource,
      'nominalCapacityKwh': nominalCapacityKwh,
      'nominalSource': nominalSource,
    });
  }

  setUp(() {
    rpc = FakeRpcClient();
    platform = FakePlatformChannel();
    platform.stub('network', 'current', {'type': 'wifi', 'ssid': 'HomeWifi'});
    stubDaemons();
    stubStorage();
    stubBattery();
    adbConnection = FakeAdbConnection();
    controller = DiagnosticsController(
      daemonChannel: DaemonChannel(platform),
      storageService: StorageServiceClient(rpc),
      systemService: SystemServiceClient(rpc),
      networkChannel: NetworkChannel(platform),
      surveillanceService: SurveillanceServiceClient(rpc),
      adbConnectionFactory: () => adbConnection,
    );
  });

  test('starts in the loading state', () {
    expect(controller.loading, isTrue);
  });

  group('refresh — network tile', () {
    test('reports the SSID when connected to Wi-Fi', () async {
      await controller.refresh();

      expect(controller.networkType, NetworkType.wifi);
      expect(controller.ssid, 'HomeWifi');
    });

    test('reports mobile with no ssid', () async {
      platform.stub('network', 'current', {'type': 'mobile', 'ssid': null});

      await controller.refresh();

      expect(controller.networkType, NetworkType.mobile);
      expect(controller.ssid, isNull);
    });

    test('falls back to offline if the platform channel throws', () async {
      platform.stubError('network', 'current', const PlatformChannelError(PlatformChannelErrorReason.shellCallFailed, 'boom'));

      await controller.refresh();

      expect(controller.networkType, NetworkType.offline);
      expect(controller.loading, isFalse); // one probe failing doesn't block the others
    });

    test('tunnel state is online when a tunnel URL is present', () async {
      controller = DiagnosticsController(
        daemonChannel: DaemonChannel(platform),
        storageService: StorageServiceClient(rpc),
        systemService: SystemServiceClient(rpc),
        networkChannel: NetworkChannel(platform),
        surveillanceService: SurveillanceServiceClient(rpc),
        adbConnectionFactory: () => adbConnection,
        tunnelUrlSource: () async => 'https://example.zrok.io',
      );

      await controller.refresh();

      expect(controller.tunnelState, TunnelState.online);
    });

    test('tunnel state is connecting when no URL yet but the tunnel daemon is starting up', () async {
      // processStatus() only reports running/not-running, not STARTING — so
      // "connecting" here means the daemon is up (about to serve) but no URL
      // has been minted yet; still distinct from fully offline.
      stubDaemons(zrok: true);

      await controller.refresh();

      expect(controller.tunnelState, TunnelState.connecting);
    });

    test('tunnel state is offline with no URL and the tunnel daemon not running', () async {
      await controller.refresh();

      expect(controller.tunnelState, TunnelState.offline);
    });
  });

  group('refresh — storage tile', () {
    test('sums recordings and surveillance bytes/counts', () async {
      stubStorage(recordingsBytes: 1000, surveillanceBytes: 500, recordingsCount: 3, surveillanceCount: 2);

      await controller.refresh();

      expect(controller.storageClipCount, 5);
      expect(controller.storageUsedFormatted, isNotEmpty);
    });

    test('formats a sub-1KB total as whole bytes', () async {
      stubStorage(recordingsBytes: 100, surveillanceBytes: 0, recordingsCount: 1, surveillanceCount: 0);

      await controller.refresh();

      expect(controller.storageUsedFormatted, '100 B');
    });

    test('formats a multi-megabyte total with the right unit', () async {
      stubStorage(recordingsBytes: 5 * 1024 * 1024, surveillanceBytes: 0, recordingsCount: 1, surveillanceCount: 0);

      await controller.refresh();

      expect(controller.storageUsedFormatted, '5.0 MB');
    });

    test('uses the internal free-space string for INTERNAL storage', () async {
      stubStorage(storageType: 'INTERNAL');

      await controller.refresh();

      expect(controller.storageFreeFormatted, '10.0 GB');
    });

    test('uses the SD card free-space string for SD_CARD storage', () async {
      stubStorage(storageType: 'SD_CARD');

      await controller.refresh();

      expect(controller.storageFreeFormatted, '20.0 GB');
    });

    test('leaves storage at its honest zero default if the RPC fails', () async {
      rpc.stubError('StorageService', 'GetStorageSettings', const ConnectError('unavailable', 'no daemon'));

      await controller.refresh();

      expect(controller.storageClipCount, 0);
    });
  });

  group('refresh — camera tile', () {
    test('is offline when the camera daemon is not running, regardless of probe config', () async {
      stubDaemons(camera: false);

      await controller.refresh();

      expect(controller.cameraStatus, CameraTileStatus.offline);
    });

    test('is probing when the daemon is running but no camera has been probed yet (the honest injected default)', () async {
      stubDaemons(camera: true);

      await controller.refresh();

      expect(controller.cameraStatus, CameraTileStatus.probing);
    });

    test('is active with the probed id and manual flag when a real config source is injected', () async {
      stubDaemons(camera: true);
      controller = DiagnosticsController(
        daemonChannel: DaemonChannel(platform),
        storageService: StorageServiceClient(rpc),
        systemService: SystemServiceClient(rpc),
        networkChannel: NetworkChannel(platform),
        surveillanceService: SurveillanceServiceClient(rpc),
        adbConnectionFactory: () => adbConnection,
        cameraConfigSource: () async => const CameraProbeConfig(probedCameraId: 1, manualOverride: true),
      );

      await controller.refresh();

      expect(controller.cameraStatus, CameraTileStatus.active);
      expect(controller.cameraProbedId, 1);
      expect(controller.cameraManualOverride, isTrue);
    });
  });

  group('refresh — battery tile', () {
    test('is pending when the SOH RPC fails', () async {
      rpc.stubError('SystemService', 'GetSohStatus', const ConnectError('unavailable', 'no daemon'));

      await controller.refresh();

      expect(controller.batteryLevel, BatteryHealthLevel.pending);
      expect(controller.batterySohPercent, isNull);
    });

    test('is pending when success is false', () async {
      stubBattery(success: false);

      await controller.refresh();

      expect(controller.batteryLevel, BatteryHealthLevel.pending);
    });

    test('is pending when displaySoh is outside the accepted 60-110 band', () async {
      stubBattery(displaySoh: 40.0);

      await controller.refresh();

      expect(controller.batteryLevel, BatteryHealthLevel.pending);
    });

    test('is neutral when the source is "nominal", regardless of the percentage', () async {
      stubBattery(displaySoh: 95.0, displaySource: 'nominal');

      await controller.refresh();

      expect(controller.batteryLevel, BatteryHealthLevel.neutral);
      expect(controller.batterySohPercent, 95.0);
    });

    test('is good at 85% or above', () async {
      stubBattery(displaySoh: 85.0, displaySource: 'live');
      await controller.refresh();
      expect(controller.batteryLevel, BatteryHealthLevel.good);
    });

    test('is moderate between 60% (the lowest accepted reading) and 80%', () async {
      stubBattery(displaySoh: 65.0, displaySource: 'live');
      await controller.refresh();
      expect(controller.batteryLevel, BatteryHealthLevel.moderate);
    });

    test('is moderate at exactly the 60% acceptance floor', () async {
      stubBattery(displaySoh: 60.0, displaySource: 'oem');
      await controller.refresh();
      expect(controller.batteryLevel, BatteryHealthLevel.moderate);
    });

    test('captures nominal capacity, nominal source, and display source for the dialog', () async {
      stubBattery(displaySoh: 90.0, displaySource: 'live', nominalCapacityKwh: 61.4, nominalSource: 'user');

      await controller.refresh();

      expect(controller.batteryNominalCapacityKwh, 61.4);
      expect(controller.batteryNominalSource, 'user');
      expect(controller.batteryDisplaySource, 'live');
    });

    test('nominal capacity/source and display source are still captured when displaySoh is out of band', () async {
      stubBattery(displaySoh: 40.0, displaySource: 'oem', nominalCapacityKwh: 61.4, nominalSource: 'auto');

      await controller.refresh();

      expect(controller.batteryLevel, BatteryHealthLevel.pending);
      expect(controller.batteryNominalCapacityKwh, 61.4);
      expect(controller.batteryNominalSource, 'auto');
      expect(controller.batteryDisplaySource, 'oem');
    });

    test('nominal source defaults to "unset" and display source to "unavailable" when unset/failed', () async {
      stubBattery(success: false);

      await controller.refresh();

      expect(controller.batteryNominalSource, 'unset');
      expect(controller.batteryDisplaySource, 'unavailable');
    });

    test('resets nominal/display fields to their defaults when the RPC throws', () async {
      rpc.stubError('SystemService', 'GetSohStatus', const ConnectError('unavailable', 'no daemon'));

      await controller.refresh();

      expect(controller.batteryNominalCapacityKwh, 0);
      expect(controller.batteryNominalSource, 'unset');
      expect(controller.batteryDisplaySource, 'unavailable');
    });
  });

  test('refresh clears the loading flag and notifies listeners', () async {
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.refresh();

    expect(controller.loading, isFalse);
    expect(notifications, greaterThan(0));
  });

  group('selectCamera (Camera probe dialog)', () {
    test('setting a manual camera id sends manualCameraId and refreshes the camera tile', () async {
      stubDaemons(camera: true);
      rpc.stubJson('SurveillanceService', 'SetConfig', {'success': true});

      final ok = await controller.selectCamera(2);

      expect(ok, isTrue);
      final call = rpc.calls.single;
      expect(call.service, 'SurveillanceService');
      expect(call.method, 'SetConfig');
      expect((call.request as dynamic).manualCameraId, 2);
    });

    test('clearing back to auto sends clearManualCameraId', () async {
      stubDaemons(camera: true);
      rpc.stubJson('SurveillanceService', 'SetConfig', {'success': true});

      await controller.selectCamera(null);

      final call = rpc.calls.single;
      expect((call.request as dynamic).clearManualCameraId_3, isTrue);
    });

    test('returns false without throwing when the RPC fails', () async {
      rpc.stubError('SurveillanceService', 'SetConfig', const ConnectError('unavailable', 'no daemon'));

      final ok = await controller.selectCamera(1);

      expect(ok, isFalse);
    });
  });

  group('resetBattery (Battery health dialog)', () {
    test('calls ResetSoh and refreshes the battery tile on success', () async {
      stubBattery(displaySoh: 90.0, displaySource: 'live');
      rpc.stubJson('SystemService', 'ResetSoh', {'success': true});

      final ok = await controller.resetBattery();

      expect(ok, isTrue);
      expect(rpc.calls.map((c) => c.method), contains('ResetSoh'));
    });

    test('returns false without throwing when the RPC fails', () async {
      rpc.stubError('SystemService', 'ResetSoh', const ConnectError('unavailable', 'no daemon'));

      final ok = await controller.resetBattery();

      expect(ok, isFalse);
    });
  });

  group('traffic monitor (Traffic monitor dialog)', () {
    test('checkTrafficMonitorStatus reports enabled when the package is not in the disabled-packages list', () async {
      adbConnection.nextConnectResult = const AdbConnectResult(AdbConnectionStatus.connected);
      adbConnection.commandOutputs['pm list packages -d 2>/dev/null | grep com.byd.trafficmonitor || echo NOT_DISABLED'] =
          'NOT_DISABLED';

      await controller.checkTrafficMonitorStatus();

      expect(controller.trafficMonitorEnabled, isTrue);
    });

    test('checkTrafficMonitorStatus reports disabled when the package is in the disabled-packages list', () async {
      adbConnection.nextConnectResult = const AdbConnectResult(AdbConnectionStatus.connected);
      adbConnection.commandOutputs['pm list packages -d 2>/dev/null | grep com.byd.trafficmonitor || echo NOT_DISABLED'] =
          'package:com.byd.trafficmonitor';

      await controller.checkTrafficMonitorStatus();

      expect(controller.trafficMonitorEnabled, isFalse);
    });

    test('checkTrafficMonitorStatus leaves the state unknown (null) when ADB is unavailable', () async {
      adbConnection.nextConnectResult = const AdbConnectResult(AdbConnectionStatus.unavailable);

      await controller.checkTrafficMonitorStatus();

      expect(controller.trafficMonitorEnabled, isNull);
    });

    test('checkTrafficMonitorStatus leaves the state unknown (null) if the connection throws', () async {
      adbConnection.connectError = Exception('boom');

      await controller.checkTrafficMonitorStatus();

      expect(controller.trafficMonitorEnabled, isNull);
    });

    test('setTrafficMonitorEnabled(false) runs the disable command and updates state', () async {
      adbConnection.nextConnectResult = const AdbConnectResult(AdbConnectionStatus.connected);
      adbConnection.commandOutputs['pm disable-user --user 0 com.byd.trafficmonitor 2>&1'] = 'ok';

      final ok = await controller.setTrafficMonitorEnabled(false);

      expect(ok, isTrue);
      expect(controller.trafficMonitorEnabled, isFalse);
    });

    test('setTrafficMonitorEnabled(true) runs the enable command and updates state', () async {
      adbConnection.nextConnectResult = const AdbConnectResult(AdbConnectionStatus.connected);
      adbConnection.commandOutputs['pm enable com.byd.trafficmonitor 2>&1'] = 'ok';

      final ok = await controller.setTrafficMonitorEnabled(true);

      expect(ok, isTrue);
      expect(controller.trafficMonitorEnabled, isTrue);
    });

    test('setTrafficMonitorEnabled returns false without throwing when ADB is unavailable', () async {
      adbConnection.nextConnectResult = const AdbConnectResult(AdbConnectionStatus.unavailable);

      final ok = await controller.setTrafficMonitorEnabled(true);

      expect(ok, isFalse);
    });
  });
}
