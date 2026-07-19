import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/tutorial_constants.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/candy_alchemy_colors.dart';
import '../controllers/tutorial_controller.dart';
import '../domain/tutorial_step_definition.dart';
import '../domain/tutorial_target.dart';

// PLACEMENT_NOTE: ARCHITECTURE.md does not yet list onboarding presentation;
// this overlay is route UI only and does not decide game rules.

/// First-time tutorial overlay in the Flutter UI layer.
class TutorialOverlay extends StatelessWidget {
  /// Creates a tutorial overlay.
  const TutorialOverlay({
    required this.controller,
    required this.onContinue,
    required this.onSkipAll,
    super.key,
  });

  /// Tutorial controller that exposes the active prompt.
  final TutorialController controller;

  /// Called when the player accepts the active tutorial prompt.
  final Future<void> Function() onContinue;

  /// Called when the player skips all first-time tutorial prompts.
  final Future<void> Function() onSkipAll;

  /// Builds the overlay above gameplay.
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tutorial = controller.activeTutorial.value;
      if (tutorial == null) {
        return const SizedBox.shrink();
      }

      return Positioned.fill(
        child: Material(
          color: CandyAlchemyColors.gameplayBackground.withValues(
            alpha: tutorialBackdropOpacity,
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    _TutorialTargetHighlight(
                      tutorial: tutorial,
                      constraints: constraints,
                    ),
                    Align(
                      alignment: _promptAlignmentFor(tutorial.target),
                      child: Padding(
                        padding: const EdgeInsets.all(uiScreenPadding),
                        child: _TutorialPrompt(
                          tutorial: tutorial,
                          onContinue: onContinue,
                          onSkipAll: onSkipAll,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
    });
  }
}

/// Highlight box for the active tutorial target.
class _TutorialTargetHighlight extends StatelessWidget {
  const _TutorialTargetHighlight({
    required this.tutorial,
    required this.constraints,
  });

  final TutorialStepDefinition tutorial;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) {
    final rect = _highlightRectFor(tutorial.target, constraints);
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.92, end: 1),
        duration: const Duration(
          milliseconds: tutorialHighlightPopMilliseconds,
        ),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: const Color(0xFFFFC83D),
              width: tutorialHighlightBorderWidth,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0xAAFFC83D),
                blurRadius: 20,
                spreadRadius: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Rect _highlightRectFor(TutorialTarget target, BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    return switch (target) {
      TutorialTarget.goal => Rect.fromLTWH(
        width * 0.52,
        16,
        math.min(width * 0.42, 170),
        86,
      ),
      TutorialTarget.boosterTray => Rect.fromLTWH(
        16,
        math.max(0, height - 124),
        width - 32,
        108,
      ),
      TutorialTarget.specialCandy => Rect.fromCenter(
        center: Offset(width / 2, height * 0.55),
        width: math.min(width - 40, 320),
        height: math.min(width - 40, 320),
      ),
      TutorialTarget.blocker => Rect.fromCenter(
        center: Offset(width / 2, height * 0.6),
        width: math.min(width - 44, 340),
        height: math.min(width - 44, 280),
      ),
      TutorialTarget.board => Rect.fromCenter(
        center: Offset(width / 2, height * 0.54),
        width: math.min(width - 40, 360),
        height: math.min(width - 40, height * 0.52),
      ),
    };
  }
}

/// Prompt card for one tutorial lesson.
class _TutorialPrompt extends StatelessWidget {
  const _TutorialPrompt({
    required this.tutorial,
    required this.onContinue,
    required this.onSkipAll,
  });

  final TutorialStepDefinition tutorial;
  final Future<void> Function() onContinue;
  final Future<void> Function() onSkipAll;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: tutorialPromptMaxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8ED),
          borderRadius: BorderRadius.circular(tutorialPromptCornerRadius),
          border: Border.all(color: const Color(0xFFFFC83D), width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF35D0C3), Color(0xFFFF5FA2)],
                      ),
                    ),
                    child: SizedBox.square(
                      dimension: 44,
                      child: Icon(
                        _iconFor(tutorial.target),
                        color: const Color(0xFFFFF8ED),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lesson ${tutorial.levelNumber}',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: const Color(0xAA2B174A),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        Text(
                          tutorial.title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: const Color(0xFF2B174A),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                tutorial.message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xDD2B174A),
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () => unawaited(onSkipAll()),
                    child: const Text('Skip tutorials'),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => unawaited(onContinue()),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(tutorial.actionLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(TutorialTarget target) {
    return switch (target) {
      TutorialTarget.board => Icons.swap_horiz_rounded,
      TutorialTarget.goal => Icons.flag_rounded,
      TutorialTarget.specialCandy => Icons.auto_awesome_rounded,
      TutorialTarget.boosterTray => Icons.inventory_2_rounded,
      TutorialTarget.blocker => Icons.lock_open_rounded,
    };
  }
}

Alignment _promptAlignmentFor(TutorialTarget target) {
  return switch (target) {
    TutorialTarget.boosterTray => Alignment.topCenter,
    TutorialTarget.goal => Alignment.bottomCenter,
    TutorialTarget.board ||
    TutorialTarget.specialCandy ||
    TutorialTarget.blocker => Alignment.bottomCenter,
  };
}
