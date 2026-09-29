/// Type-scale letter-tracking overrides ported from the `TextAppearance.
/// BladeWatch.*` styles in `app/src/main/res/values/themes_bladewatch.xml`
/// (the M3 Expressive tightening described in `docs/ui-ux-design-language.md`).
///
/// Android's `android:letterSpacing` is **em-relative** (a fraction of the
/// role's font size); Flutter's `TextStyle.letterSpacing` is in logical
/// pixels. [BladeWatchTheme] converts each value by multiplying against that
/// role's concrete font size from the M3 baseline `TextTheme` — see
/// `toPixels`.
abstract final class BwTypeTracking {
  static const double displaySmall = -0.02;
  static const double headlineLarge = -0.02;
  static const double headlineMedium = -0.015;
  static const double headlineSmall = -0.01;
  static const double titleLarge = -0.005;
  static const double titleMedium = 0;
  static const double labelLarge = 0.01;
  static const double labelMedium = 0.04;

  /// Converts an em-relative tracking value to Flutter's logical-pixel
  /// letterSpacing for a role whose resolved font size is [fontSize].
  static double toPixels(double em, double fontSize) => em * fontSize;

  /// M3 type-scale font sizes (the same spec values
  /// `TextAppearance.Material3.*` — the parent of every
  /// `TextAppearance.BladeWatch.*` override — resolves to on Android).
  /// `ThemeData(useMaterial3: true).textTheme` leaves `fontSize` null until a
  /// style is resolved inside a widget tree (`Theme.of(context)`), so
  /// [BladeWatchTheme] needs a concrete value up front to compute pixel
  /// letterSpacing eagerly at theme-build time; these are that value,
  /// verified against a real widget tree in `bladewatch_theme_test.dart`.
  static const double fontSizeDisplaySmall = 36;
  static const double fontSizeHeadlineLarge = 32;
  static const double fontSizeHeadlineMedium = 28;
  static const double fontSizeHeadlineSmall = 24;
  static const double fontSizeTitleLarge = 22;
  static const double fontSizeTitleMedium = 16;
  static const double fontSizeLabelLarge = 14;
  static const double fontSizeLabelMedium = 12;

  /// {`TextAppearance.BladeWatch.<Role>` style name : em value}, for
  /// cross-checking against themes_bladewatch.xml in tests.
  static const Map<String, double> xmlEmValues = {
    'DisplaySmall': displaySmall,
    'HeadlineLarge': headlineLarge,
    'HeadlineMedium': headlineMedium,
    'HeadlineSmall': headlineSmall,
    'TitleLarge': titleLarge,
    'TitleMedium': titleMedium,
    'LabelLarge': labelLarge,
    'LabelMedium': labelMedium,
  };
}
