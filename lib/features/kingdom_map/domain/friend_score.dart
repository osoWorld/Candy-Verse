/// Friend or fallback score shown before a level starts.
class FriendScore {
  /// Creates an immutable friend score row.
  const FriendScore({required this.name, required this.score});

  /// Display name for the friend score row.
  final String name;

  /// Best score shown for this level.
  final int score;
}
