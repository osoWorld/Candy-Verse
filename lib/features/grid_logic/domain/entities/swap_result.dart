import 'cascade_result.dart';
import 'grid_position.dart';
import 'grid_state.dart';
import 'match_group.dart';

/// Result of a requested adjacent tile swap in the pure Dart core logic layer.
class SwapResult {
  /// Creates an accepted swap with match and cascade results.
  const SwapResult.accepted({
    required this.first,
    required this.second,
    required this.swappedGrid,
    required this.matches,
    required CascadeResult this.cascadeResult,
  }) : isAccepted = true,
       rejectionReason = null;

  /// Creates a rejected swap with the reason it was rejected.
  const SwapResult.rejected({
    required this.first,
    required this.second,
    required this.swappedGrid,
    required SwapRejectionReason this.rejectionReason,
  }) : isAccepted = false,
       matches = const [],
       cascadeResult = null;

  /// First requested swap position.
  final GridPosition first;

  /// Second requested swap position.
  final GridPosition second;

  /// Grid after the tentative swap.
  final GridState swappedGrid;

  /// Whether the swap produced at least one match.
  final bool isAccepted;

  /// Reason the swap was rejected, or null for accepted swaps.
  final SwapRejectionReason? rejectionReason;

  /// Matches found immediately after the swap.
  final List<MatchGroup> matches;

  /// Cascade result started by this valid swap.
  final CascadeResult? cascadeResult;
}

/// Reason a requested swap was rejected by the pure Dart core logic layer.
enum SwapRejectionReason { notAdjacent, emptyTile, noMatch }
