import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/candy_alchemy_colors.dart';
import '../../../data/repositories/daily_reward_repository.dart';
import '../../boosters/domain/booster_type.dart';
import '../controllers/player_profile_controller.dart';
import '../domain/daily_reward_definition.dart';

// PLACEMENT_NOTE: ARCHITECTURE.md does not yet list profile presentation, but
// PRD.md section 2 requires daily rewards and player-facing return loops.

/// Opens the player profile and daily reward dialog.
///
/// Inputs: none. Output: dialog result future. Side effects: registers profile
/// dependencies when missing and shows a GetX dialog.
Future<T?> showPlayerProfileDialog<T>() async {
  _ensurePlayerProfileDependencies();
  final controller = Get.find<PlayerProfileController>();
  await controller.loadProfile();
  return Get.dialog<T>(PlayerProfileDialog(controller: controller));
}

void _ensurePlayerProfileDependencies() {
  if (!Get.isRegistered<DailyRewardRepository>()) {
    Get.put(
      DailyRewardRepository(local: MemoryDailyRewardLocalDataSource()),
      permanent: true,
    );
  }
  if (!Get.isRegistered<PlayerProfileController>()) {
    Get.put(
      PlayerProfileController(
        dailyRewardRepository: Get.find<DailyRewardRepository>(),
      ),
      permanent: true,
    );
  }
}

/// Player profile and daily rewards dialog in the Flutter UI layer.
class PlayerProfileDialog extends StatelessWidget {
  /// Creates a player profile dialog for [controller].
  const PlayerProfileDialog({required this.controller, super.key});

  /// Controller that drives profile, inventory, and reward state.
  final PlayerProfileController controller;

  /// Builds the profile dialog surface.
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.sizeOf(context).height - 48,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8ED),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFC83D), width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0x66000000),
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
                  _ProfileHeader(controller: controller),
                  const SizedBox(height: 16),
                  _ProfileSummary(controller: controller),
                  const SizedBox(height: 16),
                  _BoosterInventory(controller: controller),
                  const SizedBox(height: 16),
                  _DailyRewardPanel(controller: controller),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: Get.back,
                      child: const Text('Done'),
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
}

/// Header with avatar and player name for the profile dialog.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.controller});

  final PlayerProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF35D0C3), Color(0xFFFF5FA2)],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: const SizedBox.square(
            dimension: 54,
            child: Center(
              child: Text(
                'P',
                style: TextStyle(
                  color: Color(0xFFFFF8ED),
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.playerName.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF2B174A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  controller.bestKingdomName.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xCC2B174A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          onPressed: Get.back,
          tooltip: 'Close profile',
          icon: const Icon(Icons.close_rounded, color: Color(0xFF2B174A)),
        ),
      ],
    );
  }
}

/// Compact progress summary row for the profile dialog.
class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.controller});

  final PlayerProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Row(
        children: [
          Expanded(
            child: _ProfileStat(
              icon: Icons.flag_rounded,
              label: 'Level',
              value: '${controller.unlockedLevel.value}',
              color: CandyAlchemyColors.mint,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ProfileStat(
              icon: Icons.star_rounded,
              label: 'Stars',
              value: '${controller.totalStars.value}',
              color: const Color(0xFFFFC83D),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _ProfileStat(
              icon: Icons.public_rounded,
              label: 'Kingdom',
              value: controller.bestKingdomName.value,
              color: const Color(0xFF6B4DFF),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single compact profile statistic tile.
class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(uiPanelCornerRadius),
        border: Border.all(color: color.withValues(alpha: 0.48)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xAA2B174A),
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: const Color(0xFF2B174A),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Booster inventory row shown inside the profile dialog.
class _BoosterInventory extends StatelessWidget {
  const _BoosterInventory({required this.controller});

  final PlayerProfileController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          icon: Icons.inventory_2_rounded,
          title: 'Booster Inventory',
          color: CandyAlchemyColors.berry,
        ),
        const SizedBox(height: 8),
        Obx(
          () => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final boosterType in BoosterType.values)
                _BoosterInventoryChip(
                  boosterType: boosterType,
                  count: controller.boosterCount(boosterType),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Single booster inventory chip.
class _BoosterInventoryChip extends StatelessWidget {
  const _BoosterInventoryChip({required this.boosterType, required this.count});

  final BoosterType boosterType;
  final int count;

  @override
  Widget build(BuildContext context) {
    final color = _boosterColor(boosterType);
    return Tooltip(
      message: boosterTypeLabel(boosterType),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_boosterIcon(boosterType), color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF2B174A),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Daily reward claim section for the profile dialog.
class _DailyRewardPanel extends StatelessWidget {
  const _DailyRewardPanel({required this.controller});

  final PlayerProfileController controller;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFE7A8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFC83D), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Obx(() {
          final reward = controller.nextDailyReward;
          final canClaim = controller.canClaimDailyReward;
          final isClaiming = controller.isClaimingDailyReward.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                icon: Icons.card_giftcard_rounded,
                title: 'Daily Reward',
                color: const Color(0xFF2B174A),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      canClaim
                          ? 'Ready: ${reward.rewardLabel}'
                          : 'Collected today',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF2B174A),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: canClaim && !isClaiming
                        ? () => unawaited(controller.claimDailyReward())
                        : null,
                    icon: Icon(
                      canClaim
                          ? Icons.redeem_rounded
                          : Icons.check_circle_rounded,
                    ),
                    label: Text(canClaim ? 'Claim' : 'Claimed'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final trackReward
                      in PlayerProfileController.dailyRewardTrack)
                    _DailyRewardTile(
                      reward: trackReward,
                      isActive: trackReward.day == controller.visibleStreakDay,
                      isClaimedToday:
                          !canClaim &&
                          trackReward.day ==
                              controller.dailyRewardState.value.streakDay,
                    ),
                ],
              ),
              if (controller.lastClaimedReward.value != null) ...[
                const SizedBox(height: 10),
                Text(
                  'Collected ${controller.lastClaimedReward.value!.rewardLabel}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFF2B174A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}

/// Small day tile for the daily reward track.
class _DailyRewardTile extends StatelessWidget {
  const _DailyRewardTile({
    required this.reward,
    required this.isActive,
    required this.isClaimedToday,
  });

  final DailyRewardDefinition reward;
  final bool isActive;
  final bool isClaimedToday;

  @override
  Widget build(BuildContext context) {
    final color = _boosterColor(reward.boosterType);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isActive
            ? color.withValues(alpha: 0.24)
            : const Color(0x88FFF8ED),
        borderRadius: BorderRadius.circular(uiPanelCornerRadius),
        border: Border.all(
          color: isActive ? color : const Color(0x552B174A),
          width: isActive ? 2 : 1,
        ),
      ),
      child: SizedBox(
        width: 86,
        height: 70,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Day ${reward.day}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF2B174A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (isClaimedToday) ...[
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF35C990),
                      size: 13,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Icon(_boosterIcon(reward.boosterType), color: color, size: 17),
              Text(
                'x${reward.quantity}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xDD2B174A),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section label with a compact icon.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: const Color(0xFF2B174A),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

IconData _boosterIcon(BoosterType boosterType) {
  return switch (boosterType) {
    BoosterType.fusionBooster => Icons.auto_awesome_rounded,
    BoosterType.tempoMeter => Icons.bolt_rounded,
    BoosterType.architectTile => Icons.architecture_rounded,
    BoosterType.echoCandy => Icons.graphic_eq_rounded,
  };
}

Color _boosterColor(BoosterType boosterType) {
  return switch (boosterType) {
    BoosterType.fusionBooster => CandyAlchemyColors.popPink,
    BoosterType.tempoMeter => CandyAlchemyColors.molten,
    BoosterType.architectTile => CandyAlchemyColors.frost,
    BoosterType.echoCandy => CandyAlchemyColors.syrup,
  };
}
