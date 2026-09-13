import 'package:bladewatch_ui/platform/auth_channel.dart';
import 'package:bladewatch_ui/platform/daemon_channel.dart';
import 'package:bladewatch_ui/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_ui/rpc/services/system_service_client.dart';
import 'package:bladewatch_ui/rpc/services/trips_service_client.dart';
import 'package:bladewatch_ui/screens/dashboard/dashboard_controller.dart';
import 'package:bladewatch_ui/screens/dashboard/dashboard_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_platform_channel.dart';
import '../../fakes/fake_rpc_client.dart';

void main() {
  late FakeRpcClient rpc;
  late FakePlatformChannel channel;

  DashboardController buildController({Future<String?> Function()? tunnelUrlSource}) {
    return DashboardController(
      tripsService: TripsServiceClient(rpc),
      recordingsService: RecordingsServiceClient(rpc),
      systemService: SystemServiceClient(rpc),
      daemonChannel: DaemonChannel(channel),
      authChannel: AuthChannel(channel),
      tunnelUrlSource: tunnelUrlSource ?? () async => null,
    );
  }

  void stubHappyPath() {
    rpc.stubJson('TripsService', 'ListTrips', {
      'success': true,
      'trips': [
        {'id': '1', 'distanceKm': 9.0, 'durationSeconds': 780},
        {'id': '2', 'distanceKm': 3.2, 'durationSeconds': 300},
      ],
    });
    rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': [], 'total': 4});
    rpc.stubJson('SystemService', 'GetStatus', {'deviceId': 'byd-test', 'recording': [1]});
    rpc.stubJson('SystemService', 'GetSohNominal', {'nominalKwh': 82.5, 'nominalSource': 'user'});
    rpc.stubJson('SystemService', 'GetSelectedModel', {'modelId': 'seal'});
    channel.stub('daemon', 'processStatus', {
      'status': 'ok',
      'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': true, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': false},
    });
    channel.stub('auth', 'getAccessCode', 'shh-fake-secret');
  }

  setUp(() {
    rpc = FakeRpcClient();
    channel = FakePlatformChannel();
  });

  group('initial state', () {
    test('everything starts in a loading state', () {
      final c = buildController();
      expect(c.tripStats.loading, isTrue);
      expect(c.recordingsMetric.loading, isTrue);
      expect(c.daemonsSummary.loading, isTrue);
      expect(c.vehicleTile.loading, isTrue);
      expect(c.accessCode.loading, isTrue);
      expect(c.tunnel.phase, TunnelPhase.offline);
    });
  });

  group('refresh() — trip stats', () {
    test('populates trip count, distance, and drive time from ListTrips', () async {
      stubHappyPath();
      final c = buildController();

      await c.refresh();

      expect(c.tripStats.loading, isFalse);
      expect(c.tripStats.available, isTrue);
      expect(c.tripStats.tripCount, 2);
      expect(c.tripStats.totalDistanceKm, closeTo(12.2, 0.001));
      expect(c.tripStats.totalDurationSeconds, 1080);
    });

    test('sends days=7, limit=100 matching the native ListTripsRequest', () async {
      stubHappyPath();
      final c = buildController();
      await c.refresh();

      final call = rpc.calls.firstWhere((c) => c.method == 'ListTrips');
      final req = call.request as dynamic;
      expect(req.days, 7);
      expect(req.limit, 100);
    });

    test('zero trips is a distinct state from unavailable', () async {
      rpc.stubJson('TripsService', 'ListTrips', {'success': true, 'trips': []});
      rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': [], 'total': 0});
      rpc.stubJson('SystemService', 'GetStatus', {'deviceId': 'd', 'recording': []});
      rpc.stubJson('SystemService', 'GetSohNominal', {});
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      channel.stub('daemon', 'processStatus', {
        'status': 'ok',
        'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': false},
      });
      channel.stub('auth', 'getAccessCode', null);
      final c = buildController();

      await c.refresh();

      expect(c.tripStats.available, isTrue);
      expect(c.tripStats.tripCount, 0);
    });

    test('an RPC failure leaves trip stats unavailable rather than crashing refresh()', () async {
      rpc.stubError('TripsService', 'ListTrips', const ConnectError('unavailable', 'daemon down'));
      rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': [], 'total': 0});
      rpc.stubJson('SystemService', 'GetStatus', {'deviceId': 'd', 'recording': []});
      rpc.stubJson('SystemService', 'GetSohNominal', {});
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      channel.stub('daemon', 'processStatus', {
        'status': 'ok',
        'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': false},
      });
      channel.stub('auth', 'getAccessCode', null);
      final c = buildController();

      await c.refresh();

      expect(c.tripStats.available, isFalse);
      expect(c.tripStats.loading, isFalse);
    });
  });

  test('the true default tunnelUrlSource (no constructor argument) reports no tunnel', () async {
    stubHappyPath();
    final c = DashboardController(
      tripsService: TripsServiceClient(rpc),
      recordingsService: RecordingsServiceClient(rpc),
      systemService: SystemServiceClient(rpc),
      daemonChannel: DaemonChannel(channel),
      authChannel: AuthChannel(channel),
    );

    await c.refresh();

    expect(c.tunnel.phase, TunnelPhase.offline);
  });

  group('refresh() — recordings metric', () {
    test("today's count comes from ListRecordings(date: today).total, not a local scan", () async {
      stubHappyPath();
      final c = buildController();

      await c.refresh();

      expect(c.recordingsMetric.todayCount, 4);
      final call = rpc.calls.firstWhere((c) => c.method == 'ListRecordings');
      final req = call.request as dynamic;
      expect(req.date, isNotEmpty);
      expect(req.date.length, 8); // YYYYMMDD
    });

    test('isRecording reflects GetStatus().recording being non-empty', () async {
      stubHappyPath(); // recording: [1]
      final c = buildController();
      await c.refresh();
      expect(c.recordingsMetric.isRecording, isTrue);
    });

    test('a ListRecordings failure leaves the count at 0 but keeps isRecording from GetStatus', () async {
      rpc.stubJson('TripsService', 'ListTrips', {'success': true, 'trips': []});
      rpc.stubError('RecordingsService', 'ListRecordings', const ConnectError('unavailable', 'down'));
      rpc.stubJson('SystemService', 'GetStatus', {'deviceId': 'd', 'recording': [1]});
      rpc.stubJson('SystemService', 'GetSohNominal', {});
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      channel.stub('daemon', 'processStatus', {
        'status': 'ok',
        'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': false},
      });
      channel.stub('auth', 'getAccessCode', null);
      final c = buildController();

      await c.refresh();

      expect(c.recordingsMetric.todayCount, 0);
      expect(c.recordingsMetric.isRecording, isTrue);
      expect(c.recordingsMetric.loading, isFalse);
    });

    test('isRecording is false when no cameras are recording', () async {
      rpc.stubJson('TripsService', 'ListTrips', {'success': true, 'trips': []});
      rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': [], 'total': 0});
      rpc.stubJson('SystemService', 'GetStatus', {'deviceId': 'd', 'recording': []});
      rpc.stubJson('SystemService', 'GetSohNominal', {});
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      channel.stub('daemon', 'processStatus', {
        'status': 'ok',
        'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': false},
      });
      channel.stub('auth', 'getAccessCode', null);
      final c = buildController();
      await c.refresh();
      expect(c.recordingsMetric.isRecording, isFalse);
    });
  });

  group('refresh() — device id', () {
    test('populates from GetStatus().deviceId, for the Connect card', () async {
      stubHappyPath(); // deviceId: 'byd-test'
      final c = buildController();

      await c.refresh();

      expect(c.deviceId, 'byd-test');
    });

    test('stays null when GetStatus omits deviceId', () async {
      rpc.stubJson('TripsService', 'ListTrips', {'success': true, 'trips': []});
      rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': [], 'total': 0});
      rpc.stubJson('SystemService', 'GetStatus', {'recording': []});
      rpc.stubJson('SystemService', 'GetSohNominal', {});
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      channel.stub('daemon', 'processStatus', {
        'status': 'ok',
        'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': false},
      });
      channel.stub('auth', 'getAccessCode', null);
      final c = buildController();

      await c.refresh();

      expect(c.deviceId, isNull);
    });

    test('stays null when GetStatus fails entirely', () async {
      rpc.stubJson('TripsService', 'ListTrips', {'success': true, 'trips': []});
      rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': [], 'total': 0});
      rpc.stubError('SystemService', 'GetStatus', const ConnectError('unavailable', 'down'));
      rpc.stubJson('SystemService', 'GetSohNominal', {});
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      channel.stub('daemon', 'processStatus', {
        'status': 'ok',
        'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': false},
      });
      channel.stub('auth', 'getAccessCode', null);
      final c = buildController();

      await c.refresh();

      expect(c.deviceId, isNull);
    });
  });

  group('refresh() — daemons summary', () {
    test('counts running vs total from daemon.processStatus', () async {
      stubHappyPath(); // 2 of 4 running
      final c = buildController();

      await c.refresh();

      expect(c.daemonsSummary.running, 2);
      expect(c.daemonsSummary.total, 4);
    });

    test('a daemon.processStatus channel failure leaves the summary at 0/0 rather than crashing', () async {
      rpc.stubJson('TripsService', 'ListTrips', {'success': true, 'trips': []});
      rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': [], 'total': 0});
      rpc.stubJson('SystemService', 'GetStatus', {'deviceId': 'd', 'recording': []});
      rpc.stubJson('SystemService', 'GetSohNominal', {});
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      channel.stubError(
        'daemon',
        'processStatus',
        const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'down'),
      );
      channel.stub('auth', 'getAccessCode', null);
      final c = buildController();

      await c.refresh();

      expect(c.daemonsSummary.running, 0);
      expect(c.daemonsSummary.total, 0);
      expect(c.daemonsSummary.loading, isFalse);
    });
  });

  group('refresh() — vehicle tile', () {
    test('populates nominal capacity and model when both are set', () async {
      stubHappyPath();
      final c = buildController();

      await c.refresh();

      expect(c.vehicleTile.hasCapacity, isTrue);
      expect(c.vehicleTile.nominalKwh, closeTo(82.5, 0.001));
      expect(c.vehicleTile.modelId, 'seal');
    });

    test('hasCapacity is false when no nominal kWh has ever been set', () async {
      rpc.stubJson('TripsService', 'ListTrips', {'success': true, 'trips': []});
      rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': [], 'total': 0});
      rpc.stubJson('SystemService', 'GetStatus', {'deviceId': 'd', 'recording': []});
      rpc.stubJson('SystemService', 'GetSohNominal', {}); // nominalKwh absent (optional, unset)
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      channel.stub('daemon', 'processStatus', {
        'status': 'ok',
        'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': false},
      });
      channel.stub('auth', 'getAccessCode', null);
      final c = buildController();

      await c.refresh();

      expect(c.vehicleTile.hasCapacity, isFalse);
    });
  });

  group('refresh() — tunnel', () {
    test('defaults to offline (no IPC source exists yet — BladeWatch-m1po)', () async {
      stubHappyPath();
      final c = buildController();
      await c.refresh();
      expect(c.tunnel.phase, TunnelPhase.offline);
      expect(c.tunnel.url, isNull);
    });

    test('reports online when the injected tunnelUrlSource returns a URL', () async {
      stubHappyPath();
      final c = buildController(tunnelUrlSource: () async => 'https://example.zrok.io');
      await c.refresh();
      expect(c.tunnel.phase, TunnelPhase.online);
      expect(c.tunnel.url, 'https://example.zrok.io');
    });

    test('a tunnelUrlSource that throws resolves to offline rather than crashing refresh()', () async {
      stubHappyPath();
      final c = buildController(tunnelUrlSource: () async => throw Exception('boom'));
      await c.refresh();
      expect(c.tunnel.phase, TunnelPhase.offline);
      expect(c.tunnel.url, isNull);
    });
  });

  group('access code', () {
    test('refresh() loads the access code, masked by default', () async {
      stubHappyPath();
      final c = buildController();
      await c.refresh();

      expect(c.accessCode.loading, isFalse);
      expect(c.accessCode.secret, 'shh-fake-secret');
      expect(c.accessCode.visible, isFalse);
      expect(c.accessCode.displayValue, isNull);
    });

    test('toggleAccessCodeVisibility() flips visible and notifies', () async {
      stubHappyPath();
      final c = buildController();
      await c.refresh();
      var notified = 0;
      c.addListener(() => notified++);

      c.toggleAccessCodeVisibility();

      expect(c.accessCode.visible, isTrue);
      expect(c.accessCode.displayValue, 'shh-fake-secret');
      expect(notified, 1);
    });

    test('toggleAccessCodeVisibility() twice returns to masked', () async {
      stubHappyPath();
      final c = buildController();
      await c.refresh();

      c.toggleAccessCodeVisibility();
      c.toggleAccessCodeVisibility();

      expect(c.accessCode.visible, isFalse);
    });

    test('regenerateAccessCode() replaces the stored secret on success', () async {
      stubHappyPath();
      channel.stub('auth', 'regenerateAccessCode', 'new-code-value');
      final c = buildController();
      await c.refresh();

      final ok = await c.regenerateAccessCode();

      expect(ok, isTrue);
      expect(c.accessCode.secret, 'new-code-value');
    });

    test('regenerateAccessCode() returns false and keeps the old secret when the daemon rejects it', () async {
      stubHappyPath();
      channel.stub('auth', 'regenerateAccessCode', null);
      final c = buildController();
      await c.refresh();

      final ok = await c.regenerateAccessCode();

      expect(ok, isFalse);
      expect(c.accessCode.secret, 'shh-fake-secret');
    });

    test('setCustomAccessCode() rejects a password shorter than 12 chars without an IPC call', () async {
      stubHappyPath();
      final c = buildController();
      await c.refresh();

      final ok = await c.setCustomAccessCode('short');

      expect(ok, isFalse);
      expect(channel.calls.where((call) => call.method == 'setCustomAccessCode'), isEmpty);
    });

    test('setCustomAccessCode() persists a valid password and updates state on success', () async {
      stubHappyPath();
      channel.stub('auth', 'setCustomAccessCode', true);
      final c = buildController();
      await c.refresh();

      final ok = await c.setCustomAccessCode('my-custom-password-1');

      expect(ok, isTrue);
      expect(c.accessCode.secret, 'my-custom-password-1');
    });

    test('setCustomAccessCode() returns false and keeps the old secret when the daemon rejects it', () async {
      stubHappyPath();
      channel.stub('auth', 'setCustomAccessCode', false);
      final c = buildController();
      await c.refresh();

      final ok = await c.setCustomAccessCode('my-custom-password-1');

      expect(ok, isFalse);
      expect(c.accessCode.secret, 'shh-fake-secret');
    });

    test('a channel error while loading the access code leaves it unavailable, not crashed', () async {
      rpc.stubJson('TripsService', 'ListTrips', {'success': true, 'trips': []});
      rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': [], 'total': 0});
      rpc.stubJson('SystemService', 'GetStatus', {'deviceId': 'd', 'recording': []});
      rpc.stubJson('SystemService', 'GetSohNominal', {});
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      channel.stub('daemon', 'processStatus', {
        'status': 'ok',
        'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': false},
      });
      channel.stubError(
        'auth',
        'getAccessCode',
        const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'down'),
      );
      final c = buildController();

      await c.refresh();

      expect(c.accessCode.loading, isFalse);
      expect(c.accessCode.secret, isNull);
    });
  });

  test('refresh() notifies listeners exactly once even though it makes many calls', () async {
    stubHappyPath();
    final c = buildController();
    var notified = 0;
    c.addListener(() => notified++);

    await c.refresh();

    expect(notified, 1);
  });
}
