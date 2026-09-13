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
        Text('BladeWatch', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        ListTile(title: Text(l10n.settings_about_version_label), trailing: Text(c.versionInfo?.version ?? pending)),
        ListTile(title: Text(l10n.settings_about_package_label), trailing: Text(c.versionInfo?.packageName ?? pending)),
        Card(
          color: theme.colorScheme.surfaceContainer,
          elevation: 0,
          child: ListTile(
            key: const ValueKey('about.license'),
            title: Text(l10n.settings_about_license_title),
            subtitle: Text(l10n.settings_about_license_value),
            onTap: () => _showLicenseDialog(context, l10n),
          ),
        ),
        Card(
          color: theme.colorScheme.surfaceContainer,
          elevation: 0,
          child: ListTile(
            key: const ValueKey('about.setupGuide'),
            title: Text(l10n.settings_about_row_title),
            subtitle: Text(l10n.settings_about_row_subtitle),
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
