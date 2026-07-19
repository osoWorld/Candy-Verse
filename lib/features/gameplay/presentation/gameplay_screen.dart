import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/kingdom_constants.dart';
import '../../../core/constants/navigation_constants.dart';
import '../../../core/constants/persistence_constants.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/candy_alchemy_colors.dart';
import '../../../data/generators/level_config_generator.dart';
import '../../../data/models/leaderboard_entry.dart';
import '../../../data/models/level_config.dart';
import '../../../data/models/player_progress_record.dart';
import '../../../data/repositories/booster_inventory_repository.dart';
import '../../../data/repositories/leaderboard_repository.dart';
import '../../../data/repositories/level_repository.dart';
import '../../../data/repositories/progress_repository.dart';
import '../../boosters/domain/booster_type.dart';
import '../../grid_logic/domain/entities/grid_state.dart';
import '../../kingdom_map/controllers/kingdom_map_controller.dart';
import '../../onboarding/controllers/tutorial_controller.dart';
import '../../onboarding/presentation/tutorial_overlay.dart';
import '../../settings/controllers/settings_controller.dart';
import '../controllers/gameplay_controller.dart';
import '../controllers/gameplay_outcome.dart';
import '../controllers/gameplay_session.dart';
import '../game/candy_alchemy_game.dart';
import '../game/level_config_grid_state_factory.dart';
import 'gameplay_hud.dart';

/// Gameplay screen in the Flutter UI layer.
///
/// PLACEMENT_NOTE: ARCHITECTURE.md §4 lists gameplay components/game/controllers
/// but Step 11 requires Flutter HUD widgets; presentation is the nearest parent.
class GameplayScreen extends StatefulWidget {
  /// Creates the Candy Alchemy Gameplay screen.
  const GameplayScreen({super.key});

  /// Creates state for the gameplay screen.
  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  late final GameplayController _gameplayController;
  late final SettingsController _settingsController;
  late final TutorialController? _tutorialController;
  late final GameplaySession _session;
  late final Future<_LoadedGameplayLevel> _loadedLevelFuture;
  late final Worker _endStateWorker;
  final LevelConfigGridStateFactory _gridStateFactory =
      const LevelConfigGridStateFactory();
  var _didHandleEndState = false;

  @override
  void initState() {
    super.initState();
    _gameplayController = Get.find<GameplayController>();
    _settingsController = Get.find<SettingsController>();
    _tutorialController = Get.isRegistered<TutorialController>()
        ? Get.find<TutorialController>()
        : null;
    _session = _sessionFromArguments(Get.arguments);
    _gameplayController.resetForSession(_session);
    _endStateWorker = ever<GameplayEndState>(
      _gameplayController.endState,
      _handleEndState,
    );
    _loadedLevelFuture = _loadGameplayLevel(_session);
  }

  @override
  void dispose() {
    _endStateWorker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LoadedGameplayLevel>(
      future: _loadedLevelFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _GameplayLoadError(error: snapshot.error);
        }
        final loadedLevel = snapshot.data;
        if (loadedLevel == null) {
          return _GameplayLoading(levelNumber: _session.levelNumber);
        }

        return Scaffold(
          body: Stack(
            children: [
              GameWidget<CandyAlchemyGame>.controlled(
                gameFactory: () => CandyAlchemyGame(
                  initialGridState: loadedLevel.gridState,
                  onAcceptedSwap: _gameplayController.recordAcceptedSwap,
                  onCascadeStepClear:
                      _gameplayController.recordCascadeStepClear,
                  onCascadeStepResolved:
                      _gameplayController.recordCascadeStepResolved,
                  onCascadeSettled: _gameplayController.recordCascadeSettled,
                  isInputEnabledProvider: () =>
                      _gameplayController.isGameplayInputEnabled,
                  onFrameTick: _gameplayController.advanceTempoMeterBurst,
                  selectedBoosterProvider:
                      _gameplayController.activeBoosterForBoard,
                  onBoosterActivated:
                      _gameplayController.consumeSelectedBooster,
                  reduceMotionProvider: () =>
                      _settingsController.reduceMotionEnabled,
                  feedback: _gameplayController.feedback,
                ),
              ),
              GameplayHUD(
                gameplayController: _gameplayController,
                onRestartLevel: _restartLevel,
              ),
              if (_tutorialController != null)
                TutorialOverlay(
                  controller: _tutorialController,
                  onContinue: _completeTutorialPrompt,
                  onSkipAll: _skipAllTutorials,
                ),
            ],
          ),
        );
      },
    );
  }

  void _restartLevel() {
    final restartSession = GameplaySession(
      levelId: _session.levelId,
      levelNumber: _session.levelNumber,
      kingdomName: _session.kingdomName,
      goalLabel: _session.goalLabel,
      moveLimit: _session.moveLimit,
      selectedPreGameBoosters: const [],
    );
    Get.offNamed(AppRoutes.gameplay, arguments: restartSession);
  }

  Future<_LoadedGameplayLevel> _loadGameplayLevel(
    GameplaySession session,
  ) async {
    final levelConfig = await Get.find<LevelRepository>().loadLevelConfig(
      session.levelId,
    );
    final selectedBoosters = _selectedBoostersForConfig(
      session: session,
      levelConfig: levelConfig,
    );
    final previousProgress = await _previousProgressFor(levelConfig.levelId);
    _gameplayController.resetForLevel(
      nextLevelId: levelConfig.levelId,
      nextLevelNumber: session.levelNumber,
      nextKingdomName: session.kingdomName,
      moveLimit: levelConfig.moveLimit ?? session.moveLimit,
      nextGoalLabel: levelConfig.goalLabel,
      selectedPreGameBoosters: selectedBoosters,
      nextGameGoal: levelConfig.gameGoal,
      nextStarThresholds: levelConfig.starThresholds,
      previousBestScore: previousProgress?.bestScore ?? 0,
      previousBestStars: previousProgress?.stars ?? 0,
    );
    await _prepareTutorialForLevel(session.levelNumber);
    return _LoadedGameplayLevel(
      gridState: _gridStateFactory.create(levelConfig),
    );
  }

  Future<void> _prepareTutorialForLevel(int levelNumber) async {
    final tutorialController = _tutorialController;
    if (tutorialController == null) {
      return;
    }
    final tutorial = await tutorialController.prepareForLevel(levelNumber);
    if (tutorial != null) {
      _gameplayController.pauseGameplay();
    }
  }

  Future<void> _completeTutorialPrompt() async {
    await _tutorialController?.completeActiveTutorial();
    _gameplayController.resumeGameplay();
  }

  Future<void> _skipAllTutorials() async {
    await _tutorialController?.skipAllTutorials();
    _gameplayController.resumeGameplay();
  }

  Future<PlayerProgressRecord?> _previousProgressFor(String levelId) async {
    if (!Get.isRegistered<ProgressRepository>()) {
      return null;
    }
    try {
      final records = await Get.find<ProgressRepository>().loadProgress(
        defaultLocalPlayerId,
      );
      for (final record in records) {
        if (record.levelId == levelId) {
          return record;
        }
      }
    } on Object {
      // Offline progress lookup must never block the gameplay route.
    }
    return null;
  }

  void _handleEndState(GameplayEndState endState) {
    if (!mounted ||
        _didHandleEndState ||
        endState == GameplayEndState.playing) {
      return;
    }
    final outcome = _gameplayController.gameplayOutcome.value;
    if (outcome == null) {
      return;
    }
    _didHandleEndState = true;
    if (endState == GameplayEndState.won) {
      _markMapProgress(outcome);
      unawaited(_persistWinOutcome(outcome));
      Get.offNamed(AppRoutes.winOverlay, arguments: outcome);
      return;
    }
    Get.offNamed(AppRoutes.loseOverlay, arguments: outcome);
  }

  void _markMapProgress(GameplayOutcome outcome) {
    if (!Get.isRegistered<KingdomMapController>()) {
      return;
    }
    Get.find<KingdomMapController>().completeLevel(
      outcome.levelNumber,
      stars: outcome.bestStars,
      bestScore: outcome.bestScore,
    );
  }

  Future<void> _persistWinOutcome(GameplayOutcome outcome) async {
    final completedAt = DateTime.now().toUtc();
    try {
      if (Get.isRegistered<ProgressRepository>()) {
        await Get.find<ProgressRepository>().saveProgress(
          PlayerProgressRecord(
            playerId: defaultLocalPlayerId,
            levelId: outcome.levelId,
            stars: outcome.bestStars,
            bestScore: outcome.bestScore,
            completedAt: completedAt,
          ),
        );
      }
      if (Get.isRegistered<LeaderboardRepository>()) {
        await Get.find<LeaderboardRepository>().submitScore(
          LeaderboardEntry(
            playerId: defaultLocalPlayerId,
            chapter: _chapterForLevel(outcome.levelNumber),
            score: outcome.score,
            updatedAt: completedAt,
          ),
        );
      }
      if (outcome.rewardBoosterType != null &&
          Get.isRegistered<BoosterInventoryRepository>()) {
        await Get.find<BoosterInventoryRepository>().addBooster(
          playerId: defaultLocalPlayerId,
          boosterType: outcome.rewardBoosterType!,
        );
      }
    } on Object {
      // Offline sync must never block the win overlay or crash gameplay.
    }
  }

  int _chapterForLevel(int levelNumber) {
    return ((levelNumber - 1) ~/ v1LevelsPerKingdom) + 1;
  }

  List<BoosterType> _selectedBoostersForConfig({
    required GameplaySession session,
    required LevelConfig levelConfig,
  }) {
    return [
      for (final boosterType in session.selectedPreGameBoosters)
        if (levelConfig.preLevelBoosters.contains(boosterType)) boosterType,
    ];
  }

  GameplaySession _sessionFromArguments(Object? arguments) {
    if (arguments is GameplaySession) {
      return arguments;
    }

    final levelNumber = arguments is int ? arguments : 1;
    if (Get.isRegistered<KingdomMapController>()) {
      try {
        final level = Get.find<KingdomMapController>().levelByNumber(
          levelNumber,
        );
        return GameplaySession.fromLevel(
          level: level,
          selectedPreGameBoosters: const [],
        );
      } on RangeError {
        // PLACEMENT_NOTE: fallback keeps direct prototype routes usable.
      }
    }

    return GameplaySession(
      levelId: LevelConfigGenerator.levelIdForNumber(levelNumber),
      levelNumber: levelNumber,
      kingdomName: 'Sugar Meadow',
      goalLabel: 'Score ${3000 + levelNumber * 250}',
      moveLimit: _fallbackMoveLimitFor(levelNumber),
      selectedPreGameBoosters: const [],
    );
  }

  int _fallbackMoveLimitFor(int levelNumber) {
    return 18 + levelNumber % 7;
  }
}

/// Loaded gameplay data in the Flutter presentation layer.
class _LoadedGameplayLevel {
  const _LoadedGameplayLevel({required this.gridState});

  final GridState gridState;
}

/// Loading state for LevelConfig-backed gameplay.
class _GameplayLoading extends StatelessWidget {
  const _GameplayLoading({required this.levelNumber});

  final int levelNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CandyAlchemyColors.gameplayBackground,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: CandyAlchemyColors.citrus),
              const SizedBox(height: uiControlGap),
              Text(
                'Loading Level $levelNumber',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: CandyAlchemyColors.cream,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Error state shown when a LevelConfig asset cannot load.
class _GameplayLoadError extends StatelessWidget {
  const _GameplayLoadError({required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CandyAlchemyColors.gameplayBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(uiScreenPadding),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_rounded,
                  color: CandyAlchemyColors.molten,
                  size: gameplayHudBoosterButtonSize,
                ),
                const SizedBox(height: uiControlGap),
                Text(
                  'Level failed to load',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: CandyAlchemyColors.cream,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: uiControlGap),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: CandyAlchemyColors.tileHighlight,
                  ),
                ),
                const SizedBox(height: uiSectionGap),
                FilledButton.icon(
                  onPressed: () => Get.offNamed(AppRoutes.kingdomMap),
                  icon: const Icon(Icons.map_rounded),
                  label: const Text('Map'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
