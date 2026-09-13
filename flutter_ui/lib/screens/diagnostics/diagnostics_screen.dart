import 'package:flutter/material.dart';

import '../../gen/l10n/app_localizations.dart';
import '../../platform/network_channel.dart';
import 'adb_console_controller.dart';
import 'adb_console_screen.dart';
import 'diagnostics_controller.dart';
import 'diagnostics_models.dart';
import 'performance_controller.dart';
import 'performance_screen.dart';

/// Ground truth: `DiagnosticsFragment.kt` + `fragment_diagnostics.xml` /
/// `layout-land/fragment_diagnostics.xml`. Both layouts are structurally
/// identical (single-column HEALTH grid + TOOLS grid, no embedded logs
/// panel — see [AdbConsoleScreen]'s sibling `LogsPanelFragment` note below),
/// so this screen doesn't need a portrait/landscape split either, matching
/// this project's landscape-only target hardware.
///
/// Not ported: the inline "Live event log" card both `fragment_diagnostics.xml`
/// files' own header comments describe. Both files' *bodies* already removed
/// it ("The Live Event Log card was removed from this page...") — a stale
/// comment, not current behavior. `LogsPanelFragment`/`LogsViewModel`/
/// `LogsAdapter`/`LogEntry`/`LogLevel` — this task's own file list — turned
/// out to have zero navigation references anywhere in the app (confirmed by
/// a full-repo grep for `LogsPanelFragment`): dead code from an already-removed
/// feature, not a screen to port.
class DiagnosticsScreen extends StatefulWidget {
  final DiagnosticsController controller;
  final AdbConsoleController Function() adbConsoleControllerFactory;
  final PerformanceController Function() performanceControllerFactory;
  final VoidCallback onOpenSettings;

  const DiagnosticsScreen({
    super.key,
    required this.controller,
    required this.adbConsoleControllerFactory,
    required this.performanceControllerFactory,
    required this.onOpenSettings,
  });

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.controller.refresh();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _openAdbConsole() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(),
        body: AdbConsoleScreen(controller: widget.adbConsoleControllerFactory()),
      ),
    ));
  }

  void _openPerformance() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(),
        body: PerformanceScreen(controller: widget.performanceControllerFactory()),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final c = widget.controller;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.diagnostics_hero_title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(
          l10n.diagnostics_hero_subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        _sectionLabel(theme, l10n.diagnostics_health_section),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _networkTile(context, l10n, theme, c)),
            const SizedBox(width: 8),
            Expanded(child: _storageTile(context, l10n, theme, c)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _cameraHealthTile(context, l10n, theme, c)),
            const SizedBox(width: 8),
            Expanded(child: _batteryHealthTile(context, l10n, theme, c)),
          ],
        ),
        const SizedBox(height: 20),
        _sectionLabel(theme, l10n.diagnostics_tools_section),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _toolCard(key: 'diag.cardTraffic', theme: theme, icon: Icons.traffic, label: l10n.diagnostics_section_traffic, onTap: () => _showTrafficMonitorDialog(context, l10n, theme))),
          const SizedBox(width: 8),
          Expanded(child: _toolCard(key: 'diag.cardCameraProbe', theme: theme, icon: Icons.camera_alt_outlined, label: l10n.diagnostics_section_camera_probe, onTap: () => _showCameraSelectionDialog(context, l10n, theme))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _toolCard(key: 'diag.cardAdb', theme: theme, icon: Icons.terminal, label: l10n.diagnostics_section_adb_console, onTap: _openAdbConsole)),
          const SizedBox(width: 8),
          Expanded(child: _toolCard(key: 'diag.cardBattery', theme: theme, icon: Icons.battery_charging_full, label: l10n.diagnostics_section_battery, onTap: () => _showBatteryHealthDialog(context, l10n, theme))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _toolCard(key: 'diag.cardPerformance', theme: theme, icon: Icons.speed, label: l10n.diagnostics_section_performance, onTap: _openPerformance)),
          const SizedBox(width: 8),
          Expanded(child: _toolCard(key: 'diag.cardSettingsShortcut', theme: theme, icon: Icons.settings, label: l10n.rail_settings, onTap: widget.onOpenSettings)),
        ]),
      ],
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) => Text(
        text.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.6),
      );

  Widget _healthCard(ThemeData theme, {String? key, VoidCallback? onTap, required Widget child}) {
    final card = Card(
      key: key == null ? null : ValueKey(key),
      color: theme.colorScheme.surfaceContainerHigh,
      elevation: 0,
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
    return onTap == null ? card : InkWell(onTap: onTap, child: card);
  }

  Widget _dot(Color color) => Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle));

  Widget _networkTile(BuildContext context, AppLocalizations l10n, ThemeData theme, DiagnosticsController c) {
    final topLine = switch (c.networkType) {
      NetworkType.wifi => c.ssid ?? l10n.diagnostics_network_offline,
      NetworkType.mobile => l10n.diagnostics_network_mobile,
      NetworkType.ethernet => l10n.diagnostics_network_ethernet,
      NetworkType.offline => l10n.diagnostics_network_offline,
    };
    final (tunnelLabel, tunnelColor) = switch (c.tunnelState) {
      TunnelState.online => (l10n.diagnostics_tunnel_state_online, theme.colorScheme.primary),
      TunnelState.connecting => (l10n.diagnostics_tunnel_state_connecting, Colors.amber),
      TunnelState.offline => (l10n.diagnostics_tunnel_state_offline, theme.colorScheme.outline),
    };
    return _healthCard(
      theme,
      key: 'diag.network',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.wifi, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(l10n.diagnostics_health_network.toUpperCase(), style: theme.textTheme.labelSmall),
          Text(c.loading ? l10n.diagnostics_metric_pending : topLine, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(children: [
            _dot(tunnelColor),
            const SizedBox(width: 6),
            Flexible(child: Text(l10n.diagnostics_network_tunnel_label(tunnelLabel), style: theme.textTheme.labelSmall, overflow: TextOverflow.ellipsis)),
          ]),
        ],
      ),
    );
  }

  Widget _storageTile(BuildContext context, AppLocalizations l10n, ThemeData theme, DiagnosticsController c) {
    return _healthCard(
      theme,
      key: 'diag.storage',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.sd_storage_outlined, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(l10n.diagnostics_health_storage.toUpperCase(), style: theme.textTheme.labelSmall),
          Text(
            c.loading ? l10n.diagnostics_metric_pending : l10n.diagnostics_storage_used_line(c.storageClipCount, c.storageUsedFormatted),
            style: theme.textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            c.loading ? l10n.diagnostics_metric_pending : l10n.diagnostics_storage_free_line(c.storageFreeFormatted),
            style: theme.textTheme.labelSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _cameraHealthTile(BuildContext context, AppLocalizations l10n, ThemeData theme, DiagnosticsController c) {
    final (text, color) = switch (c.cameraStatus) {
      CameraTileStatus.offline => (l10n.diagnostics_camera_value_offline, theme.colorScheme.outline),
      CameraTileStatus.probing => (l10n.diagnostics_camera_value_probing, Colors.amber),
      CameraTileStatus.active => (
          c.cameraManualOverride
              ? l10n.diagnostics_camera_value_camera_n_manual(c.cameraProbedId)
              : l10n.diagnostics_camera_value_camera_n(c.cameraProbedId),
          theme.colorScheme.primary,
        ),
    };
    return _healthCard(
      theme,
      key: 'diag.cardCameraHealth',
      onTap: () => _showCameraSelectionDialog(context, l10n, theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Icon(Icons.camera_alt_outlined, color: theme.colorScheme.onSurfaceVariant),
            _dot(color),
          ]),
          const SizedBox(height: 12),
          Text(l10n.diagnostics_health_camera.toUpperCase(), style: theme.textTheme.labelSmall),
          Text(c.loading ? l10n.diagnostics_metric_pending : text, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _batteryHealthTile(BuildContext context, AppLocalizations l10n, ThemeData theme, DiagnosticsController c) {
    final color = switch (c.batteryLevel) {
      BatteryHealthLevel.pending => theme.colorScheme.outline,
      BatteryHealthLevel.neutral => theme.colorScheme.outline,
      BatteryHealthLevel.good => theme.colorScheme.primary,
      BatteryHealthLevel.moderate => Colors.amber,
    };
    final text = c.batterySohPercent == null
        ? l10n.diagnostics_battery_value_pending
        // diagnostics_battery_value_soh's placeholder has no numeric format
        // (untyped `Object`, unlike native's own `%1$.0f`) — round here so
        // the rendered text still matches native's whole-percent display.
        : l10n.diagnostics_battery_value_soh(c.batterySohPercent!.round());
    return _healthCard(
      theme,
      key: 'diag.cardBatteryHealth',
      onTap: () => _showBatteryHealthDialog(context, l10n, theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Icon(Icons.battery_charging_full, color: theme.colorScheme.onSurfaceVariant),
            _dot(color),
          ]),
          const SizedBox(height: 12),
          Text(l10n.diagnostics_health_battery.toUpperCase(), style: theme.textTheme.labelSmall),
          Text(c.loading ? l10n.diagnostics_metric_pending : text, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _toolCard({required String key, required ThemeData theme, required IconData icon, required String label, required VoidCallback onTap}) {
    return Card(
      key: ValueKey(key),
      color: theme.colorScheme.surfaceContainerHigh,
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Icon(icon, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: theme.textTheme.titleSmall, overflow: TextOverflow.ellipsis)),
          ]),
        ),
      ),
    );
  }

  // ─────────────────────────── Camera Selection dialog ───────────────────

  // Radio's value/groupValue don't reliably fire onChanged when the value is
  // null (tapping "Auto" again silently did nothing — caught by a widget
  // test, not the controller test, same lesson as
  // SettingsAppearanceController's missing notifyListeners() in yz1e.3): use
  // this non-null sentinel for "Auto" in the RadioGroup instead, converting
  // to/from selectCamera's real null-means-auto signature at the boundary.
  static const int _autoCameraId = -1;

  void _showCameraSelectionDialog(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    final c = widget.controller;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          int selected = c.cameraManualOverride ? c.cameraProbedId : _autoCameraId;
          final options = <(String, int)>[
            (l10n.camera_option_auto, _autoCameraId),
            (l10n.camera_option_0, 0),
            (l10n.camera_option_1, 1),
            (l10n.camera_option_2, 2),
            (l10n.camera_option_3, 3),
            (l10n.camera_option_4, 4),
            (l10n.camera_option_5, 5),
          ];
          return AlertDialog(
            title: Text(l10n.camera_selection_title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.camera_selection_subtitle, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Text(
                    c.cameraManualOverride ? l10n.camera_current_manual(c.cameraProbedId) : l10n.camera_current_auto_label,
                    style: theme.textTheme.labelMedium,
                  ),
                  RadioGroup<int>(
                    groupValue: selected,
                    onChanged: (value) async {
                      if (value == null) return;
                      setDialogState(() => selected = value);
                      final cameraId = value == _autoCameraId ? null : value;
                      final ok = await c.selectCamera(cameraId);
                      if (!dialogContext.mounted) return;
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                          !ok
                              ? l10n.toast_failed_to_save_short
                              : cameraId == null
                                  ? l10n.toast_camera_set_to_auto
                                  : l10n.toast_camera_id_set(cameraId),
                        ),
                      ));
                    },
                    child: Column(
                      children: [
                        for (final opt in options)
                          RadioListTile<int>(
                            key: ValueKey('diag.camera.option.${opt.$2 == _autoCameraId ? 'auto' : opt.$2}'),
                            dense: true,
                            title: Text(opt.$1),
                            value: opt.$2,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.camera_selection_hint, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            actions: [
              TextButton(key: const ValueKey('diag.camera.close'), onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.dialog_close)),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────── Battery Health dialog ──────────────────────

  // Native's `soh_percent > 0` file-derived "hasEstimate" (see
  // DiagnosticsController._refreshBattery's doc comment) has no RPC
  // equivalent; live/calibration displaySource is the closest honest signal
  // this port can read.
  String _batteryStatusText(AppLocalizations l10n, DiagnosticsController c) => switch (c.batteryDisplaySource) {
        'live' || 'calibration' => l10n.soh_estimation_active,
        'oem' => l10n.soh_oem_readout,
        'nominal' => l10n.soh_nominal_baseline,
        _ => l10n.soh_no_estimate_yet,
      };

  String _batteryNominalSourceSuffix(AppLocalizations l10n, String source) => switch (source) {
        'user' => ' (${l10n.soh_dialog_source_user})',
        'auto' => ' (${l10n.soh_dialog_source_auto})',
        _ => '',
      };

  void _showBatteryHealthDialog(BuildContext context, AppLocalizations l10n, ThemeData theme) {
    final c = widget.controller;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.battery_health_title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.batterySohPercent == null
                    ? l10n.diagnostics_battery_value_pending
                    : l10n.diagnostics_battery_value_soh(c.batterySohPercent!.round()),
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(_batteryStatusText(l10n, c), style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _batteryDetail(theme, l10n.battery_health_source, c.batteryNominalSource),
                ),
                Expanded(
                  child: _batteryDetail(theme, l10n.battery_health_method, c.batteryDisplaySource),
                ),
              ]),
              const SizedBox(height: 8),
              _batteryDetail(
                theme,
                l10n.battery_health_capacity,
                c.batteryNominalCapacityKwh > 0
                    ? '${c.batteryNominalCapacityKwh.toStringAsFixed(1)} kWh${_batteryNominalSourceSuffix(l10n, c.batteryNominalSource)}'
                    : l10n.soh_dialog_capacity_not_detected,
              ),
              const SizedBox(height: 12),
              Text(l10n.battery_health_reset_desc, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        actions: [
          TextButton(key: const ValueKey('diag.battery.close'), onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.dialog_close)),
          TextButton(
            key: const ValueKey('diag.battery.reset'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _confirmBatteryReset(context, l10n);
            },
            child: Text(l10n.battery_health_reset),
          ),
        ],
      ),
    );
  }

  Widget _batteryDetail(ThemeData theme, String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.bodyLarge),
        ],
      );

  void _confirmBatteryReset(BuildContext context, AppLocalizations l10n) {
    final c = widget.controller;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.dialog_reset_soh_title),
        content: SingleChildScrollView(child: Text(l10n.dialog_reset_soh_message)),
        actions: [
          TextButton(key: const ValueKey('diag.battery.resetCancel'), onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.action_cancel)),
          TextButton(
            key: const ValueKey('diag.battery.resetConfirm'),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final ok = await c.resetBattery();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(ok ? l10n.toast_soh_reset_success : l10n.toast_soh_reset_failed_no_daemon),
              ));
            },
            child: Text(l10n.dialog_reset),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── Traffic Monitor dialog ─────────────────────

  Future<void> _showTrafficMonitorDialog(BuildContext context, AppLocalizations l10n, ThemeData theme) async {
    final c = widget.controller;
    await c.checkTrafficMonitorStatus();
    if (!context.mounted) return;

    final enabled = c.trafficMonitorEnabled;
    if (enabled == null) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.dialog_traffic_cannot_check_title),
          content: SingleChildScrollView(child: Text(l10n.dialog_traffic_cannot_check_message)),
          actions: [
            TextButton(key: const ValueKey('diag.traffic.ok'), onPressed: () => Navigator.of(dialogContext).pop(), child: Text(l10n.dialog_ok)),
          ],
        ),
      );
      return;
    }

    final title = enabled ? l10n.dialog_traffic_disable_title : l10n.dialog_traffic_enable_title;
    final message = enabled ? l10n.dialog_traffic_disable_message : l10n.dialog_traffic_enable_message;
    final actionLabel = enabled ? l10n.dialog_disable : l10n.dialog_enable;
    final keepLabel = enabled ? l10n.dialog_keep_enabled : l10n.dialog_keep_disabled;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(message)),
        actions: [
          TextButton(key: const ValueKey('diag.traffic.keep'), onPressed: () => Navigator.of(dialogContext).pop(), child: Text(keepLabel)),
          TextButton(
            key: const ValueKey('diag.traffic.toggle'),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final ok = await c.setTrafficMonitorEnabled(!enabled);
              if (!context.mounted) return;
              if (ok) {
                await showDialog<void>(
                  context: context,
                  builder: (rebootContext) => AlertDialog(
                    title: Text(l10n.dialog_traffic_status_title(enabled ? l10n.dialog_disable : l10n.dialog_enable)),
                    content: SingleChildScrollView(child: Text(l10n.dialog_traffic_reboot_message)),
                    actions: [
                      TextButton(key: const ValueKey('diag.traffic.rebootOk'), onPressed: () => Navigator.of(rebootContext).pop(), child: Text(l10n.dialog_ok)),
                    ],
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toast_failed_to_save_short)));
              }
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
