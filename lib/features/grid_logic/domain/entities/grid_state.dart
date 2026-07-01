import 'grid_position.dart';
import 'tile.dart';

/// Immutable board state in the pure Dart core logic layer.
class GridState {
  /// Creates a validated grid with nullable cells for mid-cascade empty spaces.
  GridState({
    required this.rows,
    required this.columns,
    required List<List<Tile?>> cells,
  }) : cells = _copyAndValidateCells(
         rows: rows,
         columns: columns,
         cells: cells,
       );

  /// Number of board rows.
  final int rows;

  /// Number of board columns.
  final int columns;

  /// Board cells where null represents an empty mid-cascade slot.
  final List<List<Tile?>> cells;

  /// Returns whether [position] is inside this grid.
  bool contains(GridPosition position) {
    return position.row >= 0 &&
        position.row < rows &&
        position.column >= 0 &&
        position.column < columns;
  }

  /// Returns the tile at [position], or null for an empty cell.
  Tile? tileAt(GridPosition position) {
    _checkPosition(position);
    return cells[position.row][position.column];
  }

  /// Returns a new grid with [tile] placed at [position].
  GridState setTile(GridPosition position, Tile? tile) {
    _checkPosition(position);
    final nextCells = _copyCells(cells);
    nextCells[position.row][position.column] = tile;
    return GridState(rows: rows, columns: columns, cells: nextCells);
  }

  /// Returns a new grid with tiles at [first] and [second] swapped.
  GridState swapTiles(GridPosition first, GridPosition second) {
    _checkPosition(first);
    _checkPosition(second);
    final nextCells = _copyCells(cells);
    final firstTile = nextCells[first.row][first.column];
    nextCells[first.row][first.column] = nextCells[second.row][second.column];
    nextCells[second.row][second.column] = firstTile;
    return GridState(rows: rows, columns: columns, cells: nextCells);
  }

  /// Returns a new grid with all [positions] cleared to null.
  GridState clearPositions(Iterable<GridPosition> positions) {
    final nextCells = _copyCells(cells);
    for (final position in positions) {
      _checkPosition(position);
      nextCells[position.row][position.column] = null;
    }
    return GridState(rows: rows, columns: columns, cells: nextCells);
  }

  /// Returns a defensive deep copy of [source] cells.
  static List<List<Tile?>> _copyCells(List<List<Tile?>> source) {
    return [for (final row in source) List<Tile?>.of(row)];
  }

  static List<List<Tile?>> _copyAndValidateCells({
    required int rows,
    required int columns,
    required List<List<Tile?>> cells,
  }) {
    if (rows <= 0) {
      throw ArgumentError.value(
        rows,
        'rows',
        'GridState rows must be positive.',
      );
    }
    if (columns <= 0) {
      throw ArgumentError.value(
        columns,
        'columns',
        'GridState columns must be positive.',
      );
    }
    if (cells.length != rows) {
      throw ArgumentError.value(
        cells.length,
        'cells',
        'GridState must contain exactly $rows rows.',
      );
    }
    for (final row in cells) {
      if (row.length != columns) {
        throw ArgumentError.value(
          row.length,
          'cells',
          'Every GridState row must contain exactly $columns columns.',
        );
      }
    }
    return _copyCells(cells);
  }

  void _checkPosition(GridPosition position) {
    if (!contains(position)) {
      throw RangeError(
        'GridPosition row ${position.row}, column ${position.column} is outside '
        '$rows x $columns GridState.',
      );
    }
  }
}
