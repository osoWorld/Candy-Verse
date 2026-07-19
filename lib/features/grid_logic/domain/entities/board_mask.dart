import 'grid_position.dart';

/// Playable-cell mask for shaped boards in the pure Dart core logic layer.
class BoardMask {
  /// Creates a validated playable-cell mask for a [rows] by [columns] board.
  BoardMask({
    required this.rows,
    required this.columns,
    required Iterable<GridPosition> playablePositions,
  }) : playablePositions = Set<GridPosition>.unmodifiable(playablePositions) {
    if (rows <= 0) {
      throw ArgumentError.value(
        rows,
        'rows',
        'BoardMask rows must be positive.',
      );
    }
    if (columns <= 0) {
      throw ArgumentError.value(
        columns,
        'columns',
        'BoardMask columns must be positive.',
      );
    }
    if (this.playablePositions.isEmpty) {
      throw ArgumentError(
        'BoardMask.playablePositions must contain at least one cell.',
      );
    }
    for (final position in this.playablePositions) {
      if (!_contains(position)) {
        throw ArgumentError(
          'BoardMask playable position row ${position.row}, column '
          '${position.column} is outside $rows x $columns board.',
        );
      }
    }
  }

  /// Creates a full rectangular playable mask.
  ///
  /// Inputs: board dimensions. Output: full BoardMask. Side effects: none.
  factory BoardMask.full({required int rows, required int columns}) {
    return BoardMask(
      rows: rows,
      columns: columns,
      playablePositions: [
        for (var row = 0; row < rows; row += 1)
          for (var column = 0; column < columns; column += 1)
            GridPosition(row: row, column: column),
      ],
    );
  }

  /// Number of rows covered by this mask.
  final int rows;

  /// Number of columns covered by this mask.
  final int columns;

  /// Playable cells contained in this board shape.
  final Set<GridPosition> playablePositions;

  /// Returns true when [position] is playable.
  bool isPlayable(GridPosition position) {
    return _contains(position) && playablePositions.contains(position);
  }

  /// Returns true when every cell in the rectangle is playable.
  bool get isFullRectangle => playablePositions.length == rows * columns;

  /// Returns stable row-column strings for JSON serialization.
  ///
  /// Inputs: none. Output: sorted "row,column" values. Side effects: none.
  List<String> toPlayablePositionCodes() {
    final positions = playablePositions.toList()
      ..sort((first, second) {
        final rowCompare = first.row.compareTo(second.row);
        if (rowCompare != 0) {
          return rowCompare;
        }
        return first.column.compareTo(second.column);
      });
    return [
      for (final position in positions) '${position.row},${position.column}',
    ];
  }

  bool _contains(GridPosition position) {
    return position.row >= 0 &&
        position.row < rows &&
        position.column >= 0 &&
        position.column < columns;
  }
}
