import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/navigation_constants.dart';
import '../../core/constants/ui_constants.dart';
import '../../core/theme/candy_alchemy_colors.dart';
import '../profile/presentation/player_profile_dialog.dart';

/// Main Menu screen in the Flutter UI layer.
class MainMenuScreen extends StatelessWidget {
  /// Creates the Candy Alchemy Main Menu screen.
  const MainMenuScreen({super.key});

  /// Builds the Main Menu route.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CandyAlchemyColors.gameplayBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(uiScreenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                'Candy Alchemy',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: CandyAlchemyColors.cream,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: uiSectionGap),
              FilledButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.kingdomMap),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Play'),
              ),
              const SizedBox(height: uiControlGap),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Settings'),
              ),
              const SizedBox(height: uiControlGap),
              OutlinedButton.icon(
                onPressed: () => unawaited(showPlayerProfileDialog<void>()),
                icon: const Icon(Icons.person_rounded),
                label: const Text('Profile'),
              ),
              const SizedBox(height: uiControlGap),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.shopping_bag_rounded),
                label: const Text('Shop'),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
