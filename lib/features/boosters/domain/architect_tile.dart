import '../../../core/constants/booster_constants.dart';
import '../../grid_logic/domain/entities/grid_position.dart';
import '../../grid_logic/domain/entities/grid_state.dart';
import '../../grid_logic/domain/entities/tile.dart';
import 'architect_tile_action.dart';
import 'architect_tile_activation.dart';

/// Resolves Architect Tile topology changes in the boosters domain layer.
class ArchitectTile {
  /// Creates a stateless Architect Tile resolver.
  const ArchitectTile();

  /// Adds an empty row below [anchorRow] and returns the changed grid.
  ///
  /// Inputs: current [grid] and row anchor. Output: ArchitectTileActivation.
  /// Side effects: none.
  ArchitectTileActivation addRow({
    required GridState grid,
    required int anchorRow,
  }) {
    if (anchorRow < 0 || anchorRow >= grid.rows) {
      throw RangeError(
        'ArchitectTile anchorRow $anchorRow is outside ${grid.rows} rows.',
      );
    }

    final insertIndex = anchorRow + 1;
    final nextCells = <List<Tile?>>[
      for (var row = 0; row < insertIndex; row += 1)
        List<Tile?>.of(grid.cells[row]),
      List<Tile?>.filled(grid.columns, null),
      for (var row = insertIndex; row < grid.rows; row += 1)
        List<Tile?>.of(grid.cells[row]),
    ];
    final gridAfter = GridState(
      rows: grid.rows + 1,
      columns: grid.columns,
      cells: nextCells,
    );

    return ArchitectTileActivation(
      action: ArchitectTileAction.addRow,
      gridBefore: grid,
      gridAfter: gridAfter,
      affectedPositions: [
        for (var column = 0; column < grid.columns; column += 1)
          GridPosition(row: insertIndex, column: column),
      ],
    );
  }

  /// Rotates the 3x3 section centered on [center] clockwise.
  ///
  /// Inputs: current [grid] and section [center]. Output:
  /// ArchitectTileActivation. Side effects: none.
  ArchitectTileActivation rotateSectionClockwise({
    required GridState grid,
    required GridPosition center,
  }) {
    final affectedPositions = _sectionPositions(grid, center);
    final nextCells = [for (final row in grid.cells) List<Tile?>.of(row)];

    for (final position in affectedPositions) {
      final relativeRow = position.row - (center.row - 1);
      final relativeColumn = position.column - (center.column - 1);
      final target = GridPosition(
        row: center.row - 1 + relativeColumn,
        column:
            center.column - 1 + (architectTileSectionSize - 1 - relativeRow),
      );
      nextCells[target.row][target.column] = grid.tileAt(position);
    }

    return ArchitectTileActivation(
      action: ArchitectTileAction.rotateSectionClockwise,
      gridBefore: grid,
      gridAfter: GridState(
        rows: grid.rows,
        columns: grid.columns,
        cells: nextCells,
      ),
      affectedPositions: affectedPositions,
    );
  }

  Set<GridPosition> _sectionPositions(GridState grid, GridPosition center) {
    final halfSize = architectTileSectionSize ~/ 2;
    final top = center.row - halfSize;
    final left = center.column - halfSize;
    final bottom = center.row + halfSize;
    final right = center.column + halfSize;
    if (top < 0 || left < 0 || bottom >= grid.rows || right >= grid.columns) {
      throw RangeError(
        'ArchitectTile 3x3 section centered at row ${center.row}, column '
        '${center.column} is outside ${grid.rows} x ${grid.columns} GridState.',
      );
    }

    return {
      for (var row = top; row <= bottom; row += 1)
        for (var column = left; column <= right; column += 1)
          GridPosition(row: row, column: column),
    };
  }
}
