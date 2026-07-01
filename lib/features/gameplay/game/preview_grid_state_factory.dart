import '../../../core/constants/gameplay_layout_constants.dart';
import '../../grid_logic/domain/entities/base_candy.dart';
import '../../grid_logic/domain/entities/grid_state.dart';
import '../../grid_logic/domain/entities/reactive_state.dart';
import '../../grid_logic/domain/entities/tile.dart';

/// Provides a Step 4 static preview GridState for Flame rendering.
class PreviewGridStateFactory {
  /// Creates a non-level preview board; Step 10 will replace this with JSON loading.
  GridState create() {
    final reactiveStatePattern = [
      ReactiveState.molten,
      ReactiveState.frost,
      ReactiveState.living,
      ReactiveState.syrup,
      ReactiveState.spice,
      ReactiveState.none,
      ReactiveState.molten,
    ];
    final baseCandyRows = [
      [
        BaseCandy.cocoa,
        BaseCandy.citrus,
        BaseCandy.cocoa,
        BaseCandy.berry,
        BaseCandy.mint,
        BaseCandy.cream,
        BaseCandy.citrus,
      ],
      [
        BaseCandy.berry,
        BaseCandy.cocoa,
        BaseCandy.citrus,
        BaseCandy.mint,
        BaseCandy.cream,
        BaseCandy.berry,
        BaseCandy.mint,
      ],
      [
        BaseCandy.mint,
        BaseCandy.citrus,
        BaseCandy.cocoa,
        BaseCandy.cream,
        BaseCandy.berry,
        BaseCandy.mint,
        BaseCandy.cream,
      ],
      [
        BaseCandy.cream,
        BaseCandy.cocoa,
        BaseCandy.mint,
        BaseCandy.cocoa,
        BaseCandy.cocoa,
        BaseCandy.cream,
        BaseCandy.berry,
      ],
      [
        BaseCandy.citrus,
        BaseCandy.mint,
        BaseCandy.cream,
        BaseCandy.berry,
        BaseCandy.mint,
        BaseCandy.cocoa,
        BaseCandy.citrus,
      ],
      [
        BaseCandy.berry,
        BaseCandy.cream,
        BaseCandy.citrus,
        BaseCandy.cocoa,
        BaseCandy.berry,
        BaseCandy.mint,
        BaseCandy.cream,
      ],
      [
        BaseCandy.mint,
        BaseCandy.cocoa,
        BaseCandy.berry,
        BaseCandy.cream,
        BaseCandy.citrus,
        BaseCandy.berry,
        BaseCandy.mint,
      ],
    ];

    return GridState(
      rows: previewBoardRows,
      columns: previewBoardColumns,
      cells: [
        for (var row = 0; row < previewBoardRows; row += 1)
          [
            for (var column = 0; column < previewBoardColumns; column += 1)
              Tile(
                id: 'preview-$row-$column',
                baseCandy: baseCandyRows[row][column],
                reactiveState:
                    reactiveStatePattern[(row * 2 + column) %
                        reactiveStatePattern.length],
              ),
          ],
      ],
    );
  }
}
