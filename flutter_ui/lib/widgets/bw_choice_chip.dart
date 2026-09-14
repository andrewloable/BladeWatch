import 'package:flutter/material.dart';

/// A single-choice option, styled the way the native UI styles them: a FILLED
/// pill in the primary colour when selected, with no check mark.
///
/// Why this exists (BladeWatch-hpcd): every multiple-choice control in the port
/// rendered its selected option as Material 3's default tonal chip WITH a check
/// mark, while native uses a filled pill without one. Both are valid M3; the
/// difference was never a decision, and it was the single most repeated visual
/// gap between the two UIs — the Trips day filter and bottom tabs, Trip
/// Storage's distance unit and storage location, the Vehicle Climate/Windows
/// tabs, the Surveillance tabs, the recording-quality options and the vehicle
/// model picker. Since BladeWatch-81g9 deletes the native UI on the strength of
/// a 1:1 parity sign-off, it was resolved in native's favour.
///
/// Deliberately ONE widget rather than per-screen styling, and deliberately a
/// thin wrapper over [ChoiceChip] rather than a hand-rolled control: it keeps
/// ChoiceChip's semantics, focus and keyboard behaviour, which a bespoke
/// InkWell would silently drop (a mistake already made and corrected once in
/// this refactor — see the Appearance theme tiles).
///
/// This does NOT apply to multi-select filters ([FilterChip], e.g. the
/// Normal/Proximity type row): there the check mark is meaningful, because it
/// signals inclusion rather than a single active choice. The styling is scoped
/// to this widget instead of the global `chipTheme` for exactly that reason.
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: label,
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      selectedColor: scheme.primary,
      labelStyle: TextStyle(color: selected ? scheme.onPrimary : scheme.onSurface),
      side: selected ? BorderSide.none : BorderSide(color: scheme.outlineVariant),
    );
  }
}
