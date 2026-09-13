import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:qr_flutter/qr_flutter.dart';

import '../../gen/l10n/app_localizations.dart';
import '../../rpc/services/system_service_client.dart';
import '../../shell/route_stubs.dart' show BwRoutes;
import 'dashboard_controller.dart';
import 'dashboard_models.dart';
import 'vehicle_dialog_controller.dart';

/// Ported from `app/src/main/java/com/loabletech/bladewatch/ui/fragment/DashboardFragment.kt`
/// + `fragment_dashboard.xml`. Renders [DashboardController] state; forwards
/// user intent (taps, dialog input) to it or to [onNavigate]. No business
/// logic here — see the controller for behaviour.
///
/// Route mapping for tap targets that native sends to `daemonsFragment`
/// (background-services tile, remote-access tile): [BwRoutes] has no
/// dedicated "daemons" destination, so both map to [BwRoutes.diagnostics] —
/// the closest existing rail destination for daemon/service health.
class DashboardScreen extends StatefulWidget {
  final DashboardController controller;
  final SystemServiceClient systemService;
  final void Function(String route) onNavigate;

  const DashboardScreen({super.key, required this.controller, required this.systemService, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final c = widget.controller;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _TripStatsCard(state: c.tripStats, l10n: l10n, theme: theme, onViewAllTrips: () => widget.onNavigate(BwRoutes.trips)),
            const SizedBox(height: 12),
            _HeroChips(controller: c, l10n: l10n, theme: theme),
            const SizedBox(height: 16),
            _MetricGrid(
              controller: c,
              l10n: l10n,
              theme: theme,
              onRecordingsTap: () => widget.onNavigate(BwRoutes.recordings),
              onTunnelTap: () => widget.onNavigate(BwRoutes.diagnostics),
              onDaemonsTap: () => widget.onNavigate(BwRoutes.diagnostics),
              onVehicleTap: _openVehicleDialog,
            ),
            const SizedBox(height: 16),
            _ConnectCard(controller: c, l10n: l10n, theme: theme),
            const SizedBox(height: 16),
            _QuickActions(l10n: l10n, theme: theme, onLive: () => widget.onNavigate(BwRoutes.liveView)),
          ],
        ),
      ),
    );
  }

  Future<void> _openVehicleDialog() async {
    final dialogController = VehicleDialogController(systemService: widget.systemService);
    await showDialog<void>(
      context: context,
      builder: (_) => _VehicleCapacityDialog(controller: dialogController),
    );
    dialogController.dispose();
    // Whatever the dialog did (saved, reset, or just closed), refresh the
    // vehicle tile so it reflects the daemon's current state.
    unawaited(widget.controller.refresh());
  }
}

class _TripStatsCard extends StatelessWidget {
  final TripStatsState state;
  final AppLocalizations l10n;
  final ThemeData theme;
  final VoidCallback onViewAllTrips;

  const _TripStatsCard({required this.state, required this.l10n, required this.theme, required this.onViewAllTrips});

  @override
  Widget build(BuildContext context) {
    final headline = state.loading
        ? l10n.dashboard_trips_loading
        : !state.available
            ? l10n.dashboard_trips_unavailable
            : state.tripCount == 0
                ? l10n.dashboard_trips_no_data
                : l10n.dashboard_trips_count(state.tripCount);
    final pending = l10n.dashboard_metric_value_pending;

    return Card(
      color: theme.colorScheme.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.dashboard_trips_this_week,
                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(headline, style: theme.textTheme.headlineSmall?.copyWith(color: theme.colorScheme.onSurface)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _Stat(
                    label: l10n.dashboard_trips_label_trips,
                    value: state.available ? state.tripCount.toString() : pending,
                    theme: theme,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: l10n.dashboard_trips_label_distance,
                    value: state.available ? state.distanceLabel : pending,
                    theme: theme,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: l10n.dashboard_trips_label_time,
                    value: state.available ? state.driveTimeLabel : pending,
                    theme: theme,
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey('tripStats.viewAll'),
                onPressed: onViewAllTrips,
                child: Text(l10n.dashboard_trips_view_all),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _Stat({required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurface)),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      );
}

/// Mirrors `refreshHeroChips()` — each chip repeats a metric-tile value at
/// the top of the screen for at-a-glance status; the tunnel chip is the only
/// one that hides itself (only shown when actually online).
class _HeroChips extends StatelessWidget {
  final DashboardController controller;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _HeroChips({required this.controller, required this.l10n, required this.theme});

  @override
  Widget build(BuildContext context) {
    final daemons = controller.daemonsSummary;
    final chips = <Widget>[
      if (controller.tunnel.phase == TunnelPhase.online) Chip(label: Text(l10n.dashboard_tunnel_online)),
      Chip(label: Text(l10n.dashboard_daemons_running(daemons.running, daemons.total))),
      Chip(
        label: Text(
          controller.recordingsMetric.isRecording ? l10n.dashboard_chip_recording_active : l10n.dashboard_chip_recording_idle,
        ),
      ),
    ];
    return Wrap(spacing: 8, runSpacing: 4, children: chips);
  }
}

class _MetricGrid extends StatelessWidget {
  final DashboardController controller;
  final AppLocalizations l10n;
  final ThemeData theme;
  final VoidCallback onRecordingsTap;
  final VoidCallback onTunnelTap;
  final VoidCallback onDaemonsTap;
  final VoidCallback onVehicleTap;

  const _MetricGrid({
    required this.controller,
    required this.l10n,
    required this.theme,
    required this.onRecordingsTap,
    required this.onTunnelTap,
    required this.onDaemonsTap,
    required this.onVehicleTap,
  });

  @override
  Widget build(BuildContext context) {
    final rec = controller.recordingsMetric;
    final recordingsValue = rec.loading
        ? l10n.dashboard_metric_value_pending
        : rec.isRecording
            ? l10n.dashboard_recordings_value_live(rec.todayCount)
            : rec.todayCount.toString();

    final tunnelValue =
        controller.tunnel.phase == TunnelPhase.online ? l10n.dashboard_tunnel_online : l10n.dashboard_tunnel_offline;

    final daemons = controller.daemonsSummary;
    final daemonsValue = l10n.dashboard_daemons_running(daemons.running, daemons.total);

    final vehicle = controller.vehicleTile;
    final String vehicleValue;
    if (vehicle.loading) {
      vehicleValue = l10n.dashboard_metric_value_pending;
    } else if (!vehicle.hasCapacity) {
      vehicleValue = l10n.dashboard_vehicle_tap_to_set;
    } else if (vehicle.modelId != null) {
      vehicleValue = l10n.dashboard_vehicle_summary(vehicle.nominalKwh.toStringAsFixed(1), modelDisplayName(vehicle.modelId));
    } else {
      vehicleValue = '${vehicle.nominalKwh.toStringAsFixed(1)} ${l10n.vehicle_dialog_capacity_suffix}';
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.4,
      children: [
        _MetricTile(
          key: const ValueKey('tile.recordings'),
          title: l10n.dashboard_metric_recordings,
          value: recordingsValue,
          theme: theme,
          onTap: onRecordingsTap,
        ),
        _MetricTile(
          key: const ValueKey('tile.tunnel'),
          title: l10n.dashboard_metric_tunnel,
          value: tunnelValue,
          theme: theme,
          onTap: onTunnelTap,
        ),
        _MetricTile(
          key: const ValueKey('tile.daemons'),
          title: l10n.dashboard_metric_services,
          value: daemonsValue,
          theme: theme,
          onTap: onDaemonsTap,
        ),
        _MetricTile(
          key: const ValueKey('tile.vehicle'),
          title: l10n.dashboard_metric_vehicle,
          value: vehicleValue,
          theme: theme,
          onTap: onVehicleTap,
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String title;
  final String value;
  final ThemeData theme;
  final VoidCallback onTap;

  const _MetricTile({super.key, required this.title, required this.value, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        color: theme.colorScheme.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(value,
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      );
}

/// Connect card: QR / placeholder, device id, and the access-code section —
/// ground truth: `rebuildTunnelChips()`/`renderQr()`/`showPlaceholder()` +
/// `loadAuthState()`/`toggleTokenVisibility()`/`copyTokenToClipboard()`/
/// `showRegenerateConfirmation()`/`showSetPasswordDialog()`. Only Zrok has
/// ever populated native's tunnel-chip list (checked: `collectAvailableTunnels()`),
/// so there is no tunnel-type selector here — just the one tunnel's state.
class _ConnectCard extends StatefulWidget {
  final DashboardController controller;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _ConnectCard({required this.controller, required this.l10n, required this.theme});

  @override
  State<_ConnectCard> createState() => _ConnectCardState();
}

class _ConnectCardState extends State<_ConnectCard> {
  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final theme = widget.theme;
    final c = widget.controller;
    final tunnel = c.tunnel;
    final online = tunnel.phase == TunnelPhase.online && tunnel.url != null && tunnel.url!.isNotEmpty;

    return Card(
      color: theme.colorScheme.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.dashboard_scan_to_connect, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface)),
            const SizedBox(height: 12),
            Center(
              child: online
                  ? Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.white,
                          child: QrImageView(data: tunnel.url!, size: 160),
                        ),
                        const SizedBox(height: 8),
                        Text(tunnel.url!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        l10n.dashboard_no_tunnel,
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              c.deviceId ?? l10n.dashboard_device_id_loading,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline, fontFamily: 'monospace'),
            ),
            const Divider(height: 24),
            Text(l10n.dashboard_access_code, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.onSurface)),
            const SizedBox(height: 8),
            _AccessCodeRow(controller: c, l10n: l10n, theme: theme),
          ],
        ),
      ),
    );
  }
}

class _AccessCodeRow extends StatelessWidget {
  final DashboardController controller;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _AccessCodeRow({required this.controller, required this.l10n, required this.theme});

  @override
  Widget build(BuildContext context) {
    final state = controller.accessCode;
    final text = state.loading
        ? l10n.dashboard_metric_value_pending
        : state.visible
            ? (state.displayValue ?? l10n.dashboard_metric_value_pending)
            : l10n.dashboard_token_masked;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(text, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface, fontFamily: 'monospace')),
            ),
            IconButton(
              key: const ValueKey('accessCode.toggle'),
              icon: Icon(state.visible ? Icons.visibility_off : Icons.visibility),
              onPressed: controller.toggleAccessCodeVisibility,
            ),
            IconButton(
              key: const ValueKey('accessCode.copy'),
              icon: const Icon(Icons.copy),
              // Fire-and-forget the clipboard write (Android's ClipboardManager
              // is sync; Flutter's Clipboard.setData is Future-based only
              // because of the platform-channel round trip) so the
              // confirmation shows immediately, matching native's
              // effectively-synchronous copyTokenToClipboard().
              onPressed: state.secret == null
                  ? null
                  : () {
                      Clipboard.setData(ClipboardData(text: state.secret!));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toast_access_code_copied)));
                    },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            OutlinedButton(
              key: const ValueKey('accessCode.regenerate'),
              onPressed: () => _confirmRegenerate(context),
              child: Text(l10n.dashboard_regenerate_token),
            ),
            OutlinedButton(
              key: const ValueKey('accessCode.setPassword'),
              onPressed: () => _showSetPasswordDialog(context),
              child: Text(l10n.dashboard_set_password),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmRegenerate(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.dialog_regenerate_token_title),
        content: Text(l10n.dialog_regenerate_token_message),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.action_cancel)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.dialog_regenerate)),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await controller.regenerateAccessCode();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? l10n.toast_token_regenerated : l10n.toast_token_regenerated_restart)),
    );
  }

  Future<void> _showSetPasswordDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _SetPasswordDialog(controller: controller, l10n: l10n),
    );
    if (result != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.toast_password_set)));
  }
}

class _SetPasswordDialog extends StatefulWidget {
  final DashboardController controller;
  final AppLocalizations l10n;

  const _SetPasswordDialog({required this.controller, required this.l10n});

  @override
  State<_SetPasswordDialog> createState() => _SetPasswordDialogState();
}

class _SetPasswordDialogState extends State<_SetPasswordDialog> {
  final _textController = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = widget.l10n;
    final password = _textController.text.trim();
    if (password.length < DashboardController.minAccessCodeLength) {
      setState(() => _error = l10n.toast_password_too_short);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await widget.controller.setCustomAccessCode(password);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _busy = false;
        _error = l10n.toast_password_save_failed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.dialog_set_password_title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.dialog_set_password_message),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            obscureText: true,
            decoration: InputDecoration(hintText: l10n.dialog_set_password_hint, errorText: _error),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.action_cancel)),
        TextButton(onPressed: _busy ? null : _submit, child: Text(l10n.action_done)),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  final AppLocalizations l10n;
  final ThemeData theme;
  final VoidCallback onLive;

  const _QuickActions({required this.l10n, required this.theme, required this.onLive});

  @override
  Widget build(BuildContext context) => Card(
        key: const ValueKey('quickAction.live'),
        color: theme.colorScheme.primaryContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onLive,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.videocam, color: theme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.dashboard_action_live,
                        style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
                    Text(l10n.dashboard_action_live_subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}

/// Ground truth: `showVehicleCapacityDialog()`. The model picker is a row of
/// choice chips rather than native's `MaterialAutoCompleteTextView` dropdown —
/// visual parity is Phase 3's job (see this screen's task notes), and BYD's
/// model list is short enough that chips need no menu/overlay at all.
class _VehicleCapacityDialog extends StatefulWidget {
  final VehicleDialogController controller;

  const _VehicleCapacityDialog({required this.controller});

  @override
  State<_VehicleCapacityDialog> createState() => _VehicleCapacityDialogState();
}

class _VehicleCapacityDialogState extends State<_VehicleCapacityDialog> {
  late final TextEditingController _textController;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    _textController = TextEditingController(text: widget.controller.state.capacityText);
    widget.controller.load();
  }

  void _onChanged() {
    if (!mounted) return;
    if (_textController.text != widget.controller.state.capacityText) {
      _textController.text = widget.controller.state.capacityText;
    }
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _textController.dispose();
    super.dispose();
  }

  Future<void> _save(AppLocalizations l10n) async {
    widget.controller.setCapacityText(_textController.text);
    final result = await widget.controller.save();
    if (!mounted) return;
    if (result == VehicleSaveResult.success) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _error = result == VehicleSaveResult.invalidCapacity ? l10n.vehicle_dialog_invalid_capacity : l10n.toast_password_save_failed;
      });
    }
  }

  Future<void> _reset() async {
    await widget.controller.reset();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = widget.controller.state;

    return AlertDialog(
      title: Text(l10n.vehicle_dialog_title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _textController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.vehicle_dialog_capacity_label,
                suffixText: l10n.vehicle_dialog_capacity_suffix,
                helperText: l10n.vehicle_dialog_capacity_helper,
                errorText: _error,
              ),
            ),
            const SizedBox(height: 12),
            if (state.models.isNotEmpty) ...[
              Text(l10n.vehicle_dialog_model_label),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  for (final model in state.models)
                    ChoiceChip(
                      label: Text(model.title),
                      selected: state.selectedModelId == model.id,
                      onSelected: (_) => widget.controller.selectModel(model.id),
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (state.hasCapacitySummary || state.hasSohSummary) const Divider(),
            if (state.hasCapacitySummary)
              Text(l10n.vehicle_dialog_summary_capacity(
                  '${state.nominalKwh.toStringAsFixed(1)} ${l10n.vehicle_dialog_capacity_suffix}${_sourceSuffix(l10n, state.nominalSource)}')),
            if (state.hasSohSummary) Text(l10n.vehicle_dialog_summary_soh(_sohText(l10n, state))),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _reset, child: Text(l10n.vehicle_dialog_reset)),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.action_cancel)),
        TextButton(onPressed: () => _save(l10n), child: Text(l10n.vehicle_dialog_save)),
      ],
    );
  }

  String _sourceSuffix(AppLocalizations l10n, String nominalSource) => switch (nominalSource) {
        'user' => ' (${l10n.soh_dialog_source_user})',
        'auto' => ' (${l10n.soh_dialog_source_auto})',
        _ => '',
      };

  String _sohText(AppLocalizations l10n, VehicleDialogState state) {
    final pct = state.displaySoh.toStringAsFixed(1);
    return switch (state.displaySource) {
      'live' => l10n.vehicle_dialog_soh_source_live(pct),
      'calibration' => l10n.vehicle_dialog_soh_source_calibration(pct),
      'oem' => l10n.vehicle_dialog_soh_source_oem(pct),
      'nominal' => l10n.vehicle_dialog_soh_source_nominal(pct),
      _ => l10n.vehicle_dialog_soh_unavailable,
    };
  }
}
