import 'package:bladewatch_companion/screens/common/stats.dart';
import 'package:bladewatch_theme/hud_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The owner, 2026-10-04: sized one by one, "₱0.00" sat beside a smaller "₱49.96" and one tiny
  // label among full-size ones. A grid that cannot fit shrinks every figure together.
  testWidgets('a grid too narrow for its figures shrinks them all to one size, and the labels to another', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: BwHud.themeData(Brightness.light),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 240,
            child: StatGrid(rows: [
              [('₱0.00', 'Fuel Cost', StatTone.plain), ('₱49.96', 'Electric Cost', StatTone.plain), ('₱1234.56', 'Total', StatTone.plain)],
              [('7', 'Trips', StatTone.info), ('1h 15m', 'Hours', StatTone.drive)],
            ]),
          ),
        ),
      ),
    ));
    final texts = tester.widgetList<Text>(find.byType(Text)).toList();
    final values = {for (final t in texts.where((t) => t.style!.fontSize == 20)) t.textScaler};
    final labels = {for (final t in texts.where((t) => t.style!.fontSize == 12)) t.textScaler};
    expect(values, hasLength(1));
    expect(labels, hasLength(1));
    expect(values.single!.scale(20), lessThan(20), reason: '₱1234.56 cannot fit a third of 240 at full size');
    expect(tester.takeException(), isNull);
  });

  // The owner asked whether a cost with more digits breaks the layout: it shrinks with its row,
  // on one line, and nothing overflows or breaks mid-number.
  testWidgets('a cost with many more digits still fits on one line, the whole grid at one size', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: BwHud.themeData(Brightness.light),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 360,
            child: StatGrid(center: true, rows: [
              [('7', 'Trips', StatTone.plain), ('1h 15m', 'Hours', StatTone.plain), ('3.8', 'kWh', StatTone.plain)],
              [('₱1,234,567.89', 'Fuel Cost', StatTone.plain), ('₱49.96', 'Electric Cost', StatTone.plain), ('₱1,234,617.85', 'Total cost', StatTone.plain)],
            ]),
          ),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    final values = tester.widgetList<Text>(find.byType(Text)).where((t) => t.style!.fontSize == 20).toList();
    expect({for (final t in values) t.textScaler}, hasLength(1));
    for (final t in values) {
      expect(t.maxLines, 1, reason: t.data);
      // The laid-out line, not the clipped box, fits its column: (360 - 2 gaps of 16) / 3.
      final line = TextPainter(text: TextSpan(text: t.data, style: t.style), textDirection: TextDirection.ltr, textScaler: t.textScaler!)..layout();
      expect(line.width, lessThanOrEqualTo((360 - 32) / 3), reason: t.data);
      line.dispose();
    }
  });
}
