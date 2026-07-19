import '../../boosters/domain/booster_type.dart';
import '../../kingdom_map/domain/kingdom_level_definition.dart';

/// Route argument carrying one gameplay session into the GetX gameplay layer.
class GameplaySession {
  /// Creates immutable session data for one level attempt.
  const GameplaySession({
    required this.levelId,
    required this.levelNumber,
    required this.kingdomName,
    required this.goalLabel,
    required this.moveLimit,
    required this.selectedPreGameBoosters,
  });

  /// Creates a gameplay session from a Kingdom Map level definition.
  ///
  /// Inputs: [level] and selected pre-game boosters. Output: session argument.
  /// Side effects: none.
  factory GameplaySession.fromLevel({
    required KingdomLevelDefinition level,
    required List<BoosterType> selectedPreGameBoosters,
  }) {
    return GameplaySession(
      levelId: '${level.kingdomId}_level${level.levelNumber}',
      levelNumber: level.levelNumber,
      kingdomName: level.kingdomName,
      goalLabel: level.goalLabel,
      moveLimit: level.moveLimit,
      selectedPreGameBoosters: List<BoosterType>.unmodifiable(
        selectedPreGameBoosters,
      ),
    );
  }

  /// Stable level id for repositories and HUD state.
  final String levelId;

  /// Global one-based level number.
  final int levelNumber;

  /// Kingdom name shown by the current session.
  final String kingdomName;

  /// User-facing goal summary.
  final String goalLabel;

  /// Move limit for this level attempt.
  final int moveLimit;

  /// Booster inventory selected before the player tapped Play.
  final List<BoosterType> selectedPreGameBoosters;
}
