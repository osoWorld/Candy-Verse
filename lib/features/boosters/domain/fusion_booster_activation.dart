import '../../grid_logic/domain/entities/grid_position.dart';
import 'fusion_effect_type.dart';
import 'special_candy_type.dart';

/// Result of a Fusion Booster activation in the boosters domain layer.
class FusionBoosterActivation {
  /// Creates an immutable Fusion Booster activation result.
  FusionBoosterActivation({
    required this.effectType,
    required this.origin,
    required this.firstSpecialCandyType,
    required this.secondSpecialCandyType,
    required Iterable<GridPosition> affectedPositions,
  }) : affectedPositions = Set<GridPosition>.unmodifiable(affectedPositions);

  /// Hybrid Fusion effect produced by the special-candy pairing.
  final FusionEffectType effectType;

  /// Grid position where the Fusion Booster was activated.
  final GridPosition origin;

  /// First parent special candy type in the pairing.
  final SpecialCandyType firstSpecialCandyType;

  /// Second parent special candy type in the pairing.
  final SpecialCandyType secondSpecialCandyType;

  /// Grid positions affected by this hybrid Fusion Booster effect.
  final Set<GridPosition> affectedPositions;
}
