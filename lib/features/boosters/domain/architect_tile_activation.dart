import '../../grid_logic/domain/entities/grid_position.dart';
import '../../grid_logic/domain/entities/grid_state.dart';
import 'architect_tile_action.dart';

/// Result of an Architect Tile activation in the boosters domain layer.
class ArchitectTileActivation {
  /// Creates an immutable Architect Tile activation result.
  ArchitectTileActivation({
    required this.action,
    required this.gridBefore,
    required this.gridAfter,
    required Iterable<GridPosition> affectedPositions,
  }) : affectedPositions = Set<GridPosition>.unmodifiable(affectedPositions);

  /// Topology action performed by the Architect Tile.
  final ArchitectTileAction action;

  /// Grid before the topology change.
  final GridState gridBefore;

  /// Grid after the topology change.
  final GridState gridAfter;

  /// Positions affected by this topology change.
  final Set<GridPosition> affectedPositions;
}
