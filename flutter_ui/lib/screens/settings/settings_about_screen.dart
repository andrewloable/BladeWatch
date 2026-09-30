import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../gen/l10n/app_localizations.dart';
import 'settings_about_controller.dart';
import '../../theme/hud_theme.dart';
import '../../widgets/hud_widgets.dart';

/// Ground truth: `SettingsAboutFragment.kt` — version, license, and the
/// "show setup guide again" row (whose dialog is BladeWatch-yz1e.11's job).
/// There is deliberately no "Check for Updates" here: the in-app OTA updater
/// was removed from both APKs, so the app is installed and updated out of band.
class SettingsAboutScreen extends StatefulWidget {
  final SettingsAboutController controller;
  final VoidCallback onShowSetupGuide;

  const SettingsAboutScreen({super.key, required this.controller, required this.onShowSetupGuide});

  @override
  State<SettingsAboutScreen> createState() => _SettingsAboutScreenState();
}

class _SettingsAboutScreenState extends State<SettingsAboutScreen> {
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
    final pending = l10n.dashboard_metric_value_pending;

    final hud = BwHud.of(context);

    // Page header, matching native: title plus the one-line description. These are also the
    // strings behind the Settings hub's About row, which is why the setup-guide card below must
    // NOT reuse them.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: HudTitleBar(title: l10n.settings_about_title.toUpperCase()),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(
            l10n.settings_about_row_subtitle,
            style: hudText(12, hud.textSecondary, lineHeight: 16, em: 0.05),
          ),
        ),
        Expanded(child: _content(context, l10n, theme, c, pending)),
      ],
    );
  }

  Widget _content(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    SettingsAboutController c,
    String pending,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        // App identity grouped into one card with the app mark, as native does,
        // rather than two bare rows floating on the page background.
        Card(
          color: theme.colorScheme.surfaceContainer,
          elevation: 0,
          child: Column(
            children: [
              ListTile(
                // The app mark: a 4 dp accent-bordered tile, like every other HUD icon box.
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(BwHud.radiusSmall),
                    border: Border.all(color: theme.colorScheme.primary),
                  ),
                  child: Icon(Icons.shield_moon, color: theme.colorScheme.primary),
                ),
                // The product name is a proper noun; native does not localise it.
                title: Text('BladeWatch', style: theme.textTheme.titleLarge),
              ),
              ListTile(
                title: Text(l10n.settings_about_version_label),
                trailing: Text(c.versionInfo?.version ?? pending),
              ),
              ListTile(
                title: Text(l10n.settings_about_package_label),
                trailing: Text(c.versionInfo?.packageName ?? pending),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: theme.colorScheme.surfaceContainer,
          elevation: 0,
          child: ListTile(
            key: const ValueKey('about.license'),
            leading: const Icon(Icons.check),
            title: Text(l10n.settings_about_license_title),
            subtitle: Text(l10n.settings_about_license_value),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLicenseDialog(context, l10n),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: theme.colorScheme.surfaceContainer,
          elevation: 0,
          child: ListTile(
            key: const ValueKey('about.setupGuide'),
            leading: const Icon(Icons.star_border),
            // setup_guide_*, NOT settings_about_row_* — the latter are the
            // Settings hub's About ROW strings ("About BladeWatch / Version,
            // license, support development."), and using them here made this
            // read as a duplicate page header instead of the way back into the
            // setup guide. The guide matters after a BYD update, which wipes
            // the auto-start exemption its step 2 restores.
            title: Text(l10n.setup_guide_title),
            subtitle: Text(l10n.setup_guide_subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.onShowSetupGuide,
          ),
        ),
      ],
    );
  }

  Future<void> _showLicenseDialog(BuildContext context, AppLocalizations l10n) async {
    // The app's own licence, then the licence of the bundled HUD typeface (SIL OFL 1.1 requires
    // its notice to travel with the font).
    final text =
        '${await rootBundle.loadString('assets/LICENSE.txt')}\n\n---\nSpace Mono\n\n'
        '${await rootBundle.loadString('packages/bladewatch_theme/assets/fonts/OFL.txt')}';
    if (!context.mounted) return;
    showHudDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_about_license_title),
        content: SingleChildScrollView(child: Text(text)),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.action_done))],
      ),
    );
  }
}
