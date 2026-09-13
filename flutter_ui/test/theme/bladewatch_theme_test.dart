import 'package:bladewatch_ui/theme/bladewatch_theme.dart';
import 'package:bladewatch_ui/theme/color_tokens.dart';
import 'package:bladewatch_ui/theme/type_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BladeWatchTheme.light', () {
    final theme = BladeWatchTheme.light();

    test('uses Material 3', () {
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
    });

    test('color scheme roles come from BwColorTokens.light', () {
      final cs = theme.colorScheme;
      expect(cs.primary, BwColorTokens.light.primary);
      expect(cs.onPrimary, BwColorTokens.light.onPrimary);
      expect(cs.primaryContainer, BwColorTokens.light.primaryContainer);
      expect(cs.secondaryContainer, BwColorTokens.light.secondaryContainer);
      expect(cs.tertiary, BwColorTokens.light.tertiary);
      expect(cs.error, BwColorTokens.light.error);
      expect(cs.surface, BwColorTokens.light.surface);
      expect(cs.surfaceContainerHighest, BwColorTokens.light.surfaceContainerHighest);
      expect(cs.outline, BwColorTokens.light.outline);
      expect(cs.outlineVariant, BwColorTokens.light.outlineVariant);
      expect(cs.inversePrimary, BwColorTokens.light.inversePrimary);
    });

    test('scaffold background is the surface role, not stock Material grey', () {
      expect(theme.scaffoldBackgroundColor, BwColorTokens.light.surface);
    });

    test('overridden type roles carry fontWeight.w500 and correct pixel tracking', () {
      final text = theme.textTheme;
      for (final pair in [
        (text.displaySmall, BwTypeTracking.displaySmall),
        (text.headlineLarge, BwTypeTracking.headlineLarge),
        (text.headlineMedium, BwTypeTracking.headlineMedium),
        (text.headlineSmall, BwTypeTracking.headlineSmall),
        (text.titleLarge, BwTypeTracking.titleLarge),
        (text.titleMedium, BwTypeTracking.titleMedium),
        (text.labelLarge, BwTypeTracking.labelLarge),
        (text.labelMedium, BwTypeTracking.labelMedium),
      ]) {
        final style = pair.$1!;
        expect(style.fontWeight, FontWeight.w500);
        expect(style.letterSpacing, closeTo(BwTypeTracking.toPixels(pair.$2, style.fontSize!), 0.001));
      }
    });

    test('body roles are untouched by the tracking override (inherit M3 defaults)', () {
      final stock = ThemeData(brightness: Brightness.light, useMaterial3: true).textTheme;
      expect(theme.textTheme.bodyLarge!.letterSpacing, stock.bodyLarge!.letterSpacing);
      expect(theme.textTheme.bodyMedium!.letterSpacing, stock.bodyMedium!.letterSpacing);
    });
  });

  group('BladeWatchTheme.dark', () {
    final theme = BladeWatchTheme.dark();

    test('uses Material 3 dark', () {
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.dark);
    });

    test('color scheme roles come from BwColorTokens.dark', () {
      final cs = theme.colorScheme;
      expect(cs.primary, BwColorTokens.dark.primary);
      expect(cs.surface, BwColorTokens.dark.surface);
      expect(cs.secondaryContainer, BwColorTokens.dark.secondaryContainer);
      expect(cs.outlineVariant, BwColorTokens.dark.outlineVariant);
    });
  });

  test('light and dark never share a color for the same role (no theme accidentally reused)', () {
    final light = BladeWatchTheme.light().colorScheme;
    final dark = BladeWatchTheme.dark().colorScheme;
    expect(light.primary, isNot(dark.primary));
    expect(light.surface, isNot(dark.surface));
  });
}
