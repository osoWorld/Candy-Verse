/// Per-level player progress row model in the data layer.
class PlayerProgressRecord {
  /// Creates an immutable player progress row.
  const PlayerProgressRecord({
    required this.playerId,
    required this.levelId,
    required this.stars,
    required this.bestScore,
    required this.completedAt,
  });

  /// Player id, scoped by Supabase RLS to auth.uid().
  final String playerId;

  /// Completed level id.
  final String levelId;

  /// Stars earned for the level, from 0 to 3.
  final int stars;

  /// Best score achieved for the level.
  final int bestScore;

  /// Completion timestamp.
  final DateTime completedAt;

  /// Stable local key for Hive fallback storage.
  String get storageKey => '$playerId::$levelId';

  /// Parses a PlayerProgressRecord from Supabase/Hive map data.
  ///
  /// Inputs: row map. Output: PlayerProgressRecord. Side effects: none.
  factory PlayerProgressRecord.fromMap(Map<String, dynamic> map) {
    return PlayerProgressRecord(
      playerId: _requiredString(map, 'player_id'),
      levelId: _requiredString(map, 'level_id'),
      stars: _requiredInt(map, 'stars'),
      bestScore: _requiredInt(map, 'best_score'),
      completedAt: DateTime.parse(_requiredString(map, 'completed_at')),
    );
  }

  /// Converts this row to Supabase/Hive map data.
  ///
  /// Inputs: none. Output: serializable map. Side effects: none.
  Map<String, dynamic> toMap() {
    return {
      'player_id': playerId,
      'level_id': levelId,
      'stars': stars,
      'best_score': bestScore,
      'completed_at': completedAt.toUtc().toIso8601String(),
    };
  }

  static String _requiredString(Map<String, dynamic> map, String fieldName) {
    final value = map[fieldName];
    if (value is String) {
      return value;
    }
    throw FormatException('PlayerProgressRecord.$fieldName must be a string.');
  }

  static int _requiredInt(Map<String, dynamic> map, String fieldName) {
    final value = map[fieldName];
    if (value is int) {
      return value;
    }
    throw FormatException('PlayerProgressRecord.$fieldName must be an int.');
  }
}
