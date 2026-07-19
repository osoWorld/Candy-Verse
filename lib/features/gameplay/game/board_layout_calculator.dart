import 'package:flame/components.dart';

import '../../../core/constants/gameplay_layout_constants.dart';
import '../../grid_logic/domain/entities/grid_state.dart';

/// Computes responsive Flame board layout in the gameplay game layer.
class BoardLayoutCalculator {
  /// Creates a responsive board layout calculator.
  const BoardLayoutCalculator({
    this.horizontalSafeMargin = liveBoardHorizontalSafeMargin,
    this.preferredMinimumTileSize = liveBoardPreferredMinimumTileSize,
    this.maximumTileSize = liveBoardMaximumTileSize,
    this.tileGap = staticBoardTileGap,
    this.boardPadding = staticBoardPadding,
  });

  /// Minimum space kept at both horizontal screen edges.
  final double horizontalSafeMargin;

  /// Preferred smallest tile size before no-overflow constraints force smaller.
  final double preferredMinimumTileSize;

  /// Largest tile size used for live gameplay.
  final double maximumTileSize;

  /// Gap between adjacent tiles.
  final double tileGap;

  /// Padding inside the board tray.
  final double boardPadding;

  /// Computes a layout for [gridState] inside [viewportSize].
  ///
  /// Inputs: viewport size and grid dimensions. Output: board layout values.
  /// Side effects: none.
  BoardLayout calculate({
    required Vector2 viewportSize,
    required GridState gridState,
  }) {
    if (viewportSize.x <= 0 || viewportSize.y <= 0) {
      throw ArgumentError.value(
        viewportSize,
        'viewportSize',
        'BoardLayoutCalculator requires a positive viewport size.',
      );
    }

    final availableWidth = (viewportSize.x - horizontalSafeMargin * 2).clamp(
      0,
      viewportSize.x,
    );
    final tileSizeForWidth =
        (availableWidth -
            boardPadding * 2 -
            (gridState.columns - 1) * tileGap) /
        gridState.columns;
    final tileSize = tileSizeForWidth.clamp(1.0, maximumTileSize);
    final boardSize = Vector2(
      boardPadding * 2 +
          gridState.columns * tileSize +
          (gridState.columns - 1) * tileGap,
      boardPadding * 2 +
          gridState.rows * tileSize +
          (gridState.rows - 1) * tileGap,
    );

    return BoardLayout(
      tileSize: tileSize,
      tileGap: tileGap,
      boardSize: boardSize,
      position: Vector2(
        (viewportSize.x - boardSize.x) / 2,
        (viewportSize.y - boardSize.y) / 2,
      ),
    );
  }
}

/// Responsive board layout values in the gameplay game layer.
class BoardLayout {
  /// Creates immutable board layout values.
  ///
  /// Inputs: tile sizing, board size, and top-left position. Output: layout.
  /// Side effects: none.
  const BoardLayout({
    required this.tileSize,
    required this.tileGap,
    required this.boardSize,
    required this.position,
  });

  /// Computed tile size.
  final double tileSize;

  /// Gap between adjacent tiles.
  final double tileGap;

  /// Full board component size.
  final Vector2 boardSize;

  /// Top-left board position inside the viewport.
  final Vector2 position;
}
