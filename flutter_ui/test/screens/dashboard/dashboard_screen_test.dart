import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/screens/pairing/pairing_dialog.dart';
import 'package:bladewatch_ui/platform/pairing_channel.dart';
import 'package:bladewatch_ui/platform/daemon_channel.dart';
import 'package:bladewatch_rpc/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/trips_service_client.dart';
import 'package:bladewatch_ui/screens/dashboard/dashboard_controller.dart';
import 'package:bladewatch_ui/screens/dashboard/dashboard_screen.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:bladewatch_ui/util/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../fakes/fake_platform_channel.dart';
import 'package:bladewatch_rpc/testing/fake_rpc_client.dart';

void main() {
  late FakeRpcClient rpc;
  late FakePlatformChannel channel;
  late List<String> navigated;

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

  Widget wrap(DashboardController controller, {Locale? locale, ThemeData? theme, PairingChannel? pairing}) => MaterialApp(
        theme: theme ?? BladeWatchTheme.light(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DashboardScreen(
          controller: controller,
          systemService: SystemServiceClient(rpc),
          onNavigate: (route) => navigated.add(route),
          pairingChannel: pairing,
        ),
      );

  // The dashboard is a long, scrollable screen (this is Epic 1's biggest
  // layout, ported near 1:1 from a 1,086-line native fragment). A generous
  // virtual surface means every tile — including ones below the fold on a
  // real device — is actually built and tappable without each test having
  // to fight ListView scroll-position/cache-extent timing individually.
  Future<void> pumpDashboard(WidgetTester tester, DashboardController controller, {Locale? locale, ThemeData? theme, PairingChannel? pairing}) async {
    tester.view.physicalSize = const Size(1400, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(wrap(controller, locale: locale, theme: theme, pairing: pairing));
  }

  // BladeWatch-rdtj.7: pairing is an explicit action, never a QR sitting on the dashboard.
  testWidgets('Pair a device opens the pairing dialog, which mints its QR only then', (tester) async {
    final pairing = FakePlatformChannel()
      ..stub('pairing', 'mint', {'payload': 'qr-text', 'expiresAt': DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch})
      ..stub('pairing', 'list', {'companions': []});
    await pumpDashboard(tester, buildController(), pairing: PairingChannel(pairing));
    await tester.pump();
    expect(pairing.calls, isEmpty, reason: 'nothing is minted until the owner asks');
    expect(find.byKey(const ValueKey('pairing.qr')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('dashboard.pair')));
    await tester.pump();
    await tester.pump();
    expect(find.byType(PairingDialog), findsOneWidget);
    expect(pairing.calls.map((c) => c.method), containsAll(['mint', 'list']));
    expect(find.byKey(const ValueKey('pairing.qr')), findsOneWidget);
  });

  testWidgets('without a pairing channel there is no pairing action', (tester) async {
    await pumpDashboard(tester, buildController());
    await tester.pump();
    expect(find.byKey(const ValueKey('dashboard.pair')), findsNothing);
  });

  testWidgets('loading state shows pending placeholders, not a crash', (tester) async {
    final controller = buildController();
    await pumpDashboard(tester, controller);

    expect(find.text('Loading…'), findsOneWidget);
    expect(find.text('—', skipOffstage: false), findsWidgets);
  });

  testWidgets('happy path renders trip stats, recordings, daemons and vehicle', (tester) async {
    stubHappyPath();
    final controller = buildController();
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget); // trip count
    expect(find.text('12.2 km'), findsOneWidget);
    expect(find.text('18m'), findsOneWidget); // 780+300=1080s -> 18m
    // BladeWatch-by8d: count and distance once each -- no headline repeating the tiles.
    expect(find.textContaining('12.2 km'), findsOneWidget);
    expect(find.textContaining('2 trips'), findsNothing);
  });

  // BladeWatch-7zp9: gear, drive mode and Auto Hold -- a dash for anything the car could not name.
  group('drive state chips', () {
    Finder chip(String key, String text) => find.descendant(of: find.byKey(ValueKey(key)), matching: find.text(text));

    testWidgets('shows what the car names, and a dash for what it does not', (tester) async {
      stubHappyPath();
      rpc.stubJson('SystemService', 'GetStatus', {
        'deviceId': 'byd-test',
        'recording': [1],
        'driveStatus': {
          'gear': 'D',
          'driveMode': 'UNKNOWN',
          'driveModeRaw': 1,
          'autoHold': 'ACTIVE',
          'autoHoldRaw': 2,
          'energyMode': 'HEV',
          'energyModeRaw': 3,
        },
      });
      await pumpDashboard(tester, buildController());
      await tester.pumpAndSettle();
      expect(chip('chip.gear', 'Gear D'), findsOneWidget);
      expect(chip('chip.driveMode', 'Mode: –'), findsOneWidget);
      expect(chip('chip.autoHold', 'Auto Hold: Holding'), findsOneWidget);
      expect(chip('chip.energyMode', 'HEV'), findsOneWidget); // BladeWatch-os88
    });

    testWidgets('a car that sends none shows dashes, never a guessed P / off', (tester) async {
      stubHappyPath();
      await pumpDashboard(tester, buildController());
      await tester.pumpAndSettle();
      expect(chip('chip.gear', 'Gear –'), findsOneWidget);
      expect(chip('chip.autoHold', 'Auto Hold: –'), findsOneWidget);
      // BladeWatch-os88: no EV / HEV to name is no chip at all, not a dash.
      expect(find.byKey(const ValueKey('chip.energyMode')), findsNothing);
    });

    testWidgets('Auto Hold on and off read as such', (tester) async {
      stubHappyPath();
      rpc.stubJson('SystemService', 'GetStatus', {'driveStatus': {'gear': 'P', 'autoHold': 'ENABLED'}});
      await pumpDashboard(tester, buildController());
      await tester.pumpAndSettle();
      expect(chip('chip.autoHold', 'Auto Hold: On'), findsOneWidget);
      expect(chip('chip.gear', 'Gear P'), findsOneWidget);

      rpc.stubJson('SystemService', 'GetStatus', {'driveStatus': {'autoHold': 'DISABLED'}});
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();
      expect(chip('chip.autoHold', 'Auto Hold: Off'), findsOneWidget);
    });

    // The owner switched EV/HEV and Auto Hold and the chips never moved: they waited on the
    // full 15 s reload. They now follow within one 2 s drive tick, whatever the other tiles do.
    testWidgets('the drive chips follow the car within 2 s, without the full reload', (tester) async {
      stubHappyPath();
      rpc.stubJson('SystemService', 'GetStatus', {'driveStatus': {'gear': 'P', 'autoHold': 'ENABLED', 'energyMode': 'EV'}});
      await pumpDashboard(tester, buildController());
      await tester.pumpAndSettle();
      expect(chip('chip.energyMode', 'EV'), findsOneWidget);

      rpc.stubJson('SystemService', 'GetStatus', {'driveStatus': {'gear': 'D', 'autoHold': 'DISABLED', 'energyMode': 'HEV'}});
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(chip('chip.energyMode', 'HEV'), findsOneWidget);
      expect(chip('chip.autoHold', 'Auto Hold: Off'), findsOneWidget);
      expect(chip('chip.gear', 'Gear D'), findsOneWidget);
    });

    testWidgets('a failed drive tick keeps the chips as they were', (tester) async {
      stubHappyPath();
      rpc.stubJson('SystemService', 'GetStatus', {'driveStatus': {'gear': 'P', 'energyMode': 'EV'}});
      await pumpDashboard(tester, buildController());
      await tester.pumpAndSettle();

      rpc.stubError('SystemService', 'GetStatus', const ConnectError('unavailable', 'down'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(chip('chip.energyMode', 'EV'), findsOneWidget);
      expect(chip('chip.gear', 'Gear P'), findsOneWidget);
    });
  });

  // BladeWatch-39d2: the week's fuel, electric and total cost, under the three stats it kept.
  group('this week\'s costs', () {
    Future<void> pumpWith(WidgetTester tester, List<Map<String, Object?>> trips) async {
      stubHappyPath();
      rpc.stubJson('TripsService', 'ListTrips', {'success': true, 'trips': trips});
      await pumpDashboard(tester, buildController());
      await tester.pumpAndSettle();
    }

    testWidgets('a PHEV week shows fuel, electric and total', (tester) async {
      await pumpWith(tester, [
        {'id': '1', 'distanceKm': 9.0, 'durationSeconds': 780, 'tripCost': 150.0, 'fuelCost': 100.0, 'currency': 'PHP', 'hasFuelData': true},
        {'id': '2', 'distanceKm': 3.2, 'durationSeconds': 300, 'tripCost': 30.0, 'currency': 'PHP'},
      ]);
      final costs = find.byKey(const ValueKey('tripStats.costs'));
      String? money(double v) => Currency.format(v, 'PHP');
      for (final (label, value) in [('Fuel Cost', 100.0), ('Electric Cost', 80.0), ('Total Cost', 180.0)]) {
        expect(find.descendant(of: costs, matching: find.text(label)), findsOneWidget);
        expect(find.descendant(of: costs, matching: find.text(money(value)!)), findsOneWidget, reason: label);
      }
      expect(find.text('2'), findsWidgets, reason: 'trip count kept');
      expect(find.text('12.2 km'), findsWidgets, reason: 'distance kept');
    });

    testWidgets('a BEV week leaves fuel out rather than showing 0', (tester) async {
      await pumpWith(tester, [
        {'id': '1', 'distanceKm': 9.0, 'durationSeconds': 780, 'tripCost': 40.0, 'currency': 'PHP'},
      ]);
      expect(find.text('Fuel Cost'), findsNothing);
      expect(find.text('Electric Cost'), findsOneWidget);
      expect(find.text('Total Cost'), findsOneWidget);
    });

    testWidgets('with no rate set it says so instead of showing zeros', (tester) async {
      await pumpWith(tester, [
        {'id': '1', 'distanceKm': 9.0, 'durationSeconds': 780},
      ]);
      expect(find.byKey(const ValueKey('tripStats.costs')), findsNothing);
      expect(find.text('Set an electricity rate in Trip settings to see costs.'), findsOneWidget);
    });
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
      'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'PEAR_PEER': false},
    });
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
      'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': true, 'ACC_SENTRY_DAEMON': true, 'PEAR_PEER': false},
    });
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
      'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': true, 'ACC_SENTRY_DAEMON': true, 'PEAR_PEER': false},
    });
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

  // BladeWatch-rdtj.12: the Connect card (onion QR, device id, web access code, Tor help)
  // went with tor. A companion pairs through the pairing dialog instead, so nothing that
  // grants access to the car sits on the Dashboard unasked.
  testWidgets('there is no Connect card: no QR, no access code, no Tor help', (tester) async {
    stubHappyPath();
    await pumpDashboard(tester, buildController());
    await tester.pumpAndSettle();

    expect(find.byType(QrImageView), findsNothing);
    expect(find.text('Scan to Connect'), findsNothing);
    expect(find.byKey(const ValueKey('accessCode.toggle')), findsNothing);
    expect(find.byKey(const ValueKey('accessCode.setPassword')), findsNothing);
    expect(find.byKey(const ValueKey('connect.torHelp')), findsNothing);
    expect(find.textContaining('Tor'), findsNothing);
    expect(channel.calls.where((c) => c.group == 'auth'), isEmpty,
        reason: 'the Dashboard no longer reads the device secret at all');
  });

  testWidgets('with the Pear peer switched off the Remote access tile reads Offline', (tester) async {
    stubHappyPath();
    channel.stub('daemon', 'pearStatus', {'status': 'ok', 'enabled': false, 'running': false});
    await pumpDashboard(tester, buildController());
    await tester.pumpAndSettle();

    expect(find.descendant(of: find.byKey(const ValueKey('tile.tunnel')), matching: find.text('Offline')), findsOneWidget);
  });

  testWidgets('vehicle tile shows "Tap to set" with no nominal capacity', (tester) async {
    rpc.stubJson('TripsService', 'ListTrips', {'success': true, 'trips': []});
    rpc.stubJson('RecordingsService', 'ListRecordings', {'recordings': [], 'total': 0});
    rpc.stubJson('SystemService', 'GetStatus', {'deviceId': 'byd-test', 'recording': []});
    rpc.stubJson('SystemService', 'GetSohNominal', {});
    rpc.stubJson('SystemService', 'GetSelectedModel', {});
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': true, 'ACC_SENTRY_DAEMON': true, 'PEAR_PEER': false},
    });
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

  // BladeWatch-rdtj.17: while the Pear peer is on, the Remote access tile reports whether the car
  // can actually be found -- not just whether a process runs.
  group('Remote access tile with the Pear peer on', () {
    Future<void> pumpWithPear(WidgetTester tester, Map<String, Object?> pear) async {
      stubHappyPath();
      channel.stub('daemon', 'pearStatus', {'status': 'ok', 'enabled': true, ...pear});
      await pumpDashboard(tester, buildController());
      await tester.pumpAndSettle();
    }

    Finder inTile(String text) =>
        find.descendant(of: find.byKey(const ValueKey('tile.tunnel')), matching: find.text(text));
    final dot = find.descendant(of: find.byKey(const ValueKey('tile.tunnel')), matching: find.byKey(const ValueKey('tile.statusDot')));

    testWidgets('reachable reads Online, with the status dot', (tester) async {
      await pumpWithPear(tester, {'running': true, 'reachable': true});
      expect(inTile('Online'), findsOneWidget);
      expect(dot, findsOneWidget);
    });

    testWidgets('running but unreachable reads Offline, no dot', (tester) async {
      await pumpWithPear(tester, {'running': true, 'reachable': false});
      expect(inTile('Offline'), findsOneWidget);
      expect(dot, findsNothing);
    });

    testWidgets('unknown reachability reads Running, no dot', (tester) async {
      await pumpWithPear(tester, {'running': true, 'reachable': null});
      expect(inTile('Running'), findsOneWidget);
      expect(dot, findsNothing);
    });

    testWidgets('switched on but not up yet reads Starting', (tester) async {
      await pumpWithPear(tester, {'running': false, 'reachable': false});
      expect(inTile('Starting'), findsOneWidget);
      expect(dot, findsNothing);
    });

    // BladeWatch-rdtj.21: on the head unit the tile said Online long after the car lost its network.
    testWidgets('the tile follows the car while the page stays open', (tester) async {
      await pumpWithPear(tester, {'running': true, 'reachable': true});
      expect(inTile('Online'), findsOneWidget);

      channel.stub('daemon', 'pearStatus', {'status': 'ok', 'enabled': true, 'running': true, 'reachable': false});
      await tester.pump(const Duration(seconds: 14));
      await tester.pumpAndSettle();
      expect(inTile('Online'), findsOneWidget, reason: 'not yet: the page re-reads every 15 s');

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(inTile('Offline'), findsOneWidget);
      expect(dot, findsNothing);
    });
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
    final controller = buildController();
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

    testWidgets('the hero has no headline repeating its trip count and distance', (tester) async {
      stubHappyPath();
      await pumpHeadUnit(tester, buildController());

      // Native's "2 trips · 12.2 km" headline sat right above the Trips and
      // Distance tiles, so the owner read both twice (BladeWatch-by8d).
      expect(find.text('2 trips · 12.2 km'), findsNothing);
      expect(find.text('12.2 km'), findsOneWidget);
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

    testWidgets('the whole dashboard fits on one screen at head-unit size', (tester) async {
      stubHappyPath();
      await pumpHeadUnit(tester, buildController());

      // The last thing down the page is the metric row; if it is on screen,
      // nothing needs scrolling.
      final lastTile = tester.getRect(find.byKey(const ValueKey('tile.vehicle')));
      expect(lastTile.bottom, lessThanOrEqualTo(1080));
    });

    testWidgets('the hero spans the full width now that the Connect card is gone', (tester) async {
      stubHappyPath();
      await pumpHeadUnit(tester, buildController());

      final hero = tester.getRect(
        find.ancestor(of: find.byKey(const ValueKey('tripStats.viewAll')), matching: find.byType(Card)).first,
      );
      expect(hero.width, greaterThan(1920 * 0.8), reason: 'no empty column where the card used to be');
    });
  });
}
