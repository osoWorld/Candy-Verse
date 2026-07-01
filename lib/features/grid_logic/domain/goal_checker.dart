import 'entities/game_goal.dart';
import 'entities/goal_progress.dart';
import 'entities/goal_type.dart';

/// Checks level goal completion in the pure Dart core logic layer.
class GoalChecker {
  /// Creates a stateless goal checker.
  const GoalChecker();

  /// Returns true when [progress] satisfies [goal].
  bool isGoalComplete({
    required GameGoal goal,
    required GoalProgress progress,
  }) {
    goal.validate();
    switch (goal.goalType) {
      case GoalType.score:
        return progress.score >= goal.targetValue;
      case GoalType.collectState:
        return progress.collectedCountFor(goal.targetReactiveState!) >=
            goal.targetValue;
      case GoalType.clearObstacle:
        return progress.clearedObstacleCount >= goal.targetValue;
    }
  }
}
