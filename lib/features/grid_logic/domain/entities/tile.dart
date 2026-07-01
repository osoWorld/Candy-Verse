import 'base_candy.dart';
import 'reactive_state.dart';

/// Candy tile entity in the pure Dart core logic layer.
class Tile {
  /// Creates an immutable candy tile with separate Base Candy and Reactive State.
  const Tile({
    required this.id,
    required this.baseCandy,
    required this.reactiveState,
    this.isSpecial = false,
  });

  /// Stable identity for this tile instance across grid moves.
  final String id;

  /// Color-layer identity used by MatchDetector.
  final BaseCandy baseCandy;

  /// State-layer identity used by later Reaction Effect logic.
  final ReactiveState reactiveState;

  /// Whether this tile is a future special-candy equivalent.
  final bool isSpecial;
}
