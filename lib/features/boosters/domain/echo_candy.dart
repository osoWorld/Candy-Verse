import '../../../core/constants/booster_constants.dart';
import '../../grid_logic/domain/entities/cascade_step_result.dart';
import 'echo_candy_replay.dart';

/// Resolves Echo Candy replay scheduling in the boosters domain layer.
class EchoCandy {
  /// Creates a stateless Echo Candy resolver.
  const EchoCandy();

  /// Schedules a replay from [lastCascadeStep].
  ///
  /// Inputs: last Cascade Step. Output: EchoCandyReplay. Side effects: none.
  EchoCandyReplay scheduleReplay(CascadeStepResult lastCascadeStep) {
    if (lastCascadeStep.clearedPositions.isEmpty) {
      throw ArgumentError(
        'EchoCandy requires a Cascade Step with cleared positions to replay.',
      );
    }

    return EchoCandyReplay(
      sourceCascadeStep: lastCascadeStep,
      replayPositions: lastCascadeStep.clearedPositions,
      delaySeconds: echoCandyReplayDelaySeconds,
      opacity: echoCandyReplayOpacity,
    );
  }
}
