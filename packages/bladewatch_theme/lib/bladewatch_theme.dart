import 'package:flutter/material.dart';

import 'color_tokens.dart';
import 'type_tokens.dart';

/// Builds the light/dark `ThemeData` for the Flutter UI from the Android M3
/// tokens (`BwColorTokens`, `BwTypeTracking`) — see
/// `docs/ui-ux-design-language.md`. Mirrors `Theme.BladeWatch.M3` in
/// `app/src/main/res/values/themes_bladewatch.xml`: the M3 baseline type
/// scale is the parent, and only the roles that XML overrides
/// (`textAppearanceDisplaySmall`, `...HeadlineLarge/Medium/Small`,
/// `...TitleLarge/Medium`, `...LabelLarge/Medium`) get the M3 Expressive
/// `sans-serif-medium` + tightened-tracking treatment here; body roles are
/// left at the M3 stock default, same as the Android theme leaves them
/// unset.
abstract final class BladeWatchTheme {
  static ThemeData light() => _build(Brightness.light, BwColorTokens.light);

  static ThemeData dark() => _build(Brightness.dark, BwColorTokens.dark);

  static ThemeData _build(Brightness brightness, BwColorTokens tokens) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: tokens.primary,
      onPrimary: tokens.onPrimary,
      primaryContainer: tokens.primaryContainer,
      onPrimaryContainer: tokens.onPrimaryContainer,
      secondary: tokens.secondary,
      onSecondary: tokens.onSecondary,
      secondaryContainer: tokens.secondaryContainer,
      onSecondaryContainer: tokens.onSecondaryContainer,
      tertiary: tokens.tertiary,
      onTertiary: tokens.onTertiary,
      tertiaryContainer: tokens.tertiaryContainer,
      onTertiaryContainer: tokens.onTertiaryContainer,
      error: tokens.error,
      onError: tokens.onError,
      errorContainer: tokens.errorContainer,
      onErrorContainer: tokens.onErrorContainer,
      surface: tokens.surface,
      onSurface: tokens.onSurface,
      surfaceContainerLowest: tokens.surfaceContainerLowest,
      surfaceContainerLow: tokens.surfaceContainerLow,
      surfaceContainer: tokens.surfaceContainer,
      surfaceContainerHigh: tokens.surfaceContainerHigh,
      surfaceContainerHighest: tokens.surfaceContainerHighest,
      surfaceDim: tokens.surfaceDim,
      surfaceBright: tokens.surfaceBright,
      onSurfaceVariant: tokens.onSurfaceVariant,
      outline: tokens.outline,
      outlineVariant: tokens.outlineVariant,
      inverseSurface: tokens.inverseSurface,
      onInverseSurface: tokens.inverseOnSurface,
      inversePrimary: tokens.inversePrimary,
      scrim: tokens.scrim,
    );

    // The stock M3 type scale — the same baseline `Theme.Material3.Light.
    // NoActionBar` gives Android before any TextAppearance.BladeWatch.*
    // override is applied. Flutter leaves TextStyle.fontSize null here until
    // resolved inside a widget tree, so the 8 overridden roles below pin
    // BwTypeTracking's concrete M3 spec size explicitly; every other role is
    // untouched and keeps Flutter's normal (lazy) resolution.
    final baseText = ThemeData(brightness: brightness, useMaterial3: true).textTheme;

    TextStyle expressive(TextStyle? style, double fontSize, double trackingEm) => style!.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          letterSpacing: BwTypeTracking.toPixels(trackingEm, fontSize),
        );

    final textTheme = baseText.copyWith(
      displaySmall: expressive(
          baseText.displaySmall, BwTypeTracking.fontSizeDisplaySmall, BwTypeTracking.displaySmall),
      headlineLarge: expressive(
          baseText.headlineLarge, BwTypeTracking.fontSizeHeadlineLarge, BwTypeTracking.headlineLarge),
      headlineMedium: expressive(
          baseText.headlineMedium, BwTypeTracking.fontSizeHeadlineMedium, BwTypeTracking.headlineMedium),
      headlineSmall: expressive(
          baseText.headlineSmall, BwTypeTracking.fontSizeHeadlineSmall, BwTypeTracking.headlineSmall),
      titleLarge: expressive(baseText.titleLarge, BwTypeTracking.fontSizeTitleLarge, BwTypeTracking.titleLarge),
      titleMedium: expressive(
          baseText.titleMedium, BwTypeTracking.fontSizeTitleMedium, BwTypeTracking.titleMedium),
      labelLarge: expressive(baseText.labelLarge, BwTypeTracking.fontSizeLabelLarge, BwTypeTracking.labelLarge),
      labelMedium: expressive(
          baseText.labelMedium, BwTypeTracking.fontSizeLabelMedium, BwTypeTracking.labelMedium),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      // BladeWatch-mtnk follow-up: the four status roles have no ColorScheme
      // slot, so they ride as a theme extension. Without this they were
      // unreachable and screens hand-rolled their own brightness branches.
      extensions: [BwStatusColors.from(tokens)],
      scaffoldBackgroundColor: tokens.surface,
      textTheme: textTheme,
      dividerColor: tokens.outlineVariant,
      cardTheme: CardThemeData(
        color: tokens.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.surface,
        foregroundColor: tokens.onSurface,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      // Segmented controls follow the same decision as BwChoiceChip
      // (BladeWatch-hpcd): native fills the selected segment with the primary
      // colour. Unlike chips this CAN live in the theme, because every
      // SegmentedButton in the app is a single-choice selector — there is no
      // multi-select variant whose check mark carries meaning.
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? tokens.primary : tokens.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? tokens.onPrimary : tokens.onSurface,
          ),
          side: WidgetStatePropertyAll(BorderSide(color: tokens.outlineVariant)),
        ),
      ),
    );
  }
}
