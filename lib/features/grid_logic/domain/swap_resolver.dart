import 'cascade_resolver.dart';
import 'entities/grid_position.dart';
import 'entities/grid_state.dart';
import 'entities/swap_result.dart';
import 'match_detector.dart';

/// Resolves swap validity in the pure Dart core logic layer.
class SwapResolver {
  /// Creates a resolver that delegates match and cascade checks to core services.
  const SwapResolver({
    required this.matchDetector,
    required this.cascadeResolver,
  });

  /// Match detector used to validate a tentative swap.
  final MatchDetector matchDetector;

  /// Cascade resolver used after a valid swap starts a cascade.
  final CascadeResolver cascadeResolver;

  /// Resolves whether swapping [first] and [second] produces a valid match.
  SwapResult resolveSwap({
    required GridState grid,
    required GridPosition first,
    required GridPosition second,
  }) {
    if (!first.isOrthogonallyAdjacentTo(second)) {
      return SwapResult.rejected(
        first: first,
        second: second,
        swappedGrid: grid,
        rejectionReason: SwapRejectionReason.notAdjacent,
      );
    }
    if (grid.tileAt(first) == null || grid.tileAt(second) == null) {
      return SwapResult.rejected(
        first: first,
        second: second,
        swappedGrid: grid,
        rejectionReason: SwapRejectionReason.emptyTile,
      );
    }

    final swappedGrid = grid.swapTiles(first, second);
    final matches = matchDetector.detectMatches(swappedGrid);
    if (matches.isEmpty) {
      return SwapResult.rejected(
        first: first,
        second: second,
        swappedGrid: swappedGrid,
        rejectionReason: SwapRejectionReason.noMatch,
      );
    }

    return SwapResult.accepted(
      first: first,
      second: second,
      swappedGrid: swappedGrid,
      matches: matches,
      cascadeResult: cascadeResolver.resolve(swappedGrid),
    );
  }
}
