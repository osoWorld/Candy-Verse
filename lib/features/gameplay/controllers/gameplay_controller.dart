import 'dart:async';
import 'dart:math' as math;

import 'package:get/get.dart';

import '../../../core/constants/grid_logic_constants.dart';
import '../../../core/utils/candy_alchemy_feedback.dart';
import '../../boosters/domain/booster_type.dart';
import '../../boosters/domain/tempo_meter.dart';
import '../../boosters/domain/tempo_meter_state.dart';
import '../../grid_logic/domain/entities/cascade_step_result.dart';
import '../../grid_logic/domain/entities/game_goal.dart';
import '../../grid_logic/domain/entities/goal_progress.dart';
import '../../grid_logic/domain/entities/goal_type.dart';
import '../../grid_logic/domain/entities/reactive_state.dart';
import '../../grid_logic/domain/goal_checker.dart';
import '../../grid_logic/domain/score_tracker.dart';
import 'gameplay_outcome.dart';
import 'gameplay_session.dart';

/// Gameplay state bridge controller in the GetX UI layer.
class GameplayController extends GetxController {
  /// Creates a gameplay controller with optional pure-domain dependencies.
  GameplayController({
    TempoMeter? tempoMeter,
    GoalChecker? goalChecker,
    CandyAlchemyFeedback? feedback,
  }) : _goalChecker = goalChecker ?? const GoalChecker(),
       _tempoMeter = tempoMeter ?? const TempoMeter(),
       _scoreTracker = const ScoreTracker(
         pointsPerClearedTile: gameplayScorePerClearedTile,
         pointsPerCascadeStep: gameplayScorePerCascadeStep,
         pointsPerReactionEffect: gameplayScorePerReactionEffect,
       ),
       _feedback = feedback ?? PlatformCandyAlchemyFeedback();

  final GoalChecker _goalChecker;
  final TempoMeter _tempoMeter;
  final ScoreTracker _scoreTracker;
  final CandyAlchemyFeedback _feedback;
  DateTime? _lastAcceptedSwapAt;
  GameGoal? _gameGoal;
  List<int> _starThresholds = const [];
  var _previousBestScore = 0;
  var _previousBestStars = 0;

  /// Feedback service shared by the Flutter UI and Flame game layers.
  CandyAlchemyFeedback get feedback => _feedback;

  /// Current Tempo Meter state for booster UI widgets.
  final Rx<TempoMeterState> tempoMeterState = const TempoMeterState().obs;

  /// Current level score shown by GameplayHUD.
  final RxInt score = 0.obs;

  /// Remaining moves shown by GameplayHUD.
  final RxInt movesRemaining = 0.obs;

  /// Current level goal text shown by GameplayHUD.
  final RxString goalLabel = ''.obs;

  /// Current kingdom name shown by overlays.
  final RxString kingdomName = ''.obs;

  /// Current level id shown by GameplayHUD.
  final RxString levelId = ''.obs;

  /// Current one-based level number selected from the Level Map.
  final RxInt currentLevelNumber = 1.obs;

  /// Current booster inventory shown by GameplayHUD.
  final RxMap<BoosterType, int> boosterCounts = <BoosterType, int>{}.obs;

  /// Current collected Reactive State counts for candyOrder LevelKind progress.
  final RxMap<ReactiveState, int> collectedStates = <ReactiveState, int>{}.obs;

  /// Current cleared blocker count for jelly, ingredientDrop, and mixed goals.
  final RxInt clearedObstacleCount = 0.obs;

  /// Booster currently waiting for a board target.
  final Rxn<BoosterType> selectedBooster = Rxn<BoosterType>();

  /// Whether the gameplay route is paused by the pause overlay.
  final RxBool isPaused = false.obs;

  /// Current gameplay end state.
  final Rx<GameplayEndState> endState = GameplayEndState.playing.obs;

  /// Final outcome once [endState] becomes won or lost.
  final Rxn<GameplayOutcome> gameplayOutcome = Rxn<GameplayOutcome>();

  /// Booster types shown in the in-game tray.
  List<BoosterType> get trayBoosterTypes => const [
    BoosterType.fusionBooster,
    BoosterType.architectTile,
    BoosterType.echoCandy,
  ];

  /// Returns whether the board may currently accept player input.
  ///
  /// Inputs: none. Output: input enabled flag. Side effects: none.
  bool get isGameplayInputEnabled =>
      endState.value == GameplayEndState.playing && !isPaused.value;

  /// Resets HUD state for a level preview.
  ///
  /// Inputs: level identity, move count, and goal label. Output: none. Side
  /// effects: updates GetX reactive HUD state.
  void resetForLevel({
    required String nextLevelId,
    required int nextLevelNumber,
    required String nextKingdomName,
    required int moveLimit,
    required String nextGoalLabel,
    List<BoosterType> selectedPreGameBoosters = const [],
    GameGoal? nextGameGoal,
    List<int> nextStarThresholds = const [],
    int previousBestScore = 0,
    int previousBestStars = 0,
  }) {
    levelId.value = nextLevelId;
    currentLevelNumber.value = nextLevelNumber;
    kingdomName.value = nextKingdomName;
    movesRemaining.value = moveLimit;
    goalLabel.value = nextGoalLabel;
    score.value = 0;
    collectedStates.clear();
    clearedObstacleCount.value = 0;
    tempoMeterState.value = const TempoMeterState();
    selectedBooster.value = null;
    isPaused.value = false;
    endState.value = GameplayEndState.playing;
    gameplayOutcome.value = null;
    _gameGoal = nextGameGoal;
    _starThresholds = List<int>.unmodifiable(nextStarThresholds);
    _previousBestScore = previousBestScore;
    _previousBestStars = previousBestStars;
    _resetBoosterCounts(selectedPreGameBoosters);
    _lastAcceptedSwapAt = null;
  }

  /// Resets HUD state from a typed gameplay route argument.
  ///
  /// Inputs: [session]. Output: none. Side effects: updates HUD state and
  /// booster inventory.
  void resetForSession(GameplaySession session) {
    resetForLevel(
      nextLevelId: session.levelId,
      nextLevelNumber: session.levelNumber,
      nextKingdomName: session.kingdomName,
      moveLimit: session.moveLimit,
      nextGoalLabel: session.goalLabel,
      selectedPreGameBoosters: session.selectedPreGameBoosters,
    );
  }

  /// Returns the current inventory count for [boosterType].
  ///
  /// Inputs: booster type. Output: count. Side effects: none.
  int boosterCount(BoosterType boosterType) {
    return boosterCounts[boosterType] ?? 0;
  }

  /// Returns whether [boosterType] is selected for board targeting.
  ///
  /// Inputs: booster type. Output: selected state. Side effects: none.
  bool isBoosterSelected(BoosterType boosterType) {
    return selectedBooster.value == boosterType;
  }

  /// Selects or deselects [boosterType] for board targeting.
  ///
  /// Inputs: booster type. Output: none. Side effects: updates
  /// [selectedBooster].
  void selectBooster(BoosterType boosterType) {
    if (!isGameplayInputEnabled) {
      selectedBooster.value = null;
      return;
    }
    if (boosterCount(boosterType) <= 0) {
      selectedBooster.value = null;
      return;
    }
    selectedBooster.value = selectedBooster.value == boosterType
        ? null
        : boosterType;
  }

  /// Returns the selected booster only when it still has inventory.
  ///
  /// Inputs: none. Output: booster type or null. Side effects: clears stale
  /// selection when inventory has been consumed.
  BoosterType? activeBoosterForBoard() {
    if (!isGameplayInputEnabled) {
      selectedBooster.value = null;
      return null;
    }
    final boosterType = selectedBooster.value;
    if (boosterType == null) {
      return null;
    }
    if (boosterCount(boosterType) <= 0) {
      selectedBooster.value = null;
      return null;
    }
    return boosterType;
  }

  /// Consumes one selected booster after a valid board activation.
  ///
  /// Inputs: booster type that the board activated. Output: whether inventory
  /// was consumed. Side effects: decrements inventory, clears selection, and
  /// plays booster feedback.
  bool consumeSelectedBooster(BoosterType boosterType) {
    if (!isGameplayInputEnabled) {
      return false;
    }
    if (selectedBooster.value != boosterType) {
      return false;
    }
    final count = boosterCount(boosterType);
    if (count <= 0) {
      selectedBooster.value = null;
      return false;
    }
    boosterCounts[boosterType] = count - 1;
    selectedBooster.value = null;
    if (boosterType == BoosterType.architectTile) {
      _feedback.playArchitectTile();
    } else {
      _feedback.playBoosterActivation();
    }
    return true;
  }

  /// Records one accepted board swap and fills the Tempo Meter.
  ///
  /// Inputs: optional [now] for deterministic tests. Output: none. Side
  /// effects: updates [tempoMeterState].
  void recordAcceptedSwap({DateTime? now}) {
    if (!isGameplayInputEnabled) {
      return;
    }
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
    if (endState.value != GameplayEndState.playing) {
      return;
    }
    _feedback.playStandardMatch(cascadeStepIndex: cascadeStepIndex);
  }

  /// Pauses gameplay input and frame-driven timers.
  ///
  /// Inputs: none. Output: none. Side effects: updates [isPaused].
  void pauseGameplay() {
    if (endState.value != GameplayEndState.playing) {
      return;
    }
    selectedBooster.value = null;
    isPaused.value = true;
  }

  /// Resumes gameplay input and frame-driven timers.
  ///
  /// Inputs: none. Output: none. Side effects: updates [isPaused].
  void resumeGameplay() {
    if (endState.value != GameplayEndState.playing) {
      return;
    }
    isPaused.value = false;
  }

  /// Records score, collection, and obstacle progress from one Cascade Step.
  ///
  /// Inputs: zero-based cascade index and pure-domain [cascadeStep]. Output:
  /// none. Side effects: updates score and goal progress observables.
  void recordCascadeStepResolved(
    int cascadeStepIndex,
    CascadeStepResult cascadeStep,
  ) {
    if (endState.value != GameplayEndState.playing) {
      return;
    }
    addScore(_scoreTracker.scoreCascadeStep(cascadeStep));
    clearedObstacleCount.value += cascadeStep.clearedBlockers.length;
    for (final position in cascadeStep.clearedPositions) {
      final tile = cascadeStep.gridBeforeClear.tileAt(position);
      if (tile == null || tile.reactiveState == ReactiveState.none) {
        continue;
      }
      collectedStates[tile.reactiveState] =
          (collectedStates[tile.reactiveState] ?? 0) + 1;
    }
  }

  /// Evaluates win/loss state after the board has finished resolving cascades.
  ///
  /// Inputs: none. Output: none. Side effects: updates [endState] and
  /// [gameplayOutcome] when the level is won or lost.
  void recordCascadeSettled() {
    if (endState.value != GameplayEndState.playing) {
      return;
    }
    final goal = _gameGoal;
    if (goal != null &&
        _goalChecker.isGoalComplete(
          goal: goal,
          progress: currentGoalProgress(),
        )) {
      _finishAttempt(didWin: true);
      return;
    }
    if (movesRemaining.value <= 0) {
      _finishAttempt(didWin: false);
    }
  }

  /// Builds a pure-domain progress snapshot from current controller state.
  ///
  /// Inputs: none. Output: GoalProgress. Side effects: none.
  GoalProgress currentGoalProgress() {
    return GoalProgress(
      score: score.value,
      collectedStates: collectedStates,
      clearedObstacleCount: clearedObstacleCount.value,
    );
  }

  /// Returns stars earned for [finalScore] using current level thresholds.
  ///
  /// Inputs: final score. Output: 1-3 stars for a win. Side effects: none.
  int starsForScore(int finalScore) {
    if (_starThresholds.length != 3) {
      return 1;
    }
    final earnedStars = _starThresholds
        .where((threshold) => finalScore >= threshold)
        .length;
    return math.max(1, earnedStars).clamp(1, 3);
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

  void _finishAttempt({required bool didWin}) {
    final earnedStars = didWin ? starsForScore(score.value) : 0;
    final bestStars = math.max(_previousBestStars, earnedStars);
    final bestScore = math.max(_previousBestScore, score.value);
    final rewardBoosterType = didWin ? _rewardBoosterFor(earnedStars) : null;
    final outcome = GameplayOutcome(
      didWin: didWin,
      levelId: levelId.value,
      levelNumber: currentLevelNumber.value,
      kingdomName: kingdomName.value,
      goalLabel: goalLabel.value,
      goalRemainingLabel: didWin ? 'Goal complete' : _goalRemainingLabel(),
      score: score.value,
      bestScore: bestScore,
      stars: earnedStars,
      bestStars: bestStars,
      movesRemaining: movesRemaining.value,
      rewardLabel: didWin && rewardBoosterType != null
          ? '+1 ${boosterTypeLabel(rewardBoosterType)}'
          : '',
      rewardBoosterType: rewardBoosterType,
      saveStatusLabel: didWin
          ? 'Saved offline - syncs when Supabase is configured'
          : '',
    );
    gameplayOutcome.value = outcome;
    endState.value = didWin ? GameplayEndState.won : GameplayEndState.lost;
  }

  BoosterType _rewardBoosterFor(int stars) {
    return switch (stars) {
      3 => BoosterType.architectTile,
      2 => BoosterType.echoCandy,
      _ => BoosterType.fusionBooster,
    };
  }

  String _goalRemainingLabel() {
    final goal = _gameGoal;
    if (goal == null) {
      return goalLabel.value;
    }
    final progress = currentGoalProgress();
    return switch (goal.goalType) {
      GoalType.score =>
        '${math.max(0, goal.targetValue - progress.score)} score left',
      GoalType.collectState =>
        '${math.max(0, goal.targetValue - progress.collectedCountFor(goal.targetReactiveState!))} ${_reactiveStateLabel(goal.targetReactiveState!)} candies left',
      GoalType.clearObstacle =>
        '${math.max(0, goal.targetValue - progress.clearedObstacleCount)} blockers left',
    };
  }

  String _reactiveStateLabel(ReactiveState reactiveState) {
    return switch (reactiveState) {
      ReactiveState.molten => 'Molten',
      ReactiveState.frost => 'Frost',
      ReactiveState.living => 'Living',
      ReactiveState.syrup => 'Syrup',
      ReactiveState.spice => 'Spice',
      ReactiveState.none => 'Plain',
    };
  }

  /// Advances Tempo Meter burst timing from the Flame frame tick.
  ///
  /// Inputs: elapsed frame seconds. Output: none. Side effects: updates
  /// [tempoMeterState] while a burst is active.
  void advanceTempoMeterBurst(double elapsedSeconds) {
    if (!isGameplayInputEnabled) {
      return;
    }
    final currentState = tempoMeterState.value;
    if (!currentState.isBurstActive) {
      return;
    }
    tempoMeterState.value = _tempoMeter.advanceBurst(
      state: currentState,
      elapsedSeconds: elapsedSeconds,
    );
  }

  void _resetBoosterCounts(List<BoosterType> selectedPreGameBoosters) {
    boosterCounts.clear();
    for (final boosterType in selectedPreGameBoosters) {
      boosterCounts[boosterType] = boosterCount(boosterType) + 1;
    }
  }

  /// Releases feedback resources when GetX disposes the controller.
  @override
  void onClose() {
    unawaited(_feedback.dispose());
    super.onClose();
  }
}
