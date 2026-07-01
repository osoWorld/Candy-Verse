import 'entities/grid_position.dart';
import 'entities/grid_state.dart';
import 'entities/match_group.dart';
import 'entities/reaction_effect.dart';
import 'entities/reactive_state.dart';

/// Detects Reactive State reactions in the pure Dart core logic layer.
class ReactionEngine {
  /// Creates a stateless Reaction Engine.
  const ReactionEngine();

  /// Checks [matches] from the same Cascade Step and returns Reaction Effects.
  List<ReactionEffect> checkAdjacentReactions({
    required GridState grid,
    required List<MatchGroup> matches,
  }) {
    final reactiveMatches = [
      for (final match in matches) _ReactiveMatch.fromGrid(grid, match),
    ].where((match) => match.reactiveState != ReactiveState.none).toList();

    final reactions = <ReactionEffect>[];
    final emittedTemperedShatterRows = <int>{};

    for (var outer = 0; outer < reactiveMatches.length; outer += 1) {
      for (var inner = outer + 1; inner < reactiveMatches.length; inner += 1) {
        final first = reactiveMatches[outer];
        final second = reactiveMatches[inner];
        if (!_isMoltenFrostPair(first.reactiveState, second.reactiveState)) {
          continue;
        }

        final adjacentPair = _firstAdjacentPair(first.match, second.match);
        if (adjacentPair == null) {
          continue;
        }

        final reactionRow = _reactionRowFor(adjacentPair);
        if (!emittedTemperedShatterRows.add(reactionRow)) {
          continue;
        }

        reactions.add(
          TemperedShatterReaction(
            row: reactionRow,
            triggerPositions: adjacentPair,
            clearedPositions: _rowPositions(grid, reactionRow),
          ),
        );
      }
    }

    return List<ReactionEffect>.unmodifiable(reactions);
  }

  bool _isMoltenFrostPair(ReactiveState first, ReactiveState second) {
    return (first == ReactiveState.molten && second == ReactiveState.frost) ||
        (first == ReactiveState.frost && second == ReactiveState.molten);
  }

  List<GridPosition>? _firstAdjacentPair(MatchGroup first, MatchGroup second) {
    for (final firstPosition in first.positions) {
      for (final secondPosition in second.positions) {
        if (firstPosition.isOrthogonallyAdjacentTo(secondPosition)) {
          return [firstPosition, secondPosition];
        }
      }
    }
    return null;
  }

  int _reactionRowFor(List<GridPosition> adjacentPair) {
    final first = adjacentPair.first;
    final second = adjacentPair.last;
    if (first.row == second.row) {
      return first.row;
    }
    return first.row < second.row ? first.row : second.row;
  }

  Iterable<GridPosition> _rowPositions(GridState grid, int row) sync* {
    for (var column = 0; column < grid.columns; column += 1) {
      yield GridPosition(row: row, column: column);
    }
  }
}

class _ReactiveMatch {
  const _ReactiveMatch({required this.match, required this.reactiveState});

  factory _ReactiveMatch.fromGrid(GridState grid, MatchGroup match) {
    ReactiveState? state;
    for (final position in match.positions) {
      final tileState = grid.tileAt(position)?.reactiveState;
      if (tileState == null || tileState == ReactiveState.none) {
        return _ReactiveMatch(match: match, reactiveState: ReactiveState.none);
      }
      state ??= tileState;
      if (state != tileState) {
        return _ReactiveMatch(match: match, reactiveState: ReactiveState.none);
      }
    }
    return _ReactiveMatch(
      match: match,
      reactiveState: state ?? ReactiveState.none,
    );
  }

  final MatchGroup match;
  final ReactiveState reactiveState;
}
