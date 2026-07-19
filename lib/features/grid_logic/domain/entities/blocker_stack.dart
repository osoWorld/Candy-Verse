import 'blocker_type.dart';

/// A damageable blocker stack on one playable board cell in the pure Dart layer.
class BlockerStack {
  /// Creates a blocker stack with a positive [hitPoints] value.
  const BlockerStack({required this.blockerType, required this.hitPoints})
    : assert(hitPoints > 0, 'BlockerStack.hitPoints must be positive.');

  /// Type-specific blocker identity.
  final BlockerType blockerType;

  /// Remaining hits required to clear this blocker.
  final int hitPoints;

  /// Returns the blocker after damage, or null when the stack is cleared.
  ///
  /// Inputs: positive [amount]. Output: damaged blocker or null. Side effects:
  /// none.
  BlockerStack? damage({int amount = 1}) {
    if (amount <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'BlockerStack.damage amount must be positive.',
      );
    }
    final remainingHitPoints = hitPoints - amount;
    if (remainingHitPoints <= 0) {
      return null;
    }
    return BlockerStack(
      blockerType: blockerType,
      hitPoints: remainingHitPoints,
    );
  }
}
