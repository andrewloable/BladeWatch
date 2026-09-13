import 'package:flutter/material.dart';

import '../../gen/l10n/app_localizations.dart';
import '../../platform/config_channel.dart';
import '../../platform/daemon_channel.dart';
import '../../platform/prefs_channel.dart';
import '../../rpc/services/recordings_service_client.dart';
import '../../rpc/services/safe_locations_service_client.dart';
import '../../rpc/services/settings_service_client.dart';
import '../../rpc/services/storage_service_client.dart';
import '../../rpc/services/surveillance_service_client.dart';
import '../../rpc/services/system_service_client.dart';
import '../../shell/shell_controller.dart';
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

/// Everything [SettingsScreen]'s sub-rail sections need to build their own
/// controllers. Bundled into one object purely to keep the screen's own
/// constructor from growing a dozen positional dependencies — plain data,
/// no behaviour of its own.
class SettingsHubDependencies {
  final PrefsChannel prefs;
  final ShellController shellController;
  final SystemServiceClient systemService;
  final RecordingsServiceClient recordingsService;
  final SettingsServiceClient settingsService;
  final StorageServiceClient storageService;
  final SurveillanceServiceClient surveillanceService;
  final SurveillanceServiceClient longSurveillanceService;
  final SafeLocationsServiceClient safeLocationsService;
  final DaemonChannel daemonChannel;
  final ConfigChannel configChannel;
  final Future<bool> Function(DaemonKind kind, bool enabled)? setDaemonEnabled;
  final VoidCallback onOpenLanguagePicker;

  const SettingsHubDependencies({
    required this.prefs,
    required this.shellController,
    required this.systemService,
    required this.recordingsService,
    required this.settingsService,
    required this.storageService,
    required this.surveillanceService,
    required this.longSurveillanceService,
    required this.safeLocationsService,
    required this.daemonChannel,
    required this.configChannel,
    this.setDaemonEnabled,
    required this.onOpenLanguagePicker,
  });
}

enum _Section { appearance, recording, surveillance, overlay, daemons, privacy }

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
        final c = SettingsAppearanceController(prefs: deps.prefs, shellController: deps.shellController);
        controller = c;
        content = SettingsAppearanceScreen(controller: c, onOpenLanguagePicker: deps.onOpenLanguagePicker);
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
      case _Section.overlay:
        final c = SettingsOverlayController();
        controller = c;
        content = SettingsOverlayScreen(controller: c);
      case _Section.daemons:
        final c = SettingsDaemonsController(
          daemonChannel: deps.daemonChannel,
          configChannel: deps.configChannel,
          setDaemonEnabled: deps.setDaemonEnabled,
        );
        controller = c;
        content = SettingsDaemonsScreen(controller: c);
      case _Section.privacy:
        final c = SettingsPrivacyController(storageService: deps.storageService);
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
        _Section.overlay => l10n.settings_section_overlay,
        _Section.daemons => l10n.settings_section_daemons,
        _Section.privacy => l10n.settings_section_privacy,
      };

  IconData _icon(_Section section) => switch (section) {
        _Section.appearance => Icons.dashboard,
        _Section.recording => Icons.videocam,
        _Section.surveillance => Icons.shield,
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
              for (final section in _Section.values)
                ListTile(
                  key: ValueKey('settings.section.${section.name}'),
                  selected: section == _section,
                  selectedTileColor: theme.colorScheme.secondaryContainer,
                  leading: Icon(_icon(section)),
                  title: Text(_label(l10n, section)),
                  onTap: () => _select(section),
                ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: _content ?? const SizedBox.shrink()),
      ],
    );
  }
}
