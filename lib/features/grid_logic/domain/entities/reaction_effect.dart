import 'grid_position.dart';

/// Type of Reaction Effect produced by the pure Dart core logic layer.
enum ReactionEffectType { temperedShatter }

/// Special effect triggered by adjacent Reactive State matches in one Cascade Step.
abstract class ReactionEffect {
  /// Creates a Reaction Effect with the positions that caused and resolve it.
  ReactionEffect({
    required this.type,
    required Iterable<GridPosition> triggerPositions,
    required Iterable<GridPosition> clearedPositions,
  }) : triggerPositions = Set<GridPosition>.unmodifiable(triggerPositions),
       clearedPositions = Set<GridPosition>.unmodifiable(clearedPositions);

  /// Reaction Effect type for downstream score, VFX, and sound hooks.
  final ReactionEffectType type;

  /// Contact positions that triggered this Reaction Effect.
  final Set<GridPosition> triggerPositions;

  /// Board positions cleared by this Reaction Effect.
  final Set<GridPosition> clearedPositions;
}

/// Tempered Shatter Reaction Effect from adjacent Molten and Frost matches.
class TemperedShatterReaction extends ReactionEffect {
  /// Creates a Tempered Shatter row clear effect.
  TemperedShatterReaction({
    required this.row,
    required super.triggerPositions,
    required super.clearedPositions,
  }) : super(type: ReactionEffectType.temperedShatter);

  /// Row cleared by the Tempered Shatter effect.
  final int row;
}
