import 'base_candy.dart';
import 'grid_position.dart';

/// Contiguous same-Base Candy match found by the pure Dart core logic layer.
class MatchGroup {
  /// Creates a detected match group from unique board [positions].
  MatchGroup({
    required this.baseCandy,
    required Iterable<GridPosition> positions,
  }) : positions = Set<GridPosition>.unmodifiable(positions);

  /// Base Candy shared by all tiles in this match.
  final BaseCandy baseCandy;

  /// Unique positions that belong to this match.
  final Set<GridPosition> positions;

  /// Number of tiles in this match group.
  int get length => positions.length;

  /// Returns true when this match intersects [other].
  bool intersects(MatchGroup other) {
    return positions.any(other.positions.contains);
  }

  /// Returns a new match containing positions from this group and [other].
  MatchGroup merge(MatchGroup other) {
    if (baseCandy != other.baseCandy) {
      throw ArgumentError(
        'Only MatchGroup instances with the same Base Candy merge.',
      );
    }
    return MatchGroup(
      baseCandy: baseCandy,
      positions: {...positions, ...other.positions},
    );
  }
}
