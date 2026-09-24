import 'package:flutter/material.dart';

import '../../gen/l10n/app_localizations.dart';
import '../../platform/config_channel.dart';
import '../../platform/daemon_channel.dart';
import '../../platform/prefs_channel.dart';
import '../../platform/public_config_channel.dart';
import 'package:bladewatch_rpc/rpc/jwt_source.dart';
import 'package:bladewatch_rpc/rpc/raw_http_sender.dart';
import 'package:bladewatch_rpc/rpc/services/recordings_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/safe_locations_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/settings_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/storage_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/surveillance_service_client.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import '../../shell/locale_controller.dart';
import '../../shell/shell_controller.dart';
import '../trips/trips_controller.dart';
import '../surveillance/surveillance_controller.dart';
import '../surveillance/surveillance_screen.dart';
import 'settings_appearance_controller.dart';
import 'settings_appearance_screen.dart';
import 'settings_daemons_controller.dart';
import 'settings_daemons_models.dart';
import 'settings_daemons_screen.dart';
import 'settings_overlay_controller.dart';
import 'settings_overlay_screen.dart';
import 'settings_privacy_controller.dart';
import 'settings_privacy_screen.dart';
import 'settings_recording_controller.dart';
import 'settings_recording_screen.dart';
import 'settings_trips_screen.dart';

/// Everything [SettingsScreen]'s sub-rail sections need to build their own
/// controllers. Bundled into one object purely to keep the screen's own
/// constructor from growing a dozen positional dependencies — plain data,
/// no behaviour of its own.
class SettingsHubDependencies {
  final PrefsChannel prefs;
  final ShellController shellController;

  /// Owned by the app root, not by this screen: `MaterialApp.themeMode` reads
  /// it, so a per-section instance created here could never drive the theme
  /// (BladeWatch-imh6.7).
  final SettingsAppearanceController appearanceController;
  final SystemServiceClient systemService;
  final RecordingsServiceClient recordingsService;
  final SettingsServiceClient settingsService;
  final StorageServiceClient storageService;
  final SurveillanceServiceClient surveillanceService;
  final SurveillanceServiceClient longSurveillanceService;
  final SafeLocationsServiceClient safeLocationsService;
  final DaemonChannel daemonChannel;
  final ConfigChannel configChannel;

  /// BladeWatch-hygs: the daemon's PUBLIC config store, which backs the
  /// Status-overlay and Privacy logging switches. Distinct from
  /// [configChannel], which is the SECRET store.
  final PublicConfigChannel publicConfigChannel;
  final Future<bool> Function(DaemonKind kind, bool enabled)? setDaemonEnabled;
  final VoidCallback onOpenLanguagePicker;

  /// Lets the Appearance pane show the CURRENT language on its row, as native
  /// does, instead of a bare "Display language >".
  final LocaleController localeController;

  /// The app root's own controller, NOT a per-pane instance: the Trips screen
  /// holds the same object, so a rate saved in the Trips pane is reflected
  /// there without a refetch. Never disposed by this hub — see
  /// [appearanceController] for the same rule.
  final TripsController tripsController;

  /// BladeWatch-y78o.5: mints the JWT for the Recording pane's overlay-field-checklist REST
  /// calls (a plain HTTP endpoint, not a Connect RPC — see settings_recording_controller.dart).
  final JwtSource jwtSource;

  /// Test-only override for the overlay-field-checklist REST calls — null in production,
  /// which makes [RecordingSettingsController] use its own real `dart:io` senders.
  final RawGetSender? overlayFieldsGetSender;
  final RawHttpSender? overlayFieldsPostSender;

  const SettingsHubDependencies({
    required this.prefs,
    required this.shellController,
    required this.appearanceController,
    required this.systemService,
    required this.recordingsService,
    required this.settingsService,
    required this.storageService,
    required this.surveillanceService,
    required this.longSurveillanceService,
    required this.safeLocationsService,
    required this.daemonChannel,
    required this.configChannel,
    required this.publicConfigChannel,
    this.setDaemonEnabled,
    required this.onOpenLanguagePicker,
    required this.localeController,
    required this.tripsController,
    required this.jwtSource,
    this.overlayFieldsGetSender,
    this.overlayFieldsPostSender,
  });
}

// The two UnifiedConfigManager sections the daemon's config_get_section /
// config_put allowlist accepts (TcpCommandServer.PUBLIC_CONFIG_SECTIONS). Any
// other name is refused there, so these strings must match exactly.
const String _statusOverlaySection = 'statusOverlay';
const String _developerOptionsSection = 'developerOptions';

enum _Section { appearance, recording, surveillance, trips, overlay, daemons, privacy }

/// Ground truth: `SettingsFragment.kt`'s landscape two-pane sub-rail — see
/// the class doc for why this port doesn't also build the portrait
/// SOTA-hub variant: BladeWatch targets fixed-landscape BYD head units, so
/// the portrait branch is realistically unreachable on the actual target
/// hardware (documented simplification, not a silent drop).
///
/// Each row's controller is created fresh when selected and disposed when
/// the user switches away — mirrors native's own `childFragmentManager
/// .commit { replace(...) }`, which recreates each section's Fragment
/// (and therefore its state) on every switch rather than caching it.
///
/// Recording/Surveillance's "two entry points, one shared controller TYPE"
/// note (BladeWatch-yz1e.8) applies to both rows mounted here — each site
/// (this hub's row and `AppShell`'s standalone `BwRoutes.surveillance` slot)
/// constructs its own controller instance, matching how native's two
/// Fragments each construct their own `SurveillanceSettingsController`.
class SettingsScreen extends StatefulWidget {
  final SettingsHubDependencies deps;

  const SettingsScreen({super.key, required this.deps});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _Section _section = _Section.appearance;
  ChangeNotifier? _controller;
  Widget? _content;

  @override
  void initState() {
    super.initState();
    _select(_Section.appearance);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _select(_Section section) {
    final deps = widget.deps;
    _controller?.dispose();
    ChangeNotifier? controller;
    Widget content;
    switch (section) {
      case _Section.appearance:
        // Deliberately NOT assigned to `controller`: this instance belongs to
        // the app root and outlives this pane, so the dispose below must not
        // take it (BladeWatch-imh6.7).
        final c = deps.appearanceController;
        content = SettingsAppearanceScreen(
          controller: c,
          onOpenLanguagePicker: deps.onOpenLanguagePicker,
          localeController: deps.localeController,
        );
      case _Section.recording:
        final c = RecordingSettingsController(
          systemService: deps.systemService,
          recordingsService: deps.recordingsService,
          settingsService: deps.settingsService,
          storageService: deps.storageService,
        );
        controller = c;
        content = SettingsRecordingScreen(controller: c);
      case _Section.surveillance:
        final c = SurveillanceSettingsController(
          surveillanceService: deps.surveillanceService,
          longSurveillanceService: deps.longSurveillanceService,
          safeLocationsService: deps.safeLocationsService,
          storageService: deps.storageService,
          recordingsService: deps.recordingsService,
        );
        controller = c;
        content = SurveillanceSettingsScreen(controller: c);
      case _Section.trips:
        // Deliberately NOT assigned to `controller`: this instance belongs to
        // the app root and is shared with the Trips screen, so the dispose
        // below must not take it (same rule as appearance, BladeWatch-imh6.7).
        content = SettingsTripsScreen(controller: deps.tripsController);
      case _Section.overlay:
        final c = SettingsOverlayController(
          loadSettings: () async {
            final section = await deps.publicConfigChannel.getSection(_statusOverlaySection);
            // An empty map means the read failed; native's own fallback is
            // "both visible", which is what the controller defaults to anyway.
            return (
              cameraVisible: section['cameraVisible'] ?? true,
              tripVisible: section['tripVisible'] ?? true,
            );
          },
          persist: (key, value) => deps.publicConfigChannel.putBoolean(_statusOverlaySection, key, value),
        );
        controller = c;
        content = SettingsOverlayScreen(controller: c);
      case _Section.daemons:
        final c = SettingsDaemonsController(
          daemonChannel: deps.daemonChannel,
          setDaemonEnabled: deps.setDaemonEnabled,
        );
        controller = c;
        content = SettingsDaemonsScreen(controller: c);
      case _Section.privacy:
        final c = SettingsPrivacyController(
          storageService: deps.storageService,
          loadLoggingSettings: () async {
            final section = await deps.publicConfigChannel.getSection(_developerOptionsSection);
            // Native's own defaults (UnifiedConfigManager.isTimingLogsEnabled /
            // isDebugLogsEnabled) — timing on, debug off.
            return (
              timingLogsEnabled: section['timingLogsEnabled'] ?? true,
              debugLogsEnabled: section['debugLogsEnabled'] ?? false,
            );
          },
          persistLogging: (key, value) =>
              deps.publicConfigChannel.putBoolean(_developerOptionsSection, key, value),
        );
        controller = c;
        content = SettingsPrivacyScreen(controller: c, systemService: deps.systemService);
    }
    setState(() {
      _section = section;
      _controller = controller;
      _content = content;
    });
  }

  String _label(AppLocalizations l10n, _Section section) => switch (section) {
        _Section.appearance => l10n.settings_section_appearance,
        _Section.recording => l10n.settings_section_recording,
        _Section.surveillance => l10n.settings_section_surveillance,
        _Section.trips => l10n.settings_section_trips,
        _Section.overlay => l10n.settings_section_overlay,
        _Section.daemons => l10n.settings_section_daemons,
        _Section.privacy => l10n.settings_section_privacy,
      };

  /// Native marks Recording and Surveillance with `navigates = true` purely for
  /// the trailing chevron affordance (SettingsFragment.Section) — they read as
  /// drill-downs even though both UIs host them inline. The other rows have no
  /// chevron.
  bool _navigates(_Section section) => section == _Section.recording || section == _Section.surveillance;

  /// The one-line description native puts under each pane's title. Privacy is
  /// absent on purpose: that pane opens with its own "On-device by default"
  /// heading in both UIs, so a generic header would duplicate it.
  String? _paneSubtitle(AppLocalizations l10n, _Section section) => switch (section) {
        _Section.appearance => l10n.settings_appearance_subtitle,
        _Section.recording => l10n.settings_section_recording_subtitle,
        _Section.surveillance => l10n.settings_section_surveillance_subtitle,
        _Section.trips => l10n.settings_section_trips_subtitle,
        _Section.overlay => l10n.settings_overlay_subtitle,
        _Section.daemons => l10n.settings_section_daemons_subtitle,
        _Section.privacy => null,
      };

  IconData _icon(_Section section) => switch (section) {
        _Section.appearance => Icons.dashboard,
        _Section.recording => Icons.videocam,
        _Section.surveillance => Icons.shield,
        _Section.trips => Icons.route,
        _Section.overlay => Icons.layers,
        _Section.daemons => Icons.miscellaneous_services,
        _Section.privacy => Icons.privacy_tip,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 220,
          child: ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.settings_subrail_overline,
                  style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              for (final section in _Section.values)
                ListTile(
                  key: ValueKey('settings.section.${section.name}'),
                  selected: section == _section,
                  selectedTileColor: theme.colorScheme.secondaryContainer,
                  leading: Icon(_icon(section)),
                  title: Text(_label(l10n, section)),
                  trailing: _navigates(section) ? const Icon(Icons.chevron_right) : null,
                  onTap: () => _select(section),
                ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _content == null
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Native opens every pane with its title and a one-line
                    // description; the port rendered the content bare.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _label(l10n, _section),
                            key: const ValueKey('settings.pane.title'),
                            style: theme.textTheme.headlineSmall,
                          ),
                          if (_paneSubtitle(l10n, _section) != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              _paneSubtitle(l10n, _section)!,
                              key: const ValueKey('settings.pane.subtitle'),
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(child: _content!),
                  ],
                ),
        ),
      ],
    );
  }
}
