import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/navigation_constants.dart';
import 'core/constants/ui_constants.dart';
import 'core/theme/candy_alchemy_colors.dart';
import 'data/repositories/booster_inventory_repository.dart';
import 'data/repositories/daily_reward_repository.dart';
import 'data/repositories/hive_sync_store.dart';
import 'data/repositories/kingdom_gate_reward_repository.dart';
import 'data/repositories/leaderboard_repository.dart';
import 'data/repositories/offline_sync_remote_data_source.dart';
import 'data/repositories/progress_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/story_progress_repository.dart';
import 'data/repositories/tutorial_progress_repository.dart';
import 'features/gameplay/controllers/gameplay_binding.dart';
import 'features/gameplay/presentation/gameplay_screen.dart';
import 'features/gameplay/presentation/lose_overlay.dart';
import 'features/gameplay/presentation/win_overlay.dart';
import 'features/kingdom_map/controllers/kingdom_map_binding.dart';
import 'features/kingdom_map/presentation/kingdom_map_screen.dart';
import 'features/menu/main_menu_screen.dart';
import 'features/settings/controllers/settings_controller.dart';

/// Starts the Candy Alchemy Flutter application.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeOfflinePersistence();
  runApp(const App());
}

Future<void> _initializeOfflinePersistence() async {
  await Hive.initFlutter();
  final localStore = HiveSyncStore();
  const remote = OfflineSyncRemoteDataSource();
  if (!Get.isRegistered<ProgressRepository>()) {
    Get.put(
      ProgressRepository(remote: remote, local: localStore),
      permanent: true,
    );
  }
  if (!Get.isRegistered<LeaderboardRepository>()) {
    Get.put(
      LeaderboardRepository(remote: remote, local: localStore),
      permanent: true,
    );
  }
  if (!Get.isRegistered<BoosterInventoryRepository>()) {
    Get.put(
      BoosterInventoryRepository(remote: remote, local: localStore),
      permanent: true,
    );
  }
  if (!Get.isRegistered<SettingsRepository>()) {
    Get.put(SettingsRepository(local: localStore), permanent: true);
  }
  if (!Get.isRegistered<StoryProgressRepository>()) {
    Get.put(StoryProgressRepository(local: localStore), permanent: true);
  }
  if (!Get.isRegistered<KingdomGateRewardRepository>()) {
    Get.put(KingdomGateRewardRepository(local: localStore), permanent: true);
  }
  if (!Get.isRegistered<DailyRewardRepository>()) {
    Get.put(DailyRewardRepository(local: localStore), permanent: true);
  }
  if (!Get.isRegistered<TutorialProgressRepository>()) {
    Get.put(TutorialProgressRepository(local: localStore), permanent: true);
  }
  if (!Get.isRegistered<SettingsController>()) {
    Get.put(
      SettingsController(settingsRepository: Get.find<SettingsRepository>()),
      permanent: true,
    );
  }
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
          name: AppRoutes.kingdomMap,
          page: KingdomMapScreen.new,
          binding: KingdomMapBinding(),
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
          transition: Transition.noTransition,
        ),
        GetPage(
          name: AppRoutes.loseOverlay,
          page: LoseOverlay.new,
          binding: GameplayBinding(),
          transition: Transition.noTransition,
        ),
      ],
    );
  }
}
