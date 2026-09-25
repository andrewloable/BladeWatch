import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/color_tokens.dart';

import '../../gen/l10n/app_localizations.dart';
import 'settings_daemons_controller.dart';
import '../../platform/daemon_channel.dart';
import 'settings_daemons_models.dart';

/// Ground truth: `DaemonsFragment.kt` + `DaemonAdapter.kt`, reduced to what
/// `daemon.processStatus` can report — see the controller's doc comment for
/// why per-daemon start/stop and per-row uptime/subprocess detail aren't
/// here. There is no per-daemon configure action any more: the tunnel's token
/// dialog went with the previous tunnel, and a Tor onion service has nothing to
/// configure.
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
  /// BladeWatch-dh1r: how often the rows re-read daemon state while this screen is up.
  ///
  /// The screen used to load once and never again, so a tunnel that started thirty
  /// seconds after the user flipped the switch stayed "Waiting" until they navigated
  /// away and back. The daemon's own health check runs on a 30 s cycle and tor then
  /// needs up to a minute to bootstrap, so polling faster than the thing being observed
  /// only costs IPC round trips; 5 s is quick enough to feel live.
  static const Duration _refreshInterval = Duration(seconds: 5);

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.controller.load();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => widget.controller.refresh());
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
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
  /// "Tor Tunnel" is a product name and is deliberately untranslated. The Pear peer is
  /// "Remote access (Pear)": what it does is translated, the product name is not.
  String _daemonLabel(AppLocalizations l10n, DaemonKind kind) => switch (kind) {
        DaemonKind.camera => l10n.daemon_name_camera,
        DaemonKind.sentry => l10n.daemon_name_surveillance,
        DaemonKind.accSentry => l10n.daemon_name_acc,
        DaemonKind.torTunnel => l10n.daemon_name_tor,
        DaemonKind.pearPeer => l10n.daemon_name_pear,
      };

  /// Per-service icon, matching DaemonAdapter.getDaemonIcon.
  IconData _daemonIcon(DaemonKind kind) => switch (kind) {
        DaemonKind.camera => Icons.photo_camera_outlined,
        DaemonKind.sentry => Icons.shield_outlined,
        DaemonKind.accSentry => Icons.directions_car_outlined,
        DaemonKind.torTunnel => Icons.link,
        DaemonKind.pearPeer => Icons.hub_outlined,
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
        DaemonKind.torTunnel => '/data/local/tmp/tor.log',
        DaemonKind.pearPeer => '/data/local/tmp/pear_daemon.log',
      };

  /// BladeWatch-rdtj.17: what an owner needs to know about remote access beyond "the process
  /// is up" -- whether the car can be found right now, which is a different question (a live
  /// peer on a head unit with no network is not reachable), plus its connected devices and
  /// the last time one connected. Never a topic or key; the daemon sends none.
  ///
  /// Each line in its own colour (BladeWatch-rdtj.20): the whole row used to be success green,
  /// so on the head unit "Not reachable" read as fine at a glance.
  Text _pearSubtitle(ThemeData theme, AppLocalizations l10n, PearStatus pear) {
    final neutral = theme.colorScheme.onSurfaceVariant;
    final last = pear.lastConnection;
    return Text.rich(TextSpan(style: theme.textTheme.bodyMedium, children: [
      TextSpan(text: l10n.surveillance_general_status_running, style: TextStyle(color: _successColor(theme))),
      switch (pear.reachable) {
        true => TextSpan(text: '\n${l10n.pear_status_reachable}', style: TextStyle(color: _successColor(theme))),
        false => TextSpan(text: '\n${l10n.pear_status_unreachable}', style: TextStyle(color: _warningColor(theme))),
        null => TextSpan(text: '\n${l10n.pear_status_unknown}', style: TextStyle(color: neutral)),
      },
      TextSpan(text: '\n${l10n.pear_devices_connected(pear.devicesConnected)}', style: TextStyle(color: neutral)),
      if (last != null)
        TextSpan(text: '\n${l10n.pear_last_connection(DateFormat('MMM d, HH:mm').format(last))}', style: TextStyle(color: neutral)),
    ]));
  }

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
            // The "no token configured" warning state is gone with the previous
            // tunnel — Tor needs no account. What replaced it is the STARTING state:
            // enabled but not up yet, which for tor lasts up to a minute (61 s cold
            // bootstrap measured on the head unit). Showing that as a plain "Waiting"
            // is what made the row look like the toggle had failed.
            final statusText = row.running
                ? l10n.surveillance_general_status_running
                : row.pending
                    ? row.kind == DaemonKind.pearPeer
                        ? l10n.startup_status_starting
                        : l10n.dashboard_starting_tor
                    : l10n.startup_status_waiting;
            final statusColor = row.running
                ? _successColor(theme)
                : row.pending
                    ? _warningColor(theme)
                    : theme.colorScheme.onSurfaceVariant;
            final dotColor = row.running
                ? _successColor(theme)
                : row.pending
                    ? _warningColor(theme)
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
                subtitle: row.running && row.kind == DaemonKind.pearPeer
                    ? _pearSubtitle(theme, l10n, c.pear)
                    : Text(statusText, style: theme.textTheme.bodyMedium?.copyWith(color: statusColor)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: ValueKey('daemon.${row.kind.name}.log'),
                      icon: const Icon(Icons.download_outlined),
                      tooltip: l10n.logs_panel_title,
                      onPressed: () => _showLog(context, l10n, row.kind),
                    ),
                    // Every row keeps a switch so its state stays visible and the
                    // rows stay aligned. Only the Tor tunnel can actually be
                    // toggled (BladeWatch-abcx, see DaemonKind.canToggle); the rest
                    // answer immediately with the same message they always did,
                    // without a pointless IPC round trip.
                    Switch(
                      key: ValueKey('daemon.${row.kind.nativeKey}.toggle'),
                      // Toggleable rows show the user's INTENT, not liveness — see
                      // DaemonRowState.enabled. The rows that cannot be toggled have no
                      // intent to show, so they keep reporting what is actually true.
                      value: row.kind.canToggle ? row.enabled : row.running,
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

  /// Used for the "enabled but not up yet" row state — see the status block above.
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

}
