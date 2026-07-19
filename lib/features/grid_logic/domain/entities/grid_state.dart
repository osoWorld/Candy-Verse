import 'blocker_stack.dart';
import 'board_mask.dart';
import 'grid_position.dart';
import 'tile.dart';

/// Immutable board state in the pure Dart core logic layer.
class GridState {
  /// Creates a validated grid with nullable cells for mid-cascade empty spaces.
  GridState({
    required this.rows,
    required this.columns,
    required List<List<Tile?>> cells,
    BoardMask? boardMask,
    Map<GridPosition, BlockerStack> blockers = const {},
  }) : cells = _copyAndValidateCells(
         rows: rows,
         columns: columns,
         cells: cells,
         boardMask: boardMask ?? BoardMask.full(rows: rows, columns: columns),
       ),
       boardMask = boardMask ?? BoardMask.full(rows: rows, columns: columns),
       blockers = _copyAndValidateBlockers(
         rows: rows,
         columns: columns,
         boardMask: boardMask ?? BoardMask.full(rows: rows, columns: columns),
         blockers: blockers,
       );

  /// Number of board rows.
  final int rows;

  /// Number of board columns.
  final int columns;

  /// Board cells where null represents an empty mid-cascade slot.
  final List<List<Tile?>> cells;

  /// Board shape defining playable and unplayable cells.
  final BoardMask boardMask;

  /// Damageable blockers keyed by playable cell position.
  final Map<GridPosition, BlockerStack> blockers;

  /// Returns whether [position] is inside this grid.
  bool contains(GridPosition position) {
    return position.row >= 0 &&
        position.row < rows &&
        position.column >= 0 &&
        position.column < columns;
  }

  /// Returns whether [position] is inside this grid and playable.
  bool isPlayable(GridPosition position) {
    return contains(position) && boardMask.isPlayable(position);
  }

  /// Returns the tile at [position], or null for an empty cell.
  Tile? tileAt(GridPosition position) {
    _checkPosition(position);
    if (!isPlayable(position)) {
      return null;
    }
    return cells[position.row][position.column];
  }

  /// Returns the blocker at [position], or null when no blocker is present.
  BlockerStack? blockerAt(GridPosition position) {
    _checkPosition(position);
    if (!isPlayable(position)) {
      return null;
    }
    return blockers[position];
  }

  /// Returns a new grid with [tile] placed at [position].
  GridState setTile(GridPosition position, Tile? tile) {
    _checkPosition(position);
    if (!isPlayable(position) && tile != null) {
      throw ArgumentError(
        'GridState.setTile cannot place a tile on unplayable position '
        'row ${position.row}, column ${position.column}.',
      );
    }
    final nextCells = _copyCells(cells);
    nextCells[position.row][position.column] = tile;
    return GridState(
      rows: rows,
      columns: columns,
      cells: nextCells,
      boardMask: boardMask,
      blockers: blockers,
    );
  }

  /// Returns a new grid with tiles at [first] and [second] swapped.
  GridState swapTiles(GridPosition first, GridPosition second) {
    _checkPosition(first);
    _checkPosition(second);
    if (!isPlayable(first) || !isPlayable(second)) {
      throw ArgumentError(
        'GridState.swapTiles requires two playable positions.',
      );
    }
    final nextCells = _copyCells(cells);
    final firstTile = nextCells[first.row][first.column];
    nextCells[first.row][first.column] = nextCells[second.row][second.column];
    nextCells[second.row][second.column] = firstTile;
    return GridState(
      rows: rows,
      columns: columns,
      cells: nextCells,
      boardMask: boardMask,
      blockers: blockers,
    );
  }

  /// Returns a new grid with all [positions] cleared to null.
  GridState clearPositions(Iterable<GridPosition> positions) {
    final nextCells = _copyCells(cells);
    for (final position in positions) {
      _checkPosition(position);
      if (!isPlayable(position)) {
        continue;
      }
      nextCells[position.row][position.column] = null;
    }
    return GridState(
      rows: rows,
      columns: columns,
      cells: nextCells,
      boardMask: boardMask,
      blockers: blockers,
    );
  }

  /// Returns a new grid after damaging blockers at [positions].
  ///
  /// Inputs: positions receiving blocker damage and positive [amount]. Output:
  /// damage result with the updated grid. Side effects: none.
  BlockerDamageResult damageBlockers(
    Iterable<GridPosition> positions, {
    int amount = 1,
  }) {
    if (amount <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'GridState.damageBlockers amount must be positive.',
      );
    }
    final nextBlockers = Map<GridPosition, BlockerStack>.of(blockers);
    final clearedBlockers = <GridPosition, BlockerStack>{};
    final damagedBlockers = <GridPosition, BlockerStack>{};

    for (final position in positions.toSet()) {
      _checkPosition(position);
      final blocker = nextBlockers[position];
      if (blocker == null) {
        continue;
      }
      damagedBlockers[position] = blocker;
      final damagedBlocker = blocker.damage(amount: amount);
      if (damagedBlocker == null) {
        nextBlockers.remove(position);
        clearedBlockers[position] = blocker;
      } else {
        nextBlockers[position] = damagedBlocker;
      }
    }

    return BlockerDamageResult(
      grid: GridState(
        rows: rows,
        columns: columns,
        cells: cells,
        boardMask: boardMask,
        blockers: nextBlockers,
      ),
      damagedBlockers: damagedBlockers,
      clearedBlockers: clearedBlockers,
    );
  }

  /// Returns a defensive deep copy of [source] cells.
  static List<List<Tile?>> _copyCells(List<List<Tile?>> source) {
    return [for (final row in source) List<Tile?>.of(row)];
  }

  static List<List<Tile?>> _copyAndValidateCells({
    required int rows,
    required int columns,
    required List<List<Tile?>> cells,
    required BoardMask boardMask,
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
    if (boardMask.rows != rows || boardMask.columns != columns) {
      throw ArgumentError(
        'GridState boardMask dimensions must match $rows x $columns grid.',
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
    for (var row = 0; row < rows; row += 1) {
      for (var column = 0; column < columns; column += 1) {
        final position = GridPosition(row: row, column: column);
        if (!boardMask.isPlayable(position) && cells[row][column] != null) {
          throw ArgumentError(
            'GridState cells at unplayable position row $row, column $column '
            'must be null.',
          );
        }
      }
    }
    return _copyCells(cells);
  }

  static Map<GridPosition, BlockerStack> _copyAndValidateBlockers({
    required int rows,
    required int columns,
    required BoardMask boardMask,
    required Map<GridPosition, BlockerStack> blockers,
  }) {
    if (boardMask.rows != rows || boardMask.columns != columns) {
      throw ArgumentError(
        'GridState blocker validation requires a matching boardMask.',
      );
    }
    for (final entry in blockers.entries) {
      final position = entry.key;
      if (position.row < 0 ||
          position.row >= rows ||
          position.column < 0 ||
          position.column >= columns) {
        throw ArgumentError(
          'GridState blocker position row ${position.row}, column '
          '${position.column} is outside $rows x $columns grid.',
        );
      }
      if (!boardMask.isPlayable(position)) {
        throw ArgumentError(
          'GridState blocker position row ${position.row}, column '
          '${position.column} must be playable.',
        );
      }
      if (entry.value.hitPoints <= 0) {
        throw ArgumentError('GridState blockers must have positive hitPoints.');
      }
    }
    return Map<GridPosition, BlockerStack>.unmodifiable(blockers);
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

/// Result of damaging blockers in the pure Dart core logic layer.
class BlockerDamageResult {
  /// Creates an immutable blocker damage result.
  ///
  /// Inputs: updated [grid], damaged blockers, and cleared blockers. Output:
  /// result object. Side effects: none.
  BlockerDamageResult({
    required this.grid,
    Map<GridPosition, BlockerStack> damagedBlockers = const {},
    Map<GridPosition, BlockerStack> clearedBlockers = const {},
  }) : damagedBlockers = Map<GridPosition, BlockerStack>.unmodifiable(
         damagedBlockers,
       ),
       clearedBlockers = Map<GridPosition, BlockerStack>.unmodifiable(
         clearedBlockers,
       );

  /// Grid after blocker damage has been applied.
  final GridState grid;

  /// Blockers that received damage, keyed by position with pre-damage values.
  final Map<GridPosition, BlockerStack> damagedBlockers;

  /// Blockers removed by this damage pass, keyed by position.
  final Map<GridPosition, BlockerStack> clearedBlockers;
}
