import 'dart:async';

import 'package:get/get.dart';

import '../../../core/utils/candy_alchemy_feedback.dart';
import '../../boosters/domain/tempo_meter.dart';
import '../../boosters/domain/tempo_meter_state.dart';

/// Gameplay state bridge controller in the GetX UI layer.
class GameplayController extends GetxController {
  /// Creates a gameplay controller with optional pure-domain dependencies.
  GameplayController({TempoMeter? tempoMeter, CandyAlchemyFeedback? feedback})
    : _tempoMeter = tempoMeter ?? const TempoMeter(),
      _feedback = feedback ?? PlatformCandyAlchemyFeedback();

  final TempoMeter _tempoMeter;
  final CandyAlchemyFeedback _feedback;
  DateTime? _lastAcceptedSwapAt;

  /// Feedback service shared by the Flutter UI and Flame game layers.
  CandyAlchemyFeedback get feedback => _feedback;

  /// Current Tempo Meter state for booster UI widgets.
  final Rx<TempoMeterState> tempoMeterState = const TempoMeterState().obs;

  /// Current level score shown by GameplayHUD.
  final RxInt score = 0.obs;

  /// Remaining moves shown by GameplayHUD.
  final RxInt movesRemaining = 20.obs;

  /// Current level goal text shown by GameplayHUD.
  final RxString goalLabel = 'Score 5000'.obs;

  /// Current level id shown by GameplayHUD.
  final RxString levelId = 'chapter1_level1'.obs;

  /// Current one-based level number selected from the Level Map.
  final RxInt currentLevelNumber = 1.obs;

  /// Resets HUD state for a level preview.
  ///
  /// Inputs: level identity, move count, and goal label. Output: none. Side
  /// effects: updates GetX reactive HUD state.
  void resetForLevel({
    required String nextLevelId,
    required int nextLevelNumber,
    required int moveLimit,
    required String nextGoalLabel,
  }) {
    levelId.value = nextLevelId;
    currentLevelNumber.value = nextLevelNumber;
    movesRemaining.value = moveLimit;
    goalLabel.value = nextGoalLabel;
    score.value = 0;
    tempoMeterState.value = const TempoMeterState();
    _lastAcceptedSwapAt = null;
  }

  /// Records one accepted board swap and fills the Tempo Meter.
  ///
  /// Inputs: optional [now] for deterministic tests. Output: none. Side
  /// effects: updates [tempoMeterState].
  void recordAcceptedSwap({DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final previousTime = _lastAcceptedSwapAt;
    final wasBurstActive = tempoMeterState.value.isBurstActive;
    _lastAcceptedSwapAt = currentTime;
    final nextTempoMeterState = _tempoMeter.recordSwap(
      state: tempoMeterState.value,
      elapsedSincePreviousSwap: previousTime == null
          ? null
          : currentTime.difference(previousTime),
    );
    tempoMeterState.value = nextTempoMeterState;
    if (!wasBurstActive && nextTempoMeterState.isBurstActive) {
      _feedback.playTempoMeterFull();
    }
    if (movesRemaining.value > 0) {
      movesRemaining.value -= 1;
    }
  }

  /// Plays the standard match sound for one Cascade Step.
  ///
  /// Inputs: zero-based cascade step index. Output: none. Side effects: plays
  /// platform feedback through [CandyAlchemyFeedback].
  void recordCascadeStepClear(int cascadeStepIndex) {
    _feedback.playStandardMatch(cascadeStepIndex: cascadeStepIndex);
  }

  /// Plays ArchitectTile mechanical-shift feedback.
  ///
  /// Inputs: none. Output: none. Side effects: plays platform feedback.
  void playArchitectTileFeedback() {
    _feedback.playArchitectTile();
  }

  /// Plays level-complete sound and haptic feedback.
  ///
  /// Inputs: none. Output: none. Side effects: plays platform feedback.
  void playLevelCompleteFeedback() {
    _feedback.playLevelComplete();
  }

  /// Adds [scoreDelta] to the current HUD score.
  ///
  /// Inputs: score delta. Output: none. Side effects: updates [score].
  void addScore(int scoreDelta) {
    score.value += scoreDelta * tempoMeterState.value.scoreMultiplier;
  }

  /// Advances Tempo Meter burst timing from the Flame frame tick.
  ///
  /// Inputs: elapsed frame seconds. Output: none. Side effects: updates
  /// [tempoMeterState] while a burst is active.
  void advanceTempoMeterBurst(double elapsedSeconds) {
    final currentState = tempoMeterState.value;
    if (!currentState.isBurstActive) {
      return;
    }
    tempoMeterState.value = _tempoMeter.advanceBurst(
      state: currentState,
      elapsedSeconds: elapsedSeconds,
    );
  }

  /// Releases feedback resources when GetX disposes the controller.
  @override
  void onClose() {
    unawaited(_feedback.dispose());
    super.onClose();
  }
}
