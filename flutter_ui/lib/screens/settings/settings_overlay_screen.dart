import 'package:flutter/material.dart';

import '../../gen/l10n/app_localizations.dart';
import 'settings_overlay_controller.dart';

/// Ground truth: `SettingsOverlayFragment.kt` — two switches gating the
/// floating status pill's segments.
class SettingsOverlayScreen extends StatefulWidget {
  final SettingsOverlayController controller;

  const SettingsOverlayScreen({super.key, required this.controller});

  @override
  State<SettingsOverlayScreen> createState() => _SettingsOverlayScreenState();
}

class _SettingsOverlayScreenState extends State<SettingsOverlayScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.controller.load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final c = widget.controller;

    // The pane title and description are supplied by the Settings hub's shared
    // header (BladeWatch-mrsc), so this pane renders only its content.
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Native groups the two toggles in one rounded container with a divider
        // between them, and gives each row a leading icon. The port rendered
        // them as bare rows on the page background.
        Card(
          color: theme.colorScheme.surfaceContainer,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              SwitchListTile(
                key: const ValueKey('overlay.camera'),
                secondary: const Icon(Icons.videocam_outlined),
                title: Text(l10n.settings_overlay_camera_title),
                subtitle: Text(l10n.settings_overlay_camera_subtitle),
                value: c.cameraVisible,
                onChanged: c.loading ? null : c.setCameraVisible,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              SwitchListTile(
                key: const ValueKey('overlay.trip'),
                secondary: const Icon(Icons.navigation_outlined),
                title: Text(l10n.settings_overlay_trip_title),
                subtitle: Text(l10n.settings_overlay_trip_subtitle),
                value: c.tripVisible,
                onChanged: c.loading ? null : c.setTripVisible,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
