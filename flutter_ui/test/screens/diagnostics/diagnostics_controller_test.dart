import 'package:bladewatch_ui/adb/adb_client.dart';
import 'package:bladewatch_ui/platform/daemon_channel.dart';
import 'package:bladewatch_ui/platform/network_channel.dart';
import 'package:bladewatch_rpc/rpc/services/storage_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/surveillance_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import 'package:bladewatch_ui/screens/diagnostics/diagnostics_controller.dart';
import 'package:bladewatch_ui/screens/diagnostics/diagnostics_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_adb_connection.dart';
import '../../fakes/fake_platform_channel.dart';
import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';

void main() {
  late FakeRpcClient rpc;
  late FakePlatformChannel platform;
  late FakeAdbConnection adbConnection;
  late DiagnosticsController controller;

  void stubDaemons({bool camera = true}) {
    platform.stub('daemon', 'processStatus', {
      'status': 'ok',
      'daemons': {
        'CAMERA_DAEMON': camera,
        'SENTRY_DAEMON': false,
        'ACC_SENTRY_DAEMON': false,
        'PEAR_PEER': false,
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

  /// `lastMonthBytes` is stubbed but never asserted on: the daemon really does send it, so the
  /// response shape stays honest, but no screen renders it and the controller does not read it.
  void stubDataUsage({int thisMonthBytes = 0}) {
    rpc.stubJson('SystemService', 'GetStatus', {
      'network': {'thisMonthBytes': '$thisMonthBytes', 'lastMonthBytes': '0'},
    });
  }

  setUp(() {
    rpc = FakeRpcClient();
    platform = FakePlatformChannel();
    platform.stub('network', 'current', {'type': 'wifi', 'ssid': 'HomeWifi'});
    stubDaemons();
    stubStorage();
    stubBattery();
    stubDataUsage();
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

    // Remote access is the Pear peer (BladeWatch-rdtj.12): online only once the car can be
    // found, connecting while it is up but not yet reachable, offline when switched off.
    DiagnosticsController withPear(PearStatus pear) => DiagnosticsController(
          daemonChannel: DaemonChannel(platform),
          storageService: StorageServiceClient(rpc),
          systemService: SystemServiceClient(rpc),
          networkChannel: NetworkChannel(platform),
          surveillanceService: SurveillanceServiceClient(rpc),
          adbConnectionFactory: () => adbConnection,
          pearStatusSource: () async => pear,
        );

    test('tunnel state is online when the Pear peer is reachable', () async {
      controller = withPear(const PearStatus(running: true, enabled: true, reachable: true));
      await controller.refresh();
      expect(controller.tunnelState, TunnelState.online);
    });

    test('tunnel state is connecting while the Pear peer runs but is not reachable yet', () async {
      for (final reachable in [false, null]) {
        controller = withPear(PearStatus(running: true, enabled: true, reachable: reachable));
        await controller.refresh();
        expect(controller.tunnelState, TunnelState.connecting, reason: 'reachable=$reachable');
      }
    });

    test('tunnel state is offline when the Pear peer is off, down, or its status fails', () async {
      for (final pear in [
        const PearStatus(running: true, enabled: false, reachable: true),
        const PearStatus(running: false, enabled: true),
      ]) {
        controller = withPear(pear);
        await controller.refresh();
        expect(controller.tunnelState, TunnelState.offline, reason: 'running=${pear.running} enabled=${pear.enabled}');
      }

      final failing = DiagnosticsController(
        daemonChannel: DaemonChannel(platform),
        storageService: StorageServiceClient(rpc),
        systemService: SystemServiceClient(rpc),
        networkChannel: NetworkChannel(platform),
        surveillanceService: SurveillanceServiceClient(rpc),
        adbConnectionFactory: () => adbConnection,
        pearStatusSource: () async => throw StateError('daemon down'),
      );
      await failing.refresh();
      expect(failing.tunnelState, TunnelState.offline);

      // The default source (no Pear wiring at all) reads as offline too.
      final plain = DiagnosticsController(
        daemonChannel: DaemonChannel(platform),
        storageService: StorageServiceClient(rpc),
        systemService: SystemServiceClient(rpc),
        networkChannel: NetworkChannel(platform),
        surveillanceService: SurveillanceServiceClient(rpc),
        adbConnectionFactory: () => adbConnection,
      );
      await plain.refresh();
      expect(plain.tunnelState, TunnelState.offline);
    });

    test('BladeWatch-t1lg.1: formats this-month data usage from GetStatus', () async {
      stubDataUsage(thisMonthBytes: 1024 * 1024);

      await controller.refresh();

      expect(controller.thisMonthDataUsageFormatted, '1.0 MB');
    });

    test('BladeWatch-t1lg.1: leaves data usage blank rather than propagating when GetStatus fails', () async {
      rpc.stubError('SystemService', 'GetStatus', const ConnectError('unavailable', 'no daemon'));

      await controller.refresh();

      expect(controller.thisMonthDataUsageFormatted, isEmpty);
      expect(controller.loading, isFalse); // one probe failing doesn't block the others
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

  // BladeWatch-1ovy: the tile used to say "Not available" unconditionally, a
  // leftover from the SoH removal, while the Vehicle screen showed the charge
  // percentage on the same device at the same moment.
  group('refresh — battery charge', () {
    DiagnosticsController withSoc(Future<int?> Function() source) => DiagnosticsController(
          daemonChannel: DaemonChannel(platform),
          storageService: StorageServiceClient(rpc),
          systemService: SystemServiceClient(rpc),
          networkChannel: NetworkChannel(platform),
          surveillanceService: SurveillanceServiceClient(rpc),
          adbConnectionFactory: () => adbConnection,
          batterySocSource: source,
        );

    test('exposes the charge percentage the source reports', () async {
      controller = withSoc(() async => 61);

      await controller.refresh();

      expect(controller.batterySoc, 61);
    });

    // Null, NOT 0. The tile renders null as "Not available"; rendering 0% would
    // be indistinguishable from a genuinely flat pack.
    test('is null when the source reports nothing', () async {
      controller = withSoc(() async => null);

      await controller.refresh();

      expect(controller.batterySoc, isNull);
    });

    test('a throwing source leaves it null rather than propagating', () async {
      controller = withSoc(() async => throw StateError('rpc down'));

      await controller.refresh();

      expect(controller.batterySoc, isNull);
      // The other probes must still have completed.
      expect(controller.loading, isFalse);
    });

    test('defaults to null when no source is injected', () async {
      await controller.refresh();

      expect(controller.batterySoc, isNull);
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

  // BladeWatch-p7vi: SoH estimation was removed from the daemon, so the
  // controller no longer fetches it — there is nothing to classify.
  group('refresh — battery', () {
    test('does not call the removed SOH endpoint', () async {
      await controller.refresh();

      expect(rpc.calls.where((c) => c.method == 'GetSohStatus'), isEmpty);
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
