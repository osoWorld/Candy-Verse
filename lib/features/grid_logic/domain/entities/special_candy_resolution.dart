import 'grid_position.dart';
import 'special_candy_activation.dart';
import 'special_candy_creation.dart';

/// Special Candy resolution for one Cascade Step in the pure Dart core layer.
class SpecialCandyResolution {
  /// Creates a resolution containing creations and activations.
  ///
  /// Inputs: creation and activation records. Output: immutable resolution.
  /// Side effects: none.
  SpecialCandyResolution({
    required Iterable<SpecialCandyCreation> creations,
    required Iterable<SpecialCandyActivation> activations,
  }) : creations = List<SpecialCandyCreation>.unmodifiable(creations),
       activations = List<SpecialCandyActivation>.unmodifiable(activations);

  /// Special Candies created by matched shapes.
  final List<SpecialCandyCreation> creations;

  /// Existing Special Candies activated by the Cascade Step.
  final List<SpecialCandyActivation> activations;

  /// Positions that should keep their newly created Special Candy tile.
  Set<GridPosition> get createdPositions {
    return {for (final creation in creations) creation.position};
  }

  /// Positions cleared by all activations.
  Set<GridPosition> get activationClearedPositions {
    return {
      for (final activation in activations) ...activation.clearedPositions,
    };
  }
}
