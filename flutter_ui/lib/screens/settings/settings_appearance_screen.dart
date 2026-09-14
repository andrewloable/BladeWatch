import 'package:flutter/material.dart';

import '../../gen/l10n/app_localizations.dart';
import '../../shell/drive_side.dart';
import '../../shell/locale_controller.dart';
import '../dialogs/language_picker_sheet.dart' show kLocaleNativeNames;
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
  final LocaleController localeController;

  const SettingsAppearanceScreen({
    super.key,
    required this.controller,
    required this.onOpenLanguagePicker,
    required this.localeController,
  });

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
        _GroupCard(
          theme: theme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.settings_theme_label, style: theme.textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ThemePreviewTile(
                      tileKey: const ValueKey('theme.system'),
                      label: l10n.settings_theme_auto,
                      selected: c.themeMode == AppThemeMode.system,
                      preview: const LinearGradient(colors: [Color(0xFF9E9E9E), Color(0xFF1C1C1C)]),
                      theme: theme,
                      onTap: () => c.setThemeMode(AppThemeMode.system),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ThemePreviewTile(
                      tileKey: const ValueKey('theme.light'),
                      label: l10n.settings_theme_light,
                      selected: c.themeMode == AppThemeMode.light,
                      preview: const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFE8EEF3)]),
                      theme: theme,
                      onTap: () => c.setThemeMode(AppThemeMode.light),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ThemePreviewTile(
                      tileKey: const ValueKey('theme.dark'),
                      label: l10n.settings_theme_dark,
                      selected: c.themeMode == AppThemeMode.dark,
                      preview: const LinearGradient(colors: [Color(0xFF10151A), Color(0xFF000000)]),
                      theme: theme,
                      onTap: () => c.setThemeMode(AppThemeMode.dark),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.settings_theme_active_auto_caption,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _GroupCard(
          theme: theme,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.settings_drive_side_label, style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                l10n.settings_drive_side_subtitle,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _OptionTile(
                      tileKey: const ValueKey('driveSide.left'),
                      title: l10n.settings_drive_side_left,
                      subtitle: l10n.settings_drive_side_left_hint,
                      selected: c.driveSide == DriveSide.left,
                      theme: theme,
                      onTap: () => c.setDriveSide(DriveSide.left),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OptionTile(
                      tileKey: const ValueKey('driveSide.right'),
                      title: l10n.settings_drive_side_right,
                      subtitle: l10n.settings_drive_side_right_hint,
                      selected: c.driveSide == DriveSide.right,
                      theme: theme,
                      onTap: () => c.setDriveSide(DriveSide.right),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _OptionTile(
                      tileKey: const ValueKey('driveSide.auto'),
                      title: l10n.settings_drive_side_auto,
                      subtitle: l10n.settings_drive_side_auto_hint,
                      selected: c.driveSide == DriveSide.auto,
                      theme: theme,
                      onTap: () => c.setDriveSide(DriveSide.auto),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _driveSideCaption(l10n, c),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          color: theme.colorScheme.surfaceContainer,
          elevation: 0,
          child: ListTile(
            key: const ValueKey('language.card'),
            // Native shows the globe, the CURRENT language and how many are
            // available; the port had a bare "Display language >" row that told
            // the user neither.
            leading: const Icon(Icons.language),
            title: Text(l10n.settings_language_card_title),
            subtitle: Text(l10n.settings_language_count_format(kLocaleNativeNames.length, kLocaleNativeNames.length)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_currentLanguageLabel(l10n), style: theme.textTheme.titleMedium),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: widget.onOpenLanguagePicker,
          ),
        ),
      ],
    );
  }

  /// "Auto" while following the system, otherwise the language's own name in
  /// its own script — matching what the picker itself lists.
  String _currentLanguageLabel(AppLocalizations l10n) {
    final lc = widget.localeController;
    if (lc.isAuto) return l10n.language_auto_title;
    return kLocaleNativeNames[lc.rawTag] ?? lc.rawTag ?? l10n.language_auto_title;
  }

  String _driveSideCaption(AppLocalizations l10n, SettingsAppearanceController c) => switch (c.driveSide) {
    DriveSide.right => l10n.settings_drive_side_caption_right,
    DriveSide.left => l10n.settings_drive_side_caption_left,
    DriveSide.auto =>
      c.railOnRight ? l10n.settings_drive_side_caption_auto_right : l10n.settings_drive_side_caption_auto_left,
  };
}

/// The rounded container native groups each settings block into. The port
/// rendered these blocks bare on the page background.
class _GroupCard extends StatelessWidget {
  final ThemeData theme;
  final Widget child;

  const _GroupCard({required this.theme, required this.child});

  @override
  Widget build(BuildContext context) => Card(
    color: theme.colorScheme.surfaceContainer,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}

/// A theme choice shown as an actual PREVIEW, not a chip — native renders a
/// light/dark/gradient swatch so the user can see what they are choosing.
class _ThemePreviewTile extends StatelessWidget {
  final Key tileKey;
  final String label;
  final bool selected;
  final Gradient preview;
  final ThemeData theme;
  final VoidCallback onTap;

  const _ThemePreviewTile({
    required this.tileKey,
    required this.label,
    required this.selected,
    required this.preview,
    required this.theme,
    required this.onTap,
  });

  @override
  // Semantics(selected:) is not decoration: replacing ChoiceChip with a custom
  // tile would otherwise silently drop the selected state that ChoiceChip
  // exposed to accessibility services. It also lets tests assert selection
  // without depending on the widget type.
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: InkWell(
      key: tileKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 64,
              decoration: BoxDecoration(gradient: preview, borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: Container(
                width: 32,
                height: 5,
                decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 8),
            Text(label, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}

/// A choice with a title AND the explanatory subtitle native gives it. Matters
/// most for drive side, where "Left"/"Right" alone does not say LHD/RHD.
class _OptionTile extends StatelessWidget {
  final Key tileKey;
  final String title;
  final String subtitle;
  final bool selected;
  final ThemeData theme;
  final VoidCallback onTap;

  const _OptionTile({
    required this.tileKey,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: InkWell(
      key: tileKey,
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(title, style: theme.textTheme.titleSmall, textAlign: TextAlign.center),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
