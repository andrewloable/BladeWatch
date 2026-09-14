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

  // BladeWatch-p7vi: the dialog no longer reads GetSohStatus — SoH was removed
  // from the daemon — so only the model manifest is needed here.
  void stubVehicleDialog() {
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

  // BladeWatch-p7vi: the tile showed the nominal capacity, which the daemon can
  // no longer supply at all — so it sat on "Tap to set" permanently. It now
  // shows the selected model.
  testWidgets('vehicle tile shows the selected model', (tester) async {
    stubHappyPath();
    final controller = buildController();
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('BYD Seal'), findsOneWidget);
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

  // BladeWatch-8sig: ordering, not decoration. Regenerate invalidates the current
  // access code and every paired client; Set Password does not. The safer action
  // leads so a mis-tap on a touchscreen in a car is the recoverable one — and it
  // matches activity_main_new.xml, where btnSetPassword precedes
  // btnRegenerateToken.
  testWidgets('Set Password leads and Regenerate Token follows, never the reverse', (tester) async {
    stubHappyPath();
    final controller = buildController();
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    final setPassword = tester.getTopLeft(find.byKey(const ValueKey('accessCode.setPassword')));
    final regenerate = tester.getTopLeft(find.byKey(const ValueKey('accessCode.regenerate')));

    // Same row, so compare on x. If they ever wrap to separate lines, y decides.
    if (setPassword.dy == regenerate.dy) {
      expect(setPassword.dx, lessThan(regenerate.dx),
          reason: 'the destructive action must not occupy the leading position');
    } else {
      expect(setPassword.dy, lessThan(regenerate.dy),
          reason: 'the destructive action must not come first when wrapped');
    }
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

  // BladeWatch-p7vi: battery State-of-Health was removed from the daemon, so
  // the capacity field, its Reset action and the SoH summary are gone — they
  // offered an operation that could not succeed. The dialog now picks the
  // vehicle MODEL, which is really persisted.
  group('vehicle model dialog', () {
    testWidgets('opens from the vehicle tile and shows the model choices', (tester) async {
      stubHappyPath();
      stubVehicleDialog();
      final controller = buildController();
      await pumpDashboard(tester, controller);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('tile.vehicle')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('vehicleDialog.model.seal')), findsOneWidget);
    });

    testWidgets('no longer offers a capacity field or a reset action', (tester) async {
      stubHappyPath();
      stubVehicleDialog();
      final controller = buildController();
      await pumpDashboard(tester, controller);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tile.vehicle')));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNothing, reason: 'the capacity field cannot be saved');
      expect(find.widgetWithText(TextButton, 'Reset to auto-detect'), findsNothing);
    });

    testWidgets('saving persists the chosen model and closes', (tester) async {
      stubHappyPath();
      stubVehicleDialog();
      rpc.stubJson('SystemService', 'SetSelectedModel', {'ok': true});
      final controller = buildController();
      await pumpDashboard(tester, controller);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tile.vehicle')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('vehicleDialog.model.seal')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('vehicleDialog.model.seal')), findsNothing);
      final call = rpc.calls.firstWhere((c) => c.method == 'SetSelectedModel');
      expect((call.request as dynamic).modelId, 'seal');
    });

    testWidgets('the removed SOH endpoints are never called', (tester) async {
      stubHappyPath();
      stubVehicleDialog();
      rpc.stubJson('SystemService', 'SetSelectedModel', {'ok': true});
      final controller = buildController();
      await pumpDashboard(tester, controller);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tile.vehicle')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('vehicleDialog.model.seal')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      expect(rpc.calls.where((c) => c.method == 'SetSohNominal'), isEmpty);
      expect(rpc.calls.where((c) => c.method == 'GetSohNominal'), isEmpty);
    });

    // A refusal arrives as HTTP 200 with ok:false, so nothing throws. Closing
    // the dialog on that would look exactly like a successful save — the
    // original BladeWatch-p7vi defect.
    testWidgets('a refused save keeps the dialog open and shows the reason', (tester) async {
      stubHappyPath();
      stubVehicleDialog();
      rpc.stubJson('SystemService', 'SetSelectedModel', {'ok': false, 'error': 'unknown model'});
      final controller = buildController();
      await pumpDashboard(tester, controller);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tile.vehicle')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('vehicleDialog.model.seal')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('vehicleDialog.model.seal')), findsOneWidget,
          reason: 'closing would look like it saved');
      expect(find.text('unknown model'), findsOneWidget);
    });

    testWidgets('a transport failure falls back to the generic message', (tester) async {
      stubHappyPath();
      stubVehicleDialog();
      rpc.stubError('SystemService', 'SetSelectedModel', const ConnectError('unavailable', 'down'));
      final controller = buildController();
      await pumpDashboard(tester, controller);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('tile.vehicle')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('vehicleDialog.model.seal')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('vehicleDialog.error')), findsOneWidget);
      expect(find.text('Failed to save'), findsOneWidget);
    });
  });

  testWidgets('renders without error in dark theme', (tester) async {
    stubHappyPath();
    final controller = buildController(tunnelUrlSource: () async => 'https://example.zrok.io');
    await pumpDashboard(tester, controller, theme: BladeWatchTheme.dark());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('BYD Seal'), findsOneWidget);
  });

  testWidgets('renders without error in a CJK locale (Japanese)', (tester) async {
    stubHappyPath();
    final controller = buildController();
    await pumpDashboard(tester, controller, locale: const Locale('ja'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('今週'), findsOneWidget); // dashboard_trips_this_week
  });

  // ── BladeWatch-ya6f: native layout parity ──────────────────────────────
  //
  // Compared against a freshly re-captured screenshots/native/01_startup.png.
  // Native fits the whole dashboard above the fold; the port previously stacked
  // everything into roughly three screens of scrolling.

  group('native layout parity', () {
    /// Head-unit geometry. Distinct from pumpDashboard's tall virtual surface,
    /// which exists so off-screen tiles still build — here the REAL height is
    /// the point.
    Future<void> pumpHeadUnit(WidgetTester tester, DashboardController controller) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(wrap(controller));
      await tester.pumpAndSettle();
    }

    testWidgets('the hero card is filled with the primaryContainer role', (tester) async {
      stubHappyPath();
      await pumpHeadUnit(tester, buildController());

      // It was rendered on the ordinary surface grey, leaving the screen with
      // no focal point at all.
      final heroCard = tester.widget<Card>(
        find.ancestor(of: find.byKey(const ValueKey('tripStats.viewAll')), matching: find.byType(Card)).first,
      );
      expect(heroCard.color, BladeWatchTheme.light().colorScheme.primaryContainer);
    });

    testWidgets('the hero headline combines trip count and distance on one line', (tester) async {
      stubHappyPath();
      await pumpHeadUnit(tester, buildController());

      // Native reads "2 trips · 12.2 km"; the port showed only "2 trips" and
      // dropped the distance from the headline.
      expect(find.text('2 trips · 12.2 km'), findsOneWidget);
    });

    testWidgets('View all trips sits above the hero stats, not below them', (tester) async {
      stubHappyPath();
      await pumpHeadUnit(tester, buildController());

      final action = tester.getTopLeft(find.byKey(const ValueKey('tripStats.viewAll')));
      final distanceStat = tester.getTopLeft(find.text('12.2 km'));
      expect(action.dy, lessThan(distanceStat.dy));
    });

    testWidgets('all five metric cards render in one row at head-unit width', (tester) async {
      stubHappyPath();
      await pumpHeadUnit(tester, buildController());

      const keys = [
        ValueKey('tile.recordings'),
        ValueKey('tile.tunnel'),
        ValueKey('tile.daemons'),
        ValueKey('quickAction.live'),
        ValueKey('tile.vehicle'),
      ];
      // Same row => same vertical offset. Previously these were a 2-up grid
      // plus a separate full-width Live card.
      final tops = [for (final k in keys) tester.getTopLeft(find.byKey(k)).dy];
      expect(tops.toSet(), hasLength(1), reason: 'all five tiles should share one row');

      final lefts = [for (final k in keys) tester.getTopLeft(find.byKey(k)).dx];
      expect(lefts, orderedEquals(List<double>.from(lefts)..sort()), reason: 'tiles should be in native order');
    });

    testWidgets('every metric card carries a leading icon', (tester) async {
      stubHappyPath();
      await pumpHeadUnit(tester, buildController());

      for (final k in const [
        ValueKey('tile.recordings'),
        ValueKey('tile.tunnel'),
        ValueKey('tile.daemons'),
        ValueKey('quickAction.live'),
        ValueKey('tile.vehicle'),
      ]) {
        expect(find.descendant(of: find.byKey(k), matching: find.byType(Icon)), findsWidgets, reason: '$k needs an icon');
      }
    });

    testWidgets('Scan to Connect sits beside the hero and is visible without scrolling', (tester) async {
      stubHappyPath();
      await pumpHeadUnit(tester, buildController());

      // The access code was two swipes down; on a head unit that is the whole
      // point of the card.
      final heroTop = tester.getTopLeft(find.byKey(const ValueKey('tripStats.viewAll'))).dy;
      final codeRect = tester.getRect(find.byKey(const ValueKey('accessCode.toggle')));

      expect(codeRect.top, lessThan(heroTop + 400), reason: 'Scan to Connect should be level with the hero');
      expect(codeRect.bottom, lessThanOrEqualTo(1080), reason: 'it must be on screen at 1080 tall');
    });

    testWidgets('the whole dashboard fits on one screen at head-unit size', (tester) async {
      stubHappyPath();
      await pumpHeadUnit(tester, buildController());

      // The last thing down the page is the metric row; if it is on screen,
      // nothing needs scrolling.
      final lastTile = tester.getRect(find.byKey(const ValueKey('tile.vehicle')));
      expect(lastTile.bottom, lessThanOrEqualTo(1080));
    });

    testWidgets('a narrow window stacks instead of forcing two columns', (tester) async {
      stubHappyPath();
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(wrap(buildController()));
      await tester.pumpAndSettle();

      // Below the breakpoint the Connect card drops BELOW the hero rather than
      // being squeezed into an unreadable column.
      final heroLeft = tester.getTopLeft(find.byKey(const ValueKey('tripStats.viewAll')));
      final codeTop = tester.getTopLeft(find.byKey(const ValueKey('accessCode.toggle')));
      expect(codeTop.dy, greaterThan(heroLeft.dy));
    });
  });
}
