import '../../../core/constants/booster_constants.dart';
import 'tempo_meter_state.dart';

/// Resolves Tempo Meter charge and burst timing in the boosters domain layer.
class TempoMeter {
  /// Creates a stateless Tempo Meter resolver.
  const TempoMeter();

  /// Records one accepted swap and returns the next Tempo Meter state.
  ///
  /// Inputs: current [state] and optional [elapsedSincePreviousSwap]. Output:
  /// next TempoMeterState. Side effects: none.
  TempoMeterState recordSwap({
    required TempoMeterState state,
    Duration? elapsedSincePreviousSwap,
  }) {
    if (state.isBurstActive) {
      return state;
    }

    final chargeDelta =
        tempoMeterBaseSwapCharge +
        (_isQuickSwap(elapsedSincePreviousSwap)
            ? tempoMeterQuickSwapBonusCharge
            : 0);
    final nextCharge = state.charge + chargeDelta;
    if (nextCharge < tempoMeterChargeCapacity) {
      return TempoMeterState(charge: nextCharge);
    }

    return const TempoMeterState(
      charge: tempoMeterChargeCapacity,
      isBurstActive: true,
      burstSecondsRemaining: tempoMeterBurstDurationSeconds,
    );
  }

  /// Advances burst timing and returns the next Tempo Meter state.
  ///
  /// Inputs: current [state] and elapsed seconds. Output: next TempoMeterState.
  /// Side effects: none.
  TempoMeterState advanceBurst({
    required TempoMeterState state,
    required double elapsedSeconds,
  }) {
    if (!state.isBurstActive) {
      return state;
    }

    final remaining = state.burstSecondsRemaining - elapsedSeconds;
    if (remaining > 0) {
      return TempoMeterState(
        charge: state.charge,
        isBurstActive: true,
        burstSecondsRemaining: remaining,
      );
    }

    return const TempoMeterState();
  }

  bool _isQuickSwap(Duration? elapsedSincePreviousSwap) {
    if (elapsedSincePreviousSwap == null) {
      return false;
    }
    return elapsedSincePreviousSwap.inMicroseconds /
            Duration.microsecondsPerSecond <=
        tempoMeterQuickSwapWindowSeconds;
  }
}
