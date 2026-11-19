import 'package:bladewatch_rpc/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/trips_service_client.dart';
import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';
import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/platform/daemon_channel.dart';
import 'package:bladewatch_ui/screens/dashboard/dashboard_controller.dart';
import 'package:bladewatch_ui/screens/dashboard/dashboard_screen.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_platform_channel.dart';

/// BladeWatch-gklt.5: the Start Trip / Stop Trip button on the in-car dashboard.
void main() {
  late FakeRpcClient rpc;
  late FakePlatformChannel channel;

  DashboardController buildController() => DashboardController(
        tripsService: TripsServiceClient(rpc),
        recordingsService: RecordingsServiceClient(rpc),
        systemService: SystemServiceClient(rpc),
        daemonChannel: DaemonChannel(channel),
      );

  Map<String, dynamic> status({
    bool active = false,
    bool manual = false,
    int startMs = 0,
    double km = 0,
    bool liveCost = false,
    double electric = 0,
    double fuel = 0,
    bool hasFuel = false,
  }) => {
        'status': {
          'active': active,
          'manual': manual,
          'startTimeMs': '$startMs',
          'distanceKm': km,
          'liveCostAvailable': liveCost,
          'liveElectricCost': electric,
          'liveFuelCost': fuel,
          'liveCurrency': 'USD',
          'liveHasFuel': hasFuel,
        },
      };

  void stubBase() {
    rpc.stubJson('TripsService', 'ListTrips', {'success': true, 'trips': []});
    rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': [], 'total': 0});
    rpc.stubJson('SystemService', 'GetStatus', {'deviceId': 'byd-test'});
    rpc.stubJson('SystemService', 'GetSelectedModel', {'modelId': 'seal'});
    channel.stub('daemon', 'processStatus', {'status': 'ok', 'daemons': <String, bool>{}});
  }

  setUp(() {
    rpc = FakeRpcClient();
    channel = FakePlatformChannel();
  });

  group('controller', () {
    test('refreshDrive shows an open manual trip', () async {
      stubBase();
      rpc.stubJson('TripsService', 'GetActiveTrip', status(active: true, manual: true, startMs: 5000, km: 2.5));
      final c = buildController();

      await c.refreshDrive();

      expect(c.activeTrip.manual, isTrue);
      expect(c.activeTrip.startTimeMs.toInt(), 5000);
      expect(c.activeTrip.distanceKm, 2.5);
    });

    test('start sends StartManualTrip and takes the returned status', () async {
      stubBase();
      rpc.stubJson('TripsService', 'StartManualTrip', status(active: true, manual: true, startMs: 7000));
      final c = buildController();

      await c.toggleManualTrip();

      expect(rpc.calls.where((call) => call.method == 'StartManualTrip'), hasLength(1));
      expect(rpc.calls.where((call) => call.method == 'StopManualTrip'), isEmpty);
      expect(c.activeTrip.manual, isTrue);
      expect(c.tripError, isFalse);
      expect(c.tripBusy, isFalse);
    });

    test('stop sends StopManualTrip, then clears the status and reloads the week', () async {
      stubBase();
      rpc.stubJson('TripsService', 'GetActiveTrip', status(active: true, manual: true, startMs: 5000));
      rpc.stubJson('TripsService', 'StopManualTrip', {'success': true, 'stopped': true});
      final c = buildController();
      await c.refreshDrive();
      expect(c.activeTrip.manual, isTrue);

      rpc.stubJson('TripsService', 'GetActiveTrip', status());
      await c.toggleManualTrip();

      expect(rpc.calls.where((call) => call.method == 'StopManualTrip'), hasLength(1));
      expect(rpc.calls.where((call) => call.method == 'StartManualTrip'), isEmpty);
      expect(c.activeTrip.active, isFalse);
      expect(rpc.calls.where((call) => call.method == 'ListTrips'), isNotEmpty, reason: 'the new trip must show up');
    });

    test('a failed start keeps the previous state and raises the error', () async {
      stubBase();
      rpc.stubError('TripsService', 'StartManualTrip', const ConnectError('unavailable', 'down'));
      final c = buildController();

      await c.toggleManualTrip();

      expect(c.activeTrip.manual, isFalse);
      expect(c.tripError, isTrue);
      expect(c.tripBusy, isFalse);

      rpc.stubJson('TripsService', 'StartManualTrip', status(active: true, manual: true, startMs: 1));
      await c.toggleManualTrip();
      expect(c.tripError, isFalse, reason: 'the next attempt clears it');
    });

    test('a second tap while one is in flight is ignored', () async {
      stubBase();
      rpc.stubJson('TripsService', 'StartManualTrip', status(active: true, manual: true, startMs: 1));
      final c = buildController();

      final first = c.toggleManualTrip();
      final second = c.toggleManualTrip();
      await Future.wait([first, second]);

      expect(rpc.calls.where((call) => call.method == 'StartManualTrip'), hasLength(1));
    });

    test('a dropped GetActiveTrip keeps the shown status', () async {
      stubBase();
      rpc.stubJson('TripsService', 'GetActiveTrip', status(active: true, manual: true, startMs: 5000));
      final c = buildController();
      await c.refreshDrive();

      rpc.stubError('TripsService', 'GetActiveTrip', const ConnectError('unavailable', 'down'));
      await c.refreshDrive();

      expect(c.activeTrip.manual, isTrue);
    });
  });

  group('screen', () {
    Future<void> pump(WidgetTester tester, DashboardController c) async {
      tester.view.physicalSize = const Size(1400, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(MaterialApp(
        theme: BladeWatchTheme.light(),
        builder: (context, child) =>
            MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DashboardScreen(controller: c, systemService: SystemServiceClient(rpc), onNavigate: (_) {}),
      ));
      await tester.pumpAndSettle();
    }

    final button = find.byKey(const ValueKey('dashboard.manualTrip.button'));

    testWidgets('no trip: START TRIP, no detail line', (tester) async {
      stubBase();
      rpc.stubJson('TripsService', 'GetActiveTrip', status());
      final c = buildController();
      await pump(tester, c);

      expect(find.descendant(of: button, matching: find.text('START TRIP')), findsOneWidget);
      expect(find.byKey(const ValueKey('dashboard.manualTrip.detail')), findsNothing);
    });

    testWidgets('manual trip: STOP TRIP with the running time and distance', (tester) async {
      stubBase();
      final start = DateTime.now().millisecondsSinceEpoch - const Duration(minutes: 5, seconds: 7).inMilliseconds;
      rpc.stubJson('TripsService', 'GetActiveTrip', status(active: true, manual: true, startMs: start, km: 3.46));
      final c = buildController();
      await c.refreshDrive();
      await pump(tester, c);

      expect(find.descendant(of: button, matching: find.text('STOP TRIP')), findsOneWidget);
      final detail = tester.widget<Text>(find.byKey(const ValueKey('dashboard.manualTrip.detail'))).data!;
      expect(detail, contains('0:05:'));
      expect(detail, contains('3.5 km'));
    });

    testWidgets('auto trip only: START TRIP plus the hint that it will be ended', (tester) async {
      stubBase();
      rpc.stubJson('TripsService', 'GetActiveTrip', status(active: true, manual: false, startMs: 1));
      final c = buildController();
      await c.refreshDrive();
      await pump(tester, c);

      expect(find.descendant(of: button, matching: find.text('START TRIP')), findsOneWidget);
      final hint = tester.widget<Text>(find.byKey(const ValueKey('dashboard.manualTrip.detail'))).data!;
      expect(hint, contains('Auto trip'));
    });

    testWidgets('tapping the button toggles the trip, and it is disabled while busy', (tester) async {
      stubBase();
      rpc.stubJson('TripsService', 'GetActiveTrip', status());
      rpc.stubJson('TripsService', 'StartManualTrip', status(active: true, manual: true, startMs: 1));
      final c = buildController();
      await pump(tester, c);

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(rpc.calls.where((call) => call.method == 'StartManualTrip'), hasLength(1));
      expect(find.descendant(of: button, matching: find.text('STOP TRIP')), findsOneWidget);
    });

    testWidgets('the button is disabled while a start or stop is in flight', (tester) async {
      stubBase();
      rpc.stubJson('TripsService', 'GetActiveTrip', status());
      await pump(tester, _BusyController(rpc, channel));

      expect(tester.widget<FilledButton>(button).onPressed, isNull);
    });

    testWidgets('the button is enabled when idle', (tester) async {
      stubBase();
      rpc.stubJson('TripsService', 'GetActiveTrip', status());
      await pump(tester, buildController());

      expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    });

    final liveCost = find.byKey(const ValueKey('dashboard.manualTrip.liveCost'));

    // BladeWatch-reml live cost: what the open trip has cost so far, under the button.
    testWidgets('a running trip shows electricity, fuel and total so far', (tester) async {
      stubBase();
      rpc.stubJson('TripsService', 'GetActiveTrip',
          status(active: true, manual: true, startMs: DateTime.now().millisecondsSinceEpoch, liveCost: true, electric: 0.42, fuel: 1.10, hasFuel: true));
      final c = buildController();
      await c.refreshDrive();
      await pump(tester, c);

      expect(tester.widget<Text>(liveCost).data, 'So far: electricity \$0.42 · fuel \$1.10 · total \$1.52');
    });

    testWidgets('with no fuel price only the electricity is shown', (tester) async {
      stubBase();
      rpc.stubJson('TripsService', 'GetActiveTrip',
          status(active: true, manual: true, startMs: DateTime.now().millisecondsSinceEpoch, liveCost: true, electric: 0.42, hasFuel: false));
      final c = buildController();
      await c.refreshDrive();
      await pump(tester, c);

      expect(tester.widget<Text>(liveCost).data, 'So far: electricity \$0.42');
    });

    testWidgets('an auto trip shows its cost so far too', (tester) async {
      stubBase();
      rpc.stubJson('TripsService', 'GetActiveTrip',
          status(active: true, manual: false, startMs: 1, liveCost: true, electric: 0.10, fuel: 0.0, hasFuel: true));
      final c = buildController();
      await c.refreshDrive();
      await pump(tester, c);

      expect(liveCost, findsOneWidget);
    });

    testWidgets('no line when the cost is not available, or no trip is open', (tester) async {
      stubBase();
      rpc.stubJson('TripsService', 'GetActiveTrip', status(active: true, manual: true, startMs: 1, liveCost: false));
      final c = buildController();
      await c.refreshDrive();
      await pump(tester, c);
      expect(liveCost, findsNothing, reason: 'no rate configured: not a cost of zero');
    });

    testWidgets('no line with no trip', (tester) async {
      stubBase();
      rpc.stubJson('TripsService', 'GetActiveTrip', status());
      await pump(tester, buildController());
      expect(liveCost, findsNothing);
    });

    testWidgets('the button is at least 72 px tall', (tester) async {
      stubBase();
      rpc.stubJson('TripsService', 'GetActiveTrip', status());
      await pump(tester, buildController());

      expect(tester.getSize(button).height, greaterThanOrEqualTo(72));
    });

    testWidgets('a failed start shows the error under the button', (tester) async {
      stubBase();
      rpc.stubJson('TripsService', 'GetActiveTrip', status());
      rpc.stubError('TripsService', 'StartManualTrip', const ConnectError('unavailable', 'down'));
      final c = buildController();
      await pump(tester, c);

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('dashboard.manualTrip.error')), findsOneWidget);
      expect(find.descendant(of: button, matching: find.text('START TRIP')), findsOneWidget);
    });

    testWidgets('the button is the first block under the title', (tester) async {
      stubBase();
      rpc.stubJson('TripsService', 'GetActiveTrip', status());
      await pump(tester, buildController());

      final title = tester.getTopLeft(find.byKey(const ValueKey('dashboard.title'))).dy;
      final btn = tester.getTopLeft(button).dy;
      final stats = tester.getTopLeft(find.byKey(const ValueKey('tripStats.viewAll'))).dy;
      expect(btn, greaterThan(title));
      expect(btn, lessThan(stats));
    });
  });
}

/// A controller that always reports a start or stop in flight, to pin how the button looks then.
class _BusyController extends DashboardController {
  _BusyController(FakeRpcClient rpc, FakePlatformChannel channel)
      : super(
          tripsService: TripsServiceClient(rpc),
          recordingsService: RecordingsServiceClient(rpc),
          systemService: SystemServiceClient(rpc),
          daemonChannel: DaemonChannel(channel),
        );

  @override
  bool get tripBusy => true;
}
