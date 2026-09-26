import 'dart:async' show Timer, unawaited;
import '../../platform/pairing_channel.dart';
import '../pairing/pairing_dialog.dart';

import 'package:flutter/material.dart';

import '../../gen/l10n/app_localizations.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import '../../shell/route_stubs.dart' show BwRoutes;
import 'dashboard_controller.dart';
import 'dashboard_models.dart';
import '../trips/trip_costs_view.dart';
import 'vehicle_dialog_controller.dart';
import '../../widgets/bw_choice_chip.dart';

/// Width at which the dashboard uses native's two-column arrangement (hero
/// beside Scan-to-Connect) and a five-across metric row. The head unit is
/// 1920 logical pixels wide; below this the screen stacks and wraps instead.
const double _twoColumnBreakpoint = 1100;

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

  /// BladeWatch-rdtj.7: the "Pair a device" action. Null hides it (tests that do not exercise it).
  final PairingChannel? pairingChannel;

  const DashboardScreen({
    super.key,
    required this.controller,
    required this.systemService,
    required this.onNavigate,
    this.pairingChannel,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  /// BladeWatch-rdtj.21: the tiles are status, so they re-read while the page is up. It used to
  /// load once, and on the head unit "Remote access: Online" stayed on screen after the car had
  /// lost its network. 15 s: the Pear status it shows is itself refreshed every 30 s.
  static const Duration _refreshInterval = Duration(seconds: 15);

  /// The drive chips on their own short cycle (see DashboardController.refreshDrive).
  static const Duration _driveInterval = Duration(seconds: 2);

  Timer? _refreshTimer;
  Timer? _driveTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.controller.refresh();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => widget.controller.refresh());
    _driveTimer = Timer.periodic(_driveInterval, (_) => widget.controller.refreshDrive());
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _driveTimer?.cancel();
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final c = widget.controller;

    final hero = _TripStatsCard(
      state: c.tripStats,
      l10n: l10n,
      theme: theme,
      onViewAllTrips: () => widget.onNavigate(BwRoutes.trips),
    );
    final metrics = _MetricRow(
      controller: c,
      l10n: l10n,
      theme: theme,
      onRecordingsTap: () => widget.onNavigate(BwRoutes.recordings),
      onDaemonsTap: () => widget.onNavigate(BwRoutes.diagnostics),
      onVehicleTap: _openVehicleDialog,
      onLiveTap: () => widget.onNavigate(BwRoutes.liveView),
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // The trip hero takes the full width: the connect card that sat beside it (tunnel
            // QR, device id, access code) went with tor (BladeWatch-rdtj.12).
            hero,
            const SizedBox(height: 12),
            _HeroChips(controller: c, l10n: l10n, theme: theme),
            // An explicit action, never a QR on the dashboard: a permanently visible pairing
            // code would be a permanently visible way in (BladeWatch-rdtj.7).
            if (widget.pairingChannel != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FilledButton.tonalIcon(
                  key: const ValueKey('dashboard.pair'),
                  onPressed: () => showPairingDialog(context, widget.pairingChannel!),
                  icon: const Icon(Icons.qr_code_2),
                  label: Text(l10n.pairing_title),
                ),
              ),
            ],
            const SizedBox(height: 16),
            metrics,
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
    // A headline only when the tiles below have nothing to say. Native's
    // "3 trips · 21.0 km" headline repeated the Trips and Distance tiles right
    // under it, so the owner saw both twice (BladeWatch-by8d).
    final headline = state.loading
        ? l10n.dashboard_trips_loading
        : !state.available
        ? l10n.dashboard_trips_unavailable
        : state.tripCount == 0
        ? l10n.dashboard_trips_no_data
        : null;
    final pending = l10n.dashboard_metric_value_pending;
    // The hero is the focal point of the screen, so it takes the filled
    // primaryContainer role as native does. Everything inside it must therefore
    // read against onPrimaryContainer, not onSurface.
    final onHero = theme.colorScheme.onPrimaryContainer;

    return Card(
      color: theme.colorScheme.primaryContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    l10n.dashboard_trips_this_week.toUpperCase(),
                    style: theme.textTheme.labelLarge?.copyWith(color: onHero),
                  ),
                ),
                // Top-right, on the label's baseline, as native has it.
                TextButton(
                  key: const ValueKey('tripStats.viewAll'),
                  onPressed: onViewAllTrips,
                  style: TextButton.styleFrom(foregroundColor: onHero),
                  child: Text(l10n.dashboard_trips_view_all),
                ),
              ],
            ),
            if (headline != null) ...[
              Text(headline, style: theme.textTheme.headlineMedium?.copyWith(color: onHero)),
              const SizedBox(height: 16),
            ] else
              const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _Stat(
                      label: l10n.dashboard_trips_label_trips,
                      value: state.available ? state.tripCount.toString() : pending,
                      theme: theme,
                      color: onHero,
                    ),
                  ),
                  _StatDivider(color: onHero),
                  Expanded(
                    child: _Stat(
                      label: l10n.dashboard_trips_label_distance,
                      value: state.available ? state.distanceLabel : pending,
                      theme: theme,
                      color: onHero,
                    ),
                  ),
                  _StatDivider(color: onHero),
                  Expanded(
                    child: _Stat(
                      label: l10n.dashboard_trips_label_time,
                      value: state.available ? state.driveTimeLabel : pending,
                      theme: theme,
                      color: onHero,
                    ),
                  ),
                ],
              ),
            ),
            // BladeWatch-39d2: what the week cost, under the three it always showed.
            if (state.available && state.tripCount > 0) ...[
              const SizedBox(height: 16),
              _TripCostsRow(costs: tripCostDisplay(state.costs, l10n), theme: theme, color: onHero),
            ],
          ],
        ),
      ),
    );
  }
}

/// The week's fuel, electric and total cost in the hero's stat style, or the line that says
/// why there are none (no rate set; more than one currency).
class _TripCostsRow extends StatelessWidget {
  final ({List<(String, String)> figures, String? message}) costs;
  final ThemeData theme;
  final Color color;

  const _TripCostsRow({required this.costs, required this.theme, required this.color});

  @override
  Widget build(BuildContext context) {
    final message = costs.message;
    if (message != null) {
      return Text(
        message,
        key: const ValueKey('tripStats.costs.message'),
        style: theme.textTheme.bodySmall?.copyWith(color: color.withValues(alpha: 0.8)),
      );
    }
    return IntrinsicHeight(
      key: const ValueKey('tripStats.costs'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, (value, label)) in costs.figures.indexed) ...[
            if (i > 0) _StatDivider(color: color),
            Expanded(
              child: _Stat(label: label, value: value, theme: theme, color: color),
            ),
          ],
        ],
      ),
    );
  }
}

/// The vertical rule native draws between the three hero stats.
class _StatDivider extends StatelessWidget {
  final Color color;

  const _StatDivider({required this.color});

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, margin: const EdgeInsets.symmetric(horizontal: 12), color: color.withValues(alpha: 0.3));
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  /// Foreground role of whatever surface the stat sits on — the hero is a
  /// filled primaryContainer, so onSurface would be unreadable there.
  final Color color;

  const _Stat({required this.label, required this.value, required this.theme, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text(value, style: theme.textTheme.headlineSmall?.copyWith(color: color)),
      Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color.withValues(alpha: 0.8))),
    ],
  );
}

/// Mirrors `refreshHeroChips()` — each chip repeats a metric-tile value at
/// the top of the screen for at-a-glance status.
class _HeroChips extends StatelessWidget {
  final DashboardController controller;
  final AppLocalizations l10n;
  final ThemeData theme;

  const _HeroChips({required this.controller, required this.l10n, required this.theme});

  @override
  Widget build(BuildContext context) {
    final daemons = controller.daemonsSummary;
    final chips = <Widget>[
      Chip(label: Text(l10n.dashboard_daemons_running(daemons.running, daemons.total))),
      Chip(
        label: Text(
          controller.recordingsMetric.isRecording
              ? l10n.dashboard_chip_recording_active
              : l10n.dashboard_chip_recording_idle,
        ),
      ),
      // BladeWatch-7zp9: the car's state. A dash for anything the car could not (or has not been
      // measured to) name -- never a guessed P / NORMAL / off.
      ..._driveChips(controller.drive),
    ];
    return Wrap(spacing: 8, runSpacing: 4, children: chips);
  }

  List<Widget> _driveChips(DriveInfo d) {
    String known(String v, String Function(String) show) => v == DriveInfo.unknown ? '–' : show(v);
    return [
      Chip(key: const ValueKey('chip.gear'), label: Text(l10n.dashboard_chip_gear(known(d.gear, (g) => g)))),
      Chip(
        key: const ValueKey('chip.driveMode'),
        label: Text(l10n.dashboard_chip_drive_mode(known(d.driveMode, (m) => m))),
      ),
      Chip(
        key: const ValueKey('chip.autoHold'),
        label: Text(
          l10n.dashboard_chip_auto_hold(
            known(
              d.autoHold,
              (a) => switch (a) {
                'ACTIVE' => l10n.auto_hold_active,
                'ENABLED' => l10n.auto_hold_enabled,
                'DISABLED' => l10n.auto_hold_disabled,
                _ => '–',
              },
            ),
          ),
        ),
      ),
      // BladeWatch-os88: EV / HEV, as the car itself labels them in every language. Hidden, not a
      // dash, when unknown: a car with no HEV mode has nothing to show.
      if (d.energyMode != DriveInfo.unknown) Chip(key: const ValueKey('chip.energyMode'), label: Text(d.energyMode)),
    ];
  }
}

/// Native's five metric cards in ONE row, each with a leading icon:
/// recordings, remote access, background services, Live, vehicle.
///
/// This replaces a 2-up grid that pushed the last three cards below the fold,
/// and it absorbs what used to be a separate full-width "quick action" card for
/// Live — native has never had that as a separate row (BladeWatch-ya6f).
class _MetricRow extends StatelessWidget {
  final DashboardController controller;
  final AppLocalizations l10n;
  final ThemeData theme;
  final VoidCallback onRecordingsTap;
  final VoidCallback onDaemonsTap;
  final VoidCallback onVehicleTap;
  final VoidCallback onLiveTap;

  const _MetricRow({
    required this.controller,
    required this.l10n,
    required this.theme,
    required this.onRecordingsTap,
    required this.onDaemonsTap,
    required this.onVehicleTap,
    required this.onLiveTap,
  });

  @override
  Widget build(BuildContext context) {
    final rec = controller.recordingsMetric;
    final recordingsValue = rec.loading
        ? l10n.dashboard_metric_value_pending
        : rec.isRecording
        ? l10n.dashboard_recordings_value_live(rec.todayCount)
        : rec.todayCount.toString();

    // BladeWatch-rdtj.17/.12: the Pear peer, remote access's only transport -- whether the car can
    // be found right now, not merely whether a process runs. Off until a companion is paired.
    final pear = controller.pear;
    final String remoteValue = !pear.enabled
        ? l10n.dashboard_tunnel_offline
        : !pear.running
        ? l10n.startup_status_starting
        : switch (pear.reachable) {
            true => l10n.dashboard_tunnel_online,
            false => l10n.dashboard_tunnel_offline,
            null => l10n.surveillance_general_status_running,
          };
    final remoteOnline = pear.enabled && pear.running && pear.reachable == true;

    final daemons = controller.daemonsSummary;
    final daemonsValue = l10n.dashboard_daemons_running(daemons.running, daemons.total);

    final vehicle = controller.vehicleTile;
    final String vehicleValue;
    // BladeWatch-p7vi: the capacity half is gone (removed-feature stubs), so the
    // tile shows the selected MODEL. "Tap to set" stays meaningful — tapping
    // still opens the dialog, which now picks a model.
    if (vehicle.loading) {
      vehicleValue = l10n.dashboard_metric_value_pending;
    } else if (vehicle.hasModel) {
      vehicleValue = modelDisplayName(vehicle.modelId);
    } else {
      vehicleValue = l10n.dashboard_vehicle_tap_to_set;
    }

    final tiles = <Widget>[
      _MetricTile(
        key: const ValueKey('tile.recordings'),
        icon: Icons.videocam_outlined,
        title: l10n.dashboard_metric_recordings,
        value: recordingsValue,
        theme: theme,
        onTap: onRecordingsTap,
      ),
      _MetricTile(
        key: const ValueKey('tile.tunnel'),
        icon: Icons.dashboard_outlined,
        title: l10n.dashboard_metric_tunnel,
        value: remoteValue,
        theme: theme,
        // Pear's details -- reachability, connected devices, its switch -- live on the Services screen.
        onTap: onDaemonsTap,
        // Native's remote-access card is the only one with a status dot.
        showStatusDot: remoteOnline,
      ),
      _MetricTile(
        key: const ValueKey('tile.daemons'),
        icon: Icons.memory_outlined,
        title: l10n.dashboard_metric_services,
        value: daemonsValue,
        theme: theme,
        onTap: onDaemonsTap,
      ),
      _MetricTile(
        // Key preserved from the old standalone quick-action card so existing
        // tests and any muscle memory keep working.
        key: const ValueKey('quickAction.live'),
        icon: Icons.play_circle_outline,
        title: l10n.dashboard_action_live_subtitle,
        value: l10n.dashboard_action_live,
        theme: theme,
        onTap: onLiveTap,
      ),
      _MetricTile(
        key: const ValueKey('tile.vehicle'),
        icon: Icons.directions_car_outlined,
        title: l10n.dashboard_metric_vehicle,
        value: vehicleValue,
        theme: theme,
        onTap: onVehicleTap,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Five across only where they actually fit; below that, wrap rather
        // than squeeze each card into an unreadable sliver.
        if (constraints.maxWidth >= _twoColumnBreakpoint) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: tiles[i]),
                ],
              ],
            ),
          );
        }
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [for (final tile in tiles) SizedBox(width: (constraints.maxWidth - 12) / 2, child: tile)],
        );
      },
    );
  }
}

/// Native's metric card: icon on top, the VALUE large beneath it, then the
/// label. The port previously had label-then-value, which reads as a form field
/// rather than a status readout.
class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final ThemeData theme;
  final VoidCallback onTap;
  final bool showStatusDot;

  const _MetricTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.theme,
    required this.onTap,
    this.showStatusDot = false,
  });

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
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
                const Spacer(),
                if (showStatusDot)
                  Container(
                    key: const ValueKey('tile.statusDot'),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
  String? _error;

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

  Future<void> _save(AppLocalizations l10n) async {
    final result = await widget.controller.save();
    if (!mounted) return;
    if (result == VehicleSaveResult.success) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        // BladeWatch-p7vi: prefer the daemon's own reason when it gave one,
        // rather than a generic failure. toast_failed_to_save_short, not
        // toast_password_save_failed — this dialog saves no password, and that
        // string ("Failed to save password — service not ready") was simply the
        // wrong message.
        _error = (widget.controller.lastError?.isNotEmpty ?? false)
            ? widget.controller.lastError!
            : l10n.toast_failed_to_save_short;
      });
    }
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
            if (state.models.isNotEmpty) ...[
              Text(l10n.vehicle_dialog_model_label),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  for (final model in state.models)
                    BwChoiceChip(
                      key: ValueKey('vehicleDialog.model.${model.id}'),
                      label: Text(model.title),
                      selected: state.selectedModelId == model.id,
                      onSelected: (_) => widget.controller.selectModel(model.id),
                    ),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                key: const ValueKey('vehicleDialog.error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.action_cancel)),
        TextButton(onPressed: () => _save(l10n), child: Text(l10n.vehicle_dialog_save)),
      ],
    );
  }
}
