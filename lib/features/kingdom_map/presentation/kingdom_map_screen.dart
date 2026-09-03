import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:get/get.dart';

import '../../../core/constants/ui_constants.dart';
import '../../boosters/domain/booster_type.dart';
import '../../level_intro/presentation/level_detail_modal.dart';
import '../../profile/presentation/player_profile_dialog.dart';
import '../controllers/kingdom_map_controller.dart';
import '../domain/kingdom_definition.dart';
import '../domain/kingdom_gate_definition.dart';
import '../domain/kingdom_level_definition.dart';
import '../domain/kingdom_story_moment.dart';
import '../domain/level_difficulty.dart';

/// KingdomMapScreen in the Flutter UI layer.
class KingdomMapScreen extends GetView<KingdomMapController> {
  /// Creates the Candy Alchemy Kingdom Map screen.
  const KingdomMapScreen({super.key});

  /// Builds the old-style kingdom journey map.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF130B24),
      body: SafeArea(
        child: CustomScrollView(
          scrollCacheExtent: const ScrollCacheExtent.pixels(
            kingdomMapScrollCacheExtent,
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: Get.back,
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Alchemy Kingdoms',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: const Color(0xFFFFF8ED),
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          Text(
                            'Choose a level',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xCCFFF8ED)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      onPressed: () =>
                          unawaited(showPlayerProfileDialog<void>()),
                      icon: const Icon(Icons.person_rounded),
                      tooltip: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
            _KingdomMapSlivers(controller: controller),
          ],
        ),
      ),
    );
  }
}

/// Reactive kingdom map body for loaded, loading, and error states.
class _KingdomMapSlivers extends StatelessWidget {
  const _KingdomMapSlivers({required this.controller});

  final KingdomMapController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingKingdoms.value) {
        return const SliverFillRemaining(
          hasScrollBody: false,
          child: _KingdomMapStatusPanel(
            icon: Icons.map_rounded,
            title: 'Loading kingdoms',
            message: 'Preparing the alchemy road.',
          ),
        );
      }

      final loadError = controller.kingdomLoadError.value;
      if (loadError.isNotEmpty) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: _KingdomMapStatusPanel(
            icon: Icons.error_outline_rounded,
            title: 'Map unavailable',
            message: loadError,
            actionLabel: 'Retry',
            onActionPressed: controller.loadKingdoms,
          ),
        );
      }

      _schedulePendingGateRewardDialog(controller);

      // Use SliverList.builder instead of SliverFixedExtentList for lazy
      // building. Disable automatic keep-alives so disposed kingdoms release
      // their widget trees and painter caches.
      return SliverList.builder(
        itemCount: controller.kingdoms.length,
        addAutomaticKeepAlives: false,
        itemBuilder: (context, index) {
          final kingdom = controller.kingdoms[index];
          return SizedBox(
            height: kingdomMapSectionSliverExtent,
            child: _KingdomSection(kingdom: kingdom, controller: controller),
          );
        },
      );
    });
  }
}

/// Centered status panel for kingdom map asset loading states.
class _KingdomMapStatusPanel extends StatelessWidget {
  const _KingdomMapStatusPanel({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onActionPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0x22FFF8ED),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0x55FFF8ED)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: const Color(0xFFFFF8ED), size: 36),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFFFFF8ED),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xCCFFF8ED),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (actionLabel != null && onActionPressed != null) ...[
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: onActionPressed,
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single kingdom's visual section inside the map scroll view.
///
/// Uses [StatefulWidget] to cache expensive painters in state so they are
/// created once and reused across rebuilds instead of allocating new objects
/// every frame.
class _KingdomSection extends StatefulWidget {
  const _KingdomSection({required this.kingdom, required this.controller});

  final KingdomDefinition kingdom;
  final KingdomMapController controller;

  @override
  State<_KingdomSection> createState() => _KingdomSectionState();
}

class _KingdomSectionState extends State<_KingdomSection> {
  late Color _backgroundColor;
  late Color _secondaryColor;
  late Color _accentColor;

  // Cache painters so they are not re-allocated on every build.
  late _KingdomMotifPainter _motifPainter;
  late _KingdomPathPainter _pathPainter;

  @override
  void initState() {
    super.initState();
    _backgroundColor = Color(widget.kingdom.backgroundColorValue);
    _secondaryColor = Color(widget.kingdom.secondaryColorValue);
    _accentColor = Color(widget.kingdom.accentColorValue);
    _motifPainter = _KingdomMotifPainter(
      motifs: widget.kingdom.mapMotifs,
      backgroundColor: _backgroundColor,
      secondaryColor: _secondaryColor,
      accentColor: _accentColor,
    );
    _pathPainter = _KingdomPathPainter(
      accentColor: _accentColor,
      pathColor: const Color(0xFFFFF8ED),
    );
  }

  @override
  void didUpdateWidget(covariant _KingdomSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.kingdom.kingdomId != widget.kingdom.kingdomId) {
      _backgroundColor = Color(widget.kingdom.backgroundColorValue);
      _secondaryColor = Color(widget.kingdom.secondaryColorValue);
      _accentColor = Color(widget.kingdom.accentColorValue);
      _motifPainter = _KingdomMotifPainter(
        motifs: widget.kingdom.mapMotifs,
        backgroundColor: _backgroundColor,
        secondaryColor: _secondaryColor,
        accentColor: _accentColor,
      );
      _pathPainter = _KingdomPathPainter(
        accentColor: _accentColor,
        pathColor: const Color(0xFFFFF8ED),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final kingdom = widget.kingdom;
    final controller = widget.controller;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        12,
        kingdomMapSectionPaddingTop,
        12,
        kingdomMapSectionPaddingBottom,
      ),
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_backgroundColor, _secondaryColor],
            ),
            borderRadius: BorderRadius.circular(kingdomMapSectionRadius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kingdomMapSectionRadius),
            child: SizedBox(
              height: kingdomMapSectionHeight,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final sectionSize = Size(
                    constraints.maxWidth,
                    kingdomMapSectionHeight,
                  );
                  return Stack(
                    children: [
                      // Background motifs — cached painter, painted once.
                      RepaintBoundary(
                        child: CustomPaint(
                          key: ValueKey('kingdom-motifs-${kingdom.kingdomId}'),
                          isComplex: true,
                          willChange: false,
                          size: sectionSize,
                          painter: _motifPainter,
                        ),
                      ),
                      // Candy path — cached painter, painted once.
                      RepaintBoundary(
                        child: CustomPaint(
                          key: ValueKey('kingdom-path-${kingdom.kingdomId}'),
                          isComplex: true,
                          willChange: false,
                          size: sectionSize,
                          painter: _pathPainter,
                        ),
                      ),
                      // Story intro panel.
                      Positioned(
                        left: 16,
                        right: 16,
                        top: 18,
                        child: _StoryPanel(
                          kingdom: kingdom,
                          controller: controller,
                          moment: KingdomStoryMoment.intro,
                          accentColor: _accentColor,
                        ),
                      ),
                      // Character badge.
                      Positioned(
                        left: 16,
                        right: 16,
                        top: 138,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: _CharacterBadge(
                            kingdomId: kingdom.kingdomId,
                            names: kingdom.characterNames,
                            accentColor: _accentColor,
                            onPressed: () => _showCharacterPanel(
                              kingdom: kingdom,
                              accentColor: _accentColor,
                            ),
                          ),
                        ),
                      ),
                      // Level nodes — built as a list of lightweight widgets.
                      for (
                        var index = 0;
                        index < kingdom.levels.length;
                        index += 1
                      )
                        _PositionedLevelNode(
                          level: kingdom.levels[index],
                          left:
                              _nodeCenterX(index, constraints.maxWidth) -
                              levelMapNodeSize / 2,
                          top:
                              kingdomMapNodeStartY +
                              index * kingdomMapNodeStepY,
                          controller: controller,
                        ),
                      // Gate nodes.
                      for (final gate in kingdom.gates)
                        _PositionedGateNode(
                          gate: gate,
                          left:
                              _gateCenterX(
                                gate.gateIndex,
                                constraints.maxWidth,
                              ) -
                              kingdomMapGateWidth / 2,
                          top: _gateTop(gate),
                          controller: controller,
                          accentColor: _accentColor,
                        ),
                      // Story outro panel.
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 18,
                        child: _StoryPanel(
                          kingdom: kingdom,
                          controller: controller,
                          moment: KingdomStoryMoment.outro,
                          accentColor: _accentColor,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _nodeCenterX(int index, double width) {
    const factors = [0.24, 0.42, 0.68, 0.76, 0.56, 0.32];
    return width * factors[index % factors.length];
  }

  double _gateCenterX(int gateIndex, double width) {
    const factors = [0.64, 0.32, 0.7, 0.38];
    return width * factors[(gateIndex - 1) % factors.length];
  }

  double _gateTop(KingdomGateDefinition gate) {
    final checkpointOffset = gate.checkpointLevel - widget.kingdom.levelStart;
    return kingdomMapNodeStartY +
        checkpointOffset * kingdomMapNodeStepY +
        levelMapNodeSize * 0.54;
  }
}

class _PositionedGateNode extends StatelessWidget {
  const _PositionedGateNode({
    required this.gate,
    required this.left,
    required this.top,
    required this.controller,
    required this.accentColor,
  });

  final KingdomGateDefinition gate;
  final double left;
  final double top;
  final KingdomMapController controller;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Obx(() {
        final isUnlocked = controller.isGateUnlocked(gate);
        final isClaimed = controller.isGateRewardClaimed(gate);
        return RepaintBoundary(
          child: _GateNode(
            gate: gate,
            isUnlocked: isUnlocked,
            isClaimed: isClaimed,
            accentColor: accentColor,
            onPressed: isUnlocked
                ? () => _showGateRewardDialog(
                    controller: controller,
                    gate: gate,
                    accentColor: accentColor,
                    autoPresented: false,
                  )
                : () => Get.snackbar(
                    'Gate locked',
                    'Complete level ${gate.checkpointLevel} to open ${gate.title}.',
                    snackPosition: SnackPosition.BOTTOM,
                  ),
          ),
        );
      }),
    );
  }
}

class _GateNode extends StatelessWidget {
  const _GateNode({
    required this.gate,
    required this.isUnlocked,
    required this.isClaimed,
    required this.accentColor,
    required this.onPressed,
  });

  final KingdomGateDefinition gate;
  final bool isUnlocked;
  final bool isClaimed;
  final Color accentColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isUnlocked
        ? const Color(0xFF2B174A)
        : const Color(0xFFFFF8ED);
    final backgroundColor = isUnlocked
        ? const Color(0xFFFFF8ED)
        : const Color(0xFF6D6580);
    final borderColor = isUnlocked ? accentColor : const Color(0x99FFF8ED);
    final statusLabel = isUnlocked
        ? isClaimed
              ? 'Claimed'
              : 'Reward'
        : 'Locked';

    return Tooltip(
      message: _gateTooltip(gate, isUnlocked: isUnlocked, isClaimed: isClaimed),
      child: SizedBox(
        width: kingdomMapGateWidth,
        height: kingdomMapGateHeight,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onPressed,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(
                      alpha: isUnlocked ? 0.26 : 0.1,
                    ),
                    blurRadius: isUnlocked ? 16 : 8,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Icon(
                      isUnlocked
                          ? gate.isFinalGate
                                ? Icons.castle_rounded
                                : Icons.emoji_events_rounded
                          : Icons.lock_rounded,
                      color: isUnlocked ? accentColor : foregroundColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gate.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: foregroundColor,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          Text(
                            statusLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: foregroundColor.withValues(
                                    alpha: 0.78,
                                  ),
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (isUnlocked && !isClaimed)
                      const Icon(
                        Icons.card_giftcard_rounded,
                        color: Color(0xFFFFC83D),
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PositionedLevelNode extends StatelessWidget {
  const _PositionedLevelNode({
    required this.level,
    required this.left,
    required this.top,
    required this.controller,
  });

  final KingdomLevelDefinition level;
  final double left;
  final double top;
  final KingdomMapController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Obx(() {
        final isUnlocked = controller.isLevelUnlocked(level.levelNumber);
        final stars = controller.starsForLevel(level.levelNumber);
        return RepaintBoundary(
          child: _LevelNode(
            level: level,
            isUnlocked: isUnlocked,
            stars: stars,
            onPressed: isUnlocked
                ? () => LevelDetailModal.show<void>(
                    level,
                    bestScore: controller.bestScoreForLevel(level.levelNumber),
                    bestStars: stars,
                  )
                : () => Get.snackbar(
                    'Locked',
                    'Complete level ${level.levelNumber - 1} first.',
                    snackPosition: SnackPosition.BOTTOM,
                  ),
          ),
        );
      }),
    );
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.level,
    required this.isUnlocked,
    required this.stars,
    required this.onPressed,
  });

  final KingdomLevelDefinition level;
  final bool isUnlocked;
  final int stars;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final nodeColor = isUnlocked
        ? const Color(0xFFFFC83D)
        : const Color(0xFF6D6580);
    return Tooltip(
      message: isUnlocked
          ? 'Open Level ${level.levelNumber}'
          : 'Locked Level ${level.levelNumber}',
      child: SizedBox(
        width: levelMapNodeSize + 18,
        height: levelMapNodeSize + 26,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: nodeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: SizedBox.square(
                  dimension: levelMapNodeSize,
                  child: TextButton(
                    onPressed: onPressed,
                    style: TextButton.styleFrom(
                      shape: const CircleBorder(),
                      foregroundColor: const Color(0xFF2B174A),
                    ),
                    child: isUnlocked
                        ? Text(
                            '${level.levelNumber}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          )
                        : const Icon(Icons.lock_rounded),
                  ),
                ),
              ),
            ),
            if (level.difficulty != LevelDifficulty.simple)
              Positioned(
                top: 0,
                right: 2,
                child: _DifficultyDot(difficulty: level.difficulty),
              ),
            if (stars > 0)
              Positioned(
                bottom: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < stars; index += 1)
                      const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Color(0xFFFFF8ED),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyDot extends StatelessWidget {
  const _DifficultyDot({required this.difficulty});

  final LevelDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _difficultyColor(difficulty),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: SizedBox.square(
        dimension: 22,
        child: Icon(_difficultyIcon(difficulty), size: 13, color: Colors.white),
      ),
    );
  }
}

class _StoryPanel extends StatelessWidget {
  const _StoryPanel({
    required this.kingdom,
    required this.controller,
    required this.moment,
    required this.accentColor,
  });

  final KingdomDefinition kingdom;
  final KingdomMapController controller;
  final KingdomStoryMoment moment;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isIntro = moment == KingdomStoryMoment.intro;
    final panelColor = isIntro
        ? const Color(0xEFFFF8ED)
        : const Color(0xDD130B24);
    final textColor = isIntro
        ? const Color(0xFF2B174A)
        : const Color(0xFFFFF8ED);

    return Obx(() {
      final isAvailable = controller.isStoryMomentAvailable(kingdom, moment);
      final isSeen = controller.isStoryPanelSeen(
        kingdomId: kingdom.kingdomId,
        moment: moment,
      );
      final storyText = isIntro
          ? kingdom.introStory
          : isAvailable
          ? kingdom.outroStory
          : 'Complete level ${kingdom.levelEnd} to reveal the finale.';

      return Tooltip(
        message: isAvailable
            ? _storyPanelTooltip(moment, kingdom.name)
            : 'Finale locked',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => unawaited(
              _showKingdomStoryPanel(
                controller: controller,
                kingdom: kingdom,
                moment: moment,
                accentColor: accentColor,
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSeen
                      ? textColor.withValues(alpha: 0.18)
                      : accentColor,
                  width: isSeen ? 1.5 : 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: isSeen ? 0.12 : 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    _CharacterPortrait(
                      name: kingdom.characterName,
                      accentColor: accentColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                _storyPanelTitle(moment, kingdom.name),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: textColor,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              if (!isSeen && isAvailable)
                                _StoryBadge(
                                  label: 'New',
                                  color: accentColor,
                                  textColor: isIntro
                                      ? const Color(0xFF2B174A)
                                      : const Color(0xFFFFF8ED),
                                ),
                              if (!isAvailable)
                                const _StoryBadge(
                                  label: 'Locked',
                                  color: Color(0xFF6D6580),
                                  textColor: Color(0xFFFFF8ED),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            storyText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: textColor.withValues(alpha: 0.88),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isAvailable
                          ? Icons.chevron_right_rounded
                          : Icons.lock_rounded,
                      color: textColor.withValues(alpha: 0.84),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _StoryBadge extends StatelessWidget {
  const _StoryBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _CharacterBadge extends StatelessWidget {
  const _CharacterBadge({
    required this.kingdomId,
    required this.names,
    required this.accentColor,
    required this.onPressed,
  });

  final String kingdomId;
  final List<String> names;
  final Color accentColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final primaryName = names.isEmpty ? 'Kingdom Guide' : names.first;
    final secondaryName = names.length > 1 ? names[1] : null;
    return Tooltip(
      message: names.join(' and '),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 278),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onPressed,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8ED),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accentColor, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CharacterPortrait(
                      key: ValueKey('kingdom-character-$kingdomId'),
                      name: primaryName,
                      accentColor: accentColor,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            primaryName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: const Color(0xFF2B174A),
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          if (secondaryName != null)
                            Text(
                              '+ $secondaryName',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: const Color(0xCC2B174A),
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.info_rounded,
                      color: Color(0xFF2B174A),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _schedulePendingGateRewardDialog(KingdomMapController controller) {
  final gate = controller.reservePendingGateRewardForPresentation();
  if (gate == null) {
    return;
  }
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await _showGateRewardDialog(
        controller: controller,
        gate: gate,
        accentColor: _accentColorForGate(controller, gate),
        autoPresented: true,
      );
    } finally {
      controller.releaseGateRewardPresentation();
    }
  });
}

Future<void> _showGateRewardDialog({
  required KingdomMapController controller,
  required KingdomGateDefinition gate,
  required Color accentColor,
  required bool autoPresented,
}) async {
  final isClaimed = controller.isGateRewardClaimed(gate);
  await Get.dialog<void>(
    _GateRewardDialog(
      gate: gate,
      accentColor: accentColor,
      isClaimed: isClaimed,
      autoPresented: autoPresented,
      onCollect: isClaimed
          ? null
          : () async {
              await controller.claimGateReward(gate);
              Get.back<void>();
            },
    ),
    barrierDismissible: isClaimed,
  );
  if (isClaimed) {
    controller.clearPendingGateReward(gate);
  }
}

Future<void> _showKingdomStoryPanel({
  required KingdomMapController controller,
  required KingdomDefinition kingdom,
  required KingdomStoryMoment moment,
  required Color accentColor,
}) async {
  if (!controller.isStoryMomentAvailable(kingdom, moment)) {
    Get.snackbar(
      'Story locked',
      'Complete level ${kingdom.levelEnd} to reveal ${kingdom.name}.',
      snackPosition: SnackPosition.BOTTOM,
    );
    return;
  }
  await controller.markStoryPanelSeen(
    kingdomId: kingdom.kingdomId,
    moment: moment,
  );
  await Get.dialog<void>(
    _KingdomStoryDialog(
      kingdom: kingdom,
      moment: moment,
      accentColor: accentColor,
    ),
  );
}

void _showCharacterPanel({
  required KingdomDefinition kingdom,
  required Color accentColor,
}) {
  Get.dialog<void>(
    _CharacterPanelDialog(kingdom: kingdom, accentColor: accentColor),
  );
}

class _KingdomStoryDialog extends StatelessWidget {
  const _KingdomStoryDialog({
    required this.kingdom,
    required this.moment,
    required this.accentColor,
  });

  final KingdomDefinition kingdom;
  final KingdomStoryMoment moment;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isIntro = moment == KingdomStoryMoment.intro;
    return Dialog(
      backgroundColor: const Color(0xFFFFF8ED),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: accentColor, width: 3),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CharacterPortrait(
                    name: kingdom.characterName,
                    accentColor: accentColor,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StoryBadge(
                          label: isIntro ? 'Chapter Opens' : 'Finale',
                          color: accentColor,
                          textColor: const Color(0xFF2B174A),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _storyPanelTitle(moment, kingdom.name),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: const Color(0xFF2B174A),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Get.back<void>(),
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF2B174A),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _storyTextFor(kingdom, moment),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF2B174A),
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final characterName in kingdom.characterNames)
                    _CharacterChip(
                      name: characterName,
                      accentColor: accentColor,
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => Get.back<void>(),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharacterPanelDialog extends StatelessWidget {
  const _CharacterPanelDialog({
    required this.kingdom,
    required this.accentColor,
  });

  final KingdomDefinition kingdom;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFFFFF8ED),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: accentColor, width: 3),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${kingdom.name} Cast',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF2B174A),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Get.back<void>(),
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF2B174A),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final characterName in kingdom.characterNames) ...[
                _CharacterProfileRow(
                  name: characterName,
                  accentColor: accentColor,
                ),
                const SizedBox(height: 12),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => Get.back<void>(),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GateRewardDialog extends StatelessWidget {
  const _GateRewardDialog({
    required this.gate,
    required this.accentColor,
    required this.isClaimed,
    required this.autoPresented,
    required this.onCollect,
  });

  final KingdomGateDefinition gate;
  final Color accentColor;
  final bool isClaimed;
  final bool autoPresented;
  final Future<void> Function()? onCollect;

  @override
  Widget build(BuildContext context) {
    final title = gate.isFinalGate
        ? '${gate.kingdomName} Complete'
        : '${gate.title} Opened';
    final message = gate.isFinalGate
        ? 'The kingdom gate swings open and the road to the next kingdom glows.'
        : 'A candy checkpoint opens on the road. Collect your travel reward.';
    return Dialog(
      backgroundColor: const Color(0xFFFFF8ED),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: accentColor, width: 3),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor, width: 3),
                ),
                child: SizedBox.square(
                  dimension: 76,
                  child: Icon(
                    gate.isFinalGate
                        ? Icons.castle_rounded
                        : Icons.emoji_events_rounded,
                    color: const Color(0xFF2B174A),
                    size: 42,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF2B174A),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xDD2B174A),
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC83D),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _boosterIcon(gate.rewardBoosterType),
                        color: const Color(0xFF2B174A),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isClaimed ? 'Reward collected' : gate.rewardLabel,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF2B174A),
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isClaimed)
                    FilledButton.icon(
                      onPressed: () => Get.back<void>(),
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Done'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: onCollect == null
                          ? null
                          : () => unawaited(onCollect!()),
                      icon: const Icon(Icons.card_giftcard_rounded),
                      label: Text(autoPresented ? 'Collect' : 'Claim Reward'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharacterProfileRow extends StatelessWidget {
  const _CharacterProfileRow({required this.name, required this.accentColor});

  final String name;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CharacterPortrait(name: name, accentColor: accentColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF2B174A),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _characterRoleFor(name),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xDD2B174A),
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CharacterChip extends StatelessWidget {
  const _CharacterChip({required this.name, required this.accentColor});

  final String name;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accentColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          name,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xFF2B174A),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _CharacterPortrait extends StatelessWidget {
  const _CharacterPortrait({
    super.key,
    required this.name,
    required this.accentColor,
  });

  final String name;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.square(
        dimension: kingdomMapCharacterPortraitSize,
        child: CustomPaint(
          isComplex: true,
          willChange: false,
          painter: _CharacterPortraitPainter(
            name: name,
            accentColor: accentColor,
          ),
        ),
      ),
    );
  }
}

class _CharacterPortraitPainter extends CustomPainter {
  const _CharacterPortraitPainter({
    required this.name,
    required this.accentColor,
  });

  final String name;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outlinePaint = Paint()..color = const Color(0xFF2B174A);
    final glowPaint = Paint()..color = accentColor.withValues(alpha: 0.28);

    canvas.drawCircle(center.translate(0, 2), size.width * 0.46, glowPaint);

    if (name.contains('Pip')) {
      _paintPip(canvas, size, outlinePaint);
    } else if (name.contains('Caramel')) {
      _paintCaramelSage(canvas, size, outlinePaint);
    } else if (name.contains('Glacia')) {
      _paintQueenGlacia(canvas, size, outlinePaint);
    } else if (name.contains('Cocoa')) {
      _paintBaronCocoa(canvas, size, outlinePaint);
    } else if (name.contains('Ember')) {
      _paintEmberImp(canvas, size, outlinePaint);
    } else if (name.contains('Syrup')) {
      _paintSyrupSprite(canvas, size, outlinePaint);
    } else {
      _paintPip(canvas, size, outlinePaint);
    }
  }

  void _paintPip(Canvas canvas, Size size, Paint outlinePaint) {
    final cloakPaint = Paint()..color = const Color(0xFF35C990);
    final facePaint = Paint()..color = const Color(0xFFFFD8B8);
    final wandPaint = Paint()
      ..color = const Color(0xFFFFC83D)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    canvas
      ..drawOval(
        Rect.fromLTWH(
          size.width * 0.2,
          size.height * 0.34,
          size.width * 0.6,
          size.height * 0.5,
        ),
        outlinePaint,
      )
      ..drawOval(
        Rect.fromLTWH(
          size.width * 0.25,
          size.height * 0.37,
          size.width * 0.5,
          size.height * 0.42,
        ),
        cloakPaint,
      )
      ..drawCircle(
        Offset(size.width * 0.48, size.height * 0.3),
        size.width * 0.18,
        outlinePaint,
      )
      ..drawCircle(
        Offset(size.width * 0.48, size.height * 0.3),
        size.width * 0.14,
        facePaint,
      )
      ..drawLine(
        Offset(size.width * 0.66, size.height * 0.28),
        Offset(size.width * 0.88, size.height * 0.1),
        wandPaint,
      )
      ..drawCircle(
        Offset(size.width * 0.9, size.height * 0.08),
        size.width * 0.05,
        Paint()..color = const Color(0xFFFFF8ED),
      );
  }

  void _paintCaramelSage(Canvas canvas, Size size, Paint outlinePaint) {
    final robePaint = Paint()..color = const Color(0xFFB87333);
    final beardPaint = Paint()
      ..color = const Color(0xFFFFE0A8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    final staffPaint = Paint()
      ..color = const Color(0xFF7A4328)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.2,
            size.height * 0.3,
            size.width * 0.58,
            size.height * 0.55,
          ),
          const Radius.circular(12),
        ),
        outlinePaint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.25,
            size.height * 0.34,
            size.width * 0.48,
            size.height * 0.46,
          ),
          const Radius.circular(10),
        ),
        robePaint,
      )
      ..drawCircle(
        Offset(size.width * 0.5, size.height * 0.27),
        size.width * 0.15,
        Paint()..color = const Color(0xFFFFD8B8),
      )
      ..drawArc(
        Rect.fromLTWH(
          size.width * 0.33,
          size.height * 0.32,
          size.width * 0.34,
          size.height * 0.28,
        ),
        0.3,
        2.4,
        false,
        beardPaint,
      )
      ..drawLine(
        Offset(size.width * 0.78, size.height * 0.22),
        Offset(size.width * 0.78, size.height * 0.82),
        staffPaint,
      )
      ..drawCircle(
        Offset(size.width * 0.78, size.height * 0.18),
        size.width * 0.06,
        Paint()..color = const Color(0xFFFFC83D),
      );
  }

  void _paintQueenGlacia(Canvas canvas, Size size, Paint outlinePaint) {
    final gownPaint = Paint()..color = const Color(0xFF86DFFF);
    final crownPaint = Paint()..color = const Color(0xFFFFF8ED);

    final crown = Path()
      ..moveTo(size.width * 0.32, size.height * 0.22)
      ..lineTo(size.width * 0.42, size.height * 0.06)
      ..lineTo(size.width * 0.52, size.height * 0.22)
      ..lineTo(size.width * 0.64, size.height * 0.06)
      ..lineTo(size.width * 0.72, size.height * 0.22)
      ..close();
    final gown = Path()
      ..moveTo(size.width * 0.5, size.height * 0.28)
      ..lineTo(size.width * 0.22, size.height * 0.82)
      ..lineTo(size.width * 0.78, size.height * 0.82)
      ..close();

    canvas
      ..drawPath(crown, outlinePaint)
      ..drawPath(crown.shift(const Offset(0, 2)), crownPaint)
      ..drawCircle(
        Offset(size.width * 0.52, size.height * 0.31),
        size.width * 0.14,
        Paint()..color = const Color(0xFFFFE2C4),
      )
      ..drawPath(gown, outlinePaint)
      ..drawPath(gown.shift(const Offset(0, -2)), gownPaint);
  }

  void _paintBaronCocoa(Canvas canvas, Size size, Paint outlinePaint) {
    final coatPaint = Paint()..color = const Color(0xFF7A4328);
    final capePaint = Paint()..color = const Color(0xFFF2C36B);

    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.23,
            size.height * 0.32,
            size.width * 0.54,
            size.height * 0.5,
          ),
          const Radius.circular(12),
        ),
        outlinePaint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * 0.28,
            size.height * 0.36,
            size.width * 0.44,
            size.height * 0.42,
          ),
          const Radius.circular(10),
        ),
        coatPaint,
      )
      ..drawPath(
        Path()
          ..moveTo(size.width * 0.32, size.height * 0.38)
          ..lineTo(size.width * 0.12, size.height * 0.75)
          ..lineTo(size.width * 0.33, size.height * 0.68)
          ..close(),
        capePaint,
      )
      ..drawCircle(
        Offset(size.width * 0.5, size.height * 0.27),
        size.width * 0.14,
        Paint()..color = const Color(0xFFFFD8B8),
      )
      ..drawRect(
        Rect.fromLTWH(
          size.width * 0.38,
          size.height * 0.13,
          size.width * 0.24,
          size.height * 0.08,
        ),
        Paint()..color = const Color(0xFF5A2B1A),
      );
  }

  void _paintEmberImp(Canvas canvas, Size size, Paint outlinePaint) {
    final bodyPaint = Paint()..color = const Color(0xFFFF6B22);
    final flamePaint = Paint()..color = const Color(0xFFFFD45A);
    final body = Path()
      ..moveTo(size.width * 0.5, size.height * 0.12)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.36,
        size.width * 0.2,
        size.height * 0.78,
        size.width * 0.5,
        size.height * 0.86,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.78,
        size.width * 0.78,
        size.height * 0.36,
        size.width * 0.5,
        size.height * 0.12,
      )
      ..close();

    canvas
      ..drawPath(body, outlinePaint)
      ..drawPath(body.shift(const Offset(0, -2)), bodyPaint)
      ..drawCircle(
        Offset(size.width * 0.5, size.height * 0.5),
        size.width * 0.16,
        flamePaint,
      )
      ..drawCircle(
        Offset(size.width * 0.42, size.height * 0.34),
        size.width * 0.035,
        outlinePaint,
      )
      ..drawCircle(
        Offset(size.width * 0.58, size.height * 0.34),
        size.width * 0.035,
        outlinePaint,
      );
  }

  void _paintSyrupSprite(Canvas canvas, Size size, Paint outlinePaint) {
    final bodyPaint = Paint()..color = const Color(0x9935D0C3);
    final accentPaint = Paint()
      ..color = const Color(0xFFFF7AC8)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    final sprite = Path()
      ..moveTo(size.width * 0.5, size.height * 0.12)
      ..cubicTo(
        size.width * 0.18,
        size.height * 0.3,
        size.width * 0.24,
        size.height * 0.76,
        size.width * 0.5,
        size.height * 0.86,
      )
      ..cubicTo(
        size.width * 0.76,
        size.height * 0.76,
        size.width * 0.82,
        size.height * 0.3,
        size.width * 0.5,
        size.height * 0.12,
      )
      ..close();

    canvas
      ..drawPath(sprite, outlinePaint)
      ..drawPath(sprite.shift(const Offset(0, -2)), bodyPaint)
      ..drawArc(
        Rect.fromLTWH(
          size.width * 0.28,
          size.height * 0.35,
          size.width * 0.44,
          size.height * 0.28,
        ),
        0.3,
        2.4,
        false,
        accentPaint,
      )
      ..drawCircle(
        Offset(size.width * 0.44, size.height * 0.34),
        size.width * 0.025,
        outlinePaint,
      )
      ..drawCircle(
        Offset(size.width * 0.56, size.height * 0.34),
        size.width * 0.025,
        outlinePaint,
      );
  }

  @override
  bool shouldRepaint(covariant _CharacterPortraitPainter oldDelegate) {
    return oldDelegate.name != name || oldDelegate.accentColor != accentColor;
  }
}

/// Painter for kingdom-specific decorative motifs.
///
/// Shaders are pre-created in the constructor and cached rather than being
/// allocated inside [paint], which avoids expensive shader compilation on every
/// repaint.
class _KingdomMotifPainter extends CustomPainter {
  _KingdomMotifPainter({
    required List<String> motifs,
    required this.backgroundColor,
    required this.secondaryColor,
    required this.accentColor,
  }) : motifs = List<String>.unmodifiable(motifs),
       motifSignature = motifs.join('|'),
       _motifSet = Set<String>.unmodifiable(motifs);

  final List<String> motifs;
  final String motifSignature;
  final Set<String> _motifSet;
  final Color backgroundColor;
  final Color secondaryColor;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    _paintSugarSpeckles(canvas, size);

    if (_motifSet.contains('meadow')) {
      _paintMeadow(canvas, size);
    }
    if (_motifSet.contains('candyPath')) {
      _paintCandyStems(canvas, size);
    }
    if (_motifSet.contains('sugarFountain')) {
      _paintSugarFountain(canvas, size);
    }
    if (_motifSet.contains('cocoaCastle')) {
      _paintCocoaCastle(canvas, size);
    }
    if (_motifSet.contains('waferGate')) {
      _paintWaferGate(canvas, size);
    }
    if (_motifSet.contains('chocolateDrawbridge')) {
      _paintChocolateDrawbridge(canvas, size);
    }
    if (_motifSet.contains('frostedPeaks')) {
      _paintFrostedPeaks(canvas, size);
    }
    if (_motifSet.contains('crystalBridge')) {
      _paintCrystalBridge(canvas, size);
    }
    if (_motifSet.contains('snowPath')) {
      _paintSnowPath(canvas, size);
    }
    if (_motifSet.contains('moltenBakery')) {
      _paintMoltenBakery(canvas, size);
    }
    if (_motifSet.contains('ovenRoad')) {
      _paintOvenRoad(canvas, size);
    }
    if (_motifSet.contains('caramelLava')) {
      _paintCaramelLava(canvas, size);
    }
    if (_motifSet.contains('syrupLagoon')) {
      _paintSyrupLagoon(canvas, size);
    }
    if (_motifSet.contains('gummyIsland')) {
      _paintGummyIslands(canvas, size);
    }
    if (_motifSet.contains('mirrorWater')) {
      _paintMirrorWater(canvas, size);
    }
  }

  void _paintSugarSpeckles(Canvas canvas, Size size) {
    final speckPaint = Paint()..color = const Color(0x44FFF8ED);
    for (var index = 0; index < 42; index += 1) {
      final x = (index * 37 % 100) / 100 * size.width;
      final y = 120 + (index * 83 % 980).toDouble();
      canvas.drawCircle(Offset(x, y), 1.4 + index % 3, speckPaint);
    }
  }

  void _paintMeadow(Canvas canvas, Size size) {
    final hillPaint = Paint()..color = secondaryColor.withValues(alpha: 0.55);
    final flowerPaint = Paint()..color = const Color(0xFFFFF8ED);
    canvas
      ..drawOval(
        Rect.fromLTWH(
          -size.width * 0.18,
          size.height * 0.69,
          size.width * 0.72,
          size.height * 0.18,
        ),
        hillPaint,
      )
      ..drawOval(
        Rect.fromLTWH(
          size.width * 0.42,
          size.height * 0.73,
          size.width * 0.76,
          size.height * 0.18,
        ),
        hillPaint,
      );
    for (var index = 0; index < 14; index += 1) {
      final x = size.width * (0.12 + (index % 7) * 0.12);
      final y = size.height * (0.66 + (index % 2) * 0.08);
      canvas
        ..drawCircle(Offset(x, y), 3, flowerPaint)
        ..drawCircle(Offset(x + 4, y + 1), 3, Paint()..color = accentColor);
    }
  }

  void _paintCandyStems(Canvas canvas, Size size) {
    final stemPaint = Paint()
      ..color = const Color(0xAAFFF8ED)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;
    final candyPaint = Paint()..color = accentColor.withValues(alpha: 0.86);
    for (final anchor in [
      Offset(size.width * 0.12, size.height * 0.42),
      Offset(size.width * 0.84, size.height * 0.58),
      Offset(size.width * 0.18, size.height * 0.82),
    ]) {
      canvas
        ..drawLine(anchor, anchor.translate(0, 34), stemPaint)
        ..drawCircle(anchor, 16, Paint()..color = const Color(0xFFFFF8ED))
        ..drawCircle(anchor, 11, candyPaint)
        ..drawLine(
          anchor.translate(-8, -2),
          anchor.translate(8, 2),
          Paint()
            ..color = const Color(0x88FFF8ED)
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round,
        );
    }
  }

  void _paintSugarFountain(Canvas canvas, Size size) {
    final bowlPaint = Paint()..color = const Color(0xCCFFF8ED);
    final waterPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.48)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5;
    final center = Offset(size.width * 0.5, size.height * 0.22);
    canvas
      ..drawArc(
        Rect.fromCenter(center: center.translate(0, 28), width: 96, height: 42),
        0,
        3.14,
        false,
        Paint()
          ..color = const Color(0xFF2B174A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5,
      )
      ..drawOval(
        Rect.fromCenter(center: center.translate(0, 30), width: 86, height: 26),
        bowlPaint,
      )
      ..drawArc(
        Rect.fromCenter(
          center: center.translate(-18, 6),
          width: 42,
          height: 58,
        ),
        3.5,
        2.3,
        false,
        waterPaint,
      )
      ..drawArc(
        Rect.fromCenter(center: center.translate(18, 6), width: 42, height: 58),
        3.6,
        2.3,
        false,
        waterPaint,
      )
      ..drawLine(center.translate(0, -10), center.translate(0, 24), waterPaint);
  }

  void _paintCocoaCastle(Canvas canvas, Size size) {
    final castlePaint = Paint()..color = const Color(0xAA5A2B1A);
    final highlightPaint = Paint()..color = const Color(0xAAF2C36B);
    final baseRect = Rect.fromLTWH(
      size.width * 0.16,
      size.height * 0.2,
      size.width * 0.68,
      118,
    );
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(baseRect, const Radius.circular(18)),
        castlePaint,
      )
      ..drawRect(
        Rect.fromLTWH(baseRect.left + 22, baseRect.top - 42, 52, 62),
        castlePaint,
      )
      ..drawRect(
        Rect.fromLTWH(baseRect.right - 74, baseRect.top - 42, 52, 62),
        castlePaint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(baseRect.center.dx - 32, baseRect.bottom - 58, 64, 58),
          const Radius.circular(20),
        ),
        highlightPaint,
      );
  }

  void _paintWaferGate(Canvas canvas, Size size) {
    final gatePaint = Paint()
      ..color = const Color(0xCCFFF8ED)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final y = size.height * 0.5;
    for (var index = 0; index < 6; index += 1) {
      final x = size.width * 0.58 + index * 18;
      canvas.drawLine(Offset(x, y - 44), Offset(x, y + 44), gatePaint);
    }
    canvas
      ..drawLine(
        Offset(size.width * 0.56, y - 16),
        Offset(size.width * 0.9, y - 16),
        gatePaint,
      )
      ..drawLine(
        Offset(size.width * 0.56, y + 18),
        Offset(size.width * 0.9, y + 18),
        gatePaint,
      );
  }

  void _paintChocolateDrawbridge(Canvas canvas, Size size) {
    final bridgePaint = Paint()..color = const Color(0xAA7A4328);
    final ropePaint = Paint()
      ..color = const Color(0xBBFFF8ED)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final bridge = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.1,
        size.height * 0.78,
        size.width * 0.78,
        42,
      ),
      const Radius.circular(12),
    );
    canvas
      ..drawRRect(bridge, bridgePaint)
      ..drawLine(
        bridge.outerRect.topLeft,
        bridge.outerRect.topLeft.translate(30, -42),
        ropePaint,
      )
      ..drawLine(
        bridge.outerRect.topRight,
        bridge.outerRect.topRight.translate(-30, -42),
        ropePaint,
      );
  }

  void _paintFrostedPeaks(Canvas canvas, Size size) {
    final mountainPaint = Paint()..color = const Color(0xAAEAFBFF);
    final shadowPaint = Paint()..color = const Color(0x664A9DFF);
    for (final peak in [
      Offset(size.width * 0.24, size.height * 0.35),
      Offset(size.width * 0.52, size.height * 0.27),
      Offset(size.width * 0.78, size.height * 0.38),
    ]) {
      final mountain = Path()
        ..moveTo(peak.dx, peak.dy - 82)
        ..lineTo(peak.dx - 96, peak.dy + 82)
        ..lineTo(peak.dx + 96, peak.dy + 82)
        ..close();
      canvas
        ..drawPath(mountain.shift(const Offset(8, 12)), shadowPaint)
        ..drawPath(mountain, mountainPaint);
    }
  }

  void _paintCrystalBridge(Canvas canvas, Size size) {
    final crystalPaint = Paint()..color = const Color(0x9986DFFF);
    final outlinePaint = Paint()
      ..color = const Color(0xDDFFF8ED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (var index = 0; index < 5; index += 1) {
      final left = size.width * 0.16 + index * size.width * 0.14;
      final top = size.height * 0.58 + (index.isEven ? 0 : 18);
      final crystal = Path()
        ..moveTo(left + 24, top)
        ..lineTo(left + 48, top + 34)
        ..lineTo(left + 24, top + 68)
        ..lineTo(left, top + 34)
        ..close();
      canvas
        ..drawPath(crystal, crystalPaint)
        ..drawPath(crystal, outlinePaint);
    }
  }

  void _paintSnowPath(Canvas canvas, Size size) {
    final snowPaint = Paint()..color = const Color(0xCCFFF8ED);
    for (var index = 0; index < 22; index += 1) {
      final x = size.width * (0.18 + (index % 5) * 0.15);
      final y = size.height * 0.2 + index * 38;
      canvas.drawCircle(Offset(x, y), 2.5 + index % 2, snowPaint);
    }
  }

  void _paintMoltenBakery(Canvas canvas, Size size) {
    final ovenPaint = Paint()..color = const Color(0xCC7A1E12);
    final glowPaint = Paint()..color = const Color(0xBBFFD45A);
    final oven = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.56,
        size.height * 0.18,
        size.width * 0.3,
        110,
      ),
      const Radius.circular(24),
    );
    canvas
      ..drawRRect(oven, ovenPaint)
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            oven.outerRect.left + 28,
            oven.outerRect.top + 34,
            oven.outerRect.width - 56,
            46,
          ),
          const Radius.circular(22),
        ),
        glowPaint,
      )
      ..drawCircle(
        Offset(oven.outerRect.center.dx, oven.outerRect.top + 16),
        10,
        Paint()..color = const Color(0xFFFFF8ED),
      );
  }

  void _paintOvenRoad(Canvas canvas, Size size) {
    final brickPaint = Paint()..color = const Color(0x55FFF8ED);
    for (var row = 0; row < 8; row += 1) {
      for (var column = 0; column < 4; column += 1) {
        final x = size.width * 0.08 + column * size.width * 0.22;
        final y = size.height * 0.46 + row * 44;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x + (row.isOdd ? 26 : 0), y, 74, 20),
            const Radius.circular(8),
          ),
          brickPaint,
        );
      }
    }
  }

  void _paintCaramelLava(Canvas canvas, Size size) {
    // Use solid colors instead of shader to avoid expensive shader compilation.
    final lavaPaint = Paint()
      ..color = const Color(0xFFFF8A33)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 18;
    final path = Path()
      ..moveTo(size.width * 0.06, size.height * 0.72)
      ..cubicTo(
        size.width * 0.36,
        size.height * 0.65,
        size.width * 0.42,
        size.height * 0.9,
        size.width * 0.72,
        size.height * 0.82,
      )
      ..cubicTo(
        size.width * 0.86,
        size.height * 0.78,
        size.width * 0.9,
        size.height * 0.9,
        size.width * 0.98,
        size.height * 0.86,
      );
    canvas.drawPath(path, lavaPaint);
  }

  void _paintSyrupLagoon(Canvas canvas, Size size) {
    final lagoonPaint = Paint()..color = const Color(0x7735D0C3);
    final shorePaint = Paint()..color = const Color(0x66FFF8ED);
    final lagoon = Rect.fromLTWH(
      size.width * 0.08,
      size.height * 0.24,
      size.width * 0.84,
      size.height * 0.18,
    );
    canvas
      ..drawOval(lagoon.inflate(12), shorePaint)
      ..drawOval(lagoon, lagoonPaint);
  }

  void _paintGummyIslands(Canvas canvas, Size size) {
    final islandPaint = Paint()..color = accentColor.withValues(alpha: 0.65);
    for (final island in [
      Rect.fromLTWH(size.width * 0.12, size.height * 0.52, 98, 42),
      Rect.fromLTWH(size.width * 0.58, size.height * 0.62, 112, 46),
      Rect.fromLTWH(size.width * 0.22, size.height * 0.82, 126, 48),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(island, const Radius.circular(24)),
        islandPaint,
      );
    }
  }

  void _paintMirrorWater(Canvas canvas, Size size) {
    final waterPaint = Paint()
      ..color = const Color(0xAAFFF8ED)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    for (var index = 0; index < 8; index += 1) {
      final y = size.height * 0.35 + index * 82;
      canvas.drawLine(
        Offset(size.width * 0.18, y),
        Offset(size.width * 0.42 + (index % 3) * 30, y),
        waterPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _KingdomMotifPainter oldDelegate) {
    return oldDelegate.motifSignature != motifSignature ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.accentColor != accentColor;
  }
}

/// Painter for the curving candy path connecting level nodes.
///
/// Uses a solid paint instead of a shader to avoid shader compilation jank.
class _KingdomPathPainter extends CustomPainter {
  const _KingdomPathPainter({
    required this.accentColor,
    required this.pathColor,
  });

  final Color accentColor;
  final Color pathColor;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var index = 0; index < 20; index += 1) {
      final point = Offset(
        _nodeCenterX(index, size.width),
        kingdomMapNodeStartY + index * kingdomMapNodeStepY + 28,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        final previous = Offset(
          _nodeCenterX(index - 1, size.width),
          kingdomMapNodeStartY + (index - 1) * kingdomMapNodeStepY + 28,
        );
        path.cubicTo(
          previous.dx,
          previous.dy + 26,
          point.dx,
          point.dy - 26,
          point.dx,
          point.dy,
        );
      }
    }

    final shadowPaint = Paint()
      ..color = const Color(0x55000000)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 18;
    // Use solid color instead of ui.Gradient.linear to avoid shader
    // compilation stutter during scroll.
    final pathPaint = Paint()
      ..color = pathColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 12;

    canvas
      ..drawPath(path.shift(const Offset(0, 6)), shadowPaint)
      ..drawPath(path, pathPaint);
  }

  @override
  bool shouldRepaint(covariant _KingdomPathPainter oldDelegate) {
    return oldDelegate.accentColor != accentColor ||
        oldDelegate.pathColor != pathColor;
  }

  double _nodeCenterX(int index, double width) {
    const factors = [0.24, 0.42, 0.68, 0.76, 0.56, 0.32];
    return width * factors[index % factors.length];
  }
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

String _storyPanelTitle(KingdomStoryMoment moment, String kingdomName) {
  return switch (moment) {
    KingdomStoryMoment.intro => kingdomName,
    KingdomStoryMoment.outro => '$kingdomName Finale',
  };
}

String _storyPanelTooltip(KingdomStoryMoment moment, String kingdomName) {
  return switch (moment) {
    KingdomStoryMoment.intro => 'Read $kingdomName story',
    KingdomStoryMoment.outro => 'Read $kingdomName finale',
  };
}

String _storyTextFor(KingdomDefinition kingdom, KingdomStoryMoment moment) {
  return switch (moment) {
    KingdomStoryMoment.intro => kingdom.introStory,
    KingdomStoryMoment.outro => kingdom.outroStory,
  };
}

String _characterRoleFor(String name) {
  if (name.contains('Pip')) {
    return 'A quick-learning apprentice who carries the sugar wand and keeps the journey moving.';
  }
  if (name.contains('Caramel')) {
    return 'A patient mentor with a swirl-staff and a habit of turning mistakes into lessons.';
  }
  if (name.contains('Glacia')) {
    return 'The crystal-crowned ruler of the peaks, guarding Frost candy from runaway blizzards.';
  }
  if (name.contains('Cocoa')) {
    return 'A dramatic chocolate noble whose wafer gates hide a surprisingly helpful heart.';
  }
  if (name.contains('Ember')) {
    return 'A tiny oven-spark troublemaker who teaches Pip how Molten and Spice reactions behave.';
  }
  if (name.contains('Syrup')) {
    return 'A glossy lagoon helper who reads ripples, bridges gummy islands, and cheers Living candies.';
  }
  return 'A kingdom guide from the Alchemy Kingdoms.';
}

Color _accentColorForGate(
  KingdomMapController controller,
  KingdomGateDefinition gate,
) {
  for (final kingdom in controller.kingdoms) {
    if (kingdom.kingdomId == gate.kingdomId) {
      return Color(kingdom.accentColorValue);
    }
  }
  return const Color(0xFFFFC83D);
}

String _gateTooltip(
  KingdomGateDefinition gate, {
  required bool isUnlocked,
  required bool isClaimed,
}) {
  if (!isUnlocked) {
    return 'Complete level ${gate.checkpointLevel} to open ${gate.title}';
  }
  if (isClaimed) {
    return '${gate.title} reward collected';
  }
  return 'Claim ${gate.rewardLabel}';
}

IconData _boosterIcon(BoosterType boosterType) {
  return switch (boosterType) {
    BoosterType.fusionBooster => Icons.auto_awesome_rounded,
    BoosterType.tempoMeter => Icons.bolt_rounded,
    BoosterType.architectTile => Icons.architecture_rounded,
    BoosterType.echoCandy => Icons.graphic_eq_rounded,
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
