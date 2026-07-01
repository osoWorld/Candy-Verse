/// Leaderboard row model in the data layer.
class LeaderboardEntry {
  /// Creates an immutable leaderboard entry.
  const LeaderboardEntry({
    required this.playerId,
    required this.chapter,
    required this.score,
    required this.updatedAt,
  });

  /// Player id, scoped by Supabase RLS to auth.uid().
  final String playerId;

  /// Chapter leaderboard bucket.
  final int chapter;

  /// Leaderboard score.
  final int score;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// Stable local key for Hive fallback storage.
  String get storageKey => '$chapter::$playerId';

  /// Parses a LeaderboardEntry from Supabase/Hive map data.
  ///
  /// Inputs: row map. Output: LeaderboardEntry. Side effects: none.
  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      playerId: _requiredString(map, 'player_id'),
      chapter: _requiredInt(map, 'chapter'),
      score: _requiredInt(map, 'score'),
      updatedAt: DateTime.parse(_requiredString(map, 'updated_at')),
    );
  }

  /// Converts this entry to Supabase/Hive map data.
  ///
  /// Inputs: none. Output: serializable map. Side effects: none.
  Map<String, dynamic> toMap() {
    return {
      'player_id': playerId,
      'chapter': chapter,
      'score': score,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  static String _requiredString(Map<String, dynamic> map, String fieldName) {
    final value = map[fieldName];
    if (value is String) {
      return value;
    }
    throw FormatException('LeaderboardEntry.$fieldName must be a string.');
  }

  static int _requiredInt(Map<String, dynamic> map, String fieldName) {
    final value = map[fieldName];
    if (value is int) {
      return value;
    }
    throw FormatException('LeaderboardEntry.$fieldName must be an int.');
  }
}
