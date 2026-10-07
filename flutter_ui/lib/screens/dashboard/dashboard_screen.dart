import 'dart:async' show Timer, unawaited;
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../gen/l10n/app_localizations.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import '../../shell/route_stubs.dart' show BwRoutes;
import '../../theme/hud_theme.dart';
import '../../widgets/hud_widgets.dart';
import 'dashboard_controller.dart';
import 'dashboard_models.dart';
import '../trips/trip_costs_view.dart';
import '../trips/trips_models.dart' show formatDistance;
import 'vehicle_dialog_controller.dart';
import '../../widgets/bw_choice_chip.dart';

/// Width at which the dashboard uses five tiles across. The head unit is 1920 logical pixels wide
/// (1280 dp); below this the tiles wrap two to a row.
const double _twoColumnBreakpoint = 1100;

/// The reference's page padding (`p-6`), all round.
const double _pagePadding = 24;

/// BladeWatch-rdtj.17/.12: the Pear peer, remote access's only transport -- whether the car can be
/// found right now, not merely whether a process runs. Off until a companion is paired. The Remote
/// access tile and the title bar's secure-link label both read this, so they cannot disagree.
bool _remoteOnline(DashboardController c) => c.pear.enabled && c.pear.running && c.pear.reachable == true;

/// Ported from `app/src/main/java/com/loabletech/bladewatch/ui/fragment/DashboardFragment.kt`
/// + `fragment_dashboard.xml`, then re-skinned to the HUD design (BladeWatch-8w4p; reference in
/// `docs/design/hud-reference/`). Renders [DashboardController] state; forwards user intent (taps,
/// dialog input) to it or to [onNavigate]. No business logic here — see the controller for behaviour.
///
/// Route mapping for tap targets that native sends to `daemonsFragment`
/// (background-services tile, remote-access tile): [BwRoutes] has no
/// dedicated "daemons" destination, so both map to [BwRoutes.diagnostics] —
/// the closest existing rail destination for daemon/service health.
class DashboardScreen extends StatefulWidget {
  final DashboardController controller;
  final SystemServiceClient systemService;
  final void Function(String route) onNavigate;

  const DashboardScreen({
    super.key,
    required this.controller,
    required this.systemService,
    required this.onNavigate,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  /// BladeWatch-rdtj.21: the tiles are status, so they re-read while the page is up. It used to
  /// load once, and on the head unit "Remote access: Online" stayed on screen after the car had
  /// lost its network. 15 s: the Pear status it shows is itself refreshed every 30 s.
  static const Duration _refreshInterval = Duration(seconds: 15);

  /// The drive chips, and THIS WEEK's charge and fuel, on their own short cycle (see
  /// DashboardController.refreshDrive).
  static const Duration _driveInterval = Duration(seconds: 2);

  /// The week's trips and costs: they change when a trip ends, and each reload pages through a
  /// week of ListTrips, so once a minute is enough (the owner's call, 2026-09-27).
  static const Duration _tripsInterval = Duration(minutes: 1);

  Timer? _refreshTimer;
  Timer? _driveTimer;
  Timer? _tripsTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.controller.refresh();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => widget.controller.refresh(includeTrips: false));
    _driveTimer = Timer.periodic(_driveInterval, (_) => widget.controller.refreshDrive());
    _tripsTimer = Timer.periodic(_tripsInterval, (_) => widget.controller.refreshTrips());
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _driveTimer?.cancel();
    _tripsTimer?.cancel();
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hud = BwHud.of(context);
    final c = widget.controller;

    // The blocks are spread down the page (the reference's justify-between) when the window is
    // taller than they are, and the page scrolls when it is shorter. The margins under the first
    // three are the minimum gaps.
    final blocks = <Widget>[
      HudTitleBar(
        title: '${l10n.rail_dashboard} // ${l10n.dashboard_hud_overview}'.toUpperCase(),
        titleKey: const ValueKey('dashboard.title'),
        // Only ever ACTIVE while the Remote access tile says Online: the design's label is unconditional, but a
        // link that is not up must not be claimed.
        trailing: Text(
          _remoteOnline(c) ? l10n.dashboard_hud_link_active : l10n.dashboard_hud_link_offline,
          key: const ValueKey('dashboard.secureLink'),
          style: hudText(12, hud.magenta, lineHeight: 16, weight: FontWeight.w700, em: 0.1),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        // The trip hero takes the full width: the connect card that sat beside it (tunnel QR, device id,
        // access code) went with tor (BladeWatch-rdtj.12).
        child: _TripStatsCard(
          state: c.tripStats,
          l10n: l10n,
          hud: hud,
          onViewAllTrips: () => widget.onNavigate(BwRoutes.trips),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: _VehicleCard(energy: c.energy, l10n: l10n, hud: hud),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: _HeroChips(controller: c, l10n: l10n, hud: hud),
      ),
      _MetricRow(
        controller: c,
        l10n: l10n,
        hud: hud,
        onRecordingsTap: () => widget.onNavigate(BwRoutes.recordings),
        onDaemonsTap: () => widget.onNavigate(BwRoutes.diagnostics),
        onVehicleTap: _openVehicleDialog,
        onLiveTap: () => widget.onNavigate(BwRoutes.liveView),
      ),
    ];

    return Scaffold(
      backgroundColor: hud.pageBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(_pagePadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: math.max(0, constraints.maxHeight - 2 * _pagePadding)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: blocks,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openVehicleDialog() async {
    final dialogController = VehicleDialogController(systemService: widget.systemService);
    await showHudDialog<void>(
      context: context,
      builder: (_) => _VehicleCapacityDialog(controller: dialogController),
    );
    dialogController.dispose();
    // Whatever the dialog did (saved, reset, or just closed), refresh the
    // vehicle tile so it reflects the daemon's current state.
    unawaited(widget.controller.refresh());
  }
}

/// One stat of the hero: a value over its label. [hasUnit] marks a distance (`83.3 km`), whose unit
/// is drawn smaller.
class _Stat {
  final String value;
  final String label;
  final bool hasUnit;
  final Color? valueColor;
  final Shadow? glow;
  final Color? labelColor;

  const _Stat(this.value, this.label, {this.hasUnit = false, this.valueColor, this.glow, this.labelColor});
}

class _TripStatsCard extends StatelessWidget {
  final TripStatsState state;
  final AppLocalizations l10n;
  final BwHud hud;
  final VoidCallback onViewAllTrips;

  const _TripStatsCard({
    required this.state,
    required this.l10n,
    required this.hud,
    required this.onViewAllTrips,
  });

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

    // The week's figures: trips, distance and drive time. The first two glow cyan, the drive time magenta.
    final trips = [
      _Stat(
        state.available ? state.tripCount.toString() : pending,
        l10n.dashboard_trips_label_trips,
        glow: hud.glowCyan,
      ),
      _Stat(
        state.available ? state.distanceLabel : pending,
        l10n.dashboard_trips_label_distance,
        hasUnit: state.available,
        glow: hud.glowCyan,
      ),
      _Stat(
        state.available ? state.driveTimeLabel : pending,
        l10n.dashboard_trips_label_time,
        valueColor: hud.driveTimeValue,
        glow: hud.glowMagenta,
        labelColor: hud.magenta,
      ),
    ];
    // BladeWatch-39d2: what the week cost, or the line that says why there are no figures.
    final costs = state.available && state.tripCount > 0 ? tripCostDisplay(state.costs, l10n) : null;
    final costFigures = [
      for (final (value, label) in costs?.figures ?? const <(String, String)>[]) _Stat(value, label),
    ];
    final costMessage = costs?.message;
    // The vertical rules run through the rows that are stat rows; a message row breaks them.
    final rows = <Widget>[
      _StatRow(
        hud: hud,
        // The rules run on into the cost row; the last row ends the card.
        gapBelow: costs != null && costMessage == null,
        cells: [for (final s in trips) _StatCell(stat: s, big: true, hud: hud)],
      ),
      if (costMessage != null) ...[
        const SizedBox(height: 16),
        Text(
          costMessage,
          key: const ValueKey('tripStats.costs.message'),
          style: hudText(12, hud.statLabel, lineHeight: 16, weight: hud.labelWeight, em: 0.05),
        ),
      ] else if (costs != null)
        _StatRow(
          key: const ValueKey('tripStats.costs'),
          hud: hud,
          gapBelow: false,
          cells: [for (final s in costFigures) _StatCell(stat: s, hud: hud)],
        ),
    ];

    return _HeroPanel(
      hud: hud,
      icon: Icons.memory,
      title: '${l10n.dashboard_trips_this_week} ${l10n.dashboard_hud_telemetry}',
      // Top-right, level with the label, as native has it. The box is the reference's; the
      // touch target stays 48 dp (TextButton pads it).
      action: TextButton(
        key: const ValueKey('tripStats.viewAll'),
        onPressed: onViewAllTrips,
        style: TextButton.styleFrom(
          tapTargetSize: MaterialTapTargetSize.padded,
          foregroundColor: hud.accent,
          backgroundColor: hud.viewAllFill,
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          side: BorderSide(color: hud.panelBorderStrong),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(BwHud.radiusSmall)),
          textStyle: hudText(12, hud.accent, lineHeight: 16, weight: FontWeight.w700, em: 0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.dashboard_trips_view_all),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 14),
          ],
        ),
      ),
      children: [
        if (headline != null) ...[
          Text(
            headline,
            style: hudText(24, hud.textPrimary, lineHeight: 32, weight: FontWeight.w700, em: -0.025),
          ),
          const SizedBox(height: 16),
        ],
        ...rows,
      ],
    );
  }
}

/// The hero's panel: the summary gradient, the two corner glows, and an icon and label over a divider.
/// THIS WEEK and VEHICLE share it, so their stat columns line up down the page.
class _HeroPanel extends StatelessWidget {
  final BwHud hud;
  final IconData icon;
  final String title;

  /// Ends the header row (THIS WEEK's View all trips).
  final Widget? action;
  final List<Widget> children;

  const _HeroPanel({required this.hud, required this.icon, required this.title, this.action, required this.children});

  @override
  Widget build(BuildContext context) {
    // An action's 48 dp touch target adds 11 above and below the reference's 26 dp button, so the
    // paddings around a header with one are 11 smaller: 13 above, 1 below the label instead of 24 and 12.
    final trim = action == null ? 0.0 : 11.0;
    return HudPanel(
      color: null,
      gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: hud.summaryGradient),
      borderColor: hud.cardBorder,
      radius: BwHud.radiusPanel,
      shadows: hud.cardShadow,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // The two blurred corner blobs, as radial gradients (an ImageFilter blur would cost an
          // offscreen layer per frame on the head unit's GPU).
          Positioned(right: -80, top: -80, width: 240, height: 240, child: _CornerGlow(color: hud.cornerGlowCyan)),
          Positioned(left: -80, bottom: -80, width: 240, height: 240, child: _CornerGlow(color: hud.cornerGlowMagenta)),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 24 - trim, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: EdgeInsets.only(bottom: 12 - trim),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: hud.cardDivider)),
                  ),
                  child: Row(
                    // Centered: the button's 48 px touch target otherwise sat its text ~20 px below the
                    // label it pairs with (design review 2026-09-27).
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(icon, size: 14, color: hud.magenta),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title.toUpperCase(),
                          style: hudText(12, hud.accent, lineHeight: 16, weight: FontWeight.w700, em: 0.1),
                        ),
                      ),
                      ?action,
                    ],
                  ),
                ),
                ...children,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The car now, in its own card under THIS WEEK (BladeWatch-4zr7 put these under the week's rows;
/// the owner moved them out, 2026-10-04): battery and electric range, and fuel and fuel range on a
/// car with a tank, on the same three columns as the card above.
class _VehicleCard extends StatelessWidget {
  final EnergyState energy;
  final AppLocalizations l10n;
  final BwHud hud;

  const _VehicleCard({required this.energy, required this.l10n, required this.hud});

  @override
  Widget build(BuildContext context) => _HeroPanel(
    hud: hud,
    icon: Icons.directions_car,
    title: l10n.dashboard_metric_vehicle,
    children: [_energyRow()],
  );

  Widget _energyRow() {
    final e = energy;
    final pending = l10n.dashboard_metric_value_pending;
    String dist(double km) => e.available ? formatDistance(km, e.distanceUnit, decimals: 0) : pending;
    bool known(String v) => v != pending;
    final battery = _Stat(
      e.available ? e.batteryLabel : pending,
      l10n.dashboard_week_battery,
      hasUnit: e.available && e.packKwh > 0,
    );
    final evRange = _Stat(dist(e.elecRangeKm), l10n.dashboard_week_elec_range, hasUnit: known(dist(e.elecRangeKm)));
    final fuel = _Stat(e.fuelLabel, l10n.dashboard_week_fuel, hasUnit: e.tankL > 0);
    final fuelRange = _Stat(dist(e.fuelRangeKm), l10n.dashboard_week_fuel_range, hasUnit: known(dist(e.fuelRangeKm)));

    return _StatRow(
      key: const ValueKey('vehicle.energy'),
      hud: hud,
      gapBelow: false,
      cells: [
        // "77% / 14.1 kWh" is the row's longest value: scaled down rather than wrapped.
        FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: _StatCell(stat: battery, hud: hud)),
        _StatCell(stat: evRange, hud: hud),
        // The third column holds Fuel and Fuel Range side by side on a car with a tank, and is
        // empty on one without (a BEV shows no fuel rather than 0).
        if (e.hasFuel)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            // Scaled down rather than overflowing when the column is narrow (portrait, a long label).
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: _StatCell(stat: fuel, hud: hud),
                ),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: _StatCell(stat: fuelRange, hud: hud, alignEnd: true),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// A soft coloured blob for a corner of the hero.
class _CornerGlow extends StatelessWidget {
  final Color color;

  const _CornerGlow({required this.color});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    ),
  );
}

/// One row of the hero's stats on the card's three columns. The columns are `1fr` with a 24 gap; the
/// first two carry a 1 px rule after 16 of padding, the last 8 of left padding. [gapBelow] carries the
/// rules through the 16 dp before the next stat row so they read as one line, as the reference's
/// column borders do. A row with fewer than three cells leaves its last columns empty.
class _StatRow extends StatelessWidget {
  final BwHud hud;
  final List<Widget> cells;
  final bool gapBelow;

  const _StatRow({super.key, required this.hud, required this.cells, required this.gapBelow});

  @override
  Widget build(BuildContext context) {
    Widget cell(int i) => Padding(
      padding: EdgeInsets.only(bottom: gapBelow ? 16 : 0),
      child: Align(alignment: Alignment.topLeft, child: i < cells.length ? cells[i] : const SizedBox.shrink()),
    );
    Widget ruled(int i) => Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: cell(i)),
          const SizedBox(width: 16),
          Container(width: 1, color: hud.cardDivider),
        ],
      ),
    );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ruled(0),
          const SizedBox(width: 24),
          ruled(1),
          const SizedBox(width: 24),
          Expanded(
            child: Padding(padding: const EdgeInsets.only(left: 8), child: cell(2)),
          ),
        ],
      ),
    );
  }
}

/// A stat's value over its label. [big] is the week's first row (30 dp); the others are 24 dp.
class _StatCell extends StatelessWidget {
  final _Stat stat;
  final BwHud hud;
  final bool big;
  final bool alignEnd;

  const _StatCell({required this.stat, required this.hud, this.big = false, this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    final size = big ? 30.0 : 24.0;
    final shadows = hudGlow(stat.glow);
    final valueStyle = hudText(
      size,
      stat.valueColor ?? hud.textPrimary,
      lineHeight: big ? 36 : 32,
      weight: FontWeight.w700,
      em: -0.025,
      shadows: shadows,
    );
    // One Text.rich, so the plain text stays the formatted string ("83.3 km"): only the unit,
    // after the last space, is smaller. Never applied to a duration ("2h 32m") or a cost.
    final split = stat.hasUnit ? stat.value.lastIndexOf(' ') : -1;
    final value = split <= 0
        ? TextSpan(text: stat.value, style: valueStyle)
        : TextSpan(
            style: valueStyle,
            children: [
              TextSpan(text: stat.value.substring(0, split + 1)),
              TextSpan(
                text: stat.value.substring(split + 1),
                // The rule's tracking is inherited as the parent's absolute value, not re-derived.
                style: hudText(18, hud.accentBright, lineHeight: 28, em: -0.025 * size / 18, shadows: shadows),
              ),
            ],
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text.rich(value, textAlign: alignEnd ? TextAlign.end : TextAlign.start),
        const SizedBox(height: 2),
        Text(
          stat.label,
          style: hudText(12, stat.labelColor ?? hud.statLabel, lineHeight: 16, weight: hud.labelWeight, em: 0.05),
        ),
      ],
    );
  }
}

/// Mirrors `refreshHeroChips()` — each chip repeats a metric-tile value at
/// the top of the screen for at-a-glance status.
class _HeroChips extends StatelessWidget {
  final DashboardController controller;
  final AppLocalizations l10n;
  final BwHud hud;

  const _HeroChips({required this.controller, required this.l10n, required this.hud});

  @override
  Widget build(BuildContext context) {
    final recording = controller.recordingsMetric.isRecording;
    // No "4/4 Running" chip: the Background services tile below says exactly that (design review
    // 2026-09-27, the owner's call).
    final chips = <Widget>[
      HudChip(
        key: const ValueKey('chip.recording'),
        label: recording ? l10n.dashboard_chip_recording_active : l10n.dashboard_chip_recording_idle,
        live: recording,
        dotKey: const ValueKey('chip.recordingDot'),
      ),
      // BladeWatch-7zp9: the car's state. A dash for anything the car could not (or has not been
      // measured to) name -- never a guessed P / NORMAL / off.
      ..._driveChips(controller.drive),
    ];
    return Wrap(spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center, children: chips);
  }

  List<Widget> _driveChips(DriveInfo d) {
    String known(String v, String Function(String) show) => v == DriveInfo.unknown ? '–' : show(v);
    return [
      HudChip(key: const ValueKey('chip.gear'), label: l10n.dashboard_chip_gear(known(d.gear, (g) => g))),
      HudChip(
        key: const ValueKey('chip.driveMode'),
        label: l10n.dashboard_chip_drive_mode(known(d.driveMode, (m) => m)),
      ),
      HudChip(
        key: const ValueKey('chip.autoHold'),
        label: l10n.dashboard_chip_auto_hold(
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
      // BladeWatch-os88: EV / HEV, as the car itself labels them in every language. Hidden, not a
      // dash, when unknown: a car with no HEV mode has nothing to show.
      if (d.energyMode != DriveInfo.unknown) HudChip(key: const ValueKey('chip.energyMode'), label: d.energyMode),
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
  final BwHud hud;
  final VoidCallback onRecordingsTap;
  final VoidCallback onDaemonsTap;
  final VoidCallback onVehicleTap;
  final VoidCallback onLiveTap;

  const _MetricRow({
    required this.controller,
    required this.l10n,
    required this.hud,
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
        // The string carries a "●" bullet; the HUD draws it as the glowing dot instead.
        ? l10n.dashboard_recordings_value_live(rec.todayCount).replaceFirst('●', '').trim()
        : rec.todayCount.toString();

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
    final remoteOnline = _remoteOnline(controller);

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
        icon: Icons.videocam,
        title: l10n.dashboard_metric_recordings,
        value: recordingsValue.toUpperCase(),
        hud: hud,
        onTap: onRecordingsTap,
        // The reference shows this dot unconditionally; here it is the recording state.
        leadingDot: rec.isRecording,
      ),
      _MetricTile(
        key: const ValueKey('tile.tunnel'),
        icon: Icons.lan,
        title: l10n.dashboard_metric_tunnel,
        value: remoteValue.toUpperCase(),
        hud: hud,
        valueColor: hud.onlineValue,
        valueGlow: hud.glowCyan,
        // Pear's details -- reachability, connected devices, its switch -- live on the Services screen.
        onTap: onDaemonsTap,
        // Native's remote-access card is the only one with a status dot.
        showStatusDot: remoteOnline,
      ),
      _MetricTile(
        key: const ValueKey('tile.daemons'),
        icon: Icons.memory,
        title: l10n.dashboard_metric_services,
        value: daemonsValue.toUpperCase(),
        hud: hud,
        onTap: onDaemonsTap,
      ),
      _MetricTile(
        // Key preserved from the old standalone quick-action card so existing
        // tests and any muscle memory keep working.
        key: const ValueKey('quickAction.live'),
        icon: Icons.play_circle,
        iconColor: hud.magenta,
        title: l10n.dashboard_action_live_subtitle,
        value: l10n.dashboard_action_live.toUpperCase(),
        hud: hud,
        valueColor: hud.liveValue,
        valueGlow: hud.glowMagenta,
        onTap: onLiveTap,
      ),
      _MetricTile(
        key: const ValueKey('tile.vehicle'),
        icon: Icons.directions_car,
        title: l10n.dashboard_metric_vehicle,
        // Not uppercased: a model name has its own casing ("DM-i").
        value: vehicleValue,
        small: true,
        hud: hud,
        onTap: onVehicleTap,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Five across only where they actually fit; below that, wrap rather
        // than squeeze each card into an unreadable sliver.
        if (constraints.maxWidth >= _twoColumnBreakpoint) {
          return SizedBox(
            height: _MetricTile.height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < tiles.length; i++) ...[
                  if (i > 0) const SizedBox(width: 16),
                  Expanded(child: tiles[i]),
                ],
              ],
            ),
          );
        }
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            for (final tile in tiles)
              SizedBox(width: (constraints.maxWidth - 16) / 2, height: _MetricTile.height, child: tile),
          ],
        );
      },
    );
  }
}

/// Native's metric card in the HUD skin: icon on top, the VALUE large beneath it, then the label.
class _MetricTile extends StatelessWidget {
  /// `h-28`.
  static const double height = 112;

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String value;
  final BwHud hud;
  final VoidCallback onTap;
  final bool showStatusDot;

  /// A glowing dot before the value (the recordings tile while recording).
  final bool leadingDot;

  /// The vehicle model is 12 dp, not 20: it is a name, not a figure.
  final bool small;
  final Color? valueColor;
  final Shadow? valueGlow;

  const _MetricTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.hud,
    required this.onTap,
    this.iconColor,
    this.showStatusDot = false,
    this.leadingDot = false,
    this.small = false,
    this.valueColor,
    this.valueGlow,
  });

  @override
  Widget build(BuildContext context) {
    Widget glowDot(double size, Key? key, double blur) => Container(
      key: key,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: hud.dot,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: hud.dotGlow, blurRadius: blur)],
      ),
    );
    return HudPanel(
      color: hud.panel,
      borderColor: hud.panelBorder,
      radius: BwHud.radiusSmall,
      shadows: hud.tileShadow,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(BwHud.radiusSmall),
          splashColor: hud.panelPressed,
          highlightColor: hud.panelPressed,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 18, color: iconColor ?? hud.iconAccent),
                    const Spacer(),
                    if (showStatusDot) glowDot(10, const ValueKey('tile.statusDot'), 8),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Shrunk to fit, not cut: "BYD Seal 5 DM-i" lost its end to an ellipsis on the head
                    // unit (design review 2026-09-27).
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (leadingDot) ...[
                            glowDot(8, const ValueKey('tile.recordingDot'), 6),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            value,
                            maxLines: 1,
                            style: hudText(
                              small ? 12 : 20,
                              valueColor ?? hud.textPrimary,
                              lineHeight: small ? 16 : 28,
                              weight: FontWeight.w700,
                              em: -0.025,
                              shadows: hudGlow(valueGlow),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: hudText(10, hud.tileLabel, lineHeight: 15, weight: hud.labelWeight, em: 0.05),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
