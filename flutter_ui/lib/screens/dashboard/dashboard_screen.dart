import 'dart:async' show unawaited;
import '../../platform/pairing_channel.dart';
import '../pairing/pairing_dialog.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:qr_flutter/qr_flutter.dart';

import '../../gen/l10n/app_localizations.dart';
import 'package:bladewatch_rpc/rpc/services/system_service_client.dart';
import '../../shell/route_stubs.dart' show BwRoutes;
import 'dashboard_controller.dart';
import 'dashboard_models.dart';
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

    final hero = _TripStatsCard(
      state: c.tripStats,
      l10n: l10n,
      theme: theme,
      onViewAllTrips: () => widget.onNavigate(BwRoutes.trips),
    );
    // BladeWatch-y7x2: no card at all when the owner has switched the tunnel OFF.
    //
    // Only for the DISABLED phase, never for offline/connecting — an enabled tunnel is
    // also not up for the first minute while tor bootstraps, and hiding the card then
    // would make the Dashboard look broken exactly while the user waits for it.
    //
    // The access code goes with the card deliberately: it only ever authenticates the
    // web app, and with no tunnel and LAN HTTP off by default the web app is not
    // reachable at all, so there is nothing for the code to unlock.
    final tunnelDisabled = c.tunnel.phase == TunnelPhase.disabled;
    final connect = tunnelDisabled
        ? null
        : _ConnectCard(controller: c, l10n: l10n, theme: theme);
    final metrics = _MetricRow(
      controller: c,
      l10n: l10n,
      theme: theme,
      onRecordingsTap: () => widget.onNavigate(BwRoutes.recordings),
      onTunnelTap: () => widget.onNavigate(BwRoutes.diagnostics),
      onDaemonsTap: () => widget.onNavigate(BwRoutes.diagnostics),
      onVehicleTap: _openVehicleDialog,
      onLiveTap: () => widget.onNavigate(BwRoutes.liveView),
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        // LayoutBuilder rather than a hardcoded two-column layout: the head
        // unit is 1920x1080, but the same screen has to degrade sensibly if the
        // window is ever narrower.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= _twoColumnBreakpoint;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Native puts the hero and Scan-to-Connect side by side so the
                // whole dashboard fits above the fold; stacking them pushed the
                // access code two swipes down (BladeWatch-ya6f).
                // With the tunnel switched off there is no connect card, so the hero
                // takes the full width rather than leaving a gap where it used to be.
                if (connect == null)
                  hero
                else if (wide)
                  // Deliberately NOT wrapped in IntrinsicHeight to equalise the
                  // two columns: the Connect card sizes its QR with a
                  // LayoutBuilder, and IntrinsicHeight cannot measure through
                  // one ("LayoutBuilder does not support returning intrinsic
                  // dimensions"). Each column sizes to its own content instead.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: hero),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: connect),
                    ],
                  )
                else ...[
                  hero,
                  const SizedBox(height: 16),
                  connect,
                ],
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
            );
          },
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
    // Native's headline combines count and distance on one line
    // ("3 trips · 21.0 km"). DashboardFragment builds it by hand with English
    // "trip"/"trips" hardcoded; composing it from the localised plural here
    // gives the same result without inheriting that bug.
    final headline = state.loading
        ? l10n.dashboard_trips_loading
        : !state.available
            ? l10n.dashboard_trips_unavailable
            : state.tripCount == 0
                ? l10n.dashboard_trips_no_data
                : '${l10n.dashboard_trips_count(state.tripCount)} · ${state.distanceLabel}';
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
            Text(headline, style: theme.textTheme.headlineMedium?.copyWith(color: onHero)),
            const SizedBox(height: 16),
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
          ],
        ),
      ),
    );
  }
}

/// The vertical rule native draws between the three hero stats.
class _StatDivider extends StatelessWidget {
  final Color color;

  const _StatDivider({required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        margin: const EdgeInsets.symmetric(horizontal: 12),
        color: color.withValues(alpha: 0.3),
      );
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
  final VoidCallback onTunnelTap;
  final VoidCallback onDaemonsTap;
  final VoidCallback onVehicleTap;
  final VoidCallback onLiveTap;

  const _MetricRow({
    required this.controller,
    required this.l10n,
    required this.theme,
    required this.onRecordingsTap,
    required this.onTunnelTap,
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

    final tunnelValue =
        controller.tunnel.phase == TunnelPhase.online ? l10n.dashboard_tunnel_online : l10n.dashboard_tunnel_offline;

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
        value: tunnelValue,
        theme: theme,
        onTap: onTunnelTap,
        // Native's remote-access card is the only one with a status dot.
        showStatusDot: controller.tunnel.phase == TunnelPhase.online,
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
          children: [
            for (final tile in tiles)
              SizedBox(width: (constraints.maxWidth - 12) / 2, child: tile),
          ],
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

/// Connect card: QR / placeholder, device id, and the access-code section —
/// ground truth: `rebuildTunnelChips()`/`renderQr()`/`showPlaceholder()` +
/// `loadAuthState()`/`toggleTokenVisibility()`/`copyTokenToClipboard()`/
/// `showRegenerateConfirmation()`/`showSetPasswordDialog()`. Only one tunnel has
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
    // tor is up but not yet reachable — up to ~82 s on a cold start, ~6 s warm. Its own
    // state, because both alternatives are wrong: "no tunnel" is a lie while one is
    // starting, and a QR code here points at a service nothing can reach yet.
    final connecting = !online && tunnel.phase == TunnelPhase.connecting;

    return Card(
      color: theme.colorScheme.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.dashboard_scan_to_connect,
                    style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface),
                  ),
                ),
                // Always present, including with no tunnel: this is MORE useful before
                // one is up, because that is when someone is still working out what to
                // install. A .onion address does not open in Chrome or Safari — they
                // fail with an unhelpful DNS error — so without this a user scans the
                // QR, hits that error and concludes the app is broken.
                IconButton(
                  key: const ValueKey('connect.torHelp'),
                  icon: const Icon(Icons.info_outline),
                  tooltip: l10n.dashboard_tor_help_tooltip,
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => _TorHelpDialog(l10n: l10n, theme: theme),
                  ),
                ),
              ],
            ),
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
                        // A v3 onion URL is 62 characters, half again as long as the
                        // tunnel URL this replaced. Centre it and let it wrap rather
                        // than overflowing the card on the head unit's panel.
                        Text(
                          tunnel.url!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (connecting) ...[
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text(
                            connecting ? l10n.dashboard_tor_bootstrapping : l10n.dashboard_no_tunnel,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
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
              tooltip: l10n.cd_show_hide_token,
              icon: Icon(state.visible ? Icons.visibility_off : Icons.visibility),
              onPressed: controller.toggleAccessCodeVisibility,
            ),
            IconButton(
              key: const ValueKey('accessCode.copy'),
              tooltip: l10n.cd_copy_token,
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
        // BladeWatch-y7x2: Regenerate Token was removed from this card at the owner's
        // request. It rotated the access code, invalidating every paired client — a
        // destructive action sitting one mis-tap away from Set Password on a touchscreen
        // in a moving car. Set Password covers the ordinary case of changing the
        // credential. The underlying regenerate capability is untouched in the daemon;
        // only this entry point is gone.
        //
        // BladeWatch-8sig previously argued the ORDER of the two buttons on exactly that
        // mis-tap risk; removing the destructive one settles it.
        Wrap(
          spacing: 8,
          children: [
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

  // _confirmRegenerate() went with the Regenerate Token button (BladeWatch-y7x2). The
  // capability itself is NOT gone — DashboardController.regenerateAccessCode() and the
  // daemon behind it are untouched, and the l10n keys survive — so restoring the entry
  // point is a small change if the owner wants it back somewhere less mis-tappable.

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

/// How to actually open the onion address, per platform.
///
/// The second QR is the reason this is a dialog rather than a line of text: it encodes
/// an ordinary https URL, so it DOES open in any phone camera and stock browser, which
/// gets the user from the car's screen to the Tor Browser download without typing.
/// The connection QR on the card behind it cannot do that.
class _TorHelpDialog extends StatelessWidget {
  /// Only torproject.org, Google Play, F-Droid and the App Store are ever named here —
  /// never a mirror or a third-party re-host.
  static const String downloadUrl = 'https://www.torproject.org/download/';

  final AppLocalizations l10n;
  final ThemeData theme;

  const _TorHelpDialog({required this.l10n, required this.theme});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.info_outline),
      title: Text(l10n.dashboard_tor_help_title),
      // The explicit width is load-bearing, not styling: QrImageView builds a
      // LayoutBuilder, and AlertDialog sizes its content by asking for intrinsic
      // width, which a LayoutBuilder cannot answer. Without a fixed width the dialog
      // throws "LayoutBuilder does not support returning intrinsic dimensions".
      //
      // Scrollable because this is text-heavy and German, Russian and Vietnamese run
      // long — on the head unit's panel the dismiss button must stay reachable.
      content: SizedBox(
        width: 320,
        child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.dashboard_tor_help_android, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Text(l10n.dashboard_tor_help_ios, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Text(l10n.dashboard_tor_help_desktop, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            // BladeWatch-4s7w: this sits ABOVE the QR deliberately.
            //
            // It used to be the last thing in the dialog, and on the head unit's 1080 px
            // panel it fell entirely below the fold — in ENGLISH, the shortest locale,
            // with the QR caption clipped mid-line just above it. Nothing indicated there
            // was more to scroll to. It is the one line that stops a user assuming the
            // onion address alone grants access, so it cannot be the line nobody sees.
            Text(
              l10n.dashboard_tor_help_password_note,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.white,
                    child: QrImageView(
                      key: const ValueKey('connect.torHelp.downloadQr'),
                      data: downloadUrl,
                      // 96 rather than 120: the dialog is height-capped by the panel and
                      // this is the cheapest 24 px to give back. A torproject.org URL is
                      // short, so the QR stays low-density and scannable at this size.
                      size: 96,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.dashboard_tor_help_download_qr_label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('connect.torHelp.close'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.dashboard_tor_help_close),
        ),
      ],
    );
  }
}
