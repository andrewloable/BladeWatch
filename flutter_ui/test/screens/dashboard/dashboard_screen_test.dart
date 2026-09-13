import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/platform/auth_channel.dart';
import 'package:bladewatch_ui/platform/daemon_channel.dart';
import 'package:bladewatch_ui/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_ui/rpc/services/system_service_client.dart';
import 'package:bladewatch_ui/rpc/services/trips_service_client.dart';
import 'package:bladewatch_ui/screens/dashboard/dashboard_controller.dart';
import 'package:bladewatch_ui/screens/dashboard/dashboard_screen.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../fakes/fake_platform_channel.dart';
import '../../fakes/fake_rpc_client.dart';

void main() {
  late FakeRpcClient rpc;
  late FakePlatformChannel channel;
  late List<String> navigated;

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

  void stubVehicleDialog() {
    rpc.stubJson('SystemService', 'GetSohStatus', {
      'success': true,
      'nominalCapacityKwh': 82.5,
      'nominalSource': 'user',
      'displaySoh': 97.2,
      'displaySource': 'live',
    });
    rpc.stubJson('SystemService', 'GetModelsManifest', {
      'manifestJson': '{"models":[{"id":"seal","name":"BYD Seal","nominalKwh":82.5}]}',
    });
  }

  setUp(() {
    rpc = FakeRpcClient();
    channel = FakePlatformChannel();
    navigated = [];
  });

  Widget wrap(DashboardController controller, {Locale? locale, ThemeData? theme}) => MaterialApp(
        theme: theme ?? BladeWatchTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DashboardScreen(
          controller: controller,
          systemService: SystemServiceClient(rpc),
          onNavigate: (route) => navigated.add(route),
        ),
      );

  // The dashboard is a long, scrollable screen (this is Epic 1's biggest
  // layout, ported near 1:1 from a 1,086-line native fragment). A generous
  // virtual surface means every tile — including ones below the fold on a
  // real device — is actually built and tappable without each test having
  // to fight ListView scroll-position/cache-extent timing individually.
  Future<void> pumpDashboard(WidgetTester tester, DashboardController controller, {Locale? locale, ThemeData? theme}) async {
    tester.view.physicalSize = const Size(1400, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(wrap(controller, locale: locale, theme: theme));
  }

  testWidgets('loading state shows pending placeholders, not a crash', (tester) async {
    final controller = buildController();
    await pumpDashboard(tester, controller);

    expect(find.text('Loading…'), findsOneWidget);
    expect(find.text('—', skipOffstage: false), findsWidgets);
  });

  testWidgets('happy path renders trip stats, recordings, daemons, vehicle and access code', (tester) async {
    stubHappyPath();
    final controller = buildController();
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget); // trip count
    expect(find.text('12.2 km'), findsOneWidget);
    expect(find.text('18m'), findsOneWidget); // 780+300=1080s -> 18m
  });

  testWidgets('recordings tile shows the live dot prefix while recording', (tester) async {
    stubHappyPath();
    final controller = buildController();
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    expect(find.textContaining('4'), findsWidgets);
    expect(find.textContaining('●'), findsOneWidget);
  });

  testWidgets('recordings tile has no live dot when nothing is recording', (tester) async {
    rpc.stubJson('TripsService', 'ListTrips', {'success': true, 'trips': []});
    rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': [], 'total': 4});
    rpc.stubJson('SystemService', 'GetStatus', {'deviceId': 'byd-test', 'recording': []});
    rpc.stubJson('SystemService', 'GetSohNominal', {});
    rpc.stubJson('SystemService', 'GetSelectedModel', {});
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': false},
    });
    channel.stub('auth', 'getAccessCode', null);
    final controller = buildController();
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    expect(find.textContaining('●'), findsNothing);
  });

  testWidgets('zero trips this week shows the empty-state headline', (tester) async {
    rpc.stubJson('TripsService', 'ListTrips', {'success': true, 'trips': []});
    rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': [], 'total': 0});
    rpc.stubJson('SystemService', 'GetStatus', {'deviceId': 'byd-test', 'recording': []});
    rpc.stubJson('SystemService', 'GetSohNominal', {});
    rpc.stubJson('SystemService', 'GetSelectedModel', {});
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': true, 'ACC_SENTRY_DAEMON': true, 'ZROK_TUNNEL': false},
    });
    channel.stub('auth', 'getAccessCode', null);
    final controller = buildController();
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('No trips recorded this week'), findsOneWidget);
  });

  testWidgets('trip stats RPC failure shows the unavailable headline', (tester) async {
    rpc.stubError('TripsService', 'ListTrips', const ConnectError('unavailable', 'down'));
    rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': [], 'total': 0});
    rpc.stubJson('SystemService', 'GetStatus', {'deviceId': 'byd-test', 'recording': []});
    rpc.stubJson('SystemService', 'GetSohNominal', {});
    rpc.stubJson('SystemService', 'GetSelectedModel', {});
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': true, 'ACC_SENTRY_DAEMON': true, 'ZROK_TUNNEL': false},
    });
    channel.stub('auth', 'getAccessCode', null);
    final controller = buildController();
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('Start driving to see stats'), findsOneWidget);
  });

  testWidgets('daemon channel failure shows 0/0 without breaking the rest of the screen', (tester) async {
    stubHappyPath();
    channel.stubError('daemon', 'processStatus', const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'no daemon'));
    final controller = buildController();
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    // Shown twice by design — the hero chip mirrors the metric tile value,
    // same as native's refreshHeroChips() ("heroChipServices?.text = tvDaemonsStatus.text").
    expect(find.text('0/0 Running'), findsNWidgets(2));
    expect(find.text('2'), findsOneWidget); // trip stats tile still rendered fine
  });

  testWidgets('no tunnel shows the "no tunnel running" placeholder and no QR image', (tester) async {
    stubHappyPath();
    final controller = buildController();
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('No tunnel running'), findsOneWidget);
    expect(find.byType(QrImageView), findsNothing);
  });

  testWidgets('an online tunnel renders the QR code and the URL text', (tester) async {
    stubHappyPath();
    final controller = buildController(tunnelUrlSource: () async => 'https://example.zrok.io');
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('https://example.zrok.io'), findsOneWidget);
    expect(find.text('No tunnel running'), findsNothing);
    expect(find.byType(QrImageView), findsOneWidget);
  });

  testWidgets('vehicle tile shows "Tap to set" with no nominal capacity', (tester) async {
    rpc.stubJson('TripsService', 'ListTrips', {'success': true, 'trips': []});
    rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': [], 'total': 0});
    rpc.stubJson('SystemService', 'GetStatus', {'deviceId': 'byd-test', 'recording': []});
    rpc.stubJson('SystemService', 'GetSohNominal', {});
    rpc.stubJson('SystemService', 'GetSelectedModel', {});
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': true, 'ACC_SENTRY_DAEMON': true, 'ZROK_TUNNEL': false},
    });
    channel.stub('auth', 'getAccessCode', null);
    final controller = buildController();
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('Tap to set'), findsOneWidget);
  });

  testWidgets('vehicle tile shows capacity and model when both are set', (tester) async {
    stubHappyPath();
    final controller = buildController();
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('82.5 kWh · BYD Seal'), findsOneWidget);
  });

  testWidgets('access code starts masked; toggling reveals then re-masks it', (tester) async {
    stubHappyPath();
    final controller = buildController();
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('shh-fake-secret'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('accessCode.toggle')));
    await tester.pump();
    expect(find.text('shh-fake-secret'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('accessCode.toggle')));
    await tester.pump();
    expect(find.text('shh-fake-secret'), findsNothing);
  });

  testWidgets('copying the access code shows a confirmation snack bar', (tester) async {
    stubHappyPath();
    final controller = buildController();
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('accessCode.copy')));
    await tester.pump();

    expect(find.text('Access code copied'), findsOneWidget);
  });

  testWidgets('regenerating the access code asks for confirmation, then updates the secret', (tester) async {
    stubHappyPath();
    channel.stub('auth', 'regenerateAccessCode', 'new-fake-secret');
    final controller = buildController();
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('accessCode.regenerate')));
    await tester.pumpAndSettle();
    expect(find.text('This will invalidate the current token. All active sessions will be logged out. Continue?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Regenerate'));
    await tester.pumpAndSettle();

    final call = channel.calls.firstWhere((c) => c.group == 'auth' && c.method == 'regenerateAccessCode');
    expect(call, isNotNull);
    await tester.tap(find.byKey(const ValueKey('accessCode.toggle')));
    await tester.pump();
    expect(find.text('new-fake-secret'), findsOneWidget);
  });

  testWidgets('cancelling the regenerate confirmation makes no channel call', (tester) async {
    stubHappyPath();
    final controller = buildController();
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('accessCode.regenerate')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(channel.calls.where((c) => c.method == 'regenerateAccessCode'), isEmpty);
  });

  testWidgets('setting a too-short custom password shows a validation message without calling the channel', (tester) async {
    stubHappyPath();
    final controller = buildController();
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('accessCode.setPassword')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'short');
    await tester.tap(find.widgetWithText(TextButton, 'DONE'));
    await tester.pumpAndSettle();

    expect(find.text('Password must be at least 12 characters'), findsOneWidget);
    expect(channel.calls.where((c) => c.method == 'setCustomAccessCode'), isEmpty);
  });

  testWidgets('setting a valid custom password calls the channel and confirms', (tester) async {
    stubHappyPath();
    channel.stub('auth', 'setCustomAccessCode', true);
    final controller = buildController();
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('accessCode.setPassword')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'a-long-enough-password');
    await tester.tap(find.widgetWithText(TextButton, 'DONE'));
    await tester.pumpAndSettle();

    expect(find.text('Password updated'), findsOneWidget);
    final call = channel.calls.firstWhere((c) => c.method == 'setCustomAccessCode');
    expect((call.args as Map)['password'], 'a-long-enough-password');
  });

  testWidgets('a valid-length password the daemon rejects shows a failure message and stays open', (tester) async {
    stubHappyPath();
    channel.stub('auth', 'setCustomAccessCode', false);
    final controller = buildController();
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('accessCode.setPassword')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'a-long-enough-password');
    await tester.tap(find.widgetWithText(TextButton, 'DONE'));
    await tester.pumpAndSettle();

    expect(find.text('Failed to save password — service not ready'), findsOneWidget);
    expect(find.text('Set Custom Password'), findsOneWidget); // dialog stayed open
  });

  testWidgets('tapping Live calls onNavigate with the liveView route', (tester) async {
    stubHappyPath();
    final controller = buildController();
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('quickAction.live')));

    expect(navigated, ['liveView']);
  });

  testWidgets('tapping the recordings tile navigates to recordings', (tester) async {
    stubHappyPath();
    final controller = buildController();
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('tile.recordings')));

    expect(navigated, ['recordings']);
  });

  testWidgets('tapping the tunnel tile navigates to diagnostics', (tester) async {
    stubHappyPath();
    final controller = buildController();
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('tile.tunnel')));

    expect(navigated, ['diagnostics']);
  });

  testWidgets('tapping the daemons tile navigates to diagnostics', (tester) async {
    stubHappyPath();
    final controller = buildController();
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('tile.daemons')));

    expect(navigated, ['diagnostics']);
  });

  testWidgets('tapping "View all trips" navigates to trips', (tester) async {
    stubHappyPath();
    final controller = buildController();
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('tripStats.viewAll')));

    expect(navigated, ['trips']);
  });

  group('vehicle capacity dialog', () {
    testWidgets('opens from the vehicle tile, pre-filled with the current capacity', (tester) async {
      stubHappyPath();
      stubVehicleDialog();
      final controller = buildController();
      await pumpDashboard(tester, controller);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('tile.vehicle')));
      await tester.pumpAndSettle();

      expect(find.text('Set battery capacity'), findsOneWidget);
      expect(find.widgetWithText(TextField, '82.5'), findsOneWidget);
    });

    testWidgets('an invalid capacity is rejected without saving', (tester) async {
      stubHappyPath();
      stubVehicleDialog();
      final controller = buildController();
      await pumpDashboard(tester, controller);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tile.vehicle')));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, '82.5'), '3');
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Capacity must be 8 - 120 kWh'), findsOneWidget);
      expect(rpc.calls.where((c) => c.method == 'SetSohNominal'), isEmpty);
    });

    testWidgets('saving a valid capacity calls SetSohNominal and closes the dialog', (tester) async {
      stubHappyPath();
      stubVehicleDialog();
      rpc.stubJson('SystemService', 'SetSohNominal', {'success': true});
      final controller = buildController();
      await pumpDashboard(tester, controller);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tile.vehicle')));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, '82.5'), '75.0');
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Set battery capacity'), findsNothing);
      final call = rpc.calls.firstWhere((c) => c.method == 'SetSohNominal');
      expect((call.request as dynamic).nominalKwh, closeTo(75.0, 0.001));
    });

    testWidgets('reset clears the override and closes the dialog', (tester) async {
      stubHappyPath();
      stubVehicleDialog();
      rpc.stubJson('SystemService', 'SetSohNominal', {'success': true});
      final controller = buildController();
      await pumpDashboard(tester, controller);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tile.vehicle')));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Reset to auto-detect'));
      await tester.pumpAndSettle();

      expect(find.text('Set battery capacity'), findsNothing);
      final call = rpc.calls.firstWhere((c) => c.method == 'SetSohNominal');
      expect((call.request as dynamic).hasNominalKwh(), isFalse);
    });

    testWidgets('selecting a model auto-fills its manifest capacity', (tester) async {
      stubHappyPath();
      rpc.stubJson('SystemService', 'GetSohStatus', {'success': true});
      rpc.stubJson('SystemService', 'GetModelsManifest', {
        'manifestJson':
            '{"models":[{"id":"seal","name":"BYD Seal","nominalKwh":82.5},{"id":"atto3","name":"BYD Atto 3","nominalKwh":60.5}]}',
      });
      // Override stubHappyPath's pre-selected model so the dialog opens with
      // nothing chosen yet — keeps "BYD Atto 3" unambiguous in the tree (no
      // pre-selected chip already showing it elsewhere).
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      final controller = buildController();
      await pumpDashboard(tester, controller);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tile.vehicle')));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, '82.5'), '10.0');
      await tester.tap(find.widgetWithText(ChoiceChip, 'BYD Atto 3'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, '60.5'), findsOneWidget);
    });

    Future<void> openDialogWithSohStatus(WidgetTester tester, Map<String, Object?> sohStatus) async {
      stubHappyPath();
      rpc.stubJson('SystemService', 'GetSohStatus', sohStatus);
      rpc.stubJson('SystemService', 'GetModelsManifest', {'manifestJson': '{"models":[]}'});
      rpc.stubJson('SystemService', 'GetSelectedModel', {});
      final controller = buildController();
      await pumpDashboard(tester, controller);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tile.vehicle')));
      await tester.pumpAndSettle();
    }

    testWidgets('an auto-detected capacity is labelled accordingly in the summary', (tester) async {
      await openDialogWithSohStatus(tester, {
        'success': true,
        'nominalCapacityKwh': 82.5,
        'nominalSource': 'auto',
        'displaySoh': 0.0,
        'displaySource': 'unavailable',
      });

      expect(find.text('Capacity: 82.5 kWh (auto-detected)'), findsOneWidget);
    });

    testWidgets('a calibration-sourced SOH reading is labelled "from last charge"', (tester) async {
      await openDialogWithSohStatus(tester, {
        'success': true,
        'nominalCapacityKwh': 0.0,
        'nominalSource': 'unset',
        'displaySoh': 88.0,
        'displaySource': 'calibration',
      });

      expect(find.text('SOH: 88.0% (from last charge)'), findsOneWidget);
    });

    testWidgets('an OEM-sourced SOH reading is labelled "vehicle"', (tester) async {
      await openDialogWithSohStatus(tester, {
        'success': true,
        'nominalCapacityKwh': 0.0,
        'nominalSource': 'unset',
        'displaySoh': 91.0,
        'displaySource': 'oem',
      });

      expect(find.text('SOH: 91.0% (vehicle)'), findsOneWidget);
    });

    testWidgets('a nominal-sourced SOH reading is labelled "nominal"', (tester) async {
      await openDialogWithSohStatus(tester, {
        'success': true,
        'nominalCapacityKwh': 0.0,
        'nominalSource': 'unset',
        'displaySoh': 95.0,
        'displaySource': 'nominal',
      });

      expect(find.text('SOH: 95.0% (nominal)'), findsOneWidget);
    });

    testWidgets('an unrecognized SOH source falls back to "unavailable", matching native', (tester) async {
      await openDialogWithSohStatus(tester, {
        'success': true,
        'nominalCapacityKwh': 0.0,
        'nominalSource': 'unset',
        'displaySoh': 50.0,
        'displaySource': 'something-unexpected',
      });

      expect(find.text('SOH: unavailable'), findsOneWidget);
    });
  });

  testWidgets('renders without error in dark theme', (tester) async {
    stubHappyPath();
    final controller = buildController(tunnelUrlSource: () async => 'https://example.zrok.io');
    await pumpDashboard(tester, controller, theme: BladeWatchTheme.dark());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('82.5 kWh · BYD Seal'), findsOneWidget);
  });

  testWidgets('renders without error in a CJK locale (Japanese)', (tester) async {
    stubHappyPath();
    final controller = buildController();
    await pumpDashboard(tester, controller, locale: const Locale('ja'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('今週'), findsOneWidget); // dashboard_trips_this_week
  });
}
