import 'package:bladewatch_ui/gen/l10n/app_localizations.dart';
import 'package:bladewatch_ui/platform/config_channel.dart';
import 'package:bladewatch_ui/platform/daemon_channel.dart';
import 'package:bladewatch_ui/platform/prefs_channel.dart';
import 'package:bladewatch_ui/platform/public_config_channel.dart';
import 'package:bladewatch_ui/rpc/jwt_source.dart';
import 'package:bladewatch_ui/rpc/raw_http_sender.dart';
import 'package:bladewatch_ui/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_ui/rpc/services/safe_locations_service_client.dart';
import 'package:bladewatch_ui/rpc/services/settings_service_client.dart';
import 'package:bladewatch_ui/rpc/services/storage_service_client.dart';
import 'package:bladewatch_ui/rpc/services/surveillance_service_client.dart';
import 'package:bladewatch_ui/rpc/services/system_service_client.dart';
import 'package:bladewatch_ui/rpc/services/trips_service_client.dart';
import 'package:bladewatch_ui/screens/settings/settings_appearance_screen.dart';
import 'package:bladewatch_ui/screens/settings/settings_daemons_screen.dart';
import 'package:bladewatch_ui/screens/settings/settings_overlay_screen.dart';
import 'package:bladewatch_ui/screens/settings/settings_privacy_screen.dart';
import 'package:bladewatch_ui/screens/settings/settings_recording_screen.dart';
import 'package:bladewatch_ui/screens/settings/settings_appearance_controller.dart';
import 'package:bladewatch_ui/screens/settings/settings_screen.dart';
import 'package:bladewatch_ui/screens/trips/trips_controller.dart';
import 'package:bladewatch_ui/screens/surveillance/surveillance_screen.dart';
import 'package:bladewatch_ui/shell/shell_controller.dart';
import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:bladewatch_ui/shell/locale_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_platform_channel.dart';
import '../../fakes/fake_rpc_client.dart';

class _MemLocaleStore implements LocaleStore {
  String? _tag;
  @override
  Future<String?> readRaw() async => _tag;
  @override
  Future<bool> writeRaw(String tag) async {
    _tag = tag;
    return true;
  }
}

class _FakeJwtSource implements JwtSource {
  @override
  Future<String?> mintJwt() async => 'fake.jwt.token';

  @override
  Future<int> stateVersion() async => 0;
}

void main() {
  late FakeRpcClient rpc;
  late FakePlatformChannel channel;
  late bool languageOpened;

  setUp(() {
    rpc = FakeRpcClient();
    channel = FakePlatformChannel();
    languageOpened = false;
    channel.stub('prefs', 'getThemeMode', null);
    channel.stub('prefs', 'getDriveSide', null);
    channel.stub('publicConfig', 'getSection', <Object?, Object?>{});
    channel.stub('publicConfig', 'putBoolean', true);
    channel.stub('daemon', 'processStatus', {
      'daemons': {'CAMERA_DAEMON': true, 'SENTRY_DAEMON': true, 'ACC_SENTRY_DAEMON': true, 'TOR_TUNNEL': false},
    });
    rpc.stubJson('SystemService', 'GetStatus', {'recordingStatus': {}});
    rpc.stubJson('RecordingsService', 'GetStats', {'stats': {}});
    rpc.stubJson('SettingsService', 'GetQuality', {});
    rpc.stubJson('StorageService', 'GetStorageSettings', {'recordingsCount': 0, 'recordingsSize': 0});
    rpc.stubJson('SurveillanceService', 'GetConfig', {'success': false});
    rpc.stubJson('SurveillanceService', 'GetStatus', {});
    rpc.stubJson('SafeLocationsService', 'ListZones', {'zones': []});
  });

  SettingsHubDependencies buildDeps() {
    final shell = ShellController();
    return SettingsHubDependencies(
        localeController: LocaleController(store: _MemLocaleStore()),
        prefs: PrefsChannel(channel),
        shellController: shell,
        appearanceController:
            SettingsAppearanceController(prefs: PrefsChannel(channel), shellController: shell),
        systemService: SystemServiceClient(rpc),
        recordingsService: RecordingsServiceClient(rpc),
        settingsService: SettingsServiceClient(rpc),
        storageService: StorageServiceClient(rpc),
        surveillanceService: SurveillanceServiceClient(rpc),
        longSurveillanceService: SurveillanceServiceClient(rpc),
        safeLocationsService: SafeLocationsServiceClient(rpc),
        tripsController: TripsController(
            tripsService: TripsServiceClient(rpc), longTripsService: TripsServiceClient(rpc)),
        daemonChannel: DaemonChannel(channel),
        configChannel: ConfigChannel(channel),
        publicConfigChannel: PublicConfigChannel(channel),
        onOpenLanguagePicker: () => languageOpened = true,
        jwtSource: _FakeJwtSource(),
        // The Recording pane loads its overlay-field checklist on init (BladeWatch-y78o.5);
        // these fakes keep that off the real network in every test here, none of which cares
        // about the checklist's content specifically.
        overlayFieldsGetSender: (uri, headers) async =>
            const RawHttpResponse(200, '{"success":true,"availableFields":[],"selections":{}}'),
        overlayFieldsPostSender: (uri, headers, body) async => const RawHttpResponse(200, '{"success":true}'),
      );
  }

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      theme: BladeWatchTheme.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SettingsScreen(deps: buildDeps())),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('defaults to the Appearance section', (tester) async {
    await pump(tester);

    expect(find.byType(SettingsAppearanceScreen), findsOneWidget);
  });

  testWidgets('selecting Recording swaps the content and disposes Appearance', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('settings.section.recording')));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsRecordingScreen), findsOneWidget);
    expect(find.byType(SettingsAppearanceScreen), findsNothing);
  });

  testWidgets('selecting Overlay shows the overlay switches', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('settings.section.overlay')));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsOverlayScreen), findsOneWidget);
  });

  testWidgets('selecting Daemons shows the daemons list', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('settings.section.daemons')));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsDaemonsScreen), findsOneWidget);
  });

  testWidgets('selecting Privacy shows the privacy screen and the reset button opens its dialog', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('settings.section.privacy')));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPrivacyScreen), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('privacy.resetData')));
    await tester.pumpAndSettle();
    expect(find.text('Reset Data'), findsOneWidget);
  });

  testWidgets('selecting Surveillance mounts the real settings screen inline', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('settings.section.surveillance')));
    await tester.pumpAndSettle();

    expect(find.byType(SurveillanceSettingsScreen), findsOneWidget);
  });

  testWidgets('opening the language picker from Appearance calls the callback', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('language.card')));

    expect(languageOpened, isTrue);
  });

  testWidgets('switching back to a previously-visited section rebuilds it fresh', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('settings.section.recording')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings.section.appearance')));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsAppearanceScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders without error in dark theme', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
      theme: BladeWatchTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: SettingsScreen(deps: buildDeps())),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  // ── BladeWatch-mrsc: native design-system parity ───────────────────────────

  testWidgets('the section list carries its SETTINGS header', (tester) async {
    await pump(tester);

    expect(find.text('SETTINGS'), findsOneWidget);
  });

  testWidgets('only the drill-down rows carry a chevron', (tester) async {
    await pump(tester);

    // Native marks Recording and Surveillance with navigates = true purely for
    // the chevron affordance; the rest have none.
    for (final section in const ['recording', 'surveillance']) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey('settings.section.$section')),
          matching: find.byIcon(Icons.chevron_right),
        ),
        findsOneWidget,
        reason: '$section should show a drill-down chevron',
      );
    }
    for (final section in const ['appearance', 'overlay', 'daemons', 'privacy']) {
      expect(
        find.descendant(
          of: find.byKey(ValueKey('settings.section.$section')),
          matching: find.byIcon(Icons.chevron_right),
        ),
        findsNothing,
        reason: '$section is hosted inline and should have no chevron',
      );
    }
  });

  testWidgets('each pane opens with its title and description', (tester) async {
    await pump(tester);

    // Appearance is selected by default.
    expect(find.byKey(const ValueKey('settings.pane.title')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('settings.pane.title'))).data,
      'Appearance',
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('settings.pane.subtitle'))).data,
      'Theme, language, and visual preferences.',
    );

    await tester.tap(find.byKey(const ValueKey('settings.section.overlay')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('settings.pane.title'))).data,
      'Status overlay',
    );
  });

  // ── BladeWatch-hygs: the two public-config-backed panes are wired to the
  // real channel, not to the controllers' no-op defaults ─────────────────────

  testWidgets('Overlay reads statusOverlay from the public config store', (tester) async {
    channel.stub('publicConfig', 'getSection', <Object?, Object?>{'cameraVisible': false, 'tripVisible': true});
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('settings.section.overlay')));
    await tester.pumpAndSettle();

    final read = channel.calls.firstWhere((c) => c.method == 'getSection');
    expect((read.args as Map)['section'], 'statusOverlay');
    // The stubbed value has to reach the switch, or the pane is still reading
    // the controller's built-in default and this wiring proves nothing.
    expect(tester.widget<SwitchListTile>(find.byKey(const ValueKey('overlay.camera'))).value, isFalse);
  });

  testWidgets('toggling an Overlay switch writes it back over the public config channel', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const ValueKey('settings.section.overlay')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('overlay.trip')));
    await tester.pumpAndSettle();

    final write = channel.calls.firstWhere((c) => c.method == 'putBoolean');
    expect(write.args, {'section': 'statusOverlay', 'key': 'tripVisible', 'value': false});
  });

  testWidgets('Privacy reads and writes developerOptions over the public config channel', (tester) async {
    channel.stub('publicConfig', 'getSection', <Object?, Object?>{
      'timingLogsEnabled': true,
      'debugLogsEnabled': false,
    });
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('settings.section.privacy')));
    await tester.pumpAndSettle();

    final read = channel.calls.firstWhere((c) => c.method == 'getSection');
    expect((read.args as Map)['section'], 'developerOptions');

    await tester.tap(find.byKey(const ValueKey('privacy.debugLogs')));
    await tester.pumpAndSettle();

    final write = channel.calls.firstWhere((c) => c.method == 'putBoolean');
    expect(write.args, {'section': 'developerOptions', 'key': 'debugLogsEnabled', 'value': true});
  });

  testWidgets('Privacy has no generic pane subtitle, because it owns its heading', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const ValueKey('settings.section.privacy')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('settings.pane.title')), findsOneWidget);
    expect(find.byKey(const ValueKey('settings.pane.subtitle')), findsNothing);
  });
}
