import 'dart:async';

import 'package:flutter/material.dart';

import '../../gen/l10n/app_localizations.dart';
import '../../theme/hud_theme.dart';
import '../../widgets/hud_widgets.dart';
import '../location/location_controller.dart';
import '../location/location_models.dart';
import 'live_view_controller.dart';
import 'live_view_models.dart';

/// Ground truth: `LiveViewController.kt` (native) — a full-bleed `Texture`
/// (BladeWatch-yz1e.10's plugin renders decoded frames into it directly, no
/// platform-view compositing) with a connecting/error/unavailable banner
/// overlaid, matching native's `TextureView` + `banner` `FrameLayout` stack.
///
/// BladeWatch-y78o.2: the direction bar and mark button that used to overlay
/// the video now live in a narrow utility rail alongside it, together with a
/// location preview (tapping it opens the full Location destination — this
/// is deliberately NOT a second embedded map, see [_LocationPreview]'s own
/// doc comment for why). `nav_rail.dart` and the texture plugin are
/// untouched — this is layout only, reusing the SAME [LocationController]
/// instance `main.dart` already owns for the Location destination (only one
/// of the two screens is ever mounted at a time — the shell's stage
/// `Navigator` is keyed by route and tears down the previous screen on every
/// navigation — so both screens independently start/stop/poll it exactly as
/// `LocationScreen` already did, with no lifecycle conflict).
class LiveViewScreen extends StatefulWidget {
  /// How often the location preview asks for a newer fix (BladeWatch-rdtj.62).
  static const locationPollInterval = Duration(seconds: 2);

  final LiveViewController controller;
  final LocationController locationController;
  final VoidCallback onOpenLocation;

  const LiveViewScreen({
    super.key,
    required this.controller,
    required this.locationController,
    required this.onOpenLocation,
  });

  @override
  State<LiveViewScreen> createState() => _LiveViewScreenState();
}

class _LiveViewScreenState extends State<LiveViewScreen> {
  // Tracks the last markMessage already shown as a SnackBar, so the same
  // feedback doesn't re-appear on every unrelated rebuild (e.g. a frame
  // arriving) -- the controller keeps the message in its state rather than
  // firing a one-shot event, so de-duplication lives here instead.
  String? _shownMarkMessage;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.controller.start();
    widget.locationController.addListener(_onLocationChanged);
    unawaited(_startLocationPreview());
  }

  /// Polled every [LiveViewScreen.locationPollInterval] while the screen is up. It used to be one start and ONE
  /// poll: that poll runs right after the updates are requested, before Android has delivered a
  /// first fix, so the chip said "Waiting for GPS fix" for as long as the screen stayed open --
  /// seen on the head unit with a live 34-satellite fix (BladeWatch-rdtj.62). A periodic timer
  /// does not hang pumpAndSettle(): only a frame on every tick would, and [_onLocationChanged]
  /// repaints only when the state really changes.
  Future<void> _startLocationPreview() async {
    await widget.locationController.start();
    await widget.locationController.poll();
    if (!mounted) return;
    _locationTimer = Timer.periodic(
      LiveViewScreen.locationPollInterval,
      (_) => unawaited(widget.locationController.poll()),
    );
  }

  Timer? _locationTimer;
  LocationUiState? _shownLocationState;

  void _onChanged() {
    if (!mounted) return;
    final message = widget.controller.state.markMessage;
    if (message != null && message != _shownMarkMessage) {
      _shownMarkMessage = message;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
    setState(() {});
  }

  void _onLocationChanged() {
    if (!mounted) return;
    final state = widget.locationController.effectiveState;
    if (state == _shownLocationState) return; // a poll that found nothing new
    _shownLocationState = state;
    setState(() {});
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    widget.controller.removeListener(_onChanged);
    widget.controller.stop();
    widget.locationController.removeListener(_onLocationChanged);
    unawaited(widget.locationController.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hud = BwHud.of(context);
    final c = widget.controller;
    final textureId = c.textureId;
    final live = c.state.status.phase == LiveStreamPhase.live;

    return ColoredBox(
      color: hud.pageBackground,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            HudTitleBar(
              title: l10n.rail_live.toUpperCase(),
              // A magenta LIVE only while the stream really is live (rule 5): never a decorative indicator.
              trailing: live
                  ? Row(
                      key: const ValueKey('liveView.liveBadge'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const HudStatusDot(HudDotState.bad, pulse: true),
                        const SizedBox(width: 8),
                        Text(
                          l10n.dashboard_action_live.toUpperCase(),
                          style: hudText(12, hud.magenta, lineHeight: 16, weight: FontWeight.w700, em: 0.1),
                        ),
                      ],
                    )
                  : null,
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    // The video sits in a bordered frame; the video surface itself is untouched. Black is the
                    // letterbox of the picture, not a HUD colour.
                    child: HudPanel(
                      color: Colors.black,
                      borderColor: hud.panelBorder,
                      radius: BwHud.radiusSmall,
                      shadows: hud.tileShadow,
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        key: const ValueKey('liveView.stage'),
                        fit: StackFit.expand,
                        children: [
                          if (textureId != null) Texture(textureId: textureId),
                          _Banner(l10n: l10n, status: c.state.status, onRetry: c.retry),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _UtilityRail(
                    key: const ValueKey('liveView.utilityRail'),
                    l10n: l10n,
                    direction: c.state.direction,
                    onSelectDirection: c.selectDirection,
                    isRecording: c.state.isRecording,
                    markStatus: c.state.markStatus,
                    onMark: c.markRecording,
                    locationState: widget.locationController.effectiveState,
                    onOpenLocation: widget.onOpenLocation,
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

/// Ground truth: `LiveViewController.kt`'s own `banner`+`directionBar` `FrameLayout` stack —
/// no native ground truth for the rail as a whole (BladeWatch-y78o.2 is a Flutter-only
/// reimplementation of an idea, per the issue's own framing: Overdrive's 89 Activity/Fragment
/// files do not port).
class _UtilityRail extends StatelessWidget {
  final AppLocalizations l10n;
  final LiveViewDirection direction;
  final ValueChanged<LiveViewDirection> onSelectDirection;
  final bool isRecording;
  final MarkStatus markStatus;
  final VoidCallback onMark;
  final LocationUiState locationState;
  final VoidCallback onOpenLocation;

  const _UtilityRail({
    super.key,
    required this.l10n,
    required this.direction,
    required this.onSelectDirection,
    required this.isRecording,
    required this.markStatus,
    required this.onMark,
    required this.locationState,
    required this.onOpenLocation,
  });

  @override
  Widget build(BuildContext context) {
    final hud = BwHud.of(context);
    return SizedBox(
      width: 168,
      child: HudPanel(
        color: hud.panel,
        borderColor: hud.panelBorder,
        radius: BwHud.radiusSmall,
        shadows: hud.tileShadow,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _LocationPreview(l10n: l10n, state: locationState, onTap: onOpenLocation),
            const SizedBox(height: 12),
            Container(height: 1, color: hud.cardDivider),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: _DirectionBar(l10n: l10n, selected: direction, onSelect: onSelectDirection),
                ),
              ),
            ),
            if (isRecording) ...[
              const SizedBox(height: 12),
              _MarkButton(marking: markStatus == MarkStatus.marking, onTap: onMark),
            ],
          ],
        ),
      ),
    );
  }
}

/// A preview, not a second map (the issue's own explicit instruction): no `flutter_map`
/// instance here, no tiles, no marker — just the same short status text
/// [LocationScreen]'s banner already shows for the controller's current state, reusing its
/// exact ARB keys rather than adding new ones. Tapping it is the only way to reach the real
/// map, via [LiveViewScreen.onOpenLocation].
class _LocationPreview extends StatelessWidget {
  final AppLocalizations l10n;
  final LocationUiState state;
  final VoidCallback onTap;

  const _LocationPreview({required this.l10n, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hud = BwHud.of(context);
    final loc = locationOf(state);
    final title = _titleFor(l10n, state);
    return HudPanel(
      color: hud.panel,
      borderColor: hud.chipBorder,
      radius: BwHud.radiusSmall,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const ValueKey('liveView.locationPreview'),
          borderRadius: BorderRadius.circular(BwHud.radiusSmall),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined, color: hud.iconAccent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title, style: hudText(12, hud.textPrimary, lineHeight: 16, weight: FontWeight.w700)),
                      if (loc != null)
                        Text(
                          _formatLatLng(loc),
                          style: hudText(10, hud.tileLabel, lineHeight: 15, weight: hud.labelWeight),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _titleFor(AppLocalizations l10n, LocationUiState state) => switch (state) {
    LocationLoading() => l10n.location_loading_title,
    LocationPermissionMissing() => l10n.location_permission_missing_title,
    LocationPermissionDenied() => l10n.location_permission_denied_title,
    LocationProviderDisabled() => l10n.location_provider_disabled_title,
    LocationWaitingForFix() => l10n.location_waiting_for_fix_title,
    LocationFresh() => l10n.location_car_location_title,
    LocationStale() => l10n.location_stale_title,
    LocationTileFailure() => l10n.location_tile_failure_title,
    LocationError() => l10n.location_error_title,
  };

  static String _formatLatLng(LocationCarGps location) =>
      '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
}

class _Banner extends StatelessWidget {
  final AppLocalizations l10n;
  final LiveStreamStatus status;
  final VoidCallback onRetry;

  const _Banner({required this.l10n, required this.status, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final (text, showRetry) = switch (status.phase) {
      LiveStreamPhase.idle => (null, false),
      LiveStreamPhase.connecting => (l10n.live_connecting, false),
      LiveStreamPhase.live => (null, false),
      LiveStreamPhase.error => (l10n.live_error_fmt(status.reason ?? ''), true),
      LiveStreamPhase.unavailable => (l10n.live_camera_unavailable_fmt(status.reason ?? ''), true),
    };
    if (text == null) return const SizedBox.shrink();
    final hud = BwHud.of(context);
    return Center(
      child: HudPanel(
        key: const ValueKey('liveView.banner'),
        // Ground truth was a translucent black box (LiveViewController.kt's banner LinearLayout): the HUD
        // keeps the translucency, now a bordered panel over the picture.
        color: hud.pageBackground.withValues(alpha: 0.8),
        borderColor: hud.cardBorder,
        radius: BwHud.radiusSmall,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: hudText(
                14,
                status.phase == LiveStreamPhase.connecting ? hud.accent : hud.magenta,
                lineHeight: 20,
                weight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            if (showRetry) ...[
              const SizedBox(height: 16),
              FilledButton(key: const ValueKey('liveView.retry'), onPressed: onRetry, child: Text(l10n.live_retry)),
            ],
          ],
        ),
      ),
    );
  }
}

class _DirectionBar extends StatelessWidget {
  final AppLocalizations l10n;
  final LiveViewDirection selected;
  final ValueChanged<LiveViewDirection> onSelect;

  const _DirectionBar({required this.l10n, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final direction in LiveViewDirection.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            // A row per camera; the chosen one is the accent border on the soft fill (rule 3), the same as a
            // selected HudListRow.
            child: HudListRow(
              key: ValueKey('liveView.direction.${direction.name}'),
              title: _label(direction),
              selected: direction == selected,
              onTap: () => onSelect(direction),
            ),
          ),
      ],
    );
  }

  String _label(LiveViewDirection direction) => switch (direction) {
    LiveViewDirection.mosaic => l10n.live_direction_all,
    LiveViewDirection.front => l10n.live_direction_front,
    LiveViewDirection.right => l10n.live_direction_right,
    LiveViewDirection.rear => l10n.live_direction_rear,
    LiveViewDirection.left => l10n.live_direction_left,
  };
}

/// One-tap bookmark button (BladeWatch-nmao.4): a 4 dp HUD box with the accent icon, a spinner while marking.
class _MarkButton extends StatelessWidget {
  final bool marking;
  final VoidCallback onTap;

  const _MarkButton({required this.marking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hud = BwHud.of(context);
    return HudPanel(
      color: Color.alphaBlend(hud.viewAllFill, hud.panel),
      borderColor: hud.accent,
      radius: BwHud.radiusSmall,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: const ValueKey('liveView.mark'),
          borderRadius: BorderRadius.circular(BwHud.radiusSmall),
          onTap: marking ? null : onTap,
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: Center(
              child: marking
                  ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: hud.accent))
                  : Icon(Icons.bookmark_add_outlined, color: hud.accent),
            ),
          ),
        ),
      ),
    );
  }
}
