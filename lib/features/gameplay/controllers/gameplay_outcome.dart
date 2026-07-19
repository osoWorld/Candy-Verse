import '../../boosters/domain/booster_type.dart';

/// End state for the current gameplay attempt in the GetX controller layer.
enum GameplayEndState { playing, won, lost }

/// Immutable summary of one finished gameplay attempt in the controller layer.
class GameplayOutcome {
  /// Creates a gameplay outcome snapshot for overlays and persistence.
  const GameplayOutcome({
    required this.didWin,
    required this.levelId,
    required this.levelNumber,
    required this.kingdomName,
    required this.goalLabel,
    required this.goalRemainingLabel,
    required this.score,
    required this.bestScore,
    required this.stars,
    required this.bestStars,
    required this.movesRemaining,
    required this.rewardLabel,
    required this.rewardBoosterType,
    required this.saveStatusLabel,
  });

  /// Whether the player completed the level goal.
  final bool didWin;

  /// Stable level id used by repositories.
  final String levelId;

  /// Global one-based level number.
  final int levelNumber;

  /// Kingdom name shown in overlays.
  final String kingdomName;

  /// User-facing goal label for this attempt.
  final String goalLabel;

  /// User-facing remaining goal text for lose overlays.
  final String goalRemainingLabel;

  /// Final score for this attempt.
  final int score;

  /// Best score known after this attempt.
  final int bestScore;

  /// Earned stars, from 0 to 3.
  final int stars;

  /// Best stars known after this attempt.
  final int bestStars;

  /// Moves left when the attempt ended.
  final int movesRemaining;

  /// Reward text shown by the Win Overlay.
  final String rewardLabel;

  /// Booster granted by the Win Overlay reward, when any.
  final BoosterType? rewardBoosterType;

  /// Persistence status shown by the Win Overlay.
  final String saveStatusLabel;
}
