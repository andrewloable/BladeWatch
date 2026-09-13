import 'package:flutter/material.dart';

import '../../gen/l10n/app_localizations.dart';
import '../../shell/drive_side.dart';
import 'settings_appearance_controller.dart';
import 'settings_appearance_models.dart';

/// Ground truth: `SettingsAppearanceFragment.kt` — theme tiles, drive-side
/// tiles, and the language picker row. Native's WebView theme cross-fade
/// (`broadcastThemeToWebViews`) has no Flutter equivalent (no WebView on
/// this screen); `MaterialApp.themeMode` picking up the new value on the
/// next frame is this port's version of the same instant-feedback intent.
class SettingsAppearanceScreen extends StatefulWidget {
  final SettingsAppearanceController controller;
  final VoidCallback onOpenLanguagePicker;

  const SettingsAppearanceScreen({super.key, required this.controller, required this.onOpenLanguagePicker});

  @override
  State<SettingsAppearanceScreen> createState() => _SettingsAppearanceScreenState();
}

class _SettingsAppearanceScreenState extends State<SettingsAppearanceScreen> {
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
        Text(l10n.settings_theme_label, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              key: const ValueKey('theme.system'),
              label: Text(l10n.settings_theme_auto),
              selected: c.themeMode == AppThemeMode.system,
              onSelected: (_) => c.setThemeMode(AppThemeMode.system),
            ),
            ChoiceChip(
              key: const ValueKey('theme.light'),
              label: Text(l10n.settings_theme_light),
              selected: c.themeMode == AppThemeMode.light,
              onSelected: (_) => c.setThemeMode(AppThemeMode.light),
            ),
            ChoiceChip(
              key: const ValueKey('theme.dark'),
              label: Text(l10n.settings_theme_dark),
              selected: c.themeMode == AppThemeMode.dark,
              onSelected: (_) => c.setThemeMode(AppThemeMode.dark),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(l10n.settings_drive_side_label, style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(l10n.settings_drive_side_subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              key: const ValueKey('driveSide.left'),
              label: Text(l10n.settings_drive_side_left),
              selected: c.driveSide == DriveSide.left,
              onSelected: (_) => c.setDriveSide(DriveSide.left),
            ),
            ChoiceChip(
              key: const ValueKey('driveSide.right'),
              label: Text(l10n.settings_drive_side_right),
              selected: c.driveSide == DriveSide.right,
              onSelected: (_) => c.setDriveSide(DriveSide.right),
            ),
            ChoiceChip(
              key: const ValueKey('driveSide.auto'),
              label: Text(l10n.settings_drive_side_auto),
              selected: c.driveSide == DriveSide.auto,
              onSelected: (_) => c.setDriveSide(DriveSide.auto),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(_driveSideCaption(l10n, c), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 24),
        Card(
          color: theme.colorScheme.surfaceContainer,
          elevation: 0,
          child: ListTile(
            key: const ValueKey('language.card'),
            title: Text(l10n.settings_language_card_title),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.onOpenLanguagePicker,
          ),
        ),
      ],
    );
  }

  String _driveSideCaption(AppLocalizations l10n, SettingsAppearanceController c) => switch (c.driveSide) {
        DriveSide.right => l10n.settings_drive_side_caption_right,
        DriveSide.left => l10n.settings_drive_side_caption_left,
        DriveSide.auto =>
          c.railOnRight ? l10n.settings_drive_side_caption_auto_right : l10n.settings_drive_side_caption_auto_left,
      };
}
