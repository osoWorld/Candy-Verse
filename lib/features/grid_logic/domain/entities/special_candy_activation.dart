import 'grid_position.dart';
import 'special_candy_type.dart';

/// Special Candy activation in the pure Dart core logic layer.
class SpecialCandyActivation {
  /// Creates an immutable activation result.
  ///
  /// Inputs: activation [origin], [specialCandyType], and cleared positions.
  /// Output: activation record. Side effects: none.
  SpecialCandyActivation({
    required this.origin,
    required this.specialCandyType,
    required Iterable<GridPosition> clearedPositions,
  }) : clearedPositions = Set<GridPosition>.unmodifiable(clearedPositions);

  /// Position of the activated Special Candy.
  final GridPosition origin;

  /// Special Candy type that activated.
  final SpecialCandyType specialCandyType;

  /// Positions affected by this activation.
  final Set<GridPosition> clearedPositions;
}
