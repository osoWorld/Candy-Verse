/// Supabase table names for the data layer.
abstract final class SupabaseTables {
  /// Player progress table.
  ///
  /// Source: ARCHITECTURE.md §10 — player_progress schema.
  static const String playerProgress = 'player_progress';

  /// Leaderboards table.
  ///
  /// Source: ARCHITECTURE.md §10 — leaderboards schema.
  static const String leaderboards = 'leaderboards';

  /// Purchases table.
  ///
  /// Source: ARCHITECTURE.md §10 — purchases schema.
  static const String purchases = 'purchases';

  /// Levels table.
  ///
  /// Source: ARCHITECTURE.md §10 — levels schema.
  static const String levels = 'levels';
}
