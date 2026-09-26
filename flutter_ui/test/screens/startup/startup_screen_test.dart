import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/platform/daemon_channel.dart';
import 'package:bladewatch_ui/screens/startup/startup_controller.dart';
import 'package:bladewatch_ui/screens/startup/startup_screen.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_platform_channel.dart';

void main() {
  late FakePlatformChannel fakeChannel;

  void stubStatuses({bool camera = false, bool sentry = false, bool accSentry = false}) {
    fakeChannel.stub('daemon', 'processStatus', {
      'status': 'ok',
      'daemons': {
        'CAMERA_DAEMON': camera,
        'SENTRY_DAEMON': sentry,
        'ACC_SENTRY_DAEMON': accSentry,
        'PEAR_PEER': false,
      },
    });
  }

  setUp(() {
    fakeChannel = FakePlatformChannel();
    stubStatuses();
  });

  StartupController buildController({Future<bool> Function()? healthCheck}) {
    return StartupController(
      daemonChannel: DaemonChannel(fakeChannel),
      healthCheck: healthCheck ?? () async => true,
    );
  }

  Widget wrap(Widget child) => MaterialApp(
        theme: BladeWatchTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      );

  testWidgets('preparing state: shows the brand name, subtitle, and all 3 daemon rows waiting',
      (tester) async {
    final controller = buildController();
    await tester.pumpWidget(wrap(StartupScreen(controller: controller, onReadyToNavigate: () {})));
    await tester.pump();

    expect(find.text('BladeWatch'), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
    expect(find.text('Sentry Mode'), findsOneWidget);
    expect(find.text('Parking Guard'), findsOneWidget);
    expect(find.text('Waiting'), findsNWidgets(3));
    expect(find.text('Getting things ready…'), findsOneWidget);

    await tester.pumpWidget(Container());
  });

  testWidgets('starting state: a running daemon shows Ready, the others still show Waiting',
      (tester) async {
    stubStatuses(camera: true);
    final controller = buildController();
    await tester.pumpWidget(wrap(StartupScreen(controller: controller, onReadyToNavigate: () {})));
    await tester.pump();

    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Waiting'), findsNWidgets(2));
    expect(find.text('Starting up…'), findsOneWidget);

    await tester.pumpWidget(Container());
  });

  testWidgets('verifying state: shows the verifying header and all 3 rows ready', (tester) async {
    stubStatuses(camera: true, sentry: true, accSentry: true);
    final controller = buildController(healthCheck: () async => false);
    await tester.pumpWidget(wrap(StartupScreen(controller: controller, onReadyToNavigate: () {})));
    await tester.pump();

    expect(find.text('Ready'), findsNWidgets(3));
    expect(find.text('Almost ready…'), findsOneWidget);

    await tester.pumpWidget(Container());
  });

  testWidgets('ready state: shows the ready header and hides the progress indicator', (tester) async {
    stubStatuses(camera: true, sentry: true, accSentry: true);
    final controller = buildController(healthCheck: () async => true);
    await tester.pumpWidget(wrap(StartupScreen(controller: controller, onReadyToNavigate: () {})));
    await tester.pump();

    expect(find.text("Everything's ready"), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.pumpWidget(Container());
  });

  testWidgets('calls onReadyToNavigate exactly once when the controller signals it is time',
      (tester) async {
    stubStatuses(camera: true, sentry: true, accSentry: true);
    var navigateCalls = 0;
    final controller = buildController(healthCheck: () async => true);
    await tester.pumpWidget(
      wrap(StartupScreen(controller: controller, onReadyToNavigate: () => navigateCalls++)),
    );
    await tester.pump();
    expect(navigateCalls, 0, reason: 'ready state alone must not navigate yet — see the 1500ms delay');

    controller.continueAnyway(); // deterministic way to flip navigateToDashboard without real timers
    await tester.pump();

    expect(navigateCalls, 1);

    await tester.pumpWidget(Container());
  });

  /// BladeWatch-t7js: this used to assert the raw exception text was rendered. It was —
  /// on the head unit the header read "PlatformChannelError(daemonNotUp): connect to
  /// 127.0.0.1:19876 failed ... ECONNREFUSED" in red, directly under "Getting your dashcam
  /// ready". daemonNotUp is the expected answer to every poll until CameraDaemon binds
  /// 19876, roughly the first 45s after boot, so the screen was calling its own normal
  /// startup an error. It must now show ordinary progress.
  testWidgets('channel error: shows normal progress, never raw exception text', (tester) async {
    fakeChannel.stubError(
      'daemon',
      'processStatus',
      const PlatformChannelError(PlatformChannelErrorReason.daemonNotUp, 'daemon not up'),
    );
    final controller = buildController();
    await tester.pumpWidget(wrap(StartupScreen(controller: controller, onReadyToNavigate: () {})));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Getting things ready…'), findsOneWidget);
    for (final leak in ['daemon not up', 'PlatformChannelError', 'ECONNREFUSED', '19876']) {
      expect(find.textContaining(leak), findsNothing, reason: 'leaked "$leak" to the driver');
    }

    await tester.pumpWidget(Container());
  });

  testWidgets('continue-anyway button is hidden until the controller says to show it', (tester) async {
    final controller = buildController();
    await tester.pumpWidget(wrap(StartupScreen(controller: controller, onReadyToNavigate: () {})));
    await tester.pump();

    expect(find.text('Continue anyway'), findsNothing);

    await tester.pumpWidget(Container());
  });

  testWidgets('renders correctly in dark theme', (tester) async {
    final controller = buildController();
    await tester.pumpWidget(MaterialApp(
      theme: BladeWatchTheme.light(),
      darkTheme: BladeWatchTheme.dark(),
      themeMode: ThemeMode.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: StartupScreen(controller: controller, onReadyToNavigate: () {}),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('BladeWatch'), findsOneWidget);
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, BladeWatchTheme.dark().colorScheme.surface);

    await tester.pumpWidget(Container());
  });

  testWidgets('every key resolves in a CJK locale (ja) with no missing-translation errors',
      (tester) async {
    final controller = buildController();
    await tester.pumpWidget(MaterialApp(
      theme: BladeWatchTheme.light(),
      locale: const Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: StartupScreen(controller: controller, onReadyToNavigate: () {}),
    ));
    await tester.pump();

    expect(tester.takeException(), isNull);
    // The ARB value for startup_subtitle in Japanese -- proves the real
    // AppLocalizations lookup resolved for this locale, not just that the
    // key exists in the raw ARB JSON.
    expect(find.text('ドライブレコーダーを準備しています'), findsOneWidget);

    await tester.pumpWidget(Container());
  });

  testWidgets('tapping the continue-anyway button calls controller.continueAnyway()', (tester) async {
    // continueAnywayDelay: Duration.zero — the button-visible threshold is
    // already covered by StartupController's own timing tests; here we only
    // need it visible so this test can assert the tap wiring.
    final controller = StartupController(
      daemonChannel: DaemonChannel(fakeChannel),
      continueAnywayDelay: Duration.zero,
      healthCheck: () async => true,
    );
    await tester.pumpWidget(wrap(StartupScreen(controller: controller, onReadyToNavigate: () {})));
    await tester.pump();

    expect(find.text('Continue anyway'), findsOneWidget);
    await tester.tap(find.text('Continue anyway'));
    await tester.pump();

    expect(controller.navigateToDashboard, isTrue);

    await tester.pumpWidget(Container());
  });
}
