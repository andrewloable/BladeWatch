import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:bladewatch_ui/theme/color_tokens.dart';
import 'package:bladewatch_ui/theme/hud_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// BladeWatch-oxcx: the full HUD ThemeData. Every component family reads a BwHud token; change the token
/// or the mapping and the matching expectation fails.
void main() {
  for (final b in [Brightness.dark, Brightness.light]) {
    final hud = b == Brightness.dark ? BwHud.dark : BwHud.light;
    final theme = BwHud.themeData(b);
    Color over(Color top, Color bottom) => Color.alphaBlend(top, bottom);

    group('BwHud.themeData(${b.name})', () {
      test('is cached and carries the HUD extension and the re-mapped status colours', () {
        expect(BwHud.themeData(b), same(theme));
        expect(theme.extension<BwHud>(), same(hud));
        final status = theme.extension<BwStatusColors>()!;
        expect(
          (status.success, status.warning, status.danger, status.info),
          (hud.dot, hud.warning, hud.magenta, hud.accent),
        );
        expect(theme.extensions.values.whereType<BwStatusColors>(), hasLength(1));
        expect(theme.extensions.values.whereType<BwHud>(), hasLength(1));
      });

      test('the ColorScheme is mapped from the tokens', () {
        final c = theme.colorScheme;
        expect(c.brightness, b);
        expect(theme.scaffoldBackgroundColor, hud.pageBackground);
        expect((c.primary, c.onPrimary), (hud.accent, hud.pageBackground));
        expect((c.tertiary, c.error), (hud.magenta, hud.magenta));
        expect((c.surface, c.onSurface, c.onSurfaceVariant), (hud.pageBackground, hud.textPrimary, hud.textSecondary));
        expect((c.surfaceContainer, c.surfaceContainerHigh), (hud.panel, hud.panelPressed));
        expect(c.primaryContainer, over(hud.viewAllFill, hud.panel));
        expect(c.outlineVariant, over(hud.panelBorder, hud.panel));
        expect(c.errorContainer, over(hud.magenta.withValues(alpha: 0.15), hud.panel));
        expect(c.inversePrimary, hud.accent);
      });

      test('the type scale is Space Mono at the HUD sizes and colours', () {
        final t = theme.textTheme;
        for (final s in [
          t.displaySmall,
          t.headlineMedium,
          t.titleLarge,
          t.titleMedium,
          t.bodyLarge,
          t.bodySmall,
          t.labelLarge,
          t.labelSmall,
        ]) {
          expect(s!.fontFamily, BwHud.fontFamily);
          expect(s.color, hud.textPrimary);
        }
        expect((t.displaySmall!.fontSize, t.displaySmall!.fontWeight), (30, FontWeight.w700));
        expect((t.headlineMedium!.fontSize, t.headlineSmall!.fontSize), (24, 20));
        expect((t.titleLarge!.fontSize, t.titleLarge!.letterSpacing), (20, 20 * 0.05));
        expect(t.bodyMedium!.fontSize, 14);
        expect((t.labelLarge!.fontSize, t.labelLarge!.fontWeight), (12, FontWeight.w700));
        expect(t.labelMedium!.fontWeight, hud.labelWeight);
        expect(t.labelSmall!.fontSize, 10);
      });

      test('cards, dialogs, sheets, snackbars, dividers and tooltips', () {
        final card = theme.cardTheme;
        expect(card.color, hud.panel);
        expect(card.elevation, 0);
        final cardShape = card.shape! as RoundedRectangleBorder;
        expect(cardShape.borderRadius, BorderRadius.circular(4));
        expect(cardShape.side.color, hud.panelBorder);

        final dialog = theme.dialogTheme;
        expect(dialog.backgroundColor, hud.panel);
        final dialogShape = dialog.shape! as RoundedRectangleBorder;
        expect((dialogShape.borderRadius, dialogShape.side.color), (BorderRadius.circular(12), hud.cardBorder));
        expect(dialog.titleTextStyle!.color, hud.accent);
        expect(dialog.titleTextStyle!.shadows, BwHud.hudGlowList(hud.glowCyan));

        final sheet = theme.bottomSheetTheme;
        expect((sheet.backgroundColor, sheet.modalBackgroundColor), (hud.panel, hud.panel));
        expect((sheet.shape! as RoundedRectangleBorder).side.color, hud.cardBorder);

        final snack = theme.snackBarTheme;
        expect(
          (snack.backgroundColor, snack.actionTextColor, snack.behavior),
          (hud.panelPressed, hud.accent, SnackBarBehavior.floating),
        );
        expect((snack.shape! as RoundedRectangleBorder).side.color, hud.panelBorderStrong);

        expect((theme.dividerTheme.color, theme.dividerTheme.thickness), (hud.cardDivider, 1));
        final tip = theme.tooltipTheme.decoration! as BoxDecoration;
        expect((tip.color, tip.border), (hud.panelPressed, Border.all(color: hud.panelBorderStrong)));
        expect(theme.appBarTheme.backgroundColor, hud.pageBackground);
        expect(theme.appBarTheme.titleTextStyle!.color, hud.accent);
      });

      test('list tiles, switches, checkboxes, radios, sliders and progress', () {
        final tile = theme.listTileTheme;
        expect((tile.iconColor, tile.textColor, tile.selectedColor), (hud.iconAccent, hud.textPrimary, hud.accent));
        expect(tile.selectedTileColor, over(hud.viewAllFill, hud.panel));

        final on = <WidgetState>{WidgetState.selected};
        final off = <WidgetState>{};
        final sw = theme.switchTheme;
        expect((sw.thumbColor!.resolve(on), sw.thumbColor!.resolve(off)), (hud.accent, hud.textSecondary));
        expect(
          (sw.trackColor!.resolve(on), sw.trackColor!.resolve(off)),
          (over(hud.viewAllFill, hud.panel), hud.panel),
        );
        expect(
          (sw.trackOutlineColor!.resolve(on), sw.trackOutlineColor!.resolve(off)),
          (hud.accent, over(hud.panelBorder, hud.panel)),
        );

        final cb = theme.checkboxTheme;
        expect(
          (cb.fillColor!.resolve(on), cb.fillColor!.resolve(off), cb.checkColor!.resolve(on)),
          (hud.accent, null, hud.pageBackground),
        );
        expect(theme.radioTheme.fillColor!.resolve(on), hud.accent);

        final slider = theme.sliderTheme;
        expect(
          (slider.activeTrackColor, slider.thumbColor, slider.inactiveTrackColor),
          (hud.accent, hud.accent, over(hud.panelBorder, hud.panel)),
        );

        final progress = theme.progressIndicatorTheme;
        expect((progress.color, progress.linearTrackColor), (hud.accent, over(hud.panelBorder, hud.panel)));
      });

      test('inputs, dropdowns and menus', () {
        final input = theme.inputDecorationTheme;
        expect((input.filled, input.fillColor), (true, hud.panel));
        expect((input.enabledBorder! as OutlineInputBorder).borderSide.color, over(hud.panelBorder, hud.panel));
        expect((input.focusedBorder! as OutlineInputBorder).borderSide.color, hud.accent);
        expect((input.errorBorder! as OutlineInputBorder).borderSide.color, hud.magenta);
        expect((input.enabledBorder! as OutlineInputBorder).borderRadius, BorderRadius.circular(4));
        expect(input.labelStyle!.fontFamily, BwHud.fontFamily);
        expect(theme.dropdownMenuTheme.menuStyle!.backgroundColor!.resolve({}), hud.panel);
        expect(theme.popupMenuTheme.color, hud.panel);
        expect((theme.popupMenuTheme.shape! as RoundedRectangleBorder).side.color, hud.panelBorderStrong);
      });

      test('segmented buttons, chips and tabs', () {
        final on = <WidgetState>{WidgetState.selected};
        final off = <WidgetState>{};
        final seg = theme.segmentedButtonTheme.style!;
        expect(
          (seg.backgroundColor!.resolve(on), seg.backgroundColor!.resolve(off)),
          (over(hud.viewAllFill, hud.panel), hud.panel),
        );
        expect((seg.foregroundColor!.resolve(on), seg.foregroundColor!.resolve(off)), (hud.accent, hud.textSecondary));
        expect(
          (seg.side!.resolve(on)!.color, seg.side!.resolve(off)!.color),
          (hud.accent, over(hud.panelBorder, hud.panel)),
        );

        final chip = theme.chipTheme;
        expect((chip.backgroundColor, chip.selectedColor), (hud.panel, over(hud.viewAllFill, hud.panel)));
        expect((chip.side! as WidgetStateBorderSide).resolve(on)!.color, hud.accent);
        expect((chip.side! as WidgetStateBorderSide).resolve(off)!.color, hud.chipBorder);
        expect((chip.shape! as RoundedRectangleBorder).borderRadius, BorderRadius.circular(4));

        final tabs = theme.tabBarTheme;
        expect(
          (tabs.indicatorColor, tabs.labelColor, tabs.unselectedLabelColor, tabs.dividerColor),
          (hud.accent, hud.accent, hud.textSecondary, hud.cardDivider),
        );
      });

      test('buttons: filled is accent on soft accent, outlined is the chip box, text is the accent; all 4 dp', () {
        final off = <WidgetState>{};
        final disabled = <WidgetState>{WidgetState.disabled};
        final filled = theme.filledButtonTheme.style!;
        expect(
          (filled.backgroundColor!.resolve(off), filled.foregroundColor!.resolve(off)),
          (over(hud.viewAllFill, hud.panel), hud.accent),
        );
        expect(filled.side!.resolve(off)!.color, hud.accent);
        expect(filled.backgroundColor!.resolve(disabled), hud.panel);
        expect(filled.foregroundColor!.resolve(disabled)!.a, closeTo(0.38 * hud.textSecondary.a, 0.01));
        expect(filled.side!.resolve(disabled)!.color, over(hud.panelBorder, hud.panel));
        expect(filled.elevation!.resolve(off), 0);
        expect((filled.shape!.resolve(off)! as RoundedRectangleBorder).borderRadius, BorderRadius.circular(4));
        expect(filled.textStyle!.resolve(off)!.fontWeight, FontWeight.w700);
        expect(filled.minimumSize!.resolve(off), const Size(0, 36));

        final outlined = theme.outlinedButtonTheme.style!;
        expect(
          (
            outlined.backgroundColor!.resolve(off),
            outlined.foregroundColor!.resolve(off),
            outlined.side!.resolve(off)!.color,
          ),
          (hud.panel, hud.textSecondary, hud.chipBorder),
        );

        final text = theme.textButtonTheme.style!;
        expect(
          (text.foregroundColor!.resolve(off), text.backgroundColor!.resolve(off)),
          (hud.accent, const Color(0x00000000)),
        );
        expect(text.side!.resolve(off), BorderSide.none);

        expect(theme.iconButtonTheme.style!.foregroundColor!.resolve(off), hud.iconAccent);

        final fab = theme.floatingActionButtonTheme;
        expect((fab.backgroundColor, fab.foregroundColor, fab.elevation), (over(hud.viewAllFill, hud.panel), hud.accent, 0));
        expect((fab.shape! as RoundedRectangleBorder).side.color, hud.accent);
      });
    });
  }

  test('the warning token exists in both modes and differs from cyan and magenta', () {
    expect(BwHud.dark.warning, const Color(0xFFFBBF24));
    expect(BwHud.light.warning, const Color(0xFFB45309));
    for (final h in [BwHud.dark, BwHud.light]) {
      expect(h.warning, isNot(h.accent));
      expect(h.warning, isNot(h.magenta));
    }
  });

  test('BwHud.text builds the HUD style: package font, even leading, tracking in em', () {
    final s = BwHud.text(20, lineHeight: 28, color: const Color(0xFF123456), weight: FontWeight.w700, em: 0.05);
    expect(
      (s.fontFamily, s.fontSize, s.height, s.fontWeight, s.letterSpacing),
      (BwHud.fontFamily, 20, 28 / 20, FontWeight.w700, 1.0),
    );
    expect(s.leadingDistribution, TextLeadingDistribution.even);
    expect(BwHud.hudGlowList(null), isNull);
    expect(BwHud.hudGlowList(BwHud.dark.glowCyan), [BwHud.dark.glowCyan]);
  });

  test('the HUD theme is built on the M3 BladeWatchTheme: same brightness, still Material 3', () {
    expect(BwHud.themeData(Brightness.dark).useMaterial3, BladeWatchTheme.dark().useMaterial3);
    expect(BwHud.themeData(Brightness.light).brightness, Brightness.light);
  });
}
