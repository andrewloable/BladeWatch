import 'package:flutter/material.dart';

import '../../gen/l10n/app_localizations.dart';
import 'settings_daemons_controller.dart';
import 'settings_daemons_models.dart';

/// Ground truth: `DaemonsFragment.kt` + `DaemonAdapter.kt`, reduced to what
/// `daemon.processStatus` can report — see the controller's doc comment for
/// why per-daemon start/stop and per-row uptime/subprocess detail aren't
/// here. Zrok's configure action (token set/delete/reset) uses the
/// already-capable `config.*` channel in full.
class SettingsDaemonsScreen extends StatefulWidget {
  final SettingsDaemonsController controller;

  const SettingsDaemonsScreen({super.key, required this.controller});

  @override
  State<SettingsDaemonsScreen> createState() => _SettingsDaemonsScreenState();
}

class _SettingsDaemonsScreenState extends State<SettingsDaemonsScreen> {
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

  String _daemonLabel(AppLocalizations l10n, DaemonKind kind) => switch (kind) {
        DaemonKind.camera => l10n.startup_daemon_camera,
        DaemonKind.sentry => l10n.startup_daemon_sentry,
        DaemonKind.accSentry => l10n.startup_daemon_parking,
        DaemonKind.zrokTunnel => l10n.tunnel_label_zrok,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final c = widget.controller;

    if (c.loading) {
      return Center(child: Text(l10n.daemons_count_pending));
    }

    final running = c.rows.where((r) => r.running).length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.daemons_hero_title, style: theme.textTheme.titleMedium),
        Text(l10n.daemons_count_fmt(running, c.rows.length), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        for (final row in c.rows)
          Card(
            key: ValueKey('daemon.${row.kind.name}'),
            color: theme.colorScheme.surfaceContainer,
            elevation: 0,
            child: ListTile(
              leading: Icon(Icons.circle, size: 12, color: row.running ? theme.colorScheme.primary : theme.colorScheme.outlineVariant),
              title: Text(_daemonLabel(l10n, row.kind)),
              subtitle: Text(row.running ? l10n.startup_status_ready : l10n.startup_status_waiting),
              trailing: row.kind == DaemonKind.zrokTunnel
                  ? IconButton(
                      key: const ValueKey('daemon.zrok.configure'),
                      icon: const Icon(Icons.settings),
                      tooltip: l10n.settings_daemons_zrok_configure,
                      onPressed: () => _showZrokDialog(context, l10n),
                    )
                  : Switch(
                      value: row.running,
                      onChanged: (enabled) async {
                        final ok = await c.toggle(row.kind, enabled);
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(l10n.settings_daemons_toggle_unsupported(_daemonLabel(l10n, row.kind)))));
                        }
                      },
                    ),
            ),
          ),
      ],
    );
  }

  Future<void> _showZrokDialog(BuildContext context, AppLocalizations l10n) async {
    final controller = widget.controller;
    final current = await controller.getZrokToken();
    if (!context.mounted) return;
    final textController = TextEditingController(text: current);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.link),
        title: Text(l10n.dialog_zrok_token_title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.dialog_zrok_token_message),
            const SizedBox(height: 12),
            TextField(key: const ValueKey('zrok.tokenField'), controller: textController),
            const SizedBox(height: 8),
            TextButton(
              key: const ValueKey('zrok.resetEnvironment'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _confirmResetZrok(context, l10n);
              },
              child: Text(l10n.settings_daemons_zrok_reset_button),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.action_cancel)),
          TextButton(
            onPressed: () async {
              final ok = await controller.deleteZrokToken();
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (!context.mounted) return;
              _notify(context, ok ? l10n.toast_zrok_token_deleted : l10n.toast_zrok_token_delete_failed);
            },
            child: Text(l10n.dialog_delete),
          ),
          TextButton(
            key: const ValueKey('zrok.save'),
            onPressed: () async {
              final token = textController.text.trim();
              if (token.isEmpty) {
                _notify(context, l10n.toast_token_cannot_be_empty);
                return;
              }
              final ok = await controller.saveZrokToken(token);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              if (!context.mounted) return;
              _notify(context, ok ? l10n.toast_zrok_token_saved : l10n.toast_zrok_token_save_failed);
            },
            child: Text(l10n.dialog_save),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmResetZrok(BuildContext context, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning),
        title: Text(l10n.dialog_zrok_reset_title),
        content: Text(l10n.dialog_zrok_reset_message),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.action_cancel)),
          TextButton(
            key: const ValueKey('zrok.confirmReset'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.dialog_reset),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await widget.controller.resetZrokEnvironment();
    if (!context.mounted) return;
    _notify(context, ok ? l10n.toast_zrok_reset_success : l10n.toast_zrok_reset_partial);
  }

  void _notify(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
