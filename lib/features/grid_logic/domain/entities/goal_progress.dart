import 'reactive_state.dart';

/// Current level goal progress in the pure Dart core logic layer.
class GoalProgress {
  /// Creates a progress snapshot for score, collection, and obstacle goals.
  GoalProgress({
    required this.score,
    Map<ReactiveState, int> collectedStates = const {},
    this.clearedObstacleCount = 0,
  }) : collectedStates = Map<ReactiveState, int>.unmodifiable(collectedStates);

  /// Current score progress.
  final int score;

  /// Count collected per Reactive State.
  final Map<ReactiveState, int> collectedStates;

  /// Count of cleared obstacles.
  final int clearedObstacleCount;

  /// Returns the collected count for [reactiveState].
  int collectedCountFor(ReactiveState reactiveState) {
    return collectedStates[reactiveState] ?? 0;
  }
}
