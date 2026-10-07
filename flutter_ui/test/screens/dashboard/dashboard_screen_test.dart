import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/platform/daemon_channel.dart';
import 'package:bladewatch_rpc/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/trips_service_client.dart';
import 'package:bladewatch_ui/screens/dashboard/dashboard_controller.dart';
import 'package:bladewatch_ui/screens/dashboard/dashboard_screen.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:bladewatch_ui/theme/hud_theme.dart';
import 'package:bladewatch_ui/widgets/hud_widgets.dart';
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

  Widget wrap(
    DashboardController controller, {
    Locale? locale,
    ThemeData? theme,
  }) => MaterialApp(
        theme: theme ?? BladeWatchTheme.light(),
        // The HUD title square and recording dot pulse forever (HudPulse); with animations on,
        // pumpAndSettle never settles. HudPulse stands still under disableAnimations.
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
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
  Future<void> pumpDashboard(
    WidgetTester tester,
    DashboardController controller, {
    Locale? locale,
    ThemeData? theme,
  }) async {
    tester.view.physicalSize = const Size(1400, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(wrap(controller, locale: locale, theme: theme));
  }

  testWidgets('a metric tile value is shrunk to fit, never cut with an ellipsis', (tester) async {
    stubHappyPath();
    await pumpDashboard(tester, buildController());
    await tester.pumpAndSettle();
    final values = find.descendant(of: find.byType(FittedBox), matching: find.byType(Text));
    expect(values, findsWidgets);
    for (final t in tester.widgetList<Text>(values)) {
      expect(t.overflow, isNot(TextOverflow.ellipsis), reason: '"${t.data}"');
    }
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
      expect(chip('chip.gear', 'GEAR D'), findsOneWidget);
      expect(chip('chip.driveMode', 'MODE: –'), findsOneWidget);
      expect(chip('chip.autoHold', 'AUTO HOLD: HOLDING'), findsOneWidget);
      expect(chip('chip.energyMode', 'HEV'), findsOneWidget); // BladeWatch-os88
    });

    testWidgets('a car that sends none shows dashes, never a guessed P / off', (tester) async {
      stubHappyPath();
      await pumpDashboard(tester, buildController());
      await tester.pumpAndSettle();
      expect(chip('chip.gear', 'GEAR –'), findsOneWidget);
      expect(chip('chip.autoHold', 'AUTO HOLD: –'), findsOneWidget);
      // BladeWatch-os88: no EV / HEV to name is no chip at all, not a dash.
      expect(find.byKey(const ValueKey('chip.energyMode')), findsNothing);
    });

    testWidgets('Auto Hold on and off read as such', (tester) async {
      stubHappyPath();
      rpc.stubJson('SystemService', 'GetStatus', {'driveStatus': {'gear': 'P', 'autoHold': 'ENABLED'}});
      await pumpDashboard(tester, buildController());
      await tester.pumpAndSettle();
      expect(chip('chip.autoHold', 'AUTO HOLD: ON'), findsOneWidget);
      expect(chip('chip.gear', 'GEAR P'), findsOneWidget);

      rpc.stubJson('SystemService', 'GetStatus', {'driveStatus': {'autoHold': 'DISABLED'}});
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();
      expect(chip('chip.autoHold', 'AUTO HOLD: OFF'), findsOneWidget);
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
      expect(chip('chip.autoHold', 'AUTO HOLD: OFF'), findsOneWidget);
      expect(chip('chip.gear', 'GEAR D'), findsOneWidget);
    });

    // The owner: charge and fuel live, trip summaries once a minute (2026-09-27).
    testWidgets('battery and fuel follow the car within 2 s; the week\'s trips reload once a minute', (tester) async {
      stubHappyPath();
      rpc.stubJson('SystemService', 'GetStatus', {'soc': {'percent': 73}, 'range': {'elecRangeKm': 74, 'fuelRangeKm': 351, 'fuelPercent': 30}});
      await pumpDashboard(tester, buildController());
      await tester.pumpAndSettle();
      final energy = find.byKey(const ValueKey('vehicle.energy'));
      expect(find.descendant(of: energy, matching: find.text('73%')), findsOneWidget);
      int trips() => rpc.calls.where((c) => c.method == 'ListTrips').length;
      final afterOpen = trips();

      rpc.stubJson('SystemService', 'GetStatus', {'soc': {'percent': 74}, 'range': {'elecRangeKm': 76, 'fuelRangeKm': 351, 'fuelPercent': 30}});
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(find.descendant(of: energy, matching: find.text('74%')), findsOneWidget, reason: 'the 2 s drive poll carries it');
      expect(find.descendant(of: energy, matching: find.text('76 km')), findsOneWidget);

      await tester.pump(const Duration(seconds: 45));
      await tester.pump();
      expect(trips(), afterOpen, reason: 'the 15 s ticks leave the week\'s trips alone');
      await tester.pump(const Duration(seconds: 15));
      await tester.pump();
      expect(trips(), greaterThan(afterOpen), reason: 'once a minute they reload');
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
      expect(chip('chip.gear', 'GEAR P'), findsOneWidget);
    });
  });

  // BladeWatch-4zr7: the car's charge and fuel now, in THIS WEEK.
  group('the vehicle card\'s charge and fuel', () {
    Future<Finder> pumpWith(WidgetTester tester, Map<String, Object?>? status) async {
      stubHappyPath();
      if (status != null) rpc.stubJson('SystemService', 'GetStatus', status);
      await pumpDashboard(tester, buildController());
      await tester.pumpAndSettle();
      return find.byKey(const ValueKey('vehicle.energy'));
    }

    Finder inRow(Finder row, String text) => find.descendant(of: row, matching: find.text(text));

    testWidgets('a PHEV shows battery, electric range, fuel and fuel range in the car\'s unit', (tester) async {
      final row = await pumpWith(tester, {
        'recording': [1],
        'soc': {'percent': 77},
        'range': {'elecRangeKm': 81, 'fuelRangeKm': 351, 'fuelPercent': 30},
        'distanceUnit': 'mi',
      });
      for (final (label, value) in [('Battery', '77%'), ('EV Range', '50 mi'), ('Fuel', '30%'), ('Fuel Range', '218 mi')]) {
        expect(inRow(row, label), findsOneWidget, reason: label);
        expect(inRow(row, value), findsOneWidget, reason: '$label = $value');
      }
    });

    testWidgets('with the pack and tank size known, battery and fuel show what is left', (tester) async {
      stubHappyPath();
      rpc.stubJson('SystemService', 'GetSohNominal', {'nominalKwh': 18.3, 'nominalSource': 'catalogue'});
      rpc.stubJson('TripsService', 'GetConfig', {'success': true, 'config': {'fuelTankCapacityL': 48}});
      rpc.stubJson('SystemService', 'GetStatus', {
        'soc': {'percent': 77},
        'range': {'elecRangeKm': 81, 'fuelRangeKm': 351, 'fuelPercent': 30},
      });
      await pumpDashboard(tester, buildController());
      await tester.pumpAndSettle();
      final row = find.byKey(const ValueKey('vehicle.energy'));
      expect(inRow(row, '77% / 14.1 kWh'), findsOneWidget);
      expect(inRow(row, '30% / 14 L'), findsOneWidget);
    });

    testWidgets('a BEV shows no fuel at all', (tester) async {
      final row = await pumpWith(tester, {'soc': {'percent': 60}, 'range': {'elecRangeKm': 300}, 'distanceUnit': 'km'});
      expect(inRow(row, '60%'), findsOneWidget);
      expect(inRow(row, '300 km'), findsOneWidget);
      expect(inRow(row, 'Fuel'), findsNothing);
      expect(inRow(row, 'Fuel Range'), findsNothing);
    });

    // The owner saw the rows drift once the charge row brought a fourth tile under three. Since
    // 2026-10-04 the charge row is the VEHICLE card's, and its columns still line up with the week's.
    testWidgets('every row of both cards sits on the same columns', (tester) async {
      stubHappyPath();
      rpc.stubJson('SystemService', 'GetStatus', {
        'soc': {'percent': 77},
        'range': {'elecRangeKm': 81, 'fuelRangeKm': 351, 'fuelPercent': 30},
        'distanceUnit': 'km',
      });
      rpc.stubJson('TripsService', 'ListTrips', {
        'success': true,
        'trips': [
          {'id': '1', 'distanceKm': 9.0, 'durationSeconds': 780, 'tripCost': 150.0, 'fuelCost': 100.0, 'currency': 'PHP', 'hasFuelData': true},
        ],
      });
      await pumpDashboard(tester, buildController());
      await tester.pumpAndSettle();
      final card = find.ancestor(of: find.byKey(const ValueKey('tripStats.viewAll')), matching: find.byType(HudPanel));
      double left(String label) => tester.getTopLeft(find.text(label)).dx;
      for (final column in [
        ['Trips', 'Battery', 'Fuel Cost'],
        ['Distance', 'EV Range', 'Electric Cost'],
        ['Drive Time', 'Fuel', 'Total Cost'],
      ]) {
        expect(column.map(left).toSet(), hasLength(1), reason: '$column should share one left edge');
      }

      // The week's card holds only the week; the car's state is its own card, below it. The
      // header's label and button share one line (design review 2026-09-27).
      expect(find.descendant(of: card, matching: find.text('Battery')), findsNothing);
      expect(tester.getTopLeft(find.text('Battery')).dy, greaterThan(tester.getRect(card).bottom));
      final labelY = tester.getCenter(find.descendant(of: card, matching: find.text('THIS WEEK TELEMETRY'))).dy;
      final buttonY = tester.getCenter(find.byKey(const ValueKey('tripStats.viewAll'))).dy;
      expect((labelY - buttonY).abs(), lessThan(1), reason: 'label and button on one line');
    });

    testWidgets('before the car has reported, the tiles wait with the pending mark', (tester) async {
      final row = await pumpWith(tester, null); // the happy path's status has no charge or range
      expect(inRow(row, 'Battery'), findsOneWidget);
      final pending = AppLocalizations.of(tester.element(row))!.dashboard_metric_value_pending;
      expect(inRow(row, pending), findsNWidgets(2));
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

  // The live string carries a "●" bullet; the HUD (BladeWatch-8w4p) draws it as a glowing dot, and only
  // while the car is recording: the reference shows the dot unconditionally.
  testWidgets('recordings tile shows the live dot while recording', (tester) async {
    stubHappyPath();
    final controller = buildController();
    await pumpDashboard(tester, controller);
    await tester.pumpAndSettle();

    final tile = find.byKey(const ValueKey('tile.recordings'));
    expect(find.descendant(of: tile, matching: find.text('4')), findsOneWidget, reason: 'the count, without the bullet text');
    expect(find.descendant(of: tile, matching: find.byKey(const ValueKey('tile.recordingDot'))), findsOneWidget);
    expect(find.textContaining('●'), findsNothing);
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

    expect(find.byKey(const ValueKey('tile.recordingDot')), findsNothing);
    expect(find.byKey(const ValueKey('chip.recordingDot')), findsNothing);
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

    // Once: the Background services tile. The hero chip that repeated it was dropped (design
    // review 2026-09-27, BladeWatch-5l5o).
    expect(find.text('0/0 RUNNING'), findsOneWidget);
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

    expect(find.descendant(of: find.byKey(const ValueKey('tile.tunnel')), matching: find.text('OFFLINE')), findsOneWidget);
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
      expect(inTile('ONLINE'), findsOneWidget);
      expect(dot, findsOneWidget);
    });

    testWidgets('running but unreachable reads Offline, no dot', (tester) async {
      await pumpWithPear(tester, {'running': true, 'reachable': false});
      expect(inTile('OFFLINE'), findsOneWidget);
      expect(dot, findsNothing);
    });

    testWidgets('unknown reachability reads Running, no dot', (tester) async {
      await pumpWithPear(tester, {'running': true, 'reachable': null});
      expect(inTile('RUNNING'), findsOneWidget);
      expect(dot, findsNothing);
    });

    testWidgets('switched on but not up yet reads Starting', (tester) async {
      await pumpWithPear(tester, {'running': false, 'reachable': false});
      expect(inTile('STARTING'), findsOneWidget);
      expect(dot, findsNothing);
    });

    // BladeWatch-rdtj.21: on the head unit the tile said Online long after the car lost its network.
    testWidgets('the tile follows the car while the page stays open', (tester) async {
      await pumpWithPear(tester, {'running': true, 'reachable': true});
      expect(inTile('ONLINE'), findsOneWidget);

      channel.stub('daemon', 'pearStatus', {'status': 'ok', 'enabled': true, 'running': true, 'reachable': false});
      await tester.pump(const Duration(seconds: 14));
      await tester.pumpAndSettle();
      expect(inTile('ONLINE'), findsOneWidget, reason: 'not yet: the page re-reads every 15 s');

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(inTile('OFFLINE'), findsOneWidget);
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
      // BladeWatch-2llu.1: the dialog (root navigator) opts into the HUD theme and the single-choice chips follow it.
      expect(Theme.of(tester.element(find.byType(AlertDialog))).extension<BwHud>(), same(BwHud.light));
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
    expect(find.textContaining('今週'), findsOneWidget); // dashboard_trips_this_week (+ the English HUD word)
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

    testWidgets('the hero is the HUD summary card: gradient fill, cyan-edged, 12 dp radius', (tester) async {
      stubHappyPath();
      await pumpHeadUnit(tester, buildController());

      // It was the filled primaryContainer role of the M3 look (BladeWatch-ya6f); the HUD skin
      // (BladeWatch-8w4p) draws it as its own bordered panel.
      final hero = tester.widget<HudPanel>(
        find.ancestor(of: find.byKey(const ValueKey('tripStats.viewAll')), matching: find.byType(HudPanel)).first,
      );
      expect((hero.gradient! as LinearGradient).colors, BwHud.light.summaryGradient);
      expect(hero.borderColor, BwHud.light.cardBorder);
      expect(hero.radius, BwHud.radiusPanel);
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
        find.ancestor(of: find.byKey(const ValueKey('tripStats.viewAll')), matching: find.byType(HudPanel)).first,
      );
      expect(hero.width, greaterThan(1920 * 0.8), reason: 'no empty column where the card used to be');
    });
  });

  // ── BladeWatch-8w4p: the HUD skin ─────────────────────────────────────
  group('HUD skin', () {
    Future<void> pumpFull(WidgetTester tester, {ThemeData? theme, Map<String, Object?>? status, List<Map<String, Object?>>? trips}) async {
      stubHappyPath();
      if (status != null) rpc.stubJson('SystemService', 'GetStatus', status);
      if (trips != null) rpc.stubJson('TripsService', 'ListTrips', {'success': true, 'trips': trips});
      await pumpDashboard(tester, buildController(), theme: theme);
      await tester.pumpAndSettle();
    }

    const phev = {
      'recording': [1],
      'soc': {'percent': 77},
      'range': {'elecRangeKm': 81, 'fuelRangeKm': 351, 'fuelPercent': 30},
      'distanceUnit': 'km',
    };
    final costed = [
      {'id': '1', 'distanceKm': 9.0, 'durationSeconds': 780, 'tripCost': 150.0, 'fuelCost': 100.0, 'currency': 'PHP', 'hasFuelData': true},
    ];

    RichText richFor(WidgetTester tester, String plain) => tester.widget<RichText>(
          find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText() == plain).first,
        );
    // Text.rich wraps the value span in one carrying the ambient style: the value's own span is its only child.
    TextSpan spanOf(WidgetTester tester, String plain) => (richFor(tester, plain).text as TextSpan).children!.single as TextSpan;
    TextStyle? valueStyle(WidgetTester tester, String plain) => spanOf(tester, plain).style;

    group('title bar', () {
      testWidgets('reads DASHBOARD // OVERVIEW, cyan with a glow in dark', (tester) async {
        await pumpFull(tester, theme: BladeWatchTheme.dark());
        final title = tester.widget<Text>(find.byKey(const ValueKey('dashboard.title')));
        expect(title.data, 'DASHBOARD // OVERVIEW');
        expect(title.style!.color, BwHud.dark.accent);
        expect(title.style!.fontSize, 20);
        expect(title.style!.fontWeight, FontWeight.w700);
        expect(title.style!.fontFamily, BwHud.fontFamily);
        expect(title.style!.shadows, [BwHud.dark.glowCyan]);
      });

      testWidgets('has no glow in light', (tester) async {
        await pumpFull(tester);
        final title = tester.widget<Text>(find.byKey(const ValueKey('dashboard.title')));
        expect(title.style!.color, BwHud.light.accent);
        expect(title.style!.shadows, isNull);
      });

      testWidgets('SECURE_LINK is OFFLINE with no remote access, and never claims ACTIVE', (tester) async {
        await pumpFull(tester);
        expect(find.byKey(const ValueKey('dashboard.secureLink')), findsOneWidget);
        expect(find.text('SECURE_LINK: OFFLINE'), findsOneWidget);
        expect(find.text('SECURE_LINK: ACTIVE'), findsNothing);
      });

      testWidgets('SECURE_LINK is OFFLINE while the peer runs but the car cannot be found', (tester) async {
        channel.stub('daemon', 'pearStatus', {'status': 'ok', 'enabled': true, 'running': true, 'reachable': false});
        await pumpFull(tester);
        expect(find.text('SECURE_LINK: OFFLINE'), findsOneWidget);
      });

      testWidgets('SECURE_LINK is ACTIVE exactly when the Remote access tile says ONLINE', (tester) async {
        channel.stub('daemon', 'pearStatus', {'status': 'ok', 'enabled': true, 'running': true, 'reachable': true});
        await pumpFull(tester);
        expect(find.text('SECURE_LINK: ACTIVE'), findsOneWidget);
        expect(find.descendant(of: find.byKey(const ValueKey('tile.tunnel')), matching: find.text('ONLINE')), findsOneWidget);
        final link = tester.widget<Text>(find.byKey(const ValueKey('dashboard.secureLink')));
        expect(link.style!.color, BwHud.light.magenta);
        expect(link.style!.fontSize, 12);
      });

      testWidgets('the title square is a pulsing 8 dp magenta block', (tester) async {
        await pumpFull(tester);
        final pulse = find.descendant(of: find.byType(HudPulse), matching: find.byType(Container));
        expect(pulse, findsWidgets);
        final square = tester.widget<Container>(pulse.first);
        expect(square.color, BwHud.light.magenta);
        expect(tester.getSize(pulse.first), const Size(8, 8));
      });
    });

    group('summary card', () {
      testWidgets('three columns of labels share left edges, on every row (PHEV)', (tester) async {
        await pumpFull(tester, status: phev, trips: costed);
        // Across both cards: the VEHICLE card is the same width and padding as THIS WEEK.
        double left(String label) => tester.getTopLeft(find.text(label)).dx;
        expect({left('Trips'), left('Fuel Cost'), left('Battery')}, hasLength(1));
        expect({left('Distance'), left('Electric Cost'), left('EV Range')}, hasLength(1));
        expect({left('Drive Time'), left('Total Cost'), left('Fuel')}, hasLength(1));
        expect(left('Distance'), greaterThan(left('Trips')));
        expect(left('Drive Time'), greaterThan(left('Distance')));
      });

      testWidgets('Fuel and Fuel Range share the third column, Fuel Range right-aligned', (tester) async {
        await pumpFull(tester, status: phev, trips: costed);
        final card = find.ancestor(of: find.byKey(const ValueKey('vehicle.energy')), matching: find.byType(HudPanel)).first;
        final cardRect = tester.getRect(card);
        Rect rect(String label) => tester.getRect(find.text(label));
        expect(rect('Fuel').left, lessThan(rect('Fuel Range').left));
        expect(rect('Fuel').top, rect('Fuel Range').top, reason: 'side by side, one line');
        // The VEHICLE card's content edge: 1 dp border + 24 dp padding.
        expect(rect('Fuel Range').right, closeTo(cardRect.right - 25, 1));
        expect(rect('Total Cost').left, rect('Fuel').left);
      });

      testWidgets('a BEV leaves the third column of the charge row empty', (tester) async {
        await pumpFull(tester, status: {'soc': {'percent': 60}, 'range': {'elecRangeKm': 300}, 'distanceUnit': 'km'});
        final energy = find.byKey(const ValueKey('vehicle.energy'));
        expect(find.descendant(of: energy, matching: find.text('Battery')), findsOneWidget);
        expect(find.descendant(of: energy, matching: find.text('EV Range')), findsOneWidget);
        expect(find.descendant(of: energy, matching: find.text('Fuel')), findsNothing);
        expect(find.descendant(of: energy, matching: find.text('Fuel Range')), findsNothing);
      });

      testWidgets('a distance draws its unit smaller, and the plain text is unchanged', (tester) async {
        await pumpFull(tester, theme: BladeWatchTheme.dark());
        final root = spanOf(tester, '12.2 km');
        expect(root.toPlainText(), '12.2 km');
        expect(root.children, hasLength(2));
        expect((root.children![0] as TextSpan).text, '12.2 ');
        final unit = root.children![1] as TextSpan;
        expect(unit.text, 'km');
        expect(unit.style!.fontSize, 18);
        expect(unit.style!.fontWeight, FontWeight.w400);
        expect(unit.style!.color, BwHud.dark.accentBright);
        expect(root.style!.fontSize, 30);
      });

      testWidgets('a drive time is not split like a distance ("18m" has no unit span)', (tester) async {
        await pumpFull(tester);
        expect(spanOf(tester, '18m').children, isNull);
        expect(spanOf(tester, '2').children, isNull);
      });

      testWidgets('dark: Trips and Distance glow cyan, Drive Time glows magenta and its label is magenta', (tester) async {
        await pumpFull(tester, theme: BladeWatchTheme.dark(), status: phev, trips: costed);
        expect(valueStyle(tester, '1')!.shadows, [BwHud.dark.glowCyan]);
        expect(valueStyle(tester, '1')!.fontSize, 30);
        expect(valueStyle(tester, '9.0 km')!.shadows, [BwHud.dark.glowCyan]);
        expect(valueStyle(tester, '13m')!.shadows, [BwHud.dark.glowMagenta]);
        expect(valueStyle(tester, '13m')!.color, BwHud.dark.driveTimeValue);
        final driveLabel = tester.widget<Text>(find.text('Drive Time'));
        expect(driveLabel.style!.color, BwHud.dark.magenta);
        // Rows 2 and 3 are 24 dp and do not glow.
        expect(valueStyle(tester, '77%')!.shadows, isNull);
        expect(valueStyle(tester, '77%')!.fontSize, 24);
        expect(valueStyle(tester, '77%')!.color, BwHud.dark.textPrimary);
        // Labels are 12 dp, normal weight in dark.
        final trips = tester.widget<Text>(find.text('Trips'));
        expect(trips.style!.fontSize, 12);
        expect(trips.style!.fontWeight, FontWeight.w400);
        expect(trips.style!.color, BwHud.dark.statLabel);
      });

      testWidgets('light: nothing glows, labels are bold, Drive Time is magenta', (tester) async {
        await pumpFull(tester, status: phev, trips: costed);
        expect(valueStyle(tester, '1')!.shadows, isNull);
        expect(valueStyle(tester, '13m')!.shadows, isNull);
        expect(valueStyle(tester, '13m')!.color, BwHud.light.magenta);
        expect(valueStyle(tester, '1')!.color, BwHud.light.textPrimary);
        final trips = tester.widget<Text>(find.text('Trips'));
        expect(trips.style!.fontWeight, FontWeight.w700);
        expect(trips.style!.color, BwHud.light.statLabel);
        expect(tester.widget<Text>(find.text('Drive Time')).style!.color, BwHud.light.magenta);
      });

      testWidgets('the header: microchip icon, THIS WEEK TELEMETRY, and a 48 dp View all target', (tester) async {
        await pumpFull(tester);
        expect(find.text('THIS WEEK TELEMETRY'), findsOneWidget);
        final card = find.ancestor(of: find.byKey(const ValueKey('tripStats.viewAll')), matching: find.byType(HudPanel)).first;
        final icon = tester.widget<Icon>(find.descendant(of: card, matching: find.byIcon(Icons.memory)));
        expect(icon.size, 14);
        expect(icon.color, BwHud.light.magenta);
        expect(tester.getSize(find.byKey(const ValueKey('tripStats.viewAll'))).height, greaterThanOrEqualTo(48));
        expect(find.descendant(of: find.byKey(const ValueKey('tripStats.viewAll')), matching: find.byIcon(Icons.chevron_right)), findsOneWidget);
      });

      testWidgets('with no rate the message replaces the cost row and the rows around it stay', (tester) async {
        await pumpFull(tester, status: phev, trips: [
          {'id': '1', 'distanceKm': 9.0, 'durationSeconds': 780},
        ]);
        expect(find.byKey(const ValueKey('tripStats.costs')), findsNothing);
        expect(find.byKey(const ValueKey('tripStats.costs.message')), findsOneWidget);
        expect(find.byKey(const ValueKey('vehicle.energy')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    group('chips', () {
      testWidgets('the recording chip shows a pulsing dot only while recording', (tester) async {
        await pumpFull(tester);
        final chip = find.byKey(const ValueKey('chip.recording'));
        expect(find.descendant(of: chip, matching: find.text('RECORDING')), findsOneWidget);
        expect(find.descendant(of: chip, matching: find.byKey(const ValueKey('chip.recordingDot'))), findsOneWidget);
        expect(find.descendant(of: chip, matching: find.byType(HudPulse)), findsOneWidget);
      });

      testWidgets('idle: the chip reads IDLE, with no dot', (tester) async {
        stubHappyPath();
        rpc.stubJson('SystemService', 'GetStatus', {'deviceId': 'byd-test', 'recording': []});
        await pumpDashboard(tester, buildController());
        await tester.pumpAndSettle();
        final chip = find.byKey(const ValueKey('chip.recording'));
        expect(find.descendant(of: chip, matching: find.text('IDLE')), findsOneWidget);
        expect(find.descendant(of: chip, matching: find.byType(HudPulse)), findsNothing);
      });

      testWidgets('chips are 4 dp boxes with the chip border, 12 dp bold uppercase, and are not buttons', (tester) async {
        await pumpFull(tester, theme: BladeWatchTheme.dark());
        final gear = find.byKey(const ValueKey('chip.gear'));
        final panel = tester.widget<HudPanel>(find.descendant(of: gear, matching: find.byType(HudPanel)));
        expect(panel.color, BwHud.dark.panel);
        expect(panel.borderColor, BwHud.dark.chipBorder);
        expect(panel.radius, 4);
        final text = tester.widget<Text>(find.descendant(of: gear, matching: find.byType(Text)));
        expect(text.style!.fontSize, 12);
        expect(text.style!.fontWeight, FontWeight.w700);
        expect(text.style!.color, BwHud.dark.textSecondary);
        expect(find.descendant(of: gear, matching: find.byType(InkWell)), findsNothing);
        expect(find.descendant(of: gear, matching: find.byType(ButtonStyleButton)), findsNothing);
        // The live recording chip has the brighter border and text.
        final rec = tester.widget<HudPanel>(find.descendant(of: find.byKey(const ValueKey('chip.recording')), matching: find.byType(HudPanel)));
        expect(rec.borderColor, BwHud.dark.panelBorderStrong);
      });

    });

    group('tiles', () {
      const keys = [
        ValueKey('tile.recordings'),
        ValueKey('tile.tunnel'),
        ValueKey('tile.daemons'),
        ValueKey('quickAction.live'),
        ValueKey('tile.vehicle'),
      ];

      testWidgets('every tile is 112 dp tall with a 4 dp radius and the tile border', (tester) async {
        await pumpFull(tester, theme: BladeWatchTheme.dark());
        for (final k in keys) {
          expect(tester.getSize(find.byKey(k)).height, 112, reason: '$k');
          final panel = tester.widget<HudPanel>(find.descendant(of: find.byKey(k), matching: find.byType(HudPanel)).first);
          expect(panel.borderColor, BwHud.dark.panelBorder);
          expect(panel.radius, 4);
          expect(panel.color, BwHud.dark.panel);
        }
      });

      testWidgets('labels are 10 dp uppercase; values are 20 dp bold uppercase', (tester) async {
        await pumpFull(tester, theme: BladeWatchTheme.dark());
        final label = tester.widget<Text>(find.descendant(of: find.byKey(const ValueKey('tile.daemons')), matching: find.text('BACKGROUND SERVICES')));
        expect(label.style!.fontSize, 10);
        expect(label.style!.color, BwHud.dark.tileLabel);
        final value = tester.widget<Text>(find.descendant(of: find.byKey(const ValueKey('tile.daemons')), matching: find.text('2/4 RUNNING')));
        expect(value.style!.fontSize, 20);
        expect(value.style!.fontWeight, FontWeight.w700);
        expect(find.descendant(of: find.byKey(const ValueKey('tile.recordings')), matching: find.text("TODAY'S RECORDINGS")), findsOneWidget);
      });

      testWidgets('the vehicle model is 12 dp and keeps its own casing', (tester) async {
        await pumpFull(tester);
        final value = tester.widget<Text>(find.descendant(of: find.byKey(const ValueKey('tile.vehicle')), matching: find.text('BYD Seal')));
        expect(value.style!.fontSize, 12);
        expect(value.style!.fontWeight, FontWeight.w700);
      });

      testWidgets('dark: LIVE is white with a magenta glow over a magenta icon; ONLINE glows cyan', (tester) async {
        channel.stub('daemon', 'pearStatus', {'status': 'ok', 'enabled': true, 'running': true, 'reachable': true});
        await pumpFull(tester, theme: BladeWatchTheme.dark());
        final live = find.byKey(const ValueKey('quickAction.live'));
        final liveValue = tester.widget<Text>(find.descendant(of: live, matching: find.text('LIVE')));
        expect(liveValue.style!.color, BwHud.dark.liveValue);
        expect(liveValue.style!.shadows, [BwHud.dark.glowMagenta]);
        expect(tester.widget<Icon>(find.descendant(of: live, matching: find.byType(Icon))).color, BwHud.dark.magenta);
        final online = tester.widget<Text>(find.descendant(of: find.byKey(const ValueKey('tile.tunnel')), matching: find.text('ONLINE')));
        expect(online.style!.shadows, [BwHud.dark.glowCyan]);
      });

      testWidgets('light: LIVE is magenta and ONLINE cyan-700, neither glowing', (tester) async {
        channel.stub('daemon', 'pearStatus', {'status': 'ok', 'enabled': true, 'running': true, 'reachable': true});
        await pumpFull(tester);
        final liveValue = tester.widget<Text>(find.descendant(of: find.byKey(const ValueKey('quickAction.live')), matching: find.text('LIVE')));
        expect(liveValue.style!.color, BwHud.light.magenta);
        expect(liveValue.style!.shadows, isNull);
        final online = tester.widget<Text>(find.descendant(of: find.byKey(const ValueKey('tile.tunnel')), matching: find.text('ONLINE')));
        expect(online.style!.color, BwHud.light.onlineValue);
        expect(online.style!.shadows, isNull);
      });

      testWidgets('the remote status dot glows and is 10 dp; absent when offline', (tester) async {
        channel.stub('daemon', 'pearStatus', {'status': 'ok', 'enabled': true, 'running': true, 'reachable': true});
        await pumpFull(tester, theme: BladeWatchTheme.dark());
        final dot = find.byKey(const ValueKey('tile.statusDot'));
        expect(tester.getSize(dot), const Size(10, 10));
        final deco = tester.widget<Container>(dot).decoration! as BoxDecoration;
        expect(deco.color, BwHud.dark.dot);
        expect(deco.boxShadow!.single.color, BwHud.dark.dotGlow);
      });
    });

    group('appearance switch', () {
      testWidgets('dark to light restyles the open Dashboard and moves nothing', (tester) async {
        stubHappyPath();
        rpc.stubJson('SystemService', 'GetStatus', {...phev, 'deviceId': 'byd-test'});
        rpc.stubJson('TripsService', 'ListTrips', {'success': true, 'trips': costed});
        final controller = buildController();
        await pumpDashboard(tester, controller, theme: BladeWatchTheme.dark());
        await tester.pumpAndSettle();

        final watched = [
          find.byKey(const ValueKey('dashboard.title')),
          find.byKey(const ValueKey('vehicle.energy')),
          find.byKey(const ValueKey('chip.gear')),
          find.byKey(const ValueKey('tile.recordings')),
          find.byKey(const ValueKey('tile.vehicle')),
        ];
        final before = [for (final f in watched) tester.getRect(f)];
        Color? scaffold() => tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor;
        expect(scaffold(), BwHud.dark.pageBackground);
        expect(valueStyle(tester, '13m')!.shadows, [BwHud.dark.glowMagenta]);

        // The SAME controller and tree, only the theme changes (Settings > Appearance).
        await tester.pumpWidget(wrap(controller, theme: BladeWatchTheme.light()));
        await tester.pumpAndSettle();

        expect(scaffold(), BwHud.light.pageBackground);
        expect(valueStyle(tester, '13m')!.shadows, isNull);
        expect(valueStyle(tester, '13m')!.color, BwHud.light.magenta);
        expect([for (final f in watched) tester.getRect(f)], before, reason: 'no layout shift');
        expect(tester.takeException(), isNull);
      });
    });

    group('layout', () {
      Future<void> pumpAt(WidgetTester tester, Size size) async {
        stubHappyPath();
        rpc.stubJson('SystemService', 'GetStatus', {...phev, 'deviceId': 'byd-test'});
        rpc.stubJson('TripsService', 'ListTrips', {'success': true, 'trips': costed});
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        await tester.pumpWidget(wrap(buildController()));
        await tester.pumpAndSettle();
      }

      // The owner asked whether a cost with more digits breaks the layout (2026-10-04). The test font
      // is wider than Space Mono, so a cost that keeps to one line here keeps to one on the car.
      testWidgets('head unit landscape: a seven-digit cost keeps to one line, nothing overflows', (tester) async {
        stubHappyPath();
        rpc.stubJson('SystemService', 'GetStatus', {...phev, 'deviceId': 'byd-test'});
        rpc.stubJson('TripsService', 'ListTrips', {
          'success': true,
          'trips': [
            {'id': '1', 'distanceKm': 9.0, 'durationSeconds': 780, 'tripCost': 1234567.89, 'fuelCost': 1234517.93, 'currency': 'PHP', 'hasFuelData': true},
          ],
        });
        tester.view.physicalSize = const Size(1200, 604);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        await tester.pumpWidget(wrap(buildController()));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final cost in ['₱1,234,567.89', '₱1,234,517.93']) {
          final text = find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText() == cost);
          expect(text, findsOneWidget, reason: cost);
          expect(tester.getSize(text).height, lessThanOrEqualTo(32), reason: '$cost on one 32 dp line');
        }
      });

      testWidgets('head unit landscape (the page beside the 80 dp rail): no overflow, one row of five tiles', (tester) async {
        await pumpAt(tester, const Size(1200, 604));
        expect(tester.takeException(), isNull);
        final tops = {for (final k in ['tile.recordings', 'tile.tunnel', 'tile.daemons', 'quickAction.live', 'tile.vehicle']) tester.getTopLeft(find.byKey(ValueKey(k))).dy};
        expect(tops, hasLength(1));
      });

      testWidgets('blocks run title, card, chips, tiles down the page', (tester) async {
        await pumpAt(tester, const Size(1200, 900));
        final title = tester.getRect(find.byKey(const ValueKey('dashboard.title'))).top;
        final card = tester.getRect(find.byKey(const ValueKey('vehicle.energy'))).top;
        final chip = tester.getRect(find.byKey(const ValueKey('chip.gear'))).top;
        final tile = tester.getRect(find.byKey(const ValueKey('tile.recordings'))).top;
        expect(title, lessThan(card));
        expect(card, lessThan(chip));
        expect(chip, lessThan(tile));
      });

      testWidgets('a tall window spreads the blocks: the tiles sit at the bottom edge', (tester) async {
        await pumpAt(tester, const Size(1200, 1100));
        final tiles = tester.getRect(find.byKey(const ValueKey('tile.recordings')));
        expect(tiles.bottom, closeTo(1100 - 24, 1), reason: 'the reference spreads with justify-between');
      });

      testWidgets('a short window scrolls instead of overflowing', (tester) async {
        await pumpAt(tester, const Size(1200, 300));
        expect(tester.takeException(), isNull);
        expect(tester.state<ScrollableState>(find.byType(Scrollable).first).position.maxScrollExtent, greaterThan(0));
      });

      testWidgets('portrait 720x1280: no overflow, tiles wrap two to a row', (tester) async {
        await pumpAt(tester, const Size(720, 1280));
        expect(tester.takeException(), isNull);
        final recordings = tester.getTopLeft(find.byKey(const ValueKey('tile.recordings')));
        final tunnel = tester.getTopLeft(find.byKey(const ValueKey('tile.tunnel')));
        final daemons = tester.getTopLeft(find.byKey(const ValueKey('tile.daemons')));
        expect(tunnel.dy, recordings.dy, reason: 'two to a row');
        expect(daemons.dy, greaterThan(recordings.dy));
      });
    });
  });
}
