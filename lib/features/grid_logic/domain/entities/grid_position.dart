/// Row and column coordinate in the pure Dart core logic layer.
class GridPosition {
  /// Creates a zero-based grid coordinate.
  const GridPosition({required this.row, required this.column});

  /// Zero-based row index.
  final int row;

  /// Zero-based column index.
  final int column;

  /// Returns true when this position is orthogonally adjacent to [other].
  bool isOrthogonallyAdjacentTo(GridPosition other) {
    final rowDistance = (row - other.row).abs();
    final columnDistance = (column - other.column).abs();
    return rowDistance + columnDistance == 1;
  }

  /// Returns true when [other] has the same row and column.
  @override
  bool operator ==(Object other) {
    return other is GridPosition && other.row == row && other.column == column;
  }

  /// Hashes this position by row and column.
  @override
  int get hashCode => Object.hash(row, column);

  /// Formats this position for diagnostics and test failure output.
  @override
  String toString() => 'GridPosition(row: $row, column: $column)';
}
