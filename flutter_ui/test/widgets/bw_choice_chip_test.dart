/// Pins the decision recorded in BladeWatch-hpcd: single-choice options render
/// as native's FILLED pill, with no check mark. Both this and Material 3's
/// default tonal-chip-with-check-mark are valid M3, so without a test the
/// styling would drift back the first time someone reached for a plain
/// ChoiceChip.
library;

import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:bladewatch_ui/widgets/bw_choice_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        theme: BladeWatchTheme.light(),
        home: Scaffold(body: Center(child: child)),
      );

  ChoiceChip innerChip(WidgetTester tester) => tester.widget<ChoiceChip>(find.byType(ChoiceChip));

  testWidgets('a selected option is a filled primary pill with no check mark', (tester) async {
    await tester.pumpWidget(wrap(
      BwChoiceChip(label: const Text('7 Days'), selected: true, onSelected: (_) {}),
    ));

    final chip = innerChip(tester);
    expect(chip.showCheckmark, isFalse);
    expect(chip.selectedColor, BladeWatchTheme.light().colorScheme.primary);
    expect(chip.selected, isTrue);
  });

  testWidgets('an unselected option is outlined, not filled', (tester) async {
    await tester.pumpWidget(wrap(
      BwChoiceChip(label: const Text('14 Days'), selected: false, onSelected: (_) {}),
    ));

    expect(innerChip(tester).side, isA<BorderSide>());
    expect(innerChip(tester).selected, isFalse);
  });

  testWidgets('tapping reports the new selection', (tester) async {
    final taps = <bool>[];
    await tester.pumpWidget(wrap(
      BwChoiceChip(label: const Text('30 Days'), selected: false, onSelected: taps.add),
    ));

    await tester.tap(find.text('30 Days'));
    await tester.pumpAndSettle();

    expect(taps, [true]);
  });

  testWidgets('a null callback disables the option', (tester) async {
    // Two real call sites rely on this — a busy surveillance tab and an
    // unavailable storage location. Requiring a non-null callback would have
    // silently re-enabled both.
    await tester.pumpWidget(wrap(
      const BwChoiceChip(label: Text('SD Card'), selected: false, onSelected: null),
    ));

    expect(innerChip(tester).onSelected, isNull);
    expect(innerChip(tester).isEnabled, isFalse);
  });

  testWidgets('it keeps ChoiceChip semantics rather than hand-rolling a control', (tester) async {
    // A bespoke InkWell would drop the selected state screen readers rely on —
    // a mistake already made and corrected once in this refactor.
    await tester.pumpWidget(wrap(
      BwChoiceChip(label: const Text('Dark'), selected: true, onSelected: (_) {}),
    ));

    final node = tester.getSemantics(find.text('Dark'));
    expect(node.label, 'Dark');
  });
}
