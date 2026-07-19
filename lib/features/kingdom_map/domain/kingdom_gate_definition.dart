import '../../boosters/domain/booster_type.dart';

/// Checkpoint gate data for the Kingdom Map domain layer.
class KingdomGateDefinition {
  /// Creates a checkpoint gate definition.
  const KingdomGateDefinition({
    required this.gateKey,
    required this.kingdomId,
    required this.kingdomName,
    required this.checkpointLevel,
    required this.gateIndex,
    required this.title,
    required this.rewardBoosterType,
    required this.rewardQuantity,
    required this.isFinalGate,
  });

  /// Stable gate reward key for persistence.
  final String gateKey;

  /// Stable kingdom id containing this gate.
  final String kingdomId;

  /// User-facing kingdom name.
  final String kingdomName;

  /// Level that must be completed to open this gate.
  final int checkpointLevel;

  /// One-based checkpoint index within the kingdom.
  final int gateIndex;

  /// User-facing checkpoint title.
  final String title;

  /// Booster granted when this checkpoint reward is collected.
  final BoosterType rewardBoosterType;

  /// Booster quantity granted by this checkpoint.
  final int rewardQuantity;

  /// Whether this checkpoint completes the kingdom segment.
  final bool isFinalGate;

  /// User-facing reward label.
  String get rewardLabel =>
      '+$rewardQuantity ${boosterTypeLabel(rewardBoosterType)}';
}
