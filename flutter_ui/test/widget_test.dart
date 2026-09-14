import 'package:bladewatch_ui/main.dart';
import 'package:bladewatch_ui/platform/auth_channel.dart';
import 'package:bladewatch_ui/platform/daemon_channel.dart';
import 'package:bladewatch_ui/platform/prefs_channel.dart';
import 'package:bladewatch_ui/platform/setup_channel.dart';
import 'package:bladewatch_ui/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_ui/rpc/services/system_service_client.dart';
import 'package:bladewatch_ui/rpc/services/trips_service_client.dart';
import 'package:bladewatch_ui/screens/dashboard/dashboard_controller.dart';
import 'package:bladewatch_ui/screens/dashboard/dashboard_screen.dart';
import 'package:bladewatch_ui/screens/diagnostics/adb_console_screen.dart';
import 'package:bladewatch_ui/screens/diagnostics/diagnostics_screen.dart';
import 'package:bladewatch_ui/screens/diagnostics/performance_screen.dart';
import 'package:bladewatch_ui/screens/dialogs/language_picker_sheet.dart';
import 'package:bladewatch_ui/screens/dialogs/setup_guide_controller.dart';
import 'package:bladewatch_ui/screens/live_view/live_view_screen.dart';
import 'package:bladewatch_ui/screens/location/location_screen.dart';
import 'package:bladewatch_ui/screens/recordings/recordings_screen.dart';
import 'package:bladewatch_ui/screens/settings/settings_about_controller.dart' show AppVersionInfo;
import 'package:bladewatch_ui/screens/settings/settings_about_screen.dart';
import 'package:bladewatch_ui/screens/settings/settings_appearance_controller.dart';
import 'package:bladewatch_ui/screens/settings/settings_appearance_models.dart';
import 'package:bladewatch_ui/screens/settings/settings_screen.dart';
import 'package:bladewatch_ui/screens/startup/startup_controller.dart';
import 'package:bladewatch_ui/screens/startup/startup_screen.dart';
import 'package:bladewatch_ui/screens/surveillance/surveillance_screen.dart';
import 'package:bladewatch_ui/screens/trips/trip_detail_screen.dart';
import 'package:bladewatch_ui/screens/trips/trips_controller.dart';
import 'package:bladewatch_ui/screens/trips/trips_screen.dart';
import 'package:bladewatch_ui/shell/app_shell.dart';
import 'package:bladewatch_ui/shell/nav_rail.dart';
import 'package:bladewatch_ui/shell/route_stubs.dart';
import 'package:bladewatch_ui/shell/shell_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'fakes/fake_platform_channel.dart';
import 'fakes/fake_rpc_client.dart';

void main() {
  testWidgets('BladeWatchApp boots into the Startup screen, not straight to the shell', (tester) async {
    // The default (no injected controllers) constructor path — real
    // MethodChannelBridge/checkDaemonHealth, neither of which has anything
    // to talk to here, so it never gets past Startup. That is exactly the
    // point of this test: prove the app boots on the right screen without
    // crashing. The full Startup-to-shell transition is exercised below
    // with injected fakes; StartupController/StartupScreen's and
    // AppShell/NavRail's own behaviour are covered in their own test files.
    await tester.pumpWidget(const BladeWatchApp());
    await tester.pump();

    expect(find.byType(StartupScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('BladeWatchApp transitions from Startup to the shell once startup completes',
      (tester) async {
    final fakeChannel = FakePlatformChannel()
      ..stub('daemon', 'processStatus', {
        'status': 'ok',
        'daemons': {
          'CAMERA_DAEMON': true,
          'SENTRY_DAEMON': true,
          'ACC_SENTRY_DAEMON': true,
          'ZROK_TUNNEL': true,
        },
      });
    final startupController = StartupController(
      daemonChannel: DaemonChannel(fakeChannel),
      readyToNavigateDelay: Duration.zero,
      healthCheck: () async => true,
    );
    // The default route is Dashboard (ShellController's own default), so the
    // shell renders DashboardScreen immediately on arrival — give it a
    // fake-backed controller rather than the real ConnectClient/MethodChannel
    // wiring, which would otherwise try real network/platform-channel calls
    // in this test.
    final rpc = FakeRpcClient();
    final dashboardController = DashboardController(
      tripsService: TripsServiceClient(rpc),
      recordingsService: RecordingsServiceClient(rpc),
      systemService: SystemServiceClient(rpc),
      daemonChannel: DaemonChannel(fakeChannel),
      authChannel: AuthChannel(fakeChannel),
    );
    final shellController = ShellController();
    PackageInfo.setMockInitialValues(
      appName: 'BladeWatch',
      packageName: 'net.bladewatch.flutter',
      version: '9.9.9',
      buildNumber: '1',
      buildSignature: '',
    );
    // First-launch (never-seen) so main.dart's real auto-show-on-startup
    // wiring (a post-frame callback from the Builder below MaterialApp) is
    // exercised end-to-end, not just typed — otherwise this whole path goes
    // uncovered, since an unstubbed prefs call is (deliberately) treated as
    // "nothing to show" rather than thrown, per SetupGuideController's own
    // doc comment.
    fakeChannel.stub('prefs', 'getSetupGuideLastSeenBuild', null);
    fakeChannel.stub('prefs', 'setSetupGuideLastSeenBuild', null);
    fakeChannel.stub('setup', 'openAutoStartSettings', null);
    fakeChannel.stub('setup', 'openOverlaySettings', null);
    final setupGuideController = SetupGuideController(
      prefs: PrefsChannel(fakeChannel),
      setup: SetupChannel(fakeChannel),
      versionSource: () async => const AppVersionInfo(version: '9.9.9', buildNumber: '1', packageName: 'net.bladewatch.flutter'),
    );

    await tester.pumpWidget(BladeWatchApp(
      shellController: shellController,
      startupController: startupController,
      dashboardController: dashboardController,
      setupGuideController: setupGuideController,
      // settingsAboutController intentionally NOT injected here — this test
      // exercises main.dart's own real SettingsAboutController construction
      // (including its PackageInfo.fromPlatform() versionSource closure),
      // which the mock values above make safe to actually call.
    ));
    await tester.pump(); // resolves initState's immediate tick(): all daemons ready
    await tester.pump(const Duration(seconds: 1)); // the periodic timer's next tick():
    // readyToNavigateDelay (zero) has now elapsed since the first tick set _readyAt
    await tester.pump();

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(NavRailItem), findsNWidgets(9));
    expect(find.byType(StartupScreen), findsNothing);
    expect(find.byType(DashboardScreen), findsOneWidget);

    // The Setup Guide auto-shows on first launch (its post-frame callback
    // fires once the shell above has mounted) — dismiss it via "Done" before
    // interacting with the rest of the shell, same as any other modal.
    await tester.pumpAndSettle();
    expect(find.text('Getting Started'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('setupGuide.done')));
    await tester.pumpAndSettle();
    expect(find.text('Getting Started'), findsNothing);
    expect(tester.takeException(), isNull);

    // onLanguageTap is wired all the way from BladeWatchApp into AppShell,
    // and opens the real language picker sheet (BladeWatch-yz1e.11) — this
    // also exercises main.dart's own LocaleController/FileLocaleStore
    // construction and the Builder-scoped context showModalBottomSheet needs
    // (a context above MaterialApp itself, which the outer build() context
    // is, cannot open one).
    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();
    expect(find.byType(LanguagePickerSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('languagePicker.close')));
    await tester.pumpAndSettle();

    // Settings and About are wired the same way as Dashboard above — visit
    // both so main.dart's own construction of their controllers (including
    // the real PackageInfo.fromPlatform() version lookup and the two
    // still-no-op dialog callbacks) is exercised end-to-end, not just typed.
    // Their RPC/platform-channel calls go out for real here (no fakes wired
    // for Settings in main.dart yet) and fail with no listener/plugin behind
    // them — every controller already treats that as an ordinary load
    // failure (try/catch, default state), the same as it would on a device
    // before the daemon has booted.
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    shellController.selectRoute(BwRoutes.settings);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    // Settings → Appearance's language row opens the same sheet as the
    // toolbar's language button above — close it before continuing, since a
    // modal bottom sheet obscures the rest of the screen while open.
    await tester.tap(find.byKey(const ValueKey('language.card')));
    await tester.pumpAndSettle();
    expect(find.byType(LanguagePickerSheet), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('languagePicker.close')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('settings.section.privacy')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('privacy.resetData')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // The Reset Data dialog is real too (same task) — close it rather than
    // leaving it open for the rest of this test.
    expect(find.text('Reset Data'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    shellController.selectRoute(BwRoutes.settingsAbout);
    await tester.pumpAndSettle();
    expect(find.byType(SettingsAboutScreen), findsOneWidget);
    expect(find.text('9.9.9'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // "Show setup guide again" force-opens the same dialog as the auto-show
    // above, but always with no version banner (see showSetupGuideDialog's
    // own doc comment) — exercises main.dart's onShowSetupGuide wiring.
    await tester.tap(find.byKey(const ValueKey('about.setupGuide')));
    await tester.pumpAndSettle();
    // Scoped to the dialog on purpose: the About row that opens it is now
    // labelled "Getting Started" too (it previously carried the Settings hub's
    // "About BladeWatch" strings by mistake), so an unscoped finder matches
    // both the row behind and the dialog's own title.
    expect(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('Getting Started')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('setupGuide.versionBanner')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('setupGuide.skip')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Diagnostics is wired the same way — main.dart's own real
    // DiagnosticsController/AdbKeyChannel/NetworkChannel construction
    // (RPC/daemon calls fail with no listener behind them here, handled the
    // same as any other pre-boot load failure). This also exercises the
    // Settings shortcut, Traffic Monitor, ADB Console and Performance
    // factories/callbacks main.dart wires — including 2 real (if pointless
    // with nothing listening) Socket/HTTP connection attempts to
    // 127.0.0.1:5555/8080, both of which fail fast with "connection
    // refused" rather than hanging, since nothing is bound to either port
    // in this test environment.
    tester.view.physicalSize = const Size(1600, 2400);
    tester.view.devicePixelRatio = 1.0;
    shellController.selectRoute(BwRoutes.diagnostics);
    await tester.pumpAndSettle();
    expect(find.byType(DiagnosticsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('diag.cardSettingsShortcut')));
    await tester.pump();
    expect(shellController.selectedRoute, BwRoutes.settings);
    expect(tester.takeException(), isNull);

    shellController.selectRoute(BwRoutes.diagnostics);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('diag.cardTraffic')));
    await tester.pump(const Duration(seconds: 3)); // real (fast-failing) connect attempt
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // "Cannot Check Status" is the only reachable outcome with nothing
    // listening on 5555 — close it before continuing.
    if (find.byKey(const ValueKey('diag.traffic.ok')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const ValueKey('diag.traffic.ok')));
      await tester.pump();
    }

    await tester.tap(find.byKey(const ValueKey('diag.cardAdb')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3)); // real (fast-failing) connect attempt
    expect(find.byType(AdbConsoleScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('diag.cardPerformance')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3)); // real (fast-failing) connect attempt
    expect(find.byType(PerformanceScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Location is wired the same way — main.dart's own real
    // LocationController construction (LocationChannel/NetworkChannel/
    // PrefsChannel), including the screen's own 1s poll Timer. Channel calls
    // fail with no handler registered, caught the same defensive way as
    // every other pre-boot load failure (LocationController.start()/poll()
    // both catch and fall back to LocationError/a no-op tick rather than
    // throwing). Bounded pump()s, not pumpAndSettle() -- same reason as
    // Performance/ADB Console above: the poll Timer never lets it settle.
    // flutter_map's own tile fetches also happen for real here and fail
    // fast (nothing mocks the network in this test), which is fine --
    // this exercises the wiring, it does not assert on tile rendering.
    shellController.selectRoute(BwRoutes.location);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.byType(LocationScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Recordings is wired the same way — main.dart's own real
    // RecordingsController construction, reusing the same RecordingsServiceClient
    // Dashboard/Settings already share. RPC calls fail with no daemon
    // listening (RecordingsController.load() catches, -> RecordingsError);
    // the screen's own direct AuthChannel.mintJwt() call for thumbnail/video
    // auth headers is a new, separate code path from the RPC client's own
    // (already-defended) JWT use, exercised here for the first time.
    shellController.selectRoute(BwRoutes.recordings);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.byType(RecordingsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Exercises main.dart's own onOpenSettings closure, same as Diagnostics'
    // settings-shortcut tap above. Nothing later needs to be back on the
    // Recordings route, so (unlike Diagnostics) it is not re-selected.
    await tester.tap(find.byKey(const ValueKey('recordings.settings')));
    await tester.pump();
    expect(shellController.selectedRoute, BwRoutes.settings);
    expect(tester.takeException(), isNull);

    // Surveillance's standalone AppShell slot is wired the same way — main.dart's
    // own real SurveillanceSettingsController construction (a separate instance
    // from the one the Settings sub-rail builds fresh per-switch), reusing the
    // same SurveillanceServiceClient/StorageServiceClient/RecordingsServiceClient
    // Dashboard/Diagnostics/Settings already share, plus the new
    // SafeLocationsServiceClient and long-read SurveillanceServiceClient. RPC
    // calls fail with no daemon listening, caught the same defensive way as
    // every other screen's load() above. Bounded pump()s, not pumpAndSettle()
    // -- same reason as Location above: this screen can also reach a
    // flutter_map (Detection tab), whose real, unmocked tile fetch never
    // settles within pumpAndSettle()'s timeout in this sandboxed environment.
    shellController.selectRoute(BwRoutes.surveillance);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(find.byType(SurveillanceSettingsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Trips is wired the same way — main.dart's own real TripsController
    // construction, including the second (long-read-timeout) ConnectClient
    // for SyncTrips. RPC calls fail with no daemon listening, same ordinary
    // load-failure handling as every other screen visited above.
    shellController.selectRoute(BwRoutes.trips);
    await tester.pumpAndSettle();
    expect(find.byType(TripsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Vehicle (BwRoutes.vehicle) is deliberately NOT visited here, unlike
    // every other screen above. main.dart wires its real 3D hero
    // (VehicleHero, a webview_flutter WebViewController) with no test
    // override -- correct for production, but constructing a real
    // WebViewController throws `WebViewPlatform.instance != null` in any
    // plain `flutter test` run: no platform implementation is registered
    // outside a real app/device (confirmed empirically; this is not an RPC
    // failure like every other screen's daemon-less degradation above, it
    // is a missing platform channel). VehicleScreen's own widget tests
    // cover everything else via VehicleScreen(heroBuilder: ...), which
    // substitutes a placeholder specifically to avoid this. Verifying this
    // exact wiring path (main.dart -> real VehicleHero -> real WebView) is
    // BladeWatch-imh6's job, on-device.

    // Live View is wired the same way — main.dart's own real
    // LiveViewController/StreamServiceClient/LiveViewTextureChannel
    // construction, over a distinct MethodChannel from every other screen's
    // shared "privileged" one (see LiveViewTextureChannel's doc comment).
    // Unlike Vehicle above, this one is safe to visit unfaked: creating the
    // texture is the first thing LiveViewController.start() does, and with
    // no native handler registered here it fails immediately
    // (MissingPluginException -> PlatformChannelError), which start() now
    // catches and turns into an ordinary LiveStreamPhase.unavailable state —
    // the RPC/WebSocket steps further down the connect flow are never
    // reached at all in this environment.
    shellController.selectRoute(BwRoutes.liveView);
    await tester.pumpAndSettle();
    expect(find.byType(LiveViewScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Rebuild with one fake-backed trip loaded (this app instance's *only*
    // injected controller — everything else above still exercises
    // main.dart's real, unfaked construction) so there is a row to tap:
    // main.dart's own detailControllerFactory closure (building a real,
    // daemon-less TripDetailController off the real _tripsService) is
    // otherwise unreachable from a fakes-free smoke test.
    final tripsRpc = FakeRpcClient()
      ..stubJson('TripsService', 'ListTrips', {
        'success': true,
        'trips': [
          {'id': '1', 'startTime': '1000', 'endTime': '2000', 'distanceKm': 5.0, 'durationSeconds': 300, 'overallScore': 80, 'tripCost': 0.0, 'currency': ''}
        ],
      })
      ..stubJson('TripsService', 'GetSummary', {'success': true, 'summary': []})
      ..stubJson('TripsService', 'GetDna', {'success': true, 'dna': null})
      ..stubJson('TripsService', 'GetRange', {'success': true, 'rangeJson': '{}'})
      ..stubJson('TripsService', 'GetConfig', {'success': true, 'config': null})
      ..stubJson('TripsService', 'GetStorage', {'success': true, 'storage': null});
    final tripsController = TripsController(
      tripsService: TripsServiceClient(tripsRpc),
      longTripsService: TripsServiceClient(tripsRpc),
    );
    // A plain re-pump of BladeWatchApp would keep reusing the existing
    // State object (and its already-initialized `late final` controllers,
    // this new tripsController included) — tear the widget tree all the way
    // down first so the next pump mounts a genuinely fresh State. Every
    // injected controller must also be fresh: main.dart's own dispose()
    // already disposed the first pump's instances (dashboardController
    // included, even though it was injected) when the tree was torn down;
    // reusing them here would throw "used after being disposed".
    await tester.pumpWidget(const SizedBox());
    final secondShellController = ShellController(initialRoute: BwRoutes.trips);
    final secondStartupController = StartupController(
      daemonChannel: DaemonChannel(fakeChannel),
      readyToNavigateDelay: Duration.zero,
      healthCheck: () async => true,
    );
    final secondDashboardController = DashboardController(
      tripsService: TripsServiceClient(rpc),
      recordingsService: RecordingsServiceClient(rpc),
      systemService: SystemServiceClient(rpc),
      daemonChannel: DaemonChannel(fakeChannel),
      authChannel: AuthChannel(fakeChannel),
    );
    await tester.pumpWidget(BladeWatchApp(
      shellController: secondShellController,
      startupController: secondStartupController,
      dashboardController: secondDashboardController,
      tripsController: tripsController,
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(TripsScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('trips.row.1')));
    await tester.pumpAndSettle();
    expect(find.byType(TripDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(const SizedBox());
  });

  // ── BladeWatch-imh6.7: the theme the user picks must actually reach
  // MaterialApp. It used to be persisted to prefs and then ignored, because
  // MaterialApp set theme/darkTheme but never themeMode — which defaults to
  // ThemeMode.system, so the app silently followed the head unit instead. ───
  group('theme mode reaches MaterialApp', () {
    ThemeMode themeModeOf(WidgetTester tester) =>
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode ?? ThemeMode.system;

    Future<void> pumpWith(WidgetTester tester, AppThemeMode mode) async {
      final prefs = PrefsChannel(FakePlatformChannel()
        ..stub('prefs', 'getThemeMode', themeModeToPref(mode))
        ..stub('prefs', 'getDriveSide', 'left'));
      final controller = SettingsAppearanceController(prefs: prefs, shellController: ShellController());
      await controller.load();
      await tester.pumpWidget(BladeWatchApp(appearanceController: controller));
      await tester.pump();
    }

    testWidgets('dark', (tester) async {
      await pumpWith(tester, AppThemeMode.dark);
      expect(themeModeOf(tester), ThemeMode.dark);
    });

    testWidgets('light', (tester) async {
      await pumpWith(tester, AppThemeMode.light);
      expect(themeModeOf(tester), ThemeMode.light);
    });

    testWidgets('system follows the platform, as before', (tester) async {
      await pumpWith(tester, AppThemeMode.system);
      expect(themeModeOf(tester), ThemeMode.system);
    });

    test('every AppThemeMode maps to its Flutter counterpart', () {
      expect(materialThemeMode(AppThemeMode.light), ThemeMode.light);
      expect(materialThemeMode(AppThemeMode.dark), ThemeMode.dark);
      expect(materialThemeMode(AppThemeMode.system), ThemeMode.system);
    });
  });
}
