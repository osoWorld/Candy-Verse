import '../../../core/utils/candy_alchemy_feedback.dart';

/// Sound hook for Tempered Shatter in the Flame game layer.
class TemperedShatterSoundHook {
  /// Creates a Tempered Shatter audio hook.
  TemperedShatterSoundHook({CandyAlchemyFeedback? feedback})
    : feedback = feedback ?? PlatformCandyAlchemyFeedback();

  /// Sound and haptic feedback service.
  final CandyAlchemyFeedback feedback;

  /// Triggers the distinct Tempered Shatter chime/crack sound layer.
  ///
  /// Inputs: none.
  /// Output: none.
  /// Side effects: plays sound and haptic feedback.
  void playTemperedShatter() {
    feedback.playTemperedShatter();
  }
}
