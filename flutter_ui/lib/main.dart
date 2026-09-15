import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:package_info_plus/package_info_plus.dart';

import 'adb/adb_client.dart';
import 'gen/l10n/app_localizations.dart';
import 'platform/adb_key_channel.dart';
import 'platform/auth_channel.dart';
import 'platform/config_channel.dart';
import 'platform/daemon_channel.dart';
import 'platform/live_view_texture_channel.dart';
import 'platform/location_channel.dart';
import 'platform/method_channel_bridge.dart';
import 'platform/network_channel.dart';
import 'platform/prefs_channel.dart';
import 'platform/public_config_channel.dart';
import 'platform/setup_channel.dart';
import 'rpc/connect_client.dart';
import 'rpc/raw_http_sender.dart';
import 'rpc/services/recordings_service_client.dart';
import 'rpc/services/safe_locations_service_client.dart';
import 'rpc/services/settings_service_client.dart';
import 'rpc/services/storage_service_client.dart';
import 'rpc/services/stream_service_client.dart';
import 'rpc/services/surveillance_service_client.dart';
import 'rpc/services/system_service_client.dart';
import 'rpc/services/trips_service_client.dart';
import 'rpc/services/vehicle_service_client.dart';
import 'screens/dashboard/dashboard_controller.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/diagnostics/adb_console_controller.dart';
import 'screens/diagnostics/diagnostics_controller.dart';
import 'screens/diagnostics/diagnostics_models.dart';
import 'screens/diagnostics/diagnostics_screen.dart';
import 'screens/diagnostics/performance_controller.dart';
import 'screens/dialogs/language_picker_sheet.dart';
import 'screens/dialogs/setup_guide_controller.dart';
import 'screens/dialogs/setup_guide_dialog.dart';
import 'screens/live_view/live_view_controller.dart';
import 'screens/live_view/live_view_screen.dart';
import 'screens/location/location_controller.dart';
import 'screens/location/location_screen.dart';
import 'screens/recordings/recordings_controller.dart';
import 'screens/recordings/recordings_screen.dart';
import 'screens/settings/settings_appearance_controller.dart';
import 'screens/settings/settings_appearance_models.dart';
import 'screens/settings/settings_about_controller.dart';
import 'screens/settings/settings_about_screen.dart';
import 'screens/settings/settings_daemons_controller.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/startup/startup_controller.dart';
import 'screens/startup/startup_health_check.dart';
import 'screens/startup/startup_screen.dart';
import 'screens/surveillance/surveillance_controller.dart';
import 'screens/surveillance/surveillance_screen.dart';
import 'screens/trips/trip_detail_controller.dart';
import 'screens/trips/trips_controller.dart';
import 'screens/trips/trips_screen.dart';
import 'screens/vehicle/vehicle_controller.dart';
import 'screens/vehicle/vehicle_screen.dart';
import 'shell/app_shell.dart';
import 'shell/locale_controller.dart';
import 'shell/route_stubs.dart';
import 'shell/shell_controller.dart';
import 'theme/bladewatch_theme.dart';

void main() {
  runApp(const BladeWatchApp());
}

/// App root: M3 light/dark theme (`BladeWatchTheme`) + the navigation shell
/// (`AppShell`), behind the Startup screen — ground truth:
/// `nav_graph.xml`'s `app:startDestination="@id/startupFragment"` with
/// `app:popUpToInclusive="true"` on its only action (once past it, there is
/// no going back). `_startupComplete` is that same one-way gate: it starts
/// false, showing `StartupScreen`, and flips true exactly once when
/// `StartupController` says it's time — nothing ever flips it back. Screen
/// content behind each rail destination is a stub until Epic 2
/// (`BladeWatch-yz1e`) fills it in.
///
/// [shellController]/[startupController] default to the real, device-backed
/// implementations; tests inject fakes so the full app — including the
/// Startup-to-shell transition — is drivable without a real platform channel
/// or daemon.
/// [AppThemeMode] as Flutter's own [ThemeMode], for `MaterialApp.themeMode`.
///
/// Lives here rather than beside [AppThemeMode] because
/// `settings_appearance_models.dart` is deliberately Flutter-free.
///
/// BladeWatch-imh6.7: MaterialApp used to set `theme` and `darkTheme` but no
/// `themeMode`, which defaults to [ThemeMode.system] — so the app always
/// followed the head unit's own theme and the user's explicit Light/Dark
/// choice was written to prefs and then ignored.
ThemeMode materialThemeMode(AppThemeMode mode) => switch (mode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };

class BladeWatchApp extends StatefulWidget {
  final ShellController? shellController;
  final StartupController? startupController;
  final DashboardController? dashboardController;
  final SettingsAboutController? settingsAboutController;
  final TripsController? tripsController;
  final SetupGuideController? setupGuideController;

  /// Owned HERE rather than by the Settings screen because `MaterialApp`
  /// needs it: the theme the user picked has to reach `themeMode`, and a
  /// controller created inside a settings pane cannot do that
  /// (BladeWatch-imh6.7 — the choice was persisted and then ignored).
  final SettingsAppearanceController? appearanceController;

  const BladeWatchApp({
    super.key,
    this.shellController,
    this.startupController,
    this.dashboardController,
    this.settingsAboutController,
    this.tripsController,
    this.setupGuideController,
    this.appearanceController,
  });

  @override
  State<BladeWatchApp> createState() => _BladeWatchAppState();
}

class _BladeWatchAppState extends State<BladeWatchApp> {
  late final ShellController _shellController = widget.shellController ?? ShellController();
  late final StartupController _startupController =
      widget.startupController ??
      StartupController(daemonChannel: DaemonChannel(MethodChannelBridge()), healthCheck: checkDaemonHealth);
  late final LocaleController _localeController = LocaleController(store: const FileLocaleStore());
  late final SettingsAppearanceController _appearanceController = widget.appearanceController ??
      SettingsAppearanceController(prefs: _prefsChannel, shellController: _shellController);

  @override
  void initState() {
    super.initState();
    _localeController.load();
    _appearanceController.load();
  }

  // Shared by every RPC-owning controller below (Dashboard, its vehicle
  // dialog, and Settings' sub-screens) — one JWT cache, one HTTP sender.
  late final AuthChannel _authChannel = AuthChannel(MethodChannelBridge());
  late final ConnectClient _rpcTransport = ConnectClient(jwtSource: _authChannel);
  late final SystemServiceClient _systemService = SystemServiceClient(_rpcTransport);
  late final RecordingsServiceClient _recordingsService = RecordingsServiceClient(_rpcTransport);
  late final SettingsServiceClient _settingsService = SettingsServiceClient(_rpcTransport);
  late final StorageServiceClient _storageService = StorageServiceClient(_rpcTransport);
  late final SurveillanceServiceClient _surveillanceService = SurveillanceServiceClient(_rpcTransport);
  late final SafeLocationsServiceClient _safeLocationsService = SafeLocationsServiceClient(_rpcTransport);
  late final VehicleServiceClient _vehicleService = VehicleServiceClient(_rpcTransport);
  late final StreamServiceClient _streamService = StreamServiceClient(_rpcTransport);
  late final TripsServiceClient _tripsService = TripsServiceClient(_rpcTransport);
  // BladeWatch-yz1e.5: SyncTrips can take ~120s — a separate ConnectClient
  // with a long read timeout, mirroring ConnectClientProvider.longTripsService().
  late final ConnectClient _longRpcTransport = ConnectClient(
    jwtSource: _authChannel,
    send: createIoHttpSender(readTimeout: const Duration(seconds: 120)),
  );
  late final TripsServiceClient _longTripsService = TripsServiceClient(_longRpcTransport);
  // PerformanceController talks to 3 /api/performance/* endpoints over raw HTTP
  // rather than RPC, so it needs a RawHttpSender of its own kind. It is rebuilt
  // on every visit to the Performance screen, and createIoHttpSender() allocates
  // an HttpClient that nothing ever closes — so letting the controller default
  // leaks one connection pool per visit on a head unit that stays up for days.
  // Hand it this app-lifetime sender instead; HttpClient is designed to be shared.
  late final RawHttpSender _rawHttpSender = createIoHttpSender();
  // BladeWatch-yz1e.8: SyncCatalog (surveillance) shares the same long-read
  // transport, mirroring ConnectClientProvider.longSurveillanceService().
  late final SurveillanceServiceClient _longSurveillanceService = SurveillanceServiceClient(_longRpcTransport);
  late final DaemonChannel _daemonChannel = DaemonChannel(MethodChannelBridge());
  late final ConfigChannel _configChannel = ConfigChannel(MethodChannelBridge());
  late final PublicConfigChannel _publicConfigChannel = PublicConfigChannel(MethodChannelBridge());
  late final PrefsChannel _prefsChannel = PrefsChannel(MethodChannelBridge());
  late final AdbKeyChannel _adbKeyChannel = AdbKeyChannel(MethodChannelBridge());
  late final NetworkChannel _networkChannel = NetworkChannel(MethodChannelBridge());
  late final LocationChannel _locationChannel = LocationChannel(MethodChannelBridge());
  // A separate MethodChannel/TaskQueue from the shared "privileged" one above
  // — see LiveViewTextureChannel's doc comment for why a MediaCodec call
  // cannot share the same channel as everything else.
  late final LiveViewTextureChannel _liveViewTextureChannel = LiveViewTextureChannel(
    MethodChannelBridge(const MethodChannel('net.bladewatch.flutter/live_view_texture')),
  );

  late final DashboardController _dashboardController =
      widget.dashboardController ??
      DashboardController(
        tripsService: TripsServiceClient(_rpcTransport),
        recordingsService: _recordingsService,
        systemService: _systemService,
        daemonChannel: _daemonChannel,
        authChannel: _authChannel,
        tunnelStatusSource: _daemonChannel.tunnelStatus,
      );

  late final SettingsAboutController _settingsAboutController =
      widget.settingsAboutController ?? SettingsAboutController(versionSource: _appVersionInfo);

  static Future<AppVersionInfo> _appVersionInfo() async {
    final info = await PackageInfo.fromPlatform();
    return AppVersionInfo(version: info.version, buildNumber: info.buildNumber, packageName: info.packageName);
  }

  late final SetupChannel _setupChannel = SetupChannel(MethodChannelBridge());
  late final SetupGuideController _setupGuideController =
      widget.setupGuideController ??
      SetupGuideController(prefs: _prefsChannel, setup: _setupChannel, versionSource: _appVersionInfo);
  bool _setupGuideChecked = false;

  Future<void> _maybeShowSetupGuideOnLaunch(BuildContext context) async {
    final shouldShow = await _setupGuideController.checkIfNeeded();
    if (!shouldShow || !context.mounted) return;
    await showSetupGuideDialog(
      context,
      _setupGuideController,
      _localeController,
      updatedToVersion: _setupGuideController.updatedToVersion,
    );
  }

  late final DiagnosticsController _diagnosticsController = DiagnosticsController(
    daemonChannel: _daemonChannel,
    storageService: _storageService,
    systemService: _systemService,
    networkChannel: _networkChannel,
    surveillanceService: _surveillanceService,
    adbConnectionFactory: () => AdbClient(keys: _adbKeyChannel),
    // BladeWatch-i2wv: the real tunnel source, the same one DashboardController
    // uses. It was left on the always-null default here long after
    // BladeWatch-m1po built it, so the Diagnostics Network card reported the
    // tunnel offline unconditionally.
    tunnelUrlSource: _daemonChannel.tunnelUrl,
    // BladeWatch-i2wv: the real probed-camera read. `camera` was added to the
    // daemon's READABLE config allowlist only — it stays unwritable over IPC,
    // because this tile needs to read it and nothing more.
    cameraConfigSource: _cameraProbeSource.read,
    // BladeWatch-1ovy: the charge percentage, from the same RPC the Vehicle
    // screen reads, so the two cannot disagree.
    batterySocSource: _batterySocSource.read,
  );

  late final BatterySocSource _batterySocSource = BatterySocSource(_vehicleService);

  late final CameraProbeSource _cameraProbeSource = CameraProbeSource(_publicConfigChannel);

  late final TripsController _tripsController =
      widget.tripsController ?? TripsController(tripsService: _tripsService, longTripsService: _longTripsService);

  late final LocationController _locationController = LocationController(
    channel: _locationChannel,
    prefs: _prefsChannel,
    networkChannel: _networkChannel,
  );

  late final RecordingsController _recordingsController = RecordingsController(recordingsService: _recordingsService);

  // Standalone AppShell slot (BwRoutes.surveillance) — separate instance from
  // the Settings sub-rail's Surveillance row, matching native's two
  // independently-constructed SurveillanceSettingsController Fragments.
  late final SurveillanceSettingsController _surveillanceController = SurveillanceSettingsController(
    surveillanceService: _surveillanceService,
    longSurveillanceService: _longSurveillanceService,
    safeLocationsService: _safeLocationsService,
    storageService: _storageService,
    recordingsService: _recordingsService,
  );

  late final VehicleController _vehicleController = VehicleController(
    vehicleService: _vehicleService,
    systemService: _systemService,
  );

  late final LiveViewController _liveViewController = LiveViewController(
    streamService: _streamService,
    jwtSource: _authChannel,
    textureChannel: _liveViewTextureChannel,
  );

  bool _startupComplete = false;

  @override
  void dispose() {
    _shellController.dispose();
    _startupController.dispose();
    _dashboardController.dispose();
    _settingsAboutController.dispose();
    _diagnosticsController.dispose();
    _tripsController.dispose();
    _locationController.dispose();
    _recordingsController.dispose();
    _surveillanceController.dispose();
    _vehicleController.dispose();
    _liveViewController.dispose();
    _localeController.dispose();
    // Same ownership rule as _shellController and _startupController above,
    // which are also `widget.X ?? new` and are disposed here. This one was
    // missed: it is a ChangeNotifier held by the Listenable.merge that drives
    // MaterialApp's themeMode, so leaking it leaks a listener on every rebuild
    // of the app root.
    _appearanceController.dispose();
    _setupGuideController.dispose();
    super.dispose();
  }

  void _showLanguagePicker(BuildContext context) => showLanguagePickerSheet(context, _localeController);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      // The appearance controller is in here too: without it a theme change
      // would be persisted but never rebuild MaterialApp.
      listenable: Listenable.merge([_localeController, _appearanceController]),
      builder: (context, _) => MaterialApp(
        title: 'BladeWatch',
        theme: BladeWatchTheme.light(),
        darkTheme: BladeWatchTheme.dark(),
        themeMode: materialThemeMode(_appearanceController.themeMode),
        locale: _localeController.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // A Builder here, not the outer build()'s own `context`, is required:
        // that outer context sits above this very MaterialApp (it's the
        // context this widget was given by ITS OWN parent), so it has no
        // Localizations/Navigator ancestor — showModalBottomSheet from
        // onLanguageTap/onOpenLanguagePicker needs a context from BELOW
        // MaterialApp, which only a descendant Builder can provide.
        home: Builder(
          builder: (context) {
            if (_startupComplete && !_setupGuideChecked) {
              _setupGuideChecked = true;
              WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowSetupGuideOnLaunch(context));
            }
            return _startupComplete
                ? AppShell(
                    controller: _shellController,
                    onLanguageTap: () => _showLanguagePicker(context),
                    // BladeWatch-0kru: real tunnel URL, so the pill shows the
                    // actual address or nothing at all.
                    tunnelUrlSource: _daemonChannel.tunnelUrl,
                    dashboardScreen: DashboardScreen(
                      controller: _dashboardController,
                      systemService: _systemService,
                      onNavigate: _shellController.selectRoute,
                    ),
                    settingsScreen: SettingsScreen(
                      deps: SettingsHubDependencies(
                        localeController: _localeController,
                        prefs: _prefsChannel,
                        appearanceController: _appearanceController,
                        shellController: _shellController,
                        systemService: _systemService,
                        recordingsService: _recordingsService,
                        settingsService: _settingsService,
                        storageService: _storageService,
                        surveillanceService: _surveillanceService,
                        longSurveillanceService: _longSurveillanceService,
                        safeLocationsService: _safeLocationsService,
                        daemonChannel: _daemonChannel,
                        configChannel: _configChannel,
                        publicConfigChannel: _publicConfigChannel,
                        setDaemonEnabled: SettingsDaemonsController.enabledSetterFor(_daemonChannel),
                        onOpenLanguagePicker: () => _showLanguagePicker(context),
                      ),
                    ),
                    settingsAboutScreen: SettingsAboutScreen(
                      controller: _settingsAboutController,
                      onShowSetupGuide: () => showSetupGuideDialog(context, _setupGuideController, _localeController),
                    ),
                    diagnosticsScreen: DiagnosticsScreen(
                      controller: _diagnosticsController,
                      adbConsoleControllerFactory: () =>
                          AdbConsoleController(connection: AdbClient(keys: _adbKeyChannel)),
                      performanceControllerFactory: () => PerformanceController(
                        systemService: _systemService,
                        jwtSource: _authChannel,
                        send: _rawHttpSender,
                      ),
                      onOpenSettings: () => _shellController.selectRoute(BwRoutes.settings),
                    ),
                    tripsScreen: TripsScreen(
                      controller: _tripsController,
                      detailControllerFactory: () => TripDetailController(tripsService: _tripsService),
                    ),
                    locationScreen: LocationScreen(controller: _locationController),
                    recordingsScreen: RecordingsScreen(
                      controller: _recordingsController,
                      recordingsService: _recordingsService,
                      jwtSource: _authChannel,
                      onOpenSettings: () => _shellController.selectRoute(BwRoutes.settings),
                    ),
                    surveillanceScreen: SurveillanceSettingsScreen(controller: _surveillanceController),
                    vehicleScreen: VehicleScreen(controller: _vehicleController),
                    liveViewScreen: LiveViewScreen(controller: _liveViewController),
                  )
                : StartupScreen(
                    controller: _startupController,
                    onReadyToNavigate: () => setState(() => _startupComplete = true),
                  );
          },
        ),
      ),
    );
  }
}
