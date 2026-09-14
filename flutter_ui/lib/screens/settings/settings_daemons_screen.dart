import 'dart:io';
import 'package:flutter/material.dart';

import '../../theme/color_tokens.dart';

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

  /// Reads one daemon's log. Injectable for the same reason `RawHttpSender`
  /// and `ThumbnailFetcher` are: real file I/O does not resolve inside
  /// `testWidgets`' async zone, so a test could never see the dialog.
  final Future<String> Function(String path)? logReader;

  const SettingsDaemonsScreen({super.key, required this.controller, this.logReader});

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

  /// Native's Services pane names, from `DaemonAdapter.getDaemonDisplayName`.
  ///
  /// These are NOT the startup screen's short labels — the port used
  /// startup_daemon_* ("Camera", "Sentry Mode", "Parking Guard"), which are
  /// different words for the same daemons and appear nowhere in the docs, the
  /// logs or CLAUDE.md.
  ///
  /// BladeWatch-def0: localised on BOTH sides now. These used to be literals
  /// here because native hardcoded them too and adding ARB-only keys would have
  /// let the two UIs drift apart; that task added the matching
  /// `daemon_name_*` string resources to native as well, so the English wording
  /// stays byte-identical while the other 16 locales finally translate.
  /// "Zrok Tunnel" is a product name and is deliberately untranslated.
  String _daemonLabel(AppLocalizations l10n, DaemonKind kind) => switch (kind) {
        DaemonKind.camera => l10n.daemon_name_camera,
        DaemonKind.sentry => l10n.daemon_name_surveillance,
        DaemonKind.accSentry => l10n.daemon_name_acc,
        DaemonKind.zrokTunnel => l10n.daemon_name_zrok,
      };

  /// Per-service icon, matching DaemonAdapter.getDaemonIcon.
  IconData _daemonIcon(DaemonKind kind) => switch (kind) {
        DaemonKind.camera => Icons.photo_camera_outlined,
        DaemonKind.sentry => Icons.shield_outlined,
        DaemonKind.accSentry => Icons.directions_car_outlined,
        DaemonKind.zrokTunnel => Icons.link,
      };

  /// The log each service writes, from `DaemonAdapter.getLogFilePath`.
  ///
  /// Readable from the Flutter APK despite living under /data/local/tmp: the
  /// directory is 0771 shell:shell, so "others" get traverse but not list, and
  /// each log file is 0666. Opening by EXACT path therefore works — the same
  /// mechanism the app already relies on for the world-readable IPC token.
  String _daemonLogPath(DaemonKind kind) => switch (kind) {
        DaemonKind.camera => '/data/local/tmp/cam_daemon.log',
        DaemonKind.sentry => '/data/local/tmp/sentry_daemon.log',
        DaemonKind.accSentry => '/data/local/tmp/acc_sentry_daemon.log',
        DaemonKind.zrokTunnel => '/data/local/tmp/zrok.log',
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
          Builder(builder: (context) {
            // Zrok with no token is the one actionable state here: native says
            // WHY the tunnel is down and what to do, in the warning colour.
            final needsZrokToken = row.kind == DaemonKind.zrokTunnel && !c.zrokHasToken;
            final statusText = needsZrokToken
                ? l10n.zrok_no_token_configured
                : row.running
                    ? l10n.surveillance_general_status_running
                    : l10n.startup_status_waiting;
            final statusColor = needsZrokToken
                ? _warningColor(theme)
                : row.running
                    ? _successColor(theme)
                    : theme.colorScheme.onSurfaceVariant;
            final dotColor = needsZrokToken
                ? _warningColor(theme)
                : row.running
                    ? _successColor(theme)
                    : theme.colorScheme.outlineVariant;

            return Card(
              key: ValueKey('daemon.${row.kind.name}'),
              color: theme.colorScheme.surfaceContainer,
              elevation: 0,
              child: ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 12, color: dotColor),
                    const SizedBox(width: 12),
                    Icon(_daemonIcon(row.kind)),
                  ],
                ),
                title: Text(_daemonLabel(l10n, row.kind)),
                subtitle: Text(statusText, style: theme.textTheme.bodyMedium?.copyWith(color: statusColor)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: ValueKey('daemon.${row.kind.name}.log'),
                      icon: const Icon(Icons.download_outlined),
                      tooltip: l10n.logs_panel_title,
                      onPressed: () => _showLog(context, l10n, row.kind),
                    ),
                    if (row.kind == DaemonKind.zrokTunnel)
                      IconButton(
                        key: const ValueKey('daemon.zrok.configure'),
                        icon: const Icon(Icons.settings),
                        tooltip: l10n.settings_daemons_zrok_configure,
                        onPressed: () => _showZrokDialog(context, l10n),
                      ),
                    // Every row keeps a switch so its state stays visible and the
                    // rows stay aligned. Only the Zrok tunnel can actually be
                    // toggled (BladeWatch-abcx, see DaemonKind.canToggle); the rest
                    // answer immediately with the same message they always did,
                    // without a pointless IPC round trip.
                    Switch(
                      key: ValueKey('daemon.${row.kind.nativeKey}.toggle'),
                      value: row.running,
                      onChanged: (enabled) async {
                        final ok = await c.toggle(row.kind, enabled);
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.settings_daemons_toggle_unsupported(_daemonLabel(l10n, row.kind)))),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  /// Semantic status colours, from the theme.
  ///
  /// These used to branch on `theme.brightness` by hand, with a comment saying
  /// "the theme has no success/warning role". That was true but not inevitable:
  /// BwColorTokens has carried statusSuccess/Warning since the port, they were
  /// simply unreachable — one of the hardcoded values, 0xFFFFB870, WAS
  /// statusWarning for dark, verbatim. They are now a theme extension.
  Color _successColor(ThemeData theme) => theme.extension<BwStatusColors>()!.success;

  Color _warningColor(ThemeData theme) => theme.extension<BwStatusColors>()!.warning;

  /// Shows the tail of one service's log, matching native's per-service log
  /// button. Reads the file directly by exact path — see [_daemonLogPath] for
  /// why that is permitted from the app UID.
  Future<void> _showLog(BuildContext context, AppLocalizations l10n, DaemonKind kind) async {
    final path = _daemonLogPath(kind);
    String body;
    try {
      final read = widget.logReader ?? (p) => File(p).readAsString();
      final text = await read(path);
      // Logs grow without bound; show the tail, which is what anyone opening a
      // daemon log actually wants.
      const maxChars = 20000;
      body = text.length > maxChars ? text.substring(text.length - maxChars) : text;
      if (body.trim().isEmpty) body = l10n.toast_log_empty;
    } catch (e) {
      // toast_log_not_found already says exactly this and exists in every
      // catalog, so no new ARB key (and no 19-file parity churn) is needed.
      body = '${l10n.toast_log_not_found}\n$path';
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        key: const ValueKey('daemon.logDialog'),
        title: Text('${_daemonLabel(l10n, kind)} · ${l10n.logs_panel_title}'),
        content: SizedBox(
          width: 900,
          child: SingleChildScrollView(
            child: SelectableText(body, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.action_done)),
        ],
      ),
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
