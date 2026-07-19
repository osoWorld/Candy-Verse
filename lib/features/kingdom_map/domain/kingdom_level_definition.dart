import 'level_difficulty.dart';

/// Level node data for the Kingdom Map domain layer.
class KingdomLevelDefinition {
  /// Creates an immutable Kingdom Map level node definition.
  const KingdomLevelDefinition({
    required this.kingdomId,
    required this.kingdomName,
    required this.levelNumber,
    required this.difficulty,
    required this.goalLabel,
    required this.moveLimit,
    required this.friendScoreSeed,
    required this.preGameBoosters,
  });

  /// Kingdom id containing this level.
  final String kingdomId;

  /// User-facing kingdom name.
  final String kingdomName;

  /// Global one-based level number.
  final int levelNumber;

  /// Difficulty badge for the level node and modal.
  final LevelDifficulty difficulty;

  /// User-facing goal summary.
  final String goalLabel;

  /// Move limit shown before gameplay.
  final int moveLimit;

  /// Stable seed used for offline fallback friend scores.
  final int friendScoreSeed;

  /// Exactly three pre-game booster names offered by the level.
  final List<String> preGameBoosters;
}
