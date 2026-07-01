import 'dart:ui';

/// Crystal Confection color tokens from the design layer.
abstract final class CandyAlchemyColors {
  /// Base Candy Cocoa color.
  ///
  /// Source: DESIGN.md §2 — Base Candy colors.
  static const Color cocoa = Color(0xFF6B3F2A);

  /// Base Candy Citrus color.
  ///
  /// Source: DESIGN.md §2 — Base Candy colors.
  static const Color citrus = Color(0xFFF5A623);

  /// Base Candy Berry color.
  ///
  /// Source: DESIGN.md §2 — Base Candy colors.
  static const Color berry = Color(0xFFA23B72);

  /// Base Candy Mint color.
  ///
  /// Source: DESIGN.md §2 — Base Candy colors.
  static const Color mint = Color(0xFF3FB28A);

  /// Base Candy Cream color.
  ///
  /// Source: DESIGN.md §2 — Base Candy colors.
  static const Color cream = Color(0xFFF4EDE4);

  /// Reactive State Molten accent color.
  ///
  /// Source: DESIGN.md §2 — Reactive State accent colors.
  static const Color molten = Color(0xFFFF5A1F);

  /// Reactive State Frost accent color.
  ///
  /// Source: DESIGN.md §2 — Reactive State accent colors.
  static const Color frost = Color(0xFFA8E0FF);

  /// Reactive State Living gloss color.
  ///
  /// Source: DESIGN.md §2 — Living 12% white gloss overlay.
  static const Color living = Color(0x1FFFFFFF);

  /// Reactive State Living heart particle color.
  ///
  /// Source: DESIGN.md §4 — Living particles are brighter and cheerful.
  static const Color livingHeartParticle = Color(0xFFFF7AB8);

  /// Reactive State Syrup accent color.
  ///
  /// Source: DESIGN.md §2 — Reactive State accent colors.
  static const Color syrup = Color(0xFFD98C00);

  /// Reactive State Spice accent color.
  ///
  /// Source: DESIGN.md §2 — Reactive State accent colors.
  static const Color spice = Color(0xFFC2410C);

  /// Gameplay background behind the static Flame board.
  ///
  /// Source: DESIGN.md §1 — Crystal Confection contrast background.
  static const Color gameplayBackground = Color(0xFF120F18);

  /// Static board tray fill color.
  ///
  /// Source: Step 4 — static board render surface.
  static const Color boardTray = Color(0xFF241B2E);

  /// Static board tray border color.
  ///
  /// Source: Step 4 — static board render surface.
  static const Color boardTrayBorder = Color(0x66FFFFFF);

  /// Static tile highlight color.
  ///
  /// Source: DESIGN.md §1 — glossy semi-translucent candy aesthetic.
  static const Color tileHighlight = Color(0x80FFFFFF);

  /// Static tile shadow color.
  ///
  /// Source: DESIGN.md §1 — glossy semi-translucent candy aesthetic.
  static const Color tileShadow = Color(0x66000000);

  /// Static icon background color for accessibility contrast.
  ///
  /// Source: DESIGN.md §10 — state icon overlay must remain distinguishable.
  static const Color iconBackground = Color(0xCC120F18);

  /// Tempered Shatter white flash color.
  ///
  /// Source: DESIGN.md §5 — match locations flash white.
  static const Color temperedShatterFlash = Color(0xFFFFFFFF);

  /// Tempered Shatter crack-line color.
  ///
  /// Source: DESIGN.md §5 — bright crack line before row shatter.
  static const Color temperedShatterCrack = Color(0xFFFFFFFF);
}
