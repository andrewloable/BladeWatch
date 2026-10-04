import 'package:flutter/material.dart';

import 'hud_theme.dart';

/// A bordered HUD surface: the summary card, status tiles, chips. Colours come from [BwHud]
/// through the arguments the caller picks, never from literals.
class HudPanel extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Gradient? gradient;
  final Color borderColor;
  final double radius;
  final List<BoxShadow> shadows;
  final EdgeInsetsGeometry padding;

  /// Paints (and clips) [child] to the rounded shape; needed when the child paints outside it,
  /// like the summary card's corner glows.
  final Clip clipBehavior;

  const HudPanel({
    super.key,
    required this.child,
    required this.borderColor,
    this.color,
    this.gradient,
    this.radius = BwHud.radiusSmall,
    this.shadows = const [],
    this.padding = EdgeInsets.zero,
    this.clipBehavior = Clip.none,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    clipBehavior: clipBehavior,
    decoration: BoxDecoration(
      color: gradient == null ? color : null,
      gradient: gradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: borderColor),
      boxShadow: shadows,
    ),
    child: child,
  );
}

/// Tailwind's `animate-pulse`: opacity 1, 0.5, 1 over 2 s, eased, forever.
///
/// Stands still when the platform asks for no animations. That is also what keeps a widget test's
/// `pumpAndSettle` from spinning until it times out: a test that pumps this sets
/// `MediaQuery(disableAnimations: true)`.
class HudPulse extends StatefulWidget {
  final Widget child;

  const HudPulse({super.key, required this.child});

  @override
  State<HudPulse> createState() => _HudPulseState();
}

class _HudPulseState extends State<HudPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
  static const _ease = Cubic(0.4, 0, 0.6, 1);
  late final Animation<double> _opacity = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.5).chain(CurveTween(curve: _ease)), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.0).chain(CurveTween(curve: _ease)), weight: 1),
  ]).animate(_controller);

  bool _still = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_still) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _still ? widget.child : FadeTransition(opacity: _opacity, child: widget.child);
}

// ── The kit (BladeWatch-oxcx): what the Dashboard built by hand, made reusable ──────────────────────

/// One HUD text style; see [BwHud.text].
TextStyle hudText(
  double size,
  Color color, {
  required double lineHeight,
  FontWeight weight = FontWeight.w400,
  double em = 0,
  List<Shadow>? shadows,
}) => BwHud.text(size, lineHeight: lineHeight, color: color, weight: weight, em: em, shadows: shadows);

/// A glow as a text-shadow list, or null when the mode has none (light).
List<Shadow>? hudGlow(Shadow? shadow) => BwHud.hudGlowList(shadow);

/// The HUD `ThemeData` for the ambient brightness, applied to [child]. A dialog or sheet runs on the ROOT
/// navigator, outside any theme a screen wrapped itself in, so it must opt in explicitly (see
/// [showHudDialog] and [showHudSheet]); a screen that is on the HUD skin is wrapped by the shell.
class HudScope extends StatelessWidget {
  final Widget child;

  const HudScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Theme(data: BwHud.themeData(Theme.of(context).brightness), child: child);
}

/// `showDialog` on the HUD skin.
Future<T?> showHudDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) => showDialog<T>(
  context: context,
  barrierDismissible: barrierDismissible,
  useRootNavigator: useRootNavigator,
  builder: (_) => HudScope(child: Builder(builder: builder)),
);

/// `showModalBottomSheet` on the HUD skin. The sheet's own chrome (fill, shape, border) belongs to the modal
/// route, which is built from the ROOT theme, so wrapping the [builder] in [HudScope] is not enough: the HUD
/// sheet theme is passed to the route explicitly.
Future<T?> showHudSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useRootNavigator = true,
}) {
  final sheet = BwHud.themeData(Theme.of(context).brightness).bottomSheetTheme;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    backgroundColor: sheet.modalBackgroundColor,
    shape: sheet.shape,
    clipBehavior: sheet.clipBehavior,
    elevation: sheet.elevation,
    builder: (_) => HudScope(child: Builder(builder: builder)),
  );
}

/// The page title: a pulsing 8 dp magenta square, [title] (already upper-cased by the caller, as the Dashboard
/// composes `DASHBOARD // OVERVIEW`) at 20 dp bold in the accent (with the glow in dark), an optional
/// [trailing] status, an optional back button for a pushed sub-screen, and the rule under it. It replaces the
/// M3 toolbar on a HUD route.
class HudTitleBar extends StatelessWidget {
  final String title;
  final Key? titleKey;
  final Widget? trailing;

  /// Shows a back arrow (a pushed sub-screen: recording player, trip detail, the ADB console).
  final VoidCallback? onBack;
  final String? backTooltip;

  const HudTitleBar({super.key, required this.title, this.titleKey, this.trailing, this.onBack, this.backTooltip});

  @override
  Widget build(BuildContext context) {
    final hud = BwHud.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: hud.titleRule)),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            IconButton(
              key: const ValueKey('hud.back'),
              tooltip: backTooltip,
              icon: const Icon(Icons.arrow_back, size: 20),
              color: hud.accent,
              visualDensity: VisualDensity.compact,
              onPressed: onBack,
            ),
            const SizedBox(width: 4),
          ],
          HudPulse(child: Container(width: 8, height: 8, color: hud.magenta)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              key: titleKey,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: hudText(
                20,
                hud.accent,
                lineHeight: 28,
                weight: FontWeight.w700,
                em: 0.05,
                shadows: hudGlow(hud.glowCyan),
              ),
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

/// A card or section label: 12 dp bold uppercase, tracking 0.1em, in the accent, with an optional magenta icon
/// before it and an optional [trailing] widget (a "view all" button).
class HudSectionLabel extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Widget? trailing;

  const HudSectionLabel(this.label, {super.key, this.icon, this.trailing});

  @override
  Widget build(BuildContext context) {
    final hud = BwHud.of(context);
    return Row(
      children: [
        if (icon != null) ...[Icon(icon, size: 14, color: hud.magenta), const SizedBox(width: 8)],
        Expanded(
          child: Text(
            label.toUpperCase(),
            style: hudText(12, hud.accent, lineHeight: 16, weight: FontWeight.w700, em: 0.1),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// A status chip: a 4 dp box, 12 dp bold upper-case. Not a button, as the M3 `Chip`s it replaces were not.
/// [live] is the recording chip while it records: brighter border and text, and a pulsing dot.
class HudChip extends StatelessWidget {
  final String label;
  final bool live;
  final Key? dotKey;

  const HudChip({super.key, required this.label, this.live = false, this.dotKey});

  @override
  Widget build(BuildContext context) {
    final hud = BwHud.of(context);
    return HudPanel(
      color: hud.panel,
      borderColor: live ? hud.panelBorderStrong : hud.chipBorder,
      radius: BwHud.radiusSmall,
      shadows: hud.tileShadow,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (live) ...[
            HudPulse(
              child: Container(
                key: dotKey,
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: hud.dot, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            label.toUpperCase(),
            style: hudText(
              12,
              live ? hud.accentBright : hud.textSecondary,
              lineHeight: 16,
              weight: FontWeight.w700,
              em: 0.05,
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable row: icon or [leading], [title] over [subtitle], [trailing]. A 4 dp `panel` box; [selected] is the
/// accent border on the soft accent fill. At least 48 dp tall, so it is a touch target.
class HudListRow extends StatelessWidget {
  final IconData? icon;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;

  const HudListRow({
    super.key,
    this.icon,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final hud = BwHud.of(context);
    final lead = leading ?? (icon == null ? null : Icon(icon, size: 18, color: hud.iconAccent));
    return HudPanel(
      color: selected ? Color.alphaBlend(hud.viewAllFill, hud.panel) : hud.panel,
      borderColor: selected ? hud.accent : hud.panelBorder,
      radius: BwHud.radiusSmall,
      shadows: hud.tileShadow,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(BwHud.radiusSmall),
          splashColor: hud.panelPressed,
          highlightColor: hud.panelPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  if (lead != null) ...[lead, const SizedBox(width: 12)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: hudText(
                            14,
                            selected ? hud.accent : hud.textPrimary,
                            lineHeight: 20,
                            weight: FontWeight.w700,
                          ),
                        ),
                        if (subtitle != null) Text(subtitle!, style: hudText(12, hud.textSecondary, lineHeight: 16)),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[const SizedBox(width: 12), trailing!],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What a [HudStatusDot] says. Four different states, never collapsed: the Services screen must tell "running"
/// from "stopped" from "cannot tell".
enum HudDotState { ok, warning, bad, idle }

/// A dot that is real state (rule 5: a dot that claims something must be true). [pulse] is for live things only.
class HudStatusDot extends StatelessWidget {
  final HudDotState state;
  final bool pulse;
  final double size;

  const HudStatusDot(this.state, {super.key, this.pulse = false, this.size = 8});

  @override
  Widget build(BuildContext context) {
    final hud = BwHud.of(context);
    final (color, glow) = switch (state) {
      HudDotState.ok => (hud.dot, hud.dotGlow),
      HudDotState.warning => (hud.warning, hud.warning),
      HudDotState.bad => (hud.magenta, hud.magenta),
      HudDotState.idle => (hud.textSecondary.withValues(alpha: 0.5), null),
    };
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [if (glow != null) BoxShadow(color: glow, blurRadius: size * 0.75)],
      ),
    );
    return pulse ? HudPulse(child: dot) : dot;
  }
}

/// Nothing to show: an icon over an upper-case message.
class HudEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const HudEmptyState({super.key, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final hud = BwHud.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: hud.textSecondary),
            const SizedBox(height: 12),
            Text(
              message.toUpperCase(),
              textAlign: TextAlign.center,
              style: hudText(12, hud.tileLabel, lineHeight: 16, weight: hud.labelWeight, em: 0.05),
            ),
          ],
        ),
      ),
    );
  }
}

/// Something failed: a magenta icon, the message, and an optional retry.
class HudErrorState extends StatelessWidget {
  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  const HudErrorState({super.key, required this.message, this.retryLabel, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final hud = BwHud.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 32, color: hud.magenta),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: hudText(12, hud.magenta, lineHeight: 16, weight: FontWeight.w700, em: 0.05),
            ),
            if (onRetry != null && retryLabel != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: Text(retryLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading: an accent spinner and an optional upper-case label.
class HudLoading extends StatelessWidget {
  final String? label;

  const HudLoading({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    final hud = BwHud.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            // Under "remove animations" the spinner is a still arc, not an endless loop (which would also keep a
            // widget test's pumpAndSettle from ever settling).
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: hud.accent,
              value: (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ? 0.3 : null,
            ),
          ),
          if (label != null) ...[
            const SizedBox(height: 12),
            Text(
              label!.toUpperCase(),
              style: hudText(12, hud.tileLabel, lineHeight: 16, weight: hud.labelWeight, em: 0.05),
            ),
          ],
        ],
      ),
    );
  }
}

/// A nav label's text scale before any fitting: the system's, capped at 1.3x. Chrome, not content:
/// a phone's largest text size would make one item's label twice its neighbours'.
TextScaler navLabelBaseScaler(BuildContext context) => MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.3);

/// The style of a [HudNavItem] label; [selected] is bold and tracked tighter.
TextStyle navLabelStyle({required Color color, required bool selected, bool horizontal = false}) => TextStyle(
      fontFamily: BwHud.fontFamily,
      fontSize: horizontal ? 12 : 10,
      height: 1.2,
      color: color,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
      // Tailwind tracking-tighter on the active label.
      letterSpacing: horizontal ? 0.5 : (selected ? -0.5 : 0),
    );

/// A navigation item, the in-car rail's look: a 4 dp box, inactive bare (18 dp icon, slate label), active with the
/// top-to-bottom gradient, a 1 dp accent border, a 20 dp icon, a bold label and (in dark) the glow. [label] is
/// upper-cased here and scaled down (never cut or wrapped) if it is too long for the item.
///
/// Vertical by default: a 10 dp label under the icon, 64 dp tall ([dense]: 52, for the head unit's landscape rail).
/// [horizontal] is the wide layout's side panel: the icon beside a 12 dp label, 48 dp tall. A [badge] above zero
/// puts a count on the icon.
class HudNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool dense;
  final bool horizontal;
  final int badge;

  const HudNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.dense = false,
    this.horizontal = false,
    this.badge = 0,
    this.labelScaler,
  });

  /// The label's text scale when a bar sizes every item's label alike (the companion's bottom bar:
  /// one long label shrank on its own beside full-size neighbours, 2026-10-04). Null keeps the
  /// system's, clamped, with this label alone scaled down to fit.
  final TextScaler? labelScaler;

  @override
  Widget build(BuildContext context) {
    final hud = BwHud.of(context);
    final iconColor = selected ? hud.navActiveIcon : hud.navInactive;
    final labelColor = selected ? hud.navActiveLabel : hud.navInactive;
    const radius = BorderRadius.all(Radius.circular(BwHud.radiusSmall));

    Widget iconWidget = Icon(
      icon,
      size: selected ? 20 : 18,
      color: iconColor,
      shadows: selected && hud.glowCyan != null ? [hud.glowCyan!] : null,
    );
    if (badge > 0) iconWidget = Badge(label: Text('$badge', textScaler: TextScaler.noScaling), child: iconWidget);

    final text = Text(
      label.toUpperCase(),
      maxLines: 1,
      textScaler: labelScaler ?? navLabelBaseScaler(context),
      style: navLabelStyle(color: labelColor, selected: selected, horizontal: horizontal),
    );

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          height: horizontal ? 48 : (dense ? 52 : 64),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: selected ? hud.navActiveBorder : Colors.transparent),
            gradient: selected
                ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: hud.navActiveGradient)
                : null,
            boxShadow: selected ? hud.navActiveShadow : const [],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              splashColor: hud.panelPressed,
              highlightColor: hud.panelPressed,
              child: horizontal
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          iconWidget,
                          const SizedBox(width: 12),
                          Expanded(
                            child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: text),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        iconWidget,
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: FittedBox(fit: BoxFit.scaleDown, child: text),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
