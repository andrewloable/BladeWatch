import 'package:flutter/material.dart';

/// M3 color-role tokens ported from `app/src/main/res/values/colors_m3.xml`
/// (light) and `values-night/colors_m3.xml` (dark) — see
/// `docs/ui-ux-design-language.md`'s Color section. Field names match the
/// Android `md_sys_color_<role>` / `bladewatch_status_<role>` names with the
/// `_light`/`_dark` suffix dropped; [xmlNameMap] adds it back so tests can
/// cross-check every value against the XML source of truth.
class BwColorTokens {
  final Color primary, onPrimary, primaryContainer, onPrimaryContainer;
  final Color secondary, onSecondary, secondaryContainer, onSecondaryContainer;
  final Color tertiary, onTertiary, tertiaryContainer, onTertiaryContainer;
  final Color error, onError, errorContainer, onErrorContainer;
  final Color background, onBackground;
  final Color surface, onSurface;
  final Color surfaceVariant, onSurfaceVariant;
  final Color surfaceDim, surfaceBright;
  final Color surfaceContainerLowest, surfaceContainerLow, surfaceContainer;
  final Color surfaceContainerHigh, surfaceContainerHighest;
  final Color outline, outlineVariant;
  final Color inverseSurface, inverseOnSurface, inversePrimary;
  final Color scrim;
  final Color statusSuccess, statusWarning, statusDanger, statusInfo;

  const BwColorTokens({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.onSurfaceVariant,
    required this.surfaceDim,
    required this.surfaceBright,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.outline,
    required this.outlineVariant,
    required this.inverseSurface,
    required this.inverseOnSurface,
    required this.inversePrimary,
    required this.scrim,
    required this.statusSuccess,
    required this.statusWarning,
    required this.statusDanger,
    required this.statusInfo,
  });

  /// {xml resource name (with the `_$suffix`) : value} for every field, so a
  /// test can cross-check this instance against the Android XML it was
  /// ported from without hand-maintaining two copies of the same mapping.
  Map<String, Color> xmlNameMap(String suffix) => {
        'md_sys_color_primary_$suffix': primary,
        'md_sys_color_on_primary_$suffix': onPrimary,
        'md_sys_color_primary_container_$suffix': primaryContainer,
        'md_sys_color_on_primary_container_$suffix': onPrimaryContainer,
        'md_sys_color_secondary_$suffix': secondary,
        'md_sys_color_on_secondary_$suffix': onSecondary,
        'md_sys_color_secondary_container_$suffix': secondaryContainer,
        'md_sys_color_on_secondary_container_$suffix': onSecondaryContainer,
        'md_sys_color_tertiary_$suffix': tertiary,
        'md_sys_color_on_tertiary_$suffix': onTertiary,
        'md_sys_color_tertiary_container_$suffix': tertiaryContainer,
        'md_sys_color_on_tertiary_container_$suffix': onTertiaryContainer,
        'md_sys_color_error_$suffix': error,
        'md_sys_color_on_error_$suffix': onError,
        'md_sys_color_error_container_$suffix': errorContainer,
        'md_sys_color_on_error_container_$suffix': onErrorContainer,
        'md_sys_color_background_$suffix': background,
        'md_sys_color_on_background_$suffix': onBackground,
        'md_sys_color_surface_$suffix': surface,
        'md_sys_color_on_surface_$suffix': onSurface,
        'md_sys_color_surface_variant_$suffix': surfaceVariant,
        'md_sys_color_on_surface_variant_$suffix': onSurfaceVariant,
        'md_sys_color_surface_dim_$suffix': surfaceDim,
        'md_sys_color_surface_bright_$suffix': surfaceBright,
        'md_sys_color_surface_container_lowest_$suffix': surfaceContainerLowest,
        'md_sys_color_surface_container_low_$suffix': surfaceContainerLow,
        'md_sys_color_surface_container_$suffix': surfaceContainer,
        'md_sys_color_surface_container_high_$suffix': surfaceContainerHigh,
        'md_sys_color_surface_container_highest_$suffix': surfaceContainerHighest,
        'md_sys_color_outline_$suffix': outline,
        'md_sys_color_outline_variant_$suffix': outlineVariant,
        'md_sys_color_inverse_surface_$suffix': inverseSurface,
        'md_sys_color_inverse_on_surface_$suffix': inverseOnSurface,
        'md_sys_color_inverse_primary_$suffix': inversePrimary,
        'md_sys_color_scrim_$suffix': scrim,
        'bladewatch_status_success_$suffix': statusSuccess,
        'bladewatch_status_warning_$suffix': statusWarning,
        'bladewatch_status_danger_$suffix': statusDanger,
        'bladewatch_status_info_$suffix': statusInfo,
      };

  static const light = BwColorTokens(
    primary: Color(0xFF00677E),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFB4EBFF),
    onPrimaryContainer: Color(0xFF001F27),
    secondary: Color(0xFF4C626A),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFCEE6F0),
    onSecondaryContainer: Color(0xFF061E25),
    tertiary: Color(0xFF595C7E),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFDFE0FF),
    onTertiaryContainer: Color(0xFF161937),
    error: Color(0xFFBA1A1A),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    background: Color(0xFFFBFCFE),
    onBackground: Color(0xFF191C1D),
    surface: Color(0xFFFBFCFE),
    onSurface: Color(0xFF191C1D),
    surfaceVariant: Color(0xFFDBE4E8),
    onSurfaceVariant: Color(0xFF40484B),
    surfaceDim: Color(0xFFD8DADC),
    surfaceBright: Color(0xFFFBFCFE),
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF2F4F5),
    surfaceContainer: Color(0xFFECEEEF),
    surfaceContainerHigh: Color(0xFFE7E8EA),
    surfaceContainerHighest: Color(0xFFE1E3E4),
    outline: Color(0xFF70787C),
    outlineVariant: Color(0xFFBFC8CC),
    inverseSurface: Color(0xFF2E3132),
    inverseOnSurface: Color(0xFFEFF1F2),
    inversePrimary: Color(0xFF3CD7FF),
    scrim: Color(0xFF000000),
    statusSuccess: Color(0xFF1F7A3F),
    statusWarning: Color(0xFFA6601C),
    statusDanger: Color(0xFFBA1A1A),
    statusInfo: Color(0xFF00658F),
  );

  static const dark = BwColorTokens(
    primary: Color(0xFF3CD7FF),
    onPrimary: Color(0xFF003642),
    primaryContainer: Color(0xFF004E5F),
    onPrimaryContainer: Color(0xFFB4EBFF),
    secondary: Color(0xFFB3CAD4),
    onSecondary: Color(0xFF1D333B),
    secondaryContainer: Color(0xFF344A52),
    onSecondaryContainer: Color(0xFFCEE6F0),
    tertiary: Color(0xFFC1C4EB),
    onTertiary: Color(0xFF2B2E4D),
    tertiaryContainer: Color(0xFF414465),
    onTertiaryContainer: Color(0xFFDFE0FF),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    background: Color(0xFF111415),
    onBackground: Color(0xFFE1E3E4),
    surface: Color(0xFF111415),
    onSurface: Color(0xFFE1E3E4),
    surfaceVariant: Color(0xFF40484B),
    onSurfaceVariant: Color(0xFFBFC8CC),
    surfaceDim: Color(0xFF111415),
    surfaceBright: Color(0xFF373A3B),
    surfaceContainerLowest: Color(0xFF0C0F10),
    surfaceContainerLow: Color(0xFF191C1D),
    surfaceContainer: Color(0xFF1D2021),
    surfaceContainerHigh: Color(0xFF272A2C),
    surfaceContainerHighest: Color(0xFF2E3132),
    outline: Color(0xFF899296),
    outlineVariant: Color(0xFF40484B),
    inverseSurface: Color(0xFFE1E3E4),
    inverseOnSurface: Color(0xFF2E3132),
    inversePrimary: Color(0xFF00677E),
    scrim: Color(0xFF000000),
    statusSuccess: Color(0xFF5BD382),
    statusWarning: Color(0xFFFFB870),
    statusDanger: Color(0xFFFFB4AB),
    statusInfo: Color(0xFF85CFFF),
  );
}

/// The four BladeWatch status roles, exposed to widgets.
///
/// [BwColorTokens] has carried `statusSuccess/Warning/Danger/Info` since the
/// theme was ported — they mirror Android's `bladewatch_status_*` colours and are
/// parity-tested against that XML. But they were never mapped into `ColorScheme`
/// (which has no success/warning slot) and never registered as a theme
/// extension, so **no widget could reach them**.
///
/// The predictable happened: screens hand-rolled their own. `settings_daemons_screen.dart`
/// branched on `theme.brightness` to produce `0xFF6EE7A8` / `0xFFFFB870`, with a
/// comment saying "the theme has no success/warning role" — and `0xFFFFB870` is
/// `statusWarning` for dark, verbatim. The token was being reimplemented by hand,
/// one screen at a time, which is how a design system quietly stops being one.
///
/// Reach these with `Theme.of(context).extension<BwStatusColors>()!`.
@immutable
class BwStatusColors extends ThemeExtension<BwStatusColors> {
  final Color success, warning, danger, info;

  const BwStatusColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
  });

  factory BwStatusColors.from(BwColorTokens tokens) => BwStatusColors(
        success: tokens.statusSuccess,
        warning: tokens.statusWarning,
        danger: tokens.statusDanger,
        info: tokens.statusInfo,
      );

  @override
  BwStatusColors copyWith({Color? success, Color? warning, Color? danger, Color? info}) =>
      BwStatusColors(
        success: success ?? this.success,
        warning: warning ?? this.warning,
        danger: danger ?? this.danger,
        info: info ?? this.info,
      );

  @override
  BwStatusColors lerp(ThemeExtension<BwStatusColors>? other, double t) {
    if (other is! BwStatusColors) return this;
    return BwStatusColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
    );
  }
}
