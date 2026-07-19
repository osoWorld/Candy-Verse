import 'dart:ui';

/// Alchemy Kingdoms color tokens from the design layer.
abstract final class CandyAlchemyColors {
  /// Primary dark ink color.
  ///
  /// Source: DESIGN.md section 2 - alchemyInk token.
  static const Color alchemyInk = Color(0xFF2B174A);

  /// High-contrast sugar white.
  ///
  /// Source: DESIGN.md section 2 - sugarWhite token.
  static const Color sugarWhite = Color(0xFFFFF8ED);

  /// Candy gold used by stars and rewards.
  ///
  /// Source: DESIGN.md section 2 - candyGold token.
  static const Color candyGold = Color(0xFFFFC83D);

  /// Base Candy Cocoa color.
  ///
  /// Source: DESIGN.md section 4 - Cocoa rounded chocolate square.
  static const Color cocoa = Color(0xFF7A4328);

  /// Base Candy Citrus color.
  ///
  /// Source: DESIGN.md section 4 - Citrus faceted orange lozenge.
  static const Color citrus = Color(0xFFFFA929);

  /// Base Candy Berry color.
  ///
  /// Source: DESIGN.md section 4 - Berry jelly bean capsule.
  static const Color berry = Color(0xFFC43A8D);

  /// Base Candy Mint color.
  ///
  /// Source: DESIGN.md section 4 - Mint leaf gem.
  static const Color mint = Color(0xFF35C990);

  /// Base Candy Cream color.
  ///
  /// Source: DESIGN.md section 4 - Cream whipped swirl disk.
  static const Color cream = Color(0xFFFFF3DD);

  /// Playful global highlight pink.
  ///
  /// Source: DESIGN.md section 2 - popPink token.
  static const Color popPink = Color(0xFFFF5FA2);

  /// Reactive State Molten accent color.
  ///
  /// Source: DESIGN.md section 4 - Molten flame icon and ember glow.
  static const Color molten = Color(0xFFFF5A1F);

  /// Reactive State Frost accent color.
  ///
  /// Source: DESIGN.md section 4 - Frost snowflake and crystal facets.
  static const Color frost = Color(0xFFA8E0FF);

  /// Reactive State Living gloss color.
  ///
  /// Source: DESIGN.md section 4 - Living heart and bounce cue.
  static const Color living = Color(0x1FFFFFFF);

  /// Reactive State Living heart particle color.
  ///
  /// Source: DESIGN.md section 12 - Living heart pop.
  static const Color livingHeartParticle = Color(0xFFFF7AB8);

  /// Reactive State Syrup accent color.
  ///
  /// Source: DESIGN.md section 4 - Syrup droplet and glossy ripple.
  static const Color syrup = Color(0xFFD98C00);

  /// Syrup Lagoon teal palette token.
  ///
  /// Source: DESIGN.md section 2 - syrupTeal token.
  static const Color syrupTeal = Color(0xFF35D0C3);

  /// Reactive State Spice accent color.
  ///
  /// Source: DESIGN.md section 4 - Spice pepper and ember speckles.
  static const Color spice = Color(0xFFC2410C);

  /// Gameplay background behind the Flame board.
  ///
  /// Source: DESIGN.md section 2 - nightViolet gameplay accent.
  static const Color gameplayBackground = Color(0xFF130B24);

  /// Board tray fill color.
  ///
  /// Source: DESIGN.md section 6 - board tray background.
  static const Color boardTray = Color(0xFF4B2B67);

  /// Board cell fill color.
  ///
  /// Source: DESIGN.md section 6 - inner cell color.
  static const Color boardCell = Color(0xFF6C438A);

  /// Board cell bevel highlight.
  ///
  /// Source: DESIGN.md section 6 - cell bevel highlight.
  static const Color boardCellHighlight = Color(0xFFA97AD6);

  /// Board tray border color.
  ///
  /// Source: DESIGN.md section 6 - outer board stroke.
  static const Color boardTrayBorder = Color(0xFFFFD36A);

  /// Static tile highlight color.
  ///
  /// Source: DESIGN.md section 4 - glossy candy highlight.
  static const Color tileHighlight = Color(0x90FFFFFF);

  /// Static tile shadow color.
  ///
  /// Source: DESIGN.md section 4 - candy shadow offset.
  static const Color tileShadow = Color(0x66000000);

  /// Static icon background color for accessibility contrast.
  ///
  /// Source: DESIGN.md section 16 - state icon overlay must remain distinct.
  static const Color iconBackground = Color(0xCC130B24);

  /// Tempered Shatter white flash color.
  ///
  /// Source: DESIGN.md section 12 - match locations flash white.
  static const Color temperedShatterFlash = Color(0xFFFFFFFF);

  /// Tempered Shatter crack-line color.
  ///
  /// Source: DESIGN.md section 12 - bright crack line before row shatter.
  static const Color temperedShatterCrack = Color(0xFFFFFFFF);

  /// Chocolate blocker overlay color.
  ///
  /// Source: DESIGN.md section 7 - Cocoa Castle chocolate blockers.
  static const Color chocolateBlocker = Color(0xCC5A2D1A);

  /// Ice blocker overlay color.
  ///
  /// Source: DESIGN.md section 7 - Frosted Peaks ice blockers.
  static const Color iceBlocker = Color(0xCCBFEFFF);

  /// Wafer blocker overlay color.
  ///
  /// Source: DESIGN.md section 7 - Sugar Meadow wafer blockers.
  static const Color waferBlocker = Color(0xCCF2C16B);

  /// Syrup Lock blocker overlay color.
  ///
  /// Source: DESIGN.md section 7 - Syrup Lagoon locks.
  static const Color syrupLockBlocker = Color(0xCC8B5CF6);

  /// Spice Crate blocker overlay color.
  ///
  /// Source: DESIGN.md section 7 - Molten Bakery spice crates.
  static const Color spiceCrateBlocker = Color(0xCCE85D04);

  /// Blocker bevel stroke color.
  ///
  /// Source: DESIGN.md section 7 - blockers require readable cell boundaries.
  static const Color blockerStroke = Color(0xEFFFFFFF);

  /// Sugar sparkle core color.
  ///
  /// Source: DESIGN.md section 11 - standard matches emit sugar sparkles.
  static const Color sugarSparkle = Color(0xFFFFF8ED);

  /// Sugar sparkle warm edge color.
  ///
  /// Source: DESIGN.md section 11 - sparkle burst is celebratory and candy-like.
  static const Color sugarSparkleEdge = Color(0xFFFFC83D);
}
