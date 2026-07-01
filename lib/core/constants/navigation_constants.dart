/// GetX route names for the Flutter UI layer.
abstract final class AppRoutes {
  /// Main Menu route.
  ///
  /// Source: PRD.md §9 — Main Menu screen.
  static const String mainMenu = '/';

  /// Level Map route.
  ///
  /// Source: PRD.md §9 — Level Map screen.
  static const String levelMap = '/level-map';

  /// Gameplay route.
  ///
  /// Source: PRD.md §9 — Gameplay HUD screen.
  static const String gameplay = '/gameplay';

  /// Win Overlay route.
  ///
  /// Source: PRD.md §9 — Win Overlay screen.
  static const String winOverlay = '/win';

  /// Lose Overlay route.
  ///
  /// Source: PRD.md §9 — Lose Overlay screen.
  static const String loseOverlay = '/lose';
}
