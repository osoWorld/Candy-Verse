import 'cascade_step_result.dart';
import 'grid_state.dart';

/// Full cascade resolution result in the pure Dart core logic layer.
class CascadeResult {
  /// Creates the complete cascade result after the board reaches stability.
  const CascadeResult({required this.finalGrid, required this.steps});

  /// Stable grid after all Cascade Step waves finish.
  final GridState finalGrid;

  /// Ordered clear-and-gravity waves resolved by CascadeResolver.
  final List<CascadeStepResult> steps;

  /// Number of Cascade Step waves resolved.
  int get stepCount => steps.length;
}
