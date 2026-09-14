import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../gen/l10n/app_localizations.dart';
import 'settings_about_controller.dart';

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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Page header, matching native: title plus the one-line description.
        // These are also the strings behind the Settings hub's About row, which
        // is why the setup-guide card below must NOT reuse them.
        Text(l10n.settings_about_title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          l10n.settings_about_row_subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        // App identity grouped into one card with the app mark, as native does,
        // rather than two bare rows floating on the page background.
        Card(
          color: theme.colorScheme.surfaceContainer,
          elevation: 0,
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primary,
                  child: Icon(Icons.shield_moon, color: theme.colorScheme.onPrimary),
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
        const SizedBox(height: 24),
      ],
    );
  }

  Future<void> _showLicenseDialog(BuildContext context, AppLocalizations l10n) async {
    final text = await rootBundle.loadString('assets/LICENSE.txt');
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settings_about_license_title),
        content: SingleChildScrollView(child: Text(text)),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.action_done))],
      ),
    );
  }
}
