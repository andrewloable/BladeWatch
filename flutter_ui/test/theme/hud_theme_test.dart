import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:bladewatch_ui/theme/hud_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins every HUD token to the value in the owner's reference HTML
/// (`docs/design/hud-reference/`). The numbers are typed out again on purpose: a test that read
/// them back from [BwHud] could not fail.
void main() {
  group('BwHud.dark (dashboard-dark.html)', () {
    const h = BwHud.dark;
    test('surfaces', () {
      expect(h.pageBackground, const Color(0xFF05070B));
      expect(h.railBackground, const Color(0xFF05080F));
      expect(h.panel, const Color(0xFF0A1018));
      expect(h.panelPressed, const Color(0xFF0F1C29));
      expect(h.summaryGradient, const [Color(0xCC042F2E), Color(0xFF0A1018), Color(0xFF091722)]);
      expect(h.viewAllFill, const Color(0x80083344));
    });
    test('borders and rules', () {
      expect(h.railBorder, const Color(0x4D06B6D4));
      expect(h.cardBorder, const Color(0x6600F3FF));
      expect(h.panelBorder, const Color(0x4D06B6D4));
      expect(h.panelBorderStrong, const Color(0x6606B6D4));
      expect(h.titleRule, const Color(0x3306B6D4));
      expect(h.cardDivider, const Color(0x3306B6D4));
      expect(h.chipBorder, const Color(0x4D06B6D4));
      expect(h.magentaBorder, const Color(0x80FF0055));
    });
    test('accents and text', () {
      expect(h.accent, const Color(0xFF22D3EE));
      expect(h.accentBright, const Color(0xFF67E8F9));
      expect(h.iconAccent, const Color(0xFF22D3EE));
      expect(h.dot, const Color(0xFF22D3EE));
      expect(h.dotGlow, const Color(0xFF00F3FF));
      expect(h.magenta, const Color(0xFFFF0055));
      expect(h.textPrimary, const Color(0xFFFFFFFF));
      expect(h.textSecondary, const Color(0xFFCBD5E1));
      expect(h.statLabel, const Color(0xCC22D3EE));
      expect(h.tileLabel, const Color(0xB322D3EE));
      expect(h.driveTimeValue, const Color(0xFFFFFFFF));
      expect(h.liveValue, const Color(0xFFFFFFFF));
      expect(h.onlineValue, const Color(0xFFFFFFFF));
      expect(h.labelWeight, FontWeight.w400);
    });
    test('glow', () {
      expect(h.glowCyan, const Shadow(color: Color(0x9900F3FF), blurRadius: 8));
      expect(h.glowMagenta, const Shadow(color: Color(0x99FF0055), blurRadius: 8));
      expect(h.cardShadow, const [BoxShadow(color: Color(0x2600F3FF), blurRadius: 10)]);
      expect(h.tileShadow, isEmpty);
      expect(h.cornerGlowCyan, const Color(0x1A06B6D4));
      expect(h.cornerGlowMagenta, const Color(0x1AFF0055));
    });
    test('nav rail', () {
      expect(h.navInactive, const Color(0xFF94A3B8));
      expect(h.navActiveLabel, const Color(0xFF22D3EE));
      expect(h.navActiveIcon, const Color(0xFF22D3EE));
      expect(h.navActiveBorder, const Color(0xFF22D3EE));
      expect(h.navActiveGradient, const [Color(0xCC083344), Color(0xFF0A1018)]);
      expect(h.navActiveShadow, const [BoxShadow(color: Color(0x4D00F3FF), blurRadius: 12)]);
      expect(h.railShadow, const [BoxShadow(color: Color(0x80000000), offset: Offset(5, 0), blurRadius: 15)]);
    });
  });

  group('BwHud.light (dashboard-light.html)', () {
    const h = BwHud.light;
    test('surfaces', () {
      expect(h.pageBackground, const Color(0xFFF4F6F9));
      expect(h.railBackground, const Color(0xFFFFFFFF));
      expect(h.panel, const Color(0xFFFFFFFF));
      expect(h.panelPressed, const Color(0xFFF8FAFC));
      // Flat white: the light card has no gradient.
      expect(h.summaryGradient.toSet(), {const Color(0xFFFFFFFF)});
      expect(h.viewAllFill, const Color(0xFFECFEFF));
    });
    test('borders and rules', () {
      expect(h.railBorder, const Color(0x3306B6D4));
      expect(h.cardBorder, const Color(0x6600B8D4));
      expect(h.panelBorder, const Color(0x4D06B6D4));
      expect(h.panelBorderStrong, const Color(0x6606B6D4));
      expect(h.titleRule, const Color(0x3306B6D4));
      expect(h.cardDivider, const Color(0xFFF1F5F9));
      expect(h.chipBorder, const Color(0xFFE2E8F0));
      expect(h.magentaBorder, const Color(0x80D81B60));
    });
    test('accents and text', () {
      expect(h.accent, const Color(0xFF0E7490));
      expect(h.accentBright, const Color(0xFF0E7490));
      expect(h.iconAccent, const Color(0xFF0891B2));
      expect(h.dot, const Color(0xFF06B6D4));
      expect(h.dotGlow, const Color(0xFF00B8D4));
      expect(h.magenta, const Color(0xFFD81B60));
      expect(h.textPrimary, const Color(0xFF0D0D16));
      expect(h.textSecondary, const Color(0xFF334155));
      expect(h.statLabel, const Color(0xFF64748B));
      expect(h.tileLabel, const Color(0xFF64748B));
      expect(h.driveTimeValue, const Color(0xFFD81B60));
      expect(h.liveValue, const Color(0xFFD81B60));
      expect(h.onlineValue, const Color(0xFF0E7490));
      expect(h.labelWeight, FontWeight.w700);
    });
    test('no text glow', () {
      expect(h.glowCyan, isNull);
      expect(h.glowMagenta, isNull);
      expect(h.cardShadow, const [BoxShadow(color: Color(0x1400B8D4), offset: Offset(0, 4), blurRadius: 20)]);
      expect(h.tileShadow, const [BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 2)]);
      expect(h.cornerGlowCyan, const Color(0x0D06B6D4));
      expect(h.cornerGlowMagenta, const Color(0x0DD81B60));
    });
    test('nav rail', () {
      expect(h.navInactive, const Color(0xFF64748B));
      expect(h.navActiveLabel, const Color(0xFF0E7490));
      expect(h.navActiveIcon, const Color(0xFF0891B2));
      expect(h.navActiveBorder, const Color(0xFF22D3EE));
      expect(h.navActiveGradient, const [Color(0xFFECFEFF), Color(0xFFFFFFFF)]);
    });
  });

  test('shape and font constants', () {
    expect(BwHud.fontFamily, 'packages/bladewatch_theme/SpaceMono', reason: 'the package-declared family');
    expect(BwHud.radiusPanel, 12);
    expect(BwHud.radiusSmall, 4);
  });

  group('BwHud.of', () {
    Future<BwHud> read(WidgetTester tester, ThemeData theme) async {
      late BwHud got;
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: Builder(builder: (context) {
          got = BwHud.of(context);
          return const SizedBox();
        }),
      ));
      // MaterialApp animates between themes; let the new one land.
      await tester.pumpAndSettle();
      return got;
    }

    testWidgets('falls back to the const for the theme brightness when no extension is installed', (tester) async {
      expect(await read(tester, BladeWatchTheme.light()), same(BwHud.light));
      expect(await read(tester, BladeWatchTheme.dark()), same(BwHud.dark));
    });

    testWidgets('returns the installed extension', (tester) async {
      final themed = BladeWatchTheme.light().copyWith(extensions: [BwHud.dark]);
      expect(await read(tester, themed), same(BwHud.dark));
    });
  });

  test('copyWith is identity and lerp switches at the midpoint', () {
    expect(BwHud.dark.copyWith(), same(BwHud.dark));
    expect(BwHud.dark.lerp(BwHud.light, 0.4), same(BwHud.dark));
    expect(BwHud.dark.lerp(BwHud.light, 0.5), same(BwHud.light));
    expect(BwHud.dark.lerp(null, 1), same(BwHud.dark));
  });
}
