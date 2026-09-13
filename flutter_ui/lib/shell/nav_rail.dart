import 'package:flutter/material.dart';

import '../gen/l10n/app_localizations.dart';
import 'rail_destination.dart';

/// The custom 9-item navigation rail — ported from
/// `app/src/main/res/layout/activity_main_new.xml`'s `navigationRail` +
/// `app/src/main/res/layout/item_rail_destination.xml`. Not
/// `NavigationRail`/`NavigationRailView`: the native comment on that layout
/// notes Material's `NavigationRailView` caps collapsed items at 7, which is
/// exactly why the native side rolled its own — mirroring that decision
/// here keeps both sides on the same, unconstrained implementation.
class NavRail extends StatelessWidget {
  final String selectedRoute;
  final ValueChanged<String> onSelect;

  /// Landscape shows a language-picker button at the top of the rail
  /// (`layout-land/rail_header.xml`); portrait shows it in the toolbar
  /// end-cluster instead (`toolbarLanguageButton`) and this is false. See
  /// `MainActivity.kt`'s `languageClick` wiring, which binds whichever of
  /// the two buttons is present in the current layout.
  final bool showLanguageHeader;
  final VoidCallback? onLanguageTap;

  /// Landscape (`layout-land/activity_main_new.xml`) uses a 4dp divider
  /// margin and 12dp rail bottom padding; portrait uses 6dp and 16dp. Kept
  /// as one flag since both differ only by the same `-land` qualifier on the
  /// native side.
  final bool compact;

  const NavRail({
    super.key,
    required this.selectedRoute,
    required this.onSelect,
    this.showLanguageHeader = false,
    this.onLanguageTap,
    this.compact = false,
  }) : assert(!showLanguageHeader || onLanguageTap != null);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      width: 80,
      color: theme.colorScheme.surfaceContainerLow,
      child: SingleChildScrollView(
        child: Column(
          key: const ValueKey('navRailColumn'),
          children: [
            if (showLanguageHeader)
              _LanguageHeader(onTap: onLanguageTap!)
            else
              const SizedBox.shrink(),
            for (var i = 0; i < railDestinations.length; i++) ...[
              if (i == aboutRailIndex)
                Container(
                  key: const ValueKey('navRailDivider'),
                  width: 40,
                  height: 1,
                  margin: EdgeInsets.symmetric(vertical: compact ? 4 : 6),
                  color: theme.colorScheme.outlineVariant,
                ),
              NavRailItem(
                key: ValueKey('navRailItem_$i'),
                icon: railDestinations[i].icon,
                label: railDestinations[i].label(l10n),
                selected: railDestinations[i].routeName == selectedRoute,
                onTap: () => onSelect(railDestinations[i].routeName),
              ),
            ],
            SizedBox(height: compact ? 12 : 16),
          ],
        ),
      ),
    );
  }
}

/// One rail row: 56x32dp active-indicator pill (`rail_item_indicator.xml`)
/// behind a 24dp icon, LabelMedium text below
/// (`item_rail_destination.xml`).
class NavRailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const NavRailItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final iconColor = selected ? colors.onSecondaryContainer : colors.onSurfaceVariant;
    final labelColor = selected ? colors.onSurface : colors.onSurfaceVariant;

    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 32,
                decoration: BoxDecoration(
                  color: selected ? colors.secondaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 24, color: iconColor),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(color: labelColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageHeader extends StatelessWidget {
  final VoidCallback onTap;

  const _LanguageHeader({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: IconButton(
        icon: const Icon(Icons.language),
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        onPressed: onTap,
      ),
    );
  }
}
