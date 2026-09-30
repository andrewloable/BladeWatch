import 'package:flutter/material.dart';

import '../gen/l10n/app_localizations.dart';
import '../theme/hud_theme.dart';
import '../widgets/hud_widgets.dart';
import 'rail_destination.dart';

/// The custom 9-item navigation rail, in the HUD skin (`docs/ui-ux-design-language.md`, "HUD
/// skin"; reference: the `<nav>` in `docs/design/hud-reference/dashboard-*.html`). Not
/// `NavigationRail`/`NavigationRailView`: Material's caps collapsed items at 7, which is exactly
/// why the native side rolled its own — mirroring that decision here keeps both sides on the same,
/// unconstrained implementation.
class NavRail extends StatelessWidget {
  final String selectedRoute;
  final ValueChanged<String> onSelect;

  /// Shows a language-picker button at the top of the rail. The landscape rail always has it;
  /// portrait shows it in the toolbar end-cluster instead (and here only on a screen that has no
  /// toolbar, so the picker never becomes unreachable).
  final bool showLanguageHeader;
  final VoidCallback? onLanguageTap;

  /// Landscape on the head unit: the globe plus nine items must fit ~604 logical px between the
  /// car's own bars. Portrait has room for the roomier spacing.
  final bool compact;

  /// The rail sits on the right (right-hand-drive setting), so its edge line is on the left.
  final bool onRight;

  const NavRail({
    super.key,
    required this.selectedRoute,
    required this.onSelect,
    this.showLanguageHeader = false,
    this.onLanguageTap,
    this.compact = false,
    this.onRight = false,
  }) : assert(!showLanguageHeader || onLanguageTap != null);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hud = BwHud.of(context);
    final edge = BorderSide(color: hud.railBorder);

    return Container(
      width: 80,
      // The full height, whatever the items need: once they fitted the landscape screen
      // (BladeWatch-5l5o), a rail sized to its content floated with bare strips above and below.
      height: double.infinity,
      decoration: BoxDecoration(
        color: hud.railBackground,
        border: onRight ? Border(left: edge) : Border(right: edge),
        boxShadow: hud.railShadow,
      ),
      child: SingleChildScrollView(
        child: Column(
          key: const ValueKey('navRailColumn'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showLanguageHeader)
              _LanguageHeader(onTap: onLanguageTap!, dense: compact)
            else
              SizedBox(height: compact ? 8 : 16),
            for (var i = 0; i < railDestinations.length; i++) ...[
              if (i > 0) SizedBox(height: compact ? 6 : 12),
              NavRailItem(
                key: ValueKey('navRailItem_$i'),
                icon: railDestinations[i].icon,
                label: railDestinations[i].label(l10n),
                selected: railDestinations[i].routeName == selectedRoute,
                onTap: () => onSelect(railDestinations[i].routeName),
                dense: compact,
              ),
            ],
            SizedBox(height: compact ? 8 : 16),
          ],
        ),
      ),
    );
  }
}

/// One rail row: a 4 dp-radius box holding a 10 dp uppercase label under an icon. Inactive is bare;
/// active gets the gradient fill, the accent border and (in dark) the glow.
class NavRailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Landscape on the head unit: 52 dp tall (the reference's 64 does not fit nine items in 604 dp),
  /// still over the 48 dp touch target.
  final bool dense;

  const NavRailItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) =>
      HudNavItem(icon: icon, label: label, selected: selected, onTap: onTap, dense: dense);
}

class _LanguageHeader extends StatelessWidget {
  final VoidCallback onTap;
  final bool dense;

  const _LanguageHeader({required this.onTap, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: dense ? 4 : 8, bottom: dense ? 2 : 4),
      child: IconButton(
        visualDensity: dense ? VisualDensity.compact : null,
        tooltip: AppLocalizations.of(context)!.language_picker_title,
        // Not Icons.language: the Dashboard's own rail icon is the globe, and two globes read as one.
        icon: const Icon(Icons.translate),
        color: BwHud.of(context).navInactive,
        onPressed: onTap,
      ),
    );
  }
}
