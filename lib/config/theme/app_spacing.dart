// lib/config/theme/app_spacing.dart

class AppSpacing {
  // This class is not meant to be instantiated.
  AppSpacing._();

  // ============================================================
  // SPACING SCALE (8pt grid system)
  // ============================================================

  static const double xs = 4.0; // Extra small
  static const double sm = 8.0; // Small
  static const double md = 12.0; // Medium
  static const double lg = 16.0; // Large
  static const double xl = 24.0; // Extra large
  static const double xxl = 32.0; // 2X Extra large
  static const double xxxl = 48.0; // 3X Extra large
  static const double huge = 64.0; // Huge

  // ============================================================
  // SEMANTIC SPACING (Contextual names)
  // ============================================================

  // Padding
  static const double paddingXs = xs;
  static const double paddingSm = sm;
  static const double paddingMd = md;
  static const double paddingLg = lg;
  static const double paddingXl = xl;

  // Margins
  static const double marginXs = xs;
  static const double marginSm = sm;
  static const double marginMd = md;
  static const double marginLg = lg;
  static const double marginXl = xl;

  // Screen padding (horizontal)
  static const double screenPaddingHorizontal = lg; // 16
  static const double screenPaddingVertical = lg; // 16

  // Card padding
  static const double cardPadding = lg; // 16
  static const double cardPaddingLarge = xl; // 24

  // Section spacing
  static const double sectionSpacing = xl; // 24
  static const double sectionSpacingLarge = xxl; // 32

  // Element spacing (between elements)
  static const double elementSpacing = sm; // 8
  static const double elementSpacingMd = md; // 12
  static const double elementSpacingLg = lg; // 16

  // List item spacing
  static const double listItemSpacing = md; // 12
  static const double listItemPadding = lg; // 16

  // Button padding
  static const double buttonPaddingHorizontal = xl; // 24
  static const double buttonPaddingVertical = md; // 12
  static const double buttonPaddingSmallHorizontal = lg; // 16
  static const double buttonPaddingSmallVertical = sm; // 8

  // Icon spacing
  static const double iconSpacing = sm; // 8
  static const double iconMargin = md; // 12

  // ============================================================
  // BORDER RADIUS
  // ============================================================

  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;
  static const double radiusRound = 999.0; // For pills/fully rounded

  // Semantic radius
  static const double buttonRadius = radiusMd; // 12
  static const double cardRadius = radiusLg; // 16
  static const double inputRadius = radiusMd; // 12
  static const double dialogRadius = radiusLg; // 16
  static const double sheetRadius = radiusXl; // 20

  // ============================================================
  // ELEVATION/SHADOWS
  // ============================================================

  static const double elevationNone = 0.0;
  static const double elevationXs = 1.0;
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;
  static const double elevationXl = 12.0;
  static const double elevationXxl = 16.0;

  // ============================================================
  // ICON SIZES
  // ============================================================

  static const double iconXs = 16.0;
  static const double iconSm = 20.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 40.0;
  static const double iconXxl = 48.0;
  static const double iconHuge = 64.0;

  // ============================================================
  // BUTTON HEIGHTS
  // ============================================================

  static const double buttonHeightSmall = 36.0;
  static const double buttonHeight = 48.0;
  static const double buttonHeightLarge = 56.0;

  // ============================================================
  // APP BAR
  // ============================================================

  static const double appBarHeight = 56.0;
  static const double appBarElevation = 0.0; // Flat design

  // ============================================================
  // BOTTOM NAV
  // ============================================================

  static const double bottomNavHeight = 60.0;
  static const double bottomNavIconSize = iconMd; // 24

  // ============================================================
  // FAB (Floating Action Button)
  // ============================================================

  static const double fabSize = 56.0;
  static const double fabSmallSize = 48.0;
  static const double fabMini = 40.0;

  // ============================================================
  // DIVIDER
  // ============================================================

  static const double dividerThickness = 1.0;
  static const double dividerIndent = lg; // 16

  // ============================================================
  // ANIMATION DISTANCES (for slide transitions)
  // ============================================================

  static const double slideDistanceSm = 20.0;
  static const double slideDistanceMd = 40.0;
  static const double slideDistanceLg = 60.0;
}
