import 'base_candy.dart';
import 'reactive_state.dart';
import 'special_candy_type.dart';

/// Candy tile entity in the pure Dart core logic layer.
class Tile {
  /// Creates an immutable candy tile with separate Base Candy and Reactive State.
  const Tile({
    required this.id,
    required this.baseCandy,
    required this.reactiveState,
    this.specialCandyType = SpecialCandyType.none,
  });

  /// Stable identity for this tile instance across grid moves.
  final String id;

  /// Color-layer identity used by MatchDetector.
  final BaseCandy baseCandy;

  /// State-layer identity used by later Reaction Effect logic.
  final ReactiveState reactiveState;

  /// Special Candy behavior carried by this tile.
  final SpecialCandyType specialCandyType;

  /// Whether this tile carries a Special Candy behavior.
  bool get isSpecial => specialCandyType != SpecialCandyType.none;

  /// Returns a copy with [specialCandyType] changed.
  ///
  /// Inputs: new Special Candy type. Output: copied Tile. Side effects: none.
  Tile withSpecialCandyType(SpecialCandyType specialCandyType) {
    return Tile(
      id: '$id-special-${specialCandyType.name}',
      baseCandy: baseCandy,
      reactiveState: reactiveState,
      specialCandyType: specialCandyType,
    );
  }
}
