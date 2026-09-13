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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.settings_overlay_subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        SwitchListTile(
          key: const ValueKey('overlay.camera'),
          title: Text(l10n.settings_overlay_camera_title),
          subtitle: Text(l10n.settings_overlay_camera_subtitle),
          value: c.cameraVisible,
          onChanged: c.loading ? null : c.setCameraVisible,
        ),
        SwitchListTile(
          key: const ValueKey('overlay.trip'),
          title: Text(l10n.settings_overlay_trip_title),
          subtitle: Text(l10n.settings_overlay_trip_subtitle),
          value: c.tripVisible,
          onChanged: c.loading ? null : c.setTripVisible,
        ),
      ],
    );
  }
}
