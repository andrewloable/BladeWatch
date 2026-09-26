import 'package:bladewatch_ui/platform/daemon_channel.dart';
import 'package:bladewatch_rpc/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/trips_service_client.dart';
import 'package:bladewatch_ui/screens/dashboard/dashboard_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_platform_channel.dart';
import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';

void main() {
  late FakeRpcClient rpc;
  late FakePlatformChannel channel;

  DashboardController buildController() {
    return DashboardController(
      tripsService: TripsServiceClient(rpc),
      recordingsService: RecordingsServiceClient(rpc),
      systemService: SystemServiceClient(rpc),
      daemonChannel: DaemonChannel(channel),
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
      'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': true, 'ACC_SENTRY_DAEMON': false, 'PEAR_PEER': false},
    });
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
      expect(c.pear.running, isFalse);
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
        'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'PEAR_PEER': false},
      });
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
        'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'PEAR_PEER': false},
      });
      final c = buildController();

      await c.refresh();

      expect(c.tripStats.available, isFalse);
      expect(c.tripStats.loading, isFalse);
    });
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
      // MUST be YYYY-MM-DD, not YYYYMMDD. `RecordingsApiHandler.dateRangeMs`
      // (app/src/main/java/com/loabletech/bladewatch/server/RecordingsApiHandler.java:733)
      // splits on '-' and requires exactly 3 parts; anything else returns the
      // EMPTY range {0,0} rather than an error, so a wrongly-formatted date
      // yields a silent, plausible-looking 0. This test originally asserted
      // length 8 and so pinned the bug: on device the Dashboard read
      // "Today's recordings 0" while the Recordings screen said "37 today".
      expect(req.date, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
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
        'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'PEAR_PEER': false},
      });
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
        'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'PEAR_PEER': false},
      });
      final c = buildController();
      await c.refresh();
      expect(c.recordingsMetric.isRecording, isFalse);
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
      final c = buildController();

      await c.refresh();

      expect(c.daemonsSummary.running, 0);
      expect(c.daemonsSummary.total, 0);
      expect(c.daemonsSummary.loading, isFalse);
    });
  });

  group('refresh() — vehicle tile', () {
    // BladeWatch-p7vi: the tile reflects the selected MODEL. It used to read
    // GetSohNominal, a removed-feature stub that always answers "unset", so the
    // tile sat on "Tap to set" forever no matter what the user did.
    test('populates the selected model', () async {
      stubHappyPath();
      final c = buildController();

      await c.refresh();

      expect(c.vehicleTile.hasModel, isTrue);
      expect(c.vehicleTile.modelId, 'seal');
    });

    test('hasModel is false when no model has been selected', () async {
      rpc.stubJson('TripsService', 'ListTrips', {'success': true, 'trips': []});
      rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': [], 'total': 0});
      rpc.stubJson('SystemService', 'GetStatus', {'deviceId': 'd', 'recording': []});
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      channel.stub('daemon', 'processStatus', {
        'status': 'ok',
        'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'PEAR_PEER': false},
      });
      final c = buildController();

      await c.refresh();

      expect(c.vehicleTile.hasModel, isFalse);
    });

    test('does not call the removed SOH endpoint at all', () async {
      stubHappyPath();
      final c = buildController();

      await c.refresh();

      expect(rpc.calls.where((call) => call.method == 'GetSohNominal'), isEmpty);
    });
  });

  // BladeWatch-rdtj.17: the Remote access tile reads the Pear peer, read separately so a
  // failure there never blanks the rest of the Dashboard.
  group('refresh() — Pear peer', () {
    test('reads the Pear status', () async {
      stubHappyPath();
      channel.stub('daemon', 'pearStatus', {'running': true, 'enabled': true, 'reachable': true});
      final c = buildController();
      await c.refresh();
      expect(c.pear.running, isTrue);
      expect(c.pear.reachable, isTrue);
    });

    test('a pearStatus failure resolves to unknown rather than crashing refresh()', () async {
      stubHappyPath();
      channel.stubError('daemon', 'pearStatus', const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'down'));
      final c = buildController();
      await c.refresh();
      expect(c.pear.running, isFalse);
      expect(c.pear.reachable, isNull);
      expect(c.tripStats.available, isTrue);
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
