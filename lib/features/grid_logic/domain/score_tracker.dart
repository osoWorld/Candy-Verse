import 'entities/cascade_result.dart';
import 'entities/cascade_step_result.dart';

/// Tracks score changes in the pure Dart core logic layer.
class ScoreTracker {
  /// Creates a configurable score tracker without hardcoded balance values.
  const ScoreTracker({
    required this.pointsPerClearedTile,
    required this.pointsPerCascadeStep,
    required this.pointsPerReactionEffect,
  });

  /// Score awarded for each cleared tile.
  final int pointsPerClearedTile;

  /// Bonus awarded for each resolved Cascade Step.
  final int pointsPerCascadeStep;

  /// Bonus awarded for each triggered Reaction Effect.
  final int pointsPerReactionEffect;

  /// Returns updated score after applying [scoreDelta] to [currentScore].
  int applyScoreDelta({required int currentScore, required int scoreDelta}) {
    return currentScore + scoreDelta;
  }

  /// Returns score earned by all Cascade Step entries in [cascadeResult].
  int scoreCascade(CascadeResult cascadeResult) {
    return cascadeResult.steps.fold<int>(
      0,
      (score, step) => score + scoreCascadeStep(step),
    );
  }

  /// Returns score earned by one [cascadeStepResult].
  int scoreCascadeStep(CascadeStepResult cascadeStepResult) {
    final tileScore =
        cascadeStepResult.clearedPositions.length * pointsPerClearedTile;
    final reactionScore =
        cascadeStepResult.reactionEffects.length * pointsPerReactionEffect;
    return tileScore + reactionScore + pointsPerCascadeStep;
  }
}
