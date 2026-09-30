import 'package:bladewatch_ui/theme/hud_theme.dart';
import 'package:bladewatch_ui/widgets/hud_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {bool disableAnimations = false}) => MaterialApp(
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: disableAnimations),
        child: c!,
      ),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('HudPanel', () {
    testWidgets('paints border, radius, fill and shadows from its arguments', (tester) async {
      await tester.pumpWidget(_app(HudPanel(
        color: BwHud.dark.panel,
        borderColor: BwHud.dark.panelBorder,
        radius: BwHud.radiusPanel,
        shadows: BwHud.dark.cardShadow,
        padding: const EdgeInsets.all(8),
        child: const SizedBox(width: 10, height: 10),
      )));
      final deco = tester.widget<Container>(find.byType(Container).first).decoration! as BoxDecoration;
      expect(deco.color, BwHud.dark.panel);
      expect(deco.gradient, isNull);
      expect(deco.borderRadius, BorderRadius.circular(12));
      expect(deco.border, Border.all(color: BwHud.dark.panelBorder));
      expect(deco.boxShadow, BwHud.dark.cardShadow);
    });

    testWidgets('a gradient replaces the fill', (tester) async {
      const g = LinearGradient(colors: [Color(0xFF000000), Color(0xFFFFFFFF)]);
      await tester.pumpWidget(_app(const HudPanel(
        color: Color(0xFF123456),
        gradient: g,
        borderColor: Color(0xFF000000),
        child: SizedBox(width: 10, height: 10),
      )));
      final deco = tester.widget<Container>(find.byType(Container).first).decoration! as BoxDecoration;
      expect(deco.gradient, g);
      expect(deco.color, isNull);
    });
  });

  group('HudPulse', () {
    // MaterialApp's page route has FadeTransitions of its own: look only inside the pulse.
    final fade = find.descendant(of: find.byType(HudPulse), matching: find.byType(FadeTransition));
    double opacityAt(WidgetTester tester) => tester.widget<FadeTransition>(fade).opacity.value;

    testWidgets('pulses 1 -> 0.5 -> 1 over two seconds', (tester) async {
      await tester.pumpWidget(_app(const HudPulse(child: SizedBox(width: 8, height: 8))));
      expect(opacityAt(tester), closeTo(1.0, 0.001));
      await tester.pump(const Duration(seconds: 1));
      expect(opacityAt(tester), closeTo(0.5, 0.001));
      await tester.pump(const Duration(seconds: 1));
      expect(opacityAt(tester), closeTo(1.0, 0.001));
      await tester.pump(const Duration(milliseconds: 500));
      expect(opacityAt(tester), lessThan(1.0), reason: 'it repeats');
    });

    testWidgets('is a plain child and schedules no frames when animations are disabled', (tester) async {
      await tester.pumpWidget(_app(const HudPulse(child: SizedBox(width: 8, height: 8)), disableAnimations: true));
      expect(fade, findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('stops when animations become disabled and resumes when they are re-enabled', (tester) async {
      const pulse = HudPulse(child: SizedBox(width: 8, height: 8));
      await tester.pumpWidget(_app(pulse));
      expect(fade, findsOneWidget);
      await tester.pumpWidget(_app(pulse, disableAnimations: true));
      expect(fade, findsNothing);
      await tester.pumpAndSettle();
      await tester.pumpWidget(_app(pulse));
      expect(fade, findsOneWidget);
      await tester.pump(const Duration(seconds: 1));
      expect(opacityAt(tester), closeTo(0.5, 0.001));
    });

    testWidgets('works without a MediaQuery ancestor', (tester) async {
      await tester.pumpWidget(const Directionality(
        textDirection: TextDirection.ltr,
        child: HudPulse(child: SizedBox(width: 8, height: 8)),
      ));
      expect(fade, findsOneWidget);
    });
  });
}
