import 'blocker_stack.dart';
import 'grid_position.dart';
import 'grid_state.dart';
import 'match_group.dart';
import 'reaction_effect.dart';
import 'special_candy_activation.dart';
import 'special_candy_creation.dart';

/// Result of one Cascade Step in the pure Dart core logic layer.
class CascadeStepResult {
  /// Creates the result for one clear, gravity, and refill wave.
  CascadeStepResult({
    required this.gridBeforeClear,
    required this.gridAfterGravity,
    required this.matches,
    required this.reactionEffects,
    this.specialCandyCreations = const [],
    this.specialCandyActivations = const [],
    required Iterable<GridPosition> clearedPositions,
    Map<GridPosition, BlockerStack> clearedBlockers = const {},
  }) : clearedPositions = Set<GridPosition>.unmodifiable(clearedPositions),
       clearedBlockers = Map<GridPosition, BlockerStack>.unmodifiable(
         clearedBlockers,
       );

  /// Grid state at the start of this Cascade Step.
  final GridState gridBeforeClear;

  /// Grid state after this Cascade Step has cleared, applied gravity, and refilled.
  ///
  /// Compatibility note: the prototype field name is kept until Flame animation
  /// code is migrated to an explicit refill animation result.
  final GridState gridAfterGravity;

  /// Matches resolved during this Cascade Step.
  final List<MatchGroup> matches;

  /// Reaction Effects triggered during this Cascade Step.
  final List<ReactionEffect> reactionEffects;

  /// Special Candies created during this Cascade Step.
  final List<SpecialCandyCreation> specialCandyCreations;

  /// Special Candies activated during this Cascade Step.
  final List<SpecialCandyActivation> specialCandyActivations;

  /// Positions cleared during this Cascade Step.
  final Set<GridPosition> clearedPositions;

  /// Blockers removed during this Cascade Step.
  final Map<GridPosition, BlockerStack> clearedBlockers;
}
