import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/navigation_constants.dart';
import '../controllers/gameplay_controller.dart';
import '../game/candy_alchemy_game.dart';
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

  @override
  void initState() {
    super.initState();
    _gameplayController = Get.find<GameplayController>();
    final levelNumber = Get.arguments is int ? Get.arguments as int : 1;
    _gameplayController.resetForLevel(
      nextLevelId: 'chapter1_level$levelNumber',
      nextLevelNumber: levelNumber,
      moveLimit: 20,
      nextGoalLabel: 'Score 5000',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget<CandyAlchemyGame>.controlled(
            gameFactory: () => CandyAlchemyGame(
              onAcceptedSwap: _gameplayController.recordAcceptedSwap,
              onCascadeStepClear: _gameplayController.recordCascadeStepClear,
              onFrameTick: _gameplayController.advanceTempoMeterBurst,
              feedback: _gameplayController.feedback,
            ),
          ),
          GameplayHUD(gameplayController: _gameplayController),
          Positioned(
            left: 16,
            bottom: 16,
            child: SafeArea(
              child: IconButton.filledTonal(
                onPressed: () => Get.offNamed(AppRoutes.levelMap),
                icon: const Icon(Icons.map_rounded),
                tooltip: 'Level Map',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
