import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/constants/navigation_constants.dart';
import 'core/constants/ui_constants.dart';
import 'core/theme/candy_alchemy_colors.dart';
import 'features/gameplay/controllers/gameplay_binding.dart';
import 'features/gameplay/presentation/gameplay_screen.dart';
import 'features/gameplay/presentation/lose_overlay.dart';
import 'features/gameplay/presentation/win_overlay.dart';
import 'features/level_map/controllers/level_map_binding.dart';
import 'features/level_map/presentation/level_map_screen.dart';
import 'features/menu/main_menu_screen.dart';

/// Starts the Candy Alchemy Flutter application.
void main() {
  runApp(const App());
}

/// Root UI layer for Candy Alchemy.
class App extends StatelessWidget {
  /// Creates the Candy Alchemy app.
  const App({super.key});

  /// Builds the GetX navigation shell for Candy Alchemy.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.mainMenu,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: CandyAlchemyColors.mint,
          brightness: Brightness.dark,
        ),
      ),
      getPages: [
        GetPage(name: AppRoutes.mainMenu, page: MainMenuScreen.new),
        GetPage(
          name: AppRoutes.levelMap,
          page: LevelMapScreen.new,
          binding: LevelMapBinding(),
          transition: Transition.rightToLeft,
          transitionDuration: const Duration(
            milliseconds: menuToLevelMapTransitionMilliseconds,
          ),
        ),
        GetPage(
          name: AppRoutes.gameplay,
          page: GameplayScreen.new,
          binding: GameplayBinding(),
        ),
        GetPage(
          name: AppRoutes.winOverlay,
          page: WinOverlay.new,
          binding: GameplayBinding(),
          opaque: false,
          transition: Transition.noTransition,
        ),
        GetPage(
          name: AppRoutes.loseOverlay,
          page: LoseOverlay.new,
          binding: GameplayBinding(),
          opaque: false,
          transition: Transition.noTransition,
        ),
      ],
    );
  }
}
