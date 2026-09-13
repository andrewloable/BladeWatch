import 'package:flutter/material.dart';

import '../../gen/l10n/app_localizations.dart';
import 'live_view_controller.dart';
import 'live_view_models.dart';

/// Ground truth: `LiveViewController.kt` (native) — a full-bleed `Texture`
/// (BladeWatch-yz1e.10's plugin renders decoded frames into it directly, no
/// platform-view compositing) with a connecting/error/unavailable banner and
/// a 5-way direction bar overlaid, matching native's `TextureView` +
/// `banner` + `directionBar` `FrameLayout` stack exactly.
class LiveViewScreen extends StatefulWidget {
  final LiveViewController controller;

  const LiveViewScreen({super.key, required this.controller});

  @override
  State<LiveViewScreen> createState() => _LiveViewScreenState();
}

class _LiveViewScreenState extends State<LiveViewScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
    widget.controller.start();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    widget.controller.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = widget.controller;
    final textureId = c.textureId;

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (textureId != null) Texture(textureId: textureId),
          _Banner(l10n: l10n, status: c.state.status, onRetry: c.retry),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _DirectionBar(l10n: l10n, selected: c.state.direction, onSelect: c.selectDirection),
            ),
          ),
        ],
      ),
    );
  }
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
  // than pulling from BladeWatchTheme.
  static const _barBackground = Color(0xCC101010);
  static const _selectedBackground = Color(0xEDEFEFEF);
  static const _selectedForeground = Color(0xFF151515);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _barBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final direction in LiveViewDirection.values) _button(direction),
          ],
        ),
      ),
    );
  }

  Widget _button(LiveViewDirection direction) {
    final isSelected = direction == selected;
    return TextButton(
      key: ValueKey('liveView.direction.${direction.name}'),
      style: TextButton.styleFrom(
        backgroundColor: isSelected ? _selectedBackground : Colors.transparent,
        foregroundColor: isSelected ? _selectedForeground : Colors.white,
        minimumSize: const Size(60, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: const RoundedRectangleBorder(),
      ),
      onPressed: () => onSelect(direction),
      child: Text(_label(direction), style: const TextStyle(fontSize: 13)),
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
