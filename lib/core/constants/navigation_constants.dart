/// GetX route names for the Flutter UI layer.
abstract final class AppRoutes {
  /// Main Menu route.
  ///
  /// Source: PRD.md section 5 - app starts at Main Menu.
  static const String mainMenu = '/';

  /// Kingdom Map route.
  ///
  /// Source: PRD.md section 5 - Main Menu opens Kingdom Map.
  static const String kingdomMap = '/level-map';

  /// Compatibility alias for the prototype Level Map route.
  ///
  /// Source: ARCHITECTURE.md section 4 - legacy level_map may redirect.
  static const String levelMap = kingdomMap;

  /// Gameplay route.
  ///
  /// Source: PRD.md section 5 - modal Play opens Gameplay.
  static const String gameplay = '/gameplay';

  /// Win Overlay route.
  ///
  /// Source: PRD.md section 5 - Gameplay can end in Win Overlay.
  static const String winOverlay = '/win';

  /// Lose Overlay route.
  ///
  /// Source: PRD.md section 5 - Gameplay can end in Lose Overlay.
  static const String loseOverlay = '/lose';
}
