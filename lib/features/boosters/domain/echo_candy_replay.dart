import '../../grid_logic/domain/entities/cascade_step_result.dart';
import '../../grid_logic/domain/entities/grid_position.dart';

/// Scheduled Echo Candy replay in the boosters domain layer.
class EchoCandyReplay {
  /// Creates an immutable Echo Candy replay.
  EchoCandyReplay({
    required this.sourceCascadeStep,
    required Iterable<GridPosition> replayPositions,
    required this.delaySeconds,
    required this.opacity,
  }) : replayPositions = Set<GridPosition>.unmodifiable(replayPositions);

  /// Cascade Step whose effect is replayed.
  final CascadeStepResult sourceCascadeStep;

  /// Positions replayed by Echo Candy.
  final Set<GridPosition> replayPositions;

  /// Delay before replay starts.
  final double delaySeconds;

  /// Visual opacity for the replay.
  final double opacity;
}
