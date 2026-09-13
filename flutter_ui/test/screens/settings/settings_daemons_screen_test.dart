import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/platform/config_channel.dart';
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
      SettingsDaemonsController(daemonChannel: DaemonChannel(channel), configChannel: ConfigChannel(channel), setDaemonEnabled: setDaemonEnabled);

  Future<void> pumpTall(WidgetTester tester, SettingsDaemonsController controller) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      theme: BladeWatchTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SettingsDaemonsScreen(controller: controller)),
    ));
  }

  testWidgets('renders all 4 daemon rows with their running state', (tester) async {
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': true, 'ZROK_TUNNEL': false},
    });
    await pumpTall(tester, buildController());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('daemon.camera')), findsOneWidget);
    expect(find.byKey(const ValueKey('daemon.sentry')), findsOneWidget);
    expect(find.byKey(const ValueKey('daemon.accSentry')), findsOneWidget);
    expect(find.byKey(const ValueKey('daemon.zrokTunnel')), findsOneWidget);
    expect(find.text('2 of 4 running'), findsOneWidget);
  });

  testWidgets('a processStatus failure still renders the 4 rows, all stopped', (tester) async {
    channel.stubError('daemon', 'processStatus', const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'down'));
    await pumpTall(tester, buildController());
    await tester.pumpAndSettle();

    expect(find.text('0 of 4 running'), findsOneWidget);
  });

  testWidgets('toggling a non-Zrok daemon without a capability shows the unsupported message', (tester) async {
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': false},
    });
    await pumpTall(tester, buildController());
    await tester.pumpAndSettle();

    await tester.tap(find.descendant(of: find.byKey(const ValueKey('daemon.sentry')), matching: find.byType(Switch)));
    await tester.pump();

    expect(find.textContaining('isn’t supported yet'), findsOneWidget);
  });

  testWidgets('toggling with an injected capability flips the switch', (tester) async {
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': false},
    });
    final controller = buildController(setDaemonEnabled: (kind, enabled) async => true);
    await pumpTall(tester, controller);
    await tester.pumpAndSettle();
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': true, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': false},
    });

    await tester.tap(find.descendant(of: find.byKey(const ValueKey('daemon.sentry')), matching: find.byType(Switch)));
    await tester.pumpAndSettle();

    final sw = tester.widget<Switch>(find.descendant(of: find.byKey(const ValueKey('daemon.sentry')), matching: find.byType(Switch)));
    expect(sw.value, isTrue);
  });

  testWidgets('the Zrok row shows a configure button instead of a switch', (tester) async {
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': false},
    });
    await pumpTall(tester, buildController());
    await tester.pumpAndSettle();

    expect(find.descendant(of: find.byKey(const ValueKey('daemon.zrokTunnel')), matching: find.byType(Switch)), findsNothing);
    expect(find.byKey(const ValueKey('daemon.zrok.configure')), findsOneWidget);
  });

  testWidgets('opening the Zrok dialog pre-fills the current token and saves a new one', (tester) async {
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': false},
    });
    channel.stub('config', 'get', 'old-token');
    channel.stub('config', 'put', true);
    await pumpTall(tester, buildController());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('daemon.zrok.configure')));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'old-token'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('zrok.tokenField')), 'new-token');
    await tester.tap(find.byKey(const ValueKey('zrok.save')));
    await tester.pumpAndSettle();

    final call = channel.calls.firstWhere((c) => c.method == 'put');
    expect((call.args as Map)['value'], 'new-token');
  });

  testWidgets('tapping Delete in the Zrok dialog deletes the token', (tester) async {
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': false},
    });
    channel.stub('config', 'get', 'a-token');
    channel.stub('config', 'delete', true);
    await pumpTall(tester, buildController());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('daemon.zrok.configure')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(channel.calls.any((c) => c.method == 'delete'), isTrue);
    expect(find.text('Token deleted'), findsOneWidget);
  });

  testWidgets('saving an empty Zrok token shows a validation message without calling the channel', (tester) async {
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': false},
    });
    channel.stub('config', 'get', null);
    await pumpTall(tester, buildController());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('daemon.zrok.configure')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('zrok.save')));
    await tester.pumpAndSettle();

    expect(find.text('Token cannot be empty'), findsOneWidget);
    expect(channel.calls.where((c) => c.method == 'put'), isEmpty);
  });

  testWidgets('resetting the Zrok environment goes through a confirmation dialog', (tester) async {
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': false, 'SENTRY_DAEMON': false, 'ACC_SENTRY_DAEMON': false, 'ZROK_TUNNEL': true},
    });
    channel.stub('config', 'get', 'a-token');
    channel.stub('config', 'delete', true);
    final controller = buildController(setDaemonEnabled: (kind, enabled) async => true);
    await pumpTall(tester, controller);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('daemon.zrok.configure')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('zrok.resetEnvironment')));
    await tester.pumpAndSettle();

    expect(find.text('Reset Zrok Environment'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('zrok.confirmReset')));
    await tester.pumpAndSettle();

    expect(channel.calls.any((c) => c.method == 'delete'), isTrue);
    expect(find.text('Zrok environment reset. Enter a new token to set up again.'), findsOneWidget);
  });

  testWidgets('renders without error in dark theme', (tester) async {
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': true, 'ACC_SENTRY_DAEMON': true, 'ZROK_TUNNEL': true},
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
}
