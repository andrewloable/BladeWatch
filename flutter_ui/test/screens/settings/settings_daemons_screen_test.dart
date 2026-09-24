import 'dart:io';
import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/platform/daemon_channel.dart';
import 'package:bladewatch_ui/screens/settings/settings_daemons_controller.dart';
import 'package:bladewatch_ui/screens/settings/settings_daemons_models.dart';
import 'package:bladewatch_ui/screens/settings/settings_daemons_screen.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_platform_channel.dart';

void main() {
  late FakePlatformChannel channel;

  setUp(() {
    channel = FakePlatformChannel();
  });

  SettingsDaemonsController buildController({Future<bool> Function(DaemonKind, bool)? setDaemonEnabled}) =>
      SettingsDaemonsController(daemonChannel: DaemonChannel(channel), setDaemonEnabled: setDaemonEnabled);

  Future<void> pumpTall(
    WidgetTester tester,
    SettingsDaemonsController controller, {
    Future<String> Function(String path)? logReader,
    Locale? locale,
  }) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      theme: BladeWatchTheme.light(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SettingsDaemonsScreen(controller: controller, logReader: logReader)),
    ));
  }

  testWidgets('renders all 5 daemon rows with their running state', (tester) async {
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': true, 'TOR_TUNNEL': false, 'PEAR_PEER': false},
    });
    await pumpTall(tester, buildController());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('daemon.camera')), findsOneWidget);
    expect(find.byKey(const ValueKey('daemon.sentry')), findsOneWidget);
    expect(find.byKey(const ValueKey('daemon.accSentry')), findsOneWidget);
    expect(find.byKey(const ValueKey('daemon.torTunnel')), findsOneWidget);
    expect(find.byKey(const ValueKey('daemon.pearPeer')), findsOneWidget);
    expect(find.text('Remote access (Pear)'), findsOneWidget);
    expect(find.text('2 of 5 running'), findsOneWidget);
  });

  // BladeWatch-rdtj.17: running and reachable are different questions.
  testWidgets('a running Pear peer shows reachability, connected devices and the last connection', (tester) async {
    channel
      ..stub('daemon', 'processStatus', {'daemons': {'PEAR_PEER': true}, 'enabled': {'PEAR_PEER': true}})
      ..stub('daemon', 'pearStatus', {
        'running': true,
        'enabled': true,
        'reachable': false,
        'companions': 2,
        'lastCompanionAt': DateTime(2026, 9, 24, 14, 5).millisecondsSinceEpoch,
      });
    await pumpTall(tester, buildController());
    await tester.pumpAndSettle();

    final row = find.byKey(const ValueKey('daemon.pearPeer'));
    String subtitle() =>
        (tester.widget<ListTile>(find.descendant(of: row, matching: find.byType(ListTile))).subtitle! as Text).data!;
    expect(subtitle(), contains('Running'));
    expect(subtitle(), contains('Not reachable: no connection to the Pear network'),
        reason: 'the process is up but the car cannot be found');
    expect(subtitle(), contains('2 devices connected'));
    expect(subtitle(), contains('Last connection: Sep 24, 14:05'));
    expect(find.byIcon(Icons.hub_outlined), findsOneWidget);
  });

  testWidgets('Pear: reachable, unknown, and switched on but not up yet', (tester) async {
    channel
      ..stub('daemon', 'processStatus', {'daemons': {'PEAR_PEER': true}, 'enabled': {'PEAR_PEER': true}})
      ..stub('daemon', 'pearStatus', {'running': true, 'enabled': true, 'reachable': true, 'companions': 1});
    final c = buildController();
    await pumpTall(tester, c);
    await tester.pumpAndSettle();
    final row = find.byKey(const ValueKey('daemon.pearPeer'));
    String subtitle() =>
        (tester.widget<ListTile>(find.descendant(of: row, matching: find.byType(ListTile))).subtitle! as Text).data!;
    expect(subtitle(), contains('Reachable from anywhere'));
    expect(subtitle(), contains('1 device connected'));
    expect(subtitle(), isNot(contains('Last connection')));

    channel.stub('daemon', 'pearStatus', {'running': true, 'enabled': true, 'reachable': null});
    await c.refresh();
    await tester.pumpAndSettle();
    expect(subtitle(), contains('Reachability unknown'));
    expect(subtitle(), contains('No devices connected'));

    channel.stub('daemon', 'processStatus', {'daemons': {'PEAR_PEER': false}, 'enabled': {'PEAR_PEER': true}});
    await c.refresh();
    await tester.pumpAndSettle();
    expect(subtitle(), 'Starting', reason: 'switched on, not up yet -- and not "Starting Tor tunnel"');
  });

  testWidgets('a processStatus failure still renders the 5 rows, all stopped', (tester) async {
    channel.stubError('daemon', 'processStatus', const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'down'));
    await pumpTall(tester, buildController());
    await tester.pumpAndSettle();

    expect(find.text('0 of 5 running'), findsOneWidget);
  });

  testWidgets('toggling a non-tunnel daemon without a capability shows the unsupported message', (tester) async {
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'TOR_TUNNEL': false},
    });
    await pumpTall(tester, buildController());
    await tester.pumpAndSettle();

    await tester.tap(find.descendant(of: find.byKey(const ValueKey('daemon.sentry')), matching: find.byType(Switch)));
    await tester.pump();

    expect(find.textContaining('isn’t supported yet'), findsOneWidget);
  });

  // BladeWatch-dh1r. Observed on the head unit: the row read "Waiting" with the switch
  // OFF while tor was running. Enabling only RECORDS INTENT — the daemon's health check
  // launches on its next cycle and tor then needs up to a minute to bootstrap (61 s cold,
  // measured) — so a switch bound to liveness springs straight back to off. The user's
  // natural second tap then DISABLES the tunnel they just enabled, because the disable
  // path also kills the process. That is why the switch follows `enabled`, not `running`.
  testWidgets('the tunnel switch stays ON while tor is enabled but still starting', (tester) async {
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'TOR_TUNNEL': false},
      'enabled': {'TOR_TUNNEL': true},
    });
    final controller = buildController(setDaemonEnabled: (kind, enabled) async => true);
    await pumpTall(tester, controller);
    await tester.pumpAndSettle();

    expect(
      tester.widget<Switch>(find.byKey(const ValueKey('daemon.TOR_TUNNEL.toggle'))).value,
      isTrue,
      reason: 'enabled but not yet running must read as ON, or the user turns it off again',
    );
  });

  testWidgets('a tunnel the user disabled reads as OFF even mid-shutdown', (tester) async {
    // The mirror case: the process is still alive for a moment after the kill, but the
    // user has said off, and the switch must say off.
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'TOR_TUNNEL': true},
      'enabled': {'TOR_TUNNEL': false},
    });
    final controller = buildController(setDaemonEnabled: (kind, enabled) async => true);
    await pumpTall(tester, controller);
    await tester.pumpAndSettle();

    expect(
      tester.widget<Switch>(find.byKey(const ValueKey('daemon.TOR_TUNNEL.toggle'))).value,
      isFalse,
    );
  });

  testWidgets('the row distinguishes starting from simply stopped', (tester) async {
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'TOR_TUNNEL': false},
      'enabled': {'TOR_TUNNEL': true},
    });
    final controller = buildController();
    await pumpTall(tester, controller);
    await tester.pumpAndSettle();

    // "Starting" rather than "Waiting": the row must not look like the toggle failed.
    expect(find.text('Starting Tor tunnel…'), findsOneWidget);
  });

  // The daemons the user cannot toggle have no intent to show, so they keep reporting
  // what is actually true — otherwise a running camera daemon would read as off.
  testWidgets('non-toggleable rows still show liveness on their switch', (tester) async {
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': true, 'ACC_SENTRY_DAEMON': true, 'TOR_TUNNEL': false},
      'enabled': {'TOR_TUNNEL': false},
    });
    final controller = buildController();
    await pumpTall(tester, controller);
    await tester.pumpAndSettle();

    expect(
      tester.widget<Switch>(find.byKey(const ValueKey('daemon.CAMERA_DAEMON.toggle'))).value,
      isTrue,
    );
  });

  testWidgets('toggling the Tor tunnel flips its switch', (tester) async {
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'TOR_TUNNEL': false},
    });
    final controller = buildController(setDaemonEnabled: (kind, enabled) async => true);
    await pumpTall(tester, controller);
    await tester.pumpAndSettle();
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'TOR_TUNNEL': true},
    });

    await tester.tap(find.byKey(const ValueKey('daemon.TOR_TUNNEL.toggle')));
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byKey(const ValueKey('daemon.TOR_TUNNEL.toggle'))).value, isTrue);
  });

  // BladeWatch-abcx: the other three keep a switch so their state stays visible, but
  // toggling one explains itself instead of pretending to work. The reasons are
  // structural (see DaemonKind.canToggle), not missing wiring.
  testWidgets('toggling a non-toggleable daemon explains itself and leaves it running', (tester) async {
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': true, 'ACC_SENTRY_DAEMON': true, 'TOR_TUNNEL': false},
    });
    var capabilityCalls = 0;
    final controller = buildController(setDaemonEnabled: (kind, enabled) async {
      capabilityCalls++;
      return true;
    });
    await pumpTall(tester, controller);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('daemon.SENTRY_DAEMON.toggle')));
    await tester.pumpAndSettle();

    expect(find.textContaining('isn’t supported yet'), findsOneWidget);
    expect(capabilityCalls, 0);
    expect(tester.widget<Switch>(find.byKey(const ValueKey('daemon.SENTRY_DAEMON.toggle'))).value, isTrue,
        reason: 'the daemon is still running, so the switch must stay on');
  });

  testWidgets('the Tor row has a working switch and only a log button', (tester) async {
    // The configure button and its token dialog went with the previous tunnel: a Tor
    // onion service has no account, no token and nothing to configure. Counting the
    // buttons is the guard — a leftover settings button would show up here.
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'TOR_TUNNEL': false},
    });
    await pumpTall(tester, buildController());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('daemon.TOR_TUNNEL.toggle')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('daemon.torTunnel')),
        matching: find.byType(IconButton),
      ),
      findsOneWidget,
      reason: 'only the log button — no configure button survives',
    );
    expect(find.byIcon(Icons.settings), findsNothing);
  });

  testWidgets('renders without error in dark theme', (tester) async {
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': true, 'ACC_SENTRY_DAEMON': true, 'TOR_TUNNEL': true},
    });
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      theme: BladeWatchTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SettingsDaemonsScreen(controller: buildController())),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  // ── BladeWatch-b05u: native Services parity ────────────────────────────────

  testWidgets('rows use native service names, not the startup screen labels', (tester) async {
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': true, 'ACC_SENTRY_DAEMON': true, 'TOR_TUNNEL': false},
    });
    await pumpTall(tester, buildController());
    await tester.pumpAndSettle();

    // DaemonAdapter.getDaemonDisplayName, now via daemon_name_* on both sides
    // (BladeWatch-def0). Read from l10n rather than literals so this asserts
    // "the row shows the service name" rather than pinning English — the strings
    // are translated in all 19 catalogs now.
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.text(l10n.daemon_name_camera), findsOneWidget);
    expect(find.text(l10n.daemon_name_surveillance), findsOneWidget);
    expect(find.text(l10n.daemon_name_acc), findsOneWidget);
    expect(find.text(l10n.daemon_name_tor), findsOneWidget);

    // The startup screen's short labels are different words for the same
    // daemons and must not reappear here.
    expect(find.text(l10n.startup_daemon_sentry), findsNothing);
    expect(find.text(l10n.startup_daemon_parking), findsNothing);
  });

  testWidgets('the service names come from the catalog, so they localise', (tester) async {
    // BladeWatch-def0: these were literals in both UIs, so they stayed English
    // in all 17 locales. Pumping a non-English locale is what proves the fix —
    // asserting the English strings alone would still pass with hardcoded text.
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': true, 'ACC_SENTRY_DAEMON': true, 'TOR_TUNNEL': false},
    });
    await pumpTall(tester, buildController(), locale: const Locale('de'));
    await tester.pumpAndSettle();

    final de = await AppLocalizations.delegate.load(const Locale('de'));
    expect(de.daemon_name_camera, isNot('Camera Daemon'), reason: 'the German catalog must differ');
    expect(find.text(de.daemon_name_camera), findsOneWidget);
    expect(find.text(de.daemon_name_surveillance), findsOneWidget);
    expect(find.text(de.daemon_name_acc), findsOneWidget);

    // Tor is a product name and stays verbatim in every locale.
    expect(de.daemon_name_tor, 'Tor Tunnel');
    expect(find.text('Tor Tunnel'), findsOneWidget);
  });

  testWidgets('a live service says Running, not Ready', (tester) async {
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'TOR_TUNNEL': false},
    });
    await pumpTall(tester, buildController());
    await tester.pumpAndSettle();

    // "Ready" reads as "available to start", the opposite of what it meant.
    expect(
      find.descendant(of: find.byKey(const ValueKey('daemon.camera')), matching: find.text('Running')),
      findsOneWidget,
    );
    expect(find.text('Ready'), findsNothing);
  });

  testWidgets('every row has a per-service log button', (tester) async {
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': true, 'ACC_SENTRY_DAEMON': true, 'TOR_TUNNEL': true},
    });
    await pumpTall(tester, buildController());
    await tester.pumpAndSettle();

    for (final kind in const ['camera', 'sentry', 'accSentry', 'torTunnel']) {
      expect(find.byKey(ValueKey('daemon.$kind.log')), findsOneWidget, reason: '$kind needs a log button');
    }
  });

  testWidgets('the log button shows that service\'s log', (tester) async {
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': true, 'ACC_SENTRY_DAEMON': true, 'TOR_TUNNEL': true},
    });
    final requested = <String>[];
    await pumpTall(
      tester,
      buildController(),
      logReader: (path) async {
        requested.add(path);
        return 'camera daemon started\nframe 1\n';
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('daemon.camera.log')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('daemon.logDialog')), findsOneWidget);
    expect(find.textContaining('frame 1'), findsOneWidget);
    // The exact path native uses for this daemon (DaemonAdapter.getLogFilePath).
    expect(requested, ['/data/local/tmp/cam_daemon.log']);

    // Every kind must map to its own log, including the tunnel — a single
    // wrong path here would silently show one service's log under another's
    // name.
    await tester.tap(find.text('DONE'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('daemon.torTunnel.log')));
    await tester.pumpAndSettle();
    expect(requested.last, '/data/local/tmp/tor.log');
  });

  testWidgets('an unreadable log says so rather than claiming it is empty', (tester) async {
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': true, 'ACC_SENTRY_DAEMON': true, 'TOR_TUNNEL': true},
    });
    await pumpTall(
      tester,
      buildController(),
      logReader: (_) async => throw const FileSystemException('nope'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('daemon.sentry.log')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Log file not found or unreadable'), findsOneWidget);
  });

  testWidgets('an empty log says it is empty', (tester) async {
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': true, 'ACC_SENTRY_DAEMON': true, 'TOR_TUNNEL': true},
    });
    await pumpTall(tester, buildController(), logReader: (_) async => '   \n');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('daemon.accSentry.log')));
    await tester.pumpAndSettle();

    expect(find.text('Log file is empty'), findsOneWidget);
  });
}
