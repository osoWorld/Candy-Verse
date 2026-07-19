import '../../boosters/domain/booster_type.dart';

// PLACEMENT_NOTE: ARCHITECTURE.md does not yet define a profile feature, but
// daily rewards need a small domain value object shared by profile UI and
// controller code.

/// Daily reward track entry in the profile domain layer.
class DailyRewardDefinition {
  /// Creates a daily reward track entry.
  const DailyRewardDefinition({
    required this.day,
    required this.boosterType,
    required this.quantity,
  });

  /// One-based day number in the reward cycle.
  final int day;

  /// Booster granted by this day.
  final BoosterType boosterType;

  /// Quantity granted by this day.
  final int quantity;

  /// User-facing reward label.
  ///
  /// Inputs: none. Output: formatted reward label. Side effects: none.
  String get rewardLabel => '+$quantity ${boosterTypeLabel(boosterType)}';
}
