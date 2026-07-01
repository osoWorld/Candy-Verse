import 'grid_position.dart';
import 'grid_state.dart';
import 'match_group.dart';
import 'reaction_effect.dart';

/// Result of one Cascade Step in the pure Dart core logic layer.
class CascadeStepResult {
  /// Creates the result for one clear-and-gravity wave.
  CascadeStepResult({
    required this.gridBeforeClear,
    required this.gridAfterGravity,
    required this.matches,
    required this.reactionEffects,
    required Iterable<GridPosition> clearedPositions,
  }) : clearedPositions = Set<GridPosition>.unmodifiable(clearedPositions);

  /// Grid state at the start of this Cascade Step.
  final GridState gridBeforeClear;

  /// Grid state after this Cascade Step has cleared matches and applied gravity.
  final GridState gridAfterGravity;

  /// Matches resolved during this Cascade Step.
  final List<MatchGroup> matches;

  /// Reaction Effects triggered during this Cascade Step.
  final List<ReactionEffect> reactionEffects;

  /// Positions cleared during this Cascade Step.
  final Set<GridPosition> clearedPositions;
}
