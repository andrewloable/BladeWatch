import 'package:flutter/material.dart';

/// A single-choice option: the HUD chip theme's own look (accent border on the soft accent fill when
/// selected) with NO check mark (BladeWatch-hpcd: every multiple-choice control shows its selected
/// option without one; the check mark is kept for multi-select filters, where it signals inclusion).
///
/// Deliberately ONE widget rather than per-screen styling, and deliberately a thin wrapper over
/// [ChoiceChip] rather than a hand-rolled control: it keeps ChoiceChip's semantics, focus and keyboard
/// behaviour, which a bespoke InkWell would silently drop (a mistake already made and corrected once
/// in this refactor: see the Appearance theme tiles). The styling itself is the app theme's
/// (`BwHud.themeData`), so this widget carries none.
class BwChoiceChip extends StatelessWidget {
  final Widget label;
  final bool selected;

  /// Nullable, exactly as [ChoiceChip.onSelected] is: passing null DISABLES the
  /// option. Two call sites rely on that (a busy surveillance tab and a trips
  /// storage option), and making it required would have silently turned those
  /// disabled chips back on.
  final ValueChanged<bool>? onSelected;

  const BwChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) =>
      ChoiceChip(label: label, selected: selected, onSelected: onSelected, showCheckmark: false);
}
