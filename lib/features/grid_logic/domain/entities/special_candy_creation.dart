import 'grid_position.dart';
import 'special_candy_type.dart';
import 'tile.dart';

/// Special Candy created by a match in the pure Dart core logic layer.
class SpecialCandyCreation {
  /// Creates an immutable Special Candy creation record.
  ///
  /// Inputs: board [position], [specialCandyType], and resulting [tile].
  /// Output: creation record. Side effects: none.
  const SpecialCandyCreation({
    required this.position,
    required this.specialCandyType,
    required this.tile,
  });

  /// Position that keeps a tile and becomes special.
  final GridPosition position;

  /// Special Candy type created by the match.
  final SpecialCandyType specialCandyType;

  /// Replacement tile carrying [specialCandyType].
  final Tile tile;
}
