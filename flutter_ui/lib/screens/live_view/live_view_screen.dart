import 'dart:async';

import 'package:flutter/material.dart';

import '../../gen/l10n/app_localizations.dart';
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
    // One start + one poll, NOT a periodic Timer like LocationScreen's own 1s refresh: this is
    // a preview, not the full map, and a Timer here would make every existing widget test in
    // this file that calls pumpAndSettle() (which never returns while a periodic Timer is
    // pending) hang. The preview still shows a genuinely current fix as of when the screen
    // opened -- the same snapshot LocationScreen itself shows on its own very first frame,
    // before its periodic timer has ever fired.
    unawaited(_startLocationPreview());
  }

  Future<void> _startLocationPreview() async {
    await widget.locationController.start();
    await widget.locationController.poll();
  }

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
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    widget.controller.stop();
    widget.locationController.removeListener(_onLocationChanged);
    unawaited(widget.locationController.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = widget.controller;
    final textureId = c.textureId;

    return Container(
      color: Colors.black,
      child: Row(
        children: [
          Expanded(
            child: Stack(
              key: const ValueKey('liveView.stage'),
              fit: StackFit.expand,
              children: [
                if (textureId != null) Texture(textureId: textureId),
                _Banner(l10n: l10n, status: c.state.status, onRetry: c.retry),
              ],
            ),
          ),
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
    return ColoredBox(
      // Same fixed dark tone the direction bar/mark button already used as an overlay —
      // reused here as the rail's own background rather than introducing a new color.
      color: const Color(0xFF101010),
      child: SafeArea(
        left: false,
        top: false,
        bottom: false,
        child: SizedBox(
          width: 168,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: _LocationPreview(l10n: l10n, state: locationState, onTap: onOpenLocation),
              ),
              const Divider(color: Color(0x33FFFFFF), height: 1, thickness: 1),
              Expanded(
                child: Center(
                  child: _DirectionBar(l10n: l10n, selected: direction, onSelect: onSelectDirection),
                ),
              ),
              if (isRecording)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _MarkButton(marking: markStatus == MarkStatus.marking, onTap: onMark),
                ),
            ],
          ),
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
    final loc = locationOf(state);
    final title = _titleFor(l10n, state);
    return Material(
      color: const Color(0xFF1E1E1E),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        key: const ValueKey('liveView.locationPreview'),
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 12)),
                    if (loc != null)
                      Text(
                        _formatLatLng(loc),
                        style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 10),
                      ),
                  ],
                ),
              ),
            ],
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
    return Center(
      child: Container(
        key: const ValueKey('liveView.banner'),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        // Ground truth: LiveViewController.kt's banner LinearLayout —
        // Color.argb(0xCC, 0, 0, 0), no corner radius.
        color: const Color(0xCC000000),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 16), textAlign: TextAlign.center),
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

  // Ground truth: LiveViewController.kt's buildView()/renderDirectionBar() —
  // plain flat LinearLayouts (no corner radius) with literal ARGB colors,
  // independent of BladeTheme (constructed there but never referenced), so
  // this bar is ported with the same fixed, theme-invariant colors rather
  // than pulling from BladeWatchTheme. BladeWatch-y78o.2 moved it from a
  // horizontal bar overlaid on the video into the vertical utility rail —
  // same colors, a Column instead of a Row.
  static const _selectedBackground = Color(0xEDEFEFEF);
  static const _selectedForeground = Color(0xFF151515);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final direction in LiveViewDirection.values) _button(direction),
      ],
    );
  }

  Widget _button(LiveViewDirection direction) {
    final isSelected = direction == selected;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextButton(
        key: ValueKey('liveView.direction.${direction.name}'),
        style: TextButton.styleFrom(
          backgroundColor: isSelected ? _selectedBackground : Colors.transparent,
          foregroundColor: isSelected ? _selectedForeground : Colors.white,
          minimumSize: const Size(140, 40),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: const RoundedRectangleBorder(),
        ),
        onPressed: () => onSelect(direction),
        child: Text(_label(direction), style: const TextStyle(fontSize: 13)),
      ),
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

/// One-tap bookmark button (BladeWatch-nmao.4) -- no native ground truth, styled to
/// match the banner/direction bar's fixed dark overlay rather than the app theme.
class _MarkButton extends StatelessWidget {
  final bool marking;
  final VoidCallback onTap;

  const _MarkButton({required this.marking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xCC101010),
      shape: const CircleBorder(),
      child: InkWell(
        key: const ValueKey('liveView.mark'),
        customBorder: const CircleBorder(),
        onTap: marking ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: marking
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.bookmark_add_outlined, color: Colors.white),
        ),
      ),
    );
  }
}
