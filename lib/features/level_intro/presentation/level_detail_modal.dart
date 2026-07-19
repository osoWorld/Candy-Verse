import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/navigation_constants.dart';
import '../../boosters/domain/booster_type.dart';
import '../../gameplay/controllers/gameplay_session.dart';
import '../../kingdom_map/domain/kingdom_level_definition.dart';
import '../../kingdom_map/domain/level_difficulty.dart';
import '../controllers/level_intro_controller.dart';

/// Level Detail Modal in the Flutter UI layer.
class LevelDetailModal extends StatelessWidget {
  /// Creates the pre-game modal for [level].
  const LevelDetailModal({
    required this.level,
    required this.levelIntroController,
    super.key,
  });

  /// Level shown by this modal.
  final KingdomLevelDefinition level;

  /// Controller holding modal state.
  final LevelIntroController levelIntroController;

  /// Shows a LevelDetailModal for [level].
  ///
  /// Inputs: level definition. Output: dialog future. Side effects: opens a
  /// GetX dialog route.
  static Future<T?> show<T>(
    KingdomLevelDefinition level, {
    int bestScore = 0,
    int bestStars = 0,
  }) {
    return Get.dialog<T>(
      LevelDetailModal(
        level: level,
        levelIntroController: LevelIntroController(
          level: level,
          initialBestScore: bestScore,
          initialBestStars: bestStars,
        ),
      ),
    );
  }

  /// Builds the level detail modal.
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8ED),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Level ${level.levelNumber}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: const Color(0xFF2B174A),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: Get.back,
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Close',
                        color: const Color(0xFF2B174A),
                      ),
                    ],
                  ),
                  Text(
                    level.kingdomName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF6B4DFF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _DifficultyBadge(difficulty: level.difficulty),
                  ),
                  const SizedBox(height: 16),
                  _GoalPanel(level: level),
                  const SizedBox(height: 12),
                  Obx(
                    () => _BestProgressPanel(
                      bestScore: levelIntroController.bestScore.value,
                      bestStars: levelIntroController.bestStars.value,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Friends',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF2B174A),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      Obx(
                        () => Text(
                          levelIntroController.friendScoreSourceLabel.value,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: const Color(0xAA2B174A),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Obx(
                    () => Column(
                      children: [
                        for (final friendScore
                            in levelIntroController.friendScores)
                          _FriendScoreRow(
                            name: friendScore.name,
                            score: friendScore.score,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Choose boosters',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF2B174A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final booster in level.preGameBoosters)
                        Obx(
                          () => _BoosterButton(
                            boosterName: booster,
                            count: levelIntroController.boosterCountForName(
                              booster,
                            ),
                            isSelected: levelIntroController.isBoosterSelected(
                              booster,
                            ),
                            isEnabled: levelIntroController.canSelectBooster(
                              booster,
                            ),
                            onPressed: () =>
                                levelIntroController.toggleBooster(booster),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD84D), Color(0xFFFF9A3D)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Obx(
                      () => TextButton.icon(
                        onPressed:
                            levelIntroController.isConsumingBoosters.value
                            ? null
                            : _playLevel,
                        icon: Icon(
                          levelIntroController.isConsumingBoosters.value
                              ? Icons.hourglass_top_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        label: Text(
                          levelIntroController.isConsumingBoosters.value
                              ? 'Preparing'
                              : 'Play',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2B174A),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          textStyle: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _playLevel() async {
    final didConsume = await levelIntroController.consumeSelectedBoosters();
    if (!didConsume) {
      Get.snackbar(
        'Booster unavailable',
        'One selected booster is out of stock.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final selectedBoosters = [
      for (final boosterName in levelIntroController.selectedPreGameBoosters)
        ?tryParseBoosterType(boosterName),
    ];
    Get.back<void>();
    Get.toNamed(
      AppRoutes.gameplay,
      arguments: GameplaySession.fromLevel(
        level: level,
        selectedPreGameBoosters: selectedBoosters,
      ),
    );
  }
}

class _BestProgressPanel extends StatelessWidget {
  const _BestProgressPanel({required this.bestScore, required this.bestStars});

  final int bestScore;
  final int bestStars;

  @override
  Widget build(BuildContext context) {
    final hasProgress = bestScore > 0 || bestStars > 0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2B8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFC83D), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFFF9A3D),
              size: 28,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasProgress ? 'Your best' : 'No personal best yet',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF2B174A),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (hasProgress) ...[
              Text(
                '$bestScore',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF2B174A),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < 3; index += 1)
                    Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: index < bestStars
                          ? const Color(0xFFFFA929)
                          : const Color(0x662B174A),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GoalPanel extends StatelessWidget {
  const _GoalPanel({required this.level});

  final KingdomLevelDefinition level;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFC83D), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.flag_rounded, color: Color(0xFFFF5FA2), size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Goal',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF6B4DFF),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    level.goalLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF2B174A),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                const Icon(Icons.swap_horiz_rounded, color: Color(0xFF35D0C3)),
                Text(
                  '${level.moveLimit}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF2B174A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendScoreRow extends StatelessWidget {
  const _FriendScoreRow({required this.name, required this.score});

  final String name;
  final int score;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFFF5FA2),
            foregroundColor: Colors.white,
            child: Text(name.characters.first),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF2B174A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '$score',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF2B174A),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _BoosterButton extends StatelessWidget {
  const _BoosterButton({
    required this.boosterName,
    required this.count,
    required this.isSelected,
    required this.isEnabled,
    required this.onPressed,
  });

  final String boosterName;
  final int count;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: boosterName,
      child: SizedBox.square(
        dimension: 78,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: TextButton(
                onPressed: isEnabled ? onPressed : null,
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFFFFC83D)
                          : const Color(0x336B4DFF),
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  backgroundColor: isSelected
                      ? const Color(0xFFFFF2B8)
                      : const Color(0xFFFFFFFF),
                  disabledBackgroundColor: const Color(0xFFE7DFD2),
                  foregroundColor: const Color(0xFF2B174A),
                  disabledForegroundColor: const Color(0x772B174A),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_boosterIcon(boosterName), size: 28),
                    const SizedBox(height: 4),
                    Text(
                      _shortBoosterLabel(boosterName),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -6,
              right: -6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isEnabled
                      ? const Color(0xFFFF5FA2)
                      : const Color(0xFF6D6580),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: SizedBox.square(
                  dimension: 24,
                  child: Center(
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _boosterIcon(String boosterName) {
    return switch (boosterName) {
      'Fusion Booster' => Icons.auto_awesome_rounded,
      'Architect Tile' => Icons.architecture_rounded,
      'Echo Candy' => Icons.graphic_eq_rounded,
      _ => Icons.bolt_rounded,
    };
  }

  String _shortBoosterLabel(String boosterName) {
    return switch (boosterName) {
      'Fusion Booster' => 'Fusion',
      'Architect Tile' => 'Architect',
      'Echo Candy' => 'Echo',
      _ => boosterName,
    };
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});

  final LevelDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final label = _difficultyLabel(difficulty);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _difficultyColor(difficulty),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_difficultyIcon(difficulty), size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _difficultyLabel(LevelDifficulty difficulty) {
  return switch (difficulty) {
    LevelDifficulty.simple => 'Simple',
    LevelDifficulty.hard => 'Hard',
    LevelDifficulty.superHard => 'Super Hard',
    LevelDifficulty.nightmarishlyHard => 'Nightmare',
    LevelDifficulty.legendary => 'Legendary',
  };
}

Color _difficultyColor(LevelDifficulty difficulty) {
  return switch (difficulty) {
    LevelDifficulty.simple => const Color(0xFF35C990),
    LevelDifficulty.hard => const Color(0xFFC43A8D),
    LevelDifficulty.superHard => const Color(0xFFFF6B22),
    LevelDifficulty.nightmarishlyHard => const Color(0xFF6B4DFF),
    LevelDifficulty.legendary => const Color(0xFFFFA929),
  };
}

IconData _difficultyIcon(LevelDifficulty difficulty) {
  return switch (difficulty) {
    LevelDifficulty.simple => Icons.check_circle_rounded,
    LevelDifficulty.hard => Icons.whatshot_rounded,
    LevelDifficulty.superHard => Icons.local_fire_department_rounded,
    LevelDifficulty.nightmarishlyHard => Icons.bolt_rounded,
    LevelDifficulty.legendary => Icons.workspace_premium_rounded,
  };
}
