import '../../../core/constants/booster_constants.dart';

/// Immutable Tempo Meter state in the boosters domain layer.
class TempoMeterState {
  /// Creates a Tempo Meter state snapshot.
  const TempoMeterState({
    this.charge = 0,
    this.isBurstActive = false,
    this.burstSecondsRemaining = 0,
  });

  /// Current meter charge.
  final int charge;

  /// Whether the timed Tempo Meter burst is active.
  final bool isBurstActive;

  /// Remaining burst duration in seconds.
  final double burstSecondsRemaining;

  /// Filled fraction from 0.0 to 1.0 for UI rendering.
  double get fillRatio => (charge / tempoMeterChargeCapacity).clamp(0.0, 1.0);

  /// Score multiplier applied while burst is active.
  int get scoreMultiplier => isBurstActive ? tempoMeterBurstScoreMultiplier : 1;

  /// Fall-speed multiplier applied while burst is active.
  double get fallSpeedMultiplier =>
      isBurstActive ? tempoMeterBurstFallSpeedMultiplier : 1;
}
