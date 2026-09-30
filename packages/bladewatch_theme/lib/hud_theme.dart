import 'package:flutter/material.dart';

import 'bladewatch_theme.dart';
import 'color_tokens.dart';

/// The cyberpunk HUD skin for the in-car UI (`docs/ui-ux-design-language.md`, "HUD skin").
///
/// Additive to the M3 tokens in `packages/bladewatch_theme`: those are shared with the
/// companion app and parity-tested against the Android XML, so none of this belongs in
/// `BwColorTokens`. Values come from the owner's reference HTML in
/// `docs/design/hud-reference/`; the Tailwind colour each one came from is named beside it.
/// Reach it with [BwHud.of].
@immutable
class BwHud extends ThemeExtension<BwHud> {
  /// Space Mono (SIL OFL 1.1), bundled by THIS package (`assets/fonts/`, declared in its pubspec), so
  /// its family is addressed through the package path from either app.
  static const String fontFamily = 'packages/bladewatch_theme/SpaceMono';

  /// `rounded-xl` (the summary card) and `rounded` (tiles, chips, rail items).
  static const double radiusPanel = 12;
  static const double radiusSmall = 4;

  final Color pageBackground, railBackground, railBorder;
  final Color panel, panelPressed;

  /// Left to right.
  final List<Color> summaryGradient;

  /// `.hud-border-cyan` on the summary card.
  final Color cardBorder;

  /// `border-cyan-500/30` (tiles) and `/40` (recording chip, View all).
  final Color panelBorder, panelBorderStrong;

  /// The rule under the page title (`border-cyan-500/20`, both modes) and the lines inside the
  /// summary card (cyan at 20% in dark, slate-100 in light).
  final Color titleRule, cardDivider;

  final Color accent, accentBright, iconAccent, dot, dotGlow, magenta, magentaBorder;

  /// A caution that is neither information (cyan) nor attention (magenta): a low tyre pressure, a
  /// service that is up but degraded. Tailwind amber-400 in dark, amber-700 in light.
  final Color warning;

  /// `hud-glow-cyan` / `hud-glow-magenta`. Null in light: the light design has no text glow.
  final Shadow? glowCyan, glowMagenta;

  final Color textPrimary, textSecondary, statLabel, tileLabel, chipBorder;

  /// Drive Time, the LIVE tile and the ONLINE tile value: white in dark (with a glow), coloured
  /// in light.
  final Color driveTimeValue, liveValue, onlineValue;

  /// Fill of the "View all trips" button.
  final Color viewAllFill;

  final Color navInactive, navActiveLabel, navActiveIcon, navActiveBorder;

  /// Top to bottom.
  final List<Color> navActiveGradient;

  final List<BoxShadow> railShadow, navActiveShadow, cardShadow, tileShadow;

  /// The two blurred blobs in the summary card's corners (approximated with radial gradients).
  final Color cornerGlowCyan, cornerGlowMagenta;

  /// Dark labels are normal weight, light labels are bold.
  final FontWeight labelWeight;

  const BwHud({
    required this.pageBackground,
    required this.railBackground,
    required this.railBorder,
    required this.panel,
    required this.panelPressed,
    required this.summaryGradient,
    required this.cardBorder,
    required this.panelBorder,
    required this.panelBorderStrong,
    required this.titleRule,
    required this.cardDivider,
    required this.accent,
    required this.accentBright,
    required this.iconAccent,
    required this.dot,
    required this.dotGlow,
    required this.magenta,
    required this.magentaBorder,
    required this.warning,
    required this.glowCyan,
    required this.glowMagenta,
    required this.textPrimary,
    required this.textSecondary,
    required this.statLabel,
    required this.tileLabel,
    required this.chipBorder,
    required this.driveTimeValue,
    required this.liveValue,
    required this.onlineValue,
    required this.viewAllFill,
    required this.navInactive,
    required this.navActiveLabel,
    required this.navActiveIcon,
    required this.navActiveBorder,
    required this.navActiveGradient,
    required this.railShadow,
    required this.navActiveShadow,
    required this.cardShadow,
    required this.tileShadow,
    required this.cornerGlowCyan,
    required this.cornerGlowMagenta,
    required this.labelWeight,
  });

  /// From `dashboard-dark.html`. Tailwind v3: cyan-300 #67E8F9, cyan-400 #22D3EE, cyan-500
  /// #06B6D4, cyan-950 #083344, teal-950 #042F2E, slate-300 #CBD5E1, slate-400 #94A3B8.
  static const dark = BwHud(
    pageBackground: Color(0xFF05070B), // brand.dark
    railBackground: Color(0xFF05080F), // bg-[#05080f]
    railBorder: Color(0x4D06B6D4), // border-cyan-500/30
    panel: Color(0xFF0A1018), // brand.card
    panelPressed: Color(0xFF0F1C29), // brand.cardHover
    summaryGradient: [Color(0xCC042F2E), Color(0xFF0A1018), Color(0xFF091722)],
    cardBorder: Color(0x6600F3FF), // rgba(0,243,255,.4)
    panelBorder: Color(0x4D06B6D4),
    panelBorderStrong: Color(0x6606B6D4), // border-cyan-500/40
    titleRule: Color(0x3306B6D4), // border-cyan-500/20
    cardDivider: Color(0x3306B6D4),
    accent: Color(0xFF22D3EE), // text-cyan-400
    accentBright: Color(0xFF67E8F9), // text-cyan-300
    iconAccent: Color(0xFF22D3EE),
    dot: Color(0xFF22D3EE), // bg-cyan-400
    dotGlow: Color(0xFF00F3FF),
    magenta: Color(0xFFFF0055), // brand.magenta
    magentaBorder: Color(0x80FF0055), // border-brand-magenta/50
    warning: Color(0xFFFBBF24), // amber-400
    glowCyan: Shadow(color: Color(0x9900F3FF), blurRadius: 8), // rgba(0,243,255,.6)
    glowMagenta: Shadow(color: Color(0x99FF0055), blurRadius: 8),
    textPrimary: Color(0xFFFFFFFF),
    textSecondary: Color(0xFFCBD5E1), // text-slate-300
    statLabel: Color(0xCC22D3EE), // text-cyan-400/80
    tileLabel: Color(0xB322D3EE), // text-cyan-400/70
    chipBorder: Color(0x4D06B6D4),
    driveTimeValue: Color(0xFFFFFFFF),
    liveValue: Color(0xFFFFFFFF),
    onlineValue: Color(0xFFFFFFFF),
    viewAllFill: Color(0x80083344), // bg-cyan-950/50
    navInactive: Color(0xFF94A3B8), // text-slate-400
    navActiveLabel: Color(0xFF22D3EE),
    navActiveIcon: Color(0xFF22D3EE),
    navActiveBorder: Color(0xFF22D3EE), // border-cyan-400
    navActiveGradient: [Color(0xCC083344), Color(0xFF0A1018)], // from-cyan-950/80 to-brand-card
    railShadow: [BoxShadow(color: Color(0x80000000), offset: Offset(5, 0), blurRadius: 15)],
    navActiveShadow: [BoxShadow(color: Color(0x4D00F3FF), blurRadius: 12)],
    cardShadow: [BoxShadow(color: Color(0x2600F3FF), blurRadius: 10)], // rgba(0,243,255,.15)
    tileShadow: [],
    cornerGlowCyan: Color(0x1A06B6D4), // bg-cyan-500/10
    cornerGlowMagenta: Color(0x1AFF0055), // bg-brand-magenta/10
    labelWeight: FontWeight.w400,
  );

  /// From `dashboard-light.html`. Tailwind v3: cyan-50 #ECFEFF, cyan-400 #22D3EE, cyan-500
  /// #06B6D4, cyan-600 #0891B2, cyan-700 #0E7490, slate-100 #F1F5F9, slate-200 #E2E8F0,
  /// slate-500 #64748B, slate-700 #334155.
  static const light = BwHud(
    pageBackground: Color(0xFFF4F6F9),
    railBackground: Color(0xFFFFFFFF),
    railBorder: Color(0x3306B6D4), // border-cyan-500/20
    panel: Color(0xFFFFFFFF),
    panelPressed: Color(0xFFF8FAFC), // hover:bg-slate-50
    summaryGradient: [Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
    cardBorder: Color(0x6600B8D4), // rgba(0,184,212,.4)
    panelBorder: Color(0x4D06B6D4),
    panelBorderStrong: Color(0x6606B6D4),
    titleRule: Color(0x3306B6D4),
    cardDivider: Color(0xFFF1F5F9), // border-slate-100
    accent: Color(0xFF0E7490), // text-cyan-700
    accentBright: Color(0xFF0E7490),
    iconAccent: Color(0xFF0891B2), // text-cyan-600
    dot: Color(0xFF06B6D4), // bg-cyan-500
    dotGlow: Color(0xFF00B8D4),
    magenta: Color(0xFFD81B60),
    magentaBorder: Color(0x80D81B60),
    warning: Color(0xFFB45309), // amber-700
    glowCyan: null,
    glowMagenta: null,
    textPrimary: Color(0xFF0D0D16), // brand.darkText
    textSecondary: Color(0xFF334155), // text-slate-700
    statLabel: Color(0xFF64748B), // text-slate-500
    tileLabel: Color(0xFF64748B),
    chipBorder: Color(0xFFE2E8F0), // border-slate-200
    driveTimeValue: Color(0xFFD81B60),
    liveValue: Color(0xFFD81B60),
    onlineValue: Color(0xFF0E7490),
    viewAllFill: Color(0xFFECFEFF), // bg-cyan-50
    navInactive: Color(0xFF64748B),
    navActiveLabel: Color(0xFF0E7490),
    navActiveIcon: Color(0xFF0891B2),
    navActiveBorder: Color(0xFF22D3EE),
    navActiveGradient: [Color(0xFFECFEFF), Color(0xFFFFFFFF)], // from-cyan-50 to-white
    railShadow: [BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 2)],
    navActiveShadow: [BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 2)],
    cardShadow: [BoxShadow(color: Color(0x1400B8D4), offset: Offset(0, 4), blurRadius: 20)],
    tileShadow: [BoxShadow(color: Color(0x0D000000), offset: Offset(0, 1), blurRadius: 2)],
    cornerGlowCyan: Color(0x0D06B6D4), // bg-cyan-500/5
    cornerGlowMagenta: Color(0x0DD81B60),
    labelWeight: FontWeight.w700,
  );

  /// The theme's extension, or the const for the theme's brightness when none is installed, so a
  /// test that pumps a bare `MaterialApp(theme: BladeWatchTheme.light())` still renders.
  static BwHud of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<BwHud>() ?? (theme.brightness == Brightness.dark ? dark : light);
  }

  /// One HUD text style. [size] and [lineHeight] are dp (the reference's CSS px), [em] is Tailwind's
  /// tracking as a fraction of [size]. The half-leading is split evenly, as CSS does.
  static TextStyle text(
    double size, {
    required double lineHeight,
    Color? color,
    FontWeight weight = FontWeight.w400,
    double em = 0,
    List<Shadow>? shadows,
  }) => TextStyle(
    fontFamily: fontFamily,
    fontSize: size,
    height: lineHeight / size,
    leadingDistribution: TextLeadingDistribution.even,
    fontWeight: weight,
    letterSpacing: em * size,
    color: color,
    shadows: shadows,
  );

  static final Map<Brightness, ThemeData> _themeCache = {};

  /// The complete HUD `ThemeData` for [brightness]: a `ColorScheme` mapped from these tokens, the type
  /// scale of `docs/ui-ux-design-language.md` in Space Mono, and a component theme for every stock
  /// widget the screens use, so a screen that is built from Material widgets reads as HUD without being
  /// rewritten. Built on `BladeWatchTheme` (so `BwStatusColors` survives, re-mapped to HUD colours) and
  /// cached: `Theme(data: ...)` in a build method must not rebuild 40 component themes.
  static ThemeData themeData(Brightness brightness) =>
      _themeCache.putIfAbsent(brightness, () => _buildThemeData(brightness));

  static ThemeData _buildThemeData(Brightness brightness) {
    final hud = brightness == Brightness.dark ? dark : light;
    final base = brightness == Brightness.dark ? BladeWatchTheme.dark() : BladeWatchTheme.light();
    Color over(Color top, Color bottom) => Color.alphaBlend(top, bottom);

    // The translucent HUD tokens, flattened onto the panel they sit on, for the ColorScheme (which wants
    // opaque roles) and for `BorderSide`s.
    final border = over(hud.panelBorder, hud.panel);
    final borderStrong = over(hud.panelBorderStrong, hud.panel);
    final accentSoft = over(hud.viewAllFill, hud.panel);
    final magentaSoft = over(hud.magenta.withValues(alpha: 0.15), hud.panel);
    final disabledText = hud.textSecondary.withValues(alpha: 0.38);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: hud.accent,
      onPrimary: hud.pageBackground,
      primaryContainer: accentSoft,
      onPrimaryContainer: hud.accent,
      secondary: hud.accentBright,
      onSecondary: hud.pageBackground,
      secondaryContainer: accentSoft,
      onSecondaryContainer: hud.accent,
      tertiary: hud.magenta,
      onTertiary: hud.pageBackground,
      tertiaryContainer: magentaSoft,
      onTertiaryContainer: hud.magenta,
      error: hud.magenta,
      onError: hud.pageBackground,
      errorContainer: magentaSoft,
      onErrorContainer: hud.magenta,
      surface: hud.pageBackground,
      onSurface: hud.textPrimary,
      onSurfaceVariant: hud.textSecondary,
      surfaceDim: hud.pageBackground,
      surfaceBright: hud.panelPressed,
      surfaceContainerLowest: hud.pageBackground,
      surfaceContainerLow: hud.panel,
      surfaceContainer: hud.panel,
      surfaceContainerHigh: hud.panelPressed,
      surfaceContainerHighest: hud.panelPressed,
      outline: borderStrong,
      outlineVariant: border,
      inverseSurface: hud.textPrimary,
      onInverseSurface: hud.pageBackground,
      inversePrimary: hud.accent,
      scrim: const Color(0xFF000000),
      shadow: const Color(0xFF000000),
      surfaceTint: const Color(0x00000000),
    );

    // Space Mono type scale. Colour is applied below so a widget that asks for onSurfaceVariant still can.
    final textTheme = TextTheme(
      displayLarge: text(30, lineHeight: 36, weight: FontWeight.w700, em: -0.025),
      displayMedium: text(30, lineHeight: 36, weight: FontWeight.w700, em: -0.025),
      displaySmall: text(30, lineHeight: 36, weight: FontWeight.w700, em: -0.025),
      headlineLarge: text(24, lineHeight: 32, weight: FontWeight.w700, em: -0.025),
      headlineMedium: text(24, lineHeight: 32, weight: FontWeight.w700, em: -0.025),
      headlineSmall: text(20, lineHeight: 28, weight: FontWeight.w700, em: -0.025),
      titleLarge: text(20, lineHeight: 28, weight: FontWeight.w700, em: 0.05),
      titleMedium: text(16, lineHeight: 24, weight: FontWeight.w700),
      titleSmall: text(14, lineHeight: 20, weight: FontWeight.w700, em: 0.05),
      bodyLarge: text(16, lineHeight: 24),
      bodyMedium: text(14, lineHeight: 20),
      bodySmall: text(12, lineHeight: 16),
      labelLarge: text(12, lineHeight: 16, weight: FontWeight.w700, em: 0.05),
      labelMedium: text(12, lineHeight: 16, weight: hud.labelWeight, em: 0.05),
      labelSmall: text(10, lineHeight: 15, weight: hud.labelWeight, em: 0.05),
    ).apply(bodyColor: hud.textPrimary, displayColor: hud.textPrimary);

    final smallShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall));
    RoundedRectangleBorder boxed(Color side, [double radius = radiusSmall]) => RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: side),
    );

    OutlineInputBorder inputBorder(Color side) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusSmall),
      borderSide: BorderSide(color: side),
    );
    final inputTheme = InputDecorationTheme(
      filled: true,
      fillColor: hud.panel,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      labelStyle: text(12, lineHeight: 16, weight: FontWeight.w700, em: 0.05, color: hud.textSecondary),
      floatingLabelStyle: text(12, lineHeight: 16, weight: FontWeight.w700, em: 0.05, color: hud.accent),
      hintStyle: text(14, lineHeight: 20, color: hud.textSecondary.withValues(alpha: 0.6)),
      helperStyle: text(10, lineHeight: 15, color: hud.tileLabel),
      errorStyle: text(10, lineHeight: 15, color: hud.magenta),
      border: inputBorder(border),
      enabledBorder: inputBorder(border),
      focusedBorder: inputBorder(hud.accent),
      errorBorder: inputBorder(hud.magenta),
      focusedErrorBorder: inputBorder(hud.magenta),
      disabledBorder: inputBorder(over(hud.panelBorder.withValues(alpha: 0.5), hud.panel)),
    );

    ButtonStyle button({
      required Color background,
      required Color foreground,
      required BorderSide side,
      List<Shadow>? shadows,
    }) => ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? hud.panel : background,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.disabled) ? disabledText : foreground,
      ),
      overlayColor: WidgetStatePropertyAll(hud.panelPressed.withValues(alpha: 0.6)),
      side: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled) ? BorderSide(color: border) : side),
      shape: WidgetStatePropertyAll(smallShape),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Color(0x00000000)),
      surfaceTintColor: const WidgetStatePropertyAll(Color(0x00000000)),
      textStyle: WidgetStatePropertyAll(text(12, lineHeight: 16, weight: FontWeight.w700, em: 0.05)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
      minimumSize: const WidgetStatePropertyAll(Size(0, 36)),
    );

    WidgetStateProperty<Color?> byToggle(Color on, Color off) =>
        WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? on : off);

    final status = BwStatusColors(success: hud.dot, warning: hud.warning, danger: hud.magenta, info: hud.accent);
    final extensions = [
      ...base.extensions.values.where((e) => e is! BwStatusColors && e is! BwHud),
      status,
      hud,
    ];

    return base.copyWith(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: hud.pageBackground,
      canvasColor: hud.panel,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      dividerColor: hud.cardDivider,
      splashColor: hud.panelPressed,
      highlightColor: hud.panelPressed.withValues(alpha: 0.6),
      hoverColor: const Color(0x00000000),
      iconTheme: IconThemeData(color: hud.textSecondary),
      primaryIconTheme: IconThemeData(color: hud.textSecondary),
      extensions: extensions,
      appBarTheme: AppBarTheme(
        backgroundColor: hud.pageBackground,
        foregroundColor: hud.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: const Color(0x00000000),
        titleTextStyle: text(
          20,
          lineHeight: 28,
          weight: FontWeight.w700,
          em: 0.05,
          color: hud.accent,
          shadows: hudGlowList(hud.glowCyan),
        ),
      ),
      cardTheme: CardThemeData(
        color: hud.panel,
        elevation: 0,
        shadowColor: const Color(0x00000000),
        surfaceTintColor: const Color(0x00000000),
        shape: boxed(hud.panelBorder),
        clipBehavior: Clip.none,
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: hud.panel,
        elevation: 0,
        shadowColor: const Color(0x00000000),
        surfaceTintColor: const Color(0x00000000),
        shape: boxed(hud.cardBorder, radiusPanel),
        titleTextStyle: text(
          20,
          lineHeight: 28,
          weight: FontWeight.w700,
          em: 0.05,
          color: hud.accent,
          shadows: hudGlowList(hud.glowCyan),
        ),
        contentTextStyle: text(14, lineHeight: 20, color: hud.textPrimary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: hud.panel,
        modalBackgroundColor: hud.panel,
        elevation: 0,
        surfaceTintColor: const Color(0x00000000),
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(radiusPanel)),
          side: BorderSide(color: hud.cardBorder),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: hud.panelPressed,
        contentTextStyle: text(12, lineHeight: 16, weight: FontWeight.w700, em: 0.05, color: hud.textPrimary),
        actionTextColor: hud.accent,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: boxed(hud.panelBorderStrong),
      ),
      dividerTheme: DividerThemeData(color: hud.cardDivider, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: hud.iconAccent,
        textColor: hud.textPrimary,
        selectedColor: hud.accent,
        selectedTileColor: accentSoft,
        shape: smallShape,
        titleTextStyle: text(14, lineHeight: 20, weight: FontWeight.w700, color: hud.textPrimary),
        subtitleTextStyle: text(12, lineHeight: 16, color: hud.textSecondary),
        leadingAndTrailingTextStyle: text(12, lineHeight: 16, weight: FontWeight.w700, color: hud.textSecondary),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: byToggle(hud.accent, hud.textSecondary),
        trackColor: byToggle(accentSoft, hud.panel),
        trackOutlineColor: byToggle(hud.accent, border),
        trackOutlineWidth: const WidgetStatePropertyAll(1),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? hud.accent : null),
        checkColor: WidgetStatePropertyAll(hud.pageBackground),
        side: WidgetStateBorderSide.resolveWith(
          (s) => BorderSide(color: s.contains(WidgetState.selected) ? hud.accent : borderStrong, width: 1.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      ),
      radioTheme: RadioThemeData(fillColor: byToggle(hud.accent, hud.textSecondary)),
      sliderTheme: SliderThemeData(
        activeTrackColor: hud.accent,
        inactiveTrackColor: border,
        thumbColor: hud.accent,
        overlayColor: hud.accent.withValues(alpha: 0.15),
        valueIndicatorColor: hud.panelPressed,
        valueIndicatorTextStyle: text(12, lineHeight: 16, weight: FontWeight.w700, color: hud.textPrimary),
        trackHeight: 4,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: hud.accent,
        linearTrackColor: border,
        circularTrackColor: border,
      ),
      inputDecorationTheme: inputTheme,
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: inputTheme,
        textStyle: text(14, lineHeight: 20, color: hud.textPrimary),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(hud.panel),
          surfaceTintColor: const WidgetStatePropertyAll(Color(0x00000000)),
          shape: WidgetStatePropertyAll(boxed(hud.panelBorderStrong)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: hud.panel,
        surfaceTintColor: const Color(0x00000000),
        shape: boxed(hud.panelBorderStrong),
        textStyle: text(14, lineHeight: 20, color: hud.textPrimary),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: byToggle(accentSoft, hud.panel),
          foregroundColor: byToggle(hud.accent, hud.textSecondary),
          side: WidgetStateProperty.resolveWith(
            (s) => BorderSide(color: s.contains(WidgetState.selected) ? hud.accent : border),
          ),
          shape: WidgetStatePropertyAll(smallShape),
          textStyle: WidgetStatePropertyAll(text(12, lineHeight: 16, weight: FontWeight.w700, em: 0.05)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: hud.panel,
        selectedColor: accentSoft,
        disabledColor: hud.panel,
        checkmarkColor: hud.accent,
        side: WidgetStateBorderSide.resolveWith(
          (s) => BorderSide(color: s.contains(WidgetState.selected) ? hud.accent : hud.chipBorder),
        ),
        shape: smallShape,
        labelStyle: text(12, lineHeight: 16, weight: FontWeight.w700, em: 0.05, color: hud.textSecondary),
        secondaryLabelStyle: text(12, lineHeight: 16, weight: FontWeight.w700, em: 0.05, color: hud.accent),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        elevation: 0,
        pressElevation: 0,
        surfaceTintColor: const Color(0x00000000),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: button(
          background: accentSoft,
          foreground: hud.accent,
          side: BorderSide(color: hud.accent),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: button(
          background: hud.panel,
          foreground: hud.textSecondary,
          side: BorderSide(color: hud.chipBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: button(
          background: hud.panel,
          foreground: hud.accent,
          side: BorderSide(color: hud.chipBorder),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: button(background: const Color(0x00000000), foreground: hud.accent, side: BorderSide.none).copyWith(
          backgroundColor: const WidgetStatePropertyAll(Color(0x00000000)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accentSoft,
        foregroundColor: hud.accent,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: boxed(hud.accent),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? disabledText : hud.iconAccent,
          ),
          overlayColor: WidgetStatePropertyAll(hud.panelPressed.withValues(alpha: 0.6)),
          shape: WidgetStatePropertyAll(smallShape),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        indicatorColor: hud.accent,
        labelColor: hud.accent,
        unselectedLabelColor: hud.textSecondary,
        labelStyle: text(12, lineHeight: 16, weight: FontWeight.w700, em: 0.05),
        unselectedLabelStyle: text(12, lineHeight: 16, weight: FontWeight.w700, em: 0.05),
        dividerColor: hud.cardDivider,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: hud.panelPressed,
          borderRadius: BorderRadius.circular(radiusSmall),
          border: Border.all(color: hud.panelBorderStrong),
        ),
        textStyle: text(12, lineHeight: 16, color: hud.textPrimary),
      ),
      scrollbarTheme: ScrollbarThemeData(thumbColor: WidgetStatePropertyAll(hud.accent.withValues(alpha: 0.4))),
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: hud.accent,
        collapsedIconColor: hud.textSecondary,
        textColor: hud.accent,
        collapsedTextColor: hud.textPrimary,
        shape: const Border(),
        collapsedShape: const Border(),
      ),
    );
  }

  /// `[shadow]` as a text-shadow list, or null when the mode has no glow.
  static List<Shadow>? hudGlowList(Shadow? shadow) => shadow == null ? null : [shadow];

  // ponytail: a const value object with two instances; nothing copies it with overrides.
  @override
  BwHud copyWith() => this;

  // ponytail: modes switch discretely; interpolating 40 tokens buys nothing visible.
  @override
  BwHud lerp(ThemeExtension<BwHud>? other, double t) => other is BwHud && t >= 0.5 ? other : this;
}
