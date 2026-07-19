/// Daily reward claim state in the data layer.
class DailyRewardState {
  /// Creates daily reward claim state.
  const DailyRewardState({
    required this.lastClaimDateKey,
    required this.streakDay,
  });

  /// Creates the initial unclaimed daily reward state.
  const DailyRewardState.initial() : lastClaimDateKey = null, streakDay = 0;

  /// Local calendar date key of the last claim, formatted yyyy-MM-dd.
  final String? lastClaimDateKey;

  /// Current one-based streak day in the seven-day track.
  final int streakDay;

  /// Parses daily reward state from persisted map data.
  ///
  /// Inputs: Hive map payload. Output: parsed state. Side effects: none.
  factory DailyRewardState.fromMap(Map<String, dynamic> map) {
    final lastClaimDateKey = map['lastClaimDateKey'];
    final streakDay = map['streakDay'];
    return DailyRewardState(
      lastClaimDateKey: lastClaimDateKey is String ? lastClaimDateKey : null,
      streakDay: streakDay is int ? streakDay : 0,
    );
  }

  /// Serializes this state for Hive storage.
  ///
  /// Inputs: none. Output: JSON-like map. Side effects: none.
  Map<String, dynamic> toMap() {
    return {'lastClaimDateKey': lastClaimDateKey, 'streakDay': streakDay};
  }

  /// Returns whether a reward has already been claimed for [dateKey].
  ///
  /// Inputs: local date key. Output: claimed flag. Side effects: none.
  bool hasClaimedOn(String dateKey) {
    return lastClaimDateKey == dateKey;
  }
}
