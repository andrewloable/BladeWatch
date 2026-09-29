/// Shape and spacing tokens ported from
/// `app/src/main/res/values/dimens_bladewatch.xml` (`card_*`, page padding,
/// grid tile, icon sizes) and the two `ShapeAppearance.BladeWatch.*` corner
/// sizes in `app/src/main/res/values/themes.xml`. Android `dp` and Flutter's
/// logical pixels are the same density-independent unit, so values carry
/// over 1:1 with no conversion.
abstract final class BwDimens {
  static const double pagePaddingHorizontal = 24;
  static const double pagePaddingTop = 20;
  static const double pagePaddingBottom = 24;

  static const double cardGapVertical = 12;
  static const double cardGapHorizontal = 12;
  static const double cardGapHorizontalHalf = 6;

  static const double cardRadiusXs = 4;
  static const double cardRadiusSm = 8;
  static const double cardRadiusStandard = 20;
  static const double cardRadiusHero = 24;
  static const double cardRadiusDialog = 28;
  static const double cardRadiusAccent = 14;

  static const double cardPaddingStandard = 20;
  static const double cardPaddingHero = 24;

  static const double gridTileMinHeight = 128;

  static const double cardIconStandard = 24;
  static const double cardIconService = 32;
  static const double cardIconHero = 56;

  static const double sectionOverlineTop = 12;
  static const double sectionOverlineBottom = 8;

  /// `ShapeAppearance.BladeWatch.SmallComponent` / `LargeComponent` in
  /// `values/themes.xml` — not `<dimen>` entries, asserted separately.
  static const double shapeSmallComponent = 8;
  static const double shapeLargeComponent = 16;

  /// {dimens_bladewatch.xml resource name : value}, for cross-checking
  /// against the XML source of truth in tests.
  static const Map<String, double> xmlNameMap = {
    'page_padding_horizontal': pagePaddingHorizontal,
    'page_padding_top': pagePaddingTop,
    'page_padding_bottom': pagePaddingBottom,
    'card_gap_vertical': cardGapVertical,
    'card_gap_horizontal': cardGapHorizontal,
    'card_gap_horizontal_half': cardGapHorizontalHalf,
    'card_radius_xs': cardRadiusXs,
    'card_radius_sm': cardRadiusSm,
    'card_radius_standard': cardRadiusStandard,
    'card_radius_hero': cardRadiusHero,
    'card_radius_dialog': cardRadiusDialog,
    'card_radius_accent': cardRadiusAccent,
    'card_padding_standard': cardPaddingStandard,
    'card_padding_hero': cardPaddingHero,
    'grid_tile_min_height': gridTileMinHeight,
    'card_icon_standard': cardIconStandard,
    'card_icon_service': cardIconService,
    'card_icon_hero': cardIconHero,
    'section_overline_top': sectionOverlineTop,
    'section_overline_bottom': sectionOverlineBottom,
  };
}
