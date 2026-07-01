import 'goal_type.dart';
import 'reactive_state.dart';

/// Level goal definition in the pure Dart core logic layer.
class GameGoal {
  /// Creates a goal with a required target value.
  const GameGoal({
    required this.goalType,
    required this.targetValue,
    this.targetReactiveState,
  });

  /// Type of goal this level requires.
  final GoalType goalType;

  /// Numeric target required to complete this goal.
  final int targetValue;

  /// Reactive State target used by collectState goals.
  final ReactiveState? targetReactiveState;

  /// Validates that this goal has the fields required by its GoalType.
  void validate() {
    if (targetValue < 0) {
      throw ArgumentError.value(
        targetValue,
        'targetValue',
        'GameGoal targetValue must not be negative.',
      );
    }
    if (goalType == GoalType.collectState && targetReactiveState == null) {
      throw ArgumentError(
        'GameGoal collectState requires a targetReactiveState.',
      );
    }
  }
}
