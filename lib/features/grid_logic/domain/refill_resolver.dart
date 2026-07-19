import 'entities/grid_position.dart';
import 'entities/grid_state.dart';
import 'entities/tile.dart';
import 'tile_spawner.dart';

/// Refills empty playable cells in the pure Dart core logic layer.
class RefillResolver {
  /// Creates a refill resolver that delegates new candy creation to [tileSpawner].
  const RefillResolver({required this.tileSpawner});

  /// Deterministic tile factory used for refill.
  final TileSpawner tileSpawner;

  /// Fills all null cells and returns the next spawn index.
  ///
  /// Inputs: gravity-resolved [grid] and [spawnStartIndex]. Output: refill
  /// result. Side effects: none.
  RefillResult refill({required GridState grid, int spawnStartIndex = 0}) {
    final nextCells = [for (final row in grid.cells) List<Tile?>.of(row)];
    var nextSpawnIndex = spawnStartIndex;

    for (var row = 0; row < grid.rows; row += 1) {
      for (var column = 0; column < grid.columns; column += 1) {
        if (nextCells[row][column] != null) {
          continue;
        }
        final position = GridPosition(row: row, column: column);
        if (!grid.isPlayable(position)) {
          continue;
        }
        nextCells[row][column] = _spawnWithoutImmediateMatch(
          cells: nextCells,
          position: position,
          spawnIndex: nextSpawnIndex,
        );
        nextSpawnIndex += 1;
      }
    }

    return RefillResult(
      grid: GridState(
        rows: grid.rows,
        columns: grid.columns,
        cells: nextCells,
        boardMask: grid.boardMask,
        blockers: grid.blockers,
      ),
      nextSpawnIndex: nextSpawnIndex,
    );
  }

  Tile _spawnWithoutImmediateMatch({
    required List<List<Tile?>> cells,
    required GridPosition position,
    required int spawnIndex,
  }) {
    final candidateCount = tileSpawner.spawnRule.baseCandies.length;
    for (var offset = 0; offset < candidateCount; offset += 1) {
      final candidate = tileSpawner.spawnTile(
        position: position,
        spawnIndex: spawnIndex,
        candidateOffset: offset,
      );
      if (!_wouldCreateImmediateMatch(cells, position, candidate)) {
        return candidate;
      }
    }

    return tileSpawner.spawnTile(position: position, spawnIndex: spawnIndex);
  }

  bool _wouldCreateImmediateMatch(
    List<List<Tile?>> cells,
    GridPosition position,
    Tile candidate,
  ) {
    return _hasTwoMatchingLeft(cells, position, candidate) ||
        _hasTwoMatchingAbove(cells, position, candidate) ||
        _wouldCreateSquareMatch(cells, position, candidate);
  }

  bool _hasTwoMatchingLeft(
    List<List<Tile?>> cells,
    GridPosition position,
    Tile candidate,
  ) {
    if (position.column < 2) {
      return false;
    }
    final first = cells[position.row][position.column - 1];
    final second = cells[position.row][position.column - 2];
    return first?.baseCandy == candidate.baseCandy &&
        second?.baseCandy == candidate.baseCandy;
  }

  bool _hasTwoMatchingAbove(
    List<List<Tile?>> cells,
    GridPosition position,
    Tile candidate,
  ) {
    if (position.row < 2) {
      return false;
    }
    final first = cells[position.row - 1][position.column];
    final second = cells[position.row - 2][position.column];
    return first?.baseCandy == candidate.baseCandy &&
        second?.baseCandy == candidate.baseCandy;
  }

  bool _wouldCreateSquareMatch(
    List<List<Tile?>> cells,
    GridPosition position,
    Tile candidate,
  ) {
    for (final rowOffset in [-1, 0]) {
      for (final columnOffset in [-1, 0]) {
        final squareRow = position.row + rowOffset;
        final squareColumn = position.column + columnOffset;
        if (squareRow < 0 ||
            squareColumn < 0 ||
            squareRow + 1 >= cells.length ||
            squareColumn + 1 >= cells.first.length) {
          continue;
        }
        var matchingTiles = 0;
        for (var row = squareRow; row <= squareRow + 1; row += 1) {
          for (
            var column = squareColumn;
            column <= squareColumn + 1;
            column += 1
          ) {
            if (row == position.row && column == position.column) {
              matchingTiles += 1;
              continue;
            }
            if (cells[row][column]?.baseCandy == candidate.baseCandy) {
              matchingTiles += 1;
            }
          }
        }
        if (matchingTiles == 4) {
          return true;
        }
      }
    }
    return false;
  }
}

/// Result of a RefillResolver pass in the pure Dart core logic layer.
class RefillResult {
  /// Creates a refill result.
  ///
  /// Inputs: refilled grid and next spawn index. Output: immutable result.
  /// Side effects: none.
  const RefillResult({required this.grid, required this.nextSpawnIndex});

  /// Grid after all empty cells are refilled.
  final GridState grid;

  /// First unused spawn index after this refill pass.
  final int nextSpawnIndex;
}
